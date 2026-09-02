[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version Latest

$evidenceRoot = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery-2'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $PSScriptRoot 'G2B_LUT1_GROUPS14_17_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$baseXdc = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g13a-reset-return-signoff-audit\raw\timing\G2B_G13A_FULL_BASE_WITHOUT_GROUP9_AND_GROUP13.xdc'
$bs3CandidateXdc = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof\G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc'
$g13CandidateXdc = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g13a-reset-return-signoff-audit\G2B_G13A_CANDIDATE_CONSTRAINTS.xdc'
$group13Gate = Join-Path $evidenceRoot 'G2B_LUT1_GROUP13_GATE.txt'
$group13ResultsCsv = Join-Path $evidenceRoot 'G2B_LUT1_GROUP13_SIGNOFF_RESULTS.csv'
$group13Runner = Join-Path $PSScriptRoot 'Invoke-G2BLut1Group13Recovery2.ps1'
$g13aWorker = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-g13a-reset-return-signoff-audit\tools\G2B_G13A_CANDIDATE_CONTINUATION_WORKER.tcl'
$sourceRoot = 'C:\FPGA\V41_G2B'
$activeXdc = Join-Path $sourceRoot 'xdc\common\g2b_cdc.xdc'
$gitExe = 'git.exe'

$expectedDcpSha256 = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$expectedBaseXdcSha256 = '3F7D8613AB3ECF579F3F1E7A09B1608602768D2B9C880CE3B755437081DF1F87'
$expectedBs3CandidateXdcSha256 = 'AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087'
$expectedG13CandidateXdcSha256 = 'E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312'
$expectedWorkerSha256 = 'BED2E13D2EB649D5734C847CD1B45CC0CB7B6FD9A5271E95195DA041497002F4'
$expectedSourceBranch = 'integration/v41-g2b-onech-c2h'
$expectedSourceCommit = '64feb60de5d07f400e6b92527bfe54838b3372ee'
$expectedSourceTree = '26399ed456941e26d5ee4b1b2ca50392338fa24a'
$expectedActiveXdcSha256 = 'C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C'
$expectedG13aEvidenceCommit = '10c7c2898d162af8e2262b3f99861c7d560c4557'
$initializationTimeoutSeconds = 1800
$queryTimeoutSeconds = 300
$postQueryFinalizationTimeoutSeconds = 300
$attemptsPerGroup = 1
$commandText = 'report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation -file <GROUP_RAW_REPORT>'

$resultsCsv = Join-Path $evidenceRoot 'G2B_LUT1_GROUPS14_17_RESULTS.csv'
$gateReceipt = Join-Path $evidenceRoot 'G2B_LUT1_GROUPS14_17_GATE.txt'
$runRoot = Join-Path $evidenceRoot 'raw\groups14_17'
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$invariant = [Globalization.CultureInfo]::InvariantCulture

$groups = @(
    [pscustomobject][ordered]@{ Id = 14; Name = 'RELEASE_SLOT_0_AXI_TO_SOURCE'; Sources = 56; Destinations = 20 }
    [pscustomobject][ordered]@{ Id = 15; Name = 'RELEASE_SLOT_1_AXI_TO_SOURCE'; Sources = 56; Destinations = 20 }
    [pscustomobject][ordered]@{ Id = 16; Name = 'RELEASE_SLOT_2_AXI_TO_SOURCE'; Sources = 56; Destinations = 20 }
    [pscustomobject][ordered]@{ Id = 17; Name = 'RELEASE_SLOT_3_AXI_TO_SOURCE'; Sources = 56; Destinations = 20 }
)

function Write-Utf8NoBomAtomic {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyString()][string]$Text
    )
    $parent = Split-Path -Parent $Path
    if ($parent -and -not (Test-Path -LiteralPath $parent -PathType Container)) {
        New-Item -ItemType Directory -Path $parent | Out-Null
    }
    $temporary = '{0}.{1}.tmp' -f $Path,$PID
    [IO.File]::WriteAllText($temporary, $Text, $script:utf8NoBom)
    [IO.File]::Move($temporary, $Path, $true)
}

function Write-LinesAtomic {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Lines
    )
    $lf = [string][char]10
    Write-Utf8NoBomAtomic -Path $Path -Text (([string[]]$Lines -join $lf) + $lf)
}

function ConvertTo-KvValue {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)
    return $Value.Replace([string][char]13, '').Replace([string][char]10, ' | ').Replace('=', ':')
}

function Write-KvReceipt {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][Collections.IDictionary]$Values
    )
    $lines = foreach ($entry in $Values.GetEnumerator()) {
        '{0}={1}' -f $entry.Key,(ConvertTo-KvValue -Value ([string]$entry.Value))
    }
    Write-LinesAtomic -Path $Path -Lines $lines
}

function Read-KvReceipt {
    param([Parameter(Mandatory)][string]$Path)
    $values = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { return $values }
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line.Length -eq 0) { continue }
        $separator = $line.IndexOf('=')
        if ($separator -le 0) { throw "Invalid key/value row in $Path" }
        $key = $line.Substring(0, $separator)
        if ($values.ContainsKey($key)) { throw "Duplicate key $key in $Path" }
        $values[$key] = $line.Substring($separator + 1)
    }
    return $values
}

function Get-ReceiptValue {
    param(
        [Parameter(Mandatory)][hashtable]$Receipt,
        [Parameter(Mandatory)][string]$Key,
        [AllowEmptyString()][string]$Default = ''
    )
    if ($Receipt.ContainsKey($Key)) { return [string]$Receipt[$Key] }
    return $Default
}

function Get-Sha256 {
    param([Parameter(Mandatory)][string]$Path)
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToUpperInvariant()
}

function Invoke-SourceGitLines {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = @(& $script:gitExe -C $script:sourceRoot @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw ('Governed source Git command failed ({0}): {1}' -f
            ($Arguments -join ' '),(ConvertTo-KvValue -Value (($output | Out-String).Trim())))
    }
    return @($output | ForEach-Object { [string]$_ })
}

function Invoke-SourceGitSingleLine {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $lines = @(Invoke-SourceGitLines -Arguments $Arguments)
    if ($lines.Count -ne 1 -or [string]::IsNullOrWhiteSpace($lines[0])) {
        throw 'Governed source Git command did not return exactly one line: {0}' -f ($Arguments -join ' ')
    }
    return $lines[0].Trim()
}

