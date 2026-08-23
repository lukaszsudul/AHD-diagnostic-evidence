[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$root = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
$expectedRoot = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
$manifestPath = Join-Path $root 'SHA256_MANIFEST.txt'
$zipPath = 'C:\FPGA\V41_NVP_R1E_R5_COMPLETE_MEASUREMENT_EVIDENCE.zip'
$sidecarPath = 'C:\FPGA\V41_NVP_R1E_R5_COMPLETE_MEASUREMENT_EVIDENCE_SHA256.txt'
$archivePrefix = 'V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5/'

if ([IO.Path]::GetFullPath($root) -cne $expectedRoot) {
    throw 'Unexpected task root.'
}

foreach ($outputPath in @($manifestPath, $zipPath, $sidecarPath)) {
    if (Test-Path -LiteralPath $outputPath) {
        throw "Refusing to overwrite existing seal output: $outputPath"
    }
}

$sourceFiles = @(
    Get-ChildItem -LiteralPath $root -Recurse -File |
        Where-Object {
            $_.FullName -cne $manifestPath -and
            $_.Extension -cne '.pyc' -and
            $_.FullName -notmatch '[\\/]__pycache__[\\/]'
        } |
        Sort-Object FullName
)

$manifestLines = foreach ($file in $sourceFiles) {
    $relative = $file.FullName.Substring($root.Length + 1)
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash
    "$hash *$relative"
}
[IO.File]::WriteAllLines($manifestPath, $manifestLines, [Text.Encoding]::ASCII)

foreach ($line in [IO.File]::ReadAllLines($manifestPath)) {
    if ($line -notmatch '^([0-9A-F]{64}) \*(.+)$') {
        throw 'Malformed manifest line.'
    }
    $localPath = Join-Path $root $Matches[2]
    if (-not (Test-Path -LiteralPath $localPath -PathType Leaf)) {
        throw "Manifest file is missing: $localPath"
    }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $localPath).Hash -cne $Matches[1]) {
        throw "Manifest hash mismatch: $localPath"
    }
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zipStream = [IO.File]::Open($zipPath, [IO.FileMode]::CreateNew)
$zip = [IO.Compression.ZipArchive]::new(
    $zipStream,
    [IO.Compression.ZipArchiveMode]::Create,
    $false
)
try {
    $archiveFiles = @(
        Get-ChildItem -LiteralPath $root -Recurse -File |
            Where-Object {
                $_.Extension -cne '.pyc' -and
                $_.FullName -notmatch '[\\/]__pycache__[\\/]'
            } |
            Sort-Object FullName
    )
    foreach ($file in $archiveFiles) {
        $relative = $file.FullName.Substring($root.Length + 1).Replace('\', '/')
        $entry = $zip.CreateEntry(
            $archivePrefix + $relative,
            [IO.Compression.CompressionLevel]::Optimal
        )
        $inputStream = $file.OpenRead()
        $entryStream = $entry.Open()
        try {
            $inputStream.CopyTo($entryStream)
        }
        finally {
            $entryStream.Dispose()
            $inputStream.Dispose()
        }
    }
}
finally {
    $zip.Dispose()
    $zipStream.Dispose()
}

$zipItem = Get-Item -LiteralPath $zipPath
$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash
[IO.File]::WriteAllText(
    $sidecarPath,
    "$zipHash *$($zipItem.Name)`r`n",
    [Text.Encoding]::ASCII
)

$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $manifestEntryName = $archivePrefix + 'SHA256_MANIFEST.txt'
    $manifestEntries = @($archive.Entries | Where-Object FullName -CEQ $manifestEntryName)
    if ($manifestEntries.Count -ne 1) {
        throw 'Embedded SHA256_MANIFEST.txt is missing or duplicated.'
    }

    $reader = [IO.StreamReader]::new($manifestEntries[0].Open(), [Text.Encoding]::ASCII)
    try {
        $embeddedLines = [Collections.Generic.List[string]]::new()
        while (-not $reader.EndOfStream) {
            $embeddedLines.Add($reader.ReadLine())
        }
    }
    finally {
        $reader.Dispose()
    }

    $verifiedCount = 0
    foreach ($line in $embeddedLines) {
        if ($line -notmatch '^([0-9A-F]{64}) \*(.+)$') {
            throw 'Malformed embedded manifest line.'
        }
        $entryName = $archivePrefix + $Matches[2].Replace('\', '/')
        $entries = @($archive.Entries | Where-Object FullName -CEQ $entryName)
        if ($entries.Count -ne 1) {
            throw "Archive entry missing or duplicated: $entryName"
        }
        $sha = [Security.Cryptography.SHA256]::Create()
        $entryStream = $entries[0].Open()
        try {
            $digest = [BitConverter]::ToString($sha.ComputeHash($entryStream)).Replace('-', '')
        }
        finally {
            $entryStream.Dispose()
            $sha.Dispose()
        }
        if ($digest -cne $Matches[1]) {
            throw "Archived entry hash mismatch: $entryName"
        }
        $verifiedCount++
    }

    $forbiddenEntries = @(
        $archive.Entries | Where-Object {
            $_.FullName -match '(^|/)(VCDE-DUT-1\.txt|pw-[0-9a-fA-F]+\.tmp|id_rsa|id_ed25519)$' -or
            $_.FullName -match '\.(pem|pfx|p12|key|pyc)$' -or
            $_.FullName -match '/__pycache__/'
        }
    )
    if ($forbiddenEntries.Count -ne 0) {
        throw 'Forbidden file found in sealed archive.'
    }

    Write-Output "MANIFEST_ENTRIES=$($embeddedLines.Count)"
    Write-Output "ARCHIVE_ENTRIES_VERIFIED=$verifiedCount"
    Write-Output "FORBIDDEN_ARCHIVE_ENTRIES=$($forbiddenEntries.Count)"
    Write-Output "ZIP_SIZE_BYTES=$($zipItem.Length)"
    Write-Output "ZIP_SHA256=$zipHash"
    Write-Output "SIDECAR_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $sidecarPath).Hash)"
}
finally {
    $archive.Dispose()
}
