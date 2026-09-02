[CmdletBinding()]
param(
    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$VivadoBat = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$EvidenceRoot = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$BitstreamPath = 'C:\FPGA\G2B_LUT1_PRODUCT_CANDIDATE_20260902\AHD_v41_G2B_LUT1_PRODUCT.bit',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$OfflineProtectionGate = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery\G2B_LUT1_OFFLINE_PROTECTION_GATE.txt',

    [Parameter()]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$OfflineProtectionGateSha256 = '1AF5EB7F1DEAF98C271FF7C10C758895D2B81A3B891D259F6867B260C1F10A7D',

    [Parameter()]
    [ValidateNotNullOrEmpty()]
    [string]$Group9Gate = 'C:\FPGA\V41_G2B_EVIDENCE\v41-development-g2b-lut1-signoff-recovery\G2B_LUT1_GROUP9_GATE.txt',

    [Parameter()]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$Group9GateSha256 = '4531FF587FEE60FA99DC6523C7F11E6585945390D1FE5AB66CA4B30E040BB25B'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-AtomicLines {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string[]]$Lines
    )
    $parent = Split-Path -Parent $Path
    if (-not [string]::IsNullOrWhiteSpace($parent)) {
        [System.IO.Directory]::CreateDirectory($parent) | Out-Null
    }
    $temporary = '{0}.{1}.tmp' -f $Path, $PID
    [System.IO.File]::WriteAllLines($temporary, $Lines, [System.Text.UTF8Encoding]::new($false))
    Move-Item -LiteralPath $temporary -Destination $Path -Force
}

function Read-KeyValueReceipt {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required receipt is absent: $Path"
    }
    $values = @{}
    $lineNumber = 0
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        $lineNumber++
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }
        $separator = $line.IndexOf('=')
        if ($separator -le 0) {
            throw "Invalid key/value row at ${Path}:$lineNumber"
        }
        $key = $line.Substring(0, $separator)
        $value = $line.Substring($separator + 1)
        if ($values.ContainsKey($key)) {
            throw "Duplicate receipt key '$key' in $Path"
        }
        $values[$key] = $value
    }
    return $values
}

function Require-ReceiptValue {
    param(
        [Parameter(Mandatory = $true)][hashtable]$Values,
        [Parameter(Mandatory = $true)][string]$Key,
        [Parameter(Mandatory = $true)][string]$Expected
    )
    if (-not $Values.ContainsKey($Key)) {
        throw "Required receipt key is absent: $Key"
    }
    if ($Values[$Key] -cne $Expected) {
        throw "Receipt drift for ${Key}: expected '$Expected', got '$($Values[$Key])'"
    }
}

function Get-ExactSha256 {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "File is absent for SHA-256: $Path"
    }
    return (Get-FileHash -Algorithm SHA256 -LiteralPath $Path).Hash.ToUpperInvariant()
}

function Get-DescendantProcessIds {
    param([Parameter(Mandatory = $true)][int]$RootProcessId)
    $snapshot = @(Get-CimInstance -ClassName Win32_Process |
        Select-Object ProcessId, ParentProcessId)
    $knownIds = @($RootProcessId)
    $descendantIds = @()
    while ($true) {
        $newIds = @(@(
            foreach ($item in $snapshot) {
                $candidateId = [int]$item.ProcessId
                $parentId = [int]$item.ParentProcessId
                if ($knownIds -contains $parentId -and $knownIds -notcontains $candidateId) {
                    $candidateId
                }
            }
        ) | Select-Object -Unique)
        if ($newIds.Count -eq 0) {
            break
        }
        $descendantIds += $newIds
        $knownIds += $newIds
    }
    return @($descendantIds | Select-Object -Unique)
}

