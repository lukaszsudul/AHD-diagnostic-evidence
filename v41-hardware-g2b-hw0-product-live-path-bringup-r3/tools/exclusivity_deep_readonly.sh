#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C

lock_path=/tmp/ahd-g2b-hw0-product-r3-20260906T140148Z.lock
lock_receipt="$lock_path/receipt.json"
bdf=0000:01:00.0
device_path="/sys/bus/pci/devices/$bdf"

test "$(hostname)" = VCDE-DUT-1
test "$(id -u)" = 1000
test "$(cat /etc/machine-id)" = 0e90f50d9465492b80258da5658446f8
test "$(cat /proc/sys/kernel/random/boot_id)" = 52b0bf13-e9d1-4558-ae13-d08f4ecc8dac
test -f "$lock_receipt"
grep -Fq '"task_id": "G2B-HW0-PRODUCT-R3"' "$lock_receipt"
grep -Fq '"lock_release_state": "HELD"' "$lock_receipt"
sudo -S -p '' -v

session_pids=""
cursor="$$"
while [ "$cursor" -gt 1 ] 2>/dev/null; do
  session_pids="$session_pids $cursor"
  stat_line="$(cat "/proc/$cursor/stat" 2>/dev/null || true)"
  [ -n "$stat_line" ] || break
  cursor="$(printf '%s\n' "$stat_line" | awk '{print $4}')"
done

echo TASK=G2B-HW0-PRODUCT-R3
echo PHASE=EXCLUSIVITY_DEEP_READONLY
echo UTC="$(date -u +%Y-%m-%dT%H:%M:%S.%NZ)"
echo LINUX_LOCK=HELD
echo CURRENT_SESSION_ANCESTOR_PIDS="$session_pids"

echo MATCHED_HARDWARE_PROCESS_METADATA_BEGIN
sudo -n python3 - $session_pids <<'PY'
import hashlib
import os
import re
import sys

excluded = {int(value) for value in sys.argv[1:] if value.isdigit()}
terms = [
    "xdma", "vivado", "hw_server", "cs_server", "jtag", "fpga", "g2b", "ahd",
    "hdmi", "v4l2", "insmod", "rmmod", "modprobe", "new_id", "driver_override",
    "/sys/bus/pci/drivers", "/dev/xdma", "dma_from_device", "dma_to_device",
    "pci rescan", "pcie rescan", "unbind", "reboot", "shutdown", "poweroff",
]
matches = []
for name in os.listdir('/proc'):
    if not name.isdigit():
        continue
    pid = int(name)
    if pid in excluded or pid == os.getpid():
        continue
    try:
        raw = open(f'/proc/{pid}/cmdline', 'rb').read()
        if not raw:
            continue
        text = raw.replace(b'\0', b' ').decode('utf-8', 'replace').lower()
        hit = sorted({term for term in terms if term in text})
        if not hit:
            continue
        status = {}
        with open(f'/proc/{pid}/status', encoding='utf-8', errors='replace') as handle:
            for line in handle:
                if ':' in line:
                    key, value = line.split(':', 1)
                    status[key] = value.strip()
        matches.append((pid, status.get('PPid', '?'), status.get('Uid', '?').split()[0],
                        status.get('Name', '?'), ','.join(hit), hashlib.sha256(raw).hexdigest()))
    except (FileNotFoundError, PermissionError, ProcessLookupError):
        continue
for row in sorted(matches):
    print('PID=%s PPID=%s UID=%s COMM=%s MATCHED_TERMS=%s CMDLINE_SHA256=%s' % row)
print(f'MATCHED_HARDWARE_PROCESS_COUNT={len(matches)}')
PY
echo MATCHED_HARDWARE_PROCESS_METADATA_END

echo PCI_CONTROL_OPEN_FDS_BEGIN
sudo -n python3 - <<'PY'
import os

needles = ('/sys/bus/pci/drivers/', '/remove', '/rescan', '/reset', '/driver_override', '/new_id', '/bind', '/unbind')
matches = []
for name in os.listdir('/proc'):
    if not name.isdigit():
        continue
    fd_dir = f'/proc/{name}/fd'
    try:
        fds = os.listdir(fd_dir)
    except (FileNotFoundError, PermissionError, ProcessLookupError):
        continue
    for fd in fds:
        try:
            target = os.readlink(f'{fd_dir}/{fd}')
        except (FileNotFoundError, PermissionError, ProcessLookupError, OSError):
            continue
        if target.startswith('/sys/') and any(needle in target for needle in needles):
            matches.append((int(name), fd, target))
for pid, fd, target in sorted(matches):
    print(f'PID={pid} FD={fd} TARGET={target}')
