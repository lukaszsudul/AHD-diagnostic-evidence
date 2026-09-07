"""One-attempt sealed R3R4R5 AHD XDMA load and node-to-BDF proof."""
import hashlib
import json
import os
import pathlib
import re
import subprocess
import sys
import time


P = pathlib.Path
TASK = "G2B-HW0-PRODUCT-R3R4R5"
ROOT = P("/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r5/20260907T151342Z")
LOCK = P("/tmp/ahd-g2b-hw0-product-r3r4r5-20260907T151342Z.lock/receipt.json")
MODULE = P("/home/vcdeagent1/vcde_artifacts/g2b_hw0_drv1/20260906T121539Z/xdma_ahd_pcie.ko")
ENDPOINT = P("/sys/bus/pci/devices/0000:01:00.0")
ROOT_PORT = P("/sys/bus/pci/devices/0000:00:01.1")
EXPECTED_BOOT = "614295f4-c62b-4430-ae67-06013bea7084"
EXPECTED_SHA256 = "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


def command(*args):
    return subprocess.check_output(args, text=True).rstrip("\n")


def aer(path):
    values = {}
    for item in sorted(path.glob("aer_*")):
        try:
            values[item.name] = item.read_text().strip()
        except OSError:
            values[item.name] = "UNAVAILABLE"
    return values


def open_xdma_fds():
    found = []
    for proc in P("/proc").iterdir():
        if not proc.name.isdigit():
            continue
        try:
            comm = (proc / "comm").read_text().strip()
            cmdline = (proc / "cmdline").read_bytes().replace(b"\0", b" ").decode(
                "utf-8", "replace").strip()
            for desc in (proc / "fd").iterdir():
                try:
                    target = os.readlink(desc)
                except OSError:
                    continue
                if target.startswith("/dev/xdma"):
                    found.append({"pid": int(proc.name), "comm": comm,
                                  "cmdline": cmdline, "target": target})
        except (OSError, PermissionError):
            pass
    return found


def validate_lock():
    require(LOCK.is_file(), "R3R4R5_LINUX_LOCK_REQUIRED")
    lock = json.loads(LOCK.read_text())
    boot = P("/proc/sys/kernel/random/boot_id").read_text().strip()
    require(lock.get("task") == TASK and lock.get("state") == "HELD" and
            lock.get("boot_id") == boot == EXPECTED_BOOT,
            "R3R4R5_LINUX_LOCK_OR_BOOT_MISMATCH")
    return boot


result = {"task": TASK, "result": "BLOCKED", "insmod_attempts": 0,
          "normal_unload_attempts": 0, "forced_unloads": 0,
          "mmio_operations": 0, "dma_operations": 0}
