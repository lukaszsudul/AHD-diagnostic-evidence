[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$EvidenceRoot = (Split-Path -Parent $PSScriptRoot)
)

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path -LiteralPath $EvidenceRoot).Path
$zipName = 'V41_NVP_R1I_R2_QUALIFIED_POC_HARDWARE_EVIDENCE.zip'
$receiptName = 'V41_NVP_R1I_R2_QUALIFIED_POC_HARDWARE_EVIDENCE_SHA256.txt'
$manifestName = 'SHA256_MANIFEST.txt'
$zipPath = Join-Path $root $zipName
$receiptPath = Join-Path $root $receiptName
$manifestPath = Join-Path $root $manifestName

if (Test-Path -LiteralPath $zipPath) { throw "Refusing to overwrite: $zipPath" }
if (Test-Path -LiteralPath $receiptPath) { throw "Refusing to overwrite: $receiptPath" }

$payloadFiles = Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.FullName -ne $manifestPath -and
    $_.FullName -ne $zipPath -and
    $_.FullName -ne $receiptPath
} | Sort-Object FullName

$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# SHA-256 manifest for the public package payload.')
$lines.Add('# Format: SHA256<two spaces>SIZE_BYTES<two spaces>RELATIVE_PATH')
$lines.Add('# Excludes this self-hashing manifest, the outer ZIP, and its external SHA receipt.')
foreach ($file in $payloadFiles) {
    $relative = [IO.Path]::GetRelativePath($root, $file.FullName).Replace([IO.Path]::DirectorySeparatorChar, '/')
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    $lines.Add("$hash  $($file.Length)  $relative")
}
[IO.File]::WriteAllLines($manifestPath, $lines, [Text.UTF8Encoding]::new($false))

$parent = Split-Path -Parent $root
$temporaryZip = Join-Path $parent ($zipName + '.sealing')
if (Test-Path -LiteralPath $temporaryZip) { throw "Refusing to overwrite: $temporaryZip" }

Add-Type -AssemblyName System.IO.Compression.FileSystem
[IO.Compression.ZipFile]::CreateFromDirectory(
    $root,
    $temporaryZip,
    [IO.Compression.CompressionLevel]::Optimal,
    $false
)
Move-Item -LiteralPath $temporaryZip -Destination $zipPath

$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
$receipt = @(
    "SHA256=$zipHash",
    "SIZE_BYTES=$((Get-Item -LiteralPath $zipPath).Length)",
    "FILE=$zipName",
    'PACKAGE_SCOPE=ALL_PUBLIC_PAYLOAD_FILES_PLUS_INTERNAL_MANIFEST',
    'EXTERNAL_RECEIPT_EXCLUDED_FROM_ZIP=YES_SELF_HASH_RECURSION_AVOIDED'
)
[IO.File]::WriteAllLines($receiptPath, $receipt, [Text.UTF8Encoding]::new($false))

$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $fileEntries = @($archive.Entries | Where-Object { -not $_.FullName.EndsWith('/') })
    $directoryEntries = @($archive.Entries | Where-Object { $_.FullName.EndsWith('/') })
    $expectedFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
        $_.FullName -ne $zipPath -and $_.FullName -ne $receiptPath
    })
    if ($fileEntries.Count -ne $expectedFiles.Count) {
        throw "ZIP file count mismatch: $($fileEntries.Count) vs $($expectedFiles.Count)"
    }
    "PUBLIC_ZIP=PASS"
    "ZIP_SHA256=$zipHash"
    "EXPECTED_FILES=$($expectedFiles.Count)"
    "ZIP_FILE_ENTRIES=$($fileEntries.Count)"
    "ZIP_DIRECTORY_ENTRIES=$($directoryEntries.Count)"
} finally {
    $archive.Dispose()
}
