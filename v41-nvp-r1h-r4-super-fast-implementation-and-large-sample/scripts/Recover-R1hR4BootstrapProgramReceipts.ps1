[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

function Read-UniqueKv([string]$Path) {
    $map = [Collections.Generic.Dictionary[string,string]]::new([StringComparer]::Ordinal)
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ([string]::IsNullOrWhiteSpace($line)) { continue }
        $separator = $line.IndexOf('=')
        if ($separator -le 0) { throw "invalid key/value line in ${Path}: $line" }
        $key = $line.Substring(0,$separator)
        $value = $line.Substring($separator + 1)
        if (-not $map.TryAdd($key,$value)) { throw "duplicate key in ${Path}: $key" }
    }
    return $map
}

function Require-Kv($Map,[string]$Key,[string]$Expected,[string]$Source) {
    if (-not $Map.ContainsKey($Key) -or $Map[$Key] -cne $Expected) {
        $actual = if ($Map.ContainsKey($Key)) { $Map[$Key] } else { '<MISSING>' }
        throw "$Key mismatch in ${Source}: $actual != $Expected"
    }
}

function Get-UniqueLogValue([string]$Text,[string]$Key) {
    $matches = [regex]::Matches($Text,'(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$')
    if ($matches.Count -ne 1) { throw "$Key exact-line count is $($matches.Count), expected 1" }
    return $matches[0].Groups[1].Value
}

$bindingPath = Join-Path $script:R1hPrecheckRoot 'R1H_R4_HARDWARE_BINDING.json'
$binding = Get-R1hBindingDocument -BindingPath $bindingPath
Assert-R1hAcceptedToolSet
$phase = Get-R1hPhaseSpec Bootstrap
$phaseDirectory = Assert-R1hPhaseDirectory $phase
$reservationPath = Join-Path $phaseDirectory 'PROGRAM_ATTEMPT_RESERVATION.txt'
$vivadoLogPath = Join-Path $phaseDirectory 'PROGRAM_VIVADO.log'
$vivadoJournalPath = Join-Path $phaseDirectory 'PROGRAM_VIVADO.jou'
$supervisorLogPath = Join-Path $phaseDirectory 'PROGRAM_SUPERVISOR.log'
$timingReceiptPath = Join-Path $phaseDirectory 'PROGRAM_TIMING_RECEIPT.txt'
$recoveryReceiptPath = Join-Path $phaseDirectory 'PROGRAM_POSTPROCESS_RECOVERY_RECEIPT.txt'
foreach ($path in @($supervisorLogPath,$timingReceiptPath,$recoveryReceiptPath)) {
    if (Test-Path -LiteralPath $path) { throw "refusing to overwrite recovered Bootstrap evidence: $path" }
}
foreach ($path in @($bindingPath,$reservationPath,$vivadoLogPath,$vivadoJournalPath)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "required immutable Bootstrap input absent: $path" }
}

$reservation = Read-UniqueKv $reservationPath
$formalBitPath = [string]$binding.formalBit.path
$formalBitSha = (Get-FileHash -LiteralPath $formalBitPath -Algorithm SHA256).Hash
foreach ($pair in @(
    @('PHASE_TOKEN','Bootstrap'), @('PROGRAM_ROLE','FORMAL_BOOTSTRAP'),
    @('OBSERVER_MODE','BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM'),
    @('GLOBAL_RETRY_ATTEMPT','NO'), @('PROGRAM_INVOCATION_GLOBAL_MAX','8'),
    @('BIT_PATH',$formalBitPath), @('BIT_SHA256',[string]$binding.formalBit.sha256),
    @('CONFIGURED_RECEIPT_PATH','NOT_APPLICABLE'),
    @('CONFIGURED_RECEIPT_SHA256','NOT_APPLICABLE'), @('RESERVATION_IMMUTABLE','YES')
)) { Require-Kv $reservation $pair[0] $pair[1] $reservationPath }
if ($formalBitSha -cne '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2') {
    throw "formal bit SHA mismatch during Bootstrap recovery: $formalBitSha"
}

