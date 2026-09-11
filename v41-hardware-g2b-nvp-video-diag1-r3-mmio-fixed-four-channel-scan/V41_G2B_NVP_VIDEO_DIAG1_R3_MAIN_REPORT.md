# AHD v41 G2B-NVP-VIDEO-DIAG1-R3 Main Report

Engineering gate: **FAIL**  
Evidence publication: **PASS subject to the enclosing commit-pinned remote read-back**  
Overall result: **FAIL**

R3 repaired the accepted deterministic diagnostic-MMIO deadlock. The repair passed 25/25 simulations, a fresh nonincremental Vivado build and complete sign-off, and 32/32 real-hardware `CLEAR` write→read cycles with zero `0xFFFFFFFF` reads, timeouts, unexpected reboots, DPC events, or AER errors.

The Double-PREPARE baseline gate passed: both sequences executed 26 I²C transactions, returned `BGDCOL 0x78=0x88`, `BGDCOL 0x79=0x88`, and full route byte `0x00`, with zero NACK, timeout, or recovery events. PREPARE_B became the restore authority.

The 4×4 scan began. Session 1 (round 1, CH1, RED) completed 2500/2500 records and reconstructed a complete 1920×1080 UYVY frame. The frame was uniform red (`64 41 D4 41`, fraction 1.0), not digital black, and matched the assigned BGDCOL. Transport, line 0/SOF, sequence, overflow, malformed, source-drop, and 75.469 µs disable-latency gates passed.

The first failed gate was session 2 (round 1, CH2, GREEN): `R3R4R6R2R4_LIVE_SOURCE_NOT_READY`. Route readback was `0x01` and NVP classification was `NO_VIDEO_STABLE`, but the bounded source-readiness window measured `sav_delta=0` while the video clock advanced. No reset, AIO submission, helper launch, stream enable, or second capture occurred. The no-retry rule stopped the remaining matrix; therefore multi-color BGDCOL and camera-channel qualification were not reached.

Firmware safe restore physically returned BGDCOL to `0x88/0x88`, the full route to `0x00`, and the firmware-private bank/page to its PREPARE_B value. Restore status `3` proves internal physical readback. Diagnostic error `0x8` is the retained capture-failure history, not a restore failure. Five quiescent samples spanned 441.129 ms; pending AIO was zero; the driver, XDMA nodes, and locks were removed.

No raw capture, UYVY frame, PNG, thumbnail, DCP, bitstream, driver, native binary, or credential is published here.
