[CmdletBinding()]
param()

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture=[Globalization.CultureInfo]::InvariantCulture
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

function Read-UniqueKv([string]$Path) {
    $map=[Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach($line in [IO.File]::ReadAllLines($Path)) {
        if([string]::IsNullOrWhiteSpace($line)){continue}
        $i=$line.IndexOf('=');if($i-le0){throw "invalid key/value line in ${Path}: $line"}
        if(-not$map.TryAdd($line.Substring(0,$i),$line.Substring($i+1))){throw "duplicate key in ${Path}: $($line.Substring(0,$i))"}
    };$map
}
function Require-Kv($Map,[string]$Key,[string]$Expected,[string]$Source) {
    $actual=if($Map.ContainsKey($Key)){$Map[$Key]}else{'<MISSING>'}
    if($actual-cne$Expected){throw "$Key mismatch in ${Source}: $actual != $Expected"}
}
function LogValue([string]$Text,[string]$Key) {
    $m=[regex]::Matches($Text,'(?m)^'+[regex]::Escape($Key)+'=([^\r\n]*)\r?$')
    if($m.Count-ne1){throw "$Key exact-line count is $($m.Count), expected 1"};$m[0].Groups[1].Value
}

$bindingPath=Join-Path $script:R1hPrecheckRoot 'R1H_R4_HARDWARE_BINDING.json'
$binding=Get-R1hBindingDocument -BindingPath $bindingPath
Assert-R1hAcceptedToolSet
$phase=Get-R1hPhaseSpec A1;$directory=Assert-R1hPhaseDirectory $phase
$reservationPath=Join-Path $directory 'PROGRAM_ATTEMPT_RESERVATION.txt'
$logPath=Join-Path $directory 'PROGRAM_VIVADO.log';$journalPath=Join-Path $directory 'PROGRAM_VIVADO.jou'
$supervisorPath=Join-Path $directory 'PROGRAM_SUPERVISOR.log'
$timingPath=Join-Path $directory 'PROGRAM_TIMING_RECEIPT.txt'
$recoveryPath=Join-Path $directory 'PROGRAM_POSTPROCESS_RECOVERY_RECEIPT.txt'
foreach($p in @($supervisorPath,$timingPath,$recoveryPath)){if(Test-Path -LiteralPath $p){throw "refusing to overwrite A1 recovery evidence: $p"}}
foreach($p in @($reservationPath,$logPath,$journalPath,$bindingPath)){if(-not(Test-Path -LiteralPath $p -PathType Leaf)){throw "missing immutable A1 input: $p"}}

$reservation=Read-UniqueKv $reservationPath
$bitPath=[string]$binding.r1hBit.path;$bitSha=(Get-FileHash -LiteralPath $bitPath -Algorithm SHA256).Hash
$configuredPath='C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\hardware\FORMAL_START_READY_RECEIPT.txt'
foreach($pair in @(
    @('PHASE_TOKEN','A1'),@('PROGRAM_ROLE','ARM_A_R1E'),@('OBSERVER_MODE','TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'),
    @('GLOBAL_RETRY_ATTEMPT','NO'),@('PROGRAM_INVOCATION_GLOBAL_MAX','8'),@('BIT_PATH',$bitPath),
    @('BIT_SHA256',[string]$binding.r1hBit.sha256),@('CONFIGURED_RECEIPT_PATH',$configuredPath),
    @('RESERVATION_IMMUTABLE','YES')
)){Require-Kv $reservation $pair[0] $pair[1] $reservationPath}
if($bitSha-cne'73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41'){throw "R1h bit SHA mismatch: $bitSha"}
$configuredSha=(Get-FileHash -LiteralPath $configuredPath -Algorithm SHA256).Hash
Require-Kv $reservation 'CONFIGURED_RECEIPT_SHA256' $configuredSha $reservationPath
$configured=Read-UniqueKv $configuredPath
foreach($pair in @(
    @('RECEIPT_TYPE','FORMAL_READY_RECEIPT'),@('RECEIPT_STATUS','PASS'),
    @('R1H_FULL_JTAG_TARGET_PATH',[string]$binding.selectedFullJtagTargetPath),
    @('FPGA_DONE','1'),@('FORMAL_BIT_SHA256','7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'),
    @('FORMAL_IDENTITY','A40A0C07/0000400B/00031002'),@('DIAGNOSTIC_MAGIC','0'),@('FORMAL_READY','YES')
)){Require-Kv $configured $pair[0] $pair[1] $configuredPath}

$log=[IO.File]::ReadAllText($logPath)
if([regex]::Matches($log,'(?m)^ERROR:').Count-ne0){throw 'A1 Vivado program log contains ERROR lines'}
if([regex]::Matches($log,'(?m)^program_hw_devices:').Count-ne1){throw 'A1 log does not prove exactly one program_hw_devices completion'}
if([regex]::Matches($log,'(?m)^INFO: \[Common 17-206\] Exiting Vivado at ').Count-ne1){throw 'A1 log lacks one normal Vivado exit'}
foreach($pair in @(
    @('PROGRAM_ROLE','ARM_A_R1E'),@('OBSERVER_MODE','TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'),
    @('PROVEN_CONFIGURED_IMAGE_RECEIPT','FORMAL_READY_RECEIPT'),
    @('R6_SELECTED_JTAG_CANONICAL_ID','Xilinx/80802026a98b01'),
    @('R7_FULL_JTAG_TARGET_PATH',[string]$binding.selectedFullJtagTargetPath),
    @('PREPROGRAM_DONE_SAMPLE_COUNT','5'),@('PREPROGRAM_DONE_SAMPLES','1,1,1,1,1'),
    @('PREPROGRAM_DONE_READABLE','YES_5_OF_5'),@('PREPROGRAM_DONE_STABLE','YES'),
    @('TARGET_PART_IDCODE_STABLE','YES'),@('PREPROGRAM_DONE_VALUE','1'),
    @('PREPROGRAM_DONE_0_ACCEPTED','NO_TRANSITION_MODE'),
    @('PREPROGRAM_DONE_1_ACCEPTED','YES_TRANSITION_MODE_WITH_VALID_RECEIPT'),
    @('PROGRAM_PRECONDITION','PASS'),@('PROGRAM_INVOCATION_CONSUMED','1'),
    @('PROGRAM_DONE','1'),@('FRESH_DONE_OBSERVATION','1'),@('PROGRAM_INVOCATIONS','1'),
    @('PROGRAM_TCL_RESULT','PASS_DONE_1')
)){if((LogValue $log $pair[0])-cne$pair[1]){throw "$($pair[0]) mismatch in immutable A1 log"}}
foreach($n in 1..5){foreach($pair in @(
    @("PREPROGRAM_SAMPLE_${n}_PART",'xc7a35t'),@("PREPROGRAM_SAMPLE_${n}_IDCODE",'0362D093'),
    @("PREPROGRAM_DONE_SAMPLE_${n}",'1'),@("PREPROGRAM_REFRESH_${n}",'PASS')
)){if((LogValue $log $pair[0])-cne$pair[1]){throw "$($pair[0]) mismatch in immutable A1 log"}}}

$reservationUtc=[DateTimeOffset]::ParseExact($reservation['RESERVATION_UTC'],'o',[Globalization.CultureInfo]::InvariantCulture)
$startText=LogValue $log PROGRAM_START_UTC;$returnText=LogValue $log I25_PROGRAM_RETURN_MARKER
$freshText=LogValue $log I25_FRESH_DONE_MARKER;$endText=LogValue $log PROGRAM_END_UTC
$start=[DateTimeOffset]::Parse($startText,[Globalization.CultureInfo]::InvariantCulture)
$return=[DateTimeOffset]::Parse($returnText,[Globalization.CultureInfo]::InvariantCulture)
$fresh=[DateTimeOffset]::Parse($freshText,[Globalization.CultureInfo]::InvariantCulture)
$end=[DateTimeOffset]::Parse($endText,[Globalization.CultureInfo]::InvariantCulture)
if($reservationUtc-gt$start-or$start-gt$return-or$return-gt$end-or$fresh-gt$end){throw 'A1 reservation/program UTC ordering incoherent'}

$anchor=[Diagnostics.Stopwatch]::GetTimestamp();$frequency=[Diagnostics.Stopwatch]::Frequency
$records=[Collections.Generic.List[object]]::new();[long]$sequence=0
foreach($line in [IO.File]::ReadAllLines($logPath)){$sequence++;$records.Add([pscustomobject]@{Sequence=$sequence;Tick=$anchor;Stream='IMMUTABLE_VIVADO_LOG';Line=$line;Raw=$line})}
foreach($line in @('TIMED_OUT=NO','PROCESS_EXIT_CODE=0')){$sequence++;$records.Add([pscustomobject]@{Sequence=$sequence;Tick=$anchor;Stream='POSTPROCESS_DERIVED_FROM_NORMAL_VIVADO_EXIT';Line=$line;Raw=$line})}
. $script:R1hAcceptedTools.ProgramObserverParser.Path
$result=Test-I25ProgramObserver -Records $records.ToArray()
if($result.CLASSIFICATION-cne'PASS_STARTUP_HIGH_DONE_1'-or$result.PROGRAM_INVOCATION_CONSUMED_COUNT-ne1-or$result.COUNT_GATE-cne'PASS'-or$result.ORDER_GATE-cne'PASS'-or$result.VENDOR_STARTUP_HIGH_COUNT-ne1-or$result.PROGRAM_RETURN_MARKER_COUNT-ne1-or$result.FRESH_DONE_MARKER_COUNT-ne1){throw 'accepted observer parser rejected immutable A1 log'}

$reservationSha=(Get-FileHash -LiteralPath $reservationPath -Algorithm SHA256).Hash
$logSha=(Get-FileHash -LiteralPath $logPath -Algorithm SHA256).Hash
$journalSha=(Get-FileHash -LiteralPath $journalPath -Algorithm SHA256).Hash
$bindingSha=(Get-FileHash -LiteralPath $bindingPath -Algorithm SHA256).Hash
$scriptSha=(Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
Write-R1hUtf8NoBom -Path $recoveryPath -Lines @(
    'PHASE_TOKEN=A1','RECOVERY_CLASS=POSTPROCESS_ONLY_COMPLETED_VIVADO_CHILD',
    'ORIGINAL_WRAPPER_RESULT=FAIL_TASK_LOCAL_EMPTY_OBSERVER_LINE_BINDING',
    'ORIGINAL_WRAPPER_EXCEPTION=Cannot bind argument to parameter Line because it is an empty string.',
    'VIVADO_CHILD_TERMINAL_RESULT=PASS_DONE_1','VIVADO_CHILD_NORMAL_EXIT=YES',
    'PROGRAM_INVOCATIONS=1','PROGRAM_RETRIES=0','SECOND_PROGRAM_SESSION_RUN=NO',
    'REBOOT_AFTER_WRAPPER_FAILURE=NO','TELEMETRY_AFTER_WRAPPER_FAILURE=NO',
    "PROGRAM_ATTEMPT_RESERVATION_SHA256=$reservationSha","PROGRAM_VIVADO_LOG_SHA256=$logSha",
    "PROGRAM_VIVADO_JOURNAL_SHA256=$journalSha","HARDWARE_BINDING_SHA256=$bindingSha",
    "CONFIGURED_RECEIPT_SHA256=$configuredSha","R1H_BIT_SHA256=$bitSha",
    "PROGRAM_TCL_SHA256=$($script:R1hAcceptedTools.ModeAwareObserverTcl.Sha256)",
    "OBSERVER_PARSER_SHA256=$($script:R1hAcceptedTools.ProgramObserverParser.Sha256)",
    "TARGET_SELECTOR_SHA256=$($script:R1hAcceptedTools.SelectedTargetSelector.Sha256)",
    "ORIGINAL_PROGRAM_START_UTC=$startText","ORIGINAL_PROGRAM_RETURN_UTC=$returnText",
    "ORIGINAL_FRESH_DONE_UTC=$freshText","ORIGINAL_PROGRAM_END_UTC=$endText",
    "STOPWATCH_FREQUENCY=$frequency","CONSERVATIVE_RECOVERY_REFERENCE_TICKS=$anchor",
    'CONSERVATIVE_REFERENCE_AFTER_COMPLETED_PROGRAM_LOG_VALIDATION=YES',
    "RECOVERY_SCRIPT_SHA256=$scriptSha",'RECOVERY_GATE=PASS_NO_HARDWARE_ACCESS'
)
$recoverySha=(Get-FileHash -LiteralPath $recoveryPath -Algorithm SHA256).Hash
$header=@(
    'PHASE_TOKEN=A1','PROGRAM_ROLE=ARM_A_R1E','OBSERVER_MODE=TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE',
    'PROVEN_CONFIGURED_IMAGE_RECEIPT=FORMAL_READY_RECEIPT',"CONFIGURED_RECEIPT_PATH=$configuredPath",
    "CONFIGURED_RECEIPT_SHA256=$configuredSha","R1H_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    "BIT_PATH=$bitPath","BIT_FILENAME=$([string]$binding.r1hBit.filename)","BIT_SIZE=$([long]$binding.r1hBit.bytes)",
    "BIT_SHA256=$bitSha","SOURCE_COMMIT=$([string]$binding.r1hBit.sourceCommit)","SOURCE_TREE=$([string]$binding.r1hBit.sourceTree)",
    "PROGRAM_TCL_PATH=$($script:R1hAcceptedTools.ModeAwareObserverTcl.Path)","PROGRAM_TCL_SHA256=$($script:R1hAcceptedTools.ModeAwareObserverTcl.Sha256)",
    "OBSERVER_PARSER_PATH=$($script:R1hAcceptedTools.ProgramObserverParser.Path)","OBSERVER_PARSER_SHA256=$($script:R1hAcceptedTools.ProgramObserverParser.Sha256)",
    "TARGET_SELECTOR_SHA256=$($script:R1hAcceptedTools.SelectedTargetSelector.Sha256)","STOPWATCH_FREQUENCY=$frequency",
    'ORIGINAL_WRAPPER_PROCESS_EXIT_CODE=1','ORIGINAL_WRAPPER_FAILURE_CLASS=EMPTY_OBSERVER_LINE_PARAMETER_BINDING',
    "PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256=$recoverySha"
)
$recordLines=@($records|ForEach-Object{'SEQ={0} TICK={1} STREAM={2} LINE={3}'-f$_.Sequence,$_.Tick,$_.Stream,$_.Line})
$resultLines=@("PROGRAM_RESULT=$($result.CLASSIFICATION)","PROGRAM_INVOCATIONS=$($result.PROGRAM_INVOCATION_CONSUMED_COUNT)",'PROGRAM_RETRIES=0',"COUNT_GATE=$($result.COUNT_GATE)","ORDER_GATE=$($result.ORDER_GATE)","VENDOR_STARTUP_HIGH_COUNT=$($result.VENDOR_STARTUP_HIGH_COUNT)","PROGRAM_RETURN_MARKER_COUNT=$($result.PROGRAM_RETURN_MARKER_COUNT)","FRESH_DONE_MARKER_COUNT=$($result.FRESH_DONE_MARKER_COUNT)",'MODE_AWARE_PREPROGRAM_GATE=PASS','PROGRAM_SUPERVISOR_GATE=PASS_RECOVERED_POSTPROCESS_ONLY')
Write-R1hUtf8NoBom -Path $supervisorPath -Lines @($header+$recordLines+$resultLines)
$supervisorSha=(Get-FileHash -LiteralPath $supervisorPath -Algorithm SHA256).Hash
Write-R1hUtf8NoBom -Path $timingPath -Lines @(
    'PHASE_TOKEN=A1','PROGRAM_ROLE=ARM_A_R1E','OBSERVER_MODE=TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE',
    'PROVEN_CONFIGURED_IMAGE_RECEIPT=FORMAL_READY_RECEIPT',"CONFIGURED_RECEIPT_SHA256=$configuredSha",
    "R1H_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)","BIT_SHA256=$bitSha",
    "PROGRAM_TCL_SHA256=$($script:R1hAcceptedTools.ModeAwareObserverTcl.Sha256)","OBSERVER_PARSER_SHA256=$($script:R1hAcceptedTools.ProgramObserverParser.Sha256)",
    "TARGET_SELECTOR_SHA256=$($script:R1hAcceptedTools.SelectedTargetSelector.Sha256)","PROGRAM_SUPERVISOR_LOG_SHA256=$supervisorSha",
    "PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256=$recoverySha",'PROGRAM_RESULT=PASS_STARTUP_HIGH_DONE_1',
    'PROGRAM_INVOCATIONS=1','PROGRAM_RETRIES=0','MODE_AWARE_PREPROGRAM_GATE=PASS','PREPROGRAM_DONE_SAMPLES=1,1,1,1,1',
    'PREPROGRAM_DONE_VALUE=1','PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT=1',"STOPWATCH_FREQUENCY=$frequency",
    "PROGRAM_RETURN_MARKER_TICKS=$anchor","FRESH_DONE_MARKER_TICKS=$anchor","WAIT_REFERENCE_TICKS=$anchor",
    'TIMING_REFERENCE_CLASS=CONSERVATIVE_POSTPROCESS_ANCHOR_AFTER_COMPLETED_PROGRAM',
    "ORIGINAL_PROGRAM_RETURN_UTC=$returnText","ORIGINAL_FRESH_DONE_UTC=$freshText",'REQUIRED_MINIMUM_WAIT_SECONDS=33.536673744',
    "TIMING_RECEIPT_CREATED_UTC=$([DateTime]::UtcNow.ToString('o'))",'TIMING_RECEIPT_STATUS=PASS_IMMUTABLE_WAIT_INPUT_RECOVERED_POSTPROCESS_ONLY'
)
"PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256=$recoverySha"
"PROGRAM_SUPERVISOR_LOG_SHA256=$supervisorSha"
"PROGRAM_TIMING_RECEIPT_SHA256=$((Get-FileHash -LiteralPath $timingPath -Algorithm SHA256).Hash)"
'PROGRAM_SUPERVISOR_GATE=PASS_RECOVERED_POSTPROCESS_ONLY'
