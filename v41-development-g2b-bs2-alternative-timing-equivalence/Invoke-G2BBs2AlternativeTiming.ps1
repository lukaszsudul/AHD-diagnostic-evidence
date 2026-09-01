[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$analysisDir = 'C:\FPGA\G2B_BS2_ALT_TIMING_20260901T205518Z'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $analysisDir 'G2B_BS2_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$baseXdc = Join-Path $analysisDir 'G2B_BS2_CONSTRAINT_BASE.xdc'
$sourceList = Join-Path $analysisDir 'G2B_BS2_SOURCE_SET.txt'
$sinkList = Join-Path $analysisDir 'G2B_BS2_SINK_SET.txt'
$ssotJson = 'C:\FPGA\V41_G2B_EVIDENCE\project-current-state\PROJECT_STATE.json'
$consoleLog = Join-Path $analysisDir 'G2B_BS2_CONSOLE.log'
$consoleErrorLog = Join-Path $analysisDir 'G2B_BS2_CONSOLE.stderr.log'
$vivadoLog = Join-Path $analysisDir 'G2B_BS2_VIVADO.log'
$processAudit = Join-Path $analysisDir 'G2B_BS2_VIVADO_PROCESS_AUDIT.txt'
$runnerState = Join-Path $analysisDir 'G2B_BS2_RUNNER_STATE.txt'
$initializationWatchdogSeconds = 900
$queryWatchdogSeconds = 300
$methodologyWatchdogSeconds = 300
$expectedDcpSha256 = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$expectedSourceSha256 = 'F69E9199EBB6212346DA11AC7EB66D832D2E50CCF8F43C5401806780E15247EE'
$expectedSinkSha256 = 'D0E81393EF7750003EE14C3BE0A789CD35FDF132AF3D2B23CE0C3272EB8065BE'
$expectedBaseXdcSha256 = 'A05AF5431E521BBC8812DAAE5574CC31D4E7E3BE89DCA0E41974462383BE3071'

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

function Stop-Bs2WorkerTree {
    param([Parameter(Mandatory)][int]$ProcessId)
    $killOutput = & "$env:SystemRoot\System32\taskkill.exe" /PID $ProcessId /T /F 2>&1 | Out-String
    Append-Utf8NoBom -Path $processAudit -Text "TASKKILL_TIMESTAMP=$(Get-UtcTimestamp)`nTASKKILL_PID=$ProcessId`n$killOutput"
}

function Wait-Bs2Stage {
    param(
        [Parameter(Mandatory)][System.Diagnostics.Process]$Process,
        [Parameter(Mandatory)][string]$Label,
        [Parameter(Mandatory)][string]$StartMarker,
        [Parameter(Mandatory)][string]$CompletedMarker,
        [Parameter(Mandatory)][int]$BudgetSeconds
    )

    $handshakeDeadline = (Get-EpochMilliseconds) + 30000
    $overlap = $false
    while (-not $Process.HasExited -and -not (Test-Path -LiteralPath $StartMarker) -and (Get-EpochMilliseconds) -lt $handshakeDeadline) {
        if ((Get-VivadoCount) -gt 1) { $overlap = $true; break }
        Start-Sleep -Milliseconds 100
    }
    if ($overlap) {
        return [pscustomobject]@{ Status = 'ENVIRONMENT_OVERLAP'; Elapsed = 'N/A'; Start = 'N/A'; End = 'N/A'; Deadline = 'N/A' }
    }
    if (-not (Test-Path -LiteralPath $StartMarker)) {
        return [pscustomobject]@{ Status = 'FAIL'; Elapsed = 'N/A'; Start = 'N/A'; End = 'N/A'; Deadline = 'N/A' }
    }

    $startFields = Get-MarkerFields -Path $StartMarker
    $startEpochMs = [Int64]::Parse($startFields['EPOCH_MILLISECONDS'], [Globalization.CultureInfo]::InvariantCulture)
    $deadlineEpochMs = $startEpochMs + ($BudgetSeconds * 1000)
    $deadlineTimestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($deadlineEpochMs).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    Append-Utf8NoBom -Path $processAudit -Text "${Label}_WATCHDOG_ARMED_TIMESTAMP=$(Get-UtcTimestamp)`n${Label}_START_TIMESTAMP=$($startFields['TIMESTAMP'])`n${Label}_DEADLINE_TIMESTAMP=$deadlineTimestamp`n"

    while (-not $Process.HasExited -and -not (Test-Path -LiteralPath $CompletedMarker) -and (Get-EpochMilliseconds) -lt $deadlineEpochMs) {
        if ((Get-VivadoCount) -gt 1) { $overlap = $true; break }
        Start-Sleep -Milliseconds 100
    }
    if ($overlap) {
        return [pscustomobject]@{ Status = 'ENVIRONMENT_OVERLAP'; Elapsed = 'N/A'; Start = $startFields['TIMESTAMP']; End = 'N/A'; Deadline = $deadlineTimestamp }
    }
    if (Test-Path -LiteralPath $CompletedMarker) {
        $completedFields = Get-MarkerFields -Path $CompletedMarker
        $completedEpochMs = [Int64]::Parse($completedFields['EPOCH_MILLISECONDS'], [Globalization.CultureInfo]::InvariantCulture)
        $elapsed = (($completedEpochMs - $startEpochMs) / 1000.0).ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
        if ($completedEpochMs -gt $deadlineEpochMs) {
            return [pscustomobject]@{ Status = 'TIMEOUT'; Elapsed = $elapsed; Start = $startFields['TIMESTAMP']; End = $completedFields['TIMESTAMP']; Deadline = $deadlineTimestamp }
        }
        return [pscustomobject]@{ Status = 'PASS'; Elapsed = $elapsed; Start = $startFields['TIMESTAMP']; End = $completedFields['TIMESTAMP']; Deadline = $deadlineTimestamp }
    }
    if (-not $Process.HasExited -and (Get-EpochMilliseconds) -ge $deadlineEpochMs) {
        $elapsed = (((Get-EpochMilliseconds) - $startEpochMs) / 1000.0).ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
        return [pscustomobject]@{ Status = 'TIMEOUT'; Elapsed = $elapsed; Start = $startFields['TIMESTAMP']; End = 'N/A'; Deadline = $deadlineTimestamp }
    }
    return [pscustomobject]@{ Status = 'FAIL'; Elapsed = 'N/A'; Start = $startFields['TIMESTAMP']; End = 'N/A'; Deadline = $deadlineTimestamp }
}

if (Test-Path -LiteralPath (Join-Path $analysisDir 'RUN_LAUNCHED.marker')) {
    throw 'BS2_EXP001 launch marker already exists; automatic retry is forbidden.'
}

$requiredPaths = @($vivado, $worker, $checkpoint, $baseXdc, $sourceList, $sinkList, $ssotJson)
foreach ($requiredPath in $requiredPaths) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required launch input is absent: $requiredPath"
    }
}

