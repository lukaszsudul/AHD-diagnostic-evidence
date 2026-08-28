# AHD v41 G2B Minimal One-Channel C2H Offline Integration

## 1. Executive result

Engineering gate: **BLOCKED**.

First blocker: `BLOCKED — G2B_RECORD_ABI_NOT_FROZEN`.

The pre-implementation contract review found mandatory unresolved sequence/reset semantics in v41D and a still-provisional transport ABI in the authoritative revision-1 SSOT. The secondary blocker is `BLOCKED — MMIO_ALLOCATION_NOT_FROZEN`. The task explicitly prohibits silently deciding either ABI, so the run stopped before source edits, simulation, synthesis, implementation, bitstream generation, or integration-branch publication.

Hardware access was prohibited and did not occur. `HARDWARE_ACCESS = NO`; `HW_LOCK = NOT_REQUESTED`; R2 was not interfered with.

## 2. Frozen base

| Item | Verified value |
|---|---|
| Source repository | `lukaszsudul/FPGA_AHD` |
| Required base branch | `integration/v41-r1i-gen2-g2a` |
| Base commit | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Base tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| Base parent | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Isolated G2B branch | `integration/v41-g2b-onech-c2h` |
| Isolated worktree | `V:\V41_G2B` |
| G2B branch HEAD | exact base commit; no G2B commit |

The base worktree and newly created G2B worktree were clean. Local and remote G2A refs matched the required commit. The integration branch was created directly at that commit and was not pushed because the ABI hard stop prevented an implementation commit.

## 3. SSOT state

- Evidence/SSOT repository start commit: `8d502a3e0a404b73c73af82846d730355288c7b1`.
- `PROJECT_STATE_REV_AT_START = 1`.
- `PROJECT_STATE_REV_AT_END = 1`.
- `SSOT_STALENESS = NONE`.
- SSOT was read-only.

Revision 1 still calls G2A active and G2B planned. The task's explicit Owner/Architect acceptance authorizes exact G2A as the base and resolves that anticipated META lag only. It does not override `CURRENT_TRANSPORT_ABI_STATUS = PROVISIONAL`, `OD-06 FINAL_C2H_ABI = OPEN`, or the provisional G2 MMIO pages. `CURRENT_INTERFACES.md` explicitly says its newer META-0 direction prevents consumers from treating the G1 v41D plan as a final ABI without interface acceptance and a META revision.

## 4. Scope boundary

The intended implementation scope was one active source, one private four-record ring, a v41D formatter, a fixed logical-channel-0 path, and the existing XDMA C2H channel. Two-channel scheduling, second-channel rings, arbitration, H2C, drivers, V4L2, hardware DMA, and 288 MB/s qualification were excluded.

The hard stop occurred during ABI/MMIO preflight. No functional scope was implemented.

## 5. Record contract

The G1 plan provides this nominal geometry:

- 4,096 total bytes;
- 64-byte little-endian header;
- 3,840 useful UYVY payload bytes at offsets `64..3903`;
- 192 zero-padding bytes at offsets `3904..4095`;
- 512 64-bit AXI beats, `TKEEP=0xFF`, and `TLAST` only on beat 511;
- magic `0x4C444841`; version `0x00004101`;
- logical channel 0 and physical input 0 for G2B.

The record ABI is nevertheless **BLOCKED**. Offsets `0x38` and `0x3C` lack frozen initial/reset/wrap/assignment semantics; the reset-epoch statement has no corresponding header allocation; and the Firmware/build ID inheritance rule is not frozen. See `G2B_RECORD_CONTRACT_RECEIPT.md` and `G2B_BLOCKER_REPORT.md`.

## 6. Source interface

The audited reusable source is physical input 0 through `g0p8c3r1_physical_frontend` into `g0p8c2_bt656_slot_producer` in the recovered VDO1 clock domain, nominally 148.5 MHz. It consumes one 8-bit byte per enabled video clock and commits a validated record only after 3,840 payload bytes, valid EAV, and eight header writes.

Its record-level interface is slot index `[3:0]`, word address `[8:0]`, data `[63:0]`, write-enable, commit, generation `[23:0]`, and a free-slot mask. The current source writes only words 0..487; the final 24 words are not valid zero padding and may not be streamed verbatim. The current PIO adapter is AXIS-shaped but is not a legal backpressured XDMA source.

## 7. Buffer architecture

No buffer was implemented. G1 requires a separate logical-channel-0 four-slot dual-clock DMA ring: four 4,096-byte slots, nominally four RAMB36 equivalents, source writes in the video domain, and XDMA reads at 62.5 MHz. Complete-record ownership, commit descriptor CDC, reset epoch, and slot release after the beat-511 handshake are mandatory.

This G1 requirement overrides any interpretation of “minimal” as a one-beat FIFO. The legacy PIO RAM/storage and read-service behavior must stay independent and byte-exact.

## 8. AXI4-Stream behavior

No AXI source was implemented or asserted into XDMA. G2A remains tied idle on C2H; H2C remains backpressured. Required 64-bit `TVALID/TREADY/TKEEP/TLAST` behavior was not tested and is not claimed.

## 9. Backpressure

