# AHD v41 CONT1R3R3 — exact signed-DCP diagnostic bitstream

## Result and primary deliverable

**Engineering PASS: one real full diagnostic `.bit` generated and accepted offline. Evidence publication: PENDING commit-pinned read-back.** The private firmware is `C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_20260916T185629Z\firmware\AHD_v41_CONT1R3R3_DIAGNOSTIC.bit`, 2,192,144 bytes, SHA-256 `CD80C84E17467BCB03DEE58DC7FF64D50FD2CB6E5C409E21F871C3E05052BA09`. Its bytes, the DCP and any firmware package remain private; this public package contains metadata and task-owned source/receipt only.

This is firmware **generation**, not DUT configuration or a camera result. The FPGA card was not contacted or programmed. Hardware qualification and first real frame are `NOT_RUN` / `NOT_ACQUIRED`.

## Exact input and closed sign-off linkage

The authority is CONT1R3R2 evidence commit `9be3c9f023356f9dd04a4e42c2cc5944c97c211b`, [DCP_CLOSURE_RECEIPT.md](../v41-offline-g2b-nvp-camera-acq1-compat0-r2r1-cont1r3r2-signoff-harness-closure/DCP_CLOSURE_RECEIPT.md). It closed the former mixed-view A/B comparator failure for **only** the unchanged DCP with SHA-256 `C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`; the historical FAIL and warning file remain historical records, not a replacement input. The original DCP and a new private copy measured 17,469,233 bytes and that exact SHA before and after generation. The earlier routed DCP with SHA `804CB25D89DF3729A65D2771B892738AC2D580E2921AF48CAE1C5C28D76BC208` was not used.

Frozen source: `lukaszsudul/FPGA_AHD`, branch `diag/v41-g2b-nvp-camera-cont1r3r1-bram-recovery-20260916T105442Z`, commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`, tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`. The source worktree remained unchanged. Vivado 2025.2 SW build 6299465 opened the DCP as stored for part `xc7a35tcsg325-2`, top `ahd_capture_top_xdma`. The accepted closure's routed timing, resources, CDC, bus-skew and promoted-check results are inherited by exact identity; they were not rerun or presented as new implementation measurements. Raw CDC severities remain 427 critical and 874 warnings under the accepted profile-specific disposition, with zero unreconciled rows.

## Fresh generation checks

The fresh route-status report showed 38,667/38,667 fully routed nets and zero routing errors. Default DRC showed zero errors, zero critical warnings and 24 ordinary warnings matching the accepted rule/count vector. One direct, full `write_bitstream` invocation then ran its mandatory DRC with zero errors, completed successfully and returned process code 0. No new synthesis, optimization, placement, physical optimization or route ran; no design property, XDC, checkpoint, memory-init or runtime implementation identity was changed. The task-local Tcl and launcher show the command ledger.

Two complete post-generation reads agreed on the firmware hash. A read-only parser verified the length-prefixed `.bit` structure, 132-byte header, normalized part `7a35tcsg325`, declared/actual payload length 2,192,012 bytes and aligned `AA995566` sync word, without truncation or trailing bytes. Container inspection and SHA-256 establish artifact integrity and provenance, **not** circuit function or camera behavior. The retained runtime implementation remains `CONT1R3R1_BRAM_TELEMETRY`, source/DCP magic/version `0x52335231 / 0x00010000`; no live MMIO identity was measured.

## Governance and handoff

`PROJECT_STATE_REV` was 9 at start and offline validation; no SSOT, META, PRODUCT or source change occurred. The Owner's 2026-09-16 statement allows this bounded offline generation and reports a possible—but unconfirmed—warm reboot with no other modifications. It does not establish a new boot ID or current volatile FPGA/NVP/driver state. The only future DUT endpoint is `10.132.1.111:22`; this task did not contact it. The [handoff](NEXT_HARDWARE_HANDOFF.md) requires a separately authorized bounded live survey and activation/testing against this exact hash, with a new boot-scoped baseline as needed.

The firmware is not a proven NACK fix. The 1,000-scan causal campaign and 10,000-scan zero-error requirement are not run. No real camera frame has been acquired. Public evidence publication and commit-pinned remote byte read-back remain **PENDING** in this staging copy; no publication PASS is claimed here.
