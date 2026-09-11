# SCAN0 inheritance

The SCAN1 implementation imports the frozen SCAN0 authority literally: 82 active reads, 10 bank groups, 14 prohibited side-effect reads excluded from the active manifest, 40 `RAW_SEMANTICS_PARTIAL` entries, A8 pre/post bookends, entry-bank save/restore with readback, 105 expected clean transactions, 25 kHz I2C and MMIO `0x12000..0x123FF`.

Imported authority identity was verified before implementation; SSOT was not changed.
