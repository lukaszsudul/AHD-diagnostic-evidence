# G2B-LUT0 BRAM Packing Review

## Finding

The four G2B slots are already inferred efficiently. No duplicated payload storage or distributed-RAM payload spill was found, and a different inference style is unlikely to reduce BRAM or materially reduce LUT.

## Actual implementation

`rtl/g2b/v41_g2b_onech_c2h.sv` instantiates four `xpm_memory_sdpram` memories in `GEN_G2B_SLOT`:

- 512 words × 64 bits = 32,768 allocated data bits per slot;
- `MEMORY_PRIMITIVE="block"`;
- independent source-write and AXI-read clocks;
- 9-bit A and B addresses;
- registered, one-cycle read;
- one source write port and one AXI read port.

The direct post-opt checkpoint query finds exactly four `RAMB36E1` primitives below `G2B_ONECH_C2H`, one per slot. The hierarchy report's zero-BRAM module row is a flattening/repartition artifact. The 44 LUTRAMs within the core are metadata: 24 LUTRAM for `desc_attempt_source`, 16 for `desc_generation_source`, and 4 for the four-entry commit FIFO.

## Efficiency

Each ABI slot is exactly 4,096 bytes. The design stores 488 64-bit beats (3,904 bytes: header plus payload) and emits the final 24 zero-padding beats (192 bytes) without RAM reads.

| Metric | Per-slot efficiency |
|---|---:|
| Meaningful bytes versus logical 4 KiB slot | 3,904 / 4,096 = 95.3125% |
| Allocated 32 Kibit geometry versus 36 Kibit RAMB36 | 32,768 / 36,864 = 88.889% |
| Meaningful stored bits versus raw RAMB36 | 31,232 / 36,864 = 84.722% |
| Payload-only bits versus raw RAMB36 | 30,720 / 36,864 = 83.333% |

Four slots therefore consume four RAMB36 tiles. The device-wide G2A-to-G2B increase is also four BRAM tile equivalents. XDMA changes from 19 RAMB36 + 1 RAMB18 to 18 RAMB36 + 3 RAMB18, which is 19.5 tile equivalents in both cases.

Per-slot descriptor state is stored separately: five 32-bit fields, one 24-bit generation, and one 32-bit epoch, or 216 bits/slot and 864 bits total before optimization. That state supports ownership, generation and reset-epoch correctness; it is not a duplicate copy of payload.

## Alternatives

Combining the slots into one 2,048×64 simple-dual-port bank would still require four RAMB36 primitives. It could add depth selection/cascade logic and is estimated to save only 0–20 LUT, if any. Packing metadata into headers may offer a larger category-B saving, but it changes read timing and ownership proof obligations and must be evaluated separately from RAM inference.

Recommendation: keep the four explicit XPM block memories as the baseline. Do not spend G2B-LUT1 risk on a BRAM-style rewrite unless controlled synthesis contradicts this review.

