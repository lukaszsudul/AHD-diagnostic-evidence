"""R3R4R5 bounded quiescence proof and exactly-one normal driver unload."""
import json
import os
import pathlib
import signal
import subprocess
import sys
import time

from capture_r3r4 import MMIO, _parent_quiescence, read_lock


P = pathlib.Path
TASK = "G2B-HW0-PRODUCT-R3R4R5"
ROOT = P("/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r5/20260907T151342Z")
ENDPOINT = P("/sys/bus/pci/devices/0000:01:00.0")
ROOT_PORT = P("/sys/bus/pci/devices/0000:00:01.1")


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


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


def aer(path):
    values = {}
    for item in sorted(path.glob("aer_*")):
        try:
            values[item.name] = item.read_text().strip()
        except OSError:
            values[item.name] = "UNAVAILABLE"
    return values


def identify_task_reader():
    candidates = []
    for holder in open_xdma_fds():
        if ("capture_r3r4.py" in holder["cmdline"] and
                "g2b_hw0_product_r3r4r5/20260907T151342Z" in holder["cmdline"]):
            candidates.append(holder)
    pids = sorted({item["pid"] for item in candidates})
    require(len(pids) <= 1, "MULTIPLE_TASK_READER_PROCESSES_FOUND")
    return pids[0] if pids else None


result = {"task": TASK, "result": "BLOCKED", "rmmod_attempts": 0,
          "forced_unloads": 0, "reader_stop_scope": "R3R4R5_ONLY",
          "safety_disable_writes": 0, "utc_ns": time.time_ns()}
