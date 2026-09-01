# G2B-BS2 Evidence Index

## Package identity

- Repository: `lukaszsudul/AHD-diagnostic-evidence`
- Branch: `main`
- Directory: `v41-development-g2b-bs2-alternative-timing-equivalence`
- Containing commit: use the Git commit containing this index
- Analysis workspace: `C:\FPGA\G2B_BS2_ALT_TIMING_20260901T205518Z`

## Required evidence

| File | Purpose | Status |
|---|---|---|
| `V41_G2B_BS2_MAIN_REPORT.md` | Engineering result, experiments, semantics, decisions, and protections | present |
| `G2B_BS2_EXPERIMENT_RECEIPT.txt` | Machine-readable execution receipt | present |
| `G2B_BS2_EXACT_SCOPE_TIMING.rpt` | Raw bounded exact-scope `report_timing` output | present |
| `G2B_BS2_TIMING_PATHS.csv` | Raw selected actual timing-path properties | present |
| `G2B_BS2_TIMING_PROPERTY_INVENTORY.md` | Actual property-name inventory and sufficiency decision | present |
| `G2B_BS2_TOPOLOGY_ANALYSIS.md` | 58-to-1 topology, clocks, depth, fanout, and comparability | present |
| `G2B_BS2_CDC_SEMANTIC_REVIEW.md` | Toggle/ack stable-data mailbox review | present |
| `G2B_BS2_TIMING_METHODOLOGY.md` | TIMING-32/34/37/38/39 disposition | present |
| `G2B_BS2_CONSTRAINT_EQUIVALENCE_ANALYSIS.md` | Original constraint intent and A-G strategy analysis | present |
| `G2B_BS2_CONSTRAINT_DECISION.md` | Exact alternative-signoff and Group-9 recommendation | present |
| `G2B_BS2_STATE.json` | Structured task state | present |
| `G2B_BS2_EVIDENCE_INDEX.md` | This index | present |
| `G2B_BS2_SHA256_MANIFEST.txt` | Raw-byte SHA-256/size inventory; excludes itself | present after final generation |

## Raw dynamic support

| File | Purpose |
|---|---|
| `G2B_BS2_TIMING_METHODOLOGY.rpt` | Raw focused methodology report |
| `G2B_BS2_ENDPOINT_INVENTORY.csv` | Exact source/sink cell, clock, primitive, and placement inventory |
| `G2B_BS2_TIMING_PATH_PROPERTY_NAMES.txt` | Complete actual `list_property` names |
| `G2B_BS2_TIMING_PATH_PROPERTY_VALUES.csv` | Property presence counts and samples |
| `G2B_BS2_REPORT_TIMING_SUMMARY.txt` | Worker timing-query summary |
| `G2B_BS2_GET_TIMING_PATHS_SUMMARY.txt` | Worker path-query coverage summary |
| `G2B_BS2_ROUTE_STATUS.rpt` | Fully-routed checkpoint proof |
| `G2B_BS2_VIVADO_VERSION.txt` | Tool identity |
| `G2B_BS2_CONSOLE.log` | Complete batch console |
| `G2B_BS2_CONSOLE.stderr.log` | Standard error stream; zero bytes |

## Identity and control support

| File | Purpose |
|---|---|
| `G2B_BS2_SOURCE_SET.txt` | Authoritative 58-source list |
| `G2B_BS2_SOURCE_SET_RESOLVED.txt` | Vivado-resolved source identity |
| `G2B_BS2_SINK_SET.txt` | Authoritative singleton sink list |
| `G2B_BS2_SINK_SET_RESOLVED.txt` | Vivado-resolved sink identity |
| `G2B_BS2_CONSTRAINT_BASE.xdc` | Exact skew-free timing context |
| `G2B_BS2_PREFLIGHT.txt` | Hash, scope, watchdog, and isolation preflight |
| `G2B_BS2_RUNNER_STATE.txt` | External watchdog results |
| `G2B_BS2_WORKER_STATE.txt` | Vivado worker results |
| `G2B_BS2_TIMELINE.log` | Atomic phase timeline |
| `G2B_BS2_VIVADO_PROCESS_AUDIT.txt` | Pre/post process counts and watchdog deadlines |
| `G2B_BS2_LAUNCH_COMMAND.txt` | Exact launch command |
| `G2B_BS2_WORKER.tcl` | Reviewed Vivado worker; zero executable prohibited-report lines |
| `Invoke-G2BBs2AlternativeTiming.ps1` | Serialized external supervisor |

## Atomic markers

`RUN_LAUNCHED.marker`, `WORKER_STARTED.marker`, `DCP_OPENED.marker`, `OBJECTS_RESOLVED.marker`, `COMMAND_READY.marker`, `REPORT_TIMING_STARTED.marker`, `REPORT_TIMING_COMPLETED.marker`, `GET_TIMING_PATHS_STARTED.marker`, `GET_TIMING_PATHS_COMPLETED.marker`, `METHODOLOGY_STARTED.marker`, `METHODOLOGY_COMPLETED.marker`, and `WORKER_COMPLETED.marker` preserve the watchdog handshakes.

## Intentional absence

`G2B_BS2_REPORT_BUS_SKEW.rpt` is intentionally absent. BS2 prohibited and did not execute `report_bus_skew`; the official result remains `NOT_COMPLETED`.

No timeout-absence marker is needed because both alternative queries completed and their raw output files exist.

## Interpretation hierarchy

1. Raw Vivado reports/CSV and atomic markers are dynamic measurement evidence.
2. Exact scope lists, hashes, route status, and preflight are identity evidence.
3. Markdown reports interpret the raw evidence without promoting the 0.044 ns same-source range to bus skew.
4. `G2B_BS2_STATE.json` and the experiment receipt summarize the same measured values.
5. The final Git commit and independent remote read-back establish publication identity.

