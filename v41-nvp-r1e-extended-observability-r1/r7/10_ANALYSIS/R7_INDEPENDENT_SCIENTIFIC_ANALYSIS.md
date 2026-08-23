# R7 independent Arm-A/Arm-B scientific analysis

The frozen analyzer accepted both read-only T0/T1 captures, independently reproduced the existing analysis outputs byte-for-byte, and classified the pair as a complete valid paired sample. Both ordered logs overflowed, so all ordered-log conclusions below are restricted to the first eight records.

## Frozen inputs and model basis

```text
FROZEN_ANALYZER_SHA256=A19A290FF57B588AA02868F8E46AA9386005EFB0FBC38072C4373DB32F6AB967
R1E_SOURCE_COMMIT=f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
R1E_SOURCE_TREE=db8b5581a237e19905fd01c6d453793047bc3ba7
NVP_BRINGUP_GIT_BLOB=cfe33464d8e75c514462786593b278d90b4059a4
NVP_BRINGUP_SHA256=027D0D2258E5FF80A2675198EA9CD7085E2FD360B0EBCE9C423D631656DF9080
LIFECYCLE_MODEL_SHA256=76B23A59E0CB9AE05CCD8D0D52458107594FCEBA8483DC7AA3FCB5CF3AC41250
LIFECYCLE_SIMULATION_LOG_SHA256=61BA29DC661551BD25A77933A37C412F0BA0D047EC7CB8C387DAF101ADF55DDC
LIFECYCLE_SIMULATION_GATE=PASS_EXACT_I2C_CYCLE_COUNT_CROSSCHECK
EXPECTED_CNT_AT_INIT_DONE=132584734
CAPTURE_CONVENTION=FINISH_EDGE_PREINCREMENT
INDEPENDENT_ANALYZER_REPRODUCED_EXISTING_OUTPUTS=YES_BYTE_IDENTICAL
```

## Arm A lifecycle and instrumentation

```text
ARM_A_INSTRUMENTATION_VALID=YES
ARM_A_CNT_AT_INIT_DONE=132688568
ARM_A_EXPECTED_CNT_AT_INIT_DONE=132584734
ARM_A_SIGNED_COUNT_ERROR_CYCLES=+103834
ARM_A_SHORTENING_CYCLES=0
ARM_A_SHORTENING_TICKS_EXACT=0
ARM_A_SHORTENING_TICKS_NEAREST=0
ARM_A_SHORTENING_RESIDUAL_CYCLES=0
ARM_A_EXTENSION_CYCLES=103834
ARM_A_EXTENSION_TICKS_EXACT=83.00079936051159
ARM_A_EXTENSION_TICKS_NEAREST=83
ARM_A_EXTENSION_RESIDUAL_CYCLES=+1
```

The lifecycle result is an extension, not a shortening. Its difference from the all-ACK source-derived expectation is 83 complete 1,251-cycle state ticks plus one cycle. Therefore `CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG` is not applicable. The exact FSM shows that NACK state and physical-bank-valid outcomes can change later operation selection, but the aggregate count is 13 while only the first eight records are retained. The omitted five records prevent an exact, unique path reconstruction.

```text
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=NOT_APPLICABLE
CONTROL_FLOW_REPLAY=PARTIAL_FIRST_8_RECORDS_ONLY
CONTROL_FLOW_EXTENSION_TICK_ALIGNMENT=83_TICKS_PLUS_1_CYCLE
CONTROL_FLOW_EXTENSION_DECOMPOSITION=NON_UNIQUE_PARTIAL_FIRST_8_ONLY
ARM_A_CONTROL_FLOW_DECOMPOSITION=NON_UNIQUE_PARTIAL_FIRST_8_ONLY
CONTROL_FLOW_MODEL_OR_OBSERVABILITY_CONTRADICTION=NOT_ESTABLISHED_INCOMPLETE_LOG
```

## Ordered NACK evidence

| Arm | Aggregate NACK | Logged | Overflow | Phase distribution, first eight | Operation distribution, first eight | First error |
|---|---:|---:|---:|---|---|---|
| A, R1e 25 kHz | 13 | 8 | 1 | WRITE_ADDRESS_ACK:3; REGISTER_ADDRESS_ACK:3; DATA_ACK:2 | 41:2; 59:3; 86:2; 105:1 | op 41, REGISTER_ADDRESS_ACK, reg 0x44, data 0x00, phys/meta 0x00/0x00 |
| B, formal 50 kHz | 15 | 8 | 1 | WRITE_ADDRESS_ACK:1; REGISTER_ADDRESS_ACK:4; DATA_ACK:3 | 48:2; 146:2; 202:2; 207:2 | op 48, REGISTER_ADDRESS_ACK, reg 0x50, data 0x84, phys/meta 0x05/0x05 |

