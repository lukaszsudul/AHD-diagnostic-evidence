# SANITIZED PUBLICATION COPY; executed-source SHA-256: 3C3A3FFC272443EBFD6E09513CB0A55FBCC23F218FBB5E548E5345DB83BB21D7
"""Host-owned three-sample detector/debounce state."""

from __future__ import annotations

from dataclasses import dataclass, field

from .decoder import classify_stable_tuple


@dataclass
class ChannelState:
    campaign_id: str
    phase_id: str = "UNSET"
    previous_raw_tuple: tuple[int, ...] | None = None
    candidate_format: str | None = None
    agreeing_sample_count: int = 0
    confirmed_format: str | None = None
    novid_transition_history: list[int] = field(default_factory=list)
    a8_bookend_stability: list[bool] = field(default_factory=list)
    last_stable_snapshot_generation: int | None = None
    last_detector_tuple: tuple[int, ...] | None = None
    control_channel_comparison: str = "UNRESOLVED"

    def update(self, phase_id: str, generation: int, decoded: dict, bookend_stable: bool) -> None:
        raw_tuple = tuple(decoded["raw_tuple"])
        self.phase_id = phase_id
        self.novid_transition_history.append(decoded["novid"])
        self.a8_bookend_stability.append(bookend_stable)
        self.last_detector_tuple = raw_tuple
        if not bookend_stable:
            return
        if raw_tuple == self.previous_raw_tuple:
            self.agreeing_sample_count += 1
        else:
            self.previous_raw_tuple = raw_tuple
            self.agreeing_sample_count = 1
            self.confirmed_format = None
        self.candidate_format = classify_stable_tuple(decoded)
        self.last_stable_snapshot_generation = generation
        if self.agreeing_sample_count >= 3:
            self.confirmed_format = self.candidate_format


class CampaignState:
    def __init__(self, campaign_id: str):
        if not campaign_id:
            raise ValueError("campaign_id is required")
        self.campaign_id = campaign_id
        self.channels = {name: ChannelState(campaign_id) for name in ("CH1", "CH2", "CH3", "CH4")}

    def update(self, phase_id: str, snapshot: dict) -> None:
        stable = not snapshot["live_status_changed"]
        for name, decoded in snapshot["channels"].items():
            self.channels[name].update(phase_id, snapshot["generation"], decoded, stable)
