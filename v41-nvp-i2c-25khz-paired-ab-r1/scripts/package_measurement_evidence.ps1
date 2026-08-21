param(
    [Parameter(Mandatory = $true)]
    [string]$TaskRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$expectedLeaf = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1'
$root = [IO.Path]::GetFullPath($TaskRoot).TrimEnd('\')
if ((Split-Path -Leaf $root) -cne $expectedLeaf) {
    throw "Unexpected task root: $root"
}

$zipName = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1_MEASUREMENT_EVIDENCE.zip'
$sidecarName = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1_MEASUREMENT_PACKAGE_SHA256.txt'
$integrityName = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1_MEASUREMENT_PACKAGE_INTEGRITY.txt'
$manifestName = 'SHA256_MANIFEST.txt'
$contentsRelative = '09_FINAL\MEASUREMENT_PACKAGE_CONTENTS.txt'
$zipPath = Join-Path $root $zipName
$sidecarPath = Join-Path $root $sidecarName
$integrityPath = Join-Path $root $integrityName
$manifestPath = Join-Path $root $manifestName
$contentsPath = Join-Path $root $contentsRelative

foreach ($output in @($zipPath, $sidecarPath, $integrityPath, $manifestPath, $contentsPath)) {
    if (Test-Path -LiteralPath $output) {
        throw "Refusing to overwrite existing sealed output: $output"
    }
}

function Get-RelativePathNormalized {
    param([Parameter(Mandatory = $true)][string]$Path)
    $relative = [IO.Path]::GetRelativePath($root, [IO.Path]::GetFullPath($Path))
    return $relative.Replace('/', '\')
}

function Test-ExcludedRelativePath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $r = $RelativePath.Replace('/', '\')
    if ($r -match '(^|\\)\.git($|\\)') { return $true }
    if ($r -like 'worktree\*') { return $true }
    if ($r -like '04_BUILD\FULL_BUILD_ROOT\*') { return $true }
    if ($r -like '04_BUILD\BUILD_PACKAGE_STAGING\*') { return $true }
    if ($r -ieq $zipName -or $r -ieq $sidecarName -or
        $r -ieq $integrityName -or $r -ieq $manifestName) { return $true }
    if ($r -ieq 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1_BUILD_PACKAGE.zip') { return $true }
    if ($r -ieq '05_HARDWARE_PRECHECK\SECRET_CHANNEL\Invoke-ContextualPlink.ps1') { return $true }
    if ($r -match '(?i)(^|\\)pw-[0-9a-f]+\.tmp$') { return $true }
    if ($r -match '(?i)(^|\\)VCDE-DUT-1\.txt$') { return $true }
    if ([IO.Path]::GetExtension($r) -in @('.dcp', '.bit')) { return $true }
    return $false
}

$contents = @'
TASK=V41_NVP_I2C_25KHZ_PAIRED_AB_R1
PACKAGE_ROLE=MEASUREMENT_AND_SCIENTIFIC_EVIDENCE

INCLUDED=
  exact task prompt and owner experiment statement
  source identities and the exact one-line source diff
  numerical model, simulation scripts, testbenches, logs, and CSVs
  build launcher, verifier, log, journal, route/timing/DRC/CDC reports
  accepted REQP-1839 baseline reference and new-build comparison
  routed-DCP report-only audit outputs
  hardware precheck, Arm-A fail-closed evidence, formal restoration evidence
  comparison, operation/time ledgers, and final Markdown report
  SHA256_MANIFEST.txt

EXCLUDED=
  worktree and Git metadata
  transient Vivado project/build root
  duplicate build-package staging directory
  standalone DCP and bit files
  V41_NVP_I2C_25KHZ_PAIRED_AB_R1_BUILD_PACKAGE.zip
  credentials and temporary password files
  credential-handling helper source (hash, audit, and sanitized logs retained)
  this measurement ZIP, its external SHA-256 sidecar, and integrity report

BUILD_PACKAGE_SEPARATE=YES
BUILD_PACKAGE_FILENAME=V41_NVP_I2C_25KHZ_PAIRED_AB_R1_BUILD_PACKAGE.zip
BUILD_PACKAGE_SIZE_BYTES=88970399
BUILD_PACKAGE_SHA256=918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A
BUILD_PACKAGE_PUBLICATION_METHOD=GIT_LFS_EXACT_PATH

SELF_REFERENCE_POLICY=
  The measurement package SHA-256 and evidence commit cannot be embedded in
  the archive that determines them. They are recorded in external sidecar and
  post-publication receipt files.
'@
[IO.File]::WriteAllText($contentsPath, $contents.TrimStart() + "`r`n", [Text.UTF8Encoding]::new($false))

$sourceFiles = [Collections.Generic.List[IO.FileInfo]]::new()
foreach ($file in Get-ChildItem -LiteralPath $root -Recurse -File -Force) {
    $relative = Get-RelativePathNormalized -Path $file.FullName
    if (-not (Test-ExcludedRelativePath -RelativePath $relative)) {
        $sourceFiles.Add($file)
    }
}
$sourceFiles = @($sourceFiles | Sort-Object { Get-RelativePathNormalized -Path $_.FullName })
if ($sourceFiles.Count -lt 100) {
    throw "Unexpectedly small evidence set: $($sourceFiles.Count) files"
}

$forbiddenNames = @($sourceFiles | Where-Object {
    $r = Get-RelativePathNormalized -Path $_.FullName
    $r -match '(?i)(^|\\)(VCDE-DUT-1\.txt|pw-[0-9a-f]+\.tmp)$' -or
    $r -match '(^|\\)\.git($|\\)' -or
    $_.Extension -in @('.dcp', '.bit') -or
    $_.Name -ieq 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1_BUILD_PACKAGE.zip'
})
if ($forbiddenNames.Count -ne 0) {
    throw "Forbidden evidence files selected: $($forbiddenNames.FullName -join '; ')"
}

$pemHits = [Collections.Generic.List[string]]::new()
$inferableCredentialHits = [Collections.Generic.List[string]]::new()
foreach ($file in $sourceFiles | Where-Object Length -lt 10000000) {
    $bytes = [IO.File]::ReadAllBytes($file.FullName)
    $text = [Text.Encoding]::UTF8.GetString($bytes)
    if ($text -match '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----') {
        $pemHits.Add($file.FullName)
    }
    if ($text -match '(?i)username/password\s+collision|fields\.user\s+-cne\s+\$password') {
        $inferableCredentialHits.Add($file.FullName)
    }
}
if ($pemHits.Count -ne 0) {
    throw "Private-key material detected: $($pemHits -join '; ')"
}
if ($inferableCredentialHits.Count -ne 0) {
    throw "Inferable credential relationship detected: $($inferableCredentialHits -join '; ')"
}

$records = [Collections.Generic.List[object]]::new()
foreach ($file in $sourceFiles) {
    $relative = Get-RelativePathNormalized -Path $file.FullName
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $file.FullName).Hash.ToUpperInvariant()
    $records.Add([pscustomobject]@{
        RelativePath = $relative
        FullName = $file.FullName
        Length = [int64]$file.Length
        Hash = $hash
    })
}

$manifestLines = [Collections.Generic.List[string]]::new()
$manifestLines.Add('SHA256  SIZE_BYTES  RELATIVE_PATH')
foreach ($record in $records) {
    $manifestLines.Add(('{0}  {1}  {2}' -f $record.Hash, $record.Length, $record.RelativePath))
}
[IO.File]::WriteAllLines($manifestPath, $manifestLines, [Text.UTF8Encoding]::new($false))

$manifestFile = Get-Item -LiteralPath $manifestPath
$manifestRecord = [pscustomobject]@{
    RelativePath = $manifestName
    FullName = $manifestFile.FullName
    Length = [int64]$manifestFile.Length
    Hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $manifestPath).Hash.ToUpperInvariant()
}
$archiveRecords = @($records) + @($manifestRecord)

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($record in $archiveRecords | Sort-Object RelativePath) {
        $currentHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $record.FullName).Hash.ToUpperInvariant()
        if ($currentHash -cne $record.Hash) {
            throw "Source changed while sealing: $($record.RelativePath)"
        }
        $entryName = ($expectedLeaf + '/' + $record.RelativePath.Replace('\', '/'))
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $archive,
            $record.FullName,
            $entryName,
            [IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
}
finally {
    $archive.Dispose()
}

$expectedByEntry = @{}
foreach ($record in $archiveRecords) {
    $entryName = ($expectedLeaf + '/' + $record.RelativePath.Replace('\', '/'))
    $expectedByEntry[$entryName] = $record
}

$verified = 0
$zipRead = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $names = @($zipRead.Entries | ForEach-Object FullName)
    $duplicates = @($names | Group-Object | Where-Object Count -ne 1)
    if ($duplicates.Count -ne 0) {
        throw "Duplicate archive entries: $($duplicates.Name -join '; ')"
    }
    if ($names.Count -ne $expectedByEntry.Count) {
        throw "Archive entry count mismatch: $($names.Count) != $($expectedByEntry.Count)"
    }
    foreach ($entry in $zipRead.Entries) {
        if (-not $expectedByEntry.ContainsKey($entry.FullName)) {
            throw "Unexpected archive entry: $($entry.FullName)"
        }
        $expected = $expectedByEntry[$entry.FullName]
        if ([int64]$entry.Length -ne [int64]$expected.Length) {
            throw "Archive size mismatch: $($entry.FullName)"
        }
        $stream = $entry.Open()
        try {
            $sha = [Security.Cryptography.SHA256]::Create()
            try {
                $actualHash = [Convert]::ToHexString($sha.ComputeHash($stream))
            }
            finally {
                $sha.Dispose()
            }
        }
        finally {
            $stream.Dispose()
        }
        if ($actualHash -cne $expected.Hash) {
            throw "Archive hash mismatch: $($entry.FullName)"
        }
        $verified++
    }
}
finally {
    $zipRead.Dispose()
}

$zipInfo = Get-Item -LiteralPath $zipPath
$zipHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $zipPath).Hash.ToUpperInvariant()
[IO.File]::WriteAllText(
    $sidecarPath,
    "$zipHash *$zipName`r`n",
    [Text.UTF8Encoding]::new($false)
)

$includedBytes = [int64](($archiveRecords | Measure-Object Length -Sum).Sum)
$integrity = @(
    'TASK=V41_NVP_I2C_25KHZ_PAIRED_AB_R1',
    'PACKAGE_ROLE=MEASUREMENT_AND_SCIENTIFIC_EVIDENCE',
    "PACKAGE_FILENAME=$zipName",
    "PACKAGE_SIZE_BYTES=$($zipInfo.Length)",
    "PACKAGE_SHA256=$zipHash",
    "ARCHIVE_ENTRY_COUNT=$($archiveRecords.Count)",
    "ARCHIVE_ENTRIES_HASH_VERIFIED=$verified",
    "ARCHIVE_DUPLICATE_ENTRY_COUNT=0",
    "UNCOMPRESSED_INCLUDED_BYTES=$includedBytes",
    "SOURCE_MANIFEST_FILENAME=$manifestName",
    "SOURCE_MANIFEST_SHA256=$($manifestRecord.Hash)",
    'BUILD_PACKAGE_NESTED=NO',
    'DCP_OR_BIT_NESTED=NO',
    'GIT_METADATA_NESTED=NO',
    'CREDENTIAL_OR_TEMP_PWFILE_NESTED=NO',
    'CREDENTIAL_HANDLING_HELPER_SOURCE_NESTED=NO',
    'PRIVATE_KEY_MARKER_SCAN=PASS',
    'INFERABLE_CREDENTIAL_PATTERN_SCAN=PASS',
    'ZIP_INTEGRITY=PASS'
)
[IO.File]::WriteAllLines($integrityPath, $integrity, [Text.UTF8Encoding]::new($false))

Write-Output "PACKAGE_PATH=$zipPath"
Write-Output "PACKAGE_SIZE_BYTES=$($zipInfo.Length)"
Write-Output "PACKAGE_SHA256=$zipHash"
Write-Output "ARCHIVE_ENTRY_COUNT=$($archiveRecords.Count)"
Write-Output "ARCHIVE_ENTRIES_HASH_VERIFIED=$verified"
Write-Output "SOURCE_MANIFEST_SHA256=$($manifestRecord.Hash)"
Write-Output 'ZIP_INTEGRITY=PASS'
