[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('FormalBootstrap','ArmA','ArmB')]
    [string]$Phase,

    [Parameter(Mandatory)]
    [string]$ExpectedFullTargetPath,

    [string]$ProvenConfiguredImageReceiptPath = '',
    [string]$ExpectedReceiptSha256 = '',

    [ValidateRange(60,7200)]
    [int]$TimeoutSeconds = 1800
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$taskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$r6Root = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$settingsPath = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$programTclPath = Join-Path $PSScriptRoot 'program_once_mode_aware.tcl'
$observerParserPath = Join-Path $r6Root 'scripts\ProgramObserverCommon.ps1'
$selectorPath = Join-Path $r6Root 'scripts\select_r6_jtag_target.tcl'

$expectedSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$expectedVivadoSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'
$expectedProgramTclSha = '55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7'
$expectedObserverParserSha = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
$expectedSelectorSha = '3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE'
$canonicalTargetSuffix = '/Xilinx/80802026a98b01'

$formalBitPath = Join-Path $taskRoot '01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit'
$formalFilename = 'ahd_capture_v41_phase2_p1.bit'
$formalSize = 2192144L
$formalSha = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
$formalSourceCommit = 'fd32fcb65be3f1a59c569874195d1faeaf7d27e9'
$formalSourceTree = '417820c69c134161fcafae0947dc5976919814d1'

$r1eBitPath = Join-Path $taskRoot '01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_i2c_25khz_r1e_observability.bit'
$r1eFilename = 'ahd_capture_v41_i2c_25khz_r1e_observability.bit'
$r1eSize = 2192144L
$r1eSha = '0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9'
$r1eSourceCommit = 'f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd'
$r1eSourceTree = 'db8b5581a237e19905fd01c6d453793047bc3ba7'

$phaseSpec = switch ($Phase) {
    'FormalBootstrap' {
        [pscustomobject]@{
            EvidenceDirectory = Join-Path $taskRoot '07_FORMAL_BOOTSTRAP'
            ProgramRole = 'FORMAL_BOOTSTRAP'
            ObserverMode = 'BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM'
            BitPath = $formalBitPath
            Filename = $formalFilename
            Size = $formalSize
            Sha256 = $formalSha
            SourceCommit = $formalSourceCommit
            SourceTree = $formalSourceTree
            RequiredWaitSeconds = 5.0
        }
    }
    'ArmA' {
        [pscustomobject]@{
            EvidenceDirectory = Join-Path $taskRoot '08_ARM_A_R1E'
            ProgramRole = 'ARM_A_R1E'
            ObserverMode = 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'
            BitPath = $r1eBitPath
            Filename = $r1eFilename
            Size = $r1eSize
            Sha256 = $r1eSha
            SourceCommit = $r1eSourceCommit
            SourceTree = $r1eSourceTree
            RequiredWaitSeconds = 10.0
        }
    }
    'ArmB' {
        [pscustomobject]@{
            EvidenceDirectory = Join-Path $taskRoot '09_ARM_B_FORMAL'
            ProgramRole = 'ARM_B_FORMAL'
            ObserverMode = 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE'
            BitPath = $formalBitPath
            Filename = $formalFilename
            Size = $formalSize
            Sha256 = $formalSha
            SourceCommit = $formalSourceCommit
            SourceTree = $formalSourceTree
            RequiredWaitSeconds = 5.0
        }
    }
}

function Resolve-CheckedFile([string]$Path) {
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
}

function Assert-CmdToken([string]$Text) {
    if ($Text -notmatch '^[A-Za-z0-9_:\\\./-]+$') {
        throw "unsafe cmd.exe token: $Text"
    }
    return $Text
}

function Write-Utf8NoBom([string]$Path, [string[]]$Lines) {
    [IO.File]::WriteAllLines($Path, $Lines, [Text.UTF8Encoding]::new($false))
}

