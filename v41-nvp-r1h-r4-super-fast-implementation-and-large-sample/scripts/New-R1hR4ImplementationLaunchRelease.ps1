[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST'
$implementationRoot = Join-Path $taskRoot 'implementation'
$hardwareRoot = Join-Path $taskRoot 'hardware'
$resultPath = Join-Path $implementationRoot 'R1H_R4_IMPLEMENTATION_RESULT.txt'
$preBitPath = Join-Path $implementationRoot 'R1H_R4_PRE_BITSTREAM_HARD_GATE.txt'
$postOptPath = Join-Path $implementationRoot 'R1H_R4_POST_OPT_HARD_GATE.txt'
$identityPath = Join-Path $implementationRoot 'R1H_R4_SAME_SESSION_DCP_IDENTITY.txt'
$bitPath = Join-Path $implementationRoot 'ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit'
$routedDcpPath = Join-Path $implementationRoot 'R1H_routed.dcp'
$synthDcpPath = Join-Path $taskRoot 'raw\R1H_synth.dcp'
$formalBitPath = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit'
$outputPath = Join-Path $hardwareRoot 'R1H_R4_IMPLEMENTATION_LAUNCH_RELEASE.txt'

if (Test-Path -LiteralPath $outputPath) {
    throw "refusing to overwrite immutable launch-release receipt: $outputPath"
}

function Read-UniqueKv([string]$Path) {
    $map = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $separator = $line.IndexOf('=')
        if ($separator -le 0) { throw "invalid key/value line in ${Path}: $line" }
        $key = $line.Substring(0, $separator)
        $value = $line.Substring($separator + 1)
        if (-not $map.TryAdd($key, $value)) { throw "duplicate key in ${Path}: $key" }
    }
    return $map
}

function Require-Value($Map, [string]$Key, [string]$Expected, [string]$Source) {
    if (-not $Map.ContainsKey($Key)) { throw "missing $Key in $Source" }
    if ($Map[$Key] -cne $Expected) {
        throw "unexpected $Key in ${Source}: '$($Map[$Key])' != '$Expected'"
    }
}

function Require-PassClass($Map, [string]$Key, [string]$Source) {
    if (-not $Map.ContainsKey($Key)) { throw "missing $Key in $Source" }
    if (-not $Map[$Key].StartsWith('PASS_', [StringComparison]::Ordinal)) {
        throw "non-PASS resource class $Key in ${Source}: $($Map[$Key])"
    }
}

function Require-IntLe($Map, [string]$Key, [int]$Limit, [string]$Source) {
    if (-not $Map.ContainsKey($Key)) { throw "missing $Key in $Source" }
    $value = 0
    if (-not [int]::TryParse($Map[$Key], [Globalization.NumberStyles]::Integer,
            [Globalization.CultureInfo]::InvariantCulture, [ref]$value)) {
        throw "non-integer $Key in ${Source}: $($Map[$Key])"
    }
    if ($value -gt $Limit) { throw "$Key exceeds $Limit in ${Source}: $value" }
}

function Require-DecimalGe($Map, [string]$Key, [decimal]$Limit, [string]$Source, [bool]$Strict) {
    if (-not $Map.ContainsKey($Key)) { throw "missing $Key in $Source" }
    $value = 0d
    if (-not [decimal]::TryParse($Map[$Key], [Globalization.NumberStyles]::Float,
            [Globalization.CultureInfo]::InvariantCulture, [ref]$value)) {
        throw "non-decimal $Key in ${Source}: $($Map[$Key])"
    }
    if (($Strict -and $value -le $Limit) -or ((-not $Strict) -and $value -lt $Limit)) {
        throw "$Key violates lower bound in ${Source}: $value"
    }
}

function Require-NonzeroFile([string]$Path) {
    $item = Get-Item -LiteralPath $Path
    if ($item.PSIsContainer -or $item.Length -le 0) { throw "missing/nonzero-file gate failed: $Path" }
    return $item
}

