# AHD v41 — CH3 R2R10R12

Exact R11R1 experimental image activation passed: one volatile SRAM program, JTAG DONE=1, one warm reboot and fresh runtime identity for source `d0f28b35c44d66bfd46c2b02388cdf03923e0c0a`.

The sole PREPARE attempt failed before APPLY and before the new EQ finalization. Loader terminal was `0xC3C02602` (code 19). The first post-terminal MMIO access read the first-failure header. The coherent record was:

- HEADER `0xF11E9067`
- COMMAND `0x0000D80E`
- CONTEXT `0x00300909`
- HEADER2 `0xF11E9067`

It resolves to PREPARE PC14, confirmed Bank9, register `0x6C`, read operation, I2C read-address NACK, raw cause `0x03`, no timeout and no valid read data. The current microcode instruction at PC14 is `26C60`, a read of Bank9/`0x6C` into scratch slot 6.

APPLY_A, EQ finalization, SCAN1, C2H and PNG were not run. This result does not evaluate the new EQ sequence and does not establish the physical cause of this or the historical NACK. Normal owned-driver unload and both lock releases passed. The R11R1 SRAM image was left without reset or rollback; the resulting NVP state is not claimed to be baseline-restored or profile-applied.

Scope: one experimental deployment attempt; no product qualification.
