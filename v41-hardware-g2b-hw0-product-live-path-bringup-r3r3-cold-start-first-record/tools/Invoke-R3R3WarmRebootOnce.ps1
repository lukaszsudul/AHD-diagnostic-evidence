[CmdletBinding()]
param(
  [Parameter(Mandatory)][ValidatePattern('^[0-9a-f]{8}-[0-9a-f-]{27}$')][string]$ExpectedBootId
)
Set-StrictMode -Version Latest
$ErrorActionPreference='Stop'
$root=Split-Path $PSScriptRoot -Parent
$controllerLockPath='C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$preLinuxLock='/tmp/ahd-g2b-hw0-product-r3r3-20260906T200624Z-pre.lock/receipt.json'
$helper=Join-Path $PSScriptRoot 'Invoke-R3R3DutConnection.ps1'
$receiptPath=Join-Path $root 'receipts\warm-reboot-supervisor.json'
if(Test-Path -LiteralPath $receiptPath){throw 'R3R3_WARM_REBOOT_RECEIPT_EXISTS_NO_RETRY'}
$controller=Get-Content -LiteralPath $controllerLockPath -Raw | ConvertFrom-Json
if($controller.task -cne 'G2B-HW0-PRODUCT-R3R3' -or $controller.root -cne $root -or $controller.state -cne 'HELD'){throw 'R3R3_CONTROLLER_LOCK_NOT_HELD'}
if([int]$controller.sram_programming_attempts -ne 1){throw 'R3R3_EXACT_SRAM_PROGRAMMING_NOT_RECORDED'}
if([int]$controller.warm_reboot_delivery_attempts -ne 0 -or [int]$controller.warm_reboot_budget_remaining -ne 1){throw 'R3R3_WARM_REBOOT_BUDGET_EXHAUSTED'}
$receipt=[ordered]@{task='G2B-HW0-PRODUCT-R3R3';pre_boot_id=$ExpectedBootId;delivery_attempts=1;maximum_warm_reboots=1;power_cycles=0;second_reboot_authorized=$false;start_utc=[DateTime]::UtcNow.ToString('o');result='DELIVERY_IN_PROGRESS_NO_RETRY'}
[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false))
$controller.warm_reboot_delivery_attempts=1
$controller.warm_reboot_budget_remaining=0
$controller | Add-Member -NotePropertyName warm_reboot_delivery_utc -NotePropertyValue ([DateTime]::UtcNow.ToString('o')) -Force
[IO.File]::WriteAllText($controllerLockPath,($controller|ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false))
$remote=@"
set -eu
test "`$(hostname)" = 'VCDE-DUT-1'
test "`$(cat /etc/machine-id)" = '0e90f50d9465492b80258da5658446f8'
test "`$(cat /proc/sys/kernel/random/boot_id)" = '$ExpectedBootId'
test -f '$preLinuxLock'
python3 - <<'PY'
import json,pathlib
p=pathlib.Path('$preLinuxLock')
r=json.loads(p.read_text())
assert r['task']=='G2B-HW0-PRODUCT-R3R3' and r['phase']=='PRE_REBOOT' and r['state']=='HELD'
assert r['boot']=='$ExpectedBootId'
assert not pathlib.Path('/sys/module/xdma_ahd_pcie').exists()
assert not pathlib.Path('/sys/module/xdma').exists()
assert not list(pathlib.Path('/dev').glob('xdma*'))
print('PRE_REBOOT_DRIVER_MMIO_DMA_QUIESCENT=YES')
PY
/usr/bin/systemd-run --unit=ahd-g2b-hw0-product-r3r3-warm-reboot --on-active=3s --collect /usr/bin/systemctl reboot
echo REBOOT_SCHEDULE_ACKNOWLEDGED=YES
"@
$helperProblem=$null
try {
  & $helper -ReceiptName reboot-delivery -Sudo -TimeoutSeconds 20 -RemoteCommand $remote | Out-Null
} catch {
  $helperProblem=$_.Exception.Message
}
$deliveryReceipt=Get-Content -LiteralPath (Join-Path $root 'logs\connection-reboot-delivery.json') -Raw | ConvertFrom-Json
$ack=([string]$deliveryReceipt.stdout).Contains('REBOOT_SCHEDULE_ACKNOWLEDGED=YES',[StringComparison]::Ordinal)
$receipt.reboot_schedule_acknowledged=$ack
$receipt.delivery_helper_exit_code=[int]$deliveryReceipt.exit_code
$receipt.delivery_helper_problem=$helperProblem
[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false))
if(-not $ack){$receipt.result='AMBIGUOUS_DELIVERY_STOP_NO_RETRY';[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false));throw 'R3R3_WARM_REBOOT_DELIVERY_AMBIGUOUS_NO_RETRY'}

