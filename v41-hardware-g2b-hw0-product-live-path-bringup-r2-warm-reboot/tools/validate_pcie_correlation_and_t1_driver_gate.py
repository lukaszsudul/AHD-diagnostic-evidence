#!/usr/bin/env python3
import datetime as dt
import hashlib
import json
import re
from pathlib import Path

ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R2_20260906")
RAW = ROOT / "raw"
R1 = Path(r"C:\FPGA\V41_G2B_EVIDENCE\v41-hardware-g2b-hw0-product-live-path-bringup-r1")
JTAG = RAW / "POST_REBOOT_JTAG_RETENTION_GATE.json"
PCIE = RAW / "POST_REBOOT_PCIE_XDMA_INVENTORY.log"
XDMA = RAW / "XDMA_BINDING_FEASIBILITY_READONLY.log"
R1_BINDING = R1 / "raw" / "HISTORICAL_JTAG_PCIE_BINDING_VERIFICATION.log"
R1_MANIFEST = R1 / "G2B_HW0_PRODUCT_R1_SHA256_MANIFEST.txt"
CORRELATION_OUT = RAW / "POST_REBOOT_JTAG_PCIE_CORRELATION_GATE.json"
T1_OUT = RAW / "T1_DRIVER_GATE_DECISION.json"

for destination in (CORRELATION_OUT, T1_OUT):
    if destination.exists():
        raise SystemExit(f"destination already exists: {destination}")
for source in (JTAG, PCIE, XDMA, R1_BINDING, R1_MANIFEST):
    if not source.is_file():
        raise SystemExit(f"missing source: {source}")

