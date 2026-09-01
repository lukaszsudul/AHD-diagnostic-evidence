[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$analysisDir = 'C:\FPGA\G2B_BS1R_SINGLE_SINK_20260901T192755Z'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $analysisDir 'G2B_BS1R_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$baseXdc = Join-Path $analysisDir 'G2B_BS1R_CONSTRAINT_BASE.xdc'
$sourceList = Join-Path $analysisDir 'G2B_BS1R_SOURCE_SET.txt'
$sinkList = Join-Path $analysisDir 'G2B_BS1R_SINK_SET.txt'
$consoleLog = Join-Path $analysisDir 'G2B_BS1R_CONSOLE.log'
$consoleErrorLog = Join-Path $analysisDir 'G2B_BS1R_CONSOLE.stderr.log'
$vivadoLog = Join-Path $analysisDir 'G2B_BS1R_VIVADO.log'
$runnerState = Join-Path $analysisDir 'G2B_BS1R_RUNNER_STATE.txt'
$processAudit = Join-Path $analysisDir 'G2B_BS1R_VIVADO_PROCESS_AUDIT.txt'
$initializationWatchdogSeconds = 900
$busSkewWatchdogSeconds = 300
$expectedDcpSha256 = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$expectedSourceSha256 = 'F69E9199EBB6212346DA11AC7EB66D832D2E50CCF8F43C5401806780E15247EE'
$expectedSinkSha256 = 'D0E81393EF7750003EE14C3BE0A789CD35FDF132AF3D2B23CE0C3272EB8065BE'
$expectedBaseXdcSha256 = 'A05AF5431E521BBC8812DAAE5574CC31D4E7E3BE89DCA0E41974462383BE3071'
$expectedWorkerSha256 = '31E6E4FE08712166BACA133515B00D1A78BCD1A691683FCF4F40A837C6B2CF51'

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Text
    )
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Append-Utf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Text
    )
    [IO.File]::AppendAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Get-UtcTimestamp {
    [DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
}

function Get-EpochMilliseconds {
    [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
}

function Get-MarkerFields {
    param([Parameter(Mandatory)][string]$Path)
    $fields = @{}
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        $separator = $line.IndexOf('=')
        if ($separator -gt 0) {
            $fields[$line.Substring(0, $separator)] = $line.Substring($separator + 1)
        }
    }
    return $fields
}

function Get-VivadoProcesses {
    @(Get-CimInstance Win32_Process | Where-Object { $_.Name -match '^(vivado|vivado_lab)(\.exe)?$' })
}

function Get-VivadoCount {
    @(Get-Process -Name 'vivado', 'vivado_lab' -ErrorAction SilentlyContinue).Count
}

function Stop-Bs1rWorkerTree {
    param([Parameter(Mandatory)][int]$ProcessId)
    $killOutput = & "$env:SystemRoot\System32\taskkill.exe" /PID $ProcessId /T /F 2>&1 | Out-String
    Append-Utf8NoBom -Path $processAudit -Text "TASKKILL_TIMESTAMP=$(Get-UtcTimestamp)`nTASKKILL_PID=$ProcessId`n$killOutput"
}

if (Test-Path -LiteralPath (Join-Path $analysisDir 'RUN_LAUNCHED.marker')) {
    throw 'BS1R_EXP001 launch marker already exists; automatic retry is forbidden.'
}

$requiredPaths = @($vivado, $worker, $checkpoint, $baseXdc, $sourceList, $sinkList)
foreach ($requiredPath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required launch input is absent: $requiredPath"
    }
}

