# AHD v41 G2B-BS0 Recovery Inventory Report

## Result

- Engineering gate: **PASS**. The interrupted attempt was located and inventoried without resuming analysis.
- Interrupted attempt: **FOUND** at `C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831`.
- Salvageability: **PARTIALLY_RECOVERABLE_RESUME_FROM_CHECKPOINT**.
- Existing remote BS0 evidence before this recovery publication: **NONE**.
- Source state: **CHANGED_BUT_UNCOMMITTED** because the source checkout already contained unrelated untracked files; tracked source, index, branch, HEAD, and tree were unchanged by this recovery.
- Vivado executed during recovery: **NO**.
- Hardware/DUT/PCIe/DMA accessed during recovery: **NO**.
- SSOT modified: **NO**.

The static DCP/object identity work, semantic decomposition, CDC correlation, historical controls, worker source, and generated set scaffolding are reusable. No bounded `report_bus_skew` result, completed exact-scope `report_timing` result, binary-bisect result, or Gen12 methodology report was recovered.

## Authority and protection boundary

The authoritative project state was read from `lukaszsudul/AHD-diagnostic-evidence/project-current-state/` and independently from the local evidence checkout:

- `PROJECT_STATE_REV_AT_START = 3`
- `PROJECT_STATE_REV_AT_END = 3`
- project-current-state Git subtree: `90fabcb1a77a90a8d0a2ee1e237e4d8c56beb473`
- `PROJECT_STATE.json` SHA-256: `9ED040C2146C6938F7C4B90694396182D4E1B0C9BD2450675508415386001A14`

No source, active XDC, SSOT, existing evidence directory, Git stash, or working-tree entry was altered or removed. This task ran no Vivado executable or Tcl worker and performed no DUT or hardware operation.

## Relevant directories discovered

The targeted search established twelve relevant locations. Recovery-created evidence checkouts are not included in this count.

1. `C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831` — interrupted-attempt root.
2. `C:\FPGA\FPGA_AHD` — source checkout and pre-existing incident report.
3. `C:\FPGA\G2B_LUT1_AUDIT_TOOLS` — historical Group-9 worker source.
4. `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_12` — sealed Gen12 DCP and raw reports.
5. `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_LAUNCH_20260831_12` — Gen12 launch receipt/log.
6. `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1` — sealed recovery input, Group-9 objects/XDC, and incident worker receipt.
7. `C:\FPGA\G2B_LUT1_GEN12_RECOVERY_LAUNCH_20260831_01` — Gen12 recovery launch context.
8. `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260830_07B` — older methodology antecedent.
9. `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_11` — adjacent prior-generation evidence referenced by the analysis.
10. `C:\FPGA\V41_G2B` — G2B working context.
11. `C:\FPGA\V41_G2B_EVIDENCE` — local evidence/SSOT checkout.
12. `C:\Users\Łukasz Suduł\.codex\sessions\2026\08\31` — interrupted execution and evidence-scaffold session receipts.

The planned `C:\FPGA\G2B_BS0_REPRODUCER` directory did not exist and was not created.

## Interrupted-attempt footprint

`C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831` contains 190 files in 34 directories, totaling 360,647 bytes:

| Subtree | Files | Bytes | Role |
|---|---:|---:|---|
| `evidence_work` | 9 | 103,275 | Draft reports and static conclusions |
| `experiments` | 75 | 181,330 | EXP000-EXP006 receipts/logs plus planned metadata |
| `scripts` | 6 | 47,608 | Worker, runner, set generator, ledger builder, minimal XDC |
| `sets` | 99 | 28,320 | Full, semantic, and bisect candidate lists/manifest |
| root | 1 | 114 | Runtime note |

The published CSV inventories every file in that attempt, selected external provenance anchors, the two relevant Codex session receipts, and explicit rows for missing expected outputs. It contains 221 rows: 217 found artifacts and four `MISSING_EXPECTED` rows.

## Expected artifact checklist

The strict file-status reading treats a present file as partial when its own text or the interrupted evidence index marks final validation as pending.

