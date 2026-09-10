#!/usr/bin/env python3
"""Offline contract test for the truthful DIAG1-R1 evidence projections."""

from __future__ import annotations

import csv
import importlib.util
import json
from pathlib import Path
import subprocess
import sys
import tempfile


SCRIPT = Path(__file__).with_name("extract_nvp_runtime_evidence.py")
SPEC = importlib.util.spec_from_file_location("runtime_evidence", SCRIPT)
assert SPEC is not None and SPEC.loader is not None
runtime = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(runtime)


def main() -> int:
    with tempfile.TemporaryDirectory() as temporary:
        root = Path(temporary)
        history = root / "session_status_history.csv"
        result = root / "scan-controller-result.json"
        coherence = root / "snapshot_coherence.csv"
        output = root / "output"
        fields = [
            "SessionID", "Round", "Channel", "Classification",
            "StableSamples", "TotalStatusSamples", "RawNOVID", "RawAGCLock",
            "RawComparatorLock", "RawHLock", "RawChannelStatus",
            "I2CTransactionCount", "I2CNackCountLow8", "I2CTimeoutCountLow8",
            "I2CBusRecoveryCountLow8", "I2CNackOverflow", "I2CTimeoutOverflow",
            "I2CBusRecoveryOverflow", "BGDCOL78", "BGDCOL79", "RouteReadback",
        ]
        rows = []
        for session in range(1, 17):
            round_number = (session - 1) // 4 + 1
            channel = runtime.ORDERS[round_number - 1][(session - 1) % 4]
            colors = runtime.COLOR_CODES_BY_ROUND[round_number - 1]
            rows.append({
                "SessionID": session, "Round": round_number, "Channel": channel,
                "Classification": "NO_VIDEO_STABLE", "StableSamples": 5,
                "TotalStatusSamples": 5, "RawNOVID": "0x0F",
                "RawAGCLock": "0x00", "RawComparatorLock": "0x00",
                "RawHLock": "0x00", "RawChannelStatus": "0x01",
                "I2CTransactionCount": 100 + session * 27,
                "I2CNackCountLow8": 0, "I2CTimeoutCountLow8": 0,
                "I2CBusRecoveryCountLow8": 0, "I2CNackOverflow": False,
                "I2CTimeoutOverflow": False, "I2CBusRecoveryOverflow": False,
                "BGDCOL78": f"0x{(colors[1] << 4) | colors[0]:02X}",
                "BGDCOL79": f"0x{(colors[3] << 4) | colors[2]:02X}",
                "RouteReadback": f"0x{channel - 1:02X}",
            })
        with history.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=fields)
            writer.writeheader()
            writer.writerows(rows)
        result.write_text(json.dumps({
            "original_baseline": {"route": 0, "bgcolor_78": 0x88,
                                  "bgcolor_79": 0x88},
            "final_state": {"route": 0, "bgcolor_78": 0x88,
                            "bgcolor_79": 0x88,
                            "i2c_transaction_count": 540,
                            "i2c_nack_count": 0, "i2c_timeout_count": 0,
                            "i2c_bus_recovery_count": 0},
        }), encoding="utf-8")
        with coherence.open("w", encoding="utf-8", newline="") as handle:
            writer = csv.DictWriter(handle, fieldnames=[
                "Phase", "Result", "ExpectedSession", "TimestampNs"])
            writer.writeheader()
            writer.writerows({"Phase": "PRE_CAPTURE", "Result": "PASS",
                              "ExpectedSession": session,
                              "TimestampNs": 1_000_000 + session}
                             for session in range(1, 17))

        subprocess.run([
            sys.executable, str(SCRIPT), "--status-history", str(history),
            "--scan-result", str(result), "--snapshot-coherence", str(coherence),
            "--output-root", str(output),
        ], check=True, capture_output=True, text=True)

        status = runtime.read_csv(
            output / "G2B_NVP_VIDEO_DIAG1_R1_STATUS_SAMPLES.csv")
        transactions = runtime.read_csv(
            output / "G2B_NVP_VIDEO_DIAG1_R1_I2C_TRANSACTION_LOG.csv")
        writes = runtime.read_csv(
            output / "G2B_NVP_VIDEO_DIAG1_R1_NVP_WRITE_LEDGER.csv")
        reads = runtime.read_csv(
            output / "G2B_NVP_VIDEO_DIAG1_R1_NVP_READBACK_LEDGER.csv")
        scope = json.loads((output /
            "G2B_NVP_VIDEO_DIAG1_R1_RUNTIME_EVIDENCE_SCOPE.json").read_text())

        assert len(status) == 16
        assert all(row["EquivalentConsecutiveSamplesProven"] == "5"
                   for row in status)
        assert all(row["IndividualRawSampleHistoryRetained"] == "NO"
                   for row in status)
        assert len(transactions) == 17
        assert all(row["PerTransactionCommandsRetained"] == "NO"
                   for row in transactions)
        assert all(parse_int >= 0 for parse_int in
                   (int(row["AcceptedTransactionDelta"]) for row in transactions))
        assert len(writes) == 27  # 8 BGDCOL + 16 route + 3 restore receipts.
        assert all(row["PhysicalTransactionRecordRetained"] == "NO"
                   for row in writes)
        assert len(reads) == 107  # 8 BGDCOL + 16 route + 80 status + 3 restore.
        assert all(row["PhysicalTransactionIDsRetained"] == "NO"
                   for row in reads)
        assert scope["individual_raw_status_sample_history_retained"] is False
        assert scope["per_transaction_event_history_retained"] is False

    print("PASS DIAG1_R1_TRUTHFUL_RUNTIME_EVIDENCE_PROJECTIONS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
