# AHD v41 G2B-NVP-VIDEO-DIAG1-R3R2 Retained CH3 Frame Content Analysis, Bounded Route-Specific VBI-Tail Contract, Validator Regression and Complete Non-Aborting Four-Channel 4x4 Scan

Engineering gate: **FAIL**

The route-specific VBI correction itself passed. The validator regression was 16/16, the host-controller gate was 10/10, exact R3 runtime identity passed, MMIO sanity passed, and Double-PREPARE passed with equal 26-transaction deltas and PRODUCT baseline '0x88/0x88/0x00'.

The one authorized fresh scan stopped after session 1. The session-1 CH1/RED DMA acquisition itself completed 2500/2500 records and 10,240,000 bytes with an 82.262 us disable latency and zero pending AIO. The validator subprocess then failed before validation because its deployed module set omitted the unchanged transitive dependency 'abi_v1.py', imported by 'frame_reconstruct_nvp_capture.py'. The exact blocker is 'R3R2_DUT_VALIDATOR_DEPLOYMENT_MISSING_ABI_V1'.

After safe restore, the missing immutable dependency was deployed only to analyze the already retained session-1 bytes. No second scan and no recapture occurred. That retained analysis passed active-frame/transport integrity, the bounded VBI-tail contract, complete 1920x1080 reconstruction, and RED BGDCOL pixel matching. Its two frame-boundary deltas were 22, with tail intervals 21 and 21.

Because sessions 2-16 were not executed and a second 4x4 scan was prohibited, the requested complete matrix was not achieved. No multi-channel, CH2, CH3, CH4, or camera-image conclusion is claimed from this R3R2 run.

The exact R3R1 retained CH3 primary/frame/PNG byte artifacts were not present under the authorized R3R1 root, so retained CH3 content analysis is 'NOT_AVAILABLE_EXACT_ARTIFACT_MISSING'. Accepted immutable R3R1 metadata still supports the validator regression: CH3 boundary delta 2 means one legal tail interval and is not an active-frame failure.

Final safety state passed: firmware restored PRODUCT BGDCOL '0x88/0x88', full route '0x00', and its private bank context; stream was disabled; physical quiescence passed; pending AIO was zero; the driver and XDMA nodes were removed; both fresh locks were released. The R3 diagnostic image remains in volatile SRAM.

Raw captures, UYVY frames, PNGs, thumbnails, native binaries, driver binaries, bitstreams, DCPs, credentials, and camera pixels are excluded from this publication.
