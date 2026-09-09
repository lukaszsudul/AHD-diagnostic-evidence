# Diagnostic MMIO map

- Identity: `G2B_NVP_VIDEO_DIAG_MMIO_V1`
- Range: `0x3C00..0x3FFF`
- DIAG_MAGIC at 0x3C00: `0x4E565034`
- DIAG_VERSION at 0x3C04: `0x00010000`
- Control/status and timing: 0x3C08..0x3C6C
- Additional raw status: 0x3C7C..0x3C90
- 16-entry result table: 0x3D00..0x3EFF
- PRODUCT MMIO `0x3800..0x3BFF`: unchanged

Collision and read/write decode simulation: PASS. Runtime identity: NOT_REACHED.