function Read-KeyValueReceipt([string]$Path) {
    $map = @{}
    foreach ($line in [IO.File]::ReadAllLines($Path)) {
        if ($line -match '^([A-Z0-9_]+)=(.*)$') {
            if ($map.ContainsKey($Matches[1])) { throw "duplicate receipt key $($Matches[1]): $Path" }
            $map[$Matches[1]] = $Matches[2]
        }
    }
    return $map
}

function Add-ObserverRecord([Collections.Generic.List[object]]$Records, [string]$Stream, [string]$Line) {
    $script:observerSequence++
    $Records.Add([pscustomobject]@{
        Sequence = $script:observerSequence
        Tick = [Diagnostics.Stopwatch]::GetTimestamp()
        Stream = $Stream
        Line = $Line
        Raw = $Line
    })
}

function Get-UniqueObserverValue([object[]]$Records, [string]$Key) {
    $prefix = $Key + '='
    $matches = @($Records | Where-Object { $_.Line.StartsWith($prefix, [StringComparison]::Ordinal) })
    if ($matches.Count -ne 1) { throw "observer key $Key count is $($matches.Count), expected 1" }
    return $matches[0].Line.Substring($prefix.Length)
}

$resolvedTaskRoot = (Resolve-Path -LiteralPath $taskRoot -ErrorAction Stop).Path
if ($resolvedTaskRoot -cne $taskRoot) { throw "unexpected task-root resolution: $resolvedTaskRoot" }
if ($ExpectedFullTargetPath -notmatch [regex]::Escape($canonicalTargetSuffix) + '$') {
    throw "expected full target path does not end in the exact canonical suffix: $ExpectedFullTargetPath"
}

$evidenceDirectory = (Resolve-Path -LiteralPath $phaseSpec.EvidenceDirectory -ErrorAction Stop).Path
if ($evidenceDirectory -cne $phaseSpec.EvidenceDirectory) {
    throw "unexpected phase evidence-directory resolution: $evidenceDirectory"
}

$configuredReceipt = 'NO_RECEIPT_REQUIRED'
$configuredReceiptPath = 'NOT_APPLICABLE'
$configuredReceiptSha = 'NOT_APPLICABLE'
if ($Phase -eq 'FormalBootstrap') {
    if ($ProvenConfiguredImageReceiptPath -or $ExpectedReceiptSha256) {
        throw 'FormalBootstrap does not accept a configured-image receipt'
    }
} else {
    if (-not $ProvenConfiguredImageReceiptPath -or $ExpectedReceiptSha256 -notmatch '^[0-9A-Fa-f]{64}$') {
        throw "$Phase requires a receipt path and exact SHA-256"
    }
    $configuredReceiptPath = Resolve-CheckedFile $ProvenConfiguredImageReceiptPath
    $configuredReceiptSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $configuredReceiptPath).Hash
    if ($configuredReceiptSha -cne $ExpectedReceiptSha256.ToUpperInvariant()) {
        throw "$Phase configured-image receipt SHA-256 mismatch"
    }
    $receiptMap = Read-KeyValueReceipt $configuredReceiptPath
    foreach ($requiredKey in @('RECEIPT_TYPE','RECEIPT_STATUS','R7_FULL_JTAG_TARGET_PATH')) {
        if (-not $receiptMap.ContainsKey($requiredKey)) { throw "configured-image receipt lacks $requiredKey" }
    }
    if ($receiptMap.RECEIPT_STATUS -cne 'PASS' -or
        $receiptMap.R7_FULL_JTAG_TARGET_PATH -cne $ExpectedFullTargetPath) {
        throw 'configured-image receipt status or full target path mismatch'
    }
    $configuredReceipt = $receiptMap.RECEIPT_TYPE
    if ($Phase -eq 'ArmA') {
        $expectedPath = Join-Path $taskRoot '07_FORMAL_BOOTSTRAP\FORMAL_READY_RECEIPT.txt'
        if ($configuredReceiptPath -cne $expectedPath -or $configuredReceipt -cne 'FORMAL_READY_RECEIPT') {
            throw 'ArmA requires the exact FORMAL_READY_RECEIPT path/type'
        }
    } else {
        $allowedReceiptPaths = @(
            (Join-Path $taskRoot '08_ARM_A_R1E\VALID_ARM_A_RECEIPT.txt'),
            (Join-Path $taskRoot '08_ARM_A_R1E\ARM_A_TERMINAL_SAFE_DONE1_RECEIPT.txt')
        )
        $allowedTypes = @('VALID_ARM_A_RECEIPT','ARM_A_TERMINAL_SAFE_DONE1_RECEIPT')
        if ($configuredReceiptPath -cnotin $allowedReceiptPaths -or $configuredReceipt -cnotin $allowedTypes) {
            throw 'ArmB requires an exact accepted Arm-A receipt path/type'
        }
        if ((Split-Path -LeafBase $configuredReceiptPath) -cne $configuredReceipt) {
            throw 'ArmB configured-image receipt filename/type mismatch'
        }
    }
}

