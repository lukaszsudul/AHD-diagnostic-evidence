#!/usr/bin/env python3
"""Build the sanitized append-only R2R2R1 failure evidence tree."""

from __future__ import annotations

import csv
import difflib
import hashlib
import json
from pathlib import Path
import shutil
from datetime import datetime, timezone


RUN = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R2R1_20260910T183212Z")
OLD = Path(r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R2_20260910T174941Z")
DIRNAME = (
    "v41-hardware-g2b-nvp-video-diag1-r2r2r1-"
    "prebaseline-activation-four-channel-scan"
)
OUT = RUN / "evidence-staging" / DIRNAME
SOURCES = OUT / "sources"
SUPPORT = OUT / "supporting"
TASK = "G2B-NVP-VIDEO-DIAG1-R2R2R1"
SOURCE_COMMIT = "fcab95726761a0666a67e31c283dbdfb9e775074"
SOURCE_TREE = "bbf1a5fee70a2eb68bb96305ed10934a1559ca6a"
BITSTREAM_SHA = (
    "9D1491CB6709ED623C985B2C9AEA53E2C360A68A77DB4680BEE9B8935A82D12F"
)
BITSTREAM_PATH = (
    r"C:\FPGA\G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z\artifacts"
    r"\G2B_NVP_VIDEO_DIAG1_R2R1_FOUR_CHANNEL_SCAN.bit"
)
FIRST_BLOCKER = "NVP_DIAG1_R2R2R1_DIAG_CLEAR_MMIO_PATH_BECAME_UNRESPONSIVE"
GENERATED = datetime.now(timezone.utc).isoformat()


def read_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_text(name: str, text: str) -> Path:
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")
    return path


def write_json(name: str, value) -> Path:
    return write_text(name, json.dumps(value, indent=2, sort_keys=True))


def write_csv(name: str, fields: list[str], rows: list[dict]) -> Path:
    path = OUT / name
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", encoding="utf-8", newline="") as handle:
        writer = csv.DictWriter(handle, fieldnames=fields, lineterminator="\n")
        writer.writeheader()
        for row in rows:
            writer.writerow({field: row.get(field, "") for field in fields})
    return path


def sha(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for block in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest().upper()


if OUT.exists():
    raise SystemExit(f"refusing to overwrite evidence staging: {OUT}")
OUT.mkdir(parents=True)
SOURCES.mkdir()
SUPPORT.mkdir()

program = read_json(RUN / "reports" / "programming-receipt.json")
driver = read_json(RUN / "logs" / "connection-driver-load-and-endpoint.json")
reboot_delivery = read_json(
    RUN / "logs" / "connection-warm-reboot-delivery-final.json"
)
reconnect_1 = read_json(
    RUN / "logs" / "connection-post-reboot-final-reconnect-01.json"
)
reconnect_2 = read_json(
    RUN / "logs" / "connection-post-reboot-final-reconnect-02.json"
)
clear_evidence = read_json(
    RUN / "logs" / "connection-runtime-clear-failure-read.json"
)
cleanup = read_json(
    RUN / "logs" / "connection-exact-cleanup-and-linux-lock-release.json"
)
holders = read_json(
    RUN / "logs" / "connection-post-clear-exact-node-holders.json"
)
lock_release = read_json(RUN / "logs" / "controller-lock-release.json")
native_build = read_json(
    RUN / "logs" / "connection-native-helper-build-syscall.json"
)

stdout = clear_evidence["stdout"]
result_text = stdout.split(
    "FILE_BEGIN=scan-controller-result.json\n", 1
)[1].split("\nFILE_END=scan-controller-result.json", 1)[0]
ledger_text = stdout.split(
    "FILE_BEGIN=diagnostic-mmio-ledger.csv\n", 1
)[1].split("\nFILE_END=diagnostic-mmio-ledger.csv", 1)[0]
controller_result = json.loads(result_text)

original_controller = OLD / "scripts" / "controller_nvp_video_diag1_r2r2.py"
final_controller = RUN / "scripts" / "controller_nvp_video_diag1_r2r2r1.py"
original_controller_sha = sha(original_controller)
final_controller_sha = sha(final_controller)

source_names = [
    "controller_nvp_video_diag1_r2r2r1.py",
    "controller_nvp_capture_r2r2r1.py",
    "r2r2r1_authorization_sequence.py",
    "test_r2r2r1_authorization_sequence.py",
    "validate_nvp_capture.py",
    "frame_reconstruct_nvp_capture.py",
    "analyze_nvp_video_diag1.py",
    "aggregate_nvp_session_metadata.py",
    "xdma_c2h_rolling_4k_diag1.c",
    "abi_v1.py",
    "V41_C2H_TRANSPORT_ABI_V1.json",
    "program-nvp-video-diag1-r2r2r1-once.tcl",
    "build_r2r2r1_failure_evidence.py",
]
for name in source_names:
    shutil.copy2(RUN / "scripts" / name, SOURCES / name)

old_lines = original_controller.read_text(encoding="utf-8").splitlines(True)
new_lines = final_controller.read_text(encoding="utf-8").splitlines(True)
diff = "".join(
    difflib.unified_diff(
        old_lines,
        new_lines,
        fromfile="R2R2/controller_nvp_video_diag1_r2r2.py",
        tofile="R2R2R1/controller_nvp_video_diag1_r2r2r1.py",
    )
)
write_text("supporting/controller_r2r2_to_r2r2r1.diff", diff or "NO_DIFF")
write_json("supporting/programming-receipt-sanitized.json", program)
write_json("supporting/scan-controller-result.json", controller_result)
write_text("supporting/diagnostic-mmio-ledger.csv", ledger_text)

write_text(
    "V41_G2B_NVP_VIDEO_DIAG1_R2R2R1_MAIN_REPORT.md",
    f"""# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R2R1 main report

Engineering gate: **FAIL**

The inherited offline sign-off, exact candidate hash, one SRAM programming,
product-equivalent autoinit, one commanded warm reboot, endpoint/driver gate,
PRODUCT runtime identity, diagnostic identity, capabilities, and pre-baseline
transport quiescence passed.

The first executed failing gate was `{FIRST_BLOCKER}`. The sole initial
`DIAG_CONTROL.CLEAR` write completed, but the next diagnostic STATUS and ERROR
reads returned `0xFFFFFFFF`. A bounded read-only MMIO probe then produced no
first read before its 30-second timeout. No PREPARE, START, BGDCOL change, VDO1
route change, AIO submission, capture, or image analysis occurred.

The task subsequently observed a new kernel-initialization interval and found
the previously loaded module absent without any task-issued `rmmod`. Together
with the timed-out MMIO operation, this is evidence of an unexpected DUT
restart after CLEAR. This conclusion uses the bounded task log and exact module
lifecycle only; no boot-ID comparison was performed.

Cleanup passed for the state that remained: no user-node or C2H holder, the
driver and XDMA nodes were absent, pending AIO remained zero, and both exact
task locks were released. PRODUCT baseline restoration was not executed because
the Double-PREPARE gate was never established and no diagnostic functional NVP
write was authorized or performed.

Overall result: **FAIL**

Evidence publication is evaluated separately by the immutable commit and
commit-pinned remote read-back containing this report.

Generated: {GENERATED}
""",
)

write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_OWNER_AUTHORIZATION.md",
    """# Owner authorization receipt

The Owner authorized pre-baseline activation of the exact diagnostic
candidate, its unchanged product-equivalent autoinit, exactly one commanded
warm reboot, exact driver load, read-only identity, one CLEAR, PREPARE_A and
PREPARE_B. START, scan writes, route changes, BGDCOL changes, and captures were
authorized only after Double-PREPARE PASS. No source, DCP, or bitstream change
was authorized. These boundaries were enforced.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_NORMATIVE_AUTHORIZATION_ORDER.md",
    """# Normative authorization order

Observed order:

1. inherited offline sign-off PASS;
2. exact bitstream identity PASS;
3. controller lock acquired;
4. exact candidate programmed once to SRAM;
5. product-equivalent autoinit PASS;
6. one commanded warm reboot and bounded reconnect PASS;
7. Linux lock acquired and exact driver loaded;
8. PRODUCT and diagnostic read-only identity PASS;
9. pre-baseline transport quiescence PASS;
10. one DIAG CLEAR issued;
11. diagnostic MMIO became unresponsive — HARD STOP.

PREPARE_A/B, scan start, NVP functional writes, and captures were not reached.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_SCOPE.md",
    """# Scope

This continuation reused the fully signed-off diagnostic candidate and changed
no FPGA source, RTL, XDC, IP, DCP, bitstream, ABI, PRODUCT MMIO, SSOT, or NVP
configuration. Task-local host control ordering and read-only identity decoding
were corrected. Flash, power-cycle, second programming, second scan, and all
continuous/two-channel/V4L2 work were not performed.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_R2R1_INHERITANCE.md",
    """# R2R1 inheritance

- evidence commit: `f615d8a01dc56157e22b3cb01245a56969a32a52`
- remote read-back: PASS (inherited)
- offline sign-off: PASS (inherited)
- source commit: `fcab95726761a0666a67e31c283dbdfb9e775074`
- source tree: `bbf1a5fee70a2eb68bb96305ed10934a1559ca6a`
- candidate classification: `G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_CDC_CANDIDATE`
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_R2R2_INHERITANCE.md",
    """# R2R2 inheritance

- evidence commit: `5f9d3a1d8e8ca0a8d4b6c6a28daa540e03a11e9c`
- remote read-back: PASS (inherited)
- hardware access: NO
- blocker: `OWNER_AUTHORIZATION_SEQUENCE_CONTRADICTION`
- R2R2R1 disposition: `CORRECTED_BY_PRE_BASELINE_ACTIVATION_AUTHORIZATION`
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R1_PUBLICATION_RECEIPT.md",
    """# R2R1 publication receipt

Repository: `lukaszsudul/AHD-diagnostic-evidence`

Commit: `f615d8a01dc56157e22b3cb01245a56969a32a52`

Remote read-back: PASS (Owner-accepted inheritance; not repeated).
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2_PUBLICATION_RECEIPT.md",
    """# R2R2 publication receipt

Repository: `lukaszsudul/AHD-diagnostic-evidence`

Commit: `5f9d3a1d8e8ca0a8d4b6c6a28daa540e03a11e9c`

Remote read-back: PASS (Owner-accepted inheritance; not repeated).
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_EXACT_CANDIDATE_AUTHORITY.md",
    f"""# Exact candidate authority

- bitstream: `{BITSTREAM_PATH}`
- accepted size: `2192144` bytes
- sole task hash observation: `{BITSTREAM_SHA}`
- identity result: PASS
- source commit: `{SOURCE_COMMIT}`
- source tree: `{SOURCE_TREE}`
- BUILD_FLAGS: `0x00000402`
- offline sign-off: PASS_INHERITED_R2R1
- programming storage: FPGA_SRAM_VOLATILE_ONLY

The evidence builder did not re-read or re-hash the bitstream.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_HOST_CONTROLLER_REUSE.md",
    f"""# Host controller reuse

Source root: `C:\\FPGA\\G2B_NVP_VIDEO_DIAG1_R2R2_20260910T174941Z`

Original copied controller SHA-256: `{original_controller_sha}`

Final R2R2R1 controller SHA-256: `{final_controller_sha}`

The accepted rolling helper, fixed-boundary validator, reconstruction, pixel
analysis, snapshot schema, scan order, BGDCOL matrix, and result classifications
were retained.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_HOST_CONTROLLER_DIFF.md",
    f"""# Task-local host controller diff

The task-local controller was reordered to enforce candidate activation before
Double-PREPARE and to hard-gate START behind baseline PASS. An initially
incorrect task-local read-only autoinit decode was corrected against the frozen
RTL register map: status `0x008C`, NACK `0x0090`, timeout `0x0094`.

No FPGA MMIO definition, PREPARE behavior, snapshot schema, channel order,
BGDCOL assignment, capture format, or classification changed. The exact unified
diff is `supporting/controller_r2r2_to_r2r2r1.diff`.

Final controller SHA-256: `{final_controller_sha}`
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_HOST_CONTROLLER_GATE.md",
    """# Host-controller gate

Result: PASS

- syntax compile: PASS
- import check: PASS
- argument parser: PASS
- programming-before-PREPARE mock: PASS
- START-before-baseline denial mock: PASS
- exact target IP: PASS (`10.132.1.111` only)
- credential remnant: 0
- final runtime identity offset correction check: PASS

No FPGA simulation or offline sign-off was repeated.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_PROGRAMMING_RECEIPT.md",
    f"""# Programming receipt

- exact bitstream identity: PASS
- SHA-256: `{program['bitstream_sha256']}`
- size: `{program['bitstream_size']}` bytes
- target: `xc7a35t`, chain index 0
- JTAG target count: 1
- programming attempts reaching `program_hw_devices`: 1
- `program_hw_devices` calls: 1
- pre-DONE: 1
- post-DONE: 1
- Flash/cfgmem calls: 0
- result: PASS
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_AUTOINIT_RECEIPT.md",
    """# Product-equivalent autoinit receipt

Read-only status after the commanded reboot:

- raw status `0x000000F9`
- DONE = 1
- BUSY = 0
- ERROR = 0
- NVP reset released = 1
- NACK count = 0
- timeout count = 0

Result: PASS. No autoinit transaction was added, removed, or modified.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_REBOOT_RECEIPT.md",
    f"""# Warm reboot receipt

Two preliminary local wrapper invocations were rejected before any SSH process
started; their receipts explicitly record `process_started=false`, so they did
not deliver a reboot command. After the credential-helper false-positive was
corrected, exactly one reboot command was started and acknowledged:

- schedule acknowledged: YES
- delivery start: `{reboot_delivery['start_utc']}`
- first reconnect: timeout (no second reboot issued)
- second/final reconnect: PASS at `{reconnect_2['end_utc']}`
- boot-ID read or comparison: NO
- power-cycle: NO

Commanded warm reboots: 1.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_RUNTIME_IDENTITY.md",
    """# Runtime identity

PRODUCT transport identity: PASS

- block ID `0xA40A0C07`
- protocol `0x0000400B`
- capabilities `0x00031002`
- source `fcab95726761a0666a67e31c283dbdfb9e775074`
- BUILD_FLAGS `0x00000402`
- transport signature `0x58444D41`
- G2B C2H magic `0x43324831`
- ABI version `0x00010000`

Diagnostic identity before CLEAR: PASS

- DIAG_MAGIC `0x4E565034`
- DIAG_VERSION `0x00010001`
- capabilities `0x000003FF`
- current-session snapshot present
- host-owned history present
- on-chip 16-session history absent
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_DRIVER_LOAD.md",
    """# Driver and endpoint

- BDF `0000:01:00.0`
- vendor/device `10ee:7011`
- subsystem `10ee:0007`
- link `5.0 GT/s`, width 1 (Gen2 x1)
- exact qualified driver path used with one `insmod`
- `/dev/xdma0_user` created
- `/dev/xdma0_c2h_0` created
- result: PASS

No driver hash, module parameter, manual bind, or broad PCIe audit was used.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_BASELINE_CONTRACT_DECISION.md",
    """# Double-PREPARE baseline contract decision

Method: TWO_CONSECUTIVE_PREPARE_PASSES

Decision: NOT_REACHED

The sole initial CLEAR was issued, but diagnostic STATUS and ERROR immediately
returned `0xFFFFFFFF`; therefore PREPARE_A and PREPARE_B were never issued and
no restoration authority was established. START remained hard-gated.
""",
)

baseline_placeholder = {
    "result": "NOT_REACHED",
    "reason": FIRST_BLOCKER,
    "functional_nvp_writes_before_gate": 0,
}
for letter in ("A", "B"):
    csv_name = f"G2B_NVP_VIDEO_DIAG1_R2R2R1_BASELINE_{letter}.csv"
    json_name = f"G2B_NVP_VIDEO_DIAG1_R2R2R1_BASELINE_{letter}.json"
    write_csv(csv_name, ["Result", "Reason"], [{"Result": "NOT_REACHED", "Reason": FIRST_BLOCKER}])
    jp = write_json(json_name, baseline_placeholder)
    write_text(
        f"G2B_NVP_VIDEO_DIAG1_R2R2R1_BASELINE_{letter}.sha256",
        f"{sha(jp)}  {json_name}",
    )

write_csv(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_BASELINE_COMPARISON.csv",
    ["Gate", "Result", "Reason"],
    [{"Gate": "DOUBLE_PREPARE_BASELINE", "Result": "NOT_REACHED", "Reason": FIRST_BLOCKER}],
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_BASELINE_COMPARISON.md",
    """# Baseline comparison

PREPARE_A: NOT_REACHED

PREPARE_B: NOT_REACHED

A/B visible equality: NOT_REACHED

Transaction-delta equality: NOT_REACHED

Double-PREPARE baseline gate: NOT_REACHED
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_ORIGINAL_BANK_DISPOSITION.md",
    """# Original bank disposition

- ORIGINAL_BANK_HOST_VISIBLE = NO
- ORIGINAL_BANK_CLASSIFICATION = FIRMWARE_PRIVATE_OPERATIONAL_CONTEXT
- ACTIVE_RESTORE_AUTHORITY = NONE
- ORIGINAL_BANK_FINAL_VERIFY = NOT_REACHED

No bank value was invented and no arbitrary I2C access was performed.
""",
)

not_reached_csvs = {
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_SNAPSHOT_COHERENCE.csv": "SnapshotCoherence",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_HOST_SESSION_HISTORY.csv": "HostSessionHistory",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_SCAN_RESULTS.csv": "ScanResults",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_STATUS_SAMPLES.csv": "StatusSamples",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_ROUTE_READBACKS.csv": "RouteReadbacks",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_BGDCOL_ROUND_READBACKS.csv": "BGDCOLRoundReadbacks",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_CAPTURE_INDEX.csv": "CaptureIndex",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_CAPTURE_RESULTS.csv": "CaptureResults",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_FRAME_HASHES.csv": "FrameHashes",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_PIXEL_STATISTICS.csv": "PixelStatistics",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_BGDCOL_MATCH_RESULTS.csv": "BGDCOLMatch",
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_CHANNEL_REPEATABILITY.csv": "ChannelRepeatability",
}
for filename, gate in not_reached_csvs.items():
    write_csv(
        filename,
        ["Gate", "Result", "Reason"],
        [{"Gate": gate, "Result": "NOT_REACHED", "Reason": FIRST_BLOCKER}],
    )
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_HOST_SESSION_HISTORY.jsonl",
    json.dumps({"result": "NOT_REACHED", "reason": FIRST_BLOCKER}, sort_keys=True),
)
write_csv(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_I2C_COUNTER_TIMELINE.csv",
    ["Phase", "TransactionCount", "NACKCount", "TimeoutCount", "BusRecoveryCount", "Result"],
    [
        {"Phase": "PRODUCT_EQUIVALENT_AUTOINIT", "TransactionCount": "N/A", "NACKCount": 0,
         "TimeoutCount": 0, "BusRecoveryCount": "N/A", "Result": "PASS"},
        {"Phase": "AFTER_DIAG_CLEAR", "TransactionCount": "N/A", "NACKCount": "N/A",
         "TimeoutCount": "N/A", "BusRecoveryCount": "N/A", "Result": "MMIO_UNRESPONSIVE"},
    ],
)
write_csv(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_AIO_SUMMARY.csv",
    ["CapturesStarted", "IOCBsSubmitted", "PendingAIOFinal", "Result"],
    [{"CapturesStarted": 0, "IOCBsSubmitted": 0, "PendingAIOFinal": 0, "Result": "NOT_REACHED"}],
)

write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_DIGITAL_PATH_DECISION.md",
    """# Digital-path decision

DOWNSTREAM_DIGITAL_PIXEL_PATH = NOT_REACHED

The task did not reach BGDCOL programming, routing, or capture. No conclusion
about changing pixel values or a stuck-black path is permitted.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_LOGICAL_CAMERA_CHANNEL_DECISION.md",
    """# Logical camera channel decision

LOGICAL_ACTIVE_CAMERA_CHANNEL = UNRESOLVED

No channel status sample or route selection was executed.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_CAMERA_CONTENT_DECISION.md",
    """# Camera-content decision

END_TO_END_CAMERA_IMAGE = UNRESOLVED

No finite capture, frame reconstruction, or pixel analysis was executed.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_PHYSICAL_INPUT_ACTION.md",
    """# Physical-input action

No camera, cable, format, or analog-front-end conclusion can be drawn because
the scan did not begin. Before any further physical-input work, correct and
govern the diagnostic CLEAR/MMIO failure and demonstrate that the diagnostic
interface remains responsive without restarting the DUT.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_PRODUCT_RESTORE_RECEIPT.md",
    """# PRODUCT NVP restore receipt

- PREPARE_B authority: NONE (not reached)
- diagnostic functional NVP writes before baseline PASS: 0
- scan NVP writes: 0
- RESTORE_PRODUCT_BASELINE command: NOT_REACHED_BY_GOVERNED_PREBASELINE_STOP
- visible equality to PREPARE_B: NOT_REACHED
- firmware internal bank verify: NOT_REACHED

The fixed product-equivalent autoinit was the only NVP functional sequence.
No persistent NVP state change was made.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_CLEANUP_RECEIPT.md",
    f"""# Cleanup receipt

- stream was directly observed disabled before CLEAR (`CONTROL=0x00000000`)
- pre-CLEAR transport status `0x000000C4`; C2H holder none
- captures/AIO started: 0; final pending AIO: 0
- exact `/dev/xdma0_user` holder after failure: none
- exact `/dev/xdma0_c2h_0` holder after failure: none
- `xdma_ahd_pcie`: absent when cleanup ran
- XDMA nodes: absent
- normal `rmmod`: not issued because module was already absent
- exact Linux lock: released after ownership check
- exact controller lock: released last at `{lock_release['released_utc']}`
- power-cycle: NO
- final task-issued reboot: NO

The module disappearance and bounded kernel reinitialization interval occurred
after the MMIO hang without a task-issued unload or second reboot; this is part
of the engineering failure evidence.
""",
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_KERNEL_REVIEW.md",
    """# Bounded PCIe/AER/kernel review

PCIE_AER_KERNEL_HEALTH = FAIL

The bounded log did not expose an explicit AER fatal row, IOMMU fault, DMA-API
error, Oops, BUG, panic, or use-after-free. It did expose a fresh kernel
initialization interval immediately after the bounded MMIO read hung, and the
previously loaded module was then absent without task-issued `rmmod`. This
unexpected restart is independently disqualifying. No boot-ID comparison was
performed.
""",
)

state = {
    "task": TASK,
    "generated_utc": GENERATED,
    "project_state_rev": "8 - OWNER_ATTESTED_NOT_REVERIFIED",
    "engineering_gate": "FAIL",
    "evidence_publication": "PENDING_COMMIT_AND_PINNED_READBACK",
    "overall_result": "FAIL",
    "first_blocker": FIRST_BLOCKER,
    "offline_signoff": "PASS_INHERITED_R2R1",
    "source_commit": SOURCE_COMMIT,
    "source_tree": SOURCE_TREE,
    "bitstream_sha256": BITSTREAM_SHA,
    "exact_bitstream_identity": "PASS",
    "programming": "PASS_ONE_SRAM_PROGRAM",
    "warm_reboot": 1,
    "product_equivalent_autoinit": "PASS",
    "driver_load": "PASS",
    "pcie_bdf": "0000:01:00.0",
    "pcie_gen2_x1": "PASS",
    "runtime_product_identity": "PASS",
    "runtime_diagnostic_identity": "PASS",
    "diag_clear": "FAIL_MMIO_STATUS_AND_ERROR_FFFFFFFF",
    "prepare_a": "NOT_REACHED",
    "prepare_b": "NOT_REACHED",
    "double_prepare_baseline_gate": "NOT_REACHED",
    "diagnostic_functional_nvp_writes_before_baseline": 0,
    "scan_start": "NOT_REACHED",
    "sessions_completed": 0,
    "captures_started": 0,
    "pending_aio_final": 0,
    "product_baseline_restore": "NOT_REACHED_NO_SCAN_NVP_WRITES",
    "physical_quiescence": "PASS_PRECLEAR_NO_TRANSPORT_ACTIVITY_AFTER",
    "driver_final": "ABSENT_AFTER_UNEXPECTED_DUT_RESTART",
    "xdma_nodes_final": "ABSENT",
    "linux_lock_released": True,
    "controller_lock_released": True,
    "kernel_health": "FAIL_UNEXPECTED_DUT_RESTART_AFTER_MMIO_HANG",
    "raw_capture_publication": "NO",
    "camera_image_publication": "NO",
    "fpga_source_changed": "NO",
    "ssot_changed": "NO",
}
write_json("G2B_NVP_VIDEO_DIAG1_R2R2R1_STATE.json", state)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_FINAL_STATE.md",
    f"""# Final state

- Engineering gate: FAIL
- Overall result: FAIL
- First blocker: `{FIRST_BLOCKER}`
- Double-PREPARE: NOT_REACHED
- Scan sessions: 0/16
- Captures: 0/16
- Stream enabled by task: NO
- Final pending AIO: 0
- Native helper processes: absent
- Driver: absent
- XDMA nodes: absent
- Linux lock: released
- Controller lock: released last
- FPGA runtime image: diagnostic R2R1 candidate in volatile SRAM
- NVP persistent state changed: NO
- SSOT/META: unchanged/not performed
""",
)

