# AHD v41 R2 Causal Hardware Report — Owner-Mediated Continuation

## Executive result

R2 is `BLOCKED`, with no defensible scientific causal assignment. Ten of the frozen 32 primary runs completed and were committed in order. The tenth run, exact C3/R1i, was countable but non-clean because the frozen one-second frame-rate check was out of band. The frozen R0 rule required campaign suspension after safe restoration. Exact Formal Phase-2 was restored and independently sealed before the halt.

This result does not reopen or revise the historical R1i qualification. It states only that this R2 causal campaign did not complete and therefore cannot select `M1_SUPPORTED`, `M2_SUPPORTED`, `BOTH_INDEPENDENTLY_SUFFICIENT`, or `COMBINED_EFFECT_REQUIRED`.

## Frozen authority and execution controls

- Frozen R0 evidence commit: `aff7e32edc1cf71bde95b6c19e54e6f307764237`
- Candidate definitions, run count, Williams ordering, classifications, cold-start denominator, INIT_DONE timing protocol, and R3 triggers: unchanged
- Hardware authority: `PASS`
- Authority mechanism: `OWNER_CHAT_DECLARATION`
- Owner confirmation capture: `2026-08-28T10:08:52.027Z`
- Owner authority receipt SHA-256: `2DEC89DBC82EBE4361288BBC1557766C2225162BD86C63ADA56F38A5B06BE002`
- Software FPGA lock: not created and not required under the Owner-authorized continuation control
- Cold-start mechanism: `OWNER_MEDIATED_MANUAL_RESET`
- Formal manual reset requests issued: `0`

The Owner declaration remained the sole operational authority throughout the recorded hardware work. The campaign evidence contains no unexplained programming, reset, power, PCIe identity, or host-boot transition.

## Cold-reset entry state and baseline reconstruction

The Owner-performed reset before the earlier R2 attempt was explicitly recognized as a precondition only. It was not counted as a formal cold-start trial.

Fresh read-only entry evidence recorded:

- host: `VCDE-DUT-1`
- remote user: `vcdeagent1`
- kernel: `7.0.0-29-generic`
- boot ID: `c53a4c28-4120-4527-89e2-1108cfaaa2f3`
- PCIe Xilinx endpoint: absent
- XDMA module/device nodes: absent
- JTAG device: `xc7a35t`, IDCODE `0362D093`
- JTAG DONE: `0` in 5/5 samples
- entry classification: `UNPROGRAMMED_OR_FPGA_UNKNOWN`, resolved as unprogrammed, with `PCIe_NOT_ENUMERATED`

After artifact hash verification, exact Formal Phase-2 was programmed and sealed as the safe baseline:

- bitstream SHA-256: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`
- program receipt SHA-256: `D7F27EE1B266B9940D4CF111676FE52BF717962C21D125BAA8FE73B8DC807B21`
- independent DONE receipt SHA-256: `CF5558D68447DC81DAF7DF7A8262D16976A307D6FE7B606A45EE2810D1DEEF6E`
- host transition receipt SHA-256: `DAD9A20CA1D00F7E98A964B5B4C4899B87154A66A53D6262A7C3C784B3EDC747`
- runtime capture receipt SHA-256: `2B7C850F50A2E9459E7B25DD33B18FE550A7FD9E093CE27FE736586F547EB1C2`
- baseline seal SHA-256: `F4A9252E2901A7B2CE943F85544B474F51D51BBBCE44EBBB639D9F3E4B8B7B67`

The Formal image is a safe-baseline identity target, not a primary causal cell; its functional telemetry was not reinterpreted as candidate evidence.

## Exact candidate identity

| Cell | Identity | Bitstream SHA-256 | Runtime source commit |
|---|---|---|---|
| C0 | exact R1h | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` |
| C1 | R1i-a | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` |
| C2 | R1i-b | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` | `e4d10bb8e85e3797d078144fd0965e9625ee727c` |
| C3 | exact qualified R1i | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | `20c3323d79d3896edc586d6db1df7deee60f9e41` |

All four identities were observed and bound to their exact bitstream roles. No candidate was rebuilt.

## Primary campaign execution

The frozen matrix starts:

1. C0, C1, C3, C2
2. C1, C2, C0, C3
3. C2, C3, C1, C0

The first two rows and the first two positions of row three completed. Each completed run restored and verified Formal Phase-2 before the next mutation.

