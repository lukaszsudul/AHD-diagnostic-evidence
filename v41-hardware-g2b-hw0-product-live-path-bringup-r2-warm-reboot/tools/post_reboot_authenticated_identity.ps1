Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$Evidence = Join-Path $TaskRoot 'raw\POST_REBOOT_AUTHENTICATED_IDENTITY.log'
$ReconnectSummary = Join-Path $TaskRoot 'raw\EXACT_IP_RECONNECT_SUMMARY.json'
$OldBootId = '37131b8d-0e38-4b4e-b77a-b3bda55b4e97'

if (Test-Path -LiteralPath $Evidence) { throw 'POST_REBOOT_IDENTITY_EVIDENCE_ALREADY_EXISTS' }
if (-not (Test-Path -LiteralPath $ReconnectSummary -PathType Leaf)) { throw 'RECONNECT_SUMMARY_MISSING' }
$summary = Get-Content -LiteralPath $ReconnectSummary -Raw | ConvertFrom-Json
if ($summary.result -ne 'PASS' -or -not [bool]$summary.ssh_disconnect_observed -or -not [bool]$summary.tcp_reconnect_observed) {
    throw 'RECONNECT_SUMMARY_NOT_PASS'
}
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or $lock.remote_reboot_command_status -ne 'SCHEDULE_ACKNOWLEDGED_NO_RETRY' -or
    [int]$lock.remote_reboot_command_deliveries -ne 1 -or [int]$lock.warm_reboots_executed -ne 0) {
    throw 'CONTROLLER_LOCK_NOT_READY_FOR_POST_REBOOT_IDENTITY'
}

$remoteCommand = @"
set -euo pipefail
echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=POST_REBOOT_AUTHENTICATED_IDENTITY
echo UTC=`$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
test "`$(hostname)" = VCDE-DUT-1
test "`$(id -u)" = 1000
echo HOSTNAME=`$(hostname)
echo REMOTE_USER=`$(id -un)
echo REMOTE_UID=`$(id -u)
test "`$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
echo MACHINE_ID=`$(cat /etc/machine-id)
new_boot_id=`$(cat /proc/sys/kernel/random/boot_id)
test "`$new_boot_id" != $OldBootId
echo PRE_REBOOT_BOOT_ID=$OldBootId
echo POST_REBOOT_BOOT_ID=`$new_boot_id
echo BOOT_ID_CHANGED=YES
echo UPTIME_SECONDS=`$(cut -d' ' -f1 /proc/uptime)
echo SYSTEM_STATE=`$(systemctl is-system-running 2>/dev/null || true)
echo KERNEL=`$(uname -r)
echo BOOT_LIST_BEGIN
journalctl --list-boots --no-pager 2>&1 || true
echo BOOT_LIST_END
echo WHO_BOOT_BEGIN
who -b 2>&1 || true
echo WHO_BOOT_END
echo RESULT=PASS
"@

$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_POST_REBOOT_AUTHENTICATED_IDENTITY' `
    -TimeoutSeconds 30)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