loaded = False
try:
    boot = validate_lock()
    preload = json.loads((ROOT / "logs/preload-inventory.json").read_text())
    require(preload.get("result") == "PASS" and
            preload.get("recovery_path") == "NOT_REQUIRED",
            "R3R4R5_PRELOAD_OR_RECOVERY_DECISION_NOT_PASS")
    require(MODULE.is_file() and not MODULE.is_symlink(), "SEALED_DRIVER_MISSING")
    require(not (MODULE.stat().st_mode & 0o222), "SEALED_DRIVER_IS_WRITABLE")
    require(not (MODULE.parent.stat().st_mode & 0o222),
            "SEALED_DRIVER_DIRECTORY_IS_WRITABLE")

    fields = ("name", "vermagic", "alias", "depends", "srcversion",
              "signer", "sig_id")
    info = {field: command("modinfo", "-F", field, str(MODULE))
            for field in fields}
    info.update(
        sha256=hashlib.sha256(MODULE.read_bytes()).hexdigest().upper(),
        bytes=MODULE.stat().st_size,
        secure_boot=command("mokutil", "--sb-state"),
        elf=command("readelf", "-h", str(MODULE)),
        notes=command("readelf", "-n", str(MODULE)),
        taint_before=int(P("/proc/sys/kernel/tainted").read_text()),
    )
    (ROOT / "logs/driver-verification.json").write_text(
        json.dumps(info, indent=2) + "\n")
    require(info["bytes"] == 3296104, "SEALED_DRIVER_SIZE_MISMATCH")
    require(info["sha256"] == EXPECTED_SHA256, "SEALED_DRIVER_HASH_MISMATCH")
    require(info["name"] == "xdma_ahd_pcie", "DRIVER_INTERNAL_NAME_MISMATCH")
    require(info["vermagic"] ==
            "7.0.0-29-generic SMP preempt mod_unload modversions ",
            "DRIVER_VERMAGIC_MISMATCH")
    require(info["alias"] ==
            "pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*",
            "DRIVER_ALIAS_MISMATCH")
    require(info["depends"] == "" and info["signer"] == "" and
            info["sig_id"] == "", "DRIVER_METADATA_UNEXPECTED")
    require(info["srcversion"] == "EE8B149D1883AE8C6B1EE31",
            "DRIVER_SRCVERSION_MISMATCH")
    require("1471c3a284ec1cb26115fe9e9bd59890a034f83e" in info["notes"],
            "DRIVER_BUILD_ID_MISMATCH")
    require("Advanced Micro Devices X86-64" in info["elf"],
            "DRIVER_ELF_ARCH_MISMATCH")
    require("SecureBoot disabled" in info["secure_boot"],
            "SECURE_BOOT_STATE_MISMATCH")

    require(ENDPOINT.is_dir() and ROOT_PORT.is_dir(), "PCIE_PATH_MISSING")
    require((ENDPOINT / "vendor").read_text().strip() == "0x10ee" and
            (ENDPOINT / "device").read_text().strip() == "0x7011" and
            (ENDPOINT / "subsystem_vendor").read_text().strip() == "0x10ee" and
            (ENDPOINT / "subsystem_device").read_text().strip() == "0x0007" and
            (ENDPOINT / "class").read_text().strip() == "0x058000",
            "AHD_ENDPOINT_IDENTITY_MISMATCH")
    require(not (ENDPOINT / "driver").exists(), "AHD_ENDPOINT_ALREADY_BOUND")
    require((ENDPOINT / "driver_override").read_text().strip() in ("", "(null)"),
            "AHD_DRIVER_OVERRIDE_NOT_EMPTY")
    require(not P("/sys/module/xdma").exists(), "PLATFORM_XDMA_MODULE_PRESENT")
    require(not P("/sys/module/xdma_ahd_pcie").exists(),
            "AHD_XDMA_MODULE_ALREADY_PRESENT")
    require(not list(P("/dev").glob("xdma*")), "STALE_XDMA_NODES_PRESENT")
    require(not open_xdma_fds(), "XDMA_NODE_HOLDERS_PRESENT")
    require((ENDPOINT / "current_link_speed").read_text().strip().startswith("5.0") and
            (ENDPOINT / "current_link_width").read_text().strip() == "1" and
            (ROOT_PORT / "current_link_speed").read_text().strip().startswith("5.0") and
            (ROOT_PORT / "current_link_width").read_text().strip() == "1",
            "PCIE_LINK_NOT_GEN2_X1")

    kernel_before = subprocess.check_output(["dmesg", "--color=never"])
    (ROOT / "logs/kernel-immediate-before-load.txt").write_bytes(kernel_before)
    aer_before = {"endpoint": aer(ENDPOINT), "root_port": aer(ROOT_PORT)}
    lspci_before = {bdf: command("lspci", "-s", bdf, "-vvv")
                    for bdf in ("0000:01:00.0", "0000:00:01.1")}
    (ROOT / "logs/pcie-health-before-load.json").write_text(json.dumps({
        "boot_id": boot, "kernel_taint": info["taint_before"],
        "aer": aer_before, "lspci": lspci_before,
    }, indent=2) + "\n")

    with (ROOT / "logs/insmod-attempt.json").open("x") as handle:
        json.dump({"task": TASK, "attempt": 1, "utc_ns": time.time_ns(),
                   "module": str(MODULE), "parameters": []}, handle)
    result["insmod_attempts"] = 1
    load = subprocess.run(["insmod", str(MODULE)], capture_output=True,
                          text=True, timeout=20)
    loaded = P("/sys/module/xdma_ahd_pcie").exists()
    result.update(insmod_returncode=load.returncode,
                  insmod_stdout=load.stdout, insmod_stderr=load.stderr,
                  taint_before=info["taint_before"],
                  taint_after_load=int(P("/proc/sys/kernel/tainted").read_text()))
    (ROOT / "logs/driver-load.json").write_text(
        json.dumps(result, indent=2) + "\n")
    require(load.returncode == 0, "EXACT_ALIAS_AUTOMATIC_BIND_FAILED")
    subprocess.run(["udevadm", "settle", "--timeout=20"], timeout=21, check=True)
    deadline = time.monotonic() + 20.0
    while not list(P("/dev").glob("xdma*_c2h_0")) and time.monotonic() < deadline:
        time.sleep(0.1)

    validate_lock()
    require(P("/sys/module/xdma_ahd_pcie").exists(), "AHD_XDMA_MODULE_NOT_LOADED")
    require(not P("/sys/module/xdma").exists(), "PLATFORM_XDMA_MODULE_PRESENT")
    require((ENDPOINT / "driver").resolve().name == "xdma_ahd_pcie",
            "AHD_ENDPOINT_NOT_AUTOMATICALLY_BOUND")
    driver = (ENDPOINT / "driver").resolve()
    bound = sorted(item.name for item in driver.iterdir()
                   if item.name.startswith("0000:"))
    require(bound == ["0000:01:00.0"], "UNINTENDED_ENDPOINT_BOUND:" + repr(bound))

    rows = []
    for node in sorted(P("/dev").glob("xdma*")):
        st = node.stat()
        char = P("/sys/dev/char") / f"{os.major(st.st_rdev)}:{os.minor(st.st_rdev)}"
        cls = P("/sys/class/xdma") / node.name
        rows.append({
            "node": str(node), "major": os.major(st.st_rdev),
            "minor": os.minor(st.st_rdev), "mode": oct(st.st_mode),
            "char_path": str(char.resolve()),
            "char_device": str((char / "device").resolve()),
            "class_path": str(cls.resolve()),
            "class_device": str((cls / "device").resolve()),
        })
    (ROOT / "logs/node-map.json").write_text(json.dumps(rows, indent=2) + "\n")
    users = [row for row in rows
             if re.fullmatch(r"/dev/xdma\d+_user", row["node"])]
    c2hs = [row for row in rows
            if re.fullmatch(r"/dev/xdma\d+_c2h_0", row["node"])]
    require(len(users) == 1 and len(c2hs) == 1,
            "DYNAMIC_XDMA_NODE_CARDINALITY_INVALID")
    for row in users + c2hs:
        require("0000:01:00.0" in row["char_path"] or
                "0000:01:00.0" in row["char_device"],
                "NODE_CHAR_TO_BDF_MISMATCH")
        require("0000:01:00.0" in row["class_path"] or
                "0000:01:00.0" in row["class_device"],
                "NODE_CLASS_TO_BDF_MISMATCH")
    user_index = re.fullmatch(r"/dev/xdma(\d+)_user", users[0]["node"]).group(1)
    c2h_index = re.fullmatch(r"/dev/xdma(\d+)_c2h_0", c2hs[0]["node"]).group(1)
    require(user_index == c2h_index, "XDMA_NODE_INDEX_MISMATCH")
    require(not open_xdma_fds(), "XDMA_DESCRIPTOR_OPEN_AFTER_BIND")

    kernel_after = subprocess.check_output(["dmesg", "--color=never"])
    (ROOT / "logs/kernel-after-load.txt").write_bytes(kernel_after)
    require(kernel_after.startswith(kernel_before), "KERNEL_BASELINE_CONTINUITY_LOST")
    kernel_delta = kernel_after[len(kernel_before):].decode("utf-8", "replace")
    (ROOT / "logs/kernel-load-delta.txt").write_text(kernel_delta)
    fatal = re.findall(
        r"(?im)^.*(?:\bOops\b|\bBUG:|Call Trace:|hung task|use-after-free|"
        r"IOMMU fault|DMA-API|completion timeout|malformed TLP|unsupported request|"
        r"surprise link|link[- ]down|xdma[^\n]*fatal).*$", kernel_delta)
    require(not fatal, "NEW_KERNEL_OR_DRIVER_FATAL:" + repr(fatal[:4]))
    aer_after = {"endpoint": aer(ENDPOINT), "root_port": aer(ROOT_PORT)}
    require(aer_after == aer_before, "NEW_AER_COUNTER_DELTA")
    require((ENDPOINT / "current_link_speed").read_text().strip().startswith("5.0") and
            (ENDPOINT / "current_link_width").read_text().strip() == "1" and
            (ROOT_PORT / "current_link_speed").read_text().strip().startswith("5.0") and
            (ROOT_PORT / "current_link_width").read_text().strip() == "1",
            "PCIE_LINK_DOWNGRADE_AFTER_BIND")
    taint_delta = result["taint_after_load"] ^ info["taint_before"]
    require(not (taint_delta & ~((1 << 12) | (1 << 13))),
            "UNEXPECTED_TAINT_DELTA:" + str(taint_delta))

    proof = {
        "result": "PASS", "bdf": "0000:01:00.0",
        "root_port": "0000:00:01.1", "user": users[0]["node"],
        "c2h": c2hs[0]["node"], "dynamic_index": int(user_index),
        "all_nodes": rows, "bound_endpoints": bound,
        "unintended_endpoints_bound": 0,
        "taint_before": info["taint_before"],
        "taint_after_load": result["taint_after_load"],
        "kernel_fatal_matches": fatal, "aer_before": aer_before,
        "aer_after": aer_after, "boot_id": boot,
        "endpoint_link": "Gen2 x1", "root_port_link": "Gen2 x1",
    }
    (ROOT / "logs/t1-proof.json").write_text(json.dumps(proof, indent=2) + "\n")
    result.update(result="PASS", blocker="NONE", node_proof=proof)
except BaseException as exc:
    result["blocker"] = str(exc)
    if loaded or P("/sys/module/xdma_ahd_pcie").exists():
        holders = open_xdma_fds()
        result["cleanup_open_xdma_fds"] = holders
        if not holders:
            with (ROOT / "logs/normal-unload-attempt.json").open("x") as handle:
                json.dump({"reason": "T1_FAILURE_BEFORE_MMIO_OR_DMA",
                           "attempt": 1, "forced": False}, handle)
            unload = subprocess.run(["rmmod", "xdma_ahd_pcie"],
                                    capture_output=True, text=True, timeout=20)
            result["normal_unload_attempts"] = 1
            result["cleanup_unload_returncode"] = unload.returncode
            result["cleanup_unload_stdout"] = unload.stdout
            result["cleanup_unload_stderr"] = unload.stderr
            subprocess.run(["udevadm", "settle", "--timeout=20"], timeout=21)
    (ROOT / "logs/t1-failure.json").write_text(json.dumps(result, indent=2) + "\n")
finally:
    (ROOT / "logs/t1-result.json").write_text(json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2), flush=True)

sys.exit(0 if result["result"] == "PASS" else 1)