function Assert-GovernedSourceIdentity {
    if (-not (Test-Path -LiteralPath $script:sourceRoot -PathType Container)) {
        throw "Governed source root is absent: $script:sourceRoot"
    }
    if (-not (Test-Path -LiteralPath $script:activeXdc -PathType Leaf)) {
        throw "Governed active XDC is absent: $script:activeXdc"
    }
    [void](Get-Command $script:gitExe -ErrorAction Stop)
    $branch = Invoke-SourceGitSingleLine -Arguments @('branch','--show-current')
    $commit = Invoke-SourceGitSingleLine -Arguments @('rev-parse','HEAD')
    $tree = Invoke-SourceGitSingleLine -Arguments @('rev-parse','HEAD^{tree}')
    $status = @(Invoke-SourceGitLines -Arguments @('status','--porcelain=v1','--untracked-files=all'))
    $activeXdcSha256 = Get-Sha256 -Path $script:activeXdc
    if ($branch -cne $script:expectedSourceBranch) {
        throw "SOURCE_BRANCH_MISMATCH:$branch"
    }
    if ($commit -cne $script:expectedSourceCommit) {
        throw "SOURCE_COMMIT_MISMATCH:$commit"
    }
    if ($tree -cne $script:expectedSourceTree) {
        throw "SOURCE_TREE_MISMATCH:$tree"
    }
    if ($status.Count -ne 0) {
        throw 'SOURCE_WORKTREE_NOT_CLEAN:{0}' -f (ConvertTo-KvValue -Value ($status -join ' | '))
    }
    if ($activeXdcSha256 -cne $script:expectedActiveXdcSha256) {
        throw "ACTIVE_XDC_MISMATCH:$activeXdcSha256"
    }
    return [pscustomobject][ordered]@{
        Branch = $branch
        Commit = $commit
        Tree = $tree
        WorktreeClean = 'YES'
        ActiveXdcSha256 = $activeXdcSha256
    }
}

function Assert-Group13Gate {
    if (-not (Test-Path -LiteralPath $script:group13Gate -PathType Leaf)) {
        throw "Group-13 gate is absent: $script:group13Gate"
    }
    if (-not (Test-Path -LiteralPath $script:group13ResultsCsv -PathType Leaf)) {
        throw "Group-13 results CSV is absent: $script:group13ResultsCsv"
    }
    $receipt = Read-KvReceipt -Path $script:group13Gate
    $expected = [ordered]@{
        GROUP13_REPLACEMENT_SIGNOFF = 'PASS'
        GROUP13_METHOD = 'SETTLING_PLUS_STRUCTURAL_CDC'
        SEMANTIC_FAMILY_COUNT = '2'
        FAMILY_1 = 'RESET_ABANDONED_COUNT_STABLE_PAYLOAD'
        FAMILY_1_RESULT = 'PASS'
        FAMILY_2 = 'RESET_COMMIT_PHASE_COMPLETION_BARRIER'
        FAMILY_2_RESULT = 'PASS'
        SUPPLEMENTAL_AGGREGATE_COVERAGE = 'PASS'
        SUPPLEMENTAL_AGGREGATE_IS_THIRD_FAMILY = 'NO'
        STRUCTURAL_CDC_PROOF_BINDING = 'PASS'
        STABLE_DATA_SEMANTICS = 'PASS'
        HANDSHAKE_COMMIT_BARRIER = 'PASS'
        RESET_RETURN_COHERENCY = 'PASS'
        BOUNDED_SETTLING = 'PASS'
        GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED = 'NO'
        ATTEMPT_NUMBER = '1'
        RETRY_EXECUTED = 'NO'
        OUTPUT_OVERWRITE = 'NO'
        QUERY_TIMEOUT_SECONDS = '300'
        SOURCE_BRANCH = $script:expectedSourceBranch
        SOURCE_COMMIT = $script:expectedSourceCommit
        SOURCE_TREE = $script:expectedSourceTree
        ACTIVE_XDC_SHA256 = $script:expectedActiveXdcSha256
        ROUTED_DCP_SHA256 = $script:expectedDcpSha256
        DERIVED_FULL_BASE_SHA256 = $script:expectedBaseXdcSha256
        BS3_CANDIDATE_SHA256 = $script:expectedBs3CandidateXdcSha256
        G13A_CANDIDATE_SHA256 = $script:expectedG13CandidateXdcSha256
        G13A_EVIDENCE_COMMIT = $script:expectedG13aEvidenceCommit
        BITSTREAM_PRODUCED = 'NO'
        HARDWARE_ACCESSED = 'NO'
    }
    foreach ($entry in $expected.GetEnumerator()) {
        if (-not $receipt.ContainsKey($entry.Key)) {
            throw "Group-13 gate key is absent: $($entry.Key)"
        }
        if ([string]$receipt[$entry.Key] -cne [string]$entry.Value) {
            throw "Group-13 gate value mismatch: $($entry.Key)=$($receipt[$entry.Key])"
        }
    }
    if ($receipt.ContainsKey('FAMILY_3') -or $receipt.ContainsKey('FAMILY_3_RESULT')) {
        throw 'Group-13 gate contains an unauthorized third semantic family'
    }
    foreach ($key in 'RESULTS_CSV','RESULTS_CSV_SHA256') {
        if (-not $receipt.ContainsKey($key)) { throw "Group-13 gate key is absent: $key" }
    }
    $receiptResultsPath = [IO.Path]::GetFullPath([string]$receipt['RESULTS_CSV'])
    $expectedResultsPath = [IO.Path]::GetFullPath($script:group13ResultsCsv)
    if ($receiptResultsPath -cne $expectedResultsPath) {
        throw "Group-13 results path mismatch: $receiptResultsPath"
    }
    $receiptResultsSha256 = ([string]$receipt['RESULTS_CSV_SHA256']).ToUpperInvariant()
    if ($receiptResultsSha256 -notmatch '^[0-9A-F]{64}$') {
        throw 'Group-13 results receipt SHA-256 is malformed'
    }
    $actualResultsSha256 = Get-Sha256 -Path $script:group13ResultsCsv
    if ($actualResultsSha256 -cne $receiptResultsSha256) {
        throw "Group-13 results CSV hash mismatch: $actualResultsSha256"
    }
    foreach ($binding in @(
        [pscustomobject]@{ Key = 'G13A_WORKER_SHA256'; Path = $script:g13aWorker }
        [pscustomobject]@{ Key = 'RECOVERY2_RUNNER_SHA256'; Path = $script:group13Runner }
    )) {
        if (-not $receipt.ContainsKey($binding.Key)) {
            throw "Group-13 tool-binding key is absent: $($binding.Key)"
        }
        $boundSha256 = ([string]$receipt[$binding.Key]).ToUpperInvariant()
        if ($boundSha256 -notmatch '^[0-9A-F]{64}$' -or
            (Get-Sha256 -Path $binding.Path) -cne $boundSha256) {
            throw "Group-13 tool binding mismatch: $($binding.Key)"
        }
    }
    $rows = @(Import-Csv -LiteralPath $script:group13ResultsCsv)
    $expectedColumns = 'Family,Constraint_Type,Required_ns,Worst_Actual_ns,Slack_ns,Result,Source_Count,Destination_Count,Runtime_s,Notes'
    if ($rows.Count -ne 2 -or
        ($rows[0].PSObject.Properties.Name -join ',') -cne $expectedColumns) {
        throw 'Group-13 results CSV shape/header mismatch'
    }
    $families = @(
        [pscustomobject]@{ Name = 'RESET_ABANDONED_COUNT_STABLE_PAYLOAD'; Sources = 3; Destinations = 32 }
        [pscustomobject]@{ Name = 'RESET_COMMIT_PHASE_COMPLETION_BARRIER'; Sources = 4; Destinations = 207 }
    )
    for ($index = 0; $index -lt $families.Count; $index++) {
        $row = $rows[$index]
        $family = $families[$index]
        $requiredNs = [double]::Parse($row.Required_ns, $script:invariant)
        $actualNs = [double]::Parse($row.Worst_Actual_ns, $script:invariant)
        $slackNs = [double]::Parse($row.Slack_ns, $script:invariant)
        $runtimeSeconds = [double]::Parse($row.Runtime_s, $script:invariant)
        if ($row.Family -cne $family.Name -or
            $row.Constraint_Type -cne 'SET_MAX_DELAY_DATAPATH_ONLY_PLUS_STRUCTURAL_CDC' -or
            $row.Result -cne 'PASS' -or
            [int]$row.Source_Count -ne $family.Sources -or
            [int]$row.Destination_Count -ne $family.Destinations -or
            [Math]::Abs($requiredNs - 6.000) -gt 0.0005 -or
            $actualNs -gt 6.0005 -or $slackNs -lt -0.0005 -or
            $runtimeSeconds -lt 0.0 -or $runtimeSeconds -gt $script:queryTimeoutSeconds) {
            throw "Group-13 results row failed governed validation: $($family.Name)"
        }
    }
    return [pscustomobject][ordered]@{
        GateSha256 = Get-Sha256 -Path $script:group13Gate
        ResultsSha256 = $actualResultsSha256
    }
}

