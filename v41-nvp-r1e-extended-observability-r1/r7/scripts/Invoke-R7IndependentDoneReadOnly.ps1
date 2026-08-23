[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('FormalBootstrap', 'ArmA', 'ArmB')]
    [string]$Role,

    [Parameter(Mandatory = $true)]
    [ValidateSet('Immediate', 'Final')]
    [string]$Stage,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^.+/Xilinx/80802026a98b01$')]
    [string]$ExpectedFullTargetPath,

    [ValidateRange(60, 900)]
    [int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7'
$scriptPath = Join-Path $taskRoot 'scripts\read_jtag_identity_done_r7_selected.tcl'
$settingsPath = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$expectedScriptSha = '122C960412B7A8ADFD2926BE9A863A2786D4D022854AE8A0D56798461E0CD91B'
$expectedSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$expectedVivadoSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'
$canonicalId = 'Xilinx/80802026a98b01'

function Resolve-CheckedFile([string]$Path) {
    return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
}

function Assert-CmdToken([string]$Text) {
    if ($Text -notmatch '^[A-Za-z0-9_:\\./-]+$') { throw "unsafe cmd.exe token: $Text" }
    return $Text
}

function Assert-ExactHash([string]$Path, [string]$Expected) {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -cne $Expected) { throw "SHA-256 mismatch for $Path`: $actual" }
}

function Get-UniqueValue([string]$Text, [string]$Key) {
    $matches = [regex]::Matches($Text, '(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$')
    if ($matches.Count -ne 1) { throw "$Key exact-line count is $($matches.Count), expected 1" }
    return $matches[0].Groups[1].Value
}

$roleDirectory = switch ($Role) {
    'FormalBootstrap' { Join-Path $taskRoot '07_FORMAL_BOOTSTRAP' }
    'ArmA' { Join-Path $taskRoot '08_ARM_A_R1E' }
    'ArmB' { Join-Path $taskRoot '09_ARM_B_FORMAL' }
}
$roleDirectory = (Resolve-Path -LiteralPath $roleDirectory -ErrorAction Stop).Path
$stageSpec = if ($Stage -eq 'Immediate') {
    [pscustomobject]@{
        Prefix = 'INDEPENDENT_DONE'
        Receipt = 'INDEPENDENT_DONE_RECEIPT.txt'
        Label = 'IMMEDIATE_POST_PROGRAM'
    }
} else {
    [pscustomobject]@{
        Prefix = 'FINAL_DONE'
        Receipt = 'FINAL_DONE_RECEIPT.txt'
        Label = 'FINAL_POST_PHASE'
    }
}
$stdoutPath = Join-Path $roleDirectory ($stageSpec.Prefix + '_STDOUT_STDERR.log')
$vivadoLogPath = Join-Path $roleDirectory ($stageSpec.Prefix + '_VIVADO.log')
$journalPath = Join-Path $roleDirectory ($stageSpec.Prefix + '_VIVADO.jou')
$receiptPath = Join-Path $roleDirectory $stageSpec.Receipt
foreach ($path in @($stdoutPath, $vivadoLogPath, $journalPath, $receiptPath)) {
    if (Test-Path -LiteralPath $path) { throw "refusing to overwrite independent-DONE evidence: $path" }
}

$script = Resolve-CheckedFile $scriptPath
$settings = Resolve-CheckedFile $settingsPath
$vivado = Resolve-CheckedFile $vivadoPath
Assert-ExactHash $script $expectedScriptSha
Assert-ExactHash $settings $expectedSettingsSha
Assert-ExactHash $vivado $expectedVivadoSha

$tclText = [IO.File]::ReadAllText($script)
if ([regex]::IsMatch($tclText, '(?m)^\s*program_hw_devices\b') -or
    [regex]::IsMatch($tclText, '(?m)^\s*set_property\b') -or
    [regex]::IsMatch($tclText, '(?im)\b(?:FREQUENCY|JTAG_FREQUENCY)\b\s+\S+')) {
    throw 'independent-DONE Tcl contains a programming or property-changing command'
}

$command = @(
    'call', (Assert-CmdToken $settings), '&&', (Assert-CmdToken $vivado),
    '-mode', 'batch', '-notrace',
    '-log', (Assert-CmdToken $vivadoLogPath),
    '-journal', (Assert-CmdToken $journalPath),
    '-source', (Assert-CmdToken $script),
    '-tclargs', (Assert-CmdToken $Role), (Assert-CmdToken $ExpectedFullTargetPath)
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
$timedOut = $false
$startUtc = [DateTime]::UtcNow.ToString('o')
$frequency = [Diagnostics.Stopwatch]::Frequency
$startTicks = [Diagnostics.Stopwatch]::GetTimestamp()
try {
    if (-not $process.Start()) { throw 'failed to start supported Vivado launcher' }
    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $timedOut = $true
        $process.Kill($true)
        $process.WaitForExit()
    }
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $process.ExitCode
}
finally {
    $endTicks = [Diagnostics.Stopwatch]::GetTimestamp()
    $process.Dispose()
}

