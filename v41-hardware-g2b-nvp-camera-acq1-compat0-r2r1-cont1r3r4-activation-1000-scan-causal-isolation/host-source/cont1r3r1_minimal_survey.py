#!/usr/bin/env python3
"""Read-only identity and hardware-ownership admission survey for CONT1R3R1."""
import datetime
import getpass
import glob
import json
import os
import pathlib
import platform
import re
import socket
import stat

ARTIFACT_ROOT = pathlib.Path('/home/vcdeagent1/vcde_artifacts')
DEVICE_PATHS = ('/dev/xdma0_user', '/dev/xdma0_c2h_0')
TERMS = ('vcde', 'g2b', 'nvp', 'xdma', 'vivado', 'hw_server', 'cs_server')

def read_text(path):
    try:
        return pathlib.Path(path).read_text(encoding='utf-8', errors='replace').strip()
    except (FileNotFoundError, PermissionError, OSError):
        return None

def describe(path):
    path = pathlib.Path(path)
    try:
        info = path.lstat()
    except (FileNotFoundError, PermissionError, OSError) as exc:
        return {'path': str(path), 'inspection_error': type(exc).__name__}
    return {
        'path': str(path), 'uid': info.st_uid, 'gid': info.st_gid,
        'mode': format(stat.S_IMODE(info.st_mode), '04o'),
        'type': 'symlink' if stat.S_ISLNK(info.st_mode) else
                'directory' if stat.S_ISDIR(info.st_mode) else 'file',
    }

def project_locks():
    matches = []
    if not ARTIFACT_ROOT.is_dir():
        return matches
    root_depth = len(ARTIFACT_ROOT.parts)
    for current, dirs, files in os.walk(ARTIFACT_ROOT, followlinks=False):
        if len(pathlib.Path(current).parts) - root_depth >= 4:
            dirs[:] = []
        for name in sorted(set(dirs + files)):
            low = name.lower()
            if low.endswith('.lock') or ('lock' in low and re.search('ahd|g2b|nvp', low)):
                matches.append(describe(pathlib.Path(current) / name))
    return sorted(matches, key=lambda value: value['path'])

def process_inventory():
    result = []
    own_pid = os.getpid()
    for proc in pathlib.Path('/proc').glob('[0-9]*'):
        pid = int(proc.name)
        if pid == own_pid:
            continue
        try:
            command = (proc / 'cmdline').read_bytes().replace(b'\0', b' ').decode(
                'utf-8', errors='replace').strip()
            comm = read_text(proc / 'comm') or ''
            if not any(term in (comm + ' ' + command).lower() for term in TERMS):
                continue
            uid_match = re.search(r'^Uid:\s+(\d+)', read_text(proc / 'status') or '', re.M)
            result.append({'pid': pid, 'uid': int(uid_match.group(1)) if uid_match else None,
                           'comm': comm, 'command': command})
        except (FileNotFoundError, ProcessLookupError):
            continue
        except (PermissionError, OSError) as exc:
            result.append({'pid': pid, 'inspection_error': type(exc).__name__})
    return sorted(result, key=lambda value: value['pid'])

def device_holders():
    result = {path: [] for path in DEVICE_PATHS}
    for proc in pathlib.Path('/proc').glob('[0-9]*'):
        try:
            fds = list((proc / 'fd').iterdir())
        except (FileNotFoundError, ProcessLookupError, PermissionError, OSError):
            continue
        for fd in fds:
            try:
                target = os.readlink(fd)
            except (FileNotFoundError, ProcessLookupError, PermissionError, OSError):
                continue
            for device in DEVICE_PATHS:
                if target == device or os.path.realpath(target) == os.path.realpath(device):
                    result[device].append({'pid': int(proc.name), 'fd': fd.name,
                                           'comm': read_text(proc / 'comm')})
    return result

processes = process_inventory()
result = {
    'schema': 'AHD_V41_CONT1R3R1_MINIMAL_DUT_SURVEY_V1',
    'read_only': True,
    'timestamp_utc': datetime.datetime.now(datetime.timezone.utc).isoformat(),
    'hostname': socket.gethostname(), 'user': getpass.getuser(),
    'uid': os.getuid(), 'euid': os.geteuid(),
    'machine_id': read_text('/etc/machine-id'),
    'boot_id': read_text('/proc/sys/kernel/random/boot_id'),
    'kernel': platform.release(),
    'product_uuid': read_text('/sys/class/dmi/id/product_uuid'),
    'artifact_root': describe(ARTIFACT_ROOT),
    'project_locks': project_locks(),
    'matching_processes': processes,
    'xdma_module_loaded': pathlib.Path('/sys/module/xdma_ahd_pcie').is_dir(),
    'xdma_nodes': [describe(path) for path in sorted(glob.glob('/dev/xdma*'))],
    'xdma_device_holders': device_holders(),
    'active_jtag_vivado_processes': [item for item in processes if any(
        term in (item.get('comm', '') + ' ' + item.get('command', '')).lower()
        for term in ('vivado', 'hw_server', 'cs_server'))],
}
print(json.dumps(result, sort_keys=True, separators=(',', ':')))
