# Four-channel configuration audit

Result: `REUSE_EXISTING`.

The PRODUCT autoinit table already enables per-channel control and normal AFE operation for CH1..CH4, disables AUTO on 0x08..0x0B, selects AHD 1080p25 through HD_MD 0x81..0x84 = 0x03, sets SP_MD 0x85..0x88 = 0x00, and configures per-channel Bank-1 clocks. See `rtl/nvp/nvp6134c_diagnostics_pkg.vhd:392-438`.

The diagnostic FSM therefore verifies these compiled values but does not rewrite the mode configuration (`g2b_nvp_video_diag.sv:577-618`). This avoids speculative channel-address translation.
