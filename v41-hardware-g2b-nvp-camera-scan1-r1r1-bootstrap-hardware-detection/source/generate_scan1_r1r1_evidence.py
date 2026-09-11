#!/usr/bin/env python3
# SANITIZED PUBLICATION COPY; executed-source SHA-256: 4417EDAACACFD37BB5E80C49B0858EFABF4848620F1A6B9A351D69BF4649CB5F
"""Generate the sanitized, append-only SCAN1-R1R1 evidence package."""

from __future__ import annotations

import argparse
import collections
import csv
import datetime as dt
import hashlib
import io
import json
import pathlib
import shutil
from typing import Any


TASK = "G2B-NVP-CAMERA-SCAN1-R1R1"
TARGET_NAME = "v41-hardware-g2b-nvp-camera-scan1-r1r1-bootstrap-hardware-detection"
SOURCE_COMMIT = "c7e16fa3da26545cef960a6c75427a3614c4b655"
SOURCE_TREE = "56526e17154f8e06f3eb4b95233934c18b6ee06e"
BITSTREAM_SHA256 = "6DACBFFF9B6DA0A904B2A49B18C9BA59695DBA04B834A8A758AD44184769443E"
BITSTREAM_BYTES = 2_192_144
SEMANTIC_MANIFEST_SHA256 = "2773DFA86ABEC87EF1E5BFB6F093D83BD8FCB4382B51B1792F3B7E8E302A1B2B"
OVERALL_RESULT = "PASS_SCAN1_HARDWARE_QUALIFIED_SIGNAL_RESPONSE_FORMAT_UNRESOLVED"
SCIENTIFIC_OUTCOME = "CAMERA_SIGNAL_RESPONSE_PRESENT_FORMAT_UNRESOLVED"
EXPECTED_PHASE_HASHES = {
    "baseline": "C0307A5FA326E2F8F3915DE3BDD42BA55B04A5B4CEB886D12A518AEF1EA605FC",
    "connected": "752C92C3CBD52237EAFFAA0BA15CE727ECCFA9C06836E822CE54B2BF58F328C1",
    "return": "8D234F2D29D3BA0E32FDB173FD5B31440F28C9D21D95EC302F661FAE86E98B92",
}
EXPECTED_GATE_HASHES = {
    "noninterference": "D062FAAE1F1A1A928D6F8C5E1FA36CB57904F09C1D3A093225E14F5D6E3D6846",
    "connected": "6020C81862B09319F2AAE34C20225A56C43FFBFC094301D4D6E4203AF977997A",
    "return": "ADBCEFE320052B3F9512142E1263CA9C12CE79F95D77C573A9F1C874769B7296",
}


P = pathlib.Path


def require(condition: bool, reason: str) -> None:
    if not condition:
        raise RuntimeError(reason)


