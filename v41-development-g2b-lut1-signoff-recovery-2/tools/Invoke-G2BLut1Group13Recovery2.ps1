[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$invariant = [Globalization.CultureInfo]::InvariantCulture

$evidenceRepository = 'C:\FPGA\V41_G2B_EVIDENCE'
$recoveryRoot = Join-Path $evidenceRepository 'v41-development-g2b-lut1-signoff-recovery-2'
$outputDirectory = Join-Path $recoveryRoot 'raw\group13_fresh'
$runtimeDirectory = 'C:\FPGA\G2B_LUT1_RECOVERY2_GROUP13_RUNTIME'
$resultsPath = Join-Path $recoveryRoot 'G2B_LUT1_GROUP13_SIGNOFF_RESULTS.csv'
$gatePath = Join-Path $recoveryRoot 'G2B_LUT1_GROUP13_GATE.txt'

$sourceRepository = 'C:\FPGA\V41_G2B'
$activeXdc = Join-Path $sourceRepository 'xdc\common\g2b_cdc.xdc'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$g13aRoot = Join-Path $evidenceRepository 'v41-development-g2b-g13a-reset-return-signoff-audit'
$worker = Join-Path $g13aRoot 'tools\G2B_G13A_CANDIDATE_CONTINUATION_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$derivedFullBase = Join-Path $g13aRoot 'raw\timing\G2B_G13A_FULL_BASE_WITHOUT_GROUP9_AND_GROUP13.xdc'
$bs3Candidate = Join-Path $evidenceRepository 'v41-development-g2b-bs3-ownership-mailbox-settling-proof\G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc'
$g13Candidate = Join-Path $g13aRoot 'G2B_G13A_CANDIDATE_CONSTRAINTS.xdc'
$referenceObjects = Join-Path $evidenceRepository 'v41-development-g2b-lut1-signoff-recovery\raw\groups10_17\group_13_RESET_RETURN_SOURCE_TO_AXI\13_RESET_RETURN_SOURCE_TO_AXI_OBJECTS.txt'

$expectedSourceBranch = 'integration/v41-g2b-onech-c2h'
$expectedSourceCommit = '64feb60de5d07f400e6b92527bfe54838b3372ee'
$expectedSourceTree = '26399ed456941e26d5ee4b1b2ca50392338fa24a'
$expectedActiveXdcHash = 'C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C'
$expectedDcpHash = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$expectedDerivedFullBaseHash = '3F7D8613AB3ECF579F3F1E7A09B1608602768D2B9C880CE3B755437081DF1F87'
$expectedBs3CandidateHash = 'AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087'
$expectedG13CandidateHash = 'E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312'
$expectedReferenceObjectsHash = '7B2AF4B8422B58B208590FD3AB9A675819FF7DD56DFAB44789984DA2BBB6C380'
$expectedWorkerHash = 'CBDFF958DCB1D4168EBA08C3FC5089836C17419D8765FD06EDBBB43389ED50D9'
$expectedG13aEvidenceCommit = '10c7c2898d162af8e2262b3f99861c7d560c4557'
$expectedG13aDirectoryTree = 'd4694977a5bfecfec8005d9cc0dd1c1c44f36f7f'
$queryTimeoutSeconds = 300
$initializationInterqueryTimeoutSeconds = 1800

$structuralProofs = @(
    [pscustomobject]@{
        Name = 'G2B_G13A_SEMANTIC_MODEL.md'
        Hash = 'A9FD1BF43691F503011471DD5890509094F3CD9B8CDABFD2D050A1D43297CF63'
    }
    [pscustomobject]@{
        Name = 'G2B_G13A_SAFETY_INVARIANT.md'
        Hash = '85CD73384B50CACA94CCE50D2997225A16EB201D908E3FB20E63253673D39737'
    }
    [pscustomobject]@{
        Name = 'G2B_G13A_RESET_SEMANTIC_PROOF.md'
        Hash = 'D866AC1C5F2E7FD8B3AB3957710A564F8C2FF0C024A3D15211AB74DF035037AE'
    }
    [pscustomobject]@{
        Name = 'G2B_G13A_CDC_CORRELATION.md'
        Hash = 'FAD5DE7F9BDEC9B86FB7AD51BB1457FB7D0941B5810E9879985AEFF011FE98AE'
    }
    [pscustomobject]@{
        Name = 'G2B_G13A_FAMILIES.csv'
        Hash = '2B59FC228C72046C9BF4E925015A992E244C26FC08A4E12DF43438364462EBD3'
    }
)

function Write-NewUtf8NoBom {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text
    )
    $bytes = [Text.UTF8Encoding]::new($false).GetBytes($Text)
    $stream = [IO.FileStream]::new(
        $Path,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::Write,
        [IO.FileShare]::None
    )
    try {
        $stream.Write($bytes, 0, $bytes.Length)
        $stream.Flush($true)
    } finally {
        $stream.Dispose()
    }
}

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Get-CommandCount {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Command
    )
    [regex]::Matches($Text, "(?m)^\s*$([regex]::Escape($Command))\b").Count
}

