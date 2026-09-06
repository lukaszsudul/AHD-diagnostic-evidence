#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
umask 077

lock_path=/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock
receipt_path="$lock_path/receipt.json"
artifact_parent="$HOME/vcde_artifacts/g2b_hw0_product_r3"
artifact_path="$artifact_parent/20260906T140148Z"
expected_boot_id=52b0bf13-e9d1-4558-ae13-d08f4ecc8dac

test "$(hostname)" = VCDE-DUT-1
test "$(id -u)" = 1000
test "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
test "$(cat /proc/sys/kernel/random/boot_id)" = "$expected_boot_id"
test "$(uname -r)" = 7.0.0-29-generic
test "$(uname -m)" = x86_64
ip -o -4 addr show scope global | awk '{print $4}' | grep -Eq '^10\.132\.1\.111/'
test ! -e "$lock_path"
test ! -e "$artifact_path"

process_pattern='^(vivado|vivado_lab|hw_server|cs_server|xsdb|xicom|impact|xbutil|xbmgmt|dma_from_device|dma_to_device|reg_rw|test_chrdev|xdma_test|g2b_capture|g2b_mmio|ffmpeg|gst-launch.*|v4l2-ctl)$'
relevant_process_count="$(ps -eo comm= | awk -v p="$process_pattern" 'BEGIN {IGNORECASE=1} $1 ~ p {count++} END {print count+0}')"
platform_xdma_count="$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)"
ahd_xdma_count="$(awk '$1 == "xdma_ahd_pcie" {count++} END {print count+0}' /proc/modules)"
node_count="$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)"
class_count=0
if [ -d /sys/class/xdma ]; then class_count="$(find /sys/class/xdma -mindepth 1 -maxdepth 1 -print | wc -l)"; fi
other_task_lock_count="$( { find /tmp /run/lock /var/lock -mindepth 1 -maxdepth 3 -type d \( -iname '*ahd*.lock' -o -iname '*g2b*.lock' -o -iname '*xdma*.lock' -o -iname '*jtag*.lock' -o -iname '*fpga*.lock' \) -print 2>/dev/null || true; } | wc -l)"
endpoint_count="$(lspci -Dnnd 10ee:7011 | wc -l)"

test "$relevant_process_count" -eq 0
test "$platform_xdma_count" -eq 0
test "$ahd_xdma_count" -eq 0
test "$node_count" -eq 0
test "$class_count" -eq 0
test "$other_task_lock_count" -eq 0
test "$endpoint_count" -eq 1
bdf="$(lspci -Dnnd 10ee:7011 | awk '{print $1}')"
test "$bdf" = 0000:01:00.0
test ! -L "/sys/bus/pci/devices/$bdf/driver"
driver_override="$(cat "/sys/bus/pci/devices/$bdf/driver_override")"
test -z "$driver_override" -o "$driver_override" = '(null)'

mkdir -- "$lock_path"
mkdir -p -- "$artifact_parent"
mkdir -- "$artifact_path"
mkdir -- "$artifact_path/raw" "$artifact_path/tools" "$artifact_path/captures" "$artifact_path/private-video" "$artifact_path/locks"

python3 - "$receipt_path" "$artifact_path" "$expected_boot_id" <<'PY'
import datetime
import json
import socket
import sys

receipt_path, artifact_path, boot_id = sys.argv[1:]
receipt = {
    "schema": "AHD_DUT_TASK_LOCK_V1",
    "task_id": "G2B-HW0-PRODUCT-R3",
    "task_owner_session": "Codex task 01a07701-1c3a-72d2-9352-130ffc66a71c / root agent",
    "controller_identity": "NBLSUDUL",
    "linux_dut_identity": "VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111",
    "hostname": socket.gethostname(),
    "boot_id": boot_id,
    "lock_timestamp_utc": datetime.datetime.now(datetime.timezone.utc).isoformat().replace("+00:00", "Z"),
    "lock_path": "/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock",
    "artifact_path": artifact_path,
    "candidate_bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
    "driver_candidate_sha256": "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77",
    "expected_endpoint_bdf": "0000:01:00.0",
    "relevant_process_count_before_lock": 0,
    "platform_xdma_module_count_before_lock": 0,
    "ahd_xdma_module_count_before_lock": 0,
    "xdma_device_node_count_before_lock": 0,
    "xdma_class_count_before_lock": 0,
    "other_task_lock_count_before_lock": 0,
    "controller_lock_state": "HELD",
    "lock_release_state": "HELD"
}
with open(receipt_path, "x", encoding="utf-8", newline="\n") as handle:
    json.dump(receipt, handle, ensure_ascii=False, indent=2)
    handle.write("\n")
PY

test -f "$receipt_path"
echo TASK=G2B-HW0-PRODUCT-R3
echo PHASE=LINUX_LOCK_ACQUIRE_V2
echo LINUX_LOCK=HELD
echo LINUX_LOCK_PATH="$lock_path"
echo DUT_ARTIFACT_PATH="$artifact_path"
echo BOOT_ID="$expected_boot_id"
echo RELEVANT_PROCESS_COUNT_BEFORE_LOCK="$relevant_process_count"
echo PLATFORM_XDMA_MODULE_COUNT_BEFORE_LOCK="$platform_xdma_count"
echo AHD_XDMA_MODULE_COUNT_BEFORE_LOCK="$ahd_xdma_count"
echo XDMA_NODE_COUNT_BEFORE_LOCK="$node_count"
echo XDMA_CLASS_COUNT_BEFORE_LOCK="$class_count"
echo OTHER_TASK_LOCK_COUNT_BEFORE_LOCK="$other_task_lock_count"
echo ENDPOINT_BDF="$bdf"
echo LINUX_LOCK_RECEIPT_SHA256="$(sha256sum "$receipt_path" | awk '{print $1}')"
echo LINUX_LOCK_RECEIPT_BEGIN
cat "$receipt_path"
echo LINUX_LOCK_RECEIPT_END
echo RESULT=PASS
