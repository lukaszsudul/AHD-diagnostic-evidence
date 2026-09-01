# AHD v41 G2B-BS1A Vivado Initialization Budget Characterization

## Gate result

- Engineering gate: **PASS**.
- Initialization result: **INITIALIZATION_BUDGET_TOO_SMALL_CONFIRMED**.
- `COMMAND_READY`: **YES**, reached in **312.233 seconds**.
- BUS_SKEW command executed: **NO**.
- BUS_SKEW status after BS1A: **UNTESTED**.
- BS1 retry readiness: **READY_WITH_NEW_INIT_BUDGET**.

BS1A reached the exact pre-command state in one isolated Vivado run and exited cleanly. Because readiness took more than 300 seconds but less than 1200 seconds, the prescribed decision tree confirms that the previous total initialization budget was too small. This result makes no claim about BUS_SKEW behavior.

## Authority and predecessor boundary

The authoritative `project-current-state` was revision 3 at both start and end. It was read only. The task gate disposition for G2B-LUT1 remains **HOLD**; its exact SSOT fields remain `PLANNED / READY / NOT_STARTED`. The R-track remains `HOLD`, G2B implementation remains `BLOCKED`, and G2B hardware remains not proven.

The immediate predecessor is `BS1_EXP001` at evidence commit `de7dc18e3fa5e7f5e80dc542983a2f9025a22992`. Its result remains `INITIALIZATION_TIMEOUT`: it spent 300.949 seconds under the old total watchdog, never completed `open_checkpoint`, and never started the target command. It is not reinterpreted as a BUS_SKEW timeout.

The recovery predecessor is commit `6707d6f2ca39c76295ce565b0e04878dff16110a`. It proved that BS0 EXP004-EXP006 had overlapping initialization windows, but did not prove overlap caused their failures. BS1A did not repeat BS0; it used one serialized worker and one initialization-only attempt.

## Sealed input and scope

The execution used a byte-identical copy of the preserved Gen12 routed checkpoint:

