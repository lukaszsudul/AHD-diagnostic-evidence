#!/usr/bin/env bash
set -u

hdmi=/opt/fpga-hdmi-lab/driver/xdma.ko
platform=/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst
endpoint=/sys/bus/pci/devices/0000:01:00.0

echo "AUDIT=G2B-HW0-DRV-REUSE0_STATIC_MODULE"
echo "UTC=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "KERNEL=$(uname -r)"
echo "ARCH=$(uname -m)"

echo "HDMI_MODULE_BEGIN"
echo "PATH=$hdmi"
if [ -f "$hdmi" ]; then
  echo "PRESENT=YES"
  stat -Lc 'STAT_SIZE=%s%nSTAT_OWNER=%U%nSTAT_GROUP=%G%nSTAT_MODE=%a%nSTAT_MTIME=%y%nSTAT_CTIME=%z%nSTAT_INODE=%i' "$hdmi"
  echo "SHA256=$(sha256sum "$hdmi" | awk '{print $1}')"
  echo "SHA512=$(sha512sum "$hdmi" | awk '{print $1}')"
  echo "FILE=$(file -b "$hdmi" 2>&1)"
  echo "MODINFO_BEGIN"
  modinfo "$hdmi" 2>&1 || true
  echo "MODINFO_END"
  echo "ALIASES_BEGIN"
  modinfo -F alias "$hdmi" 2>&1 || true
  echo "ALIASES_END"
  echo "PARAMETERS_BEGIN"
  modinfo -F parm "$hdmi" 2>&1 || true
  echo "PARAMETERS_END"
  echo "READELF_HEADER_BEGIN"
  readelf -h "$hdmi" 2>&1 || true
  echo "READELF_HEADER_END"
  echo "READELF_NOTES_BEGIN"
  readelf -n "$hdmi" 2>&1 || true
  echo "READELF_NOTES_END"
  echo "READELF_MODINFO_BEGIN"
  readelf -p .modinfo "$hdmi" 2>&1 || true
  echo "READELF_MODINFO_END"
  echo "OBJDUMP_FILE_HEADER_BEGIN"
  objdump -f "$hdmi" 2>&1 || true
  echo "OBJDUMP_FILE_HEADER_END"
  echo "UNRESOLVED_SYMBOLS_BEGIN"
  nm -u "$hdmi" 2>&1 | sort || true
  echo "UNRESOLVED_SYMBOLS_END"
  dependencies=$(modinfo -F depends "$hdmi" 2>/dev/null || true)
  echo "DEPENDENCIES=$dependencies"
  echo "DEPENDENCY_PATHS_BEGIN"
  if [ -n "$dependencies" ]; then
    old_ifs=$IFS
    IFS=,
    for dependency in $dependencies; do
      modinfo -n "$dependency" 2>&1 || true
    done
    IFS=$old_ifs
  fi
  echo "DEPENDENCY_PATHS_END"
else
  echo "PRESENT=NO"
fi
echo "HDMI_MODULE_END"

echo "PLATFORM_MODULE_BEGIN"
echo "PATH=$platform"
if [ -f "$platform" ]; then
  echo "PRESENT=YES"
  stat -Lc 'STAT_SIZE=%s%nSTAT_OWNER=%U%nSTAT_GROUP=%G%nSTAT_MODE=%a%nSTAT_MTIME=%y%nSTAT_CTIME=%z%nSTAT_INODE=%i' "$platform"
  echo "SHA256=$(sha256sum "$platform" | awk '{print $1}')"
  echo "SHA512=$(sha512sum "$platform" | awk '{print $1}')"
  echo "FILE=$(file -b "$platform" 2>&1)"
  echo "MODINFO_BEGIN"
  modinfo "$platform" 2>&1 || true
  echo "MODINFO_END"
  echo "ALIASES_BEGIN"
  modinfo -F alias "$platform" 2>&1 || true
  echo "ALIASES_END"
else
  echo "PRESENT=NO"
fi
echo "PLATFORM_MODULE_END"

echo "FINAL_STATE_BEGIN"
if [ -d /sys/module/xdma ]; then echo "XDMA_MODULE_LOADED=YES"; else echo "XDMA_MODULE_LOADED=NO"; fi
if [ -L "$endpoint/driver" ]; then echo "ENDPOINT_DRIVER=$(basename "$(readlink -f "$endpoint/driver")")"; else echo "ENDPOINT_DRIVER=UNBOUND"; fi
echo "DRIVER_OVERRIDE=$(cat "$endpoint/driver_override" 2>/dev/null || true)"
echo "XDMA_NODES_BEGIN"
find /dev -maxdepth 1 -name 'xdma*' -printf '%p\n' 2>/dev/null | sort
echo "XDMA_NODES_END"
echo "FINAL_STATE_END"
echo "AUDIT_COMPLETE=YES"
