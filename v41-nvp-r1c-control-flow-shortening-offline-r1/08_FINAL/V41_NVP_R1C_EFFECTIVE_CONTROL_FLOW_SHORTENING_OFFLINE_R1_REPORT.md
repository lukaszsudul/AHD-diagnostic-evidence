# V41 NVP R1/R1c effective control-flow shortening — offline forensic report

## Executive result

The existing R1c evidence cannot compute a control-flow-shortening metric for
either arm.  This is a definitive availability result, not a failed analysis.

Both images lack the historical R1 lifecycle counter.  Each retained R1c raw
log contains 40 MMIO reads, but the only read in the `0x2000` range is the
zero diagnostic-magic/reserved word at `0x2000`; neither log reads the R1
`CNT_AT_INIT_DONE` words at `0x2014/0x2018`.  Both arms expose only 192
diagnostic bits (`DETAIL0..5`), not the internal ordered NACK log.

Accordingly, Arm A's 8 NACKs and Arm B's 15 NACKs remain valid raw
observations, but the seven-count reduction is not an effective-operation
reduction.

## Input identity

The audit used only pinned local objects from:

- historical R1 evidence commit
  `cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c`;
- R1c evidence commit
  `2c86f792bb439279d2eca69d87c21125f99bf63f`;
- the R1c evidence ZIP, SHA-256
  `9B8AF29EEDFF10775F747F28BDF5B208A1C87AF82EF22A156129DF4ABE992D19`;
- exact source commits `0af44dee3bc091eaff805704dd5c687eeaa01bbd`
  (R1), `f007dc172d43d30b02729755e60382f8ce3dbff4`
  (R1c Arm A), and `c89e88bcdf389614c884fb129e8b2d42a585bccb`
  (formal Arm B).

The four R1c telemetry files were verified both as published files and as
entries inside the pinned ZIP.  Their identities and complete address/field
inventories are preserved in `01_INPUT_IDENTITY` and
`02_FIELD_AVAILABILITY`.

No current hardware state was read.

## Historical R1 method validation

Original R1 evidence independently records:

```text
EXPECTED_CNT_AT_INIT_DONE=113182679
ACTUAL_CNT_AT_INIT_DONE=113144494
SIGNED_COUNT_ERROR_CYCLES=-38185
CONTROL_FLOW_SHORTENING_CYCLES=38185
TICK_CYCLES=626
CONTROL_FLOW_SHORTENING_TICKS_EXACT=60.9984025559
CONTROL_FLOW_SHORTENING_TICKS_NEAREST=61
RESIDUAL_CYCLES=-1
```

The source proves that the monitor increments its free-running counter and
captures the old counter value on the first clock where `nvp_init_done` is
observed.  The expected model uses that same next-edge/pre-increment
convention.  The remaining one-cycle residual is retained as measured and is
consistent with a one-base-clock model/observer boundary difference; it is not
eliminated by mixing in the separately documented wrapper-high edge.  This
validates the method as
`PASS_61_TICKS_WITH_MINUS_1_CYCLE_EDGE_RESIDUAL` without claiming a unique
attribution for the residual cycle.

### The 61 ticks do not uniquely identify one omitted operation

The exact source-derived costs are 61 state ticks for a write and 83 for a
read.  A failed selector verify omits the following target write; a failed
selector write omits both its verify read and target write.  Cache validity
also controls whether the next table entry incurs a replacement selector
sequence.

At least two exact branch witnesses produce the same net 61-tick shortening:

1. At a one-entry bank run, a selector write succeeds and its verify read
   fails, omitting one target write before the next bank run.
2. In the multi-entry Bank-3 run (slots 2, 3 and 5, with delay slot 4), a
   selector verify failure at the first entry plus selector-write failures at
   the remaining entries omits three target writes while replacing two of
   them with equal-cost selector writes.  Net transaction deltas are still
   one fewer write and no fewer reads: 61 ticks.

The measured R1 first error (`0x80020100`) is a register-byte NACK at operation
1/table slot 0.  That transaction continues to completion and is path-neutral;
it does not select between the later witnesses.  The R1 raw files do not
contain the ordered NACK log.  Therefore the correct interpretation is
`R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS`: the net deficit is measured,
but effective-event, skipped-transaction, and skipped-entry counts are not
unique.

Here, one versus three skipped transactions means gross omitted target writes.
Both witnesses have the same net transaction delta: one fewer write and zero
fewer reads.

## Exact FSM model

The source-derived model enumerates the states entered on each tick.  It
reproduces the accepted all-ACK path of 31,043 tick actions (31,042
tick-to-tick intervals), 220 writes, 55 reads, 26 NOPs, one 1,003-tick delay
slot, and the inclusive 12,001-tick final settle.

It reproduces both preserved lifecycle expectations exactly:

| Profile | Divider | Tick cycles | Expected lifecycle count |
|---|---:|---:|---:|
| 50 kHz | 625 | 626 | 113182679 |
| 25 kHz | 1250 | 1251 | 132584734 |

The 500-ms reset and 1.5-s start counters remain base-clock counters and are
kept separate from tick-based protocol and settle costs.

## Per-arm availability

| Gate | Arm A, 25 kHz | Arm B, formal 50 kHz |
|---|---|---|
| Source lifecycle counter | No | No |
| MMIO lifecycle field read | No | No |
| Expected-count field | No | No |
| Full ordered NACK log | No | No |
| Raw NACK count | 8 | 15 |
| Result mode | Aggregate only | Aggregate only |
| Shortening result | Not computable | Not computable |

