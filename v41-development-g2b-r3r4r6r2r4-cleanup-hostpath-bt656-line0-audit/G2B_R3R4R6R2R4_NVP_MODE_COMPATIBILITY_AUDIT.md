
# NVP mode compatibility audit

Read-only local evidence establishes:

- autoinit selects profile `10`, documented in the RTL as AHD 1080p25;
- the mode byte selected for that profile is `0x03`;
- channel selection is `00` (CH1 to VDO1), stage 2;
- output overlay retains one-port/one-channel VDO1 routing (`C2=00`, `C8=00`),
  enables VCLK1/VDO1 (`CA=22`), normal bit order (`CB=00`), and programs
  VCLK1 selector/delay `CD=4A`;
- data-output registers `0x7A` and `0x7B` are written `0x11` and described only
  as the default output mode in the local package;
- existing NVP simulations validate I2C sequencing/table behavior, not a
  cycle-accurate VDO1 marker stream.

The local public-datasheet audit explicitly records undocumented/private
register limitations. It does not establish the exact F/V/H polarity, low
nibble convention, vertical-blanking marker count, or 1080p25 frame-boundary
byte sequence produced by the programmed device. Consequently the configured
profile is proven, but protocol compatibility at the failing boundary is not.

`H4_NVP_MODE_MISMATCH=OPEN`

No NVP register or RTL source was changed. The missing evidence is a bounded
post-frontend raw marker/state trace, not a reason to guess a new register
value.
