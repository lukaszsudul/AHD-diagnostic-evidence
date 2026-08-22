# Exact FSM cost-model validation

## Outcome

```text
ALL_ACK_50KHZ_MODEL_MATCH=PASS
ALL_ACK_25KHZ_MODEL_MATCH=PASS
R1_61_TICK_DECOMPOSITION_UNIQUE=NO
R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS=YES
```

## Immutable inputs

The analysis reads Git objects without checkout or mutation:

- source repository commits:
  - formal `c89e88bcdf389614c884fb129e8b2d42a585bccb`;
  - R1c `f007dc172d43d30b02729755e60382f8ce3dbff4`;
  - R1 `0af44dee3bc091eaff805704dd5c687eeaa01bbd`;
- evidence repository commits:
  - R1 `cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c`;
  - R1c context `2c86f792bb439279d2eca69d87c21125f99bf63f`.

The three protected NVP blobs have identical Git blob identities across the
formal, R1c and R1 commits:

| Source | Git blob | SHA-256 of exact blob bytes |
|---|---|---|
| `rtl/nvp/nvp6134c_autoinit.vhd` | `5dc0230cd569f03d68452055db6b10c5fcade751` | `74EFDC0147ADEA9A13265C061ECD3BA0B8042A2357B0A0E10673112F9986C17F` |
| `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `cfe33464d8e75c514462786593b278d90b4059a4` | `027D0D2258E5FF80A2675198EA9CD7085E2FD360B0EBCE9C423D631656DF9080` |
| `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | `7ddd60fc86da49cda1adcd7af7b772b337c95df6` | `36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156` |

## Derivation method

The staged standard-library Python script:

1. asserts exact source fragments for the divider, state branches, bank-cache
   updates, selector failure behavior, lifecycle-counter preincrement capture,
   and compact first-error mapping;
2. reads the preserved simulator dump of
   `c_v38ek_effective_init_op_for_slot` and requires exactly slots 0..213;
3. replays every operation through the exact verified-bank cache algorithm;
4. independently compares the result with the preserved 275-row all-ACK
   transaction stream and operation-count matrix;
5. recomputes both expected completion counts; and
6. replays two explicit R1 failure-path witnesses.

No new HDL simulation was run. The preserved operation dump is used as the
evaluated output of the exact package function; the state/path costs and
failure replay are freshly derived by this audit.

## All-ACK reproduction

The source-derived path contains:

```text
TABLE_SLOTS=214
TARGET_WRITE_SLOTS=187
NOP_SLOTS=26
DELAY_SLOTS=1

INIT_WRITE_TRANSACTIONS=212
INIT_READ_TRANSACTIONS=25
TOTAL_WRITE_TRANSACTIONS=220
TOTAL_READ_TRANSACTIONS=55
TOTAL_I2C_TRANSACTIONS=275

SUCCESS_PATH_TICK_ACTIONS=31043
FIRST_IDLE_TO_FINISH_INTERVALS=31042
```

At 50 kHz:

```text
DIVIDER=625
TICK_CYCLES=626
FIRST_IDLE_TICK_EDGE=93750387
DERIVED_FINISH_COUNTER=
    93750387 + 31042*626
    = 113182679
PRESERVED_EXPECTED_FINISH_COUNTER=113182679
ALL_ACK_50KHZ_MODEL_MATCH=PASS
```

At 25 kHz:

```text
DIVIDER=1250
TICK_CYCLES=1251
FIRST_IDLE_TICK_EDGE=93751192
DERIVED_FINISH_COUNTER=
    93751192 + 31042*1251
    = 132584734
PRESERVED_EXPECTED_FINISH_COUNTER=132584734
ALL_ACK_25KHZ_MODEL_MATCH=PASS
```

## Failure-path validation

Both explicit witnesses contain 19 raw NACK events and retain the measured
first error (slot-0 target register-byte NACK). Fresh replay gives:

| Witness | Actual init writes | Actual init reads | Skipped target slots | Net shortening |
|---|---:|---:|---|---:|
| one skipped target | 211 | 25 | 1 | 61 ticks |
| three skipped targets | 211 | 25 | 2, 3, 5 | 61 ticks |

This proves the counter deficit cannot uniquely determine either the number of
control-flow-effective NACK events or the number of skipped transactions/table
entries.  The skipped-transaction counts are gross omitted targets (one versus
three); the net transaction delta is identical in both witnesses: one fewer
write and zero fewer reads.

## Limits

The model is validated for exact all-ACK totals and for the branch-cost
non-uniqueness proof. It does not invent the absent ordered R1 NACK log and
does not select either witness as the historical path actually taken.

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
HARDWARE_ACTIONS=0
MMIO_OPERATIONS=0
DMA_TRANSFERS=0
```
