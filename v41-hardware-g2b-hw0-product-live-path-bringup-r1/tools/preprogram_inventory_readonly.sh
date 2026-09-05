#!/usr/bin/env bash
set -u
export LC_ALL=C

emit() { printf '%s=%s\n' "$1" "$2"; }
section() { printf '\n===== %s =====\n' "$1"; }

emit TASK_ID G2B-HW0-PRODUCT-R1
emit INVENTORY_MODE READ_ONLY_PREPROGRAM
emit REMOTE_UTC "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
emit HOSTNAME "$(hostname)"
emit REMOTE_USER "${SUDO_USER:-$(id -un)}"
emit EFFECTIVE_USER "$(id -un)"
emit EFFECTIVE_UID "$(id -u)"
emit MACHINE_ID "$(cat /etc/machine-id 2>/dev/null || true)"
emit BOOT_ID "$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || true)"
emit KERNEL "$(uname -r)"
emit UPTIME_SECONDS "$(cut -d' ' -f1 /proc/uptime)"

section NETWORK_IDENTITY
ip -4 -o addr show scope global 2>&1 || true
ip route show 2>&1 || true

section RELEVANT_PROCESSES
ps -eo pid=,ppid=,user=,lstart=,stat=,cmd= --sort=pid 2>&1 | \
  grep -E -i '(^|[ /])(xdma|dma_from_device|dma_to_device|test_chrdev|ahd|g2b|capture|ffmpeg|gst-launch|v4l2|vivado|hw_server|cs_server|xsdb|openocd)([ /]|$)' || true

section RELEVANT_LOCKS
for root in /run/lock /var/lock /tmp; do
  [ -d "$root" ] || continue
  find "$root" -xdev -maxdepth 3 \
    \( -iname '*ahd*' -o -iname '*g2b*' -o -iname '*xdma*' -o -iname '*fpga*' -o -iname '*jtag*' -o -iname '*codex*' \) \
    -printf '%y %p owner=%u group=%g mode=%m mtime=%TY-%Tm-%TdT%TH:%TM:%TS%Tz\n' 2>/dev/null || true
done

section PCI_TOPOLOGY
lspci -Dtv 2>&1 || true

section PCI_IDENTITIES
lspci -Dnn 2>&1 || true

section RELEVANT_PCI_SYSFS
for d in /sys/bus/pci/devices/*; do
  [ -r "$d/vendor" ] || continue
  vendor=$(cat "$d/vendor" 2>/dev/null || true)
  device=$(cat "$d/device" 2>/dev/null || true)
  class=$(cat "$d/class" 2>/dev/null || true)
  driver=NONE
  [ -L "$d/driver" ] && driver=$(basename "$(readlink -f "$d/driver")")
  if [ "$vendor" = 0x10ee ] || [ "$vendor" = 0x12ab ] || [ "$driver" = xdma ]; then
    bdf=$(basename "$d")
    iommu=NONE
    [ -L "$d/iommu_group" ] && iommu=$(basename "$(readlink -f "$d/iommu_group")")
    slot=NONE
    [ -r "$d/physical_slot" ] && slot=$(cat "$d/physical_slot")
    printf 'BDF=%s VENDOR=%s DEVICE=%s CLASS=%s DRIVER=%s IOMMU_GROUP=%s PHYSICAL_SLOT=%s\n' \
      "$bdf" "$vendor" "$device" "$class" "$driver" "$iommu" "$slot"
  fi
done

section EXPECTED_AHD_ENDPOINT_VERBOSE
if [ -e /sys/bus/pci/devices/0000:01:00.0 ]; then
  lspci -Dvv -s 0000:01:00.0 2>&1 || true
else
  echo EXPECTED_AHD_ENDPOINT_0000_01_00_0=ABSENT
fi

section EXPECTED_AHD_ROOT_VERBOSE
if [ -e /sys/bus/pci/devices/0000:00:01.1 ]; then
  lspci -Dvv -s 0000:00:01.1 2>&1 || true
else
  echo EXPECTED_AHD_ROOT_0000_00_01_1=ABSENT
fi

section XDMA_MODULE
lsmod 2>&1 | awk 'NR==1 || $1=="xdma"' || true
modinfo xdma 2>&1 || true
module_path=$(modinfo -n xdma 2>/dev/null || true)
if [ -n "$module_path" ] && [ -f "$module_path" ]; then
  sha256sum "$module_path" 2>&1 || true
fi

section XDMA_NODES
shopt -s nullglob
nodes=(/dev/xdma*)
emit XDMA_NODE_COUNT "${#nodes[@]}"
for n in "${nodes[@]}"; do
  printf 'NODE=%s\n' "$n"
  ls -l "$n" 2>&1 || true
  udevadm info -q path -n "$n" 2>&1 | sed 's/^/UDEV_PATH=/' || true
  udevadm info -q property -n "$n" 2>/dev/null | grep -E '^(DEVPATH|DEVNAME|MAJOR|MINOR)=' || true
  cls="/sys/class/$(stat -c '%F' "$n" 2>/dev/null | grep -q character && echo xdma || true)"
  base=$(basename "$n")
  if [ -L "/sys/class/xdma/$base/device" ]; then
    printf 'SYSFS_DEVICE=%s\n' "$(readlink -f "/sys/class/xdma/$base/device")"
  fi
done

section XDMA_NODE_USERS
if [ "${#nodes[@]}" -gt 0 ]; then
  lsof -nP -- "${nodes[@]}" 2>&1 || true
  fuser -v -- "${nodes[@]}" 2>&1 || true
else
  echo NO_XDMA_NODES
fi

section RELEVANT_KERNEL_LOG
journalctl -k -b --no-pager 2>&1 | \
  grep -E -i 'xdma|10ee:7011|0000:01:00.0|0000:00:01.1|aer|pcie.*error|pci.*error' | tail -n 300 || true

emit MMIO_READS 0
emit MMIO_WRITES 0
emit DMA_OPERATIONS 0
emit DRIVER_CHANGES 0
emit PCI_RECOVERY_OPERATIONS 0
emit INVENTORY_COMPLETE YES