print(f'PCI_CONTROL_OPEN_FD_COUNT={len(matches)}')
PY
echo PCI_CONTROL_OPEN_FDS_END

echo SSH_ACCOUNTING_BEGIN
printf 'CURRENT_SSH_CONNECTION_REDACTED_PEER=%s\n' "$(printf '%s\n' "${SSH_CONNECTION:-N/A}" | awk '{print "present fields=" NF}')"
ss -Htn state established '( sport = :22 )' 2>/dev/null | awk '{print $1, $3, $4}' | sort || true
ssh_connection_count="$( { ss -Htn state established '( sport = :22 )' 2>/dev/null || true; } | wc -l)"
echo SSH_ESTABLISHED_CONNECTION_COUNT="$ssh_connection_count"
ps -C sshd -o pid=,ppid=,uid=,user=,stat=,comm= --sort=pid || true
echo SSH_ACCOUNTING_END

echo ALL_RELEVANT_LOCK_ENTRIES_BEGIN
find /tmp /run/lock /var/lock -mindepth 1 -maxdepth 4 \
  \( -iname '*ahd*' -o -iname '*g2b*' -o -iname '*xdma*' -o -iname '*jtag*' -o -iname '*fpga*' \) \
  -printf '%y %p\n' 2>/dev/null | sort || true
echo ALL_RELEVANT_LOCK_ENTRIES_END
relevant_lock_roots="$( { find /tmp /run/lock /var/lock -mindepth 1 -maxdepth 3 \( -type d -o -type f \) \( -iname '*ahd*.lock' -o -iname '*g2b*.lock' -o -iname '*xdma*.lock' -o -iname '*jtag*.lock' -o -iname '*fpga*.lock' \) -print 2>/dev/null || true; } | wc -l)"
echo RELEVANT_LOCK_ROOT_COUNT="$relevant_lock_roots"

echo RECENT_HARDWARE_ARTIFACT_DIRECTORIES_BEGIN
find "$HOME/vcde_artifacts" -mindepth 1 -maxdepth 3 -type d -mmin -720 \
  \( -iname '*g2b*' -o -iname '*ahd*' -o -iname '*xdma*' -o -iname '*hdmi*' \) \
  -printf '%TY-%Tm-%TdT%TH:%TM:%TSZ %p\n' 2>/dev/null | sort || true
echo RECENT_HARDWARE_ARTIFACT_DIRECTORIES_END

echo MODULE_NODE_ENDPOINT_RECHECK_BEGIN
echo PLATFORM_XDMA_MODULE_COUNT="$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)"
echo AHD_XDMA_MODULE_COUNT="$(awk '$1 == "xdma_ahd_pcie" {count++} END {print count+0}' /proc/modules)"
echo XDMA_NODE_COUNT="$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)"
echo XDMA_CLASS_COUNT="$(if [ -d /sys/class/xdma ]; then find /sys/class/xdma -mindepth 1 -maxdepth 1 -print | wc -l; else echo 0; fi)"
echo EXACT_AHD_ENDPOINT_COUNT="$(lspci -Dnnd 10ee:7011 | wc -l)"
echo ENDPOINT_BDF="$bdf"
printf 'ENDPOINT_DRIVER='
if [ -L "$device_path/driver" ]; then basename "$(readlink -f "$device_path/driver")"; else echo NONE; fi
echo ENDPOINT_LINK="$(cat "$device_path/current_link_speed"),x$(cat "$device_path/current_link_width")"
echo MODULE_NODE_ENDPOINT_RECHECK_END

echo SYSTEM_JOB_RECHECK_BEGIN
systemctl list-jobs --no-pager --no-legend 2>&1 || true
if [ -e /run/systemd/shutdown/scheduled ]; then echo SCHEDULED_SHUTDOWN=PRESENT; else echo SCHEDULED_SHUTDOWN=ABSENT; fi
echo SYSTEM_JOB_RECHECK_END

test "$ssh_connection_count" -eq 1
test "$relevant_lock_roots" -eq 1
test "$(awk '$1 == "xdma" {count++} END {print count+0}' /proc/modules)" -eq 0
test "$(awk '$1 == "xdma_ahd_pcie" {count++} END {print count+0}' /proc/modules)" -eq 0
test "$(find /dev -mindepth 1 -maxdepth 1 -name 'xdma*' -print | wc -l)" -eq 0
test ! -L "$device_path/driver"

echo MMIO_READS=0
echo MMIO_WRITES=0
echo DMA_OPERATIONS=0
echo DRIVER_CHANGES=0
echo PCI_CONFIG_WRITES=0
echo PCI_RESCANS=0
echo PCI_RESETS=0
echo FPGA_PROGRAMMING=0
echo DEEP_EXCLUSIVITY_INVENTORY=COMPLETE
echo RESULT=PASS
