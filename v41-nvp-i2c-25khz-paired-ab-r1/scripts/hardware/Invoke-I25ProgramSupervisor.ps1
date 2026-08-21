[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('ARM_A_25KHZ','ARM_B_FORMAL_50KHZ')]
    [string]$Role,
    [Parameter(Mandatory = $true)]
    [string]$BitPath,
    [Parameter(Mandatory = $true)]
    [string]$ExpectedFilename,
    [Parameter(Mandatory = $true)]
    [long]$ExpectedSize,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{64}$')]
    [string]$ExpectedSha256,
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[0-9A-Fa-f]{40}$')]
    [string]$ExpectedSourceCommit,
    [Parameter(Mandatory = $true)]
    [string]$ProgramTclPath,
    [Parameter(Mandatory = $true)]
    [string]$EvidencePath,
    [ValidateRange(60, 7200)]
    [int]$TimeoutSeconds = 1800,
    [ValidateRange(5.0, 60.0)]
    [double]$MinimumWaitSeconds = 5.0
)

# WARNING: running this script performs the one hardware programming attempt.
# Merely retaining or parsing it does not. The caller must complete all owner-
# authorized gates and operation-budget checks before invocation. There is no
# bootstrap role. An unproven exact formal Phase-2 start state requires a hard
# stop before this supervisor is launched.

$ErrorActionPreference = 'Stop'
[System.Globalization.CultureInfo]::CurrentCulture = [System.Globalization.CultureInfo]::InvariantCulture

$settingsPath = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$expectedSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$expectedVivadoSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'
$expectedProgramTclSha = '0574AC0B325095E9726BFC030D8B4318481B0E38FB4039B56B22521EF0838CF6'
$formalFilename = 'ahd_capture_v41_phase2_p1.bit'
$formalSize = 2192144L
$formalSha = '7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2'
$diagnosticFilename = 'ahd_capture_v41_i2c_25khz_r1.bit'
$diagnosticSize = 2192144L
$diagnosticSha = 'B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191'
$diagnosticSourceCommit = 'f007dc172d43d30b02729755e60382f8ce3dbff4'
$formalFunctionalSourceCommit = 'fd32fcb65be3f1a59c569874195d1faeaf7d27e9'

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
$tcl = Resolve-CheckedFile $ProgramTclPath
$settings = Resolve-CheckedFile $settingsPath
$vivado = Resolve-CheckedFile $vivadoPath
$evidenceFull = [IO.Path]::GetFullPath($EvidencePath)
if (Test-Path -LiteralPath $evidenceFull) {
    throw "evidence path must be fresh: $evidenceFull"
}
$evidenceParent = Split-Path -Parent $evidenceFull
if (-not (Test-Path -LiteralPath $evidenceParent -PathType Container)) {
    throw "evidence parent does not exist: $evidenceParent"
}

$bitItem = Get-Item -LiteralPath $bit
$bitSha = (Get-FileHash -LiteralPath $bit -Algorithm SHA256).Hash
if ($bitItem.Name -cne $ExpectedFilename -or $bitItem.Length -ne $ExpectedSize -or
    $bitSha -cne $ExpectedSha256.ToUpperInvariant()) {
    throw 'bit filename/size/SHA-256 gate failed before Vivado launch'
}
if ((Get-FileHash -LiteralPath $tcl -Algorithm SHA256).Hash -cne $expectedProgramTclSha) {
    throw 'single-program Tcl identity gate failed'
}
if ($Role -eq 'ARM_B_FORMAL_50KHZ' -and
    ($ExpectedFilename -cne $formalFilename -or $ExpectedSize -ne $formalSize -or
     $ExpectedSha256.ToUpperInvariant() -cne $formalSha -or
     $ExpectedSourceCommit.ToLowerInvariant() -cne $formalFunctionalSourceCommit)) {
    throw 'Arm-B role is not bound to the exact formal Phase-2 bit identity'
}
if ($Role -eq 'ARM_A_25KHZ' -and
    ($ExpectedFilename -cne $diagnosticFilename -or $ExpectedSize -ne $diagnosticSize -or
     $ExpectedSha256.ToUpperInvariant() -cne $diagnosticSha -or
     $ExpectedSourceCommit.ToLowerInvariant() -cne $diagnosticSourceCommit)) {
    throw 'Arm-A role is not bound to the completed-build diagnostic filename'
}
if ((Get-FileHash -LiteralPath $settings -Algorithm SHA256).Hash -cne $expectedSettingsSha -or
    (Get-FileHash -LiteralPath $vivado -Algorithm SHA256).Hash -cne $expectedVivadoSha) {
    throw 'supported Vivado wrapper identity gate failed'
}

