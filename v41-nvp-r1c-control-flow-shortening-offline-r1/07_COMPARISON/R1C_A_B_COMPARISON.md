# R1c Arm-A / Arm-B comparison

## Availability result

Both R1c arms independently classify as
`AGGREGATE_ONLY_NOT_COMPUTABLE`:

| Evidence | Arm A, 25 kHz | Arm B, formal 50 kHz |
|---|---:|---:|
| Raw NACK count | 8 | 15 |
| Lifecycle counter implemented | No | No |
| Counter field read | No | No |
| Expected-count field available | No | No |
| Full ordered NACK log available | No | No |
| Host-visible diagnostic bits | 192 | 192 |

Both samples were infrastructure-valid functional failures in the R1c
campaign.  That result and the seven-count raw NACK reduction remain valid.
They do not identify how many NACKs changed control flow.

## Classification

```text
R1C_EFFECTIVE_METRIC_CLASSIFICATION=R1C_EFFECTIVE_METRIC_NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
R1C_EFFECTIVE_METRIC=NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
RAW_AVAILABLE_COMPARISON=ARM_A_8_NACKS_ARM_B_15_NACKS_BOTH_FUNCTIONAL_FAIL
NEW_HARDWARE_OR_BUILD_REQUIRED_TO_MEASURE_COUNTER_DEFICIT=YES
NEW_HARDWARE_OR_BUILD_AUTHORIZED_BY_THIS_TASK=NO
```

This is a successful fail-closed forensic result.  It identifies the exact
instrumentation gap without fabricating a counter value or ordered log.

