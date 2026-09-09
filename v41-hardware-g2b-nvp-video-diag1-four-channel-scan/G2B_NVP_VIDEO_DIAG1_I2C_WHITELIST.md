# Fixed I2C whitelist

Permitted compiled operations are limited to:

- Bank selector 0xFF (save/select/restore)
- Bank 0: BGDCOL 0x78 and 0x79
- Bank 0 read-only configuration/status: 0x80, 0x00..0x03, 0x08..0x0B, 0x81..0x88, 0xA8, 0xE0..0xE2, 0xE8..0xEB
- Bank 1: VDO1 route 0xC2, preserving unrelated bits

No general host-supplied I2C write service exists. Simulation whitelist gate: PASS.
