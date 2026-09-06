#!/usr/bin/env python3
import csv
import datetime as dt
import hashlib
import json
from pathlib import Path

ROOT = Path(r"C:\FPGA\G2B_HW0_PRODUCT_R2_20260906")
RAW = ROOT / "raw"
CSV_PATH = RAW / "JTAG_POST_REBOOT_SESSION.csv"
TARGET_PATH = RAW / "JTAG_POST_REBOOT_TARGET_PROPERTIES.tsv"
DEVICE_PATH = RAW / "JTAG_POST_REBOOT_DEVICE_PROPERTIES.tsv"
LOG_PATH = RAW / "JTAG_POST_REBOOT_VIVADO.log"
JOU_PATH = RAW / "JTAG_POST_REBOOT_VIVADO.jou"
OUTPUT = RAW / "POST_REBOOT_JTAG_RETENTION_GATE.json"

if OUTPUT.exists():
    raise SystemExit(f"destination already exists: {OUTPUT}")
for path in (CSV_PATH, TARGET_PATH, DEVICE_PATH, LOG_PATH, JOU_PATH):
    if not path.is_file():
        raise SystemExit(f"missing source: {path}")

with CSV_PATH.open("r", encoding="utf-8-sig", newline="") as handle:
    rows = list(csv.DictReader(handle))
if len(rows) != 5:
    raise SystemExit(f"expected 5 samples, got {len(rows)}")
for expected_index, row in enumerate(rows, 1):
    expected = {
        "session_index": "2",
        "sample_index": str(expected_index),
        "target_count": "1",
        "device_count": "1",
        "target_path": "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01",
        "canonical_id": "Xilinx/80802026a98b01",
        "server_endpoint": "localhost:3121",
        "transport_class": "xilinx_tcf",
        "part": "xc7a35t",
        "idcode": "0362D093",
        "done": "1",
        "refresh_result": "PASS",
    }
    for key, value in expected.items():
        if row.get(key) != value:
            raise SystemExit(f"sample {expected_index} {key}: expected {value!r}, got {row.get(key)!r}")

def read_tsv(path: Path) -> dict[str, str]:
    with path.open("r", encoding="utf-8-sig", newline="") as handle:
        reader = csv.reader(handle, delimiter="\t")
        header = next(reader)
        if header != ["property_name", "property_value"]:
            raise SystemExit(f"bad property header in {path}: {header}")
        return {row[0]: row[1] if len(row) > 1 else "" for row in reader}

target = read_tsv(TARGET_PATH)
device = read_tsv(DEVICE_PATH)
expected_target = {
    "NAME": "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01",
    "PARAM.TYPE": "xilinx_tcf",
    "UID": "Xilinx/80802026a98b01",
}
expected_device = {
    "INDEX": "0",
    "PART": "xc7a35t",
    "IDCODE_HEX": "0362D093",
    "REGISTER.IR.BIT5_DONE": "1",
    "REGISTER.BOOT_STATUS.BIT03_0_WATCHDOG_TIMEOUT_ERROR": "0",
    "REGISTER.BOOT_STATUS.BIT04_0_ID_ERROR": "0",
    "REGISTER.BOOT_STATUS.BIT05_0_CRC_ERROR": "0",
    "REGISTER.BOOT_STATUS.BIT06_0_WRAP_ERROR": "0",
    "REGISTER.BOOT_STATUS.BIT07_0_SECURITY_ERROR": "0",
    "REGISTER.CONFIG_STATUS.BIT00_CRC_ERROR": "0",
    "REGISTER.CONFIG_STATUS.BIT13_DONE_INTERNAL_SIGNAL_STATUS": "1",
    "REGISTER.CONFIG_STATUS.BIT14_DONE_PIN": "1",
    "REGISTER.CONFIG_STATUS.BIT15_IDCODE_ERROR": "0",
    "REGISTER.CONFIG_STATUS.BIT16_SECURITY_ERROR": "0",
    "REGISTER.CONFIG_STATUS.BIT27_HMAC_ERROR": "0",
    "REGISTER.CONFIG_STATUS.BIT29_BAD_PACKET_ERROR": "0",
}
for mapping, expected in ((target, expected_target), (device, expected_device)):
    for key, value in expected.items():
        if mapping.get(key) != value:
            raise SystemExit(f"property {key}: expected {value!r}, got {mapping.get(key)!r}")

log_text = LOG_PATH.read_text(encoding="utf-8", errors="replace")
jou_text = JOU_PATH.read_text(encoding="utf-8", errors="replace")
for marker in ("SESSION_GATE=PASS", "FPGA_PROGRAM_OPERATIONS_THIS_SESSION=0"):
    if marker not in log_text:
        raise SystemExit(f"missing log marker: {marker}")
for forbidden in ("program_hw_devices", "program_hw_cfgmem", "write_cfgmem", "create_hw_cfgmem"):
    if forbidden in log_text.lower() or forbidden in jou_text.lower():
        raise SystemExit(f"programming command found: {forbidden}")

def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()

receipt = {
    "task": "G2B-HW0-PRODUCT-R2",
    "recorded_at_utc": dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z"),
    "result": "PASS",
    "gate": "POST_REBOOT_CANDIDATE_RETENTION",
    "jtag_target_count": 1,
    "jtag_device_count": 1,
    "target_path": "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01",
    "canonical_id": "Xilinx/80802026a98b01",
    "transport": "xilinx_tcf",
    "part": "xc7a35t",
    "idcode": "0362D093",
    "chain_index": 0,
    "done_samples": [1, 1, 1, 1, 1],
    "done_stable": True,
    "configuration_crc_error": 0,
    "configuration_idcode_error": 0,
    "configuration_security_error": 0,
    "configuration_hmac_error": 0,
    "configuration_bad_packet_error": 0,
    "fpga_program_operations_this_session": 0,
    "sram_program_operations_in_r2": 0,
    "flash_program_operations": 0,
    "candidate_bitstream_sha256": "AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7",
    "candidate_retained_across_warm_reboot": "PASS",
    "retention_basis": "OPERATION_CONTINUITY_PLUS_STABLE_CONFIGURED_STATE",
    "qualification": "JTAG_DOES_NOT_READ_BACK_BITSTREAM_HASH",
    "source_sha256": {
        path.name: sha256(path)
        for path in (CSV_PATH, TARGET_PATH, DEVICE_PATH, LOG_PATH, JOU_PATH)
    },
}
OUTPUT.write_text(json.dumps(receipt, indent=2) + "\n", encoding="utf-8", newline="\n")
print("POST_REBOOT_JTAG_RETENTION_GATE=PASS")
print("POST_REBOOT_DONE=1")
print("CANDIDATE_RETAINED_ACROSS_WARM_REBOOT=PASS")
print("FPGA_PROGRAM_OPERATIONS_THIS_SESSION=0")
