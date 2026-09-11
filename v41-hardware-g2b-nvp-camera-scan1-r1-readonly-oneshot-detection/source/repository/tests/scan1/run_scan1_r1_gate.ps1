[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$OutputRoot,
    [Parameter(Mandatory = $true)][string]$PythonExe,
    [string]$VivadoBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$env:PYTHONDONTWRITEBYTECODE = '1'
$RepoRoot = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\', '/')
if (Test-Path -LiteralPath $OutputRoot) {
    throw "OutputRoot already exists: $OutputRoot"
}
if ($OutputRoot.StartsWith($RepoRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Gate output must remain outside the source worktree'
}

$package = Join-Path $RepoRoot 'rtl\g2b\g2b_nvp_camera_scan1_manifest_pkg.sv'
$core = Join-Path $RepoRoot 'rtl\g2b\g2b_nvp_camera_scan1.sv'
$master = Join-Path $RepoRoot 'rtl\v41\nvp_i2c_fixed_master.sv'
$coreTb = Join-Path $RepoRoot 'tests\scan1\tb_g2b_nvp_camera_scan1.sv'
$masterTb = Join-Path $RepoRoot 'tests\scan1\tb_nvp_i2c_fixed_master_scan1.sv'
$staticCheck = Join-Path $RepoRoot 'tests\scan1\check_scan1_static_contract.py'
$hostTest = 'tests.scan1.test_scan1_host'
$generator = Join-Path $RepoRoot 'scripts\scan1\generate_scan1_manifest_pkg.py'
$bundleBuilder = Join-Path $RepoRoot 'scripts\scan1\build_runtime_bundle.py'
$xvlog = Join-Path $VivadoBin 'xvlog.bat'
$xelab = Join-Path $VivadoBin 'xelab.bat'
$xsim = Join-Path $VivadoBin 'xsim.bat'
$inputs = @($package, $core, $master, $coreTb, $masterTb, $staticCheck,
    $generator, $bundleBuilder, $PythonExe, $xvlog, $xelab, $xsim)
foreach ($path in $inputs) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required SCAN1 gate input missing: $path"
    }
}

[void][IO.Directory]::CreateDirectory($OutputRoot)
$hashBefore = @{}
foreach ($path in $inputs | Where-Object { $_ -like "$RepoRoot*" }) {
    $hashBefore[$path] = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
}

function Invoke-Logged {
    param([scriptblock]$Action, [string]$Name)
    $log = Join-Path $OutputRoot "$Name.console.log"
    & $Action 2>&1 | Tee-Object -FilePath $log
    if ($LASTEXITCODE -ne 0) {
        throw "$Name failed with exit $LASTEXITCODE"
    }
}

