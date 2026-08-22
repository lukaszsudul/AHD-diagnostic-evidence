# R1c Arm A — 25-kHz shortening result

## Result

```text
ROLE=ARM_A_25KHZ
AVAILABILITY_CLASSIFICATION=AGGREGATE_ONLY_NOT_COMPUTABLE
ARM_A_CONTROL_FLOW_SHORTENING=NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_REASON=COUNTER_ABSENT_AND_FULL_ORDERED_NACK_LOG_ABSENT
```

The exact Arm-A source is commit
`f007dc172d43d30b02729755e60382f8ce3dbff4`, tree
`b8f87966c8021396acb6341bd2d7d86a10fd7f13`.  Its only functional RTL
change relative to formal Phase 2 is the top-level `I2C_HZ` connection from
50,000 to 25,000.  It does not contain the R1 lifecycle monitor or R1
measurement-register module.

The retained raw telemetry contains 40 reads.  It reads `0x00002000` once as
the zero diagnostic-magic/reserved word, but reads none of the lifecycle
counter fields in the R1 overlay (including `0x00002014` and
`0x00002018`).  A zero at the reserved word is not a counter value.

The BAR exposes only `DETAIL0..DETAIL5`, 192 diagnostic bits.  The internal
ordered NACK log occupies diagnostic bits `[735:224]` and was not host-visible.
The available observations are therefore only the aggregate NACK count (8)
and first-error tuple
`CODE_0x02_STEP_0x2D_META_0x01_PHYS_0x01_REG_0xED_VALUE_0x00`.

No count deficit, effective NACK-event count, skipped transaction count, or
skipped table-entry count is inferred from those aggregate observations.

