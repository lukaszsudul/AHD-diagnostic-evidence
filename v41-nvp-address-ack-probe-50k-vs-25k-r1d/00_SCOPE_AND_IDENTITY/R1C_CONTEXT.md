# R1c context carried into R1d

The prior valid paired observation supplied by the Owner was:

- 25-kHz full autoinit: `INIT_DONE=1`, `INIT_ERROR=1`, `NACK_COUNT=8`,
  `TIMEOUT_COUNT=0`, `SAV=0`, `FRAME=0`.
- exact formal 50-kHz full autoinit: `INIT_DONE=1`, `INIT_ERROR=1`,
  `NACK_COUNT=15`, `TIMEOUT_COUNT=0`, `SAV=0`, `FRAME=0`.
- `R1C_CLASSIFICATION=PARTIAL_OR_MIXED_EFFECT_SINGLE_SAMPLE`.

R1d does not repeat full autoinit. Its measured quantity is
`POST_INIT_ADDRESS_PHASE_NACK_RATE` for the address byte `0x60`, with no
register, data, or read-address bytes. It does not measure a generic bus BER,
payload integrity, analog signal quality, or full-autoinit recovery.

