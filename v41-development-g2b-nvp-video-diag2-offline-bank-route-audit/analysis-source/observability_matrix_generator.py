#!/usr/bin/env python3
"""Authoritative R3 raw-marker observability inventory."""

from __future__ import annotations

from typing import Any


def rows() -> list[dict[str, Any]]:
    # `active_sav_candidate_count` is a direct post-frontend FF 00 00 XY
    # detector in the VDO clock domain. It is therefore legal raw SAV
    # observability, though it is insufficient to distinguish prefix and
    # parity failure modes by itself.
    return [
        {"Observation": "VCLK edge/count", "RTLSignal": "vclk_edge_count_nvp -> vclk_edge_count_user", "ClockDomain": "nvp_clk to axi_aclk Gray CDC", "ExistingCounter": "YES", "ExistingMMIO": "0x3880", "CoherentRead": "Gray synchronized snapshot", "R3Available": "YES", "RequiredForRootCause": "YES", "Gap": "NONE", "RecommendedImplementation": "REUSE"},
        {"Observation": "raw VDO byte-change count", "RTLSignal": "NONE", "ClockDomain": "nvp_clk", "ExistingCounter": "NO", "ExistingMMIO": "NO", "CoherentRead": "NO", "R3Available": "NO", "RequiredForRootCause": "YES", "Gap": "cannot distinguish constant bus from changing non-marker data", "RecommendedImplementation": "counter increment when source_byte != previous_source_byte"},
        {"Observation": "raw nonconstant-data count", "RTLSignal": "NONE", "ClockDomain": "nvp_clk", "ExistingCounter": "NO", "ExistingMMIO": "NO", "CoherentRead": "NO", "R3Available": "NO", "RequiredForRootCause": "YES", "Gap": "no activity histogram", "RecommendedImplementation": "bounded raw sample/nonconstant counters"},
        {"Observation": "raw 0xFF byte count", "RTLSignal": "marker_p0/p1/p2 hold history but no counter", "ClockDomain": "source_clk", "ExistingCounter": "NO", "ExistingMMIO": "NO", "CoherentRead": "NO", "R3Available": "NO", "RequiredForRootCause": "YES", "Gap": "prefix stage unobservable", "RecommendedImplementation": "raw_ff_count"},
        {"Observation": "raw FF 00 count", "RTLSignal": "prefix history only", "ClockDomain": "source_clk", "ExistingCounter": "NO", "ExistingMMIO": "NO", "CoherentRead": "NO", "R3Available": "NO", "RequiredForRootCause": "YES", "Gap": "prefix stage unobservable", "RecommendedImplementation": "raw_ff00_count"},
        {"Observation": "raw FF 00 00 count", "RTLSignal": "prefix history only", "ClockDomain": "source_clk", "ExistingCounter": "NO", "ExistingMMIO": "NO", "CoherentRead": "NO", "R3Available": "NO", "RequiredForRootCause": "YES", "Gap": "three-byte prefix unobservable", "RecommendedImplementation": "raw_ff0000_count"},
        {"Observation": "raw FF 00 00 XY candidate count", "RTLSignal": "combinational marker predicate exists", "ClockDomain": "source_clk", "ExistingCounter": "only legal-marker-derived SAV counter", "ExistingMMIO": "NO distinct candidate register", "CoherentRead": "NO distinct counter", "R3Available": "NO", "RequiredForRootCause": "YES", "Gap": "cannot separate any XY candidate from legality", "RecommendedImplementation": "raw_ff0000xy_candidate_count before XY validation"},
        {"Observation": "legal raw SAV count", "RTLSignal": "active_sav_candidate_count", "ClockDomain": "video/nvp clock", "ExistingCounter": "YES", "ExistingMMIO": "0x3884", "CoherentRead": "source counter surfaced through existing telemetry", "R3Available": "YES", "RequiredForRootCause": "YES", "Gap": "does not expose prefix/parity failure stages", "RecommendedImplementation": "REUSE alongside new raw counters"},
        {"Observation": "legal raw EAV count", "RTLSignal": "marker_valid_pipe and H exist; no EAV counter", "ClockDomain": "source_clk", "ExistingCounter": "NO", "ExistingMMIO": "NO", "CoherentRead": "NO", "R3Available": "NO", "RequiredForRootCause": "YES", "Gap": "EAV independent rate unavailable", "RecommendedImplementation": "legal_raw_eav_count"},
        {"Observation": "illegal XY/parity marker count", "RTLSignal": "legal predicate rejects silently", "ClockDomain": "source_clk", "ExistingCounter": "NO raw counter", "ExistingMMIO": "NO", "CoherentRead": "NO", "R3Available": "NO", "RequiredForRootCause": "YES", "Gap": "cannot identify malformed XY", "RecommendedImplementation": "illegal_xy_or_parity_count after FF0000 prefix"},
        {"Observation": "unexpected marker count", "RTLSignal": "bad_marker_v is parser/record outcome, not raw prefix counter", "ClockDomain": "source_clk/video clock", "ExistingCounter": "PARTIAL qualified-path counter", "ExistingMMIO": "0x3864", "CoherentRead": "existing telemetry", "R3Available": "PARTIAL", "RequiredForRootCause": "YES", "Gap": "no raw unexpected-marker taxonomy", "RecommendedImplementation": "raw unexpected-marker counter separate from record error"},
        {"Observation": "parser state", "RTLSignal": "source_state internal", "ClockDomain": "source_clk", "ExistingCounter": "NO", "ExistingMMIO": "NO direct state", "CoherentRead": "NO", "R3Available": "PARTIAL via status outcomes", "RequiredForRootCause": "YES", "Gap": "state not directly exposed", "RecommendedImplementation": "coherent parser-state snapshot"},
        {"Observation": "parser lock", "RTLSignal": "source_locked_source -> source_locked_sync2_axi", "ClockDomain": "source_clk to axi_aclk", "ExistingCounter": "state bit", "ExistingMMIO": "transport status bit", "CoherentRead": "2FF synchronizer", "R3Available": "YES", "RequiredForRootCause": "YES", "Gap": "NONE", "RecommendedImplementation": "REUSE"},
        {"Observation": "line-length failure count", "RTLSignal": "bad_length_v/status_bad_length", "ClockDomain": "video clock", "ExistingCounter": "YES", "ExistingMMIO": "0x3868", "CoherentRead": "existing telemetry", "R3Available": "YES", "RequiredForRootCause": "SUPPORTING", "Gap": "qualified parser only", "RecommendedImplementation": "REUSE"},
        {"Observation": "payload-count failure count", "RTLSignal": "bad_length_v/status_bad_length", "ClockDomain": "video clock", "ExistingCounter": "YES shared", "ExistingMMIO": "0x3868", "CoherentRead": "existing telemetry", "R3Available": "YES", "RequiredForRootCause": "SUPPORTING", "Gap": "not separately categorized", "RecommendedImplementation": "optional separate counter"},
        {"Observation": "source malformed count", "RTLSignal": "source_lifetime_malformed / malformed_v", "ClockDomain": "source/video clock", "ExistingCounter": "YES", "ExistingMMIO": "0x3870 and transport snapshots", "CoherentRead": "existing snapshot/telemetry", "R3Available": "YES", "RequiredForRootCause": "SUPPORTING", "Gap": "NONE for aggregate", "RecommendedImplementation": "REUSE"},
        {"Observation": "source dropped count", "RTLSignal": "source_lifetime_dropped / dropped_v", "ClockDomain": "source/video clock", "ExistingCounter": "YES", "ExistingMMIO": "0x3874 and transport snapshots", "CoherentRead": "existing snapshot/telemetry", "R3Available": "YES", "RequiredForRootCause": "SUPPORTING", "Gap": "NONE for aggregate", "RecommendedImplementation": "REUSE"},
    ]


def summary() -> dict[str, str]:
    return {
        "existing_r3_observability": "INSUFFICIENT",
        "raw_vdo_toggle_counter": "NOT_AVAILABLE",
        "raw_ff_counter": "NOT_AVAILABLE",
        "ff0000xy_candidate_counter": "NOT_AVAILABLE",
        "legal_raw_sav_counter": "AVAILABLE",
        "legal_raw_eav_counter": "NOT_AVAILABLE",
        "illegal_marker_counter": "NOT_AVAILABLE",
        "parser_state_observability": "PARTIAL",
        "minimal_raw_marker_extension_required": "YES",
    }


if __name__ == "__main__":
    import json

    print(json.dumps({"rows": rows(), "summary": summary()}, indent=2))
