[CmdletBinding()]
param(
    [Parameter()]
    [string]$TaskRoot = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$manifestName = 'SHA256_MANIFEST.txt'
$zipName = 'V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY_EVIDENCE.zip'
$sidecarName = 'V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY_EVIDENCE_SHA256.txt'
$manifestPath = Join-Path $TaskRoot $manifestName
$zipPath = Join-Path $TaskRoot $zipName
$sidecarPath = Join-Path $TaskRoot $sidecarName

$manifestLines = @(Get-Content -LiteralPath $manifestPath)
if ($manifestLines.Count -lt 2 -or
    $manifestLines[0] -cne 'FORMAT=SHA256|SIZE_BYTES|TASK_ROOT_RELATIVE_PATH') {
    throw 'Manifest header is missing or invalid.'
}

$records = [System.Collections.Generic.List[object]]::new()
$seen = [System.Collections.Generic.HashSet[string]]::new(
    [System.StringComparer]::OrdinalIgnoreCase)
foreach ($line in $manifestLines[1..($manifestLines.Count - 1)]) {
    if ($line -notmatch '^([0-9A-F]{64})\|([0-9]+)\|(.+)$') {
        throw "Invalid manifest row: $line"
    }
    $relative = $Matches[3]
    if ($relative.StartsWith('/', [System.StringComparison]::Ordinal) -or
        $relative.StartsWith('../', [System.StringComparison]::Ordinal) -or
        $relative.Contains('\') -or -not $seen.Add($relative)) {
        throw "Unsafe or duplicate manifest path: $relative"
    }
    $records.Add([pscustomobject]@{
        Hash = $Matches[1]
        Size = [int64]$Matches[2]
        Relative = $relative
    })
}

foreach ($record in $records) {
    $full = Join-Path $TaskRoot $record.Relative.Replace('/', '\')
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) {
        throw "Manifest file missing from task root: $($record.Relative)"
    }
    $item = Get-Item -LiteralPath $full
    if ($item.Length -ne $record.Size) {
        throw "Task-root size mismatch: $($record.Relative)"
    }
    if ((Get-FileHash -Algorithm SHA256 -LiteralPath $full).Hash -cne $record.Hash) {
        throw "Task-root hash mismatch: $($record.Relative)"
    }
}

$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash
$sidecar = (Get-Content -LiteralPath $sidecarPath -Raw).Trim()
if ($sidecar -cne "$zipHash  $zipName") {
    throw 'Evidence-package sidecar does not match the ZIP identity.'
}

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $entries = @($archive.Entries | Where-Object { -not $_.FullName.EndsWith('/') })
    $entryNames = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase)
    foreach ($entry in $entries) {
        if ($entry.FullName.StartsWith('/', [System.StringComparison]::Ordinal) -or
            $entry.FullName.StartsWith('../', [System.StringComparison]::Ordinal) -or
            $entry.FullName.Contains('\') -or -not $entryNames.Add($entry.FullName)) {
            throw "Unsafe or duplicate ZIP entry: $($entry.FullName)"
        }
    }
    if (-not $entryNames.Contains($manifestName)) {
        throw 'ZIP does not contain its exact manifest.'
    }
    if ($entries.Count -ne ($records.Count + 1)) {
        throw "ZIP file-entry count mismatch: expected $($records.Count + 1), got $($entries.Count)"
    }

    foreach ($record in $records) {
        $entry = $archive.GetEntry($record.Relative)
        if ($null -eq $entry -or $entry.Length -ne $record.Size) {
            throw "ZIP entry missing or wrong size: $($record.Relative)"
        }
        $stream = $entry.Open()
        try {
            $sha = [System.Security.Cryptography.SHA256]::Create()
            try {
                $entryHash = [System.BitConverter]::ToString($sha.ComputeHash($stream)).Replace('-', '')
            } finally {
                $sha.Dispose()
            }
        } finally {
            $stream.Dispose()
        }
        if ($entryHash -cne $record.Hash) {
            throw "ZIP entry hash mismatch: $($record.Relative)"
        }
    }

    $manifestEntry = $archive.GetEntry($manifestName)
    $manifestStream = $manifestEntry.Open()
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        try {
            $zipManifestHash = [System.BitConverter]::ToString(
                $sha.ComputeHash($manifestStream)).Replace('-', '')
        } finally {
            $sha.Dispose()
        }
    } finally {
        $manifestStream.Dispose()
    }
    $localManifestHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash
    if ($zipManifestHash -cne $localManifestHash) {
        throw 'ZIP manifest is not byte-identical to the external task manifest.'
    }
} finally {
    $archive.Dispose()
}

Write-Output 'PACKAGE_VALIDATION=PASS'
Write-Output "MANIFEST_ROWS=$($records.Count)"
Write-Output "MANIFEST_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash)"
Write-Output "ZIP_FILE_ENTRIES=$($records.Count + 1)"
Write-Output "EVIDENCE_PACKAGE_SHA256=$zipHash"
