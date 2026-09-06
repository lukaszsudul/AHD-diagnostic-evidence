#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C.UTF-8

task_lock=/tmp/ahd-g2b-hw0-product-r2-post-reboot.lock/receipt.json
expected_boot_id=52b0bf13-e9d1-4558-ae13-d08f4ecc8dac

[ "$(hostname)" = VCDE-DUT-1 ]
[ "$(id -u)" = 1000 ]
[ "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8 ]
[ "$(cat /proc/sys/kernel/random/boot_id)" = "$expected_boot_id" ]
[ -f "$task_lock" ]
grep -Fq '"task_id": "G2B-HW0-PRODUCT-R2"' "$task_lock"
grep -Fq '"lock_release_state": "HELD"' "$task_lock"

mapfile -t endpoint_lines < <(lspci -Dnnd 10ee:7011)
[ "${#endpoint_lines[@]}" -eq 1 ]
bdf="${endpoint_lines[0]%% *}"
[ -e "/sys/bus/pci/devices/$bdf" ]
[ "$(cat "/sys/bus/pci/devices/$bdf/vendor")" = 0x10ee ]
[ "$(cat "/sys/bus/pci/devices/$bdf/device")" = 0x7011 ]
sysfs_path="$(readlink -f "/sys/bus/pci/devices/$bdf")"
upstream_bdf="$(basename "$(dirname "$sysfs_path")")"
[ -e "/sys/bus/pci/devices/$upstream_bdf" ]

echo TASK=G2B-HW0-PRODUCT-R2
echo PHASE=POST_REBOOT_PCIE_XDMA_READ_ONLY_INVENTORY
echo UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
echo HOSTNAME="$(hostname)"
echo REMOTE_USER="$(id -un)"
echo BOOT_ID="$(cat /proc/sys/kernel/random/boot_id)"
echo LINUX_POST_REBOOT_LOCK=HELD
echo EXACT_AHD_ENDPOINT_COUNT="${#endpoint_lines[@]}"
echo ENDPOINT_BDF="$bdf"
echo ENDPOINT_VENDOR_DEVICE=10ee:7011
echo ENDPOINT_SYSFS_PATH="$sysfs_path"
echo UPSTREAM_BDF="$upstream_bdf"

echo FULL_PCIE_TOPOLOGY_BEGIN
lspci -Dtv
echo FULL_PCIE_TOPOLOGY_END
echo FULL_PCIE_NUMERIC_INVENTORY_BEGIN
lspci -Dnn
echo FULL_PCIE_NUMERIC_INVENTORY_END

echo RELEVANT_ENDPOINTS_BEGIN
for dev in /sys/bus/pci/devices/*; do
  [ -r "$dev/vendor" ] || continue
  vendor="$(cat "$dev/vendor")"
  device="$(cat "$dev/device")"
  class="$(cat "$dev/class")"
  driver=NONE
  [ -L "$dev/driver" ] && driver="$(basename "$(readlink -f "$dev/driver")")"
  if [ "$vendor" = 0x10ee ] || [ "$vendor" = 0x12ab ] || [[ "$class" =~ ^0x03 ]] || [[ "$class" =~ ^0x04 ]] || [ "$driver" = xdma ]; then
    iommu=NONE
    [ -L "$dev/iommu_group" ] && iommu="$(basename "$(readlink -f "$dev/iommu_group")")"
    slot=NONE
    [ -r "$dev/physical_slot" ] && slot="$(cat "$dev/physical_slot")"
    printf 'BDF=%s VENDOR=%s DEVICE=%s CLASS=%s DRIVER=%s IOMMU_GROUP=%s PHYSICAL_SLOT=%s SYSFS=%s\n' \
      "$(basename "$dev")" "$vendor" "$device" "$class" "$driver" "$iommu" "$slot" "$(readlink -f "$dev")"
  fi
done
echo RELEVANT_ENDPOINTS_END

echo ENDPOINT_SYSFS_ATTRIBUTES_BEGIN
for attr in vendor device class subsystem_vendor subsystem_device irq numa_node current_link_speed current_link_width max_link_speed max_link_width modalias driver_override power_state; do
  if [ -r "/sys/bus/pci/devices/$bdf/$attr" ]; then
    printf '%s=' "${attr^^}"
    cat "/sys/bus/pci/devices/$bdf/$attr"
  fi
done
printf 'DRIVER='
if [ -L "/sys/bus/pci/devices/$bdf/driver" ]; then basename "$(readlink -f "/sys/bus/pci/devices/$bdf/driver")"; else echo NONE; fi
echo RESOURCE_BEGIN
cat "/sys/bus/pci/devices/$bdf/resource"
echo RESOURCE_END
echo UEVENT_BEGIN
cat "/sys/bus/pci/devices/$bdf/uevent"
echo UEVENT_END
echo ENDPOINT_SYSFS_ATTRIBUTES_END

echo UPSTREAM_SYSFS_ATTRIBUTES_BEGIN
echo UPSTREAM_SYSFS_PATH="$(readlink -f "/sys/bus/pci/devices/$upstream_bdf")"
for attr in vendor device class subsystem_vendor subsystem_device irq numa_node current_link_speed current_link_width max_link_speed max_link_width physical_slot; do
  if [ -r "/sys/bus/pci/devices/$upstream_bdf/$attr" ]; then
    printf '%s=' "${attr^^}"
    cat "/sys/bus/pci/devices/$upstream_bdf/$attr"
  fi
done
printf 'DRIVER='
if [ -L "/sys/bus/pci/devices/$upstream_bdf/driver" ]; then basename "$(readlink -f "/sys/bus/pci/devices/$upstream_bdf/driver")"; else echo NONE; fi
echo UPSTREAM_SYSFS_ATTRIBUTES_END

echo FIRMWARE_SLOT_MAP_BEGIN
slot_count=0
if [ -d /sys/bus/pci/slots ]; then
  for slot_dir in /sys/bus/pci/slots/*; do
    [ -d "$slot_dir" ] || continue
    slot_count=$((slot_count + 1))
    echo SLOT="$(basename "$slot_dir")"
    for attr in address power attention latch adapter; do
      [ -r "$slot_dir/$attr" ] && printf '%s=' "${attr^^}" && cat "$slot_dir/$attr"
    done
  done
fi
echo FIRMWARE_SLOT_COUNT="$slot_count"
echo FIRMWARE_SLOT_MAP_END

echo ENDPOINT_LSPCI_ROOT_VERBOSE_BEGIN
sudo -S -p '' env LC_ALL=C /usr/bin/lspci -Dnnvvxxxx -s "$bdf"
echo ENDPOINT_LSPCI_ROOT_VERBOSE_END
echo UPSTREAM_LSPCI_ROOT_VERBOSE_BEGIN
sudo -S -p '' env LC_ALL=C /usr/bin/lspci -Dnnvvxxxx -s "$upstream_bdf"
echo UPSTREAM_LSPCI_ROOT_VERBOSE_END

echo XDMA_MODULE_INVENTORY_BEGIN
xdma_loaded_count="$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)"
echo XDMA_MODULE_LOADED_COUNT="$xdma_loaded_count"
modinfo xdma 2>&1 || true
module_path="$(modinfo -n xdma 2>/dev/null || true)"
echo XDMA_MODULE_PATH="${module_path:-N/A}"
if [ -n "$module_path" ] && [ -f "$module_path" ]; then
  echo XDMA_MODULE_SHA256="$(sha256sum "$module_path" | awk '{print $1}')"
fi
echo XDMA_MODULE_INVENTORY_END

echo XDMA_BINDINGS_AND_NODES_BEGIN
if [ -d /sys/bus/pci/drivers/xdma ]; then
  echo XDMA_DRIVER_SYSFS=PRESENT
  find /sys/bus/pci/drivers/xdma -mindepth 1 -maxdepth 1 -printf '%f -> %l\n' 2>/dev/null | sort || true
else
  echo XDMA_DRIVER_SYSFS=ABSENT
fi
node_count="$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)"
echo XDMA_DEVICE_NODE_COUNT="$node_count"
find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -printf '%p\n' | sort || true
echo XDMA_BINDINGS_AND_NODES_END

echo CURRENT_BOOT_PCIE_KERNEL_LOG_BEGIN
journalctl -k -b --no-pager 2>&1 | grep -E -i "pcie|pci |aer|10ee|7011|$bdf|$upstream_bdf|xdma" | tail -n 500 || true
echo CURRENT_BOOT_PCIE_KERNEL_LOG_END

echo MMIO_READS=0
echo MMIO_WRITES=0
echo DMA_OPERATIONS=0
echo DRIVER_CHANGES=0
echo PCI_RESCANS=0
echo PCI_RESETS=0
echo RESULT=PASS
