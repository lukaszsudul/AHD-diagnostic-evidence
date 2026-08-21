param(
    [Parameter(Mandatory=$true)][string]$TaskRoot
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path -LiteralPath $TaskRoot).Path.TrimEnd('\')
$zipName = 'RCA_VS_FORMAL_PHASE2_POWER_BREAKDOWN_EVIDENCE.zip'
$sidecarName = 'RCA_VS_FORMAL_PHASE2_POWER_BREAKDOWN_EVIDENCE_SHA256.txt'
$manifestName = 'SHA256_MANIFEST.txt'
$zipPath = Join-Path $root $zipName
$sidecarPath = Join-Path $root $sidecarName
$manifestPath = Join-Path $root $manifestName

foreach ($path in @($zipPath, $sidecarPath, $manifestPath)) {
    if (Test-Path -LiteralPath $path) {
        throw "Refusing to overwrite existing seal artifact: $path"
    }
}

$excludedNames = @($zipName, $sidecarName, $manifestName)
$evidenceFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.Name -notin $excludedNames
} | Sort-Object FullName)
if ($evidenceFiles.Count -eq 0) {
    throw 'No evidence files found'
}

$manifestLines = New-Object System.Collections.Generic.List[string]
$manifestLines.Add('# SHA-256 manifest for task evidence files')
$manifestLines.Add('# The manifest excludes itself and the external ZIP/SHA-256 sidecar.')
foreach ($file in $evidenceFiles) {
    $relative = $file.FullName.Substring($root.Length + 1).Replace('\','/')
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToUpperInvariant()
    $manifestLines.Add("$hash *$relative")
}
[System.IO.File]::WriteAllLines($manifestPath, $manifestLines, [System.Text.UTF8Encoding]::new($false))

$filesForZip = @($evidenceFiles + (Get-Item -LiteralPath $manifestPath) | Sort-Object FullName)
$archive = [System.IO.Compression.ZipFile]::Open($zipPath, [System.IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $filesForZip) {
        $relative = $file.FullName.Substring($root.Length + 1).Replace('\','/')
        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            $file.FullName,
            $relative,
            [System.IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
} finally {
    $archive.Dispose()
}

$readArchive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    if ($readArchive.Entries.Count -ne $filesForZip.Count) {
        throw "ZIP entry count mismatch: expected $($filesForZip.Count), got $($readArchive.Entries.Count)"
    }
    $names = @($readArchive.Entries | ForEach-Object FullName)
    if (@($names | Group-Object | Where-Object Count -gt 1).Count -ne 0) {
        throw 'ZIP contains duplicate entry names'
    }
    $buffer = New-Object byte[] 65536
    foreach ($entry in $readArchive.Entries) {
        $stream = $entry.Open()
        try {
            while ($stream.Read($buffer, 0, $buffer.Length) -gt 0) { }
        } finally {
            $stream.Dispose()
        }
    }
} finally {
    $readArchive.Dispose()
}

$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToUpperInvariant()
$sidecar = @(
    "SHA256=$zipHash",
    "FILE=$zipName",
    "ZIP_INTEGRITY=PASS",
    "ZIP_ENTRY_COUNT=$($filesForZip.Count)",
    "DCP_COPIES_INCLUDED=YES"
)
[System.IO.File]::WriteAllLines($sidecarPath, $sidecar, [System.Text.UTF8Encoding]::new($false))

Write-Output "EVIDENCE_PACKAGE_SHA256=$zipHash"
Write-Output "ZIP_ENTRY_COUNT=$($filesForZip.Count)"
Write-Output 'ZIP_INTEGRITY=PASS'
