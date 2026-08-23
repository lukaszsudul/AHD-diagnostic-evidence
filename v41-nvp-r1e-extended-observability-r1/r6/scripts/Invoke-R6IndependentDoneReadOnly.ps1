[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateSet('FormalBootstrap', 'ArmA', 'ArmB')]
    [string]$Role,
    [Parameter(Mandatory = $true)]
    [string]$EvidencePrefix,
    [ValidateRange(60, 900)]
    [int]$TimeoutSeconds = 600
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$taskRoot = 'C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6'
$scriptPath = Join-Path $taskRoot 'scripts\read_jtag_identity_done_r6_selected.tcl'
$settingsPath = 'C:\AMDDesignTools\2025.2\Vivado\settings64.bat'
$vivadoPath = 'C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$expectedScriptSha = 'A1D967C7306F0C751DC5A41DE3A3D331A0CE92E36BB9430C7D99604FC8432D30'
$expectedSettingsSha = '4E33A3CAECB999C71E92A9A2804170C5A6B71EDF997578AA069AEC65131B50BA'
$expectedVivadoSha = '4F9C05AEA82A71C7086A9E5EDF01BA16EA70255F69CF3420C58B805EC113E994'

function Resolve-CheckedFile([string]$Path) { return (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path }
function Assert-CmdToken([string]$Text) {
    if ($Text -notmatch '^[A-Za-z0-9_:\\\./-]+$') { throw "unsafe cmd.exe token: $Text" }
    return $Text
}
function Assert-ExactHash([string]$Path, [string]$Expected) {
    $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
    if ($actual -cne $Expected) { throw "SHA-256 mismatch for $Path`: $actual" }
}

$roleDirectory = switch ($Role) {
    'FormalBootstrap' { Join-Path $taskRoot '07_FORMAL_BOOTSTRAP' }
    'ArmA' { Join-Path $taskRoot '08_ARM_A_R1E' }
    'ArmB' { Join-Path $taskRoot '09_ARM_B_FORMAL' }
}
$prefix = [IO.Path]::GetFullPath($EvidencePrefix)
$roleFull = [IO.Path]::GetFullPath($roleDirectory)
if (-not $prefix.StartsWith($roleFull + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) {
    throw 'evidence prefix must stay inside the selected R6 phase directory'
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $prefix) -PathType Container)) { throw 'evidence parent directory does not exist' }
$stdoutPath = $prefix + '_stdout_stderr.log'; $vivadoLogPath = $prefix + '.log'
$journalPath = $prefix + '.jou'; $resultPath = $prefix + '_RESULT.txt'
foreach ($path in @($stdoutPath,$vivadoLogPath,$journalPath,$resultPath)) {
    if (Test-Path -LiteralPath $path) { throw "refusing to overwrite independent-DONE evidence: $path" }
}

