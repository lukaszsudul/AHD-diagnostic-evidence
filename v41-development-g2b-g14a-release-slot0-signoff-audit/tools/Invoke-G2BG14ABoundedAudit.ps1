$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$runtimeRoot = 'C:\FPGA\G2B_G14A_RUNTIME_20260903'
$outputDirectory = Join-Path $runtimeRoot 'raw'
$workerTemp = Join-Path $runtimeRoot 'temp'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $runtimeRoot 'G2B_G14A_BOUNDED_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$baseXdc = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery-2\raw\groups14_17\group_14_RELEASE_SLOT_0_AXI_TO_SOURCE\QUERY_BASE_WITHOUT_BUS_SKEW.xdc'
$bs3Candidate = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof\G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc'
$g13Candidate = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g13a-reset-return-signoff-audit\G2B_G13A_CANDIDATE_CONSTRAINTS.xdc'
$g14aCandidate = Join-Path $runtimeRoot 'G2B_G14A_CANDIDATE_CONSTRAINTS.xdc'
$referenceObjects = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery-2\raw\groups14_17\group_14_RELEASE_SLOT_0_AXI_TO_SOURCE\14_RELEASE_SLOT_0_AXI_TO_SOURCE_OBJECTS.txt'
$queryTimeoutSeconds = 300
$initializationTimeoutSeconds = 1800
$overallTimeoutSeconds = 3600

function Read-KeyValueFile {
    param([Parameter(Mandatory)][string]$Path)
    $values = @{}
    foreach ($line in Get-Content -LiteralPath $Path -ErrorAction Stop) {
        if ($line -match '^([^=]+)=(.*)$') {
            $values[$matches[1]] = $matches[2]
        }
    }
    return $values
}

function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Value)
    [System.IO.File]::WriteAllText($Path, $Value, [System.Text.UTF8Encoding]::new($false))
}

if (Test-Path -LiteralPath $outputDirectory) {
    throw "Audit output directory already exists: $outputDirectory"
}
New-Item -ItemType Directory -Path $outputDirectory | Out-Null
if (-not (Test-Path -LiteralPath $workerTemp -PathType Container)) {
    New-Item -ItemType Directory -Path $workerTemp | Out-Null
}

$requiredInputs = @($vivado, $worker, $checkpoint, $baseXdc, $bs3Candidate, $g13Candidate, $g14aCandidate, $referenceObjects)
foreach ($requiredInput in $requiredInputs) {
    if (-not (Test-Path -LiteralPath $requiredInput -PathType Leaf)) {
        throw "Required input is absent: $requiredInput"
    }
}

$preexistingVivado = @(Get-Process -Name vivado, vivado_lab -ErrorAction SilentlyContinue)
if ($preexistingVivado.Count -ne 0) {
    throw "Refusing to start with preexisting Vivado processes: $($preexistingVivado.Id -join ',')"
}

$env:XILINX_LOCAL_USER_DATA = 'NO'
$env:TEMP = $workerTemp
$env:TMP = $workerTemp

$stdoutPath = Join-Path $outputDirectory 'G2B_G14A_CONSOLE.stdout.log'
$stderrPath = Join-Path $outputDirectory 'G2B_G14A_CONSOLE.stderr.log'
$vivadoLog = Join-Path $outputDirectory 'G2B_G14A_VIVADO.log'
$activeQueryPath = Join-Path $outputDirectory 'ACTIVE_QUERY.marker'
$watchdogPath = Join-Path $outputDirectory 'G2B_G14A_EXTERNAL_WATCHDOG.txt'
$arguments = @(
    '-mode', 'batch',
    '-log', $vivadoLog,
    '-nojournal',
    '-source', $worker,
    '-tclargs',
    $checkpoint,
    $baseXdc,
    $bs3Candidate,
    $g13Candidate,
    $g14aCandidate,
    $referenceObjects,
    $outputDirectory
)

