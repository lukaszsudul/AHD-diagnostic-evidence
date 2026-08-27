# AHD v41 R0 Evidence Index

## Scope

This is a sanitized design-only evidence set. It contains no bitstream, proprietary source tree, credential, host address, hardware transcript, or authentication material. Small source semantics, public hashes, and source anchors are included only to make the future causal variants auditable.

## Authoritative inputs

| Input | Identity / location | Use |
| --- | --- | --- |
| Qualified public evidence | `https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/main/v41-nvp-r1i-r2-qualified-poc-hardware-evidence` | Frozen A/B outcome, telemetry, artifacts, limitations |
| R1h base | commit `c4f4bfcf577c92c3021d1fe83c05878dd12e001c`, tree `161e561f007912d73dba93c5ecd78e3cc3a6955b` | Exact control/source base |
| Qualified R1i | commit `20c3323d79d3896edc586d6db1df7deee60f9e41`, tree `70d801fd7a879080da399bfa9ee95fd6eb008e16` | Frozen positive/source base for C1/C2 |
| Exact source patch | public `final/R1H_TO_R1I_SOURCE.patch`, SHA-256 `01A2CD8C5F87B9F532F1FA6152F7D2DC0A039525345F8AB1AAE6A4F2CCD55238` | Authoritative changed-source semantics |
| R1i bitstream | SHA-256 `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | Exact C3 |
| R1h bitstream | SHA-256 `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` | Exact C0 |
| Formal Phase-2 bitstream | SHA-256 `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | Preferred safe restoration |
| Evidence `origin/main` before publication | `955ba0cd2462f4dec9dcb086175ab6eca57365bb` | Publication ancestry receipt |

## Produced artifacts

| Artifact | Purpose |
| --- | --- |
| `README.md` | Scope, result, and navigation |
| `R0_R1I_CAUSAL_ISOLATION_EXPERIMENT_PLAN.md` | Complete 21-section main report |
| `R0_VARIANT_DEFINITION_MATRIX.csv` | Machine-readable C0/C1/C2/C3 semantics and controls |
| `R0_OUTCOME_INTERPRETATION_MATRIX.csv` | Frozen result mapping and exceptional cases |
| `R0_COLD_START_PROTOCOL.md` | Exact-R1i 10-consecutive-cold-start robustness protocol |
| `R0_INIT_DONE_TIMING_PROTOCOL.md` | Counter/wall-clock timing and 62.5/125 MHz falsification protocol |
| `R0_MARGIN_CHARACTERIZATION_TRIGGER.md` | Mandatory R3 rules and first margin sweep |
| `R0_R1_IMPLEMENTATION_CONTRACT.md` | Exact source/change/build/hardware boundary for R1 |
| `R0_STATE.json` | Machine-readable gate state and non-action attestations |
| `R0_EVIDENCE_INDEX.md` | This provenance/index file |
| `R0_SHA256_MANIFEST.txt` | SHA-256/size seal for all other published files |

## Read-only inspection receipts

- Public evidence directory and README were read from GitHub/main.
- Published source provenance, changeset, exact patch, artifact identity, measurements, telemetry, and limitations were inspected from an isolated evidence clone.
- The existing `C:\FPGA\FPGA_AHD` checkout was queried read-only and remained clean; the historical qualified objects were not fetched into or written to that checkout.
- The exact published patch supplied the qualified state/timing anchors.
- Published lifecycle telemetry supplied A1/B1 `cnt_at_init_done` values; routed timing supplied the 62.5 MHz implementation expectation, while the missing independent host wall-clock bracket remains explicitly unmeasured.

## Explicit non-actions

- FPGA_AHD source repository modified: **NO**
- Qualified R1i baseline modified: **NO**
- Research branch/worktree created: **NO**
- Firmware/bitstream built: **NO**
- Vivado executed: **NO**
- Hardware accessed: **NO**
- R1 started: **NO**

## Manifest and publication note

`R0_SHA256_MANIFEST.txt` hashes every other file in this directory and intentionally excludes itself. The containing Git commit cannot embed its own SHA without a self-reference; the authoritative publication commit is therefore recorded by the push receipt, remote read-back, and task final response. `R0_STATE.json.remote_commit` remains the schema-defined empty string inside the sealed commit.
