# R1h-R2 required final-block field mapping

Status: `READY_FOR_INDEPENDENT_FINAL_REPORT_AUDIT_AND_SEAL`

This task-local mapping controls the final §21 block. The owner prompt contains
178 unique keys. The authoritative task-local report preserves those keys in
exact prompt order. No publication-only value is invented before sealing.

## Identity and historical R1h fields

| Keys | Value source |
|---|---|
| `TASK`, `EXPERIMENT_NAME`, `CONTINUATION_REVISION` | exact owner prompt |
| `R1H_SOURCE_COMMIT`, `R1H_SOURCE_TREE` | P0 Git identity plus prebuild and build provenance receipts |
| `R1H_EVIDENCE_COMMIT`, `R1H_AUTHORITATIVE_REPORT_SHA256`, `R1H_EVIDENCE_PACKAGE_SHA256` | exact public R1h evidence verification |
| `R1H_TERMINAL_CLASSIFICATION`, `R1H_TERMINAL_ASSERTION` | immutable historical terminal R1h report; these are not the R1h-R2 terminal classification |

The current continuation classification is intentionally reported outside the
fixed §21 key set:

```text
R1H_R2_TERMINAL_CLASSIFICATION=BLOCKED_R1H_R2_POST_SYNTH_RESOURCE_OR_MAPPING_GATE
R1H_R2_TERMINAL_ERROR=BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING
CAUSE_DISAMBIGUATION=POST_SYNTH_RESOURCE_MARGIN_GATE_FAIL_LUT_ONLY
```

## Harness, dry-run and semantic preflight

| Keys | Exact evidence |
|---|---|
| `R1H_R2_BUILD_HARNESS_CORRECTION_MODE` through `COMPILE_ORDER_RECORDED` | `04_PROJECT_SETUP_DRY_RUN/R1H_R2_PROJECT_SETUP_DRY_RUN_RESULT.txt` and independent P3 audit |
| `PROJECT_SETUP_SEMANTIC_GATE`, `PROJECT_SETUP_DRY_RUNS`, `PROJECT_SETUP_DRY_RUN` | same exact dry-run receipt; one invocation only |
| `SEMANTIC_ELABORATION_PREFLIGHTS` through `PROBE_INDEX_WRAPPER_BINDING` | `05_SEMANTIC_ELABORATION/run_01/R1H_R2_SEMANTIC_ELABORATION_RESULT.txt` and independent P4 audit |

## No-source-change and provenance

| Keys | Exact evidence |
|---|---|
| `FPGA_RTL_SOURCE_CHANGES`, `TRACKED_BUILD_HARNESS_COMMITS` | corrected harness audit and P5 224/224 tree equality |
| `BUILD_PROVENANCE_COMMIT`, `BUILD_PROVENANCE_TREE` | `06_BUILD/FULL_BUILD/R1H_BUILD_PROVENANCE.txt` |
| `R1H_RTL_BLOBS_UNCHANGED` through `R1H_STATISTICAL_PLAN_UNCHANGED` | finalized P5 manifest and independent prebuild release audit |

## Synthesis, primitives and resource gate

| Keys | Exact evidence |
|---|---|
| `R1H_R2_BIT_SHA256`, `R1H_R2_ROUTED_DCP_SHA256` | nonexistence after terminal post-synth gate; use `NOT_GENERATED` |
| `FAILED_RECORD_PAYLOAD_RAMB18` through `FAILED_RECORD_PAYLOAD_RAMD64E` | `06_BUILD/FULL_BUILD/R1H_POST_SYNTH_PAYLOAD_PRIMITIVE_INVENTORY.txt` and resource gate receipt |
| `MMIO_READ_SERVICE`, both combinational-mux keys | exact unchanged R1h architecture, semantic/source gates, and full-top payload mapping; fixed values from contract |
| `FULL_CLEAN_BUILDS` | atomic one-build sentinel plus terminal receipt |
| `POST_SYNTH_SLICE_LUTS` through `POST_SYNTH_RAMB36` | exact post-synthesis resource gate receipt |
| `POST_SYNTH_RESOURCE_MARGIN_GATE` | `FAIL`: Slice LUT 19,255 exceeds 18,720 by 535; registers 20,395 pass 37,440 |
| `SYNTHESIS` | `PASS`, exact terminal and resource receipts plus Vivado log |
| `OPT_DESIGN` through `SOURCE_COMMIT_TO_BIT_PROVENANCE` | terminal receipt and build Tcl ordering; use NOT-RUN/NOT-AVAILABLE, never zero or PASS |

