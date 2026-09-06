#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

lock_receipt=/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock/receipt.json
expected_boot_id=52b0bf13-e9d1-4558-ae13-d08f4ecc8dac

test "$(hostname)" = VCDE-DUT-1
test "$(id -u)" = 1000
test "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
test "$(cat /proc/sys/kernel/random/boot_id)" = "$expected_boot_id"
test "$(uname -r)" = 7.0.0-29-generic
test "$(uname -m)" = x86_64
test -f "$lock_receipt"
grep -Fq '"task_id": "G2B-HW0-PRODUCT-R3"' "$lock_receipt"
grep -Fq '"lock_release_state": "HELD"' "$lock_receipt"

sudo -S -p '' -v

echo TASK=G2B-HW0-PRODUCT-R3
echo PHASE=T0_PCIE_AER_RUNTIME_INVENTORY_READONLY
echo T0_UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
echo HOSTNAME="$(hostname)"
echo REMOTE_USER="$(id -un)"
echo BOOT_ID="$(cat /proc/sys/kernel/random/boot_id)"
echo KERNEL="$(uname -r)"
echo ARCH="$(uname -m)"
echo KERNEL_TAINT_BEFORE="$(cat /proc/sys/kernel/tainted)"
echo LINUX_LOCK=HELD

mapfile -t endpoint_lines < <(lspci -Dnnd 10ee:7011)
echo EXACT_AHD_ENDPOINT_COUNT="${#endpoint_lines[@]}"
test "${#endpoint_lines[@]}" -eq 1
bdf="${endpoint_lines[0]%% *}"
echo ENDPOINT_BDF="$bdf"
test "$bdf" = 0000:01:00.0
device_path="/sys/bus/pci/devices/$bdf"
test -d "$device_path"
sysfs_path="$(readlink -f "$device_path")"
upstream_bdf="$(basename "$(dirname "$sysfs_path")")"
echo ENDPOINT_SYSFS_PATH="$sysfs_path"
echo UPSTREAM_BDF="$upstream_bdf"
test "$upstream_bdf" = 0000:00:01.1

echo FULL_PCIE_TREE_BEGIN
lspci -Dtv
echo FULL_PCIE_TREE_END
echo FULL_PCIE_NUMERIC_INVENTORY_BEGIN
lspci -Dnn
echo FULL_PCIE_NUMERIC_INVENTORY_END

echo ENDPOINT_SYSFS_ATTRIBUTES_BEGIN
for attr in vendor device subsystem_vendor subsystem_device class modalias irq numa_node current_link_speed current_link_width max_link_speed max_link_width power_state; do
  printf '%s=' "${attr^^}"
  if [ -r "$device_path/$attr" ]; then cat "$device_path/$attr"; else echo UNAVAILABLE; fi
done
printf 'DRIVER='
if [ -L "$device_path/driver" ]; then basename "$(readlink -f "$device_path/driver")"; else echo NONE; fi
printf 'DRIVER_OVERRIDE_TEXT='
if [ -r "$device_path/driver_override" ]; then cat "$device_path/driver_override"; else echo UNREADABLE; fi
printf 'DRIVER_OVERRIDE_HEX='
if [ -r "$device_path/driver_override" ]; then od -An -tx1 -v "$device_path/driver_override" | tr -d ' \n'; echo; else echo UNREADABLE; fi
echo IOMMU_GROUP="$(if [ -L "$device_path/iommu_group" ]; then basename "$(readlink -f "$device_path/iommu_group")"; else echo NONE; fi)"
echo RESOURCE_BEGIN
cat "$device_path/resource"
echo RESOURCE_END
echo UEVENT_BEGIN
cat "$device_path/uevent"
echo UEVENT_END
echo ENDPOINT_SYSFS_ATTRIBUTES_END

echo UPSTREAM_SYSFS_ATTRIBUTES_BEGIN
upstream_path="/sys/bus/pci/devices/$upstream_bdf"
echo UPSTREAM_SYSFS_PATH="$(readlink -f "$upstream_path")"
for attr in vendor device subsystem_vendor subsystem_device class irq numa_node current_link_speed current_link_width max_link_speed max_link_width physical_slot power_state; do
  printf '%s=' "${attr^^}"
  if [ -r "$upstream_path/$attr" ]; then cat "$upstream_path/$attr"; else echo UNAVAILABLE; fi
