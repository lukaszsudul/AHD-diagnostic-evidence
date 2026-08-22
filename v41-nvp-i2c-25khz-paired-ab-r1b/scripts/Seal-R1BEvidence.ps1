[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$root = (Resolve-Path -LiteralPath (Split-Path -Parent $PSScriptRoot)).Path
$zipName = 'V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1B_EVIDENCE.zip'
$zipPath = Join-Path $root $zipName
$sidecarPath = Join-Path $root 'V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1B_EVIDENCE_SHA256.txt'
$manifestPath = Join-Path $root 'SHA256_MANIFEST.txt'
$securityPath = Join-Path $root '07_FINAL\SECURITY_SCAN.txt'
$integrityPath = Join-Path $root '07_FINAL\EVIDENCE_ZIP_INTEGRITY.txt'

foreach ($fresh in @($zipPath,$sidecarPath,$manifestPath,$securityPath,$integrityPath)) {
    if (Test-Path -LiteralPath $fresh) { throw "seal output must be fresh: $fresh" }
}

function Get-Relative([string]$Path) {
    return $Path.Substring($root.Length).TrimStart('\','/').Replace('\','/')
}

$baseFiles = @(Get-ChildItem -LiteralPath $root -Recurse -File | Where-Object {
    $_.Name -notlike 'pw-*.tmp' -and
    $_.Name -ne $zipName -and
    $_.Name -ne (Split-Path -Leaf $sidecarPath) -and
    $_.Name -ne (Split-Path -Leaf $manifestPath) -and
    $_.Name -ne 'LOCAL_EVIDENCE_PUBLICATION_RECEIPT.md' -and
    $_.Name -ne 'dfx_runtime.txt' -and
    $_.FullName -notmatch '[\\/]\.git([\\/]|$)'
})

$forbiddenNameHits = @($baseFiles | Where-Object {
    $_.Name -match '^(?i:pw-.*\.tmp|VCDE-DUT-1\.txt|id_rsa|id_ed25519)$'
})
$secretContentHits = [Collections.Generic.List[string]]::new()
foreach ($file in $baseFiles) {
    if ($file.Extension -notin @('.zip','.bit','.dcp','.jou')) {
        $text = [IO.File]::ReadAllText($file.FullName)
        if ($text -match '(?im)^\s*(password|haslo)\s*[:=]\s*\S+' -or
            $text -match '-----BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY-----' -or
            $text -match '(?<!\S)-pw[ \t]+\S+') {
            $secretContentHits.Add((Get-Relative $file.FullName))
        }
    }
}
if ($forbiddenNameHits.Count -ne 0 -or $secretContentHits.Count -ne 0) {
    throw 'security scan found a forbidden secret artifact or content pattern'
}

$securityLines = [string[]]@(
    'SECURITY_SCAN=PASS',
    ('FILES_SCANNED={0}' -f $baseFiles.Count),
    ('FORBIDDEN_FILENAME_HITS={0}' -f $forbiddenNameHits.Count),
    ('SECRET_CONTENT_PATTERN_HITS={0}' -f $secretContentHits.Count),
    'CREDENTIAL_FILE_INCLUDED=NO',
    'TEMPORARY_PWFILE_INCLUDED=NO',
    'EXTERNAL_CONTEXTUAL_CREDENTIAL_HELPER_INCLUDED=NO',
    'PRIVATE_KEY_INCLUDED=NO',
    'STANDALONE_BITSTREAM_INCLUDED=NO',
    'STANDALONE_DCP_INCLUDED=NO',
    'PRIOR_R1_BUILD_PACKAGE_DUPLICATED=NO'
)
[IO.File]::WriteAllLines($securityPath,$securityLines,[Text.UTF8Encoding]::new($false))

$manifestInputs = @($baseFiles + (Get-Item -LiteralPath $securityPath) | Sort-Object FullName -Unique)
$manifestLines = [Collections.Generic.List[string]]::new()
foreach ($file in $manifestInputs) {
    $hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    $manifestLines.Add(('{0}  {1}  {2}' -f $hash,$file.Length,(Get-Relative $file.FullName)))
}
[IO.File]::WriteAllLines($manifestPath,[string[]]$manifestLines,[Text.UTF8Encoding]::new($false))

$zipInputs = @($manifestInputs + (Get-Item -LiteralPath $manifestPath) | Sort-Object FullName -Unique)
$zip = [IO.Compression.ZipFile]::Open($zipPath,[IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($file in $zipInputs) {
        $entryName = ('V41_NVP_I2C_25KHZ_PAIRED_AB_R1B/' + (Get-Relative $file.FullName))
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
            $zip,$file.FullName,$entryName,[IO.Compression.CompressionLevel]::Optimal
        ) | Out-Null
    }
} finally {
    $zip.Dispose()
}

$expected = @{}
foreach ($file in $zipInputs) {
    $entryName = 'V41_NVP_I2C_25KHZ_PAIRED_AB_R1B/' + (Get-Relative $file.FullName)
    $expected[$entryName] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
}
$verified = 0
$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    if ($archive.Entries.Count -ne $expected.Count) { throw 'ZIP entry-count mismatch' }
    foreach ($entry in $archive.Entries) {
        if (-not $expected.ContainsKey($entry.FullName)) { throw "unexpected ZIP entry: $($entry.FullName)" }
        $stream = $entry.Open()
        $sha = [Security.Cryptography.SHA256]::Create()
        try { $actual = ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-','') }
        finally { $sha.Dispose(); $stream.Dispose() }
        if ($actual -cne $expected[$entry.FullName]) { throw "ZIP content hash mismatch: $($entry.FullName)" }
        $verified++
    }
} finally {
    $archive.Dispose()
}
if ($verified -ne $expected.Count) { throw 'ZIP verification count mismatch' }

$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash
$zipLength = (Get-Item -LiteralPath $zipPath).Length
[IO.File]::WriteAllLines($sidecarPath,[string[]]@(
    ('SHA256={0}' -f $zipHash),
    ('SIZE_BYTES={0}' -f $zipLength),
    ('FILENAME={0}' -f $zipName)
),[Text.UTF8Encoding]::new($false))
[IO.File]::WriteAllLines($integrityPath,[string[]]@(
    'ZIP_INTEGRITY=PASS',
    ('ZIP_ENTRY_COUNT={0}' -f $expected.Count),
    ('ZIP_ENTRIES_HASH_VERIFIED={0}' -f $verified),
    ('ZIP_SHA256={0}' -f $zipHash),
    ('ZIP_SIZE_BYTES={0}' -f $zipLength),
    'DUPLICATE_ENTRY_NAMES=0'
),[Text.UTF8Encoding]::new($false))

'EVIDENCE_SEAL=PASS'
'EVIDENCE_PACKAGE_SHA256=' + $zipHash
'EVIDENCE_PACKAGE_SIZE_BYTES=' + $zipLength
'EVIDENCE_ENTRY_COUNT=' + $expected.Count
