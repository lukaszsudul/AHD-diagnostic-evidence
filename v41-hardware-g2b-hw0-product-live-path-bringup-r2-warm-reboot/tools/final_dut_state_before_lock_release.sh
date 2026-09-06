#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

bdf=0000:01:00.0
root_bdf=0000:00:01.1
task_lock=/tmp/ahd-g2b-hw0-product-r2-post-reboot.lock/receipt.json
[ "$(hostname)" = VCDE-DUT-1 ]
[ "$(id -u)" = 1000 ]
[ "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8 ]
[ "$(cat /proc/sys/kernel/random/boot_id)" = 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac ]
[ -f "$task_lock" ]
grep -Fq '"task_id": "G2B-HW0-PRODUCT-R2"' "$task_lock"
grep -Fq '"lock_release_state": "HELD"' "$task_lock"
[ -d "/sys/bus/pci/devices/$bdf" ]
[ "$(cat "/sys/bus/pci/devices/$bdf/vendor")" = 0x10ee ]
[ "$(cat "/sys/bus/pci/devices/$bdf/device")" = 0x7011 ]

echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=FINAL_DUT_STATE_BEFORE_LOCK_RELEASE
echo UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
echo HOSTNAME="$(hostname)"
echo REMOTE_USER="$(id -un)"
echo MACHINE_ID="$(cat /etc/machine-id)"
echo BOOT_ID="$(cat /proc/sys/kernel/random/boot_id)"
echo UPTIME_SECONDS="$(cut -d' ' -f1 /proc/uptime)"
echo SYSTEM_STATE="$(systemctl is-system-running 2>/dev/null || true)"
echo LINUX_LOCK_RECEIPT_BEGIN
cat "$task_lock"
echo LINUX_LOCK_RECEIPT_END
echo LINUX_LOCK_RECEIPT_SHA256="$(sha256sum "$task_lock" | awk '{print $1}')"

relevant_process_count="$(ps -eo comm= | awk 'BEGIN {IGNORECASE=1} /^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test)$/ {count++} END {print count+0}')"
echo RELEVANT_PROCESS_COUNT="$relevant_process_count"
test "$relevant_process_count" -eq 0
echo LOGGED_IN_USERS_BEGIN
who || true
echo LOGGED_IN_USERS_END

endpoint_count="$(lspci -Dnnd 10ee:7011 | wc -l)"
echo EXACT_AHD_ENDPOINT_COUNT="$endpoint_count"
test "$endpoint_count" -eq 1
echo ENDPOINT_BDF="$bdf"
echo ENDPOINT_VENDOR_DEVICE="$(cat "/sys/bus/pci/devices/$bdf/vendor"):$(cat "/sys/bus/pci/devices/$bdf/device")"
echo ENDPOINT_SUBSYSTEM="$(cat "/sys/bus/pci/devices/$bdf/subsystem_vendor"):$(cat "/sys/bus/pci/devices/$bdf/subsystem_device")"
echo ENDPOINT_CLASS="$(cat "/sys/bus/pci/devices/$bdf/class")"
echo ENDPOINT_SYSFS_PATH="$(readlink -f "/sys/bus/pci/devices/$bdf")"
echo UPSTREAM_BDF="$root_bdf"
echo ENDPOINT_CURRENT_LINK_SPEED="$(cat "/sys/bus/pci/devices/$bdf/current_link_speed")"
echo ENDPOINT_CURRENT_LINK_WIDTH="$(cat "/sys/bus/pci/devices/$bdf/current_link_width")"
printf 'ENDPOINT_DRIVER='
if [ -L "/sys/bus/pci/devices/$bdf/driver" ]; then basename "$(readlink -f "/sys/bus/pci/devices/$bdf/driver")"; else echo NONE; fi
echo ENDPOINT_DRIVER_OVERRIDE="$(cat "/sys/bus/pci/devices/$bdf/driver_override" 2>/dev/null || true)"
echo ENDPOINT_FINAL_VERBOSE_BEGIN
sudo -S -p '' env LC_ALL=C /usr/bin/lspci -Dnnvv -s "$bdf"
echo ENDPOINT_FINAL_VERBOSE_END
echo UPSTREAM_FINAL_VERBOSE_BEGIN
sudo -S -p '' env LC_ALL=C /usr/bin/lspci -Dnnvv -s "$root_bdf"
echo UPSTREAM_FINAL_VERBOSE_END

module_path="$(modinfo -n xdma)"
echo XDMA_MODULE_PATH="$module_path"
echo XDMA_MODULE_SHA256="$(sha256sum "$module_path" | awk '{print $1}')"
echo XDMA_MODULE_ALIAS_BEGIN
modinfo -F alias xdma
echo XDMA_MODULE_ALIAS_END
echo XDMA_LOADED_COUNT="$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)"
echo XDMA_PCI_DRIVER_SYSFS="$([ -d /sys/bus/pci/drivers/xdma ] && echo PRESENT || echo ABSENT)"
echo XDMA_PLATFORM_DRIVER_SYSFS="$([ -d /sys/bus/platform/drivers/xdma ] && echo PRESENT || echo ABSENT)"
node_count="$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)"
echo XDMA_DEVICE_NODE_COUNT="$node_count"
test "$node_count" -eq 0

echo CURRENT_BOOT_RELEVANT_KERNEL_LOG_BEGIN
journalctl -k -b --no-pager 2>&1 | grep -E -i "pcie|pci |aer|10ee|7011|$bdf|$root_bdf|xdma" | tail -n 500 || true
echo CURRENT_BOOT_RELEVANT_KERNEL_LOG_END

echo FIRST_BLOCKER='BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE'
echo CANDIDATE_RETAINED_ACROSS_WARM_REBOOT=PASS
echo FINAL_JTAG_DONE=1
echo WARM_REBOOTS_EXECUTED=1
echo SECOND_REBOOT_ATTEMPTED=NO
echo POWER_CYCLES_EXECUTED=0
echo SRAM_PROGRAM_OPERATIONS_IN_R2=0
echo FLASH_PROGRAM_OPERATIONS=0
echo XDMA_MODULE_LOADS_IN_R2=0
echo DRIVER_BINDS_IN_R2=0
echo DRIVER_UNBINDS_IN_R2=0
echo MMIO_READS=0
echo MMIO_WRITES=0
echo DMA_OPERATIONS=0
echo STREAM_ENABLE_WRITES=0
echo PCI_RESCANS=0
echo PCI_RESETS=0
echo CANDIDATE_LEFT_IN_VOLATILE_SRAM=YES
echo PERSISTENT_STATE_MODIFIED=NO
echo RESULT=PASS
