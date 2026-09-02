[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$invariant = [Globalization.CultureInfo]::InvariantCulture

$evidenceRoot = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g13a-reset-return-signoff-audit'
$outputDirectory = Join-Path $evidenceRoot 'raw\timing'
$toolsDirectory = Join-Path $evidenceRoot 'tools'
$runtimeDirectory = 'C:\FPGA\G2B_G13A_RUNTIME_20260902T190000Z'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $toolsDirectory 'G2B_G13A_BOUNDED_TIMING_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$primaryBase = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery\raw\groups10_17\group_13_RESET_RETURN_SOURCE_TO_AXI\QUERY_BASE_WITHOUT_BUS_SKEW.xdc'
$sourceFullBase = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof\validation\G2B_BS3_FULL_BASE_WITHOUT_GROUP9.xdc'
$derivedFullBase = Join-Path $outputDirectory 'G2B_G13A_FULL_BASE_WITHOUT_GROUP9_AND_GROUP13.xdc'
$bs3Candidate = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof\G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc'
$g13Candidate = Join-Path $evidenceRoot 'G2B_G13A_CANDIDATE_CONSTRAINTS.xdc'
$referenceObjects = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery\raw\groups10_17\group_13_RESET_RETURN_SOURCE_TO_AXI\13_RESET_RETURN_SOURCE_TO_AXI_OBJECTS.txt'
$expectedDcpHash = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$expectedPrimaryBaseHash = '5B285774E2CBCAD66D6C1A777761EE066D57811C648E8C2A909F8AC4DF29FF3B'
$expectedSourceFullBaseHash = '3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507'
$expectedDerivedFullBaseHash = '3F7D8613AB3ECF579F3F1E7A09B1608602768D2B9C880CE3B755437081DF1F87'
$expectedBs3CandidateHash = 'AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087'
$initializationTimeoutSeconds = 1800
$queryTimeoutSeconds = 300

function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Text)
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-CommandCount {
    param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string]$Command)
    return [regex]::Matches($Text, "(?m)^\s*$([regex]::Escape($Command))\b").Count
}

function Read-KeyValueFile {
    param([Parameter(Mandatory)][string]$Path)
    $result = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^([^=]+)=(.*)$') { $result[$matches[1]] = $matches[2] }
    }
    return $result
}

function Get-VivadoProcesses {
    return @(Get-Process -Name 'vivado','vivado_lab' -ErrorAction SilentlyContinue)
}

function Stop-ProcessTree {
    param([Parameter(Mandatory)][int]$ProcessId)
    return (& "$env:SystemRoot\System32\taskkill.exe" /PID $ProcessId /T /F 2>&1 | Out-String).Trim()
}

foreach ($required in @($vivado,$worker,$checkpoint,$primaryBase,$sourceFullBase,$derivedFullBase,$bs3Candidate,$g13Candidate,$referenceObjects)) {
    if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
        throw "Required timing input is absent: $required"
    }
}
if (@(Get-VivadoProcesses).Count -ne 0) {
    throw 'Vivado isolation check failed before launch'
}
if (Test-Path -LiteralPath $runtimeDirectory) {
    throw "Fixed one-attempt runtime directory already exists: $runtimeDirectory"
}

$oneAttemptOutputs = @(
    'ACTIVE_QUERY.marker','WORKER_STARTED.marker','WORKER_COMPLETED.marker',
    'G2B_G13A_CONSOLE.stdout.log','G2B_G13A_CONSOLE.stderr.log','G2B_G13A_VIVADO.log',
    'G2B_G13A_EXTERNAL_WATCHDOG.txt','G2B_G13A_PREFLIGHT.txt',
    'G2B_G13A_TIMING_EXECUTION_RECEIPT.txt','G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc'
) | ForEach-Object { Join-Path $outputDirectory $_ }
foreach ($path in $oneAttemptOutputs) {
    if (Test-Path -LiteralPath $path) { throw "One-attempt output already exists: $path" }
}
if (Test-Path -LiteralPath (Join-Path $evidenceRoot 'G2B_G13A_CANDIDATE_RESULTS.csv')) {
    throw 'Candidate results already exist; retry is refused'
}