$logText = [IO.File]::ReadAllText($vivadoLogPath)
if ([regex]::Matches($logText,'(?m)^ERROR:').Count -ne 0) { throw 'Vivado program log contains ERROR lines' }
if ([regex]::Matches($logText,'(?m)^program_hw_devices:').Count -ne 1) {
    throw 'Vivado program log does not prove exactly one program_hw_devices completion'
}
if ([regex]::Matches($logText,'(?m)^INFO: \[Common 17-206\] Exiting Vivado at ').Count -ne 1) {
    throw 'Vivado program log does not prove one normal Vivado exit'
}
foreach ($pair in @(
    @('PROGRAM_ROLE','FORMAL_BOOTSTRAP'), @('OBSERVER_MODE','BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM'),
    @('PROVEN_CONFIGURED_IMAGE_RECEIPT','NO_RECEIPT_REQUIRED'),
    @('R6_SELECTED_JTAG_CANONICAL_ID','Xilinx/80802026a98b01'),
    @('R7_FULL_JTAG_TARGET_PATH',[string]$binding.selectedFullJtagTargetPath),
    @('PREPROGRAM_DONE_SAMPLE_COUNT','5'), @('PREPROGRAM_DONE_SAMPLES','1,1,1,1,1'),
    @('PREPROGRAM_DONE_READABLE','YES_5_OF_5'), @('PREPROGRAM_DONE_STABLE','YES'),
    @('TARGET_PART_IDCODE_STABLE','YES'), @('PREPROGRAM_DONE_VALUE','1'),
    @('PROGRAM_PRECONDITION','PASS'), @('PROGRAM_INVOCATION_CONSUMED','1'),
    @('PROGRAM_DONE','1'), @('FRESH_DONE_OBSERVATION','1'),
    @('PROGRAM_INVOCATIONS','1'), @('PROGRAM_TCL_RESULT','PASS_DONE_1')
)) {
    $actual = Get-UniqueLogValue $logText $pair[0]
    if ($actual -cne $pair[1]) { throw "$($pair[0]) mismatch in immutable program log: $actual" }
}
foreach ($sampleIndex in 1..5) {
    foreach ($pair in @(
        @("PREPROGRAM_SAMPLE_${sampleIndex}_PART",'xc7a35t'),
        @("PREPROGRAM_SAMPLE_${sampleIndex}_IDCODE",'0362D093'),
        @("PREPROGRAM_DONE_SAMPLE_${sampleIndex}",'1'),
        @("PREPROGRAM_REFRESH_${sampleIndex}",'PASS')
    )) {
        $actual = Get-UniqueLogValue $logText $pair[0]
        if ($actual -cne $pair[1]) { throw "$($pair[0]) mismatch in immutable program log: $actual" }
    }
}

$reservationUtc = [DateTimeOffset]::ParseExact($reservation['RESERVATION_UTC'],'o',[Globalization.CultureInfo]::InvariantCulture)
$programStartUtcText = Get-UniqueLogValue $logText PROGRAM_START_UTC
$programReturnUtcText = Get-UniqueLogValue $logText I25_PROGRAM_RETURN_MARKER
$freshDoneUtcText = Get-UniqueLogValue $logText I25_FRESH_DONE_MARKER
$programEndUtcText = Get-UniqueLogValue $logText PROGRAM_END_UTC
$programStartUtc = [DateTimeOffset]::Parse($programStartUtcText,[Globalization.CultureInfo]::InvariantCulture)
$programReturnUtc = [DateTimeOffset]::Parse($programReturnUtcText,[Globalization.CultureInfo]::InvariantCulture)
$freshDoneUtc = [DateTimeOffset]::Parse($freshDoneUtcText,[Globalization.CultureInfo]::InvariantCulture)
$programEndUtc = [DateTimeOffset]::Parse($programEndUtcText,[Globalization.CultureInfo]::InvariantCulture)
if ($reservationUtc -gt $programStartUtc -or $programStartUtc -gt $programReturnUtc -or
    $programReturnUtc -gt $programEndUtc -or $freshDoneUtc -gt $programEndUtc) {
    throw 'immutable reservation/program UTC ordering is incoherent'
}

