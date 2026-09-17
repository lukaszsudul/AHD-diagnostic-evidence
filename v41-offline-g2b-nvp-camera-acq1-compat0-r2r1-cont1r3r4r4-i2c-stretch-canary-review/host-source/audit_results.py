"""Second, read-only compliance audit and injected-negative checker tests."""
import csv
import json
from pathlib import Path

from run_grid import ROOT, MATRIX, RESULTS, LOGS, check_case, parse_observation, parse_pins


def source_compliance(case, obs):
    mode = int(case["ack_mode"])
    if mode == 1:
        return "INVALID_ABSENT_ACK"
    if mode == 3:
        return "INVALID_EARLY_RELEASE"
    if mode == 2:
        assertion = int(obs["ack_assert"])
        low = int(obs["target_low"])
        if not assertion or not low:
            return "UNRESOLVED_ACK_TIMING"
        if assertion - low > 3_450_000:
            return "INVALID_TVD_ACK"
        if int(obs["slave_release"]) - assertion < 1_250_000:
            return "INVALID_STRETCH_PRE_RELEASE_SETUP"
        return "GENERIC_VALID_LATE_ACK"
    if mode == 0 and int(case["scl_input_delay_ns"]) > 0:
        return "GENERIC_VALID_DIGITAL_ANALOG_UNVERIFIED"
    return "GENERIC_VALID_DIGITAL"


def reject_false_compliance(case, obs, claimed):
    actual = source_compliance(case, obs)
    if claimed.startswith("GENERIC_VALID") and actual.startswith("INVALID"):
        raise ValueError(f"FALSE_COMPLIANCE:{actual}")
    return actual


def must_reject(fn, marker):
    try:
        fn()
    except Exception:
        return marker
    raise AssertionError(f"NEGATIVE_CHECKER_DID_NOT_REJECT:{marker}")


def main():
    cases = list(csv.DictReader(MATRIX.open(newline="", encoding="utf-8")))
    rows = list(csv.DictReader(RESULTS.open(newline="", encoding="utf-8")))
    if len(cases) != 214 or len(rows) != 214:
        raise RuntimeError(f"INCOMPLETE_MATRIX:{len(rows)}/214")
    by_id = {r["case_id"]:r for r in cases}
    summary = {"total":0, "generic_valid_digital":0,
               "digital_analog_unverified":0, "invalid_stress":0,
               "unresolved":0, "valid_path_false_nack":0,
               "outside_envelope_nack":0, "local_scl_timeout":0,
               "other_valid_path_defect":0}
    audited = []
    for r in rows:
        case = by_id[r["case_id"]]
        cls = source_compliance(case, r)
        summary["total"] += 1
        if cls == "GENERIC_VALID_DIGITAL":
            summary["generic_valid_digital"] += 1
        elif cls == "GENERIC_VALID_DIGITAL_ANALOG_UNVERIFIED":
            summary["digital_analog_unverified"] += 1
        elif cls.startswith("INVALID"):
            summary["invalid_stress"] += 1
        else:
            summary["unresolved"] += 1
        raw = int(r["raw"])
        timeout = int(r["timeout"])
        if raw in (1,2,3,4) and not timeout and int(case["ack_mode"]) != 1:
            if cls == "GENERIC_VALID_DIGITAL":
                summary["valid_path_false_nack"] += 1
            else:
                summary["outside_envelope_nack"] += 1
        if raw == 5 and timeout:
            summary["local_scl_timeout"] += 1
        if cls == "GENERIC_VALID_DIGITAL" and raw not in (0,5) and int(case["ack_mode"]) == 0:
            summary["other_valid_path_defect"] += 1
        audited.append({"case_id":case["case_id"], "independent_compliance":cls,
                        "raw":raw,"timeout":timeout,"success":int(r["success"])})

    # Deliberately corrupted copies; original frozen inputs are never edited.
    c1 = cases[0]
    o1 = parse_observation((LOGS/"case_0001.log").read_text(encoding="utf-8"), 1)
    p1 = parse_pins(LOGS/"case_0001_pin_edges.csv")
    invalid_case = next(c for c in cases if c["ack_mode"] == "2")
    invalid_obs = rows[int(invalid_case["case_id"])-1]
    tests = []
    tests.append(must_reject(lambda: reject_false_compliance(invalid_case, invalid_obs, "GENERIC_VALID_DIGITAL"), "FALSE_COMPLIANCE"))
    changed = dict(c1); changed["edge_phase_ns"] = "7"
    tests.append(must_reject(lambda: check_case(changed, o1, p1), "PHASE_IDENTITY"))
    altered_pins = list(p1)
    for i,(action,t,sda) in enumerate(altered_pins):
        if action == "RISE":
            altered_pins[i] = (action,t,1-sda)
            break
    tests.append(must_reject(lambda: check_case(c1, o1, altered_pins), "PIN_BYTE"))
    dropped = list(p1)
    dropped.pop(next(i for i,e in enumerate(dropped) if e[0] == "RISE"))
    tests.append(must_reject(lambda: check_case(c1, o1, dropped), "PIN_COUNT"))
    stale = (LOGS/"case_0001.log").read_text(encoding="utf-8").replace("CASE_COMPLETE_1", "CASE_COMPLETE_999")
    tests.append(must_reject(lambda: parse_observation(stale, 1), "STALE_COMPLETION"))
    wrong_result = (LOGS/"case_0001.log").read_text(encoding="utf-8").replace("OBS case=1", "OBS case=999")
    tests.append(must_reject(lambda: parse_observation(wrong_result, 1), "RESULT_ID"))
    receipt = {"summary":summary,"negative_tests":tests,"negative_passes":len(tests),
               "source_of_truth":"NXP UM10204 Rev7 Table11/footnotes and pinned matrix"}
    (ROOT/"reports"/"INDEPENDENT_AUDIT.json").write_text(json.dumps(receipt,indent=2)+"\n",encoding="utf-8")
    with (ROOT/"reports"/"INDEPENDENT_COMPLIANCE.csv").open("w",newline="",encoding="utf-8") as f:
        w=csv.DictWriter(f,fieldnames=list(audited[0]),lineterminator="\n")
        w.writeheader(); w.writerows(audited)
    print(json.dumps(receipt,indent=2))


if __name__ == "__main__":
    main()