$dcpHash = Get-Sha256 $checkpoint
$primaryBaseHash = Get-Sha256 $primaryBase
$sourceFullBaseHash = Get-Sha256 $sourceFullBase
$derivedFullBaseHash = Get-Sha256 $derivedFullBase
$bs3CandidateHash = Get-Sha256 $bs3Candidate
$g13CandidateHash = Get-Sha256 $g13Candidate
$workerHash = Get-Sha256 $worker
$runnerHash = Get-Sha256 $PSCommandPath
if ($dcpHash -cne $expectedDcpHash) { throw "DCP hash mismatch: $dcpHash" }
if ($primaryBaseHash -cne $expectedPrimaryBaseHash) { throw "Primary base hash mismatch: $primaryBaseHash" }
if ($sourceFullBaseHash -cne $expectedSourceFullBaseHash) { throw "Source full-base hash mismatch: $sourceFullBaseHash" }
if ($derivedFullBaseHash -cne $expectedDerivedFullBaseHash) { throw "Derived full-base hash mismatch: $derivedFullBaseHash" }
if ($bs3CandidateHash -cne $expectedBs3CandidateHash) { throw "BS3 candidate hash mismatch: $bs3CandidateHash" }

$primaryText = [IO.File]::ReadAllText($primaryBase)
$sourceFullText = [IO.File]::ReadAllText($sourceFullBase)
$derivedFullText = [IO.File]::ReadAllText($derivedFullBase)
$bs3CandidateText = [IO.File]::ReadAllText($bs3Candidate)
$g13CandidateText = [IO.File]::ReadAllText($g13Candidate)
if ((Get-CommandCount $primaryText 'set_bus_skew') -ne 0 -or (Get-CommandCount $primaryText 'set_max_delay') -ne 9) {
    throw 'Primary bus-skew-free context command counts differ from 0/9'
}
if ((Get-CommandCount $sourceFullText 'set_bus_skew') -ne 16 -or (Get-CommandCount $sourceFullText 'set_max_delay') -ne 9) {
    throw 'Source full-base command counts differ from 16/9'
}
if ((Get-CommandCount $derivedFullText 'set_bus_skew') -ne 15 -or (Get-CommandCount $derivedFullText 'set_max_delay') -ne 9) {
    throw 'Derived full-base command counts differ from 15/9'
}
if ((Get-CommandCount $bs3CandidateText 'set_bus_skew') -ne 0 -or (Get-CommandCount $bs3CandidateText 'set_max_delay') -ne 3) {
    throw 'BS3 candidate command counts differ from 0/3'
}
if ((Get-CommandCount $g13CandidateText 'set_bus_skew') -ne 0 -or (Get-CommandCount $g13CandidateText 'set_max_delay') -ne 2) {
    throw 'G13-A candidate command counts differ from 0/2'
}
if ([regex]::IsMatch($g13CandidateText, '(?m)^\s*(if|foreach|while|for|error|source)\b')) {
    throw 'G13-A candidate contains a procedural or source command'
}
if ([regex]::Matches($g13CandidateText, '(?m)^\s*set_max_delay\b[^\r\n]+-to \$g2b_g13a_(abandoned|all)_dst_cells\s+6\.000\s*$').Count -ne 2 -or
    [regex]::IsMatch($g13CandidateText, '(?m)^\s*set_max_delay\b[^\r\n]+-to \$g2b_g13a_.*_dst_d\b')) {
    throw 'G13-A candidate does not target the two destination-cell collections exactly'
}

$sourceLines = @(Get-Content -LiteralPath $sourceFullBase)
$derivedLines = @(Get-Content -LiteralPath $derivedFullBase)
$lineDiff = @(Compare-Object -ReferenceObject $sourceLines -DifferenceObject $derivedLines)
$expectedRemovedLine = 'set_bus_skew -from [filter [get_cells -quiet -hier -regexp .*G2B_ONECH_C2H/(reset_abandoned_hold_source|reset_commit_phase_hold_source)_reg.*] {IS_SEQUENTIAL == 1}] -to $_xlnx_shared_i10 3.000'
if ($lineDiff.Count -ne 1 -or $lineDiff[0].SideIndicator -cne '<=' -or $lineDiff[0].InputObject -cne $expectedRemovedLine) {
    throw 'Derived full base does not differ by exactly the single Group-13 command'
}

