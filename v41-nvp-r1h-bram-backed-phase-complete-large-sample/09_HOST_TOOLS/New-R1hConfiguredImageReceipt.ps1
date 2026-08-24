[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken,
    [Parameter(Mandatory)][ValidateSet('FormalReady','ValidArmA','ArmATerminalSafeDone1')][string]$ReceiptKind,
    [Parameter(Mandatory)][string]$BindingPath,
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$OperationLedgerSha256 = ''
)

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

function Require-ExactLine([string]$Path,[string]$Key,[string]$Expected) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw "required receipt input is absent: $Path"}
    $text=[IO.File]::ReadAllText($Path)
    $matches=[regex]::Matches($text,'(?m)^'+[regex]::Escape($Key)+'='+[regex]::Escape($Expected)+'\r?$')
    if($matches.Count-ne1){throw "$Key=$Expected exact-line count is $($matches.Count), expected 1: $Path"}
}
function Add-Hash([Collections.Generic.List[string]]$Lines,[string]$Label,[string]$Path) {
    if(-not(Test-Path -LiteralPath $Path -PathType Leaf)){throw "required receipt input is absent: $Path"}
    $Lines.Add("INPUT_${Label}_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash)")
}

$binding=Get-R1hBindingDocument -BindingPath $BindingPath
$phase=Get-R1hPhaseSpec $PhaseToken
$directory=Assert-R1hPhaseDirectory $phase
if($ReceiptKind-eq'FormalReady' -and $phase.Kind-eq'ARM_A'){throw 'an R1h Arm-A result cannot issue a formal-ready receipt'}
if($ReceiptKind-ne'FormalReady' -and $phase.Kind-ne'ARM_A'){throw 'only an R1h Arm-A phase can issue an Arm-A receipt'}

$timing=Join-Path $directory 'PROGRAM_TIMING_RECEIPT.txt'
$immediate=Join-Path $directory 'INDEPENDENT_DONE_RECEIPT.txt'
Require-ExactLine $timing PROGRAM_RESULT PASS_STARTUP_HIGH_DONE_1
Require-ExactLine $timing PROGRAM_INVOCATIONS 1
Require-ExactLine $timing PROGRAM_RETRIES 0
Require-ExactLine $immediate INDEPENDENT_DONE_GATE PASS_SELECTED_TARGET_DONE_1
Require-ExactLine $immediate FPGA_DONE 1
Require-ExactLine $immediate FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT 0

$receiptType=switch($ReceiptKind){'FormalReady'{'FORMAL_READY_RECEIPT'}'ValidArmA'{'VALID_ARM_A_RECEIPT'}'ArmATerminalSafeDone1'{'ARM_A_TERMINAL_SAFE_DONE1_RECEIPT'}}
$output=if($PhaseToken-eq'Bootstrap') {
    Join-Path $script:R1hPrecheckRoot 'FORMAL_START_READY_RECEIPT.txt'
} else {
    Join-Path $directory ($receiptType+'.txt')
}
if(Test-Path -LiteralPath $output){throw "refusing to overwrite configured-image receipt: $output"}

$lines=[Collections.Generic.List[string]]::new()
foreach($line in @(
    "RECEIPT_TYPE=$receiptType",'RECEIPT_STATUS=PASS',"PHASE_TOKEN=$PhaseToken",
    "R1H_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    'FPGA_DONE=1','PROGRAM_RETRIES=0','RECEIPT_CREATION_LIVE_ACTIONS=0',
    "RECEIPT_UTC=$([DateTime]::UtcNow.ToString('o'))"
)){$lines.Add($line)}
Add-Hash $lines PROGRAM_TIMING $timing
Add-Hash $lines INDEPENDENT_DONE $immediate
$lines.Add('SAME_SESSION_DONE=1')
$lines.Add('INDEPENDENT_IMMEDIATE_DONE=1')