gate_rows = [
    ("INHERITED_OFFLINE_SIGNOFF", "PASS", "R2R1"),
    ("HOST_CONTROLLER_SEQUENCE", "PASS", "program-before-PREPARE; START hard-gated"),
    ("EXACT_BITSTREAM_IDENTITY", "PASS", BITSTREAM_SHA),
    ("FPGA_SRAM_PROGRAMMING", "PASS", "one program_hw_devices; DONE=1"),
    ("PRODUCT_EQUIVALENT_AUTOINIT", "PASS", "status=0x000000F9; NACK=0; timeout=0"),
    ("COMMANDED_WARM_REBOOT", "PASS", "one acknowledged reboot"),
    ("DRIVER_AND_ENDPOINT", "PASS", "0000:01:00.0 Gen2 x1"),
    ("RUNTIME_PRODUCT_IDENTITY", "PASS", SOURCE_COMMIT),
    ("RUNTIME_DIAGNOSTIC_IDENTITY", "PASS", "magic/version/capabilities"),
    ("PREBASELINE_QUIESCENCE", "PASS", "CONTROL=0; STATUS=0x000000C4; no holder"),
    ("INITIAL_DIAG_CLEAR", "FAIL", "STATUS=0xFFFFFFFF; ERROR=0xFFFFFFFF"),
    ("PREPARE_A", "NOT_REACHED", FIRST_BLOCKER),
    ("PREPARE_B", "NOT_REACHED", FIRST_BLOCKER),
    ("DOUBLE_PREPARE_BASELINE", "NOT_REACHED", FIRST_BLOCKER),
    ("START_4X4_SCAN", "NOT_REACHED", FIRST_BLOCKER),
    ("CAPTURES_16", "NOT_REACHED", "0/16"),
    ("PRODUCT_BASELINE_RESTORE", "NOT_REACHED", "no PREPARE_B; no scan NVP writes"),
    ("FINAL_PENDING_AIO", "PASS", "0"),
    ("DRIVER_NODES_FINAL", "PASS", "absent"),
    ("LOCKS_RELEASED", "PASS", "Linux then controller-last"),
    ("PCIE_AER_KERNEL_HEALTH", "FAIL", "unexpected DUT restart after MMIO hang"),
    ("EVIDENCE_PUBLICATION", "PENDING", "evaluated after immutable commit/read-back"),
]
write_csv(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_GATE_MATRIX.csv",
    ["Gate", "Result", "Evidence"],
    [{"Gate": a, "Result": b, "Evidence": c} for a, b, c in gate_rows],
)
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_SOURCE_ROLE_MAP.md",
    """# Published source role map

- R2R2R1 controller, Double-PREPARE wrapper, baseline collector, snapshot
  collector, scan orchestration, and final classifier:
  `sources/controller_nvp_video_diag1_r2r2r1.py`
- authorization sequence and mocked gate:
  `sources/r2r2r1_authorization_sequence.py`,
  `sources/test_r2r2r1_authorization_sequence.py`
- finite capture orchestration: `sources/controller_nvp_capture_r2r2r1.py`
- fixed record validation and reconstruction:
  `sources/validate_nvp_capture.py`,
  `sources/frame_reconstruct_nvp_capture.py`
- private pixel statistics/classification: `sources/analyze_nvp_video_diag1.py`
- result aggregation: `sources/aggregate_nvp_session_metadata.py`
- rolling AIO helper source: `sources/xdma_c2h_rolling_4k_diag1.c`

No native binary, camera pixels, bitstream, DCP, driver, or credential is
published.
""",
)

