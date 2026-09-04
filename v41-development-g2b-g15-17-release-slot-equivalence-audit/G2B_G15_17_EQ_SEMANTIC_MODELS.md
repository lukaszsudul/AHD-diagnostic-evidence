# Groups 15-17 semantic models

## Common protocol proven independently

Each slot has a 56-bit token: a 24-bit generation and 32-bit epoch. The AXI final-beat branch updates the selected slot's token and release toggle on the same `userclk1` edge. The token is not cleared by later AXI or source-reset episodes. The lifecycle prevents another record from taking the same slot until the synchronized release and coherent retirement have completed.

The corresponding release bit crosses through a direct two-FDRE `ASYNC_REG` chain into `nvp_vclk1`. Semantic decoding reads `release_sync2_source[slot]` and then uses the held token. There is no combinational semantic use of the asynchronous toggle before sync2.

Normal decoding requires matching generation, descriptor epoch, current reset epoch, and `DMA_OWNED` state. A mismatch fails closed by asserting ownership-fatal signaling and disabling admission. During transport reset, the captured release phase and the stable token determine abandoned-record accounting. Acknowledgement waits until the full synchronized release vector and ownership phase equal their captured phases.

RTL anchors: declarations 205-210; initialization 356-373; synchronizers 456-468; ordinary decode 575-612; reset accounting and retirement 614-708; allocation 855-863; descriptor capture 1024-1032; captured release phase 1550-1554 and 1921-1926; final release launch 1791-1805.

## Slot classifications

| Group | Slot | Required semantic elements | Semantic result | Required classification | Candidate decision |
|---|---:|---|---|---|---|
| 15 | 1 | Stable generation/epoch token; release sync; mismatch containment; reset accounting; captured-phase retirement | All proven | `STRUCTURALLY_DIFFERENT` | `REQUIRE_SLOT_SPECIFIC_SETTLING_PLUS_STRUCTURAL_CDC` |
| 16 | 2 | Stable generation/epoch token; release sync; mismatch containment; reset accounting; captured-phase retirement | All proven | `STRUCTURALLY_DIFFERENT` | `REQUIRE_SLOT_SPECIFIC_SETTLING_PLUS_STRUCTURAL_CDC` |
| 17 | 3 | Stable generation/epoch token; release sync; mismatch containment; reset accounting; captured-phase retirement | All proven | `STRUCTURALLY_DIFFERENT` | `REQUIRE_SLOT_SPECIFIC_SETTLING_PLUS_STRUCTURAL_CDC` |

`STRUCTURALLY_DIFFERENT` records the real mapped-cone differences and does not mean semantic divergence. All three slots are semantically equivalent to slot 0 and have the same safety-relevant protocol graph. They are not exact slot-index netlist isomorphs: family depth vectors are slot 0 `[8,8,6]`, slot 1 `[9,9,6]`, slot 2 `[9,9,5]`, and slot 3 `[8,9,7]`; per-bit LUT input bindings also vary.

Because exact routed symmetry is rejected, no slot inherits Group 14 merely by name. Each slot's three families and 6.000 ns settling property were resolved and timed independently. This satisfies the compatible-method branch for a combined candidate.
