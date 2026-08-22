[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$LogPath,
    [Parameter(Mandatory)][string]$OutputPath,
    [ValidateRange(5.0,60.0)][double]$MinimumWaitSeconds = 5.0
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$commonPath = Join-Path $PSScriptRoot 'ProgramObserverCommon.ps1'
. $commonPath
$resolvedLog = (Resolve-Path -LiteralPath $LogPath -ErrorAction Stop).Path
$outputFull = [IO.Path]::GetFullPath($OutputPath)
if (Test-Path -LiteralPath $outputFull) { throw "output path must be fresh: $outputFull" }

$records = ConvertTo-I25ObserverRecords -Lines ([IO.File]::ReadAllLines($resolvedLog))
$result = Test-I25ProgramObserver -Records $records
if ($result.CLASSIFICATION -cne 'PASS_STARTUP_HIGH_DONE_1') {
    throw "raw-log observer replay failed: $($result.CLASSIFICATION)"
}

[long]$referenceTicks = [Math]::Max(
    [long]$result.PROGRAM_RETURN_MARKER_TICKS,
    [long]$result.FRESH_DONE_MARKER_TICKS
)
[long]$frequency = [Diagnostics.Stopwatch]::Frequency
[long]$requiredTicks = [long][Math]::Ceiling($MinimumWaitSeconds * $frequency)
while (([Diagnostics.Stopwatch]::GetTimestamp() - $referenceTicks) -lt $requiredTicks) {
    Start-Sleep -Milliseconds 5
}
[long]$observationTicks = [Diagnostics.Stopwatch]::GetTimestamp()
[long]$elapsedTicks = $observationTicks - $referenceTicks
[double]$elapsedSeconds = [double]$elapsedTicks / $frequency

$lines = [string[]]@(
    'RECOVERY_KIND=POSTPROCESS_ONLY_NO_PROGRAM_NO_JTAG',
    ('RAW_LOG_PATH={0}' -f $resolvedLog),
    ('RAW_LOG_SHA256={0}' -f (Get-FileHash -LiteralPath $resolvedLog -Algorithm SHA256).Hash),
    ('PARSER_SHA256={0}' -f (Get-FileHash -LiteralPath $commonPath -Algorithm SHA256).Hash),
    ('OBSERVER_REPLAY_CLASSIFICATION={0}' -f $result.CLASSIFICATION),
    ('COUNT_GATE={0}' -f $result.COUNT_GATE),
    ('ORDER_GATE={0}' -f $result.ORDER_GATE),
    ('PROGRAM_EOS={0}' -f $result.PROGRAM_EOS),
    ('PROGRAM_DONE={0}' -f $result.PROGRAM_DONE),
    ('PROGRAM_INVOCATION_CONSUMED_COUNT={0}' -f $result.PROGRAM_INVOCATION_CONSUMED_COUNT),
    ('VENDOR_STARTUP_HIGH_COUNT={0}' -f $result.VENDOR_STARTUP_HIGH_COUNT),
    ('PROGRAM_RETURN_MARKER_COUNT={0}' -f $result.PROGRAM_RETURN_MARKER_COUNT),
    ('FRESH_DONE_MARKER_COUNT={0}' -f $result.FRESH_DONE_MARKER_COUNT),
    ('PROCESS_EXIT_ZERO_COUNT={0}' -f $result.PROCESS_EXIT_ZERO_COUNT),
    ('TIMED_OUT_NO_COUNT={0}' -f $result.TIMED_OUT_NO_COUNT),
    ('STOPWATCH_FREQUENCY={0}' -f $frequency),
    ('WAIT_REFERENCE_TICKS={0}' -f $referenceTicks),
    ('WAIT_OBSERVATION_TICKS={0}' -f $observationTicks),
    ('ACTUAL_MONOTONIC_WAIT_TICKS={0}' -f $elapsedTicks),
    ('ACTUAL_MONOTONIC_WAIT_SECONDS={0}' -f $elapsedSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture)),
    ('REQUIRED_MINIMUM_WAIT_SECONDS={0}' -f $MinimumWaitSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture)),
    'PROGRAM_OBSERVER=PASS_REPLAYED_COMPLETE_SAME_SESSION_RAW_EVIDENCE',
    'WAIT_GATE=PASS_RECOVERED_SAME_QPC_EPOCH',
    'PROGRAM_RETRY=NO'
)
[IO.File]::WriteAllLines($outputFull,$lines,[Text.UTF8Encoding]::new($false))
$lines
