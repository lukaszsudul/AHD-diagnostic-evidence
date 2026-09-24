# AHD v41 R2R10R14R6 — R14R5R2 hardware attempt

## Result

- Exact bitstream SHA-256: `989079972C3051E05FC497E98B41A9CFFD1A9B58329338D682C6E98019D29AA1` (2192144 bytes); programmed once to volatile SRAM; DONE=1; one planned warm reboot.
- Source commit/tree: `c05f62d204853f36263b5fd486596abd517f5e92` / `9d35c25b09718057bb100314309006baae8409c5`.
- Fresh Owner attestation: physical CH3 camera connected, powered, and left connected.
- Autoinit NACK by phase WADDR/REGADDR/DATA/RADDR: `0/0/0/0`; aggregate `0`; timeout attempts `0`. This does not establish a physical cause for earlier NACKs.
- PREPARE: `PASS_CLEAN`, generation 1, terminal `0xC3CD0042`, no hard failure, no read retry event.
- APPLY_A: `PASS_CLEAN`, apply generation 1 linked to PREPARE generation 1, terminal `0xC3CD0092`, no hard failure, no write retry event. PREPARE telemetry remained byte-identical after APPLY.
- EQ finalization: `PASS_REPORTED_BY_LOADER_SCOPED_FINALIZATION`.
- Fresh SCAN1: `VALID_CLEAN`, T=105, R=0, F0=0x34, NOVID PRE/POST=0/0, bank restore PASS.
- One C2H session: 2500/2500 records completed, 10,240,000 bytes, pending/short/failed/duplicate all zero; normal OFF, one existing tail flush, quiescence PASS.
- First complete frame: 1920x1080 UYVY, SHA-256 `727DACB909C144CAC091A5DCBF31974DE4A11B9BCF273F92DE6AD34DC4821C03`; PNG SHA-256 `A83CDE93F03A80BA201CE67AB564BB611B2AE8C60CC36C3D276B3DC39F29DD57`.
- Pixel payload is byte-identical to the historical static color-tile baseline: 0 changed bytes and 0 changed lines. No recognizable live camera scene was confirmed.
- Cleanup: PASS, including normal driver unload and release of task-owned locks.

## Retry interpretation

Both telemetry ABIs were coherent, but neither retry path was exercised because PREPARE and APPLY completed without a qualifying NACK. The run does not prove retry effectiveness or the physical cause of prior NACK events.

## Process note

A task-local output-name collision occurred after APPLY and before SCAN1. Retained state showed that SCAN1 and C2H had not started. The continuation executed only SCAN1, C2H, and cleanup on the same boot and image; JTAG, reboot, PREPARE, and APPLY were not repeated.

## Scope limits

This is one experimental hardware attempt. It is not product qualification, full vendor adaptive EQ, physical NACK root-cause proof, or additional timing/CDC/bus-skew sign-off. Firmware, DCP, raw MMIO, capture bytes, raster, PNG, source, ABI files, and environment-specific identifiers remain private.