$ssot = Get-Content -LiteralPath $ssotJson -Raw | ConvertFrom-Json
$projectStateRev = [int]$ssot.project_state_revision
if ($projectStateRev -ne 3) { throw "BLOCKED — SSOT_REVISION_MISMATCH: $projectStateRev" }

$dcpSha256 = (Get-FileHash -LiteralPath $checkpoint -Algorithm SHA256).Hash.ToUpperInvariant()
$sourceSha256 = (Get-FileHash -LiteralPath $sourceList -Algorithm SHA256).Hash.ToUpperInvariant()
$sinkSha256 = (Get-FileHash -LiteralPath $sinkList -Algorithm SHA256).Hash.ToUpperInvariant()
$baseXdcSha256 = (Get-FileHash -LiteralPath $baseXdc -Algorithm SHA256).Hash.ToUpperInvariant()
$workerSha256 = (Get-FileHash -LiteralPath $worker -Algorithm SHA256).Hash.ToUpperInvariant()
if ($dcpSha256 -ne $expectedDcpSha256) { throw "BLOCKED — SEALED_DCP_HASH_MISMATCH: $dcpSha256" }
if ($sourceSha256 -ne $expectedSourceSha256) { throw "BLOCKED — OBJECT_SCOPE_DRIFT: source hash $sourceSha256" }
if ($sinkSha256 -ne $expectedSinkSha256) { throw "BLOCKED — OBJECT_SCOPE_DRIFT: sink hash $sinkSha256" }
if ($baseXdcSha256 -ne $expectedBaseXdcSha256) { throw "Skew-free timing context drift: $baseXdcSha256" }

