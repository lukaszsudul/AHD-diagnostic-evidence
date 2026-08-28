# AHD v41 G2B Source Interface Receipt

## Receipt result

`BLOCKED BEFORE IMPLEMENTATION`

First blocker: `G2B_RECORD_ABI_NOT_FROZEN`.

The reusable one-input source path was identified, but it was not extended or connected to XDMA because the externally visible record ABI is provisional. No source RTL, protected R1i RTL, tests, or build inputs were changed.

## Source authority

The source inspection used accepted G2A commit `224d194e5f82c85bcb29297561c5d5e76d28063b` without checkout or modification.

Relevant source objects at that commit:

- `rtl/top/ahd_capture_top_xdma.sv`
- `rtl/video/video_capture.sv`
- `rtl/record/bt656_record_producer.sv`
- `rtl/pio/pio_slot_adapter.sv`

Relevant G1 contracts in the read-only evidence snapshot:

- `V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md`, lines 38–47 and 122–124
- `V41_G1_ONE_CHANNEL_DMA_CONTRACT.md`, lines 5–28
- `V41_G2_IMPLEMENTATION_CONTRACT.md`, lines 88–101

## Existing reusable source

| Item | Accepted G2A source |
|---|---|
| Top integration | `ahd_capture_top_xdma` |
| Capture subsystem | `g0p8c2_capture_subsystem` in `rtl/video/video_capture.sv` |
| Record producer | `g0p8c2_bt656_slot_producer` in `rtl/record/bt656_record_producer.sv` |
| Physical source | VDO1 / physical input 0 |
| Source clock | recovered `nvp_clk` / `clk_vdo`; G1 expectation 148.5 MHz, 6.734 ns constraint |
| Input data width | 8-bit BT.656 byte stream, `data_byte[7:0]` |
| Existing record write width | 64-bit `producer_write_data` |
| Existing record address | 9-bit 64-bit-word address, 512 positions |
| Existing payload | 3840 UYVY bytes from one validated active line |
| Existing completion | one-cycle `producer_commit` after payload/EAV validation and all header writes |
| Existing provenance | 24-bit slot generation plus 4-bit slot index |

The current producer validates BT.656 SAV/EAV context, admits an eligible active line only when a free slot is selected, captures exactly 3840 payload bytes, writes eight 64-bit header words, then asserts `producer_commit`. A malformed or bad-length source record is not committed as a valid record.

## Existing flow-control semantics

The current producer is not a conventional record-level `valid/ready` source:

- `producer_free_mask[15:0]` is observed before line admission;
- payload/header writes are emitted with `producer_write_enable`;
- completion is a separate `producer_commit` pulse;
- `g0p8c5a_pio_slot_adapter` exposes an AXIS-shaped temporary PIO boundary and derives `s_axis_tready` from slot ownership, but the producer itself has no ready input for per-beat backpressure;
- video input cannot be backpressured.

Consequently, G1 requires a whole-record admission sink and separate DMA storage rather than direct per-byte throttling of the VDO1 source.

## G1-required G2B source extension

If the ABI is frozen, the one-channel implementation must:

1. map only physical input 0 to logical channel 0;
2. leave R1i NVP initialization independent of DMA enable and PCIe reset;
3. enable streaming only after `INIT_DONE=1`, `INIT_ERROR=0`, local video release, and a valid host enable request;
4. add a mutually exclusive streaming mode to the donor recordizer while preserving byte-exact legacy v40B/PIO behavior when DMA mode is off;
5. write only complete records into a dedicated channel-0 four-slot DMA ring;
6. create a commit descriptor containing channel, slot, generation, and reset epoch only after complete-record admission;
7. prevent rewriting a committed slot until beat 511 is accepted and ownership is returned; and
8. suppress malformed records and perform whole-record drop accounting when no slot is free.

G1 role name `v41_dma_record_sink` covers admission, commit/drop accounting, and discontinuity propagation. `v41_dma_record_ring` provides separate DMA storage. G2 may change syntax but may not merge clock ownership in a way that weakens these boundaries.

## Protected boundary

The source selection requires no edit to:

- `rtl/nvp/nvp6134c_i2c_bringup.vhd`
- `rtl/nvp/nvp6134c_autoinit.vhd`

No such edit was made or proposed. The existing NVP init table, I2C timing/qualification, ACK/STOP/BUS_FREE behavior, retry/backoff, timeout, bank safety, settling, and R1i telemetry remain outside G2B source-plane ownership.

## Implementation status

| Item | Status |
|---|---|
| Source path identified | `YES` |
| Source interface documented | `YES` |
| Streaming-mode extension | `NOT IMPLEMENTED` |
| DMA record sink | `NOT IMPLEMENTED` |
| Four-slot DMA ring | `NOT IMPLEMENTED` |
| XDMA C2H connection | `NOT IMPLEMENTED` |
| Source simulation | `NOT RUN` |

Implementation is intentionally stopped until `G2B_RECORD_ABI_NOT_FROZEN` is resolved.

