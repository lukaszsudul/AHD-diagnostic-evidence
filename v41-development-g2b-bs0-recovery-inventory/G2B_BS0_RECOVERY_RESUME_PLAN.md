# G2B-BS0 Recovery Resume Plan

## Resume classification

`PARTIALLY_RECOVERABLE_RESUME_FROM_CHECKPOINT`

The available checkpoint is the completed static identity/semantic/CDC checkpoint. There is no completed dynamic subset or experiment-number checkpoint. This plan is documentary only and was not executed by the recovery task.

## Work that must not be repeated

1. Do not re-copy or re-derive the sealed Gen12 DCP identity unless an integrity check fails.
2. Do not repeat the 58-source/19-destination object inventory.
3. Do not repeat the static slot/generation/epoch semantic decomposition.
4. Do not repeat the completed static CDC correlation.
5. Do not repeat historical extraction showing Groups 1-8 completed and the older Group-9 attempts stalled.
6. Do not overwrite, renumber, reinterpret, or delete EXP000-EXP006. They are immutable non-gating receipts.
7. Do not run the existing ledger builder blindly. EXP002 predates command markers, so its classification logic must first be corrected and reviewed.
8. Do not claim exact worker-source reproducibility for EXP000-EXP002. Their recorded worker hashes identify two historical bodies that are no longer present.

## Authoritative reusable artifacts

| Artifact | SHA-256 | Authority/use |
|---|---|---|
| `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp` | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` | Sealed design checkpoint |
| `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\workers\09_OWNERSHIP_AXI_TO_SOURCE\attempt_01\09_OWNERSHIP_AXI_TO_SOURCE_OBJECTS.txt` | `CE4E8A35CB82CCD0A85AEBF340B997D74FEF9250C86BA76C61769E332079F4DB` | Exact 58x19 object identity |
| `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\workers\09_OWNERSHIP_AXI_TO_SOURCE\attempt_01\09_OWNERSHIP_AXI_TO_SOURCE_ISOLATED.xdc` | `06F27BB2D3E5E6D8691274F7C9D28A8C560F218ADCDD53D173ECFA6AE696A754` | Historical isolated Group-9 XDC reference; do not activate in source |
| `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\BUS_SKEW_GROUPS\ROUTED_TIMING_WITHOUT_BUS_SKEW_SEMANTIC_PASS_2.xdc` | `A05AF5431E521BBC8812DAAE5574CC31D4E7E3BE89DCA0E41974462383BE3071` | Historical base XDC reference; do not activate in source |
| `C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831\evidence_work\G2B_BS0_GROUP9_SEMANTIC_DECOMPOSITION.md` | `AE2A006958569588402399055A46172AE44EA50E883C4DA58172CDBC7E1D6B4F` | Completed static semantic checkpoint |
| `C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831\evidence_work\G2B_BS0_GROUP9_CDC_CORRELATION.md` | `2D4C81336B32B00FE0AC70541624AB2935D22C85E6C98ECA37D67309B819ECA1` | Completed CDC-correlation checkpoint |
| `C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831\sets\SET_MANIFEST.csv` | `6CBA6906495CC53A8149B2B512E5377FA03027C4E77D9FA91B872A4236BABD48` | Candidate-set provenance; review four orphan lists before reuse |
| `C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831\sets\S_FULL.txt` | `F69E9199EBB6212346DA11AC7EB66D832D2E50CCF8F43C5401806780E15247EE` | Full 58-source set |
| `C:\FPGA\G2B_BS0_GROUP9_ANALYSIS_20260831\sets\K_OWNERSHIP_RESULT.txt` | `D0E81393EF7750003EE14C3BE0A789CD35FDF132AF3D2B23CE0C3272EB8065BE` | First recommended one-destination scope |

The following scaffolding may be reused only after code review, not as authoritative results:

- `Invoke-G2BBs0Experiment.ps1` — SHA-256 `4C92F162FC89830CC5DC1671A2CA97D92C1CB054238720DCC1C9EAC75F798EA8`.
- `g2b_bs0_worker.tcl` — SHA-256 `B17B15A3FC99F53EEA39F6BAA3BCA754C1BA54B9F08D353C109998500F2A4749`.
- `G2B_BS0_MINIMAL_CLOCK_BASE.xdc` — SHA-256 `04976FD759DC1DDD4D2D0DA9387F47ABB7F70FDF2EF3D51C539D8EE95D7EBD60`.
- `Build-G2BBs0Ledgers.ps1` — SHA-256 `50DDB9D1BA9F8229B2272F539082F422DC3574F6EC4CA1BA244DD10FF73DC379`; unexecuted and known to need EXP002 logic review.

## Remaining analysis

1. Establish a serialized bounded-worker preflight that distinguishes initialization timeout from query timeout and always writes a command-start marker.
2. Freeze and copy the reviewed worker into the new isolated directory, record its hash before launch, use an explicit invariant numeric format, and version the receipt schema.
3. Run a bounded full-source-to-single-semantic-sink BUS_SKEW test using `S_FULL.txt` (58) and `K_OWNERSHIP_RESULT.txt` (1).
4. Run a separately serialized exact-scope `report_timing` control for the same endpoints.
5. If the 58x1 result is pathological, continue semantic receiver subsets and then binary bisect with new immutable experiment IDs.
6. If it is not pathological, expand through the reviewed semantic receiver groups before any full 58x19 rerun.
7. Generate a current Gen12 `report_methodology` result and classify TIMING-32/34/37/38/39 from that result only.
8. Complete logic-depth/reconvergence analysis for the smallest reproduced scope.
9. Finalize constraint validity only after the exact timing, methodology, and BUS_SKEW controls exist.
10. Assemble and execute a minimal reproducer only after the smallest pathological subset is known.
11. Generate the original ledger, bisect CSV, state JSON, evidence index, and manifest from corrected logic.

Every absent result above is `MISSING_REQUIRES_FUTURE_G2B_BS0_CONTINUATION`.

## Exact next task scope

Use a fresh isolated directory and new experiment IDs. Preserve the interrupted tree read-only. Review the runner/worker and fix the ledger builder's EXP002 handling. Then, with no concurrent Vivado initialization, execute exactly one bounded BUS_SKEW worker using:

- source set: `S_FULL.txt` (58 objects)
- destination set: `K_OWNERSHIP_RESULT.txt` (1 object)
- sealed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`
- required receipts: initialization-start, initialization-complete, command-start marker, bounded timeout phase, process tree, stdout/stderr, output hashes, and immutable result JSON/text

Do not run a second worker concurrently. Do not accept an initialization timeout as query evidence.

## Resume-point answer

- Resume from a specific completed subset/experiment number: **NO**.
- Resume without repeating completed static work: **YES**.
- First new dynamic scope: **58 sources to `K_OWNERSHIP_RESULT` (one destination)**.
- Fresh isolated directory recommended: **YES**.
- Reuse the old experiment IDs: **NO**.