$sourceNames = [IO.File]::ReadAllLines($sourceList)
$sinkNames = [IO.File]::ReadAllLines($sinkList)
if ($sourceNames.Count -ne 58) { throw "BLOCKED — OBJECT_SCOPE_DRIFT: source count $($sourceNames.Count)" }
if ($sinkNames.Count -ne 1 -or $sinkNames[0] -cne 'G2B_ONECH_C2H/own_ok_hold_source_reg') {
    throw "BLOCKED — OBJECT_SCOPE_DRIFT: sink count/identity"
}

$workerText = Get-Content -LiteralPath $worker -Raw
if ($workerText -match '(?m)^\s*report_bus_skew(?:\s|$)') {
    throw 'Critical prohibition violated: worker contains an executable report_bus_skew line.'
}
$baseXdcText = Get-Content -LiteralPath $baseXdc -Raw
if ($baseXdcText -match '(?m)^\s*set_bus_skew(?:\s|$)') {
    throw 'Base timing context unexpectedly contains set_bus_skew.'
}

$preexistingVivado = Get-VivadoProcesses
$preexistingVivadoCount = @($preexistingVivado).Count
$processLines = @(
    "PREFLIGHT_TIMESTAMP=$(Get-UtcTimestamp)"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
)
if ($preexistingVivadoCount -eq 0) {
    $processLines += 'PREEXISTING_VIVADO_PROCESSES=NONE'
} else {
    $processLines += ($preexistingVivado | ForEach-Object { "PID=$($_.ProcessId)|PPID=$($_.ParentProcessId)|NAME=$($_.Name)|CREATION=$($_.CreationDate)|COMMAND=$($_.CommandLine)" })
}
Write-Utf8NoBom -Path $processAudit -Text (($processLines -join "`n") + "`n")
if ($preexistingVivadoCount -ne 0) { throw 'BLOCKED — VIVADO_ENVIRONMENT_NOT_ISOLATED' }

$preflightLines = @(
    'EXPERIMENT_ID=BS2_EXP001'
    "PREFLIGHT_TIMESTAMP=$(Get-UtcTimestamp)"
    "PROJECT_STATE_REV_AT_START=$projectStateRev"
    "DCP_PATH=$checkpoint"
    "DCP_SIZE_BYTES=$((Get-Item -LiteralPath $checkpoint).Length)"
    "DCP_SHA256=$dcpSha256"
    'DCP_HASH_VERIFIED=YES'
    'SOURCE_SCOPE=S_FULL'
    'SOURCE_COUNT=58'
    "SOURCE_SET_SHA256=$sourceSha256"
    'SINK_SCOPE=K_OWNERSHIP_RESULT'
    'SINK_COUNT=1'
    "SINK_OBJECT=$($sinkNames[0])"
    "SINK_SET_SHA256=$sinkSha256"
    "BASE_XDC_SHA256=$baseXdcSha256"
    "WORKER_TCL_SHA256=$workerSha256"
    'REPORT_BUS_SKEW_EXECUTABLE_LINE_COUNT=0'
    "INITIALIZATION_WATCHDOG_SECONDS=$initializationWatchdogSeconds"
    "REPORT_TIMING_WATCHDOG_SECONDS=$queryWatchdogSeconds"
    "GET_TIMING_PATHS_WATCHDOG_SECONDS=$queryWatchdogSeconds"
    "METHODOLOGY_WATCHDOG_SECONDS=$methodologyWatchdogSeconds"
    "PREEXISTING_VIVADO_COUNT=$preexistingVivadoCount"
    'WORKER_OVERLAP=NO'
)
Write-Utf8NoBom -Path (Join-Path $analysisDir 'G2B_BS2_PREFLIGHT.txt') -Text (($preflightLines -join "`n") + "`n")

