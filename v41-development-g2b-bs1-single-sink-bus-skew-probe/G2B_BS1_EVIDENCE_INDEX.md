# G2B-BS1 Evidence Index

## Required evidence

| Artifact | Status | Purpose |
|---|---|---|
| `V41_G2B_BS1_MAIN_REPORT.md` | PRESENT | Main result and interpretation |
| `G2B_BS1_EXPERIMENT_RECEIPT.txt` | PRESENT | Immutable experiment receipt |
| `G2B_BS1_SOURCE_SET.txt` | PRESENT | Exact recovered 58-source `S_FULL` list |
| `G2B_BS1_SINK_SET.txt` | PRESENT | Exact singleton `K_OWNERSHIP_RESULT` list |
| `G2B_BS1_WORKER.tcl` | PRESENT | Frozen single-probe worker |
| `G2B_BS1_APPLIED_CONSTRAINT.xdc` | PRESENT_SENTINEL_NOT_APPLIED | Explicit initialization-timeout status; no dynamic XDC application occurred |
| `G2B_BS1_CONSOLE.log` | PRESENT | Vivado standard console output |
| `G2B_BS1_VIVADO.log` | PRESENT | Vivado log |
| `G2B_BS1_STATE.json` | PRESENT | Machine-readable experiment state |
| `G2B_BS1_EVIDENCE_INDEX.md` | PRESENT | This index |
| `G2B_BS1_SHA256_MANIFEST.txt` | PRESENT | File-integrity manifest |

## Conditional report

`G2B_BS1_REPORT_BUS_SKEW.rpt` is **ABSENT_AS_EXPECTED**. The worker timed out during initialization before `COMMAND_STARTED`; no BUS_SKEW report command executed.

## Supporting evidence

- `G2B_BS1_CONSTRAINT_BASE.xdc` — exact authoritative skew-free base.
- `Invoke-G2BBs1SingleProbe.ps1` — frozen external timeout/serialization wrapper.
- `G2B_BS1_LAUNCH_COMMAND.txt` — exact launch command.
- `G2B_BS1_RUNNER_STATE.txt` — external timeout and process result.
- `G2B_BS1_MARKERS.log` — phase-marker ledger.
- `RUN_LAUNCHED.marker` and `WORKER_STARTED.marker` — reached boundaries.
- `G2B_BS1_CONSOLE.stderr.log` — empty stderr capture.

`DCP_OPENED.marker`, `OBJECTS_RESOLVED.marker`, `COMMAND_STARTED.marker`, and `COMMAND_COMPLETED.marker` are absent because those boundaries were not reached. No retry or second experiment exists.
