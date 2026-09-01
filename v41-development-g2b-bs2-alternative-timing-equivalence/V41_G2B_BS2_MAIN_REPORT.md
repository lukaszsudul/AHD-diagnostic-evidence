# AHD v41 G2B-BS2 Alternative Timing Query and BUS_SKEW Requirement Equivalence Audit

## Executive result

- Engineering gate: `PASS`
- Sealed DCP: `VERIFIED`
- Exact object scope: `VERIFIED` (`S_FULL` 58 -> `K_OWNERSHIP_RESULT` 1)
- Vivado initialization: `PASS`, 706.648 s
- Exact-scope `report_timing`: `PASS`, 64.183 s external / 64.164 s command
- Capped `get_timing_paths`: `PASS`, 4.346 s external / 2.957 s query-and-export
- `report_bus_skew` retried: `NO`
- Path-set comparability: `INVALID_FOR_SKEW_COMPARISON`
- Alternative computed skew: `NOT_AVAILABLE`
- Alternative sign-off: `FEASIBLE_WITH_CONSTRAINT_CHANGES`
- Group-9 recommendation: `REPLACE_WITH_EQUIVALENT_TIMING_CHECKS`

BS2 demonstrates that ordinary exact-scope timing primitives are operational on the sealed routed design. It does not produce a drop-in numerical replacement for `report_bus_skew`: the capped path query returned 58 objects but only one unique source cell, and the 58-to-1 topology is a reconvergent decision cone rather than a parallel capture bus.

The functional ownership safety invariant can instead be signed off with a structural toggle/ack stable-data proof plus justified absolute per-family settling constraints. That is functional-safety equivalence with constraint changes, not numerical equivalence to a 3.000 ns bus-skew report.

## Authoritative inputs

| Input | Required | Observed | Result |
|---|---|---|---|
| `PROJECT_STATE_REV_AT_START` | 3 | 3 | PASS |
| Sealed routed DCP SHA-256 | `EAE2DEF4...2ACF83` | exact match | PASS |
| DCP size | 57,900,063 bytes | 57,900,063 bytes | PASS |
| Part | `xc7a35tcsg325-2` | exact match | PASS |
| Fully routed nets | all routable | 33,985 / 33,985; 0 routing errors | PASS |
| Source scope | `S_FULL`, 58 | exact list and resolved identity | PASS |
| Source-set SHA-256 | `F69E9199...247EE` | exact match before and after resolution | PASS |
| Sink scope | `K_OWNERSHIP_RESULT`, 1 | exact singleton | PASS |
| Sink object | `G2B_ONECH_C2H/own_ok_hold_source_reg` | exact match | PASS |
| Sink-set SHA-256 | `D0E81393...8065BE` | exact match before and after resolution | PASS |

The analysis used `C:\FPGA\G2B_BS2_ALT_TIMING_20260901T205518Z`, a new isolated directory. It did not reuse BS0, BS1, BS1A, or BS1R workspaces.

## Serialization and prohibition controls

The supervisor found zero pre-existing Vivado processes, launched one worker, observed no overlap, and found zero Vivado processes after exit. The worker exited normally and was not forcibly terminated.

A static preflight required zero executable lines matching `^\s*report_bus_skew(?:\s|$)`. The verified count was zero. The worker state, runner state, launch marker, and final receipt all record `REPORT_BUS_SKEW_ATTEMPT_COUNT=0`.

The methodology stage did apply the exact `set_bus_skew` constraint in memory so that focused TIMING rules could inspect it. Applying a constraint is not executing the prohibited report. No `report_bus_skew` report exists by design.

## Experiment A — exact-scope report_timing

One bounded max/setup query was run with the exact 58-source and one-sink collections, `-max_paths 1 -nworst 1`, under a 300 s external watchdog.

| Field | Result |
|---|---|
| Status | PASS |
| Start | 2026-09-01T21:20:15.378Z |
| Complete | 2026-09-01T21:21:19.561Z |
| External elapsed | 64.183 s |
| Vivado command elapsed | 64.164 s |
| Returned paths | 1 |
| Context | Setup / Max / Slow process corner |
| Worst source | `axis_slot_reg[1]/C` |
| Destination | `own_ok_hold_source_reg/D` |
| Source clock | `userclk1`, 16.000 ns |
| Destination clock | `nvp_vclk1`, 6.734 ns |
| Datapath delay | 4.868 ns |
| Logic / route | 1.602 ns / 3.266 ns |
| Logic levels | 6 |
| Timing exception | `MaxDelay Path 6.000ns -datapath_only` |
| Slack | +1.162 ns |

The report proves the worst path selected from the exact collection meets the existing 6.000 ns absolute datapath-only requirement. It does not prove relative spread.

## Experiment B — exact-scope get_timing_paths

One bounded call used the same collections with `-max_paths 58 -nworst 58` and a separate 300 s external watchdog.

| Field | Result |
|---|---|
| Status | PASS |
| Start | 2026-09-01T21:21:19.591Z |
| Complete | 2026-09-01T21:21:23.937Z |
| External elapsed | 4.346 s |
| Query and export elapsed | 2.957 s |
| Returned path objects | 58 |
| At cap | YES |
| Unique source cells | 1 of 58 |
| Unique destination cells | 1 |
| Arrival property | `ARRIVAL_TIME` |
| Datapath property | `DATAPATH_DELAY` |
| Bus-skew property value | none (`SKEW` empty) |

