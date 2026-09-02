# AHD v41 G2B-G13-A — Evidence Index

## Gate identity

| Field | Value |
|---|---|
| Gate | `G2B-G13-A` |
| Group | `13 — RESET_RETURN_SOURCE_TO_AXI` |
| Project state revision | `4` at start and end |
| Source commit | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` |
| Routed DCP SHA-256 | `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` |
| Engineering gate | `PASS` |
| Evidence commit | `CONTAINING_GIT_COMMIT` |
| Remote read-back | Required after push; recorded in the execution response |

## Required decision artifacts

| Artifact | Purpose |
|---|---|
| `V41_G2B_G13A_MAIN_REPORT.md` | Authority, exact constraint, semantic/timing synthesis, routed validation, decision, protection, and continuation |
| `G2B_G13A_GROUP13_CURRENT_CONSTRAINT.md` | Exact active-XDC definition, object counts, clocks, current absolute bound, and historical timeout |
| `G2B_G13A_SEMANTIC_MODEL.md` | Stable-data/handshake classification, two semantic families, and comparability decision |
| `G2B_G13A_SAFETY_INVARIANT.md` | Settle-before-valid, hold-until-ack, commit equality, and epoch/state-use invariant |
| `G2B_G13A_FAMILIES.csv` | Exact family sources/destinations, counts, roles, domains, and required properties |
| `G2B_G13A_RESET_SEMANTIC_PROOF.md` | Assertion/deassertion, reset transaction, stability, epoch/versioning, and mixed-state proof |
| `G2B_G13A_CDC_CORRELATION.md` | Focused request/ack/live-phase/stable-data CDC correlation and dispositions |
| `G2B_G13A_TIMING_METHODOLOGY.md` | Prohibited-query record, TIMING-32/34/37/38/39 findings, A/B queries, and bounded candidate method |
| `G2B_G13A_CONSTRAINT_ANALYSIS.md` | Strategies A–G, selected conjunction, equivalence, RTL, META, and Group-13 disposition |
| `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc` | Temporary declarative two-family max-delay candidate; active XDC is untouched |
| `G2B_G13A_CANDIDATE_RESULTS.csv` | Machine-readable routed results for the two semantic families |
| `G2B_G13A_SIGNOFF_CONTINUATION_PLAN.md` | Preserved prior groups and exact post-audit continuation boundary |
| `G2B_G13A_STATE.json` | Machine-readable authority, timing, decisions, protections, and publication convention |
| `G2B_G13A_PROTECTION_AUDIT.md` | End-to-end source/active-XDC/index/branch/SSOT/bitstream/hardware protection receipt |
| `G2B_G13A_QUERY_RECEIPT_SUMMARY.md` | Deterministic marker/result summary, applied counts, split-attempt runtimes, and timeline-sampling caveat |
| `G2B_G13A_VALIDATION_ID_MAP.csv` | Mapping from sealed validation IDs to the two canonical semantic-family names |
| `G2B_G13A_EVIDENCE_INDEX.md` | This artifact inventory and integrity/publication convention |
| `G2B_G13A_SHA256_MANIFEST.txt` | SHA-256 inventory for every other published file |

## Raw routed-timing evidence

All successful-run receipts are under `raw/timing/`. No full Group-13
`report_bus_skew` command appears in the worker or transcript.

| Evidence group | Principal files |
|---|---|
| External supervision | `G2B_G13A_PREFLIGHT.txt`, `G2B_G13A_LAUNCH_COMMAND.txt`, external watchdog receipt, worker/query start and completion markers |
| Checkpoint authority | Vivado version, route status, route signature, exact checkpoint/hash receipts |
| Exact scope | `G2B_G13A_OBJECT_INVENTORY.csv`, `G2B_G13A_SCOPE_SUMMARY.txt` |
| Alternative query A | `G2B_G13A_EXACT_SCOPE_REPORT_TIMING.rpt`, `G2B_G13A_REPORT_TIMING_SUMMARY.txt`, worst-path properties |
| Alternative query B | `G2B_G13A_PRIMARY_TIMING_PATHS.csv`, `G2B_G13A_GET_TIMING_PATHS_SUMMARY.txt` |
| Constraint preservation | `G2B_G13A_FULL_BASE_WITHOUT_GROUP9_AND_GROUP13.xdc`, applied-context inventory/count receipts; see attempt distinction below |
| Aggregate coverage | Aggregate membership summary and `G2B_G13A_SUPPLEMENTAL_AGGREGATE_RESULTS.csv` |
| Candidate families | Per-family reports, properties, result summaries, and completion markers |
| Methodology | Focused TIMING-32/34/37/38/39 report and summary; authoritative predecessor mapping retained in the methodology note |
| Tool transcript | Vivado log plus stdout/stderr logs |

There are intentionally two same-basename applied-context artifacts. The root
`raw/timing/G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc` (SHA-256
`8CB3B5A21912803E4E02D92ED2B6E444B93474EE739734FE54E1294E2AA0C493`)
belongs to attempt 1, which stopped before any candidate query. It is retained
only as failure provenance. The authoritative validated context is
`raw/timing/candidate_continuation/G2B_G13A_APPLIED_CANDIDATE_CONTEXT.xdc`
(SHA-256
`5BE4471486CC09C04E22FAD5A9A26030EB521D1235628ACEAE6664C87A2D72ED`).

## Reproducibility tools

| Artifact | Purpose |
|---|---|
| `tools/G2B_G13A_BOUNDED_TIMING_WORKER.tcl` | Preserved attempt-1 worker: exactly one primary `report_timing`, one primary bounded `get_timing_paths`, candidate query sites not reached, and no `report_bus_skew` |
| `tools/Invoke-G2BG13ABoundedTiming.ps1` | Preserved attempt-1 launcher, authority preflight, active-query watchdog, and failure receipt |
| `tools/G2B_G13A_CANDIDATE_CONTINUATION_WORKER.tcl` | Corrected candidate-only worker: no primary A/B repetition; two family and one supplemental bounded `get_timing_paths`; no `report_bus_skew` |
| `tools/Invoke-G2BG13ACandidateContinuation.ps1` | Fresh-process continuation launcher, exact hash/count preflight, per-active-query 300 s watchdog, and process-tree cleanup |

## External authority retained by reference

- `project-current-state/` at `PROJECT_STATE_REV = 4`.
- Predecessor package
  `v41-development-g2b-lut1-signoff-recovery` at evidence commit
  `765f5a5d4760f7a685447651dc68179b2fd96846`.
- Promoted Group-9 method package
  `v41-development-g2b-bs3-ownership-mailbox-settling-proof`.
- Qualified current XSIM receipt at
  `C:/FPGA/G2B_LUT1_ONECH_C2H_XSIM_20260831_13/G2B_XSIM_RECEIPT.txt`, SHA-256
  `9609B4E9CFE643FE63A91C255484189BBAFA165DDF7DD3B34114308AAB1EA38E`.
- Existing focused CDC source report at
  `C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_12/CDC.rpt`, SHA-256
  `FD1962A3353C5F6288989A39453C038709F5C1F41F1D6422D74D9AD28D5F553E`.

## Integrity convention

`G2B_G13A_SHA256_MANIFEST.txt` intentionally excludes itself. The state file
uses `CONTAINING_GIT_COMMIT` because embedding the containing commit's SHA in
that same commit is self-referential. The exact commit and remote branch head
are returned after the non-force push and independent remote read-back.