## Frozen scientific contract

| Keys | Exact evidence |
|---|---|
| `SCIENTIFIC_SCOPE_REDUCTION` | P5 exact 224/224 source identity and inherited equivalence evidence |
| `FAILED_RECORD_CAPACITY` through `TOTAL_TARGET_PHASE_OPPORTUNITIES` | exact owner contract and build provenance constants |

## Hardware, analysis and final state

| Keys | Exact evidence |
|---|---|
| `PAIR_COUNT_PLANNED` | owner contract, value 3 |
| `PAIR_COUNT_VALID` | explicit pair receipts, value 0 |
| `BOOTSTRAP_RUN`, `BOOTSTRAP_RESULT` | `11_BOOTSTRAP/R1H_R2_BOOTSTRAP_NOT_RUN_RECEIPT.txt` |
| all `A1`/`B1`, `A2`/`B2`, `A3`/`B3` fields | pair receipts in `12_PAIR_1`, `13_PAIR_2`, `14_PAIR_3`; all `NOT_RUN_BUILD_BLOCKED` |
| process and statistical classification fields | `15_ANALYSIS/R1H_R2_STATISTICAL_ANALYSIS_NOT_RUN_RECEIPT.txt`; all `NOT_RUN_NO_HARDWARE_DATA` with the explicit R7 historical caveat |
| four root-cause/analogue claims | frozen required values `NO` |
| `FINAL_ACTIVE_IMAGE` through `FINAL_DONE` | `10_HARDWARE_PRECHECK` and `11_BOOTSTRAP` receipts; not freshly verified; R7 values historical only |
| program/reboot/driver and prohibited-action counters | explicit hardware receipts plus absence of hardware artifacts; all zero |

## Prompt and publication fields

| Keys | Exact evidence / draft rule |
|---|---|
| `OWNER_PROMPT_SHA256` | `00_R1H_INPUT/OWNER_PROMPT_VERBATIM_SHA256.txt`: `395E5DDE...02A5` |
| `EVIDENCE_PACKAGE_SHA256` | `SEE_EXTERNAL_SHA256_SIDECAR_NONCIRCULAR`; the actual digest is recorded outside the package/report after ZIP creation |
| `EVIDENCE_REPOSITORY_COMMIT` | `SEE_EXTERNAL_PUBLICATION_RECEIPT`; the actual commit is unavailable before publication |
| `PUBLIC_REMOTE_VERIFICATION` | `SEE_EXTERNAL_PUBLICATION_RECEIPT`; the actual result is unavailable before commit-pinned verification |
| `NEXT_ACTION` | exact required owner-prompt text |

## Finalization invariants

Before sealing, an independent checker must establish:

```text
REQUIRED_KEYS=178
REQUIRED_KEYS_UNIQUE=178
REPORT_KEYS=178
REPORT_KEYS_UNIQUE=178
KEY_ORDER_EQUAL_TO_OWNER_PROMPT=PASS
BLANK_REQUIRED_VALUES=0
CONTRADICTORY_VALUES=0
HARDWARE_MEASUREMENT_NUMERIC_ZERO_SUBSTITUTIONS=0
FORMAL_PHASE2_FRESHLY_RECONFIRMED=NO
INDEPENDENT_BUILD_MONITOR_AUDIT=PASS_SHA256_0B1047FA437375890C0BF2D81F8F1C385B552CB38358091B9C990571F6EF1856
INDEPENDENT_POST_SYNTH_AUDIT=PASS_SHA256_7AC5BA922A2C4F3DB9C7301BBB81DD7EF74BF0889B3EBC2A26C3C7B0D641224E
PUBLICATION_FIELDS_RESOLVED_ONLY_AFTER_SEAL=YES
```
