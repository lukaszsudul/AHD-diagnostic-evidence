[CmdletBinding()]
param()

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$taskRoot='C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST';$scriptsRoot=Join-Path $taskRoot 'scripts';$phaseRoot=Join-Path $taskRoot 'hardware\02_A1'
$gatePath=Join-Path $taskRoot 'hardware\R1H_R4_A1_WRAPPER_RECOVERY_OFFLINE_GATE.txt'
$identityPath=Join-Path $taskRoot 'hardware\R1H_R4_TASK_LOCAL_SCRIPT_IDENTITY_POST_A1_FIX.csv'
foreach($p in @($gatePath,$identityPath)){if(Test-Path -LiteralPath $p){throw "refusing to overwrite A1 offline audit: $p"}}
function Map([string]$Path){$m=@{};foreach($l in [IO.File]::ReadAllLines($Path)){if($l-match'^([A-Z0-9_]+)=(.*)$'){if($m.ContainsKey($Matches[1])){throw "duplicate $($Matches[1]) in $Path"};$m[$Matches[1]]=$Matches[2]}};$m}
$fail=[Collections.Generic.List[string]]::new()
$names=@('R1hCampaignCommon.ps1','Invoke-R1hProgramOnce.ps1','Invoke-R1hIndependentDoneReadOnly.ps1','Wait-R1hProgramMinimum.ps1','Invoke-R1hHostStep.ps1','Invoke-R1hTelemetryReadOnly.ps1','New-R1hConfiguredImageReceipt.ps1','Invoke-R1hR4JtagSafetyReadOnly.ps1','Invoke-R1hR4MinimalHostSafetyReadOnly.ps1','New-R1hR4HardwareBinding.ps1','Invoke-R1hR4EligibleProgramRetryOnce.ps1','New-R1hR4ImplementationLaunchRelease.ps1','Recover-R1hR4JtagSafetyReceiptFromCompletedSession.ps1','Recover-R1hR4BootstrapProgramReceipts.ps1','Recover-R1hR4A1ProgramReceipts.ps1','Test-R1hR4HardwarePrepOffline.ps1','Test-R1hR4WrapperRecoveryOffline.ps1','Test-R1hR4A1RecoveryOffline.ps1')
$ids=[Collections.Generic.List[object]]::new()
foreach($n in $names){$p=Join-Path $scriptsRoot $n;try{$t=$null;$e=$null;[void][Management.Automation.Language.Parser]::ParseFile($p,[ref]$t,[ref]$e);if($e.Count){throw(($e|ForEach-Object Message)-join'; ')};$i=Get-Item -LiteralPath $p;$ids.Add([pscustomobject]@{name=$n;path=$i.FullName;bytes=$i.Length;sha256=(Get-FileHash -LiteralPath $p -Algorithm SHA256).Hash;parse='PASS'})}catch{$fail.Add("PARSE=${n}:$($_.Exception.Message)")}}
$ids|Export-Csv -LiteralPath $identityPath -NoTypeInformation -Encoding utf8NoBOM
try{
    $programPath=Join-Path $scriptsRoot 'Invoke-R1hProgramOnce.ps1';$t=$null;$e=$null;$ast=[Management.Automation.Language.Parser]::ParseFile($programPath,[ref]$t,[ref]$e)
    $fn=$ast.Find({param($node)$node-is[Management.Automation.Language.FunctionDefinitionAst]-and$node.Name-ceq'Add-ObserverRecord'},$true);if($null-eq$fn){throw'Add-ObserverRecord absent'};Invoke-Expression $fn.Extent.Text
    $r=[Collections.Generic.List[object]]::new();[long]$script:observerSequence=0;Add-ObserverRecord -Records $r -Stream STDOUT -Line ''
    if($r.Count-ne1-or$r[0].Line-cne''){throw'empty initial record/line not preserved'}
    $text=[IO.File]::ReadAllText($programPath)
    foreach($required in @('[AllowEmptyCollection()][Collections.Generic.List[object]]$Records','[AllowEmptyString()][string]$Line')){if(-not$text.Contains($required,[StringComparison]::Ordinal)){throw"missing wrapper allowance: $required"}}
}catch{$fail.Add("OBSERVER_FIXTURE=$($_.Exception.Message)")}
try{
    . (Join-Path $scriptsRoot 'R1hCampaignCommon.ps1');$fixture=Join-Path $taskRoot 'hardware\R1H_R4_EMPTY_STREAM_SERIALIZATION_FIXTURE.txt';$lines=[IO.File]::ReadAllLines($fixture)
    if($lines.Count-ne6-or$lines[4]-cne''-or(Get-FileHash -LiteralPath $fixture -Algorithm SHA256).Hash-cne'AF347CA7171CE789B830B1AF49537740B1528F3FBB2E5220F7EC0C9A4ABF11B7'){throw'empty stream fixture mismatch'}
}catch{$fail.Add("SERIALIZER_FIXTURE=$($_.Exception.Message)")}
try{
    $timingPath=Join-Path $phaseRoot 'PROGRAM_TIMING_RECEIPT.txt';$recoveryPath=Join-Path $phaseRoot 'PROGRAM_POSTPROCESS_RECOVERY_RECEIPT.txt';$supervisorPath=Join-Path $phaseRoot 'PROGRAM_SUPERVISOR.log';$timing=Map $timingPath;$recovery=Map $recoveryPath
    $expected=@{PHASE_TOKEN='A1';PROGRAM_RESULT='PASS_STARTUP_HIGH_DONE_1';PROGRAM_INVOCATIONS='1';PROGRAM_RETRIES='0';MODE_AWARE_PREPROGRAM_GATE='PASS';PREPROGRAM_DONE_SAMPLES='1,1,1,1,1';PREPROGRAM_DONE_VALUE='1';REQUIRED_MINIMUM_WAIT_SECONDS='33.536673744';TIMING_REFERENCE_CLASS='CONSERVATIVE_POSTPROCESS_ANCHOR_AFTER_COMPLETED_PROGRAM';TIMING_RECEIPT_STATUS='PASS_IMMUTABLE_WAIT_INPUT_RECOVERED_POSTPROCESS_ONLY'}
    foreach($x in $expected.GetEnumerator()){if([string]$timing[$x.Key]-cne$x.Value){throw"timing mismatch $($x.Key)"}}
    if($timing.PROGRAM_POSTPROCESS_RECOVERY_RECEIPT_SHA256-cne(Get-FileHash -LiteralPath $recoveryPath -Algorithm SHA256).Hash-or$timing.PROGRAM_SUPERVISOR_LOG_SHA256-cne(Get-FileHash -LiteralPath $supervisorPath -Algorithm SHA256).Hash){throw'A1 timing dependency hash mismatch'}
    [long]$a=0;[long]$b=0;[long]$c=0;if(-not[long]::TryParse($timing.PROGRAM_RETURN_MARKER_TICKS,[ref]$a)-or-not[long]::TryParse($timing.FRESH_DONE_MARKER_TICKS,[ref]$b)-or-not[long]::TryParse($timing.WAIT_REFERENCE_TICKS,[ref]$c)-or$c-le0-or$a-ne$c-or$b-ne$c-or$c-gt[Diagnostics.Stopwatch]::GetTimestamp()){throw'A1 conservative anchor mismatch'}
    $recoveryExpected=@{PHASE_TOKEN='A1';RECOVERY_CLASS='POSTPROCESS_ONLY_COMPLETED_VIVADO_CHILD';ORIGINAL_WRAPPER_RESULT='FAIL_TASK_LOCAL_EMPTY_OBSERVER_LINE_BINDING';VIVADO_CHILD_TERMINAL_RESULT='PASS_DONE_1';VIVADO_CHILD_NORMAL_EXIT='YES';PROGRAM_INVOCATIONS='1';PROGRAM_RETRIES='0';SECOND_PROGRAM_SESSION_RUN='NO';REBOOT_AFTER_WRAPPER_FAILURE='NO';TELEMETRY_AFTER_WRAPPER_FAILURE='NO';RECOVERY_GATE='PASS_NO_HARDWARE_ACCESS'}
    foreach($x in $recoveryExpected.GetEnumerator()){if([string]$recovery[$x.Key]-cne$x.Value){throw"recovery mismatch $($x.Key)"}}
    $deps=@{PROGRAM_ATTEMPT_RESERVATION_SHA256=(Join-Path $phaseRoot 'PROGRAM_ATTEMPT_RESERVATION.txt');PROGRAM_VIVADO_LOG_SHA256=(Join-Path $phaseRoot 'PROGRAM_VIVADO.log');PROGRAM_VIVADO_JOURNAL_SHA256=(Join-Path $phaseRoot 'PROGRAM_VIVADO.jou');HARDWARE_BINDING_SHA256=(Join-Path $taskRoot 'hardware\R1H_R4_HARDWARE_BINDING.json');CONFIGURED_RECEIPT_SHA256=(Join-Path $taskRoot 'hardware\FORMAL_START_READY_RECEIPT.txt');R1H_BIT_SHA256=(Join-Path $taskRoot 'implementation\ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit')}
    foreach($x in $deps.GetEnumerator()){if([string]$recovery[$x.Key]-cne(Get-FileHash -LiteralPath $x.Value -Algorithm SHA256).Hash){throw"dependency mismatch $($x.Key)"}}
}catch{$fail.Add("A1_RECEIPT_FIXTURE=$($_.Exception.Message)")}
$gate=if($fail.Count-eq0){'PASS'}else{'FAIL'};$out=[Collections.Generic.List[string]]::new()
foreach($l in @("R1H_R4_A1_WRAPPER_RECOVERY_OFFLINE_GATE=$gate","TASK_LOCAL_SCRIPT_IDENTITY_SHA256=$((Get-FileHash -LiteralPath $identityPath -Algorithm SHA256).Hash)",'POWERSHELL_PARSE=PASS_ALL','EMPTY_INITIAL_OBSERVER_AND_LINE=PASS','EMPTY_STREAM_SERIALIZATION=PASS','A1_RECOVERED_RECEIPTS=PASS','WAIT_SCRIPT_COMPATIBILITY=PASS_CONSERVATIVE_MONOTONIC_REFERENCE',"A1_PROGRAM_TIMING_SHA256=$((Get-FileHash -LiteralPath (Join-Path $phaseRoot 'PROGRAM_TIMING_RECEIPT.txt') -Algorithm SHA256).Hash)","A1_PROGRAM_SUPERVISOR_SHA256=$((Get-FileHash -LiteralPath (Join-Path $phaseRoot 'PROGRAM_SUPERVISOR.log') -Algorithm SHA256).Hash)","A1_PROGRAM_RECOVERY_SHA256=$((Get-FileHash -LiteralPath (Join-Path $phaseRoot 'PROGRAM_POSTPROCESS_RECOVERY_RECEIPT.txt') -Algorithm SHA256).Hash)",'OFFLINE_AUDIT_HARDWARE_ACTIONS=0','OFFLINE_AUDIT_JTAG_SESSIONS=0','OFFLINE_AUDIT_SSH_SESSIONS=0')){$out.Add($l)};foreach($f in $fail){$out.Add("FAILURE=$f")};[IO.File]::WriteAllLines($gatePath,$out,[Text.UTF8Encoding]::new($false));$out;if($gate-cne'PASS'){exit 1}
