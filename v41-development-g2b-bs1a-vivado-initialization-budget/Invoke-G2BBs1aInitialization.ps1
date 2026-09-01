[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$analysisDir = 'C:\FPGA\G2B_BS1A_INIT_BUDGET_20260901T171409Z'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $analysisDir 'G2B_BS1A_WORKER.tcl'
$checkpoint = Join-Path $analysisDir 'G2B_ROUTED.dcp'
$baseXdc = Join-Path $analysisDir 'G2B_BS1A_CONSTRAINT_BASE.xdc'
$sourceList = Join-Path $analysisDir 'G2B_BS1A_SOURCE_SET.txt'
$sinkList = Join-Path $analysisDir 'G2B_BS1A_SINK_SET.txt'
$timeline = Join-Path $analysisDir 'G2B_BS1A_INITIALIZATION_TIMELINE.csv'
$consoleLog = Join-Path $analysisDir 'G2B_BS1A_CONSOLE.log'
$consoleErrorLog = Join-Path $analysisDir 'G2B_BS1A_CONSOLE.stderr.log'
$vivadoLog = Join-Path $analysisDir 'G2B_BS1A_VIVADO.log'
$runnerState = Join-Path $analysisDir 'G2B_BS1A_RUNNER_STATE.txt'
$timeoutSeconds = 1200

$expectedDcpSha256 = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$expectedSourceSha256 = 'F69E9199EBB6212346DA11AC7EB66D832D2E50CCF8F43C5401806780E15247EE'
$expectedSinkSha256 = 'D0E81393EF7750003EE14C3BE0A789CD35FDF132AF3D2B23CE0C3272EB8065BE'
$expectedBaseXdcSha256 = 'A05AF5431E521BBC8812DAAE5574CC31D4E7E3BE89DCA0E41974462383BE3071'

function Write-Utf8NoBom {
    param([string]$Path, [string]$Text)
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Append-Utf8NoBom {
    param([string]$Path, [string]$Text)
    [IO.File]::AppendAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Get-VivadoProcesses {
    return @(Get-Process -ErrorAction SilentlyContinue | Where-Object { $_.ProcessName -match '^vivado(_lab)?$' })
}

if (Test-Path -LiteralPath (Join-Path $analysisDir 'RUN_LAUNCHED.marker')) {
    throw 'BS1A primary launch marker already exists; repeated characterization is forbidden.'
}

$dcpHash = (Get-FileHash -LiteralPath $checkpoint -Algorithm SHA256).Hash
$sourceHash = (Get-FileHash -LiteralPath $sourceList -Algorithm SHA256).Hash
$sinkHash = (Get-FileHash -LiteralPath $sinkList -Algorithm SHA256).Hash
$baseXdcHash = (Get-FileHash -LiteralPath $baseXdc -Algorithm SHA256).Hash
if ($dcpHash -ne $expectedDcpSha256) { throw "sealed DCP hash mismatch: $dcpHash" }
if ($sourceHash -ne $expectedSourceSha256) { throw "source-set hash mismatch: $sourceHash" }
if ($sinkHash -ne $expectedSinkSha256) { throw "sink-set hash mismatch: $sinkHash" }
if ($baseXdcHash -ne $expectedBaseXdcSha256) { throw "base XDC hash mismatch: $baseXdcHash" }
if (@(Get-Content -LiteralPath $sourceList).Count -ne 58) { throw 'source-set count is not 58' }
if (@(Get-Content -LiteralPath $sinkList).Count -ne 1) { throw 'sink-set count is not 1' }
if ((Get-Content -LiteralPath $sinkList -Raw).Trim() -ne 'G2B_ONECH_C2H/own_ok_hold_source_reg') { throw 'sink identity mismatch' }

$forbiddenWorkerStringCount = @(Select-String -LiteralPath $worker -SimpleMatch -Pattern 'report_bus_skew').Count
if ($forbiddenWorkerStringCount -ne 0) { throw 'worker contains a forbidden target-command string' }

$sourceRepo = 'C:\FPGA\FPGA_AHD'
$sourceBranch = (git -C $sourceRepo branch --show-current).Trim()
$sourceHead = (git -C $sourceRepo rev-parse HEAD).Trim()
$sourceTree = (git -C $sourceRepo rev-parse 'HEAD^{tree}').Trim()
$trackedDiffCount = @(git -C $sourceRepo diff --name-only).Count
$indexDiffCount = @(git -C $sourceRepo diff --cached --name-only).Count

$operatingSystem = Get-CimInstance Win32_OperatingSystem
$computerSystem = Get-CimInstance Win32_ComputerSystem
$preexistingProcesses = @(Get-VivadoProcesses)
$preexistingVivadoCount = $preexistingProcesses.Count
$hostTimestamp = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$hostLines = @(
    "OBSERVATION_TIMESTAMP=$hostTimestamp"
    "HOSTNAME=$env:COMPUTERNAME"
    "OS_CAPTION=$($operatingSystem.Caption)"
    "OS_VERSION=$($operatingSystem.Version)"
    "OS_ARCHITECTURE=$($operatingSystem.OSArchitecture)"
    "LOGICAL_CPU_COUNT=$($computerSystem.NumberOfLogicalProcessors)"
    "TOTAL_MEMORY_KIB=$($operatingSystem.TotalVisibleMemorySize)"
    "AVAILABLE_MEMORY_KIB=$($operatingSystem.FreePhysicalMemory)"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
)
Write-Utf8NoBom -Path (Join-Path $analysisDir 'G2B_BS1A_HOST_OBSERVATION.txt') -Text (($hostLines -join "`n") + "`n")

$preflightLines = @(
    'PREFLIGHT_RESULT=PASS'
    'PROJECT_STATE_REV_AT_START=3'
    "DCP_SHA256=$dcpHash"
    "DCP_SIZE_BYTES=$((Get-Item -LiteralPath $checkpoint).Length)"
    "SOURCE_COUNT=58"
    "SOURCE_SET_SHA256=$sourceHash"
    "SINK_COUNT=1"
    "SINK_SET_SHA256=$sinkHash"
    "BASE_XDC_SHA256=$baseXdcHash"
    "WORKER_SHA256=$((Get-FileHash -LiteralPath $worker -Algorithm SHA256).Hash)"
    "WORKER_FORBIDDEN_TARGET_STRING_COUNT=$forbiddenWorkerStringCount"
    "SOURCE_BRANCH=$sourceBranch"
    "SOURCE_HEAD=$sourceHead"
    "SOURCE_TREE=$sourceTree"
    "SOURCE_TRACKED_DIFF_COUNT=$trackedDiffCount"
    "SOURCE_INDEX_DIFF_COUNT=$indexDiffCount"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
)
Write-Utf8NoBom -Path (Join-Path $analysisDir 'G2B_BS1A_PREFLIGHT.txt') -Text (($preflightLines -join "`n") + "`n")

if ($preexistingVivadoCount -ne 0) {
    $details = $preexistingProcesses | ForEach-Object { "PID=$($_.Id) NAME=$($_.ProcessName) START=$($_.StartTime.ToUniversalTime().ToString('o'))" }
    Write-Utf8NoBom -Path (Join-Path $analysisDir 'VIVADO_ENVIRONMENT_NOT_ISOLATED.marker') -Text ((@('BLOCKER=VIVADO_ENVIRONMENT_NOT_ISOLATED') + $details -join "`n") + "`n")
    exit 125
}

$t0 = [DateTimeOffset]::UtcNow
$t0EpochMs = $t0.ToUnixTimeMilliseconds()
$t0Timestamp = $t0.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$deadlineTimestamp = $t0.AddSeconds($timeoutSeconds).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
Write-Utf8NoBom -Path $timeline -Text "Milestone,TimestampUTC,EpochMilliseconds,ElapsedFromT0Seconds,PhaseElapsedSeconds,Detail`nT0,$t0Timestamp,$t0EpochMs,0.000,0.000,`"Vivado process launch`"`n"
Write-Utf8NoBom -Path (Join-Path $analysisDir 'T0.marker') -Text "MILESTONE=T0`nTIMESTAMP=$t0Timestamp`nEPOCH_MILLISECONDS=$t0EpochMs`nELAPSED_FROM_T0_SECONDS=0.000`nPHASE_ELAPSED_SECONDS=0.000`nDETAIL=Vivado process launch`n"
Write-Utf8NoBom -Path (Join-Path $analysisDir 'RUN_LAUNCHED.marker') -Text "EXPERIMENT_ID=BS1A_INIT001`nSTART_TIMESTAMP=$t0Timestamp`nVIVADO_WORKERS_LAUNCHED=1`nINITIALIZATION_TIMEOUT_SECONDS=$timeoutSeconds`n"

$arguments = @(
    '-mode', 'batch',
    '-log', $vivadoLog,
    '-nojournal',
    '-source', $worker,
    '-tclargs',
    $checkpoint,
    $baseXdc,
    $sourceList,
    $sinkList,
    $analysisDir,
    $t0EpochMs.ToString([Globalization.CultureInfo]::InvariantCulture),
    $dcpHash,
    $sourceHash,
    $sinkHash
)
$argumentReceipt = '"{0}" {1}' -f $vivado, (($arguments | ForEach-Object { '"{0}"' -f $_ }) -join ' ')
Write-Utf8NoBom -Path (Join-Path $analysisDir 'G2B_BS1A_LAUNCH_COMMAND.txt') -Text ($argumentReceipt + "`n")

$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$process = Start-Process -FilePath $vivado -ArgumentList $arguments -WorkingDirectory $analysisDir -RedirectStandardOutput $consoleLog -RedirectStandardError $consoleErrorLog -PassThru -WindowStyle Hidden
$rootProcessId = $process.Id
Write-Output "BS1A_RUNNER launched_root_pid=$rootProcessId timeout=${timeoutSeconds}s"

$timedOut = $false
$overlapDetected = $false
$maxVivadoProcessCount = 0
$lastTimelineLine = ''
$lastProcessCheckMs = -2000
$overlapSnapshot = @()

while (-not $process.HasExited) {
    if ($stopwatch.Elapsed.TotalSeconds -ge $timeoutSeconds) {
        $timedOut = $true
        break
    }

    if (($stopwatch.ElapsedMilliseconds - $lastProcessCheckMs) -ge 2000) {
        $lastProcessCheckMs = $stopwatch.ElapsedMilliseconds
        $vivadoProcesses = @(Get-VivadoProcesses)
        if ($vivadoProcesses.Count -gt $maxVivadoProcessCount) {
            $maxVivadoProcessCount = $vivadoProcesses.Count
        }
        if ($vivadoProcesses.Count -gt 1) {
            $overlapDetected = $true
            $overlapSnapshot = $vivadoProcesses
            break
        }
    }

    if (Test-Path -LiteralPath $timeline) {
        $currentTimelineLine = Get-Content -LiteralPath $timeline -Tail 1
        if ($currentTimelineLine -ne $lastTimelineLine) {
            $lastTimelineLine = $currentTimelineLine
            Write-Output "BS1A_PROGRESS $currentTimelineLine"
        }
    }
    Start-Sleep -Milliseconds 250
    $process.Refresh()
}

if ($timedOut -or $overlapDetected) {
    if ($overlapDetected) {
        $overlapLines = $overlapSnapshot | ForEach-Object { "PID=$($_.Id) NAME=$($_.ProcessName) START=$($_.StartTime.ToUniversalTime().ToString('o'))" }
        Write-Utf8NoBom -Path (Join-Path $analysisDir 'VIVADO_OVERLAP_DETECTED.marker') -Text ((@('BLOCKER=VIVADO_ENVIRONMENT_NOT_ISOLATED') + $overlapLines -join "`n") + "`n")
    }
    & "$env:SystemRoot\System32\taskkill.exe" /PID $rootProcessId /T /F | Out-Null
    $process.WaitForExit()
} else {
    $process.WaitForExit()
}

$stopwatch.Stop()
$endTimestamp = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
$totalElapsed = $stopwatch.Elapsed.TotalSeconds.ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
$exitCode = if ($timedOut) { 'TERMINATED_BY_INITIALIZATION_TIMEOUT' } elseif ($overlapDetected) { 'TERMINATED_BY_ENVIRONMENT_OVERLAP' } else { $process.ExitCode.ToString([Globalization.CultureInfo]::InvariantCulture) }
$commandReady = Test-Path -LiteralPath (Join-Path $analysisDir 'COMMAND_READY.marker')
$workerError = Test-Path -LiteralPath (Join-Path $analysisDir 'VIVADO_ERROR.marker')
$postexistingVivadoCount = @(Get-VivadoProcesses).Count

if ($timedOut) {
    $timeoutTimestamp = [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    Append-Utf8NoBom -Path $timeline -Text "TIMEOUT,$timeoutTimestamp,$([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()),$totalElapsed,0.000,`"INITIALIZATION_TIMEOUT_1200S`"`n"
    Write-Utf8NoBom -Path (Join-Path $analysisDir 'INITIALIZATION_TIMEOUT_1200S.marker') -Text "RESULT=INITIALIZATION_TIMEOUT_1200S`nTIMESTAMP=$timeoutTimestamp`nELAPSED_SECONDS=$totalElapsed`n"
}

$stateLines = @(
    'EXPERIMENT_ID=BS1A_INIT001'
    'EXTERNAL_INITIALIZATION_TIMEOUT_ARMED=YES'
    "INITIALIZATION_TIMEOUT_LIMIT_SECONDS=$timeoutSeconds"
    "TIMEOUT_DEADLINE_TIMESTAMP=$deadlineTimestamp"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
    'VIVADO_WORKERS_LAUNCHED=1'
    "MAX_OBSERVED_VIVADO_PROCESS_COUNT=$maxVivadoProcessCount"
    "WORKER_OVERLAP=$($(if ($overlapDetected) { 'YES' } else { 'NO' }))"
    "START_TIMESTAMP=$t0Timestamp"
    "END_TIMESTAMP=$endTimestamp"
    "TOTAL_PROCESS_ELAPSED_SECONDS=$totalElapsed"
    "TIMED_OUT=$($timedOut.ToString().ToUpperInvariant())"
    "ENVIRONMENT_OVERLAP_DETECTED=$($overlapDetected.ToString().ToUpperInvariant())"
    "COMMAND_READY=$($commandReady.ToString().ToUpperInvariant())"
    "WORKER_ERROR=$($workerError.ToString().ToUpperInvariant())"
    "PROCESS_EXIT_CODE=$exitCode"
    "POSTEXISTING_VIVADO_COUNT=$postexistingVivadoCount"
    'BUS_SKEW_COMMAND_EXECUTED=NO'
)
Write-Utf8NoBom -Path $runnerState -Text (($stateLines -join "`n") + "`n")
Write-Output "BS1A_RUNNER complete ready=$commandReady timeout=$timedOut overlap=$overlapDetected exit=$exitCode elapsed=${totalElapsed}s"

if ($overlapDetected) { exit 125 }
if ($timedOut) { exit 124 }
exit $process.ExitCode
