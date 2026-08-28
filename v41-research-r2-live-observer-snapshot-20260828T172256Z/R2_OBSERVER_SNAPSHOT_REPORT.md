# AHD v41 R2 passive execution observer snapshot

**POINT-IN-TIME OBSERVATION**

- `SNAPSHOT_UTC`: `2026-08-28T17:22:56.2017197Z`
- `SNAPSHOT_LOCAL_TIME`: `2026-08-28T19:22:56.2017197+02:00`
- Ledger cutoff: index `182`, `R2OM-R03-P1-C2:CANDIDATE_TELEMETRY:COMPLETE`
- The R2 campaign may continue after this snapshot.
- Scientific result: `NOT_FINAL_CAMPAIGN_IN_PROGRESS`

## Observer gate

`PASS`

This observer performed read-only local forensics and created an independent evidence package outside the active R2 directory. It did not contact the active R2 agent, access the DUT, use SSH/JTAG/XDMA/MMIO/Vivado, acquire a hardware lock, modify `FPGA_AHD`, modify active R2 artifacts, or modify SSOT.

## Campaign identification

The active campaign is `AHD v41 R2 Hardware Causal Experiment — Owner-Mediated Continuation`, rooted at:

`C:\Users\Łukasz Suduł\Documents\ChatGPT\AHD_20260807\R2_OWNER_MEDIATED_CONTINUATION_STAGE`

It was distinguished from the historical `v41-research-r2-r1i-causal-hardware-executed` blocker package by all of the following:

- the Owner exclusivity receipt captured at `2026-08-28T10:08:52.027Z`;
- continuation provenance explicitly naming the old blocker and the later Owner-mediated continuation;
- current `R2OM-*` canonical run IDs;
- successful Formal safe-baseline establishment followed by the first accepted primary program event;
- the append-only active campaign ledger beginning at `2026-08-28T13:39:42.4511452Z` and growing through the snapshot cutoff.

The historical package remains a correct record of its own blocked attempt: engineering/scientific `BLOCKED`, `0/32` primary runs. It is not the current campaign.

## Campaign progress at cutoff

| Metric | Observation |
|---|---:|
| Frozen primary denominator | 32 |
| Completed valid primary arms | 8/32 |
| Primary progress | 25% |
| Countable telemetry rows present | 9 |
| Countable but uncommitted arms | 1 (`R2OM-R03-P1-C2`) |
| Fully completed frozen rounds | 2/8 |
| Active frozen round | R03 |
| C0 completed primary | 2/8 |
| C1 completed primary | 2/8 |
| C2 completed primary | 2/8 |
| C3 completed primary | 2/8 |
| Additional non-primary runs | 1 |

The additional non-primary run is `BASELINE_FORMAL_001`, a sealed `PRE_PROBE` / safe-baseline establishment observation. Its receipt explicitly says `PRIMARY_R2_RUN_ROLE=NO` and `R0_PRIMARY_RUN_COUNTABLE=NO`.

No supplemental, campaign-retry, cold-start, timing, robustness, or diagnostic run was present. Operational baseline parser/harness recovery attempts did not create scientific run rows.

## R09_C2 conclusion

`R09_C2` resolves to canonical `R2OM-R03-P1-C2`: execution sequence 9, frozen round R03, position 1, candidate C2/R1i-b.

- Classification: `PRIMARY_CAUSAL_RUN`
- Part of frozen 32-run denominator: `YES`
- Protocol deviation: `NO`
- Campaign retry: `NO`
- Cold-start/robustness/timing/supplemental: `NO`
- Predeclared: `YES`, matrix line 10
- Interim telemetry classification: `RECOVERED_PASS`
- Arm committed at cutoff: `NO`

The exact literal `R09_C2` does not appear in the active artifacts searched. The unique evidence-equivalent identifier is sequence index 9 / directory prefix `009_` combined with candidate C2. It started after execution slots 1–8 were committed, meaning after frozen rounds R01 and R02—not after all frozen rounds R01–R08.

Its telemetry `RETRY_COUNT=2` describes DUT transaction-level recovery inside the single scheduled arm. Its programming receipt records one invocation and zero programming retries. It is not a repeat of a scientific run.

At the cutoff, its countable candidate capture was complete, but safe restoration and final run commit were not. Consequently it is shown in the timeline but excluded from the completed-valid progress count of eight.

## Protocol check

Actual committed order exactly matched the frozen prefix:

- R01: C0 C1 C3 C2
- R02: C1 C2 C0 C3
- R03: C2 active at cutoff, uncommitted

Missing primary completions were sequence 9 in progress plus sequences 10–32 not started: 24 total. No duplicate primary ID, extra primary ID, classification rebinding, or denominator change was observed. The denominator remains 32.

The active agent had not executed more than the frozen 32 primary runs. The single pre-primary safe-baseline observation is legitimate control evidence outside the denominator, not primary-denominator expansion.

## Owner-mediated control

- Owner DUT exclusivity confirmation exists: `YES`, result `PASS`.
- Manual cold resets requested in the current continuation at cutoff: `0`.
- Owner cold-reset confirmations at cutoff: `0`.
- Formal cold-start trials at cutoff: `0`.
- Cold-start trials are distinguishable: `YES`; a separate predeclared C3 10x harness and naming scheme exists.

The primary orchestrator explicitly performs zero cold-start operations. The frozen R0 plan states that the later exact-C3 10-cold-start campaign is separate and is not pooled with primary factorial runs.

## Candidate identity verification

| Cell | Candidate | Existing-receipt SHA-256 | Result |
|---|---|---|---|
| C0 | exact R1h | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` | PASS |
| C1 | R1i-a | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` | PASS |
| C2 | R1i-b | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` | PASS |
| C3 | exact R1i | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | PASS |

The observer used existing identity and programming receipts and did not read or hash bitstreams.

## Scientific boundary

No final causal result is declared. In particular, this snapshot does not declare `M1_SUPPORTED`, `M2_SUPPORTED`, `BOTH_INDEPENDENTLY_SUFFICIENT`, or `COMBINED_EFFECT_REQUIRED`. Interim run classifications are recorded only as descriptive evidence.

## Package contents

- `R2_OBSERVER_SNAPSHOT_REPORT.md`
- `R2_OBSERVER_EXECUTION_TIMELINE.csv`
- `R2_OBSERVER_R09_C2_ANALYSIS.md`
- `R2_OBSERVER_PROTOCOL_CHECK.md`
- `R2_OBSERVER_SOURCE_MAP.md`
- `R2_OBSERVER_STATE.json`
- `R2_OBSERVER_SHA256_MANIFEST.txt`

See `R2_OBSERVER_SOURCE_MAP.md` for record-level reproduction anchors and `R2_OBSERVER_EXECUTION_TIMELINE.csv` for the complete identified-run chronology.
