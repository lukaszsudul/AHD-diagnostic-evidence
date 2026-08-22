CODEX MASTER PROMPT

R1/R1c effective control-flow shortening analysis

CNT_AT_INIT_DONE deficit → omitted ticks / operations

EXISTING EVIDENCE ONLY — OFFLINE — NO BUILD — NO HARDWARE

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1

PRIMARY_QUESTION:
    Can the existing R1c evidence quantify, for Arm A 25 kHz and Arm B formal
    50 kHz, how much the NVP autoinit control flow was shortened by NACK-driven
    path changes?

DESIRED_METRICS:
    CNT_AT_INIT_DONE
    EXPECTED_CNT_AT_INIT_DONE
    SIGNED_COUNT_ERROR_CYCLES
    CONTROL_FLOW_SHORTENING_CYCLES
    CONTROL_FLOW_SHORTENING_TICKS
    CONTROL_FLOW_EFFECTIVE_NACK_EVENTS
    SKIPPED_I2C_TRANSACTIONS
    SKIPPED_TABLE_ENTRIES
    UNEXPLAINED_RESIDUAL_CYCLES

SCIENTIFIC_MOTIVATION:
    Raw NACK_COUNT counts every observed NACK.

    A counter-derived shortening metric counts only errors that actually changed
    the subsequent FSM path and shortened or lengthened completion.

TASK_MODE:
    OFFLINE_EXISTING_EVIDENCE_FORENSIC

HARDWARE_ACTIONS:
    0

FULL_BUILDS:
    0

FPGA_SOURCE_CHANGES:
    0

MMIO_OPERATIONS:
    0
```

===================================================================== 0. CRITICAL FAIL-CLOSED AVAILABILITY RULE

Do not assume R1c contains the R1 lifecycle counter.

Prove field availability separately for each image.

Known historical distinction to verify:

```text
R1_MEASUREMENT_SOURCE_COMMIT=
    0af44dee3bc091eaff805704dd5c687eeaa01bbd

R1_MEASUREMENT_IMAGE_ADDED=
    axi_clock_lifecycle_monitor
    axi_clock_measurement_regs
    measurement register window at 0x00002000

R1C_25KHZ_SOURCE_COMMIT=
    f007dc172d43d30b02729755e60382f8ce3dbff4

R1C_FORMAL_CONTROL=
    exact formal Phase-2 bit
```

Expected—but not to be accepted without proof:

```text
R1C_ARM_A_CNT_AT_INIT_DONE_PRESENT=
    LIKELY_NO

R1C_ARM_B_CNT_AT_INIT_DONE_PRESENT=
    LIKELY_NO

R1C_FULL_NACK_LOG_HOST_VISIBLE=
    LIKELY_NO
```

If an actual CNT_AT_INIT_DONE value is absent, do not infer it from:

```text
NACK_COUNT;
FIRST_ERROR;
program/reboot timestamps;
VCLK;
INIT_DONE;
approximate autoinit duration;
the R1 value;
the other arm;
or a simulated value.
```

If the full ordered NACK log is absent, do not reconstruct all control-flow
effects from aggregate NACK_COUNT plus only the first-error tuple.

Valid terminal outcome:

```text
R1C_CONTROL_FLOW_SHORTENING=
    NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
```

That is a successful fail-closed audit result, not a task failure.

=====================================================================

1. AUTHORITATIVE EVIDENCE IDENTITIES
=====================================================================

────────

1.1 Historical R1 counter measurement

Evidence repository:

```text
lukaszsudul/AHD-diagnostic-evidence
```

Evidence commit:

```text
cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c
```

R1 source:

```text
SOURCE_COMMIT=
    0af44dee3bc091eaff805704dd5c687eeaa01bbd

SOURCE_TREE=
    69154c1257c226c8cddacf4d8e1e9badbbd91c46

BIT_SHA256=
    4C169486BCEA09F0C76213C88CF675317C8F30C4DD887EDC4B8989D8E72EF5DB
```

R1 counter facts:

```text
MEASUREMENT_REGISTER_BASE=
    0x00002000