| Expected output | Status | Recovery note |
|---|---|---|
| `V41_G2B_BS0_MAIN_REPORT.md` | PARTIAL | Draft; dynamic controls and final disposition pending |
| `G2B_BS0_GROUP9_SEMANTIC_DECOMPOSITION.md` | PARTIAL | Static decomposition is substantively complete; dynamic cross-check pending |
| `G2B_BS0_GROUP9_BISECT.csv` | MISSING_EXPECTED | No bisect result exists |
| `G2B_BS0_TIMING_METHODOLOGY_REVIEW.md` | PARTIAL | Gen12 methodology result absent |
| `G2B_BS0_CONSTRAINT_VALIDITY_DECISION.md` | PARTIAL | Provisional static classification only |
| `G2B_BS0_GROUP9_CDC_CORRELATION.md` | PARTIAL | Correlation is substantively complete; final cross-check was marked pending |
| `G2B_BS0_MINIMAL_REPRODUCER.md` | PARTIAL | Recipe only; no completed minimal reproducer |
| `G2B_BS0_EXPERIMENT_LEDGER.csv` | MISSING_EXPECTED | Builder was authored but not executed |
| `G2B_BS0_STATE.json` | MISSING_EXPECTED | Not created |
| `G2B_BS0_EVIDENCE_INDEX.md` | PARTIAL | Draft index with pending outputs |
| `G2B_BS0_SHA256_MANIFEST.txt` | MISSING_EXPECTED | Not created |

Strict expected-output total: **0 complete, 7 partial, 4 missing of 11**. This does not negate the stage-level conclusion that the static semantic decomposition and CDC correlation work themselves are complete and reusable.

## FPGA_AHD Git state

Read-only Git inventory of `C:\FPGA\FPGA_AHD`:

- branch: `main`
- HEAD: `be94f88ee8d179f12928ab791bdae27c22cd1762`
- tree: `e128ff47a5e21e8131971f5e5caa7657e2eccc7f`
- upstream `origin/main`: `be94f88ee8d179f12928ab791bdae27c22cd1762` (`+0/-0`)
- staged tracked modifications: none
- unstaged tracked modifications: none
- stash entries: none
- pre-existing untracked content: 46 files, confined to `.codex_tmp/g2b_audit_report/` and `reports/Raport_incydentu_G2B_LUT1_2026-08-31.{docx,md}`
- sorted porcelain baseline SHA-256 (UTF-8, LF-joined, no trailing LF): `947A17F4896EC868DAF028B54749E1EEA827CD377D2A60830638711F7FA1ABDF`

Visible remote refs were recorded at recovery time:

| Remote ref | Object |
|---|---|
| `origin/HEAD` | `be94f88ee8d179f12928ab791bdae27c22cd1762` |
| `origin/main` | `be94f88ee8d179f12928ab791bdae27c22cd1762` |
| `origin/archive/v41-xdma-pre-v40.1.0-20260817` | `f3cfa6bf72f3cdcc5688f3a28ff16e80afc5d875` |
| `origin/archive/v42-ready-d3-r4-7707243` | `770724344ae35fb65f177c04b050f666e70439dc` |
| `origin/archive/v42-ready-d3-r5-01acf49` | `01acf496b2b920c40f8564b08b9cefd9c7186e5a` |
| `origin/baseline/v41-r1i-qualified-poc` | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| `origin/dev/v41-xdma-offline-next` | `8464af66611f7c22b8a36a4aab915d598eedda3f` |
| `origin/diag/v41-nvp-address-ack-probe-r1d` | `1beb70536d8e57305813f377a9e2c0e810b0bfc0` |
| `origin/diag/v41-nvp-axi-clock-measure-r1` | `0af44dee3bc091eaff805704dd5c687eeaa01bbd` |
| `origin/diag/v41-nvp-i2c-25khz-r1` | `f007dc172d43d30b02729755e60382f8ce3dbff4` |
| `origin/integration/v41-r1i-gen2-g2a` | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| `origin/release/v40.1.0-nvp` | `55ce0df41552bb74e0923f89eff43977b040f2e5` |
| `origin/v41/xdma` | `f3cfa6bf72f3cdcc5688f3a28ff16e80afc5d875` |
| `origin/v41/xdma-v40.1.0-base` | `c89e88bcdf389614c884fb129e8b2d42a585bccb` |