# The original task-local wrapper terminated at its first attempt to pass an empty
# observer collection into Add-ObserverRecord. The Vivado child nevertheless ran
# to a normal terminal PASS. A fresh monotonic reference taken only after the
# completed log is fully validated is conservative: waiting from it cannot
# under-wait relative to the earlier real program completion.
$recoveryReferenceTicks = [Diagnostics.Stopwatch]::GetTimestamp()
$frequency = [Diagnostics.Stopwatch]::Frequency
$records = [Collections.Generic.List[object]]::new()
[long]$sequence = 0
foreach ($line in [IO.File]::ReadAllLines($vivadoLogPath)) {
    $sequence++
    $records.Add([pscustomobject]@{
        Sequence=$sequence; Tick=$recoveryReferenceTicks; Stream='IMMUTABLE_VIVADO_LOG'; Line=$line; Raw=$line
    })
}
foreach ($derivedLine in @('TIMED_OUT=NO','PROCESS_EXIT_CODE=0')) {
    $sequence++
    $records.Add([pscustomobject]@{
        Sequence=$sequence; Tick=$recoveryReferenceTicks; Stream='POSTPROCESS_DERIVED_FROM_NORMAL_VIVADO_EXIT';
        Line=$derivedLine; Raw=$derivedLine
    })
}
. $script:R1hAcceptedTools.ProgramObserverParser.Path
$result = Test-I25ProgramObserver -Records $records.ToArray()
if ($result.CLASSIFICATION -cne 'PASS_STARTUP_HIGH_DONE_1' -or
    $result.PROGRAM_INVOCATION_CONSUMED_COUNT -ne 1 -or $result.COUNT_GATE -cne 'PASS' -or
    $result.ORDER_GATE -cne 'PASS' -or $result.VENDOR_STARTUP_HIGH_COUNT -ne 1 -or
    $result.PROGRAM_RETURN_MARKER_COUNT -ne 1 -or $result.FRESH_DONE_MARKER_COUNT -ne 1) {
    throw 'exact accepted program-observer parser rejected the immutable completed Bootstrap log'
}

$reservationSha = (Get-FileHash -LiteralPath $reservationPath -Algorithm SHA256).Hash
$vivadoLogSha = (Get-FileHash -LiteralPath $vivadoLogPath -Algorithm SHA256).Hash
$vivadoJournalSha = (Get-FileHash -LiteralPath $vivadoJournalPath -Algorithm SHA256).Hash
$bindingSha = (Get-FileHash -LiteralPath $bindingPath -Algorithm SHA256).Hash
$recoveryScriptSha = (Get-FileHash -LiteralPath $PSCommandPath -Algorithm SHA256).Hash
Write-R1hUtf8NoBom -Path $recoveryReceiptPath -Lines @(
    'PHASE_TOKEN=Bootstrap', 'RECOVERY_CLASS=POSTPROCESS_ONLY_COMPLETED_VIVADO_CHILD',
    'ORIGINAL_WRAPPER_RESULT=FAIL_TASK_LOCAL_EMPTY_OBSERVER_COLLECTION_BINDING',
    'ORIGINAL_WRAPPER_EXCEPTION=Cannot bind argument to parameter Records because it is an empty collection.',
    'VIVADO_CHILD_TERMINAL_RESULT=PASS_DONE_1', 'VIVADO_CHILD_NORMAL_EXIT=YES',
    'PROGRAM_INVOCATIONS=1', 'PROGRAM_RETRIES=0', 'SECOND_PROGRAM_SESSION_RUN=NO',
    'REBOOT_AFTER_WRAPPER_FAILURE=NO', 'TELEMETRY_AFTER_WRAPPER_FAILURE=NO',
    "PROGRAM_ATTEMPT_RESERVATION_SHA256=$reservationSha", "PROGRAM_VIVADO_LOG_SHA256=$vivadoLogSha",
    "PROGRAM_VIVADO_JOURNAL_SHA256=$vivadoJournalSha", "HARDWARE_BINDING_SHA256=$bindingSha",
    "FORMAL_BIT_SHA256=$formalBitSha", "PROGRAM_TCL_SHA256=$($script:R1hAcceptedTools.ModeAwareObserverTcl.Sha256)",
    "OBSERVER_PARSER_SHA256=$($script:R1hAcceptedTools.ProgramObserverParser.Sha256)",
    "TARGET_SELECTOR_SHA256=$($script:R1hAcceptedTools.SelectedTargetSelector.Sha256)",
    "ORIGINAL_PROGRAM_START_UTC=$programStartUtcText", "ORIGINAL_PROGRAM_RETURN_UTC=$programReturnUtcText",
    "ORIGINAL_FRESH_DONE_UTC=$freshDoneUtcText", "ORIGINAL_PROGRAM_END_UTC=$programEndUtcText",
    "STOPWATCH_FREQUENCY=$frequency", "CONSERVATIVE_RECOVERY_REFERENCE_TICKS=$recoveryReferenceTicks",
    'CONSERVATIVE_REFERENCE_AFTER_COMPLETED_PROGRAM_LOG_VALIDATION=YES',
    "RECOVERY_SCRIPT_SHA256=$recoveryScriptSha", 'RECOVERY_GATE=PASS_NO_HARDWARE_ACCESS'
)
$recoveryReceiptSha = (Get-FileHash -LiteralPath $recoveryReceiptPath -Algorithm SHA256).Hash