$preflight = @(
    'STATE=PASS'
    "SEALED_DCP_SHA256=$dcpHash"
    "PRIMARY_BASE_SHA256=$primaryBaseHash"
    'PRIMARY_BASE_BUS_SKEW_COMMAND_COUNT=0'
    'PRIMARY_BASE_MAX_DELAY_COMMAND_COUNT=9'
    "SOURCE_FULL_BASE_SHA256=$sourceFullBaseHash"
    'SOURCE_FULL_BASE_BUS_SKEW_COMMAND_COUNT=16'
    'SOURCE_FULL_BASE_MAX_DELAY_COMMAND_COUNT=9'
    "DERIVED_FULL_BASE_SHA256=$derivedFullBaseHash"
    'DERIVED_FULL_BASE_BUS_SKEW_COMMAND_COUNT=15'
    'DERIVED_FULL_BASE_MAX_DELAY_COMMAND_COUNT=9'
    'REMOVED_LINE_COUNT=1'
    "REMOVED_LINE=$expectedRemovedLine"
    "BS3_CANDIDATE_SHA256=$bs3CandidateHash"
    'BS3_CANDIDATE_MAX_DELAY_COMMAND_COUNT=3'
    "G13A_CANDIDATE_SHA256=$g13CandidateHash"
    'G13A_CANDIDATE_BUS_SKEW_COMMAND_COUNT=0'
    'G13A_CANDIDATE_MAX_DELAY_COMMAND_COUNT=2'
    'G13A_CANDIDATE_PROCEDURAL_COMMAND_COUNT=0'
    "WORKER_SHA256=$workerHash"
    "RUNNER_SHA256=$runnerHash"
    'FULL_GROUP13_BUS_SKEW_RETRIED=NO'
    'HARDWARE_ACCESSED=NO'
)
Write-Utf8NoBom -Path (Join-Path $outputDirectory 'G2B_G13A_PREFLIGHT.txt') -Text (($preflight -join "`n") + "`n")

New-Item -ItemType Directory -Path $runtimeDirectory | Out-Null
$consoleOut = Join-Path $outputDirectory 'G2B_G13A_CONSOLE.stdout.log'
$consoleErr = Join-Path $outputDirectory 'G2B_G13A_CONSOLE.stderr.log'
$vivadoLog = Join-Path $outputDirectory 'G2B_G13A_VIVADO.log'
$watchdogPath = Join-Path $outputDirectory 'G2B_G13A_EXTERNAL_WATCHDOG.txt'
$launchPath = Join-Path $outputDirectory 'G2B_G13A_LAUNCH_COMMAND.txt'
$activeMarker = Join-Path $outputDirectory 'ACTIVE_QUERY.marker'
$arguments = @(
    '-mode','batch','-log',$vivadoLog,'-nojournal','-source',$worker,'-tclargs',
    $checkpoint,$primaryBase,$derivedFullBase,$bs3Candidate,$g13Candidate,
    $referenceObjects,$outputDirectory,$expectedDcpHash,$expectedDerivedFullBaseHash
)
$quotedArguments = $arguments | ForEach-Object { '"{0}"' -f ([string]$_).Replace('"','""') }
Write-Utf8NoBom -Path $launchPath -Text (('"{0}" {1}' -f $vivado,($quotedArguments -join ' ')) + "`n")

