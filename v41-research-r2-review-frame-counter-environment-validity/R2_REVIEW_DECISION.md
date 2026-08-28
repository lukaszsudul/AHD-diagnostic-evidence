# R2 Review Decision

## Formal review disposition

| Field | Decision |
|---|---|
| Review gate | PASS |
| Primary result | `MEASUREMENT_ARTIFACT_PROBABLE` |
| Confidence | `HIGH` |
| Integer 25/26-event quantization | `CONFIRMED` |
| Real timing change | `NOT_ABSOLUTELY_EXCLUDED` |
| Exact C3 identity | `CONFIRMED_EXACT_R1I`; `C3_IDENTITY_DRIFT=NO` |
| Independent C3 abnormality | `NO_RECORDED_INDEPENDENT_ABNORMALITY` |
| Historical halt | PRESERVE |
| Existing ten runs | `KEEP_RAW_DATA_BUT_PRIMARY_CLASSIFICATION_INVALID` |
| Historical labels | PRESERVE |
| Retrospective reclassification | NOT RECOMMENDED; DO NOT MIX METHODS |
| Protocol amendment | `PROPOSED — NOT AUTHORIZED` |
| Campaign decision | `NEW_CONTROL_EXPERIMENT_REQUIRED` |
| Halted R2 sequence-11 continuation | PROHIBITED BY MIXED-METHOD CONFOUND |
| New campaign start if separately authorized | new sequence 1; new denominator |
| R3 | `STILL_REQUIRED` |
| Hardware operations in review | 0 |
| Firmware/source changes in review | 0 |
| SSOT operations in review | 0 |
| PROJECT_STATE revision start/end | `1 / 1` |

## Decision basis

The one-second estimator has approximately `0.992 Hz` integer resolution against a `±0.10 Hz` pass band. All eight video-present observations occupy exact 25- or 26-event branches, across C1/C2/C3, with overlapping actual monotonic windows and stable SAV/VCLK rates. All ten printed rates independently recalculate from raw monotonic captures whose aggregate hashes match the historical committed receipts. Exact C3 run 10 has no independent identity, autoinit, SCL, recovery, timeout, or video-presence abnormality.

This establishes the quantization defect. Because the evidence lacks external event timestamps or an independent video analyzer, a real timing change is not excluded absolutely; the primary conclusion is therefore `PROBABLE`, not `CONFIRMED`.

## Authority boundary

This review is advisory evidence. It does not authorize:

- reclassification;
- protocol mutation;
- FPGA programming;
- DUT reset or power cycle;
- resumption of R2;
- R3 execution;
- SSOT modification.

The historical ten rows and labels remain immutable. Their raw identity/autoinit/recovery evidence remains valid, but their primary classifications cannot be pooled with future corrected-method observations. Owner/Architect approval is required for the prospective amendment, a separate measurement-control validation, and any new causal campaign. Fresh Owner DUT exclusivity is required before any new hardware operation.

## Recommended next action

Owner/Architect reviews and either approves or rejects `R2_MEASUREMENT_PROTOCOL_AMENDMENT_PROPOSAL.md`. If approved, predeclare and execute a separate measurement-control validation; only after it passes should a new full balanced causal campaign be authorized from its own run 1. Do not resume sequence 11 and do not start R3 in this review.
