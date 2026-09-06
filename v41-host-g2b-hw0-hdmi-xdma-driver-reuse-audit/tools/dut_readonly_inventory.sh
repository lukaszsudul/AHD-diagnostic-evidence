#!/usr/bin/env bash
set -u

endpoint=/sys/bus/pci/devices/0000:01:00.0

echo "AUDIT=G2B-HW0-DRV-REUSE0"
echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "HOSTNAME=$(hostname)"
echo "HOSTNAMECTL_STATIC=$(hostnamectl --static 2>/dev/null || true)"
echo "MACHINE_ID=$(cat /etc/machine-id 2>/dev/null || true)"
echo "AUTHENTICATED_USER=$(id -un)"
echo "AUTHENTICATED_UID=$(id -u)"
echo "ARCH=$(uname -m)"
echo "BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)"
echo "KERNEL=$(uname -r)"
echo "UPTIME_SECONDS=$(cut -d' ' -f1 /proc/uptime 2>/dev/null || true)"

if [ -d "$endpoint" ]; then
  echo "ENDPOINT_PRESENT=YES"
  echo "ENDPOINT_BDF=0000:01:00.0"
  echo "VENDOR=$(cat "$endpoint/vendor" 2>/dev/null || true)"
  echo "DEVICE=$(cat "$endpoint/device" 2>/dev/null || true)"
  echo "SUBSYSTEM_VENDOR=$(cat "$endpoint/subsystem_vendor" 2>/dev/null || true)"
  echo "SUBSYSTEM_DEVICE=$(cat "$endpoint/subsystem_device" 2>/dev/null || true)"
  echo "CLASS=$(cat "$endpoint/class" 2>/dev/null || true)"
  echo "MODALIAS=$(cat "$endpoint/modalias" 2>/dev/null || true)"
  if [ -L "$endpoint/driver" ]; then
    echo "DRIVER=$(basename "$(readlink -f "$endpoint/driver")")"
    echo "DRIVER_SYMLINK=$(readlink "$endpoint/driver")"
  else
    echo "DRIVER=UNBOUND"
    echo "DRIVER_SYMLINK=NONE"
  fi
  echo "DRIVER_OVERRIDE=$(cat "$endpoint/driver_override" 2>/dev/null || true)"
  echo "CURRENT_LINK_SPEED=$(cat "$endpoint/current_link_speed" 2>/dev/null || true)"
  echo "CURRENT_LINK_WIDTH=$(cat "$endpoint/current_link_width" 2>/dev/null || true)"
  endpoint_real=$(readlink -f "$endpoint")
  upstream_path=$(dirname "$endpoint_real")
  echo "ENDPOINT_SYSFS_REALPATH=$endpoint_real"
  echo "UPSTREAM_BDF=$(basename "$upstream_path")"
  echo "LSPCI_ENDPOINT_BEGIN"
  lspci -D -s 0000:01:00.0 -nn -vv 2>&1 || true
  echo "LSPCI_ENDPOINT_END"
  upstream_bdf=$(basename "$upstream_path")
  echo "LSPCI_UPSTREAM_BEGIN"
  lspci -D -s "$upstream_bdf" -nn -vv 2>&1 || true
  echo "LSPCI_UPSTREAM_END"
else
  echo "ENDPOINT_PRESENT=NO"
  echo "ENDPOINT_BDF=NONE"
fi

echo "XDMA_PROC_MODULES_BEGIN"
awk '$1 == "xdma" {print}' /proc/modules 2>/dev/null || true
echo "XDMA_PROC_MODULES_END"
if [ -d /sys/module/xdma ]; then
  echo "XDMA_MODULE_LOADED=YES"
else
  echo "XDMA_MODULE_LOADED=NO"
fi
echo "XDMA_NODES_BEGIN"
find /dev -maxdepth 1 -name 'xdma*' -printf '%p %y %m %u:%g\n' 2>/dev/null | sort
echo "XDMA_NODES_END"

echo "SECURE_BOOT_BEGIN"
if command -v mokutil >/dev/null 2>&1; then
  mokutil --sb-state 2>&1 || true
else
  echo "mokutil unavailable"
fi
echo "SECURE_BOOT_END"
echo "LOCKDOWN=$(cat /sys/kernel/security/lockdown 2>/dev/null || true)"
kernel_config=/boot/config-$(uname -r)
if [ -r "$kernel_config" ]; then
  grep '^CONFIG_MODULE_SIG_FORCE=' "$kernel_config" 2>/dev/null || echo 'CONFIG_MODULE_SIG_FORCE_NOT_SET'
else
  echo 'CONFIG_MODULE_SIG_FORCE_UNREADABLE'
fi

echo "CONCURRENT_PROCESSES_BEGIN"
ps -eo pid=,ppid=,user=,lstart=,args= | grep -E '[x]dma|[i]nsmod|[m]odprobe|[r]mmod|/sys/bus/pci/.*/(bind|unbind|rescan|reset)|[v]ivado|[h]w_server|[o]penocd|[f]pga|[a]pt(-get)?|[d]pkg|[u]nattended-upgrade|[m]ake .*xdma|[g]cc .*xdma' || true
echo "CONCURRENT_PROCESSES_END"
echo "SYSTEMD_JOBS_BEGIN"
systemctl list-jobs --no-legend 2>&1 || true
echo "SYSTEMD_JOBS_END"
echo "PACKAGE_LOCK_HOLDERS_BEGIN"
for lockfile in /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock /var/lib/apt/lists/lock /var/cache/apt/archives/lock; do
  if command -v fuser >/dev/null 2>&1; then
    fuser "$lockfile" 2>&1 || true
  fi
done
echo "PACKAGE_LOCK_HOLDERS_END"
echo "AUDIT_COMPLETE=YES"