$dcpSha256 = (Get-FileHash -LiteralPath $checkpoint -Algorithm SHA256).Hash.ToUpperInvariant()
$sourceSha256 = (Get-FileHash -LiteralPath $sourceList -Algorithm SHA256).Hash.ToUpperInvariant()
$sinkSha256 = (Get-FileHash -LiteralPath $sinkList -Algorithm SHA256).Hash.ToUpperInvariant()
$baseXdcSha256 = (Get-FileHash -LiteralPath $baseXdc -Algorithm SHA256).Hash.ToUpperInvariant()
$workerSha256 = (Get-FileHash -LiteralPath $worker -Algorithm SHA256).Hash.ToUpperInvariant()
if ($dcpSha256 -ne $expectedDcpSha256) { throw "BLOCKED — SEALED_DCP_HASH_MISMATCH: $dcpSha256" }
if ($sourceSha256 -ne $expectedSourceSha256) { throw "BLOCKED — SOURCE_SCOPE_DRIFT: $sourceSha256" }
if ($sinkSha256 -ne $expectedSinkSha256) { throw "BLOCKED — SINK_SCOPE_DRIFT: $sinkSha256" }
if ($baseXdcSha256 -ne $expectedBaseXdcSha256) { throw "Required skew-free timing/XDC context drift: $baseXdcSha256" }
if ($workerSha256 -ne $expectedWorkerSha256) { throw "Worker Tcl hash changed after review: $workerSha256" }
if (-not (Get-Item -LiteralPath $worker).IsReadOnly) { throw 'Worker Tcl is not immutable/read-only at launch.' }

$sourceNames = [IO.File]::ReadAllLines($sourceList)
$sinkNames = [IO.File]::ReadAllLines($sinkList)
if ($sourceNames.Count -ne 58) { throw "BLOCKED — SOURCE_SCOPE_DRIFT: count=$($sourceNames.Count)" }
if ($sinkNames.Count -ne 1 -or $sinkNames[0] -cne 'G2B_ONECH_C2H/own_ok_hold_source_reg') {
    throw "BLOCKED — SINK_SCOPE_DRIFT: count=$($sinkNames.Count) identity=$($sinkNames -join ',')"
}

$preexistingVivado = Get-VivadoProcesses
$preexistingVivadoCount = @($preexistingVivado).Count
$activeBs1rWorkers = @($preexistingVivado | Where-Object { $_.CommandLine -and $_.CommandLine -match 'G2B_BS1R_WORKER\.tcl' })
$processLines = @(
    "PREFLIGHT_TIMESTAMP=$(Get-UtcTimestamp)"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
    "PREEXISTING_BS1R_WORKER_COUNT=$($activeBs1rWorkers.Count)"
)
if ($preexistingVivadoCount -eq 0) {
    $processLines += 'PREEXISTING_VIVADO_PROCESSES=NONE'
} else {
    $processLines += ($preexistingVivado | ForEach-Object { "PID=$($_.ProcessId)|PPID=$($_.ParentProcessId)|NAME=$($_.Name)|CREATION=$($_.CreationDate)|COMMAND=$($_.CommandLine)" })
}
Write-Utf8NoBom -Path $processAudit -Text (($processLines -join "`n") + "`n")
if ($activeBs1rWorkers.Count -ne 0) { throw 'BLOCKED — VIVADO_ENVIRONMENT_NOT_ISOLATED: BS1R worker already active.' }
if ($preexistingVivadoCount -ne 0) { throw 'BLOCKED — VIVADO_ENVIRONMENT_NOT_ISOLATED: unrelated Vivado process present.' }

$preflightLines = @(
    'EXPERIMENT_ID=BS1R_EXP001'
    "PREFLIGHT_TIMESTAMP=$(Get-UtcTimestamp)"
    'PROJECT_STATE_REV_AT_START=3'
    "DCP_PATH=$checkpoint"
    "DCP_SIZE_BYTES=$((Get-Item -LiteralPath $checkpoint).Length)"
    "DCP_SHA256=$dcpSha256"
    'DCP_HASH_VERIFIED=YES'
    'SOURCE_SCOPE=S_FULL'
    "SOURCE_COUNT=$($sourceNames.Count)"
    "SOURCE_SET_SHA256=$sourceSha256"
    'SINK_SCOPE=K_OWNERSHIP_RESULT'
    "SINK_COUNT=$($sinkNames.Count)"
    "SINK_OBJECT=$($sinkNames[0])"
    "SINK_SET_SHA256=$sinkSha256"
    "BASE_XDC_SHA256=$baseXdcSha256"
    "WORKER_TCL_SHA256=$workerSha256"
    'WORKER_TCL_READ_ONLY=YES'
    "INITIALIZATION_WATCHDOG_SECONDS=$initializationWatchdogSeconds"
    "BUS_SKEW_WATCHDOG_SECONDS=$busSkewWatchdogSeconds"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
    'WORKER_OVERLAP=NO'
)
Write-Utf8NoBom -Path (Join-Path $analysisDir 'G2B_BS1R_PREFLIGHT.txt') -Text (($preflightLines -join "`n") + "`n")