| Seq. | Run ID | Cell | Classification | INIT_DONE | INIT_ERROR | Total NACK | Retry | Recovered | Timeout | Video | Frame Hz |
|---:|---|---|---|---:|---:|---:|---:|---:|---:|---|---:|
| 1 | `R2OM-R01-P1-C0` | C0 | FAIL | 1 | 1 | 11 | 0 | 0 | 0 | NO | 0.000000 |
| 2 | `R2OM-R01-P2-C1` | C1 | INCONCLUSIVE | 1 | 0 | 0 | 0 | 0 | 0 | YES | 25.795496 |
| 3 | `R2OM-R01-P3-C3` | C3 | CLEAN_PASS | 1 | 0 | 0 | 0 | 0 | 0 | YES | 24.799186 |
| 4 | `R2OM-R01-P4-C2` | C2 | CLEAN_PASS | 1 | 0 | 0 | 0 | 0 | 0 | YES | 24.808690 |
| 5 | `R2OM-R02-P1-C1` | C1 | INCONCLUSIVE | 1 | 0 | 0 | 0 | 0 | 0 | YES | 25.794836 |
| 6 | `R2OM-R02-P2-C2` | C2 | RECOVERED_PASS | 1 | 0 | 1 | 1 | 1 | 0 | YES | 25.797844 |
| 7 | `R2OM-R02-P3-C0` | C0 | FAIL | 1 | 1 | 13 | 0 | 0 | 0 | NO | 0.000000 |
| 8 | `R2OM-R02-P4-C3` | C3 | CLEAN_PASS | 1 | 0 | 0 | 0 | 0 | 0 | YES | 24.804729 |
| 9 | `R2OM-R03-P1-C2` | C2 | RECOVERED_PASS | 1 | 0 | 2 | 2 | 2 | 0 | YES | 24.806087 |
| 10 | `R2OM-R03-P2-C3` | C3 | INCONCLUSIVE | 1 | 0 | 0 | 0 | 0 | 0 | YES | 25.776567 |

Every listed run has `R0_PRIMARY_RUN_COUNTABLE=YES` and `SAFE_FORMAL_BASELINE_RESTORED=YES` in the append-only completion ledger.

### Cell totals at halt

| Cell | Runs | CLEAN_PASS | RECOVERED_PASS | FAIL | INCONCLUSIVE |
|---|---:|---:|---:|---:|---:|
| C0 | 2 | 0 | 0 | 2 | 0 |
| C1 | 2 | 0 | 0 | 0 | 2 |
| C2 | 3 | 1 | 2 | 0 | 0 |
| C3 | 3 | 2 | 0 | 0 | 1 |

## Mandatory suspension

Run 10 had exact C3 identity and otherwise clean causal counters, but its measured frame rate did not satisfy the frozen clean band. The frozen R0 plan states that any non-clean C3 run invalidates its block and suspends the campaign for identity/environment review. Accordingly:

- run 10 remained `INCONCLUSIVE`;
- no observed-result criterion was changed;
- the run was not retried or removed from the denominator;
- the exact Formal baseline was restored;
- the campaign halted at sequence 10;
- runs 11–32 were not executed.

The halt receipt is SHA-256 `5939346939DBAA7B934662A4718095045BAE22CA3A341847032335E22B36062B` and records `C3_NON_CLEAN_SUSPEND_BLOCK`.

## Scientific interpretation

Scientific causal result: `BLOCKED`.

The frozen primary mapping cannot be applied because the campaign did not reach 8 runs per cell, C1 and C3 already contain non-clean results, and C2 recovery activity makes M1/M2 sufficiency inconclusive for those runs. The observations are useful diagnostics but not a completed causal answer.

The R3 trigger is `REQUIRED` before any stronger mechanism or margin claim because R1i-derived C2 runs activated retry/recovery and the executed cells are mixed/non-clean. R3 was not started and is not authorized by this task.

## Exact R1i cold starts

Status: `0/10`, `NOT_RUN`.

No Owner-mediated manual reset was requested for this phase. No receipt exists, and no trial was counted. The earlier Owner cold reset remains `PRECONDITION ONLY`.

## INIT_DONE timing

Status: `NOT_RUN`.

No counter delta, host timing bracket, or derived clock-consistency result was measured under the frozen protocol. No expected-duration hypothesis is reported as evidence.

## Final safe hardware state

After run 10, exact Formal Phase-2 was restored and sealed:

- final safe-baseline receipt SHA-256: `26E2FFCEEA193E834CB80777A1E34EA618EDF6E6FECE4E067CD3000EC8E849AF`
- bitstream SHA-256: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`
- `DONE=1`
- PCIe `10ee:7011`, Gen1 ×1
- driver `xdma`
- `BLOCK_ID=0xA40A0C07`
- `PROTOCOL=0x0000400B`
- `CAPABILITIES=0x00031002`
- diagnostic magic `0x00000000`
- secondary diagnostic magic `0x00000000`
- boot ID `d12b3a07-ea25-4769-8293-88ee8fc92ef2`
- flash operations `0`

A final pre-publication live read-only capture at `2026-08-28T18:34:18.741078119Z` reconfirmed the same exact Formal runtime identity. Its receipt SHA-256 is `57D0BA961EE73C2B89574B04FF5ED19782F4EE0FA909A47C7DA005F181EAD49A`; it recorded zero MMIO writes and zero DMA transfers.

## Compliance statement

- Product R1i modified: `NO`
- G-track modified: `NO`
- G2A bitstream used: `NO`
- flash changed: `NO`
- drivers changed: `NO`
- project-current-state modified: `NO`
- R3 started: `NO`
- G2B resumed: `NO`

## Publication-state caveats

This report is an offline publication input. Before final evidence commit, the publisher must record `PROJECT_STATE_REV_AT_END`, classify SSOT staleness, append the actual DUT-exclusivity release interaction after it occurs, create the SHA-256 manifest, commit to the new immutable evidence directory, and perform remote read-back. Until those steps occur, evidence publication remains `PENDING`.