MEASUREMENT_MAGIC=
    0x314B4C43

MEASUREMENT_VERSION=
    1

COUNTER_WIDTH_BITS=
    48

EXPECTED_CNT_AT_INIT_DONE=
    113182679

ACTUAL_CNT_AT_INIT_DONE=
    113144494

I2C_HZ=
    50000

DIVIDER=
    625

TICK_CYCLES=
    626

RAW_NACK_COUNT=
    19
```

Historical R1 values must be re-read from original evidence, not copied blindly
from this prompt.

────────

1.2 R1c paired result

Evidence commit:

```text
2c86f792bb439279d2eca69d87c21125f99bf63f
```

Evidence path:

```text
v41-nvp-i2c-25khz-paired-ab-r1c/
```

Evidence ZIP SHA-256:

```text
9B8AF29EEDFF10775F747F28BDF5B208A1C87AF82EF22A156129DF4ABE992D19
```

Arm A:

```text
ROLE=
    ARM_A_25KHZ

SOURCE_COMMIT=
    f007dc172d43d30b02729755e60382f8ce3dbff4

SOURCE_TREE=
    b8f87966c8021396acb6341bd2d7d86a10fd7f13

BIT_SHA256=
    B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191

I2C_HZ=
    25000

DIVIDER=
    1250

TICK_CYCLES=
    1251

NACK_COUNT=
    8

FIRST_ERROR=
    CODE_0x02_STEP_0x2D_META_0x01_PHYS_0x01_REG_0xED_VALUE_0x00
```

Arm B:

```text
ROLE=
    ARM_B_FORMAL_50KHZ

BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

I2C_HZ=
    50000

DIVIDER=
    625

TICK_CYCLES=
    626

NACK_COUNT=
    15

FIRST_ERROR=
    CODE_0x01_STEP_0x02_META_0x01_PHYS_0x01_REG_0xCA_VALUE_0x66
```

R1c parsed telemetry paths:

```text
v41-nvp-i2c-25khz-paired-ab-r1c/
    03_ARM_A_25KHZ/ARM_A_TELEMETRY_RAW.log

v41-nvp-i2c-25khz-paired-ab-r1c/
    03_ARM_A_25KHZ/ARM_A_TELEMETRY_PARSED.txt

v41-nvp-i2c-25khz-paired-ab-r1c/
    04_ARM_B_FORMAL_50KHZ/ARM_B_TELEMETRY_RAW.log

v41-nvp-i2c-25khz-paired-ab-r1c/
    04_ARM_B_FORMAL_50KHZ/ARM_B_TELEMETRY_PARSED.txt
```

R1c report currently records:

```text
HOST_VISIBLE_DIAGNOSTIC_BITS=
    192

FULL_INTERNAL_NACK_LOG_BAR_VISIBLE=
    NO
```

Verify these exact fields in both arms.

===================================================================== 2. SOURCE IDENTITIES AND FSM INPUTS

Formal checkpoint:

```text
c89e88bcdf389614c884fb129e8b2d42a585bccb
```

Exact protected NVP sources for R1c:

```text
rtl/nvp/nvp6134c_autoinit.vhd
rtl/nvp/nvp6134c_i2c_bringup.vhd
rtl/nvp/nvp6134c_diagnostics_pkg.vhd
```

Exact source commit for Arm A:

```text
f007dc172d43d30b02729755e60382f8ce3dbff4
```

Expected source-diff fact to verify:

```text
formal checkpoint -> R1c source:

    functional RTL:
        only .I2C_HZ(50000) -> .I2C_HZ(25000)

    other tracked change:
        provenance build script

    lifecycle counter modules:
        absent
