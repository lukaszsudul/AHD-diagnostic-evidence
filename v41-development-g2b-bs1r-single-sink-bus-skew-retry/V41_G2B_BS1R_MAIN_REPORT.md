# AHD v41 G2B-BS1R Serialized Single-Sink BUS_SKEW Retry

## Result

**Engineering gate: PASS.** The one authorized bounded diagnostic probe reproduced the BUS_SKEW query pathology for the exact 58-source to one-sink scope. Vivado reached `COMMAND_READY` in 310.390 seconds, after which the independent 300-second BUS_SKEW watchdog was armed. The sole `report_bus_skew` call did not return before its deadline and was classified `REPORT_BUS_SKEW_TIMEOUT`.

This is an accepted primary outcome for this diagnostic gate. It is not a timing pass or violation result: actual skew and slack are unavailable because Vivado produced no report summary before external termination.

## Authority and immutable inputs

- Project state revision at start/end: 3 / 3.
- BS1A authority commit: `99bf5177b645260ace59c5e48d079f64a77b7383`.
- BS1A measured launch-to-ready time: 312.233 seconds.
- Required watchdogs: initialization 900 seconds; BUS_SKEW command 300 seconds.
- Sealed routed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`.
- DCP route status: 33,985 routable / 33,985 fully routed / 0 routing errors.
- Source set: `S_FULL`, 58 cells, SHA-256 `F69E9199EBB6212346DA11AC7EB66D832D2E50CCF8F43C5401806780E15247EE`.
- Sink set: `K_OWNERSHIP_RESULT`, one cell `G2B_ONECH_C2H/own_ok_hold_source_reg`, SHA-256 `D0E81393EF7750003EE14C3BE0A789CD35FDF132AF3D2B23CE0C3272EB8065BE`.
- Skew-free base XDC SHA-256: `A05AF5431E521BBC8812DAAE5574CC31D4E7E3BE89DCA0E41974462383BE3071`.
- Immutable worker SHA-256: `31E6E4FE08712166BACA133515B00D1A78BCD1A691683FCF4F40A837C6B2CF51`.
- Vivado: 2025.2, software build 6299465, IP build 6300035.

The resolved source and sink files independently reproduce their authoritative hashes. The generated applied XDC contains exactly one `set_bus_skew` constraint, for the exact 58→1 objects at 3.000 ns.

## Serialized execution and watchdog boundary

Exactly one Vivado worker was launched. No Vivado process or prior BS1R worker existed at preflight, and the maximum observed Vivado executable count was one. No overlap occurred.

| Milestone | UTC timestamp | From launch (s) |
|---|---:|---:|
| Process launch | 2026-09-01T19:39:38.164Z | 0.000 |
| Tcl worker entered | 2026-09-01T19:40:32.305Z | 54.139 |
| DCP opened | 2026-09-01T19:43:16.584Z | 218.418 |
| Objects resolved | 2026-09-01T19:44:46.078Z | 307.912 |
| `COMMAND_READY` | 2026-09-01T19:44:48.556Z | 310.390 |
| BUS_SKEW started | 2026-09-01T19:44:48.620Z | 310.454 |
| BUS_SKEW deadline | 2026-09-01T19:49:48.620Z | 610.454 |
| Worker tree terminated | 2026-09-01T19:49:49.332Z | 611.168 |

The initialization watchdog covered launch through `COMMAND_READY` only and passed at 310.390 seconds. The BUS_SKEW watchdog was based on `BUS_SKEW_STARTED.marker`, 64 ms after readiness, and had its own deadline exactly 300 seconds later. The recorded 300.735-second command interval includes polling and Windows process-tree termination overhead after the 300-second deadline; it does not enlarge the authorized command budget.

## Command and primary evidence

The worker attempted exactly one command:

```tcl
report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation -file G2B_BS1R_REPORT_BUS_SKEW.rpt
```

`BUS_SKEW_STARTED.marker` exists. `BUS_SKEW_COMPLETED.marker` does not exist. `G2B_BS1R_REPORT_BUS_SKEW.rpt` was not produced. The supervisor terminated only the launched process tree. Its immediate post-termination process query briefly observed one terminating process object; an independent quiescent audit at 2026-09-01T19:50:56.470Z observed zero Vivado processes.

Vivado entered its internal timing update and logged `[Timing 38-91] UpdateTimingParams` plus `[Timing 38-191]` multithreading with at most two CPUs. It emitted no report summary, actual skew, slack, or worst source path before the watchdog. One unrelated startup warning, `[Runs 36-547]`, reported a duplicate strategy name; no critical warning, Vivado error, or stderr content was observed.

The optional exact-scope `report_timing` control is `NOT_RUN` because the primary command exceeded 120 seconds.

## Interpretation

Primary outcome: `SINGLE_SINK_BUS_SKEW_TIMEOUT`.

Constraint implication: `SINGLE_SINK_QUERY_PATHOLOGY_REPRODUCED`.

The result proves that the bounded query pathology is reproducible for `S_FULL → K_OWNERSHIP_RESULT` (58→1). It does not establish timing pass or violation and must not be extrapolated to all 19 original Group 9 sinks. No production XDC change follows from this experiment.

## Protection audit

- FPGA_AHD tracked source modified: NO.
- Active XDC modified: NO.
- Source index changed: NO.
- Source branch movement: NO.
- Source commit created: NO.
- Pre-existing untracked `.codex_tmp/` and `reports/` content was preserved.
- Bitstream produced: NO.
- Hardware or DUT accessed: NO.
- SSOT modified: NO.
- Project state revision at end: 3.
- G2B-LUT1 task disposition remains HOLD; G2B-HW remains BLOCKED.

## Publication

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Branch: `main`.
- Directory: `v41-development-g2b-bs1r-single-sink-bus-skew-retry`.
- Evidence commit: containing Git commit.
- Remote read-back: required after push.

Final execution point: hard stop after G2B-BS1R single-sink retry.