function Get-XdcCommandCount {
    param(
        [Parameter(Mandatory)][string]$Text,
        [Parameter(Mandatory)][string]$Command
    )
    $pattern = '(?m)^[ \t]*{0}(?:[ \t]|$)' -f [regex]::Escape($Command)
    return [regex]::Matches($Text, $pattern).Count
}

function Assert-NoVivadoRelatedProcess {
    $matches = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^(vivado|vivado_lab|hw_server)(\.exe)?$' -or
        $_.CommandLine -match '(?i)[\\/]Vivado[\\/].*vivado(\.bat|\.exe)'
    })
    if ($matches.Count -ne 0) {
        $identities = ($matches | ForEach-Object { '{0}:{1}' -f $_.ProcessId,$_.Name }) -join ','
        throw "Vivado-related process is already active: $identities"
    }
}

function Stop-ExactProcessTree {
    param([Parameter(Mandatory)][int]$RootProcessId)
    if ($RootProcessId -eq $PID) { throw 'Refusing to stop the orchestrator process' }
    $taskkill = Join-Path $env:SystemRoot 'System32\taskkill.exe'
    $output = & $taskkill /PID $RootProcessId /T /F 2>&1 | Out-String
    return (ConvertTo-KvValue -Value $output.Trim())
}

function Get-Warnings {
    param([Parameter(Mandatory)][string[]]$Paths)
    $warnings = [Collections.Generic.List[string]]::new()
    foreach ($path in $Paths) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
        foreach ($line in [IO.File]::ReadAllLines($path)) {
            if ($line -match '^\s*(?:CRITICAL WARNING|WARNING):') {
                $normalized = $line.Trim().Replace([string][char]13, '').Replace([string][char]10, ' ')
                if (-not $warnings.Contains($normalized)) { $warnings.Add($normalized) }
            }
        }
    }
    return @($warnings)
}

function Assert-PassWorkerReceipt {
    param(
        [Parameter(Mandatory)][hashtable]$Receipt,
        [Parameter(Mandatory)]$Group,
        [Parameter(Mandatory)][int]$ExitCode,
        [Parameter(Mandatory)][string]$CompletionMarker
    )
    if ($ExitCode -ne 0) { throw "worker exit code is $ExitCode" }
    if (-not (Test-Path -LiteralPath $CompletionMarker -PathType Leaf)) {
        throw 'QUERY_COMPLETED.marker is absent'
    }
    $required = @(
        'STATE','GROUP_ID','GROUP_NAME','COMMAND','SEALED_DCP_SHA256',
        'BASE_XDC_SHA256','BS3_CANDIDATE_XDC_SHA256',
        'G13_CANDIDATE_XDC_SHA256','WORKER_TCL_SHA256',
        'FULL_CONTEXT_BASE_BUS_SKEW_COMMAND_COUNT',
        'FULL_CONTEXT_BASE_MAX_DELAY_COMMAND_COUNT',
        'FULL_CONTEXT_BS3_BUS_SKEW_COMMAND_COUNT',
        'FULL_CONTEXT_BS3_MAX_DELAY_COMMAND_COUNT',
        'FULL_CONTEXT_G13_BUS_SKEW_COMMAND_COUNT',
        'FULL_CONTEXT_G13_MAX_DELAY_COMMAND_COUNT',
        'FULL_CONTEXT_TOTAL_BUS_SKEW_COMMAND_COUNT',
        'FULL_CONTEXT_TOTAL_MAX_DELAY_COMMAND_COUNT',
        'WORKER_LOCAL_REMOVED_BUS_SKEW_COMMAND_COUNT',
        'QUERY_CONTEXT_BUS_SKEW_COMMAND_COUNT',
        'QUERY_CONTEXT_MAX_DELAY_COMMAND_COUNT','SOURCE_COUNT',
        'DESTINATION_COUNT','REQUIREMENT_NS','ACTUAL_NS','SLACK_NS',
        'QUERY_RUNTIME_SECONDS','GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED',
        'GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED','HARDWARE_ACCESSED'
    )
    foreach ($key in $required) {
        if (-not $Receipt.ContainsKey($key)) { throw "worker receipt key is absent: $key" }
    }
    if ($Receipt['STATE'] -cne 'PASS' -or
        $Receipt['GROUP_ID'] -cne ([string]$Group.Id) -or
        $Receipt['GROUP_NAME'] -cne $Group.Name -or
        $Receipt['COMMAND'] -cne $script:commandText) {
        throw 'worker identity or state mismatch'
    }
    if ($Receipt['SEALED_DCP_SHA256'] -cne $script:expectedDcpSha256 -or
        $Receipt['BASE_XDC_SHA256'] -cne $script:expectedBaseXdcSha256 -or
        $Receipt['BS3_CANDIDATE_XDC_SHA256'] -cne $script:expectedBs3CandidateXdcSha256 -or
        $Receipt['G13_CANDIDATE_XDC_SHA256'] -cne $script:expectedG13CandidateXdcSha256 -or
        $Receipt['WORKER_TCL_SHA256'] -cne $script:expectedWorkerSha256) {
        throw 'worker input identity mismatch'
    }
    if ($Receipt['FULL_CONTEXT_BASE_BUS_SKEW_COMMAND_COUNT'] -cne '15' -or
        $Receipt['FULL_CONTEXT_BASE_MAX_DELAY_COMMAND_COUNT'] -cne '9' -or
        $Receipt['FULL_CONTEXT_BS3_BUS_SKEW_COMMAND_COUNT'] -cne '0' -or
        $Receipt['FULL_CONTEXT_BS3_MAX_DELAY_COMMAND_COUNT'] -cne '3' -or
        $Receipt['FULL_CONTEXT_G13_BUS_SKEW_COMMAND_COUNT'] -cne '0' -or
        $Receipt['FULL_CONTEXT_G13_MAX_DELAY_COMMAND_COUNT'] -cne '2' -or
        $Receipt['FULL_CONTEXT_TOTAL_BUS_SKEW_COMMAND_COUNT'] -cne '15' -or
        $Receipt['FULL_CONTEXT_TOTAL_MAX_DELAY_COMMAND_COUNT'] -cne '14' -or
        $Receipt['WORKER_LOCAL_REMOVED_BUS_SKEW_COMMAND_COUNT'] -cne '15' -or
        $Receipt['QUERY_CONTEXT_BUS_SKEW_COMMAND_COUNT'] -cne '1' -or
        $Receipt['QUERY_CONTEXT_MAX_DELAY_COMMAND_COUNT'] -cne '14') {
        throw 'worker full or isolated constraint context mismatch'
    }
    if ($Receipt['SOURCE_COUNT'] -cne ([string]$Group.Sources) -or
        $Receipt['DESTINATION_COUNT'] -cne ([string]$Group.Destinations)) {
        throw 'worker selector cardinality mismatch'
    }
    if ($Receipt['GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED'] -cne 'NO' -or
        $Receipt['GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED'] -cne 'NO' -or
        $Receipt['HARDWARE_ACCESSED'] -cne 'NO') {
        throw 'worker governance receipt mismatch'
    }
    $requirement = [double]::Parse($Receipt['REQUIREMENT_NS'], $script:invariant)
    $actual = [double]::Parse($Receipt['ACTUAL_NS'], $script:invariant)
    $slack = [double]::Parse($Receipt['SLACK_NS'], $script:invariant)
    $queryRuntime = [double]::Parse($Receipt['QUERY_RUNTIME_SECONDS'], $script:invariant)
    if ([Math]::Abs($requirement - 3.000) -gt 0.0005 -or
        $actual -lt 0.0 -or $slack -lt 0.0 -or
        $queryRuntime -gt $script:queryTimeoutSeconds) {
        throw 'worker bus-skew metric is invalid or violated'
    }
}

