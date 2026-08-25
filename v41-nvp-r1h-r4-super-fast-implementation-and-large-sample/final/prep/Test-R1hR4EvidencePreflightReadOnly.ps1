[CmdletBinding()]
param(
    [string]$TaskRoot = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST',
    [string]$EvidenceRepo = 'C:\FPGA\EVIDENCE_WORKTREES\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1',
    [string]$TargetDirectoryName = 'v41-nvp-r1h-r4-super-fast-implementation-and-large-sample'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$expectedTaskRoot = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST'
$expectedRemote = 'https://github.com/lukaszsudul/AHD-diagnostic-evidence.git'
$zipName = 'V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE.zip'
$sidecarName = 'V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE_SHA256.txt'
$reportRelative = 'final/V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_AUTHORITATIVE_REPORT.md'
$analysisReleaseRelative = 'final/R1H_R4_ANALYSIS_AND_CAMPAIGN_AUDIT_RELEASE.txt'

function Require([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Normalize-Relative([string]$FullPath, [string]$ResolvedRoot) {
    $full = [IO.Path]::GetFullPath($FullPath)
    Require ($full.StartsWith($ResolvedRoot + '\', [StringComparison]::OrdinalIgnoreCase)) "Path escaped task root: $full"
    return $full.Substring($ResolvedRoot.Length + 1).Replace('\', '/')
}

function Test-UnsafeRelative([string]$Relative) {
    if ([string]::IsNullOrWhiteSpace($Relative)) { return $true }
    if ([IO.Path]::IsPathRooted($Relative)) { return $true }
    if ($Relative.Contains('\') -or $Relative.Contains('|')) { return $true }
    if ($Relative -match '[\x00-\x1F<>:"?*]') { return $true }
    foreach ($part in $Relative.Split('/')) {
        if ([string]::IsNullOrEmpty($part) -or $part -ceq '.' -or $part -ceq '..') { return $true }
        if ($part.EndsWith('.') -or $part.EndsWith(' ')) { return $true }
        if ($part.Split('.')[0] -match '^(?i:CON|PRN|AUX|NUL|COM[1-9]|LPT[1-9])$') { return $true }
    }
    return $false
}

function Invoke-Git([string[]]$Arguments) {
    $output = @(& git -C $EvidenceRepo @Arguments 2>&1)
    Require ($LASTEXITCODE -eq 0) "git $($Arguments -join ' ') failed: $($output -join ' ')"
    return $output
}

$resolvedTaskRoot = [IO.Path]::GetFullPath($TaskRoot).TrimEnd('\')
$resolvedRepo = [IO.Path]::GetFullPath($EvidenceRepo).TrimEnd('\')
Require ($resolvedTaskRoot -ceq $expectedTaskRoot) "Unexpected task root: $resolvedTaskRoot"
Require (Test-Path -LiteralPath $resolvedTaskRoot -PathType Container) 'Task root is absent'
Require (Test-Path -LiteralPath $resolvedRepo -PathType Container) 'Evidence worktree is absent'

$rootItem = Get-Item -LiteralPath $resolvedTaskRoot -Force
$allItems = @(Get-ChildItem -LiteralPath $resolvedTaskRoot -Recurse -Force)
$files = @($allItems | Where-Object { -not $_.PSIsContainer })
$directories = @($allItems | Where-Object PSIsContainer)
Require ($files.Count -gt 0) 'Task tree contains no files'

$reparse = @(@($rootItem) + $allItems | Where-Object { $_.Attributes -band [IO.FileAttributes]::ReparsePoint })
$nonDefaultAds = 0
foreach ($item in @($rootItem) + $allItems) {
    $streams = @(Get-Item -LiteralPath $item.FullName -Stream * -Force -ErrorAction Stop)
    $nonDefaultAds += @($streams | Where-Object Stream -ne ':$DATA').Count
}

$relativeItems = [System.Collections.Generic.List[string]]::new()
$unsafePaths = [System.Collections.Generic.List[string]]::new()
$overlongPaths = [System.Collections.Generic.List[string]]::new()
$sensitiveNames = [System.Collections.Generic.List[string]]::new()
foreach ($item in $allItems) {
    $relative = Normalize-Relative $item.FullName $resolvedTaskRoot
    $relativeItems.Add($relative)
    if (Test-UnsafeRelative $relative) { $unsafePaths.Add($relative) }
    if ($relative.Length -gt 240) { $overlongPaths.Add($relative) }
    foreach ($component in $relative.Split('/')) {
        if ($component -match '(?i)(^|[._-])(credential|credentials|password|passwd|private[_-]?key|id_rsa|id_ed25519|secrets?)([._-]|$)' -or
            $component -match '(?i)\.(pem|pfx|p12|key|kdbx|env)$') {
            $sensitiveNames.Add($relative)
            break
        }
    }
}
$casefoldCollisions = @($relativeItems | Group-Object { $_.ToLowerInvariant() } | Where-Object Count -gt 1)

# Construct high-confidence signatures from fragments so this scanner does not
# self-match its own source.
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
$secretHits = [System.Collections.Generic.List[string]]::new()
$latin1 = [Text.Encoding]::GetEncoding(28591)
foreach ($file in $files) {
    $relative = Normalize-Relative $file.FullName $resolvedTaskRoot
    $text = $latin1.GetString([IO.File]::ReadAllBytes($file.FullName))
    for ($index = 0; $index -lt $secretPatterns.Count; $index++) {
        if ([regex]::IsMatch($text, $secretPatterns[$index], [Text.RegularExpressions.RegexOptions]::CultureInvariant)) {
            $secretHits.Add("$relative|SIGNATURE_$($index + 1)")
        }
    }
}

$repoTop = (Invoke-Git @('rev-parse', '--show-toplevel') | Select-Object -Last 1).Trim().Replace('/', '\')
Require ([IO.Path]::GetFullPath($repoTop).TrimEnd('\') -ieq $resolvedRepo) 'Evidence repository top mismatch'
$repoHead = (Invoke-Git @('rev-parse', 'HEAD') | Select-Object -Last 1).Trim()
$repoTree = (Invoke-Git @('rev-parse', 'HEAD^{tree}') | Select-Object -Last 1).Trim()
$repoBranch = (Invoke-Git @('branch', '--show-current') | Select-Object -Last 1).Trim()
$repoStatus = @(Invoke-Git @('status', '--porcelain=v1'))
$remoteUrl = (Invoke-Git @('remote', 'get-url', 'origin') | Select-Object -Last 1).Trim()
$remoteLine = (Invoke-Git @('ls-remote', '--exit-code', 'origin', 'refs/heads/main') | Select-Object -Last 1).Trim()
$remoteMain = ($remoteLine -split '\s+')[0]
$targetPath = Join-Path $resolvedRepo $TargetDirectoryName
$trackedTopDirectories = @(Invoke-Git @('ls-tree', '-d', '--name-only', 'HEAD'))
$targetCollision = @($trackedTopDirectories | Where-Object { $_ -ieq $TargetDirectoryName }).Count -ne 0 -or (Test-Path -LiteralPath $targetPath)

$zipRepoRelative = "$TargetDirectoryName/$zipName"
$synthDcpRepoRelative = "$TargetDirectoryName/raw/R1H_synth.dcp"
$routedDcpRepoRelative = "$TargetDirectoryName/implementation/R1H_routed.dcp"
$bitRepoRelative = "$TargetDirectoryName/implementation/ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit"
function Get-FilterAttribute([string]$Path) {
    $line = (Invoke-Git @('check-attr', 'filter', '--', $Path) | Select-Object -Last 1)
    return (($line -split ':', 3)[2]).Trim()
}
$zipFilter = Get-FilterAttribute $zipRepoRelative
$synthDcpFilter = Get-FilterAttribute $synthDcpRepoRelative
$routedDcpFilter = Get-FilterAttribute $routedDcpRepoRelative
$bitFilter = Get-FilterAttribute $bitRepoRelative
$lfsVersion = (& git -C $resolvedRepo lfs version 2>&1 | Select-Object -Last 1).ToString().Trim()
Require ($LASTEXITCODE -eq 0) 'git-lfs is unavailable'

$reportExists = Test-Path -LiteralPath (Join-Path $resolvedTaskRoot $reportRelative.Replace('/', '\')) -PathType Leaf
$analysisReleaseExists = Test-Path -LiteralPath (Join-Path $resolvedTaskRoot $analysisReleaseRelative.Replace('/', '\')) -PathType Leaf
$manifestExists = Test-Path -LiteralPath (Join-Path $resolvedTaskRoot 'SHA256_MANIFEST.txt')
$zipExists = Test-Path -LiteralPath (Join-Path $resolvedTaskRoot $zipName)
$sidecarExists = Test-Path -LiteralPath (Join-Path $resolvedTaskRoot $sidecarName)
$totalBytes = [int64](($files | Measure-Object Length -Sum).Sum)
$maxRelativeLength = ($relativeItems | Measure-Object Length -Maximum).Maximum

Require ($reparse.Count -eq 0) "Reparse point count is $($reparse.Count)"
Require ($nonDefaultAds -eq 0) "Non-default ADS count is $nonDefaultAds"
Require ($unsafePaths.Count -eq 0) "Unsafe relative-path count is $($unsafePaths.Count)"
Require ($overlongPaths.Count -eq 0) "Overlong relative-path count is $($overlongPaths.Count)"
Require ($casefoldCollisions.Count -eq 0) "Casefold collision groups: $($casefoldCollisions.Count)"
Require ($sensitiveNames.Count -eq 0) "Sensitive filename count is $($sensitiveNames.Count)"
Require ($secretHits.Count -eq 0) "High-confidence secret scan hits: $($secretHits.Count)"
Require ($repoStatus.Count -eq 0) 'Evidence worktree is not clean'
Require ($repoBranch -ceq 'main') "Evidence worktree branch is $repoBranch, expected main"
Require ($remoteUrl -ceq $expectedRemote) "Evidence origin URL mismatch: $remoteUrl"
Require ($repoHead -ceq $remoteMain) "Local/remote main mismatch: $repoHead != $remoteMain"
Require (-not $targetCollision) "Evidence target path collision: $TargetDirectoryName"
Require (-not $manifestExists -and -not $zipExists -and -not $sidecarExists) 'Seal output exists before authorized sealing'

Write-Output 'READ_ONLY_PREPUBLICATION_AUDIT=PASS_PREP_STAGE'
Write-Output "AUDIT_UTC=$([DateTime]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ'))"
Write-Output "TASK_ROOT=$resolvedTaskRoot"
Write-Output "TASK_TREE_FILES=$($files.Count)"
Write-Output "TASK_TREE_DIRECTORIES=$($directories.Count)"
Write-Output "TASK_TREE_BYTES=$totalBytes"
Write-Output "MAX_RELATIVE_PATH_LENGTH=$maxRelativeLength"
Write-Output 'REPARSE_POINTS=0'
Write-Output 'NONDEFAULT_ADS=0'
Write-Output 'UNSAFE_PATHS=0'
Write-Output 'OVERLONG_PATHS=0'
Write-Output 'CASEFOLD_COLLISION_GROUPS=0'
Write-Output 'SENSITIVE_FILENAMES=0'
Write-Output "SECRET_SIGNATURE_CLASSES=$($secretPatterns.Count)"
Write-Output 'HIGH_CONFIDENCE_SECRET_HITS=0'
Write-Output "AUTHORITATIVE_REPORT_EXISTS=$($reportExists.ToString().ToUpperInvariant())"
Write-Output "ANALYSIS_RELEASE_EXISTS=$($analysisReleaseExists.ToString().ToUpperInvariant())"
Write-Output "SEAL_OUTPUTS_EXIST=$((($manifestExists -or $zipExists -or $sidecarExists)).ToString().ToUpperInvariant())"
Write-Output "EVIDENCE_REPO=$resolvedRepo"
Write-Output "EVIDENCE_REPO_HEAD=$repoHead"
Write-Output "EVIDENCE_REPO_TREE=$repoTree"
Write-Output "EVIDENCE_REPO_REMOTE_MAIN=$remoteMain"
Write-Output "EVIDENCE_REPO_REMOTE=$remoteUrl"
Write-Output 'EVIDENCE_REPO_CLEAN=YES'
Write-Output 'EVIDENCE_TARGET_COLLISION=NO'
Write-Output "EVIDENCE_TARGET_DIRECTORY=$TargetDirectoryName"
Write-Output "GIT_LFS_VERSION=$lfsVersion"
Write-Output "CURRENT_ZIP_FILTER=$zipFilter"
Write-Output "CURRENT_SYNTH_DCP_FILTER=$synthDcpFilter"
Write-Output "CURRENT_ROUTED_DCP_FILTER=$routedDcpFilter"
Write-Output "CURRENT_BIT_FILTER=$bitFilter"
Write-Output "LFS_ATTRIBUTE_UPDATE_REQUIRED=$((($zipFilter -cne 'lfs' -or $synthDcpFilter -cne 'lfs' -or $routedDcpFilter -cne 'lfs')).ToString().ToUpperInvariant())"
Write-Output "READY_TO_SEAL=$((($reportExists -and $analysisReleaseExists)).ToString().ToUpperInvariant())"
Write-Output 'REPOSITORY_MUTATIONS=0'
Write-Output 'PACKAGE_CREATED=NO'
Write-Output 'PUBLICATION_PERFORMED=NO'