Thirty-two objects have 4.868 ns arrival/delay and six logic levels; 26 have 4.824 ns and seven levels. Every object starts at `axis_slot_reg[1]`. The 0.044 ns mechanical range is therefore same-source reconvergent-path dispersion, not `S_FULL` arrival spread. It is explicitly rejected as an alternative skew result.

## Structural comparability and topology

The 58 sources are one transaction token:

- slot: 2 bits;
- generation: 24 bits;
- epoch: 32 bits.

They have one launch clock and are transaction-related, but they have different logic roles. Slot selects one of four records; generation and epoch feed wide equality reductions; those predicates reconverge into one Boolean result. The worst path has fanout 142 and six levels. The returned path set also has only 1/58 source coverage.

Therefore:

`PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`

Alternative queries completed, so `TIMING_QUERY_PATHOLOGY_BROADER_THAN_BUS_SKEW` is not established. The evidence instead points to `report_bus_skew` sensitivity to the high-fanout reconvergent decision topology.

## Original Group-9 intent

The original `OWNERSHIP_AXI_TO_SOURCE` constraint applies 3.000 ns bus skew from the 58-bit ownership token to 19 destination registers in five roles: slot state, request/ack phase, result, fatal effects, and admission interlock. Its engineering intent is to prevent a stale or mixed ownership token from authorizing the `COMMITTED -> DMA_OWNED` transition.

The XDC also applies a broad 6.000 ns `set_max_delay -datapath_only` to AXI-to-source stable-data mailbox paths. The source comments state that payloads remain held from request launch through acknowledgement.

The constraint's presence does not prove that relative 3.000 ns spread across aggregate decision paths is the correct property.

## CDC semantic review

The actual crossing is a toggle/ack stable-data mailbox with combinational aggregation after synchronized control:

1. payload and request toggle launch together;
2. request crosses two `ASYNC_REG` stages;
3. source logic consumes the stable payload only on a new synchronized request;
4. source registers result and acknowledgement;
5. acknowledgement crosses two stages back;
6. AXI consumes the held result only after acknowledgement.

Correctness depends on payload stability and an absolute settle-before-consume margin, plus synchronizer/handshake correctness. It does not primarily depend on the relative arrival spread of 58 signals at one Boolean D pin.

## Focused timing methodology

| Rule | Status | Relevance |
|---|---|---|
| TIMING-32 | ABSENT | focused check found no issue |
| TIMING-34 | PRESENT | 3.000 ns is below half the shorter 6.734 ns clock period; aggressive value may increase runtime |
| TIMING-37 | ABSENT | focused check found no issue |
| TIMING-38 | ABSENT | focused check found no issue |
| TIMING-39 | PRESENT | exact constraint covers paths with more than one logic level |

Both present warnings name `own_ok_hold_source_reg/D` as the first endpoint. Related violations are reported as none; the warnings are methodological, not a numerical bus-skew pass.

## Equivalence and constraint decision

`set_max_delay -datapath_only` is not automatically equivalent to `set_bus_skew`:

- max delay constrains absolute propagation;
- bus skew constrains relative arrival spread.

For this architecture, the recommended safety sign-off is structural mailbox proof plus per-family absolute settling bounds derived from the minimum synchronized-request observation window. That replaces the actual safety function of Group 9, not its 3.000 ns numerical statistic.

- `ALTERNATIVE_SIGNOFF = FEASIBLE_WITH_CONSTRAINT_CHANGES`
- `GROUP9_CONSTRAINT_DECISION = REPLACE_WITH_EQUIVALENT_TIMING_CHECKS`

Production XDC must not be edited until a separately authorized XDC-only gate derives the delay budget, proves exact source/destination coverage, and reviews the complete constraint diff.

## Protection audit

| Protection | Result |
|---|---|
| FPGA_AHD tracked source modified | NO |
| Active XDC modified | NO |
| Primary Git index changed | NO |
| Primary branch moved | NO |
| Primary source commit created | NO |
| Bitstream produced | NO |
| Hardware accessed | NO |
| JTAG / programming / PCIe / DMA | NO |
| DUT accessed | NO |
| HDMI project modified | NO |
| SSOT modified | NO |
| `PROJECT_STATE_REV_AT_END` | 3 |
| G2B-LUT1 disposition | HOLD |
| G2B-HW disposition | BLOCKED |

The primary repository remains `main` at `be94f88ee8d179f12928ab791bdae27c22cd1762`, with a clean tracked tree/index and only the pre-existing untracked `.codex_tmp/` and `reports/` roots.

## Final engineering disposition

Engineering PASS does not depend on obtaining a drop-in bus-skew replacement. BS2 met the diagnostic acceptance criteria: all hard identities were verified, alternative queries were bounded and completed, insufficiency was identified without fabricating skew, topology and CDC semantics were classified, methodology findings were resolved, and a concrete constraint recommendation was produced without implementation or hardware changes.

Recommended next action: open one XDC-only methodology gate to derive and validate per-family absolute ownership-mailbox settling constraints plus the structural hold/request/ack proof.

