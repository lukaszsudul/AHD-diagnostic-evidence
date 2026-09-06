#!/usr/bin/env bash
set -u
export LC_ALL=C.UTF-8

echo "TASK=G2B-HW0-PRODUCT-R2"
echo "PHASE=PRE_REBOOT_LINUX_SNAPSHOT"
echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "HOSTNAME=$(hostname)"
echo "USER=$(id -un)"
echo "UID=$(id -u)"
echo "MACHINE_ID=$(cat /etc/machine-id)"
echo "BOOT_ID=$(cat /proc/sys/kernel/random/boot_id)"
echo "UPTIME_SECONDS=$(cut -d' ' -f1 /proc/uptime)"
echo "KERNEL=$(uname -r)"
uname -a

echo "=== CONTROLLER_EXPECTED_STATE ==="
echo "CONTROLLER_LOCK_EXPECTED=HELD"
echo "MAXIMUM_WARM_REBOOTS=1"
echo "WARM_REBOOT_COMMANDS_ISSUED=0"
echo "SRAM_PROGRAMS_R2=0"
echo "FLASH_OPERATIONS_R2=0"
echo "POWER_CYCLES_R2=0"

echo "=== LINUX_LOCK ==="
lock_path=/tmp/ahd-g2b-hw0-product-r2.lock
if [ -d "$lock_path" ] && [ -f "$lock_path/receipt.json" ]; then
  echo "LINUX_LOCK=HELD"
  cat "$lock_path/receipt.json"
else
  echo "LINUX_LOCK=MISSING"
fi

echo "=== REBOOT_INHIBITORS ==="
systemd-inhibit --list --no-pager 2>&1 || true

echo "=== BOOT_HISTORY ==="
last -x reboot shutdown -n 20 2>&1 || true
journalctl --list-boots --no-pager 2>&1 || true

echo "=== PCIE_TREE ==="
lspci -Dnn -tv 2>&1 || true
echo "=== PCIE_NUMERIC ==="
lspci -Dnn 2>&1 || true
echo "=== PCIE_DRIVER_MAP ==="
lspci -Dnnk 2>&1 || true
echo "=== PCIE_VERBOSE ==="
lspci -Dnnvv 2>&1 || true

echo "=== EXACT_AHD_IDENTITY_SEARCH ==="
if lspci -Dnn | grep -i '10ee:7011'; then
  echo "AHD_ENDPOINT=LOCAL_ID_MATCH_PRESENT"
else
  echo "AHD_ENDPOINT=ABSENT"
fi
if [ -e /sys/bus/pci/devices/0000:00:01.1 ]; then
  echo "HISTORICAL_ROOT_0000_00_01_1=PRESENT"
else
  echo "HISTORICAL_ROOT_0000_00_01_1=ABSENT"
fi

echo "=== XDMA_MODULE_AND_FILES ==="
awk '$1 == "xdma" {print}' /proc/modules || true
modinfo xdma 2>&1 || true
echo "=== XDMA_DRIVER_SYSFS ==="
if [ -d /sys/bus/pci/drivers/xdma ]; then
  find /sys/bus/pci/drivers/xdma -maxdepth 1 -mindepth 1 -printf '%f -> %l\n' 2>/dev/null | sort
else
  echo "XDMA_DRIVER_SYSFS=ABSENT"
fi

echo "=== XDMA_NODES_AND_USERS ==="
node_count=0
for node in /dev/xdma*; do
  [ -e "$node" ] || continue
  node_count=$((node_count + 1))
  ls -l "$node"
  if command -v fuser >/dev/null 2>&1; then
    fuser -v "$node" 2>&1 || true
  fi
done
echo "XDMA_NODE_COUNT=$node_count"

echo "=== RELEVANT_PROCESSES ==="
ps -eo pid=,ppid=,user=,stat=,comm=,args= --sort=pid | \
  awk 'BEGIN{IGNORECASE=1} /xdma|vivado|hw_server|jtag|fpga|g2b|ahd|hdmi|v4l2/ {print}' || true

echo "=== AER_SYSFS ==="
for dev in /sys/bus/pci/devices/*; do
  [ -d "$dev" ] || continue
  found=0
  for field in aer_dev_correctable aer_dev_fatal aer_dev_nonfatal; do
    if [ -r "$dev/$field" ]; then
      if [ "$found" -eq 0 ]; then
        echo "DEVICE=$(basename "$dev")"
        found=1
      fi
      echo "--- $field"
      cat "$dev/$field" 2>&1 || true
    fi
  done
done

echo "=== KERNEL_PCIE_XDMA_LOGS_CURRENT_BOOT ==="
journalctl -k -b --no-pager 2>&1 | \
  awk 'BEGIN{IGNORECASE=1} /pci|pcie|aer|xdma|xilinx|10ee|ahd|iommu/ {print}' || true

echo "PRE_REBOOT_LINUX_SNAPSHOT=COMPLETE"