$childEnvironment = @{
    TEMP = $runtimeDirectory
    TMP = $runtimeDirectory
    XILINX_LOCAL_USER_DATA = 'NO'
    XILINX_TCLAPP_REPO = 'C:\AMDDesignTools\2025.2\Vivado\data\XilinxTclStore'
}
$start = [DateTimeOffset]::UtcNow
$phaseDeadline = $start.AddSeconds($initializationTimeoutSeconds)
$queryDeadline = $null
$activeEpoch = $null
$activeQueryId = 'NONE'
$timeoutPhase = 'NONE'
$supervisorError = 'NONE'
$killOutput = 'NONE'
$timeline = [Collections.Generic.List[string]]::new()
$stopwatch = [Diagnostics.Stopwatch]::StartNew()
$process = $null
try {
    $process = Start-Process -FilePath $vivado -ArgumentList $arguments -WorkingDirectory $runtimeDirectory `
        -RedirectStandardOutput $consoleOut -RedirectStandardError $consoleErr `
        -Environment $childEnvironment -PassThru -WindowStyle Hidden
    $timeline.Add("PROCESS_STARTED_UTC=$($start.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))")
    while ($true) {
        $process.Refresh()
        if ($process.HasExited) { break }
        if (Test-Path -LiteralPath $activeMarker -PathType Leaf) {
            try {
                $marker = Read-KeyValueFile $activeMarker
                if ($marker.ContainsKey('QUERY_ID') -and $marker.ContainsKey('EPOCH_MILLISECONDS') -and
                    $marker.ContainsKey('TIMEOUT_SECONDS') -and $marker.ContainsKey('COMMAND')) {
                    $epoch = [Int64]::Parse($marker['EPOCH_MILLISECONDS'], $invariant)
                    if ($null -eq $activeEpoch -or $epoch -ne $activeEpoch) {
                        $activeEpoch = $epoch
                        $activeQueryId = $marker['QUERY_ID']
                        if ($marker['TIMEOUT_SECONDS'] -cne ([string]$queryTimeoutSeconds)) {
                            throw "Invalid query timeout marker: $($marker['TIMEOUT_SECONDS'])"
                        }
                        $queryStart = [DateTimeOffset]::FromUnixTimeMilliseconds($epoch)
                        $queryDeadline = $queryStart.AddSeconds($queryTimeoutSeconds)
                        $timeline.Add("QUERY_STARTED|$activeQueryId|$($queryStart.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))|$($marker['COMMAND'])")
                    }
                }
            } catch {
                if ($supervisorError -eq 'NONE') {
                    $supervisorError = 'MARKER_READ_ERROR:' + $_.Exception.Message.Replace("`r",' ').Replace("`n",' ')
                }
            }
        } elseif ($null -ne $activeEpoch) {
            $timeline.Add("QUERY_COMPLETED_OBSERVED|$activeQueryId|$([DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))")
            $activeEpoch = $null
            $activeQueryId = 'NONE'
            $queryDeadline = $null
            $phaseDeadline = [DateTimeOffset]::UtcNow.AddSeconds($initializationTimeoutSeconds)
        }
        $now = [DateTimeOffset]::UtcNow
        if ($null -ne $queryDeadline) {
            if ($now -ge $queryDeadline) {
                $timeoutPhase = "QUERY:$activeQueryId"
                break
            }
        } elseif ($now -ge $phaseDeadline) {
            $timeoutPhase = 'INITIALIZATION_OR_INTERQUERY'
            break
        }
        Start-Sleep -Milliseconds 200
    }
    if ($timeoutPhase -ne 'NONE') {
        $killOutput = Stop-ProcessTree -ProcessId $process.Id
        [void]$process.WaitForExit(60000)
    }
} catch {
    $supervisorError = 'SUPERVISOR_EXCEPTION:' + $_.Exception.Message.Replace("`r",' ').Replace("`n",' ')
    if ($null -ne $process) {
        $process.Refresh()
        if (-not $process.HasExited) {
            $killOutput = Stop-ProcessTree -ProcessId $process.Id
            [void]$process.WaitForExit(60000)
        }
    }
} finally {
    $stopwatch.Stop()
}

$end = [DateTimeOffset]::UtcNow
if ($null -ne $process) { $process.Refresh() }
$exitCode = if ($null -ne $process -and $process.HasExited) { $process.ExitCode } else { -999 }
$postVivadoCount = @(Get-VivadoProcesses).Count
$elapsed = $stopwatch.Elapsed.TotalSeconds.ToString('F3', $invariant)
$timedOut = $timeoutPhase -ne 'NONE'
$watchdog = @(
    "START_UTC=$($start.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"
    "END_UTC=$($end.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"
    "ELAPSED_SECONDS=$elapsed"
    "INITIALIZATION_TIMEOUT_SECONDS=$initializationTimeoutSeconds"
    "EXTERNAL_QUERY_TIMEOUT_SECONDS=$queryTimeoutSeconds"
    'QUERY_TIMEOUT_SCOPE=ACTIVE_QUERY_MARKER_TO_COMPLETION'
    "TIMED_OUT=$($timedOut.ToString().ToUpperInvariant())"
    "TIMEOUT_PHASE=$timeoutPhase"
    "PROCESS_EXIT_CODE=$exitCode"
    "SUPERVISOR_ERROR=$supervisorError"
    "POSTEXISTING_VIVADO_COUNT=$postVivadoCount"
    "TASKKILL_OUTPUT=$killOutput"
    'FULL_GROUP13_BUS_SKEW_RETRIED=NO'
    'HARDWARE_ACCESSED=NO'
)
Write-Utf8NoBom -Path $watchdogPath -Text (($watchdog -join "`n") + "`n")
Write-Utf8NoBom -Path (Join-Path $outputDirectory 'G2B_G13A_QUERY_TIMELINE.log') -Text (($timeline -join "`n") + "`n")

