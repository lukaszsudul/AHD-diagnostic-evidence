"""Read-only R3R4R5 candidate-continuity and pre-load hardware inventory."""
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
EXPECTED_DRIVER_SHA256 = "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77"


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


def relevant_processes():
    pattern = re.compile(
        r"(?i)(vivado|hw_server|cs_server|impact|openocd|jtag|program.*fpga|"
        r"hdmi.*(?:fpga|hardware)|ahd.*(?:fpga|hardware)|xdma|reboot|shutdown|"
        r"poweroff|shelly|\bups(?:d|mon|sd|drvctl|cmd)?\b)")
    found = []
    for proc in P("/proc").iterdir():
        if not proc.name.isdigit() or int(proc.name) in (os.getpid(), os.getppid()):
            continue
        try:
            cmdline = (proc / "cmdline").read_bytes().replace(b"\0", b" ").decode(
                "utf-8", "replace").strip()
            comm = (proc / "comm").read_text().strip()
        except (OSError, PermissionError):
            continue
        if pattern.search(comm + " " + cmdline):
            found.append({"pid": int(proc.name), "comm": comm,
                          "cmdline": cmdline})
    return found


result = {"task": TASK, "result": "BLOCKED", "utc_ns": time.time_ns(),
          "hardware_access": "READ_ONLY_INVENTORY"}
