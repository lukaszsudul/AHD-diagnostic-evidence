# R2R10R4 — LEGACY1 capture-card-master-2 addendum

The local historical commit
`ee06d86f2ad6c30a83dabebfbb9df36b87df1c36` contains a reachable MicroBlaze
path `main -> Codec_Init -> Codec_SetupVideo`. It configures VIN1 / logical
CH1 / Bank5 for CVBS SD PAL 720H (576i50) and routes channel 0 to VDO1 in
1MUX SD mode. It is not TVI1080p25 CH3/Bank7.

The historical path does not read F0 or A8/NOVID and has no readiness loop,
deadline, or consecutive-sample criterion. Low-level helpers detect I2C
send/receive and bank-readback errors, but `Codec_SetupVideo()` ignores their
return values and reports success unconditionally. The commit subject is an
author declaration; no preserved ELF, execution receipt, detector readout,
sync sample, or camera frame was found in the reviewed material.

Impact on R2R10R4:

- exact F0=`0x34` for current TVI1080p25 remains unchanged;
- the old code does not establish that a first F0 sample must already be ready;
- its missing readiness check is a weaker policy, not evidence that PC310 is
  wrong;
- do not transfer the CVBS PAL table, Bank5 values, route, pinout, DMA, fixed
  delays, or error policy to CH3;
- preserve the finite R2R10R4 window with fresh samples, three consecutive
  F0=`0x34` and A8[2]=0 results, bounded time and transactions, and hard stops
  for NACK, timeout, bank, static-configuration, and CH2-protection failures;
- route only after readiness succeeds.

`TRANSFER_TO_CURRENT_TVI_CH3=PARTIAL`: only waiting/verification structure and
error policy are comparable. Register correctness is not transferable between
CVBS PAL CH1 and TVI1080p25 CH3.

No RTL, microcode, profile, PN, master, driver, DMA, or XDC change was made.
The DUT was untouched. This addendum does not prove the physical cause of
F0=`0xFF` or any historical NACK.