Both headers and both first-error-to-record comparisons pass. Both first-eight sets are dispersed across multiple operations and multiple phases, and each contains at least one write-address NACK plus non-address-phase NACKs. The detailed sixteen records are preserved in `R7_ORDERED_NACK_RECORDS.csv`.

Arm-A bank/register distribution, first eight:

```text
phys=0x00/meta=0x00/reg=0x44:2
phys=0x00/meta=0x00/reg=0xA0:1
phys=0x05/meta=0x05/reg=0x26:3
phys=0x09/meta=0x02/reg=0xFF:2
```

Arm-B bank/register distribution, first eight:

```text
phys=0x01/meta=0x01/reg=0xC8:2
phys=0x05/meta=0x05/reg=0x50:2
phys=0x09/meta=0x09/reg=0x56:2
phys=0x09/meta=0x09/reg=0x5B:2
```

## Arm A post-autoinit address probe

```text
ARM_A_PROBE_DONE=1
ARM_A_PROBE_ABORTED=0
ARM_A_PROBE_ACTIVE=0
ARM_A_PROBE_STATUS=0x00000339
ARM_A_PROBE_COUNT=10000
ARM_A_PROBE_ACK_COUNT=9971
ARM_A_PROBE_NACK_COUNT=29
ARM_A_PROBE_TIMEOUT_COUNT=0
ARM_A_PROBE_NACK_RATE=0.0029
ARM_A_PROBE_NACK_RATE_PERCENT=0.29
ARM_A_PROBE_NACK_RATE_PPM=2900
ARM_A_PROBE_WILSON95_LOWER=0.0020199966335610452
ARM_A_PROBE_WILSON95_UPPER=0.004161774546565626
ARM_A_PROBE_WILSON95_PERCENT=0.20199966335610452_TO_0.4161774546565626
ARM_A_PROBE_FIRST_NACK_INDEX=318
ARM_A_PROBE_LAST_NACK_INDEX=9749
ARM_A_PROBE_MAX_CONSECUTIVE_NACKS=1
```

This is a nonzero post-autoinit write-address NACK sample at 25 kHz. It does not measure register-byte, data-byte, read-address, 50-kHz probe, analog-voltage, or rise-time reliability. Only aggregate counters plus first/last/max-streak metadata are retained; a full per-probe sequence is unavailable.

## Functional and paired results

| Arm | INIT_DONE | INIT_ERROR | NACK | Timeout | VCLK advanced | SAV advanced | Frame advanced | Result |
|---|---:|---:|---:|---:|---|---|---|---|
| A, R1e 25 kHz | 1 | 1 | 13 | 0 | yes | no | no | `R1E_NVP_FAIL` |
| B, formal 50 kHz | 1 | 1 | 15 | 0 | yes | no | no | `FORMAL_NVP_FAIL` |

Arm B's complete 0x2000..0x20FF R1e page is zero, as required. The difference of 13 versus 15 aggregate autoinit NACKs is descriptive only: the branch-dependent autoinit paths and mixed ACK phases do not supply a common Bernoulli denominator.

```text
PAIRED_AB_RESULT=COMPLETE_VALID_PAIRED_SAMPLE
PAIRED_FUNCTIONAL_RESULT=BOTH_ARMS_NVP_FAIL_SINGLE_PAIR
STOCHASTIC_ADDRESS_OR_BUS_MARGIN=STRONGLY_SUPPORTED
AUTOINIT_OPERATION_OR_PHASE_CONTEXT=WEAKENED_AS_OPERATION_SPECIFIC_ONLY
OPERATION_SPECIFIC_ONLY=WEAKENED
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=UNRESOLVED
POST_INIT_ADDRESS_RELIABILITY=NOT_SUPPORTED_NONZERO_NACK_RATE
ROOT_CAUSE_SOLELY_PROVEN=NO
BOARD_VCCO_DROOP_PROVEN=NO
GROUND_BOUNCE_PROVEN=NO
ANALOG_MARGIN_DIRECTLY_MEASURED=NO
```

The strong-support classification follows the predeclared R1e matrix: the 10,000-probe address sample has a materially nonzero NACK rate, while the first-eight autoinit log is dispersed across both phases and operations. This weakens an operation-specific-only explanation but does not eliminate operation or phase context, especially because both ordered logs overflow.