```

Exact R1 measurement source:

```text
0af44dee3bc091eaff805704dd5c687eeaa01bbd
```

Expected R1-only added files to verify:

```text
rtl/v41/axi_clock_lifecycle_monitor.sv
rtl/v41/axi_clock_measurement_regs.sv
```

Use exact source and exact operation table to derive:

```text
all-ACK expected path;
NACK-dependent branch graph;
transaction-state costs;
NOP/delay costs;
bank-select write path;
bank-select verify-read path;
target-write path;
read transaction path;
finish/capture-edge convention.
```

Do not hardcode “61 ticks equals one skipped transaction” until proven from the
exact FSM and the exact failure path.

===================================================================== 3. AUTHORIZATION AND ABSOLUTE LIMITS

Authorized:

```text
read and hash existing local/GitHub evidence;
extract the exact R1c ZIP;
read exact FPGA source and test/model files;
run task-local Python analysis scripts;
run existing source-level or HDL simulation only when no source modification,
synthesis, implementation, or bit generation occurs;
create Markdown, CSV, JSON and text reports;
create one small sealed analysis ZIP;
publish one normal evidence commit/push.
```

Not authorized:

```text
FPGA build;
synthesis;
implementation;
DCP modification;
bitstream generation;
FPGA source edit;
new source commit;
SSH;
JTAG;
FPGA programming;
Ubuntu reboot;
MMIO;
DMA;
physical action;
Phase 3;
XDMA development.
```

No result may depend on reading the currently active hardware.

The historical R1c images are no longer both simultaneously recoverable from
the running board.

===================================================================== 4. TASK ROOT

Create:

```text
C:\FPGA\V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1\
```

Required structure:

```text
00_SCOPE\
01_INPUT_IDENTITY\
02_FIELD_AVAILABILITY\
03_R1_VALIDATION\
04_FSM_COST_MODEL\
05_R1C_ARM_A\
06_R1C_ARM_B\
07_COMPARISON\
08_FINAL\
scripts\
raw\
```

Create immediately:

```text
OPERATION_LEDGER.md
TOOL_COMMAND_LEDGER.md
```

Initial ledger:

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
HARDWARE_ACTIONS=0
MMIO_OPERATIONS=0
DMA_TRANSFERS=0
FORMAL_REPOSITORY_MUTATIONS=0
```

Save this prompt verbatim under:

```text
00_SCOPE\OWNER_PROMPT_VERBATIM.md
```

and record SHA-256.

===================================================================== 5. P0 — INPUT IDENTITY

Verify:

```text
R1 evidence commit;
R1c evidence commit;
R1c evidence ZIP SHA-256;
all four R1c telemetry file hashes;
R1 source commit/tree;
R1c source commit/tree;
diagnostic and formal bit identities;
protected NVP source blob identities.
```

Create:

```text
01_INPUT_IDENTITY\INPUT_IDENTITY.md
01_INPUT_IDENTITY\INPUT_SHA256.txt
01_INPUT_IDENTITY\SOURCE_COMMIT_DIFF_MATRIX.csv
```

Any identity mismatch:

```text
BLOCKED_INPUT_IDENTITY
```

No analytical conclusion.

===================================================================== 6. P1 — FIELD-AVAILABILITY GATE

Audit each arm independently using four layers.

────────

6.1 Source/register-map proof

Search exact source for:

```text
axi_clock_lifecycle_monitor
axi_clock_measurement_regs
CNT_AT_INIT_DONE
cnt_at_init_done
MEASUREMENT_MAGIC
0x314B4C43
measurement range 0x2000
```

Record:

```text
ARM_A_COUNTER_IMPLEMENTED_IN_SOURCE=
ARM_B_COUNTER_IMPLEMENTED_IN_SOURCE=
```

For Arm B, verify the exact formal image’s R1 measurement range is zero/reserved.

────────

6.2 Raw MMIO address inventory

Parse both raw telemetry logs.

Create a complete ordered list of all MMIO read addresses and values.

Record:

```text
ARM_A_MMIO_READ_COUNT=
ARM_B_MMIO_READ_COUNT=

ARM_A_MEASUREMENT_RANGE_0X2000_READS=
ARM_B_MEASUREMENT_RANGE_0X2000_READS=
```

Do not infer an unread register value.

────────

6.3 Parsed-field inventory

List every parsed field from both arms.

Search exact aliases:

```text
CNT_AT_INIT_DONE
EXPECTED_CNT_AT_INIT_DONE
INIT_DONE_COUNT_ERROR_CYCLES
FREERUN_COUNT
MEASUREMENT_MAGIC
MEASUREMENT_VERSION
```

