"""Release only the exact R3R4R5 Linux lock after verified final hardware state."""
import json
import os
import pathlib
import sys
import time


P = pathlib.Path
TASK = "G2B-HW0-PRODUCT-R3R4R5"
ROOT = P("/home/vcdeagent1/vcde_artifacts/g2b_hw0_product_r3r4r5/20260907T151342Z")
LOCK_DIR = P("/tmp/ahd-g2b-hw0-product-r3r4r5-20260907T151342Z.lock")
LOCK = LOCK_DIR / "receipt.json"
ENDPOINT = P("/sys/bus/pci/devices/0000:01:00.0")
ROOT_PORT = P("/sys/bus/pci/devices/0000:00:01.1")
EXPECTED_BOOT = "614295f4-c62b-4430-ae67-06013bea7084"


def require(condition, message):
    if not condition:
        raise RuntimeError(message)


result = {"task": TASK, "result": "BLOCKED", "utc_ns": time.time_ns()}
try:
    require(str(LOCK_DIR) ==
            "/tmp/ahd-g2b-hw0-product-r3r4r5-20260907T151342Z.lock",
            "R3R4R5_LINUX_LOCK_PATH_INVALID")
    require(LOCK.is_file(), "R3R4R5_LINUX_LOCK_MISSING")
    lock = json.loads(LOCK.read_text())
    boot = P("/proc/sys/kernel/random/boot_id").read_text().strip()
    require(lock.get("task") == TASK and lock.get("state") == "HELD" and
            lock.get("boot_id") == boot == EXPECTED_BOOT,
            "R3R4R5_LINUX_LOCK_OWNER_OR_BOOT_MISMATCH")
    require(not P("/sys/module/xdma_ahd_pcie").exists() and
            not P("/sys/module/xdma").exists(), "XDMA_MODULE_PRESENT_AT_RELEASE")
    require(not list(P("/dev").glob("xdma*")), "XDMA_NODES_PRESENT_AT_RELEASE")
    require(ENDPOINT.is_dir() and not (ENDPOINT / "driver").exists(),
            "ENDPOINT_FINAL_UNBOUND_STATE_INVALID")
    require((ENDPOINT / "driver_override").read_text().strip() in ("", "(null)"),
            "DRIVER_OVERRIDE_NOT_EMPTY_AT_RELEASE")
    require((ENDPOINT / "current_link_speed").read_text().strip().startswith("5.0") and
            (ENDPOINT / "current_link_width").read_text().strip() == "1" and
            (ROOT_PORT / "current_link_speed").read_text().strip().startswith("5.0") and
            (ROOT_PORT / "current_link_width").read_text().strip() == "1",
            "PCIE_LINK_NOT_GEN2_X1_AT_RELEASE")
    require(sorted(LOCK_DIR.iterdir()) == [LOCK], "LINUX_LOCK_DIRECTORY_NOT_EXACT")
    result.update(result="PASS", blocker="NONE", state="RELEASED",
                  boot_id=boot, module="ABSENT", nodes="ABSENT",
                  endpoint="PRESENT_UNBOUND", driver_override="EMPTY",
                  endpoint_link="Gen2 x1", root_port_link="Gen2 x1",
                  release_order="LINUX_THEN_CONTROLLER")
    (ROOT / "logs/linux-lock-release.json").write_text(
        json.dumps(result, indent=2) + "\n")
    LOCK.unlink()
    os.rmdir(LOCK_DIR)
except BaseException as exc:
    result["blocker"] = str(exc)
    (ROOT / "logs/linux-lock-release-failure.json").write_text(
        json.dumps(result, indent=2) + "\n")

print(json.dumps(result, indent=2), flush=True)
sys.exit(0 if result["result"] == "PASS" else 1)
