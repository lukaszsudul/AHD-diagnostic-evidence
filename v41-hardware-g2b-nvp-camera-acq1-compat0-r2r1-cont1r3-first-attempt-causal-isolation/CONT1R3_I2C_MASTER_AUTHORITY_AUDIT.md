# CONT1R3 I2C Master Authority Audit

Result: `PASS`.

- Exact instantiated master: `rtl/v41/nvp_i2c_fixed_master.sv` SHA-256 `8C916DD7E3967AB22FF0ED90D9BC4533FA50ADE3FB0F4EB620D26B35E93363BF`.
- Exact scanner: `rtl/g2b/g2b_nvp_camera_scan1.sv` SHA-256 `130A99A1ABE976CF182963C312C747D74B8A1EBD0F3237A0F966F6DDAB363C05`.
- Exact combined wrapper: `rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv` SHA-256 `273EEC7C60CFB196A4E9C89E1C5AFE5E4A530278DAB107E4C083F62538985BF5`.
- Instantiated parameters: `CLK_HZ=NVP_AUTOINIT_CLK_HZ=62500000`, `I2C_HZ=25000`; default timeout parameters therefore resolve to `SCL_TIMEOUT_CYCLES=1250`, `BUS_IDLE_TIMEOUT_CYCLES=62500`.
- `autonomous_clk` and scanner `clk` are the same XDMA `axi_aclk`; expected and build-verified application frequency is 62.5 MHz.

Existing raw completion causes are: WADDR `0x1`, REGADDR `0x2`, RADDR `0x3`, DATA `0x4`, SCL timeout `0x5`, and bus-idle timeout `0x6`.

The master synchronizes and qualifies SCL/SDA, gates high-phase advancement on filtered SCL, and uses bounded SCL and bus-idle waits. `scl_release`/`sda_release` are open-drain release controls. The master-generated NACK ending a successful one-byte read is a separate state and is not an error cause.

The raw cause is connected to SCAN1. On an eligible first-attempt entry NACK SCAN1 sets only `retry_used`; when the retry succeeds, the published entry contains valid/retried/bank-verified bits but no first-attempt cause. The information loss is therefore the successful-retry publication path in SCAN1, not the low-level detector.

Conclusions:

- `FIRST_ATTEMPT_CAUSE_EXISTS_BELOW_SCAN1`
- `SCL_QUALIFICATION_PRESENT`
- The low-level master need not change for CONT1R3; only its existing `transaction_sequence` requires pass-through to the scanner boundary.

These source facts do not establish an electrical root cause.
