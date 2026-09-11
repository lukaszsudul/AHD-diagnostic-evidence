# AHD v41 G2B-NVP-VIDEO-DIAG1-R3R1 Main Report

Engineering gate: FAIL

Evidence publication: PASS after the commit-pinned remote read-back for the commit containing this report.

Overall result: FAIL

The R3 FPGA image was reused without programming, reboot, source, XDC, IP, DCP, bitstream, SSOT, or META changes. The exact driver/runtime identity, one bounded CLEAR write/read sanity check, and Double-PREPARE baseline all passed. PREPARE deltas were 26 and 26; both visible baselines were BG78=0x88, BG79=0x88, route=0x00.

The non-aborting host policy worked for session 2: CH2 had VCLK but no SAV before or after reset, launched no helper, submitted no AIO, made no stream-enable write, proved physical quiescence, used response 0x00020009, and advanced safely.

The scan then hard-stopped at session 3 as required. CH3 was qualified before and after reset, completed 2500/2500 DMA reads and reconstructed a 1920x1080 frame, but both line1079-to-next-line0 capture-sequence deltas were 2 instead of the governed 22. The validator returned `NVP_DIAG1_SESSION_03_VALIDATION_FAILED:RC=1`. The session was not acknowledged as a capture pass and sessions 4 through 16 were not executed.

Failure restore completed physically despite the terminal diagnostic error code 0x08: restore status was 3, firmware internal verification passed, visible values were restored to 0x88/0x88/0x00, I2C counters remained clean, transport was quiescent, pending AIO was zero, the driver unloaded, nodes disappeared, and both task locks were released.

First blocker: NVP_DIAG1_SESSION_03_VALIDATION_FAILED:RC=1

Working causal model: CH3_BT656_READY_TRANSPORT_AND_FRAME_PASS_BUT_GOVERNED_VERTICAL_TAIL_CAPTURE_SEQUENCE_DELTA_2_NOT_22