index_lines = [
    "# R2R2R1 evidence index",
    "",
    "Engineering result: FAIL",
    "",
    f"First blocker: `{FIRST_BLOCKER}`",
    "",
    "All entries are sanitized public evidence. Raw captures and camera images",
    "do not exist because the scan was not reached. Prohibited binaries and",
    "credentials are excluded.",
    "",
    "## Files",
    "",
]
for path in sorted(OUT.rglob("*")):
    if path.is_file() and path.name not in {
        "G2B_NVP_VIDEO_DIAG1_R2R2R1_EVIDENCE_INDEX.md",
        "G2B_NVP_VIDEO_DIAG1_R2R2R1_SHA256_MANIFEST.txt",
    }:
        index_lines.append(f"- `{path.relative_to(OUT).as_posix()}`")
index_lines.extend([
    "- `G2B_NVP_VIDEO_DIAG1_R2R2R1_EVIDENCE_INDEX.md`",
    "- `G2B_NVP_VIDEO_DIAG1_R2R2R1_SHA256_MANIFEST.txt`",
])
write_text("G2B_NVP_VIDEO_DIAG1_R2R2R1_EVIDENCE_INDEX.md", "\n".join(index_lines))

manifest_lines = []
for path in sorted(OUT.rglob("*")):
    if path.is_file() and path.name != "G2B_NVP_VIDEO_DIAG1_R2R2R1_SHA256_MANIFEST.txt":
        manifest_lines.append(f"{sha(path)}  {path.relative_to(OUT).as_posix()}")
write_text(
    "G2B_NVP_VIDEO_DIAG1_R2R2R1_SHA256_MANIFEST.txt",
    "\n".join(manifest_lines),
)

print(json.dumps({
    "result": "PASS",
    "evidence_root": str(OUT),
    "files": sum(1 for path in OUT.rglob("*") if path.is_file()),
    "controller_sha256": final_controller_sha,
    "first_blocker": FIRST_BLOCKER,
}, sort_keys=True))
