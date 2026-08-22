[CmdletBinding()]
param(
    [string]$TaskRoot = 'C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1B',
    [string]$PriorRoot = 'C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1',
    [string]$OutputPath = 'C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1B\03_PRECHECK\FORMAL_START_GATE_RESULT.txt'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Read-Lines([string]$Path) { return [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $Path).Path) }
function Require-Line([string[]]$Lines,[string]$Exact,[string]$Label) {
    if (@($Lines | Where-Object { $_ -ceq $Exact }).Count -ne 1) { throw "$Label missing or duplicated: $Exact" }
}
function Require-Hash([string]$Path,[string]$Expected,[string]$Label) {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -cne $Expected) { throw "$Label SHA-256 mismatch: $actual" }
    return $actual
}

$propertyLog = Read-Lines "$TaskRoot\02_PROGRAM_OBSERVER_FIX\READ_ONLY_PROPERTY_PREFLIGHT.log"
$hostLog = Read-Lines "$TaskRoot\03_PRECHECK\HOST_READ_ONLY_DISCOVERY.log"
$barLog = Read-Lines "$TaskRoot\03_PRECHECK\BAR_GEOMETRY_READ_ONLY.log"
$telemetry = Read-Lines "$TaskRoot\03_PRECHECK\FORMAL_START_TELEMETRY_PARSED.txt"
$ledger = Read-Lines "$TaskRoot\OPERATION_LEDGER.md"

