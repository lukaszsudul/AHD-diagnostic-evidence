# R1f address-collision and exact-formal zero proof

## Result

```text
R1F_READ_MAP_COLLISION=PASS_NONE
R1E_DEFINED_OFFSETS_PRESERVED=YES
LEGACY_NACK_WINDOW_PRESERVED=YES
FORMAL_PHASE2_R1F_RANGE_ZERO=PROVEN_FROM_EXACT_SOURCE_DECODE
R1F_WRITE_FIELD_MUTATION=NONE
PRIOR_INVALID_WRITE_ACCOUNTING=PRESERVED_BY_FORWARDING
```

The proof is source-based and uses the exact R1e and exact formal Phase-2 Git
objects. No source was edited during this audit.

## Source identities

Exact R1e:

```text
COMMIT=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
TREE=db8b5581a237e19905fd01c6d453793047bc3ba7
rtl/top/ahd_capture_top_xdma.sv blob=cd2f864702f3820009e8c683b359e822dfd71ae4
rtl/v41/control_status_regs.sv blob=fc46bf37804daa929d0453e4b258372048121014
rtl/v41/r1e_measurement_regs.sv blob=9e48ba8f9f58ce60939c5155faef3024ea133d34
rtl/pio/pio_bar_target.sv blob=1ab24dace7534d4c42d860e9234024440cb69f39
rtl/nvp/nvp6134c_i2c_bringup.vhd blob=cfe33464d8e75c514462786593b278d90b4059a4
```

Exact formal Phase 2:

```text
COMMIT=c89e88bcdf389614c884fb129e8b2d42a585bccb
TREE=417820c69c134161fcafae0947dc5976919814d1
rtl/top/ahd_capture_top_xdma.sv blob=c75db4b946a19a831e9869e3404b4640dae053d6
rtl/v41/control_status_regs.sv blob=3582a21f235678e3310b8dc523818cfeace96d97
rtl/pio/pio_bar_target.sv blob=1ab24dace7534d4c42d860e9234024440cb69f39
```

The exact formal and R1e images share the same preserved PIO target blob.

## Existing decode relevant to the proof

The exact R1e top has `SLOT_COUNT=2`. Its local control/status decoder handles
the identity page and, for reads only, page `0x2000..0x20FF`. The R1e
measurement module defines data through offset `0x94`, i.e.
`0x2000..0x2094`; its remaining local words read zero. R1e writes to that page
remain forwarded.

The exact formal top also has `SLOT_COUNT=2`, set both by the top parameter and
the formal build generic. Its local decoder handles only `0x0000..0x00FF` and
forwards the R1f range to the preserved PIO target.

For every read address below `0x10000`, the PIO target selects a capture slot
from address bits `[15:12]`. If the selected slot is greater than or equal to
`SLOT_COUNT`, the exact source completes the read with deterministic
`32'b0`. Therefore:

```text
slot 0 = 0x0000..0x0FFF (available capture storage)
slot 1 = 0x1000..0x1FFF (available capture storage)
slot 2 = 0x2000..0x2FFF (unavailable/reserved because SLOT_COUNT=2)
slot 3 = 0x3000..0x3FFF (unavailable/reserved because SLOT_COUNT=2)
```

The proposed R1f span `0x20A0..0x35FF` lies entirely within reserved slot 2
and reserved slot 3 in the inherited/formal decode.

## Collision matrix

| Existing allocation | Existing range | R1f overlap | Result |
|---|---:|---:|---|
| Identity/provenance/control local page | `0x0000..0x00FF` | none | PASS |
| Capture slot 0 | `0x0000..0x0FFF` | none | PASS |
| Capture slot 1 | `0x1000..0x1FFF` | none | PASS |
| R1e defined lifecycle/probe words | `0x2000..0x2094` | none; R1f starts `0x20A0` | PASS |
| R1e reserved-zero gap | `0x2098..0x209F` | none | PASS |
| R1f header and statistics | `0x20A0..0x23FF` | inherited reserved slot 2 only | PASS |
| R1f 64 x 24-byte records | `0x2400..0x29FF` | inherited reserved slot 2 only | PASS |
| R1f WADDR index log | `0x2A00..0x2DFF` | inherited reserved slot 2 only | PASS |
| R1f REGADDR index log | `0x2E00..0x31FF` | inherited reserved slots 2/3 only | PASS |
| R1f DATA index log | `0x3200..0x35FF` | inherited reserved slot 3 only | PASS |
| Preserved capture/control register page | `0x10000..0x10FFF` | none | PASS |
| Legacy NACK header/log | `0x10098..0x100D8` | none | PASS |
| PIO slot-0 mirror | `0x11000..0x11FFF` | none | PASS |

