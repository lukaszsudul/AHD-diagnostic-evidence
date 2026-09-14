# Bank9 / 0x44 disposition

- Reference operation: read-modify-write clearing CH1-owned bit 0 (`old & 0xFE`).
- Current v41 effective byte: `0x00` from deterministic stage-2 product-equivalent autoinit and later overlay.
- Target owned bit: bit 0 = 0; other bits preserved.
- First-image delta: none; the current byte already satisfies the full masked target.
- Recovery authority: not needed because MODE1 does not touch this register.
- Final disposition: `EXCLUDED_FROM_MINIMAL_MODE1`.
