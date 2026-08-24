[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken,
    [Parameter(Mandatory)][ValidateSet('Immediate','Final')][string]$Stage,
    [Parameter(Mandatory)][string]$BindingPath,
    [ValidateRange(60,900)][int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1gCampaignCommon.ps1')

function Assert-CmdToken([string]$Text) {
    if ($Text -notmatch '^[A-Za-z0-9_:\\\./-]+$') { throw "unsafe cmd.exe token: $Text" }
    return $Text
}

function Get-UniqueValue([string]$Text,[string]$Key) {
    $matches = [regex]::Matches($Text,'(?m)^' + [regex]::Escape($Key) + '=([^\r\n]*)\r?$')
    if ($matches.Count -ne 1) { throw "$Key exact-line count is $($matches.Count), expected 1" }
    return $matches[0].Groups[1].Value
}

$binding = Get-R1gBindingDocument -BindingPath $BindingPath
Assert-R1gAcceptedToolSet
$phase = Get-R1gPhaseSpec $PhaseToken
$phaseDirectory = Assert-R1gPhaseDirectory $phase
$inheritedRole = switch ($phase.Kind) {
    'BOOTSTRAP' { 'FormalBootstrap' }
    'ARM_A' { 'ArmA' }
    'ARM_B' { 'ArmB' }
}
$stageSpec = if ($Stage -eq 'Immediate') {
    [pscustomobject]@{ Prefix='INDEPENDENT_DONE'; Receipt='INDEPENDENT_DONE_RECEIPT.txt'; Label='IMMEDIATE_POST_PROGRAM' }
} else {
    [pscustomobject]@{ Prefix='FINAL_DONE'; Receipt='FINAL_DONE_RECEIPT.txt'; Label='FINAL_POST_PHASE' }
}
$rawPath = Join-Path $phaseDirectory ($stageSpec.Prefix + '_STDOUT_STDERR.log')
$vivadoLog = Join-Path $phaseDirectory ($stageSpec.Prefix + '_VIVADO.log')
$journal = Join-Path $phaseDirectory ($stageSpec.Prefix + '_VIVADO.jou')
$receiptPath = Join-Path $phaseDirectory $stageSpec.Receipt
foreach ($path in @($rawPath,$vivadoLog,$journal,$receiptPath)) {
    if (Test-Path -LiteralPath $path) { throw "refusing to overwrite independent-DONE evidence: $path" }
}

$scriptPath = $script:R1gAcceptedTools.IndependentDoneTcl.Path
$settingsPath = $script:R1gAcceptedTools.VivadoSettings.Path
$vivadoPath = $script:R1gAcceptedTools.VivadoLauncher.Path
$tclText = [IO.File]::ReadAllText($scriptPath)
if ([regex]::IsMatch($tclText,'(?m)^\s*program_hw_devices\b') -or
    [regex]::IsMatch($tclText,'(?m)^\s*set_property\b') -or
    [regex]::IsMatch($tclText,'(?im)\b(?:FREQUENCY|JTAG_FREQUENCY)\b\s+\S+')) {
    throw 'independent-DONE Tcl contains a programming or property-changing command'
}

$command = @(
    'call',(Assert-CmdToken $settingsPath),'&&',(Assert-CmdToken $vivadoPath),
    '-mode','batch','-notrace',
    '-log',(Assert-CmdToken $vivadoLog),
    '-journal',(Assert-CmdToken $journal),
    '-source',(Assert-CmdToken $scriptPath),'-tclargs',
    (Assert-CmdToken $inheritedRole),(Assert-CmdToken ([string]$binding.selectedFullJtagTargetPath))
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
} finally {
    $endTicks = [Diagnostics.Stopwatch]::GetTimestamp()
    $process.Dispose()
}

Write-R1gUtf8NoBom -Path $rawPath -Lines @(
    "PHASE_TOKEN=$PhaseToken",
    "INHERITED_R7_PHASE=$inheritedRole",
    "R1G_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    "UTC_START=$startUtc",
    "UTC_END=$([DateTime]::UtcNow.ToString('o'))",
    "STOPWATCH_FREQUENCY=$frequency",
    "SESSION_START_TICKS=$startTicks",
    "SESSION_END_TICKS=$endTicks",
    "TIMED_OUT=$(if ($timedOut) {'YES'} else {'NO'})",
    "PROCESS_EXIT_CODE=$exitCode",
    "READ_ONLY_JTAG_TCL_SHA256=$($script:R1gAcceptedTools.IndependentDoneTcl.Sha256)",
    'STDOUT_BEGIN',$stdout.TrimEnd(),'STDOUT_END',
    'STDERR_BEGIN',$stderr.TrimEnd(),'STDERR_END'
)
$rawSha = (Get-FileHash -Algorithm SHA256 -LiteralPath $rawPath).Hash
$combined = $stdout + "`n" + $stderr
$failures = [Collections.Generic.List[string]]::new()
try {
    $observedPhase = Get-UniqueValue $combined PHASE
    $canonical = Get-UniqueValue $combined R7_SELECTED_JTAG_CANONICAL_ID
    $path = Get-UniqueValue $combined R7_FULL_JTAG_TARGET_PATH
    $deviceCount = Get-UniqueValue $combined R7_JTAG_DEVICE_COUNT
    $part = Get-UniqueValue $combined FPGA_PART
    $idcode = Get-UniqueValue $combined FPGA_IDCODE
    $done = Get-UniqueValue $combined FPGA_DONE
    $frequencyChanged = Get-UniqueValue $combined JTAG_FREQUENCY_CHANGED
    $programOperations = Get-UniqueValue $combined FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT
    $tclGate = Get-UniqueValue $combined INDEPENDENT_DONE_GATE
} catch {
    $failures.Add("OUTPUT_PARSE=$($_.Exception.Message)")
    $observedPhase='UNKNOWN';$canonical='UNKNOWN';$path='UNKNOWN';$deviceCount='UNKNOWN'
    $part='UNKNOWN';$idcode='UNKNOWN';$done='UNKNOWN';$frequencyChanged='UNKNOWN'
    $programOperations='UNKNOWN';$tclGate='UNKNOWN'
}
if ($timedOut) { $failures.Add('PROCESS_TIMEOUT') }
if ($exitCode -ne 0) { $failures.Add("PROCESS_EXIT_CODE=$exitCode") }
if ($observedPhase -cne $inheritedRole) { $failures.Add('PHASE_MISMATCH') }
if ($canonical -cne $script:R1gCanonicalTarget -or $path -cne [string]$binding.selectedFullJtagTargetPath) {
    $failures.Add('SELECTED_TARGET_MISMATCH')
}
if ($deviceCount -cne '1' -or $part -cne $script:R1gExpectedPart -or $idcode -cne $script:R1gExpectedIdcode) {
    $failures.Add('DEVICE_IDENTITY_MISMATCH')
}
if ($done -cne '1' -or $tclGate -cne 'PASS_SELECTED_TARGET_DONE_1') { $failures.Add('DONE_GATE') }
if ($frequencyChanged -cne 'NO') { $failures.Add('JTAG_FREQUENCY_CHANGED') }
if ($programOperations -cne '0') { $failures.Add('UNAUTHORIZED_PROGRAM_OPERATION') }
$gate = if ($failures.Count -eq 0) { 'PASS_SELECTED_TARGET_DONE_1' } else { 'FAIL' }
$lines = [Collections.Generic.List[string]]::new()
foreach ($line in @(
    "PHASE_TOKEN=$PhaseToken",
    "INHERITED_R7_PHASE=$inheritedRole",
    "DONE_STAGE=$($stageSpec.Label)",
    'INDEPENDENT_READ_ONLY_SESSION=YES',
    "READ_ONLY_JTAG_TCL_SHA256=$($script:R1gAcceptedTools.IndependentDoneTcl.Sha256)",
    "R1G_SELECTED_JTAG_CANONICAL_ID=$canonical",
    "R1G_FULL_JTAG_TARGET_PATH=$path",
    "FPGA_PART=$part","FPGA_IDCODE=$idcode","FPGA_DONE=$done",
    "FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT=$programOperations",
    "PROCESS_EXIT_CODE=$exitCode","TIMED_OUT=$(if ($timedOut) {'YES'} else {'NO'})",
    "STOPWATCH_FREQUENCY=$frequency","SESSION_START_TICKS=$startTicks","SESSION_END_TICKS=$endTicks",
    "RAW_TRANSCRIPT_SHA256=$rawSha","INDEPENDENT_DONE_GATE=$gate"
)) { $lines.Add($line) }
foreach ($failure in $failures) { $lines.Add("FAILURE=$failure") }
Write-R1gUtf8NoBom -Path $receiptPath -Lines $lines.ToArray()
$lines
if ($gate -cne 'PASS_SELECTED_TARGET_DONE_1') { exit 1 }