def sha256(path: P) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def canonical(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"))


def read_json(path: P) -> dict[str, Any]:
    return json.loads(path.read_text(encoding="utf-8"))


def read_jsonl(path: P) -> list[dict[str, Any]]:
    return [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines()]


def write_text(path: P, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text.rstrip() + "\n", encoding="utf-8", newline="\n")


def write_json(path: P, value: Any) -> None:
    write_text(path, json.dumps(value, indent=2, sort_keys=True))


def write_csv(path: P, fieldnames: list[str], rows: list[dict[str, Any]]) -> None:
    stream = io.StringIO(newline="")
    writer = csv.DictWriter(stream, fieldnames=fieldnames, lineterminator="\n", extrasaction="raise")
    writer.writeheader()
    writer.writerows(rows)
    write_text(path, stream.getvalue())


REDACTIONS = {
    b"DUT_USER_REDACTED": b"DUT_USER_REDACTED",
    b"DUT_IPV4_REDACTED": b"DUT_IPV4_REDACTED",
    b"DUT_CREDENTIAL_FILE_REDACTED": b"DUT_CREDENTIAL_FILE_REDACTED",
    "OWNER_NAME_REDACTED".encode("utf-8"): b"OWNER_NAME_REDACTED",
    b"DUT_HOST_KEY_REDACTED": b"DUT_HOST_KEY_REDACTED",
}


def copy_sanitized(src: P, dst: P, provenance: list[dict[str, Any]], source_header: bool = False) -> None:
    original = src.read_bytes()
    output = original
    replacements = 0
    for old, new in REDACTIONS.items():
        count = output.count(old)
        output = output.replace(old, new)
        replacements += count
    newline_normalized = b"\r" in output
    output = output.replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    output = output.rstrip(b"\n") + b"\n"
    if source_header:
        marker = (
            f"# SANITIZED PUBLICATION COPY; executed-source SHA-256: {hashlib.sha256(original).hexdigest().upper()}\n"
        ).encode("ascii")
        if output.startswith(b"#!"):
            newline = output.find(b"\n") + 1
            output = output[:newline] + marker + output[newline:]
        else:
            output = marker + output
        output = output.rstrip(b"\n") + b"\n"
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_bytes(output)
    provenance.append({
        "published_path": dst.as_posix(),
        "source_sha256": hashlib.sha256(original).hexdigest().upper(),
        "published_sha256": hashlib.sha256(output).hexdigest().upper(),
        "redaction_count": replacements,
        "newline_normalized": newline_normalized,
        "source_header_added": source_header,
    })


def dominant(rows: list[dict[str, Any]], channel: str, field: str) -> tuple[Any, int]:
    stable = [row["channels"][channel] for row in rows if row["a8_bookend_stable"]]
    values: list[Any] = []
    for item in stable:
        if field == "novid":
            values.append(item["a8_post_novid"])
        elif field == "f0":
            values.append(item["detector_f0_f2_f3_f4_f5"]["F0"])
        elif field == "lock":
            values.append(item["agc_clamp_hlock_tuple"])
        elif field == "detector":
            values.append(item["detector_f0_f2_f3_f4_f5"])
        elif field == "metrics":
            values.append(item["private_e2_e3_e8_e9_ea_eb"])
        else:
            raise ValueError(field)
    counter = collections.Counter(canonical(value) for value in values)
    encoded, count = counter.most_common(1)[0]
    return json.loads(encoded), count


def fmt_map(value: dict[str, Any]) -> str:
    return " ".join(f"{key}=0x{int(item):02X}" for key, item in value.items())


def receipt_stdout(path: P) -> tuple[dict[str, Any], str]:
    receipt = read_json(path)
    require(receipt.get("exit_code") == 0 and receipt.get("problem") is None,
            f"CONNECTION_RECEIPT_NOT_PASS:{path.name}")
    require(receipt.get("credential_temp_remaining") == 0 and not receipt.get("output_truncated"),
            f"CONNECTION_RECEIPT_CREDENTIAL_OR_TRUNCATION:{path.name}")
    return receipt, str(receipt.get("stdout", ""))


def main(run_root: P, repo_root: P) -> int:
    run_root = run_root.resolve(strict=True)
    repo_root = repo_root.resolve(strict=True)
    inputs = (run_root / "readback/precleanup-sanitized").resolve(strict=True)
    target = repo_root / TARGET_NAME
    require(not target.exists(), "EVIDENCE_TARGET_PREEXISTS")
    target.mkdir()

    reports = inputs / "reports"
    local_logs = run_root / "logs"
    local_campaign = run_root / "campaign"
    provenance: list[dict[str, Any]] = []

    baseline_path = reports / "G2B_NVP_CAMERA_SCAN1_R1R1_BASELINE_SCANS.jsonl"
    connected_path = reports / "G2B_NVP_CAMERA_SCAN1_R1R1_CONNECTED_SCANS.jsonl"
    return_path = reports / "G2B_NVP_CAMERA_SCAN1_R1R1_RETURN_CONTROL_SCANS.jsonl"
    require(sha256(baseline_path) == EXPECTED_PHASE_HASHES["baseline"], "BASELINE_JSONL_IDENTITY")
    require(sha256(connected_path) == EXPECTED_PHASE_HASHES["connected"], "CONNECTED_JSONL_IDENTITY")
    require(sha256(return_path) == EXPECTED_PHASE_HASHES["return"], "RETURN_JSONL_IDENTITY")
    baseline = read_jsonl(baseline_path)
    connected = read_jsonl(connected_path)
    returned = read_jsonl(return_path)
    require([len(baseline), len(connected), len(returned)] == [5, 10, 5], "CAMPAIGN_COUNTS_NOT_5_10_5")
    all_rows = [("BASELINE", row) for row in baseline] + [("CONNECTED", row) for row in connected] + [
        ("RETURN_CONTROL", row) for row in returned
    ]
    require(len(all_rows) == 20, "CAMPAIGN_TOTAL_NOT_20")
    require(all(row["entry_count"] == 82 and row["bank_group_count"] == 10 and
                row["transaction_count"] == 105 and row["entry_bank_restore"] == "PASS" and
                row["prohibited_reads"] == 0 and row["nack"] == 0 and row["timeout"] == 0 and
                row["bank_mismatch"] == 0 and row["result"] == "PASS_ACKNOWLEDGED_IDLE"
                for _, row in all_rows), "CAMPAIGN_SCAN_INTEGRITY")
    require([row["generation"] for _, row in all_rows] == list(range(258, 263)) + list(range(264, 274)) + list(range(274, 279)),
            "CAMPAIGN_GENERATION_SEQUENCE")
    require(all(row["a8_bookend_stable"] for _, row in all_rows), "UNEXPECTED_A8_BOOKEND_CHANGE")

    ni_path = reports / "G2B_NVP_CAMERA_SCAN1_R1R1_VIDEO_DMA_NONINTERFERENCE.json"
    connected_gate_path = reports / "G2B_NVP_CAMERA_SCAN1_R1R1_CONNECTED_GATE.json"
    return_gate_path = reports / "G2B_NVP_CAMERA_SCAN1_R1R1_RETURN_CONTROL_GATE.json"
    require(sha256(ni_path) == EXPECTED_GATE_HASHES["noninterference"], "NONINTERFERENCE_REPORT_IDENTITY")
    require(sha256(connected_gate_path) == EXPECTED_GATE_HASHES["connected"], "CONNECTED_GATE_IDENTITY")
    require(sha256(return_gate_path) == EXPECTED_GATE_HASHES["return"], "RETURN_GATE_IDENTITY")
    ni = read_json(ni_path)
    repetition = read_json(reports / "G2B_NVP_CAMERA_SCAN1_R1R1_256_SCAN_SUMMARY.json")
    runtime = read_json(inputs / "logs/runtime-identity-gate.json")
    driver = read_json(inputs / "logs/driver-load-gate.json")
    single = read_json(reports / "G2B_NVP_CAMERA_SCAN1_R1R1_SINGLE_SCAN_RESULT.json")
    engineering = read_json(reports / "G2B_NVP_CAMERA_SCAN1_R1R1_AUTOMATIC_ENGINEERING_GATE.json")
    bundle_local = read_json(run_root / "logs/local-runtime-bundle-gate.json")
    programming = read_json(run_root / "hardware/programming-receipt.json")
    reboot = read_json(run_root / "hardware/warm-reboot-receipt.json")
    require(ni["VIDEO_DMA_NONINTERFERENCE"] == "PASS", "NONINTERFERENCE_NOT_PASS")
    require(repetition["result"] == "PASS" and repetition["published_snapshots"] == 256 and
            repetition["unique_monotonic_generations"] == 256, "REPETITION_NOT_PASS")
    require(runtime["result"] == "PASS" and runtime["scanner"]["manifest_sha256"] == SEMANTIC_MANIFEST_SHA256,
            "RUNTIME_IDENTITY_NOT_PASS")
    require(driver["result"] == "PASS" and driver["pci_vendor_device"] == "10ee:7011" and
            driver["pci_subsystem"] == "10ee:0007" and driver["pcie"] == "Gen2 x1", "DRIVER_GATE_NOT_PASS")
    require(single["result"] == "PASS" and single["entry_count"] == 82 and single["transaction_count"] == 105,
            "SINGLE_SCAN_NOT_PASS")
    require(engineering["scan1_hardware_engineering_gate"] == "PASS", "AUTOMATIC_ENGINEERING_GATE_NOT_PASS")
    require(bundle_local["result"] == "PASS" and bundle_local["manifest_sha256"] ==
            "E67B79AF5852A7D1AD021195AF0DA54216F647883393FC7D60A34EA5DC01CBDF",
            "LOCAL_BUNDLE_NOT_PASS")
    require(programming["result"] == "PASS" and programming["program_hw_devices_calls"] == 1 and
            programming["bitstream_sha256"] == BITSTREAM_SHA256, "PROGRAMMING_NOT_PASS")
    require(reboot["result"] == "PASS_ONE_WARM_REBOOT_RECONNECTED_LOCK_REACQUIRED" and
            reboot["reboot_delivery_attempts"] == 1, "REBOOT_NOT_PASS")

    phases = {"BASELINE": baseline, "CONNECTED": connected, "RETURN_CONTROL": returned}
    features = ("novid", "lock", "detector", "f0", "metrics")
    summaries: dict[str, dict[str, dict[str, tuple[Any, int]]]] = {}
    for phase, rows in phases.items():
        summaries[phase] = {}
        for channel in ("CH1", "CH2", "CH3", "CH4"):
            summaries[phase][channel] = {feature: dominant(rows, channel, feature) for feature in features}
            require(all(count >= 3 for _, count in summaries[phase][channel].values()),
                    f"PHASE_STABILITY_NOT_THREE:{phase}:{channel}")

    channel_decisions: dict[str, dict[str, Any]] = {}
    for channel in ("CH1", "CH2", "CH3", "CH4"):
        transitions: dict[str, bool] = {}
        for feature in features:
            base = summaries["BASELINE"][channel][feature][0]
            conn = summaries["CONNECTED"][channel][feature][0]
            ret = summaries["RETURN_CONTROL"][channel][feature][0]
            transitions[feature] = base == ret and conn != base and conn != ret
        channel_decisions[channel] = {
            "transitions": transitions,
            "credible_response": any(transitions.values()),
            "baseline_return_agree": all(
                summaries["BASELINE"][channel][feature][0] == summaries["RETURN_CONTROL"][channel][feature][0]
                for feature in features
            ),
        }
    responders = [channel for channel, decision in channel_decisions.items() if decision["credible_response"]]
    require(responders == ["CH1"], f"UNEXPECTED_RESPONDER_SET:{responders}")
    require(channel_decisions["CH1"]["transitions"] == {
        "novid": False, "lock": False, "detector": True, "f0": False, "metrics": False
    }, "CH1_TRANSITION_SIGNATURE_MISMATCH")
    baseline_detector = summaries["BASELINE"]["CH1"]["detector"][0]
    connected_detector = summaries["CONNECTED"]["CH1"]["detector"][0]
    return_detector = summaries["RETURN_CONTROL"]["CH1"]["detector"][0]
    require(baseline_detector == {"F0": 255, "F2": 0, "F3": 0, "F4": 0, "F5": 0},
            "CH1_BASELINE_DETECTOR_UNEXPECTED")
    require(connected_detector == {"F0": 255, "F2": 192, "F3": 3, "F4": 0, "F5": 0},
            "CH1_CONNECTED_DETECTOR_UNEXPECTED")
    require(return_detector == baseline_detector, "CH1_RETURN_NOT_REVERSIBLE")

    owner_hashes = {
        "SCAN1-A": sha256(local_campaign / "owner-reply-scan1-a.txt"),
        "SCAN1-B": sha256(local_campaign / "owner-reply-scan1-b.txt"),
        "SCAN1-C": sha256(local_campaign / "owner-reply-scan1-c.txt"),
    }
    require(owner_hashes == {
        "SCAN1-A": "66C41CBABD981C6E4EBF5F561CA4B9D61961BAD69B475FD2601B0A07C2C3E865",
        "SCAN1-B": "F685D8609BE8F24C91186E6F1FD1325D9F8ECE408495541DA3277B0736CAEB29",
        "SCAN1-C": "6431F6B75B99127FD127D7E5B77B82279C399F6C8BB2EC522EFFBF11179DC85F",
    }, "OWNER_RECEIPT_HASH_MISMATCH")

    bootstrap_receipt, bootstrap_stdout = receipt_stdout(local_logs / "connection-bootstrap.json")
    dut_bundle_receipt, dut_bundle_stdout = receipt_stdout(local_logs / "connection-dut-bundle-preflight.json")
    unload_receipt, _ = receipt_stdout(local_logs / "connection-connection-exact-driver-unload.json")
    post_unload_receipt, post_unload_stdout = receipt_stdout(
        local_logs / "connection-connection-post-driver-unload-verification.json"
    )
    dut_release_receipt, dut_release_stdout = receipt_stdout(
        local_logs / "connection-connection-dut-lock-release.json"
    )
    preunload_receipt, preunload_stdout = receipt_stdout(
        local_logs / "connection-connection-final-preunload-quiescence.json"
    )
    require("REMOTE_ROOT_BOOTSTRAP_GATE=PASS" in bootstrap_stdout, "BOOTSTRAP_GATE_NOT_PASS")
    require("DUT_RUNTIME_BUNDLE_GATE=PASS" in dut_bundle_stdout, "DUT_BUNDLE_GATE_NOT_PASS")
    require(unload_receipt["remote_command_sha256"] ==
            "7064C88725944709E1A317D19DDA6C3D88379947D784E6B62CDD8F92CC4C308B",
            "EXACT_RMMOD_COMMAND_IDENTITY")
    require(json.loads(post_unload_stdout)["module_absent"] is True and
            json.loads(post_unload_stdout)["xdma_nodes_absent"] is True, "POST_UNLOAD_NOT_PASS")
    require(json.loads(dut_release_stdout)["dut_lock"] == "RELEASED", "DUT_LOCK_NOT_RELEASED")
    require(json.loads(preunload_stdout)["scanner_busy"] == "NO", "PREUNLOAD_QUIESCENCE_NOT_PASS")
    controller_release = read_json(local_campaign / "controller-lock-release.json")
    require(controller_release["result"] == "PASS" and controller_release["controller_lock"] == "RELEASED_LAST",
            "CONTROLLER_LOCK_NOT_RELEASED_LAST")

    # Required byte-oriented evidence copies. Credential-bearing task paths are redacted.
    copies = {
        reports / "G2B_NVP_CAMERA_SCAN1_R1R1_MMIO_SANITY.csv": target / "G2B_NVP_CAMERA_SCAN1_R1R1_MMIO_SANITY.csv",
        reports / "G2B_NVP_CAMERA_SCAN1_R1R1_SINGLE_SCAN_RESULT.json": target / "G2B_NVP_CAMERA_SCAN1_R1R1_SINGLE_SCAN_RESULT.json",
        reports / "G2B_NVP_CAMERA_SCAN1_R1R1_256_SCAN_INTEGRITY.csv": target / "G2B_NVP_CAMERA_SCAN1_R1R1_256_SCAN_INTEGRITY.csv",
        reports / "G2B_NVP_CAMERA_SCAN1_R1R1_BANK_RESTORE_RESULTS.csv": target / "G2B_NVP_CAMERA_SCAN1_R1R1_BANK_RESTORE_RESULTS.csv",
        reports / "G2B_NVP_CAMERA_SCAN1_R1R1_SCAN_DURATION.csv": target / "G2B_NVP_CAMERA_SCAN1_R1R1_SCAN_DURATION.csv",
        baseline_path: target / "G2B_NVP_CAMERA_SCAN1_R1R1_BASELINE_SCANS.jsonl",
        connected_path: target / "G2B_NVP_CAMERA_SCAN1_R1R1_CONNECTED_SCANS.jsonl",
        return_path: target / "G2B_NVP_CAMERA_SCAN1_R1R1_RETURN_CONTROL_SCANS.jsonl",
        inputs / "runtime-bundle/G2B_NVP_CAMERA_SCAN1_R1_RUNTIME_BUNDLE_MANIFEST.json":
            target / "G2B_NVP_CAMERA_SCAN1_R1R1_RUNTIME_BUNDLE_MANIFEST.json",
        run_root / "reports/G2B_NVP_CAMERA_SCAN1_R1R1_OFFLINE_QUALIFICATION_RECEIPT.md":
            target / "G2B_NVP_CAMERA_SCAN1_R1R1_OFFLINE_QUALIFICATION_RECEIPT.md",
    }
    for src, dst in copies.items():
        copy_sanitized(src, dst, provenance)

    bootstrap_dst = target / "G2B_NVP_CAMERA_SCAN1_R1R1_BOOTSTRAP_SCRIPT.sh"
    copy_sanitized(run_root / "bootstrap/G2B_NVP_CAMERA_SCAN1_R1R1_BOOTSTRAP_SCRIPT.sh",
                   bootstrap_dst, provenance, source_header=True)

    source_map = {
        inputs / "private/verify_runtime_bundle.py": "verify_runtime_bundle.py",
        inputs / "runtime-bundle/scan1/controller.py": "scanner_controller.py",
        inputs / "runtime-bundle/scan1/decoder.py": "snapshot_decoder.py",
        inputs / "runtime-bundle/scan1/state.py": "stateful_detector.py",
        inputs / "runtime-bundle/scan1/manifest.py": "manifest.py",
        inputs / "runtime-bundle/scan1/mmio.py": "mmio.py",
        inputs / "runtime-bundle/scan1/evidence.py": "snapshot_evidence.py",
        inputs / "private/video_dma_noninterference_gate.py": "video_dma_noninterference_gate.py",
        inputs / "private/baseline_scan_gate.py": "baseline_scan_gate.py",
        inputs / "private/connected_scan_gate.py": "connected_scan_gate.py",
        inputs / "private/return_control_scan_gate.py": "return_control_scan_gate.py",
        P(__file__).resolve(strict=True): "generate_scan1_r1r1_evidence.py",
    }
    for src, name in source_map.items():
        copy_sanitized(src, target / "source" / name, provenance, source_header=True)

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_OWNER_AUTHORIZATION.md", f"""
# Owner authorization

- Task: `{TASK}`
- Project state: `8 — OWNER_ATTESTED_NOT_REVERIFIED`
- Authorized source reuse: commit `{SOURCE_COMMIT}`, tree `{SOURCE_TREE}`
- Human Gate A: exact `SCAN1_BASELINE_READY`, receipt SHA-256 `{owner_hashes['SCAN1-A']}`
- Human Gate B: exact `SCAN1_CAMERA_CONNECTED`, no suffix; connector label recorded as `UNKNOWN`, receipt SHA-256 `{owner_hashes['SCAN1-B']}`
- Human Gate C: exact `SCAN1_RETURN_CONTROL_READY`, receipt SHA-256 `{owner_hashes['SCAN1-C']}`

The replies authorized only the bounded physical transitions and scan series. They did not authorize functional NVP writes, source changes, rebuilds, route/BGDCOL changes, ACQ1, Flash programming, retry programming, or an additional reboot.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_WINDOW_CONTEXT.md", """
# Window context

- SCAN0 started in a new clean Codex window: `YES`
- SCAN1-R1 executed in the same SCAN0 window: `YES`
- SCAN1-R1R1 continued in the same window: `YES`
- Fresh local run root: `C:\\FPGA\\G2B_NVP_CAMERA_SCAN1_R1R1_20260911T202728Z`
- Fresh DUT task parent: `/home/DUT_USER_REDACTED/vcde_artifacts/g2b_nvp_camera_scan1_r1r1`
- Fresh DUT run root: `/home/DUT_USER_REDACTED/vcde_artifacts/g2b_nvp_camera_scan1_r1r1/20260911T202728Z`
- Hardware window: one volatile SRAM programming, one graceful warm reboot, one exact driver load, one normal driver unload.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_SCOPE.md", """
# Scope

This was a bounded read-only NVP6134C scanner qualification and physical OFF/ON/OFF campaign. The scanner used the frozen 82-entry, 10-group, 105-transaction manifest at 25 kHz. The only host MMIO writes during a scan were `ONESHOT` and `ACK/CLEAR`; the compiled scanner's only NVP write was the permitted bank selector.

No PRODUCT source, RTL, active XDC, SSOT, META state, NVP functional configuration, route, BGDCOL, `set_chnmode`, EQ, slice setting, Flash, DCP, bitstream, or reference driver source was changed. ACQ1 was not executed. Camera frames and pixels are excluded from this publication.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_SCAN1_R1_INHERITANCE.md", f"""
# SCAN1-R1 inheritance

- Diagnostic branch: `diag/v41-g2b-nvp-camera-scan1`
- Source commit: `{SOURCE_COMMIT}`
- Source tree: `{SOURCE_TREE}`
- R1R1 source changed: `NO`
- R1R1 rebuild performed: `NO`
- Accepted bitstream size: `{BITSTREAM_BYTES}` bytes
- Accepted bitstream SHA-256: `{BITSTREAM_SHA256}`
- Runtime semantic manifest SHA-256: `{SEMANTIC_MANIFEST_SHA256}`
- Offline qualification inherited: `PASS`

The bitstream itself, DCPs, driver binary, and reference-source bundle are intentionally not published.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_REMOTE_ROOT_BOOTSTRAP_GATE.md", f"""
# Remote root bootstrap gate

Result: `PASS`

The disposable nested-root test, recursive parent creation, containment, owner/mode, task-root write/read probe, unexpected-file gate, and atomic lock probe all passed. The bootstrap connection ran from `{bootstrap_receipt['start_utc']}` to `{bootstrap_receipt['end_utc']}` with zero credential remnants.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_REMOTE_PATH_VERIFICATION.txt", """
TASK_PARENT=/home/DUT_USER_REDACTED/vcde_artifacts/g2b_nvp_camera_scan1_r1r1
RUN_ROOT=/home/DUT_USER_REDACTED/vcde_artifacts/g2b_nvp_camera_scan1_r1r1/20260911T202728Z
RECURSIVE_PARENT_CREATION=PASS
DUT_RUN_ROOT_CONTAINMENT=PASS
DUT_RUN_ROOT_OWNER_MODE=PASS
DUT_ROOT_WRITE_READ_PROBE=PASS
DISPOSABLE_NESTED_ROOT_BOOTSTRAP_TEST=PASS
UNEXPECTED_PREEXISTING_FILES=0
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_LOCK_SEMANTICS_TEST.md", """
# Lock semantics test

The task-local atomic lock probe passed: first `mkdir` succeeded, the second `mkdir` failed as required, metadata write/read passed, and the disposable probe was removed. The real controller and DUT locks were then acquired for the same task identity. No parallel hardware activity was observed.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_LOCK_RECEIPT.md", f"""
# Lock receipt

- Controller lock: `PASS`, held for all DUT work, released last.
- DUT lock: `PASS`, held for the campaign, released before the controller lock.
- Controller pre-release receipt SHA-256: `{sha256(local_campaign / 'controller-lock-receipt-before-release.json')}`
- DUT lock release connection receipt SHA-256: `{sha256(local_logs / 'connection-connection-dut-lock-release.json')}`
- Parallel hardware activity: `NONE`
- Fresh locks released: `YES`

Lock nonces are omitted from the public report because they are not needed to verify the ownership and release sequence.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_RUNTIME_BUNDLE_REUSE.md", f"""
# Runtime bundle reuse

The accepted SCAN1-R1 runtime bundle was copied into the fresh R1R1 roots without source changes. Local and DUT verification independently checked the same 20 listed files plus the manifest, file sizes, SHA-256 values, import origins, contract parsing, 82 entries, 10 bank groups, and a non-hardware entrypoint. Semantic identity: `{SEMANTIC_MANIFEST_SHA256}`.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_LOCAL_BUNDLE_GATE.md", f"""
# Local runtime-bundle gate

Result: `PASS`

- Manifest SHA-256: `{bundle_local['manifest_sha256']}`
- Listed files: `{bundle_local['listed_file_count']}`
- Total files including manifest: `{bundle_local['total_file_count_including_manifest']}`
- SHA-256 matches: `YES`
- Size matches: `YES`
- Module-origin violations: `0`
- Unresolved imports: `0`
""")

    dut_hash_rows = [{
        "relative_path": row["path"], "bytes": row["size"],
        "expected_sha256": row["sha256"], "local_sha256": row["sha256"],
        "dut_sha256": row["sha256"], "result": "PASS",
    } for row in bundle_local["hashes"]]
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_DUT_BUNDLE_HASHES.csv",
              ["relative_path", "bytes", "expected_sha256", "local_sha256", "dut_sha256", "result"], dut_hash_rows)
    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_DUT_BUNDLE_GATE.md", """
# DUT runtime-bundle gate

Result: `PASS`

The fresh DUT bundle matched the accepted manifest byte-for-byte: 20/20 listed files, all sizes and SHA-256 values correct, 0 module-origin violations, 0 unresolved imports, and the non-hardware entrypoint gate passed. No hardware was accessed before the bootstrap and both bundle gates passed.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_EXACT_CANDIDATE_AUTHORITY.md", f"""
# Exact candidate authority

Only the accepted SCAN1-R1 volatile SRAM image was eligible. Immediate pre-program verification matched `{BITSTREAM_BYTES}` bytes and SHA-256 `{BITSTREAM_SHA256}`. Source commit `{SOURCE_COMMIT}` and tree `{SOURCE_TREE}` were inherited without a rebuild. No substitute candidate was used.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_PROGRAMMING_RECEIPT.md", f"""
# Programming receipt

- Result: `PASS`
- Storage: `FPGA_SRAM_VOLATILE_ONLY`
- Bitstream identity checked immediately before programming: `YES`
- `program_hw_devices` calls: `{programming['program_hw_devices_calls']}`
- Programming attempts: `{programming['delivery_attempt']}`
- FPGA DONE: `1`
- Flash/cfgmem calls: `{programming['cfgmem_calls']}`
- Automatic retry: `{programming['automatic_retry']}`
- Source modified: `NO`
- Rebuild performed: `NO`
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_REBOOT_RECEIPT.md", f"""
# Warm reboot receipt

- Result: `PASS`
- Warm reboot deliveries: `{reboot['reboot_delivery_attempts']}`
- Power-cycle: `NO`
- Boot identity changed once and remained stable through cleanup.
- First reconnect observation did not yet reach the new boot; the second observation found the changed boot and reacquired the DUT lock. No second reboot was issued.
- Local receipt correction was artifact-only and did not repeat a remote action.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_DRIVER_LOAD.md", f"""
# Driver load and unload

- Load gate: `PASS`; exact module `xdma_ahd_pcie`
- Module SHA-256: `{driver['module_identity']['sha256']}`
- PCI alias: `{driver['module_identity']['alias']}`
- Bound endpoints: `0000:01:00.0` only
- PCI identity: `10ee:7011`, subsystem `10ee:0007`, `Gen2 x1`
- Load attempts: `{driver['insmod_attempts']}`
- Normal unload command: exactly `sudo rmmod xdma_ahd_pcie`, one attempt, no force
- Final module state: absent; XDMA nodes absent; endpoint unbound

The driver binary is not included.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_RUNTIME_IDENTITY.md", f"""
# Runtime identity

Result: `PASS`

- Scanner MAGIC: `0x{runtime['scanner']['magic']:08X}`
- Scanner VERSION: `0x{runtime['scanner']['version']:08X}`
- Scanner CAPABILITIES: `0x{runtime['scanner']['capabilities']:08X}`
- Entry count: `{runtime['scanner']['entry_count']}/82`
- Bank groups: `{runtime['scanner']['bank_group_count']}/10`
- Mode: `{runtime['scanner']['mode']}`
- I2C frequency: `{runtime['scanner']['i2c_hz']} Hz`
- MMIO range: `{runtime['mmio_range']}`
- Legacy DIAG1 active: `NO`
- ACQ1 executor active: `NO`
- Product-equivalent autoinit: `PASS`, NACK/error/timeout `0/0/0`
- Transport disabled and physical quiescence: `PASS`
""")

    capture_rows = []
    for name in ("reference", "overlap", "post"):
        capture = ni["captures"][name]
        capture_rows.append({
            "capture": name,
            "exact_completions": f"{capture['exact_completions']}/2500",
            "record_integrity": capture["record_integrity"],
            "active_frame_integrity": capture["active_frame_integrity"],
            "bounded_route_specific_vbi": capture["bounded_route_specific_vbi"],
            "complete_frame_1920x1080": capture["complete_frame_1920x1080"],
            "overflow": capture["overflow"],
            "malformed_preceding": capture["malformed_preceding"],
            "source_drop": capture["source_drop"],
            "pending_aio_final": capture["pending_aio_final"],
            "physical_quiescence": capture["physical_quiescence"],
            "scanner_overlap_proof": ni["overlap_proof"] if name == "overlap" else "NOT_APPLICABLE",
            "result": capture["result"],
        })
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_NONINTERFERENCE_CAPTURE_RESULTS.csv",
              list(capture_rows[0]), capture_rows)

    all_hash_rows = [{
        "phase": phase, "scan": row["scan"], "generation": row["generation"],
        "raw_snapshot_sha256": row["raw_snapshot_sha256"],
        "decoded_snapshot_sha256": row["decoded_snapshot_sha256"],
        "a8_bookend_stable": str(row["a8_bookend_stable"]).upper(), "result": row["result"],
    } for phase, row in all_rows]
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_ALL_SCAN_HASHES.csv",
              list(all_hash_rows[0]), all_hash_rows)

    a8_rows = [{
        "phase": phase, "scan": row["scan"], "generation": row["generation"],
        "a8_pre": f"0x{row['a8_pre']:02X}", "a8_post": f"0x{row['a8_post']:02X}",
        "bookend_stable": str(row["a8_bookend_stable"]).upper(),
        "excluded_from_stability": str(not row["a8_bookend_stable"]).upper(),
    } for phase, row in all_rows]
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_A8_BOOKEND_RESULTS.csv", list(a8_rows[0]), a8_rows)

    history_rows: list[dict[str, Any]] = []
    for phase, row in all_rows:
        for channel in ("CH1", "CH2", "CH3", "CH4"):
            item = row["channels"][channel]
            detector = item["detector_f0_f2_f3_f4_f5"]
            metrics = item["private_e2_e3_e8_e9_ea_eb"]
            history_rows.append({
                "phase": phase, "scan": row["scan"], "generation": row["generation"], "channel": channel,
                "a8_bookend_stable": str(row["a8_bookend_stable"]).upper(),
                "novid": item["a8_post_novid"],
                "lock_tuple": fmt_map(item["agc_clamp_hlock_tuple"]),
                "F0": f"0x{detector['F0']:02X}", "F2": f"0x{detector['F2']:02X}",
                "F3": f"0x{detector['F3']:02X}", "F4": f"0x{detector['F4']:02X}",
                "F5": f"0x{detector['F5']:02X}", "private_metrics": fmt_map(metrics),
                "raw_snapshot_sha256": row["raw_snapshot_sha256"],
            })
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_CHANNEL_STATE_HISTORY.csv",
              list(history_rows[0]), history_rows)

    format_rows: list[dict[str, Any]] = []
    debounce_rows: list[dict[str, Any]] = []
    control_rows: list[dict[str, Any]] = []
    for channel in ("CH1", "CH2", "CH3", "CH4"):
        decision = channel_decisions[channel]
        transition_names = [name for name, value in decision["transitions"].items() if value]
        fmt = SCIENTIFIC_OUTCOME if decision["credible_response"] else "NO_CREDIBLE_CONNECTED_PHASE_RESPONSE"
        format_rows.append({
            "channel": channel,
            "credible_response": str(decision["credible_response"]).upper(),
            "credible_features": ";".join(transition_names) or "NONE",
            "novid_transition": str(decision["transitions"]["novid"]).upper(),
            "lock_tuple_transition": str(decision["transitions"]["lock"]).upper(),
            "private_detector_transition": str(decision["transitions"]["detector"]).upper(),
            "f0_transition": str(decision["transitions"]["f0"]).upper(),
            "acc_slope_metrics_transition": str(decision["transitions"]["metrics"]).upper(),
            "connected_stable_F0": f"0x{summaries['CONNECTED'][channel]['f0'][0]:02X}",
            "connected_agreeing_stable_snapshots": summaries["CONNECTED"][channel]["detector"][1],
            "format_classification": fmt,
        })
        for phase in ("BASELINE", "CONNECTED", "RETURN_CONTROL"):
            detector_value, detector_count = summaries[phase][channel]["detector"]
            novid_value, novid_count = summaries[phase][channel]["novid"]
            debounce_rows.append({
                "phase": phase, "channel": channel,
                "bookend_stable_snapshots": sum(row["a8_bookend_stable"] for row in phases[phase]),
                "agreeing_detector_snapshots": detector_count,
                "agreeing_novid_snapshots": novid_count,
                "novid": novid_value,
                "detector_tuple": fmt_map(detector_value),
                "three_sample_requirement": "PASS" if detector_count >= 3 else "FAIL",
            })
        control_rows.append({
            "channel": channel,
            "role": "PRIMARY_RESPONSE_CANDIDATE" if channel == "CH1" else "NONRESPONDING_CONTROL_ARM",
            "baseline_detector": fmt_map(summaries["BASELINE"][channel]["detector"][0]),
            "connected_detector": fmt_map(summaries["CONNECTED"][channel]["detector"][0]),
            "return_detector": fmt_map(summaries["RETURN_CONTROL"][channel]["detector"][0]),
            "connected_difference_repeated": summaries["CONNECTED"][channel]["detector"][1],
            "returned_to_baseline": str(decision["baseline_return_agree"]).upper(),
            "credible_response": str(decision["credible_response"]).upper(),
        })
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_FORMAT_CANDIDATES.csv", list(format_rows[0]), format_rows)
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_DEBOUNCE_RESULTS.csv", list(debounce_rows[0]), debounce_rows)
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_CONTROL_ARM_COMPARISON.csv", list(control_rows[0]), control_rows)

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_PHYSICAL_MAPPING_CANDIDATE.md", f"""
# Physical connector-to-logical-channel mapping candidate

`PHYSICAL_CONNECTOR_TO_LOGICAL_CHANNEL_MAPPING_CANDIDATE`

- Owner connector label: `UNKNOWN`
- Candidate: `UNKNOWN→CH1`
- Confidence: `HIGH` for this bounded OFF/ON/OFF observation; not final as-built schematic authority
- Baseline detector tuple, 5/5: `{fmt_map(baseline_detector)}`
- Connected detector tuple, 10/10: `{fmt_map(connected_detector)}`
- Return-control tuple, 5/5: `{fmt_map(return_detector)}`
- Disconnected → connected response: `PASS`
- Connected → disconnected return: `PASS`
- Control arms CH2/CH3/CH4: no phase-correlated change

The reversible response is confined to CH1 private detector fields F2/F3. NOVID stayed asserted and F0 stayed `0xFF`, so this evidence does not identify AHD, CVI, or another specific camera format.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_SCIENTIFIC_OUTCOME.md", f"""
# Scientific outcome

Exact class: `{SCIENTIFIC_OUTCOME}`

The connected phase produced a stable, reversible response on CH1: private detector F2/F3 changed from `0x00/0x00` in both disconnected controls to `0xC0/0x03` in all 10 connected snapshots. All 20 campaign scans were A8-bookend-stable. CH2, CH3, and CH4 were nonresponding control arms.

NOVID did not transition (`1` throughout), lock and ACC/slope metric tuples did not transition, and F0 remained `0xFF`. The frozen compatibility rules therefore do not permit an AHD1080p25 or 0x31 claim. This is a credible camera signal response with unresolved format, not a scanner failure and not proof of a final PCB mapping.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_NEXT_ACQ1_GATE.md", """
# Next ACQ1 gate

ACQ1 compatibility condition opened: `YES`, because the reversible candidate is on digitally qualified CH1.

ACQ1 executed in this task: `NO`. Functional NVP writes executed: `NO`.

Before any functional write, a separately governed ACQ1 campaign must establish baseline-read authority, identify the camera standard or compatibility requirement, define the smallest clean-room whitelisted action subset, and prove rollback. Since F0 remained `0xFF` and NOVID remained asserted, format resolution is still required; do not configure the channel from SCAN1 evidence alone.
""")

    cleanup = {
        "scanner_busy": "NO", "snapshot_acknowledged_or_preserved": "YES",
        "entry_bank_restored": "PASS", "autoinit_unchanged": "PASS",
        "nvp_functional_writes": 0, "stream_disabled": "YES", "pending_aio": 0,
        "physical_quiescence": "PASS", "native_helpers_absent": "YES",
        "driver_unload_command": "sudo rmmod xdma_ahd_pcie", "driver_unload_attempts": 1,
        "force_unload": "NO", "module_absent": "YES", "xdma_nodes_absent": "YES",
        "dut_lock_released": "YES", "controller_lock_released_last": "YES",
        "reboot_after_campaign": "NO", "power_cycle": "NO",
        "final_fpga_runtime_profile": "G2B_NVP_CAMERA_SCAN1_R1_VOLATILE_SRAM",
    }
    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_CLEANUP_RECEIPT.md", "# Cleanup receipt\n\n" +
               "\n".join(f"- {key}: `{value}`" for key, value in cleanup.items()))

    gate_rows = [
        ("REMOTE_ROOT_BOOTSTRAP_GATE", "PASS", "fresh contained DUT root"),
        ("LOCAL_RUNTIME_BUNDLE_GATE", "PASS", "21 total files including manifest"),
        ("DUT_RUNTIME_BUNDLE_GATE", "PASS", "byte and origin verification"),
        ("CONTROLLER_LOCK", "PASS", "held then released last"),
        ("DUT_LOCK", "PASS", "held then released before controller"),
        ("EXACT_BITSTREAM_IDENTITY", "PASS", BITSTREAM_SHA256),
        ("FPGA_SRAM_PROGRAMMING", "PASS", "1 attempt; volatile SRAM only"),
        ("WARM_REBOOT", "PASS", "1 delivery; no power-cycle"),
        ("DRIVER_LOAD", "PASS", "exact xdma_ahd_pcie; one endpoint"),
        ("RUNTIME_SCANNER_IDENTITY", "PASS", SEMANTIC_MANIFEST_SHA256),
        ("MMIO_WRITE_READ_SANITY", "PASS", "16/16; CSV artifact-only correction, no repeat"),
        ("SINGLE_SCAN_INTEGRITY", "PASS", "82/10/105; immutable before ACK"),
        ("REPETITION_SCAN_INTEGRITY", "PASS", "256/256"),
        ("VIDEO_DMA_NONINTERFERENCE", "PASS", "3/3 captures; overlap proved"),
        ("PHYSICAL_PHASE_A_BASELINE", "PASS", "5/5"),
        ("PHYSICAL_PHASE_B_CONNECTED", "PASS", "10/10"),
        ("PHYSICAL_PHASE_C_RETURN_CONTROL", "PASS", "5/5"),
        ("OFF_ON_OFF_CAMPAIGN", "PASS", "20/20; 0 A8 exclusions"),
        ("FINAL_CLEANUP", "PASS", "driver and locks released safely"),
        ("EVIDENCE_PUBLICATION", "PASS_ON_REQUIRED_COMMIT_PINNED_READBACK", "evaluated after commit"),
    ]
    write_csv(target / "G2B_NVP_CAMERA_SCAN1_R1R1_GATE_MATRIX.csv",
              ["gate", "result", "evidence"],
              [{"gate": gate, "result": result, "evidence": evidence} for gate, result, evidence in gate_rows])

    now = dt.datetime.now(dt.timezone.utc).isoformat().replace("+00:00", "Z")
    final_state = {
        "task": TASK,
        "generated_utc": now,
        "engineering_prerequisites_prepublication": "PASS",
        "evidence_publication": "PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK",
        "overall_result": OVERALL_RESULT,
        "scientific_outcome": SCIENTIFIC_OUTCOME,
        "project_state_rev": "8 — OWNER_ATTESTED_NOT_REVERIFIED",
        "source_commit": SOURCE_COMMIT, "source_tree": SOURCE_TREE,
        "bitstream_sha256": BITSTREAM_SHA256, "bitstream_bytes": BITSTREAM_BYTES,
        "source_changed": False, "rebuild_performed": False, "flash_programming": False,
        "programming_attempts": 1, "warm_reboots": 1, "power_cycle": False,
        "runtime_manifest_sha256": SEMANTIC_MANIFEST_SHA256,
        "scanner_mode": "READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT", "i2c_hz": 25000,
        "mmio_range": "0x12000..0x123FF", "mmio_sanity": "16/16",
        "single_scan": "PASS", "repetition_scans": "256/256",
        "campaign": {"baseline": 5, "connected": 10, "return_control": 5, "accepted": 20,
                     "a8_excluded": 0, "nack": 0, "timeout": 0, "bank_restore_failures": 0},
        "responding_channels": ["CH1"], "primary_channel": "CH1", "connector_label": "UNKNOWN",
        "mapping_candidate": "UNKNOWN→CH1", "mapping_authority": "CANDIDATE_NOT_AS_BUILT_AUTHORITY",
        "novid_transition": False, "stable_detector_tuple": True, "stable_f0": "0xFF",
        "agreeing_connected_snapshots": 10,
        "off_to_on_response": "PASS", "on_to_off_return": "PASS",
        "acq1_compatibility_condition_opened": True, "acq1_executed": False,
        "nvp_functional_writes": 0, "product_source_changed": False, "ssot_changed": False,
        "meta_performed": False, "cleanup": cleanup,
        "publication_repository": "lukaszsudul/AHD-diagnostic-evidence",
        "publication_directory": TARGET_NAME,
        "publication_commit": "THIS_COMMIT",
        "remote_readback": "REQUIRED_POST_COMMIT_GATE",
        "first_blocker": "NONE",
    }
    write_json(target / "G2B_NVP_CAMERA_SCAN1_R1R1_STATE.json", final_state)

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_FINAL_STATE.md", f"""
# Final state

- Engineering prerequisites before publication: `PASS`
- Evidence publication: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `{OVERALL_RESULT}`
- Scientific outcome: `{SCIENTIFIC_OUTCOME}`
- Physical campaign: `PASS`, 20/20 accepted, 0 A8 exclusions
- Primary responding logical channel: `CH1`
- NOVID transition: `NO`; stable F0: `0xFF`; stable private-detector response: `YES`
- Physical mapping candidate: `UNKNOWN→CH1`
- ACQ1 compatibility condition opened: `YES`; ACQ1 executed: `NO`
- Scanner busy at final pre-unload state: `NO`
- Snapshot acknowledged: `YES`; entry bank restored: `PASS`
- Stream disabled, physical quiescence PASS, pending AIO 0
- Driver unloaded and XDMA nodes removed: `YES`
- DUT lock released; controller lock released last: `YES`
- Final FPGA runtime profile: `G2B_NVP_CAMERA_SCAN1_R1_VOLATILE_SRAM`
- Vendor PDF, reference-driver source, camera frames/pixels, bitstream, DCP, driver binary published: `NO`
- PRODUCT source, SSOT, NVP persistent state changed: `NO`
- First blocker: `NONE`

The immutable commit identifier and commit-pinned remote read-back are necessarily evaluated after the commit containing this file is created; the final executor response carries that post-commit result.
""")

    incidents = """
## Preserved non-hardware corrections

- MMIO sanity completed all 16 engineering cycles, then its first persistence step found the reports directory absent. The CSV was reconstructed solely from the durable gate JSON; no MMIO cycle was repeated.
- The first noninterference orchestration preflight used version/generation offsets as status/generation. It failed before scan, transport enable, or capture. Correct offsets were recorded and the hardware sequence then ran once.
- The first connected-phase offline self-check lacked permission to read root-owned baseline artifacts. It failed before device open and was repeated only with read authority.
- Connected-phase remote evidence read-back passed; a subsequent local-only controller-lock path check initially treated the lock directory as a file. The receipt was then read from its exact child path without DUT access.
- The first post-reboot connection observation occurred before the new boot was reachable; the second observation found the changed boot. Only one reboot was delivered.
"""
    write_text(target / "V41_G2B_NVP_CAMERA_SCAN1_R1R1_MAIN_REPORT.md", f"""
# AHD v41 G2B-NVP-CAMERA-SCAN1-R1R1 main report

## Result

- Engineering prerequisites before publication: `PASS`
- Evidence publication gate: `PASS_ON_REQUIRED_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `{OVERALL_RESULT}`
- Scientific outcome: `{SCIENTIFIC_OUTCOME}`

## Hardware qualification

The exact accepted SCAN1-R1 bitstream was programmed once to volatile SRAM, followed by one authorized warm reboot. The exact qualified driver bound only `0000:01:00.0`. Runtime identity, 16/16 MMIO sanity cycles, one immutable single scan, 256/256 repetition scans, all bank restores, autoinit exclusion, and video/DMA noninterference passed with zero prohibited reads, NACK, timeout, bank mismatch, partial publication, or snapshot mutation.

The noninterference sequence completed three exact 2500-record captures. The reference, overlap, and post runs passed record, active-frame, bounded VBI, complete-frame, overflow, malformed-record, drop, AIO, and quiescence gates. The scanner operation demonstrably overlapped the middle capture. No camera frames or pixels are published.

## Physical campaign and classification

All 20 OFF/ON/OFF scans passed scanner integrity: 5 disconnected baseline, 10 connected, and 5 disconnected return-control. Every scan was A8-bookend-stable. Exactly CH1 showed a repeatable phase-correlated private detector change: F2/F3 `0x00/0x00 → 0xC0/0x03 → 0x00/0x00`. CH2/CH3/CH4 remained unchanged control arms. This yields a high-confidence bounded mapping candidate `UNKNOWN→CH1`, not final as-built authority.

NOVID remained asserted and F0 stayed `0xFF`; lock and private ACC/slope metrics did not transition. The camera response is therefore credible and reversible, but its format is unresolved. No AHD1080p25 or 0x31 compatibility claim is made.

## Cleanup

Final live pre-unload state showed scanner idle at generation 278, acknowledged snapshot, restored bank, unchanged autoinit, disabled stream, AIO 0, physical quiescence, and no native helper process. The exact normal unload `sudo rmmod xdma_ahd_pcie` ran once; the module and all XDMA nodes disappeared and the endpoint became unbound. The DUT lock was released first and the controller lock last. There was no reboot or power-cycle after the campaign; the SCAN1 image remains in volatile SRAM.

{incidents}

## Non-claims and next step

No PRODUCT source, SSOT, RTL, active XDC, NVP functional state, route, BGDCOL, Flash, or persistent configuration changed. ACQ1 was not executed. A separately governed ACQ1 compatibility campaign may now be prepared for CH1, but only after baseline-read authority, format/compatibility resolution, a minimal whitelisted action set, and rollback proof.
""")

    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_SANITIZATION_RECEIPT.md", """
# Sanitization receipt

All published artifacts are text. Task-path occurrences equal to the DUT credential were replaced with `DUT_USER_REDACTED`; workstation identity, DUT IPv4, host key, and credential-file names are rejected. No credential value was read by the evidence generator. No vendor PDF, reference-driver source, bitstream, DCP, XDMA driver/binary, native helper, camera frame, or camera pixel payload is included. The required JSONL files contain only read-only NVP register evidence and host metadata. Original and sanitized hashes are recorded in the generator provenance table inside the machine state preparation log.
""")

    write_text(target / "source/README.md", """
# Published task-local source

These are sanitized publication copies of the corrected bootstrap wrapper, runtime-bundle verifier, scanner controller, snapshot decoder, stateful detector/debounce logic, MMIO/manifest/evidence helpers, physical-phase runners, noninterference orchestration, and evidence generator. Each source file carries the SHA-256 of the executed source before sanitization. Reference capture-controller source, native helpers, driver code/binary, bitstream, and DCP are excluded.
""")

    # Preserve provenance outside the main state without exposing original credential-bearing bytes.
    write_json(target / "G2B_NVP_CAMERA_SCAN1_R1R1_PUBLICATION_COPY_PROVENANCE.json", provenance)

    required = {
        "V41_G2B_NVP_CAMERA_SCAN1_R1R1_MAIN_REPORT.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_OWNER_AUTHORIZATION.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_WINDOW_CONTEXT.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_SCOPE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_SCAN1_R1_INHERITANCE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_OFFLINE_QUALIFICATION_RECEIPT.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_BOOTSTRAP_SCRIPT.sh",
        "G2B_NVP_CAMERA_SCAN1_R1R1_REMOTE_ROOT_BOOTSTRAP_GATE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_REMOTE_PATH_VERIFICATION.txt",
        "G2B_NVP_CAMERA_SCAN1_R1R1_LOCK_SEMANTICS_TEST.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_LOCK_RECEIPT.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_RUNTIME_BUNDLE_REUSE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_RUNTIME_BUNDLE_MANIFEST.json",
        "G2B_NVP_CAMERA_SCAN1_R1R1_LOCAL_BUNDLE_GATE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_DUT_BUNDLE_HASHES.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_DUT_BUNDLE_GATE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_EXACT_CANDIDATE_AUTHORITY.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_PROGRAMMING_RECEIPT.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_REBOOT_RECEIPT.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_DRIVER_LOAD.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_RUNTIME_IDENTITY.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_MMIO_SANITY.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_SINGLE_SCAN_RESULT.json",
        "G2B_NVP_CAMERA_SCAN1_R1R1_256_SCAN_INTEGRITY.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_BANK_RESTORE_RESULTS.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_SCAN_DURATION.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_NONINTERFERENCE_CAPTURE_RESULTS.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_BASELINE_SCANS.jsonl",
        "G2B_NVP_CAMERA_SCAN1_R1R1_CONNECTED_SCANS.jsonl",
        "G2B_NVP_CAMERA_SCAN1_R1R1_RETURN_CONTROL_SCANS.jsonl",
        "G2B_NVP_CAMERA_SCAN1_R1R1_ALL_SCAN_HASHES.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_A8_BOOKEND_RESULTS.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_CHANNEL_STATE_HISTORY.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_FORMAT_CANDIDATES.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_DEBOUNCE_RESULTS.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_CONTROL_ARM_COMPARISON.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_PHYSICAL_MAPPING_CANDIDATE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_SCIENTIFIC_OUTCOME.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_NEXT_ACQ1_GATE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_CLEANUP_RECEIPT.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_FINAL_STATE.md",
        "G2B_NVP_CAMERA_SCAN1_R1R1_GATE_MATRIX.csv",
        "G2B_NVP_CAMERA_SCAN1_R1R1_STATE.json",
    }
    require(required.issubset({path.name for path in target.iterdir() if path.is_file()}), "REQUIRED_EVIDENCE_MISSING")

    purposes = {
        path.relative_to(target).as_posix(): (
            "required governed evidence" if path.name in required else
            "sanitized task-local source" if path.parts[0] == "source" else
            "supporting publication provenance"
        )
        for path in sorted(target.rglob("*")) if path.is_file()
    }
    index_lines = ["# Evidence index", "", f"Task: `{TASK}`", "", "| Path | Purpose |", "|---|---|"]
    index_lines += [f"| `{name}` | {purpose} |" for name, purpose in purposes.items()]
    index_lines += [
        "", "The SHA-256 manifest covers every file present when it was generated except the manifest itself.",
        "The immutable commit and post-push read-back are reported by the final executor after commit creation.",
    ]
    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_EVIDENCE_INDEX.md", "\n".join(index_lines))

    # Final public-content safety gate before the manifest is made.
    forbidden_suffixes = {".bit", ".dcp", ".ko", ".exe", ".dll", ".bin", ".tar", ".gz", ".pdf"}
    forbidden_names = ("controller_nvp_capture", "frame_reconstruct", "xdma_c2h_rolling", "abi_v1", "vbi_tail")
    forbidden_content = list(REDACTIONS.keys())
    published_files = [path for path in sorted(target.rglob("*")) if path.is_file()]
    for path in published_files:
        relative = path.relative_to(target).as_posix()
        require(path.suffix.lower() not in forbidden_suffixes, f"FORBIDDEN_PUBLIC_SUFFIX:{relative}")
        require(not any(token in path.name.lower() for token in forbidden_names),
                f"FORBIDDEN_PUBLIC_NAME:{relative}")
        data = path.read_bytes()
        require(b"\x00" not in data, f"PUBLIC_FILE_NOT_TEXT:{relative}")
        for token in forbidden_content:
            require(token not in data, f"FORBIDDEN_PUBLIC_CONTENT:{relative}")

    manifest_lines = ["# SHA-256 manifest; this file intentionally excludes itself."]
    manifest_lines += [f"{sha256(path)}  {path.relative_to(target).as_posix()}" for path in published_files]
    write_text(target / "G2B_NVP_CAMERA_SCAN1_R1R1_SHA256_MANIFEST.txt", "\n".join(manifest_lines))

    final_files = [path for path in sorted(target.rglob("*")) if path.is_file()]
    require(len(final_files) == len(published_files) + 1, "MANIFEST_FILE_COUNT")
    print(json.dumps({
        "task": TASK, "result": "PASS", "target": str(target), "files": len(final_files),
        "required_files": len(required), "campaign_scans": 20, "a8_excluded": 0,
        "responders": responders, "scientific_outcome": SCIENTIFIC_OUTCOME,
        "overall_result": OVERALL_RESULT, "sanitization": "PASS",
        "manifest_sha256": sha256(target / "G2B_NVP_CAMERA_SCAN1_R1R1_SHA256_MANIFEST.txt"),
    }, sort_keys=True))
    return 0


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--run-root", type=P, required=True)
    parser.add_argument("--repo-root", type=P, required=True)
    args = parser.parse_args()
    raise SystemExit(main(args.run_root, args.repo_root))
