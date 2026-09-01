# G2B-BS1R Evidence Index

## Primary conclusion

- `V41_G2B_BS1R_MAIN_REPORT.md` — authoritative engineering report and bounded interpretation.
- `G2B_BS1R_EXPERIMENT_RECEIPT.txt` — flat execution receipt with identities, timestamps, watchdogs, result, and protection audit.
- `G2B_BS1R_STATE.json` — machine-readable experiment state.

## Exact inputs and scope

- `G2B_BS1R_WORKER.tcl` — immutable single-attempt Vivado worker.
- `Invoke-G2BBs1rSingleProbe.ps1` — separated-watchdog external supervisor.
- `G2B_BS1R_SOURCE_SET.txt` — authoritative 58-source `S_FULL` list.
- `G2B_BS1R_SOURCE_SET_RESOLVED.txt` — dynamically resolved source identities.
- `G2B_BS1R_SINK_SET.txt` — authoritative singleton `K_OWNERSHIP_RESULT` list.
- `G2B_BS1R_SINK_SET_RESOLVED.txt` — dynamically resolved sink identity.
- `G2B_BS1R_CONSTRAINT_BASE.xdc` — preserved routed timing context with no BUS_SKEW constraint.
- `G2B_BS1R_APPLIED_CONSTRAINT.xdc` — applied context with exactly one 58→1, 3.000 ns BUS_SKEW constraint.

## Raw execution evidence

- `G2B_BS1R_CONSOLE.log` and `G2B_BS1R_CONSOLE.stderr.log` — redirected process output.
- `G2B_BS1R_VIVADO.log` — Vivado batch log.
- `G2B_BS1R_VIVADO_VERSION.txt` — exact tool version/build.
- `G2B_BS1R_ROUTE_STATUS.rpt` — fully routed checkpoint proof.
- `G2B_BS1R_PREFLIGHT.txt` — pinned input hashes and isolation checks.
- `G2B_BS1R_LAUNCH_COMMAND.txt` — exact launch invocation.
- `G2B_BS1R_RUNNER_STATE.txt` — external watchdog classification.
- `G2B_BS1R_WORKER_STATE.txt` — internal worker state through command start.
- `G2B_BS1R_TIMELINE.log` — worker milestone log.
- `G2B_BS1R_VIVADO_PROCESS_AUDIT.txt` — preflight, launch, targeted termination, and immediate postrun process evidence.
- `G2B_BS1R_POSTRUN_PROCESS_AUDIT.txt` — quiescent zero-Vivado confirmation.
- `G2B_BS1R_WARNINGS_AND_TIMING_MESSAGES.txt` — normalized messages relevant to interpretation.

## Markers

- `RUN_LAUNCHED.marker`
- `WORKER_STARTED.marker`
- `DCP_OPENED.marker`
- `OBJECTS_RESOLVED.marker`
- `COMMAND_READY.marker`
- `BUS_SKEW_STARTED.marker`
- `REPORT_FILE_NOT_PRODUCED.marker`

`BUS_SKEW_COMPLETED.marker` is intentionally absent because the command timed out. `VIVADO_ERROR.marker` and `SUPERVISOR_ERROR.marker` are absent because the result was an external command watchdog event, not a Vivado or supervisor error.

## Protection evidence

- `G2B_BS1R_SOURCE_REPOSITORY_AUDIT.txt` — no tracked source, index, branch, commit, or active-XDC mutation.
- `G2B_BS1R_SSOT_AUDIT.txt` — project revision 3 at both boundaries and no SSOT mutation.
- `G2B_BS1R_SHA256_MANIFEST.txt` — package integrity manifest; the manifest intentionally excludes itself.

## Absent primary report

`G2B_BS1R_REPORT_BUS_SKEW.rpt` was not produced. This is explicitly recorded as `REPORT_FILE_NOT_PRODUCED` and is consistent with `REPORT_BUS_SKEW_TIMEOUT`.

