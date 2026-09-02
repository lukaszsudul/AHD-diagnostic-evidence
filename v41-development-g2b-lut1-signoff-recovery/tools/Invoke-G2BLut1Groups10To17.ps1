[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
Set-StrictMode -Version Latest

$evidenceRoot = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery'
$vivado = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$worker = Join-Path $PSScriptRoot 'G2B_LUT1_GROUPS10_17_WORKER.tcl'
$checkpoint = 'C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp'
$baseXdc = 'C:\FPGA\G2B_BS3_OWNERSHIP_20260902\G2B_BS3_FULL_BASE_WITHOUT_GROUP9.xdc'
$candidateXdc = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-bs3-ownership-mailbox-settling-proof\G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc'

$expectedDcpSha256 = 'EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83'
$expectedBaseXdcSha256 = '3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507'
$expectedCandidateXdcSha256 = 'AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087'
$expectedWorkerSha256 = 'C5981DC0FA27892C1CCD150ADEBFE032443EBC33B0B7039911CF226D2415FCCA'
$initializationTimeoutSeconds = 1800
$queryTimeoutSeconds = 300
$attemptsPerGroup = 1
$commandText = 'report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation -file <GROUP_RAW_REPORT>'

$resultsCsv = Join-Path $evidenceRoot 'G2B_LUT1_GROUPS10_17_RESULTS.csv'
$gateReceipt = Join-Path $evidenceRoot 'G2B_LUT1_GROUPS10_17_GATE.txt'
$runRoot = Join-Path $evidenceRoot 'raw\groups10_17'
$utf8NoBom = [Text.UTF8Encoding]::new($false)
$invariant = [Globalization.CultureInfo]::InvariantCulture

$groups = @(
    [pscustomobject][ordered]@{ Id = 10; Name = 'DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI'; Sources = 44; Destinations = 32 }
    [pscustomobject][ordered]@{ Id = 11; Name = 'DESCRIPTOR_GENERATION_SOURCE_TO_AXI'; Sources = 32; Destinations = 24 }
    [pscustomobject][ordered]@{ Id = 12; Name = 'DESCRIPTOR_EPOCH_SOURCE_TO_AXI'; Sources = 128; Destinations = 32 }
    [pscustomobject][ordered]@{ Id = 13; Name = 'RESET_RETURN_SOURCE_TO_AXI'; Sources = 7; Destinations = 207 }
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

function ConvertTo-KvValue {
    param([Parameter(Mandatory)][AllowEmptyString()][string]$Value)
    return $Value.Replace([string][char]13, '').Replace([string][char]10, ' | ').Replace('=', ':')
}

function Read-KvReceipt {
    param([Parameter(Mandatory)][string]$Path)
    $values = @{}
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $values
    }
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line.Length -eq 0) { continue }
        $separator = $line.IndexOf('=')
        if ($separator -le 0) {
            throw "Invalid key/value row in $Path"
        }
        $key = $line.Substring(0, $separator)
        if ($values.ContainsKey($key)) {
            throw "Duplicate key $key in $Path"
        }
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
    if ($RootProcessId -eq $PID) {
        throw 'Refusing to stop the orchestrator process'
    }
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
                if (-not $warnings.Contains($normalized)) {
                    $warnings.Add($normalized)
                }
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
        'BASE_XDC_SHA256','BS3_CANDIDATE_XDC_SHA256','WORKER_TCL_SHA256',
        'FULL_CONTEXT_BASE_BUS_SKEW_COMMAND_COUNT',
        'FULL_CONTEXT_CANDIDATE_BUS_SKEW_COMMAND_COUNT',
        'FULL_CONTEXT_CANDIDATE_MAX_DELAY_COMMAND_COUNT',
        'WORKER_LOCAL_REMOVED_BUS_SKEW_COMMAND_COUNT',
        'QUERY_CONTEXT_BUS_SKEW_COMMAND_COUNT','SOURCE_COUNT',
        'DESTINATION_COUNT','REQUIREMENT_NS','ACTUAL_NS','SLACK_NS',
        'QUERY_RUNTIME_SECONDS','GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED',
        'HARDWARE_ACCESSED'
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
        $Receipt['BS3_CANDIDATE_XDC_SHA256'] -cne $script:expectedCandidateXdcSha256 -or
        $Receipt['WORKER_TCL_SHA256'] -cne $script:expectedWorkerSha256) {
        throw 'worker input identity mismatch'
    }
    if ($Receipt['FULL_CONTEXT_BASE_BUS_SKEW_COMMAND_COUNT'] -cne '16' -or
        $Receipt['FULL_CONTEXT_CANDIDATE_BUS_SKEW_COMMAND_COUNT'] -cne '0' -or
        $Receipt['FULL_CONTEXT_CANDIDATE_MAX_DELAY_COMMAND_COUNT'] -cne '3' -or
        $Receipt['WORKER_LOCAL_REMOVED_BUS_SKEW_COMMAND_COUNT'] -cne '16' -or
        $Receipt['QUERY_CONTEXT_BUS_SKEW_COMMAND_COUNT'] -cne '1') {
        throw 'worker full or isolated constraint context mismatch'
    }
    if ($Receipt['SOURCE_COUNT'] -cne ([string]$Group.Sources) -or
        $Receipt['DESTINATION_COUNT'] -cne ([string]$Group.Destinations)) {
        throw 'worker selector cardinality mismatch'
    }
    if ($Receipt['GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED'] -cne 'NO' -or
        $Receipt['HARDWARE_ACCESSED'] -cne 'NO') {
        throw 'worker governance receipt mismatch'
    }
    $requirement = [double]::Parse($Receipt['REQUIREMENT_NS'], $script:invariant)
    $actual = [double]::Parse($Receipt['ACTUAL_NS'], $script:invariant)
    $slack = [double]::Parse($Receipt['SLACK_NS'], $script:invariant)
    if ([Math]::Abs($requirement - 3.000) -gt 0.0005 -or
        $actual -lt 0.0 -or $slack -lt 0.0) {
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
        '-tclargs',$script:checkpoint,$script:baseXdc,$script:candidateXdc,
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
    $timeoutPhase = 'NONE'
    $supervisorError = 'NONE'
    $killOutput = 'NONE'
    $process = $null
    $stopwatch = [Diagnostics.Stopwatch]::StartNew()
    try {
        $process = Start-Process -FilePath $script:vivado -ArgumentList $arguments -WorkingDirectory $GroupDirectory -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath -Environment $childEnvironment -PassThru -WindowStyle Hidden
        while ($true) {
            $process.Refresh()
            if ($process.HasExited) { break }
            if ($null -eq $queryDeadline -and (Test-Path -LiteralPath $queryMarker -PathType Leaf)) {
                try {
                    $marker = Read-KvReceipt -Path $queryMarker
                    foreach ($key in 'GROUP_ID','GROUP_NAME','EPOCH_MILLISECONDS','TIMEOUT_SECONDS','COMMAND','GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED') {
                        if (-not $marker.ContainsKey($key)) { throw "query marker key is absent: $key" }
                    }
                    if ($marker['GROUP_ID'] -cne ([string]$Group.Id) -or
                        $marker['GROUP_NAME'] -cne $Group.Name -or
                        $marker['TIMEOUT_SECONDS'] -cne ([string]$script:queryTimeoutSeconds) -or
                        $marker['COMMAND'] -cne $script:commandText -or
                        $marker['GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED'] -cne 'NO') {
                        throw 'query marker governance mismatch'
                    }
                    $queryStartEpoch = [Int64]::Parse($marker['EPOCH_MILLISECONDS'], $script:invariant)
                    $queryStart = [DateTimeOffset]::FromUnixTimeMilliseconds($queryStartEpoch)
                    if ($queryStart -lt $start.AddSeconds(-5) -or
                        $queryStart -gt [DateTimeOffset]::UtcNow.AddSeconds(5)) {
                        throw 'query marker epoch is outside the worker lifetime'
                    }
                    $queryDeadline = $queryStart.AddSeconds($script:queryTimeoutSeconds)
                } catch {
                    $supervisorError = 'INVALID_QUERY_MARKER:{0}' -f (ConvertTo-KvValue -Value $_.Exception.Message)
                    $timeoutPhase = 'MARKER_ERROR'
                    break
                }
            }
            $now = [DateTimeOffset]::UtcNow
            if ($null -ne $queryDeadline) {
                if ($now -ge $queryDeadline) {
                    $timeoutPhase = 'QUERY'
                    break
                }
            } elseif ($now -ge $initializationDeadline) {
                $timeoutPhase = 'INITIALIZATION'
                break
            }
            [Threading.Thread]::Sleep(200)
        }
        if ($timeoutPhase -ne 'NONE') {
            $killOutput = Stop-ExactProcessTree -RootProcessId $process.Id
            [void]$process.WaitForExit(60000)
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
    $queryElapsed = if ($null -ne $queryStartEpoch) {
        ([Math]::Max(0.0, ($end.ToUnixTimeMilliseconds() - $queryStartEpoch) / 1000.0)).ToString('F3', $script:invariant)
    } else {
        ''
    }
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
        QUERY_TIMEOUT_SCOPE = 'QUERY_STARTED_MARKER_TO_PROCESS_COMPLETION'
        ELAPSED_SECONDS = $elapsed
        QUERY_ELAPSED_SECONDS = $queryElapsed
        TIMED_OUT = $(if ($timeoutPhase -eq 'INITIALIZATION' -or $timeoutPhase -eq 'QUERY') { 'YES' } else { 'NO' })
        TIMEOUT_PHASE = $timeoutPhase
        PROCESS_EXIT_CODE = $exitCode
        SUPERVISOR_ERROR = $supervisorError
        POSTEXISTING_VIVADO_COUNT = $postexistingVivado
        TASKKILL_OUTPUT = $killOutput
        SEALED_DCP_SHA256 = $script:expectedDcpSha256
        BASE_XDC_SHA256 = $script:expectedBaseXdcSha256
        BS3_CANDIDATE_XDC_SHA256 = $script:expectedCandidateXdcSha256
        WORKER_TCL_SHA256 = $WorkerSha256
        GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = 'NO'
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
$preflightPassed = $false
try {
    foreach ($required in $vivado,$worker,$checkpoint,$baseXdc,$candidateXdc,$PSCommandPath) {
        if (-not (Test-Path -LiteralPath $required -PathType Leaf)) {
            throw "Required file is absent: $required"
        }
    }
    Assert-NoVivadoRelatedProcess
    $dcpSha256 = Get-Sha256 -Path $checkpoint
    $baseSha256 = Get-Sha256 -Path $baseXdc
    $candidateSha256 = Get-Sha256 -Path $candidateXdc
    $workerSha256 = Get-Sha256 -Path $worker
    if ($dcpSha256 -cne $expectedDcpSha256) { throw "SEALED_DCP_MISMATCH:$dcpSha256" }
    if ($baseSha256 -cne $expectedBaseXdcSha256) { throw "BASE_XDC_MISMATCH:$baseSha256" }
    if ($candidateSha256 -cne $expectedCandidateXdcSha256) { throw "BS3_CANDIDATE_XDC_MISMATCH:$candidateSha256" }
    if ($workerSha256 -cne $expectedWorkerSha256) { throw "WORKER_TCL_MISMATCH:$workerSha256" }

    $baseText = [IO.File]::ReadAllText($baseXdc)
    $candidateText = [IO.File]::ReadAllText($candidateXdc)
    if ((Get-XdcCommandCount -Text $baseText -Command 'set_bus_skew') -ne 16 -or
        (Get-XdcCommandCount -Text $baseText -Command 'set_max_delay') -ne 9 -or
        (Get-XdcCommandCount -Text $candidateText -Command 'set_bus_skew') -ne 0 -or
        (Get-XdcCommandCount -Text $candidateText -Command 'set_max_delay') -ne 3) {
        throw 'FULL_CONSTRAINT_CONTEXT_COMMAND_COUNT_MISMATCH'
    }
    Write-KvReceipt -Path (Join-Path $runRoot 'PREFLIGHT.txt') -Values ([ordered]@{
        STATE = 'PASS'
        SEALED_DCP = $checkpoint
        SEALED_DCP_SHA256 = $dcpSha256
        BASE_XDC = $baseXdc
        BASE_XDC_SHA256 = $baseSha256
        BASE_XDC_BUS_SKEW_COMMAND_COUNT = 16
        BASE_XDC_MAX_DELAY_COMMAND_COUNT = 9
        BS3_CANDIDATE_XDC = $candidateXdc
        BS3_CANDIDATE_XDC_SHA256 = $candidateSha256
        BS3_CANDIDATE_BUS_SKEW_COMMAND_COUNT = 0
        BS3_CANDIDATE_MAX_DELAY_COMMAND_COUNT = 3
        WORKER_TCL = $worker
        WORKER_TCL_SHA256 = $workerSha256
        GROUP_IDS = '10,11,12,13,14,15,16,17'
        ATTEMPTS_PER_GROUP = 1
        INITIALIZATION_TIMEOUT_SECONDS = $initializationTimeoutSeconds
        QUERY_TIMEOUT_SECONDS = $queryTimeoutSeconds
        GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = 'NO'
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
            Runtime_s = $runtime
            Result = $result
            Actual_ns = (Get-ReceiptValue -Receipt $receipt -Key 'ACTUAL_NS')
            Required_ns = (Get-ReceiptValue -Receipt $receipt -Key 'REQUIREMENT_NS' -Default '3.000')
            Slack_ns = (Get-ReceiptValue -Receipt $receipt -Key 'SLACK_NS')
            Warning_Count = $warningLines.Count
            Warnings = $warningText
            Source_Count = (Get-ReceiptValue -Receipt $receipt -Key 'SOURCE_COUNT')
            Destination_Count = (Get-ReceiptValue -Receipt $receipt -Key 'DESTINATION_COUNT')
            Timeout_Phase = $execution.TimeoutPhase
            Process_Exit_Code = $execution.ExitCode
        })
        Write-KvReceipt -Path (Join-Path $groupDirectory 'GROUP_DISPOSITION.txt') -Values ([ordered]@{
            GROUP_ID = $group.Id
            GROUP_NAME = $group.Name
            RESULT = $result
            RESULT_REASON = $resultReason
            COMMAND = (Get-ReceiptValue -Receipt $receipt -Key 'COMMAND' -Default $commandText)
            RUNTIME_SECONDS = $runtime
            ACTUAL_NS = (Get-ReceiptValue -Receipt $receipt -Key 'ACTUAL_NS')
            REQUIRED_NS = (Get-ReceiptValue -Receipt $receipt -Key 'REQUIREMENT_NS' -Default '3.000')
            SLACK_NS = (Get-ReceiptValue -Receipt $receipt -Key 'SLACK_NS')
            WARNING_COUNT = $warningLines.Count
            WARNINGS = $warningText
            SOURCE_COUNT = (Get-ReceiptValue -Receipt $receipt -Key 'SOURCE_COUNT')
            DESTINATION_COUNT = (Get-ReceiptValue -Receipt $receipt -Key 'DESTINATION_COUNT')
            ATTEMPT = 1
            MAX_ATTEMPTS = 1
            GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = 'NO'
            HARDWARE_ACCESSED = 'NO'
        })
        if ($result -ne 'PASS') {
            $firstBlocker = '{0}:GROUP_{1:D2}:{2}:{3}' -f $result,$group.Id,$group.Name,$resultReason
        }
    }
}

foreach ($group in $groups) {
    if (@($rows | Where-Object { $_.Group_ID -eq $group.Id }).Count -ne 0) { continue }
    $rows.Add([pscustomobject][ordered]@{
        Group_ID = $group.Id
        Name = $group.Name
        Command = $commandText
        Runtime_s = '0.000'
        Result = 'NOT_RUN_AFTER_BLOCKER'
        Actual_ns = ''
        Required_ns = '3.000'
        Slack_ns = ''
        Warning_Count = 0
        Warnings = $firstBlocker
        Source_Count = ''
        Destination_Count = ''
        Timeout_Phase = 'NOT_RUN'
        Process_Exit_Code = 'NONE'
    })
}

$orderedRows = @($rows | Sort-Object Group_ID)
$csvLines = $orderedRows | Select-Object Group_ID,Name,Command,Runtime_s,Result,Actual_ns,Required_ns,Slack_ns,Warning_Count,Warnings,Source_Count,Destination_Count,Timeout_Phase,Process_Exit_Code | ConvertTo-Csv -NoTypeInformation
Write-LinesAtomic -Path $resultsCsv -Lines $csvLines
$resultsCsvSha256 = Get-Sha256 -Path $resultsCsv
$orchestratorSha256 = Get-Sha256 -Path $PSCommandPath
$passCount = @($orderedRows | Where-Object { $_.Result -ceq 'PASS' }).Count
$timeoutCount = @($orderedRows | Where-Object { $_.Result -ceq 'REQUIRED_BUS_SKEW_TIMEOUT' }).Count
$failCount = $orderedRows.Count - $passCount - $timeoutCount
$gatePass = $passCount -eq 8 -and $timeoutCount -eq 0 -and $failCount -eq 0 -and $firstBlocker -ceq 'NONE'

Write-KvReceipt -Path $gateReceipt -Values ([ordered]@{
    STATE = $(if ($gatePass) { 'COMPLETE' } else { 'BLOCKED' })
    GROUPS10_17_GATE = $(if ($gatePass) { 'PASS' } else { 'FAIL' })
    GROUP_IDS = '10,11,12,13,14,15,16,17'
    SEALED_DCP_SHA256 = $expectedDcpSha256
    BASE_XDC_SHA256 = $expectedBaseXdcSha256
    BS3_CANDIDATE_XDC_SHA256 = $expectedCandidateXdcSha256
    WORKER_TCL_SHA256 = $expectedWorkerSha256
    ORCHESTRATOR_PS1_SHA256 = $orchestratorSha256
    GROUPS_REQUIRED = 8
    GROUPS_PASS = $passCount
    GROUPS_FAIL = $failCount
    GROUPS_TIMEOUT = $timeoutCount
    ATTEMPTS_PER_GROUP = $attemptsPerGroup
    INITIALIZATION_TIMEOUT_SECONDS = $initializationTimeoutSeconds
    QUERY_TIMEOUT_SECONDS = $queryTimeoutSeconds
    GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED = 'NO'
    HARDWARE_ACCESSED = 'NO'
    RESULTS_CSV = [IO.Path]::GetFullPath($resultsCsv)
    RESULTS_CSV_SHA256 = $resultsCsvSha256
    FIRST_BLOCKER = $firstBlocker
})

if ($gatePass) { exit 0 }
exit 1
