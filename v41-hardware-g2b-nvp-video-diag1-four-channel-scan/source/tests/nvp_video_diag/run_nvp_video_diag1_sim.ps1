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
$master = Join-Path $RepoRoot 'rtl\v41\nvp_i2c_fixed_master.sv'
$top = Join-Path $RepoRoot 'rtl\top\ahd_capture_top_xdma.sv'
$coreTb = Join-Path $RepoRoot 'tests\nvp_video_diag\tb_g2b_nvp_video_diag.sv'
$masterTb = Join-Path $RepoRoot 'tests\nvp_video_diag\tb_nvp_i2c_fixed_master.sv'
$xvlog = Join-Path $VivadoBin 'xvlog.bat'
$xelab = Join-Path $VivadoBin 'xelab.bat'
$xsim = Join-Path $VivadoBin 'xsim.bat'
$inputs = @($core, $master, $top, $coreTb, $masterTb)
foreach ($path in $inputs + @($xvlog, $xelab, $xsim)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required simulation input missing: $path"
    }
}

[void][IO.Directory]::CreateDirectory($OutputRoot)
$hashBefore = @{}
foreach ($path in $inputs) {
    $hashBefore[$path] = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
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
try {
    Push-Location $OutputRoot
    try {
        Invoke-SimTool $xvlog @('--sv', '--work', 'work', $master, $masterTb,
            $core, $coreTb) 'compile'
        Invoke-SimTool $xelab @('work.tb_nvp_i2c_fixed_master', '-s',
            'nvp_diag1_i2c', '--debug', 'typical', '--relax') 'i2c_elaborate'
        Invoke-SimTool $xsim @('nvp_diag1_i2c', '-runall', '-log',
            (Join-Path $OutputRoot 'i2c_xsim.log')) 'i2c_run'
        Invoke-SimTool $xelab @('work.tb_g2b_nvp_video_diag', '-s',
            'nvp_diag1_core', '--debug', 'typical', '--relax') 'core_elaborate'
        Invoke-SimTool $xsim @('nvp_diag1_core', '-runall', '-log',
            (Join-Path $OutputRoot 'core_xsim.log')) 'core_run'
    } finally {
        Pop-Location
    }

    $i2cConsole = Get-Content -Raw -LiteralPath (Join-Path $OutputRoot 'i2c_run.console.log')
    $coreConsole = Get-Content -Raw -LiteralPath (Join-Path $OutputRoot 'core_run.console.log')
    if ($i2cConsole -notmatch 'PASS NVP_I2C_FIXED_MASTER_PHYSICAL_TRANSACTION_GATE') {
        throw 'Physical I2C transaction PASS marker missing'
    }
    if ($i2cConsole -match 'Fatal:|Error:') {
        throw 'Physical I2C simulation emitted a fatal/error marker'
    }
    $caseMatches = [regex]::Matches($coreConsole, '(?m)^PASS T(?:[1-9]|1[0-6]) ')
    if ($caseMatches.Count -ne 16 -or
        $coreConsole -notmatch 'PASS NVP_VIDEO_DIAG1_SIMULATION_GATE 16/16') {
        throw "Expected 16 named simulation cases, found $($caseMatches.Count)"
    }
    if ($coreConsole -match 'Fatal:|Error:') {
        throw 'Diagnostic core simulation emitted a fatal/error marker'
    }

    $coreText = Get-Content -Raw -LiteralPath $core
    $topText = Get-Content -Raw -LiteralPath $top
    foreach ($literal in @('17''h03c00', '32''h4e56_5034',
            '32''h0001_0000', 'REG_BGDCOL_12', 'REG_BGDCOL_34',
            'REG_VDO1_ROUTE', 'REG_NOVID')) {
        if ($coreText -notmatch [regex]::Escape($literal)) {
            throw "Required fixed diagnostic contract literal missing: $literal"
        }
    }
    if ($topText -notmatch 'ENABLE_NVP_VIDEO_DIAGNOSTIC != 0' -or
        $topText -notmatch "legacy_host_req_addr >= 17'h03c00" -or
        $topText -notmatch "legacy_host_req_addr <= 17'h03fff") {
        throw 'Top-level diagnostic profile/range isolation is absent'
    }
    if ($coreText -match 'i2c_cmd_reg\s*<=\s*mmio_req' -or
        $coreText -match 'i2c_cmd_wdata\s*<=\s*mmio_req') {
        throw 'Potential arbitrary host I2C write surface detected'
    }

    foreach ($path in $inputs) {
        $after = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash
        if ($after -ne $hashBefore[$path]) {
            throw "Simulation input changed during execution: $path"
        }
    }
    $result = 'PASS'
} catch {
    $failure = $_.Exception.Message
}

$receipt = @(
    'TASK=AHD_V41_G2B_NVP_VIDEO_DIAG1_SIMULATION',
    "RESULT=$result",
    "FIRST_FAILURE=$failure",
    'SIMULATION_CASES_EXPECTED=16',
    "SIMULATION_CASES_PASSED=$(if ($result -eq 'PASS') { 16 } else { 0 })",
    'I2C_PHYSICAL_ENGINE_SIMULATION=PASS',
    'DIAGNOSTIC_MMIO_RANGE=0x3C00..0x3FFF',
    'PRODUCT_MMIO_RANGE=0x3800..0x3BFF_UNCHANGED',
    'HARDWARE_ACCESSED=NO'
)
[IO.File]::WriteAllLines((Join-Path $OutputRoot 'NVP_VIDEO_DIAG1_SIMULATION_RECEIPT.txt'),
    $receipt, [Text.UTF8Encoding]::new($false))

Write-Output "NVP_VIDEO_DIAG1_SIMULATION_GATE=$result"
if ($result -ne 'PASS') {
    Write-Error $failure
    exit 1
}