$launchTimestamp = Get-UtcTimestamp
$launchEpochMs = Get-EpochMilliseconds
$initializationDeadlineEpochMs = $launchEpochMs + ($initializationWatchdogSeconds * 1000)
$initializationDeadlineTimestamp = [DateTimeOffset]::FromUnixTimeMilliseconds($initializationDeadlineEpochMs).ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
Write-Utf8NoBom -Path (Join-Path $analysisDir 'RUN_LAUNCHED.marker') -Text "MARKER=RUN_LAUNCHED`nEXPERIMENT_ID=BS2_EXP001`nTIMESTAMP=$launchTimestamp`nEPOCH_MILLISECONDS=$launchEpochMs`nVIVADO_WORKERS_LAUNCHED=1`nINITIALIZATION_WATCHDOG_SECONDS=$initializationWatchdogSeconds`nINITIALIZATION_DEADLINE_TIMESTAMP=$initializationDeadlineTimestamp`nREPORT_TIMING_WATCHDOG_SECONDS=$queryWatchdogSeconds`nGET_TIMING_PATHS_WATCHDOG_SECONDS=$queryWatchdogSeconds`nREPORT_BUS_SKEW_ATTEMPT_COUNT=0`n"

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
Write-Utf8NoBom -Path (Join-Path $analysisDir 'G2B_BS2_LAUNCH_COMMAND.txt') -Text "$argumentReceipt`n"

$process = $null
$finalResult = 'FAIL'
$timeoutPhase = 'NONE'
$workerTerminated = $false
$initializationStatus = 'FAIL'
$initializationElapsed = 'N/A'
$reportTimingStatus = 'NOT_RUN'
$reportTimingElapsed = 'N/A'
$getTimingPathsStatus = 'NOT_RUN'
$getTimingPathsElapsed = 'N/A'
$methodologyStatus = 'NOT_RUN'
$methodologyElapsed = 'N/A'
$supervisorError = 'NONE'

