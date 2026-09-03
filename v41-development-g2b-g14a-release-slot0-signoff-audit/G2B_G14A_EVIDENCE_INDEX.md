# G2B-G14-A evidence index

## Primary deliverables

| File | Purpose |
|---|---|
| `V41_G2B_G14A_MAIN_REPORT.md` | Authoritative audit result and acceptance-criteria closure. |
| `G2B_G14A_CURRENT_CONSTRAINT.md` | Exact governed Group-14 XDC, counts, clocks, objects, intent, and comparability. |
| `G2B_G14A_SEMANTIC_MODEL.md` | Independent RTL/netlist model of release-token behavior. |
| `G2B_G14A_SAFETY_INVARIANT.md` | Hardware failure analysis and real correctness requirements. |
| `G2B_G14A_FAMILIES.csv` | Three exact semantic endpoint-role families. |
| `G2B_G14A_CDC_PROTOCOL_PROOF.md` | Synchronizer, stability, ordering, epoch, and reset-barrier proof. |
| `G2B_G14A_TIMING_METHODOLOGY.md` | Bounded query method, results, warning disposition, and runtime classification. |
| `G2B_G14A_CONSTRAINT_ANALYSIS.md` | Candidate-strategy comparison, selected disposition, and equivalence. |
| `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` | Temporary Group-14-only replacement candidate; not active XDC. |
| `G2B_G14A_CANDIDATE_RESULTS.csv` | Required candidate result schema and measured family results. |
| `G2B_G14A_SIGNOFF_CONTINUATION_PLAN.md` | Future post-META sign-off order; not executed. |
| `G2B_G14A_STATE.json` | Machine-readable final audit state. |
| `G2B_G14A_AUTHORITY_AND_PROTECTION_RECEIPT.txt` | Final SSOT/source/DCP identity and non-mutation receipt. |
| `G2B_G14A_SHA256_MANIFEST.txt` | SHA-256 integrity manifest for every other published evidence file. |

## Raw timing evidence

`raw/timing/` contains the frozen scope summary, complete object inventory, applied in-memory candidate context, capped timing-path table, worst-path properties, exact-scope timing report, three family property receipts, focused methodology report/summary, route/tool receipts, six start/completion marker pairs, worker markers, console/Vivado logs, the supervisor receipt, and the post-run metadata correction.

The applied context is a zero-bus-skew query-isolation context, not a proposed full active-XDC replacement. Group preservation is determined from the Group-14-only candidate file and governed continuation boundary, not by treating the raw applied context as a future active constraint set.

Key files:

- `G2B_G14A_SCOPE_SUMMARY.txt`
- `G2B_G14A_OBJECT_INVENTORY.csv`
- `G2B_G14A_GET_TIMING_PATHS_SUMMARY.txt`
- `G2B_G14A_PRIMARY_TIMING_PATHS.csv`
- `G2B_G14A_PRIMARY_WORST_PATH_PROPERTIES.txt`
- `G2B_G14A_REPORT_TIMING_SUMMARY.txt`
- `G2B_G14A_EXACT_SCOPE_REPORT_TIMING.rpt`
- `G2B_G14A_CANDIDATE_RESULTS.csv`
- `G2B_G14A_FOCUSED_METHODOLOGY_SUMMARY.txt`
- `G2B_G14A_FOCUSED_TIMING_METHODOLOGY.rpt`
- `G2B_G14A_EXTERNAL_WATCHDOG.txt`
- `G2B_G14A_SUPERVISOR_POSTRUN_CORRECTION.txt`
- `WORKER_COMPLETED.marker`

## Predecessor timeout authority

`raw/predecessor_group14_timeout/` contains the recovery-2 `56/20` object authority and the marker/watchdog evidence proving that the required Group-14 `report_bus_skew` started and exceeded its independent 300-second command deadline.

## Initialization transparency

`raw/attempt0_initialization_failure/` preserves the cold harness failure that occurred before any timing query began. It is not counted as a query attempt and no timing result from it is used.

## Reproducibility tools

`tools/` contains the exact bounded Tcl worker and external PowerShell supervisor used. These are audit artifacts, not instructions to rerun the completed gates.

## Integrity convention

`G2B_G14A_SHA256_MANIFEST.txt` covers every published file except itself, uses repository-relative forward-slash paths, and is sorted ordinally by path. Integrity and remote read-back checks must also verify the evidence commit/tree from Git rather than relying only on this manifest.
