# G2B-BS1A Evidence Index

## Primary result artifacts

| Artifact | Purpose |
|---|---|
| `V41_G2B_BS1A_MAIN_REPORT.md` | Engineering result, interpretation, timing, protection, and acceptance summary |
| `G2B_BS1A_INITIALIZATION_TIMELINE.csv` | T0-T9 milestone timestamps and phase elapsed times |
| `G2B_BS1A_INITIALIZATION_RECEIPT.txt` | Machine-readable execution, identity, timing, budget, and protection receipt |
| `G2B_BS1A_BUDGET_RECOMMENDATION.md` | Independent initialization/command watchdog derivation |
| `G2B_BS1A_STATE.json` | Structured BS1A state and gate disposition |
| `COMMAND_READY.marker` | Primary success marker written at T9 |

## Frozen execution artifacts

| Artifact | Purpose |
|---|---|
| `G2B_BS1A_WORKER.tcl` | Exact initialization-only Vivado worker; contains no target report command |
| `Invoke-G2BBs1aInitialization.ps1` | Single-launch serialization and 1200-second watchdog wrapper |
| `G2B_BS1A_LAUNCH_COMMAND.txt` | Exact Vivado command-line receipt |
| `G2B_BS1A_PREFLIGHT.txt` | DCP/list/XDC hashes, source baseline, and isolation preflight |
| `G2B_BS1A_RUNNER_STATE.txt` | Wrapper completion, timeout, process-count, and overlap state |
| `G2B_BS1A_WORKER_STATE.txt` | Vivado-side route, timing, identity, and phase result |

## Scope and context artifacts

| Artifact | Purpose |
|---|---|
| `G2B_BS1A_SOURCE_SET.txt` | Authoritative 58-object `S_FULL` list |
| `G2B_BS1A_SINK_SET.txt` | Authoritative singleton `K_OWNERSHIP_RESULT` list |
| `G2B_BS1A_SOURCE_SET_RESOLVED.txt` | Dynamically resolved 58-object source list |
| `G2B_BS1A_SINK_SET_RESOLVED.txt` | Dynamically resolved singleton sink list |
| `G2B_BS1A_CONSTRAINT_BASE.xdc` | Authoritative skew-free future-BS1 context |
| `G2B_BS1A_APPLIED_CONSTRAINT.xdc` | Read-back of command-ready constraints after exact setup |
| `G2B_BS1A_ROUTE_STATUS.rpt` | Read-only fully-routed checkpoint status |
| `G2B_BS1A_TIMING_DATABASE_PROPERTIES.txt` | Lightweight pre-command timing-property snapshot |

## Runtime artifacts

| Artifact | Purpose |
|---|---|
| `G2B_BS1A_CONSOLE.log` | Vivado standard output |
| `G2B_BS1A_CONSOLE.stderr.log` | Vivado standard error (empty on clean success) |
| `G2B_BS1A_VIVADO.log` | Vivado batch log |
| `G2B_BS1A_VIVADO_VERSION.txt` | Full Vivado version/build identity |
| `G2B_BS1A_HOST_OBSERVATION.txt` | Non-invasive host/runtime context |

## Integrity

`G2B_BS1A_SHA256_MANIFEST.txt` records the SHA-256 and byte length of every published payload file except the manifest itself. The sealed 57,900,063-byte DCP is deliberately not republished; its verified SHA-256 and original path are recorded in the receipt, state, marker, and main report.

The immutable evidence identity is the containing commit on `lukaszsudul/AHD-diagnostic-evidence` `main`. Remote read-back is performed after push and reported externally.