$result = Read-UniqueKv $resultPath
$preBit = Read-UniqueKv $preBitPath
$postOpt = Read-UniqueKv $postOptPath
$identity = Read-UniqueKv $identityPath

$expectedCommit = 'c4f4bfcf577c92c3021d1fe83c05878dd12e001c'
$expectedTree = '161e561f007912d73dba93c5ecd78e3cc3a6955b'
$expectedSynthDcpSha = '807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E'
$expectedFormalBitSha = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'

foreach ($pair in @(
    @('TASK','V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE'),
    @('EXPERIMENT_NAME','R1h'), @('CONTINUATION_REVISION','R4'),
    @('SOURCE_FILE_MUTATIONS','0'), @('SOURCE_COMMITS','0'),
    @('SYNTH_DESIGN_INVOCATIONS_THIS_TASK','0'),
    @('R1H_SOURCE_COMMIT',$expectedCommit), @('R1H_SOURCE_TREE',$expectedTree),
    @('R1H_SYNTH_DCP_SHA256',$expectedSynthDcpSha),
    @('RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE','NO'),
    @('OPT_DESIGN_INVOCATIONS','1'), @('PLACE_DESIGN_INVOCATIONS','1'),
    @('PHYS_OPT_DESIGN_INVOCATIONS','1'), @('ROUTE_DESIGN_INVOCATIONS','1'),
    @('WRITE_BITSTREAM_INVOCATIONS','1'), @('POST_OPT_POSITIVE_MAPPING_REGRESSION','NO'),
    @('PLACE','PASS'), @('ROUTE','PASS'), @('ROUTE_ERRORS','0'),
    @('UNROUTED_NETS','0'), @('FAILING_SETUP_PATHS','0'), @('FAILING_HOLD_PATHS','0'),
    @('DRC_ERRORS','0'), @('DRC_CRITICAL_WARNINGS','0'),
    @('CDC_REPORT_STATUS','PASS'), @('CDC_CRITICAL','0'), @('CDC_UNKNOWN','0'),
    @('SOURCE_COMMIT_TO_BIT_PROVENANCE','PASS_BY_EXACT_SHA_BOUND_DCP'),
    @('DIAGNOSTIC_ONLY_IMAGE','YES'), @('PRODUCTION_ACCEPTANCE_CLAIM','NO'),
    @('R1H_R4_IMPLEMENTATION_RESULT','PASS')
)) { Require-Value $result $pair[0] $pair[1] $resultPath }
Require-PassClass $result 'POST_OPT_RESOURCE_CLASS' $resultPath
Require-PassClass $result 'FINAL_RESOURCE_CLASS' $resultPath
Require-IntLe $result 'POST_OPT_SLICE_LUTS' 19760 $resultPath
Require-IntLe $result 'POST_OPT_SLICE_REGISTERS' 37440 $resultPath
Require-IntLe $result 'FINAL_SLICE_LUTS' 19760 $resultPath
Require-IntLe $result 'FINAL_SLICE_REGISTERS' 37440 $resultPath
Require-DecimalGe $result 'WNS' 0 $resultPath $false
Require-DecimalGe $result 'WHS' 0 $resultPath $true

foreach ($pair in @(
    @('PLACE','PASS'), @('ROUTE','PASS'), @('ROUTE_ERRORS','0'),
    @('UNROUTED_NETS','0'), @('ROUTE_COUNT_PARSE','RESOLVED'),
    @('RAW_NONEMPTY_ROUTE_PROPERTY_QUERIED','NO'),
    @('RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE','NO'),
    @('FAILING_SETUP_PATHS','0'), @('FAILING_HOLD_PATHS','0'),
    @('DRC_ERRORS','0'), @('DRC_CRITICAL_WARNINGS','0'),
    @('CDC_REPORT_STATUS','PASS'), @('CDC_CRITICAL','0'), @('CDC_UNKNOWN','0'),
    @('R1H_R4_PRE_BITSTREAM_HARD_GATE','PASS')
)) { Require-Value $preBit $pair[0] $pair[1] $preBitPath }
Require-PassClass $preBit 'FINAL_RESOURCE_CLASS' $preBitPath
Require-IntLe $preBit 'FINAL_SLICE_LUTS' 19760 $preBitPath
Require-IntLe $preBit 'FINAL_SLICE_REGISTERS' 37440 $preBitPath
Require-DecimalGe $preBit 'WNS' 0 $preBitPath $false
Require-DecimalGe $preBit 'WHS' 0 $preBitPath $true

