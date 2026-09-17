"""Run preregistered XSim cases and check resolved pins independently.

This task-owned program has no network, DUT, driver, MMIO, or hardware path.
"""
import csv
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GRID = ROOT / "simulation" / "grid"
LOGS = ROOT / "logs" / "grid"
MATRIX = ROOT / "contracts" / "CASE_MATRIX.csv"
RESULTS = ROOT / "reports" / "CASE_RESULTS.csv"
X_SIM = Path(r"C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat")
FIELDS = ["case_id", "op_read", "stretch_phase", "stretch_bit",
          "extra_cycles", "edge_phase_ns", "scl_input_delay_ns",
          "sda_input_delay_ns", "ack_mode", "ack_lead_ns",
          "early_release_ns"]
OBS = re.compile(r"^OBS (.*)$", re.M)


def digest(path):
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest().upper()


def load_cases():
    with MATRIX.open(newline="", encoding="utf-8") as f:
        rows = list(csv.DictReader(f))
    if len(rows) != 214 or len(rows) > 4096:
        raise RuntimeError(f"CASE_COUNT_CONTRACT:{len(rows)}")
    for i, r in enumerate(rows, 1):
        if int(r["case_id"]) != i:
            raise RuntimeError("CASE_ID_ORDER")
    return rows


def parse_observation(output, expected_id):
    if re.search(r"(^|\n)(Fatal:|ERROR:|Error:)", output):
        raise RuntimeError("SIM_FATAL_OR_ERROR")
    if f"CASE_COMPLETE_{expected_id}" not in output:
        raise RuntimeError("MISSING_COMPLETION_MARKER")
    matches = OBS.findall(output)
    if len(matches) != 1:
        raise RuntimeError(f"OBS_CARDINALITY:{len(matches)}")
    pairs = dict(re.findall(r"([a-z_]+)=([^ ]+)", matches[0]))
    if int(pairs.get("case", -1)) != expected_id:
        raise RuntimeError("STALE_OR_WRONG_CASE_RESULT")
    return pairs


def parse_pins(path):
    edges = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        action, when, sda = raw.split(",")
        if action not in {"START", "STOP", "RISE", "FALL"}:
            raise RuntimeError("INVALID_PIN_ACTION")
        edges.append((action, int(when), int(sda)))
    if not edges:
        raise RuntimeError("EMPTY_PIN_RECORD")
    # XSim prints %t in the design precision of 1 ps; no rounding conversion.
    if any(edges[i][1] > edges[i+1][1] for i in range(len(edges)-1)):
        raise RuntimeError("PIN_TIME_REVERSED")
    return edges


def independently_decode(edges, read, complete, expected_phase):
    event_segments = []
    current = None
    for action, t, sda in edges:
        if action == "START":
            current = []
            event_segments.append(current)
        elif current is not None:
            current.append((action, t, sda))
    if not event_segments:
        raise RuntimeError("NO_RESOLVED_START")
    segments = []
    for events in event_segments:
        # STOP and repeated-START setup also raise SCL, but are not bit clocks.
        # A data/ACK high pulse must have a following resolved FALL before the
        # next bus START/STOP boundary. This is independent of slave phase.
        clocks = []
        for i, (action, t, sda) in enumerate(events):
            if action != "RISE":
                continue
            if any(a == "FALL" for a,_,_ in events[i+1:]):
                clocks.append((t, sda))
        segments.append(clocks)
    if complete:
        expected_lengths = [27] if not read else [18, 18]
        lengths = [len(s) for s in segments]
        if lengths != expected_lengths:
            raise RuntimeError(f"PIN_CLOCK_COUNT:{lengths}!={expected_lengths}")
    expected = [(0, 0x60), (0, 0xFF if not read else 0xF4)]
    expected += [(0, 0x05)] if not read else [(1, 0x61)]
    decoded = []
    for seg_idx, byte in expected:
        seg = segments[seg_idx] if len(segments) > seg_idx else []
        offset = 0 if (seg_idx == 1) else (0 if len(decoded) == 0 else 9 * len([b for b in decoded if b[0] == 0]))
        if len(seg) >= offset + 8:
            value = sum(seg[offset + i][1] << (7-i) for i in range(8))
            decoded.append((seg_idx, value))
            if value != byte:
                raise RuntimeError(f"PIN_BYTE_MISMATCH:{seg_idx}:{offset}:{value:02X}!={byte:02X}")
    if complete and read:
        second = segments[1]
        if len(second) != 18 or second[-1][1] != 1:
            raise RuntimeError("READ_TERMINAL_MASTER_NACK_NOT_OBSERVED")
    return {"starts_pin":len(segments), "stops_pin":sum(a == "STOP" for a,_,_ in edges),
            "pin_rises":sum(len(x) for x in segments), "pin_bytes":decoded}


