# G2B-HW0-PRODUCT-R3R2 — SESSION_START_RECEIPTS

No actual START_C2H_CAPTURE_SESSION reached. T3 launch timed out; no T3-start-once, session-start, reader-ready, write ledger, completion journal or raw capture file exists on DUT. T4/T5 NOT_REACHED and not retried.
Reset writes0, enable writes0, fatal W1C0, nonfatal W1C0, statistics clear0, unauthorized writes0. No per-session epoch or fatal-mask observation is available; T2 epoch0 is NOT a T3 pre-reset epoch.
Complete auditable implementation in tools/capture.py (START_C2H_CAPTURE_SESSION). Exact frozen parser and ABI are included. Offline synthetic/mock tests PASS but are not DUT DMA or hardware-session evidence. Mock write tests never touched a device.
No continuation on the new boot was attempted. Absence of persistent start records plus boot interruption is reported honestly; no successful capture is inferred.
