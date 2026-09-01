# G2B-BS3 Mutation and Hardware-Protection Audit

## Source repositories

| Repository/worktree | Start branch | Start HEAD | End branch | End HEAD | BS3 mutation |
|---|---|---|---|---|---|
| `C:\FPGA\FPGA_AHD` | `main` | `be94f88ee8d179f12928ab791bdae27c22cd1762` | `main` | `be94f88ee8d179f12928ab791bdae27c22cd1762` | NO |
| `C:\FPGA\V41_G2B` | `integration/v41-g2b-onech-c2h` | `224d194e5f82c85bcb29297561c5d5e76d28063b` | `integration/v41-g2b-onech-c2h` | `224d194e5f82c85bcb29297561c5d5e76d28063b` | NO |

The primary repository began with pre-existing untracked `.codex_tmp/` and `reports/`. The G2B worktree began with pre-existing modified/untracked implementation content. BS3 neither cleaned nor altered those entries. Tracked/index diffs attributable to BS3 are empty.

## Protected content hashes

| File | Start SHA-256 | End SHA-256 | Result |
|---|---|---|---|
| `C:\FPGA\V41_G2B\rtl\g2b\v41_g2b_onech_c2h.sv` | `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471` | `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471` | PASS |
| `C:\FPGA\V41_G2B\xdc\common\g2b_cdc.xdc` | `2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF` | `2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF` | PASS |

## Required declarations

- FPGA_AHD source modified: `NO`.
- Active XDC modified: `NO`.
- Source index changed: `NO`.
- Source branch movement: `NO`.
- SSOT/project-current-state modified: `NO`.
- Synthesis run: `NO`.
- Place/route run: `NO`.
- Bitstream produced: `NO`.
- Hardware accessed: `NO`.
- JTAG/PCIe/DMA/programming/reboot/power-cycle: `NO`.
- `report_bus_skew` attempted: `NO`.

Vivado activity was limited to opening the sealed routed checkpoint, isolated timing-constraint reloads, bounded timing/methodology/exception queries, and constraint export. Reading the placement/routing databases during `open_checkpoint` is not a place/route execution.
