[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidateSet('Bootstrap','A1','B1','A2','B2','A3','B3')][string]$PhaseToken,
    [Parameter(Mandatory)][string]$BindingPath,
    [string]$ConfiguredImageReceiptPath = '',
    [ValidatePattern('^$|^[0-9A-Fa-f]{64}$')][string]$ExpectedConfiguredImageReceiptSha256 = '',
    [ValidateRange(60,7200)][int]$TimeoutSeconds = 1800
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'R1hCampaignCommon.ps1')

function Cmd([string]$Value) {
    if ($Value -notmatch '^[A-Za-z0-9_:\\\./-]+$') { throw "unsafe command token: $Value" }
    return $Value
}
function Unique([string]$Text,[string]$Key) {
    $matches=[regex]::Matches($Text,'(?m)^'+[regex]::Escape($Key)+'=([^\r\n]*)\r?$')
    if($matches.Count-ne1){throw "$Key exact-line count is $($matches.Count), expected 1"}
    return $matches[0].Groups[1].Value
}

$binding = Get-R1hBindingDocument -BindingPath $BindingPath
Assert-R1hAcceptedToolSet
$phase = Get-R1hPhaseSpec $PhaseToken
$directory = Assert-R1hPhaseDirectory $phase
$image = Get-R1hImageBinding -Document $binding -PhaseSpec $phase
$globalReceipt = Join-Path $script:R1hPrecheckRoot 'GLOBAL_PROGRAM_RETRY_RESERVATION.txt'
$globalAttempt = Join-Path $script:R1hPrecheckRoot 'GLOBAL_PROGRAM_RETRY_REESTABLISH_ATTEMPT.marker'
foreach($path in @($globalReceipt,$globalAttempt)){
    if(Test-Path -LiteralPath $path){throw 'global R1h-R4 program retry/re-establishment budget is already consumed'}
}

$reservation = Join-Path $directory 'PROGRAM_ATTEMPT_RESERVATION.txt'
$supervisor = Join-Path $directory 'PROGRAM_SUPERVISOR.log'
$vivadoLog = Join-Path $directory 'PROGRAM_VIVADO.log'
$vivadoJournal = Join-Path $directory 'PROGRAM_VIVADO.jou'
foreach($path in @($reservation,$supervisor)){
    if(-not(Test-Path -LiteralPath $path -PathType Leaf)){throw "primary failed-attempt evidence absent: $path"}
}
if(Test-Path -LiteralPath (Join-Path $directory 'PROGRAM_TIMING_RECEIPT.txt')){throw 'primary attempt passed; programming retry is forbidden'}
$primaryText=[IO.File]::ReadAllText($supervisor)
if((Unique $primaryText PROGRAM_SUPERVISOR_GATE)-cne'FAIL_PRIMARY_ATTEMPT'){throw 'primary failure did not reach the retry-eligible supervisor gate'}
$classification=Unique $primaryText PROGRAM_RESULT
if($classification-cnotin@('FAIL_BEFORE_PROGRAM','FAIL_OBSERVER_GATE')){throw "primary classification is not retry-eligible infrastructure: $classification"}
foreach($forbidden in @('WARM_REBOOT_EVIDENCE.log','HOST_CYCLE_RECEIPT.txt','PRELOADER_EVIDENCE.log','LOADER_EVIDENCE.log','RUNTIME_PROVENANCE_EVIDENCE.log','TELEMETRY_EVIDENCE.log','FINAL_DONE_RECEIPT.txt')){
    if(Test-Path -LiteralPath (Join-Path $directory $forbidden)){throw "downstream action followed primary failure; retry forbidden: $forbidden"}
}
$reservationText=[IO.File]::ReadAllText($reservation)
$expectedBitSha=[string]$image.sha256
if((Unique $reservationText BIT_SHA256)-cne$expectedBitSha){throw 'primary attempt bit identity differs from frozen binding'}
$bitPath=(Resolve-Path -LiteralPath ([string]$image.path) -ErrorAction Stop).Path
if((Get-FileHash -LiteralPath $bitPath -Algorithm SHA256).Hash-cne$expectedBitSha){throw 'same-bit rehash failed before retry'}

Write-R1hUtf8NoBom -Path $globalAttempt -Lines @(
    "RETRY_PHASE_TOKEN=$PhaseToken","PRIMARY_PROGRAM_RESULT=$classification",
    "PRIMARY_SUPERVISOR_SHA256=$((Get-FileHash -LiteralPath $supervisor -Algorithm SHA256).Hash)",
    'NO_REBOOT_OR_TELEMETRY_FOLLOWED=YES','REESTABLISH_ATTEMPTS_MAX=1',
    "ATTEMPT_UTC=$([DateTime]::UtcNow.ToString('o'))")