No interrupted-task commit was found. `SOURCE_STATE = CHANGED_BUT_UNCOMMITTED` describes the pre-existing untracked files, not a recovery mutation.

## Existing remote evidence audit

Before publication, `lukaszsudul/AHD-diagnostic-evidence` `main` was:

- HEAD: `a7db236b56340095f3521ec195d2a3b49d10f956`
- tree: `a3787fb50b411e578cc440804c142133ae7c6fcc`

The exact prior directory `v41-development-g2b-bs0-bus-skew-group9-isolation` was absent. Full-history searches for `G2B-BS0`, `group9`, and `OWNERSHIP_AXI_TO_SOURCE` found no matching evidence commit. Eleven unrelated files containing `BUS_SKEW` in their names belong to earlier G2A/NVP material and are not BS0 publication. Therefore:

- `EVIDENCE_PUBLICATION_STATUS_BEFORE_RECOVERY = NONE`
- existing BS0 evidence commit: `NONE`

## Reconstructed experiment sequence

| Experiment | Intended operation | Recovered boundary | Classification |
|---|---|---|---|
| EXP000 | Initial worker launch | Argument/locale usage failure before DCP/report work | FAILED PRE-WORKER |
| EXP001 | First DCP worker | DCP opened; invalid `check_route_status` invocation stopped progress | PARTIAL |
| EXP002 | Exact 58x19 `report_timing` control | DCP opened, route status/XDC/object resolution completed, timing update entered, then 600 s timeout; no report file | PARTIAL |
| EXP003 | 1x1 semantic timing probe | Initialization timeout; command start `NONE` | STARTED, NO RESULT |
| EXP004 | 1x1 semantic timing probe | Initialization timeout; command start `NONE` | STARTED, NO RESULT |
| EXP005 | Full 58x19 bounded `report_bus_skew` | Initialization timeout; command start `NONE`; zero command elapsed time | STARTED, NO BUS_SKEW EXECUTION |
| EXP006 | Full 58x19 timing control | Initialization timeout; command start `NONE`; zero command elapsed time | STARTED, NO RESULT |
| EXP007-EXP009 | Methodology/topology/minimal follow-ups | Planned metadata only | NOT_STARTED |

EXP004, EXP005, and EXP006 had overlapping Vivado initialization windows. The overlap is proven; it is not proof of why they timed out. Future work must serialize workers.

There are zero `report_bus_skew.rpt`, `report_timing.rpt`, `report_methodology.rpt`, `command_started.marker`, `command.txt`, or `applied_constraints.xdc` files in the interrupted-attempt tree. EXP002 predates the later command-marker scheme, but its console proves entry into the timing operation. The unexecuted ledger builder must not be trusted to reclassify EXP002 automatically.

The early receipts also have a preserved provenance limitation. EXP000/EXP001 record worker SHA-256 `E0737EC308508E1DC8E8340C68C15A451D8C10487964ADA853ECE3CB1D84EFF8`, and EXP002 records `A3BA0772543C92588C394DBE0F7106672302D0BB7E142B21526EE75E8B98088D`. Neither historical worker body survives in the 190-file attempt tree; the referenced path now contains the later `B17B15A3FC99F53EEA39F6BAA3BCA754C1BA54B9F08D353C109998500F2A4749` worker. EXP000-EXP002 use a 26-field receipt schema, while EXP003-EXP006 use 30 fields with explicit command/timeout-phase fields. Locale-rendered numeric arguments (`3,000`/`3.000`) are another early portability warning. These facts do not invalidate the console/timeout boundaries, but the early exact worker sources are not reproducible.

## Recovered conclusions

Only artifact-supported conclusions were accepted:

