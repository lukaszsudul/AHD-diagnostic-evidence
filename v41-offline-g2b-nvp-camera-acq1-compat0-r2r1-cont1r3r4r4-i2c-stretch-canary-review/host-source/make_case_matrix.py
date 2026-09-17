"""Deterministic, bounded offline stimulus grid; no hardware interfaces."""
import csv
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "contracts" / "CASE_MATRIX.csv"
FIELDS = ["case_id", "op_read", "stretch_phase", "stretch_bit",
          "extra_cycles", "edge_phase_ns", "scl_input_delay_ns",
          "sda_input_delay_ns", "ack_mode", "ack_lead_ns",
          "early_release_ns", "stratum", "declared_class"]
rows = []
seen = set()

def add(read=0, phase=-1, bit=-1, extra=0, edge=0, scl=0, sda=0,
        ack=0, lead=2000, early=0, stratum="clean", cls="GENERIC_VALID_DIGITAL"):
    values = (read, phase, bit, extra, edge, scl, sda, ack, lead, early)
    if values in seen:
        return
    seen.add(values)
    rows.append(dict(zip(FIELDS, (len(rows)+1, *values, stratum, cls))))

# Clean transactions, complete read including repeated START and terminal NACK.
add()
add(read=1)
# Negative controls: the simulator slave genuinely withholds the selected ACK.
for read, phase in [(0,0),(1,1),(0,3),(1,4)]:
    add(read=read, phase=phase, ack=1, stratum="absent_ack_control",
        cls="INTENTIONALLY_INVALID_NO_ACK")

durations = [0,1,4,16,64,256,625,1000,1200,1240,1248,1249,
             1250,1251,1252,1260,1300,2500]
for phase, read in [(3,0),(1,1)]:
    for extra in durations:
        add(read=read, phase=phase, extra=extra, edge=8,
            stratum="full_ack_duration",
            cls="GENERIC_VALID_DIGITAL" if extra < 1200 else "STRETCH_TIMEOUT_SENSITIVITY")

# Every transmitted bit of 0x05 plus its ACK: no, mid, near, over limit.
for bit in range(8):
    for extra in [0,64,1248,1260]:
        add(phase=2, bit=bit, extra=extra, edge=4,
            stratum="all_data_bits", cls="GENERIC_VALID_DIGITAL" if extra < 1200 else "STRETCH_TIMEOUT_SENSITIVITY")
# Register-byte bit preceding its ACK; controls address ACKs separately.
for bit in [2,6]:
    add(read=1, phase=5, bit=bit, extra=256, edge=12,
        stratum="register_bit_before_ack")
for read, phase in [(0,0),(1,4)]:
    for extra in [0,256,1248]:
        add(read=read, phase=phase, extra=extra, edge=8,
            stratum="address_ack_control",
            cls="GENERIC_VALID_DIGITAL" if extra < 1200 else "STRETCH_TIMEOUT_SENSITIVITY")

# Independent asynchronous phase and input-recognition skew.
for read, phase in [(0,3),(1,1)]:
    for edge in [1,4,8,12,15]:
        for extra in [256,1248]:
            for scl,sda in [(0,0),(32,0),(0,32),(128,500)]:
                add(read=read, phase=phase, extra=extra, edge=edge,
                    scl=scl, sda=sda, stratum="phase_skew",
                    cls="GENERIC_VALID_DIGITAL" if extra == 256 else "STRETCH_TIMEOUT_SENSITIVITY")

# ACK setup around the conservative 1250 ns source footnote. Because the
# master owns a ~20 us LOW before release, late assertion is not certified
# by tVD;ACK; these are explicit sensitivity/invalid-timing probes.
for read, phase in [(0,3),(1,1)]:
    for lead in [2000,1282,1266,1250,1234,32,16,0]:
        for scl in [0,128]:
            add(read=read, phase=phase, extra=256, edge=8,
                scl=scl, ack=2, lead=lead, stratum="late_ack_setup",
                cls="TIMING_STRESS_TVD_ACK_UNVERIFIED")

# Digital release-to-high sensitivity, not analog rise-time claims.
for read, phase in [(0,3),(1,1)]:
    for scl in [0,32,128,500,1000,2000]:
        for late in [False, True]:
            add(read=read, phase=phase, extra=256, edge=8,
                scl=scl, sda=32 if scl else 0, ack=2 if late else 0,
                lead=1250 if late else 2000, stratum="rise_recognition",
                cls="TIMING_STRESS_TVD_ACK_UNVERIFIED" if late else "DIGITAL_SENSITIVITY_ANALOG_UNVERIFIED")

for read, phase in [(0,3),(1,1)]:
    for early in [16,128]:
        add(read=read, phase=phase, extra=256, edge=8, ack=3,
            early=early, stratum="early_release_control",
            cls="INTENTIONALLY_INVALID_ACK_HOLD")

assert len(rows) <= 4096
assert len({r["case_id"] for r in rows}) == len(rows)
with OUT.open("w", encoding="utf-8", newline="") as f:
    writer = csv.DictWriter(f, fieldnames=FIELDS, lineterminator="\n")
    writer.writeheader()
    writer.writerows(rows)
print(f"FROZEN_CASE_COUNT={len(rows)}")