function Invoke-BoundedGroup {
    param(
        [Parameter(Mandatory)]$Group,
        [Parameter(Mandatory)][string]$GroupDirectory,
        [Parameter(Mandatory)][string]$WorkerSha256
    )
    $tempDirectory = Join-Path $GroupDirectory 'temp'
    New-Item -ItemType Directory -Path $tempDirectory | Out-Null
    $stdoutPath = Join-Path $GroupDirectory 'console.stdout.log'
    $stderrPath = Join-Path $GroupDirectory 'console.stderr.log'
    $vivadoLog = Join-Path $GroupDirectory 'vivado.log'
    $queryMarker = Join-Path $GroupDirectory 'QUERY_STARTED.marker'
    $completionMarker = Join-Path $GroupDirectory 'QUERY_COMPLETED.marker'
    $watchdogReceipt = Join-Path $GroupDirectory 'EXTERNAL_WATCHDOG.txt'
    $launchReceipt = Join-Path $GroupDirectory 'LAUNCH_COMMAND.txt'
    $arguments = @(
        '-mode','batch',
        '-log',$vivadoLog,
        '-nojournal',
        '-source',$script:worker,
        '-tclargs',$script:checkpoint,$script:baseXdc,
        $script:bs3CandidateXdc,$script:g13CandidateXdc,
        $GroupDirectory,([string]$Group.Id),$WorkerSha256
    )
    $quotedArguments = $arguments | ForEach-Object { '"{0}"' -f ([string]$_).Replace('"','""') }
    Write-LinesAtomic -Path $launchReceipt -Lines @(
        ('"{0}" {1}' -f $script:vivado,($quotedArguments -join ' '))
        'ATTEMPT=1'
        'MAX_ATTEMPTS=1'
        ('GROUP_ID={0}' -f $Group.Id)
        ('GROUP_NAME={0}' -f $Group.Name)
        'GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO'
        'GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED=NO'
        'HARDWARE_ACCESSED=NO'
    )

    $childEnvironment = @{
        XILINX_LOCAL_USER_DATA = 'NO'
        XILINX_TCLAPP_REPO = 'C:\AMDDesignTools\2025.2\Vivado\data\XilinxTclStore'
        TEMP = $tempDirectory
        TMP = $tempDirectory
    }
    $start = [DateTimeOffset]::UtcNow
    $initializationDeadline = $start.AddSeconds($script:initializationTimeoutSeconds)
    $queryDeadline = $null
    $queryStartEpoch = $null
    $queryStarted = $false
    $queryCompletionValidated = $false
    $queryRuntimeFromMarker = $null
    $postQueryDeadline = $null
    $timeoutPhase = 'NONE'
    $supervisorError = 'NONE'
    $killOutput = 'NONE'
    $process = $null
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    try {
        $process = Start-Process -FilePath $script:vivado -ArgumentList $arguments -WorkingDirectory $GroupDirectory -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -Environment $childEnvironment -PassThru -WindowStyle Hidden
        while ($true) {
            $process.Refresh()
            if (-not $queryStarted -and (Test-Path -LiteralPath $queryMarker -PathType Leaf)) {
                try {
                    $marker = Read-KvReceipt -Path $queryMarker
                    foreach ($key in 'GROUP_ID','GROUP_NAME','EPOCH_MILLISECONDS','TIMEOUT_SECONDS','COMMAND','GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED','GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED') {
                        if (-not $marker.ContainsKey($key)) { throw "query marker key is absent: $key" }
                    }
                    if ($marker['GROUP_ID'] -cne ([string]$Group.Id) -or
                        $marker['GROUP_NAME'] -cne $Group.Name -or
                        $marker['TIMEOUT_SECONDS'] -cne ([string]$script:queryTimeoutSeconds) -or
                        $marker['COMMAND'] -cne $script:commandText -or
                        $marker['GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED'] -cne 'NO' -or
                        $marker['GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED'] -cne 'NO') {
                        throw 'query marker governance mismatch'
                    }
                    $queryStartEpoch = [Int64]::Parse($marker['EPOCH_MILLISECONDS'], $script:invariant)
                    $queryStart = [DateTimeOffset]::FromUnixTimeMilliseconds($queryStartEpoch)
                    if ($queryStart -lt $start.AddSeconds(-5) -or
                        $queryStart -gt [DateTimeOffset]::UtcNow.AddSeconds(5)) {
                        throw 'query marker epoch is outside the worker lifetime'
                    }
                    $queryDeadline = $queryStart.AddSeconds($script:queryTimeoutSeconds)
                    $queryStarted = $true
                } catch {
                    $supervisorError = 'INVALID_QUERY_MARKER:{0}' -f (ConvertTo-KvValue -Value $_.Exception.Message)
                    $timeoutPhase = 'MARKER_ERROR'
                    break
                }
            }
            if ($queryStarted -and -not $queryCompletionValidated -and
                (Test-Path -LiteralPath $completionMarker -PathType Leaf)) {
                try {
                    $completion = Read-KvReceipt -Path $completionMarker
                    foreach ($key in 'GROUP_ID','GROUP_NAME','QUERY_START_EPOCH_MILLISECONDS','QUERY_END_EPOCH_MILLISECONDS','QUERY_RUNTIME_SECONDS','TIMEOUT_SECONDS','STATUS','GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED','GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED') {
                        if (-not $completion.ContainsKey($key)) { throw "query completion marker key is absent: $key" }
                    }
                    if ($completion['GROUP_ID'] -cne ([string]$Group.Id) -or
                        $completion['GROUP_NAME'] -cne $Group.Name -or
                        $completion['QUERY_START_EPOCH_MILLISECONDS'] -cne ([string]$queryStartEpoch) -or
                        $completion['TIMEOUT_SECONDS'] -cne ([string]$script:queryTimeoutSeconds) -or
                        $completion['STATUS'] -cnotin @('PASS','VIOLATION') -or
                        $completion['GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED'] -cne 'NO' -or
                        $completion['GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED'] -cne 'NO') {
                        throw 'query completion marker governance mismatch'
                    }
                    $queryEndEpoch = [Int64]::Parse($completion['QUERY_END_EPOCH_MILLISECONDS'], $script:invariant)
                    $queryRuntime = [double]::Parse($completion['QUERY_RUNTIME_SECONDS'], $script:invariant)
                    $runtimeFromEpochs = ($queryEndEpoch - $queryStartEpoch) / 1000.0
                    if ($queryEndEpoch -lt $queryStartEpoch -or $queryRuntime -lt 0.0 -or
                        [Math]::Abs($queryRuntime - $runtimeFromEpochs) -gt 0.002) {
                        throw 'query completion marker runtime is internally inconsistent'
                    }
                    if ($queryRuntime -gt $script:queryTimeoutSeconds) {
                        $queryRuntimeFromMarker = $queryRuntime
                        $timeoutPhase = 'QUERY'
                        break
                    }
                    $queryRuntimeFromMarker = $queryRuntime
                    $queryCompletionValidated = $true
                    $queryDeadline = $null
                    $postQueryDeadline = [DateTimeOffset]::UtcNow.AddSeconds(
                        $script:postQueryFinalizationTimeoutSeconds
                    )
                } catch {
                    $supervisorError = 'INVALID_QUERY_COMPLETION_MARKER:{0}' -f (ConvertTo-KvValue -Value $_.Exception.Message)
                    $timeoutPhase = 'MARKER_ERROR'
                    break
                }
            }
            if ($process.HasExited) {
                if ($queryStarted -and -not $queryCompletionValidated -and $null -ne $queryDeadline) {
                    $processExitUtc = [DateTimeOffset]::new($process.ExitTime.ToUniversalTime())
                    if ($processExitUtc -gt $queryDeadline) { $timeoutPhase = 'QUERY' }
                }
                break
            }
            $now = [DateTimeOffset]::UtcNow
            if ($queryStarted -and -not $queryCompletionValidated -and $null -ne $queryDeadline) {
                if ($now -ge $queryDeadline) { $timeoutPhase = 'QUERY'; break }
            } elseif (-not $queryStarted -and $now -ge $initializationDeadline) {
                $timeoutPhase = 'INITIALIZATION'
                break
            } elseif ($queryCompletionValidated -and $null -ne $postQueryDeadline -and
                $now -ge $postQueryDeadline) {
                $timeoutPhase = 'FINALIZATION'
                break
            }
            [Threading.Thread]::Sleep(200)
        }
        if ($timeoutPhase -ne 'NONE') {
            $process.Refresh()
            if (-not $process.HasExited) {
                $killOutput = Stop-ExactProcessTree -RootProcessId $process.Id
                [void]$process.WaitForExit(60000)
            }
        }
    } catch {
        $supervisorError = 'SUPERVISOR_EXCEPTION:{0}' -f (ConvertTo-KvValue -Value $_.Exception.Message)
        if ($null -ne $process) {
            $process.Refresh()
            if (-not $process.HasExited) {
                $killOutput = Stop-ExactProcessTree -RootProcessId $process.Id
                [void]$process.WaitForExit(60000)
            }
        }
    } finally {
        $stopwatch.Stop()
    }
    $end = [DateTimeOffset]::UtcNow
    if ($null -ne $process) { $process.Refresh() }
    $exitCode = if ($null -ne $process -and $process.HasExited) { $process.ExitCode } else { -999 }
    $elapsed = $stopwatch.Elapsed.TotalSeconds.ToString('F3', $script:invariant)
    $queryElapsed = if ($null -ne $queryRuntimeFromMarker) {
        ([double]$queryRuntimeFromMarker).ToString('F3', $script:invariant)
    } elseif ($null -ne $queryStartEpoch) {
        ([Math]::Max(0.0, ($end.ToUnixTimeMilliseconds() - $queryStartEpoch) / 1000.0)).ToString('F3', $script:invariant)
    } else { '' }
    $postexistingVivado = @(Get-CimInstance Win32_Process | Where-Object {
        $_.Name -match '^(vivado|vivado_lab)(\.exe)?$' -or
        $_.CommandLine -match '(?i)[\\/]Vivado[\\/].*vivado(\.bat|\.exe)'
    }).Count
    if ($postexistingVivado -ne 0 -and $supervisorError -eq 'NONE') {
        $supervisorError = "POSTEXISTING_VIVADO_COUNT:$postexistingVivado"
    }

    Write-KvReceipt -Path $watchdogReceipt -Values ([ordered]@{
        GROUP_ID = $Group.Id
        GROUP_NAME = $Group.Name
        ATTEMPT = 1
        MAX_ATTEMPTS = 1
        START_UTC = $start.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        END_UTC = $end.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        INITIALIZATION_TIMEOUT_SECONDS = $script:initializationTimeoutSeconds
        EXTERNAL_QUERY_TIMEOUT_SECONDS = $script:queryTimeoutSeconds
        POST_QUERY_FINALIZATION_TIMEOUT_SECONDS = $script:postQueryFinalizationTimeoutSeconds
        QUERY_TIMEOUT_SCOPE = 'QUERY_STARTED_MARKER_TO_VALIDATED_QUERY_COMPLETED_MARKER'
        QUERY_COMPLETION_MARKER_VALIDATED = $(if ($queryCompletionValidated) { 'YES' } else { 'NO' })
        QUERY_INTERVAL_END = $(if ($queryCompletionValidated) { 'RECORDED_QUERY_RUNTIME' } else { 'NOT_COMPLETED' })
        ELAPSED_SECONDS = $elapsed
        QUERY_ELAPSED_SECONDS = $queryElapsed
        TIMED_OUT = $(if ($timeoutPhase -in @('INITIALIZATION','QUERY','FINALIZATION')) { 'YES' } else { 'NO' })
        TIMEOUT_PHASE = $timeoutPhase
        PROCESS_EXIT_CODE = $exitCode
        SUPERVISOR_ERROR = $supervisorError
        POSTEXISTING_VIVADO_COUNT = $postexistingVivado
        TASKKILL_OUTPUT = $killOutput
        SEALED_DCP_SHA256 = $script:expectedDcpSha256
        BASE_XDC_SHA256 = $script:expectedBaseXdcSha256
        BS3_CANDIDATE_XDC_SHA256 = $script:expectedBs3CandidateXdcSha256
        G13_CANDIDATE_XDC_SHA256 = $script:expectedG13CandidateXdcSha256
        WORKER_TCL_SHA256 = $WorkerSha256
        GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = 'NO'
        GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED = 'NO'
        HARDWARE_ACCESSED = 'NO'
    })
    return [pscustomobject][ordered]@{
        ExitCode = $exitCode
        ElapsedSeconds = $elapsed
        QueryElapsedSeconds = $queryElapsed
        TimeoutPhase = $timeoutPhase
        SupervisorError = $supervisorError
        CompletionMarker = $completionMarker
        StdoutPath = $stdoutPath
        StderrPath = $stderrPath
        VivadoLog = $vivadoLog
    }
}

