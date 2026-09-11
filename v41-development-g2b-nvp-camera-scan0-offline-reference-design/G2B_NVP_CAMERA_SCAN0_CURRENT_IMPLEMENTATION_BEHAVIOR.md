# Exact current-v41 NVP behavior

The current source is a one-shot static profile, not an adaptive camera-acquisition loop.

| Behavior | Source proof | Finding |
|---|---|---|
| Start condition | `nvp6134c_autoinit.vhd:158-173` | after fixed start delay, `started=0` emits one pulse and latches `started=1` |
| One-shot | `nvp6134c_autoinit.vhd:161-178` | no periodic restart; only reset clears `started` |
| Format | `nvp6134c_autoinit.vhd:193` | profile 2, AHD 1080p25 |
| Channel | `nvp6134c_autoinit.vhd:197` | CH1 to VDO1 |
| AUTO | `nvp6134c_autoinit.vhd:198` | disabled |
| Stage | `nvp6134c_autoinit.vhd:199` | stage 2 |
| I2C rate | `ahd_capture_top_xdma.sv:121` and `:376` | 25,000 Hz for autoinit and diagnostic fixed master |
| Clock/domain | `ahd_capture_top_xdma.sv:45,104,124,378` | `autonomous_clk = axi_aclk` |
| Open drain ownership | `ahd_capture_top_xdma.sv:67-74` | wired AND of release controls; no active-high drive |
| Master timeouts | `nvp_i2c_fixed_master.sv:12-15,243-275,386-403` | fixed SCL and bus-idle timeouts; releases on abort |
| Read set | `g2b_nvp_video_diag.sv:77-83,846-851` | Bank0 A8/E0/E1/E2/E8+channel plus configuration verify reads |
| Write whitelist | `g2b_nvp_video_diag.sv:690-799,1029-1065` | Bank select, BGDCOL 0x78/0x79 and Bank1 VDO1 route 0xC2 only |
| Restore | `g2b_nvp_video_diag.sv:1023-1093` | original BGDCOL/route/entry bank restored and read back |
| Diagnostic isolation | `ahd_capture_top_xdma.sv:620-622,1185-1235` | DIAG1 exists only when compile-time enable is nonzero |

Absent are the private-bank detector loop, host/circuit debounce campaign, callable `set_chnmode`, reference-equivalent initial EQ action, and no-video slice sweep. Thus a connected camera can leave output at BGDCOL when the fixed CH1/AHD1080p25/static-EQ assumptions do not yield valid decoder lock; the current diagnostic changes background color and route, not the input acquisition state.