$supervisorLog = Join-Path $evidenceDirectory 'PROGRAM_SUPERVISOR.log'
$vivadoLog = Join-Path $evidenceDirectory 'PROGRAM_VIVADO.log'
$vivadoJournal = Join-Path $evidenceDirectory 'PROGRAM_VIVADO.jou'
$timingReceipt = Join-Path $evidenceDirectory 'PROGRAM_TIMING_RECEIPT.txt'
foreach ($freshPath in @($supervisorLog, $vivadoLog, $vivadoJournal, $timingReceipt)) {
    if (Test-Path -LiteralPath $freshPath) { throw "phase output path must be fresh: $freshPath" }
}

$bit = Resolve-CheckedFile $phaseSpec.BitPath
$tcl = Resolve-CheckedFile $programTclPath
$observerParser = Resolve-CheckedFile $observerParserPath
$selector = Resolve-CheckedFile $selectorPath
$settings = Resolve-CheckedFile $settingsPath
$vivado = Resolve-CheckedFile $vivadoPath
$bitItem = Get-Item -LiteralPath $bit
$bitSha = (Get-FileHash -LiteralPath $bit -Algorithm SHA256).Hash
if ($bit -cne $phaseSpec.BitPath -or $bitItem.Name -cne $phaseSpec.Filename -or
    $bitItem.Length -ne $phaseSpec.Size -or $bitSha -cne $phaseSpec.Sha256) {
    throw "exact $Phase bit path/name/size/SHA-256 gate failed"
}
if ((Get-FileHash -LiteralPath $tcl -Algorithm SHA256).Hash -cne $expectedProgramTclSha) { throw 'mode-aware Tcl hash mismatch' }
if ((Get-FileHash -LiteralPath $observerParser -Algorithm SHA256).Hash -cne $expectedObserverParserSha) { throw 'frozen observer parser hash mismatch' }
if ((Get-FileHash -LiteralPath $selector -Algorithm SHA256).Hash -cne $expectedSelectorSha) { throw 'frozen R6 selector hash mismatch' }
if ((Get-FileHash -LiteralPath $settings -Algorithm SHA256).Hash -cne $expectedSettingsSha) { throw 'Vivado settings wrapper hash mismatch' }
if ((Get-FileHash -LiteralPath $vivado -Algorithm SHA256).Hash -cne $expectedVivadoSha) { throw 'Vivado launcher hash mismatch' }

. $observerParser

$command = @(
    'call', (Assert-CmdToken $settings), '&&', (Assert-CmdToken $vivado),
    '-mode', 'batch', '-notrace',
    '-log', (Assert-CmdToken $vivadoLog),
    '-journal', (Assert-CmdToken $vivadoJournal),
    '-source', (Assert-CmdToken $tcl), '-tclargs',
    (Assert-CmdToken $phaseSpec.ProgramRole),
    (Assert-CmdToken $phaseSpec.ObserverMode),
    (Assert-CmdToken $configuredReceipt),
    (Assert-CmdToken $ExpectedFullTargetPath),
    (Assert-CmdToken $bit),
    (Assert-CmdToken $phaseSpec.Filename),
    (Assert-CmdToken ([string]$phaseSpec.Size)),
    (Assert-CmdToken $phaseSpec.Sha256)
) -join ' '

