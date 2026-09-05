# G2B-HW0-PRODUCT — Exact Candidate Live-Path Bring-Up

Lifecycle: PLANNED. Readiness: AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION. Progress: NOT_STARTED. Qualification: NOT_PROVEN, not ACCEPTED. Initial scope: ONE_CHANNEL_FIXED_LIVE_AHD_PATH.

META-8A authorizes the existence and scope of this separate future gate, not uncontrolled hardware access. Before execution, its separate governed prompt must explicitly define exact DUT identity, DUT exclusivity, operator/agent authority, candidate path and SHA-256, JTAG/SRAM programming authorization, PCIe rescan policy, XDMA driver policy, rollback method, stop conditions, evidence path and final hardware state. Fresh authority and exclusivity are required.

Candidate path: `C:\FPGA\G2B_LUT1_SIGNOFF_RECOVERY4_20260905_112316\G2B_PRODUCT_RECOVERY4.bit`; bytes 2192144; SHA-256 `AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7`. DCP SHA-256 `95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175`. Source `92e9b3d914134c044371779def1ee18eaaeda98a`, tree `cf6bf82249c90782eab1978c68541ed9c0e6430b`. FPGA xc7a35tcsg325-2. See META8A_DUAL_IDENTITY_CONTRACT.md.

## T0 — Candidate and runtime identity

Hash exact .bit before programming; verify two-layer identity, correct FPGA/DUT, authority and exclusivity. Establish expected runtime tuple before T1 and verify it on the programmed image before T2. Expected GIT_SHA 224d194e5f82c85bcb29297561c5d5e76d28063b and BUILD_FLAGS 0x00000103. An unrelated old image's tuple cannot prove the candidate; stop on unexpected mismatch.

## T1 — SRAM programming and endpoint

Under separate operational authority, program only the exact bitstream into SRAM, never Flash. Verify DONE, PCIe endpoint enumeration, actual generation/width and driver binding. Complete runtime verification before capture. Do not infer Gen2 hardware qualification from XCI/source settings.

## T2 — MMIO baseline

Verify ABI v1, PRODUCT profile and MMIO 0x3800..0x3BFF. Read capabilities, counters, epoch and error baseline. Do not clear unexplained errors to manufacture PASS. Follow the frozen acknowledged-snapshot/reset/session contract. Any later control writes require the separate task's authority.

## T3 — One complete live C2H record

Use exact PRODUCT live AHD path on the fixed supported input established by candidate/current-board evidence. Receive one complete 4096-byte record; verify 512 × 64-bit beats, TKEEP/TLAST-derived record boundary, 64-byte header, 3840-byte payload, 192-byte zero padding, magic, ABI/record version, channel/input, sequence, epoch, flags and reserved bits against CURRENT_INTERFACES.md. G2B emits logical channel 0, physical input ID 0 and active count 1; encoded IDs do not prove all four physical connector mappings. Live payload is not expected to match predetermined synthetic golden bytes. Document available endpoint/host proof of the AXI-derived boundary; do not invent direct internal observations for this no-debug PRODUCT profile.

## T4 — Bounded finite capture

Verify sequence continuity, no unexplained duplicates or gaps, coherent slot ownership/release, and record counters/errors. Preserve anomalies and raw source/host evidence.

## T5 — Continuous one-channel live AHD capture

Execute only after T0–T4 PASS, for the bounded duration defined in the separate prompt. Reconstruct lines/frame where possible. Stop on corruption, unexplained sequence gaps, ownership errors or reset errors. Preserve evidence before authorized recovery.

## Boundaries

No persistent Flash programming, HDMI project-state changes, unload/rebind of unrelated devices, uncoordinated broad PCIe rescans, or reboot/power-cycle without explicit authority. No FOUR_INPUT_SELECTION, AUTO_SCAN_AND_LOCK, UNIVERSAL_DIAGNOSTIC_LIVE_MODE or TWO_CHANNEL_PARALLEL_CAPTURE promotion.

Offline >=288 MB/s architecture analysis: PASS. HARDWARE_THROUGHPUT_PROVEN = NO. One real 1080p25 AHD stream cannot prove the full 288 MB/s application requirement. PCIe Gen2 hardware qualification and required-payload hardware qualification remain NOT_PROVEN; later governed synthetic diagnostic or multi-channel testing is needed for full throughput proof.

G2B-DIAG0: BLOCKED / NOT_PROMOTED; HW0_DIAGNOSTIC bitstream: NOT_IMPLEMENTED; synthetic generator in PRODUCT: NO; diagnostic MMIO 0x3C00..0x3FFF: NOT_PROMOTED_BY_META-8A; four-input auto scan: NOT_QUALIFIED. DIAG0 blockers do not block fixed-input PRODUCT testing.

V4L2: PLANNED_FOR_LATER_STAGE, not required for HW0. release/v41.0.0: NOT_CREATED, NOT_AUTHORIZED, NOT_RELEASED. Release candidacy requires later governed hardware and stability gates.

The historical G2B_HW0_SYNTHETIC_DMA_TEST_PLAN.md and its synthetic continuation recommendation are not promoted. This Owner-authorized live-path contract defines META-8A's next gate. META-8A executes none of T0–T5 hardware operations.