Backpressure tests were not run. The frozen architectural rule remains whole-record ownership: stable output while stalled, beat index advance only on handshake, no release before beat 511, and whole-record drop when all four slots are owned. No implementation proof exists in this run.

## 10. Sequence and channel semantics

Logical channel 0 and physical input 0 are architecturally selected. Per-channel attempts must include admitted and whole-record-dropped attempts; global order covers streamed records. Because the exact initial/reset/wrap/header-assignment rules are not frozen, sequence/channel implementation and tests are **NOT RUN**.

## 11. MMIO delta

MMIO result: **BLOCKED**.

Legacy `0x0000..0x35FF`, R1i `0x3600..0x367F`, and the `0x3680..0x37FF` compatibility gap remain untouched. The proposed `0x3800..0x3BFF` region was not implemented. G1 labels it `PROPOSED_FOR_G2`; revision-1 SSOT labels it `PROVISIONAL`; mandatory control/state/capability/error bit encodings are not frozen.

## 12. CDC/reset

No new CDC/reset paths were added. The planned implementation requires dual-clock BRAM, bundled descriptor/toggle or async-FIFO commit CDC, per-slot release synchronization, coherent status snapshots, and an explicit stream reset-epoch handshake. PCIe reset must never reset or restart protected NVP/I2C autoinit. Static CDC/reset review therefore records the requirements but cannot pass an implementation.

## 13. Offline simulations

Status: **NOT RUN** due the pre-implementation ABI hard stop.

No formatter, ready/valid, backpressure, record-boundary, reset, overflow/drop, MMIO, legacy v40B, or v41D self-checking simulation was launched. No waveform-only claim is made.

## 14. Offline throughput estimate

No RTL throughput measurement exists. The immutable interface arithmetic is 64 bits × 62.5 MHz = 500 MB/s raw AXI capacity. If a future approved formatter sustains one beat per cycle, the 3,840/4,096 useful-byte fraction gives an architectural ceiling of 468.75 MB/s useful payload before PCIe/host effects. This is not a G2B result and not hardware qualification.

## 15. Synthesis

**NOT RUN**. The gate forbids proceeding after an unresolved mandatory ABI field. No G2B synthesis utilization exists.

## 16. Implementation

**NOT RUN**. No opt/place/phys-opt/route run, routed checkpoint, congestion report, or G2B bitstream exists.

## 17. Timing

**NOT RUN** for G2B. Accepted G2A reference only: WNS `+0.617 ns`, TNS `0.000 ns`, WHS `+0.024 ns`, THS `0.000 ns`. The small G2A hold margin remains a known future implementation risk.

## 18. DRC

**NOT RUN** for G2B. Accepted G2A reference only: zero DRC errors, zero critical warnings, 15 warnings, zero black boxes. No G2B DRC claim is made.

## 19. Resource delta

No G2B resource delta exists. Accepted G2A routed reference only:

- LUT: 18,178 / 20,800 (87.394%);
- FF: 20,137 / 41,600 (48.406%);
- BRAM: 26 / 50 (52.000%);
- DSP: 0 / 90.

The G1 development hard stop is greater than 90% LUT at post-opt or route. G2A has only 542 routed LUTs to the 90% boundary, making the future four-slot ring/control implementation high risk. Diagnostics were not reduced.

## 20. Provenance

The isolated G2B branch was created directly from the exact accepted base and remains at that base. No integration commit, source diff, XCI change, build flag change, or bitstream was produced. The protected NVP files and XDMA XCI therefore remain byte-identical by the empty source diff.

Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`; directory: `v41-development-g2b-one-channel-c2h-offline`.

## 21. Hardware prohibition proof

- DUT SSH: not used.
- JTAG/open hardware/programming: not used.
- DUT MMIO/PCIe enumeration/XDMA/DMA: not used.
- Driver operations/reboot/power cycle: not used.
- `FPGA_AHD_HW_LOCK`: not requested.
- DUT availability: not probed.
- R2 interference: none.

Only local Git/file inspection, offline tool-version inspection, branch/worktree creation, evidence generation, and evidence Git publication were performed.

## 22. Risks

1. v41D sequence/reset epoch and build-ID semantics are not frozen.
2. New MMIO control/state bit encodings are not frozen.
3. Revision-1 SSOT explicitly retains the transport ABI as provisional.
4. G2A has little routed LUT margin to the development hard stop.
5. G2A WHS is only +0.024 ns.
6. The donor source's 192-byte tail is unwritten and requires explicit zero generation.
7. A complete future implementation must preserve the legacy PIO path while adding separate DMA storage and strict CDC.

## 23. Hardware-test readiness

`G2B_HW_TEST_READY = false` / **BLOCKED**.

No hardware test is authorized or technically ready. This result does not qualify DMA, video capture, PCIe Gen2 negotiation, or 288 MB/s.

## 24. Recommended next step

Owner/Architect should freeze the exact v41D sequence/reset/build-ID semantics and the complete G2B MMIO register bit contract, then authorize the required SSOT interface update. Restart G2B from the existing unchanged isolated branch. One-channel C2H hardware qualification may begin only after a complete offline G2B pass, later Owner/Architect acceptance, and R2 release of the DUT.
