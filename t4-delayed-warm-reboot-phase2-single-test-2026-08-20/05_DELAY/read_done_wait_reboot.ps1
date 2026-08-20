$ErrorActionPreference='Stop'
$root='C:\FPGA\T4_DELAYED_REBOOT_PHASE2_SINGLE_TEST_20260820'
$vivado='C:\AMDDesignTools\2025.2\Vivado\bin\unwrapped\win64.o\vivado.exe'
$tcl=Join-Path $root '03_FORMAL_BEFORE\read_jtag_identity_done.tcl'
$log=Join-Path $root '04_PROGRAM\POST_PROGRAM_FRESH_DONE.log'
$jou=Join-Path $root '04_PROGRAM\POST_PROGRAM_FRESH_DONE.jou'
$proc=Start-Process -FilePath $vivado -ArgumentList @('-mode','batch','-notrace','-source',$tcl,'-log',$log,'-journal',$jou) -WindowStyle Hidden -Wait -PassThru
if($proc.ExitCode -ne 0){ throw 'POST_PROGRAM_DONE_PROCESS_FAILED' }
$text=[IO.File]::ReadAllText($log)
if($text -notmatch 'READ_ONLY_JTAG_GATE=PASS' -or $text -notmatch 'FPGA_DONE=1'){ throw 'POST_PROGRAM_DONE_GATE_FAILED' }

$referenceUtc=[DateTime]::UtcNow
$sw=[Diagnostics.Stopwatch]::StartNew()
while($sw.Elapsed.TotalSeconds -lt 3.000000){ Start-Sleep -Milliseconds 10 }
$initUtc=[DateTime]::UtcNow
$ticks=$sw.ElapsedTicks
$seconds=$sw.Elapsed.TotalSeconds
[IO.File]::WriteAllLines((Join-Path $root '05_DELAY\MONOTONIC_WAIT.log'),@(
  "DELAY_REFERENCE_UTC=$($referenceUtc.ToString('o'))",
  "STOPWATCH_FREQUENCY=$([Diagnostics.Stopwatch]::Frequency)",
  'REQUIRED_MINIMUM_WAIT_SECONDS=2.810937',
  'TARGET_WAIT_SECONDS=3.000000',
  "ACTUAL_MONOTONIC_WAIT_TICKS=$ticks",
  "ACTUAL_MONOTONIC_WAIT_SECONDS=$($seconds.ToString('F9',[Globalization.CultureInfo]::InvariantCulture))",
  "REBOOT_HELPER_INITIATION_UTC=$($initUtc.ToString('o'))"
),[Text.UTF8Encoding]::new($false))
if($seconds -lt 3.000000){ throw 'MONOTONIC_WAIT_GATE_FAILED' }

$helper=Join-Path $root '01_SECRET_CHANNEL\Invoke-ContextualPlink.ps1'
& $helper -PlinkPath 'C:\FPGA\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe' -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' -RemoteCommand "sudo -S -k -p '' /usr/bin/systemctl reboot" -EvidencePath (Join-Path $root '06_REBOOT\REBOOT_PLINK_REDACTED.log') -ExpectedIp '10.132.1.111' -ExpectedUser 'vcdeagent1' -EvidenceKind DELAYED_REBOOT_SUBMISSION -SendPasswordToStdin -TimeoutSeconds 30
$code=$LASTEXITCODE
[IO.File]::WriteAllText((Join-Path $root '06_REBOOT\REBOOT_HELPER_EXIT.txt'),"REBOOT_HELPER_EXIT=$code`r`n",[Text.UTF8Encoding]::new($false))
exit 0
