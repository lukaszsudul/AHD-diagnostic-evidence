# Reference CVBS slice-helper disposition

- Result: `PROVEN_NOT_EXECUTED`.
- Current v41 source: `nvp6134c_autoinit.vhd` fixes `range_sel => "10"`, documented as profile 2 AHD 1080p25, and `channel_sel => "00"` for CH1 to VDO1.
- Current mode mapping: `nvp6134c_diagnostics_pkg.vhd` maps profile `10` to mode byte `0x03`, AHD 1080p25.
- Accepted connected baseline context: NOVID remained `1` and `F0=0xFF`; this is the governed 1080p no-video observation under the fixed AHD 1080p25 target profile.
- Reference enum: `NVP6134_VI_720P_2530=0x10`; `NVP6134_VI_1080P_2530=0x20`; `NVP6134_VI_1080P_NOVIDEO=0x24`.
- Helper guard: `ch_mode_status[ch] < NVP6134_VI_720P_2530`.
- Therefore the governed target context is not below the helper threshold; `nvp6134_cvbs_slicelevel_con` contributes no additional functional write to this task.
- This proof does not authorize the separate explicit Bank5 `0x08` then `0x05` slice action.