Record:

```text
ARM_A_CNT_AT_INIT_DONE_AVAILABLE=
ARM_A_EXPECTED_CNT_AT_INIT_DONE_AVAILABLE=

ARM_B_CNT_AT_INIT_DONE_AVAILABLE=
ARM_B_EXPECTED_CNT_AT_INIT_DONE_AVAILABLE=
```

────────

6.4 Full NACK-log availability

Audit whether each R1c arm contains the ordered per-NACK records from
diag_detail[735:224].

Record:

```text
ARM_A_FULL_ORDERED_NACK_LOG_AVAILABLE=
ARM_B_FULL_ORDERED_NACK_LOG_AVAILABLE=

ARM_A_NACK_LOG_RECORD_COUNT=
ARM_B_NACK_LOG_RECORD_COUNT=
```

Aggregate NACK count and first error do not count as a full ordered log.

────────

6.5 Availability classification

Per arm, use exactly one:

```text
MEASURED_COUNTER_AVAILABLE

FULL_NACK_LOG_MODEL_AVAILABLE

AGGREGATE_ONLY_NOT_COMPUTABLE
```

Create:

```text
02_FIELD_AVAILABILITY\FIELD_AVAILABILITY_MATRIX.csv
02_FIELD_AVAILABILITY\MMIO_ADDRESS_INVENTORY_A.csv
02_FIELD_AVAILABILITY\MMIO_ADDRESS_INVENTORY_B.csv
02_FIELD_AVAILABILITY\PARSED_FIELD_INVENTORY_A.txt
02_FIELD_AVAILABILITY\PARSED_FIELD_INVENTORY_B.txt
02_FIELD_AVAILABILITY\FIELD_AVAILABILITY_REPORT.md
```

Do not stop the overall task if fields are absent.

Continue to validate the method on historical R1 and produce a definitive R1c
availability conclusion.

===================================================================== 7. P2 — HISTORICAL R1 VALIDATION VECTOR

Re-read from original R1 evidence:

```text
EXPECTED_CNT_AT_INIT_DONE
ACTUAL_CNT_AT_INIT_DONE
DIVIDER
I2C_HZ
counter capture-edge definition
first-error tuple
NACK_COUNT
```

Use definitions:

```text
SIGNED_COUNT_ERROR_CYCLES =
    ACTUAL_CNT_AT_INIT_DONE - EXPECTED_CNT_AT_INIT_DONE

CONTROL_FLOW_SHORTENING_CYCLES =
    EXPECTED_CNT_AT_INIT_DONE - ACTUAL_CNT_AT_INIT_DONE

TICK_CYCLES =
    DIVIDER + 1

CONTROL_FLOW_SHORTENING_TICKS_EXACT =
    CONTROL_FLOW_SHORTENING_CYCLES / TICK_CYCLES

CONTROL_FLOW_SHORTENING_TICKS_NEAREST =
    round(CONTROL_FLOW_SHORTENING_TICKS_EXACT)

RESIDUAL_CYCLES =
    CONTROL_FLOW_SHORTENING_CYCLES
    - CONTROL_FLOW_SHORTENING_TICKS_NEAREST * TICK_CYCLES
```

Expected validation values to reproduce:

```text
SIGNED_COUNT_ERROR_CYCLES=
    -38185

CONTROL_FLOW_SHORTENING_CYCLES=
    38185

TICK_CYCLES=
    626

CONTROL_FLOW_SHORTENING_TICKS_EXACT=
    approximately 60.9984025559

CONTROL_FLOW_SHORTENING_TICKS_NEAREST=
    61

RESIDUAL_CYCLES=
    -1
```

The -1 residual may be accepted as an observation-edge convention only after
the exact counter-capture edge and expected-model edge are reconciled.

Required classification:

```text
R1_SHORTENING_METHOD_VALIDATION=
    PASS_61_TICKS_WITH_MINUS_1_CYCLE_EDGE_RESIDUAL
```

or an exact contrary result with evidence.

────────

7.1 Prove or reject the one-omitted-transaction interpretation