def sha256(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest().upper()

def require(text: str, markers: tuple[str, ...], label: str) -> None:
    for marker in markers:
        if marker not in text:
            raise SystemExit(f"{label} missing marker: {marker}")

jtag = json.loads(JTAG.read_text(encoding="utf-8-sig"))
if not (
    jtag.get("result") == "PASS"
    and jtag.get("part") == "xc7a35t"
    and jtag.get("idcode") == "0362D093"
    and jtag.get("chain_index") == 0
    and jtag.get("done_samples") == [1, 1, 1, 1, 1]
    and jtag.get("fpga_program_operations_this_session") == 0
):
    raise SystemExit("JTAG retention gate mismatch")

r1_hash = sha256(R1_BINDING)
if r1_hash != "961D435339A94A5DA3F225EFD589D7E1D549398EF855BF77455E246DBC2AB765":
    raise SystemExit(f"R1 binding hash mismatch: {r1_hash}")
r1_manifest = R1_MANIFEST.read_text(encoding="utf-8-sig")
if f"{r1_hash}  raw/HISTORICAL_JTAG_PCIE_BINDING_VERIFICATION.log" not in r1_manifest:
    raise SystemExit("R1 binding missing from R1 manifest")
r1_text = R1_BINDING.read_text(encoding="utf-8", errors="replace")
require(
    r1_text,
    (
        "HISTORICAL_AHD_ENDPOINT_BDF=0000:01:00.0",
        "HISTORICAL_AHD_PARENT_BDF=0000:00:01.1",
        "HISTORICAL_AHD_VID_DID=10ee:7011",
        "HISTORICAL_AHD_SUBSYSTEM=10ee:0007",
    ),
    "R1 binding",
)

pcie = PCIE.read_text(encoding="utf-8", errors="replace")
require(
    pcie,
    (
        "RESULT=PASS",
        "EXACT_AHD_ENDPOINT_COUNT=1",
        "ENDPOINT_BDF=0000:01:00.0",
        "ENDPOINT_VENDOR_DEVICE=10ee:7011",
        "ENDPOINT_SYSFS_PATH=/sys/devices/pci0000:00/0000:00:01.1/0000:01:00.0",
        "UPSTREAM_BDF=0000:00:01.1",
        "BDF=0000:01:00.0 VENDOR=0x10ee DEVICE=0x7011 CLASS=0x058000 DRIVER=NONE IOMMU_GROUP=13",
        "SUBSYSTEM_VENDOR=0x10ee",
        "SUBSYSTEM_DEVICE=0x0007",
        "CURRENT_LINK_SPEED=5.0 GT/s PCIe",
        "CURRENT_LINK_WIDTH=1",
        "MAX_LINK_SPEED=5.0 GT/s PCIe",
        "MAX_LINK_WIDTH=1",
        "pci 0000:01:00.0: [10ee:7011] type 00 class 0x058000 PCIe Endpoint",
        "DRIVER_CHANGES=0",
        "PCI_RESCANS=0",
        "PCI_RESETS=0",
    ),
    "PCIe inventory",
)
endpoint_match = re.search(
    r"ENDPOINT_LSPCI_ROOT_VERBOSE_BEGIN\r?\n(.*?)\r?\nENDPOINT_LSPCI_ROOT_VERBOSE_END",
    pcie,
    re.S,
)
if not endpoint_match:
    raise SystemExit("endpoint verbose section missing")
endpoint = endpoint_match.group(1)
require(
    endpoint,
    (
        "[10ee:7011]",
        "Subsystem: Xilinx Corporation Device [10ee:0007]",
        "DevSta:\tCorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-",
        "LnkCap:\tPort #0, Speed 5GT/s, Width x1",
        "LnkSta:\tSpeed 5GT/s, Width x1",
    ),
    "endpoint verbose",
)

correlation = {
    "task": "G2B-HW0-PRODUCT-R2",
    "recorded_at_utc": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
    "result": "PASS",
    "post_reboot_jtag_to_pcie_correlation": "PASS",
    "correlation_basis": [
        "R1_ACCEPTED_PHYSICAL_BINDING_HASH_VERIFIED",
        "SAME_AUTHORITATIVE_DUT_AND_CONTROLLER_LOCK",
        "SAME_EXACT_JTAG_TARGET_PART_IDCODE_AND_CHAIN_INDEX",
        "EXACT_HISTORICAL_PCIE_BDF_PARENT_VENDOR_DEVICE_SUBSYSTEM_CLASS_REAPPEARED",
        "EXACT_VENDOR_DEVICE_ENDPOINT_COUNT_ONE",
        "OTHER_XILINX_DEVICE_HAS_DIFFERENT_ID_CLASS_AND_ROOT_PATH",
    ],
    "jtag": {
        "target": "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01",
        "part": "xc7a35t",
        "idcode": "0362D093",
        "chain_index": 0,
        "done": 1,
    },
    "pcie": {
        "endpoint_bdf": "0000:01:00.0",
        "vendor_device": "10ee:7011",
        "subsystem": "10ee:0007",
        "class": "058000",
        "upstream_bdf": "0000:00:01.1",
        "endpoint_lnkcap": "Speed 5GT/s, Width x1",
        "endpoint_lnksta": "Speed 5GT/s, Width x1",
        "sysfs_current_link_speed": "5.0 GT/s PCIe",
        "sysfs_current_link_width": 1,
        "driver": "NONE",
    },
    "pcie_gen2_x1_hardware_gate": "PASS",
    "r1_binding_sha256": r1_hash,
    "source_sha256": {
        JTAG.name: sha256(JTAG),
        PCIE.name: sha256(PCIE),
        R1_BINDING.name: r1_hash,
        R1_MANIFEST.name: sha256(R1_MANIFEST),
    },
}
CORRELATION_OUT.write_text(json.dumps(correlation, indent=2) + "\n", encoding="utf-8", newline="\n")

xdma = XDMA.read_text(encoding="utf-8", errors="replace")
require(
    xdma,
    (
        "RESULT=PASS",
        "ENDPOINT_BDF=0000:01:00.0",
        "ENDPOINT_MODALIAS=pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00",
        "ENDPOINT_DRIVER=NONE",
        "EXACT_MODALIAS_RESOLUTION_EXIT_CODE=1",
        "alias:          platform:xdma",
        "platform:xdma",
        "PLATFORM_XDMA_MATCHING_DEVICE_COUNT=0",
        "XDMA_LOADED_COUNT=0",
        "XDMA_DRIVER_SYSFS_PCI=ABSENT",
        "XDMA_DEVICE_NODE_COUNT=0",
        "MODULE_LOADS=0",
        "DRIVER_BINDS=0",
        "DRIVER_UNBINDS=0",
        "MMIO_READS=0",
        "MMIO_WRITES=0",
        "DMA_OPERATIONS=0",
    ),
    "XDMA feasibility",
)
if re.search(r"(?im)^alias\s+pci:v000010ee[dD]00007011.*\s+xdma\s*$", xdma):
    raise SystemExit("unexpected installed PCI alias for 10ee:7011 -> xdma")

t1 = {
    "task": "G2B-HW0-PRODUCT-R2",
    "recorded_at_utc": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
    "result": "BLOCKED",
    "t1_warm_reboot_endpoint_gate": "BLOCKED",
    "first_blocker": "BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE",
    "passed_subgates": {
        "warm_reboot": "PASS",
        "exact_ip_reconnect": "PASS",
        "exactly_one_boot_transition": "PASS",
        "post_reboot_exclusivity": "PASS",
        "candidate_retention": "PASS",
        "endpoint_enumeration": "PASS",
        "jtag_to_pcie_correlation": "PASS",
        "pcie_gen2_x1": "PASS",
    },
    "blocked_subgates": {
        "safe_ahd_xdma_bind": "BLOCKED",
        "xdma_node_to_bdf_mapping": "NOT_REACHED",
    },
    "installed_module": {
        "path": "/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst",
        "sha256": "523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490",
        "name": "xdma",
        "bus_aliases": ["platform:xdma"],
        "matching_platform_devices": 0,
        "matches_ahd_pci_modalias": False,
        "exact_pci_modalias_resolution_exit_code": 1,
    },
    "decision": "DO_NOT_LOAD_OR_BIND",
    "decision_reason": "The only installed xdma module is a platform-bus driver. It cannot bind the PCI endpoint, and no installed PCI module resolves the exact 10ee:7011 modalias. Loading it would be an irrelevant recovery experiment and cannot create the required user/C2H nodes.",
    "xdma_module_loaded_during_r2": False,
    "driver_bind_operations": 0,
    "driver_unbind_operations": 0,
    "mmio_reads": 0,
    "mmio_writes": 0,
    "dma_operations": 0,
    "downstream_gates": {"T2": "NOT_REACHED", "T3": "NOT_REACHED", "T4": "NOT_REACHED", "T5": "NOT_REACHED"},
    "source_sha256": {
        CORRELATION_OUT.name: sha256(CORRELATION_OUT),
        XDMA.name: sha256(XDMA),
    },
}
T1_OUT.write_text(json.dumps(t1, indent=2, ensure_ascii=False) + "\n", encoding="utf-8", newline="\n")
print("POST_REBOOT_JTAG_PCIE_CORRELATION=PASS")
print("PCIE_GEN2_X1_HARDWARE_GATE=PASS")
print("T1_WARM_REBOOT_ENDPOINT_GATE=BLOCKED")
print("FIRST_BLOCKER=BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE")
print("XDMA_MODULE_LOAD_DECISION=DO_NOT_LOAD_OR_BIND")
print("MMIO_AND_DMA_GATES=NOT_REACHED")