$prefix='PROGRAM_RETRY_REESTABLISH'
$raw=Join-Path $directory ($prefix+'_RAW.log')
$log=Join-Path $directory ($prefix+'_VIVADO.log')
$jou=Join-Path $directory ($prefix+'_VIVADO.jou')
$csv=Join-Path $directory ($prefix+'_MATRIX.csv')
$targetProps=Join-Path $directory ($prefix+'_TARGET_PROPERTIES.tsv')
$deviceProps=Join-Path $directory ($prefix+'_DEVICE_PROPERTIES.tsv')
foreach($path in @($raw,$log,$jou,$csv,$targetProps,$deviceProps)){
    if(Test-Path -LiteralPath $path){throw "retry re-establishment output already exists: $path"}
}
$command=@('call',(Cmd $script:R1hAcceptedTools.VivadoSettings.Path),'&&',(Cmd $script:R1hAcceptedTools.VivadoLauncher.Path),'-mode','batch','-notrace','-log',(Cmd $log),'-journal',(Cmd $jou),'-source',(Cmd $script:R1hAcceptedTools.JtagReconfirmationTcl.Path),'-tclargs',(Cmd $csv),(Cmd $targetProps),(Cmd $deviceProps))-join' '
$psi=[Diagnostics.ProcessStartInfo]::new();$psi.FileName="$env:SystemRoot\System32\cmd.exe";$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true;$psi.WorkingDirectory=$directory;$psi.Arguments='/d /s /c "'+$command+'"'
$process=[Diagnostics.Process]::new();$process.StartInfo=$psi;$timedOut=$false
try{
    if(-not$process.Start()){throw 'retry target re-establishment Vivado launch failed'}
    $stdoutTask=$process.StandardOutput.ReadToEndAsync();$stderrTask=$process.StandardError.ReadToEndAsync()
    if(-not$process.WaitForExit(600000)){$timedOut=$true;$process.Kill($true);$process.WaitForExit()}
    $stdout=$stdoutTask.GetAwaiter().GetResult();$stderr=$stderrTask.GetAwaiter().GetResult();$rc=$process.ExitCode
}finally{$process.Dispose()}
Write-R1hUtf8NoBom -Path $raw -Lines @("PROCESS_EXIT_CODE=$rc","TIMED_OUT=$(if($timedOut){'YES'}else{'NO'})",'STDOUT_BEGIN',$stdout.TrimEnd(),'STDOUT_END','STDERR_BEGIN',$stderr.TrimEnd(),'STDERR_END')
$combined=$stdout+"`n"+$stderr
if($timedOut-or$rc-ne0-or(Unique $combined R7_JTAG_RECONFIRMATION_SESSION_GATE)-cne'PASS'-or
   (Unique $combined R7_SELECTED_JTAG_CANONICAL_ID)-cne$script:R1hCanonicalTarget-or
   (Unique $combined R7_FULL_JTAG_TARGET_PATH)-cne[string]$binding.selectedFullJtagTargetPath-or
   (Unique $combined FPGA_PROGRAM_INVOCATIONS_THIS_SESSION)-cne'0'-or
   (Unique $combined JTAG_FREQUENCY_CHANGED)-cne'NO'){
    throw 'fresh same-target retry re-establishment failed'
}
$rows=@(Import-Csv -LiteralPath $csv)
if($rows.Count-ne5-or@($rows|Where-Object{[string]$_.target_count-cne'1'-or[string]$_.device_count-cne'1'-or[string]$_.part-cne'xc7a35t'-or[string]$_.idcode-cne'0362D093'-or[string]$_.target_path-cne[string]$binding.selectedFullJtagTargetPath-or[string]$_.refresh_result-cne'PASS'}).Count-ne0){throw 'fresh retry target/part/IDCODE matrix failed'}
if((Get-FileHash -LiteralPath $bitPath -Algorithm SHA256).Hash-cne$expectedBitSha){throw 'same-bit rehash failed after retry target re-establishment'}

Write-R1hUtf8NoBom -Path $globalReceipt -Lines @(
    'GLOBAL_PROGRAM_RETRY_RESERVED=YES',"RETRY_PHASE_TOKEN=$PhaseToken",
    'RETRY_ELIGIBILITY_GATE=PASS_INFRASTRUCTURE_ONLY',"PRIMARY_PROGRAM_RESULT=$classification",
    'NO_REBOOT_OR_TELEMETRY_FOLLOWED=YES','SAME_TARGET_PART_IDCODE_REESTABLISHED=YES',
    "R1H_FULL_JTAG_TARGET_PATH=$([string]$binding.selectedFullJtagTargetPath)",
    'FPGA_PART=xc7a35t','FPGA_IDCODE=0362D093',"SAME_BIT_SHA256=$expectedBitSha",
    "REESTABLISH_RAW_SHA256=$((Get-FileHash -LiteralPath $raw -Algorithm SHA256).Hash)",
    'PHYSICAL_ACTIONS=0','PROGRAM_RETRY_BUDGET_CONSUMED=1')

$archive=Join-Path $directory 'PRIMARY_FAILED_ATTEMPT'
if(Test-Path -LiteralPath $archive){throw 'primary failed-attempt archive already exists'}
New-Item -ItemType Directory -Path $archive | Out-Null
foreach($path in @($reservation,$supervisor,$vivadoLog,$vivadoJournal)){
    if(Test-Path -LiteralPath $path -PathType Leaf){Move-Item -LiteralPath $path -Destination (Join-Path $archive (Split-Path -Leaf $path))}
}

$programArgs=@{
    PhaseToken=$PhaseToken;BindingPath=$BindingPath;TimeoutSeconds=$TimeoutSeconds;GlobalRetryAttempt=$true
}
if($PhaseToken-ne'Bootstrap'){
    $programArgs.ConfiguredImageReceiptPath=$ConfiguredImageReceiptPath
    $programArgs.ExpectedConfiguredImageReceiptSha256=$ExpectedConfiguredImageReceiptSha256
}
& (Join-Path $PSScriptRoot 'Invoke-R1hProgramOnce.ps1') @programArgs
exit $LASTEXITCODE