Trace the exact historical first-error path through:

```text
ACK state;
cur_error;
STORE_RESULT;
NEXT_OP;
init_action;
slot_idx;
bank-select write;
bank verify;
target write.
```

Calculate the exact tick cost of every transaction/path omitted by that branch.

Use exactly one:

```text
R1_61_TICKS_UNIQUELY_EQUALS_ONE_OMITTED_TRANSACTION

R1_61_TICKS_EQUALS_OTHER_UNIQUE_PATH_CHANGE

R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS

R1_61_TICKS_NOT_EXPLAINED_BY_EXACT_FSM_MODEL
```

Do not promote the user’s proposed interpretation without this proof.

Create:

```text
03_R1_VALIDATION\R1_COUNTER_RECALCULATION.csv
03_R1_VALIDATION\R1_FAILURE_PATH_TRACE.md
03_R1_VALIDATION\R1_METHOD_VALIDATION.md
```

===================================================================== 8. P3 — EXACT FSM COST MODEL

Create a source-derived model, not a hand-entered timing table.

The model must enumerate:

```text
each FSM state entered per tick;
write transaction tick cost;
read transaction tick cost;
bank-select write tick cost;
bank-verify read tick cost;
target-write tick cost;
preinit paths;
NOP path;
table-delay path;
final settle path;
post-table readback paths;
restore path;
FINISH and counter-capture edge.
```

Support both:

```text
Arm A:
    DIVIDER=1250
    TICK_CYCLES=1251

Arm B:
    DIVIDER=625
    TICK_CYCLES=626
```

Separate:

```text
state ticks;
FPGA clock cycles;
fixed wall-clock counters:
    POR
    500-ms reset
    1.5-s start;
tick-based delays.
```

The model must reproduce the all-ACK expected completion count already
preserved in prior numerical/simulation evidence for 50 and 25 kHz.

Required:

```text
ALL_ACK_50KHZ_MODEL_MATCH=
    PASS

ALL_ACK_25KHZ_MODEL_MATCH=
    PASS
```

If not:

```text
BLOCKED_FSM_COST_MODEL_NOT_VALIDATED
```

No skipped-operation conclusions.

Create:

```text
04_FSM_COST_MODEL\FSM_STATE_COSTS.csv
04_FSM_COST_MODEL\TRANSACTION_COSTS.csv
04_FSM_COST_MODEL\ALL_ACK_EXPECTED_COUNTS.csv
04_FSM_COST_MODEL\FAILURE_PATH_RULES.csv
04_FSM_COST_MODEL\MODEL_VALIDATION.md
scripts\derive_control_flow_shortening.py
```

===================================================================== 9. P4 — ARM-A 25-kHz ANALYSIS

Use one of the following modes.

────────

9.1 Measured-counter mode

Allowed only when:

```text
ARM_A_CNT_AT_INIT_DONE_AVAILABLE=YES
ARM_A_EXPECTED_CNT_AT_INIT_DONE_AVAILABLE=YES
```

Compute:

```text
ARM_A_SIGNED_COUNT_ERROR_CYCLES
ARM_A_CONTROL_FLOW_SHORTENING_CYCLES
ARM_A_CONTROL_FLOW_SHORTENING_TICKS_EXACT
ARM_A_CONTROL_FLOW_SHORTENING_TICKS_NEAREST
ARM_A_RESIDUAL_CYCLES
```

Then use the exact FSM model and ordered NACK log, if available, to derive:

```text
ARM_A_CONTROL_FLOW_EFFECTIVE_NACK_EVENTS
ARM_A_SKIPPED_I2C_TRANSACTIONS
ARM_A_SKIPPED_TABLE_ENTRIES
ARM_A_MODEL_EXPLAINED_SHORTENING_TICKS
ARM_A_UNEXPLAINED_RESIDUAL_TICKS
```

If the counter exists but the full NACK log does not, report the total measured
shortening but do not assign it uniquely to individual NACK events unless the
tick decomposition is mathematically unique.

────────

9.2 Full-NACK-log model-only mode

Allowed only when:

