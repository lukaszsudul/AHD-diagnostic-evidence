# AHD v41 G2B-NVP-VIDEO-DIAG1

## Result

- Engineering gate: **FAIL**
- Evidence publication: **PASS** (commit-pinned read-back recorded after push)
- Overall result: **FAIL**
- First blocker: `DIAGNOSTIC_POST_OPT_LUT_RESOURCE_GATE_FAILED:22306/20800=107.240%>98.000%`

The authoritative local NVP6134C register contract passed, the diagnostic source was committed and pushed, and the required simulation gate passed 16/16. The one authorized fresh nonincremental Vivado build then stopped at the post-optimization resource hard gate. The design uses 22,306 Slice LUTs on a 20,800-LUT device (107.240%), exceeding both physical capacity and the diagnostic limit of 98.000%.

The stop occurred before placement, routing, bitstream generation, FPGA programming, DUT contact, driver load, NVP writes, or capture. The hardware-qualified PRODUCT image and the NVP register state were not changed.

## Proven offline

- Local PDF authority confirms BGDCOL registers/codes, the VDO1 route field, and per-channel video-loss/lock status.
- Existing PRODUCT autoinit configures all four channels for forced AHD 1080p25.
- Diagnostic I2C ownership, fixed whitelist, 4x4 scan, rotated route order, BGDCOL Latin square, host handshake, error-safe restore, MMIO isolation, and transport noninterference passed simulation: 16/16.
- Inherited G2B PRODUCT, line-0/SOF, and vertical-tail regressions passed.
- Diagnostic source commit: `bed970032dd4acdfbb2cf254f3e21ebcfb60c6f1`.

## Resource diagnosis

The diagnostic core accounts for 3,992 LUTs and 4,222 FFs. Its `result_words[0:127]` table is a 128x32 asynchronous-read/resettable array, which synthesizes as registers and a large read mux rather than one compact block RAM. The full design must remove at least 1,922 post-opt LUTs to reach the authorized 98% ceiling (20,384 LUTs), and at least 1,506 LUTs merely to fit the device.

## Exact next correction

Keep the fixed whitelist and scan semantics, but implement the 16x8-word result table as synchronous block RAM without a bulk array reset (valid bits/session tags provide logical clearing), or remove the retained table in favor of host collection at each mandatory handshake. Re-run all 16 simulations and one fresh full build. No constraint waiver or FPGA/driver/ABI change is appropriate.

## Nonclaims

No 16-session scan, channel mapping, BGDCOL pixel-path result, camera-image result, 60-second capture, throughput qualification, or physical connector mapping was reached.