function Stop-ExactProcessTree {
    param([Parameter(Mandatory = $true)][System.Diagnostics.Process]$Process)
    try {
        $Process.Refresh()
        if ($Process.HasExited) {
            return $true
        }
        $descendantIds = @(Get-DescendantProcessIds -RootProcessId $Process.Id)
        $killer = Start-Process `
            -FilePath (Join-Path $env:SystemRoot 'System32\taskkill.exe') `
            -ArgumentList @('/PID', [string]$Process.Id, '/T', '/F') `
            -WindowStyle Hidden `
            -Wait `
            -PassThru
        [void]$Process.WaitForExit(30000)
        $Process.Refresh()
        $remainingDescendants = @(
            foreach ($descendantId in $descendantIds) {
                try {
                    [void][Diagnostics.Process]::GetProcessById($descendantId)
                    $descendantId
                }
                catch {
                    # The snapshotted descendant no longer exists.
                }
            }
        )
        return ($killer.ExitCode -eq 0 -and $Process.HasExited -and
            $remainingDescendants.Count -eq 0)
    }
    catch {
        return $false
    }
}

function ConvertTo-QuotedProcessArgument {
    param([Parameter(Mandatory = $true)][string]$Value)
    if ($Value.Contains('"')) {
        throw 'A Vivado command-line argument contains an unsupported double quote'
    }
    return '"{0}"' -f $Value
}

function Get-MarkerPhase {
    param([Parameter(Mandatory = $true)][string]$Path)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        return $null
    }
    foreach ($line in [System.IO.File]::ReadAllLines($Path)) {
        if ($line.StartsWith('PHASE=', [System.StringComparison]::Ordinal)) {
            return $line.Substring(6)
        }
    }
    return $null
}

$resolvedEvidenceRoot = [System.IO.Path]::GetFullPath($EvidenceRoot)
$resolvedBitstreamPath = [System.IO.Path]::GetFullPath($BitstreamPath)
$resolvedOfflineGate = [System.IO.Path]::GetFullPath($OfflineProtectionGate)
$resolvedGroup9Gate = [System.IO.Path]::GetFullPath($Group9Gate)
$resolvedVivadoBat = [System.IO.Path]::GetFullPath($VivadoBat)
$finalizerTcl = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot 'g2b_lut1_routed_signoff_recovery.tcl')
)
$runnerPath = [System.IO.Path]::GetFullPath($PSCommandPath)
$rawRoot = Join-Path $resolvedEvidenceRoot 'raw\final_signoff'
$phaseMarker = Join-Path $rawRoot 'ACTIVE_PHASE.marker'
$watchdogReceipt = Join-Path $rawRoot 'PHASE_WATCHDOG_RESULT.txt'
$finalResult = Join-Path $resolvedEvidenceRoot 'FINAL_GATE_RESULT.txt'
$preBitGate = Join-Path $resolvedEvidenceRoot 'G2B_PRE_BITSTREAM_HARD_GATE.txt'
$candidateIdentity = Join-Path $resolvedEvidenceRoot 'G2B_LUT1_PRODUCT_CANDIDATE_IDENTITY.json'
$groupsGate = Join-Path $resolvedEvidenceRoot 'G2B_LUT1_GROUPS10_17_GATE.txt'
$groupsCsv = Join-Path $resolvedEvidenceRoot 'G2B_LUT1_GROUPS10_17_RESULTS.csv'
$vivadoLog = Join-Path $rawRoot 'VIVADO_FINAL_SIGNOFF.log'
$vivadoJournal = Join-Path $rawRoot 'VIVADO_FINAL_SIGNOFF.jou'
$consoleOut = Join-Path $rawRoot 'VIVADO_CONSOLE.stdout.log'
$consoleErr = Join-Path $rawRoot 'VIVADO_CONSOLE.stderr.log'
$tempRoot = Join-Path $rawRoot 'vivado_temp'

foreach ($requiredFile in @(
    $resolvedVivadoBat,
    $finalizerTcl,
    $runnerPath,
    $resolvedOfflineGate,
    $resolvedGroup9Gate,
    $groupsGate,
    $groupsCsv
)) {
    if (-not (Test-Path -LiteralPath $requiredFile -PathType Leaf)) {
        throw "Required final-signoff input is absent: $requiredFile"
    }
}

$actualOfflineSha = Get-ExactSha256 -Path $resolvedOfflineGate
if ($actualOfflineSha -cne $OfflineProtectionGateSha256.ToUpperInvariant()) {
    throw "Offline protection gate SHA-256 mismatch: $actualOfflineSha"
}
$actualGroup9Sha = Get-ExactSha256 -Path $resolvedGroup9Gate
if ($actualGroup9Sha -cne $Group9GateSha256.ToUpperInvariant()) {
    throw "Group-9 recovery gate SHA-256 mismatch: $actualGroup9Sha"
}

foreach ($oneShotTarget in @(
    $rawRoot,
    $finalResult,
    $preBitGate,
    $candidateIdentity,
    $resolvedBitstreamPath
)) {
    if (Test-Path -LiteralPath $oneShotTarget) {
        throw "One-shot final-signoff output already exists; refusing overwrite: $oneShotTarget"
    }
}

[System.IO.Directory]::CreateDirectory($rawRoot) | Out-Null
[System.IO.Directory]::CreateDirectory($tempRoot) | Out-Null
Write-AtomicLines -Path $phaseMarker -Lines @(
    'PHASE=INIT',
    'TIMEOUT_SECONDS=1800',
    ('EPOCH_SECONDS={0}' -f [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()),
    'SOURCE=POWERSHELL_WATCHDOG_PRELAUNCH'
)

$runnerSha = Get-ExactSha256 -Path $runnerPath
$finalizerSha = Get-ExactSha256 -Path $finalizerTcl
$phaseBudgets = @{
    INIT                    = 1800
    REPORT_OWNERSHIP        = 900
    REPORT_TIMING           = 900
    REPORT_DRC              = 900
    REPORT_CDC              = 900
    REPORT_CLOCKS_RESOURCES = 900
    PRE_BIT_GATE            = 900
    WRITE_BITSTREAM         = 1800
    COMPLETE                = 30
    FAILED                  = 60
}
$phaseRanks = @{
    INIT                    = 0
    REPORT_OWNERSHIP        = 1
    REPORT_TIMING           = 2
    REPORT_DRC              = 3
    REPORT_CDC              = 4
    REPORT_CLOCKS_RESOURCES = 5
    PRE_BIT_GATE            = 6
    WRITE_BITSTREAM         = 7
    COMPLETE                = 8
}

$savedEnvironment = @{
    XILINX_LOCAL_USER_DATA = $env:XILINX_LOCAL_USER_DATA
    TEMP                   = $env:TEMP
    TMP                    = $env:TMP
}
$env:XILINX_LOCAL_USER_DATA = 'NO'
$env:TEMP = $tempRoot
$env:TMP = $tempRoot

$process = $null
$timedOut = $false
$timeoutPhase = $null
$watchdogReason = $null
$processTreeTerminated = $true
$globalBudgetSeconds = 9090
$globalStopwatch = [Diagnostics.Stopwatch]::StartNew()
$currentPhase = 'INIT'
$phaseStopwatch = [Diagnostics.Stopwatch]::StartNew()

try {
    $arguments = @(
        '-mode', 'batch',
        '-notrace',
        '-log', $vivadoLog,
        '-journal', $vivadoJournal,
        '-source', $finalizerTcl,
        '-tclargs',
        $resolvedEvidenceRoot,
        $resolvedBitstreamPath,
        $resolvedOfflineGate,
        $OfflineProtectionGateSha256.ToUpperInvariant(),
        $resolvedGroup9Gate,
        $Group9GateSha256.ToUpperInvariant(),
        $phaseMarker,
        $runnerPath,
        $runnerSha,
        $finalizerSha
    )
    $argumentText = ($arguments | ForEach-Object {
        ConvertTo-QuotedProcessArgument -Value ([string]$_)
    }) -join ' '
    $process = Start-Process `
        -FilePath $resolvedVivadoBat `
        -ArgumentList $argumentText `
        -WorkingDirectory $rawRoot `
        -WindowStyle Hidden `
        -RedirectStandardOutput $consoleOut `
        -RedirectStandardError $consoleErr `
        -PassThru

    while (-not $process.HasExited) {
        Start-Sleep -Seconds 1
        $process.Refresh()
        $observedPhase = Get-MarkerPhase -Path $phaseMarker
        if (-not [string]::IsNullOrWhiteSpace($observedPhase) -and
            $observedPhase -cne $currentPhase) {
            if (-not $phaseBudgets.ContainsKey($observedPhase)) {
                $timeoutPhase = "UNKNOWN_PHASE_$observedPhase"
                $watchdogReason = 'WATCHDOG_UNKNOWN_PHASE'
                $timedOut = $true
                $processTreeTerminated = Stop-ExactProcessTree -Process $process
                break
            }
            if ($observedPhase -cne 'FAILED' -and
                (-not $phaseRanks.ContainsKey($observedPhase) -or
                 -not $phaseRanks.ContainsKey($currentPhase) -or
                 [int]$phaseRanks[$observedPhase] -le [int]$phaseRanks[$currentPhase])) {
                $timeoutPhase = "PHASE_ORDER_${currentPhase}_TO_$observedPhase"
                $watchdogReason = 'WATCHDOG_PHASE_ORDER_VIOLATION'
                $timedOut = $true
                $processTreeTerminated = Stop-ExactProcessTree -Process $process
                break
            }
            $currentPhase = $observedPhase
            $phaseStopwatch.Restart()
        }
        $elapsed = $phaseStopwatch.Elapsed.TotalSeconds
        if ($globalStopwatch.Elapsed.TotalSeconds -gt $globalBudgetSeconds) {
            $timeoutPhase = 'GLOBAL'
            $watchdogReason = 'GLOBAL_TIMEOUT'
            $timedOut = $true
            $processTreeTerminated = Stop-ExactProcessTree -Process $process
            break
        }
        if ($elapsed -gt [double]$phaseBudgets[$currentPhase]) {
            $timeoutPhase = $currentPhase
            $watchdogReason = 'PHASE_TIMEOUT'
            $timedOut = $true
            $processTreeTerminated = Stop-ExactProcessTree -Process $process
            break
        }
    }

    if ($timedOut) {
        $bitState = if ((Test-Path -LiteralPath $resolvedBitstreamPath -PathType Leaf) -and
            (Get-Item -LiteralPath $resolvedBitstreamPath).Length -gt 0) {
            'YES_UNQUALIFIED'
        }
        else {
            'NO'
        }
        Write-AtomicLines -Path $finalResult -Lines @(
            'TASK=AHD_V41_G2B_LUT1_SIGNOFF_RECOVERY',
            'RESULT=BLOCKED',
            'ENGINEERING_GATE=BLOCKED',
            ("FIRST_BLOCKER={0}:{1}" -f $watchdogReason, $timeoutPhase),
            'PRE_BITSTREAM_HARD_GATE=FAIL',
            ("BITSTREAM_PRODUCED={0}" -f $bitState),
            'DEBUG_PROBES_PRODUCED=NO',
            'GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO',
            'HARDWARE_ACCESSED=NO'
        )
        Write-AtomicLines -Path $watchdogReceipt -Lines @(
            'RESULT=BLOCKED',
            ("TIMEOUT_PHASE={0}" -f $timeoutPhase),
            ("TIMEOUT_SECONDS={0}" -f $phaseBudgets[$currentPhase]),
            ("GLOBAL_TIMEOUT_SECONDS={0}" -f $globalBudgetSeconds),
            ("VIVADO_PROCESS_ID={0}" -f $process.Id),
            ("PROCESS_TREE_TERMINATED={0}" -f $(if ($processTreeTerminated) { 'YES' } else { 'NO' })),
            'HARDWARE_ACCESSED=NO'
        )
        if (-not $processTreeTerminated) {
            throw "Final-signoff watchdog blocked in $timeoutPhase and could not confirm process-tree termination"
        }
        throw "Final-signoff watchdog blocked in $timeoutPhase ($watchdogReason)"
    }

    $process.WaitForExit()
    $runtimeSeconds = $globalStopwatch.Elapsed.TotalSeconds
    if ($process.ExitCode -ne 0) {
        if (-not (Test-Path -LiteralPath $finalResult -PathType Leaf)) {
            Write-AtomicLines -Path $finalResult -Lines @(
                'TASK=AHD_V41_G2B_LUT1_SIGNOFF_RECOVERY',
                'RESULT=FAIL',
                'ENGINEERING_GATE=FAIL',
                ("FIRST_BLOCKER=VIVADO_EXIT_CODE_{0}" -f $process.ExitCode),
                'PRE_BITSTREAM_HARD_GATE=FAIL',
                'BITSTREAM_PRODUCED=NO',
                'DEBUG_PROBES_PRODUCED=NO',
                'GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO',
                'HARDWARE_ACCESSED=NO'
            )
        }
        throw "Vivado final signoff exited with code $($process.ExitCode)"
    }

    $resultValues = Read-KeyValueReceipt -Path $finalResult
    Require-ReceiptValue -Values $resultValues -Key RESULT -Expected PASS
    Require-ReceiptValue -Values $resultValues -Key ENGINEERING_GATE -Expected PASS
    Require-ReceiptValue -Values $resultValues -Key PRE_BITSTREAM_HARD_GATE -Expected PASS
    Require-ReceiptValue -Values $resultValues -Key BITSTREAM_PRODUCED -Expected YES
    Require-ReceiptValue -Values $resultValues -Key DEBUG_PROBES_PRODUCED -Expected NO
    Require-ReceiptValue -Values $resultValues -Key GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED -Expected NO
    Require-ReceiptValue -Values $resultValues -Key HARDWARE_ACCESSED -Expected NO
    if (-not (Test-Path -LiteralPath $resolvedBitstreamPath -PathType Leaf)) {
        throw "Final result says PASS but PRODUCT bitstream is absent"
    }
    $actualBitSha = Get-ExactSha256 -Path $resolvedBitstreamPath
    Require-ReceiptValue -Values $resultValues -Key BITSTREAM_SHA256 -Expected $actualBitSha
    if ((Get-ExactSha256 -Path $resolvedOfflineGate) -cne
        $OfflineProtectionGateSha256.ToUpperInvariant()) {
        throw 'Offline protection gate changed after Vivado completion'
    }
    if ((Get-ExactSha256 -Path $resolvedGroup9Gate) -cne
        $Group9GateSha256.ToUpperInvariant()) {
        throw 'Group-9 gate changed after Vivado completion'
    }
    if ((Get-ExactSha256 -Path $runnerPath) -cne $runnerSha -or
        (Get-ExactSha256 -Path $finalizerTcl) -cne $finalizerSha) {
        throw 'Final-signoff tool changed during execution'
    }

    Write-AtomicLines -Path $watchdogReceipt -Lines @(
        'RESULT=PASS',
        'ALL_PHASES_BOUNDED=YES',
        'INIT_TIMEOUT_SECONDS=1800',
        'REPORT_TIMEOUT_SECONDS=900',
        'WRITE_BITSTREAM_TIMEOUT_SECONDS=1800',
        ("GLOBAL_TIMEOUT_SECONDS={0}" -f $globalBudgetSeconds),
        ("TOTAL_RUNTIME_SECONDS={0:F3}" -f $runtimeSeconds),
        ("VIVADO_PROCESS_ID={0}" -f $process.Id),
        ("VIVADO_EXIT_CODE={0}" -f $process.ExitCode),
        ("FINALIZER_TCL_SHA256={0}" -f $finalizerSha),
        ("WATCHDOG_RUNNER_SHA256={0}" -f $runnerSha),
        ("BITSTREAM_SHA256={0}" -f $actualBitSha),
        'GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO',
        'HARDWARE_ACCESSED=NO'
    )
    Write-Output "G2B_LUT1_ROUTED_SIGNOFF_RECOVERY=PASS BITSTREAM_SHA256=$actualBitSha"
}
catch {
    $caughtMessage = $_.Exception.Message
    $cleanupTermination = $true
    if ($null -ne $process) {
        $cleanupTermination = Stop-ExactProcessTree -Process $process
    }
    if (-not $timedOut) {
        $bitState = if ((Test-Path -LiteralPath $resolvedBitstreamPath -PathType Leaf) -and
            (Get-Item -LiteralPath $resolvedBitstreamPath).Length -gt 0) {
            'YES_UNQUALIFIED'
        }
        else {
            'NO'
        }
        $preserveExistingFailure = $false
        if (Test-Path -LiteralPath $finalResult -PathType Leaf) {
            try {
                $existingResult = Read-KeyValueReceipt -Path $finalResult
                $preserveExistingFailure = $existingResult.ContainsKey('RESULT') -and
                    $existingResult['RESULT'] -in @('FAIL', 'BLOCKED')
            }
            catch {
                $preserveExistingFailure = $false
            }
        }
        if (-not $preserveExistingFailure) {
            Write-AtomicLines -Path $finalResult -Lines @(
                'TASK=AHD_V41_G2B_LUT1_SIGNOFF_RECOVERY',
                'RESULT=FAIL',
                'ENGINEERING_GATE=FAIL',
                ("FIRST_BLOCKER=WATCHDOG_OR_POSTVALIDATION:{0}" -f ($caughtMessage -replace '[\r\n=]', ' ')),
                'PRE_BITSTREAM_HARD_GATE=FAIL',
                ("BITSTREAM_PRODUCED={0}" -f $bitState),
                'DEBUG_PROBES_PRODUCED=NO',
                'GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO',
                'HARDWARE_ACCESSED=NO'
            )
        }
        Write-AtomicLines -Path $watchdogReceipt -Lines @(
            'RESULT=FAIL',
            ("FIRST_BLOCKER={0}" -f ($caughtMessage -replace '[\r\n=]', ' ')),
            ("PROCESS_TREE_TERMINATED={0}" -f $(if ($cleanupTermination) { 'YES' } else { 'NO' })),
            'HARDWARE_ACCESSED=NO'
        )
    }
    throw
}
finally {
    $env:XILINX_LOCAL_USER_DATA = $savedEnvironment.XILINX_LOCAL_USER_DATA
    $env:TEMP = $savedEnvironment.TEMP
    $env:TMP = $savedEnvironment.TMP
}
