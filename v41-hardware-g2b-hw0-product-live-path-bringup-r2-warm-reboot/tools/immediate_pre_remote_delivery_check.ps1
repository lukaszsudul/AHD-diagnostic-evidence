Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$TaskRoot = 'C:\FPGA\G2B_HW0_PRODUCT_R2_20260906'
$Helper = 'C:\FPGA\G2B_HW0_PRODUCT_R1_20260905\tools\Invoke-G2BR1Plink.ps1'
$Plink = 'C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\T1_RCA_PUTTY_CONTROL_20260820\00_PUTTY\putty-0.84-w64\plink.exe'
$Evidence = Join-Path $TaskRoot 'raw\IMMEDIATE_PRE_REMOTE_REBOOT_DELIVERY_CHECK.log'

if (Test-Path -LiteralPath $Evidence) {
    throw 'IMMEDIATE_PRE_REMOTE_DELIVERY_EVIDENCE_ALREADY_EXISTS'
}

$remoteCommand = @"
set -euo pipefail
echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=IMMEDIATE_PRE_REMOTE_REBOOT_DELIVERY_CHECK
echo UTC=`$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)
test "`$(hostname)" = VCDE-DUT-1
test "`$(id -u)" = 1000
echo HOSTNAME=`$(hostname)
echo REMOTE_USER=`$(id -un)
echo REMOTE_UID=`$(id -u)
test "`$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
echo MACHINE_ID=`$(cat /etc/machine-id)
test "`$(cat /proc/sys/kernel/random/boot_id)" = 37131b8d-0e38-4b4e-b77a-b3bda55b4e97
echo BOOT_ID=`$(cat /proc/sys/kernel/random/boot_id)
echo UPTIME_SECONDS=`$(cut -d' ' -f1 /proc/uptime)
test -d /tmp/ahd-g2b-hw0-product-r2.lock
test -f /tmp/ahd-g2b-hw0-product-r2.lock/receipt.json
grep -Fq '"task_id": "G2B-HW0-PRODUCT-R2"' /tmp/ahd-g2b-hw0-product-r2.lock/receipt.json
echo LINUX_LOCK=HELD
endpoint_count=`$(lspci -Dnnd 10ee:7011 | wc -l)
echo EXACT_AHD_ENDPOINT_COUNT=`$endpoint_count
test `$endpoint_count -eq 0
xdma_module_count=`$(awk '`$1 == "xdma" {count++} END {print count+0}' /proc/modules)
echo XDMA_MODULE_COUNT=`$xdma_module_count
test `$xdma_module_count -eq 0
shopt -s nullglob
nodes=(/dev/xdma*)
echo XDMA_DEVICE_NODE_COUNT=`${#nodes[@]}
test `${#nodes[@]} -eq 0
echo RESULT=PASS
"@

$output = @(& $Helper `
    -PlinkPath $Plink `
    -HostKey 'SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8' `
    -RemoteCommand $remoteCommand `
    -EvidencePath $Evidence `
    -ExpectedIp '10.132.1.111' `
    -ExpectedUser 'vcdeagent1' `
    -EvidenceKind 'R2_IMMEDIATE_PRE_REMOTE_REBOOT_DELIVERY_CHECK' `
    -TimeoutSeconds 30)
$exitCode = $LASTEXITCODE
$output | ForEach-Object { Write-Output $_ }
exit $exitCode
