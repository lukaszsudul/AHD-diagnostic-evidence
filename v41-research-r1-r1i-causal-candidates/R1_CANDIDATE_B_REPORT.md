# AHD v41 R1 Candidate B Report — R1i-b / C2

## Identity

- Branch: `research/v41-r1i-b`
- Commit: `e4d10bb8e85e3797d078144fd0965e9625ee727c`
- Tree: `2658cf45e36c3dab81005117056b1f8e6cf3ddc1`
- Direct parent: qualified R1i `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Runtime Git words: `e4d10bb8 e85e3797 d078144f d0965e96 25ee727c`

## Causal change

C2 is the frozen anchored safe approximation that isolates the late terminal ACK sample without ordinary protocol-HIGH divider gating. Its predicate contains exactly:

`START_W_A`, `START_W_B`, `SEND_W_HIGH`, `ACK_W_HIGH`, `SEND_REG_HIGH`, `ACK_REG_HIGH`, `SEND_DATA_HIGH`, `ACK_DATA_HIGH`, `REP_HIGH`, `REP_START_A`, `SEND_R_HIGH`, `ACK_R_HIGH`, `READ_HIGH`, and `MASTER_NACK_HIGH`.

For this set only, the divider runs from state entry without reset/stall caused by filtered SCL. At the terminal endpoint, progression requires filtered SCL HIGH. ACK states sample live filtered SDA only at that endpoint. Endpoint LOW samples nothing, counts no ACK opportunity, advances to no later phase, and reuses the exact qualified x07 abort/recovery dispatch.

STOP_B, STOP_C, ABORT, BUS_FREE, retry/backoff, terminal error, telemetry, bank safety and MMIO behavior remain frozen. No timeout constant or selected-sample latch was added.

## Source and offline gate

The total commit delta is six paths: the allowlisted RTL and five add-only files under `research_tests/r1i_b`. All 231 frozen tracked files are byte-identical; `git diff --check` is clean; no C1 selected-sample logic is present.

Static contract tests passed 10/10. Directed endpoint-HIGH and endpoint-LOW simulations passed with 21-cycle divider dwell; the latter proved no SDA sample, opportunity, or forward phase. The unmodified inherited suite passed, MMIO simulations passed 3/3, and host fixtures passed 40/40.

## Clean build

| Item | Result |
|---|---|
| Elaboration | PASS |
| Synthesis / implementation / routing | PASS / PASS / PASS |
| Critical DRC | PASS — 0 Error, 0 Critical Warning |
| WNS / TNS | +0.617 ns / 0.000 ns |
| WHS / THS | +0.036 ns / 0.000 ns |
| LUT / FF | 18,214 / 20,084 |
| RAMB18E1 / RAMB36E1 | 10 / 21 |
| Bitstream SHA-256 | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` |
| LTX/probe | not produced or required by the canonical MMIO/BRAM flow |

The valid clean build root is `V:/R1I_RCA_B_CLEAN`. The earlier `V:/R1I_RCA_B` wrapper race was explicitly terminated before project creation/design processing and quarantined; see `builds/PRE_PROJECT_LAUNCH_INCIDENT_RECEIPT.txt`.

## Candidate result

**PASS.** The 2,192,144-byte routed image passed every hard gate. Its 15 warning-only DRC findings exactly match qualified R1i by rule and count, and its clock, I/O-resource and `check_timing` sections are equivalent to the qualified build.
