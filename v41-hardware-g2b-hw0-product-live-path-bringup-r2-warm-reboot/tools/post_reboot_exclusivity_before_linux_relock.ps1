Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$ControllerLock = 'C:\FPGA\.AHD_DUT_EXCLUSIVE_LOCK\receipt.json'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$Evidence = Join-Path $TaskRoot 'raw\POST_REBOOT_EXCLUSIVITY_BEFORE_LINUX_RELOCK.log'
$ExpectedBootId = '52b0bf13-e9d1-4558-ae13-d08f4ecc8dac'

if (Test-Path -LiteralPath $Evidence) { throw 'POST_REBOOT_EXCLUSIVITY_EVIDENCE_ALREADY_EXISTS' }
$lock = Get-Content -LiteralPath $ControllerLock -Raw | ConvertFrom-Json
if ($lock.state -ne 'HELD' -or [int]$lock.warm_reboots_executed -ne 1 -or
    $lock.post_reboot_boot_id -ne $ExpectedBootId -or
    $lock.remote_reboot_command_status -ne 'EXECUTION_CONFIRMED_NO_RETRY') {
    throw 'CONTROLLER_LOCK_NOT_READY_FOR_POST_REBOOT_EXCLUSIVITY'
}

$remoteCommand = @"
set -euo pipefail
echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=POST_REBOOT_EXCLUSIVITY_BEFORE_LINUX_RELOCK
echo UTC=`$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
test "`$(hostname)" = VCDE-DUT-1
test "`$(id -u)" = 1000
test "`$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
test "`$(cat /proc/sys/kernel/random/boot_id)" = $ExpectedBootId
echo HOSTNAME=`$(hostname)
echo REMOTE_USER=`$(id -un)
echo BOOT_ID=`$(cat /proc/sys/kernel/random/boot_id)
echo UPTIME_SECONDS=`$(cut -d' ' -f1 /proc/uptime)
echo RELEVANT_PROCESS_COMMANDS_BEGIN
ps -eo pid=,ppid=,user=,stat=,comm= --sort=pid | awk 'BEGIN {IGNORECASE=1} `$5 ~ /^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test)$/ {print}' || true
echo RELEVANT_PROCESS_COMMANDS_END
xdma_module_count=`$(awk '`$1 == "xdma" {count++} END {print count+0}' /proc/modules)
echo XDMA_MODULE_COUNT=`$xdma_module_count
if [ -d /sys/bus/pci/drivers/xdma ]; then echo XDMA_DRIVER_SYSFS=PRESENT; else echo XDMA_DRIVER_SYSFS=ABSENT; fi
shopt -s nullglob
nodes=(/dev/xdma*)
echo XDMA_DEVICE_NODE_COUNT=`${#nodes[@]}
for node in "`${nodes[@]}"; do ls -l -- "`$node"; fuser -v -- "`$node" 2>&1 || true; done
echo TASK_LOCKS_BEGIN
find /tmp /run/lock /var/lock -maxdepth 2 -type d \( -iname 'ahd*.lock' -o -iname 'g2b*.lock' -o -iname 'xdma*.lock' -o -iname 'fpga*.lock' \) -printf '%p\n' 2>/dev/null | sort || true
echo TASK_LOCKS_END
if [ -f /tmp/ahd-g2b-hw0-product-r2.lock/receipt.json ]; then
  echo PRE_REBOOT_LINUX_LOCK=PERSISTED
  cat /tmp/ahd-g2b-hw0-product-r2.lock/receipt.json
else
  echo PRE_REBOOT_LINUX_LOCK=ABSENT_AFTER_REBOOT
fi
if [ -e /tmp/ahd-g2b-hw0-product-r2-post-reboot.lock ]; then echo POST_REBOOT_LINUX_LOCK=PREEXISTING; else echo POST_REBOOT_LINUX_LOCK=ABSENT_READY_TO_ACQUIRE; fi
echo LOGGED_IN_USERS_BEGIN
who || true
echo LOGGED_IN_USERS_END
echo REBOOT_INHIBITORS_BEGIN
systemd-inhibit --list --no-pager 2>&1 || true
echo REBOOT_INHIBITORS_END
echo EXACT_AHD_ENDPOINTS_BEGIN
lspci -Dnnd 10ee:7011 || true
echo EXACT_AHD_ENDPOINTS_END
endpoint_count=`$(lspci -Dnnd 10ee:7011 | wc -l)
echo EXACT_AHD_ENDPOINT_COUNT=`$endpoint_count
echo RELEVANT_PCIE_FUNCTIONS_BEGIN
lspci -Dnn | awk 'BEGIN {IGNORECASE=1} /xilinx|amd|advanced micro|display|vga|multimedia|video/ {print}' || true
echo RELEVANT_PCIE_FUNCTIONS_END
echo HISTORICAL_ROOT_PORT_BEGIN
lspci -Dnnvv -s 0000:00:01.1 2>&1 || true
echo HISTORICAL_ROOT_PORT_END
echo RESULT=PASS
"@

$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_POST_REBOOT_EXCLUSIVITY_BEFORE_LINUX_RELOCK' `
    -TimeoutSeconds 30)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