- original: `C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp`;
- size: 57,900,063 bytes;
- SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`;
- part: `xc7a35tcsg325-2`.

The exact future-BS1 scope resolved and matched its deterministic evidence files:

| Scope | Count | Identity/hash |
|---|---:|---|
| `S_FULL` sources | 58 | `F69E9199EBB6212346DA11AC7EB66D832D2E50CCF8F43C5401806780E15247EE` |
| `K_OWNERSHIP_RESULT` sinks | 1 | `D0E81393EF7750003EE14C3BE0A789CD35FDF132AF3D2B23CE0C3272EB8065BE` |
| Sink object | 1 | `G2B_ONECH_C2H/own_ok_hold_source_reg` (`FDRE`) |

The dynamically resolved source and sink files are byte-identical to the authoritative input lists.

## Isolation and host observation

- Host: `NBLSUDUL`, Microsoft Windows 10 Pro 10.0.19045, 64-bit.
- Vivado: 2025.2, SW build 6299465, IP build 6300035.
- Logical CPUs: 4.
- Available memory at start: 5,646,392 KiB.
- Vivado processes before launch: 0.
- Vivado workers launched: 1.
- Maximum observed Vivado process count: 1.
- Worker overlap: **NO**.
- Vivado processes after exit: 0.

## Initialization timeline

| Milestone | UTC timestamp | From T0 (s) | Phase (s) |
|---|---|---:|---:|
| T0 — process launch | 2026-09-01T17:21:38.981Z | 0.000 | 0.000 |
| T1 — Tcl worker entered | 2026-09-01T17:22:21.513Z | 42.532 | 42.532 |
| T2 — checkpoint open started | 2026-09-01T17:22:25.560Z | 46.579 | 4.047 |
| T3 — checkpoint open completed | 2026-09-01T17:25:05.314Z | 206.333 | 159.754 |
| T4 — route-status query completed | 2026-09-01T17:25:13.373Z | 214.392 | 8.037 |
| T5 — XDC/context preparation completed | 2026-09-01T17:26:48.474Z | 309.493 | 95.066 |
| T6 — 58 sources resolved | 2026-09-01T17:26:48.600Z | 309.619 | 0.101 |
| T7 — singleton sink resolved | 2026-09-01T17:26:48.630Z | 309.649 | 0.008 |
| T8 — object identity verified | 2026-09-01T17:26:48.674Z | 309.693 | 0.023 |
| T9 — `COMMAND_READY` | 2026-09-01T17:26:51.214Z | **312.233** | 2.519 |

The dominant initialization phase was **checkpoint open**, at 159.754 seconds (51.165% of time to readiness). Context/XDC preparation was second at 95.066 seconds (30.447%). Checkpoint open was therefore the largest cost, but the combined startup, route, and context phases were also material.

The individually timed phases sum to 312.087 seconds. The remaining 0.146 seconds is interphase route parsing and marker/bookkeeping overhead and remains included in the authoritative 312.233-second T0-to-T9 total.

## Checkpoint and route status

`open_checkpoint G2B_ROUTED.dcp` completed successfully. The supported read-only `report_route_status` query then reported 33,985 routable nets, 33,985 fully routed nets, and zero routing errors. No implementation command ran.

## Timing-database readiness

`TIMING_DATABASE_PREPARATION = AUTOMATIC`.

Vivado logged restoration of timing data from the checkpoint's binary archive during `open_checkpoint`. That restore is included in the checkpoint-open phase and is not separately measurable from the available log. BS1A issued no explicit timing-update command, and there were no `UpdateTimingParams` messages during pre-command context preparation.

This establishes that no separate explicit timing update was needed to reach the future command invocation boundary. It does not establish whether the future BUS_SKEW command will perform additional automatic timing work after invocation; that behavior remains untested and belongs under the independent command watchdog.

## No-command proof

The frozen worker contains zero instances of the target report command string. The worker, Vivado console, and Vivado log each contain zero such instances; no target report file exists. The last substantive action was writing `COMMAND_READY.marker`, followed by clean design close and process exit.

Accordingly:

- BUS_SKEW command executed: **NO**;
- BUS_SKEW status after BS1A: **UNTESTED**.

## Budget decision

The margin rule produces max(312.233 × 2, 312.233 + 300) = max(624.466, 612.233) = 624.466 seconds. The practical recommendation is rounded upward to **900 seconds** to allow initialization variability while staying below the 1800-second cap.

The future command budget remains separately bounded at **300 seconds**.

Required future structure:

`INITIALIZATION (900 s) -> COMMAND_READY -> separate BUS_SKEW watchdog (300 s)`

This is a recommendation only. No retry was executed.

## Interpretation

BS1A answers the initialization question: the old 300-second total limit was simply too short for this successful, isolated command-ready path. Initialization itself was not pathological in BS1A because all required milestones completed within 312.233 seconds and Vivado exited normally.

BS1A does not answer whether the target report is fast, slow, pathological, passing, or violating. That status remains **UNTESTED**.

## Protection verification

- Source repository tracked changes: 0.
- Source index changes: 0.
- Source branch movement: no (`main`, HEAD `be94f88ee8d179f12928ab791bdae27c22cd1762`).
- Source commit: no.
- Active XDC modified: no; all six active-XDC hashes matched the pre-run baseline.
- Bitstream produced: no.
- Hardware/DUT/JTAG/PCIe/DMA accessed: no.
- SSOT modified: no; revision remained 3.
- Historical evidence mutated: no.

## Acceptance matrix

| Criterion | Result |
|---|---|
| PROJECT_STATE_REV = 3 | PASS |
| Sealed DCP verified | PASS |
| Exact 58+1 scope verified | PASS |
| Exactly one Vivado worker/no overlap | PASS |
| One bounded initialization characterization | PASS |
| Phase timing captured | PASS |
| `COMMAND_READY` or bounded timeout | PASS — `COMMAND_READY` |
| BUS_SKEW not executed | PASS |
| Source/XDC/hardware/SSOT protected | PASS |
| Engineering gate | **PASS** |

Evidence publication and remote read-back are recorded by the containing Git commit and the external publication receipt, because a commit cannot embed its own immutable SHA.