mmio = None
try:
    with (ROOT / "logs/cleanup-start-once.json").open("x") as handle:
        json.dump({"task": TASK, "utc_ns": time.time_ns()}, handle)
    lock = read_lock()
    require(P("/sys/module/xdma_ahd_pcie").is_dir(), "TASK_MODULE_NOT_LOADED")
    require(not P("/sys/module/xdma").exists(), "PLATFORM_XDMA_MODULE_PRESENT")
    proof = json.loads((ROOT / "logs/t1-proof.json").read_text())
    capture_path = ROOT / "logs/T3T4-result.json"
    capture_result = (json.loads(capture_path.read_text())
                      if capture_path.exists() else None)
    result["capture_result"] = (capture_result.get("result")
                                if capture_result else "NOT_CREATED")
    result["capture_blocker"] = (capture_result.get("blocker")
                                 if capture_result else "NOT_CREATED")

    task_reader = identify_task_reader()
    allowed = {os.getpid()} | ({task_reader} if task_reader else set())
    mmio = MMIO("CLEANUP_PARENT")
    control = mmio.read(0x380C)
    if control & 1:
        mmio.write(0x380C, 0, "SAFETY_DISABLE",
                   "POST_ENABLE_FAILURE_CONTROL_STILL_ENABLED")
        result["safety_disable_writes"] = 1
    passed, observations = _parent_quiescence(mmio, 10.0, allowed)
    result["cleanup_quiescence_observations"] = observations
    result["cleanup_quiescence_samples_passed"] = (
        observations[-1]["consecutive"] if observations else 0)
    result["cleanup_quiescence_span_ms"] = (
        observations[-1]["span_ms"] if observations else 0.0)
    require(passed, "R3R4R5_ROLLBACK_UNSAFE_ACTIVE_DMA")
    mmio.close()
    mmio = None

    if task_reader is not None:
        proc = P("/proc") / str(task_reader)
        require(proc.exists(), "TASK_READER_IDENTITY_LOST")
        os.kill(task_reader, signal.SIGTERM)
        deadline = time.monotonic() + 3.0
        while proc.exists() and time.monotonic() < deadline:
            time.sleep(0.05)
        require(not proc.exists(), "R3R4R5_OWNED_READER_DID_NOT_STOP")
        result["task_reader_cleanup"] = "STOPPED_AFTER_PARENT_QUIESCENCE"
    else:
        result["task_reader_cleanup"] = "ALREADY_EXITED"

    holders = open_xdma_fds()
    result["open_xdma_fds_before_unload"] = holders
    require(not holders, "XDMA_DESCRIPTOR_REMAINS_OPEN")
    attempt = ROOT / "logs/cleanup-normal-unload-attempt.json"
    with attempt.open("x") as handle:
        json.dump({"attempt": 1, "module": "xdma_ahd_pcie",
                   "forced": False, "utc_ns": time.time_ns()}, handle)
    unload = subprocess.run(["rmmod", "xdma_ahd_pcie"], capture_output=True,
                            text=True, timeout=20)
    result.update(rmmod_attempts=1, rmmod_returncode=unload.returncode,
                  rmmod_stdout=unload.stdout, rmmod_stderr=unload.stderr)
    require(unload.returncode == 0, "NORMAL_DRIVER_UNLOAD_FAILED")
    subprocess.run(["udevadm", "settle", "--timeout=20"], check=True, timeout=21)

    require(not P("/sys/module/xdma_ahd_pcie").exists(),
            "TASK_MODULE_REMAINS_LOADED")
    require(not P("/sys/module/xdma").exists(), "PLATFORM_XDMA_MODULE_PRESENT")
    for row in proof["all_nodes"]:
        require(not P(row["node"]).exists(), "R3R4R5_XDMA_NODE_REMAINS")
    require(ENDPOINT.is_dir() and ROOT_PORT.is_dir(), "EXACT_ENDPOINT_MISSING")
    require(not (ENDPOINT / "driver").exists(),
            "ENDPOINT_NOT_AUTOMATICALLY_UNBOUND")
    require((ENDPOINT / "driver_override").read_text().strip() in ("", "(null)"),
            "DRIVER_OVERRIDE_NOT_EMPTY")
    require((ENDPOINT / "current_link_speed").read_text().strip().startswith("5.0") and
            (ENDPOINT / "current_link_width").read_text().strip() == "1" and
            (ROOT_PORT / "current_link_speed").read_text().strip().startswith("5.0") and
            (ROOT_PORT / "current_link_width").read_text().strip() == "1",
            "PCIE_LINK_NOT_GEN2_X1_AFTER_UNLOAD")
    require(P("/proc/sys/kernel/random/boot_id").read_text().strip() ==
            lock["boot_id"], "ADDITIONAL_REBOOT_DETECTED")

    current_aer = {"endpoint": aer(ENDPOINT), "root_port": aer(ROOT_PORT)}
    require(current_aer == proof["aer_after"], "NEW_AER_COUNTER_DELTA")
    kernel_before = (ROOT / "logs/kernel-immediate-before-load.txt").read_bytes()
    kernel_now = subprocess.check_output(["dmesg", "--color=never"])
    (ROOT / "logs/kernel-after-unload.txt").write_bytes(kernel_now)
    require(kernel_now.startswith(kernel_before), "KERNEL_BASELINE_CONTINUITY_LOST")
    delta = kernel_now[len(kernel_before):].decode("utf-8", "replace")
    fatal = __import__("re").findall(
        r"(?im)^.*(?:\bOops\b|\bBUG:|Call Trace:|hung task|use-after-free|"
        r"IOMMU fault|DMA-API|completion timeout|malformed TLP|unsupported request|"
        r"surprise link|link[- ]down|xdma[^\n]*fatal).*$", delta)
    require(not fatal, "NEW_KERNEL_OR_DRIVER_FATAL")
    result.update(
        result="PASS", blocker="NONE", boot_id=lock["boot_id"],
        module="ABSENT", nodes="REMOVED", endpoint="PRESENT_UNBOUND",
        automatic_unbind="PASS", platform_xdma="ABSENT",
        driver_override="EMPTY", endpoint_link="Gen2 x1",
        root_port_link="Gen2 x1", open_xdma_fds_after_unload=open_xdma_fds(),
        aer=current_aer, aer_delta="NONE", kernel_fatal_matches=fatal,
        taint_after_unload=int(P("/proc/sys/kernel/tainted").read_text()),
        additional_reboots=0, power_cycles=0, flash_programming=0)
except BaseException as exc:
    result["blocker"] = str(exc)
finally:
    if mmio is not None:
        mmio.close()
    (ROOT / "logs/cleanup-result.json").write_text(
        json.dumps(result, indent=2) + "\n")
    print(json.dumps(result, indent=2), flush=True)

sys.exit(0 if result["result"] == "PASS" else 1)
