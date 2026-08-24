[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')]
    [string]$PhaseToken,

    [Parameter(Mandatory)]
    [string]$BindingPath,

    [string]$ConfiguredImageReceiptPath = '',

    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedConfiguredImageReceiptSha256 = '',

    [ValidateRange(60,7200)]
    [int]$TimeoutSeconds = 1800
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture
. (Join-Path $PSScriptRoot 'R1fCampaignCommon.ps1')

function Assert-CmdToken([string]$Text) {
    if ($Text -notmatch '^[A-Za-z0-9_:\\\./-]+$') { throw "unsafe cmd.exe token: $Text" }
    return $Text
}

function Add-ObserverRecord {
    param(
        [Parameter(Mandatory)][Collections.Generic.List[object]]$Records,
        [Parameter(Mandatory)][string]$Stream,
        [Parameter(Mandatory)][string]$Line
    )
    $script:observerSequence++
    $Records.Add([pscustomobject]@{
        Sequence = $script:observerSequence
        Tick = [Diagnostics.Stopwatch]::GetTimestamp()
        Stream = $Stream
        Line = $Line
        Raw = $Line
    })
}

function Get-UniqueObserverValue([object[]]$Records,[string]$Key) {
    $prefix = $Key + '='
    $matches = @($Records | Where-Object { $_.Line.StartsWith($prefix,[StringComparison]::Ordinal) })
    if ($matches.Count -ne 1) { throw "observer key $Key count is $($matches.Count), expected 1" }
    return $matches[0].Line.Substring($prefix.Length)
}

$binding = Get-R1fBindingDocument -BindingPath $BindingPath
Assert-R1fAcceptedToolSet
$phase = Get-R1fPhaseSpec $PhaseToken
$phaseDirectory = Assert-R1fPhaseDirectory $phase
$image = Get-R1fImageBinding -Document $binding -PhaseSpec $phase
Assert-R1fProgramBudget $phase

$configuredReceiptLiteral = 'NO_RECEIPT_REQUIRED'
$configuredReceiptResolved = 'NOT_APPLICABLE'
$configuredReceiptSha = 'NOT_APPLICABLE'
if ($PhaseToken -eq 'Bootstrap') {
    if ($ConfiguredImageReceiptPath -or $ExpectedConfiguredImageReceiptSha256) {
        throw 'Bootstrap does not accept a configured-image receipt'
    }
    $formalStartReceipt = Join-Path $script:R1fPrecheckRoot 'FORMAL_START_READY_RECEIPT.txt'
    if (Test-Path -LiteralPath $formalStartReceipt) {
        throw 'conditional bootstrap is forbidden after an exact formal-start receipt already exists'
    }
    $startGatePath = Join-Path $script:R1fPrecheckRoot 'R1F_FRESH_FORMAL_START_GATE.txt'
    if (-not (Test-Path -LiteralPath $startGatePath -PathType Leaf)) {
        throw 'conditional bootstrap requires the fresh read-only start-state gate'
    }
    $startGateText = [IO.File]::ReadAllText($startGatePath)
    if ([regex]::Matches($startGateText,'(?m)^FORMAL_START_GATE=BOOTSTRAP_REQUIRED_SAFE\r?$').Count -ne 1 -or
        [regex]::Matches($startGateText,'(?m)^READ_ONLY_GATE=YES\r?$').Count -ne 1) {
        throw 'fresh start-state gate does not authorize the one conditional bootstrap'
    }
} else {
    if (-not $ConfiguredImageReceiptPath -or -not $ExpectedConfiguredImageReceiptSha256) {
        throw "$PhaseToken requires an exact configured-image receipt path and SHA-256"
    }
    $receipt = Read-R1fReceipt -Path $ConfiguredImageReceiptPath -ExpectedSha256 $ExpectedConfiguredImageReceiptSha256
    $configuredReceiptResolved = $receipt.Path
    $configuredReceiptSha = $receipt.Sha256
    if ($receipt.Fields.R1F_FULL_JTAG_TARGET_PATH -cne [string]$binding.selectedFullJtagTargetPath) {
        throw 'configured-image receipt selected-target path mismatch'
    }
    $expectedReceipt = Get-R1fExpectedReceiptPath $PhaseToken
    $allowedReceipt = @($expectedReceipt)
    if ($phase.Kind -ceq 'ARM_B') {
        $allowedReceipt += Join-Path (Split-Path -Parent $expectedReceipt) 'ARM_A_TERMINAL_SAFE_DONE1_RECEIPT.txt'
    }
    if ($configuredReceiptResolved -cnotin $allowedReceipt) {
        throw "configured-image receipt is not the exact frozen predecessor for $PhaseToken"
    }
    $configuredReceiptLiteral = [string]$receipt.Fields.RECEIPT_TYPE
    if ($phase.Kind -ceq 'ARM_A' -and $configuredReceiptLiteral -cne 'FORMAL_READY_RECEIPT') {
        throw "$PhaseToken requires FORMAL_READY_RECEIPT"
    }
    if ($phase.Kind -ceq 'ARM_B' -and
        $configuredReceiptLiteral -cnotin @('VALID_ARM_A_RECEIPT','ARM_A_TERMINAL_SAFE_DONE1_RECEIPT')) {
        throw "$PhaseToken requires an accepted Arm-A receipt"
    }
}

$reservationPath = Join-Path $phaseDirectory 'PROGRAM_ATTEMPT_RESERVATION.txt'
$supervisorLog = Join-Path $phaseDirectory 'PROGRAM_SUPERVISOR.log'
$vivadoLog = Join-Path $phaseDirectory 'PROGRAM_VIVADO.log'
$vivadoJournal = Join-Path $phaseDirectory 'PROGRAM_VIVADO.jou'
$timingReceipt = Join-Path $phaseDirectory 'PROGRAM_TIMING_RECEIPT.txt'
foreach ($path in @($reservationPath,$supervisorLog,$vivadoLog,$vivadoJournal,$timingReceipt)) {
    if (Test-Path -LiteralPath $path) { throw "one-shot program output path is not fresh: $path" }
}

$programTcl = $script:R1fAcceptedTools.ModeAwareObserverTcl.Path
$observerParser = $script:R1fAcceptedTools.ProgramObserverParser.Path
$settingsPath = $script:R1fAcceptedTools.VivadoSettings.Path
$vivadoPath = $script:R1fAcceptedTools.VivadoLauncher.Path
$bitPath = (Resolve-Path -LiteralPath ([string]$image.path) -ErrorAction Stop).Path
$requiredWait = if ($phase.Image -ceq 'R1F') {
    [Math]::Max([double]$phase.RequiredWaitFloorSeconds,[double]$image.requiredWaitSeconds)
} else {
    [double]$phase.RequiredWaitFloorSeconds
}

# The reservation is written before the process launch and is never removed.
# A failed or interrupted call therefore cannot silently become a retry.
Write-R1fUtf8NoBom -Path $reservationPath -Lines @(
    "PHASE_TOKEN=$PhaseToken",
    "PROGRAM_ROLE=$($phase.ProgramRole)",
    "OBSERVER_MODE=$($phase.ObserverMode)",
    "PROGRAM_RETRY_AUTHORIZED=NO",
    "PROGRAM_INVOCATION_GLOBAL_MAX=$script:R1fMaximumPrograms",
    "BIT_PATH=$bitPath",
    "BIT_SHA256=$([string]$image.sha256)",
    "CONFIGURED_RECEIPT_PATH=$configuredReceiptResolved",
    "CONFIGURED_RECEIPT_SHA256=$configuredReceiptSha",
    "RESERVATION_UTC=$([DateTime]::UtcNow.ToString('o'))",
    'RESERVATION_IMMUTABLE=YES'
)

. $observerParser

$command = @(
    'call',(Assert-CmdToken $settingsPath),'&&',(Assert-CmdToken $vivadoPath),
    '-mode','batch','-notrace',
    '-log',(Assert-CmdToken $vivadoLog),
    '-journal',(Assert-CmdToken $vivadoJournal),
    '-source',(Assert-CmdToken $programTcl),'-tclargs',
    (Assert-CmdToken $phase.ProgramRole),
    (Assert-CmdToken $phase.ObserverMode),
    (Assert-CmdToken $configuredReceiptLiteral),
    (Assert-CmdToken ([string]$binding.selectedFullJtagTargetPath)),
    (Assert-CmdToken $bitPath),
    (Assert-CmdToken ([string]$image.filename)),
    (Assert-CmdToken ([string][long]$image.bytes)),
    (Assert-CmdToken ([string]$image.sha256))
) -join ' '

$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = "$env:SystemRoot\System32\cmd.exe"
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.WorkingDirectory = $phaseDirectory
$psi.Arguments = '/d /s /c "' + $command + '"'

$process = [Diagnostics.Process]::new()
$process.StartInfo = $psi
$records = [Collections.Generic.List[object]]::new()
[long]$script:observerSequence = 0
$timedOut = $false
$processStartTicks = [Diagnostics.Stopwatch]::GetTimestamp()
$processStartUtc = [DateTime]::UtcNow.ToString('o')
try {
    if (-not $process.Start()) { throw 'failed to start the one Vivado programming process' }
    $stdoutTask = $process.StandardOutput.ReadLineAsync()
    $stderrTask = $process.StandardError.ReadLineAsync()
    $stdoutClosed = $false
    $stderrClosed = $false
    while (-not ($process.HasExited -and $stdoutClosed -and $stderrClosed)) {
        $madeProgress = $false
        if (-not $stdoutClosed -and $stdoutTask.IsCompleted) {
            $line = $stdoutTask.GetAwaiter().GetResult()
            if ($null -eq $line) { $stdoutClosed = $true } else {
                Add-ObserverRecord -Records $records -Stream STDOUT -Line $line
                $stdoutTask = $process.StandardOutput.ReadLineAsync()
            }
            $madeProgress = $true
        }
        if (-not $stderrClosed -and $stderrTask.IsCompleted) {
            $line = $stderrTask.GetAwaiter().GetResult()
            if ($null -eq $line) { $stderrClosed = $true } else {
                Add-ObserverRecord -Records $records -Stream STDERR -Line $line
                $stderrTask = $process.StandardError.ReadLineAsync()
            }
            $madeProgress = $true
        }
        $elapsed = ([Diagnostics.Stopwatch]::GetTimestamp() - $processStartTicks) / [Diagnostics.Stopwatch]::Frequency
        if ($elapsed -gt $TimeoutSeconds -and -not $process.HasExited) {
            $timedOut = $true
            try { $process.Kill($true) } catch { try { $process.Kill() } catch {} }
            break
        }
        if (-not $madeProgress) { Start-Sleep -Milliseconds 5 }
    }
    $process.WaitForExit()
} finally {
    $processEndTicks = [Diagnostics.Stopwatch]::GetTimestamp()
    $processEndUtc = [DateTime]::UtcNow.ToString('o')
}

Add-ObserverRecord -Records $records -Stream SUPERVISOR -Line ('TIMED_OUT=' + $(if ($timedOut) {'YES'} else {'NO'}))
Add-ObserverRecord -Records $records -Stream SUPERVISOR -Line ('PROCESS_EXIT_CODE=' + $process.ExitCode)
$header = @(
    "PHASE_TOKEN=$PhaseToken",
    "PROGRAM_ROLE=$($phase.ProgramRole)",
    "OBSERVER_MODE=$($phase.ObserverMode)",
    "PROVEN_CONFIGURED_IMAGE_RECEIPT=$configuredReceiptLiteral",
    "CONFIGURED_RECEIPT_PATH=$configuredReceiptResolved",
    "CONFIGURED_RECEIPT_SHA256=$configuredReceiptSha",
    "R1F_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    "BIT_PATH=$bitPath",
    "BIT_FILENAME=$([string]$image.filename)",
    "BIT_SIZE=$([long]$image.bytes)",
    "BIT_SHA256=$([string]$image.sha256)",
    "SOURCE_COMMIT=$([string]$image.sourceCommit)",
    "SOURCE_TREE=$([string]$image.sourceTree)",
    "PROGRAM_TCL_PATH=$programTcl",
    "PROGRAM_TCL_SHA256=$($script:R1fAcceptedTools.ModeAwareObserverTcl.Sha256)",
    "OBSERVER_PARSER_PATH=$observerParser",
    "OBSERVER_PARSER_SHA256=$($script:R1fAcceptedTools.ProgramObserverParser.Sha256)",
    "TARGET_SELECTOR_SHA256=$($script:R1fAcceptedTools.SelectedTargetSelector.Sha256)",
    "STOPWATCH_FREQUENCY=$([Diagnostics.Stopwatch]::Frequency)",
    "PROCESS_START_UTC=$processStartUtc",
    "PROCESS_END_UTC=$processEndUtc",
    "PROCESS_START_TICKS=$processStartTicks",
    "PROCESS_END_TICKS=$processEndTicks"
)
$recordLines = @($records | ForEach-Object {
    'SEQ={0} TICK={1} STREAM={2} LINE={3}' -f $_.Sequence,$_.Tick,$_.Stream,$_.Line
})
Write-R1fUtf8NoBom -Path $supervisorLog -Lines @($header + $recordLines)

$result = Test-I25ProgramObserver -Records $records.ToArray()
$resultLines = @(
    "PROGRAM_RESULT=$($result.CLASSIFICATION)",
    "PROGRAM_INVOCATIONS=$($result.PROGRAM_INVOCATION_CONSUMED_COUNT)",
    'PROGRAM_RETRIES=0',
    "COUNT_GATE=$($result.COUNT_GATE)",
    "ORDER_GATE=$($result.ORDER_GATE)",
    "VENDOR_STARTUP_HIGH_COUNT=$($result.VENDOR_STARTUP_HIGH_COUNT)",
    "PROGRAM_RETURN_MARKER_COUNT=$($result.PROGRAM_RETURN_MARKER_COUNT)",
    "FRESH_DONE_MARKER_COUNT=$($result.FRESH_DONE_MARKER_COUNT)"
)
[IO.File]::AppendAllLines($supervisorLog,$resultLines,[Text.UTF8Encoding]::new($false))

try {
    $observedRole = Get-UniqueObserverValue $records.ToArray() PROGRAM_ROLE
    $observedMode = Get-UniqueObserverValue $records.ToArray() OBSERVER_MODE
    $observedReceipt = Get-UniqueObserverValue $records.ToArray() PROVEN_CONFIGURED_IMAGE_RECEIPT
    $observedTarget = Get-UniqueObserverValue $records.ToArray() R7_FULL_JTAG_TARGET_PATH
    $precondition = Get-UniqueObserverValue $records.ToArray() PROGRAM_PRECONDITION
    $sampleCount = Get-UniqueObserverValue $records.ToArray() PREPROGRAM_DONE_SAMPLE_COUNT
    $samples = Get-UniqueObserverValue $records.ToArray() PREPROGRAM_DONE_SAMPLES
    $readable = Get-UniqueObserverValue $records.ToArray() PREPROGRAM_DONE_READABLE
    $stable = Get-UniqueObserverValue $records.ToArray() PREPROGRAM_DONE_STABLE
    $identityStable = Get-UniqueObserverValue $records.ToArray() TARGET_PART_IDCODE_STABLE
    $preDone = Get-UniqueObserverValue $records.ToArray() PREPROGRAM_DONE_VALUE
    if ($observedRole -cne $phase.ProgramRole -or $observedMode -cne $phase.ObserverMode -or
        $observedReceipt -cne $configuredReceiptLiteral -or
        $observedTarget -cne [string]$binding.selectedFullJtagTargetPath -or
        $precondition -cne 'PASS' -or $sampleCount -cne '5' -or
        $readable -cne 'YES_5_OF_5' -or $stable -cne 'YES' -or $identityStable -cne 'YES') {
        throw 'mode-aware pre-program observer receipt mismatch'
    }
    if ($phase.ObserverMode -ceq 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE') {
        if ($samples -cne '1,1,1,1,1' -or $preDone -cne '1') {
            throw 'transition-mode pre-program DONE is not exact stable 1'
        }
    } elseif ($samples -cnotin @('0,0,0,0,0','1,1,1,1,1') -or $preDone -cnotin @('0','1')) {
        throw 'bootstrap pre-program DONE is not readable and stable'
    }
} catch {
    [IO.File]::AppendAllLines($supervisorLog,@('MODE_AWARE_PREPROGRAM_GATE=FAIL',"MODE_AWARE_PREPROGRAM_ERROR=$($_.Exception.Message)"),[Text.UTF8Encoding]::new($false))
    throw
}

if ($result.CLASSIFICATION -cne 'PASS_STARTUP_HIGH_DONE_1') {
    [IO.File]::AppendAllLines($supervisorLog,@('PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'),[Text.UTF8Encoding]::new($false))
    $resultLines
    'PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'
    exit 1
}

$referenceTicks = [Math]::Max([long]$result.PROGRAM_RETURN_MARKER_TICKS,[long]$result.FRESH_DONE_MARKER_TICKS)
$supervisorSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $supervisorLog).Hash
Write-R1fUtf8NoBom -Path $timingReceipt -Lines @(
    "PHASE_TOKEN=$PhaseToken",
    "PROGRAM_ROLE=$($phase.ProgramRole)",
    "OBSERVER_MODE=$($phase.ObserverMode)",
    "PROVEN_CONFIGURED_IMAGE_RECEIPT=$configuredReceiptLiteral",
    "CONFIGURED_RECEIPT_SHA256=$configuredReceiptSha",
    "R1F_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    "BIT_SHA256=$([string]$image.sha256)",
    "PROGRAM_TCL_SHA256=$($script:R1fAcceptedTools.ModeAwareObserverTcl.Sha256)",
    "OBSERVER_PARSER_SHA256=$($script:R1fAcceptedTools.ProgramObserverParser.Sha256)",
    "TARGET_SELECTOR_SHA256=$($script:R1fAcceptedTools.SelectedTargetSelector.Sha256)",
    "PROGRAM_SUPERVISOR_LOG_SHA256=$supervisorSha",
    'PROGRAM_RESULT=PASS_STARTUP_HIGH_DONE_1',
    'PROGRAM_INVOCATIONS=1',
    'PROGRAM_RETRIES=0',
    'MODE_AWARE_PREPROGRAM_GATE=PASS',
    "PREPROGRAM_DONE_SAMPLES=$samples",
    "PREPROGRAM_DONE_VALUE=$preDone",
    'PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT=1',
    "STOPWATCH_FREQUENCY=$([Diagnostics.Stopwatch]::Frequency)",
    "PROGRAM_RETURN_MARKER_TICKS=$($result.PROGRAM_RETURN_MARKER_TICKS)",
    "FRESH_DONE_MARKER_TICKS=$($result.FRESH_DONE_MARKER_TICKS)",
    "WAIT_REFERENCE_TICKS=$referenceTicks",
    ('REQUIRED_MINIMUM_WAIT_SECONDS={0}' -f $requiredWait.ToString('F9',[Globalization.CultureInfo]::InvariantCulture)),
    "TIMING_RECEIPT_CREATED_UTC=$([DateTime]::UtcNow.ToString('o'))",
    'TIMING_RECEIPT_STATUS=PASS_IMMUTABLE_WAIT_INPUT'
)

$resultLines
'MODE_AWARE_PREPROGRAM_GATE=PASS'
"PROGRAM_TIMING_RECEIPT=$timingReceipt"
"PROGRAM_TIMING_RECEIPT_SHA256=$((Get-FileHash -Algorithm SHA256 -LiteralPath $timingReceipt).Hash)"
'PROGRAM_SUPERVISOR_GATE=PASS_PENDING_INDEPENDENT_DONE_AND_WAIT'
