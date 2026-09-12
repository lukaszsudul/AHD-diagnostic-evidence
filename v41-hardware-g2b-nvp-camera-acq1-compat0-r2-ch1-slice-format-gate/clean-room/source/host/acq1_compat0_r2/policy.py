"""Pure bounded NOVID sweep policy used by the runtime and offline gate."""

from __future__ import annotations


LEVELS = (0x50, 0x40, 0x60)


def stable_novid(snapshots: list[dict], minimum: int = 3) -> int | None:
    eligible = [item for item in snapshots
                if item.get("live_status_changed") is False and
                item.get("entry_bank_restore") == "PASS" and
                "CH1" in item.get("channels", {})]
    if len(eligible) < minimum:
        return None
    tail = eligible[-minimum:]
    values = [int(item["channels"]["CH1"]["novid"]) for item in tail]
    return values[0] if len(set(values)) == 1 else None


def post_level_decision(level: int, snapshots: list[dict]) -> str:
    if level not in LEVELS:
        raise ValueError("UNAUTHORIZED_SLICE_LEVEL")
    value = stable_novid(snapshots)
    if value == 0:
        return "STOP_AND_IDENTIFY_FORMAT"
    if value == 1 and level != 0x60:
        return "CONTINUE_TO_NEXT_LEVEL"
    if value == 1:
        return "STOP_NO_VALID_VIDEO_AND_ROLLBACK"
    if len(snapshots) >= 5:
        return "STOP_SIGNAL_UNSTABLE_AND_ROLLBACK"
    return "COLLECT_ANOTHER_ACCEPTED_SNAPSHOT"