```text
counter absent;
full ordered NACK log present.
```

Replay the exact log against the exact FSM.

Report:

```text
ARM_A_MODEL_DERIVED_CONTROL_FLOW_SHORTENING_TICKS
ARM_A_MODEL_DERIVED_SKIPPED_TRANSACTIONS
ARM_A_MODEL_DERIVED_EFFECTIVE_NACK_EVENTS
```

Label every result:

```text
MODEL_DERIVED_NOT_COUNTER_MEASURED
```

────────

9.3 Aggregate-only mode

If only:

```text
NACK_COUNT=8
FIRST_ERROR
```

is available:

```text
ARM_A_CONTROL_FLOW_SHORTENING=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE

ARM_A_REASON=
    COUNTER_ABSENT_AND_FULL_ORDERED_NACK_LOG_ABSENT
```

Do not estimate skipped operations from 8.

Create:

```text
05_R1C_ARM_A\ARM_A_SHORTENING_RESULT.md
05_R1C_ARM_A\ARM_A_SHORTENING_CALCULATION.csv
05_R1C_ARM_A\ARM_A_FAILURE_PATH_REPLAY.csv
```

===================================================================== 10. P5 — ARM-B FORMAL 50-kHz ANALYSIS

Apply the identical rules and script to Arm B.

Do not substitute historical R1’s counter value for Arm B.

Do not treat the formal image’s zero/reserved R1 measurement range as a zero
cycle count.

Measured mode requires actual non-reserved fields captured during Arm B.

Model-only mode requires the full ordered Arm-B NACK log.

If only:

```text
NACK_COUNT=15
FIRST_ERROR
```

is available:

```text
ARM_B_CONTROL_FLOW_SHORTENING=
    NOT_COMPUTABLE_FROM_EXISTING_R1C_EVIDENCE

ARM_B_REASON=
    COUNTER_ABSENT_AND_FULL_ORDERED_NACK_LOG_ABSENT
```

Create:

```text
06_R1C_ARM_B\ARM_B_SHORTENING_RESULT.md
06_R1C_ARM_B\ARM_B_SHORTENING_CALCULATION.csv
06_R1C_ARM_B\ARM_B_FAILURE_PATH_REPLAY.csv
```

===================================================================== 11. P6 — COMPARISON AND NOISE CLAIM

Create:

```text
07_COMPARISON\R1_R1C_SHORTENING_MATRIX.csv
07_COMPARISON\RAW_NACK_VS_EFFECTIVE_PATH_METRIC.md
07_COMPARISON\R1C_A_B_COMPARISON.md
```

Required matrix columns:

```text
SAMPLE
I2C_HZ
DIVIDER
TICK_CYCLES
RAW_NACK_COUNT
CNT_AT_INIT_DONE_AVAILABLE
EXPECTED_CNT_AVAILABLE
FULL_NACK_LOG_AVAILABLE
SIGNED_COUNT_ERROR_CYCLES
SHORTENING_CYCLES
SHORTENING_TICKS_EXACT
SHORTENING_TICKS_NEAREST
RESIDUAL_CYCLES
CONTROL_FLOW_EFFECTIVE_NACK_EVENTS
SKIPPED_I2C_TRANSACTIONS
SKIPPED_TABLE_ENTRIES
RESULT_MODE
CONFIDENCE
```

Scientific wording:

```text
The control-flow shortening metric is less sensitive than raw NACK count to
NACKs that leave the subsequent state path unchanged.

It is not automatically less noisy when:
    the completion counter is absent;
    multiple failure paths share the same tick cost;
    or only aggregate NACK data is available.
```

Allowed comparison classifications:

```text
R1C_EFFECTIVE_METRIC_MEASURED_FOR_BOTH_ARMS

R1C_EFFECTIVE_METRIC_MEASURED_FOR_ONE_ARM_ONLY

R1C_EFFECTIVE_METRIC_MODEL_DERIVED_FOR_BOTH_ARMS

R1C_EFFECTIVE_METRIC_PARTIALLY_MODEL_DERIVED

R1C_EFFECTIVE_METRIC_NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE
```

