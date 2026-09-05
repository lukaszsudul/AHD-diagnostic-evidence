# G2B HW0 PRODUCT T0 Receipt

T0 result: `BLOCKED`

## Passed offline components

- SSOT revision 8 and mandatory frozen read order: `PASS`.
- META-8A authority: `PASS`.
- Recovery-4 authority and required files: `PASS`.
- Exact bitstream hash/size: `PASS`.
- Exact signed-off DCP hash/size: `PASS`.
- Source branch/commit/tree publication: `PASS`.
- Dual-layer identity contract loaded: `PASS`.
- Authoritative and protected source worktrees tracked-clean: `PASS`.

## Unmet components

- Complete runtime identity can be read within granted MMIO authority: `FAIL`.
- Fresh authenticated Linux inventory: `NOT_REACHED`.
- Fresh JTAG chain: `NOT_REACHED`.
- Exact AHD endpoint: `NOT_REACHED`.
- DUT exclusivity: `BLOCKED`.
- JTAG-to-PCIe board correlation: `BLOCKED`.

First blocker:

`BLOCKED — ADDITIONAL_HARDWARE_AUTHORIZATION_REQUIRED`

No programming may occur until all T0 components pass. T1 was not run.
