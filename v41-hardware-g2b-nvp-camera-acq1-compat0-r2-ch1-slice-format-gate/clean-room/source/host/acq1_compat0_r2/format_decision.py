"""Read-only CH1 format decision using only frozen SCAN1 snapshot fields."""

from __future__ import annotations

from . import contract


AMBIGUOUS_AHD_CVI_CODES = {0x20, 0x21, 0x2B, 0x2C, 0x30, 0x31, 0x35, 0x36}


def _eligible(snapshot: dict) -> bool:
    return (snapshot.get("live_status_changed") is False and
            snapshot.get("entry_bank_restore") == "PASS" and
            snapshot.get("entry_count") == 82 and
            "CH1" in snapshot.get("channels", {}))


def decide(snapshots: list[dict]) -> dict:
    """Classify three or more snapshots without emitting any write request."""
    contract.load_and_validate()
    if len(snapshots) < 3 or not all(_eligible(item) for item in snapshots):
        return {"outcome": "SIGNAL_UNSTABLE", "reason": "INELIGIBLE_OR_TOO_FEW_SNAPSHOTS",
                "read_only": True}
    channels = [item["channels"]["CH1"] for item in snapshots]
    tuples = [tuple(item["raw_tuple"]) for item in channels]
    novids = [int(item["novid"]) for item in channels]
    if len(set(novids)) != 1 or len(set(tuples)) != 1:
        return {"outcome": "SIGNAL_UNSTABLE", "reason": "NOVID_OR_RAW_TUPLE_NOT_STABLE",
                "read_only": True}
    if novids[0] == 1:
        return {"outcome": "NO_FORMAT_CODE", "reason": "STABLE_NOVID_ONE", "read_only": True}
    raw_f0 = int(channels[0]["raw_f0"])
    if raw_f0 in AMBIGUOUS_AHD_CVI_CODES:
        return {"outcome": "FORMAT_PRESENT_UNRESOLVED",
                "reason": f"RAW_F0_0x{raw_f0:02X}_REQUIRES_WRITE_BASED_AHD_CVI_DISCRIMINATOR",
                "raw_f0": raw_f0, "read_only": True}
    if (raw_f0 & 0x0F) == 0x0F or (raw_f0 >> 4) == 0x0F:
        return {"outcome": "FORMAT_PRESENT_UNRESOLVED", "reason": "RAW_FORMAT_CODE_NOT_VALID",
                "raw_f0": raw_f0, "read_only": True}
    # The frozen R2 manifest contains no authoritative read-only mapping for
    # any remaining private code.  Do not manufacture an unsupported label.
    return {"outcome": "FORMAT_PRESENT_UNRESOLVED",
            "reason": "RAW_FORMAT_CODE_NOT_AUTHORITATIVELY_MAPPED_READ_ONLY",
            "raw_f0": raw_f0, "read_only": True}


def terminal_policy(outcome: str, functional_write_occurred: bool) -> dict:
    if outcome not in contract.OUTCOMES:
        raise ValueError(f"UNKNOWN_FORMAT_OUTCOME:{outcome}")
    return {
        "outcome": outcome,
        "mode_write": False,
        "eq_write": False,
        "capture": False,
        "rollback_required": bool(functional_write_occurred),
        "terminal": True,
    }

