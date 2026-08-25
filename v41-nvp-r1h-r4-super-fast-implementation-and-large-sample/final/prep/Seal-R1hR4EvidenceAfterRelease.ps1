[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$AuthoritativeReportSha256,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$IndependentFinalAuditSha256,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$AnalysisReleaseSha256,

    [string]$Root = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$expectedRoot = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST'
$manifestName = 'SHA256_MANIFEST.txt'
$zipName = 'V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE.zip'
$sidecarName = 'V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE_SHA256.txt'
$reportRelative = 'final/V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_AUTHORITATIVE_REPORT.md'
$auditRelative = 'final/R1H_R4_INDEPENDENT_FINAL_AUDIT.md'
$releaseRelative = 'final/R1H_R4_ANALYSIS_AND_CAMPAIGN_AUDIT_RELEASE.txt'

function Require([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Hash-Stream([IO.Stream]$Stream) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [Convert]::ToHexString($sha.ComputeHash($Stream)) }
    finally { $sha.Dispose() }
}

function Normalize-Relative([string]$FullPath, [string]$ResolvedRoot) {
    $full = [IO.Path]::GetFullPath($FullPath)
    Require ($full.StartsWith($ResolvedRoot + '\', [StringComparison]::OrdinalIgnoreCase)) "Path escaped task root: $full"
    return $full.Substring($ResolvedRoot.Length + 1).Replace('\', '/')
}

function Test-UnsafeRelative([string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($Relative) -or [IO.Path]::IsPathRooted($Relative)) { return $true }
    if ($Relative.Contains('\') -or $Relative.Contains('|') -or $Relative -match '[\x00-\x1F<>:"?*]') { return $true }
    foreach ($part in $Relative.Split('/')) {
        if ([string]::IsNullOrEmpty($part) -or $part -ceq '.' -or $part -ceq '..') { return $true }
        if ($part.EndsWith('.') -or $part.EndsWith(' ')) { return $true }
        if ($part.Split('.')[0] -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') { return $true }
    }
    return $false
}

$resolvedRoot = [IO.Path]::GetFullPath($Root).TrimEnd('\')
Require ($resolvedRoot -ceq $expectedRoot) "Unexpected task root: $resolvedRoot"
Require (Test-Path -LiteralPath $resolvedRoot -PathType Container) 'Task root is absent'

$reportPath = Join-Path $resolvedRoot $reportRelative.Replace('/', '\')
$auditPath = Join-Path $resolvedRoot $auditRelative.Replace('/', '\')
$releasePath = Join-Path $resolvedRoot $releaseRelative.Replace('/', '\')
Require (Test-Path -LiteralPath $reportPath -PathType Leaf) 'Authoritative report is absent'
Require (Test-Path -LiteralPath $auditPath -PathType Leaf) 'Independent final audit is absent'
Require (Test-Path -LiteralPath $releasePath -PathType Leaf) 'Analysis/campaign audit release is absent'
Require ((Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash -ceq $AuthoritativeReportSha256.ToUpperInvariant()) 'Authoritative report SHA-256 mismatch'
Require ((Get-FileHash -LiteralPath $auditPath -Algorithm SHA256).Hash -ceq $IndependentFinalAuditSha256.ToUpperInvariant()) 'Independent final audit SHA-256 mismatch'
Require ((Get-FileHash -LiteralPath $releasePath -Algorithm SHA256).Hash -ceq $AnalysisReleaseSha256.ToUpperInvariant()) 'Analysis/campaign release SHA-256 mismatch'

$releaseText = Get-Content -LiteralPath $releasePath -Raw
Require ($releaseText -match '(?m)^ANALYSIS_AND_CAMPAIGN_AUDIT_RELEASE=PASS\s*$') 'Analysis/campaign release does not authorize sealing'
$reportText = Get-Content -LiteralPath $reportPath -Raw
Require ($reportText -match '(?s)TASK=\s*\r?\n\s*V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE.*NEXT_ACTION=\s*\r?\n\s*OWNER_REVIEW_OF_THE_R1H_LARGE_SAMPLE_RESULT\s*(?:```)?\s*\z') 'Authoritative report does not end with the required R1h-R4 final block'

$manifestPath = Join-Path $resolvedRoot $manifestName
$zipPath = Join-Path $resolvedRoot $zipName
$sidecarPath = Join-Path $resolvedRoot $sidecarName
foreach ($output in @($manifestPath, $zipPath, $sidecarPath)) {
    Require (-not (Test-Path -LiteralPath $output)) "Seal output already exists: $output"
}

$rootItem = Get-Item -LiteralPath $resolvedRoot -Force
Require (-not ($rootItem.Attributes -band [IO.FileAttributes]::ReparsePoint)) 'Task root is a reparse point'
$allItems = @(Get-ChildItem -LiteralPath $resolvedRoot -Recurse -Force)
$reparse = @($allItems | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
Require ($reparse.Count -eq 0) "Reparse point count is $($reparse.Count), expected zero"

$nonDefaultAds = 0
foreach ($item in @($rootItem) + $allItems) {
    $streams = @(Get-Item -LiteralPath $item.FullName -Stream * -Force -ErrorAction Stop)
    $nonDefaultAds += @($streams | Where-Object Stream -ne ':$DATA').Count
}
Require ($nonDefaultAds -eq 0) "Non-default ADS count is $nonDefaultAds, expected zero"

$normalizedItemPaths = [Collections.Generic.List[string]]::new()
foreach ($item in $allItems) {
    $relative = Normalize-Relative $item.FullName $resolvedRoot
    Require (-not (Test-UnsafeRelative $relative)) "Unsafe task-root path: $relative"
    Require ($relative.Length -le 240) "Task-root relative path exceeds 240 characters: $relative"
    $normalizedItemPaths.Add($relative)
}
$itemCaseCollisions = @($normalizedItemPaths | Group-Object { $_.ToLowerInvariant() } | Where-Object Count -gt 1)
Require ($itemCaseCollisions.Count -eq 0) "Case-fold item-path collisions: $($itemCaseCollisions.Count)"

$files = @($allItems | Where-Object { -not $_.PSIsContainer })
Require ($files.Count -gt 0) 'No evidence input files found'
$hiddenSystem = @($files | Where-Object {
    ($_.Attributes -band [IO.FileAttributes]::Hidden) -or
    ($_.Attributes -band [IO.FileAttributes]::System)
})
Require ($hiddenSystem.Count -eq 0) "Hidden/system evidence files: $($hiddenSystem.Count)"

$rowsByPath = @{}
$sensitiveNames = [Collections.Generic.List[string]]::new()
foreach ($file in $files) {
    $relative = Normalize-Relative $file.FullName $resolvedRoot
    Require (-not (Test-UnsafeRelative $relative)) "Unsafe evidence-file path: $relative"
    Require ($relative.Length -le 240) "Evidence-file relative path exceeds 240 characters: $relative"
    foreach ($component in $relative.Split('/')) {
        if ($component -match '(?i)(^|[._-])(credential|credentials|password|passwd|private[_-]?key|id_rsa|id_ed25519|secrets?)([._-]|$)' -or
            $component -match '(?i)\.(pem|pfx|p12|key|kdbx|env)$') {
            $sensitiveNames.Add($relative)
            break
        }
    }
    Require (-not $rowsByPath.ContainsKey($relative)) "Duplicate evidence path: $relative"
    $rowsByPath[$relative] = [pscustomobject]@{
        Path = $relative
        FullPath = [IO.Path]::GetFullPath($file.FullName)
        Size = [int64]$file.Length
        Hash = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToUpperInvariant()
    }
}
Require ($sensitiveNames.Count -eq 0) "Sensitive filenames: $($sensitiveNames.Count)"

$pathKeys = [string[]]@($rowsByPath.Keys)
[Array]::Sort($pathKeys, [StringComparer]::Ordinal)
$rows = @($pathKeys | ForEach-Object { $rowsByPath[$_] })
Require (@($rows | Group-Object { $_.Path.ToLowerInvariant() } | Where-Object Count -gt 1).Count -eq 0) 'Case-fold evidence-file collision'

$secretPatterns = @(
    ('-----BEGIN ' + '(?:RSA |EC |DSA |OPENSSH )?' + 'PRIVATE KEY-----'),
    ('github_' + 'pat_[A-Za-z0-9_]{20,}'),
    ('gh' + '[pousr]_[A-Za-z0-9]{20,}'),
    ('sk' + '-(?:proj-)?[A-Za-z0-9_-]{20,}'),
    ('AK' + 'IA[0-9A-Z]{16}'),
    ('xo' + 'x[baprs]-[A-Za-z0-9-]{12,}'),
    ('(?i)Authoriz' + 'ation\s*:\s*Bearer\s+[A-Za-z0-9._~+\/-]{12,}'),
    ('(?i)https?://' + '[^\s/:@]+:[^\s/@]+@'),
    ('AI' + 'za[0-9A-Za-z_-]{35}'),
    ('gl' + 'pat-[0-9A-Za-z_-]{20,}'),
    ('npm' + '_[A-Za-z0-9]{30,}'),
    ('sk' + '_live_[0-9A-Za-z]{20,}')
)
$secretHits = [Collections.Generic.List[string]]::new()
$latin1 = [Text.Encoding]::GetEncoding(28591)
foreach ($row in $rows) {
    $text = $latin1.GetString([IO.File]::ReadAllBytes($row.FullPath))
    for ($index = 0; $index -lt $secretPatterns.Count; $index++) {
        if ([regex]::IsMatch($text, $secretPatterns[$index], [Text.RegularExpressions.RegexOptions]::CultureInvariant)) {
            $secretHits.Add("$($row.Path)|SIGNATURE_$($index + 1)")
        }
    }
}
Require ($secretHits.Count -eq 0) "High-confidence secret scan hits: $($secretHits.Count)"

# Detect concurrent or post-audit mutation immediately before writing outputs.
foreach ($row in $rows) {
    Require ((Get-Item -LiteralPath $row.FullPath).Length -eq $row.Size) "Input size changed during sealing audit: $($row.Path)"
    Require ((Get-FileHash -LiteralPath $row.FullPath -Algorithm SHA256).Hash -ceq $row.Hash) "Input hash changed during sealing audit: $($row.Path)"
}

$manifestLines = [Collections.Generic.List[string]]::new()
$manifestLines.Add('FORMAT=SHA256|SIZE_BYTES|TASK_ROOT_RELATIVE_PATH')
foreach ($row in $rows) { $manifestLines.Add("$($row.Hash)|$($row.Size)|$($row.Path)") }
$utf8NoBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText($manifestPath, ([string]::Join("`n", $manifestLines) + "`n"), $utf8NoBom)
$manifestBytes = [IO.File]::ReadAllBytes($manifestPath)
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToUpperInvariant()

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::Open($zipPath, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($row in $rows) {
        $entry = $archive.CreateEntry($row.Path, [IO.Compression.CompressionLevel]::Optimal)
        $entry.LastWriteTime = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
        $input = [IO.File]::OpenRead($row.FullPath)
        $output = $entry.Open()
        try { $input.CopyTo($output) }
        finally { $output.Dispose(); $input.Dispose() }
    }
    $manifestEntry = $archive.CreateEntry($manifestName, [IO.Compression.CompressionLevel]::Optimal)
    $manifestEntry.LastWriteTime = [DateTimeOffset]::new(2000, 1, 1, 0, 0, 0, [TimeSpan]::Zero)
    $output = $manifestEntry.Open()
    try { $output.Write($manifestBytes, 0, $manifestBytes.Length) }
    finally { $output.Dispose() }
}
finally { $archive.Dispose() }

$expected = @{}
foreach ($row in $rows) { $expected[$row.Path] = $row }
$expected[$manifestName] = [pscustomobject]@{ Path = $manifestName; Size = [int64]$manifestBytes.Length; Hash = $manifestHash }
$archive = [IO.Compression.ZipFile]::OpenRead($zipPath)
try {
    $entries = @($archive.Entries)
    Require ($entries.Count -eq $expected.Count) "ZIP entry count mismatch: $($entries.Count) != $($expected.Count)"
    Require (@($entries | Group-Object FullName | Where-Object Count -gt 1).Count -eq 0) 'Duplicate ZIP entries'
    Require (@($entries | Group-Object { $_.FullName.ToLowerInvariant() } | Where-Object Count -gt 1).Count -eq 0) 'Case-fold ZIP collision'
    foreach ($entry in $entries) {
        Require (-not (Test-UnsafeRelative $entry.FullName)) "Unsafe ZIP entry: $($entry.FullName)"
        Require ($expected.ContainsKey($entry.FullName)) "Unexpected ZIP entry: $($entry.FullName)"
        $want = $expected[$entry.FullName]
        Require ([int64]$entry.Length -eq $want.Size) "ZIP size mismatch: $($entry.FullName)"
        $stream = $entry.Open()
        try { $actualHash = Hash-Stream $stream }
        finally { $stream.Dispose() }
        Require ($actualHash -ceq $want.Hash) "ZIP hash mismatch: $($entry.FullName)"
    }
}
finally { $archive.Dispose() }

$zipItem = Get-Item -LiteralPath $zipPath
$zipHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToUpperInvariant()
$sidecarLines = @(
    "SHA256=$zipHash",
    "BYTES=$($zipItem.Length)",
    "FILE=$zipName",
    "MANIFEST_ROWS=$($rows.Count)",
    "ZIP_ENTRIES=$($rows.Count + 1)",
    'MANIFEST_SELF=INCLUDED_NONCIRCULAR',
    'ZIP_AND_SIDECAR=EXCLUDED_FROM_MANIFEST_AND_ZIP_INPUTS'
)
[IO.File]::WriteAllText($sidecarPath, ([string]::Join("`n", $sidecarLines) + "`n"), $utf8NoBom)

Require ((Get-FileHash -LiteralPath $reportPath -Algorithm SHA256).Hash -ceq $AuthoritativeReportSha256.ToUpperInvariant()) 'Report changed during sealing'
Require ((Get-FileHash -LiteralPath $auditPath -Algorithm SHA256).Hash -ceq $IndependentFinalAuditSha256.ToUpperInvariant()) 'Final audit changed during sealing'
Require ((Get-FileHash -LiteralPath $releasePath -Algorithm SHA256).Hash -ceq $AnalysisReleaseSha256.ToUpperInvariant()) 'Analysis release changed during sealing'
Require ((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash -ceq $zipHash) 'ZIP changed after sidecar creation'

Write-Output 'SEAL_RESULT=PASS'
Write-Output "INPUT_FILES=$($rows.Count)"
Write-Output "MANIFEST_ROWS=$($rows.Count)"
Write-Output "MANIFEST_SHA256=$manifestHash"
Write-Output "ZIP_ENTRIES=$($rows.Count + 1)"
Write-Output "ZIP_BYTES=$($zipItem.Length)"
Write-Output "ZIP_SHA256=$zipHash"
Write-Output "SIDECAR_SHA256=$((Get-FileHash -LiteralPath $sidecarPath -Algorithm SHA256).Hash.ToUpperInvariant())"
Write-Output 'REPARSE_POINTS=0'
Write-Output 'NONDEFAULT_ADS=0'
Write-Output 'CASEFOLD_COLLISIONS=0'
Write-Output 'UNSAFE_PATHS=0'
Write-Output 'SENSITIVE_FILENAMES=0'
Write-Output "SECRET_SIGNATURE_CLASSES=$($secretPatterns.Count)"
Write-Output 'HIGH_CONFIDENCE_SECRET_HITS=0'
Write-Output 'PUBLICATION_PERFORMED=NO'
