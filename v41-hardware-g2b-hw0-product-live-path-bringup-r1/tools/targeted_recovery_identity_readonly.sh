#!/usr/bin/env bash
set -u
export LC_ALL=C
echo TASK_ID=G2B-HW0-PRODUCT-R1
echo MODE=READ_ONLY_TARGETED_RECOVERY_IDENTITY
printf 'UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"

echo '===== EXACT_FUNCTION_CONFIG_READS ====='
for spec in 0000:00:01.0 0000:00:01.1; do
  printf 'SPEC=%s\n' "$spec"
  for reg in 0.w 2.w 8.l e.b; do
    printf 'REG_%s=' "${reg//./_}"
    setpci -s "$spec" "$reg" 2>&1 || true
  done
  if [ -e "/sys/bus/pci/devices/$spec" ]; then
    echo SYSFS_PRESENT=YES
    for attr in vendor device class subsystem_vendor subsystem_device; do
      if [ -r "/sys/bus/pci/devices/$spec/$attr" ]; then
        printf '%s=' "${attr^^}"
        cat "/sys/bus/pci/devices/$spec/$attr"
      fi
    done
    printf 'SYSFS_PATH=%s\n' "$(readlink -f "/sys/bus/pci/devices/$spec")"
  else
    echo SYSFS_PRESENT=NO
  fi
done

echo '===== ROOT_BUS_TOPOLOGY ====='
lspci -Dnn | sed -n '/^0000:00:/p'
echo '===== TOPOLOGY_TREE ====='
lspci -Dtv

echo '===== FIRMWARE_SLOT_MAP ====='
slot_count=0
if [ -d /sys/bus/pci/slots ]; then
  for slot in /sys/bus/pci/slots/*; do
    [ -d "$slot" ] || continue
    slot_count=$((slot_count + 1))
    printf 'SLOT=%s\n' "$(basename "$slot")"
    for attr in address power attention latch adapter; do
      if [ -r "$slot/$attr" ]; then
        printf '%s=' "${attr^^}"
        cat "$slot/$attr"
      fi
    done
  done
fi
printf 'FIRMWARE_SLOT_COUNT=%s\n' "$slot_count"

echo '===== HISTORICAL_BDF_KERNEL_MESSAGES ====='
dmesg 2>/dev/null | grep -E 'pci 0000:00:01\.1|pci 0000:01:00\.0|10ee:7011|Xilinx' | tail -n 80 || true

echo MMIO_READS=0
echo MMIO_WRITES=0
echo PCI_CONFIG_WRITES=0
echo PCI_RESCANS=0
echo PCI_RESETS=0
echo IDENTITY_INVENTORY_COMPLETE=YES
