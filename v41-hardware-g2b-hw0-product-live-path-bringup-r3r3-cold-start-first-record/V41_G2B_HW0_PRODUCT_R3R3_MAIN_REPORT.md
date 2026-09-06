# AHD v41 G2B-HW0-PRODUCT-R3R3

## Outcome

| Gate | Result |
|---|---|
| Engineering | BLOCKED |
| Evidence publication | SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK |
| Overall | BLOCKED |

First blocker: BLOCKED — R3R3_ROLLBACK_UNSAFE_ACTIVE_DMA at the capture-time decision point.

T0, T1 and T2 passed. The exact PRODUCT image was programmed to SRAM once, survived exactly one controlled warm reboot, enumerated as the exact Gen2 x1 AHD endpoint, automatically bound to the sealed driver, exposed dynamically mapped XDMA nodes, and returned the expected runtime identity and live input-0 telemetry.

T3 consumed its one authorized session. The mandatory reset executed once, epoch advanced from 1 to 2, post-reset ERROR_STATUS was zero, no W1C was needed, one coherent pre-capture snapshot completed, one reader was ready before one enable, and a complete record arrived within the ten-second budget. The reader assembled 53 complete 4096-byte records (one primary plus 52 drain) and the parent issued the single normal disable. The reader then exited during bounded drain before proving quiescence. The exact records were not persisted, so ABI/header/payload/padding/epoch validation and coherent counter reconciliation were not reached. No retry was authorized or attempted.

A subsequent read-only rollback assessment found no XDMA descriptors open and independently proved CONTROL=0 with the quiescent status mask. It also preserved active nonfatal ERROR_STATUS=0x00000007 and LAST_ERROR_CAUSE=0x00000002; no nonfatal W1C was attempted. Safe cleanup then performed exactly one normal unload, automatically unbound the endpoint, removed all XDMA nodes, and left both endpoint and root-port links at Gen2 x1. Kernel/AER review remained clean. Final JTAG read-back returned the exact sole xc7a35t, IDCODE 0362D093, DONE=1 in five samples.

The engineering gate remains BLOCKED because the one permitted session cannot establish the record's SHA-256, frozen ABI fields, padding, epoch, or counter reconciliation. ONE_RECORD_FIXED_LIVE_AHD_C2H_HARDWARE_PASS is not claimed. The 2500-record capture, frame reconstruction, 60-second capture, throughput, multi-input, two-channel, synthetic, V4L2, soak, and release gates were not run.

PROJECT_STATE_REV remained 8. SSOT, RTL, XDC, PRODUCT candidate, driver binary, prior evidence, and unrelated records were not modified. Raw camera bytes are not present in this public package. Publication completion and commit-pinned remote byte/blob verification are recorded outside this immutable commit in the fresh run root.