def check_case(case, obs, pins):
    cid = int(case["case_id"])
    read = int(case["op_read"])
    phase = int(case["stretch_phase"])
    ack_mode = int(case["ack_mode"])
    for name in FIELDS:
        obs_key = {"case_id":"case", "op_read":"read", "stretch_phase":"target",
                   "stretch_bit":"bit", "extra_cycles":"extra",
                   "edge_phase_ns":"phase_ns", "scl_input_delay_ns":"scl_delay",
                   "sda_input_delay_ns":"sda_delay", "ack_lead_ns":"ack_lead",
                   "early_release_ns":"early_release"}.get(name, name)
        if int(case[name]) != int(obs.get(obs_key, -999999)):
            raise RuntimeError(f"CASE_IDENTITY_MISMATCH:{name}")
    success = int(obs["success"])
    timeout = int(obs["timeout"])
    cause = int(obs["raw"])
    if success and (timeout or cause):
        raise RuntimeError("SUCCESS_WITH_ERROR_CAUSE")
    if timeout and cause not in {5,6}:
        raise RuntimeError("TIMEOUT_CAUSE_MISMATCH")
    if int(obs["starts"]) != sum(a == "START" for a,_,_ in pins):
        raise RuntimeError("START_MONITOR_CONTRADICTION")
    pin_stop_count = sum(a == "STOP" for a,_,_ in pins)
    if ack_mode == 3:
        # The intentionally early SDA release can itself form an illegal
        # STOP-like edge during SCL HIGH. The independent pin recorder sees
        # both that edge and the later master STOP; the slave's `active` gate
        # intentionally counts only the first. Require the violation rather
        # than erasing the extra physical bus edge.
        if not int(obs["ack_high_violation"]) or pin_stop_count <= int(obs["stops"]):
            raise RuntimeError("EARLY_RELEASE_PIN_VIOLATION_MISSING")
    elif int(obs["stops"]) != pin_stop_count:
        raise RuntimeError("STOP_MONITOR_CONTRADICTION")
    pin = independently_decode(pins, read, bool(success), phase)
    if int(obs["bytes"]) < len(pin["pin_bytes"]):
        raise RuntimeError("BYTE_MONITOR_CONTRADICTION")
    expected_control = {0:1,1:2,3:4,4:3}
    if ack_mode == 1:
        if success or timeout or cause != expected_control[phase]:
            raise RuntimeError("ABSENT_ACK_CONTROL_WRONG_CAUSE")
        outcome = "EXPECTED_ABSENT_ACK"
    elif ack_mode == 0 and int(case["extra_cycles"]) <= 1000 and int(case["scl_input_delay_ns"]) <= 1000:
        if not success or timeout or cause:
            outcome = "UNEXPECTED_VALID_PATH_FAILURE"
        else:
            outcome = "CLEAN_VALID_PATH"
    elif ack_mode == 3:
        outcome = "EARLY_RELEASE_INVALID_STRESS"
    elif ack_mode == 2:
        outcome = "LATE_ASSERTION_TIMING_STRESS"
    elif timeout and cause == 5:
        outcome = "LOCAL_SCL_TIMEOUT"
    elif success:
        outcome = "CLEAN_SENSITIVITY"
    else:
        outcome = "UNEXPECTED_BOUNDARY_RESULT"
    if phase in {0,1,3,4} and int(obs["target_low"]) and int(obs["bus_high"]):
        low = int(obs["target_low"])
        high = int(obs["bus_high"])
        assertion = int(obs["ack_assert"])
        ack_valid_from_low_ps = assertion - low if assertion else None
        ack_setup_to_high_ps = high - assertion if assertion else None
        if ack_mode == 0 and (not assertion or ack_valid_from_low_ps > 3_450_000 or
                              ack_setup_to_high_ps < 1_250_000):
            raise RuntimeError("EARLY_ACK_TIMING_MONITOR_FAIL")
    else:
        ack_valid_from_low_ps = None
        ack_setup_to_high_ps = None
    return {"checker":"PASS", "experiment_outcome":outcome,
            "starts_pin":pin["starts_pin"], "stops_pin":pin["stops_pin"],
            "pin_rises":pin["pin_rises"], "pin_bytes":str(pin["pin_bytes"]),
            "ack_valid_from_low_ps":ack_valid_from_low_ps,
            "ack_setup_to_high_ps":ack_setup_to_high_ps}


