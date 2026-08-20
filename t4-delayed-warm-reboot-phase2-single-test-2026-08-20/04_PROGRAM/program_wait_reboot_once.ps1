$ErrorActionPreference='Stop'
$root='C:\FPGA\T4_DELAYED_REBOOT_PHASE2_SINGLE_TEST_20260820'
$vivado='C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat'
$tcl=Join-Path $root '04_PROGRAM\program_phase2_once.tcl'
$log=Join-Path $root '04_PROGRAM\PROGRAM_ONCE.log'
$jou=Join-Path $root '04_PROGRAM\PROGRAM_ONCE.jou'
$vivadoProcess=Start-Process -FilePath $vivado -ArgumentList @('-mode','batch','-notrace','-source',$tcl,'-log',$log,'-journal',$jou) -WindowStyle Hidden -Wait -PassThru
if($vivadoProcess.ExitCode -ne 0){ throw 'PROGRAM_GATE_FAILED' }
$programText=[IO.File]::ReadAllText($log)
if($programText -notmatch 'PROGRAM_RESULT=PASS_EOS_HIGH_DONE_1' -or $programText -notmatch 'FRESH_DONE_OBSERVATION=1'){ throw 'PROGRAM_EVIDENCE_GATE_FAILED' }

$referenceUtc=[DateTime]::UtcNow
$sw=[Diagnostics.Stopwatch]::StartNew()
while($sw.Elapsed.TotalSeconds -lt 3.000000){ Start-Sleep -Milliseconds 10 }
$rebootInitiationUtc=[DateTime]::UtcNow
$elapsedTicks=$sw.ElapsedTicks
$elapsedSeconds=$sw.Elapsed.TotalSeconds
$delayLines=@(
  "DELAY_REFERENCE_UTC=$($referenceUtc.ToString('o'))",
  "STOPWATCH_FREQUENCY=$([Diagnostics.Stopwatch]::Frequency)",
  'REQUIRED_MINIMUM_WAIT_SECONDS=2.810937',
  'TARGET_WAIT_SECONDS=3.000000',
  "ACTUAL_MONOTONIC_WAIT_TICKS=$elapsedTicks",
  "ACTUAL_MONOTONIC_WAIT_SECONDS=$($elapsedSeconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture))",
  "REBOOT_HELPER_INITIATION_UTC=$($rebootInitiationUtc.ToString('o'))"
)
[IO.File]::WriteAllLines((Join-Path $root '05_DELAY\MONOTONIC_WAIT.log'),$delayLines,[Text.UTF8Encoding]::new($false))
if($elapsedSeconds -lt 3.000000){ throw 'MONOTONIC_WAIT_GATE_FAILED' }

$helper=Join-Path $root '01_SECRET_CHANNEL\Invoke-ContextualPlink.ps1'
$plink='C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$hostKey='SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8'
& $helper -PlinkPath $plink -HostKey $hostKey -RemoteCommand "sudo -S -k -p '' /usr/bin/systemctl reboot" -EvidencePath (Join-Path $root '06_REBOOT\REBOOT_PLINK_REDACTED.log') -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' -EvidenceKind DELAYED_REBOOT_SUBMISSION -SendPasswordToStdin -TimeoutSeconds 30
$rebootExit=$LASTEXITCODE
[IO.File]::WriteAllText((Join-Path $root '06_REBOOT\REBOOT_HELPER_EXIT.txt'),"REBOOT_HELPER_EXIT=$rebootExit`r`n",[Text.UTF8Encoding]::new($false))
exit 0
