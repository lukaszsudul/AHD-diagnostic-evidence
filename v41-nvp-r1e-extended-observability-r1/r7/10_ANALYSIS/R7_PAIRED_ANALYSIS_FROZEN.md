# R4 telemetry analysis

This output is derived only from the two saved read-only T0/T1 reader captures.

## Arm A lifecycle

- Actual `CNT_AT_INIT_DONE`: 132688568
- Expected count: 132584734
- Signed error: 103834 cycles
- Shortening: 0 cycles (0 ticks; nearest 0, residual 0 cycles)
- Extension: 103834 cycles

## Ordered NACK evidence

| Arm | Aggregate | Logged | Overflow | Completeness | Phase distribution | Operation distribution |
|---|---:|---:|---:|---|---|---|
| A | 13 | 8 | 1 | FIRST_8_RECORDS_ONLY | DATA_ACK:2, REGISTER_ADDRESS_ACK:3, WRITE_ADDRESS_ACK:3 | 41:2, 59:3, 86:2, 105:1 |
| B | 15 | 8 | 1 | FIRST_8_RECORDS_ONLY | DATA_ACK:3, REGISTER_ADDRESS_ACK:4, WRITE_ADDRESS_ACK:1 | 48:2, 146:2, 202:2, 207:2 |

## Arm A address probe

- N/ACK/NACK/timeout: 10000 / 9971 / 29 / 0
- NACK rate: 0.0029 (2900 ppm)
- Wilson 95% interval: [0.00201999663356, 0.00416177454657]
- First/last/max consecutive NACK: 318 / 9749 / 1

## Functional and combined classifications

- Arm A NVP result: `R1E_NVP_FAIL`
- Arm B NVP result: `FORMAL_NVP_FAIL`
- `STOCHASTIC_ADDRESS_OR_BUS_MARGIN=STRONGLY_SUPPORTED`
- `AUTOINIT_OPERATION_OR_PHASE_CONTEXT=WEAKENED_AS_OPERATION_SPECIFIC_ONLY`
- `POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=UNRESOLVED`
- `POST_INIT_ADDRESS_RELIABILITY=NOT_SUPPORTED_NONZERO_NACK_RATE`
- `PAIRED_AB_RESULT=COMPLETE_VALID_PAIRED_SAMPLE`
- `CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=NOT_APPLICABLE`
- `ROOT_CAUSE_SOLELY_PROVEN=NO`
- `BOARD_VCCO_DROOP_PROVEN=NO`
- `GROUND_BOUNCE_PROVEN=NO`
- `ANALOG_MARGIN_DIRECTLY_MEASURED=NO`

## Required limitations

The ordered log holds at most eight records; overflow exposes only the first eight. The active, non-register-writing probe measures only post-autoinit 25-kHz write-address ACK behavior. It does not measure register/data/read-address phases or analog voltage/rise time. The added implementation may affect placement/routing.
