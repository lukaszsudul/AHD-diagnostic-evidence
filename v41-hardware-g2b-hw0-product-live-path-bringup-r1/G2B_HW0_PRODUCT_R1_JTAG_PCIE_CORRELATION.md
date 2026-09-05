# G2B-HW0-PRODUCT-R1 JTAG to PCIe Correlation

T0 correlation result: `PASS`

## Fresh JTAG identity

- Target count: `1`.
- Full path: `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`.
- Canonical ID: `Xilinx/80802026a98b01`.
- TID/device: `jsn-DLC10-80802026a98b01`.
- Frequency: `6000000 Hz`, unchanged.
- Device count: `1`; chain index: `0`.
- Part / IDCODE: `xc7a35t / 0362D093`.
- Additional JTAG devices: `0`.

The first legacy-selector inventory refused the obsolete
`Digilent/210241768436` literal and performed no program operation. The
accepted exact selector then passed five stable pre-program samples and five
stable final samples.

## Accepted physical binding

Accepted migration/R1H/R7 evidence binds the exact Xilinx cable, FPGA,
authoritative DUT, and physical AHD board to historical endpoint
`0000:01:00.0`, parent `0000:00:01.1`, vendor/device `10ee:7011`, subsystem
`10ee:0007`, class `058000`, BAR0 131072 bytes. File paths and SHA-256 values
are frozen in `raw/HISTORICAL_JTAG_PCIE_BINDING_VERIFICATION.log`.

This accepted binding supports T0 board ownership. It does not replace the
required fresh post-program endpoint and link measurements. After programming,
the historical root function and AHD endpoint remained absent, so correlation
could not be retained into T1. T1 stopped with
`BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE`.

The accepted sources were reviewed in the executing task before T0. The raw
historical-binding verification file in this package is a post-run rehash at
`2026-09-05T22:26:29Z`; it preserves source identity and does not claim a fresh
pre-program live endpoint/root mapping.
