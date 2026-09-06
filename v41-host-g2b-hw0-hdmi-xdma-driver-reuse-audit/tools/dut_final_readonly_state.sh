#!/usr/bin/env bash
set -u

endpoint=/sys/bus/pci/devices/0000:01:00.0

echo "AUDIT=G2B-HW0-DRV-REUSE0_FINAL_STATE"
echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "HOSTNAME=$(hostname)"
echo "MACHINE_ID=$(cat /etc/machine-id 2>/dev/null || true)"
echo "AUTHENTICATED_USER=$(id -un)"
echo "ARCH=$(uname -m)"
echo "BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)"
echo "KERNEL=$(uname -r)"

if [ -d "$endpoint" ]; then
  echo "ENDPOINT_PRESENT=YES"
  echo "ENDPOINT_BDF=0000:01:00.0"
  echo "VENDOR=$(cat "$endpoint/vendor" 2>/dev/null || true)"
  echo "DEVICE=$(cat "$endpoint/device" 2>/dev/null || true)"
  echo "SUBSYSTEM_VENDOR=$(cat "$endpoint/subsystem_vendor" 2>/dev/null || true)"
  echo "SUBSYSTEM_DEVICE=$(cat "$endpoint/subsystem_device" 2>/dev/null || true)"
  echo "MODALIAS=$(cat "$endpoint/modalias" 2>/dev/null || true)"
  if [ -L "$endpoint/driver" ]; then
    echo "ENDPOINT_DRIVER=$(basename "$(readlink -f "$endpoint/driver")")"
  else
    echo "ENDPOINT_DRIVER=UNBOUND"
  fi
  echo "DRIVER_OVERRIDE=$(cat "$endpoint/driver_override" 2>/dev/null || true)"
  echo "CURRENT_LINK_SPEED=$(cat "$endpoint/current_link_speed" 2>/dev/null || true)"
  echo "CURRENT_LINK_WIDTH=$(cat "$endpoint/current_link_width" 2>/dev/null || true)"
else
  echo "ENDPOINT_PRESENT=NO"
fi

if [ -d /sys/module/xdma ]; then
  echo "XDMA_MODULE_LOADED=YES"
else
  echo "XDMA_MODULE_LOADED=NO"
fi

node_count=$(find /dev -maxdepth 1 -name 'xdma*' -printf '.' 2>/dev/null | wc -c)
echo "XDMA_NODE_COUNT=$node_count"
echo "XDMA_NODES_BEGIN"
find /dev -maxdepth 1 -name 'xdma*' -printf '%p %y %m %u:%g\n' 2>/dev/null | sort
echo "XDMA_NODES_END"

echo "MATCHING_CONCURRENT_PROCESSES_BEGIN"
audit_pid=$$
ps -eo pid=,ppid=,user=,args= | awk -v audit_pid="$audit_pid" '
  $1 == audit_pid || $2 == audit_pid { next }
  {
    line=tolower($0)
    if (line ~ /xdma|insmod|modprobe|rmmod|\/sys\/bus\/pci\/.*\/(bind|unbind|rescan|reset)|vivado|hw_server|openocd|fpga|apt(-get)?|dpkg|unattended-upgrade/) print
  }
'
echo "MATCHING_CONCURRENT_PROCESSES_END"
echo "AUDIT_COMPLETE=YES"
