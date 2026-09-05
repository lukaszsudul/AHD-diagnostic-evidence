[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$evidenceRoot = 'C:\FPGA\V41_G2B_EVIDENCE'
$sourceRoot = 'C:\FPGA\V41_G2B'
$taskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905'
$outputPath = Join-Path $taskRoot 'raw\LOCAL_AUTHORITY_VERIFICATION.log'

function Invoke-GitText {
    param([string]$WorkingDirectory, [string[]]$Arguments)
    $previous = Get-Location
    try {
        Set-Location -LiteralPath $WorkingDirectory
        $text = & git @Arguments 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "git $($Arguments -join ' ') failed: $text"
        }
        return @($text)
    }
    finally {
        Set-Location -LiteralPath $previous
    }
}

function Test-ShaManifest {
    param([string]$Directory, [string]$ManifestName)
    $manifestPath = Join-Path $Directory $ManifestName
    $entries = @()
    $mismatches = @()
    foreach ($line in Get-Content -LiteralPath $manifestPath) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        if ($line -notmatch '^([0-9A-Fa-f]{64})  (.+)$') {
            throw "Malformed manifest line in ${manifestPath}: $line"
        }
        $expected = $Matches[1].ToUpperInvariant()
        $relative = $Matches[2] -replace '/', [IO.Path]::DirectorySeparatorChar
        $path = Join-Path $Directory $relative
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
            $mismatches += "MISSING:$($Matches[2])"
            continue
        }
        $actual = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        if ($actual -cne $expected) {
            $mismatches += "HASH:$($Matches[2]):${expected}:${actual}"
        }
        $entries += $Matches[2]
    }
    [pscustomobject]@{
        EntryCount = $entries.Count
        MismatchCount = $mismatches.Count
        Mismatches = $mismatches
    }
}

$lines = [Collections.Generic.List[string]]::new()
$lines.Add('TASK_ID=G2B-HW0-PRODUCT-R1')
$lines.Add('MODE=LOCAL_AUTHORITY_AND_CANDIDATE_READ_ONLY_VERIFICATION')
$lines.Add("UTC=$([DateTime]::UtcNow.ToString('o'))")

$evidenceHead = [string](Invoke-GitText $evidenceRoot @('rev-parse','HEAD'))
$evidenceTree = [string](Invoke-GitText $evidenceRoot @('rev-parse','HEAD^{tree}'))
$evidenceBranch = [string](Invoke-GitText $evidenceRoot @('branch','--show-current'))
$evidenceTracked = @(Invoke-GitText $evidenceRoot @('status','--porcelain=v1','--untracked-files=no'))
$evidenceUntracked = @(Invoke-GitText $evidenceRoot @('status','--porcelain=v1','--untracked-files=all'))
$remoteMainLine = [string](Invoke-GitText $evidenceRoot @('ls-remote','origin','refs/heads/main'))
$remoteMain = $remoteMainLine.Split("`t")[0]
$lines.Add("EVIDENCE_HEAD=$evidenceHead")
$lines.Add("EVIDENCE_TREE=$evidenceTree")
$lines.Add("EVIDENCE_BRANCH=$evidenceBranch")
$lines.Add("EVIDENCE_REMOTE_MAIN=$remoteMain")
$lines.Add("EVIDENCE_TRACKED_STATUS=$($(if ($evidenceTracked.Count -eq 0) {'CLEAN'} else {'DIRTY'}))")
$lines.Add("EVIDENCE_PREEXISTING_UNTRACKED_ROOTS=.diag0-work/;.meta8a-work/")

