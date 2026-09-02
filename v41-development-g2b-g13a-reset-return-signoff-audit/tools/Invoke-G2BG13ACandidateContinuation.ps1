[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$invariant = [Globalization.CultureInfo]::InvariantCulture

$evidenceRoot = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g13a-reset-return-signoff-audit'
$outputDirectory = Join-Path $evidenceRoot 'raw\timing\candidate_continuation'
$runtimeDirectory = 'C:\FPGA\G2B_G13A_RUNTIME_CONTINUATION_20260902T192000Z'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $evidenceRoot 'tools\G2B_G13A_CANDIDATE_CONTINUATION_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$sourceFullBase = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof\validation\G2B_BS3_FULL_BASE_WITHOUT_GROUP9.xdc'
$derivedFullBase = Join-Path $evidenceRoot 'raw\timing\G2B_G13A_FULL_BASE_WITHOUT_GROUP9_AND_GROUP13.xdc'
$bs3Candidate = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof\G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc'
$g13Candidate = Join-Path $evidenceRoot 'G2B_G13A_CANDIDATE_CONSTRAINTS.xdc'
$referenceObjects = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery\raw\groups10_17\group_13_RESET_RETURN_SOURCE_TO_AXI\13_RESET_RETURN_SOURCE_TO_AXI_OBJECTS.txt'
$attempt1Disposition = Join-Path $evidenceRoot 'raw\timing\G2B_G13A_ATTEMPT1_DISPOSITION.txt'
$expectedDcpHash = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$expectedSourceFullBaseHash = '3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507'
$expectedDerivedFullBaseHash = '3F7D8613AB3ECF579F3F1E7A09B1608602768D2B9C880CE3B755437081DF1F87'
$expectedBs3CandidateHash = 'AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087'
$expectedG13CandidateHash = 'E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312'
$expectedWorkerHash = 'CBDFF958DCB1D4168EBA08C3FC5089836C17419D8765FD06EDBBB43389ED50D9'
$attempt1ElapsedSeconds = 1135.069
$attempt1StartUtc = [DateTimeOffset]::Parse('2026-09-02T16:52:49.090Z', $invariant)
$initializationTimeoutSeconds = 1800
$queryTimeoutSeconds = 300

function Write-Utf8NoBom {
    param([Parameter(Mandatory)][string]$Path, [Parameter(Mandatory)][string]$Text)
    [IO.File]::WriteAllText($Path, $Text, [Text.UTF8Encoding]::new($false))
}
function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}
function Get-CommandCount {
    param([Parameter(Mandatory)][string]$Text, [Parameter(Mandatory)][string]$Command)
    [regex]::Matches($Text, "(?m)^\s*$([regex]::Escape($Command))\b").Count
}
function Read-KeyValueFile {
    param([Parameter(Mandatory)][string]$Path)
    $result = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^([^=]+)=(.*)$') { $result[$matches[1]] = $matches[2] }
    }
    $result
}
function Get-VivadoProcesses { @(Get-Process -Name 'vivado','vivado_lab' -ErrorAction SilentlyContinue) }
function Stop-ProcessTree {
    param([Parameter(Mandatory)][int]$ProcessId)
    (& "$env:SystemRoot\System32\taskkill.exe" /PID $ProcessId /T /F 2>&1 | Out-String).Trim()
}

foreach ($path in @($vivado,$worker,$checkpoint,$sourceFullBase,$derivedFullBase,$bs3Candidate,$g13Candidate,$referenceObjects,$attempt1Disposition)) {
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "Required continuation input absent: $path" }
}
if (@(Get-VivadoProcesses).Count -ne 0) { throw 'Vivado isolation check failed before continuation' }
if (Test-Path -LiteralPath $outputDirectory) { throw "Continuation output already exists: $outputDirectory" }
if (Test-Path -LiteralPath $runtimeDirectory) { throw "Continuation runtime already exists: $runtimeDirectory" }
if (Test-Path -LiteralPath (Join-Path $evidenceRoot 'G2B_G13A_CANDIDATE_RESULTS.csv')) {
    throw 'Candidate results already exist; continuation retry refused'
}