Do not convert the seven-count raw NACK reduction into an effective-operation
reduction without the required evidence.

===================================================================== 12. EXPECTED AVAILABILITY FINDING TO VERIFY

The task must verify—not merely copy—the following likely conclusion:

```text
R1c Arm A:
    source is formal Phase 2 plus only I2C_HZ change;
    R1 lifecycle monitor is absent;
    0x2000 counter fields were not read;
    only 192 diagnostic bits were host-visible;
    full internal NACK log was not BAR-visible.

R1c Arm B:
    exact formal Phase 2;
    R1 measurement range is zero/reserved;
    no counter fields;
    only 192 diagnostic bits were host-visible;
    full internal NACK log was not BAR-visible.
```

If verified, the correct scientific result is:

```text
R1C_EFFECTIVE_METRIC=
    NOT_COMPUTABLE_FROM_EXISTING_EVIDENCE

RAW_AVAILABLE_COMPARISON=
    ARM_A_8_NACKS
    ARM_B_15_NACKS
    BOTH_FUNCTIONAL_FAIL

NEW_HARDWARE_OR_BUILD_REQUIRED_TO_MEASURE_COUNTER_DEFICIT=
    YES

NEW_HARDWARE_OR_BUILD_AUTHORIZED_BY_THIS_TASK=
    NO
```

Do not call this a failed analysis.

It precisely identifies the instrumentation gap.

===================================================================== 13. OPTIONAL MEASUREMENT-GAP NOTE

If the R1c metric is not computable, prepare a short design note only.

Do not build it.

The clean future A/B concept is:

```text
Arm A:
    R1 lifecycle-counter instrumentation
    + I2C_HZ=25000

Arm B:
    exact existing R1 lifecycle-counter 50-kHz bit
    SHA256=
        4C169486BCEA09F0C76213C88CF675317C8F30C4DD887EDC4B8989D8E72EF5DB
```

The future Arm-A source should be derived from:

```text
R1_SOURCE_COMMIT=
    0af44dee3bc091eaff805704dd5c687eeaa01bbd
```

with only:

```text
I2C_HZ 50000 -> 25000
```

as the functional change.

This note is informational only.

Required status:

```text
FUTURE_COUNTER_INSTRUMENTED_25KHZ_BUILD=
    NOT_RUN

FUTURE_HARDWARE=
    NOT_RUN
```

===================================================================== 14. EVIDENCE OUTPUT AND PUBLICATION

Create final report:

```text
08_FINAL\
    V41_NVP_R1C_EFFECTIVE_CONTROL_FLOW_SHORTENING_OFFLINE_R1_REPORT.md
```

Create sealed package:

```text
V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1_EVIDENCE.zip
V41_NVP_R1C_CONTROL_FLOW_SHORTENING_OFFLINE_R1_EVIDENCE_SHA256.txt
SHA256_MANIFEST.txt
```

Include:

```text
verbatim prompt;
input identities;
source diff evidence;
field-availability inventories;
raw MMIO-address inventories;
R1 validation calculation;
exact FSM cost model;
Arm-A and Arm-B results;
comparison matrix;
measurement-gap note if required;
scripts;
operation ledger;
security scan;
final report.
```

Publish to:

```text
REPOSITORY=
    lukaszsudul/AHD-diagnostic-evidence

BRANCH=
    main

PATH=
    v41-nvp-r1c-control-flow-shortening-offline-r1/
```

One normal commit/push.

No force-push.

No tag.

No Release.

If publication fails:

```text
retain and verify the sealed local package;
record exact blocker;
do not use an unsafe alternate path.
```

===================================================================== 15. REQUIRED FINAL REPORT BLOCK

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
R1_EXPECTED_CNT_AT_INIT_DONE=
R1_ACTUAL_CNT_AT_INIT_DONE=
R1_SIGNED_COUNT_ERROR_CYCLES=
R1_SHORTENING_CYCLES=
R1_TICK_CYCLES=
R1_SHORTENING_TICKS_EXACT=
R1_SHORTENING_TICKS_NEAREST=
R1_RESIDUAL_CYCLES=
R1_OMITTED_TRANSACTION_INTERPRETATION=