$launchTimestamp = Get-UtcTimestamp
$launchEpochMs = Get-EpochMilliseconds
$initializationDeadlineEpochMs = $launchEpochMs + ($initializationWatchdogSeconds * 1000)
$initializationDeadlineTimestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($initializationDeadlineEpochMs).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
Write-Utf8NoBom -Path (Join-Path $analysisDir 'RUN_LAUNCHED.marker') -Text "MARKER=RUN_LAUNCHED`nEXPERIMENT_ID=BS1R_EXP001`nTIMESTAMP=$launchTimestamp`nEPOCH_MILLISECONDS=$launchEpochMs`nVIVADO_WORKERS_LAUNCHED=1`nINITIALIZATION_WATCHDOG_SECONDS=$initializationWatchdogSeconds`nINITIALIZATION_DEADLINE_TIMESTAMP=$initializationDeadlineTimestamp`nBUS_SKEW_WATCHDOG_SECONDS=$busSkewWatchdogSeconds`n"

$arguments = @(
    '-mode', 'batch',
    '-log', $vivadoLog,
    '-nojournal',
    '-source', $worker,
    '-tclargs', $checkpoint, $baseXdc, $sourceList, $sinkList, $analysisDir,
    $launchEpochMs.ToString([Globalization.CultureInfo]::InvariantCulture),
    $dcpSha256, $sourceSha256, $sinkSha256
)
$argumentReceipt = '"{0}" {1}' -f $vivado, (($arguments | ForEach-Object { '"{0}"' -f $_ }) -join ' ')
Write-Utf8NoBom -Path (Join-Path $analysisDir 'G2B_BS1R_LAUNCH_COMMAND.txt') -Text "$argumentReceipt`n"

$process = $null
$readyMarker = Join-Path $analysisDir 'COMMAND_READY.marker'
$busSkewStartedMarker = Join-Path $analysisDir 'BUS_SKEW_STARTED.marker'
$busSkewCompletedMarker = Join-Path $analysisDir 'BUS_SKEW_COMPLETED.marker'
$maxObservedVivadoCount = 0
$environmentOverlapDetected = $false
$finalResult = 'INCONCLUSIVE'
$timeoutPhase = 'NONE'
$workerTerminated = $false
$commandWatchdogArmed = $false
$commandWatchdogObservedTimestamp = 'N/A'
$commandDeadlineTimestamp = 'N/A'
$commandStartEpochMs = $null
$commandEndEpochMs = $null
$supervisorError = 'NONE'

