# Source freeze

- Repository: `lukaszsudul/FPGA_AHD`
- Dedicated branch: `diag/v41-nvp-i2c-25khz-r1e-observability`
- Dedicated worktree: `C:\FPGA\WORKTREES\V41_NVP_R1E_EXTENDED_OBSERVABILITY_R1`
- Base commit: `f007dc172d43d30b02729755e60382f8ce3dbff4`
- Base tree: `b8f87966c8021396acb6341bd2d7d86a10fd7f13`
- R1e source commit: `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`
- R1e source tree: `db8b5581a237e19905fd01c6d453793047bc3ba7`
- Part: `xc7a35tcsg325-2`
- Vivado: `2025.2 build 6299465`
- Active autoinit setting: 25,000 Hz on `axi_aclk` at 62.5 MHz

Protected inputs matched the required Git blobs before editing and after the source commit:

| Path | Git blob |
|---|---|
| `rtl/nvp/nvp6134c_autoinit.vhd` | `5dc0230cd569f03d68452055db6b10c5fcade751` |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `cfe33464d8e75c514462786593b278d90b4059a4` |
| `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | `7ddd60fc86da49cda1adcd7af7b772b337c95df6` |
| `xdc/boards/current/nvp_control.xdc` | `2e4a6f56d5dfa227a968492fe4476d25721f09f9` |

The exact R1 lifecycle files were copied byte-for-byte:

- `axi_clock_lifecycle_monitor.sv`: `c8c8145b12494cbdd54de7760f0558e6ab5fef11`
- `axi_clock_measurement_regs.sv`: `64f4a3df745bcde00f9facac3030637a32a19485`

The worktree was clean at commit and remained clean after the sole build attempt. No LitePCIe, formal, R1/R1b/R1c/R1d branch, or primary checkout was modified.