Arithmetic checks:

```text
R1F_HEADER_BYTES=352
R1F_PROBE_STAT_BYTES=512
R1F_FAILED_LOG_BYTES=64*24=1536
R1F_FAILED_LOG_LAST_WORD=0x29FC
EACH_INDEX_RANGE_BYTES=1024
EACH_INDEX_RANGE_DWORDS=256
EACH_INDEX_RANGE_16BIT_ENTRIES=512
R1F_TOTAL_SPAN_BYTES_0x20A0_THROUGH_0x35FF=5472
```

No record crosses `0x2A00`; no index log exceeds its assigned end.

## Exact formal Phase-2 zero proof

For every aligned address in `0x20A0..0x35FF` under the exact formal Phase-2
source:

1. the control/status decoder does not select it locally because its local
   range is only `0x0000..0x00FF`;
2. the request is forwarded unchanged to the PIO target;
3. the address is below `0x10000`, so the PIO target takes the slot-memory
   read branch;
4. address bits `[15:12]` are 2 or 3;
5. formal `SLOT_COUNT` is exactly 2;
6. the condition `selected_slot >= SLOT_COUNT` is true;
7. the exact PIO source returns `32'b0` without enabling a slot RAM.

Thus every DWORD in the complete R1f range reads deterministic zero under the
exact formal control image. This proof does not depend on SRAM initialization,
capture-slot validity, or host timing.

The Arm-B host fixture must still enumerate and assert every aligned DWORD
from `0x20A0` through `0x35FC` is zero. The fixture is confirmation of the
proven decode, not a replacement for it.

## R1f read integration and preservation

The R1f image may locally overlay reads in `0x20A0..0x35FF` because every
overlaid address was deterministic zero with `SLOT_COUNT=2`. Integration must:

- give R1f read selection priority over the inherited R1e page mux at
  `0x20A0..0x20FF`;
- preserve every R1e-defined offset and decoder path in `0x2000..0x2094`;
  in the R1f image those words carry the explicitly documented WADDR-counter
  and full-tri-lifecycle compatibility projection, so byte-identical dynamic
  values are not claimed;
- leave `0x2098..0x209F` zero;
- leave the legacy log window `0x10098..0x100D8` unchanged;
- return zero for unlisted and unaligned R1f reads;
- keep the R1f path read-only and structurally disconnected from functional
  NVP/capture control.

## Exact write-semantics interpretation

The prompt requires R1f fields to be read-only while retaining prior
reserved/invalid-write behavior. The exact prior behavior is *not* a literal
global write-ignore: a write below `0x10000` reaches the PIO invalid-write
branch, increments `err_bad_mmio_addr`, and records `last_bad_mmio_addr`.

Accordingly, the only interpretation that preserves exact prior behavior is:

```text
R1F_LOCAL_WRITE_SELECT=NO
R1F_FIELD_MUTATION_FROM_WRITE=NONE
WRITE_FORWARDED_TO_PRIOR_INVALID_WRITE_ACCOUNTING=YES
LEGACY_BAD_MMIO_DIAGNOSTIC_SIDE_EFFECT=PRESERVED
```

Locally absorbing a write would make it globally WI but would change the exact
prior invalid-write accounting, so that alternative is rejected. This
diagnostic accounting has no R1f-field or NVP functional effect. The authorized
hardware campaign issues zero AXI-Lite writes, so the distinction is never
exercised by measurement.

## Gate conclusion

```text
RECORD_MAP_COLLISION=NO
COMPLETE_R1F_RANGE_AVAILABLE=YES_WITH_SLOT_COUNT_2
FORMAL_ZERO_BEHAVIOR=PASS_EXACT_SOURCE_PROOF
WRITE_SEMANTICS_AMBIGUITY=RESOLVED_PRESERVE_INVALID_WRITE_ACCOUNTING
```

The map is conditional on the build retaining `SLOT_COUNT=2`. The pre-build
static gate and post-build provenance audit must fail if that generic changes.