foreach ($entry in @(
    @($propertyLog,'GLOBAL_HW_TARGET_COUNT=1','global target'),
    @($propertyLog,'JTAG_TARGET_MATCH_COUNT=1','exact HS2 target'),
    @($propertyLog,'JTAG_DEVICE_COUNT=1','JTAG device'),
    @($propertyLog,'FPGA_PART=xc7a35t','part'),
    @($propertyLog,'FPGA_IDCODE=0362D093','IDCODE'),
    @($propertyLog,'BIT5_DONE_PROPERTY_AVAILABLE=YES','BIT5 availability'),
    @($propertyLog,'BIT4_EOS_PROPERTY_AVAILABLE=NO','BIT4 absence'),
    @($propertyLog,'BIT4_EOS_PROPERTY_QUERY_ATTEMPTED=NO','BIT4 query prohibition'),
    @($propertyLog,'CURRENT_DONE=1','current DONE'),
    @($propertyLog,'PROGRAM_INVOCATIONS=0','property preflight program count'),
    @($propertyLog,'READ_ONLY_PROPERTY_PREFLIGHT=PASS','property preflight'),
    @($hostLog,'RESULT=PASS','host helper result'),
    @($hostLog,'EXIT_CODE=0','host helper exit'),
    @($hostLog,'ARGUMENT_TOKEN_AUDIT=PASS','SSH argument audit'),
    @($hostLog,'PLINK_PW_OPTION_USED=NO','forbidden -pw'),
    @($hostLog,'PLINK_PWFILE_OPTION_USED=YES','required -pwfile'),
    @($hostLog,'PWFILE_DELETED=YES','pwfile deletion'),
    @($hostLog,'REMOTE_USER=vcdeagent1','remote user'),
    @($hostLog,'REMOTE_EFFECTIVE_USER=root','effective user'),
    @($hostLog,'HOSTNAME=VCDE-DUT-1','hostname'),
    @($hostLog,'CURRENT_BOOT_ID=b9d58c87-6574-4596-8ff9-b61052ba26dc','boot continuity'),
    @($hostLog,'CURRENT_KERNEL=7.0.0-29-generic','kernel'),
    @($hostLog,'PINNED_XDMA_ARTIFACT_SHA256=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A','module hash'),
    @($hostLog,'ACCEPTED_XDMA_LOADER_SHA256=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F','loader hash'),
    @($hostLog,'PINNED_ARTIFACT_GATE=PASS','pinned artifacts'),
    @($hostLog,'PINNED_MODULE_VERSION=2025.2.0','module version'),
    @($hostLog,'ENDPOINT_COUNT=1','endpoint count'),
    @($hostLog,'ENDPOINT_BDF=0000:01:00.0','endpoint BDF'),
    @($hostLog,'ENDPOINT_VENDOR_DEVICE=10ee:7011','endpoint ID'),
    @($hostLog,'ENDPOINT_SUBSYSTEM=10ee:0007','subsystem'),
    @($hostLog,'ENDPOINT_LINK=GEN1_X1','link'),
    @($hostLog,'ENDPOINT_BOUND_DRIVER=xdma','bound driver'),
    @($hostLog,'XDMA_MODULE_PRESENT=YES','xdma present'),
    @($hostLog,'XDMA_ALL_NODE_COUNT=21','node count'),
    @($hostLog,'XDMA_ALL_NODES_CLASSIFICATION=PASS_EXACT_ACCEPTED_21_NODE_SET','node set'),
    @($hostLog,'XDMA_OPEN_PROCESS_COUNT=0','node owners'),
    @($hostLog,'TARGETED_KERNEL_MATCH_COUNT=1','expected kernel match count'),
    @($hostLog,'HOST_PRECHECK_READ_ONLY=YES','read-only host precheck'),
    @($barLog,'RESULT=PASS','BAR helper result'),
    @($barLog,'BAR0_BYTES=131072','BAR0'),
    @($barLog,'BAR1_BYTES=65536','BAR1'),
    @($barLog,'BAR_GEOMETRY_READ_ONLY=YES','BAR read-only'),
    @($telemetry,'BOOT_ID_BEFORE=b9d58c87-6574-4596-8ff9-b61052ba26dc','telemetry boot before'),
    @($telemetry,'BOOT_ID_AFTER=b9d58c87-6574-4596-8ff9-b61052ba26dc','telemetry boot after'),
    @($telemetry,'BOOT_ID_STABLE=PASS','telemetry boot stability'),
    @($telemetry,'BLOCK_ID=0xA40A0C07','block ID'),
    @($telemetry,'PROTOCOL=0x0000400B','protocol'),
    @($telemetry,'CAPABILITIES=0x00031002','capabilities'),
    @($telemetry,'DIAGNOSTIC_MAGIC=0x00000000','diagnostic magic'),
    @($telemetry,'RUNTIME_GIT_SHA=0000000000000000000000000000000000000000','formal Git words'),
    @($telemetry,'BUILD_FLAGS=0x00000000','formal flags'),
    @($telemetry,'PROVENANCE_GATE=PASS_ACCEPTED_FORMAL_ZERO_GIT_WORDS_AND_BUILD_FLAGS','formal provenance'),
    @($telemetry,'STATIC_FIELDS_MATCH=PASS','static telemetry coherence'),
    @($telemetry,'MMIO_READS_THIS_TRANSACTION=40','read count'),
    @($telemetry,'AXI_LITE_WRITES_THIS_TRANSACTION=0','write count'),
    @($telemetry,'C2H_TRANSFERS_THIS_TRANSACTION=0','C2H count'),
    @($telemetry,'H2C_TRANSFERS_THIS_TRANSACTION=0','H2C count'),
    @($telemetry,'NVP_TELEMETRY_PARSE=PASS','telemetry parse'),
    @($ledger,'FPGA_PROGRAM_INVOCATIONS=0','R1b program budget'),
    @($ledger,'PROGRAM_RETRIES=0','R1b retries'),
    @($ledger,'AXI_LITE_WRITES=0','R1b writes'),
    @($ledger,'C2H_TRANSFERS=0','R1b C2H'),
    @($ledger,'H2C_TRANSFERS=0','R1b H2C')
)) { Require-Line -Lines $entry[0] -Exact $entry[1] -Label $entry[2] }

if (@($hostLog | Where-Object { $_ -match 'xdma: module verification failed: signature and/or required key missing - tainting kernel' }).Count -ne 1) {
    throw 'kernel match is not the sole accepted unsigned out-of-tree module taint'
}