1. Both sealed Gen12 DCP copies are byte-identical: 57,900,063 bytes, SHA-256 `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`.
2. The preserved Group-9 object inventory resolves exactly 58 sources and 19 destinations; object-list SHA-256 is `CE4E8A35CB82CCD0A85AEBF340B997D74FEF9250C86BA76C61769E332079F4DB`.
3. The 58 sources are one encoded token: 2 slot bits, 24 generation bits, and 32 epoch bits. The 19 receivers divide into five semantic roles. This is a high-confidence static decomposition.
4. Static semantic classification is heterogeneous Class B: `OWNERSHIP_AXI_TO_SOURCE` spans distinct control roles and should not be treated as a homogeneous payload bus. This is not a completed dynamic proof of final endpoint safety.
5. The provisional constraint decision `VALID_WITH_NARROWER_ENDPOINT_SCOPE` is medium-confidence and partial. It requires exact-scope timing, methodology, and BUS_SKEW controls before final adoption.
6. Historical incident evidence shows Groups 1-8 completed and two unbounded Group-9 attempts remained running/stalled. This localizes the historical symptom but does not supply a bounded current result.
7. A broad historical setup report contains `axis_slot_reg[1]/C -> source_ownership_fatal_deferred_reg/D` at 5.939 ns, 8 logic levels, fanout 142. It is not the missing exact 58x19 control.
8. Gen12 CDC raw counts are CDC-1=423, CDC-10=2, CDC-13=2. The correlation found 89 exact group-cell overlap rows, four direct Group-9 source-to-sink cases, and no CDC-10/13 overlap.
9. Current Gen12 TIMING-32/34/37/38/39 presence is unresolved because no Gen12 methodology report exists. Older Gen7B antecedent evidence contains TIMING-34=8 and TIMING-39=2 only; it is not current proof.
10. No smallest pathological subset, binary bisect, completed semantic-subset timing result, final constraint decision, or executed minimal reproducer exists.
11. The current attempts neither strengthen nor weaken a Vivado query-pathology hypothesis: EXP003-EXP006 failed in initialization before their target commands.
12. The exact historical worker sources for EXP000-EXP002 are missing; their receipts remain usable only for the boundaries supported by preserved consoles/results, not for worker-source reproduction.

Exact evidence-file hashes and confidence levels are in `G2B_BS0_RECOVERED_FINDINGS.md`.

## Interruption point

- `LAST_COMPLETED_ACTION`: EXP005 finalized an immutable pre-command initialization-timeout receipt.
- `LAST_STARTED_BUT_INCOMPLETE_ACTION`: ledger/final evidence-package assembly; `Build-G2BBs0Ledgers.ps1` was saved and syntax-validated, but it was not executed and no ledger, state, bisect CSV, or manifest appeared.
- `LAST_ARTIFACT_TIMESTAMP`: `2026-08-31T20:59:04.7157077+02:00` for `EXP005_FULL_BUS_SKEW\experiment_result.txt`, 1,631 bytes, SHA-256 `EFF524FE16B471ED7F6BE87B3FAFF7BBA0E922C7EFD80C04A2BEB286A2AEF2F1`.

The approximately 56-minute root-session interruption is most consistent with Codex analysis/evidence packaging while bounded workers were still in initialization. Independent worker harnesses subsequently finalized their timeout receipts, which explains the later 20:59 artifact. No preserved marker shows an active `report_bus_skew` command. The precise external execution-environment failure is not provable from local artifacts.

## Salvageability and continuation boundary

`SALVAGEABILITY = PARTIALLY_RECOVERABLE_RESUME_FROM_CHECKPOINT`.

The checkpoint is static, not a completed dynamic subset checkpoint. Reuse the sealed DCP identity, Group-9 object inventory, static semantic decomposition, CDC correlation, raw historical controls, and reviewed set/worker scaffolding. Preserve EXP000-EXP006 as non-gating receipts. No completed dynamic subset/experiment number is safe to claim, so the next attempt must use a fresh isolated directory and new experiment IDs.

The exact next operation is defined in `G2B_BS0_RECOVERY_RESUME_PLAN.md`. Missing dynamic results are classified `MISSING_REQUIRES_FUTURE_G2B_BS0_CONTINUATION`; this recovery did not compensate by re-executing Vivado.

## Publication boundary

This report and its eight companion files are published only in the new directory `v41-development-g2b-bs0-recovery-inventory`. No pre-existing BS0 directory is modified. The containing Git commit is the authoritative evidence identity; its exact SHA is recorded by push and remote read-back in the task completion response because a commit cannot self-contain its own SHA.