foreach ($path in $resultsCsv,$gateReceipt,$runRoot) {
    if (Test-Path -LiteralPath $path) {
        throw "One-attempt output already exists; overwrite and resume are forbidden: $path"
    }
}
if ([IO.Path]::GetFullPath($PSScriptRoot).TrimEnd('\') -cne
    [IO.Path]::GetFullPath((Join-Path $evidenceRoot 'tools')).TrimEnd('\')) {
    throw 'Harness tools directory is outside the governed evidence target'
}
New-Item -ItemType Directory -Path $runRoot | Out-Null

$rows = [Collections.Generic.List[object]]::new()
$firstBlocker = 'NONE'
$workerSha256 = ''
$sourceBranch = 'UNVERIFIED'
$sourceCommit = 'UNVERIFIED'
$sourceTree = 'UNVERIFIED'
$sourceWorktreeClean = 'NO'
$activeXdcSha256 = 'UNVERIFIED'
$group13GateSha256 = 'UNVERIFIED'
$group13ResultsSha256 = 'UNVERIFIED'
$group13PreflightPassed = $false
$preflightPassed = $false
try {
    foreach ($required in $vivado,$worker,$checkpoint,$baseXdc,$bs3CandidateXdc,
        $g13CandidateXdc,$group13Gate,$group13ResultsCsv,$group13Runner,
        $g13aWorker,$activeXdc,$PSCommandPath) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            throw "Required file is absent: $required"
        }
    }
    Assert-NoVivadoRelatedProcess
    $sourceIdentity = Assert-GovernedSourceIdentity
    $sourceBranch = $sourceIdentity.Branch
    $sourceCommit = $sourceIdentity.Commit
    $sourceTree = $sourceIdentity.Tree
    $sourceWorktreeClean = $sourceIdentity.WorktreeClean
    $activeXdcSha256 = $sourceIdentity.ActiveXdcSha256
    $group13Binding = Assert-Group13Gate
    $group13GateSha256 = $group13Binding.GateSha256
    $group13ResultsSha256 = $group13Binding.ResultsSha256
    $group13PreflightPassed = $true
    $dcpSha256 = Get-Sha256 -Path $checkpoint
    $baseSha256 = Get-Sha256 -Path $baseXdc
    $bs3CandidateSha256 = Get-Sha256 -Path $bs3CandidateXdc
    $g13CandidateSha256 = Get-Sha256 -Path $g13CandidateXdc
    $workerSha256 = Get-Sha256 -Path $worker
    if ($dcpSha256 -cne $expectedDcpSha256) { throw "SEALED_DCP_MISMATCH:$dcpSha256" }
    if ($baseSha256 -cne $expectedBaseXdcSha256) { throw "BASE_XDC_MISMATCH:$baseSha256" }
    if ($bs3CandidateSha256 -cne $expectedBs3CandidateXdcSha256) { throw "BS3_CANDIDATE_XDC_MISMATCH:$bs3CandidateSha256" }
    if ($g13CandidateSha256 -cne $expectedG13CandidateXdcSha256) { throw "G13_CANDIDATE_XDC_MISMATCH:$g13CandidateSha256" }
    if ($workerSha256 -cne $expectedWorkerSha256) { throw "WORKER_TCL_MISMATCH:$workerSha256" }

    $baseText = [IO.File]::ReadAllText($baseXdc)
    $bs3CandidateText = [IO.File]::ReadAllText($bs3CandidateXdc)
    $g13CandidateText = [IO.File]::ReadAllText($g13CandidateXdc)
    if ((Get-XdcCommandCount -Text $baseText -Command 'set_bus_skew') -ne 15 -or
        (Get-XdcCommandCount -Text $baseText -Command 'set_max_delay') -ne 9 -or
        (Get-XdcCommandCount -Text $bs3CandidateText -Command 'set_bus_skew') -ne 0 -or
        (Get-XdcCommandCount -Text $bs3CandidateText -Command 'set_max_delay') -ne 3 -or
        (Get-XdcCommandCount -Text $g13CandidateText -Command 'set_bus_skew') -ne 0 -or
        (Get-XdcCommandCount -Text $g13CandidateText -Command 'set_max_delay') -ne 2) {
        throw 'FULL_CONSTRAINT_CONTEXT_COMMAND_COUNT_MISMATCH'
    }
    Write-KvReceipt -Path (Join-Path $runRoot 'PREFLIGHT.txt') -Values ([ordered]@{
        STATE = 'PASS'
        SEALED_DCP = $checkpoint
        SEALED_DCP_SHA256 = $dcpSha256
        BASE_XDC = $baseXdc
        BASE_XDC_SHA256 = $baseSha256
        BASE_XDC_BUS_SKEW_COMMAND_COUNT = 15
        BASE_XDC_MAX_DELAY_COMMAND_COUNT = 9
        BS3_CANDIDATE_XDC = $bs3CandidateXdc
        BS3_CANDIDATE_XDC_SHA256 = $bs3CandidateSha256
        BS3_CANDIDATE_BUS_SKEW_COMMAND_COUNT = 0
        BS3_CANDIDATE_MAX_DELAY_COMMAND_COUNT = 3
        G13_CANDIDATE_XDC = $g13CandidateXdc
        G13_CANDIDATE_XDC_SHA256 = $g13CandidateSha256
        G13_CANDIDATE_BUS_SKEW_COMMAND_COUNT = 0
        G13_CANDIDATE_MAX_DELAY_COMMAND_COUNT = 2
        FULL_CONTEXT_TOTAL_BUS_SKEW_COMMAND_COUNT = 15
        FULL_CONTEXT_TOTAL_MAX_DELAY_COMMAND_COUNT = 14
        WORKER_TCL = $worker
        WORKER_TCL_SHA256 = $workerSha256
        GROUP13_GATE = $group13Gate
        GROUP13_GATE_SHA256 = $group13GateSha256
        GROUP13_REPLACEMENT_SIGNOFF = 'PASS'
        GROUP13_SEMANTIC_FAMILY_COUNT = 2
        GROUP13_FAMILY_1 = 'RESET_ABANDONED_COUNT_STABLE_PAYLOAD'
        GROUP13_FAMILY_1_RESULT = 'PASS'
        GROUP13_FAMILY_2 = 'RESET_COMMIT_PHASE_COMPLETION_BARRIER'
        GROUP13_FAMILY_2_RESULT = 'PASS'
        GROUP13_GLOBAL_REPORT_BUS_SKEW_EXECUTED = 'NO'
        GROUP13_RESULTS_CSV = $group13ResultsCsv
        GROUP13_RESULTS_CSV_SHA256 = $group13ResultsSha256
        SOURCE_ROOT = $sourceRoot
        SOURCE_BRANCH = $sourceBranch
        SOURCE_COMMIT = $sourceCommit
        SOURCE_TREE = $sourceTree
        SOURCE_WORKTREE_CLEAN = $sourceWorktreeClean
        ACTIVE_XDC = $activeXdc
        ACTIVE_XDC_SHA256 = $activeXdcSha256
        GROUP_IDS = '14,15,16,17'
        ATTEMPTS_PER_GROUP = 1
        INITIALIZATION_TIMEOUT_SECONDS = $initializationTimeoutSeconds
        QUERY_TIMEOUT_SECONDS = $queryTimeoutSeconds
        GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = 'NO'
        GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED = 'NO'
        HARDWARE_ACCESSED = 'NO'
    })
    $preflightPassed = $true
} catch {
    $firstBlocker = 'PREFLIGHT_BLOCKER:{0}' -f (ConvertTo-KvValue -Value $_.Exception.Message)
}