function Read-KeyValueFile {
    param([Parameter(Mandatory)][string]$Path)
    $result = @{}
    foreach ($line in Get-Content -LiteralPath $Path) {
        if ($line -match '^([^=]+)=(.*)$') {
            $result[$matches[1]] = $matches[2]
        }
    }
    $result
}

function Invoke-GitText {
    param(
        [Parameter(Mandatory)][string]$Repository,
        [Parameter(Mandatory)][string[]]$Arguments
    )
    $commandOutput = @(& git.exe --no-optional-locks -C $Repository @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git failed in $Repository ($($Arguments -join ' ')): $($commandOutput -join ' ')"
    }
    ($commandOutput -join "`n").Trim()
}

function Get-VivadoProcesses {
    @(Get-Process -Name 'vivado','vivado_lab' -ErrorAction SilentlyContinue)
}

function Stop-ProcessTree {
    param([Parameter(Mandatory)][int]$ProcessId)
    (& "$env:SystemRoot\System32\taskkill.exe" /PID $ProcessId /T /F 2>&1 | Out-String).Trim()
}

function Convert-ToInvariantDouble {
    param(
        [Parameter(Mandatory)][string]$Value,
        [Parameter(Mandatory)][string]$Label
    )
    $parsed = 0.0
    if (-not [double]::TryParse(
        $Value,
        [Globalization.NumberStyles]::Float,
        $invariant,
        [ref]$parsed
    )) {
        throw "$Label is not an invariant floating-point value: $Value"
    }
    $parsed
}

function Assert-Hash {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][string]$Expected,
        [Parameter(Mandatory)][string]$Label
    )
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label is absent: $Path"
    }
    $actual = Get-Sha256 $Path
    if ($actual -cne $Expected) {
        throw "$Label hash mismatch: expected=$Expected actual=$actual"
    }
    $actual
}

function Assert-QueryCompletion {
    param(
        [Parameter(Mandatory)][string]$QueryId,
        [Parameter(Mandatory)][string]$Directory
    )
    $markerPath = Join-Path $Directory "QUERY_COMPLETED_${QueryId}.marker"
    if (-not (Test-Path -LiteralPath $markerPath -PathType Leaf)) {
        throw "Required completed-query marker is absent: $QueryId"
    }
    $marker = Read-KeyValueFile $markerPath
    if ($marker['QUERY_ID'] -cne $QueryId -or $marker['STATUS'] -cne 'PASS') {
        throw "Completed-query marker is invalid: $QueryId"
    }
    $runtime = Convert-ToInvariantDouble $marker['QUERY_RUNTIME_SECONDS'] "$QueryId runtime"
    if ($runtime -lt 0.0 -or $runtime -gt ($queryTimeoutSeconds + 0.001)) {
        throw "$QueryId exceeded the 300-second query limit: $runtime"
    }
    $runtime
}

if (Test-Path -LiteralPath $outputDirectory) {
    throw "One-shot Group-13 output already exists; overwrite/retry refused: $outputDirectory"
}
if (Test-Path -LiteralPath $resultsPath) {
    throw "One-shot Group-13 results already exist; overwrite/retry refused: $resultsPath"
}
if (Test-Path -LiteralPath $gatePath) {
    throw "One-shot Group-13 gate already exists; overwrite/retry refused: $gatePath"
}
if (Test-Path -LiteralPath $runtimeDirectory) {
    throw "One-shot Group-13 runtime already exists; overwrite/retry refused: $runtimeDirectory"
}

$gateWritten = $false
$process = $null
$timeoutPhase = 'NONE'
$supervisorError = 'NONE'
$killOutput = 'NONE'
$postVivadoCount = -1
$elapsedText = 'N/A'

