# AHD v41 G2B-HW0 PRODUCT R3R4R6 Main Report

Generated: `2026-09-07T18:13:21.892Z`

## Result

- Engineering gate: `BLOCKED`
- Evidence package: `SEALED_PENDING_COMMIT_PINNED_REMOTE_READBACK`
- Overall result: `BLOCKED`
- First blocker: `R3R4R6_FOCUSED_HOST_TOOL_GATE_FAILED:NATIVE_HELPER_COMPILES_PASS:NON_DUT_OFFLINE_COMPILER_UNREACHABLE`

The focused pre-DUT host-tool gate completed `5/6 PASS`. The native Linux AIO
helper could not be compiled because the available non-DUT Linux compilation
host at `10.132.1.227:22` timed out. No local Linux compiler/toolchain was
available. The source was not changed after this infrastructure failure, and
the permitted focused correction iteration was not consumed.

The hard gate therefore prevented the first DUT connection. Hardware access,
driver load attempts, MMIO operations, DMA operations, FPGA programming,
reboot, Flash access, and power cycling were all zero. No live capture result
or causal-model conclusion is claimed.

## Owner-attested inputs

- `PROJECT_STATE_REV = 8` (owner-attested, not reverified)
- DUT: `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`
- boot ID: `614295f4-c62b-4430-ae67-06013bea7084`
- endpoint: `0000:01:00.0`, `10ee:7011 / 10ee:0007`, Gen2 x1, unbound
- PRODUCT bitstream SHA-256: `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`
- driver SHA-256: `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`
- ABI SHA-256: `AACB8F32CE3807C0A1DACD644FFFA90D214AA599F0798A700576987924E0D2B6`

These values were accepted exactly as instructed and were not re-audited.

## Focused gate

1. Native helper compiles: `FAIL` — non-DUT compiler host unreachable.
2. No signal interruption in active DMA path: `PASS`.
3. C2H open flags omit `O_TRUNC` and `eop_flush`: `PASS`.
4. Primary and guard requests precede `PREQUEUE_READY`: `PASS`.
5. Parent enable depends on `PREQUEUE_READY`: `PASS`.
6. Integrity/continuity/accounting fixture: `PASS`.

## Governed boundary

- Fresh run root: `C:\FPGA\G2B_HW0_PRODUCT_R3R4R6_20260907T174249Z`
- Prior run directories modified by R3R4R6: `NO`
- Fresh credential helper SHA-256: `677727ED53345BAB68B015714AE3638D45A0C553EF3B84E7B9C1909D742EC79A`
- Credential remnants: `0`
- Hardware accessed: `NO`
- Raw camera bytes published: `NO`
- SSOT update required: `NO`
