# R1c field-availability audit

## Result

Both R1c arms contain only aggregate NACK information and the first-error tuple. Neither arm contains a lifecycle completion counter or the full ordered internal NACK log.

```text
ARM_A_AVAILABILITY_CLASSIFICATION=AGGREGATE_ONLY_NOT_COMPUTABLE
ARM_B_AVAILABILITY_CLASSIFICATION=AGGREGATE_ONLY_NOT_COMPUTABLE

ARM_A_COUNTER_IMPLEMENTED_IN_SOURCE=NO
ARM_B_COUNTER_IMPLEMENTED_IN_SOURCE=NO

ARM_A_CNT_AT_INIT_DONE_AVAILABLE=NO
ARM_A_EXPECTED_CNT_AT_INIT_DONE_AVAILABLE=NO
ARM_B_CNT_AT_INIT_DONE_AVAILABLE=NO
ARM_B_EXPECTED_CNT_AT_INIT_DONE_AVAILABLE=NO

ARM_A_FULL_ORDERED_NACK_LOG_AVAILABLE=NO
ARM_B_FULL_ORDERED_NACK_LOG_AVAILABLE=NO
ARM_A_NACK_LOG_RECORD_COUNT=0_HOST_VISIBLE_RECORDS_FULL_LOG_ABSENT
ARM_B_NACK_LOG_RECORD_COUNT=0_HOST_VISIBLE_RECORDS_FULL_LOG_ABSENT
```

This is a fail-closed availability result. No absent value is inferred from NACK count, first error, timing, VCLK, another image, or an expected model.

## Layer 1 — exact source and register map

The exact formal commit `c89e88bcdf389614c884fb129e8b2d42a585bccb` and exact Arm-A commit `f007dc172d43d30b02729755e60382f8ce3dbff4` both lack:

- `rtl/v41/axi_clock_lifecycle_monitor.sv`
- `rtl/v41/axi_clock_measurement_regs.sv`
- any source match for `cnt_at_init_done`, `CNT_AT_INIT_DONE`, `MEASUREMENT_MAGIC`, or `314B4C43`

Their shared `rtl/v41/control_status_regs.sv` blob is `3582a21f235678e3310b8dc523818cfeace96d97`. Its local register select is limited to `host_req_addr[16:8] == 9'b0`; it has no R1 measurement-range select.

Their shared `rtl/pio/pio_bar_target.sv` blob is `1ab24dace7534d4c42d860e9234024440cb69f39`. With top-level `SLOT_COUNT=2`, address `0x2000` selects slot index 2, which satisfies `host_req_addr[15:12] >= SLOT_COUNT`; the exact source returns deterministic zero for that reserved/unused aligned DWORD. Thus the observed `0x00000000` at `0x2000` is a reserved-range response, not a zero-valued lifecycle counter.

Historical R1 provides the contrast:

- commit `0af44dee3bc091eaff805704dd5c687eeaa01bbd` adds `v41_axi_clock_lifecycle_monitor` (blob `c8c8145b12494cbdd54de7760f0558e6ab5fef11`);
- it adds `v41_axi_clock_measurement_regs` (blob `64f4a3df745bcde00f9facac3030637a32a19485`);
- measurement offset `0x00` returns magic `0x314B4C43`;
- measurement offsets `0x14` and `0x18` return `cnt_at_init_done[31:0]` and `[47:32]`;
- its modified control-register blob `9dea600316b80797e5d26470882208eabf3b861b` intercepts the `0x2000` range and returns the measurement data.

The formal-to-R1c diff contains only the top-level `I2C_HZ` change and the already-qualified provenance build-script change. The lifecycle-counter modules remain absent.

## Layer 2 — raw MMIO address inventories

The complete ordered address/value inventories are in:

- `MMIO_ADDRESS_INVENTORY_A.csv`
- `MMIO_ADDRESS_INVENTORY_B.csv`

Results:

