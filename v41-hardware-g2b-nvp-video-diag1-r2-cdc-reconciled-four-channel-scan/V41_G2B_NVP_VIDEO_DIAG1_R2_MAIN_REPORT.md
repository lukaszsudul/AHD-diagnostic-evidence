# AHD v41 G2B NVP VIDEO DIAG1-R2 main report

Engineering gate: **FAIL**

Overall result: **FAIL**

Evidence publication: **PENDING — local package prepared, no commit or push performed by this assembler**

The exact source branch, commit and tree passed the minimal authority check. The
exact routed DCP passed SHA-256 identity and reopened read-only in Vivado 2025.2.
The complete raw CDC report reproduced the governed counts: 427 Critical rows
(423 CDC-1, 2 CDC-10, 2 CDC-13) and 874 Warning rows (13 CDC-6, 861 CDC-15).
All 423 CDC-1 destinations and their multiplicities were preserved; CDC-10 and
CDC-13 remained byte-identical; rule, severity, clock-pair, exception and
destination drift were zero.

The semantic reconciliation then encountered a governed hard failure. Seven
changed CDC-1 rows replace a `release_epoch_axi_reg` physical source with an
`axis_slot_reg` physical source, and three changed CDC-15 rows replace a
`release_generation_axi_reg` source with a `release_epoch_axi_reg` source.
These are different signal base names and different declared semantic source
families. R2 explicitly forbids normalizing different bus base names. The first
failed row is `CDC1-CHG-0286: PRODUCT release_epoch_axi_reg[0][9]/C -> diagnostic axis_slot_reg[1]/C at G2B_ONECH_C2H/enable_applied_source_reg/D`.

First failed gate: `FAIL — NVP_DIAG1_R2_UNRECONCILED_CDC_SOURCE_FAMILY`.

Mechanical reason: `NVP_DIAG1_R2_PROHIBITED_SOURCE_BASE_DRIFT`.

No profile-specific semantic manifest was created. The remaining R2 sign-off,
signed-off DCP write, bitstream generation, hardware eligibility, DUT contact,
JTAG, FPGA programming, reboot, driver load, NVP I2C, MMIO, DMA/AIO, capture,
baseline restore and hardware cleanup were not reached. The Owner-attested
PRODUCT runtime state therefore remains unchanged.
