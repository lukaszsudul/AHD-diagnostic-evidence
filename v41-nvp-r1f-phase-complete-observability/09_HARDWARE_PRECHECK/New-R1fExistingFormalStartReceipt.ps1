[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$BindingPath,
    [Parameter(Mandatory)][string]$FreshStartGatePath,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-Fa-f]{64}$')][string]$FreshStartGateSha256,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-Fa-f]{64}$')][string]$OperationLedgerSha256
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. 'C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\08_HOST_TOOLS\R1fCampaignCommon.ps1'

function Require([string]$Text,[string]$Key,[string]$Expected) {
    $count=[regex]::Matches($Text,'(?m)^'+[regex]::Escape($Key)+'='+[regex]::Escape($Expected)+'\r?$').Count
    if($count-ne1){throw "$Key=$Expected exact-line count is $count, expected 1"}
}

$binding=Get-R1fBindingDocument -BindingPath $BindingPath
$gate=(Resolve-Path -LiteralPath $FreshStartGatePath -ErrorAction Stop).Path
$actual=(Get-FileHash -Algorithm SHA256 -LiteralPath $gate).Hash
if($actual-cne$FreshStartGateSha256.ToUpperInvariant()){throw 'fresh formal-start gate SHA-256 mismatch'}
$text=[IO.File]::ReadAllText($gate)
foreach($pair in @(
    @('FORMAL_START_GATE','PASS_EXISTING_EXACT_FORMAL'),@('KERNEL','7.0.0-29-generic'),
    @('NEXT_REBOOT_KERNEL','7.0.0-29-generic'),@('ENDPOINT_COUNT','1'),
    @('ENDPOINT_IDENTITY','10ee:7011/subsystem_0007/class_058000'),@('LINK','GEN1_X1'),
    @('BAR0_BYTES','131072'),@('BAR1_BYTES','65536'),@('PINNED_DRIVER','PASS'),
    @('FORMAL_IDENTITY','A40A0C07/0000400B/00031002'),@('DIAGNOSTIC_MAGIC','0'),
    @('NODE_OWNERS','0'),@('TASK_DMA','0'),@('KERNEL_AER_HEALTH','PASS'),
    @('SELECTED_JTAG','Xilinx/80802026a98b01'),@('FPGA_PART','xc7a35t'),
    @('FPGA_IDCODE','0362D093'),@('DONE','1'),@('JTAG_FREQUENCY_CHANGED','NO'),
    @('READ_ONLY_GATE','YES')
)) { Require $text $pair[0] $pair[1] }
$target=[regex]::Match($text,'(?m)^R1F_FULL_JTAG_TARGET_PATH=([^\r\n]+)\r?$')
if(-not$target.Success-or$target.Groups[1].Value-cne[string]$binding.selectedFullJtagTargetPath){throw 'fresh gate selected full target path mismatch'}
$out=Join-Path $script:R1fPrecheckRoot 'FORMAL_START_READY_RECEIPT.txt'
if(Test-Path -LiteralPath $out){throw 'refusing to overwrite formal-start receipt'}
Write-R1fUtf8NoBom -Path $out -Lines @(
    'RECEIPT_TYPE=FORMAL_READY_RECEIPT','RECEIPT_STATUS=PASS','PHASE_TOKEN=EXISTING_FORMAL_START',
    "R1F_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",'FPGA_DONE=1',
    'PROGRAMS_USED_TO_CREATE_RECEIPT=0','WARM_REBOOTS_USED_TO_CREATE_RECEIPT=0','DRIVER_LOADS_USED_TO_CREATE_RECEIPT=0',
    "FORMAL_BIT_SHA256=$([string]$binding.formalBit.sha256)",'FORMAL_IDENTITY=A40A0C07/0000400B/00031002',
    'DIAGNOSTIC_MAGIC=0','FORMAL_READY=YES','FORMAL_READY_SOURCE=FRESH_EXISTING_EXACT_FORMAL_STATE',
    "FRESH_START_GATE_SHA256=$actual","OPERATION_LEDGER_SHA256=$($OperationLedgerSha256.ToUpperInvariant())",
    "RECEIPT_UTC=$([DateTime]::UtcNow.ToString('o'))"
)
Get-Content -LiteralPath $out
"FORMAL_START_READY_RECEIPT_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $out).Hash)"