def run():
    rows = load_cases()
    LOGS.mkdir(parents=True, exist_ok=True)
    GRID.mkdir(parents=True, exist_ok=True)
    contract_hashes = json.loads((ROOT / "contracts" / "FROZEN_HASHES.json").read_text(encoding="utf-8"))
    for rel, expected in contract_hashes.items():
        if digest(ROOT / rel) != expected:
            raise RuntimeError(f"FROZEN_HASH_CHANGED:{rel}")
    result_fields = list(rows[0]) + ["checker","experiment_outcome","success","timeout","raw",
                                     "starts","stops","bytes","bits","max_scl_wait",
                                     "target_low","master_release","slave_release","bus_high",
                                     "bus_fall","ack_assert","ack_release","sample","sample_bus_sda",
                                     "sample_raw_sda","sample_filtered_sda","raw_scl_high",
                                     "sync_scl_high","filtered_scl_high","raw_sda_low",
                                     "sync_sda_low","filtered_sda_low","ack_high_violation",
                                     "starts_pin","stops_pin","pin_rises","pin_bytes",
                                     "ack_valid_from_low_ps","ack_setup_to_high_ps","log_sha256",
                                     "pin_sha256"]
    with RESULTS.open("w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=result_fields, lineterminator="\n")
        writer.writeheader()
        for idx, case in enumerate(rows, 1):
            input_line = " ".join(case[k] for k in FIELDS) + "\n"
            (GRID / "case_input.txt").write_text(input_line, encoding="ascii")
            output = subprocess.run([str(X_SIM), "i2c_timing_sim", "-R", "-onerror", "quit"],
                                    cwd=GRID, text=True, stdout=subprocess.PIPE,
                                    stderr=subprocess.STDOUT, timeout=45)
            log = LOGS / f"case_{idx:04d}.log"
            log.write_text(output.stdout, encoding="utf-8")
            if output.returncode != 0:
                raise RuntimeError(f"XSIM_EXIT_{output.returncode}:case_{idx}")
            obs = parse_observation(output.stdout, idx)
            pin_src = GRID / "pin_edges.csv"
            if not pin_src.is_file():
                raise RuntimeError(f"PIN_LOG_MISSING:case_{idx}")
            pin_dest = LOGS / f"case_{idx:04d}_pin_edges.csv"
            pin_src.replace(pin_dest)
            pins = parse_pins(pin_dest)
            checked = check_case(case, obs, pins)
            writer.writerow({**case, **{k:obs.get(k,"") for k in result_fields},
                             **checked, "log_sha256":digest(log),
                             "pin_sha256":digest(pin_dest)})
            f.flush()
            if idx % 10 == 0 or idx == len(rows):
                print(f"GRID_PROGRESS={idx}/{len(rows)}", flush=True)
    print("GRID_COMPLETE", flush=True)


if __name__ == "__main__":
    try:
        run()
    except Exception as exc:
        print(f"GRID_HARD_STOP={exc}", file=sys.stderr, flush=True)
        raise