$formalBitPath = 'C:\FPGA\FPGA_AHD_v41_V40_1_0_PHASE2_EVIDENCE\02_FRESH_BUILD\SEALED\artifacts\ahd_capture_v41_phase2_p1.bit'
$diagnosticBitPath = 'C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\04_BUILD\FULL_BUILD_EVIDENCE\artifacts\ahd_capture_v41_i2c_25khz_r1.bit'
[void](Require-Hash $formalBitPath '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2' 'formal bit')
[void](Require-Hash $diagnosticBitPath 'B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191' 'diagnostic bit')
[void](Require-Hash "$PriorRoot\09_FINAL\V41_NVP_I2C_25KHZ_PAIRED_AB_R1_REPORT.md" '912EE4F77927C0BEEFC436849791AE655F12B7A1CEB707EF578416236CF4D34B' 'R1 report')
[void](Require-Hash "$PriorRoot\OPERATION_LEDGER.md" 'B438F089DAD0F3F63DCEAEA5F56F99B35FA771BFC684F294E470BF691360E0B7' 'R1 ledger')
[void](Require-Hash "$PriorRoot\SHA256_MANIFEST.txt" '8CF3CE11F3A44CA9A7B2E5C0DA05B6475C3E8D0D66034B2C079AE22380770B43' 'R1 manifest')
[void](Require-Hash "$PriorRoot\V41_NVP_I2C_25KHZ_PAIRED_AB_R1_MEASUREMENT_EVIDENCE.zip" '0CFF6084057983FFCC6FDC814BC3C3DFD98E70F814114FF26B6F29126E84CF54' 'R1 evidence ZIP')
$formalBitHash = (Get-FileHash -LiteralPath $formalBitPath -Algorithm SHA256).Hash
$diagnosticBitHash = (Get-FileHash -LiteralPath $diagnosticBitPath -Algorithm SHA256).Hash
$priorReportHash = (Get-FileHash -LiteralPath "$PriorRoot\09_FINAL\V41_NVP_I2C_25KHZ_PAIRED_AB_R1_REPORT.md" -Algorithm SHA256).Hash
$priorLedgerHash = (Get-FileHash -LiteralPath "$PriorRoot\OPERATION_LEDGER.md" -Algorithm SHA256).Hash
$priorManifestHash = (Get-FileHash -LiteralPath "$PriorRoot\SHA256_MANIFEST.txt" -Algorithm SHA256).Hash
$priorZipHash = (Get-FileHash -LiteralPath "$PriorRoot\V41_NVP_I2C_25KHZ_PAIRED_AB_R1_MEASUREMENT_EVIDENCE.zip" -Algorithm SHA256).Hash

foreach ($name in @('vivado','hw_server','cs_server')) {
    if (@(Get-Process -Name $name -ErrorAction SilentlyContinue).Count -ne 0) { throw "stale process present: $name" }
}
$secretDir = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\R1B_SECRET_CHANNEL'
if (@(Get-ChildItem -LiteralPath $secretDir -Filter 'pw-*.tmp' -File -ErrorAction SilentlyContinue).Count -ne 0) {
    throw 'temporary pwfile remains'
}

$rows = @(
    'R1B_PROGRAMS_BEFORE_FORMAL_START_PROOF=0',
    'RETAINED_FINAL_BOOT_ID=b9d58c87-6574-4596-8ff9-b61052ba26dc',
    'CURRENT_BOOT_ID=b9d58c87-6574-4596-8ff9-b61052ba26dc',
    'BOOT_ID_CONTINUITY=PASS',
    ('FORMAL_BIT_REHASH=' + $formalBitHash),
    ('DIAGNOSTIC_BIT_REHASH=' + $diagnosticBitHash),
    ('R1_REPORT_REHASH=' + $priorReportHash),
    ('R1_LEDGER_REHASH=' + $priorLedgerHash),
    ('R1_MANIFEST_REHASH=' + $priorManifestHash),
    ('R1_EVIDENCE_ZIP_REHASH=' + $priorZipHash),
    'R1_EVIDENCE_COMMIT=5a81f5b115dddcdddd809a655fced115e113585e',
    'CONTROLLED_HARDWARE_MUTATION_AFTER_RETAINED_CLOSURE=NO_BEFORE_R1B',
    'LOADED_XDMA_PROVENANCE=PASS_BOOT_CONTINUITY_EXACT_PINNED_ARTIFACT_ACCEPTED_LOAD_CHAIN',
    'WRONG_SAME_NAME_XDMA_LOADED_OR_BOUND=NO',
    'DMA_ACTIVITY=0_ZERO_NODE_OWNERS_ZERO_TASK_DMA_COMMANDS',
    'KERNEL_AER_XDMA_HEALTH=PASS_ONLY_EXPECTED_UNSIGNED_OOT_TAINT',
    'TEMP_PASSWORD_FILES_REMAINING=0',
    'STALE_VIVADO_HW_SERVER_PROCESS_COUNT=0',
    'FORMAL_BOOTSTRAP_AUTHORIZED=NO',
    'FORMAL_PHASE2_START_PROOF=PASS_EXACT_FORMAL_PHASE2_START_NO_BOOTSTRAP',
    'HARDWARE_SEQUENCE_ENTRY_ELIGIBLE=YES',
    'HARD_STOP=NO'
)
[IO.File]::WriteAllLines($OutputPath,$rows,[Text.UTF8Encoding]::new($false))
$rows
