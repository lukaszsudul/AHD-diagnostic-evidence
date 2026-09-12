[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$OutputRoot,
    [Parameter(Mandatory = $true)][string]$PythonExe,
    [Parameter(Mandatory = $true)][string]$ReferenceRoot,
    [string]$VivadoBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$env:PYTHONDONTWRITEBYTECODE = '1'
$RepoRoot = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\', '/')
$ReferenceRoot = [IO.Path]::GetFullPath($ReferenceRoot).TrimEnd('\', '/')
if (Test-Path -LiteralPath $OutputRoot) { throw "OutputRoot already exists: $OutputRoot" }
if ($OutputRoot.StartsWith($RepoRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Gate output must remain outside the source worktree'
}

$executor = Join-Path $RepoRoot 'rtl\g2b\g2b_nvp_acq1_compat0_r2.sv'
$testbench = Join-Path $RepoRoot 'tests\acq1_compat0_r2\tb_g2b_nvp_acq1_compat0_r2.sv'
$static = Join-Path $RepoRoot 'tests\acq1_compat0_r2\check_static_contract.py'
$hostTest = 'tests.acq1_compat0_r2.test_host_policy'
$xvlog = Join-Path $VivadoBin 'xvlog.bat'
$xelab = Join-Path $VivadoBin 'xelab.bat'
$xsim = Join-Path $VivadoBin 'xsim.bat'
$inputs = @($executor, $testbench, $static, $PythonExe, $xvlog, $xelab, $xsim,
    (Join-Path $ReferenceRoot 'video.c'), (Join-Path $ReferenceRoot 'video.h'))
foreach ($path in $inputs) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Gate input missing: $path" }
}
[void][IO.Directory]::CreateDirectory($OutputRoot)

$sourceInputs = Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'host\acq1_compat0_r2') -Recurse -File
$sourceInputs += Get-Item -LiteralPath (Join-Path $RepoRoot 'host\acq1_compat0_r2_launcher.py')
$sourceInputs += Get-Item -LiteralPath (Join-Path $RepoRoot 'host\acq1_compat0_r2_campaign_launcher.py')
$sourceInputs += Get-Item -LiteralPath (Join-Path $RepoRoot 'scripts\acq1_compat0_r2\build_runtime_bundle.py')
$sourceInputs += Get-ChildItem -LiteralPath (Join-Path $RepoRoot 'tests\acq1_compat0_r2') -File
$sourceInputs += Get-Item -LiteralPath $executor
$sourceInputs += Get-Item -LiteralPath (Join-Path $RepoRoot 'rtl\g2b\g2b_nvp_camera_scan1_acq1_compat0_r2.sv')
$sourceInputs += Get-Item -LiteralPath (Join-Path $RepoRoot 'rtl\top\ahd_capture_top_xdma.sv')
$hashBefore = @{}
foreach ($item in $sourceInputs) { $hashBefore[$item.FullName] = (Get-FileHash $item.FullName -Algorithm SHA256).Hash }

function Invoke-Logged {
    param([scriptblock]$Action, [string]$Name)
    $log = Join-Path $OutputRoot "$Name.console.log"
    & $Action 2>&1 | Tee-Object -FilePath $log
    if ($LASTEXITCODE -ne 0) { throw "$Name failed with exit $LASTEXITCODE" }
}

$result = 'FAIL'
$firstFailure = ''
try {
    Invoke-Logged { & $PythonExe -B $static --reference-root $ReferenceRoot } 'static_contract'
    Push-Location $RepoRoot
    try { Invoke-Logged { & $PythonExe -B -m unittest $hostTest -v } 'host_policy' }
    finally { Pop-Location }

    Push-Location $OutputRoot
    try {
        Invoke-Logged { & $xvlog '--sv' '--work' 'work' $executor $testbench } 'compile'
        Invoke-Logged { & $xelab 'work.tb_g2b_nvp_acq1_compat0_r2' '-s' 'acq1_compat0_r2_gate' '--debug' 'typical' '--relax' } 'elaborate'
        Invoke-Logged { & $xsim 'acq1_compat0_r2_gate' '-runall' '-log' (Join-Path $OutputRoot 'xsim.log') } 'simulate'
    } finally { Pop-Location }

    $hostText = Get-Content -Raw -LiteralPath (Join-Path $OutputRoot 'host_policy.console.log')
    if ($hostText -notmatch '(?m)^OK\s*$') { throw 'host policy unit gate did not end in OK' }
    $hostMarkers = @(
        'PASS E18 stable NOVID=0 stops the sweep immediately',
        'PASS E19 NOVID=1 after final 0x60 stops without mode/EQ/capture',
        'PASS E20 format unresolved/unsupported/AHD1080P25 outcomes are read-only and all end in exact rollback'
    )
    [IO.File]::WriteAllLines((Join-Path $OutputRoot 'host_policy_markers.log'), $hostMarkers,
        [Text.UTF8Encoding]::new($false))
    $hostMarkers | Write-Output

    $allText = (Get-Content -Raw (Join-Path $OutputRoot 'static_contract.console.log')) + "`n" +
               (Get-Content -Raw (Join-Path $OutputRoot 'simulate.console.log')) + "`n" +
               ($hostMarkers -join "`n")
    for ($case = 1; $case -le 20; $case++) {
        $tag = 'E{0:D2}' -f $case
        $count = [regex]::Matches($allText, "(?m)^PASS $tag ").Count
        if ($count -ne 1) { throw "expected exactly one PASS $tag marker; found $count" }
    }
    if ([regex]::Matches($allText, '(?m)^PASS E\d\d ').Count -ne 20) {
        throw 'governed PASS marker total is not exactly twenty'
    }
    if ($allText -notmatch '(?m)^UNAUTHORIZED_FUNCTIONAL_WRITE_COUNT=0\r?$') {
        throw 'unauthorized functional write zero marker missing'
    }

    $credentialPatterns = '(?i)(BEGIN [A-Z ]*PRIVATE KEY|github_pat_|ghp_[A-Za-z0-9]{20,}|password\s*=\s*["''][^"'']+["''])'
    $credentialRemnants = 0
    foreach ($item in $sourceInputs) {
        if ($item.Name -eq 'run_acq1_compat0_r2_gate.ps1') { continue }
        if ((Get-Content -Raw -LiteralPath $item.FullName) -match $credentialPatterns) { $credentialRemnants++ }
    }
    if ($credentialRemnants -ne 0) { throw "credential remnants found: $credentialRemnants" }
    $controllerText = Get-Content -Raw -LiteralPath (Join-Path $RepoRoot 'host\acq1_compat0_r2\controller.py')
    if ($controllerText -match '(?i)(socket|subprocess|multiprocessing|shared_memory|raw_payload)') {
        throw 'controller contains a prohibited IPC/raw-payload surface'
    }
    foreach ($path in $hashBefore.Keys) {
        if ((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash -ne $hashBefore[$path]) {
            throw "gate input changed during run: $path"
        }
    }
    $result = 'PASS'
} catch {
    $firstFailure = $_.Exception.Message
}

$rows = @('Test,Result')
for ($case = 1; $case -le 20; $case++) {
    $rows += ('E{0:D2},{1}' -f $case, $(if ($result -eq 'PASS') { 'PASS' } else { 'NOT_PROVEN' }))
}
[IO.File]::WriteAllLines((Join-Path $OutputRoot 'G2B_NVP_ACQ1_COMPAT0_R2_TEST_RESULTS.csv'),
    $rows, [Text.UTF8Encoding]::new($false))
$receipt = @(
    'TASK=AHD_V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2',
    "RESULT=$result",
    "FIRST_FAILURE=$firstFailure",
    "EXECUTOR_INTEGRATION_GATE=$(if ($result -eq 'PASS') { '20/20 PASS' } else { 'FAIL' })",
    "UNAUTHORIZED_FUNCTIONAL_WRITE_COUNT=$(if ($result -eq 'PASS') { '0' } else { 'NOT_PROVEN' })",
    "CREDENTIAL_REMNANTS=$(if ($result -eq 'PASS') { '0' } else { 'NOT_PROVEN' })",
    "RAW_PAYLOAD_THROUGH_CONTROLLER_IPC=$(if ($result -eq 'PASS') { 'NO' } else { 'NOT_PROVEN' })",
    "TESTED_BRANCH=$((& git -C $RepoRoot branch --show-current).Trim())",
    "TESTED_HEAD=$((& git -C $RepoRoot rev-parse HEAD).Trim())",
    'HARDWARE_ACCESSED=NO'
)
[IO.File]::WriteAllLines((Join-Path $OutputRoot 'G2B_NVP_ACQ1_COMPAT0_R2_TEST_RECEIPT.txt'),
    $receipt, [Text.UTF8Encoding]::new($false))
Write-Output "ACQ1_COMPAT0_R2_EXECUTOR_INTEGRATION_GATE=$result"
if ($result -ne 'PASS') { Write-Error $firstFailure; exit 1 }