$rawLines = [string[]]@(
    "PHASE=$Role",
    "R7_FULL_JTAG_TARGET_PATH=$ExpectedFullTargetPath",
    "UTC_START=$startUtc",
    "UTC_END=$([DateTime]::UtcNow.ToString('o'))",
    "STOPWATCH_FREQUENCY=$frequency",
    "SESSION_START_TICKS=$startTicks",
    "SESSION_END_TICKS=$endTicks",
    "TIMED_OUT=$(if ($timedOut) {'YES'} else {'NO'})",
    "PROCESS_EXIT_CODE=$exitCode",
    "READ_ONLY_JTAG_TCL_SHA256=$expectedScriptSha",
    'STDOUT_BEGIN',
    $stdout.TrimEnd(),
    'STDOUT_END',
    'STDERR_BEGIN',
    $stderr.TrimEnd(),
    'STDERR_END'
)
[IO.File]::WriteAllLines($stdoutPath, $rawLines, [Text.UTF8Encoding]::new($false))
$rawSha = (Get-FileHash -LiteralPath $stdoutPath -Algorithm SHA256).Hash
$combined = $stdout + "`n" + $stderr

$failures = [Collections.Generic.List[string]]::new()
try {
    $observedPhase = Get-UniqueValue $combined 'PHASE'
    $observedCanonical = Get-UniqueValue $combined 'R7_SELECTED_JTAG_CANONICAL_ID'
    $observedPath = Get-UniqueValue $combined 'R7_FULL_JTAG_TARGET_PATH'
    $deviceCount = Get-UniqueValue $combined 'R7_JTAG_DEVICE_COUNT'
    $part = Get-UniqueValue $combined 'FPGA_PART'
    $idcode = Get-UniqueValue $combined 'FPGA_IDCODE'
    $done = Get-UniqueValue $combined 'FPGA_DONE'
    $frequencyChanged = Get-UniqueValue $combined 'JTAG_FREQUENCY_CHANGED'
    $programOperations = Get-UniqueValue $combined 'FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT'
    $tclGate = Get-UniqueValue $combined 'INDEPENDENT_DONE_GATE'
} catch {
    $failures.Add("OUTPUT_PARSE=$($_.Exception.Message)")
    $observedPhase = 'UNKNOWN'; $observedCanonical = 'UNKNOWN'; $observedPath = 'UNKNOWN'
    $deviceCount = 'UNKNOWN'; $part = 'UNKNOWN'; $idcode = 'UNKNOWN'; $done = 'UNKNOWN'
    $frequencyChanged = 'UNKNOWN'; $programOperations = 'UNKNOWN'; $tclGate = 'UNKNOWN'
}

if ($timedOut) { $failures.Add('PROCESS_TIMEOUT') }
if ($exitCode -ne 0) { $failures.Add("PROCESS_EXIT_CODE=$exitCode") }
if ($observedPhase -cne $Role) { $failures.Add('PHASE_MISMATCH') }
if ($observedCanonical -cne $canonicalId) { $failures.Add('CANONICAL_TARGET_MISMATCH') }
if ($observedPath -cne $ExpectedFullTargetPath) { $failures.Add('FULL_TARGET_PATH_MISMATCH') }
if ($deviceCount -cne '1' -or $part -cne 'xc7a35t' -or $idcode -cne '0362D093') {
    $failures.Add('DEVICE_IDENTITY_MISMATCH')
}
if ($done -cne '1' -or $tclGate -cne 'PASS_SELECTED_TARGET_DONE_1') {
    $failures.Add('DONE_GATE')
}
if ($frequencyChanged -cne 'NO') { $failures.Add('JTAG_FREQUENCY_CHANGED') }
if ($programOperations -cne '0') { $failures.Add('UNAUTHORIZED_PROGRAM_OPERATION') }

$gate = if ($failures.Count -eq 0) { 'PASS_SELECTED_TARGET_DONE_1' } else { 'FAIL' }
$receiptLines = [Collections.Generic.List[string]]::new()
$receiptLines.Add("PHASE=$Role")
$receiptLines.Add("DONE_STAGE=$($stageSpec.Label)")
$receiptLines.Add('INDEPENDENT_READ_ONLY_SESSION=YES')
$receiptLines.Add("READ_ONLY_JTAG_TCL_SHA256=$expectedScriptSha")
$receiptLines.Add("R7_SELECTED_JTAG_CANONICAL_ID=$observedCanonical")
$receiptLines.Add("R7_FULL_JTAG_TARGET_PATH=$observedPath")
$receiptLines.Add("FPGA_PART=$part")
$receiptLines.Add("FPGA_IDCODE=$idcode")
$receiptLines.Add("FPGA_DONE=$done")
$receiptLines.Add("FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT=$programOperations")
$receiptLines.Add("PROCESS_EXIT_CODE=$exitCode")
$receiptLines.Add("TIMED_OUT=$(if ($timedOut) {'YES'} else {'NO'})")
$receiptLines.Add("STOPWATCH_FREQUENCY=$frequency")
$receiptLines.Add("SESSION_START_TICKS=$startTicks")
$receiptLines.Add("SESSION_END_TICKS=$endTicks")
$receiptLines.Add("RAW_TRANSCRIPT_SHA256=$rawSha")
$receiptLines.Add("INDEPENDENT_DONE_GATE=$gate")
foreach ($failure in $failures) { $receiptLines.Add("FAILURE=$failure") }
[IO.File]::WriteAllLines($receiptPath, $receiptLines, [Text.UTF8Encoding]::new($false))
$receiptLines
if ($gate -cne 'PASS_SELECTED_TARGET_DONE_1') { exit 1 }
exit 0