try {
$process = Start-Process -FilePath $vivado -ArgumentList $arguments -WorkingDirectory $analysisDir -RedirectStandardOutput $consoleLog -RedirectStandardError $consoleErrorLog -PassThru -WindowStyle Hidden
Append-Utf8NoBom -Path $processAudit -Text "LAUNCH_TIMESTAMP=$launchTimestamp`nLAUNCH_PID=$($process.Id)`n"
Write-Output "BS1R_LAUNCHED PID=$($process.Id) INIT_DEADLINE=$initializationDeadlineTimestamp"

while (-not $process.HasExited -and -not (Test-Path -LiteralPath $readyMarker) -and -not $environmentOverlapDetected -and (Get-EpochMilliseconds) -lt $initializationDeadlineEpochMs) {
    $vivadoCount = Get-VivadoCount
    if ($vivadoCount -gt $maxObservedVivadoCount) { $maxObservedVivadoCount = $vivadoCount }
    if ($vivadoCount -gt 1) { $environmentOverlapDetected = $true }
    Start-Sleep -Milliseconds 200
}

$readyPresent = Test-Path -LiteralPath $readyMarker
if ($environmentOverlapDetected) {
    $finalResult = 'VIVADO_ERROR'
    if (-not $process.HasExited) {
        Stop-Bs1rWorkerTree -ProcessId $process.Id
        $workerTerminated = $true
        $process.WaitForExit()
    }
} elseif (-not $readyPresent) {
    if (-not $process.HasExited -and (Get-EpochMilliseconds) -ge $initializationDeadlineEpochMs) {
        $finalResult = 'INITIALIZATION_TIMEOUT'
        $timeoutPhase = 'INITIALIZATION'
        Stop-Bs1rWorkerTree -ProcessId $process.Id
        $workerTerminated = $true
        $process.WaitForExit()
    } else {
        $finalResult = 'VIVADO_ERROR'
        if (-not $process.HasExited) { $process.WaitForExit() }
    }
} else {
    $readyFields = Get-MarkerFields -Path $readyMarker
    $readyTimestamp = $readyFields['TIMESTAMP']
    $readyEpochMs = [Int64]::Parse($readyFields['EPOCH_MILLISECONDS'], [Globalization.CultureInfo]::InvariantCulture)
    if ($readyEpochMs -gt $initializationDeadlineEpochMs) {
        $finalResult = 'INITIALIZATION_TIMEOUT'
        $timeoutPhase = 'INITIALIZATION'
        if (-not $process.HasExited) {
            Stop-Bs1rWorkerTree -ProcessId $process.Id
            $workerTerminated = $true
            $process.WaitForExit()
        }
    } elseif (
        $readyFields['DCP_SHA256'] -ne $expectedDcpSha256 -or
        $readyFields['SOURCE_COUNT'] -ne '58' -or
        $readyFields['SOURCE_SET_SHA256'] -ne $expectedSourceSha256 -or
        $readyFields['SINK_COUNT'] -ne '1' -or
        $readyFields['SINK_OBJECT'] -cne 'G2B_ONECH_C2H/own_ok_hold_source_reg' -or
        $readyFields['SINK_SET_SHA256'] -ne $expectedSinkSha256
    ) {
        $finalResult = 'VIVADO_ERROR'
        if (-not $process.HasExited) {
            Stop-Bs1rWorkerTree -ProcessId $process.Id
            $workerTerminated = $true
            $process.WaitForExit()
        }
    } else {
        Write-Output "BS1R_COMMAND_READY TIMESTAMP=$readyTimestamp INIT_ELAPSED=$($readyFields['INITIALIZATION_ELAPSED_SECONDS'])"

        $busSkewHandshakeDeadlineEpochMs = (Get-EpochMilliseconds) + 30000
        while (-not $process.HasExited -and -not (Test-Path -LiteralPath $busSkewStartedMarker) -and (Get-EpochMilliseconds) -lt $busSkewHandshakeDeadlineEpochMs) {
            Start-Sleep -Milliseconds 20
        }

        if (-not (Test-Path -LiteralPath $busSkewStartedMarker)) {
            $finalResult = 'VIVADO_ERROR'
            if (-not $process.HasExited) {
                Stop-Bs1rWorkerTree -ProcessId $process.Id
                $workerTerminated = $true
                $process.WaitForExit()
            }
        } else {
            $busSkewStartFields = Get-MarkerFields -Path $busSkewStartedMarker
            $commandStartEpochMs = [Int64]::Parse($busSkewStartFields['EPOCH_MILLISECONDS'], [Globalization.CultureInfo]::InvariantCulture)
            $commandDeadlineEpochMs = $commandStartEpochMs + ($busSkewWatchdogSeconds * 1000)
            $commandWatchdogObservedTimestamp = Get-UtcTimestamp
            $commandDeadlineTimestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($commandDeadlineEpochMs).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
            $commandWatchdogArmed = $true
            Write-Output "BS1R_BUS_SKEW_WATCHDOG_ARMED START=$($busSkewStartFields['TIMESTAMP']) DEADLINE=$commandDeadlineTimestamp"

            while (-not $process.HasExited -and -not (Test-Path -LiteralPath $busSkewCompletedMarker) -and -not $environmentOverlapDetected -and (Get-EpochMilliseconds) -lt $commandDeadlineEpochMs) {
                $vivadoCount = Get-VivadoCount
                if ($vivadoCount -gt $maxObservedVivadoCount) { $maxObservedVivadoCount = $vivadoCount }
                if ($vivadoCount -gt 1) { $environmentOverlapDetected = $true }
                Start-Sleep -Milliseconds 100
            }

            if ($environmentOverlapDetected) {
                $finalResult = 'VIVADO_ERROR'
                if (-not $process.HasExited) {
                    Stop-Bs1rWorkerTree -ProcessId $process.Id
                    $workerTerminated = $true
                    $process.WaitForExit()
                }
                $commandEndEpochMs = Get-EpochMilliseconds
            } elseif (Test-Path -LiteralPath $busSkewCompletedMarker) {
                $completedFields = Get-MarkerFields -Path $busSkewCompletedMarker
                $commandEndEpochMs = [Int64]::Parse($completedFields['EPOCH_MILLISECONDS'], [Globalization.CultureInfo]::InvariantCulture)
                if ($commandEndEpochMs -gt $commandDeadlineEpochMs) {
                    $finalResult = 'REPORT_BUS_SKEW_TIMEOUT'
                    $timeoutPhase = 'REPORT_BUS_SKEW'
                    if (-not $process.HasExited) {
                        Stop-Bs1rWorkerTree -ProcessId $process.Id
                        $workerTerminated = $true
                        $process.WaitForExit()
                    }
                } else {
                    $finalResult = 'BUS_SKEW_COMPLETED'
                    Write-Output "BS1R_BUS_SKEW_COMPLETED TIMESTAMP=$($completedFields['TIMESTAMP']) ELAPSED=$($completedFields['BUS_SKEW_ELAPSED_SECONDS'])"
                    $exitDeadlineEpochMs = (Get-EpochMilliseconds) + 60000
                    while (-not $process.HasExited -and -not $environmentOverlapDetected -and (Get-EpochMilliseconds) -lt $exitDeadlineEpochMs) {
                        $vivadoCount = Get-VivadoCount
                        if ($vivadoCount -gt $maxObservedVivadoCount) { $maxObservedVivadoCount = $vivadoCount }
                        if ($vivadoCount -gt 1) { $environmentOverlapDetected = $true }
                        Start-Sleep -Milliseconds 100
                    }
                    if ($environmentOverlapDetected) {
                        $finalResult = 'VIVADO_ERROR'
                        if (-not $process.HasExited) {
                            Stop-Bs1rWorkerTree -ProcessId $process.Id
                            $workerTerminated = $true
                            $process.WaitForExit()
                        }
                    } elseif (-not $process.HasExited) {
                        $finalResult = 'VIVADO_ERROR'
                        Stop-Bs1rWorkerTree -ProcessId $process.Id
                        $workerTerminated = $true
                        $process.WaitForExit()
                    }
                }
            } elseif (-not $process.HasExited -and (Get-EpochMilliseconds) -ge $commandDeadlineEpochMs) {
                $finalResult = 'REPORT_BUS_SKEW_TIMEOUT'
                $timeoutPhase = 'REPORT_BUS_SKEW'
                Stop-Bs1rWorkerTree -ProcessId $process.Id
                $workerTerminated = $true
                $process.WaitForExit()
                $commandEndEpochMs = Get-EpochMilliseconds
            } else {
                $finalResult = 'VIVADO_ERROR'
                if (-not $process.HasExited) { $process.WaitForExit() }
                $commandEndEpochMs = Get-EpochMilliseconds
            }
        }
    }
}
} catch {
    $supervisorError = $_.Exception.Message
    $finalResult = 'VIVADO_ERROR'
    if ($null -ne $process -and -not $process.HasExited) {
        Stop-Bs1rWorkerTree -ProcessId $process.Id
        $workerTerminated = $true
        $process.WaitForExit()
    }
    Write-Utf8NoBom -Path (Join-Path $analysisDir 'SUPERVISOR_ERROR.marker') -Text "MARKER=SUPERVISOR_ERROR`nTIMESTAMP=$(Get-UtcTimestamp)`nERROR=$supervisorError`n"
}

