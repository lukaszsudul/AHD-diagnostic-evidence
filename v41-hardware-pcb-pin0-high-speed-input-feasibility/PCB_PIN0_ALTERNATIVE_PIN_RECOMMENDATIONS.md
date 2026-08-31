# PCB-PIN-0 Alternative Pin Recommendations

Only materially useful alternatives are listed. The proposed sets are otherwise retained.

| Rank | Signal | Current proposed pin | Alternative | Bank/group | Clock relationship | Reason | Trade-off |
|---:|---|---|---|---|---|---|---|
| 1 | 27 MHz reference | C13, `IO_L11N_T1_SRCC_15` | D13, `IO_L11P_T1_SRCC_15` | 15/T1, X0Y1, LT | same SRCC pair, P-side | fixes Vivado `PLIO-9`: only P-side can drive a clock buffer single-ended | mandatory ball change; otherwise same bank/locality and preserves MRCC |
| 2 | provisional VDO2 bit on T15 | T15, `IO_L13N_T2_MRCC_14` | U15, `IO_L17P_T2_A14_D30_14` | 14/T2, X0Y0, LB | same R16 SRCC/BUFIO region | completes four contiguous data pairs L15-L18, pairs with U16, frees MRCC pair T14/T15 | PCB escape/routing changes; logical bit can be remapped freely |
| 3 | SCL | N17, `IO_L9N_T1_DQS_D13_14` | N18, `IO_L10P_T1_D14_14` | 14/T1, X0Y0 | control only; no video clock dependency | preserves the N16/N17 DQS pair for future high-speed use | optional; may worsen physical I2C routing; both have configuration-data alternates |
| 4 | 27 MHz reference | C13, `IO_L11N_T1_SRCC_15` | E13, `IO_L12P_T1_MRCC_15` | 15/T1, X0Y1 | MRCC P-side | valid second-choice clock input after VCLK1 moves | consumes an MRCC and reuses a current VCLK1 ball; D13 is cleaner |

## Retained pins

- E16 and R16 are preferred over using MRCC for the local video clocks because they are T2 SRCC inputs in the exact data regions.
- CH1 data already uses the complete L15-L18 P/N set; no better local replacement exists.
- C13 is not retained for the clock role; D13 is the required first-choice correction.
- K17/L18/M17 are ordinary, locally convenient controls and need no architectural replacement.

## Routing recommendation

Apply `C13 -> D13` before routing the oscillator clock. Also apply `T15 -> U15` before freezing the CH2 escape if practical. If routing constraints force T15, the original CH2 set remains valid with the explicit cost that the T14/T15 MRCC pair is no longer available as a differential clock input.