$command = @(
    'call', (Assert-CmdToken $settings), '&&', (Assert-CmdToken $vivado),
    '-mode', 'batch', '-notrace', '-source', (Assert-CmdToken $tcl), '-tclargs',
    (Assert-CmdToken $Role), (Assert-CmdToken $bit),
    (Assert-CmdToken $ExpectedFilename), (Assert-CmdToken ([string]$ExpectedSize)),
    (Assert-CmdToken $ExpectedSha256.ToUpperInvariant())
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
$watch = [Diagnostics.Stopwatch]::StartNew()
$records = [Collections.Generic.List[string]]::new()
$stdoutLines = [Collections.Generic.List[string]]::new()
[long]$programConsumedTicks = -1
[long]$programReturnTicks = -1
[long]$freshDoneTicks = -1
$stdoutClosed = $false
$stderrClosed = $false
$timedOut = $false
[long]$processExitTicks = -1

function Record-Line([string]$Stream, [string]$Line) {
    $tick = $watch.ElapsedTicks
    $records.Add(('{0} TICK={1} LINE={2}' -f $Stream,$tick,$Line))
    if ($Stream -eq 'STDOUT') {
        $stdoutLines.Add($Line)
        if ($Line -eq 'PROGRAM_INVOCATION_CONSUMED=1' -and $programConsumedTicks -lt 0) {
            $script:programConsumedTicks = $tick
        }
        if ($Line -like 'I25_PROGRAM_RETURN_MARKER=*' -and $programReturnTicks -lt 0) {
            $script:programReturnTicks = $tick
        }
        if ($Line -like 'I25_FRESH_DONE_MARKER=*' -and $freshDoneTicks -lt 0) {
            $script:freshDoneTicks = $tick
        }
    }
}

try {
    if (-not $process.Start()) { throw 'failed to start Vivado wrapper process' }
    $stdoutTask = $process.StandardOutput.ReadLineAsync()
    $stderrTask = $process.StandardError.ReadLineAsync()

    while (-not ($process.HasExited -and $stdoutClosed -and $stderrClosed)) {
        $progress = $false
        if (-not $stdoutClosed -and $stdoutTask.IsCompleted) {
            $line = $stdoutTask.GetAwaiter().GetResult()
            if ($null -eq $line) { $stdoutClosed = $true }
            else { Record-Line STDOUT $line; $stdoutTask = $process.StandardOutput.ReadLineAsync() }
            $progress = $true
        }
        if (-not $stderrClosed -and $stderrTask.IsCompleted) {
            $line = $stderrTask.GetAwaiter().GetResult()
            if ($null -eq $line) { $stderrClosed = $true }
            else { Record-Line STDERR $line; $stderrTask = $process.StandardError.ReadLineAsync() }
            $progress = $true
        }
        if ($watch.Elapsed.TotalSeconds -gt $TimeoutSeconds -and -not $process.HasExited) {
            $timedOut = $true
            try { $process.Kill() } catch {}
            break
        }
        if (-not $progress) { Start-Sleep -Milliseconds 5 }
    }
    $process.WaitForExit()
} finally {
    $processExitTicks = $watch.ElapsedTicks
    $header = @(
        'ROLE=' + $Role,
        'BIT_PATH=' + $bit,
        'BIT_SIZE=' + $bitItem.Length,
        'BIT_SHA256=' + $bitSha,
        'EXPECTED_SOURCE_COMMIT=' + $ExpectedSourceCommit.ToLowerInvariant(),
        'PROGRAM_TCL_PATH=' + $tcl,
        'STOPWATCH_FREQUENCY=' + [Diagnostics.Stopwatch]::Frequency,
        'PROCESS_START_REFERENCE_TICKS=0',
        'PROCESS_EXIT_TICKS=' + $processExitTicks,
        'TIMED_OUT=' + $(if ($timedOut) { 'YES' } else { 'NO' })
    )
    [IO.File]::WriteAllLines($evidenceFull, @($header + $records))
}

$consumedCount = @($stdoutLines | Where-Object { $_ -eq 'PROGRAM_INVOCATION_CONSUMED=1' }).Count
$returnCount = @($stdoutLines | Where-Object { $_ -like 'I25_PROGRAM_RETURN_MARKER=*' }).Count
$doneMarkerCount = @($stdoutLines | Where-Object { $_ -like 'I25_FRESH_DONE_MARKER=*' }).Count
$passLineCount = @($stdoutLines | Where-Object { $_ -eq 'PROGRAM_RESULT=PASS_EOS_HIGH_DONE_1' }).Count
$eosPass = @($stdoutLines | Where-Object { $_ -eq 'PROGRAM_EOS=1' }).Count -eq 1
$donePass = @($stdoutLines | Where-Object { $_ -eq 'PROGRAM_DONE=1' }).Count -eq 1

'PROGRAM_SUPERVISOR_EVIDENCE={0}' -f $evidenceFull
'STOPWATCH_FREQUENCY={0}' -f [Diagnostics.Stopwatch]::Frequency
'PROGRAM_INVOCATION_CONSUMED_MARKER_COUNT={0}' -f $consumedCount
'PROGRAM_INVOCATION_CONSUMED_TICKS={0}' -f $(if ($programConsumedTicks -ge 0) { $programConsumedTicks } else { 'NOT_SEEN' })
'PROGRAM_RETURN_MARKER_COUNT={0}' -f $returnCount
'PROGRAM_RETURN_MARKER_TICKS={0}' -f $(if ($programReturnTicks -ge 0) { $programReturnTicks } else { 'NOT_SEEN' })
'FRESH_DONE_MARKER_COUNT={0}' -f $doneMarkerCount
'FRESH_DONE_MARKER_TICKS={0}' -f $(if ($freshDoneTicks -ge 0) { $freshDoneTicks } else { 'NOT_SEEN' })

if ($programReturnTicks -ge 0 -and $freshDoneTicks -ge 0) {
    $referenceTicks = [Math]::Max($programReturnTicks, $freshDoneTicks)
    'WAIT_REFERENCE_TICKS={0}' -f $referenceTicks
} else {
    'WAIT_REFERENCE_TICKS=UNAVAILABLE'
}

if ($timedOut -or $consumedCount -ne 1 -or $returnCount -ne 1 -or
    $doneMarkerCount -ne 1 -or $passLineCount -ne 1 -or -not $eosPass -or
    -not $donePass -or $process.ExitCode -ne 0) {
    $watch.Stop()
    [IO.File]::AppendAllLines(
        $evidenceFull,
        [string[]]@('PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'),
        [Text.UTF8Encoding]::new($false)
    )
    'PROGRAM_SUPERVISOR_GATE=FAIL_NO_RETRY'
    exit 1
}

# Preserve a single monotonic epoch through programming, fresh DONE and the
# full wait. Returning from this script is the earliest time at which a caller
# may submit the one separately gated warm-reboot command.
$requiredWaitTicks = [long][Math]::Ceiling($MinimumWaitSeconds * [Diagnostics.Stopwatch]::Frequency)
while (($watch.ElapsedTicks - $referenceTicks) -lt $requiredWaitTicks) {
    Start-Sleep -Milliseconds 5
}
$waitEndTicks = $watch.ElapsedTicks
$actualWaitTicks = $waitEndTicks - $referenceTicks
$actualWaitSeconds = [double]$actualWaitTicks / [Diagnostics.Stopwatch]::Frequency
$watch.Stop()
[IO.File]::AppendAllLines(
    $evidenceFull,
    [string[]]@(
        'WAIT_REFERENCE_TICKS=' + $referenceTicks,
        'REQUIRED_MINIMUM_WAIT_SECONDS=' + $MinimumWaitSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture),
        'ACTUAL_MONOTONIC_WAIT_TICKS=' + $actualWaitTicks,
        'ACTUAL_MONOTONIC_WAIT_SECONDS=' + $actualWaitSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture),
        'REBOOT_SUBMISSION_TIME_GATE=PASS'
    ),
    [Text.UTF8Encoding]::new($false)
)
'REQUIRED_MINIMUM_WAIT_SECONDS={0:F9}' -f $MinimumWaitSeconds
'ACTUAL_MONOTONIC_WAIT_TICKS={0}' -f $actualWaitTicks
'ACTUAL_MONOTONIC_WAIT_SECONDS={0:F9}' -f $actualWaitSeconds
'REBOOT_SUBMISSION_TIME_GATE=PASS'
'PROGRAM_SUPERVISOR_GATE=PASS'
