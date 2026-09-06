#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

task_lock=/tmp/ahd-g2b-hw0-product-r2-post-reboot.lock/receipt.json
expected_boot_id=52b0bf13-e9d1-4558-ae13-d08f4ecc8dac
bdf=0000:01:00.0
device_path=/sys/bus/pci/devices/$bdf

[ "$(hostname)" = VCDE-DUT-1 ]
[ "$(id -u)" = 1000 ]
[ "$(cat /proc/sys/kernel/random/boot_id)" = "$expected_boot_id" ]
[ -f "$task_lock" ]
grep -Fq '"lock_release_state": "HELD"' "$task_lock"
[ -d "$device_path" ]
[ "$(cat "$device_path/vendor")" = 0x10ee ]
[ "$(cat "$device_path/device")" = 0x7011 ]
[ ! -L "$device_path/driver" ]

kernel="$(uname -r)"
modalias="$(cat "$device_path/modalias")"
module_path="$(modinfo -n xdma)"

echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=XDMA_BINDING_FEASIBILITY_READ_ONLY
echo UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
echo HOSTNAME="$(hostname)"
echo BOOT_ID="$(cat /proc/sys/kernel/random/boot_id)"
echo LINUX_POST_REBOOT_LOCK=HELD
echo ENDPOINT_BDF="$bdf"
echo ENDPOINT_MODALIAS="$modalias"
echo ENDPOINT_DRIVER=NONE
echo KERNEL="$kernel"

echo EXACT_MODALIAS_RESOLUTION_BEGIN
set +e
modprobe --resolve-alias "$modalias" 2>&1
resolve_rc=$?
set -e
echo EXACT_MODALIAS_RESOLUTION_EXIT_CODE="$resolve_rc"
echo EXACT_MODALIAS_RESOLUTION_END

echo XDMA_MODPROBE_DRY_RUN_BEGIN
modprobe --show-depends --verbose xdma 2>&1 || true
echo XDMA_MODPROBE_DRY_RUN_END
echo XDMA_MODINFO_BEGIN
modinfo xdma
echo XDMA_MODINFO_END
echo XDMA_MODULE_PATH="$module_path"
echo XDMA_MODULE_SHA256="$(sha256sum "$module_path" | awk '{print $1}')"
echo XDMA_MODULE_ALIASES_BEGIN
modinfo -F alias xdma 2>&1 || true
echo XDMA_MODULE_ALIASES_END

echo EXACT_KERNEL_MODULE_MATCHES_BEGIN
find "/lib/modules/$kernel" -type f \( -iname '*xdma*.ko' -o -iname '*xdma*.ko.*' \) -printf '%p\n' | sort
echo EXACT_KERNEL_MODULE_MATCHES_END
echo XILINX_DMA_NAMED_KERNEL_MODULES_BEGIN
find "/lib/modules/$kernel" -type f \( -iname '*xilinx*dma*.ko' -o -iname '*xilinx*dma*.ko.*' \) -printf '%p\n' | sort
echo XILINX_DMA_NAMED_KERNEL_MODULES_END

echo MODULE_ALIAS_DATABASE_EXACT_VENDOR_BEGIN
grep -iE 'pci:v000010EE|pci:v000010ee|7011|xdma' "/lib/modules/$kernel/modules.alias" 2>/dev/null || true
echo MODULE_ALIAS_DATABASE_EXACT_VENDOR_END
echo MODULE_DEPENDENCY_DATABASE_XDMA_BEGIN
grep -i 'xdma' "/lib/modules/$kernel/modules.dep" 2>/dev/null || true
echo MODULE_DEPENDENCY_DATABASE_XDMA_END

echo PLATFORM_XDMA_MATCHING_DEVICES_BEGIN
platform_xdma_count=0
for alias_path in /sys/bus/platform/devices/*/modalias; do
  [ -r "$alias_path" ] || continue
  if [ "$(cat "$alias_path")" = platform:xdma ]; then
    platform_xdma_count=$((platform_xdma_count + 1))
    echo PLATFORM_DEVICE="$(basename "$(dirname "$alias_path")")"
  fi
done
echo PLATFORM_XDMA_MATCHING_DEVICE_COUNT="$platform_xdma_count"
echo PLATFORM_XDMA_MATCHING_DEVICES_END

echo DKMS_XDMA_BEGIN
if command -v dkms >/dev/null 2>&1; then dkms status 2>&1 | grep -i xdma || true; else echo DKMS_COMMAND=ABSENT; fi
find /var/lib/dkms -maxdepth 4 -iname '*xdma*' -print 2>/dev/null || true
echo DKMS_XDMA_END

echo PCI_DRIVER_INVENTORY_BEGIN
for driver_path in /sys/bus/pci/drivers/*; do
  [ -d "$driver_path" ] || continue
  name="$(basename "$driver_path")"
  printf 'PCI_DRIVER=%s MODULE=' "$name"
  if [ -L "$driver_path/module" ]; then basename "$(readlink -f "$driver_path/module")"; else echo NONE; fi
done
echo PCI_DRIVER_INVENTORY_END

echo ENDPOINT_KERNEL_BINDING_VIEW_BEGIN
lspci -Dnnk -s "$bdf"
udevadm info --query=property --path="$device_path" 2>&1 || true
echo ENDPOINT_KERNEL_BINDING_VIEW_END

echo XDMA_LOADED_COUNT="$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)"
echo XDMA_DRIVER_SYSFS_PCI="$([ -d /sys/bus/pci/drivers/xdma ] && echo PRESENT || echo ABSENT)"
echo XDMA_DRIVER_SYSFS_PLATFORM="$([ -d /sys/bus/platform/drivers/xdma ] && echo PRESENT || echo ABSENT)"
echo XDMA_DEVICE_NODE_COUNT="$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)"
echo MODULE_LOADS=0
echo DRIVER_BINDS=0
echo DRIVER_UNBINDS=0
echo MMIO_READS=0
echo MMIO_WRITES=0
echo DMA_OPERATIONS=0
echo RESULT=PASS