foreach ($pair in @(
    @('OPT_DESIGN_INVOCATIONS','1'), @('OPT_DESIGN_COMMAND','opt_design'),
    @('POSITIVE_MAPPING_REGRESSION','NO')
)) { Require-Value $postOpt $pair[0] $pair[1] $postOptPath }
Require-PassClass $postOpt 'POST_OPT_RESOURCE_CLASS' $postOptPath
Require-IntLe $postOpt 'POST_OPT_SLICE_LUTS' 19760 $postOptPath
Require-IntLe $postOpt 'POST_OPT_SLICE_REGISTERS' 37440 $postOptPath

foreach ($pair in @(
    @('R1H_SYNTH_DCP_SHA256',$expectedSynthDcpSha), @('PART','xc7a35tcsg325-2'),
    @('TOP_FROM_AUTHORITATIVE_BUILD_MANIFEST','ahd_capture_top_xdma'),
    @('DESIGN_STATE','SYNTHESIZED'), @('INITIAL_STATE_REPORT_STATUS','PASS'),
    @('R1H_SOURCE_COMMIT',$expectedCommit), @('R1H_SOURCE_TREE',$expectedTree),
    @('SOURCE_PROVENANCE','PASS_BY_EXACT_SHA_BOUND_DCP'),
    @('RAW_NONEMPTY_ROUTE_PROPERTY_QUERIED','NO'),
    @('RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE','NO'),
    @('VIVADO_VERSION','2025.2'), @('VIVADO_SW_BUILD','6299465')
)) { Require-Value $identity $pair[0] $pair[1] $identityPath }

$bitItem = Require-NonzeroFile $bitPath
$routedDcpItem = Require-NonzeroFile $routedDcpPath
$synthDcpItem = Require-NonzeroFile $synthDcpPath
$formalBitItem = Require-NonzeroFile $formalBitPath
$bitSha = (Get-FileHash -LiteralPath $bitPath -Algorithm SHA256).Hash
$routedDcpSha = (Get-FileHash -LiteralPath $routedDcpPath -Algorithm SHA256).Hash
$synthDcpSha = (Get-FileHash -LiteralPath $synthDcpPath -Algorithm SHA256).Hash
$formalBitSha = (Get-FileHash -LiteralPath $formalBitPath -Algorithm SHA256).Hash
if ($synthDcpSha -cne $expectedSynthDcpSha) { throw "independent synth DCP SHA mismatch: $synthDcpSha" }
if ($formalBitSha -cne $expectedFormalBitSha) { throw "independent formal bit SHA mismatch: $formalBitSha" }
Require-Value $result 'R1H_BIT_SHA256' $bitSha $resultPath
Require-Value $result 'R1H_ROUTED_DCP_SHA256' $routedDcpSha $resultPath
Require-Value $preBit 'R1H_ROUTED_DCP_SHA256' $routedDcpSha $preBitPath

