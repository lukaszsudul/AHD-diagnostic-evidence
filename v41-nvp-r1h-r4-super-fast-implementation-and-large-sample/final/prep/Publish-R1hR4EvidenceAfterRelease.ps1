[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [switch]$ExecuteAfterRelease,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{40}$')]
    [string]$ExpectedRemoteMain,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedEvidenceZipSha256,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$AnalysisReleaseSha256,

    [string]$TaskRoot = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST',
    [string]$EvidenceRepo = 'C:\FPGA\EVIDENCE_WORKTREES\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$targetName = 'v41-nvp-r1h-r4-super-fast-implementation-and-large-sample'
$expectedRemoteUrl = 'https://github.com/lukaszsudul/AHD-diagnostic-evidence.git'
$zipName = 'V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE.zip'
$sidecarName = 'V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_EVIDENCE_SHA256.txt'
$releaseRelative = 'final\R1H_R4_ANALYSIS_AND_CAMPAIGN_AUDIT_RELEASE.txt'
$commitMessage = 'Publish R1h-R4 super-fast implementation and large-sample evidence'

function Require([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw $Message }
}

function Invoke-Git([string[]]$Arguments) {
    $output = @(& git -C $EvidenceRepo @Arguments 2>&1)
    Require ($LASTEXITCODE -eq 0) "git $($Arguments -join ' ') failed: $($output -join ' ')"
    return $output
}

Require ($ExecuteAfterRelease.IsPresent) 'Explicit -ExecuteAfterRelease switch is required'
$task = [IO.Path]::GetFullPath($TaskRoot).TrimEnd('\')
$repo = [IO.Path]::GetFullPath($EvidenceRepo).TrimEnd('\')
Require ($task -ceq 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST') "Unexpected task root: $task"
Require (Test-Path -LiteralPath $task -PathType Container) 'Task root is absent'
Require (Test-Path -LiteralPath $repo -PathType Container) 'Evidence repository is absent'

$zipPath = Join-Path $task $zipName
$sidecarPath = Join-Path $task $sidecarName
$manifestPath = Join-Path $task 'SHA256_MANIFEST.txt'
$releasePath = Join-Path $task $releaseRelative
foreach ($path in @($zipPath, $sidecarPath, $manifestPath, $releasePath)) {
    Require (Test-Path -LiteralPath $path -PathType Leaf) "Required sealed evidence file is absent: $path"
}
Require ((Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash -ceq $ExpectedEvidenceZipSha256.ToUpperInvariant()) 'Evidence ZIP SHA-256 mismatch'
Require ((Get-FileHash -LiteralPath $releasePath -Algorithm SHA256).Hash -ceq $AnalysisReleaseSha256.ToUpperInvariant()) 'Analysis release SHA-256 mismatch'
$releaseText = Get-Content -LiteralPath $releasePath -Raw
Require ($releaseText -match '(?m)^ANALYSIS_AND_CAMPAIGN_AUDIT_RELEASE=PASS\s*$') 'Analysis release is not PASS'
$sidecarText = Get-Content -LiteralPath $sidecarPath -Raw
Require ($sidecarText -match "(?m)^SHA256=$($ExpectedEvidenceZipSha256.ToUpperInvariant())\s*$") 'Evidence ZIP sidecar mismatch'

$repoTop = (Invoke-Git @('rev-parse', '--show-toplevel') | Select-Object -Last 1).Trim().Replace('/', '\')
Require ([IO.Path]::GetFullPath($repoTop).TrimEnd('\') -ieq $repo) 'Evidence repository top mismatch'
$repoHead = (Invoke-Git @('rev-parse', 'HEAD') | Select-Object -Last 1).Trim()
$branch = (Invoke-Git @('branch', '--show-current') | Select-Object -Last 1).Trim()
$status = @(Invoke-Git @('status', '--porcelain=v1'))
$remoteUrl = (Invoke-Git @('remote', 'get-url', 'origin') | Select-Object -Last 1).Trim()
$remoteLine = (Invoke-Git @('ls-remote', '--exit-code', 'origin', 'refs/heads/main') | Select-Object -Last 1).Trim()
$remoteMain = ($remoteLine -split '\s+')[0]
Require ($branch -ceq 'main') "Evidence branch is $branch, expected main"
Require ($status.Count -eq 0) 'Evidence worktree is not clean'
Require ($remoteUrl -ceq $expectedRemoteUrl) "Evidence origin URL mismatch: $remoteUrl"
Require ($repoHead -ceq $ExpectedRemoteMain.ToLowerInvariant()) 'Local main differs from authorized expected base'
Require ($remoteMain -ceq $ExpectedRemoteMain.ToLowerInvariant()) 'Remote main differs from authorized expected base'

$target = Join-Path $repo $targetName
Require (-not (Test-Path -LiteralPath $target)) "Evidence target path already exists: $target"
$trackedTop = @(Invoke-Git @('ls-tree', '-d', '--name-only', 'HEAD'))
Require (@($trackedTop | Where-Object { $_ -ieq $targetName }).Count -eq 0) 'Case-insensitive target path collision in HEAD'

# Mechanical staging begins only after every release/remote/identity gate above.
Copy-Item -LiteralPath $task -Destination $target -Recurse -Force:$false
Require (Test-Path -LiteralPath (Join-Path $target $zipName) -PathType Leaf) 'Target copy is incomplete'
Require ((Get-FileHash -LiteralPath (Join-Path $target $zipName) -Algorithm SHA256).Hash -ceq $ExpectedEvidenceZipSha256.ToUpperInvariant()) 'Copied ZIP SHA-256 mismatch'

$attributesPath = Join-Path $repo '.gitattributes'
Require (Test-Path -LiteralPath $attributesPath -PathType Leaf) 'Repository .gitattributes is absent'
$attributeLines = @(
    "$targetName/$zipName filter=lfs diff=lfs merge=lfs -text",
    "$targetName/**/*.dcp filter=lfs diff=lfs merge=lfs -text",
    "$targetName/**/*.bit filter=lfs diff=lfs merge=lfs -text"
)
$attributeText = Get-Content -LiteralPath $attributesPath -Raw
foreach ($line in $attributeLines) {
    Require ($attributeText -notmatch "(?m)^$([regex]::Escape($line))\s*$") "LFS attribute already existed unexpectedly: $line"
}
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$newAttributeText = $attributeText.TrimEnd("`r", "`n") + "`n" + ([string]::Join("`n", $attributeLines)) + "`n"
[IO.File]::WriteAllText($attributesPath, $newAttributeText, $utf8NoBom)

Invoke-Git @('add', '--', '.gitattributes', $targetName) | Out-Null
$stagedNames = @(Invoke-Git @('diff', '--cached', '--name-only'))
Require ($stagedNames.Count -gt 4) 'Staged evidence set is unexpectedly small'
Require (@($stagedNames | Where-Object { $_ -ne '.gitattributes' -and -not $_.StartsWith("$targetName/") }).Count -eq 0) 'Staged path escaped the authorized target'

$largePaths = @(
    "$targetName/$zipName",
    "$targetName/raw/R1H_synth.dcp",
    "$targetName/implementation/R1H_routed.dcp",
    "$targetName/implementation/ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit"
)
foreach ($path in $largePaths) {
    $attr = (Invoke-Git @('check-attr', 'filter', '--', $path) | Select-Object -Last 1)
    Require ($attr -match ': filter: lfs\s*$') "LFS filter is absent for $path"
    $indexText = [string]::Join("`n", @(Invoke-Git @('show', ":$path")))
    # The staged form must be an LFS pointer, never the large object itself.
    Require ($indexText -match '^version https://git-lfs.github.com/spec/v1') "Staged large artifact is not an LFS pointer: $path"
}

Invoke-Git @('commit', '-m', $commitMessage) | Out-Null
$evidenceCommit = (Invoke-Git @('rev-parse', 'HEAD') | Select-Object -Last 1).Trim()
Require ($evidenceCommit -cne $ExpectedRemoteMain.ToLowerInvariant()) 'Evidence commit was not created'
Invoke-Git @('push', 'origin', 'HEAD:main') | Out-Null
$publishedRemoteLine = (Invoke-Git @('ls-remote', '--exit-code', 'origin', 'refs/heads/main') | Select-Object -Last 1).Trim()
$publishedRemoteMain = ($publishedRemoteLine -split '\s+')[0]
Require ($publishedRemoteMain -ceq $evidenceCommit) 'Public remote main does not equal the evidence commit'

Write-Output 'PUBLICATION_RESULT=PASS'
Write-Output "EVIDENCE_REPOSITORY_COMMIT=$evidenceCommit"
Write-Output "EVIDENCE_REPOSITORY_REMOTE_MAIN=$publishedRemoteMain"
Write-Output "EVIDENCE_TARGET_DIRECTORY=$targetName"
Write-Output "EVIDENCE_PACKAGE_SHA256=$($ExpectedEvidenceZipSha256.ToUpperInvariant())"
Write-Output 'FORCE_PUSH=NO'
Write-Output 'TAG=NO'
Write-Output 'RELEASE=NO'
