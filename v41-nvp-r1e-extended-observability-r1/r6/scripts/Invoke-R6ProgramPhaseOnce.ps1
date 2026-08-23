[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [ValidateSet('FormalBootstrap','ArmA','ArmB')]
    [string]$Phase,

    [ValidateRange(60,7200)]
    [int]$TimeoutSeconds = 1800
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$taskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$settingsPath = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$programTclPath = Join-Path $PSScriptRoot 'program_once_startup_high_done_r6_selected.tcl'
$observerParserPath = Join-Path $PSScriptRoot 'ProgramObserverCommon.ps1'

$expectedSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$expectedVivadoSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'
$expectedProgramTclSha = '00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC'
$expectedObserverParserSha = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'

$formalBitPath = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit'
$formalFilename = 'ahd_capture_v41_phase2_p1.bit'
$formalSize = 2192144L
$formalSha = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
$formalSourceCommit = 'fd32fcb65be3f1a59c569874195d1faeaf7d27e9'
$formalSourceTree = '417820c69c134161fcafae0947dc5976919814d1'

$r1eBitPath = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_i2c_25khz_r1e_observability.bit'
$r1eFilename = 'ahd_capture_v41_i2c_25khz_r1e_observability.bit'
$r1eSize = 2192144L
$r1eSha = '0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9'
$r1eSourceCommit = 'f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd'
$r1eSourceTree = 'db8b5581a237e19905fd01c6d453793047bc3ba7'

$phaseSpec = switch ($Phase) {
    'FormalBootstrap' {
        [pscustomobject]@{
            EvidenceDirectory = Join-Path $taskRoot '07_FORMAL_BOOTSTRAP'
            TclRole = 'ARM_B_FORMAL_50KHZ'
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
            TclRole = 'ARM_A_25KHZ'
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
            TclRole = 'ARM_B_FORMAL_50KHZ'
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

$resolvedTaskRoot = (Resolve-Path -LiteralPath $taskRoot -ErrorAction Stop).Path
if ($resolvedTaskRoot -cne $taskRoot) {
    throw "unexpected task-root resolution: $resolvedTaskRoot"
}

$evidenceDirectory = (Resolve-Path -LiteralPath $phaseSpec.EvidenceDirectory -ErrorAction Stop).Path
if ($evidenceDirectory -cne $phaseSpec.EvidenceDirectory) {
    throw "unexpected phase evidence-directory resolution: $evidenceDirectory"
}

$supervisorLog = Join-Path $evidenceDirectory 'PROGRAM_SUPERVISOR.log'
$vivadoLog = Join-Path $evidenceDirectory 'PROGRAM_VIVADO.log'
$vivadoJournal = Join-Path $evidenceDirectory 'PROGRAM_VIVADO.jou'
$waitReceipt = Join-Path $evidenceDirectory 'PROGRAM_WAIT_RECEIPT.txt'
foreach ($freshPath in @($supervisorLog, $vivadoLog, $vivadoJournal, $waitReceipt)) {
    if (Test-Path -LiteralPath $freshPath) {
        throw "phase output path must be fresh: $freshPath"
    }
}

$bit = Resolve-CheckedFile $phaseSpec.BitPath
$tcl = Resolve-CheckedFile $programTclPath
$observerParser = Resolve-CheckedFile $observerParserPath
$settings = Resolve-CheckedFile $settingsPath
$vivado = Resolve-CheckedFile $vivadoPath

$bitItem = Get-Item -LiteralPath $bit
$bitSha = (Get-FileHash -LiteralPath $bit -Algorithm SHA256).Hash
if ($bit -cne $phaseSpec.BitPath -or
    $bitItem.Name -cne $phaseSpec.Filename -or
    $bitItem.Length -ne $phaseSpec.Size -or
    $bitSha -cne $phaseSpec.Sha256) {
    throw "exact $Phase bit path/name/size/SHA-256 gate failed"
}
if ((Get-FileHash -LiteralPath $tcl -Algorithm SHA256).Hash -cne $expectedProgramTclSha) {
    throw 'accepted single-program Tcl hash mismatch'
}
if ((Get-FileHash -LiteralPath $observerParser -Algorithm SHA256).Hash -cne $expectedObserverParserSha) {
    throw 'accepted program-observer parser hash mismatch'
}
if ((Get-FileHash -LiteralPath $settings -Algorithm SHA256).Hash -cne $expectedSettingsSha) {
    throw 'accepted Vivado settings-wrapper hash mismatch'
}
if ((Get-FileHash -LiteralPath $vivado -Algorithm SHA256).Hash -cne $expectedVivadoSha) {
    throw 'supported Vivado launcher hash mismatch'
}

. $observerParser

$command = @(
    'call', (Assert-CmdToken $settings), '&&', (Assert-CmdToken $vivado),
    '-mode', 'batch', '-notrace',
    '-log', (Assert-CmdToken $vivadoLog),
    '-journal', (Assert-CmdToken $vivadoJournal),
    '-source', (Assert-CmdToken $tcl), '-tclargs',
    (Assert-CmdToken $phaseSpec.TclRole),
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
            if ($null -eq $line) {
                $stdoutClosed = $true
            } else {
                Add-ObserverRecord -Records $records -Stream 'STDOUT' -Line $line
                $stdoutTask = $process.StandardOutput.ReadLineAsync()
            }
            $madeProgress = $true
        }
        if (-not $stderrClosed -and $stderrTask.IsCompleted) {
            $line = $stderrTask.GetAwaiter().GetResult()
            if ($null -eq $line) {
                $stderrClosed = $true
            } else {
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
    ('TCL_ROLE={0}' -f $phaseSpec.TclRole),
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
[IO.File]::WriteAllLines($supervisorLog, @($header + $recordLines), [Text.UTF8Encoding]::new($false))

$result = Test-I25ProgramObserver -Records $records.ToArray()
$resultLines = [string[]]@(
    ('PROGRAM_EOS={0}' -f $result.PROGRAM_EOS),
    ('PROGRAM_DONE={0}' -f $result.PROGRAM_DONE),
    ('PROGRAM_RESULT={0}' -f $result.CLASSIFICATION),
    ('COUNT_GATE={0}' -f $result.COUNT_GATE),
    ('ORDER_GATE={0}' -f $result.ORDER_GATE),
    ('PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT={0}' -f $result.PROGRAM_INVOCATION_CONSUMED_COUNT),
    ('VENDOR_STARTUP_HIGH_COUNT={0}' -f $result.VENDOR_STARTUP_HIGH_COUNT),
    ('PROGRAM_RETURN_MARKER_COUNT={0}' -f $result.PROGRAM_RETURN_MARKER_COUNT),
    ('FRESH_DONE_MARKER_COUNT={0}' -f $result.FRESH_DONE_MARKER_COUNT)
)
[IO.File]::AppendAllLines($supervisorLog, $resultLines, [Text.UTF8Encoding]::new($false))
$resultLines

if ($result.CLASSIFICATION -cne 'PASS_STARTUP_HIGH_DONE_1') {
    [IO.File]::AppendAllLines($supervisorLog, [string[]]@('PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'), [Text.UTF8Encoding]::new($false))
    'PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'
    exit 1
}

$referenceTicks = [Math]::Max([long]$result.PROGRAM_RETURN_MARKER_TICKS, [long]$result.FRESH_DONE_MARKER_TICKS)
$requiredWaitTicks = [long][Math]::Ceiling([double]$phaseSpec.RequiredWaitSeconds * [Diagnostics.Stopwatch]::Frequency)
while (([Diagnostics.Stopwatch]::GetTimestamp() - $referenceTicks) -lt $requiredWaitTicks) {
    Start-Sleep -Milliseconds 5
}
$waitEndTicks = [Diagnostics.Stopwatch]::GetTimestamp()
$actualWaitTicks = $waitEndTicks - $referenceTicks
$actualWaitSeconds = [double]$actualWaitTicks / [Diagnostics.Stopwatch]::Frequency
$waitLines = [string[]]@(
    ('PHASE={0}' -f $Phase),
    ('STOPWATCH_FREQUENCY={0}' -f [Diagnostics.Stopwatch]::Frequency),
    ('PROGRAM_RETURN_MARKER_TICKS={0}' -f $result.PROGRAM_RETURN_MARKER_TICKS),
    ('FRESH_DONE_MARKER_TICKS={0}' -f $result.FRESH_DONE_MARKER_TICKS),
    ('WAIT_REFERENCE_TICKS={0}' -f $referenceTicks),
    ('WAIT_END_TICKS={0}' -f $waitEndTicks),
    ('REQUIRED_MINIMUM_WAIT_SECONDS={0}' -f ([double]$phaseSpec.RequiredWaitSeconds).ToString('F9', [Globalization.CultureInfo]::InvariantCulture)),
    ('ACTUAL_MONOTONIC_WAIT_TICKS={0}' -f $actualWaitTicks),
    ('ACTUAL_MONOTONIC_WAIT_SECONDS={0}' -f $actualWaitSeconds.ToString('F9', [Globalization.CultureInfo]::InvariantCulture)),
    'WAIT_GATE=PASS',
    'PROGRAM_SUPERVISOR_GATE=PASS'
)
[IO.File]::WriteAllLines($waitReceipt, $waitLines, [Text.UTF8Encoding]::new($false))
[IO.File]::AppendAllLines($supervisorLog, $waitLines, [Text.UTF8Encoding]::new($false))
$waitLines