$header = @(
    'PHASE_TOKEN=Bootstrap', 'PROGRAM_ROLE=FORMAL_BOOTSTRAP',
    'OBSERVER_MODE=BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM',
    'PROVEN_CONFIGURED_IMAGE_RECEIPT=NO_RECEIPT_REQUIRED',
    'CONFIGURED_RECEIPT_PATH=NOT_APPLICABLE', 'CONFIGURED_RECEIPT_SHA256=NOT_APPLICABLE',
    "R1H_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    "BIT_PATH=$formalBitPath", "BIT_FILENAME=$([string]$binding.formalBit.filename)",
    "BIT_SIZE=$([long]$binding.formalBit.bytes)", "BIT_SHA256=$formalBitSha",
    "SOURCE_COMMIT=$([string]$binding.formalBit.sourceCommit)",
    "SOURCE_TREE=$([string]$binding.formalBit.sourceTree)",
    "PROGRAM_TCL_PATH=$($script:R1hAcceptedTools.ModeAwareObserverTcl.Path)",
    "PROGRAM_TCL_SHA256=$($script:R1hAcceptedTools.ModeAwareObserverTcl.Sha256)",
    "OBSERVER_PARSER_PATH=$($script:R1hAcceptedTools.ProgramObserverParser.Path)",
    "OBSERVER_PARSER_SHA256=$($script:R1hAcceptedTools.ProgramObserverParser.Sha256)",
    "TARGET_SELECTOR_SHA256=$($script:R1hAcceptedTools.SelectedTargetSelector.Sha256)",
    "STOPWATCH_FREQUENCY=$frequency", 'ORIGINAL_WRAPPER_PROCESS_EXIT_CODE=1',
    'ORIGINAL_WRAPPER_FAILURE_CLASS=EMPTY_OBSERVER_COLLECTION_PARAMETER_BINDING',
    "PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256=$recoveryReceiptSha"
)
$recordLines = @($records | ForEach-Object {
    'SEQ={0} TICK={1} STREAM={2} LINE={3}' -f $_.Sequence,$_.Tick,$_.Stream,$_.Line
})
$resultLines = @(
    "PROGRAM_RESULT=$($result.CLASSIFICATION)",
    "PROGRAM_INVOCATIONS=$($result.PROGRAM_INVOCATION_CONSUMED_COUNT)", 'PROGRAM_RETRIES=0',
    "COUNT_GATE=$($result.COUNT_GATE)", "ORDER_GATE=$($result.ORDER_GATE)",
    "VENDOR_STARTUP_HIGH_COUNT=$($result.VENDOR_STARTUP_HIGH_COUNT)",
    "PROGRAM_RETURN_MARKER_COUNT=$($result.PROGRAM_RETURN_MARKER_COUNT)",
    "FRESH_DONE_MARKER_COUNT=$($result.FRESH_DONE_MARKER_COUNT)",
    'MODE_AWARE_PREPROGRAM_GATE=PASS', 'PROGRAM_SUPERVISOR_GATE=PASS_RECOVERED_POSTPROCESS_ONLY'
)
Write-R1hUtf8NoBom -Path $supervisorLogPath -Lines @($header + $recordLines + $resultLines)
$supervisorSha = (Get-FileHash -LiteralPath $supervisorLogPath -Algorithm SHA256).Hash