try {
    $process = Start-Process -FilePath $vivado -ArgumentList $arguments -WorkingDirectory $analysisDir -RedirectStandardOutput $consoleLog -RedirectStandardError $consoleErrorLog -PassThru -WindowStyle Hidden
    Append-Utf8NoBom -Path $processAudit -Text "LAUNCH_TIMESTAMP=$launchTimestamp`nLAUNCH_PID=$($process.Id)`n"
    Write-Output "BS2_LAUNCHED PID=$($process.Id) INIT_DEADLINE=$initializationDeadlineTimestamp"

    $readyMarker = Join-Path $analysisDir 'COMMAND_READY.marker'
    $overlap = $false
    while (-not $process.HasExited -and -not (Test-Path -LiteralPath $readyMarker) -and (Get-EpochMilliseconds) -lt $initializationDeadlineEpochMs) {
        if ((Get-VivadoCount) -gt 1) { $overlap = $true; break }
        Start-Sleep -Milliseconds 200
    }

    if ($overlap) {
        $finalResult = 'VIVADO_ENVIRONMENT_NOT_ISOLATED'
    } elseif (-not (Test-Path -LiteralPath $readyMarker)) {
        if (-not $process.HasExited -and (Get-EpochMilliseconds) -ge $initializationDeadlineEpochMs) {
            $initializationStatus = 'TIMEOUT'
            $finalResult = 'INITIALIZATION_TIMEOUT'
            $timeoutPhase = 'INITIALIZATION'
        } else {
            $initializationStatus = 'FAIL'
            $finalResult = 'VIVADO_ERROR'
        }
    } else {
        $readyFields = Get-MarkerFields -Path $readyMarker
        $readyEpochMs = [Int64]::Parse($readyFields['EPOCH_MILLISECONDS'], [Globalization.CultureInfo]::InvariantCulture)
        $initializationElapsed = $readyFields['INITIALIZATION_ELAPSED_SECONDS']
        if ($readyEpochMs -gt $initializationDeadlineEpochMs) {
            $initializationStatus = 'TIMEOUT'
            $finalResult = 'INITIALIZATION_TIMEOUT'
            $timeoutPhase = 'INITIALIZATION'
        } elseif (
            $readyFields['DCP_SHA256'] -ne $expectedDcpSha256 -or
            $readyFields['SOURCE_COUNT'] -ne '58' -or
            $readyFields['SOURCE_SET_SHA256'] -ne $expectedSourceSha256 -or
            $readyFields['SINK_COUNT'] -ne '1' -or
            $readyFields['SINK_OBJECT'] -cne 'G2B_ONECH_C2H/own_ok_hold_source_reg' -or
            $readyFields['SINK_SET_SHA256'] -ne $expectedSinkSha256 -or
            $readyFields['REPORT_BUS_SKEW_ATTEMPT_COUNT'] -ne '0'
        ) {
            $initializationStatus = 'FAIL'
            $finalResult = 'OBJECT_SCOPE_OR_PROHIBITION_FAILURE'
        } else {
            $initializationStatus = 'PASS'
            Write-Output "BS2_COMMAND_READY TIMESTAMP=$($readyFields['TIMESTAMP']) INIT_ELAPSED=$initializationElapsed"

            $reportResult = Wait-Bs2Stage -Process $process -Label 'REPORT_TIMING' -StartMarker (Join-Path $analysisDir 'REPORT_TIMING_STARTED.marker') -CompletedMarker (Join-Path $analysisDir 'REPORT_TIMING_COMPLETED.marker') -BudgetSeconds $queryWatchdogSeconds
            $reportTimingStatus = $reportResult.Status
            $reportTimingElapsed = $reportResult.Elapsed
            Write-Output "BS2_REPORT_TIMING STATUS=$reportTimingStatus ELAPSED=$reportTimingElapsed"

            if ($reportTimingStatus -eq 'PASS') {
                $pathsResult = Wait-Bs2Stage -Process $process -Label 'GET_TIMING_PATHS' -StartMarker (Join-Path $analysisDir 'GET_TIMING_PATHS_STARTED.marker') -CompletedMarker (Join-Path $analysisDir 'GET_TIMING_PATHS_COMPLETED.marker') -BudgetSeconds $queryWatchdogSeconds
                $getTimingPathsStatus = $pathsResult.Status
                $getTimingPathsElapsed = $pathsResult.Elapsed
                Write-Output "BS2_GET_TIMING_PATHS STATUS=$getTimingPathsStatus ELAPSED=$getTimingPathsElapsed"

                if ($getTimingPathsStatus -eq 'PASS') {
                    $methodResult = Wait-Bs2Stage -Process $process -Label 'METHODOLOGY' -StartMarker (Join-Path $analysisDir 'METHODOLOGY_STARTED.marker') -CompletedMarker (Join-Path $analysisDir 'METHODOLOGY_COMPLETED.marker') -BudgetSeconds $methodologyWatchdogSeconds
                    $methodologyStatus = $methodResult.Status
                    $methodologyElapsed = $methodResult.Elapsed
                    Write-Output "BS2_METHODOLOGY STATUS=$methodologyStatus ELAPSED=$methodologyElapsed"
                    if ($methodologyStatus -eq 'PASS') {
                        $workerExitDeadline = (Get-EpochMilliseconds) + 60000
                        while (-not $process.HasExited -and (Get-EpochMilliseconds) -lt $workerExitDeadline) {
                            if ((Get-VivadoCount) -gt 1) { $overlap = $true; break }
                            Start-Sleep -Milliseconds 100
                        }
                        if ($overlap) {
                            $finalResult = 'VIVADO_ENVIRONMENT_NOT_ISOLATED'
                        } elseif ((Test-Path -LiteralPath (Join-Path $analysisDir 'WORKER_COMPLETED.marker')) -and $process.HasExited -and $process.ExitCode -eq 0) {
                            $finalResult = 'COMPLETE'
                        } else {
                            $finalResult = 'VIVADO_ERROR'
                        }
                    } elseif ($methodologyStatus -eq 'TIMEOUT') {
                        $finalResult = 'METHODOLOGY_TIMEOUT'
                        $timeoutPhase = 'METHODOLOGY'
                    } elseif ($methodologyStatus -eq 'ENVIRONMENT_OVERLAP') {
                        $finalResult = 'VIVADO_ENVIRONMENT_NOT_ISOLATED'
                    } else {
                        $finalResult = 'VIVADO_ERROR'
                    }
                } elseif ($getTimingPathsStatus -eq 'TIMEOUT') {
                    $finalResult = 'GET_TIMING_PATHS_TIMEOUT'
                    $timeoutPhase = 'GET_TIMING_PATHS'
                } elseif ($getTimingPathsStatus -eq 'ENVIRONMENT_OVERLAP') {
                    $finalResult = 'VIVADO_ENVIRONMENT_NOT_ISOLATED'
                } else {
                    $finalResult = 'VIVADO_ERROR'
                }
            } elseif ($reportTimingStatus -eq 'TIMEOUT') {
                $finalResult = 'REPORT_TIMING_TIMEOUT'
                $timeoutPhase = 'REPORT_TIMING'
            } elseif ($reportTimingStatus -eq 'ENVIRONMENT_OVERLAP') {
                $finalResult = 'VIVADO_ENVIRONMENT_NOT_ISOLATED'
            } else {
                $finalResult = 'VIVADO_ERROR'
            }
        }
    }
} catch {
    $supervisorError = $_.Exception.Message
    $finalResult = 'VIVADO_ERROR'
    Write-Utf8NoBom -Path (Join-Path $analysisDir 'SUPERVISOR_ERROR.marker') -Text "MARKER=SUPERVISOR_ERROR`nTIMESTAMP=$(Get-UtcTimestamp)`nERROR=$supervisorError`n"
}

