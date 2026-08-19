# Independent Review Erratum — NVP ACK Window Interpretation

## Scope

This erratum corrects only the extended interpretation of the existing R1
digital trace. It does not alter, replace, or invalidate the original raw or
decoded data. In particular, `TRACE_RAW.bin`, `TRACE_DECODED.csv`,
`ACK_DECISION_FOCUSED.csv`, the original report, the original correlation
report, and both sealed packages remain unchanged.

The corrected interpretation was derived directly from the published
`TRACE_DECODED.csv` at 62.5 MHz (16 ns per sample).

## A. Samples 1829 through 2446 are master-driven data

For every sample from 1829 through 2446, inclusive, the trace shows:

```text
SDA_STAGE1=0
SDA_STAGE2=0
SDA_FILTERED=0

SCL_STAGE1=1
SCL_STAGE2=1
SCL_FILTERED=1

SDA_DRIVE_LOW=1
SCL_DRIVE_LOW=0

CURRENT_TX_BYTE=0x60
BIT_INDEX=0
BYTE_PHASE=WRITE_ADDRESS
```

Because `SDA_DRIVE_LOW=1`, the LOW is driven by the FPGA I2C master. With
`CURRENT_TX_BYTE=0x60` and `BIT_INDEX=0`, this interval is address bit 0 of the
wire byte `0x60`; it is not a slave-owned ACK interval and is not evidence of a
slave ACK.

## B. Sample 2447 begins ACK preparation

At sample 2447 the drive enables change as follows:

```text
SDA_DRIVE_LOW: 1 -> 0
SCL_DRIVE_LOW: 0 -> 1
```

The master releases SDA for slave ownership and pulls SCL LOW. This is the
start of ACK preparation, not the ACK-high observation interval.

## C. SDA returns digitally HIGH after release

After the release at sample 2447, the synchronized/filtered SDA path returns
HIGH in this order:

```text
SDA_STAGE1=1 at sample 2451
SDA_STAGE2=1 at sample 2452
SDA_FILTERED=1 at sample 2455
```

## D. Functional decision occurs while SCL is still driven LOW

At the functional decision strobe, sample 3072, the trace shows:

```text
SDA_STAGE1=1
SDA_STAGE2=1
SDA_FILTERED=1

SCL_STAGE1=0
SCL_STAGE2=0
SCL_FILTERED=0

SDA_DRIVE_LOW=0
SCL_DRIVE_LOW=1

ACK_VALUE_USED_BY_FSM=0
```

The unchanged FSM therefore makes its ACK/NACK decision while SCL is still
physically observed LOW and actively driven LOW by the master.

## E. Actual observed SCL-HIGH interval follows the decision

SCL becomes physically observed HIGH only after the decision. The first
subsequent sample with the master releasing both lines and all synchronized /
filtered SCL stages HIGH is sample 3081. Across the 618 captured samples in
that subsequent released, qualified SCL-HIGH interval, observed filtered SDA
remains HIGH in every sample. No slave ACK LOW is observed in this captured
event.

## Corrected conclusions

```text
ORIGINAL_EXTENDED_ACK_INTERPRETATION=INCORRECT_MASTER_DRIVEN_LOW_MISCLASSIFIED_AS_SLAVE_ACK

MASTER_DRIVEN_ADDRESS_BIT_LOW=PROVEN

SLAVE_ACK_LOW_OBSERVED_IN_CAPTURED_EVENT=NO

ACK_DECISION_BEFORE_PHYSICAL_SCL_HIGH=PROVEN

ACK_PHASE_ARCHITECTURE_DEFECT=PROVEN

ACK_PHASE_DEFECT_IS_SOLE_NVP_ROOT_CAUSE=NOT_PROVEN

Z8_EXPECTED_TO_FIX_CAPTURED_REAL_DIGITAL_NACK=NOT_PROVEN

RAW_ANALOG_MEASUREMENT_AVAILABLE=NO
```

The trace proves an ACK-phase architecture defect: the functional decision is
made before the captured physical SCL-HIGH opportunity. It does not prove that
this phase defect is the sole NVP root cause, nor that moving the sample phase
will cause the NVP to acknowledge a transaction that remains digitally HIGH
through the actual captured SCL-HIGH interval.