$result = 'FAIL'
$firstFailure = ''
$bundleGate = 'NOT_REACHED'
try {
    Invoke-Logged { & $PythonExe -B $generator } 'manifest_generation'
    Invoke-Logged { & $PythonExe -B $staticCheck } 'static_contract'
    Push-Location $RepoRoot
    try {
        Invoke-Logged { & $PythonExe -B -m unittest $hostTest -v } 'host_tests'
    } finally {
        Pop-Location
    }

    Push-Location $OutputRoot
    try {
        Invoke-Logged { & $xvlog '--sv' '--work' 'work' $package $master $masterTb $core $coreTb } 'compile'
        Invoke-Logged { & $xelab 'work.tb_nvp_i2c_fixed_master_scan1' '-s' 'scan1_master' '--debug' 'typical' '--relax' } 'master_elaborate'
        Invoke-Logged { & $xsim 'scan1_master' '-runall' '-log' (Join-Path $OutputRoot 'master_xsim.log') } 'master_run'
        Invoke-Logged { & $xelab 'work.tb_g2b_nvp_camera_scan1' '-s' 'scan1_core' '--debug' 'typical' '--relax' } 'core_elaborate'
        Invoke-Logged { & $xsim 'scan1_core' '-runall' '-log' (Join-Path $OutputRoot 'core_xsim.log') } 'core_run'
    } finally {
        Pop-Location
    }

    $bundleRoot = Join-Path $OutputRoot 'runtime-bundle'
    $head = (& git -C $RepoRoot rev-parse HEAD).Trim()
    $tree = (& git -C $RepoRoot show -s --format=%T HEAD).Trim()
    Invoke-Logged {
        & $PythonExe -B $bundleBuilder --output $bundleRoot `
            --source-commit "PRECOMMIT_$head" --source-tree "PRECOMMIT_$tree"
    } 'runtime_bundle'
    $bundleText = Get-Content -Raw -LiteralPath (Join-Path $OutputRoot 'runtime_bundle.console.log')
    if ($bundleText -notmatch '"result": "PASS"' -or
        $bundleText -notmatch '"local_isolated_import_gate": "PASS"' -or
        $bundleText -notmatch '"negative_missing_dependency_gate": "PASS"') {
        throw 'closed runtime bundle gate markers missing'
    }
    $bundleGate = 'PASS'

    $staticText = Get-Content -Raw -LiteralPath (Join-Path $OutputRoot 'static_contract.console.log')
    $masterText = Get-Content -Raw -LiteralPath (Join-Path $OutputRoot 'master_run.console.log')
    $coreText = Get-Content -Raw -LiteralPath (Join-Path $OutputRoot 'core_run.console.log')
    $hostText = Get-Content -Raw -LiteralPath (Join-Path $OutputRoot 'host_tests.console.log')
    if ($masterText -match 'Fatal:|Error:' -or $coreText -match 'Fatal:|Error:' -or
        $hostText -notmatch '(?m)^OK\s*$') {
        throw 'runtime simulation or host test emitted failure'
    }
    $allText = $staticText + "`n" + $masterText + "`n" + $coreText
    for ($case = 1; $case -le 23; $case++) {
        $tag = 'T{0:D2}' -f $case
        $matches = [regex]::Matches($allText, "(?m)^PASS $tag ")
        if ($matches.Count -ne 1) {
            throw "expected exactly one PASS $tag marker; found $($matches.Count)"
        }
    }
    Write-Output 'PASS T24 HOST_THREE_SAMPLE_DEBOUNCE_AND_CLOSED_BUNDLE_GATE'

    foreach ($path in $hashBefore.Keys) {
        $after = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash
        if ($after -ne $hashBefore[$path]) {
            throw "gate input changed during run: $path"
        }
    }
    $result = 'PASS'
} catch {
    $firstFailure = $_.Exception.Message
}

$rows = @('Test,Result')
for ($case = 1; $case -le 24; $case++) {
    $rows += ('T{0:D2},{1}' -f $case, $(if ($result -eq 'PASS') { 'PASS' } else { 'NOT_PROVEN' }))
}
[IO.File]::WriteAllLines((Join-Path $OutputRoot 'G2B_NVP_CAMERA_SCAN1_R1_SIMULATION_RESULTS.csv'),
    $rows, [Text.UTF8Encoding]::new($false))
$receipt = @(
    'TASK=AHD_V41_G2B_NVP_CAMERA_SCAN1_R1',
    "RESULT=$result",
    "FIRST_FAILURE=$firstFailure",
    "SIMULATION_AND_HOST_GATE=$(if ($result -eq 'PASS') { '24/24 PASS' } else { 'FAIL' })",
    "CLOSED_RUNTIME_BUNDLE_GATE=$bundleGate",
    "TESTED_BRANCH=$((& git -C $RepoRoot branch --show-current).Trim())",
    "TESTED_HEAD=$((& git -C $RepoRoot rev-parse HEAD).Trim())",
    "TESTED_BASE_TREE=$((& git -C $RepoRoot show -s --format=%T HEAD).Trim())",
    'HARDWARE_ACCESSED=NO'
)
[IO.File]::WriteAllLines((Join-Path $OutputRoot 'G2B_NVP_CAMERA_SCAN1_R1_SIMULATION_RECEIPT.txt'),
    $receipt, [Text.UTF8Encoding]::new($false))
Write-Output "SCAN1_R1_SIMULATION_AND_HOST_GATE=$result"
if ($result -ne 'PASS') {
    Write-Error $firstFailure
    exit 1
}
