[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$RepoRoot,
    [Parameter(Mandatory = $true)][string]$OutputRoot,
    [string]$VivadoBin = 'C:\AMDDesignTools\2025.2\Vivado\bin'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$RepoRoot = [IO.Path]::GetFullPath($RepoRoot).TrimEnd('\', '/')
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot).TrimEnd('\', '/')
if (Test-Path -LiteralPath $OutputRoot) {
    throw "OutputRoot already exists: $OutputRoot"
}
if ($OutputRoot.StartsWith($RepoRoot + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'Simulation output must remain outside the source worktree'
}

$core = Join-Path $RepoRoot 'rtl\g2b\g2b_nvp_video_diag.sv'
$bridge = Join-Path $RepoRoot 'rtl\v41\axi_lite_host_bridge.sv'
$router = Join-Path $RepoRoot 'rtl\g2b\v41_g2b_mmio_router.sv'
$coreTb = Join-Path $RepoRoot 'tests\nvp_video_diag\tb_g2b_nvp_video_diag_mmio_protocol.sv'
$axiTb = Join-Path $RepoRoot 'tests\nvp_video_diag\tb_g2b_nvp_video_diag_axi_integration.sv'
$inheritedRunner = Join-Path $RepoRoot 'tests\nvp_video_diag\run_nvp_video_diag1_sim.ps1'
$contractChecker = Join-Path $RepoRoot 'tests\nvp_video_diag\check_nvp_video_diag_r3_contract.ps1'
$xvlog = Join-Path $VivadoBin 'xvlog.bat'
$xelab = Join-Path $VivadoBin 'xelab.bat'
$xsim = Join-Path $VivadoBin 'xsim.bat'
$inputs = @($core, $bridge, $router, $coreTb, $axiTb, $inheritedRunner,
    $contractChecker)
foreach ($path in $inputs + @($xvlog, $xelab, $xsim)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required R3 simulation input missing: $path"
    }
}

[void][IO.Directory]::CreateDirectory($OutputRoot)
$hashBefore = @{}
foreach ($path in $inputs) {
    $hashBefore[$path] = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
}

function Invoke-Logged {
    param([scriptblock]$Action, [string]$LogPath, [string]$Label)
    & $Action 2>&1 | Tee-Object -FilePath $LogPath
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit $LASTEXITCODE"
    }
}

function Invoke-SimTool {
    param([string]$Tool, [string[]]$Arguments, [string]$Label)
    $log = Join-Path $OutputRoot "$Label.console.log"
    & $Tool @Arguments 2>&1 | Tee-Object -FilePath $log
    if ($LASTEXITCODE -ne 0) {
        throw "$Label failed with exit $LASTEXITCODE"
    }
}

$result = 'FAIL'
$failure = ''
$inherited = 'NOT_REACHED'
$newGate = 'NOT_REACHED'
$stress = 'NOT_REACHED'
$ordering = 'NOT_REACHED'
$isolation = 'NOT_REACHED'
$progress = 'NOT_REACHED'
$staticContract = 'NOT_REACHED'
try {
    $inheritedRoot = Join-Path $OutputRoot 'inherited_19'
    & $inheritedRunner -RepoRoot $RepoRoot -OutputRoot $inheritedRoot `
        -VivadoBin $VivadoBin 2>&1 |
        Tee-Object -FilePath (Join-Path $OutputRoot 'inherited.console.log')
    if ($LASTEXITCODE -ne 0) {
        throw 'Inherited 19-case simulation gate failed'
    }
    $inheritedReceipt = Get-Content -Raw -LiteralPath (
        Join-Path $inheritedRoot 'NVP_VIDEO_DIAG1_SIMULATION_RECEIPT.txt')
    if ($inheritedReceipt -notmatch 'R1_SIMULATION_CASES_PASSED=19' -or
        $inheritedReceipt -notmatch 'RESULT=PASS') {
        throw 'Inherited simulation receipt does not prove 19/19 PASS'
    }
    $inherited = 'PASS_19_OF_19'

    & $contractChecker -RepoRoot $RepoRoot 2>&1 |
        Tee-Object -FilePath (Join-Path $OutputRoot 'static_contract.console.log')
    if ($LASTEXITCODE -ne 0) {
        throw 'R3 static source contract failed'
    }
    $staticText = Get-Content -Raw -LiteralPath (
        Join-Path $OutputRoot 'static_contract.console.log')
    if ($staticText -notmatch 'PASS R3_DIAGNOSTIC_MMIO_STATIC_SOURCE_CONTRACT') {
        throw 'R3 static source-contract PASS marker missing'
    }
    $staticContract = 'PASS'

    Push-Location $OutputRoot
    try {
        Invoke-SimTool $xvlog @('--sv', '--work', 'work', $core, $bridge,
            $router, $coreTb, $axiTb) 'r3_compile'
        Invoke-SimTool $xelab @('work.tb_g2b_nvp_video_diag_mmio_protocol',
            '-s', 'nvp_diag_r3_core_protocol', '--debug', 'typical', '--relax') `
            'r3_core_elaborate'
        Invoke-SimTool $xsim @('nvp_diag_r3_core_protocol', '-runall', '-log',
            (Join-Path $OutputRoot 'r3_core_xsim.log')) 'r3_core_run'
        Invoke-SimTool $xelab @(
            'work.tb_g2b_nvp_video_diag_axi_integration', '-s',
            'nvp_diag_r3_axi_integration', '--debug', 'typical', '--relax') `
            'r3_axi_elaborate'
        Invoke-SimTool $xsim @('nvp_diag_r3_axi_integration', '-runall',
            '-log', (Join-Path $OutputRoot 'r3_axi_xsim.log')) 'r3_axi_run'
    } finally {
        Pop-Location
    }

    $coreText = Get-Content -Raw -LiteralPath (
        Join-Path $OutputRoot 'r3_core_run.console.log')
    $axiText = Get-Content -Raw -LiteralPath (
        Join-Path $OutputRoot 'r3_axi_run.console.log')
    if ($coreText -match 'Fatal:|Error:' -or $axiText -match 'Fatal:|Error:') {
        throw 'R3 MMIO/AXI simulation emitted a fatal/error marker'
    }
    if ($coreText -notmatch
        'PASS T20 CORE_WRITE_NO_RESPONSE_READ_RESPONSE_CONTRACT') {
        throw 'T20 PASS marker missing'
    }
    foreach ($marker in @(
            'PASS T21 ACTUAL_AXI_LITE_BRIDGE_INTEGRATION',
            'PASS T22 AXI_LITE_ORDERING_AND_BACKPRESSURE',
            'PASS T23 1000_CYCLE_COMMAND_STRESS',
            'PASS T24 DIAGNOSTIC_PRODUCT_ADDRESS_ISOLATION',
            'PASS T25 BOUNDED_PROGRESS_PROPERTIES',
            'PASS R3_NEW_MMIO_AXI_LITE_SIMULATION_GATE 6/6')) {
        if ($axiText -notmatch [regex]::Escape($marker)) {
            throw "R3 integration PASS marker missing: $marker"
        }
    }
    $newGate = 'PASS_6_OF_6'
    $stress = 'PASS'
    $ordering = 'PASS'
    $isolation = 'PASS'
    $progress = 'PASS'

    foreach ($path in $inputs) {
        $after = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        if ($after -ne $hashBefore[$path]) {
            throw "R3 simulation input changed during execution: $path"
        }
    }
    $result = 'PASS'
} catch {
    $failure = $_.Exception.Message
}

$receipt = @(
    'TASK=AHD_V41_G2B_NVP_VIDEO_DIAG1_R3_SIMULATION',
    "RESULT=$result",
    "FIRST_FAILURE=$failure",
    "INHERITED_DIAGNOSTIC_SIMULATION_GATE=$inherited",
    "NEW_MMIO_AXI_LITE_SIMULATION_GATE=$newGate",
    "COMPLETE_R3_SIMULATION_GATE=$(if ($result -eq 'PASS') { 'PASS_25_OF_25' } else { 'FAIL' })",
    "T20_CORE_WRITE_NO_RESPONSE=$(if ($newGate -eq 'PASS_6_OF_6') { 'PASS' } else { 'NOT_PROVEN' })",
    "T21_AXI_LITE_INTEGRATION=$(if ($newGate -eq 'PASS_6_OF_6') { 'PASS' } else { 'NOT_PROVEN' })",
    "T22_AXI_LITE_ORDERING_BACKPRESSURE=$ordering",
    "T23_1000_CYCLE_STRESS=$stress",
    "T24_DIAGNOSTIC_PRODUCT_ADDRESS_ISOLATION=$isolation",
    "T25_BOUNDED_PROGRESS_PROPERTIES=$progress",
    "STATIC_SOURCE_CONTRACT=$staticContract",
    "TESTED_CORE_SHA256=$($hashBefore[$core])",
    "TESTED_CORE_PROTOCOL_TB_SHA256=$($hashBefore[$coreTb])",
    "TESTED_AXI_INTEGRATION_TB_SHA256=$($hashBefore[$axiTb])",
    "TESTED_SHARED_BRIDGE_SHA256=$($hashBefore[$bridge])",
    "TESTED_MMIO_ROUTER_SHA256=$($hashBefore[$router])",
    'HARDWARE_ACCESSED=NO'
)
[IO.File]::WriteAllLines((Join-Path $OutputRoot 'NVP_VIDEO_DIAG1_R3_SIMULATION_RECEIPT.txt'),
    $receipt, [Text.UTF8Encoding]::new($false))

Write-Output "NVP_VIDEO_DIAG1_R3_SIMULATION_GATE=$result"
if ($result -ne 'PASS') {
    Write-Error $failure
    exit 1
}