if ($preflightPassed) {
    foreach ($group in $groups) {
        if ($firstBlocker -ne 'NONE') { break }
        $groupDirectory = Join-Path $runRoot ('group_{0:D2}_{1}' -f $group.Id,$group.Name)
        New-Item -ItemType Directory -Path $groupDirectory | Out-Null
        $execution = Invoke-BoundedGroup -Group $group -GroupDirectory $groupDirectory -WorkerSha256 $workerSha256
        $receipt = @{}
        $receiptError = 'NONE'
        try {
            $receipt = Read-KvReceipt -Path (Join-Path $groupDirectory 'worker_result.txt')
        } catch {
            $receiptError = 'WORKER_RECEIPT_ERROR:{0}' -f (ConvertTo-KvValue -Value $_.Exception.Message)
        }
        $warningLines = Get-Warnings -Paths @($execution.StdoutPath,$execution.StderrPath,$execution.VivadoLog)
        Write-LinesAtomic -Path (Join-Path $groupDirectory 'WARNINGS.txt') -Lines $(if ($warningLines.Count -eq 0) { @('NONE') } else { $warningLines })
        $result = 'ERROR'
        $resultReason = 'UNKNOWN_WORKER_FAILURE'
        if ($execution.TimeoutPhase -eq 'QUERY') {
            $result = 'REQUIRED_BUS_SKEW_TIMEOUT'
            $resultReason = 'QUERY_EXCEEDED_300_SECONDS_FROM_QUERY_STARTED_MARKER'
        } elseif ($execution.TimeoutPhase -eq 'INITIALIZATION') {
            $result = 'INITIALIZATION_TIMEOUT'
            $resultReason = 'INITIALIZATION_EXCEEDED_1800_SECONDS_BEFORE_QUERY_STARTED_MARKER'
        } elseif ($execution.TimeoutPhase -eq 'FINALIZATION') {
            $result = 'FINALIZATION_TIMEOUT'
            $resultReason = 'POST_QUERY_RECEIPT_FINALIZATION_EXCEEDED_300_SECONDS_AFTER_VALIDATED_COMPLETION_MARKER'
        } elseif ($execution.SupervisorError -ne 'NONE') {
            $resultReason = $execution.SupervisorError
        } elseif ($receiptError -ne 'NONE') {
            $resultReason = $receiptError
        } elseif ((Get-ReceiptValue -Receipt $receipt -Key 'STATE') -ceq 'VIOLATION') {
            $result = 'FAIL'
            $resultReason = 'BUS_SKEW_VIOLATION'
        } else {
            try {
                Assert-PassWorkerReceipt -Receipt $receipt -Group $group -ExitCode $execution.ExitCode -CompletionMarker $execution.CompletionMarker
                $result = 'PASS'
                $resultReason = 'NONE'
            } catch {
                $resultReason = 'WORKER_VALIDATION_ERROR:{0}' -f (ConvertTo-KvValue -Value $_.Exception.Message)
            }
        }
        $runtime = Get-ReceiptValue -Receipt $receipt -Key 'QUERY_RUNTIME_SECONDS' -Default $execution.QueryElapsedSeconds
        if ([string]::IsNullOrWhiteSpace($runtime)) { $runtime = $execution.ElapsedSeconds }
        $warningText = if ($warningLines.Count -eq 0) { 'NONE' } else { $warningLines -join ' | ' }
        $rows.Add([pscustomobject][ordered]@{
            Group_ID = $group.Id
            Name = $group.Name
            Command = (Get-ReceiptValue -Receipt $receipt -Key 'COMMAND' -Default $commandText)
            Source_Count = (Get-ReceiptValue -Receipt $receipt -Key 'SOURCE_COUNT')
            Destination_Count = (Get-ReceiptValue -Receipt $receipt -Key 'DESTINATION_COUNT')
            Runtime_s = $runtime
            Actual_Result = $result
            Actual_ns = (Get-ReceiptValue -Receipt $receipt -Key 'ACTUAL_NS')
            Required_ns = (Get-ReceiptValue -Receipt $receipt -Key 'REQUIREMENT_NS' -Default '3.000')
            Slack_ns = (Get-ReceiptValue -Receipt $receipt -Key 'SLACK_NS')
            Warning_Count = $warningLines.Count
            Warnings = $warningText
            Timeout_Phase = $execution.TimeoutPhase
            Process_Exit_Code = $execution.ExitCode
        })
        Write-KvReceipt -Path (Join-Path $groupDirectory 'GROUP_DISPOSITION.txt') -Values ([ordered]@{
            GROUP_ID = $group.Id
            GROUP_NAME = $group.Name
            RESULT = $result
            RESULT_REASON = $resultReason
            COMMAND = (Get-ReceiptValue -Receipt $receipt -Key 'COMMAND' -Default $commandText)
            SOURCE_COUNT = (Get-ReceiptValue -Receipt $receipt -Key 'SOURCE_COUNT')
            DESTINATION_COUNT = (Get-ReceiptValue -Receipt $receipt -Key 'DESTINATION_COUNT')
            RUNTIME_SECONDS = $runtime
            ACTUAL_NS = (Get-ReceiptValue -Receipt $receipt -Key 'ACTUAL_NS')
            REQUIRED_NS = (Get-ReceiptValue -Receipt $receipt -Key 'REQUIREMENT_NS' -Default '3.000')
            SLACK_NS = (Get-ReceiptValue -Receipt $receipt -Key 'SLACK_NS')
            WARNING_COUNT = $warningLines.Count
            WARNINGS = $warningText
            ATTEMPT = 1
            MAX_ATTEMPTS = 1
            GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = 'NO'
            GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED = 'NO'
            HARDWARE_ACCESSED = 'NO'
        })
        if ($result -eq 'REQUIRED_BUS_SKEW_TIMEOUT') {
            $firstBlocker = 'REQUIRED_BUS_SKEW_TIMEOUT:GROUP_{0}:{1}' -f $group.Id,$group.Name
        } elseif ($result -ne 'PASS') {
            $firstBlocker = '{0}:GROUP_{1}:{2}:{3}' -f $result,$group.Id,$group.Name,$resultReason
        }
    }
}

