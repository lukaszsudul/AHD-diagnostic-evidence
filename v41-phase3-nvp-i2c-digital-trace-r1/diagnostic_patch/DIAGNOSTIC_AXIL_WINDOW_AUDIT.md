# Diagnostic AXI-Lite Window Audit

## Existing decode

1. `v41_axi_lite_host_bridge` passes address bits `[16:0]`, matching the 128 KiB user aperture.
2. `v41_control_status_regs` handles only addresses whose `[16:8]` are zero; the existing 53-register region ends at `0x00E0`.
3. Other requests are forwarded unchanged to `g0p8c2_capture_subsystem` / `pio_bar_target`.
4. With formal `SLOT_COUNT=2`, valid capture-slot memory occupies slots 0 and 1 (`0x0000..0x1FFF`, subject to the existing local register overlay).
5. Reads in slot indices 2 through 15 (`0x2000..0xFFFF`) return deterministic zero because `host_req_addr[15:12] >= SLOT_COUNT`.
6. The formal application register page is `0x10000..0x10FFF`; the slot-0 mirror is `0x11000..0x11FFF`. Reads above that through `0x1FFFF` return zero.
7. Writes below `0x10000` are rejected by the formal application as bad MMIO and increment its error telemetry. The diagnostic interceptor must prevent diagnostic-window writes from reaching that application path and must ignore them with no state effect.

The prompt's preferred `0x1000` status page is unsafe because it overlaps valid capture slot 1. It is rejected.

## Selected diagnostic-only map

```text
DIAGNOSTIC_STATUS_BASE=0x02000
DIAGNOSTIC_STATUS_END=0x020FF
DIAGNOSTIC_TRACE_BASE=0x03000
DIAGNOSTIC_TRACE_END=0x0AFFF
TRACE_BYTES=32768
BAR0_APERTURE_END=0x1FFFF
```

This is the lowest aligned layout that:

- does not overlap the existing 53 registers;
- does not overlap valid slot 0 or slot 1;
- does not overlap the formal `0x10000` register page or `0x11000` mirror;
- fits 4096 samples x 64 bits entirely inside BAR0;
- uses ranges that are deterministic-zero/no-read-side-effect in the formal image.

The diagnostic module will intercept only these exact ranges. Existing transactions outside them retain the original decode and response path.

## Alias and restore implications

The host dump tool must reject offsets outside the 17-bit BAR0 aperture. Within the aperture, the selected ranges do not alias any valid formal register or slot. After formal restoration, a bounded read of `0x02000` is safe and deterministically returns zero, so absence of diagnostic magic can be verified without a write.

```text
CURRENT_DECODE_WIDTH_BITS=17
EXISTING_REGISTER_RANGE=0x0000..0x00E0
EXISTING_REGISTER_ENTRIES=53
VALID_CAPTURE_SLOT_RANGE=0x0000..0x1FFF
SAFE_DIAGNOSTIC_STATUS_RANGE=0x02000..0x020FF
SAFE_DIAGNOSTIC_TRACE_RANGE=0x03000..0x0AFFF
HIGH_ADDRESS_ALIAS_WITHIN_BAR0=NO
OVERLAP_WITH_EXISTING_53_REGISTERS=NO
OVERLAP_WITH_VALID_CAPTURE_SLOTS=NO
BLOCKED_NO_SAFE_DIAGNOSTIC_AXIL_WINDOW=NO
DIAGNOSTIC_AXIL_WINDOW_GATE=PASS
```

