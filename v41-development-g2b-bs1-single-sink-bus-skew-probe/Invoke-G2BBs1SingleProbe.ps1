[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$analysisDir = 'C:\FPGA\G2B_BS1_SINGLE_SINK_20260831T235727'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $analysisDir 'G2B_BS1_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$baseXdc = Join-Path $analysisDir 'G2B_BS1_CONSTRAINT_BASE.xdc'
$sourceList = Join-Path $analysisDir 'G2B_BS1_SOURCE_SET.txt'
$sinkList = Join-Path $analysisDir 'G2B_BS1_SINK_SET.txt'
$consoleLog = Join-Path $analysisDir 'G2B_BS1_CONSOLE.log'
$consoleErrorLog = Join-Path $analysisDir 'G2B_BS1_CONSOLE.stderr.log'
$vivadoLog = Join-Path $analysisDir 'G2B_BS1_VIVADO.log'
$runnerState = Join-Path $analysisDir 'G2B_BS1_RUNNER_STATE.txt'
$timeoutSeconds = 300

if (Test-Path -LiteralPath (Join-Path $analysisDir 'RUN_LAUNCHED.marker')) {
    throw 'BS1_EXP001 launch marker already exists; automatic retry is forbidden.'
}

$preexistingVivadoCount = @(Get-Process -Name 'vivado' -ErrorAction SilentlyContinue).Count
if ($preexistingVivadoCount -ne 0) {
    throw "Serialization preflight failed: $preexistingVivadoCount Vivado process(es) already running."
}

$startTimestamp = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$deadlineTimestamp = [DateTimeOffset]::UtcNow.AddSeconds($timeoutSeconds).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
[IO.File]::WriteAllText(
    (Join-Path $analysisDir 'RUN_LAUNCHED.marker'),
    "EXPERIMENT_ID=BS1_EXP001`nSTART_TIMESTAMP=$startTimestamp`nVIVADO_WORKERS_LAUNCHED=1`n",
    [Text.UTF8Encoding]::new($false)
)

$arguments = @(
    '-mode', 'batch',
    '-log', $vivadoLog,
    '-nojournal',
    '-source', $worker,
    '-tclargs', $checkpoint, $baseXdc, $sourceList, $sinkList, $analysisDir
)

$argumentReceipt = '"{0}" {1}' -f $vivado, (($arguments | ForEach-Object { '"{0}"' -f $_ }) -join ' ')
[IO.File]::WriteAllText(
    (Join-Path $analysisDir 'G2B_BS1_LAUNCH_COMMAND.txt'),
    "$argumentReceipt`n",
    [Text.UTF8Encoding]::new($false)
)

$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$process = Start-Process -FilePath $vivado -ArgumentList $arguments -WorkingDirectory $analysisDir -RedirectStandardOutput $consoleLog -RedirectStandardError $consoleErrorLog -PassThru -WindowStyle Hidden
$timedOut = $false

while (-not $process.HasExited -and $stopwatch.Elapsed.TotalSeconds -lt $timeoutSeconds) {
    Start-Sleep -Milliseconds 200
}

if (-not $process.HasExited) {
    $timedOut = $true
    $timeoutPhase = if (Test-Path -LiteralPath (Join-Path $analysisDir 'COMMAND_STARTED.marker')) { 'REPORT_BUS_SKEW' } else { 'INITIALIZATION' }
    & "$env:SystemRoot\System32\taskkill.exe" /PID $process.Id /T /F | Out-Null
    $process.WaitForExit()
} else {
    $timeoutPhase = 'NONE'
}

$stopwatch.Stop()
$endTimestamp = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$exitCode = if ($timedOut) { 'TERMINATED_BY_EXTERNAL_TIMEOUT' } else { $process.ExitCode.ToString([Globalization.CultureInfo]::InvariantCulture) }
$totalElapsed = $stopwatch.Elapsed.TotalSeconds.ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
$commandStarted = Test-Path -LiteralPath (Join-Path $analysisDir 'COMMAND_STARTED.marker')
$commandCompleted = Test-Path -LiteralPath (Join-Path $analysisDir 'COMMAND_COMPLETED.marker')

$stateLines = @(
    'EXPERIMENT_ID=BS1_EXP001'
    'EXTERNAL_TIMEOUT_ARMED=YES'
    "TIMEOUT_LIMIT_SECONDS=$timeoutSeconds"
    "TIMEOUT_DEADLINE_TIMESTAMP=$deadlineTimestamp"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
    'VIVADO_WORKERS_LAUNCHED=1'
    'WORKER_OVERLAP=NO'
    "START_TIMESTAMP=$startTimestamp"
    "END_TIMESTAMP=$endTimestamp"
    "TOTAL_ELAPSED_SECONDS=$totalElapsed"
    "TIMED_OUT=$($timedOut.ToString().ToUpperInvariant())"
    "TIMEOUT_PHASE=$timeoutPhase"
    "COMMAND_STARTED=$($commandStarted.ToString().ToUpperInvariant())"
    "COMMAND_COMPLETED=$($commandCompleted.ToString().ToUpperInvariant())"
    "PROCESS_EXIT_CODE=$exitCode"
)
[IO.File]::WriteAllText($runnerState, (($stateLines -join "`n") + "`n"), [Text.UTF8Encoding]::new($false))

if ($timedOut) {
    exit 124
}
exit $process.ExitCode
