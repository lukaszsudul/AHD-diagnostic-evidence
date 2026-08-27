# AHD v41 R1 Candidate A Report — R1i-a / C1

## Identity

- Branch: `research/v41-r1i-a`
- Commit: `8b8ec0fa9c22965e46d0421c25e63d83e7971597`
- Tree: `a0fcbdbfb2b01049b357a8f8bf68bd448d6394f7`
- Direct parent: qualified R1i `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Runtime Git words: `8b8ec0fa 9c22965e 46d0421c 25e63d83 e7971597`

## Causal change

C1 preserves qualified R1i's physical filtered-SCL HIGH qualification, divider reset/stall, full `DIVIDER+1` qualified-HIGH dwell, passive end-of-LOW telemetry, STOP/BUS_FREE behavior, retry/error policy, read-data sampling and bank safety. It removes only the later ACK sampling point.

Two registers were added in the one allowlisted RTL file: one selected ACK value and one selected ACK valid bit. In `ACK_W_HIGH`, `ACK_REG_HIGH`, `ACK_DATA_HIGH` and `ACK_R_HIGH`, the first controller edge observing filtered SCL HIGH captures filtered SDA. A LOW before dwell completion invalidates the selection, allowing the next valid HIGH interval to resample. At the unchanged terminal tick, the decision consumes the held selection; live/raw SDA is not a fallback. Missing validity dispatches to the existing x07 timeout/recovery path.

No physical output waveform or non-ACK sampling policy was changed.

## Source and offline gate

The total commit delta is three paths: the allowlisted RTL and two add-only files under `research_tests/r1i_a`. All 231 frozen tracked files are byte-identical; `git diff --check` is clean; no C2 ordinary-HIGH/endpoint logic is present.

Focused and inherited lifecycle tests passed under the C1 contract. All four ACK phases passed held ACK/NACK, delayed-HIGH, broken-interval invalidation/resampling and unchanged terminal-tick checks. MMIO simulations passed 3/3 and host fixtures passed 40/40. See `R1_OFFLINE_TEST_REPORT.md` for the explicit qualified-R1i late-sample assertion disposition.

## Clean build

| Item | Result |
|---|---|
| Elaboration | PASS |
| Synthesis / implementation / routing | PASS / PASS / PASS |
| Critical DRC | PASS — 0 Error, 0 Critical Warning |
| WNS / TNS | +0.617 ns / 0.000 ns |
| WHS / THS | +0.036 ns / 0.000 ns |
| LUT / FF | 18,215 / 20,084 |
| RAMB18E1 / RAMB36E1 | 10 / 21 |
| Bitstream SHA-256 | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` |
| LTX/probe | not produced or required by the canonical MMIO/BRAM flow |

The build uses a fresh short ASCII-only root, no incremental checkpoint reuse, and the qualified command strategy/directives. Runtime provenance must reconstruct the complete candidate commit above.

## Candidate result

**PASS.** The 2,192,144-byte routed image passed every hard gate. Its 15 warning-only DRC findings exactly match qualified R1i by rule and count, and its clock, I/O-resource and `check_timing` sections are equivalent to the qualified build.