$dcpHash = Get-Sha256 $checkpoint
$sourceFullBaseHash = Get-Sha256 $sourceFullBase
$derivedFullBaseHash = Get-Sha256 $derivedFullBase
$bs3CandidateHash = Get-Sha256 $bs3Candidate
$g13CandidateHash = Get-Sha256 $g13Candidate
$workerHash = Get-Sha256 $worker
$runnerHash = Get-Sha256 $PSCommandPath
if ($dcpHash -cne $expectedDcpHash) { throw "DCP hash mismatch: $dcpHash" }
if ($sourceFullBaseHash -cne $expectedSourceFullBaseHash) { throw "Source full-base hash mismatch: $sourceFullBaseHash" }
if ($derivedFullBaseHash -cne $expectedDerivedFullBaseHash) { throw "Derived full-base hash mismatch: $derivedFullBaseHash" }
if ($bs3CandidateHash -cne $expectedBs3CandidateHash) { throw "BS3 candidate hash mismatch: $bs3CandidateHash" }
if ($g13CandidateHash -cne $expectedG13CandidateHash) { throw "G13-A candidate hash mismatch: $g13CandidateHash" }
if ($workerHash -cne $expectedWorkerHash) { throw "Continuation worker hash mismatch: $workerHash" }

$sourceText = [IO.File]::ReadAllText($sourceFullBase)
$derivedText = [IO.File]::ReadAllText($derivedFullBase)
$bs3Text = [IO.File]::ReadAllText($bs3Candidate)
$g13Text = [IO.File]::ReadAllText($g13Candidate)
if ((Get-CommandCount $sourceText 'set_bus_skew') -ne 16 -or (Get-CommandCount $sourceText 'set_max_delay') -ne 9) {
    throw 'Source base counts differ from 16 bus-skew / 9 max-delay'
}
if ((Get-CommandCount $derivedText 'set_bus_skew') -ne 15 -or (Get-CommandCount $derivedText 'set_max_delay') -ne 9) {
    throw 'Derived base counts differ from 15 bus-skew / 9 max-delay'
}
if ([regex]::Matches($derivedText, '(?m)^\s*set_bus_skew\b[^\r\n]*(reset_abandoned_hold_source|reset_commit_phase_hold_source)').Count -ne 0) {
    throw 'Derived base still contains Group-13 bus skew'
}
if ((Get-CommandCount $bs3Text 'set_bus_skew') -ne 0 -or (Get-CommandCount $bs3Text 'set_max_delay') -ne 3) {
    throw 'BS3 candidate counts differ from 0/3'
}
if ((Get-CommandCount $g13Text 'set_bus_skew') -ne 0 -or (Get-CommandCount $g13Text 'set_max_delay') -ne 2) {
    throw 'G13-A candidate counts differ from 0/2'
}
if ([regex]::Matches($g13Text, '(?m)^\s*set_max_delay\b[^\r\n]+-to \$g2b_g13a_(abandoned|all)_dst_cells\s+6\.000\s*$').Count -ne 2) {
    throw 'G13-A candidate is not the exact two cell-target 6 ns commands'
}
$sourceLines = @(Get-Content -LiteralPath $sourceFullBase)
$derivedLines = @(Get-Content -LiteralPath $derivedFullBase)
$lineDiff = @(Compare-Object -ReferenceObject $sourceLines -DifferenceObject $derivedLines)
$expectedRemoved = 'set_bus_skew -from [filter [get_cells -quiet -hier -regexp .*G2B_ONECH_C2H/(reset_abandoned_hold_source|reset_commit_phase_hold_source)_reg.*] {IS_SEQUENTIAL == 1}] -to $_xlnx_shared_i10 3.000'
if ($lineDiff.Count -ne 1 -or $lineDiff[0].SideIndicator -cne '<=' -or $lineDiff[0].InputObject -cne $expectedRemoved) {
    throw 'Derived base exact one-line removal proof failed'
}
$attempt1 = Read-KeyValueFile $attempt1Disposition
if ($attempt1['DISPOSITION'] -cne 'HARNESS_OBJECT_TYPING_ERROR_BEFORE_CANDIDATE_QUERY' -or
    $attempt1['CANDIDATE_QUERY_STARTED'] -cne 'NO' -or $attempt1['PRIMARY_REPORT_TIMING'] -cne 'PASS' -or
    $attempt1['PRIMARY_GET_TIMING_PATHS'] -cne 'PASS') {
    throw 'Attempt-1 disposition is not the approved continuation state'
}

