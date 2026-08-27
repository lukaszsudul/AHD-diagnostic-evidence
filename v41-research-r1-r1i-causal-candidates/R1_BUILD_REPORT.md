# AHD v41 R1 Clean Build Report

## Result

**PASS.** Two independent, non-incremental candidate builds were run from separate fresh ASCII-only roots after their offline gates passed.

## Frozen environment and flow

- Vivado: 2025.2, SW build 6299465
- Part: `xc7a35tcsg325-2`
- Top: `ahd_capture_top_xdma`
- `XILINX_LOCAL_USER_DATA=NO`
- `XILINX_TCLAPP_REPO=C:/AMDDesignTools/2025.2/Vivado/data/XilinxTclStore`
- Candidate-local short ASCII TEMP/TMP roots
- Synthesis flattening: `rebuilt`
- Qualified synthesis and implementation sequence: one each of synthesis, optimization, placement, physical optimization, routing and bitstream generation
- Incremental checkpoint reuse: none

The external provenance adapter has SHA-256 `6BCE35C32D4FA7E878F34D0003CD49F38FDE96F6F6BAB1E8602B9E33E1B54B49`. Relative to the canonical script hash `7A0CF8BA86FB9245355AD964D6127CC1412A3CF4B9D3228C478F9FC768CDA58F`, it changes only candidate authorization, ancestry validation, naming and provenance labels. Source/XDC/XCI lists, part, top, generics other than exact commit words, strategies, directives and design commands are unchanged.

The preserved `FLOW=R1H_R2_SYNTH_SETUP_PLUS_SUCCESSFUL_R1H_R4_IMPLEMENTATION` string is a historical label inherited verbatim from the qualified canonical harness. It names the donor flow recipe; it does not mean that this task started or executed research phase R2.

## Candidate results

| Metric | R1i-a / C1 | R1i-b / C2 |
|---|---:|---:|
| Valid clean root | `V:/R1I_RCA_A_CLEAN` | `V:/R1I_RCA_B_CLEAN` |
| Elaboration | PASS | PASS |
| Synthesis | PASS | PASS |
| Implementation | PASS | PASS |
| Routing | PASS | PASS |
| Critical DRC | PASS — 0 Error / 0 Critical Warning | PASS — 0 Error / 0 Critical Warning |
| WNS | +0.617 ns | +0.617 ns |
| TNS | 0.000 ns | 0.000 ns |
| WHS | +0.036 ns | +0.036 ns |
| THS | 0.000 ns | 0.000 ns |
| LUT | 18,215 | 18,214 |
| FF | 20,084 | 20,084 |
| RAMB18E1 / RAMB36E1 | 10 / 21 | 10 / 21 |
| Route status | 35,852/35,852 routable nets fully routed; 0 errors/partial/unrouted | 35,854/35,854 routable nets fully routed; 0 errors/partial/unrouted |
| Bitstream bytes | 2,192,144 | 2,192,144 |
| Bitstream SHA-256 | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` |
| LTX/probe SHA-256 | not produced / N/A | not produced / N/A |

## DRC and timing gate

Both candidates have WNS +0.617 ns, TNS 0.000 ns, WHS +0.036 ns and THS 0.000 ns with zero failing setup/hold endpoints. Each has 0 DRC Error and 0 Critical Warning. Their 15 Warning-only findings exactly match C3: `PDCN-1569` ×1, `REQP-1839` ×4, `REQP-1840` ×9 and `RTSTAT-10` ×1. CDC reports contain only the inherited info/warning classes, with no Critical or Unknown classification.

The frozen I/O timing policy is preserved: I/O paths are not globally ignored, no internal endpoint lacks a clock, and no internal endpoint is unconstrained. The qualified design's intentionally constrained/false-pathed external-interface findings are compared unchanged in `R1_CANDIDATE_COMPARISON.md`.

## Build-process accounting

Two valid clean design builds were used: one Candidate B process followed by one Candidate A process, each terminating with exit code 0. Two additional delayed Vivado startup processes arose only in the original Candidate B wrapper race; both were explicitly terminated before `create_project` or any design operation. Total Vivado process starts observed for R1 were therefore four: two quarantined pre-project startups and two completed clean builds.

The original `V:/R1I_RCA_B` wrapper race is not counted as a valid design build. Two delayed startup processes were explicitly terminated before `create_project` or any design operation, and the root was quarantined. The file-backed incident receipt records both PIDs, timestamps, missing-stage proofs and hashes. No automatic retry occurred; the clean superseding root was separately authorized.

## Preserved artifacts

Each candidate evidence directory contains the bitstream, Vivado log and journal, timing summary, DRC report, final utilization report, route-status report, build provenance, operation counts, hard-gate result, build-result record and invocation. Routed/synthesis checkpoints remain preserved in the local build roots. The canonical MMIO/BRAM instrumentation flow has no debug-probe/LTX generation action; a per-candidate status receipt records that no LTX was produced or required.

No image was opened in a hardware manager or programmed.