$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = "$env:SystemRoot\System32\cmd.exe"
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.WorkingDirectory = $evidenceDirectory
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
                Add-ObserverRecord -Records $records -Stream 'STDOUT' -Line $line
                $stdoutTask = $process.StandardOutput.ReadLineAsync()
            }
            $madeProgress = $true
        }
        if (-not $stderrClosed -and $stderrTask.IsCompleted) {
            $line = $stderrTask.GetAwaiter().GetResult()
            if ($null -eq $line) { $stderrClosed = $true } else {
                Add-ObserverRecord -Records $records -Stream 'STDERR' -Line $line
                $stderrTask = $process.StandardError.ReadLineAsync()
            }
            $madeProgress = $true
        }
        $elapsedSeconds = ([Diagnostics.Stopwatch]::GetTimestamp() - $processStartTicks) / [Diagnostics.Stopwatch]::Frequency
        if ($elapsedSeconds -gt $TimeoutSeconds -and -not $process.HasExited) {
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

Add-ObserverRecord -Records $records -Stream 'SUPERVISOR' -Line ('TIMED_OUT=' + $(if ($timedOut) {'YES'} else {'NO'}))
Add-ObserverRecord -Records $records -Stream 'SUPERVISOR' -Line ('PROCESS_EXIT_CODE=' + $process.ExitCode)

$header = [string[]]@(
    ('PHASE={0}' -f $Phase),
    ('PROGRAM_ROLE={0}' -f $phaseSpec.ProgramRole),
    ('OBSERVER_MODE={0}' -f $phaseSpec.ObserverMode),
    ('PROVEN_CONFIGURED_IMAGE_RECEIPT={0}' -f $configuredReceipt),
    ('CONFIGURED_RECEIPT_PATH={0}' -f $configuredReceiptPath),
    ('CONFIGURED_RECEIPT_SHA256={0}' -f $configuredReceiptSha),
    ('R7_FULL_JTAG_TARGET_PATH={0}' -f $ExpectedFullTargetPath),
    ('BIT_PATH={0}' -f $bit),
    ('BIT_FILENAME={0}' -f $bitItem.Name),
    ('BIT_SIZE={0}' -f $bitItem.Length),
    ('BIT_SHA256={0}' -f $bitSha),
    ('SOURCE_COMMIT={0}' -f $phaseSpec.SourceCommit),
    ('SOURCE_TREE={0}' -f $phaseSpec.SourceTree),
    ('PROGRAM_TCL_PATH={0}' -f $tcl),
    ('PROGRAM_TCL_SHA256={0}' -f $expectedProgramTclSha),
    ('OBSERVER_PARSER_PATH={0}' -f $observerParser),
    ('OBSERVER_PARSER_SHA256={0}' -f $expectedObserverParserSha),
    ('TARGET_SELECTOR_PATH={0}' -f $selector),
    ('TARGET_SELECTOR_SHA256={0}' -f $expectedSelectorSha),
    ('VIVADO_LOG_PATH={0}' -f $vivadoLog),
    ('VIVADO_JOURNAL_PATH={0}' -f $vivadoJournal),
    ('STOPWATCH_FREQUENCY={0}' -f [Diagnostics.Stopwatch]::Frequency),
    ('PROCESS_START_UTC={0}' -f $processStartUtc),
    ('PROCESS_END_UTC={0}' -f $processEndUtc),
    ('PROCESS_START_TICKS={0}' -f $processStartTicks),
    ('PROCESS_END_TICKS={0}' -f $processEndTicks)
)
$recordLines = @($records | ForEach-Object {
    'SEQ={0} TICK={1} STREAM={2} LINE={3}' -f $_.Sequence, $_.Tick, $_.Stream, $_.Line
})
Write-Utf8NoBom -Path $supervisorLog -Lines @($header + $recordLines)

$result = Test-I25ProgramObserver -Records $records.ToArray()
$resultLines = [string[]]@(
    ('PROGRAM_EOS={0}' -f $result.PROGRAM_EOS),
    ('PROGRAM_DONE={0}' -f $result.PROGRAM_DONE),
    ('PROGRAM_RESULT={0}' -f $result.CLASSIFICATION),
    ('PROGRAM_INVOCATIONS={0}' -f $result.PROGRAM_INVOCATION_CONSUMED_COUNT),
    'PROGRAM_RETRIES=0',
    ('COUNT_GATE={0}' -f $result.COUNT_GATE),
    ('ORDER_GATE={0}' -f $result.ORDER_GATE),
    ('PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT={0}' -f $result.PROGRAM_INVOCATION_CONSUMED_COUNT),
    ('VENDOR_STARTUP_HIGH_COUNT={0}' -f $result.VENDOR_STARTUP_HIGH_COUNT),
    ('PROGRAM_RETURN_MARKER_COUNT={0}' -f $result.PROGRAM_RETURN_MARKER_COUNT),
    ('FRESH_DONE_MARKER_COUNT={0}' -f $result.FRESH_DONE_MARKER_COUNT)
)
[IO.File]::AppendAllLines($supervisorLog, $resultLines, [Text.UTF8Encoding]::new($false))

try {
    $observedRole = Get-UniqueObserverValue $records.ToArray() 'PROGRAM_ROLE'
    $observedMode = Get-UniqueObserverValue $records.ToArray() 'OBSERVER_MODE'
    $observedReceipt = Get-UniqueObserverValue $records.ToArray() 'PROVEN_CONFIGURED_IMAGE_RECEIPT'
    $observedTarget = Get-UniqueObserverValue $records.ToArray() 'R7_FULL_JTAG_TARGET_PATH'
    $precondition = Get-UniqueObserverValue $records.ToArray() 'PROGRAM_PRECONDITION'
    $sampleCount = Get-UniqueObserverValue $records.ToArray() 'PREPROGRAM_DONE_SAMPLE_COUNT'
    $samples = Get-UniqueObserverValue $records.ToArray() 'PREPROGRAM_DONE_SAMPLES'
    $readable = Get-UniqueObserverValue $records.ToArray() 'PREPROGRAM_DONE_READABLE'
    $stable = Get-UniqueObserverValue $records.ToArray() 'PREPROGRAM_DONE_STABLE'
    $identityStable = Get-UniqueObserverValue $records.ToArray() 'TARGET_PART_IDCODE_STABLE'
    $preDoneValue = Get-UniqueObserverValue $records.ToArray() 'PREPROGRAM_DONE_VALUE'
    if ($observedRole -cne $phaseSpec.ProgramRole -or $observedMode -cne $phaseSpec.ObserverMode -or
        $observedReceipt -cne $configuredReceipt -or $observedTarget -cne $ExpectedFullTargetPath -or
        $precondition -cne 'PASS' -or $sampleCount -cne '5' -or
        $readable -cne 'YES_5_OF_5' -or $stable -cne 'YES' -or $identityStable -cne 'YES') {
        throw 'mode-aware pre-program observer receipt mismatch'
    }
    $expectedSamples = $(if ($phaseSpec.ObserverMode -ceq 'TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE') {
        '1,1,1,1,1'
    } elseif ($preDoneValue -ceq '0') {
        '0,0,0,0,0'
    } else {
        '1,1,1,1,1'
    })
    if ($samples -cne $expectedSamples -or $preDoneValue -cnotin @('0','1')) {
        throw 'mode-aware pre-program DONE sample/value mismatch'
    }
} catch {
    [IO.File]::AppendAllLines($supervisorLog, [string[]]@('MODE_AWARE_PREPROGRAM_GATE=FAIL', ('MODE_AWARE_PREPROGRAM_ERROR=' + $_.Exception.Message)), [Text.UTF8Encoding]::new($false))
    throw
}

if ($result.CLASSIFICATION -cne 'PASS_STARTUP_HIGH_DONE_1') {
    [IO.File]::AppendAllLines($supervisorLog, [string[]]@('PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'), [Text.UTF8Encoding]::new($false))
    $resultLines
    'PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'
    exit 1
}

$referenceTicks = [Math]::Max([long]$result.PROGRAM_RETURN_MARKER_TICKS, [long]$result.FRESH_DONE_MARKER_TICKS)
[IO.File]::AppendAllLines($supervisorLog, [string[]]@(
    'MODE_AWARE_PREPROGRAM_GATE=PASS',
    ('PREPROGRAM_DONE_SAMPLES={0}' -f $samples),
    ('PREPROGRAM_DONE_VALUE={0}' -f $preDoneValue),
    'PROGRAM_SUPERVISOR_GATE=PASS_PENDING_INDEPENDENT_DONE_AND_WAIT'
), [Text.UTF8Encoding]::new($false))
$supervisorLogSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $supervisorLog).Hash