$script = Resolve-CheckedFile $scriptPath; $settings = Resolve-CheckedFile $settingsPath; $vivado = Resolve-CheckedFile $vivadoPath
Assert-ExactHash $script $expectedScriptSha; Assert-ExactHash $settings $expectedSettingsSha; Assert-ExactHash $vivado $expectedVivadoSha
$tclText = [IO.File]::ReadAllText($script)
if ([regex]::IsMatch($tclText,'(?m)^\s*program_hw_devices\b') -or
    [regex]::IsMatch($tclText,'(?m)^\s*set_property\b') -or
    [regex]::IsMatch($tclText,'(?im)\b(?:FREQUENCY|JTAG_FREQUENCY)\b\s+\S+')) {
    throw 'frozen independent-DONE Tcl contains a programming command'
}
$command = @('call',(Assert-CmdToken $settings),'&&',(Assert-CmdToken $vivado),'-mode','batch','-notrace','-log',(Assert-CmdToken $vivadoLogPath),'-journal',(Assert-CmdToken $journalPath),'-source',(Assert-CmdToken $script)) -join ' '
$psi = [Diagnostics.ProcessStartInfo]::new(); $psi.FileName = "$env:SystemRoot\System32\cmd.exe"
$psi.UseShellExecute = $false; $psi.CreateNoWindow = $true; $psi.RedirectStandardOutput = $true; $psi.RedirectStandardError = $true
$psi.Arguments = '/d /s /c "' + $command + '"'
$process = [Diagnostics.Process]::new(); $process.StartInfo = $psi; $timedOut = $false
$startUtc=[DateTime]::UtcNow.ToString('o'); $startTicks=[Diagnostics.Stopwatch]::GetTimestamp()
try {
    if (-not $process.Start()) { throw 'failed to start supported Vivado launcher' }
    $stdoutTask=$process.StandardOutput.ReadToEndAsync(); $stderrTask=$process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds*1000)) { $timedOut=$true; $process.Kill($true); $process.WaitForExit() }
    $stdout=$stdoutTask.GetAwaiter().GetResult(); $stderr=$stderrTask.GetAwaiter().GetResult(); $exitCode=$process.ExitCode
} finally { $endTicks=[Diagnostics.Stopwatch]::GetTimestamp(); $process.Dispose() }
$rawLines=[string[]]@("ROLE=$Role","UTC_START=$startUtc","UTC_END=$([DateTime]::UtcNow.ToString('o'))","START_TICKS=$startTicks","END_TICKS=$endTicks","TIMED_OUT=$(if($timedOut){'YES'}else{'NO'})","PROCESS_EXIT_CODE=$exitCode","READ_ONLY_JTAG_TCL_SHA256=$expectedScriptSha",'STDOUT_BEGIN',$stdout.TrimEnd(),'STDOUT_END','STDERR_BEGIN',$stderr.TrimEnd(),'STDERR_END')
[IO.File]::WriteAllLines($stdoutPath,$rawLines,[Text.UTF8Encoding]::new($false))
$combined=$stdout+"`n"+$stderr
$required=[ordered]@{
    R6_TOTAL_TARGET_COUNT='1'
    R6_EXACT_CANONICAL_MATCH_COUNT='1'
    R6_TARGET_SELECTOR_STATUS='PASS'
    R6_SELECTED_JTAG_CANONICAL_ID='Xilinx/80802026a98b01'
    R6_FULL_JTAG_TARGET_PATH='localhost:3121/xilinx_tcf/Xilinx/80802026a98b01'
    R6_JTAG_DEVICE_COUNT='1'
    FPGA_PART='xc7a35t'
    FPGA_IDCODE='0362D093'
    FPGA_DONE='1'
    READ_ONLY_JTAG_GATE='PASS_SELECTED_TARGET_DONE_1'
    FPGA_PROGRAM_OPERATIONS_THIS_SCRIPT='0'
}
$failures=[Collections.Generic.List[string]]::new()
foreach($entry in $required.GetEnumerator()){$count=[regex]::Matches($combined,'(?m)^'+[regex]::Escape($entry.Key+'='+$entry.Value)+'\r?$').Count;if($count-ne 1){$failures.Add("$($entry.Key)_EXACT_LINE_COUNT=$count")}}
if($timedOut){$failures.Add('PROCESS_TIMEOUT')};if($exitCode-ne 0){$failures.Add("PROCESS_EXIT_CODE=$exitCode")}
$gate=if($failures.Count-eq 0){'PASS_SELECTED_TARGET_DONE_1'}else{'FAIL'}
$resultLines=[Collections.Generic.List[string]]::new();$resultLines.Add("ROLE=$Role");$resultLines.Add('INDEPENDENT_READ_ONLY_SESSION=YES');$resultLines.Add('FPGA_PROGRAM_INVOCATIONS_THIS_SCRIPT=0');$resultLines.Add("PROCESS_EXIT_CODE=$exitCode");$resultLines.Add("INDEPENDENT_DONE_GATE=$gate")
foreach($failure in $failures){$resultLines.Add("FAILURE=$failure")}
[IO.File]::WriteAllLines($resultPath,$resultLines,[Text.UTF8Encoding]::new($false));$resultLines
if($gate-cne 'PASS_SELECTED_TARGET_DONE_1'){exit 1};exit 0