try {
    foreach ($requiredPath in @(
        $vivado,
        $worker,
        $checkpoint,
        $derivedFullBase,
        $bs3Candidate,
        $g13Candidate,
        $referenceObjects,
        $activeXdc
    )) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            throw "Required Group-13 recovery input is absent: $requiredPath"
        }
    }

    if (@(Get-VivadoProcesses).Count -ne 0) {
        throw 'Vivado isolation check failed before Group-13 recovery'
    }

    $sourceBranch = Invoke-GitText $sourceRepository @('branch','--show-current')
    $sourceCommit = Invoke-GitText $sourceRepository @('rev-parse','HEAD')
    $sourceTree = Invoke-GitText $sourceRepository @('rev-parse','HEAD^{tree}')
    $sourceStatus = Invoke-GitText $sourceRepository @('status','--porcelain','--untracked-files=all')
    if ($sourceBranch -cne $expectedSourceBranch) {
        throw "Source branch mismatch: $sourceBranch"
    }
    if ($sourceCommit -cne $expectedSourceCommit) {
        throw "Source commit mismatch: $sourceCommit"
    }
    if ($sourceTree -cne $expectedSourceTree) {
        throw "Source tree mismatch: $sourceTree"
    }
    if ($sourceStatus -cne '') {
        throw "Source worktree is not clean: $sourceStatus"
    }

    $activeXdcHash = Assert-Hash $activeXdc $expectedActiveXdcHash 'active Group-13 XDC'
    $dcpHash = Assert-Hash $checkpoint $expectedDcpHash 'routed DCP'
    $derivedFullBaseHash = Assert-Hash $derivedFullBase $expectedDerivedFullBaseHash 'derived full base'
    $bs3CandidateHash = Assert-Hash $bs3Candidate $expectedBs3CandidateHash 'BS3 candidate'
    $g13CandidateHash = Assert-Hash $g13Candidate $expectedG13CandidateHash 'G13-A candidate'
    $referenceObjectsHash = Assert-Hash $referenceObjects $expectedReferenceObjectsHash 'Group-13 reference object list'
    $workerHash = Assert-Hash $worker $expectedWorkerHash 'G13-A continuation worker'
    $runnerHash = Get-Sha256 $PSCommandPath

    $g13aTreeSpec = "${expectedG13aEvidenceCommit}:v41-development-g2b-g13a-reset-return-signoff-audit"
    $g13aDirectoryTree = Invoke-GitText $evidenceRepository @('rev-parse',$g13aTreeSpec)
    if ($g13aDirectoryTree -cne $expectedG13aDirectoryTree) {
        throw "G13-A evidence directory tree mismatch: $g13aDirectoryTree"
    }

    $proofBindingLines = [Collections.Generic.List[string]]::new()
    foreach ($proof in $structuralProofs) {
        $proofPath = Join-Path $g13aRoot $proof.Name
        $proofHash = Assert-Hash $proofPath $proof.Hash "G13-A structural proof $($proof.Name)"
        $proofBindingLines.Add("STRUCTURAL_PROOF_$($proof.Name)=$proofHash")
    }

    $workerText = [IO.File]::ReadAllText($worker)
    $derivedText = [IO.File]::ReadAllText($derivedFullBase)
    $bs3Text = [IO.File]::ReadAllText($bs3Candidate)
    $g13Text = [IO.File]::ReadAllText($g13Candidate)
    $activeXdcText = [IO.File]::ReadAllText($activeXdc)
    $referenceText = [IO.File]::ReadAllText($referenceObjects)

    if ((Get-CommandCount $workerText 'report_bus_skew') -ne 0) {
        throw 'Exact continuation worker contains a report_bus_skew command'
    }
    if ((Get-CommandCount $derivedText 'set_bus_skew') -ne 15 -or
        (Get-CommandCount $derivedText 'set_max_delay') -ne 9) {
        throw 'Derived base differs from 15 bus-skew / 9 max-delay commands'
    }
    if ([regex]::Matches(
        $derivedText,
        '(?m)^\s*set_bus_skew\b[^\r\n]*(reset_abandoned_hold_source|reset_commit_phase_hold_source)'
    ).Count -ne 0) {
        throw 'Derived base still contains the retired Group-13 global bus skew'
    }
    if ((Get-CommandCount $bs3Text 'set_bus_skew') -ne 0 -or
        (Get-CommandCount $bs3Text 'set_max_delay') -ne 3) {
        throw 'BS3 candidate differs from 0 bus-skew / 3 max-delay commands'
    }
    if ((Get-CommandCount $g13Text 'set_bus_skew') -ne 0 -or
        (Get-CommandCount $g13Text 'set_max_delay') -ne 2) {
        throw 'G13-A candidate differs from 0 bus-skew / 2 max-delay commands'
    }
    if ([regex]::Matches(
        $g13Text,
        '(?m)^\s*set_max_delay\b[^\r\n]+-to \$g2b_g13a_(abandoned|all)_dst_cells\s+6\.000\s*$'
    ).Count -ne 2) {
        throw 'G13-A candidate does not contain exactly two cell-target 6.000 ns constraints'
    }

    $candidateOffset = $activeXdcText.IndexOf($g13Text, [StringComparison]::Ordinal)
    if ($candidateOffset -lt 0 -or
        $activeXdcText.LastIndexOf($g13Text, [StringComparison]::Ordinal) -ne $candidateOffset) {
        throw 'Active XDC does not contain exactly one byte-exact G13-A candidate stanza'
    }
    $retiredGroup13Command = 'set_bus_skew 3.000 -from $g2b_reset_return_src -to $g2b_reset_return_dst'
    if ($activeXdcText.Contains($retiredGroup13Command, [StringComparison]::Ordinal) -or
        $activeXdcText -match '(?m)^\s*set\s+g2b_reset_return_(src|dst)\b') {
        throw 'Active XDC still contains the retired Group-13 global bus-skew relation'
    }
    if ((Get-CommandCount $activeXdcText 'set_bus_skew') -ne 12 -or
        (Get-CommandCount $activeXdcText 'set_max_delay') -ne 11) {
        throw 'Active G2B XDC command counts differ from governed recovery-2 content'
    }

    $referenceSourceCount = [regex]::Matches($referenceText, '(?m)^SOURCE=').Count
    $referenceDestinationCount = [regex]::Matches($referenceText, '(?m)^DESTINATION=').Count
    if ($referenceSourceCount -ne 7 -or $referenceDestinationCount -ne 207) {
        throw "Group-13 reference object counts differ from 7/207: $referenceSourceCount/$referenceDestinationCount"
    }

    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
    New-Item -ItemType Directory -Path $runtimeDirectory | Out-Null

    $preflightLines = [Collections.Generic.List[string]]::new()
    foreach ($line in @(
        'STATE=PASS',
        'MODE=G2B_LUT1_GROUP13_RECOVERY2_FRESH',
        'ATTEMPT_NUMBER=1',
        'OUTPUT_OVERWRITE=NO',
        "SOURCE_BRANCH=$sourceBranch",
        "SOURCE_COMMIT=$sourceCommit",
        "SOURCE_TREE=$sourceTree",
        "ACTIVE_XDC_SHA256=$activeXdcHash",
        "ROUTED_DCP_SHA256=$dcpHash",
        "DERIVED_FULL_BASE_SHA256=$derivedFullBaseHash",
        "BS3_CANDIDATE_SHA256=$bs3CandidateHash",
        "G13A_CANDIDATE_SHA256=$g13CandidateHash",
        "REFERENCE_OBJECTS_SHA256=$referenceObjectsHash",
        "G13A_WORKER_SHA256=$workerHash",
        "RECOVERY2_RUNNER_SHA256=$runnerHash",
        "G13A_EVIDENCE_COMMIT=$expectedG13aEvidenceCommit",
        "G13A_EVIDENCE_DIRECTORY_TREE=$g13aDirectoryTree",
        'STRUCTURAL_CDC_PROOF_BINDING=PASS',
        'SEMANTIC_FAMILY_COUNT=2',
        'SUPPLEMENTAL_AGGREGATE_IS_THIRD_FAMILY=NO',
        "QUERY_TIMEOUT_SECONDS=$queryTimeoutSeconds",
        "INITIALIZATION_INTERQUERY_TIMEOUT_SECONDS=$initializationInterqueryTimeoutSeconds",
        'GLOBAL_GROUP13_REPORT_BUS_SKEW_COMMAND_COUNT=0',
        'GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO',
        'HARDWARE_ACCESSED=NO'
    )) {
        $preflightLines.Add($line)
    }
    foreach ($line in $proofBindingLines) { $preflightLines.Add($line) }
    Write-NewUtf8NoBom (Join-Path $outputDirectory 'G2B_LUT1_GROUP13_RECOVERY2_PREFLIGHT.txt') `
        (($preflightLines -join "`n") + "`n")

    $consoleOut = Join-Path $outputDirectory 'G2B_LUT1_GROUP13_RECOVERY2_CONSOLE.stdout.log'
    $consoleErr = Join-Path $outputDirectory 'G2B_LUT1_GROUP13_RECOVERY2_CONSOLE.stderr.log'
    $vivadoLog = Join-Path $outputDirectory 'G2B_LUT1_GROUP13_RECOVERY2_VIVADO.log'
    $activeMarker = Join-Path $outputDirectory 'ACTIVE_QUERY.marker'
    $watchdogPath = Join-Path $outputDirectory 'G2B_LUT1_GROUP13_RECOVERY2_EXTERNAL_WATCHDOG.txt'
    $timelinePath = Join-Path $outputDirectory 'G2B_LUT1_GROUP13_RECOVERY2_QUERY_TIMELINE.log'
    $arguments = @(
        '-mode','batch',
        '-log',$vivadoLog,
        '-nojournal',
        '-source',$worker,
        '-tclargs',
        $checkpoint,
        $derivedFullBase,
        $bs3Candidate,
        $g13Candidate,
        $referenceObjects,
        $outputDirectory,
        $outputDirectory,
        $expectedDcpHash,
        $expectedDerivedFullBaseHash
    )
    $quotedArguments = $arguments | ForEach-Object {
        '"{0}"' -f ([string]$_).Replace('"','""')
    }
    Write-NewUtf8NoBom (Join-Path $outputDirectory 'G2B_LUT1_GROUP13_RECOVERY2_LAUNCH_COMMAND.txt') `
        (('"{0}" {1}' -f $vivado,($quotedArguments -join ' ')) + "`n")

    $childEnvironment = @{
        TEMP = $runtimeDirectory
        TMP = $runtimeDirectory
        XILINX_LOCAL_USER_DATA = 'NO'
        XILINX_TCLAPP_REPO = 'C:\AMDDesignTools\2025.2\Vivado\data\XilinxTclStore'
    }
    $start = [DateTimeOffset]::UtcNow
    $phaseDeadline = $start.AddSeconds($initializationInterqueryTimeoutSeconds)
    $queryDeadline = $null
    $activeEpoch = $null
    $activeQueryId = 'NONE'
    $timeline = [Collections.Generic.List[string]]::new()
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()

    try {
        $process = Start-Process -FilePath $vivado -ArgumentList $arguments `
            -WorkingDirectory $runtimeDirectory `
            -RedirectStandardOutput $consoleOut `
            -RedirectStandardError $consoleErr `
            -Environment $childEnvironment `
            -PassThru `
            -WindowStyle Hidden

        while ($true) {
            $process.Refresh()
            if ($process.HasExited) { break }

            if (Test-Path -LiteralPath $activeMarker -PathType Leaf) {
                $marker = Read-KeyValueFile $activeMarker
                if ($marker.ContainsKey('QUERY_ID') -and
                    $marker.ContainsKey('EPOCH_MILLISECONDS') -and
                    $marker.ContainsKey('TIMEOUT_SECONDS') -and
                    $marker.ContainsKey('COMMAND')) {
                    $epoch = [Int64]::Parse($marker['EPOCH_MILLISECONDS'], $invariant)
                    if ($null -eq $activeEpoch -or $epoch -ne $activeEpoch) {
                        if ($marker['TIMEOUT_SECONDS'] -cne ([string]$queryTimeoutSeconds)) {
                            throw 'ACTIVE_QUERY.marker timeout is not exactly 300 seconds'
                        }
                        $activeEpoch = $epoch
                        $activeQueryId = $marker['QUERY_ID']
                        $queryStart = [DateTimeOffset]::FromUnixTimeMilliseconds($epoch)
                        $queryDeadline = $queryStart.AddSeconds($queryTimeoutSeconds)
                        $timeline.Add(
                            "QUERY_STARTED|$activeQueryId|$($queryStart.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))|$($marker['COMMAND'])"
                        )
                    }
                }
            } elseif ($null -ne $activeEpoch) {
                $timeline.Add(
                    "QUERY_COMPLETED_OBSERVED|$activeQueryId|$([DateTimeOffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))"
                )
                $activeEpoch = $null
                $activeQueryId = 'NONE'
                $queryDeadline = $null
                $phaseDeadline = [DateTimeOffset]::UtcNow.AddSeconds($initializationInterqueryTimeoutSeconds)
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
    } finally {
        $stopwatch.Stop()
    }

    $end = [DateTimeOffset]::UtcNow
    if ($null -ne $process) { $process.Refresh() }
    $exitCode = if ($null -ne $process -and $process.HasExited) { $process.ExitCode } else { -999 }
    $postVivadoCount = @(Get-VivadoProcesses).Count
    $elapsedText = $stopwatch.Elapsed.TotalSeconds.ToString('F3',$invariant)
    $watchdogLines = @(
        "START_UTC=$($start.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))",
        "END_UTC=$($end.ToString('yyyy-MM-ddTHH:mm:ss.fffZ'))",
        "ELAPSED_SECONDS=$elapsedText",
        "QUERY_TIMEOUT_SECONDS=$queryTimeoutSeconds",
        "INITIALIZATION_INTERQUERY_TIMEOUT_SECONDS=$initializationInterqueryTimeoutSeconds",
        "TIMED_OUT=$(($timeoutPhase -ne 'NONE').ToString().ToUpperInvariant())",
        "TIMEOUT_PHASE=$timeoutPhase",
        "PROCESS_EXIT_CODE=$exitCode",
        "SUPERVISOR_ERROR=$supervisorError",
        "POSTEXISTING_VIVADO_COUNT=$postVivadoCount",
        "TASKKILL_OUTPUT=$killOutput",
        'ATTEMPT_NUMBER=1',
        'RETRY_EXECUTED=NO',
        'FULL_GROUP13_BUS_SKEW_RETRIED=NO',
        'GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO'
    )
    Write-NewUtf8NoBom $watchdogPath (($watchdogLines -join "`n") + "`n")
    Write-NewUtf8NoBom $timelinePath (($timeline -join "`n") + "`n")

    if ($timeoutPhase -ne 'NONE') { throw "Group-13 recovery timeout: $timeoutPhase" }
    if ($supervisorError -ne 'NONE') { throw $supervisorError }
    if ($exitCode -ne 0) { throw "Group-13 recovery Vivado exit code: $exitCode" }
    if ($postVivadoCount -ne 0) { throw "Vivado remains after Group-13 recovery: $postVivadoCount" }
    if (Test-Path -LiteralPath $activeMarker) { throw 'ACTIVE_QUERY.marker remains after worker completion' }

    $requiredOutputs = @(
        'WORKER_COMPLETED.marker',
        'G2B_G13A_CONTINUATION_ROUTE_STATUS.rpt',
        'G2B_G13A_CONTINUATION_ROUTE_SIGNATURE.txt',
        'G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc',
        'G2B_G13A_AGGREGATE_MEMBERSHIP_SUMMARY.txt',
        'G2B_G13A_SUPPLEMENTAL_AGGREGATE_INVENTORY.csv',
        'G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv',
        'G2B_G13A_SUPPLEMENTAL_AGGREGATE_PATH_PROPERTIES.txt',
        'G2B_G13A_CANDIDATE_RESET_ABANDONED_HOLD_PATH_PROPERTIES.txt',
        'G2B_G13A_CANDIDATE_RESET_COMMIT_PHASE_HOLD_PATH_PROPERTIES.txt',
        'G2B_G13A_FOCUSED_TIMING_METHODOLOGY.rpt',
        'G2B_G13A_FOCUSED_METHODOLOGY_SUMMARY.txt',
        'G2B_G13A_CANDIDATE_RESULTS.csv'
    )
    foreach ($name in $requiredOutputs) {
        if (-not (Test-Path -LiteralPath (Join-Path $outputDirectory $name) -PathType Leaf)) {
            throw "Required fresh Group-13 output is absent: $name"
        }
    }

    $workerCompletion = Read-KeyValueFile (Join-Path $outputDirectory 'WORKER_COMPLETED.marker')
    if ($workerCompletion['STATUS'] -cne 'PASS' -or
        $workerCompletion['MODE'] -cne 'CANDIDATE_ONLY_CONTINUATION' -or
        $workerCompletion['PRIMARY_A_B_REPEATED'] -cne 'NO' -or
        $workerCompletion['FULL_GROUP13_BUS_SKEW_RETRIED'] -cne 'NO' -or
        $workerCompletion['BITSTREAM_PRODUCED'] -cne 'NO' -or
        $workerCompletion['HARDWARE_ACCESSED'] -cne 'NO' -or
        $workerCompletion['DCP_EXPECTED_SHA256'] -cne $expectedDcpHash -or
        $workerCompletion['BASE_EXPECTED_SHA256'] -cne $expectedDerivedFullBaseHash) {
        throw 'Fresh G13-A worker completion marker is invalid'
    }

    $routeText = [IO.File]::ReadAllText(
        (Join-Path $outputDirectory 'G2B_G13A_CONTINUATION_ROUTE_STATUS.rpt')
    )
    if ($routeText -notmatch '# of fully routed nets.*:\s+33985\s+:' -or
        $routeText -notmatch '# of nets with routing errors.*:\s+0\s+:') {
        throw 'Fresh Group-13 routed-checkpoint signature failed'
    }

    $membership = Read-KeyValueFile (
        Join-Path $outputDirectory 'G2B_G13A_AGGREGATE_MEMBERSHIP_SUMMARY.txt'
    )
    if ($membership['STATUS'] -cne 'PASS' -or
        $membership['AGGREGATE_SOURCE_LITERAL_COUNT'] -cne '212' -or
        $membership['AGGREGATE_SOURCE_RESOLVED_COUNT'] -cne '212' -or
        $membership['AGGREGATE_DESTINATION_LITERAL_COUNT'] -cne '457' -or
        $membership['AGGREGATE_DESTINATION_RESOLVED_COUNT'] -cne '457' -or
        $membership['GROUP13_SOURCE_MEMBER_COUNT'] -cne '7' -or
        $membership['GROUP13_DESTINATION_MEMBER_COUNT'] -cne '207' -or
        $membership['TOTAL_SUPPLEMENTAL_COUNT'] -cne '79') {
        throw 'Fresh Group-13 aggregate membership/coverage proof failed'
    }

    $appliedPath = Join-Path $outputDirectory 'G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc'
    $appliedText = [IO.File]::ReadAllText($appliedPath)
    if ((Get-CommandCount $appliedText 'set_bus_skew') -ne 15 -or
        (Get-CommandCount $appliedText 'set_max_delay') -ne 14 -or
        [regex]::Matches(
            $appliedText,
            '(?m)^\s*set_bus_skew\b[^\r\n]*(reset_abandoned_hold_source|reset_commit_phase_hold_source)'
        ).Count -ne 0) {
        throw 'Applied candidate context differs from 15 bus-skew / 14 max-delay / zero Group-13 skew'
    }

    $queryRuntimes = @{}
    foreach ($queryId in @(
        'CANDIDATE_RESET_ABANDONED_HOLD',
        'CANDIDATE_RESET_COMMIT_PHASE_HOLD',
        'SUPPLEMENTAL_AGGREGATE_COVERAGE',
        'FOCUSED_METHODOLOGY'
    )) {
        $queryRuntimes[$queryId] = Assert-QueryCompletion $queryId $outputDirectory
    }

    $rawResultsPath = Join-Path $outputDirectory 'G2B_G13A_CANDIDATE_RESULTS.csv'
    $rawRows = @(Import-Csv -LiteralPath $rawResultsPath)
    if ($rawRows.Count -ne 2) {
        throw "Fresh Group-13 semantic-family row count is not exactly two: $($rawRows.Count)"
    }
    $familySpecifications = @(
        [pscustomobject]@{
            WorkerName = 'RESET_ABANDONED_HOLD'
            AcceptedName = 'RESET_ABANDONED_COUNT_STABLE_PAYLOAD'
            Sources = 3
            Destinations = 32
        }
        [pscustomobject]@{
            WorkerName = 'RESET_COMMIT_PHASE_HOLD'
            AcceptedName = 'RESET_COMMIT_PHASE_COMPLETION_BARRIER'
            Sources = 4
            Destinations = 207
        }
    )
    $publishedRows = [Collections.Generic.List[object]]::new()
    foreach ($specification in $familySpecifications) {
        $matches = @($rawRows | Where-Object { $_.Family -ceq $specification.WorkerName })
        if ($matches.Count -ne 1) {
            throw "Fresh result missing unique worker family: $($specification.WorkerName)"
        }
        $row = $matches[0]
        $required = Convert-ToInvariantDouble $row.Required_ns "$($specification.WorkerName) requirement"
        $actual = Convert-ToInvariantDouble $row.Worst_Actual_ns "$($specification.WorkerName) actual"
        $slack = Convert-ToInvariantDouble $row.Slack_ns "$($specification.WorkerName) slack"
        $runtime = Convert-ToInvariantDouble $row.Runtime_s "$($specification.WorkerName) runtime"
        if ($row.Result -cne 'PASS' -or
            $row.Target_Scope -cne 'CELLS_ALL_TIMING_ENDPOINT_PINS' -or
            [int]$row.Source_Count -ne $specification.Sources -or
            [int]$row.Destination_Cell_Count -ne $specification.Destinations -or
            [int]$row.Destination_D_Pin_Inventory_Count -ne $specification.Destinations -or
            [math]::Abs($required - 6.0) -gt 0.0005 -or
            $actual -gt 6.0005 -or
            $slack -lt -0.0005 -or
            $runtime -lt 0.0 -or
            $runtime -gt ($queryTimeoutSeconds + 0.001)) {
            throw "Fresh semantic-family validation failed: $($specification.WorkerName)"
        }

        $notes = if ($specification.AcceptedName -ceq 'RESET_ABANDONED_COUNT_STABLE_PAYLOAD') {
            'Stable-data settling before valid and stable-until-ack structural proof hash-bound; all timing endpoint roles.'
        } else {
            'Handshake/commit-phase completion barrier structural proof hash-bound; supplemental 79-cell aggregate coverage is PASS and is not a third family.'
        }
        $publishedRows.Add([pscustomobject][ordered]@{
            Family = $specification.AcceptedName
            Constraint_Type = 'SET_MAX_DELAY_DATAPATH_ONLY_PLUS_STRUCTURAL_CDC'
            Required_ns = $row.Required_ns
            Worst_Actual_ns = $row.Worst_Actual_ns
            Slack_ns = $row.Slack_ns
            Result = $row.Result
            Source_Count = $row.Source_Count
            Destination_Count = $row.Destination_Cell_Count
            Runtime_s = $row.Runtime_s
            Notes = $notes
        })
    }

    $supplementalPath = Join-Path $outputDirectory 'G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv'
    $supplementalRows = @(Import-Csv -LiteralPath $supplementalPath)
    if ($supplementalRows.Count -ne 1) {
        throw 'Supplemental aggregate result row count is not exactly one'
    }
    $supplemental = $supplementalRows[0]
    $supplementalRequired = Convert-ToInvariantDouble $supplemental.Required_ns 'supplemental requirement'
    $supplementalActual = Convert-ToInvariantDouble $supplemental.Worst_Actual_ns 'supplemental actual'
    $supplementalSlack = Convert-ToInvariantDouble $supplemental.Slack_ns 'supplemental slack'
    $supplementalRuntime = Convert-ToInvariantDouble $supplemental.Runtime_s 'supplemental runtime'
    if ($supplemental.Coverage_Record -cne 'SUPPLEMENTAL_AGGREGATE_COVERAGE' -or
        $supplemental.Result -cne 'PASS' -or
        $supplemental.Target_Scope -cne 'CELLS_ALL_TIMING_ENDPOINT_PINS' -or
        [int]$supplemental.Source_Count -ne 4 -or
        [int]$supplemental.Destination_Cell_Count -ne 79 -or
        [int]$supplemental.Destination_D_Pin_Inventory_Count -ne 79 -or
        [math]::Abs($supplementalRequired - 6.0) -gt 0.0005 -or
        $supplementalActual -gt 6.0005 -or
        $supplementalSlack -lt -0.0005 -or
        $supplementalRuntime -lt 0.0 -or
        $supplementalRuntime -gt ($queryTimeoutSeconds + 0.001)) {
        throw 'Supplemental aggregate coverage validation failed'
    }

    $methodology = Read-KeyValueFile (
        Join-Path $outputDirectory 'G2B_G13A_FOCUSED_METHODOLOGY_SUMMARY.txt'
    )
    if ($methodology['STATUS'] -cne 'PASS') {
        throw 'Focused Group-13 methodology result is not PASS'
    }

    $warningLines = @()
    foreach ($logPath in @($consoleOut,$consoleErr,$vivadoLog)) {
        $warningLines += @(
            Select-String -LiteralPath $logPath -Pattern '^(WARNING:|CRITICAL WARNING:)' |
                ForEach-Object { $_.Line }
        )
    }
    $warningLines = @($warningLines | Sort-Object -Unique)
    Write-NewUtf8NoBom (Join-Path $outputDirectory 'G2B_LUT1_GROUP13_RECOVERY2_WARNINGS.txt') `
        $(if ($warningLines.Count -eq 0) { "NONE`n" } else { ($warningLines -join "`n") + "`n" })

    $csvText = ($publishedRows | ConvertTo-Csv -NoTypeInformation) -join "`n"
    Write-NewUtf8NoBom $resultsPath ($csvText + "`n")
    $resultsHash = Get-Sha256 $resultsPath

    $gateLines = [Collections.Generic.List[string]]::new()
    foreach ($line in @(
        'GROUP13_REPLACEMENT_SIGNOFF=PASS',
        'GROUP13_METHOD=SETTLING_PLUS_STRUCTURAL_CDC',
        'SEMANTIC_FAMILY_COUNT=2',
        'FAMILY_1=RESET_ABANDONED_COUNT_STABLE_PAYLOAD',
        'FAMILY_1_RESULT=PASS',
        'FAMILY_2=RESET_COMMIT_PHASE_COMPLETION_BARRIER',
        'FAMILY_2_RESULT=PASS',
        'SUPPLEMENTAL_AGGREGATE_COVERAGE=PASS',
        'SUPPLEMENTAL_AGGREGATE_DESTINATION_COUNT=79',
        'SUPPLEMENTAL_AGGREGATE_IS_THIRD_FAMILY=NO',
        'STRUCTURAL_CDC_PROOF_BINDING=PASS',
        'STABLE_DATA_SEMANTICS=PASS',
        'HANDSHAKE_COMMIT_BARRIER=PASS',
        'RESET_RETURN_COHERENCY=PASS',
        'BOUNDED_SETTLING=PASS',
        'GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO',
        'ATTEMPT_NUMBER=1',
        'RETRY_EXECUTED=NO',
        'OUTPUT_OVERWRITE=NO',
        "QUERY_TIMEOUT_SECONDS=$queryTimeoutSeconds",
        "INITIALIZATION_INTERQUERY_TIMEOUT_SECONDS=$initializationInterqueryTimeoutSeconds",
        "TOTAL_RUNTIME_SECONDS=$elapsedText",
        "SOURCE_BRANCH=$sourceBranch",
        "SOURCE_COMMIT=$sourceCommit",
        "SOURCE_TREE=$sourceTree",
        "ACTIVE_XDC_SHA256=$activeXdcHash",
        "ROUTED_DCP_SHA256=$dcpHash",
        "DERIVED_FULL_BASE_SHA256=$derivedFullBaseHash",
        "BS3_CANDIDATE_SHA256=$bs3CandidateHash",
        "G13A_CANDIDATE_SHA256=$g13CandidateHash",
        "REFERENCE_OBJECTS_SHA256=$referenceObjectsHash",
        "G13A_WORKER_SHA256=$workerHash",
        "RECOVERY2_RUNNER_SHA256=$runnerHash",
        "G13A_EVIDENCE_COMMIT=$expectedG13aEvidenceCommit",
        "G13A_EVIDENCE_DIRECTORY_TREE=$g13aDirectoryTree",
        "APPLIED_CONTEXT_SHA256=$(Get-Sha256 $appliedPath)",
        "RAW_FAMILY_RESULTS_SHA256=$(Get-Sha256 $rawResultsPath)",
        "SUPPLEMENTAL_RESULTS_SHA256=$(Get-Sha256 $supplementalPath)",
        "RESULTS_CSV=$resultsPath",
        "RESULTS_CSV_SHA256=$resultsHash",
        "WARNING_COUNT=$($warningLines.Count)",
        'BITSTREAM_PRODUCED=NO',
        'HARDWARE_ACCESSED=NO'
    )) {
        $gateLines.Add($line)
    }
    foreach ($line in $proofBindingLines) { $gateLines.Add($line) }
    Write-NewUtf8NoBom $gatePath (($gateLines -join "`n") + "`n")
    $gateWritten = $true

    Write-Output (
        'G2B_LUT1_GROUP13_RECOVERY2_PASS ' +
        "family1_actual=$($publishedRows[0].Worst_Actual_ns)ns " +
        "family2_actual=$($publishedRows[1].Worst_Actual_ns)ns " +
        "supplemental_actual=$($supplemental.Worst_Actual_ns)ns"
    )
} catch {
    $failureText = $_.Exception.Message.Replace("`r",' ').Replace("`n",' ')
    if (-not $gateWritten -and -not (Test-Path -LiteralPath $gatePath)) {
        $failureGateLines = @(
            'GROUP13_REPLACEMENT_SIGNOFF=FAIL',
            'GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO',
            'ATTEMPT_NUMBER=1',
            'RETRY_EXECUTED=NO',
            'OUTPUT_OVERWRITE=NO',
            "TIMEOUT_PHASE=$timeoutPhase",
            "SUPERVISOR_ERROR=$supervisorError",
            "TOTAL_RUNTIME_SECONDS=$elapsedText",
            "POSTEXISTING_VIVADO_COUNT=$postVivadoCount",
            "FAILURE=$failureText",
            'BITSTREAM_PRODUCED=NO',
            'HARDWARE_ACCESSED=NO'
        )
        Write-NewUtf8NoBom $gatePath (($failureGateLines -join "`n") + "`n")
    }
    throw
}