```text
ARM_A_MMIO_READ_COUNT=40
ARM_B_MMIO_READ_COUNT=40

ARM_A_MEASUREMENT_RANGE_0X2000_READS=1_BASE_ONLY
ARM_B_MEASUREMENT_RANGE_0X2000_READS=1_BASE_ONLY

ARM_A_MMIO_COUNTER_FIELDS_READ=NO
ARM_B_MMIO_COUNTER_FIELDS_READ=NO
```

Each arm read `0x2000` once under the campaign label `IDENTITY_DIAGNOSTIC_MAGIC` and observed zero. Neither arm read the R1 `CNT_AT_INIT_DONE` offsets `0x2014` or `0x2018`, nor any other R1 measurement-window field. An unread register value is not inferred.

## Layer 3 — parsed-field inventories

Both parsed evidence files contain 77 fields. Their complete, byte-checked field lists are preserved in `PARSED_FIELD_INVENTORY_A.txt` and `PARSED_FIELD_INVENTORY_B.txt`.

Exact alias searches in each arm found no fields named:

```text
CNT_AT_INIT_DONE
EXPECTED_CNT_AT_INIT_DONE
INIT_DONE_COUNT_ERROR_CYCLES
FREERUN_COUNT
MEASUREMENT_MAGIC
MEASUREMENT_VERSION
```

The field named `DIAGNOSTIC_MAGIC=0x00000000` is the campaign's reserved-range identity probe; it is not R1 `MEASUREMENT_MAGIC=0x314B4C43`.

## Layer 4 — full ordered NACK log

The protected and unchanged `nvp6134c_autoinit.vhd` internally produces a 736-bit detail vector and assigns its 512-bit ordered NACK log to `diag_detail[735:224]`. Exact Arm-A/formal top-level source carries the full vector internally, but exports only `nvp_diag_axi[193:2]` into the 192-bit `nvp_detail` port of `v41_control_status_regs`.

The host map exposes six 32-bit detail words at `0xA0` through `0xB4`, covering only internal detail bits `[191:0]`. The ordered log at `[735:224]` is outside that window. Both parsed files independently record:

```text
HOST_VISIBLE_DIAGNOSTIC_DETAIL_WORDS=DETAIL0_THROUGH_DETAIL5
HOST_VISIBLE_DIAGNOSTIC_BITS=192
FULL_INTERNAL_NACK_LOG_BAR_VISIBLE=NO
```

Consequently, aggregate `NACK_COUNT` and `FIRST_ERROR` are available, but no
ordered per-NACK record set exists in the retained host evidence.  The
`0_HOST_VISIBLE_RECORDS_FULL_LOG_ABSENT` label is not an observation of an
empty internal log; the internal records were simply outside the exposed BAR
window.

## Per-arm terminal availability

### Arm A — 25 kHz

```text
RAW_NACK_COUNT=8
FIRST_ERROR=CODE_0x02_STEP_0x2D_META_0x01_PHYS_0x01_REG_0xED_VALUE_0x00
RESULT_MODE=AGGREGATE_ONLY_NOT_COMPUTABLE
CONTROL_FLOW_SHORTENING=NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
REASON=COUNTER_ABSENT_AND_FULL_ORDERED_NACK_LOG_ABSENT
```

### Arm B — exact formal 50 kHz

```text
RAW_NACK_COUNT=15
FIRST_ERROR=CODE_0x01_STEP_0x02_META_0x01_PHYS_0x01_REG_0xCA_VALUE_0x66
RESULT_MODE=AGGREGATE_ONLY_NOT_COMPUTABLE
CONTROL_FLOW_SHORTENING=NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE
REASON=COUNTER_ABSENT_AND_FULL_ORDERED_NACK_LOG_ABSENT
```

## Availability conclusion

```text
R1C_CONTROL_FLOW_SHORTENING=NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
R1C_EFFECTIVE_METRIC=NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
RAW_AVAILABLE_COMPARISON=ARM_A_8_NACKS_ARM_B_15_NACKS_BOTH_FUNCTIONAL_FAIL
```

The seven-count raw-NACK reduction cannot be converted into an effective control-flow event, skipped-transaction, or skipped-table-entry reduction from these existing records.