An aggregate count plus the first-error tuple cannot reconstruct later NACK
order or cache-dependent branch decisions.  No simulated expected value, R1
counter value, timestamp, VCLK value, or reserved zero was substituted for a
missing measurement.

## Scientific conclusion

```text
R1C_EFFECTIVE_METRIC=NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
RAW_AVAILABLE_COMPARISON=ARM_A_8_NACKS_ARM_B_15_NACKS_BOTH_FUNCTIONAL_FAIL
NEW_HARDWARE_OR_BUILD_REQUIRED_TO_MEASURE_COUNTER_DEFICIT=YES
NEW_HARDWARE_OR_BUILD_AUTHORIZED_BY_THIS_TASK=NO
```

The control-flow metric can reject path-neutral NACK noise when it is
measured.  It cannot do so for R1c because the required counter and ordered log
are absent.  A future counter-instrumented concept is documented separately;
it was not built or run.

## Operation accounting

All work was offline: existing evidence/source reads, task-local analysis,
reporting, sealing, and the authorized evidence publication only.  FPGA source
and formal repositories were not mutated.

## Required final block

```text
TASK=
    V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1

TASK_MODE=
    OFFLINE_EXISTING_EVIDENCE_FORENSIC

R1_EVIDENCE_COMMIT=
    cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c

R1C_EVIDENCE_COMMIT=
    2c86f792bb439279d2eca69d87c21125f99bf63f

R1C_EVIDENCE_ZIP_SHA256=
    9B8AF29EEDFF10775F747F28BDF5B208A1C87AF82EF22A156129DF4ABE992D19

R1_METHOD_VALIDATION=
    PASS_61_TICKS_WITH_MINUS_1_CYCLE_EDGE_RESIDUAL
R1_EXPECTED_CNT_AT_INIT_DONE=
    113182679
R1_ACTUAL_CNT_AT_INIT_DONE=
    113144494
R1_SIGNED_COUNT_ERROR_CYCLES=
    -38185
R1_SHORTENING_CYCLES=
    38185
R1_TICK_CYCLES=
    626
R1_SHORTENING_TICKS_EXACT=
    60.9984025559
R1_SHORTENING_TICKS_NEAREST=
    61
R1_RESIDUAL_CYCLES=
    -1
R1_OMITTED_TRANSACTION_INTERPRETATION=
    R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS

ARM_A_SOURCE_COUNTER_PRESENT=
    NO
ARM_A_MMIO_COUNTER_FIELDS_READ=
    NO
ARM_A_CNT_AT_INIT_DONE_AVAILABLE=
    NO
ARM_A_EXPECTED_CNT_AVAILABLE=
    NO
ARM_A_FULL_ORDERED_NACK_LOG_AVAILABLE=
    NO
ARM_A_RESULT_MODE=
    AGGREGATE_ONLY_NOT_COMPUTABLE
ARM_A_RAW_NACK_COUNT=
    8
ARM_A_SIGNED_COUNT_ERROR_CYCLES=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_SHORTENING_CYCLES=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_SHORTENING_TICKS_EXACT=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_SHORTENING_TICKS_NEAREST=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_RESIDUAL_CYCLES=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_CONTROL_FLOW_EFFECTIVE_NACK_EVENTS=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_SKIPPED_I2C_TRANSACTIONS=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_SKIPPED_TABLE_ENTRIES=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_A_CONTROL_FLOW_SHORTENING_RESULT=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE

ARM_B_SOURCE_COUNTER_PRESENT=
    NO
ARM_B_MMIO_COUNTER_FIELDS_READ=
    NO
ARM_B_CNT_AT_INIT_DONE_AVAILABLE=
    NO
ARM_B_EXPECTED_CNT_AVAILABLE=
    NO
ARM_B_FULL_ORDERED_NACK_LOG_AVAILABLE=
    NO
ARM_B_RESULT_MODE=
    AGGREGATE_ONLY_NOT_COMPUTABLE
ARM_B_RAW_NACK_COUNT=
    15
ARM_B_SIGNED_COUNT_ERROR_CYCLES=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_SHORTENING_CYCLES=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_SHORTENING_TICKS_EXACT=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_SHORTENING_TICKS_NEAREST=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_RESIDUAL_CYCLES=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_CONTROL_FLOW_EFFECTIVE_NACK_EVENTS=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_SKIPPED_I2C_TRANSACTIONS=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_SKIPPED_TABLE_ENTRIES=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
ARM_B_CONTROL_FLOW_SHORTENING_RESULT=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE

R1C_EFFECTIVE_METRIC_CLASSIFICATION=
    R1C_EFFECTIVE_METRIC_NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
RAW_NACK_REDUCTION=
    7
RAW_NACK_REDUCTION_INTERPRETED_AS_EFFECTIVE_OPERATION_REDUCTION=
    NO_UNLESS_PROVEN

NEW_BUILD_REQUIRED_FOR_COUNTER_MEASUREMENT=
    YES
NEW_HARDWARE_REQUIRED_FOR_COUNTER_MEASUREMENT=
    YES

FULL_BUILDS=
    0

FPGA_SOURCE_CHANGES=
    0

HARDWARE_ACTIONS=
    0

MMIO_OPERATIONS=
    0

DMA_TRANSFERS=
    0

FORMAL_REPOSITORY_MUTATIONS=
    0

EVIDENCE_PACKAGE_SHA256=
    NOT_SELF_EMBEDDABLE_SEE_EXTERNAL_SHA256_SIDECAR
EVIDENCE_REPOSITORY_COMMIT=
    SELF_COMMIT_RECORDED_IN_08_FINAL/EVIDENCE_PUBLICATION_RECEIPT.md

NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_EFFECTIVE_METRIC_AVAILABILITY
```
