# R1c Arm B — formal 50-kHz shortening result

## Result

```text
ROLE=ARM_B_FORMAL_50KHZ
AVAILABILITY_CLASSIFICATION=AGGREGATE_ONLY_NOT_COMPUTABLE
ARM_B_CONTROL_FLOW_SHORTENING=NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_REASON=COUNTER_ABSENT_AND_FULL_ORDERED_NACK_LOG_ABSENT
```

Arm B is the exact accepted formal Phase-2 bit.  Its source does not contain
the R1 lifecycle monitor or R1 measurement-register module.  The formal image
leaves the R1 measurement overlay absent/reserved.

The retained raw telemetry contains 40 reads.  It reads `0x00002000` once and
gets zero, but that address is the diagnostic-magic/reserved word in this
image—not a count—and no lifecycle counter field (including `0x00002014` or
`0x00002018`) was read.

The BAR exposes only `DETAIL0..DETAIL5`, 192 diagnostic bits.  The internal
ordered NACK log was not host-visible.  The available observations are only
the aggregate NACK count (15) and first-error tuple
`CODE_0x01_STEP_0x02_META_0x01_PHYS_0x01_REG_0xCA_VALUE_0x66`.

The historical R1 counter value is not substituted for this arm.  The formal
zero/reserved `0x2000` value is not interpreted as a zero cycle count.