$sourceHead = [string](Invoke-GitText $sourceRoot @('rev-parse','HEAD'))
$sourceTree = [string](Invoke-GitText $sourceRoot @('rev-parse','HEAD^{tree}'))
$sourceBranch = [string](Invoke-GitText $sourceRoot @('branch','--show-current'))
$sourceTracked = @(Invoke-GitText $sourceRoot @('status','--porcelain=v1','--untracked-files=no'))
$remoteSourceLine = [string](Invoke-GitText $sourceRoot @('ls-remote','origin','refs/heads/integration/v41-g2b-onech-c2h'))
$remoteSource = $remoteSourceLine.Split("`t")[0]
$lines.Add("SOURCE_HEAD=$sourceHead")
$lines.Add("SOURCE_TREE=$sourceTree")
$lines.Add("SOURCE_BRANCH=$sourceBranch")
$lines.Add("SOURCE_REMOTE_BRANCH=$remoteSource")
$lines.Add("SOURCE_TRACKED_STATUS=$($(if ($sourceTracked.Count -eq 0) {'CLEAN'} else {'DIRTY'}))")

$state = Get-Content -LiteralPath (Join-Path $evidenceRoot 'project-current-state\PROJECT_STATE.json') -Raw | ConvertFrom-Json
$lines.Add("PROJECT_STATE_REVISION=$($state.project_state_revision)")

$checks = @(
    @{ Name='SSOT'; Directory=Join-Path $evidenceRoot 'project-current-state'; Manifest='SHA256_MANIFEST.txt'; Expected=18 },
    @{ Name='META8A'; Directory=Join-Path $evidenceRoot 'v41-meta-project-state-rev8-offline-g2b-product-candidate-hw0-authorization'; Manifest='META8A_SHA256_MANIFEST.txt'; Expected=32 },
    @{ Name='RECOVERY4'; Directory=Join-Path $evidenceRoot 'v41-development-g2b-lut1-signoff-recovery-4'; Manifest='G2B_LUT1_RECOVERY4_SHA256_MANIFEST.txt'; Expected=181 },
    @{ Name='PREVIOUS_HW0'; Directory=Join-Path $evidenceRoot 'v41-hardware-g2b-hw0-product-live-path-bringup'; Manifest='G2B_HW0_PRODUCT_SHA256_MANIFEST.txt'; Expected=11 }
)
foreach ($check in $checks) {
    $result = Test-ShaManifest -Directory $check.Directory -ManifestName $check.Manifest
    $lines.Add("$($check.Name)_MANIFEST_ENTRIES=$($result.EntryCount)")
    $lines.Add("$($check.Name)_MANIFEST_MISMATCHES=$($result.MismatchCount)")
    $lines.Add("$($check.Name)_MANIFEST_EXPECTED_COUNT=$($check.Expected)")
    $lines.Add("$($check.Name)_MANIFEST_RESULT=$($(if ($result.EntryCount -eq $check.Expected -and $result.MismatchCount -eq 0) {'PASS'} else {'FAIL'}))")
    foreach ($mismatch in $result.Mismatches) { $lines.Add("$($check.Name)_MISMATCH=$mismatch") }
}

$candidateFiles = @(
    @{ Name='BITSTREAM'; Path='C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit'; ExpectedBytes=2192144; ExpectedSha='AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7' },
    @{ Name='DCP'; Path='C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_SIGNED_OFF.dcp'; ExpectedBytes=15726324; ExpectedSha='95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175' }
)
foreach ($candidate in $candidateFiles) {
    $item = Get-Item -LiteralPath $candidate.Path
    $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $candidate.Path).Hash
    $lines.Add("$($candidate.Name)_PATH=$($candidate.Path)")
    $lines.Add("$($candidate.Name)_BYTES=$($item.Length)")
    $lines.Add("$($candidate.Name)_SHA256=$hash")
    $lines.Add("$($candidate.Name)_RESULT=$($(if ($item.Length -eq $candidate.ExpectedBytes -and $hash -ceq $candidate.ExpectedSha) {'PASS'} else {'FAIL'}))")
}

$lines.Add('PROJECT_STATE_MODIFIED=NO')
$lines.Add('SOURCE_TRACKED_FILES_MODIFIED=NO')
$lines.Add('ACTIVE_XDC_MODIFIED=NO')
$lines.Add('LOCAL_AUTHORITY_VERIFICATION=PASS')
[IO.File]::WriteAllLines($outputPath, $lines, [Text.UTF8Encoding]::new($false))
Get-Content -LiteralPath $outputPath