try:
    require(ROOT.is_dir(), "R3R4R5_REMOTE_RUN_ROOT_MISSING")
    require(LOCK.is_file(), "R3R4R5_LINUX_LOCK_REQUIRED")
    lock = json.loads(LOCK.read_text())
    boot = P("/proc/sys/kernel/random/boot_id").read_text().strip()
    require(lock.get("task") == TASK and lock.get("state") == "HELD" and
            lock.get("boot_id") == boot == EXPECTED_BOOT,
            "R3R4R5_LINUX_LOCK_OR_BOOT_MISMATCH")
    require(command("hostname") == "VCDE-DUT-1", "DUT_HOSTNAME_MISMATCH")
    require(P("/etc/machine-id").read_text().strip() ==
            "0e90f50d9465492b80258da5658446f8", "DUT_MACHINE_ID_MISMATCH")
    require(command("uname", "-r") == "7.0.0-29-generic", "DUT_KERNEL_MISMATCH")
    require(command("uname", "-m") == "x86_64", "DUT_ARCH_MISMATCH")

    require(ENDPOINT.is_dir() and ROOT_PORT.is_dir(), "PCIE_PATH_MISSING")
    identity = {
        "vendor": (ENDPOINT / "vendor").read_text().strip(),
        "device": (ENDPOINT / "device").read_text().strip(),
        "subsystem_vendor": (ENDPOINT / "subsystem_vendor").read_text().strip(),
        "subsystem_device": (ENDPOINT / "subsystem_device").read_text().strip(),
        "class": (ENDPOINT / "class").read_text().strip(),
        "modalias": (ENDPOINT / "modalias").read_text().strip(),
    }
    require(identity == {
        "vendor": "0x10ee", "device": "0x7011",
        "subsystem_vendor": "0x10ee", "subsystem_device": "0x0007",
        "class": "0x058000",
        "modalias": "pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00",
    }, "AHD_ENDPOINT_IDENTITY_MISMATCH")
    ancestry = str(ENDPOINT.resolve())
    require("0000:00:01.1" in ancestry, "AHD_ROOT_PORT_CORRELATION_MISMATCH")
    require(not (ENDPOINT / "driver").exists(), "AHD_ENDPOINT_ALREADY_BOUND")
    require((ENDPOINT / "driver_override").read_text().strip() in ("", "(null)"),
            "AHD_DRIVER_OVERRIDE_NOT_EMPTY")
    require(not P("/sys/module/xdma").exists(), "PLATFORM_XDMA_MODULE_PRESENT")
    require(not P("/sys/module/xdma_ahd_pcie").exists(),
            "AHD_XDMA_MODULE_ALREADY_PRESENT")
    nodes = sorted(str(item) for item in P("/dev").glob("xdma*"))
    holders = open_xdma_fds()
    require(not nodes, "STALE_XDMA_NODES_PRESENT")
    require(not holders, "XDMA_NODE_HOLDERS_PRESENT")

    endpoint_link = {
        "speed": (ENDPOINT / "current_link_speed").read_text().strip(),
        "width": (ENDPOINT / "current_link_width").read_text().strip(),
    }
    root_link = {
        "speed": (ROOT_PORT / "current_link_speed").read_text().strip(),
        "width": (ROOT_PORT / "current_link_width").read_text().strip(),
    }
    require(endpoint_link["speed"].startswith("5.0") and
            endpoint_link["width"] == "1" and
            root_link["speed"].startswith("5.0") and root_link["width"] == "1",
            "PCIE_LINK_NOT_GEN2_X1")

    require(MODULE.is_file() and not MODULE.is_symlink(), "SEALED_DRIVER_MISSING")
    driver_sha = hashlib.sha256(MODULE.read_bytes()).hexdigest().upper()
    require(driver_sha == EXPECTED_DRIVER_SHA256, "SEALED_DRIVER_HASH_MISMATCH")
    module_info = {field: command("modinfo", "-F", field, str(MODULE))
                   for field in ("name", "vermagic", "alias", "depends",
                                 "srcversion", "signer", "sig_id")}
    require(module_info["name"] == "xdma_ahd_pcie", "DRIVER_INTERNAL_NAME_MISMATCH")
    require(module_info["alias"] ==
            "pci:v000010EEd00007011sv000010EEsd00000007bc*sc*i*",
            "DRIVER_ALIAS_MISMATCH")
    require(module_info["vermagic"] ==
            "7.0.0-29-generic SMP preempt mod_unload modversions ",
            "DRIVER_VERMAGIC_MISMATCH")
    require(module_info["depends"] == "" and module_info["signer"] == "" and
            module_info["sig_id"] == "", "DRIVER_METADATA_UNEXPECTED")

    current_aer = {"endpoint": aer(ENDPOINT), "root_port": aer(ROOT_PORT)}
    kernel = subprocess.check_output(["dmesg", "--color=never"])
    lspci = {bdf: command("lspci", "-s", bdf, "-vvv")
             for bdf in ("0000:01:00.0", "0000:00:01.1")}
    processes = relevant_processes()
    require(not processes, "PARALLEL_HARDWARE_ACTIVITY_NOT_EXCLUDED")
    result.update(
        result="PASS", boot_id=boot, hostname="VCDE-DUT-1",
        machine_id="0e90f50d9465492b80258da5658446f8",
        kernel="7.0.0-29-generic", architecture="x86_64",
        endpoint_bdf="0000:01:00.0", root_port_bdf="0000:00:01.1",
        endpoint_identity=identity, endpoint_sysfs_path=ancestry,
        endpoint_driver=None, driver_override="EMPTY",
        endpoint_link=endpoint_link, root_port_link=root_link,
        platform_xdma_loaded=False, xdma_ahd_pcie_loaded=False,
        xdma_nodes=nodes, xdma_holders=holders,
        relevant_parallel_processes=processes,
        driver_path=str(MODULE), driver_bytes=MODULE.stat().st_size,
        driver_sha256=driver_sha, driver_metadata=module_info,
        kernel_taint=int(P("/proc/sys/kernel/tainted").read_text()),
        aer=current_aer, lspci=lspci,
        recovery_path="NOT_REQUIRED",
        sram_programming_executed=0, warm_reboot_executed=0,
    )
    (ROOT / "logs/kernel-preload-inventory.txt").write_bytes(kernel)
except BaseException as exc:
    result["blocker"] = str(exc)

(ROOT / "logs/preload-inventory.json").write_text(
    json.dumps(result, indent=2) + "\n")
print(json.dumps(result, indent=2), flush=True)
sys.exit(0 if result["result"] == "PASS" else 1)
