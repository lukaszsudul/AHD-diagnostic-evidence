"""Verify private W4 data and build the sanitized, self-contained public report."""
import argparse
import csv
import hashlib
import json
import shutil
from collections import Counter, defaultdict
from pathlib import Path


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest().upper()


def read(path):
    return json.loads(path.read_text(encoding="utf-8"))


def write_json(path, obj):
    path.write_text(json.dumps(obj, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8", newline="\n")


def write_csv(path, columns, rows):
    with path.open("w", encoding="utf-8", newline="") as f:
        writer = csv.DictWriter(f, fieldnames=columns, lineterminator="\n")
        writer.writeheader()
        writer.writerows(rows)


def check(condition, message):
    if not condition:
        raise RuntimeError(message)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("root", type=Path)
    ap.add_argument("output", type=Path)
    args = ap.parse_args()
    root, out = args.root, args.output
    check(not out.exists() or all(f.is_file() for f in out.iterdir()), "public output directory has unexpected children")
    private = root / "campaign" / "byte-exact"
    manifest_file = root / "campaign" / "W4_PRIVATE_RAW_MANIFEST.json"
    manifest = read(manifest_file)
    check(manifest["data_files"] == 532 and len(manifest["files"]) == 532, "manifest count")
    for item in manifest["files"]:
        check(item["path"].startswith("campaign/"), "manifest path")
        name = Path(item["path"]).name
        f = private / ("state-after-block16.json" if name == "state.json" else name)
        check(f.is_file() and f.stat().st_size == item["size_bytes"] and digest(f) == item["sha256"], f"byte identity {f.name}")
    check(digest(manifest_file) == "5259A9D6C4E6CB811D986CC6212CA4ACE28881BAC9451C3E5F4529CA1ADFAFD9", "DUT manifest identity")
    recovery = read(root / "campaign" / "byte-exact-recovery-receipt.json")
    check(recovery["byte_identical_to_dut_manifest"] is True, "copy recovery")
    plan = read(root / "host" / "bundle-r1" / "W4_PLAN.json")
    check(digest(root / "host" / "bundle-r1" / "W4_PLAN.json") == "5FD3F3A27BFBEE24341FC7C095429A43541CB941F6B23C2E2C3F2FB84F8AE47D", "frozen plan")
    check(len(plan["blocks"]) == 16 and plan["max_ab_scans"] == 256, "plan shape")
    state = read(private / "state-after-block16.json")
    check(state["ab_attempted"] == state["ab_complete"] == 256 and state["blocks_completed"] == 16 and state["hard_stop"] is False, "final campaign state")
    control = read(private / "control.json")
    check(control["complete"] and control["attempt_id"] == 1 and control["generation_after"] == 1 and control["regaddr_nack_events"] == 0 and control["bank_restore"] == "PASS", "control")
    check(digest(private / "control.bin") == control["complete_raw_sha256"], "control raw")
    block_rows, scan_rows, error_rows = [], [], []
    totals = defaultdict(lambda: Counter())
    all_durations = defaultdict(list)
    for block in plan["blocks"]:
        i, mode, replica = block["block_index"], block["mode"], block["replica"]
        summary = read(private / f"block-{i:02d}-summary.json")
        check(summary["block_index"] == i and summary["mode"] == mode and summary["replica"] == replica, f"block {i} identity")
        check(summary["attempted"] == summary["complete"] == 16 and not summary["time_budget_incomplete"], f"block {i} completion")
        check(summary["first_entry_read_opportunities"] == 1312, f"block {i} opportunities")
        check(summary["regaddr_nack_events"] == summary["other_recovered_causes"] == summary["scans_with_retries"] == 0, f"block {i} errors")
        check(summary["end_retained"]["status"] == (8 if mode == "A" else 28), f"block {i} mode status")
        block_rows.append(dict(block_index=i, replica=replica, mode=mode, block_id=summary["block_id"], attempted=16, complete=16,
                               first_entry_read_opportunities=1312, regaddr_nack_events=0, rate_per_1000=0, other_recovered_causes=0,
                               scans_with_retries=0, bank_error=0, time_budget_incomplete=False))
        for j in range(1, 17):
            f = private / f"block-{i:02d}-scan-{j:02d}.json"
            rec = read(f)
            ab_index = (i - 1) * 16 + j
            check(rec["ab_index"] == ab_index and rec["attempt_id"] == ab_index + 1, f"scan {ab_index} attempt")
            check(rec["generation_before"] == ab_index and rec["generation_after"] == ab_index + 1, f"scan {ab_index} generation")
            check(rec["mode"] == mode and rec["block_id"] == summary["block_id"] and rec["complete"], f"scan {ab_index} mode")
            check(rec["w3a_status"] == (8 if mode == "A" else 28) and rec["w3a_retained"]["scan_attempt_id"] == ab_index + 1, f"scan {ab_index} W3a")
            check(rec["w3a_retained"]["primary"] is None and rec["w3a_retained"]["cleanup"] is None and rec["w3a_retained"]["rejected_write_count"] == 0, f"scan {ab_index} bank")
            check(rec["bank_restore"] == "PASS" and rec["entry_count"] == 82 and rec["group_count"] == 10 and rec["transaction_count"] == 105, f"scan {ab_index} shape")
            check(rec["first_entry_read_opportunities"] == 82 and rec["regaddr_nack_events"] == 0 and rec["retried_entry_count"] == 0 and rec["other_recovered_causes"] == [] and rec["events"] == [], f"scan {ab_index} events")
            check(rec["a8_pre"] == rec["a8_post"] == 15 and rec["projection"]["00:F4"] == 144 and rec["projection"]["00:F5"] == 1, f"scan {ab_index} projection")
            raw = private / f"block-{i:02d}-scan-{j:02d}.bin"
            check(raw.stat().st_size == rec["complete_raw_bytes"] == 4200 and digest(raw) == rec["complete_raw_sha256"], f"scan {ab_index} raw")
            ticks = rec["fpga_end_tick"] - rec["fpga_start_tick"]
            check(ticks > 0, f"scan {ab_index} ticks")
            all_durations[mode].append(ticks)
            scan_rows.append(dict(ab_index=ab_index, block_index=i, replica=replica, mode_planned=mode, mode_effective=mode,
                                  block_id=rec["block_id"], scan_attempt_id=rec["attempt_id"], generation_before=rec["generation_before"],
                                  generation_after=rec["generation_after"], complete=1, first_entry_read_opportunities=82,
                                  regaddr_nack_events=0, other_recovered_causes=0, retried_entries=0, bank_restore="PASS",
                                  entry_count=82, group_count=10, transaction_count=105, fpga_ticks=ticks,
                                  fpga_duration_ms=f"{ticks / 62500:.6f}", host_start_ns=rec["host_start_ns"], host_collected_ns=rec["host_collected_ns"],
                                  raw_sha256=rec["complete_raw_sha256"], legacy_raw_sha256=rec["legacy_raw_sha256"],
                                  telemetry_raw_sha256=rec["telemetry_raw_sha256"], w3a_status=rec["w3a_status"], rejected_write_count=0))
            totals[(replica, mode)]["scans"] += 1
            totals[(replica, mode)]["opportunities"] += 82
    check(len(scan_rows) == 256 and len(error_rows) == 0, "A/B counts")
    for replica in ("I", "II"):
        for mode in ("A", "B"):
            check(totals[(replica, mode)]["scans"] == 64 and totals[(replica, mode)]["opportunities"] == 5248, "replica balance")
    check(set(all_durations["A"]) == {10499618} and set(all_durations["B"]) == {10705868}, "FPGA duration distribution")
    cleanup = read(root / "deployment" / "dut-receipts" / "cleanup" / "normal_scan_cleanup.json")
    unload = read(root / "deployment" / "dut-receipts" / "cleanup" / "driver_unload.json")
    dut_lock = read(root / "deployment" / "dut-receipts" / "cleanup" / "dut_lock_release.json")
    ctrl_lock = read(root / "authority" / "CONTROLLER_LOCK_RELEASE.json")
    preflight = read(root / "deployment" / "dut-receipts" / "deployment" / "runtime_preflight.json")
    dut_bundle = read(root / "deployment" / "dut-receipts" / "deployment" / "bundle_gate_r1.json")
    driver = read(root / "deployment" / "dut-receipts" / "deployment" / "exact_driver_load.json")
    check(cleanup["result"] == unload["result"] == preflight["result"] == dut_bundle["result"] == driver["result"] == "PASS", "system gates")
    check(cleanup["extra_oneshot"] == 0 and cleanup["scan_attempt_id"] == cleanup["published_generation"] == 257, "cleanup no extra scan")
    check(cleanup["after"]["w3a_status"] == 0 and cleanup["after"]["stream_enable"] == 0 and cleanup["rejected_write_count_after"] == 0, "cleanup idle/off")
    check(unload["ahd_driver_after"] is None and unload["target_nodes_after"] == [] and dut_lock["state"].startswith("RELEASED") and ctrl_lock["state"].startswith("RELEASED"), "released ownership")
    check(driver["module_sha256"] == "E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77", "exact driver")
    check(preflight["identities"]["git_sha_words"] == ["70266F0B", "90C6FC6A", "853495EB", "A1D526B2", "85FD7286"], "runtime source identity")
    check(preflight["identities"]["build_flags"] == 2050 and preflight["identities"]["slot_count"] == 2, "runtime flags/slots")
    check(preflight["scan1_mmio_sanity"] == preflight["acq_mmio_sanity"] == 16, "MMIO sanity")
    # Build only sanitized summaries and hashes; raw snapshots remain private.
    out.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(root / "host" / "bundle-r1" / "W4_PLAN.json", out / "W4_PLAN.json")
    shutil.copyfile(manifest_file, out / "W4_PRIVATE_RAW_MANIFEST.json")
    shutil.copyfile(root / "host" / "bundle-r1" / "w4_coordinator.py", out / "w4_coordinator.py")
    shutil.copyfile(Path(__file__), out / "analyze_w4.py")
    write_csv(out / "W4_BLOCKS.csv", list(block_rows[0]), block_rows)
    write_csv(out / "W4_SCAN_SUMMARY.csv", list(scan_rows[0]), scan_rows)
    write_csv(out / "W4_ERROR_EVENTS.csv", ["ab_index", "block_index", "mode", "entry_index", "bank", "register", "group", "position", "raw_status", "first_cause", "retry_result", "final_valid"], error_rows)
    write_json(out / "W4_STATE.json", state)
    write_json(out / "W4_LOCAL_BUNDLE_MANIFEST.json", read(root / "host" / "bundle-r1" / "W4_BUNDLE_MANIFEST.json"))
    write_json(out / "W4_DUT_BUNDLE_GATE.json", dut_bundle)
    write_json(out / "W4_RUNTIME_AND_MAPPING_RECEIPT.json", {
        "result": "PASS", "endpoint": "10.132.1.111:22", "hostname": "VCDE-DUT-1", "machine_id": "0e90f50d9465492b80258da5658446f8",
        "ssh_host_key_sha256": "yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8", "boot_before": "e9656f6c-dd41-4500-95cc-9dc90ef9b69d",
        "boot_after": "0a86ba7c-b382-4c90-b2bd-cce33b8cf56b", "bdf": "0000:01:00.0", "ids": "10ee:7011 / 10ee:0007",
        "link": "PCIe Gen2 x1", "parent": "0000:00:01.1", "user_node": "/dev/xdma0_user", "user_dev_t": "511:0",
        "c2h_node": "/dev/xdma0_c2h_0", "c2h_dev_t": "511:36", "c2h_transfer_count": 0,
        "driver": driver, "runtime_preflight": preflight,
        "protected_function_initial": "ABSENT", "protected_function_final": "ABSENT", "protected_function_ids": "10ee:7021 / 10ee:f0a1"
    })
    write_json(out / "W4_DEPLOYMENT_RECEIPT.json", {
        "runtime_path": "PROGRAMMED_EXACT_RELEASE", "bitstream_size_bytes": 2192144,
        "bitstream_sha256": "8B6402C776AAF6B2D6E0F4453479B75462516AB79A9FE534257CD5339B95A51B",
        "jtag_target": "localhost:3121/xilinx_tcf/Xilinx/80802026a98b01", "part": "xc7a35tcsg325-2", "idcode": "0362D093",
        "sram_programming_attempts": 1, "sram_programming_budget": 1, "done_after": 1,
        "programming_start_utc": "2026-09-18T07:31:57Z", "programming_return_utc": "2026-09-18T07:32:04Z",
        "warm_reboots": 1, "warm_reboot_budget": 1, "cold_starts": 0, "flash_programming": 0,
        "autoinit_completion": "DONE_IDLE_NO_ACQ_ERROR", "autoinit_nack_count": "NOT_EXPOSED/NOT_INDEPENDENTLY_MEASURED"
    })
    write_json(out / "W4_CLEANUP_RECEIPT.json", {
        "normal_scan_cleanup": cleanup, "driver_unload": unload, "dut_lock_release": dut_lock,
        "controller_lock_release": {"state": ctrl_lock["state"], "released_utc": ctrl_lock["released_utc"]},
        "bank_restore": "PASS_ALL_257_COMPLETE_SCANS", "aio": "0_BY_NO_C2H_OPEN", "final_reboot": 0,
        "experimental_functional_nvp_writes": 0, "dma_transfers": 0, "camera_frames": 0
    })
    write_json(out / "W4_PRECHECK_CORRECTION.json", {
        "first_interrupted_gate": "HOST_PREFLIGHT_SOURCE_IDENTITY_FALSE_REJECT",
        "cause": "task-local host compared capability bits 15:0 with slot count 2; live C3 capabilities were 0x00031002 and low 8 bits give slot count 2",
        "raw_preflight_error": "C3_RUNTIME_SOURCE_IDENTITY_MISMATCH", "hardware_scan_starts_at_interruption": 0,
        "correction": "one task-local closed bundle R1, C3 seven-file subset unchanged; full capability word and low-eight-bit slot count verified",
        "corrected_gate": "PASS", "campaign_hard_stop": False, "hardware_error": False,
        "private_original_receipt_sha256": digest(root / "deployment" / "dut-receipts" / "hard-stop" / "W4_HARD_STOP_RECEIPT.json")
    })
    write_json(out / "W4_HARD_STOP_RECEIPT.json", {
        "classification": "HOST_PREFLIGHT_FALSE_REJECT_PRE_CAMPAIGN_CORRECTED_ONCE",
        "stage": "preflight", "reported_error": "C3_RUNTIME_SOURCE_IDENTITY_MISMATCH",
        "exact_failed_check": "task-local host compared capability bits 15:0 against slot count 2",
        "raw_runtime_capability_word": "0x00031002", "actual_slot_count_from_low_8_bits": 2,
        "scan_starts_before_correction": 0, "campaign_hard_stop": False,
        "raw_first_hardware_failure_cause": "NONE", "completion_hardware_failure_cause": "NONE",
        "corrected_preflight": "PASS", "private_full_receipt_sha256": digest(root / "deployment" / "dut-receipts" / "hard-stop" / "W4_HARD_STOP_RECEIPT.json")
    })
    write_json(out / "W4_LOCAL_COPY_RECOVERY_RECEIPT.json", {
        "first_copy_issue": "Windows os.open without O_BINARY expanded LF bytes in first local copies",
        "recovery": "re-materialized from previously persisted, byte-exact checkpoint transfers; no additional scan or hardware run",
        "private_recovery_receipt_sha256": digest(root / "campaign" / "byte-exact-recovery-receipt.json"),
        "dut_manifest_files_verified": 532, "byte_identical_to_dut_manifest": True,
        "analysis_source": "campaign/byte-exact only; original campaign copies excluded"
    })
    write_json(out / "W4_GATE_MATRIX.json", {
        "engineering_gate": "PASS", "scientific_outcome": "INCONCLUSIVE_LOW_EVENTS_OR_INCOMPLETE", "overall": "PASS_W4_BOUNDED_AB_COMPLETED",
        "evidence_publication_at_report_build": "PENDING_REMOTE_READBACK", "ssot_revision_start_end": [9, 9], "ssot_tree_start_end": ["24e8b5e3f7b151bebe6b8da5dc102d734037ee48"] * 2,
        "authority": "PASS", "exact_bitstream_activation": "PASS", "local_dut_bundle": "PASS/PASS", "runtime_mapping": "PASS",
        "control": "PASS_CLEAN", "ab": "256/256", "raw_data": "532/532_BYTE_IDENTICAL_TO_DUT_MANIFEST", "cleanup": "PASS",
        "hard_stop_during_campaign": "NONE", "behavioral_assurance": "LIMITED_STATIC_REVIEW_AND_IDENTIFIED_HISTORY",
        "ten_thousand_scan_qualification": "NOT_RUN_NOT_WAIVED", "xsims": 0,
        "new_synth_opt_place_phys_opt_route_bitgen": [0, 0, 0, 0, 0, 0]
    })
    write_csv(out / "W4_GATE_MATRIX.csv", ["gate", "status", "evidence"], [
        {"gate": "SSOT rev9 and manifest", "status": "PASS", "evidence": "18/18 local hashes; pinned project-current-state tree"},
        {"gate": "Exact C3 image", "status": "PASS", "evidence": "size/SHA; sole JTAG SRAM program; runtime Git SHA"},
        {"gate": "Host bundle", "status": "PASS", "evidence": "local and DUT R1 42/42; C3 7/7 unchanged"},
        {"gate": "DUT mapping and protected function", "status": "PASS", "evidence": "AHD 0000:01:00.0; protected absent initial/final"},
        {"gate": "Control", "status": "PASS_CLEAN", "evidence": "1/1; 82/82; bank restore PASS"},
        {"gate": "A/B", "status": "PASS", "evidence": "16/16 blocks; 256/256 scans; 128 per arm"},
        {"gate": "Byte identity", "status": "PASS", "evidence": "532/532 DUT manifest files verified"},
        {"gate": "Cleanup", "status": "PASS", "evidence": "idle, stream OFF, driver and locks released"},
        {"gate": "Scientific effect", "status": "INCONCLUSIVE_LOW_EVENTS_OR_INCOMPLETE", "evidence": "zero recovered REGADDR_NACK in either arm"},
        {"gate": "Evidence publication", "status": "PENDING_REMOTE_READBACK", "evidence": "separate final receipt after push"},
    ])
    rows = ["| Replica | OFF scans | ON scans | OFF events / opportunities | ON events / opportunities | OFF/ON per 1000 |",
            "|---|---:|---:|---:|---:|---:|",
            "| I | 64 | 64 | 0/5248 | 0/5248 | 0 / 0 |",
            "| II | 64 | 64 | 0/5248 | 0/5248 | 0 / 0 |",
            "| Total | 128 | 128 | 0/10496 | 0/10496 | 0 / 0 |"]
    decision = """# W4 A/B decision

**Scientific outcome: `INCONCLUSIVE_LOW_EVENTS_OR_INCOMPLETE`.** The complete comparable pilot contains no recovered first-attempt REGADDR_NACK in either arm. The observed rate difference is 0 per 1000 first entry-read opportunities; B/A is undefined because A=0. This does not establish a pause effect, a repair, or absence of an effect.

""" + "\n".join(rows) + """

All 16 blocks completed 16/16 scans. Each scan evaluated 82 first entry reads and recorded 105 transactions. Other recovered causes, retries, and bank select/verify/restore/cleanup errors were all zero. The control scan is excluded from A/B denominators. Raw first-cause/event rows remain empty because no such events were observed; successful raw snapshots remain private with published hashes.

FPGA duration per scan: OFF 167.993888 ms, ON 171.293888 ms, difference +3.300000 ms. The duration difference is consistent with 11 successful bank writes and a 18,750-cycle pause at 62.5 MHz. It is not a measurement of analog SCL rise, SCL_WAIT_MAX, ACK phase, or physical cause. Both replicas ran on one card in one post-activation boot.

`SCL_WAIT_MAX=NOT_COLLECTED`; `ACK_PHASE_WAIT=NOT_COLLECTED`. The 10,000-scan gate is `NOT_RUN_NOT_WAIVED`.
"""
    (out / "W4_AB_DECISION.md").write_text(decision, encoding="utf-8", newline="\n")
    authority = """# W4 authority and Owner scope

Task `CONT1R3R4R7-W4-C3-PNR1-AB` was authorized by the Owner for bounded DUT admission, exact C3-PNR1 SRAM activation, one control scan, 16 × 16 OFF/ON scans, cleanup, and publication. This did not authorize MODE1, functional NVP configuration, DMA, capture, Flash, a new FPGA build, XSim, driver modification, or camera configuration.

Project-current-state revision was 9 at start and end. Its pinned tree was `24e8b5e3f7b151bebe6b8da5dc102d734037ee48`; all 18 local SSOT manifest entries matched before publication. SSOT and prior evidence are unchanged by the W4 evidence commit.

Source candidate C3 commit `70266f0b90c6fc6a853495eba1d526b285fd7286`, tree `5f2bd8377985406b45433418b20be8993399bcb6`; source revision budget 4/4 used unchanged. Release evidence commit `c23143d37c6518e6f7859ecebf4a4eb0f339f55b`. Inherited final LUT 19995/20384 and WNS +0.102 ns belong to C3 release, not a new W4 implementation result. `BEHAVIORAL_ASSURANCE=LIMITED_STATIC_REVIEW_AND_IDENTIFIED_HISTORY`.

Exact bitstream: `AHD_v41_W3A_C3_PNR1_DIAGNOSTIC.bit`, 2,192,144 bytes, SHA-256 `8B6402C776AAF6B2D6E0F4453479B75462516AB79A9FE534257CD5339B95A51B`. Signed DCP provenance SHA-256 `A99EDFE4DF21A3607EC1C31464AD4A03EC6717FCBABBC2979FDA4DFF48E188A5`. Released C3 host manifest SHA-256 `E2F16444A1B6DA59603774A79AE24D60541151DF05D3CD976BE87915BAE79478` and seven released files retained exact bytes. C3 contract SHA-256 `7F2A9647EF60D360B9884E57F6FAE16BCAFC4DD8F60D592CE0A44D728FA67D39`; status-bit1 erratum SHA-256 `B3764AC42EE2A26DA0202FF50F906E087B96A7A6E017DBCA020DF52849990689` applied.
"""
    (out / "W4_AUTHORITY_AND_OWNER_SCOPE.md").write_text(authority, encoding="utf-8", newline="\n")
    report = """# AHD v41 W4 exact C3-PNR1 hardware A/B

**Engineering gate: PASS. Evidence publication: PENDING_REMOTE_READBACK. Overall: `PASS_W4_BOUNDED_AB_COMPLETED`. Scientific outcome: `INCONCLUSIVE_LOW_EVENTS_OR_INCOMPLETE`.**

The exact released C3-PNR1 bitstream was programmed once to the AHD card's SRAM. The post-activation runtime Git SHA, build flags, SCAN1, ACQ, telemetry, and W3a identities matched. One planned warm reboot occurred; no cold start, Flash program, new build, or XSim run occurred. The qualified AHD driver was loaded once and normally unloaded after the measurement. The protected `10ee:7021 / 10ee:f0a1` function was absent at entry and exit.

The control scan completed cleanly (1/1, 82/82 entry reads, 105 transactions, bank restore PASS). The frozen ABBA/BAAB plan completed 16/16 blocks and 256/256 scans, including 128 OFF and 128 ON scans. Each arm yielded 0 recovered first-attempt REGADDR_NACK from 10,496 actual first entry-read opportunities. The two 64/64 scan replica windows were each zero/zero. No retry, other recovered cause, or bank select/verify/restore/cleanup error was recorded. Details and the formal interpretation are in `W4_AB_DECISION.md`.

The C3 W3a status-bit1 erratum was applied: safe idle was checked using SCAN1, ACQ, W3a lockout and stream state together. The W3a controller showed locked OFF (`8`) or locked effective ON (`28`) as planned, with zero rejected-write increment. After the last ACK and block close, configuration was set OFF in safe idle; W3a status was `0`, SCAN1 status `0x11`, ACQ status `0x00800011`, stream OFF, task-owned AIO `0_BY_NO_C2H_OPEN`, and the scan attempt/generation stayed at 257. No extra scan or final reboot occurred. Driver and task locks were released. The C3 image remains in SRAM; this report does not claim earlier NVP state was restored.

**Evidence handling.** A task-local preflight host check initially compared too many capability bits with slot count and falsely rejected the exact live runtime (`0x00031002`). It stopped before any scan; a read-only identity inspection established the cause. One closed host bundle R1 corrected that check while retaining the seven C3 release files byte-identically. Both local and DUT 42-file bundle gates then passed. Separately, the first Windows checkpoint materialization expanded LF bytes. The retained, byte-exact checkpoint transfers were re-materialized in binary mode. All 532 final DUT manifest files match size and SHA-256 in the private `campaign/byte-exact` analysis source. The first local copies were excluded. Neither correction caused a second firmware program or hardware campaign.

Autoinit reached done/idle with no ACQ error; its NACK count is `NOT_EXPOSED/NOT_INDEPENDENTLY_MEASURED`. Hardware ERR_CNT is not exposed; event totals here are host-derived from frozen telemetry. SCL_WAIT_MAX and ACK_PHASE_WAIT were not collected. The observed FPGA duration difference does not prove analog behavior or pause causality. The 10,000-scan qualification remains `NOT_RUN_NOT_WAIVED`. No experimental functional NVP writes, C2H DMA transfer, or camera frame occurred (0/0/0).

Next step toward a first frame: a separate Owner decision and scoped authorization for single-channel camera configuration and real-frame acquisition, with the unresolved low-event A/B effect and 10,000-scan gate stated explicitly. No MODE1 or capture follows under W4.
"""
    (out / "W4_MAIN_REPORT.md").write_text(report, encoding="utf-8", newline="\n")
    index = """# W4 evidence index

- `W4_MAIN_REPORT.md`: gates, runtime, measurement, cleanup, limits.
- `W4_AUTHORITY_AND_OWNER_SCOPE.md`: governing scope and pinned release identities.
- `W4_PLAN.json`: frozen 16-block plan.
- `W4_LOCAL_BUNDLE_MANIFEST.json`, `W4_DUT_BUNDLE_GATE.json`: closed host bundle and DUT gate.
- `W4_DEPLOYMENT_RECEIPT.json`, `W4_RUNTIME_AND_MAPPING_RECEIPT.json`: SRAM program, runtime and target identity.
- `W4_BLOCKS.csv`, `W4_SCAN_SUMMARY.csv`, `W4_ERROR_EVENTS.csv`: all blocks, all 256 scan summaries, and recovered event rows (header only because none occurred).
- `W4_AB_DECISION.md`: denominator-correct effect classification.
- `W4_HARD_STOP_RECEIPT.json`, `W4_PRECHECK_CORRECTION.json`, `W4_LOCAL_COPY_RECOVERY_RECEIPT.json`: initial host preflight false reject, bounded correction, and retained evidence identity.
- `W4_CLEANUP_RECEIPT.json`, `W4_STATE.json`, `W4_GATE_MATRIX.csv`, `W4_GATE_MATRIX.json`: final state and gate receipts.
- `W4_PRIVATE_RAW_MANIFEST.json`: exact DUT file paths, byte sizes and hashes for all 532 private data files; raw snapshots stay on private controller storage.
- `w4_coordinator.py`, `analyze_w4.py`: task-local coordinator and report/verification source; no credentials or vendor materials.
- `SHA256_MANIFEST.txt`: hashes of every public file except itself.

The immutable report carries `PENDING_REMOTE_READBACK`. The final publication receipt is held beside the private task root after independent remote read-back of the exact commit.
"""
    (out / "W4_EVIDENCE_INDEX.md").write_text(index, encoding="utf-8", newline="\n")
    lines = [f"{digest(f)}  {f.name}" for f in sorted(out.iterdir()) if f.is_file() and f.name != "SHA256_MANIFEST.txt"]
    (out / "SHA256_MANIFEST.txt").write_text("\n".join(lines) + "\n", encoding="ascii", newline="\n")
    print(json.dumps({"result": "PASS", "public_files": len(lines) + 1, "private_files_verified": 532, "blocks": 16, "ab_scans": len(scan_rows), "out": str(out)}, indent=2))


if __name__ == "__main__":
    main()