$sourcePostrunRevalidation = 'NOT_RUN'
if ($preflightPassed -and $firstBlocker -ceq 'NONE') {
    try {
        $postrunSourceIdentity = Assert-GovernedSourceIdentity
        if ($postrunSourceIdentity.Branch -cne $sourceBranch -or
            $postrunSourceIdentity.Commit -cne $sourceCommit -or
            $postrunSourceIdentity.Tree -cne $sourceTree -or
            $postrunSourceIdentity.ActiveXdcSha256 -cne $activeXdcSha256) {
            throw 'Governed source identity changed after Groups 14-17 preflight'
        }
        $sourcePostrunRevalidation = 'PASS'
    } catch {
        $sourcePostrunRevalidation = 'FAIL'
        $firstBlocker = 'POSTRUN_SOURCE_IDENTITY_BLOCKER:{0}' -f (
            ConvertTo-KvValue -Value $_.Exception.Message
        )
    }
}

foreach ($group in $groups) {
    if (@($rows | Where-Object { $_.Group_ID -eq $group.Id }).Count -ne 0) { continue }
    $rows.Add([pscustomobject][ordered]@{
        Group_ID = $group.Id
        Name = $group.Name
        Command = $commandText
        Source_Count = ''
        Destination_Count = ''
        Runtime_s = '0.000'
        Actual_Result = 'NOT_RUN_AFTER_BLOCKER'
        Actual_ns = ''
        Required_ns = '3.000'
        Slack_ns = ''
        Warning_Count = 0
        Warnings = $firstBlocker
        Timeout_Phase = 'NOT_RUN'
        Process_Exit_Code = 'NONE'
    })
}

