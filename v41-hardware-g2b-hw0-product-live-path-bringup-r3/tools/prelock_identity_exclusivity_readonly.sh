#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

echo TASK=G2B-HW0-PRODUCT-R3
echo PHASE=PRELOCK_IDENTITY_EXCLUSIVITY_READONLY
echo UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
echo HOSTNAME="$(hostname)"
echo REMOTE_USER="$(id -un)"
echo REMOTE_UID="$(id -u)"
echo MACHINE_ID="$(cat /etc/machine-id)"
echo BOOT_ID="$(cat /proc/sys/kernel/random/boot_id)"
echo KERNEL="$(uname -r)"
echo ARCH="$(uname -m)"
echo UPTIME_SECONDS="$(cut -d' ' -f1 /proc/uptime)"
echo IPV4_BEGIN
ip -o -4 addr show scope global 2>/dev/null | awk '{print $2, $4}' | sort || true
echo IPV4_END

test "$(hostname)" = VCDE-DUT-1
test "$(id -u)" = 1000
test "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
test "$(uname -r)" = 7.0.0-29-generic
test "$(uname -m)" = x86_64
ip -o -4 addr show scope global | awk '{print $4}' | grep -Eq '^10\.132\.1\.111/'

echo RELEVANT_PROCESS_COMMANDS_BEGIN
ps -eo pid=,ppid=,uid=,user=,stat=,comm= --sort=pid | \
  awk 'BEGIN {IGNORECASE=1} $6 ~ /^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test|g2b_capture|g2b_mmio|ffmpeg|gst-launch.*|v4l2-ctl)$/ {print}' || true
echo RELEVANT_PROCESS_COMMANDS_END
relevant_process_count="$(ps -eo comm= | awk 'BEGIN {IGNORECASE=1} /^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test|g2b_capture|g2b_mmio|ffmpeg|gst-launch.*|v4l2-ctl)$/ {count++} END {print count+0}')"
echo RELEVANT_PROCESS_COUNT="$relevant_process_count"

echo FPGA_XDMA_MODULES_BEGIN
awk '$1 ~ /^(xdma|xdma_ahd_pcie|xocl|xclmgmt)$/ {print}' /proc/modules || true
echo FPGA_XDMA_MODULES_END
xdma_count="$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)"
ahd_xdma_count="$(awk '$1 == "xdma_ahd_pcie" {count++} END {print count+0}' /proc/modules)"
echo PLATFORM_XDMA_MODULE_COUNT="$xdma_count"
echo AHD_XDMA_MODULE_COUNT="$ahd_xdma_count"

echo XDMA_NODES_BEGIN
node_count=0
shopt -s nullglob
for node in /dev/xdma*; do
  node_count=$((node_count + 1))
  stat -Lc 'NODE=%n MODE=%a OWNER=%U GROUP=%G MAJOR=%t MINOR=%T' -- "$node"
  if command -v fuser >/dev/null 2>&1; then
    fuser -v -- "$node" 2>&1 || true
  fi
done
echo XDMA_NODE_COUNT="$node_count"
echo XDMA_NODES_END

echo XDMA_CLASS_BEGIN
if [ -d /sys/class/xdma ]; then
  find /sys/class/xdma -mindepth 1 -maxdepth 1 -printf '%f -> %l\n' 2>/dev/null | sort || true
else
  echo XDMA_CLASS=ABSENT
fi
echo XDMA_CLASS_END

echo RELEVANT_LOCKS_BEGIN
find /tmp /run/lock /var/lock -mindepth 1 -maxdepth 3 \
  \( -iname '*ahd*.lock' -o -iname '*g2b*.lock' -o -iname '*xdma*.lock' -o -iname '*jtag*.lock' -o -iname '*fpga*.lock' \) \
  -printf '%y %p\n' 2>/dev/null | sort || true
echo RELEVANT_LOCKS_END
other_task_lock_count="$(find /tmp /run/lock /var/lock -mindepth 1 -maxdepth 3 -type d \( -iname '*ahd*.lock' -o -iname '*g2b*.lock' -o -iname '*xdma*.lock' -o -iname '*jtag*.lock' -o -iname '*fpga*.lock' \) -print 2>/dev/null | wc -l)"
echo RELEVANT_TASK_LOCK_COUNT="$other_task_lock_count"

echo SSH_CONNECTIONS_BEGIN
printf 'CURRENT_SSH_CONNECTION=%s\n' "${SSH_CONNECTION:-N/A}"
ss -Htn state established '( sport = :22 )' 2>/dev/null | awk '{print $1, $3, $4}' | sort || true
echo SSH_CONNECTIONS_END
ssh_connection_count="$(ss -Htn state established '( sport = :22 )' 2>/dev/null | wc -l || true)"
echo SSH_ESTABLISHED_CONNECTION_COUNT="$ssh_connection_count"

echo LOGIN_SESSIONS_BEGIN
who || true
echo LOGIN_SESSIONS_END
echo INHIBITORS_BEGIN
systemd-inhibit --list --no-pager 2>&1 || true
echo INHIBITORS_END
if [ -e /run/systemd/shutdown/scheduled ]; then
  echo SCHEDULED_SHUTDOWN=PRESENT
else
  echo SCHEDULED_SHUTDOWN=ABSENT
fi

echo EXACT_AHD_ENDPOINTS_BEGIN
lspci -Dnnd 10ee:7011 || true
echo EXACT_AHD_ENDPOINTS_END
endpoint_count="$(lspci -Dnnd 10ee:7011 | wc -l)"
echo EXACT_AHD_ENDPOINT_COUNT="$endpoint_count"
if [ "$endpoint_count" -eq 1 ]; then
  bdf="$(lspci -Dnnd 10ee:7011 | awk '{print $1}')"
  echo ENDPOINT_BDF="$bdf"
  printf 'ENDPOINT_DRIVER='
  if [ -L "/sys/bus/pci/devices/$bdf/driver" ]; then basename "$(readlink -f "/sys/bus/pci/devices/$bdf/driver")"; else echo NONE; fi
  printf 'DRIVER_OVERRIDE_HEX='
  if [ -r "/sys/bus/pci/devices/$bdf/driver_override" ]; then od -An -tx1 -v "/sys/bus/pci/devices/$bdf/driver_override" | tr -d ' \n'; echo; else echo UNREADABLE; fi
fi

echo PRELOCK_READONLY_RESULT=COMPLETE
echo MMIO_READS=0
echo MMIO_WRITES=0
echo DMA_OPERATIONS=0
echo DRIVER_CHANGES=0
echo PCI_CONFIG_WRITES=0
echo PCI_RESCANS=0
echo FPGA_PROGRAMMING=0