$endTimestamp = Get-UtcTimestamp
$endEpochMs = Get-EpochMilliseconds
$totalElapsedSeconds = (($endEpochMs - $launchEpochMs) / 1000.0).ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
$initializationElapsedSeconds = if (Test-Path -LiteralPath $readyMarker) {
    (Get-MarkerFields -Path $readyMarker)['INITIALIZATION_ELAPSED_SECONDS']
} else {
    (($endEpochMs - $launchEpochMs) / 1000.0).ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
}
$busSkewElapsedSeconds = if ($null -ne $commandStartEpochMs -and $null -ne $commandEndEpochMs) {
    (($commandEndEpochMs - $commandStartEpochMs) / 1000.0).ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
} else {
    'N/A'
}
$processExitCode = if ($null -eq $process) { 'PROCESS_NOT_STARTED' } elseif ($workerTerminated) { 'TERMINATED_BY_EXTERNAL_WATCHDOG' } elseif ($process.HasExited) { $process.ExitCode.ToString([Globalization.CultureInfo]::InvariantCulture) } else { 'N/A' }
$postexistingVivadoCount = Get-VivadoCount

$runnerLines = @(
    'EXPERIMENT_ID=BS1R_EXP001'
    'WATCHDOG_STRUCTURE=SEPARATED'
    "INITIALIZATION_WATCHDOG_SECONDS=$initializationWatchdogSeconds"
    "INITIALIZATION_DEADLINE_TIMESTAMP=$initializationDeadlineTimestamp"
    "BUS_SKEW_WATCHDOG_SECONDS=$busSkewWatchdogSeconds"
    "BUS_SKEW_WATCHDOG_ARMED=$($commandWatchdogArmed.ToString().ToUpperInvariant())"
    "BUS_SKEW_WATCHDOG_OBSERVED_TIMESTAMP=$commandWatchdogObservedTimestamp"
    "BUS_SKEW_DEADLINE_TIMESTAMP=$commandDeadlineTimestamp"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
    'VIVADO_WORKERS_LAUNCHED=1'
    "MAX_OBSERVED_VIVADO_PROCESS_COUNT=$maxObservedVivadoCount"
    "ENVIRONMENT_OVERLAP_DETECTED=$($environmentOverlapDetected.ToString().ToUpperInvariant())"
    "WORKER_OVERLAP=$($environmentOverlapDetected.ToString().ToUpperInvariant())"
    "POSTEXISTING_VIVADO_COUNT=$postexistingVivadoCount"
    "LAUNCH_TIMESTAMP=$launchTimestamp"
    "END_TIMESTAMP=$endTimestamp"
    "INITIALIZATION_ELAPSED_SECONDS=$initializationElapsedSeconds"
    "BUS_SKEW_ELAPSED_SECONDS=$busSkewElapsedSeconds"
    "TOTAL_ELAPSED_SECONDS=$totalElapsedSeconds"
    "COMMAND_READY=$((Test-Path -LiteralPath $readyMarker).ToString().ToUpperInvariant())"
    "BUS_SKEW_STARTED=$((Test-Path -LiteralPath $busSkewStartedMarker).ToString().ToUpperInvariant())"
    "BUS_SKEW_COMPLETED=$((Test-Path -LiteralPath $busSkewCompletedMarker).ToString().ToUpperInvariant())"
    "TIMEOUT_PHASE=$timeoutPhase"
    "WORKER_TERMINATED=$($workerTerminated.ToString().ToUpperInvariant())"
    "PROCESS_EXIT_CODE=$processExitCode"
    "SUPERVISOR_ERROR=$supervisorError"
    "FINAL_RESULT=$finalResult"
)
Write-Utf8NoBom -Path $runnerState -Text (($runnerLines -join "`n") + "`n")
Append-Utf8NoBom -Path $processAudit -Text "END_TIMESTAMP=$endTimestamp`nPOSTEXISTING_VIVADO_COUNT=$postexistingVivadoCount`nFINAL_RESULT=$finalResult`n"
Write-Output "BS1R_RUNNER_FINAL RESULT=$finalResult TOTAL_ELAPSED=$totalElapsedSeconds"

switch ($finalResult) {
    'BUS_SKEW_COMPLETED' { exit 0 }
    'REPORT_BUS_SKEW_TIMEOUT' { exit 124 }
    'INITIALIZATION_TIMEOUT' { exit 125 }
    default { exit 1 }
}