$orderedRows = @($rows | Sort-Object Group_ID)
$csvLines = $orderedRows | Select-Object Group_ID,Name,Command,Source_Count,Destination_Count,Runtime_s,Actual_Result,Actual_ns,Required_ns,Slack_ns,Warning_Count,Warnings,Timeout_Phase,Process_Exit_Code | ConvertTo-Csv -NoTypeInformation
Write-LinesAtomic -Path $resultsCsv -Lines $csvLines
$resultsCsvSha256 = Get-Sha256 -Path $resultsCsv
$orchestratorSha256 = Get-Sha256 -Path $PSCommandPath
$passCount = @($orderedRows | Where-Object { $_.Actual_Result -ceq 'PASS' }).Count
$timeoutCount = @($orderedRows | Where-Object { $_.Actual_Result -ceq 'REQUIRED_BUS_SKEW_TIMEOUT' }).Count
$failCount = $orderedRows.Count - $passCount - $timeoutCount
$gatePass = $passCount -eq 4 -and $timeoutCount -eq 0 -and $failCount -eq 0 -and $firstBlocker -ceq 'NONE'

Write-KvReceipt -Path $gateReceipt -Values ([ordered]@{
    STATE = $(if ($gatePass) { 'COMPLETE' } else { 'BLOCKED' })
    GROUPS14_17_GATE = $(if ($gatePass) { 'PASS' } else { 'FAIL' })
    GROUP_IDS = '14,15,16,17'
    SEALED_DCP_SHA256 = $expectedDcpSha256
    BASE_XDC_SHA256 = $expectedBaseXdcSha256
    BS3_CANDIDATE_XDC_SHA256 = $expectedBs3CandidateXdcSha256
    G13_CANDIDATE_XDC_SHA256 = $expectedG13CandidateXdcSha256
    WORKER_TCL_SHA256 = $expectedWorkerSha256
    ORCHESTRATOR_PS1_SHA256 = $orchestratorSha256
    GROUP13_GATE_SHA256 = $group13GateSha256
    GROUP13_REPLACEMENT_SIGNOFF = $(if ($group13PreflightPassed) { 'PASS' } else { 'NOT_VERIFIED' })
    GROUP13_SEMANTIC_FAMILY_COUNT = 2
    GROUP13_FAMILY_1 = 'RESET_ABANDONED_COUNT_STABLE_PAYLOAD'
    GROUP13_FAMILY_1_RESULT = $(if ($group13PreflightPassed) { 'PASS' } else { 'NOT_VERIFIED' })
    GROUP13_FAMILY_2 = 'RESET_COMMIT_PHASE_COMPLETION_BARRIER'
    GROUP13_FAMILY_2_RESULT = $(if ($group13PreflightPassed) { 'PASS' } else { 'NOT_VERIFIED' })
    GROUP13_GLOBAL_REPORT_BUS_SKEW_EXECUTED = $(if ($group13PreflightPassed) { 'NO' } else { 'NOT_VERIFIED' })
    GROUP13_RESULTS_CSV_SHA256 = $group13ResultsSha256
    SOURCE_BRANCH = $sourceBranch
    SOURCE_COMMIT = $sourceCommit
    SOURCE_TREE = $sourceTree
    SOURCE_WORKTREE_CLEAN = $sourceWorktreeClean
    ACTIVE_XDC_SHA256 = $activeXdcSha256
    SOURCE_POSTRUN_REVALIDATION = $sourcePostrunRevalidation
    GROUPS_REQUIRED = 4
    GROUPS_PASS = $passCount
    GROUPS_FAIL = $failCount
    GROUPS_TIMEOUT = $timeoutCount
    ATTEMPTS_PER_GROUP = $attemptsPerGroup
    INITIALIZATION_TIMEOUT_SECONDS = $initializationTimeoutSeconds
    QUERY_TIMEOUT_SECONDS = $queryTimeoutSeconds
    POST_QUERY_FINALIZATION_TIMEOUT_SECONDS = $postQueryFinalizationTimeoutSeconds
    GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = 'NO'
    GLOBAL_GROUP13_REPORT_BUS_SKEW_EXECUTED = 'NO'
    HARDWARE_ACCESSED = 'NO'
    RESULTS_CSV = [IO.Path]::GetFullPath($resultsCsv)
    RESULTS_CSV_SHA256 = $resultsCsvSha256
    FIRST_BLOCKER = $firstBlocker
})

if ($gatePass) { exit 0 }
exit 1