New-Item -ItemType Directory -Path $outputDirectory | Out-Null
New-Item -ItemType Directory -Path $runtimeDirectory | Out-Null
$preflightLines = @(
    'STATE=PASS'
    'MODE=CANDIDATE_ONLY_CONTINUATION'
    "SEALED_DCP_SHA256=$dcpHash"
    "SOURCE_FULL_BASE_SHA256=$sourceFullBaseHash"
    "DERIVED_FULL_BASE_SHA256=$derivedFullBaseHash"
    'DERIVED_FULL_BASE_BUS_SKEW_COUNT=15'
    'DERIVED_FULL_BASE_MAX_DELAY_COUNT=9'
    'DERIVED_FULL_BASE_GROUP13_BUS_SKEW_COUNT=0'
    "BS3_CANDIDATE_SHA256=$bs3CandidateHash"
    'BS3_CANDIDATE_MAX_DELAY_COUNT=3'
    "G13A_CANDIDATE_SHA256=$g13CandidateHash"
    'G13A_CANDIDATE_MAX_DELAY_COUNT=2'
    "CONTINUATION_WORKER_SHA256=$workerHash"
    "CONTINUATION_RUNNER_SHA256=$runnerHash"
    'ATTEMPT1_DISPOSITION=HARNESS_OBJECT_TYPING_ERROR_BEFORE_CANDIDATE_QUERY'
    'PRIMARY_A_B_REPEATED=NO'
    'FULL_GROUP13_BUS_SKEW_RETRIED=NO'
)
Write-Utf8NoBom (Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_PREFLIGHT.txt') (($preflightLines -join "`n") + "`n")

$consoleOut = Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_CONSOLE.stdout.log'
$consoleErr = Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_CONSOLE.stderr.log'
$vivadoLog = Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_VIVADO.log'
$activeMarker = Join-Path $outputDirectory 'ACTIVE_QUERY.marker'
$watchdogPath = Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_EXTERNAL_WATCHDOG.txt'
$arguments = @('-mode','batch','-log',$vivadoLog,'-nojournal','-source',$worker,'-tclargs',
    $checkpoint,$derivedFullBase,$bs3Candidate,$g13Candidate,$referenceObjects,$outputDirectory,
    $evidenceRoot,$expectedDcpHash,$expectedDerivedFullBaseHash)
$quotedArguments = $arguments | ForEach-Object { '"{0}"' -f ([string]$_).Replace('"','""') }
Write-Utf8NoBom (Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_LAUNCH_COMMAND.txt') `
    (('"{0}" {1}' -f $vivado,($quotedArguments -join ' ')) + "`n")
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
        -RedirectStandardOutput $consoleOut -RedirectStandardError $consoleErr -Environment $childEnvironment `
        -PassThru -WindowStyle Hidden
    while ($true) {
        $process.Refresh()
        if ($process.HasExited) { break }
        if (Test-Path -LiteralPath $activeMarker -PathType Leaf) {
            $marker = Read-KeyValueFile $activeMarker
            if ($marker.ContainsKey('QUERY_ID') -and $marker.ContainsKey('EPOCH_MILLISECONDS') -and
                $marker.ContainsKey('TIMEOUT_SECONDS') -and $marker.ContainsKey('COMMAND')) {
                $epoch = [Int64]::Parse($marker['EPOCH_MILLISECONDS'], $invariant)
                if ($null -eq $activeEpoch -or $epoch -ne $activeEpoch) {
                    if ($marker['TIMEOUT_SECONDS'] -cne ([string]$queryTimeoutSeconds)) { throw 'Query marker timeout mismatch' }
                    $activeEpoch = $epoch
                    $activeQueryId = $marker['QUERY_ID']
                    $queryStart = [DateTimeOffset]::FromUnixTimeMilliseconds($epoch)
                    $queryDeadline = $queryStart.AddSeconds($queryTimeoutSeconds)
                    $timeline.Add("QUERY_STARTED|$activeQueryId|$($queryStart.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))|$($marker['COMMAND'])")
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
        if ($null -ne $queryDeadline -and $now -ge $queryDeadline) {
            $timeoutPhase = "QUERY:$activeQueryId"
            break
        }
        if ($null -eq $queryDeadline -and $now -ge $phaseDeadline) {
            $timeoutPhase = 'INITIALIZATION_OR_INTERQUERY'
            break
        }
        Start-Sleep -Milliseconds 200
    }
    if ($timeoutPhase -ne 'NONE') {
        $killOutput = Stop-ProcessTree $process.Id
        [void]$process.WaitForExit(60000)
    }
} catch {
    $supervisorError = 'SUPERVISOR_EXCEPTION:' + $_.Exception.Message.Replace("`r",' ').Replace("`n",' ')
    if ($null -ne $process) {
        $process.Refresh()
        if (-not $process.HasExited) {
            $killOutput = Stop-ProcessTree $process.Id
            [void]$process.WaitForExit(60000)
        }
    }
} finally { $stopwatch.Stop() }

$end = [DateTimeOffset]::UtcNow
if ($null -ne $process) { $process.Refresh() }
$exitCode = if ($null -ne $process -and $process.HasExited) { $process.ExitCode } else { -999 }
$postVivadoCount = @(Get-VivadoProcesses).Count
$elapsed = $stopwatch.Elapsed.TotalSeconds
$elapsedText = $elapsed.ToString('F3',$invariant)
$combinedProcessRuntime = ($attempt1ElapsedSeconds + $elapsed).ToString('F3',$invariant)
$correctedEndToEnd = ($end - $attempt1StartUtc).TotalSeconds.ToString('F3',$invariant)
$watchdogLines = @(
    "START_UTC=$($start.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"
    "END_UTC=$($end.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"
    "CONTINUATION_ELAPSED_SECONDS=$elapsedText"
    "ATTEMPT1_ELAPSED_SECONDS=$($attempt1ElapsedSeconds.ToString('F3',$invariant))"
    "COMBINED_PROCESS_RUNTIME_SECONDS=$combinedProcessRuntime"
    "CORRECTED_END_TO_END_SECONDS=$correctedEndToEnd"
    "TIMED_OUT=$(($timeoutPhase -ne 'NONE').ToString().ToUpperInvariant())"
    "TIMEOUT_PHASE=$timeoutPhase"
    "PROCESS_EXIT_CODE=$exitCode"
    "SUPERVISOR_ERROR=$supervisorError"
    "POSTEXISTING_VIVADO_COUNT=$postVivadoCount"
    "TASKKILL_OUTPUT=$killOutput"
    'PRIMARY_A_B_REPEATED=NO'
    'FULL_GROUP13_BUS_SKEW_RETRIED=NO'
)
Write-Utf8NoBom $watchdogPath (($watchdogLines -join "`n") + "`n")
Write-Utf8NoBom (Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_QUERY_TIMELINE.log') (($timeline -join "`n") + "`n")
if ($timeoutPhase -ne 'NONE') { throw "Continuation timeout: $timeoutPhase" }
if ($supervisorError -ne 'NONE') { throw $supervisorError }
if ($exitCode -ne 0) { throw "Continuation Vivado exit code: $exitCode" }
if ($postVivadoCount -ne 0) { throw "Vivado remains after continuation: $postVivadoCount" }

$required = @('WORKER_COMPLETED.marker','G2B_G13A_CONTINUATION_ROUTE_STATUS.rpt',
    'G2B_G13A_CONTINUATION_ROUTE_SIGNATURE.txt','G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc',
    'G2B_G13A_AGGREGATE_MEMBERSHIP_SUMMARY.txt','G2B_G13A_SUPPLEMENTAL_AGGREGATE_INVENTORY.csv',
    'G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv','G2B_G13A_SUPPLEMENTAL_AGGREGATE_PATH_PROPERTIES.txt',
    'G2B_G13A_CANDIDATE_RESET_ABANDONED_HOLD_PATH_PROPERTIES.txt',
    'G2B_G13A_CANDIDATE_RESET_COMMIT_PHASE_HOLD_PATH_PROPERTIES.txt',
    'G2B_G13A_FOCUSED_TIMING_METHODOLOGY.rpt','G2B_G13A_FOCUSED_METHODOLOGY_SUMMARY.txt')
foreach ($name in $required) {
    if (-not (Test-Path -LiteralPath (Join-Path $outputDirectory $name) -PathType Leaf)) { throw "Missing continuation output: $name" }
}
$routeText = [IO.File]::ReadAllText((Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_ROUTE_STATUS.rpt'))
if ($routeText -notmatch '# of fully routed nets.*:\s+33985\s+:' -or $routeText -notmatch '# of nets with routing errors.*:\s+0\s+:') {
    throw 'Continuation routed-checkpoint signature failed'
}
$membership = Read-KeyValueFile (Join-Path $outputDirectory 'G2B_G13A_AGGREGATE_MEMBERSHIP_SUMMARY.txt')
if ($membership['STATUS'] -cne 'PASS' -or
    $membership['AGGREGATE_SOURCE_LITERAL_COUNT'] -cne $membership['AGGREGATE_SOURCE_RESOLVED_COUNT'] -or
    $membership['AGGREGATE_DESTINATION_LITERAL_COUNT'] -cne $membership['AGGREGATE_DESTINATION_RESOLVED_COUNT'] -or
    $membership['GROUP13_SOURCE_MEMBER_COUNT'] -cne '7' -or $membership['GROUP13_DESTINATION_MEMBER_COUNT'] -cne '207') {
    throw 'Aggregate membership continuation proof failed'
}
$appliedPath = Join-Path $outputDirectory 'G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc'
$appliedText = [IO.File]::ReadAllText($appliedPath)
if ((Get-CommandCount $appliedText 'set_bus_skew') -ne 15 -or (Get-CommandCount $appliedText 'set_max_delay') -ne 14 -or
    [regex]::Matches($appliedText, '(?m)^\s*set_bus_skew\b[^\r\n]*(reset_abandoned_hold_source|reset_commit_phase_hold_source)').Count -ne 0) {
    throw 'Applied continuation constraint context differs from 15 bus-skew / 14 max-delay / zero Group13 skew'
}
$candidateResultsPath = Join-Path $evidenceRoot 'G2B_G13A_CANDIDATE_RESULTS.csv'
$candidateRows = @(Import-Csv -LiteralPath $candidateResultsPath)
if ($candidateRows.Count -ne 2) { throw 'Candidate results row count is not 2' }
foreach ($row in $candidateRows) {
    if ($row.Result -cne 'PASS' -or $row.Target_Scope -cne 'CELLS_ALL_TIMING_ENDPOINT_PINS') { throw "Candidate row invalid: $($row.Family)" }
    if ([double]::Parse($row.Required_ns,$invariant) -ne 6.0 -or [double]::Parse($row.Worst_Actual_ns,$invariant) -gt 6.0005 -or
        [double]::Parse($row.Slack_ns,$invariant) -lt -0.0005) { throw "Candidate numeric failure: $($row.Family)" }
}
$supplementalPath = Join-Path $outputDirectory 'G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv'
$supplemental = @(Import-Csv -LiteralPath $supplementalPath)
if ($supplemental.Count -ne 1 -or $supplemental[0].Result -cne 'PASS' -or
    $supplemental[0].Coverage_Record -cne 'SUPPLEMENTAL_AGGREGATE_COVERAGE') { throw 'Supplemental aggregate row invalid' }

$warningLines = @()
foreach ($path in @($consoleOut,$consoleErr,$vivadoLog)) {
    $warningLines += @(Select-String -LiteralPath $path -Pattern '^(WARNING:|CRITICAL WARNING:)' | ForEach-Object { $_.Line })
}
$warningLines = @($warningLines | Sort-Object -Unique)
Write-Utf8NoBom (Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_WARNINGS.txt') $(if ($warningLines.Count -eq 0) { "NONE`n" } else { ($warningLines -join "`n") + "`n" })

$receiptLines = @(
    'STATE=PASS'
    'MODE=CANDIDATE_ONLY_CONTINUATION'
    'ATTEMPT1_DISPOSITION=HARNESS_OBJECT_TYPING_ERROR_BEFORE_CANDIDATE_QUERY'
    "ATTEMPT1_ELAPSED_SECONDS=$($attempt1ElapsedSeconds.ToString('F3',$invariant))"
    "CONTINUATION_ELAPSED_SECONDS=$elapsedText"
    "COMBINED_PROCESS_RUNTIME_SECONDS=$combinedProcessRuntime"
    "CORRECTED_END_TO_END_SECONDS=$correctedEndToEnd"
    "SEALED_DCP_SHA256=$dcpHash"
    "DERIVED_FULL_BASE_SHA256=$derivedFullBaseHash"
    "BS3_CANDIDATE_SHA256=$bs3CandidateHash"
    "G13A_CANDIDATE_SHA256=$g13CandidateHash"
    "CONTINUATION_WORKER_SHA256=$workerHash"
    "CONTINUATION_RUNNER_SHA256=$runnerHash"
    "APPLIED_CONTEXT_SHA256=$(Get-Sha256 $appliedPath)"
    "CANDIDATE_RESULTS_SHA256=$(Get-Sha256 $candidateResultsPath)"
    "SUPPLEMENTAL_RESULTS_SHA256=$(Get-Sha256 $supplementalPath)"
    "WARNING_COUNT=$($warningLines.Count)"
    'PRIMARY_A_B_REPEATED=NO'
    'FULL_GROUP13_BUS_SKEW_RETRIED=NO'
    'BITSTREAM_PRODUCED=NO'
    'HARDWARE_ACCESSED=NO'
)
Write-Utf8NoBom (Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_EXECUTION_RECEIPT.txt') (($receiptLines -join "`n") + "`n")
Write-Output "G2B_G13A_CONTINUATION_PASS elapsed=${elapsedText}s combined=${combinedProcessRuntime}s"
