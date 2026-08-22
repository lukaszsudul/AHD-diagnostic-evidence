[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$PriorRecoveryPath,
    [Parameter(Mandatory)][string]$OutputPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$supervisorPath = Join-Path $PSScriptRoot 'Run-ProgramOnceStartupHighDone.ps1'
$parserPath = Join-Path $PSScriptRoot 'ProgramObserverCommon.ps1'
$tclPath = Join-Path $PSScriptRoot 'program_once_startup_high_done.tcl'
$expectedSupervisorSha = '2F6CF02E14E5461F9710C3F1E803F0DC325628C04D64E3C925502E88BFA315AF'
$expectedParserSha = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
$expectedTclSha = '7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653'

if ((Get-FileHash -LiteralPath $supervisorPath -Algorithm SHA256).Hash -cne $expectedSupervisorSha -or
    (Get-FileHash -LiteralPath $parserPath -Algorithm SHA256).Hash -cne $expectedParserSha -or
    (Get-FileHash -LiteralPath $tclPath -Algorithm SHA256).Hash -cne $expectedTclSha) {
    throw 'accepted R1b observer identity mismatch'
}

$supervisor = [IO.File]::ReadAllText($supervisorPath)
$appendResultCast = $supervisor.Contains('[IO.File]::AppendAllLines($evidenceFull,[string[]]$resultLines')
$appendFailureCast = $supervisor.Contains("[IO.File]::AppendAllLines(`$evidenceFull,[string[]]@('PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY')")
$appendWaitCast = $supervisor.Contains('[IO.File]::AppendAllLines($evidenceFull,[string[]]$waitLines')
if (-not ($appendResultCast -and $appendFailureCast -and $appendWaitCast)) {
    throw 'accepted supervisor does not contain all three fixed evidence-append casts'
}

$tempFile = Join-Path ([IO.Path]::GetTempPath()) ('r1c_observer_append_' + [guid]::NewGuid().ToString('N') + '.txt')
try {
    $initial = [string[]]@('RAW_EVENT=1')
    $resultLines = [string[]]@('PROGRAM_EOS=HIGH_VENDOR_STARTUP_STATUS','PROGRAM_DONE=1','PROGRAM_RESULT=PASS_STARTUP_HIGH_DONE_1')
    $waitLines = [string[]]@('WAIT_REFERENCE_TICKS=100','WAIT_END_TICKS=200','PROGRAM_SUPERVISOR_GATE=PASS')
    [IO.File]::WriteAllLines($tempFile,$initial,[Text.UTF8Encoding]::new($false))
    [IO.File]::AppendAllLines($tempFile,[string[]]$resultLines,[Text.UTF8Encoding]::new($false))
    [IO.File]::AppendAllLines($tempFile,[string[]]@('PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'),[Text.UTF8Encoding]::new($false))
    [IO.File]::AppendAllLines($tempFile,[string[]]$waitLines,[Text.UTF8Encoding]::new($false))
    $actualAppend = [IO.File]::ReadAllLines($tempFile)
    $expectedAppend = [string[]]@($initial + $resultLines + 'PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY' + $waitLines)
    if ($actualAppend.Count -ne $expectedAppend.Count -or
        [string]::Join("`n",$actualAppend) -cne [string]::Join("`n",$expectedAppend) -or
        @($actualAppend | Where-Object { $_ -ceq 'System.Object[]' }).Count -ne 0) {
        throw 'evidence-append fixture failed'
    }
} finally {
    if (Test-Path -LiteralPath $tempFile) { Remove-Item -LiteralPath $tempFile -Force }
}

[long]$frequency = [Diagnostics.Stopwatch]::Frequency
[long]$programReturnTicks = [Diagnostics.Stopwatch]::GetTimestamp()
Start-Sleep -Milliseconds 5
[long]$freshDoneTicks = [Diagnostics.Stopwatch]::GetTimestamp()
[long]$referenceTicks = [Math]::Max($programReturnTicks,$freshDoneTicks)
[double]$requiredSeconds = 0.025
[long]$requiredTicks = [long][Math]::Ceiling($requiredSeconds * $frequency)
while (([Diagnostics.Stopwatch]::GetTimestamp() - $referenceTicks) -lt $requiredTicks) {
    Start-Sleep -Milliseconds 1
}
[long]$observationTicks = [Diagnostics.Stopwatch]::GetTimestamp()
[long]$elapsedTicks = $observationTicks - $referenceTicks
[double]$elapsedSeconds = [double]$elapsedTicks / $frequency
if ($frequency -le 0 -or $freshDoneTicks -le $programReturnTicks -or
    $observationTicks -le $referenceTicks -or $elapsedTicks -lt $requiredTicks -or
    $elapsedSeconds -lt $requiredSeconds) {
    throw 'same-QPC wait fixture failed'
}

$recovery = @{}
foreach ($line in [IO.File]::ReadAllLines((Resolve-Path -LiteralPath $PriorRecoveryPath).Path)) {
    $split = $line.IndexOf('=')
    if ($split -gt 0) { $recovery[$line.Substring(0,$split)] = $line.Substring($split + 1) }
}
foreach ($key in @('RECOVERY_KIND','STOPWATCH_FREQUENCY','WAIT_REFERENCE_TICKS','WAIT_OBSERVATION_TICKS','ACTUAL_MONOTONIC_WAIT_TICKS','ACTUAL_MONOTONIC_WAIT_SECONDS','WAIT_GATE','PROGRAM_RETRY')) {
    if (-not $recovery.ContainsKey($key)) { throw "prior recovery field missing: $key" }
}
[long]$priorFrequency = $recovery.STOPWATCH_FREQUENCY
[long]$priorReference = $recovery.WAIT_REFERENCE_TICKS
[long]$priorObservation = $recovery.WAIT_OBSERVATION_TICKS
[long]$priorElapsed = $recovery.ACTUAL_MONOTONIC_WAIT_TICKS
[double]$priorSeconds = [double]::Parse($recovery.ACTUAL_MONOTONIC_WAIT_SECONDS,[Globalization.CultureInfo]::InvariantCulture)
if ($recovery.RECOVERY_KIND -cne 'POSTPROCESS_ONLY_NO_PROGRAM_NO_JTAG' -or
    $recovery.WAIT_GATE -cne 'PASS_RECOVERED_SAME_QPC_EPOCH' -or
    $recovery.PROGRAM_RETRY -cne 'NO' -or
    $priorFrequency -le 0 -or $priorObservation - $priorReference -ne $priorElapsed -or
    [Math]::Abs(($priorElapsed / [double]$priorFrequency) - $priorSeconds) -gt 0.000000001 -or
    $priorSeconds -lt 5.0) {
    throw 'prior R1b same-QPC record replay failed'
}

$outputFull = [IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $outputFull) { throw "output path must be fresh: $outputFull" }
$lines = [string[]]@(
    'POSTFIX_SUPERVISOR_SHA256=' + $expectedSupervisorSha,
    'OBSERVER_PARSER_SHA256=' + $expectedParserSha,
    'PROGRAM_TCL_SHA256=' + $expectedTclSha,
    'EVIDENCE_APPEND_RESULT_CAST=PASS',
    'EVIDENCE_APPEND_FAILURE_CAST=PASS',
    'EVIDENCE_APPEND_WAIT_CAST=PASS',
    'EVIDENCE_APPEND_FLAT_LINE_COUNT=' + $actualAppend.Count,
    'EVIDENCE_APPEND_SYSTEM_OBJECT_ARRAY_COUNT=0',
    'POSTPROCESS_APPEND_FIXTURE=PASS',
    'SAME_QPC_STOPWATCH_FREQUENCY=' + $frequency,
    'SAME_QPC_PROGRAM_RETURN_TICKS=' + $programReturnTicks,
    'SAME_QPC_FRESH_DONE_TICKS=' + $freshDoneTicks,
    'SAME_QPC_REFERENCE_TICKS=' + $referenceTicks,
    'SAME_QPC_OBSERVATION_TICKS=' + $observationTicks,
    'SAME_QPC_ELAPSED_TICKS=' + $elapsedTicks,
    'SAME_QPC_ELAPSED_SECONDS=' + $elapsedSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture),
    'SAME_QPC_WAIT_FIXTURE=PASS',
    'PRIOR_R1B_RECOVERY_SHA256=' + (Get-FileHash -LiteralPath $PriorRecoveryPath -Algorithm SHA256).Hash,
    'PRIOR_R1B_SAME_QPC_WAIT_SECONDS=' + $priorSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture),
    'PRIOR_R1B_SAME_QPC_REPLAY=PASS',
    'HARDWARE_ACTIONS=0'
)
[IO.File]::WriteAllLines($outputFull,$lines,[Text.UTF8Encoding]::new($false))
$lines