ARM_A_SOURCE_COUNTER_PRESENT=
ARM_A_MMIO_COUNTER_FIELDS_READ=
ARM_A_CNT_AT_INIT_DONE_AVAILABLE=
ARM_A_EXPECTED_CNT_AVAILABLE=
ARM_A_FULL_ORDERED_NACK_LOG_AVAILABLE=
ARM_A_RESULT_MODE=
ARM_A_RAW_NACK_COUNT=
    8
ARM_A_SIGNED_COUNT_ERROR_CYCLES=
ARM_A_SHORTENING_CYCLES=
ARM_A_SHORTENING_TICKS_EXACT=
ARM_A_SHORTENING_TICKS_NEAREST=
ARM_A_RESIDUAL_CYCLES=
ARM_A_CONTROL_FLOW_EFFECTIVE_NACK_EVENTS=
ARM_A_SKIPPED_I2C_TRANSACTIONS=
ARM_A_SKIPPED_TABLE_ENTRIES=
ARM_A_CONTROL_FLOW_SHORTENING_RESULT=

ARM_B_SOURCE_COUNTER_PRESENT=
ARM_B_MMIO_COUNTER_FIELDS_READ=
ARM_B_CNT_AT_INIT_DONE_AVAILABLE=
ARM_B_EXPECTED_CNT_AVAILABLE=
ARM_B_FULL_ORDERED_NACK_LOG_AVAILABLE=
ARM_B_RESULT_MODE=
ARM_B_RAW_NACK_COUNT=
    15
ARM_B_SIGNED_COUNT_ERROR_CYCLES=
ARM_B_SHORTENING_CYCLES=
ARM_B_SHORTENING_TICKS_EXACT=
ARM_B_SHORTENING_TICKS_NEAREST=
ARM_B_RESIDUAL_CYCLES=
ARM_B_CONTROL_FLOW_EFFECTIVE_NACK_EVENTS=
ARM_B_SKIPPED_I2C_TRANSACTIONS=
ARM_B_SKIPPED_TABLE_ENTRIES=
ARM_B_CONTROL_FLOW_SHORTENING_RESULT=

R1C_EFFECTIVE_METRIC_CLASSIFICATION=
RAW_NACK_REDUCTION=
    7
RAW_NACK_REDUCTION_INTERPRETED_AS_EFFECTIVE_OPERATION_REDUCTION=
    NO_UNLESS_PROVEN

NEW_BUILD_REQUIRED_FOR_COUNTER_MEASUREMENT=
NEW_HARDWARE_REQUIRED_FOR_COUNTER_MEASUREMENT=

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
EVIDENCE_REPOSITORY_COMMIT=

NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_EFFECTIVE_METRIC_AVAILABILITY
```

===================================================================== 16. HARD STOPS

Hard stop analytical inference if:

```text
input hash differs;
source commit differs;
counter field is inferred rather than read;
expected count is scaled approximately rather than derived exactly;
full NACK log is reconstructed from aggregate count;
FSM cost model does not reproduce all-ACK evidence;
a tick deficit has multiple decompositions but one is selected without proof.
```

Do not:

```text
read current hardware;
run a new FPGA program;
build a new bit;
edit source;
invent missing NACK records;
interpret formal zero/reserved measurement registers as counter value zero.
```

===================================================================== 17. BEGIN

```text
save and hash this prompt
    ->
verify R1 and R1c evidence identities
    ->
inventory exact R1c source/register-map instrumentation
    ->
inventory all R1c MMIO addresses and parsed fields
    ->
prove full-NACK-log availability or absence
    ->
recalculate and validate historical R1 61-tick result
    ->
derive exact FSM transaction/failure-path costs
    ->
compute Arm-A result only if evidence permits
    ->
compute Arm-B result only if evidence permits
    ->
compare raw NACK and effective control-flow metrics
    ->
produce measurement-gap note if fields are absent
    ->
seal and publish offline evidence
    ->
HARD STOP.
```

No build.
No hardware.
No source changes.
No fabricated counter values.