Write-R1hUtf8NoBom -Path $timingReceiptPath -Lines @(
    'PHASE_TOKEN=Bootstrap', 'PROGRAM_ROLE=FORMAL_BOOTSTRAP',
    'OBSERVER_MODE=BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM',
    'PROVEN_CONFIGURED_IMAGE_RECEIPT=NO_RECEIPT_REQUIRED', 'CONFIGURED_RECEIPT_SHA256=NOT_APPLICABLE',
    "R1H_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    "BIT_SHA256=$formalBitSha", "PROGRAM_TCL_SHA256=$($script:R1hAcceptedTools.ModeAwareObserverTcl.Sha256)",
    "OBSERVER_PARSER_SHA256=$($script:R1hAcceptedTools.ProgramObserverParser.Sha256)",
    "TARGET_SELECTOR_SHA256=$($script:R1hAcceptedTools.SelectedTargetSelector.Sha256)",
    "PROGRAM_SUPERVISOR_LOG_SHA256=$supervisorSha", "PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256=$recoveryReceiptSha",
    'PROGRAM_RESULT=PASS_STARTUP_HIGH_DONE_1', 'PROGRAM_INVOCATIONS=1', 'PROGRAM_RETRIES=0',
    'MODE_AWARE_PREPROGRAM_GATE=PASS', 'PREPROGRAM_DONE_SAMPLES=1,1,1,1,1',
    'PREPROGRAM_DONE_VALUE=1', 'PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT=1',
    "STOPWATCH_FREQUENCY=$frequency", "PROGRAM_RETURN_MARKER_TICKS=$recoveryReferenceTicks",
    "FRESH_DONE_MARKER_TICKS=$recoveryReferenceTicks", "WAIT_REFERENCE_TICKS=$recoveryReferenceTicks",
    'TIMING_REFERENCE_CLASS=CONSERVATIVE_POSTPROCESS_ANCHOR_AFTER_COMPLETED_PROGRAM',
    "ORIGINAL_PROGRAM_RETURN_UTC=$programReturnUtcText", "ORIGINAL_FRESH_DONE_UTC=$freshDoneUtcText",
    'REQUIRED_MINIMUM_WAIT_SECONDS=5.000000000',
    "TIMING_RECEIPT_CREATED_UTC=$([DateTime]::UtcNow.ToString('o'))",
    'TIMING_RECEIPT_STATUS=PASS_IMMUTABLE_WAIT_INPUT_RECOVERED_POSTPROCESS_ONLY'
)

"PROGRAM_POSTPROCESS_RECOVERY_RECEIPT=$recoveryReceiptPath"
"PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256=$recoveryReceiptSha"
"PROGRAM_SUPERVISOR_LOG=$supervisorLogPath"
"PROGRAM_SUPERVISOR_LOG_SHA256=$supervisorSha"
"PROGRAM_TIMING_RECEIPT=$timingReceiptPath"
"PROGRAM_TIMING_RECEIPT_SHA256=$((Get-FileHash -LiteralPath $timingReceiptPath -Algorithm SHA256).Hash)"
'PROGRAM_SUPERVISOR_GATE=PASS_RECOVERED_POSTPROCESS_ONLY'
