#!/usr/bin/env bash
set -u

echo "TASK=G2B-HW0-PRODUCT-R2"
echo "PHASE=PRELOCK_EXCLUSIVITY_READONLY"
echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "HOSTNAME=$(hostname)"
echo "USER=$(id -un)"
echo "BOOT_ID=$(cat /proc/sys/kernel/random/boot_id)"
echo "UPTIME_SECONDS=$(cut -d' ' -f1 /proc/uptime)"

echo "=== RELEVANT_PROCESSES ==="
ps -eo pid=,ppid=,user=,stat=,comm=,args= --sort=pid | \
  awk 'BEGIN{IGNORECASE=1} /xdma|vivado|hw_server|jtag|fpga|g2b|ahd|hdmi|v4l2/ {print}' || true

echo "=== XDMA_MODULE ==="
awk '$1 == "xdma" {print}' /proc/modules || true

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

echo "=== XDMA_SYSFS_BINDINGS ==="
if [ -d /sys/bus/pci/drivers/xdma ]; then
  find /sys/bus/pci/drivers/xdma -maxdepth 1 -mindepth 1 -printf '%f -> %l\n' 2>/dev/null | sort
else
  echo "XDMA_DRIVER_SYSFS=ABSENT"
fi

echo "=== RELEVANT_LOCK_RECORDS ==="
for base in /run/lock /var/lock /tmp "$HOME"; do
  [ -d "$base" ] || continue
  find "$base" -maxdepth 3 \
    \( -iname '*ahd*' -o -iname '*g2b*' -o -iname '*xdma*' -o -iname '*jtag*' -o -iname '*fpga*' \) \
    -printf '%y %p\n' 2>/dev/null | sort || true
done

echo "=== LOGGED_IN_USERS ==="
who || true

echo "=== REBOOT_INHIBITORS ==="
if command -v systemd-inhibit >/dev/null 2>&1; then
  systemd-inhibit --list --no-pager 2>&1 || true
else
  echo "SYSTEMD_INHIBIT=UNAVAILABLE"
fi

echo "=== RELEVANT_PCIE_ENDPOINTS ==="
lspci -Dnn | awk 'BEGIN{IGNORECASE=1} /xilinx|amd|advanced micro|display|vga|multimedia|video/ {print}' || true

echo "PRELOCK_EXCLUSIVITY_READONLY=COMPLETE"