if($ReceiptKind-eq'ArmATerminalSafeDone1') {
    $lines.Add('ARM_A_SAMPLE_VALID=NO')
    $lines.Add('ARM_A_TERMINAL_SAFE_DONE1=YES')
    $lines.Add('ARM_A_TERMINAL_CLASSIFICATION=R1H_INFRASTRUCTURE_INVALID')
} else {
    if($OperationLedgerSha256-notmatch'^[0-9A-Fa-f]{64}$'){throw "$ReceiptKind requires an exact operation-ledger SHA-256"}
    $wait=Join-Path $directory 'PROGRAM_WAIT_RECEIPT.txt'
    $reboot=Join-Path $directory 'WARM_REBOOT_EVIDENCE.log'
    $cycle=Join-Path $directory 'HOST_CYCLE_RECEIPT.txt'
    $preloader=Join-Path $directory 'PRELOADER_EVIDENCE.log'
    $preloaderAdapter=Join-Path $directory 'PRELOADER_PAYLOAD_ADAPTER_RECEIPT.txt'
    $loader=Join-Path $directory 'LOADER_EVIDENCE.log'
    $runtimeProvenance=Join-Path $directory 'RUNTIME_PROVENANCE_EVIDENCE.log'
    $telemetry=Join-Path $directory 'TELEMETRY_EVIDENCE.log'
    $finalDone=Join-Path $directory 'FINAL_DONE_RECEIPT.txt'
    Require-ExactLine $wait WAIT_GATE PASS
    Require-ExactLine $reboot RESULT PASS
    Require-ExactLine $reboot EXIT_CODE 0
    Require-ExactLine $cycle HOST_CYCLE_GATE PASS_HOST_DISAPPEARED_AND_RETURNED
    Require-ExactLine $preloader RESULT PASS
    Require-ExactLine $preloader EXIT_CODE 0
    Require-ExactLine $preloaderAdapter ADAPTED_PAYLOAD_SHA256_GATE PASS
    Require-ExactLine $loader RESULT PASS
    Require-ExactLine $loader EXIT_CODE 0
    Require-ExactLine $runtimeProvenance RESULT PASS
    Require-ExactLine $runtimeProvenance EXIT_CODE 0
    Require-ExactLine $runtimeProvenance RUNTIME_PROVENANCE_GATE PASS
    Require-ExactLine $runtimeProvenance MMIO_ACCESS READ_ONLY
    Require-ExactLine $telemetry RESULT PASS
    Require-ExactLine $telemetry EXIT_CODE 0
    Require-ExactLine $telemetry READ_ONLY YES
    Require-ExactLine $telemetry STATIC_SNAPSHOTS_MATCH YES
    Require-ExactLine $finalDone INDEPENDENT_DONE_GATE PASS_SELECTED_TARGET_DONE_1
    Require-ExactLine $finalDone DONE_STAGE FINAL_POST_PHASE
    Require-ExactLine $finalDone FPGA_DONE 1
    $hashInputs=[ordered]@{WAIT=$wait;WARM_REBOOT=$reboot;HOST_CYCLE=$cycle;PRELOADER_ADAPTER=$preloaderAdapter;PRELOADER=$preloader;LOADER=$loader;RUNTIME_PROVENANCE=$runtimeProvenance;TELEMETRY=$telemetry;FINAL_DONE=$finalDone}
    foreach($entry in $hashInputs.GetEnumerator()) {
        Add-Hash $lines $entry.Key $entry.Value
    }
    $lines.Add("OPERATION_LEDGER_SHA256=$($OperationLedgerSha256.ToUpperInvariant())")
    if($ReceiptKind-eq'ValidArmA') {
        $lines.Add("R1H_BIT_SHA256=$([string]$binding.r1hBit.sha256)")
        $lines.Add("R1H_SOURCE_COMMIT=$([string]$binding.r1hSourceCommit)")
        $lines.Add("R1H_SOURCE_TREE=$([string]$binding.r1hSourceTree)")
        $lines.Add('ARM_A_SAMPLE_VALID=YES')
        $lines.Add('ARM_A_TERMINAL_SAFE_DONE1=YES')
    } else {
        $lines.Add("FORMAL_BIT_SHA256=$([string]$binding.formalBit.sha256)")
        $lines.Add('FORMAL_IDENTITY=A40A0C07/0000400B/00031002')
        $lines.Add('DIAGNOSTIC_MAGIC=0')
        $lines.Add('FORMAL_READY=YES')
        $lines.Add("FORMAL_READY_SOURCE=R1H_${PhaseToken}_EXACT_FORMAL_CONTROL")
        $lines.Add('FINAL_PINNED_DRIVER_LOADED=YES')
    }
}
Write-R1hUtf8NoBom -Path $output -Lines $lines.ToArray()
$lines
"CONFIGURED_IMAGE_RECEIPT_PATH=$output"
"CONFIGURED_IMAGE_RECEIPT_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $output).Hash)"
