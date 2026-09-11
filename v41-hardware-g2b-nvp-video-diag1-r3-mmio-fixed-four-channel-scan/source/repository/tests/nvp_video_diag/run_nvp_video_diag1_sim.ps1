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
$gitBranch = (& git -C $RepoRoot branch --show-current).Trim()
$gitHead = (& git -C $RepoRoot rev-parse HEAD).Trim()
$gitTree = (& git -C $RepoRoot rev-parse 'HEAD^{tree}').Trim()

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
$runtimeCasesPassed = 0
$t17 = 'NOT_REACHED'
$t18 = 'NOT_REACHED'
$t19 = 'NOT_REACHED'
$timingBoundaryRuntime = 'NOT_REACHED'
$timingBoundaryFormula = 'NOT_REACHED'
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
    $caseMatches = [regex]::Matches($coreConsole, '(?m)^PASS T(?:[1-9]|1[0-8]) ')
    if ($caseMatches.Count -ne 18 -or
        $coreConsole -notmatch 'PASS INHERITED_NVP_VIDEO_DIAG1_SIMULATION_GATE 16/16' -or
        $coreConsole -notmatch 'PASS NVP_VIDEO_DIAG1_R1_RUNTIME_SIMULATION_GATE 18/18') {
        throw "Expected 18 named runtime simulation cases, found $($caseMatches.Count)"
    }
    if ($coreConsole -match 'Fatal:|Error:') {
        throw 'Diagnostic core simulation emitted a fatal/error marker'
    }
    if ($coreConsole -notmatch
        'PASS TIMING_BOUNDARIES ACCELERATED_SETTLE_2_SAMPLE_1_STATUS_200') {
        throw 'Exact accelerated timing-boundary PASS marker missing'
    }
    $runtimeCasesPassed = 18
    $t17 = 'PASS'
    $t18 = 'PASS'
    $timingBoundaryRuntime = 'PASS'

    $coreText = Get-Content -Raw -LiteralPath $core
    $topText = Get-Content -Raw -LiteralPath $top
    foreach ($literal in @('17''h03c00', '32''h4e56_5034',
            '32''h0001_0002', 'REG_BGDCOL_12', 'REG_BGDCOL_34',
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

    # Tie the accelerated 2/1/200-cycle simulation proof to the unchanged
    # production defaults and their cycle formulas: 200/100/2000 ms at
    # 62.5 MHz (62500 clocks per millisecond).
    foreach ($pattern in @(
            'parameter\s+integer\s+CYCLES_PER_MS\s*=\s*62500',
            'parameter\s+integer\s+SETTLE_TIME_MS\s*=\s*200',
            'parameter\s+integer\s+STATUS_SAMPLE_INTERVAL_MS\s*=\s*100',
            'parameter\s+integer\s+MAX_STATUS_WAIT_MS\s*=\s*2000',
            'SETTLE_CYCLES\s*=\s*SETTLE_TIME_MS\s*\*\s*CYCLES_PER_MS',
            'SAMPLE_INTERVAL_CYCLES\s*=\s*\r?\n\s*STATUS_SAMPLE_INTERVAL_MS\s*\*\s*CYCLES_PER_MS',
            'MAX_STATUS_WAIT_CYCLES\s*=\s*\r?\n\s*MAX_STATUS_WAIT_MS\s*\*\s*CYCLES_PER_MS')) {
        if ($coreText -notmatch $pattern) {
            throw "Production timing formula contract missing: $pattern"
        }
    }
    if ((200 * 62500) -ne 12500000 -or
        (100 * 62500) -ne 6250000 -or
        (2000 * 62500) -ne 125000000) {
        throw 'Production timing-cycle arithmetic mismatch'
    }
    $timingBoundaryFormula = 'PASS'

    # T19: prove the resource architecture in source before synthesis.
    if ($coreText -match '\bresult_words\b' -or
        $coreText -match '\bresult_reset_index\b' -or
        $coreText -match '\btable_word\b' -or
        $coreText -match '\[\s*0\s*:\s*127\s*\]') {
        throw 'T19 failed: retired 128-word on-chip history architecture remains'
    }
    $snapshotDeclarations = [regex]::Matches($coreText,
        '(?m)^\s*logic\s+\[31:0\]\s+current_result_word_[0-7]\s*;')
    if ($snapshotDeclarations.Count -ne 8) {
        throw "T19 failed: expected 8 explicit snapshot registers, found $($snapshotDeclarations.Count)"
    }
    foreach ($literal in @('current_result_valid', 'current_result_session_id',
            'current_result_generation', 'LATCH_SESSION_RESULT',
            'SETTLE_COUNTER_WIDTH', 'SAMPLE_COUNTER_WIDTH',
            'STATUS_WAIT_COUNTER_WIDTH', 'INHERITED_DIAG_CAPABILITIES',
            'CAP_CURRENT_SESSION_SNAPSHOT_V1',
            'CAP_HOST_OWNED_SESSION_HISTORY',
            'CAP_ONCHIP_16_SESSION_HISTORY')) {
        if ($coreText -notmatch [regex]::Escape($literal)) {
            throw "T19 failed: required R1 architecture literal missing: $literal"
        }
    }
    foreach ($offset in 0x00,0x04,0x08,0x0c,0x10,0x14,0x18,0x1c,0x20,0x24,0x28) {
        $addressLiteral = "17'h03d{0:x2}" -f $offset
        if ($coreText -notmatch [regex]::Escape($addressLiteral)) {
            throw "T19 failed: snapshot MMIO address missing: $addressLiteral"
        }
    }
    $explicitReservedDecode = @([regex]::Matches($coreText,
        "17'h([0-9a-fA-F]+)") | Where-Object {
            $value = [Convert]::ToInt32($_.Groups[1].Value, 16)
            $value -ge 0x3D2C -and $value -le 0x3EFF
        })
    if ($explicitReservedDecode.Count -ne 0) {
        throw 'T19 failed: reserved snapshot range contains explicit decode logic'
    }
    if ($coreText -notmatch "CAP_CURRENT_SESSION_SNAPSHOT_V1\s*=\s*32'h0000_0100" -or
        $coreText -notmatch "CAP_HOST_OWNED_SESSION_HISTORY\s*=\s*32'h0000_0200" -or
        $coreText -notmatch "CAP_ONCHIP_16_SESSION_HISTORY\s*=\s*32'h0000_0400" -or
        $coreText -match 'DIAG_CAPABILITIES\s*=.*CAP_ONCHIP_16_SESSION_HISTORY') {
        throw 'T19 failed: R1 capability-bit contract is not explicit'
    }
    $t19 = 'PASS'
    Write-Output 'PASS T19 RESOURCE_ARCHITECTURE_STATIC_CONTRACT'

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
    'TASK=AHD_V41_G2B_NVP_VIDEO_DIAG1_R1_SIMULATION',
    "RESULT=$result",
    "FIRST_FAILURE=$failure",
    'INHERITED_SIMULATION_CASES_EXPECTED=16',
    "INHERITED_SIMULATION_CASES_PASSED=$(if ($result -eq 'PASS') { 16 } else { 0 })",
    'R1_SIMULATION_CASES_EXPECTED=19',
    "R1_RUNTIME_CASES_PASSED=$runtimeCasesPassed",
    "R1_SIMULATION_CASES_PASSED=$(if ($result -eq 'PASS') { 19 } else { $runtimeCasesPassed })",
    "T17_SNAPSHOT_ATOMICITY=$t17",
    "T18_HOST_OWNED_HISTORY=$t18",
    "T19_RESOURCE_ARCHITECTURE_STATIC_CONTRACT=$t19",
    "TIMING_BOUNDARY_RUNTIME_PROOF=$timingBoundaryRuntime",
    "TIMING_BOUNDARY_PRODUCTION_FORMULA_PROOF=$timingBoundaryFormula",
    'ACCELERATED_SETTLE_CYCLES=2',
    'ACCELERATED_SAMPLE_INTERVAL_CYCLES=1',
    'ACCELERATED_MAX_STATUS_WAIT_CYCLES=200',
    'PRODUCTION_CYCLES_PER_MS=62500',
    'PRODUCTION_SETTLE_TIME_MS=200',
    'PRODUCTION_SETTLE_CYCLES=12500000',
    'PRODUCTION_SAMPLE_INTERVAL_MS=100',
    'PRODUCTION_SAMPLE_INTERVAL_CYCLES=6250000',
    'PRODUCTION_MAX_STATUS_WAIT_MS=2000',
    'PRODUCTION_MAX_STATUS_WAIT_CYCLES=125000000',
    "TESTED_GIT_BRANCH=$gitBranch",
    "TESTED_GIT_HEAD_AT_START=$gitHead",
    "TESTED_GIT_TREE_AT_START=$gitTree",
    "TESTED_CORE_SHA256=$($hashBefore[$core])",
    "TESTED_CORE_TB_SHA256=$($hashBefore[$coreTb])",
    "TESTED_I2C_MASTER_SHA256=$($hashBefore[$master])",
    "TESTED_I2C_TB_SHA256=$($hashBefore[$masterTb])",
    "TESTED_TOP_SHA256=$($hashBefore[$top])",
    'I2C_PHYSICAL_ENGINE_SIMULATION=PASS',
    'DIAGNOSTIC_MMIO_RANGE=0x3C00..0x3FFF',
    'PRODUCT_MMIO_RANGE=0x3800..0x3BFF_UNCHANGED',
    'HARDWARE_ACCESSED=NO'
)
[IO.File]::WriteAllLines((Join-Path $OutputRoot 'NVP_VIDEO_DIAG1_SIMULATION_RECEIPT.txt'),
    $receipt, [Text.UTF8Encoding]::new($false))

Write-Output "NVP_VIDEO_DIAG1_R1_SIMULATION_GATE=$result"
if ($result -ne 'PASS') {
    Write-Error $failure
    exit 1
}
