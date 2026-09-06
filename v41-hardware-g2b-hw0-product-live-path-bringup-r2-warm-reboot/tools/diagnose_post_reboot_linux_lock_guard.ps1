Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$Evidence = Join-Path $TaskRoot 'raw\LINUX_LOCK_POST_REBOOT_ACQUIRE_FAILURE_DIAGNOSTIC.log'
if (Test-Path -LiteralPath $Evidence) { throw 'POST_REBOOT_LOCK_DIAGNOSTIC_ALREADY_EXISTS' }

$remoteCommand = @"
set -u
echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=POST_REBOOT_LINUX_LOCK_GUARD_DIAGNOSTIC_READ_ONLY
echo UTC=`$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
echo SHELL=`$SHELL
echo HOSTNAME=`$(hostname)
echo REMOTE_UID=`$(id -u)
echo MACHINE_ID=`$(cat /etc/machine-id)
echo BOOT_ID=`$(cat /proc/sys/kernel/random/boot_id)
if [ "`$(hostname)" = VCDE-DUT-1 ]; then echo GUARD_HOSTNAME=PASS; else echo GUARD_HOSTNAME=FAIL; fi
if [ "`$(id -u)" = 1000 ]; then echo GUARD_UID=PASS; else echo GUARD_UID=FAIL; fi
if [ "`$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8 ]; then echo GUARD_MACHINE_ID=PASS; else echo GUARD_MACHINE_ID=FAIL; fi
if [ "`$(cat /proc/sys/kernel/random/boot_id)" = 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac ]; then echo GUARD_BOOT_ID=PASS; else echo GUARD_BOOT_ID=FAIL; fi
if [ ! -e /tmp/ahd-g2b-hw0-product-r2-post-reboot.lock ]; then echo GUARD_NEW_LOCK_ABSENT=PASS; else echo GUARD_NEW_LOCK_ABSENT=FAIL; fi
if [ ! -e /tmp/ahd-g2b-hw0-product-r2.lock ]; then echo GUARD_OLD_LOCK_ABSENT=PASS; else echo GUARD_OLD_LOCK_ABSENT=FAIL; fi
relevant_process_count=`$(ps -eo comm= | awk 'BEGIN {IGNORECASE=1} /^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test)$/ {count++} END {print count+0}')
echo RELEVANT_PROCESS_COUNT=`$relevant_process_count
if [ "`$relevant_process_count" -eq 0 ]; then echo GUARD_RELEVANT_PROCESSES=PASS; else echo GUARD_RELEVANT_PROCESSES=FAIL; fi
xdma_module_count=`$(awk '`$1 == "xdma" {count++} END {print count+0}' /proc/modules)
echo XDMA_MODULE_COUNT=`$xdma_module_count
if [ "`$xdma_module_count" -eq 0 ]; then echo GUARD_XDMA_MODULE=PASS; else echo GUARD_XDMA_MODULE=FAIL; fi
echo XDMA_NODES_BEGIN
find /dev -maxdepth 1 -name 'xdma*' -print 2>&1 || true
echo XDMA_NODES_END
node_count=`$(find /dev -maxdepth 1 -name 'xdma*' -print 2>/dev/null | wc -l)
echo XDMA_DEVICE_NODE_COUNT=`$node_count
if [ "`$node_count" -eq 0 ]; then echo GUARD_XDMA_NODES=PASS; else echo GUARD_XDMA_NODES=FAIL; fi
echo TASK_LOCK_FIND_BEGIN
set +e
find /tmp /run/lock /var/lock -maxdepth 2 -type d \( -iname 'ahd*.lock' -o -iname 'g2b*.lock' -o -iname 'xdma*.lock' -o -iname 'fpga*.lock' \) -print 2>&1
find_rc=`$?
set -e
echo TASK_LOCK_FIND_EXIT_CODE=`$find_rc
echo TASK_LOCK_FIND_END
other_task_lock_count=`$(find /tmp /run/lock /var/lock -maxdepth 2 -type d \( -iname 'ahd*.lock' -o -iname 'g2b*.lock' -o -iname 'xdma*.lock' -o -iname 'fpga*.lock' \) -print 2>/dev/null | wc -l)
echo OTHER_TASK_LOCK_COUNT=`$other_task_lock_count
if [ "`$other_task_lock_count" -eq 0 ]; then echo GUARD_OTHER_TASK_LOCKS=PASS; else echo GUARD_OTHER_TASK_LOCKS=FAIL; fi
echo RESULT=COMPLETE
"@

$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_POST_REBOOT_LINUX_LOCK_GUARD_DIAGNOSTIC_READ_ONLY' `
    -TimeoutSeconds 30)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