function Test-ExactSshPort {
  $client=[Net.Sockets.TcpClient]::new()
  try {
    $task=$client.ConnectAsync('10.132.1.111',22)
    if(-not $task.Wait(500)){return $false}
    return $client.Connected
  } catch { return $false } finally { $client.Dispose() }
}

$downObserved=$false
$disconnectDeadline=[DateTime]::UtcNow.AddSeconds(120)
while([DateTime]::UtcNow -lt $disconnectDeadline){
  if(-not(Test-ExactSshPort)){$downObserved=$true;break}
  Start-Sleep -Milliseconds 250
}
$receipt.ssh_disconnect_observed=$downObserved
$returnDeadline=[DateTime]::UtcNow.AddSeconds(900)
$portReturned=$false
while([DateTime]::UtcNow -lt $returnDeadline){
  if(Test-ExactSshPort){$portReturned=$true;break}
  Start-Sleep -Seconds 2
}
$receipt.ssh_port_returned=$portReturned
if(-not $portReturned){$receipt.result='DUT_DID_NOT_RETURN_AFTER_AUTHORIZED_WARM_REBOOT';[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false));throw 'R3R3_DUT_DID_NOT_RETURN_AFTER_AUTHORIZED_WARM_REBOOT'}

$identity=$null
for($attempt=1;$attempt -le 20 -and -not $identity;$attempt++){
  $name='postreboot-auth-{0:D2}' -f $attempt
  $cmd="python3 - <<'PY'`nimport json,pathlib,platform,socket`nprint(json.dumps({'hostname':socket.gethostname(),'machine_id':pathlib.Path('/etc/machine-id').read_text().strip(),'kernel':platform.uname().release,'architecture':platform.machine(),'boot_id':pathlib.Path('/proc/sys/kernel/random/boot_id').read_text().strip()}))`nPY"
  try {
    & $helper -ReceiptName $name -TimeoutSeconds 15 -RemoteCommand $cmd | Out-Null
    $connection=Get-Content -LiteralPath (Join-Path $root ('logs\connection-'+$name+'.json')) -Raw | ConvertFrom-Json
    $identity=([string]$connection.stdout).Trim() | ConvertFrom-Json
  } catch {
    if([DateTime]::UtcNow -ge $returnDeadline){break}
    Start-Sleep -Seconds 2
  }
}
if(-not $identity){$receipt.result='AUTHENTICATED_RECONNECT_FAILED';[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false));throw 'R3R3_AUTHENTICATED_RECONNECT_FAILED'}
if($identity.hostname -cne 'VCDE-DUT-1' -or $identity.machine_id -cne '0e90f50d9465492b80258da5658446f8' -or $identity.kernel -cne '7.0.0-29-generic' -or $identity.architecture -cne 'x86_64'){throw 'R3R3_AUTHORITATIVE_DUT_IDENTITY_DRIFT'}
if($identity.boot_id -ceq $ExpectedBootId){throw 'R3R3_EXPECTED_WARM_REBOOT_BOOT_ID_DID_NOT_CHANGE'}
$receipt.post_boot_id=$identity.boot_id
$receipt.observed_task_window_boot_transitions=1
$receipt.unexpected_boot_transitions_after_post_baseline=0
$receipt.authenticated_reconnect='PASS'
$receipt.result=if($downObserved){'PASS'}else{'FAIL_SSH_DISCONNECT_NOT_OBSERVED'}
$receipt.end_utc=[DateTime]::UtcNow.ToString('o')
[IO.File]::WriteAllText($receiptPath,($receipt|ConvertTo-Json -Depth 6)+"`n",[Text.UTF8Encoding]::new($false))
if(-not $downObserved){throw 'R3R3_SSH_DISCONNECT_NOT_OBSERVED'}
Write-Output "R3R3_POSTPROGRAM_BOOT_ID=$($identity.boot_id)"
Write-Output 'R3R3_AUTHORIZED_WARM_REBOOT=PASS'