$timingLines = [string[]]@(
    ('PHASE={0}' -f $Phase),
    ('PROGRAM_ROLE={0}' -f $phaseSpec.ProgramRole),
    ('OBSERVER_MODE={0}' -f $phaseSpec.ObserverMode),
    ('PROVEN_CONFIGURED_IMAGE_RECEIPT={0}' -f $configuredReceipt),
    ('CONFIGURED_RECEIPT_SHA256={0}' -f $configuredReceiptSha),
    ('R7_FULL_JTAG_TARGET_PATH={0}' -f $ExpectedFullTargetPath),
    ('BIT_SHA256={0}' -f $bitSha),
    ('PROGRAM_TCL_SHA256={0}' -f $expectedProgramTclSha),
    ('OBSERVER_PARSER_SHA256={0}' -f $expectedObserverParserSha),
    ('TARGET_SELECTOR_SHA256={0}' -f $expectedSelectorSha),
    ('PROGRAM_SUPERVISOR_LOG_SHA256={0}' -f $supervisorLogSha),
    ('PROGRAM_RESULT={0}' -f $result.CLASSIFICATION),
    'PROGRAM_INVOCATIONS=1',
    'PROGRAM_RETRIES=0',
    'MODE_AWARE_PREPROGRAM_GATE=PASS',
    ('PREPROGRAM_DONE_SAMPLES={0}' -f $samples),
    ('PREPROGRAM_DONE_VALUE={0}' -f $preDoneValue),
    ('PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT={0}' -f $result.PROGRAM_INVOCATION_CONSUMED_COUNT),
    ('STOPWATCH_FREQUENCY={0}' -f [Diagnostics.Stopwatch]::Frequency),
    ('PROGRAM_RETURN_MARKER_TICKS={0}' -f $result.PROGRAM_RETURN_MARKER_TICKS),
    ('FRESH_DONE_MARKER_TICKS={0}' -f $result.FRESH_DONE_MARKER_TICKS),
    ('WAIT_REFERENCE_TICKS={0}' -f $referenceTicks),
    ('REQUIRED_MINIMUM_WAIT_SECONDS={0}' -f ([double]$phaseSpec.RequiredWaitSeconds).ToString('F9', [Globalization.CultureInfo]::InvariantCulture)),
    ('TIMING_RECEIPT_CREATED_UTC={0}' -f [DateTime]::UtcNow.ToString('o')),
    'TIMING_RECEIPT_STATUS=PASS_IMMUTABLE_WAIT_INPUT'
)
Write-Utf8NoBom -Path $timingReceipt -Lines $timingLines

$resultLines
'MODE_AWARE_PREPROGRAM_GATE=PASS'
('PREPROGRAM_DONE_SAMPLES={0}' -f $samples)
('PREPROGRAM_DONE_VALUE={0}' -f $preDoneValue)
('PROGRAM_TIMING_RECEIPT={0}' -f $timingReceipt)
('PROGRAM_TIMING_RECEIPT_SHA256={0}' -f (Get-FileHash -Algorithm SHA256 -LiteralPath $timingReceipt).Hash)
'PROGRAM_SUPERVISOR_GATE=PASS_PENDING_INDEPENDENT_DONE_AND_WAIT'
