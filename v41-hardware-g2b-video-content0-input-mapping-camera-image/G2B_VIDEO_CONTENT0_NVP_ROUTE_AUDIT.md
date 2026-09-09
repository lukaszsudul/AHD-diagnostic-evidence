
# NVP route audit

- Source authority: `30b14d13b0b789b62b05ab513eb9578c7c43b11a` / tree `bdbe39077a03f8945ebdd1ed9e52761fbe787696`.
- `nvp6134c_autoinit.vhd` freezes `range_sel="10"`, `channel_sel="00"`,
  `output_sel=0xA`, `auto_enable=0`, and stage 2.
- `nvp6134c_diagnostics_pkg.vhd` maps Bank1 C2[3:0]=0 to channel 1 on
  VDO1, C8=0 to one-port/one-channel, and CA=0x22 to VCLK1/VDO1 enabled.
- Configured format is AHD 1080p25, 1920x1080 progressive at 25 frames/s.
- The table writes Bank0 0x78=0x88 and 0x79=0x88. The manufacturer's
  BGDCOL definition makes nibble value 8 digital black during No-Video, so
  the exact captured `80 10 80 10` image is consistent with the configured
  loss-of-video background. It is not proof that No-Video was asserted; a
  physically black valid scene can produce the same active pixels.
- Manufacturer status definitions exist for Bank0 A8 (NOVID), E0/E1/E2
  (AGC/clamp/H lock), E8..EB, and conditional Bank5..8 F0 classifiers.
- The current PRODUCT wrapper discards the sixteen channel read values and
  exposes only initializer first-error/activity diagnostics. Its runtime
  tri-phase I2C master is compiled out (`ENABLE_RTRACK_DIAGNOSTICS=0`).
- Therefore `0x80..0xB4` used by source readiness are initializer/activity
  telemetry, not an arbitrary live NVP-register service.
- `NVP_PER_CHANNEL_STATUS_ACCESS = NOT_AVAILABLE_IN_CURRENT_PRODUCT`.
- No documented, reversible multi-region NVP internal color-bar/ramp pattern
  was established for this profile. The documented BGDCOL control is a solid
  no-video background and cannot satisfy the requested pattern-isolation gate.
- Runtime channel selection is silicon-documented at Bank1 C2, but no governed
  host I2C transaction path exists in the current PRODUCT image. No NVP write
  was attempted.

Primary register source: `NVP6134C_Rev1_0.pdf`, SHA-256
`301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46`,
especially pages 20, 42, 58 and 88. The page-88 format classifier is conditional
on auto detection; this profile forces 1080p25 with AUTO off, so detected
standard/fps are not claimed.