if ($timedOut) { throw "Vivado timing stage timed out: $timeoutPhase" }
if ($supervisorError -ne 'NONE') { throw $supervisorError }
if ($exitCode -ne 0) { throw "Vivado exited nonzero: $exitCode" }
if ($postVivadoCount -ne 0) { throw "Vivado process remains after run: $postVivadoCount" }

$requiredOutputs = @(
    'WORKER_COMPLETED.marker','G2B_G13A_ROUTE_STATUS.rpt','G2B_G13A_ROUTE_SIGNATURE.txt',
    'G2B_G13A_SCOPE_SUMMARY.txt','G2B_G13A_EXACT_SCOPE_REPORT_TIMING.rpt',
    'G2B_G13A_REPORT_TIMING_SUMMARY.txt','G2B_G13A_GET_TIMING_PATHS_SUMMARY.txt',
    'G2B_G13A_PRIMARY_TIMING_PATHS.csv','G2B_G13A_PRIMARY_WORST_PATH_PROPERTIES.txt',
    'G2B_G13A_CANDIDATE_RESET_ABANDONED_HOLD_PATH_PROPERTIES.txt',
    'G2B_G13A_CANDIDATE_RESET_COMMIT_PHASE_HOLD_PATH_PROPERTIES.txt',
    'G2B_G13A_AGGREGATE_MEMBERSHIP_SUMMARY.txt','G2B_G13A_SUPPLEMENTAL_AGGREGATE_INVENTORY.csv',
    'G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv','G2B_G13A_SUPPLEMENTAL_AGGREGATE_PATH_PROPERTIES.txt',
    'G2B_G13A_FOCUSED_TIMING_METHODOLOGY.rpt','G2B_G13A_FOCUSED_METHODOLOGY_SUMMARY.txt',
    'G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc'
) | ForEach-Object { Join-Path $outputDirectory $_ }
foreach ($path in $requiredOutputs) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Expected output is absent: $path" }
}
$candidateResultsPath = Join-Path $evidenceRoot 'G2B_G13A_CANDIDATE_RESULTS.csv'
if (-not (Test-Path -LiteralPath $candidateResultsPath -PathType Leaf)) { throw 'Candidate results CSV is absent' }
$resultRows = @(Import-Csv -LiteralPath $candidateResultsPath)
if ($resultRows.Count -ne 2) { throw "Candidate result row count is not 2: $($resultRows.Count)" }
foreach ($row in $resultRows) {
    if ($row.Result -cne 'PASS') { throw "Candidate family is not PASS: $($row.Family)" }
    $requiredNs = [double]::Parse($row.Required_ns, $invariant)
    $actualNs = [double]::Parse($row.Worst_Actual_ns, $invariant)
    $slackNs = [double]::Parse($row.Slack_ns, $invariant)
    if ([Math]::Abs($requiredNs - 6.000) -gt 0.0005 -or $actualNs -gt 6.0005 -or $slackNs -lt -0.0005) {
        throw "Candidate numeric validation failed: $($row.Family)"
    }
}
$supplementalResultsPath = Join-Path $outputDirectory 'G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv'
$supplementalRows = @(Import-Csv -LiteralPath $supplementalResultsPath)
if ($supplementalRows.Count -ne 1 -or $supplementalRows[0].Coverage_Record -cne 'SUPPLEMENTAL_AGGREGATE_COVERAGE' -or
    $supplementalRows[0].Result -cne 'PASS' -or $supplementalRows[0].Target_Scope -cne 'CELLS_ALL_TIMING_ENDPOINT_PINS') {
    throw 'Supplemental aggregate coverage row is absent or invalid'
}
$supplementalRequired = [double]::Parse($supplementalRows[0].Required_ns, $invariant)
$supplementalActual = [double]::Parse($supplementalRows[0].Worst_Actual_ns, $invariant)
$supplementalSlack = [double]::Parse($supplementalRows[0].Slack_ns, $invariant)
if ([Math]::Abs($supplementalRequired - 6.000) -gt 0.0005 -or $supplementalActual -gt 6.0005 -or $supplementalSlack -lt -0.0005) {
    throw 'Supplemental aggregate numeric validation failed'
}
$appliedPath = Join-Path $outputDirectory 'G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc'
$appliedText = [IO.File]::ReadAllText($appliedPath)
$appliedBusSkewCount = Get-CommandCount $appliedText 'set_bus_skew'
$appliedMaxDelayCount = Get-CommandCount $appliedText 'set_max_delay'
if ($appliedBusSkewCount -ne 15 -or $appliedMaxDelayCount -ne 14) {
    throw "Applied candidate context counts differ from 15/14: $appliedBusSkewCount/$appliedMaxDelayCount"
}
$appliedGroup13SkewCount = [regex]::Matches($appliedText, '(?m)^\s*set_bus_skew\b[^\r\n]*(reset_abandoned_hold_source|reset_commit_phase_hold_source)').Count
if ($appliedGroup13SkewCount -ne 0) { throw 'Applied candidate context still contains Group-13 bus skew' }

