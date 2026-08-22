[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('ARM_A_25KHZ','ARM_B_FORMAL_50KHZ')][string]$Role,
    [Parameter(Mandatory)][string]$BitPath,
    [Parameter(Mandatory)][string]$ExpectedFilename,
    [Parameter(Mandatory)][long]$ExpectedSize,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-Fa-f]{64}$')][string]$ExpectedSha256,
    [Parameter(Mandatory)][ValidatePattern('^[0-9A-Fa-f]{40}$')][string]$ExpectedSourceCommit,
    [Parameter(Mandatory)][string]$EvidencePath,
    [ValidateRange(60,7200)][int]$TimeoutSeconds = 1800,
    [ValidateRange(5.0,60.0)][double]$MinimumWaitSeconds = 5.0
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
[Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::InvariantCulture

$settingsPath = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$programTclPath = Join-Path $PSScriptRoot 'program_once_startup_high_done.tcl'
$commonPath = Join-Path $PSScriptRoot 'ProgramObserverCommon.ps1'
$expectedSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$expectedVivadoSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'
$expectedProgramTclSha = '7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653'
$expectedCommonSha = '6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66'
$formalFilename = 'ahd_capture_v41_phase2_p1.bit'
$formalSize = 2192144L
$formalSha = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
$formalSourceCommit = 'fd32fcb65be3f1a59c569874195d1faeaf7d27e9'
$diagnosticFilename = 'ahd_capture_v41_i2c_25khz_r1.bit'
$diagnosticSize = 2192144L
$diagnosticSha = 'B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191'
$diagnosticSourceCommit = 'f007dc172d43d30b02729755e60382f8ce3dbff4'

function Resolve-CheckedFile([string]$Path) {
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
}

function Assert-CmdToken([string]$Text) {
    if ($Text -notmatch '^[A-Za-z0-9_:\\\./-]+$') {
        throw "unsafe cmd.exe token: $Text"
    }
    return $Text
}

$bit = Resolve-CheckedFile $BitPath
$tcl = Resolve-CheckedFile $programTclPath
$common = Resolve-CheckedFile $commonPath
$settings = Resolve-CheckedFile $settingsPath
$vivado = Resolve-CheckedFile $vivadoPath
$evidenceFull = [IO.Path]::GetFullPath($EvidencePath)
if (Test-Path -LiteralPath $evidenceFull) { throw "evidence path must be fresh: $evidenceFull" }
if (-not (Test-Path -LiteralPath (Split-Path -Parent $evidenceFull) -PathType Container)) {
    throw 'evidence parent does not exist'
}

$bitItem = Get-Item -LiteralPath $bit
$bitSha = (Get-FileHash -LiteralPath $bit -Algorithm SHA256).Hash
if ($bitItem.Name -cne $ExpectedFilename -or $bitItem.Length -ne $ExpectedSize -or
    $bitSha -cne $ExpectedSha256.ToUpperInvariant()) {
    throw 'bit filename/size/SHA-256 gate failed before Vivado launch'
}
if ((Get-FileHash -LiteralPath $tcl -Algorithm SHA256).Hash -cne $expectedProgramTclSha) {
    throw 'corrected single-program Tcl identity gate failed'
}
if ((Get-FileHash -LiteralPath $common -Algorithm SHA256).Hash -cne $expectedCommonSha) {
    throw 'program-observer parser identity gate failed'
}
if ((Get-FileHash -LiteralPath $settings -Algorithm SHA256).Hash -cne $expectedSettingsSha -or
    (Get-FileHash -LiteralPath $vivado -Algorithm SHA256).Hash -cne $expectedVivadoSha) {
    throw 'supported Vivado wrapper identity gate failed'
}
if ($Role -eq 'ARM_A_25KHZ' -and
    ($ExpectedFilename -cne $diagnosticFilename -or $ExpectedSize -ne $diagnosticSize -or
     $ExpectedSha256.ToUpperInvariant() -cne $diagnosticSha -or
     $ExpectedSourceCommit.ToLowerInvariant() -cne $diagnosticSourceCommit)) {
    throw 'Arm-A role is not bound to the exact R1 diagnostic artifact'
}
if ($Role -eq 'ARM_B_FORMAL_50KHZ' -and
    ($ExpectedFilename -cne $formalFilename -or $ExpectedSize -ne $formalSize -or
     $ExpectedSha256.ToUpperInvariant() -cne $formalSha -or
     $ExpectedSourceCommit.ToLowerInvariant() -cne $formalSourceCommit)) {
    throw 'Arm-B role is not bound to exact formal Phase 2'
}

. $common

$command = @(
    'call',(Assert-CmdToken $settings),'&&',(Assert-CmdToken $vivado),
    '-mode','batch','-notrace','-source',(Assert-CmdToken $tcl),'-tclargs',
    (Assert-CmdToken $Role),(Assert-CmdToken $bit),(Assert-CmdToken $ExpectedFilename),
    (Assert-CmdToken ([string]$ExpectedSize)),(Assert-CmdToken $ExpectedSha256.ToUpperInvariant())
) -join ' '

$psi = [Diagnostics.ProcessStartInfo]::new()
$psi.FileName = "$env:SystemRoot\System32\cmd.exe"
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardOutput = $true
$psi.RedirectStandardError = $true
$psi.Arguments = '/d /s /c "' + $command + '"'

$process = [Diagnostics.Process]::new()
$process.StartInfo = $psi
$records = [Collections.Generic.List[object]]::new()
[long]$script:observerSequence = 0
$timedOut = $false
$processStartTicks = [Diagnostics.Stopwatch]::GetTimestamp()

function Add-ObserverRecord([string]$Stream,[string]$Line) {
    $script:observerSequence++
    $records.Add([pscustomobject]@{
        Sequence = $script:observerSequence
        Tick = [Diagnostics.Stopwatch]::GetTimestamp()
        Stream = $Stream
        Line = $Line
        Raw = $Line
    })
}

try {
    if (-not $process.Start()) { throw 'failed to start Vivado wrapper process' }
    $stdoutTask = $process.StandardOutput.ReadLineAsync()
    $stderrTask = $process.StandardError.ReadLineAsync()
    $stdoutClosed = $false
    $stderrClosed = $false
    while (-not ($process.HasExited -and $stdoutClosed -and $stderrClosed)) {
        $progress = $false
        if (-not $stdoutClosed -and $stdoutTask.IsCompleted) {
            $line = $stdoutTask.GetAwaiter().GetResult()
            if ($null -eq $line) { $stdoutClosed = $true }
            else { Add-ObserverRecord 'STDOUT' $line; $stdoutTask = $process.StandardOutput.ReadLineAsync() }
            $progress = $true
        }
        if (-not $stderrClosed -and $stderrTask.IsCompleted) {
            $line = $stderrTask.GetAwaiter().GetResult()
            if ($null -eq $line) { $stderrClosed = $true }
            else { Add-ObserverRecord 'STDERR' $line; $stderrTask = $process.StandardError.ReadLineAsync() }
            $progress = $true
        }
        $elapsed = ([Diagnostics.Stopwatch]::GetTimestamp() - $processStartTicks) / [Diagnostics.Stopwatch]::Frequency
        if ($elapsed -gt $TimeoutSeconds -and -not $process.HasExited) {
            $timedOut = $true
            try { $process.Kill() } catch {}
            break
        }
        if (-not $progress) { Start-Sleep -Milliseconds 5 }
    }
    $process.WaitForExit()
} finally {
    $processEndTicks = [Diagnostics.Stopwatch]::GetTimestamp()
}

Add-ObserverRecord 'SUPERVISOR' ('TIMED_OUT=' + $(if ($timedOut) {'YES'} else {'NO'}))
Add-ObserverRecord 'SUPERVISOR' ('PROCESS_EXIT_CODE=' + $process.ExitCode)

$header = [string[]]@(
    ('ROLE={0}' -f $Role),
    ('BIT_PATH={0}' -f $bit),
    ('BIT_SIZE={0}' -f $bitItem.Length),
    ('BIT_SHA256={0}' -f $bitSha),
    ('EXPECTED_SOURCE_COMMIT={0}' -f $ExpectedSourceCommit.ToLowerInvariant()),
    ('PROGRAM_TCL_PATH={0}' -f $tcl),
    ('PROGRAM_TCL_SHA256={0}' -f $expectedProgramTclSha),
    ('OBSERVER_PARSER_SHA256={0}' -f $expectedCommonSha),
    ('STOPWATCH_FREQUENCY={0}' -f [Diagnostics.Stopwatch]::Frequency),
    ('PROCESS_START_TICKS={0}' -f $processStartTicks),
    ('PROCESS_END_TICKS={0}' -f $processEndTicks)
)
$recordLines = @($records | ForEach-Object {
    'SEQ={0} TICK={1} STREAM={2} LINE={3}' -f $_.Sequence,$_.Tick,$_.Stream,$_.Line
})
[IO.File]::WriteAllLines($evidenceFull,@($header + $recordLines),[Text.UTF8Encoding]::new($false))

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
[IO.File]::AppendAllLines($evidenceFull,[string[]]$resultLines,[Text.UTF8Encoding]::new($false))
$resultLines

if ($result.CLASSIFICATION -cne 'PASS_STARTUP_HIGH_DONE_1') {
    [IO.File]::AppendAllLines($evidenceFull,[string[]]@('PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'),[Text.UTF8Encoding]::new($false))
    'PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'
    exit 1
}

$referenceTicks = [Math]::Max([long]$result.PROGRAM_RETURN_MARKER_TICKS,[long]$result.FRESH_DONE_MARKER_TICKS)
$requiredWaitTicks = [long][Math]::Ceiling($MinimumWaitSeconds * [Diagnostics.Stopwatch]::Frequency)
while (([Diagnostics.Stopwatch]::GetTimestamp() - $referenceTicks) -lt $requiredWaitTicks) {
    Start-Sleep -Milliseconds 5
}
$waitEndTicks = [Diagnostics.Stopwatch]::GetTimestamp()
$actualWaitTicks = $waitEndTicks - $referenceTicks
$actualWaitSeconds = [double]$actualWaitTicks / [Diagnostics.Stopwatch]::Frequency
$waitLines = [string[]]@(
    ('WAIT_REFERENCE_TICKS={0}' -f $referenceTicks),
    ('WAIT_END_TICKS={0}' -f $waitEndTicks),
    ('REQUIRED_MINIMUM_WAIT_SECONDS={0}' -f $MinimumWaitSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture)),
    ('ACTUAL_MONOTONIC_WAIT_TICKS={0}' -f $actualWaitTicks),
    ('ACTUAL_MONOTONIC_WAIT_SECONDS={0}' -f $actualWaitSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture)),
    'REBOOT_SUBMISSION_TIME_GATE=PASS',
    'PROGRAM_SUPERVISOR_GATE=PASS'
)
[IO.File]::AppendAllLines($evidenceFull,[string[]]$waitLines,[Text.UTF8Encoding]::new($false))
$waitLines
