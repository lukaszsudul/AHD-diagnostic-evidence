#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
umask 077

task_root="$HOME/vcde_artifacts/g2b_hw0_product_r3/20260906T140148Z"
lock_path=/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock
lock_receipt="$lock_path/receipt.json"
bdf=0000:01:00.0
device="/sys/bus/pci/devices/$bdf"
remote_log="$task_root/raw/FINAL_STATE_AND_LINUX_LOCK_RELEASE.log"

if [ -e "$remote_log" ]; then echo FINAL_RELEASE_OUTPUT_EXISTS; exit 90; fi
exec > >(tee "$remote_log") 2>&1

echo TASK=G2B-HW0-PRODUCT-R3
echo PHASE=FINAL_STATE_AND_LINUX_LOCK_RELEASE_AFTER_GOVERNANCE_HARD_STOP
echo "UTC_START=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
[ "$(hostname)" = VCDE-DUT-1 ]
[ "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8 ]
[ "$(cat /proc/sys/kernel/random/boot_id)" = 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac ]
[ "$(uname -r)" = 7.0.0-29-generic ]
[ "$(uname -m)" = x86_64 ]
[ -d "$lock_path" ] && [ ! -L "$lock_path" ]
[ -f "$lock_receipt" ] && [ ! -L "$lock_receipt" ]
grep -Fq '"task_id": "G2B-HW0-PRODUCT-R3"' "$lock_receipt"
grep -Fq '"lock_release_state": "HELD"' "$lock_receipt"
[ "$(find "$lock_path" -mindepth 1 -maxdepth 1 -printf '%f\n' | sort)" = receipt.json ]
sudo -S -p '' -v

echo "HOSTNAME=$(hostname)"
echo "MACHINE_ID=$(cat /etc/machine-id)"
echo "BOOT_ID=$(cat /proc/sys/kernel/random/boot_id)"
echo "KERNEL=$(uname -r)"
echo "ARCH=$(uname -m)"
echo "KERNEL_TAINT_FINAL=$(cat /proc/sys/kernel/tainted)"
echo "AHD_XDMA_MODULE_COUNT=$(awk '$1=="xdma_ahd_pcie"{n++} END{print n+0}' /proc/modules)"
echo "PLATFORM_XDMA_MODULE_COUNT=$(awk '$1=="xdma"{n++} END{print n+0}' /proc/modules)"
echo "XDMA_NODE_COUNT=$(find /dev -maxdepth 1 -name 'xdma*' -print | wc -l)"
echo "XDMA_CLASS_COUNT=$(if [ -d /sys/class/xdma ]; then find /sys/class/xdma -mindepth 1 -maxdepth 1 -print | wc -l; else echo 0; fi)"
[ "$(awk '$1=="xdma_ahd_pcie"{n++} END{print n+0}' /proc/modules)" -eq 0 ]
[ "$(awk '$1=="xdma"{n++} END{print n+0}' /proc/modules)" -eq 0 ]
[ "$(find /dev -maxdepth 1 -name 'xdma*' -print | wc -l)" -eq 0 ]
[ -d "$device" ]
[ "$(cat "$device/vendor")" = 0x10ee ]
[ "$(cat "$device/device")" = 0x7011 ]
[ "$(cat "$device/subsystem_vendor")" = 0x10ee ]
[ "$(cat "$device/subsystem_device")" = 0x0007 ]
[ "$(cat "$device/class")" = 0x058000 ]
[ "$(cat "$device/modalias")" = pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00 ]
[ ! -L "$device/driver" ]
echo ENDPOINT_BDF="$bdf"
echo ENDPOINT_DRIVER=NONE
echo "DRIVER_OVERRIDE_RAW=$(cat "$device/driver_override")"
echo "ENDPOINT_CURRENT_LINK_SPEED=$(cat "$device/current_link_speed")"
echo "ENDPOINT_CURRENT_LINK_WIDTH=$(cat "$device/current_link_width")"
[ "$(cat "$device/current_link_speed")" = '5.0 GT/s PCIe' ]
[ "$(cat "$device/current_link_width")" = 1 ]

echo "RECENT_BLOCKING_KERNEL_SIGNATURES_BEGIN"
sudo -n journalctl -k --since '2026-09-06 14:00:00 UTC' --no-pager 2>/dev/null |
  grep -Ei 'BUG:|Oops:|Call Trace:|hung task|use-after-free|DMA-API|IOMMU.*fault|AER:.*(fatal|non-fatal|uncorrected)|Completion Timeout|Malformed TLP|Unsupported Request|surprise.*link|link.*down' || true
echo "RECENT_BLOCKING_KERNEL_SIGNATURES_END"
blocking_count="$(sudo -n journalctl -k --since '2026-09-06 14:00:00 UTC' --no-pager 2>/dev/null |
  grep -Eic 'BUG:|Oops:|Call Trace:|hung task|use-after-free|DMA-API|IOMMU.*fault|AER:.*(fatal|non-fatal|uncorrected)|Completion Timeout|Malformed TLP|Unsupported Request|surprise.*link|link.*down' || true)"
echo "RECENT_BLOCKING_KERNEL_SIGNATURE_COUNT=$blocking_count"
[ "$blocking_count" -eq 0 ]

echo MODULE_LOAD_ATTEMPTS=0
echo MODULE_UNLOAD_ATTEMPTS=0
echo AUTOMATIC_BIND_OCCURRED=NO
echo MMIO_READS=0
echo MMIO_WRITES=0
echo DMA_READS=0
echo STREAM_CONTROL_WRITES=0
echo FPGA_PROGRAMMING=0
echo FLASH_PROGRAMMING=0
echo REBOOT=0
echo POWER_CYCLE=0
echo FINAL_TECHNICAL_STATE=PASS_CLEAN_PRELOAD_STATE

release_receipt="$task_root/locks/LINUX_LOCK_RELEASE_RECEIPT.txt"
[ ! -e "$release_receipt" ]
printf 'TASK=G2B-HW0-PRODUCT-R3\nLOCK_PATH=/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock\nRELEASE_UTC=%s\nFINAL_STATE=PASS_CLEAN_PRELOAD_STATE\nMODULE_LOAD_ATTEMPTS=0\n' "$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)" > "$release_receipt"
chmod 0444 "$release_receipt"
rm -- "$lock_receipt"
rmdir -- "$lock_path"
[ ! -e "$lock_path" ]
echo LINUX_LOCK_RELEASED=YES
echo "LINUX_LOCK_RELEASE_RECEIPT_SHA256=$(sha256sum "$release_receipt" | awk '{print toupper($1)}')"
echo "UTC_END=$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
echo RESULT=PASS
