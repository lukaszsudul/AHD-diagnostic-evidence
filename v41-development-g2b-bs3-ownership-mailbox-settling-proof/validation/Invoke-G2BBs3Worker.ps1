[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('inventory','slot','generation','epoch','methodology','validate_all')]
    [string]$Mode,

    [Parameter(Mandatory)]
    [string]$BaseXdc,

    [Parameter(Mandatory)]
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$analysisRoot = 'C:\FPGA\G2B_BS3_OWNERSHIP_20260902'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $analysisRoot 'G2B_BS3_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$candidateXdc = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof\G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc'
$expectedDcpHash = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$initializationTimeoutSeconds = 1800
$queryTimeoutSeconds = 300

function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Text)
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

foreach ($requiredPath in @($vivado, $worker, $checkpoint, $BaseXdc, $candidateXdc)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required file is missing: $requiredPath"
    }
}

if (Test-Path -LiteralPath $OutputDirectory) {
    if ((Get-ChildItem -LiteralPath $OutputDirectory -Force | Measure-Object).Count -ne 0) {
        throw "Output directory is not empty; retry is intentionally refused: $OutputDirectory"
    }
} else {
    New-Item -ItemType Directory -Path $OutputDirectory | Out-Null
}

$preexistingVivado = @(Get-Process -Name 'vivado','vivado_lab' -ErrorAction SilentlyContinue)
if ($preexistingVivado.Count -ne 0) {
    throw "Vivado environment is not isolated; count=$($preexistingVivado.Count)"
}

$dcpHash = (Get-FileHash -LiteralPath $checkpoint -Algorithm SHA256).Hash.ToUpperInvariant()
if ($dcpHash -ne $expectedDcpHash) {
    throw "Sealed DCP hash mismatch: $dcpHash"
}

$consoleLog = Join-Path $OutputDirectory 'G2B_BS3_CONSOLE.log'
$consoleErrorLog = Join-Path $OutputDirectory 'G2B_BS3_CONSOLE.stderr.log'
$vivadoLog = Join-Path $OutputDirectory 'G2B_BS3_VIVADO.log'
$runtimeReceipt = Join-Path $OutputDirectory 'G2B_BS3_EXTERNAL_WATCHDOG.txt'

$arguments = @(
    '-mode', 'batch',
    '-log', $vivadoLog,
    '-nojournal',
    '-source', $worker,
    '-tclargs', $checkpoint, $BaseXdc, $candidateXdc, $OutputDirectory, $Mode
)
$launchCommand = '"{0}" {1}' -f $vivado, (($arguments | ForEach-Object { '"{0}"' -f $_ }) -join ' ')
Write-Utf8NoBom -Path (Join-Path $OutputDirectory 'G2B_BS3_LAUNCH_COMMAND.txt') -Text "$launchCommand`n"

$start = [DateTimeOffset]::UtcNow
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$process = Start-Process -FilePath $vivado -ArgumentList $arguments `
    -WorkingDirectory $analysisRoot `
    -RedirectStandardOutput $consoleLog `
    -RedirectStandardError $consoleErrorLog `
    -PassThru -WindowStyle Hidden

$queryMarker = Join-Path $OutputDirectory 'QUERY_STARTED.marker'
$initializationDeadline = $start.AddSeconds($initializationTimeoutSeconds)
$queryDeadline = $null
$lastQueryEpoch = $null
$timeoutPhase = 'NONE'
while (-not $process.HasExited) {
    if (Test-Path -LiteralPath $queryMarker) {
        $queryStartEpochLine = Get-Content -LiteralPath $queryMarker |
            Where-Object { $_ -like 'EPOCH_MILLISECONDS=*' } |
            Select-Object -First 1
        if ($queryStartEpochLine) {
            $queryStartEpoch = [Int64]$queryStartEpochLine.Substring('EPOCH_MILLISECONDS='.Length)
            if ($queryStartEpoch -ne $lastQueryEpoch) {
                $lastQueryEpoch = $queryStartEpoch
                $queryDeadline = [DateTimeOffset]::FromUnixTimeMilliseconds($queryStartEpoch).AddSeconds($queryTimeoutSeconds)
            }
        }
    }
    $currentTime = [DateTimeOffset]::UtcNow
    if ($null -ne $queryDeadline) {
        if ($currentTime -ge $queryDeadline) {
            $timeoutPhase = 'QUERY'
            break
        }
    } elseif ($currentTime -ge $initializationDeadline) {
        $timeoutPhase = 'INITIALIZATION'
        break
    }
    Start-Sleep -Milliseconds 200
    $process.Refresh()
}
$timedOut = $timeoutPhase -ne 'NONE'
if ($timedOut) {
    $killOutput = & "$env:SystemRoot\System32\taskkill.exe" /PID $process.Id /T /F 2>&1 | Out-String
    $null = $process.WaitForExit(60000)
} else {
    $killOutput = 'NONE'
}
$stopwatch.Stop()
$process.Refresh()
$end = [DateTimeOffset]::UtcNow
$exitCode = if ($process.HasExited) { $process.ExitCode } else { -999 }
$elapsed = $stopwatch.Elapsed.TotalSeconds.ToString('F3', [Globalization.CultureInfo]::InvariantCulture)
$postexistingVivado = @(Get-Process -Name 'vivado','vivado_lab' -ErrorAction SilentlyContinue).Count

$receipt = @(
    "MODE=$Mode"
    "START_UTC=$($start.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"
    "END_UTC=$($end.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"
    "INITIALIZATION_TIMEOUT_SECONDS=$initializationTimeoutSeconds"
    "EXTERNAL_QUERY_TIMEOUT_SECONDS=$queryTimeoutSeconds"
    'QUERY_TIMEOUT_SCOPE=MARKER_TO_COMPLETION_EXTERNAL_PROCESS_SUPERVISOR'
    "ELAPSED_SECONDS=$elapsed"
    "TIMED_OUT=$($timedOut.ToString().ToUpperInvariant())"
    "TIMEOUT_PHASE=$timeoutPhase"
    "PROCESS_EXIT_CODE=$exitCode"
    "POSTEXISTING_VIVADO_COUNT=$postexistingVivado"
    'REPORT_BUS_SKEW_ATTEMPT_COUNT=0'
    "DCP_SHA256=$dcpHash"
    "BASE_XDC_SHA256=$((Get-FileHash -LiteralPath $BaseXdc -Algorithm SHA256).Hash.ToUpperInvariant())"
    "CANDIDATE_XDC_SHA256=$((Get-FileHash -LiteralPath $candidateXdc -Algorithm SHA256).Hash.ToUpperInvariant())"
    "WORKER_TCL_SHA256=$((Get-FileHash -LiteralPath $worker -Algorithm SHA256).Hash.ToUpperInvariant())"
    "TASKKILL_OUTPUT=$($killOutput.Trim())"
)
Write-Utf8NoBom -Path $runtimeReceipt -Text (($receipt -join "`n") + "`n")

if ($timedOut) { exit 124 }
if ($postexistingVivado -ne 0) { exit 2 }
exit $exitCode
