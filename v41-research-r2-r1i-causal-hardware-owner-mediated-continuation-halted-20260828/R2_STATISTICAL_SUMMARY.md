# AHD v41 R2 Primary Campaign Statistical Summary

Generated offline: `2026-08-28T18:38:05.2291659Z`

## Result

- Frozen primary design: 32 runs, 8 runs per candidate, counterbalanced order.
- Completed and countable: **10/32**.
- Not run after the safety halt: **22/32**.
- Halt point: sequence 10, `R2OM-R03-P2-C3`, exact C3.
- Halt classification: `INCONCLUSIVE` with `C3_NON_CLEAN_SUSPEND_BLOCK`.
- Safe Formal baseline restored after every completed run: **10/10**.
- Scientific causal result: **BLOCKED**.
- Partial-data disposition: **INCONCLUSIVE; no causal mechanism assignment**.

No C1/C2/C3 cell reached the frozen 8-run denominator. The frozen O1-O4 causal interpretation matrix therefore cannot be applied. In addition, the observed C3 prefix is mixed (two `CLEAN_PASS`, one `INCONCLUSIVE`), and the frozen R0 plan requires a campaign suspension on any non-clean C3 run. The scientific gate is therefore `BLOCKED`; the partial observations remain inconclusive and this report makes no causal-mechanism assignment from the incomplete prefix.

## Classification counts

| Candidate | Completed | CLEAN_PASS | RECOVERED_PASS | FAIL | INCONCLUSIVE | Not run |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| C0 — exact R1h | 2 | 0 | 0 | 2 | 0 | 6 |
| C1 — R1i-a | 2 | 0 | 0 | 0 | 2 | 6 |
| C2 — R1i-b | 3 | 1 | 2 | 0 | 0 | 5 |
| C3 — exact qualified R1i | 3 | 2 | 0 | 0 | 1 | 5 |
| **Total** | **10** | **3** | **2** | **2** | **3** | **22** |

## Descriptive telemetry

| Candidate | INIT_ERROR sum | Total autoinit NACK | Retry count | Recovered count | Video present | Frame rate mean Hz | Frame rate range Hz |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | --- |
| C0 | 2 | 24 | 0 | 0 | 0/2 | 0.000000 | 0.000000-0.000000 |
| C1 | 0 | 0 | 0 | 0 | 2/2 | 25.795166 | 25.794836-25.795496 |
| C2 | 0 | 3 | 3 | 3 | 3/3 | 25.137540 | 24.806087-25.797844 |
| C3 | 0 | 0 | 0 | 0 | 3/3 | 25.126827 | 24.799186-25.776567 |
| **Total** | **2** | **27** | **3** | **3** | **8/10** | — | — |

These are descriptive summaries of the stopped, order-dependent prefix; they are not estimates for the planned 32-run campaign. No confidence interval, cell-level PASS/FAIL, or mechanism-level hypothesis result is calculated from this truncated denominator.

## Evidence observations

- Both completed C0 observations reproduced the negative control: `FAIL`, `INIT_ERROR=1`, nonzero autoinit NACK, and no video. No unexpected C0 pass occurred in the observed prefix.
- Both completed C1 observations had zero autoinit NACK/retry/recovery and video present, but were `INCONCLUSIVE` because the captured frame rates (`25.795496` and `25.794836` Hz) failed the frozen frame-rate band.
- C2 produced one `CLEAN_PASS` and two `RECOVERED_PASS` observations. The recovered observations recorded REGADDR NACK/retry/recovered counts of 1/1/1 and 2/2/2. Frozen R0 rules do not treat these as clean causal success.
- C3 produced two `CLEAN_PASS` observations. Sequence 10 had clean autoinit counters and video present, but its `25.776567` Hz frame rate failed the frozen `24.803727 ± 0.10 Hz` band, producing `INCONCLUSIVE` and the required positive-control suspension.
- Recovery activity in C2 and the mixed/non-clean C3 prefix satisfy frozen margin/validity review triggers. R0 requires the C3 validity issue to be resolved before any R3 sweep or stronger mechanism claim.

## Source and hash binding

| Source | SHA-256 | Role |
| --- | --- | --- |
| `R2_OWNER_MEDIATED_CONTINUATION_STAGE/R2_RUN_MATRIX.csv` | `59322EA26F60143AF211C2F9D6F869DDC78FA3B8A808C8F6E9AEDE13BD1F6AFF` | Frozen 32-row order |
| `R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/R2_PRIMARY_CAMPAIGN_CONFIGURATION.txt` | `9470F8314BA040E29FDEC7AC48DAE6BE843488634CBE9539A978A5E9FCCA682F` | Frozen identities and campaign configuration |
| `R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/R2_PRIMARY_RAW_RESULTS_APPEND_ONLY.csv` | `A4A55541D1457202D490C3F7855810B0C79049984FE991CDCF306D648F8189A0` | Ten immutable raw result rows |
| `R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/R2_PRIMARY_RUN_COMPLETIONS_APPEND_ONLY.csv` | `E3A2B5A52B10D4140FDBB0D5E620EEDE09A0698F402E354F3EBE45E70F9C9D7B` | Ten immutable completion rows |
| `R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/R2_PRIMARY_CAMPAIGN_LEDGER.jsonl` | `AA110E907571C9C1CD6E1B454A5284315C816C7507AC02E0DFE512342ADB1914` | Append-only event chain |
| `R2_PRIMARY_CAMPAIGN_ORCHESTRATED_AFTER_R02/R2_PRIMARY_CAMPAIGN_HALT.txt` | `5939346939DBAA7B934662A4718095045BAE22CA3A341847032335E22B36062B` | Authoritative halt receipt |
| `v41-research-r0-r1i-causal-isolation-design/R0_R1I_CAUSAL_ISOLATION_EXPERIMENT_PLAN.md` | `2F687813F0A299CE72E160E3BF5B4F35E334825A54002A2F43D00A0BCFD8BD6C` | Frozen run/classification protocol |
| `v41-research-r0-r1i-causal-isolation-design/R0_OUTCOME_INTERPRETATION_MATRIX.csv` | `26B34E14F813DF3D6CB27469D09396942B657FE3B98182720B6CD1DB301D6836` | Frozen causal mapping |
| `v41-research-r0-r1i-causal-isolation-design/R0_MARGIN_CHARACTERIZATION_TRIGGER.md` | `04261D83A28017E880B01B474D3A1A210D0B276E2B7FF99F87B02BBD38E7F92D` | Frozen R3/validity triggers |

## Publication-input lineage

- `R2_RAW_RESULTS.csv` is a byte-identical copy of the immutable append-only raw source; both hashes are `A4A55541D1457202D490C3F7855810B0C79049984FE991CDCF306D648F8189A0`.
- `R2_RUN_MATRIX.csv` joins the frozen order to the immutable raw and completion rows for sequences 1-10. Sequences 11-32 remain explicitly `NOT_RUN_AFTER_HALT`; no result fields were imputed.
- Normalized matrix SHA-256 at generation: `019695FCC3A0AAD9B9E8A295428010A2C916C03DD5D378369DD032C6E8AA9B3A`.