$startUtc = [DateTimeOffset]::UtcNow
$process = Start-Process -FilePath $vivado -ArgumentList $arguments -WorkingDirectory $outputDirectory `
    -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -WindowStyle Hidden -PassThru
$sawAnyQuery = $false
$timedOut = $false
$timeoutPhase = 'NONE'
$timeoutQuery = 'NONE'
$timeoutElapsed = 'N/A'
$terminationOutput = 'NONE'

try {
    while (-not $process.HasExited) {
        $now = [DateTimeOffset]::UtcNow
        $overallElapsed = ($now - $startUtc).TotalSeconds
        if ($overallElapsed -gt $overallTimeoutSeconds) {
            $timedOut = $true
            $timeoutPhase = 'OVERALL'
            $timeoutElapsed = ('{0:F3}' -f $overallElapsed)
        }

        if (-not $timedOut -and (Test-Path -LiteralPath $activeQueryPath -PathType Leaf)) {
            try {
                $active = Read-KeyValueFile -Path $activeQueryPath
                if ($active.ContainsKey('QUERY_ID') -and $active.ContainsKey('EPOCH_MILLISECONDS') -and
                    $active.ContainsKey('TIMEOUT_SECONDS') -and $active['TIMEOUT_SECONDS'] -ceq '300') {
                    $sawAnyQuery = $true
                    $queryStartMs = [int64]$active['EPOCH_MILLISECONDS']
                    $queryElapsedSeconds = ([DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds() - $queryStartMs) / 1000.0
                    if ($queryElapsedSeconds -gt $queryTimeoutSeconds) {
                        $timedOut = $true
                        $timeoutPhase = 'QUERY'
                        $timeoutQuery = $active['QUERY_ID']
                        $timeoutElapsed = ('{0:F3}' -f $queryElapsedSeconds)
                    }
                }
            } catch {
                # The worker may be between file creation and close; retry next poll.
            }
        }

        if (-not $timedOut -and -not $sawAnyQuery -and $overallElapsed -gt $initializationTimeoutSeconds) {
            $timedOut = $true
            $timeoutPhase = 'INITIALIZATION'
            $timeoutElapsed = ('{0:F3}' -f $overallElapsed)
        }

        if ($timedOut) {
            $taskkill = Join-Path $env:SystemRoot 'System32\taskkill.exe'
            $terminationOutput = (& $taskkill /PID $process.Id /T /F 2>&1 | Out-String).Trim()
            break
        }

        Start-Sleep -Milliseconds 1000
        $process.Refresh()
    }
} finally {
    try { $process.WaitForExit(30000) } catch {}
}

$endUtc = [DateTimeOffset]::UtcNow
$process.Refresh()
$exitCode = if ($process.HasExited) { $process.ExitCode } else { -1 }
$completedMarkers = @(Get-ChildItem -LiteralPath $outputDirectory -Filter 'QUERY_COMPLETED_*.marker' -File -ErrorAction SilentlyContinue | Sort-Object Name)
$startedMarkers = @(Get-ChildItem -LiteralPath $outputDirectory -Filter 'QUERY_STARTED_*.marker' -File -ErrorAction SilentlyContinue | Sort-Object Name)
$postexistingVivado = @(Get-Process -Name vivado, vivado_lab -ErrorAction SilentlyContinue)

$receipt = @(
    'TASK=G2B-G14-A',
    "START_UTC=$($startUtc.ToString('o'))",
    "END_UTC=$($endUtc.ToString('o'))",
    "ELAPSED_SECONDS=$('{0:F3}' -f ($endUtc - $startUtc).TotalSeconds)",
    "INITIALIZATION_TIMEOUT_SECONDS=$initializationTimeoutSeconds",
    "EXTERNAL_QUERY_TIMEOUT_SECONDS=$queryTimeoutSeconds",
    "OVERALL_TIMEOUT_SECONDS=$overallTimeoutSeconds",
    'QUERY_TIMEOUT_SCOPE=ACTIVE_QUERY_MARKER_TO_VALIDATED_COMPLETION_MARKER',
    "TIMED_OUT=$(if ($timedOut) { 'YES' } else { 'NO' })",
    "TIMEOUT_PHASE=$timeoutPhase",
    "TIMEOUT_QUERY=$timeoutQuery",
    "TIMEOUT_ELAPSED_SECONDS=$timeoutElapsed",
    "PROCESS_EXIT_CODE=$exitCode",
    "STARTED_QUERY_COUNT=$($startedMarkers.Count)",
    "COMPLETED_QUERY_COUNT=$($completedMarkers.Count)",
    "STARTED_QUERY_MARKERS=$((@($startedMarkers | ForEach-Object { $_.Name })) -join ',')",
    "COMPLETED_QUERY_MARKERS=$((@($completedMarkers | ForEach-Object { $_.Name })) -join ',')",
    "POSTEXISTING_VIVADO_COUNT=$($postexistingVivado.Count)",
    "TERMINATION_OUTPUT=$($terminationOutput -replace "`r?`n", ' | ')",
    'FULL_GROUP14_REPORT_BUS_SKEW_RETRIED=NO',
    'BITSTREAM_PRODUCED=NO',
    'HARDWARE_ACCESSED=NO'
) -join "`n"
Write-Utf8NoBom -Path $watchdogPath -Value ($receipt + "`n")

if ($timedOut) {
    throw "Vivado audit timed out in $timeoutPhase ($timeoutQuery) after $timeoutElapsed seconds"
}
if ($exitCode -ne 0) {
    throw "Vivado audit failed with exit code $exitCode"
}
if ($completedMarkers.Count -ne 6) {
    throw "Expected six completed bounded queries, found $($completedMarkers.Count)"
}
if ($postexistingVivado.Count -ne 0) {
    throw "Vivado processes remain after completion: $($postexistingVivado.Id -join ',')"
}

Write-Output "G2B_G14A_WATCHDOG_PASS elapsed=$('{0:F3}' -f ($endUtc - $startUtc).TotalSeconds) queries=$($completedMarkers.Count)"