$warningLines = @()
foreach ($path in @($consoleOut,$consoleErr,$vivadoLog)) {
    if (Test-Path -LiteralPath $path) {
        $warningLines += @(Select-String -LiteralPath $path -Pattern '^(WARNING:|CRITICAL WARNING:)' | ForEach-Object { $_.Line })
    }
}
$warningLines = @($warningLines | Sort-Object -Unique)
Write-Utf8NoBom -Path (Join-Path $outputDirectory 'G2B_G13A_WARNINGS.txt') -Text $(
    if ($warningLines.Count -eq 0) { "NONE`n" } else { ($warningLines -join "`n") + "`n" }
)

$receipt = @(
    'STATE=PASS'
    "TOTAL_RUNTIME_SECONDS=$elapsed"
    "PROCESS_EXIT_CODE=$exitCode"
    "SEALED_DCP_SHA256=$dcpHash"
    "PRIMARY_BASE_SHA256=$primaryBaseHash"
    "DERIVED_FULL_BASE_SHA256=$derivedFullBaseHash"
    "BS3_CANDIDATE_SHA256=$bs3CandidateHash"
    "G13A_CANDIDATE_SHA256=$g13CandidateHash"
    "WORKER_SHA256=$workerHash"
    "RUNNER_SHA256=$runnerHash"
    "APPLIED_CONTEXT_SHA256=$(Get-Sha256 $appliedPath)"
    "APPLIED_CONTEXT_BUS_SKEW_COMMAND_COUNT=$appliedBusSkewCount"
    "APPLIED_CONTEXT_MAX_DELAY_COMMAND_COUNT=$appliedMaxDelayCount"
    "APPLIED_CONTEXT_GROUP13_BUS_SKEW_COMMAND_COUNT=$appliedGroup13SkewCount"
    "CANDIDATE_RESULTS_SHA256=$(Get-Sha256 $candidateResultsPath)"
    "SUPPLEMENTAL_AGGREGATE_RESULTS_SHA256=$(Get-Sha256 $supplementalResultsPath)"
    "WARNING_COUNT=$($warningLines.Count)"
    'FULL_GROUP13_BUS_SKEW_RETRIED=NO'
    'BITSTREAM_PRODUCED=NO'
    'HARDWARE_ACCESSED=NO'
)
Write-Utf8NoBom -Path (Join-Path $outputDirectory 'G2B_G13A_TIMING_EXECUTION_RECEIPT.txt') -Text (($receipt -join "`n") + "`n")
Write-Output "G2B_G13A_RUN_PASS runtime=${elapsed}s candidate=$g13CandidateHash"
