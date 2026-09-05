#!/usr/bin/env bash
set -u
export LC_ALL=C
echo TASK_ID=G2B-HW0-PRODUCT-R1
echo MODE=FINAL_DUT_STATE_READ_ONLY
printf 'UTC=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
printf 'HOSTNAME=%s\n' "$(hostname)"
printf 'USER=%s\n' "$(id -un)"
printf 'KERNEL=%s\n' "$(uname -r)"
printf 'BOOT_ID=%s\n' "$(cat /proc/sys/kernel/random/boot_id)"

echo '===== TASK_LOCK ====='
lock_path=/tmp/ahd-g2b-hw0-product-r1.lock
printf 'LINUX_LOCK_PATH=%s\n' "$lock_path"
if [ -d "$lock_path" ]; then
  echo LINUX_LOCK_PRESENT=YES
  find "$lock_path" -maxdepth 1 -type f -print -exec sh -c 'for f do echo "--- $f"; cat "$f"; done' sh {} +
else
  echo LINUX_LOCK_PRESENT=NO
fi

echo '===== EXACT_AHD_ENDPOINT ====='
ahd_lines=$(lspci -Dnn 2>&1 | grep -E -i '10ee:7011|10ee:.*0007|12ab:|Xilinx' || true)
if [ -n "$ahd_lines" ]; then
  echo "$ahd_lines"
  echo EXACT_AHD_ENDPOINT_PRESENT=YES
else
  echo EXACT_AHD_ENDPOINT_PRESENT=NO
fi

echo '===== CURRENT_PCIE_TOPOLOGY ====='
lspci -Dnn
echo '===== CURRENT_PCIE_TREE ====='
lspci -Dtv
echo '===== HISTORICAL_AHD_ROOT_FUNCTION ====='
if [ -e /sys/bus/pci/devices/0000:00:01.1 ]; then
  echo BDF_0000_00_01_1_PRESENT=YES
  lspci -Dvv -s 0000:00:01.1
else
  echo BDF_0000_00_01_1_PRESENT=NO
fi

echo '===== XDMA_MODULE ====='
if grep -q '^xdma ' /proc/modules; then
  echo XDMA_MODULE_LOADED=YES
  grep '^xdma ' /proc/modules
  modinfo xdma 2>&1 || true
else
  echo XDMA_MODULE_LOADED=NO
fi

echo '===== XDMA_NODES_AND_BINDINGS ====='
node_count=0
for node in /dev/xdma*; do
  [ -e "$node" ] || continue
  node_count=$((node_count + 1))
  ls -l "$node"
  fuser "$node" 2>&1 || true
done
printf 'XDMA_NODE_COUNT=%s\n' "$node_count"
if [ -d /sys/bus/pci/drivers/xdma ]; then
  echo XDMA_DRIVER_SYSFS_PRESENT=YES
  find /sys/bus/pci/drivers/xdma -maxdepth 1 -type l -printf '%f -> %l\n' | sort
else
  echo XDMA_DRIVER_SYSFS_PRESENT=NO
fi

echo '===== RELEVANT_PROCESSES ====='
ps -eo pid=,user=,comm=,args= | grep -E -i '(^|[ /])(dma_from_device|dma_to_device|xdma|g2b|capture|ffmpeg|gst-launch|vivado|hw_server)([ /]|$)' | grep -v -E 'grep -E|FINAL_DUT_STATE_READ_ONLY' || true

echo '===== RECENT_RELEVANT_KERNEL_MESSAGES ====='
dmesg 2>/dev/null | grep -E -i '10ee:7011|xdma|Xilinx|pci 0000:00:01\.1' | tail -n 120 || true

echo CANDIDATE_PROGRAMMED_ONCE=YES
echo JTAG_FINAL_DONE_EVIDENCE=SEPARATE_LOCAL_LOG
echo ENDPOINT_BDF=N/A
echo LAST_MMIO_STATE=NOT_REACHED_NO_MMIO_ACCESS
echo G2B_STREAM_STATE=NEVER_ENABLED
echo LEGACY_MMIO_READS=0
echo LEGACY_MMIO_WRITES=0
echo G2B_MMIO_READS=0
echo G2B_MMIO_WRITES=0
echo DMA_CAPTURES=0
echo PCI_CONFIG_WRITES=0
echo PCI_RESCANS=0
echo PCI_RESETS=0
echo REBOOT=NO
echo POWER_CYCLE=NO
echo FINAL_DUT_STATE_CAPTURE_COMPLETE=YES