if ($null -ne $process -and -not $process.HasExited) {
    Stop-Bs2WorkerTree -ProcessId $process.Id
    $workerTerminated = $true
    $null = $process.WaitForExit(60000)
}

$quiescenceDeadline = (Get-EpochMilliseconds) + 30000
while ((Get-VivadoCount) -ne 0 -and (Get-EpochMilliseconds) -lt $quiescenceDeadline) {
    Start-Sleep -Milliseconds 200
}
$postexistingVivadoCount = Get-VivadoCount
$endTimestamp = Get-UtcTimestamp
$endEpochMs = Get-EpochMilliseconds
$totalElapsedSeconds = (($endEpochMs - $launchEpochMs) / 1000.0).ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
$processExitCode = if ($null -ne $process -and $process.HasExited) { $process.ExitCode } else { 'N/A' }

$runnerLines = @(
    'EXPERIMENT_ID=BS2_EXP001'
    "START_TIMESTAMP=$launchTimestamp"
    "END_TIMESTAMP=$endTimestamp"
    "TOTAL_ELAPSED_SECONDS=$totalElapsedSeconds"
    "INITIALIZATION_STATUS=$initializationStatus"
    "INITIALIZATION_ELAPSED_SECONDS=$initializationElapsed"
    "REPORT_TIMING_STATUS=$reportTimingStatus"
    "REPORT_TIMING_ELAPSED_SECONDS=$reportTimingElapsed"
    "GET_TIMING_PATHS_STATUS=$getTimingPathsStatus"
    "GET_TIMING_PATHS_ELAPSED_SECONDS=$getTimingPathsElapsed"
    "METHODOLOGY_STATUS=$methodologyStatus"
    "METHODOLOGY_ELAPSED_SECONDS=$methodologyElapsed"
    "TIMEOUT_PHASE=$timeoutPhase"
    "WORKER_TERMINATED=$($workerTerminated.ToString().ToUpperInvariant())"
    "PROCESS_EXIT_CODE=$processExitCode"
    "POSTEXISTING_VIVADO_COUNT=$postexistingVivadoCount"
    'REPORT_BUS_SKEW_ATTEMPT_COUNT=0'
    "SUPERVISOR_ERROR=$supervisorError"
    "FINAL_RESULT=$finalResult"
)
Write-Utf8NoBom -Path $runnerState -Text (($runnerLines -join "`n") + "`n")
Append-Utf8NoBom -Path $processAudit -Text "END_TIMESTAMP=$endTimestamp`nPOSTEXISTING_VIVADO_COUNT=$postexistingVivadoCount`nFINAL_RESULT=$finalResult`n"
Write-Output "BS2_RUNNER_FINAL RESULT=$finalResult TOTAL_ELAPSED=$totalElapsedSeconds POSTEXISTING_VIVADO_COUNT=$postexistingVivadoCount"

switch ($finalResult) {
    'COMPLETE' { exit 0 }
    'REPORT_TIMING_TIMEOUT' { exit 124 }
    'INITIALIZATION_TIMEOUT' { exit 125 }
    'GET_TIMING_PATHS_TIMEOUT' { exit 126 }
    'METHODOLOGY_TIMEOUT' { exit 127 }
    'VIVADO_ENVIRONMENT_NOT_ISOLATED' { exit 2 }
    default { exit 1 }
}
