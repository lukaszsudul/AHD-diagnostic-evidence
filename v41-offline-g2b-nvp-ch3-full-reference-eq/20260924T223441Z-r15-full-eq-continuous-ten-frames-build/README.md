# AHD v41 R15 — full-reference CH3 EQ and continuous ten-frame build

## Result

`BLOCKED_POST_OPT_LUT_CAPACITY`

The target TVI1080p25/physical CH3/index-2 source path is fully accounted for in the reviewed target scope: 28 rows, 0 `MISSING_REQUIRED`. This is source completeness only; no functional or hardware test was performed.

The implementation is hybrid: a restricted FPGA service uses the existing I2C master, while the bounded Linux host program performs the target reference EQ control flow and selects ten fresh complete frames around T0+1..10 seconds from one continuous C2H session.

The single authorized build performed one synthesis and one `ExploreArea`. Post-opt use was 21,377 Slice LUTs for 20,800 available. Placement, routing, post-route physical optimization and bit generation were not run. No bitstream exists.

The Linux reader source exists, but its target binary was not created because a compatible Linux compiler was unavailable. The package is not ready for hardware.

DUT contact, JTAG, MMIO, I2C, driver operations, DMA and capture were zero.