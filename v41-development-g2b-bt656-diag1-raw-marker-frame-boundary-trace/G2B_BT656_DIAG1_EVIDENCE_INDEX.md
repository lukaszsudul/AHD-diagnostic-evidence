# Evidence index

This directory records the governed DIAG1 run through its first failed gate.

- First blocker: `BT656_DIAG1_FULL_BUILD_TIMING_GATE_FAILED:WNS=-4.675ns,TNS=-3545.498ns`
- Engineering gate: FAIL
- Hardware accessed: NO
- Event trace captured: NO
- `G2B_BT656_DIAG1_TRACE.bin` is intentionally absent: no hardware trace existed, and an empty/fabricated binary was not created.
- The private routed DCP is intentionally not published.
- No bitstream was produced.

## Published groups

- Governance, source authority and scope reports
- Complete diagnostic RTL/XDC/test/build-script source subset under `source/`
- Final simulation receipts under `simulation/`
- Sanitized build result, route, DRC, CDC, utilization and worst-path evidence under `build-evidence/`
- Explicit NOT_REACHED receipts for every hardware-dependent stage
- State, gate matrix and SHA-256 manifest