$resultSha = (Get-FileHash -LiteralPath $resultPath -Algorithm SHA256).Hash
$preBitSha = (Get-FileHash -LiteralPath $preBitPath -Algorithm SHA256).Hash
$postOptSha = (Get-FileHash -LiteralPath $postOptPath -Algorithm SHA256).Hash
$identitySha = (Get-FileHash -LiteralPath $identityPath -Algorithm SHA256).Hash
$lines = @(
    'R1H_R4_IMPLEMENTATION_LAUNCH_RELEASE=PASS',
    'RELEASE_SCOPE=MINIMAL_LIVE_SAFETY_CHECKS_THEN_EXACT_BINDING',
    'FPGA_PROGRAMMING_RELEASED_BY_THIS_RECEIPT=NO',
    'MANDATORY_FORMAL_BOOTSTRAP_RELEASE_CONDITION=R1H_R4_MINIMAL_HARDWARE_SAFETY_GATE_PASS_AND_HARDWARE_BINDING_PASS',
    "R1H_SOURCE_COMMIT=$expectedCommit", "R1H_SOURCE_TREE=$expectedTree",
    "R1H_SYNTH_DCP_PATH=$synthDcpPath", "R1H_SYNTH_DCP_BYTES=$($synthDcpItem.Length)",
    "R1H_SYNTH_DCP_SHA256=$synthDcpSha",
    "R1H_IMPLEMENTATION_RESULT_PATH=$resultPath", "R1H_IMPLEMENTATION_RESULT_SHA256=$resultSha",
    "R1H_PRE_BITSTREAM_GATE_PATH=$preBitPath", "R1H_PRE_BITSTREAM_GATE_SHA256=$preBitSha",
    "R1H_POST_OPT_GATE_PATH=$postOptPath", "R1H_POST_OPT_GATE_SHA256=$postOptSha",
    "R1H_SAME_SESSION_IDENTITY_PATH=$identityPath", "R1H_SAME_SESSION_IDENTITY_SHA256=$identitySha",
    "R1H_BIT_PATH=$bitPath", "R1H_BIT_BYTES=$($bitItem.Length)", "R1H_BIT_SHA256=$bitSha",
    "R1H_ROUTED_DCP_PATH=$routedDcpPath", "R1H_ROUTED_DCP_BYTES=$($routedDcpItem.Length)",
    "R1H_ROUTED_DCP_SHA256=$routedDcpSha",
    "FORMAL_BIT_PATH=$formalBitPath", "FORMAL_BIT_BYTES=$($formalBitItem.Length)",
    "FORMAL_BIT_SHA256=$formalBitSha",
    "POST_OPT_SLICE_LUTS=$($result['POST_OPT_SLICE_LUTS'])",
    "POST_OPT_SLICE_REGISTERS=$($result['POST_OPT_SLICE_REGISTERS'])",
    "POST_OPT_RESOURCE_CLASS=$($result['POST_OPT_RESOURCE_CLASS'])",
    "FINAL_SLICE_LUTS=$($result['FINAL_SLICE_LUTS'])",
    "FINAL_SLICE_REGISTERS=$($result['FINAL_SLICE_REGISTERS'])",
    "FINAL_RESOURCE_CLASS=$($result['FINAL_RESOURCE_CLASS'])",
    "WNS=$($result['WNS'])", "WHS=$($result['WHS'])",
    'ROUTE_ERRORS=0', 'UNROUTED_NETS=0', 'DRC_ERRORS=0', 'DRC_CRITICAL_WARNINGS=0',
    'SOURCE_COMMIT_TO_BIT_PROVENANCE=PASS_BY_EXACT_SHA_BOUND_DCP',
    'SSH_SESSIONS=0', 'JTAG_SESSIONS=0', 'FPGA_PROGRAMS=0', 'WARM_REBOOTS=0',
    'DRIVER_LOADS=0', 'MMIO_READS=0', 'MMIO_WRITES=0', 'DMA_TRANSFERS=0',
    'NEXT_COMMAND_1=Invoke-R1hR4JtagSafetyReadOnly.ps1',
    'NEXT_COMMAND_2=Invoke-R1hR4MinimalHostSafetyReadOnly.ps1',
    'NEXT_COMMAND_3=New-R1hR4HardwareBinding.ps1',
    'NEXT_MUTATING_ACTION_AFTER_ALL_THREE_PASS=Invoke-R1hProgramOnce.ps1 -PhaseToken Bootstrap'
)
[IO.File]::WriteAllLines($outputPath, $lines, [Text.UTF8Encoding]::new($false))
$lines
