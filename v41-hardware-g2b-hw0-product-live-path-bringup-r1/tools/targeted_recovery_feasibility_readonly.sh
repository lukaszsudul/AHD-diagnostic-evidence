#!/usr/bin/env bash
set -u
export LC_ALL=C
echo TASK_ID=G2B-HW0-PRODUCT-R1
echo MODE=READ_ONLY_TARGETED_RECOVERY_FEASIBILITY
printf 'UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"

echo '===== HISTORICAL_ROOT_FUNCTION_CONFIG_READ ====='
for spec in 0000:00:01.0 0000:00:01.1; do
  printf 'SPEC=%s\n' "$spec"
  setpci -s "$spec" VENDOR_ID DEVICE_ID CLASS_REV HEADER_TYPE 2>&1 || true
  if [ -e "/sys/bus/pci/devices/$spec" ]; then
    echo SYSFS_PRESENT=YES
    readlink -f "/sys/bus/pci/devices/$spec"
    [ -e "/sys/bus/pci/devices/$spec/rescan" ] && echo DEVICE_RESCAN_ATTRIBUTE=YES || echo DEVICE_RESCAN_ATTRIBUTE=NO
    [ -r "/sys/bus/pci/devices/$spec/physical_slot" ] && cat "/sys/bus/pci/devices/$spec/physical_slot" || true
    lspci -Dvv -s "$spec" 2>&1 || true
  else
    echo SYSFS_PRESENT=NO
  fi
done

echo '===== CURRENT_EXTERNAL_BRIDGE_CHAIN ====='
for spec in 0000:00:02.1 0000:01:00.0 0000:02:00.0 0000:02:08.0 0000:02:09.0 0000:02:0a.0 0000:02:0b.0 0000:02:0c.0 0000:02:0d.0; do
  [ -e "/sys/bus/pci/devices/$spec" ] || continue
  printf 'SPEC=%s\n' "$spec"
  printf 'SYSFS_PATH=%s\n' "$(readlink -f "/sys/bus/pci/devices/$spec")"
  printf 'RESCAN_ATTRIBUTE=%s\n' "$([ -e "/sys/bus/pci/devices/$spec/rescan" ] && echo YES || echo NO)"
  printf 'REMOVE_ATTRIBUTE=%s\n' "$([ -e "/sys/bus/pci/devices/$spec/remove" ] && echo YES || echo NO)"
  [ -r "/sys/bus/pci/devices/$spec/physical_slot" ] && printf 'PHYSICAL_SLOT=%s\n' "$(cat "/sys/bus/pci/devices/$spec/physical_slot")"
  lspci -Dvv -s "$spec" 2>&1 | grep -E '^[0-9a-f]{4}:|Bus:|Physical Slot|LnkCap:|LnkSta:|SlotCap:|SlotSta:|Kernel driver in use:|DevSta:|UESta:|CESta:' || true
done

echo '===== BUS_DEVICE_COUNTS ====='
for bus in 01 02 03 04 05 06 07 08 09; do
  count=$(find /sys/bus/pci/devices -maxdepth 1 -type l -name "0000:${bus}:*" | wc -l)
  printf 'BUS_%s_DEVICE_COUNT=%s\n' "$bus" "$count"
done

echo '===== XILINX_AND_MULTIMEDIA ====='
lspci -Dnn 2>&1 | grep -E -i '10ee:|12ab:|multimedia|video' || true
echo MMIO_READS=0
echo MMIO_WRITES=0
echo PCI_CONFIG_WRITES=0
echo PCI_RESCANS=0
echo PCI_RESETS=0
echo FEASIBILITY_INVENTORY_COMPLETE=YES
