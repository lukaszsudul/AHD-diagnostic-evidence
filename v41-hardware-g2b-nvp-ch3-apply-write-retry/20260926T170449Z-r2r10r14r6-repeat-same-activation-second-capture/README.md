# AHD v41 R2R10R14R6 — repeat and same-activation capture

## Result

- Exact bitstream SHA-256: `989079972C3051E05FC497E98B41A9CFFD1A9B58329338D682C6E98019D29AA1` (2192144 bytes); programmed once to volatile SRAM at **2026-09-26T16:45:11.0155474Z–2026-09-26T16:45:54.0399676Z**, DONE=1; one planned warm reboot. This activation predates the followup and is reused, not presented as newly performed.
- Source commit/tree: `c05f62d204853f36263b5fd486596abd517f5e92` / `9d35c25b09718057bb100314309006baae8409c5`.
- Owner attestation: physical CH3 camera remains connected and powered; unchanged setup.
- First execution autoinit WADDR/REGADDR/DATA/RADDR: `0/0/0/0`, aggregate `0`, timeout `0`. This is retained evidence from that activation, not a new autoinit in the followup.
- PREPARE: `PASS_CLEAN`, generation 1, terminal `0xC3CD0042`, no hard failure or retry. APPLY_A: `PASS_CLEAN`, generation 1, terminal `0xC3CD0092`, no hard failure or retry. Both ran only in the first execution. Scoped EQ finalization reported PASS by loader.
- First capture: 2500/2500 records, pending 0. All 1080 real lines of frame 1713/epoch 0 reconstructed; image shows a plant and surroundings. The strict frame extractor FAILED due to a source capture counter gap of 3 at the first line. Initial session DISCONTINUITY/MALFORMED_PRECEDING flags retained. This earlier image remains diagnostic, not a retrospectively qualified strict frame.
- Followup: **2026-09-26T17:06:48.126902+00:00–2026-09-26T17:06:55.140276+00:00**, same boot and runtime verified. **No programming, reboot, PREPARE, APPLY, driver load or unload.**
- Fresh followup SCAN1: VALID_CLEAN, generation 2, T=105, R=0, F0=0x34, NOVID PRE/POST=0/0, bank restore PASS.
- Followup C2H: 2500/2500 records, 10,240,000 bytes; pending/short/failed/duplicate all zero. Normal OFF, one existing tail flush, quiescence PASS.
- Followup first complete frame: 1920x1080, epoch 1, frame 31197, lines 0–1079. **Strict frame extraction PASS.** Two complete frames available in this one session; the first is delivered. The initial discontinuity is outside the selected frame, in the discarded 31-record partial prefix.
- UYVY SHA-256: `727DACB909C144CAC091A5DCBF31974DE4A11B9BCF273F92DE6AD34DC4821C03`; PNG SHA-256: `A83CDE93F03A80BA201CE67AB564BB611B2AE8C60CC36C3D276B3DC39F29DD57`. Pixels are byte-identical to historical R14R6 color tiles: 0 changed bytes/lines. Compared with the preceding same-boot scene raster: 4091154 changed bytes, 1080 changed lines.
- Cleanup: user resources closed, pending=0, stream OFF and owned locks released. Driver retained loaded and idle; manual unload NOT_ATTEMPTED.

## Retry interpretation

Both PREPARE/APPLY telemetry snapshots from the first execution were coherent and clean; neither retry path was exercised. They were not rerun or counted as new commands during the followup. No physical NACK cause or retry effectiveness is established.

## Process note

One activation/configuration chain and two separately authorized capture sessions are reported together with actual times. The existing scan/capture implementation and frozen reader/driver/decoder bytes were reused; only task wrapper paths, admission of the already-loaded exact driver, MMIO-failure latch and no-unload closeout were adapted. Acquisition gates were preserved. The earlier scene result and its integrity limitation are not overwritten by the later tile result.

## Scope limits

The last PNG shows the historical colored tile pattern. The prior capture showed recognizable surroundings on the same activation. This task does not determine why content changed or where the pattern originates; one image does not establish temporal live behavior. This is not product qualification, full vendor adaptive EQ or additional timing/CDC sign-off. Firmware, DCP, source, ABI, raw MMIO, system logs, capture bytes, raster, PNG and environment identifiers remain private.