done
printf 'DRIVER='
if [ -L "$upstream_path/driver" ]; then basename "$(readlink -f "$upstream_path/driver")"; else echo NONE; fi
echo UPSTREAM_SYSFS_ATTRIBUTES_END

echo ENDPOINT_AER_SYSFS_BEGIN
for attr_path in "$device_path"/aer_*; do
  [ -e "$attr_path" ] || continue
  printf '%s=' "$(basename "$attr_path")"
  cat "$attr_path" 2>&1 || true
done
echo ENDPOINT_AER_SYSFS_END
echo UPSTREAM_AER_SYSFS_BEGIN
for attr_path in "$upstream_path"/aer_*; do
  [ -e "$attr_path" ] || continue
  printf '%s=' "$(basename "$attr_path")"
  cat "$attr_path" 2>&1 || true
done
echo UPSTREAM_AER_SYSFS_END

echo ENDPOINT_LSPCI_VVV_BEGIN
sudo -n env LC_ALL=C /usr/bin/lspci -Dnnvvvxxxx -s "$bdf"
echo ENDPOINT_LSPCI_VVV_END
echo UPSTREAM_LSPCI_VVV_BEGIN
sudo -n env LC_ALL=C /usr/bin/lspci -Dnnvvvxxxx -s "$upstream_bdf"
echo UPSTREAM_LSPCI_VVV_END

echo MODULE_STATE_BEGIN
awk '$1 ~ /^(xdma|xdma_ahd_pcie)$/ {print}' /proc/modules || true
echo PLATFORM_XDMA_MODULE_COUNT="$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)"
echo AHD_XDMA_MODULE_COUNT="$(awk '$1 == "xdma_ahd_pcie" {count++} END {print count+0}' /proc/modules)"
echo MODULE_STATE_END
echo XDMA_RUNTIME_BEGIN
echo XDMA_NODE_COUNT="$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)"
find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -printf '%p\n' | sort || true
if [ -d /sys/class/xdma ]; then
  echo XDMA_CLASS=PRESENT
  find /sys/class/xdma -mindepth 1 -maxdepth 1 -printf '%f -> %l\n' 2>/dev/null | sort || true
else
  echo XDMA_CLASS=ABSENT
fi
echo XDMA_RUNTIME_END

echo PROCESS_RECHECK_BEGIN
ps -eo pid=,ppid=,uid=,user=,stat=,comm= --sort=pid | awk 'BEGIN {IGNORECASE=1} $6 ~ /^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test|g2b_capture|g2b_mmio|ffmpeg|gst-launch.*|v4l2-ctl)$/ {print}' || true
echo PROCESS_RECHECK_END

echo SECURE_BOOT_BEGIN
if command -v mokutil >/dev/null 2>&1; then mokutil --sb-state 2>&1 || true; else echo MOKUTIL=UNAVAILABLE; fi
echo SECURE_BOOT_END
echo LOCKDOWN_STATE="$(cat /sys/kernel/security/lockdown 2>/dev/null || echo UNAVAILABLE)"

echo KERNEL_PCIE_AER_BASELINE_BEGIN
sudo -n journalctl -k -b --no-pager -o short-monotonic 2>&1 | grep -E -i 'pcie|pci |aer|10ee|7011|0000:01:00.0|0000:00:01.1|xdma|iommu|dma' || true
echo KERNEL_PCIE_AER_BASELINE_END
echo KERNEL_LOG_CURSOR_BEGIN
sudo -n journalctl -k -b -n 0 --no-pager --show-cursor 2>&1 || true
echo KERNEL_LOG_CURSOR_END

echo STABILITY_SAMPLE_1="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ),$(cat "$device_path/vendor"),$(cat "$device_path/device"),$(cat "$device_path/current_link_speed"),$(cat "$device_path/current_link_width")"
sleep 1
test -d "$device_path"
test ! -L "$device_path/driver"
echo STABILITY_SAMPLE_2="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ),$(cat "$device_path/vendor"),$(cat "$device_path/device"),$(cat "$device_path/current_link_speed"),$(cat "$device_path/current_link_width")"

echo MMIO_READS=0
echo MMIO_WRITES=0
echo DMA_OPERATIONS=0
echo DRIVER_CHANGES=0
echo PCI_CONFIG_WRITES=0
echo PCI_RESCANS=0
echo PCI_RESETS=0
echo FPGA_PROGRAMMING=0
echo RESULT=PASS
