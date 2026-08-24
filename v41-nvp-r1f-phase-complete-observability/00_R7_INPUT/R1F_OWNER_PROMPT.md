CODEX MASTER PROMPT

v41 NVP R1f — phase-complete observability and replicated paired A/B

64-entry failed-transaction log, 16-bit diagnostic transaction index,

explicit bank-state semantics, and interleaved address/register/data probes

One clean build, three exact same-bit paired A/B repetitions

FULL OWNER PRE-AUTHORIZATION — NO INTERACTIVE CONFIRMATIONS

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY_AND_REPLICATED_PAIRED_AB

EXPERIMENT_NAME:
    R1f

NAMING_BASIS:
    R1f is the next letter after the completed R1e experiment.

PRIMARY_PURPOSE:
    Resolve the three concrete observability gaps left by R1e/R7:

        1. distinguish per-phase autoinit error rates from the post-autoinit
           write-address-only probe rate using exact phase-opportunity
           denominators;

        2. replace the capacity-8, first-events-only view with a capacity-64
           failed-transaction log that preserves all historically observed
           failure episodes and records unambiguous transaction/bank semantics;

        3. remove the diagnostic operation-index uniqueness limit by adding an
           independent 16-bit transaction serial and a separate 16-bit table
           slot index.

    Add a round-robin post-autoinit probe that separately measures:

        WRITE_ADDRESS_ACK;
        REGISTER_ADDRESS_ACK;
        DATA_ACK;

    at 25 kHz with 10,000 valid target-phase opportunities per phase.

    Run three A/B repetitions with the exact same R1f bit:

        A1/B1;
        A2/B2;
        A3/B3.

    Each A arm is the R1f 25-kHz image.
    Each B arm is the exact formal Phase-2 50-kHz control.

SCIENTIFIC_QUESTIONS:

    Q1:
        Is the post-autoinit Bernoulli-like error process reproduced in
        register-address and data ACK phases, or only in write-address ACK?

    Q2:
        Are opportunity-normalized autoinit phase error rates significantly
        higher than the matching post-autoinit probe rates?

    Q3:
        Are autoinit failures concentrated by transaction kind, phase, table
        slot, or bank context after the bank fields are made semantically
        unambiguous?

    Q4:
        Is the Arm-A versus Arm-B directional difference repeatable across
        three interleaved pairs?

BUILD_COUNT:
    1

PAIRED_REPETITIONS:
    3

FINAL_ACTIVE_IMAGE:
    exact formal Phase 2

PHASE3_RESUME:
    NO

XDMA_DEVELOPMENT:
    NO
```

===================================================================== -1. STANDING OWNER AUTHORIZATION — NO INTERACTIVE CONFIRMATIONS

```text
OWNER_STANDING_AUTHORIZATION=
    GRANTED

OWNER_AUTHORIZATION_EFFECTIVE=
    IMMEDIATELY_FOR_THE_ENTIRE_TASK

OWNER_INTERACTIVE_APPROVAL_REQUIRED=
    NO

CODEX_MUST_REQUEST_ADDITIONAL_CONFIRMATION=
    NO

EXPECTED_OWNER_INTERACTIONS=
    0
```

The owner grants prior approval for every action explicitly authorized by this
prompt.

Do not pause to request approval for:

```text
isolated worktree/branch creation;
the exact diagnostic-only source changes defined here;
one source commit;
one clean build;
one normal diagnostic-branch push;
all simulations and report-only audits;
conditional exact formal bootstrap;
three Arm-A programs;
three full Arm-B programs;
all authorized warm reboots and exact driver loads;
all bounded read-only MMIO/telemetry;
evidence sealing;
one normal evidence commit/push;
public remote verification.
```

A passing gate means continue automatically.

A failed or blocked gate means:

```text
preserve all available evidence;
create the one authoritative final report;
publish safely available evidence;
hard-stop without asking whether to continue.
```

This authorization does not permit any operation outside the explicit scope or
above the numerical limits.

===================================================================== 0. AUTHORITATIVE R1e / R7 INPUT

R7 public evidence:

```text
R7_EVIDENCE_REPOSITORY=
    lukaszsudul/AHD-diagnostic-evidence

R7_EVIDENCE_COMMIT=
    16beec37a266c421da5838fbb986301d072cbb50

R7_EVIDENCE_PACKAGE_SHA256=
    A1864DA7EC52AEE852169656808510C42D98FDCE27816D82449946B610DD2A56
```

Exact frozen R1e implementation:

```text
R1E_SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1E_SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1E_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

R1E_BIT_SHA256=
    0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9
```

R7 valid Arm-A observation:

```text
R7_ARM_A_IMAGE=
    exact R1e 25 kHz

R7_ARM_A_NVP_RESULT=
    R1E_NVP_FAIL

R7_ARM_A_AUTOINIT_NACK_COUNT=
    13

R7_ARM_A_TIMEOUT_COUNT=
    0

R7_ARM_A_CNT_AT_INIT_DONE=
    132688568

R7_ARM_A_EXPECTED_CNT_AT_INIT_DONE=
    132584734

R7_ARM_A_EXTENSION_CYCLES=
    103834

R7_ARM_A_EXTENSION_TICKS=
    83_plus_1_cycle

R7_ARM_A_ORDERED_LOG_STORED=
    8

R7_ARM_A_ORDERED_LOG_OVERFLOW=
    1

R7_ARM_A_POSTINIT_WRITE_ADDRESS_PROBE=
    29_NACKS_OF_10000

R7_ARM_A_PROBE_RATE=
    0.0029

R7_ARM_A_PROBE_SCOPE=
    POST_AUTOINIT_WRITE_ADDRESS_ACK_AT_25KHZ_ONLY
```

R7 valid Arm-B observation:

```text
R7_ARM_B_IMAGE=
    exact formal Phase 2 50 kHz

R7_ARM_B_NVP_RESULT=
    FORMAL_NVP_FAIL

R7_ARM_B_AUTOINIT_NACK_COUNT=
    15

R7_ARM_B_TIMEOUT_COUNT=
    0

R7_ARM_B_ORDERED_LOG_STORED=
    8

R7_ARM_B_ORDERED_LOG_OVERFLOW=
    1
```

R7 paired result:

```text
R7_PAIRED_RESULT=
    COMPLETE_VALID_PAIRED_SAMPLE

R7_POSTINIT_WRITE_ADDRESS_STOCHASTICITY=
    STRONGLY_SUPPORTED

R7_SINGLE_STATIONARY_PROCESS_FOR_PROBE_AND_AUTOINIT=
    NOT_SUPPORTED_BY_CURRENT_NUMBERS

R7_AUTOINIT_CONTEXT_DEPENDENCE=
    SUPPORTED_NOT_ISOLATED

R7_BANK_ATTRIBUTION=
    CONDITIONAL_PENDING_EXPLICIT_SEMANTICS

R7_ROOT_CAUSE_SOLELY_PROVEN=
    NO
```

R7 terminal state:

```text
FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
    A40A0C07 / 0000400B / 00031002

FINAL_DIAGNOSTIC_MAGIC=
    0

FINAL_PINNED_DRIVER_LOADED=
    YES

FINAL_DONE=
    1
```

R1f preserves R7 as immutable historical evidence.

=====================================================================

1. REQUIRED CORRECTIONS TO THE R7 INTERPRETATION
=====================================================================

The final R1f report must preserve these predeclared distinctions.

────────

1.1 Probe memorylessness

R7’s 29 NACK positions are compatible with a low-rate memoryless process
within the exact probe scope.

Required wording:

```text
POSTINIT_WRITE_ADDRESS_PROCESS=
    COMPATIBLE_WITH_STATIONARY_MEMORYLESS_BERNOULLI_PROCESS

MEMORYLESSNESS_PROVEN=
    NO

PROBE_SCOPE=
    POST_AUTOINIT_WRITE_ADDRESS_ACK_AT_25KHZ_ONLY
```

The absence of adjacent NACKs is not suspicious.

R1f must evaluate stationarity separately for all three probe phases.

────────

1.2 Autoinit versus probe

Do not compare aggregate autoinit NACK count with probe count without an exact
phase-opportunity denominator.

R1f must measure:

```text
AUTOINIT_WRITE_ADDRESS_OPPORTUNITIES
AUTOINIT_REGISTER_ADDRESS_OPPORTUNITIES
AUTOINIT_DATA_OPPORTUNITIES
AUTOINIT_READ_ADDRESS_OPPORTUNITIES

and matching per-phase NACK counts.
```

Required historical classification:

```text
EXACT_R7_AUTOINIT_TO_PROBE_RATE_RATIO=
    NOT_IDENTIFIABLE_FROM_R7

R1F_PURPOSE=
    MEASURE_EXACT_OPPORTUNITY_NORMALIZED_RATIOS
```

────────

1.3 Current phase distribution

The first 16 retained R7 records contain phase counts:

```text
WRITE_ADDRESS_ACK=
    4

REGISTER_ADDRESS_ACK=
    7

DATA_ACK=
    5
```

A raw equal-cell chi-square is not a phase-rate test unless the phase
opportunity counts are equal.

R1f must use the measured denominators.

────────

1.4 Bank semantics

Do not assume that the R7 operation-86 record proves a broken bank tracker.

The current 64-bit record overloads fields:

```text
write_data may be invalid or a placeholder for a read transaction;
physical bank can intentionally describe the last proven bank before a bank
verify completes;
metadata bank can describe the requested target bank.
```

R1f must distinguish these meanings explicitly.

Required entry classification:

```text
R7_OPERATION_86_BANK_TRACKER_DEFECT=
    NOT_PROVEN_FROM_OVERLOADED_RECORD_FIELDS

R1F_BANK_SEMANTICS_AUDIT_REQUIRED=
    YES
```

────────

1.5 Current operation index

The exact inherited source uses an 8-bit-bounded diagnostic operation index.

Before changing it, audit whether the exact R1e source:

```text
wraps;
saturates;
or aliases through another conversion.
```

Regardless of the exact old behavior:

```text
LEGACY_OPERATION_INDEX_UNIQUE_ABOVE_255=
    NO
```

R1f must add a new independent 16-bit transaction serial without changing
legacy control flow.

===================================================================== 2. EXACT SOURCE AND FORMAL IDENTITIES

Formal repository:

```text
GITHUB_REPOSITORY=
    lukaszsudul/FPGA_AHD
```

R1f base must be the exact local R1e source:

```text
BASE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

BASE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

BASE_AUTOINIT_I2C_HZ=
    25000

BASE_EXPECTED_CNT_AT_INIT_DONE=
    132584734
```

The base commit may be local-only.

Do not substitute:

```text
formal Phase 2;
R1c;
a reconstructed approximation;
or a new build from the R1e DCP.
```

If the exact commit/tree cannot be checked out:

```text
BLOCKED_EXACT_LOCAL_R1E_SOURCE_NOT_AVAILABLE
```

No source mutation.

Exact formal Phase-2 control:

```text
FORMAL_BRANCH=
    v41/xdma-v40.1.0-base

FORMAL_CHECKPOINT_COMMIT=
    c89e88bcdf389614c884fb129e8b2d42a585bccb

FORMAL_CHECKPOINT_TREE=
    417820c69c134161fcafae0947dc5976919814d1

FORMAL_TAG=
    v41.0.0-phase2-p2

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
```

Formal runtime identity:

```text
BLOCK_ID=
    0xA40A0C07

PROTOCOL=
    0x0000400B

CAPABILITIES=
    0x00031002

DIAGNOSTIC_MAGIC=
    0x00000000
```

Selected JTAG:

```text
JTAG_CANONICAL_ID=
    Xilinx/80802026a98b01

JTAG_FULL_PATH_EXPECTED_SUFFIX=
    /Xilinx/80802026a98b01

PART=
    xc7a35t

IDCODE=
    0362D093

JTAG_FREQUENCY_POLICY=
    RECORD_DEFAULT_NO_CHANGE
```

Ubuntu:

```text
DUT=
    vcdeagent1@10.132.1.111

REQUIRED_KERNEL=
    7.0.0-29-generic
```

Pinned module and loader:

```text
MODULE_PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko

MODULE_SHA256=
    1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A

LOADER_PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh

LOADER_SHA256=
    7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
```

Reuse the accepted R7:

```text
mode-aware programming observer;
selected-target selector;
Python BAR parser;
credential/host-key procedure.
```

===================================================================== 3. AUTHORIZATION AND LIMITS

Authorized offline:

```text
one isolated R1f branch/worktree;
one R1f source commit;
diagnostic-only changes defined by this prompt;
one clean build;
all bounded simulations and formal assertions;
one normal diagnostic-branch push;
evidence packaging/publication.
```

Authorized hardware:

```text
optional exact formal bootstrap only if the fresh formal start state is not
proven;

three Arm-A R1f samples;

three full exact formal Arm-B control samples;

one warm reboot and at most one exact pinned-driver load after every valid
program;

read-only telemetry only.
```

Maximum:

```text
CLEAN_BUILDS=
    1

CONDITIONAL_FORMAL_BOOTSTRAP_PROGRAMS<=
    1

ARM_A_PROGRAMS=
    3

ARM_B_PROGRAMS=
    3

FPGA_PROGRAM_INVOCATIONS_MAX=
    7

WARM_REBOOTS_MAX=
    7

POST_REBOOT_DRIVER_LOADS_MAX=
    7

PROGRAM_RETRIES=
    0
```

Not authorized:

```text
second build;
source correction after the build;
different probe target after build;
different probe count after build;
different pair count after hardware begins;
cold start;
power cycle;
physical action;
JTAG/cable change;
JTAG-frequency change;
PCIe reset/remove/rescan;
AXI-Lite write during hardware;
NVP register write from host;
DMA;
Phase 3;
XDMA development;
tag;
Release.
```

===================================================================== 4. TASK ROOT AND GIT POLICY

Create:

```text
C:\FPGA\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\
```

Required structure:

```text
00_R7_INPUT\
01_SOURCE_IDENTITY\
02_CURRENT_SEMANTICS_AUDIT\
03_SAFE_PROBE_TARGET\
04_R1F_RECORD_FORMAT\
05_R1F_REGISTER_MAP\
06_SIMULATION\
07_BUILD\
08_HOST_TOOLS\
09_HARDWARE_PRECHECK\
10_BOOTSTRAP\
11_PAIR_1\
12_PAIR_2\
13_PAIR_3\
14_ANALYSIS\
15_FINAL\
```

Create immediately:

```text
OPERATION_LEDGER.md
TIME_LEDGER.md
```

Save this prompt verbatim and record its SHA-256.

Branch:

```text
diag/v41-nvp-r1f-phase-complete-observability
```

Base:

```text
f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
```

Do not mutate the R1e worktree.

Allowed tracked modifications:

```text
diagnostic-only event outputs/counters in the existing autoinit/bringup source;

one new R1f failed-transaction logger;

one new R1f tri-phase post-init probe;

one new R1f read-only register-page implementation;

minimal top-level integration/open-drain arbitration;

host readers/decoders;

focused tests;

one provenance-correct build script.
```

Forbidden tracked modifications:

```text
NVP operation table contents;
autoinit I2C_HZ;
DIVIDER formula;
POR;
R17 timing;
start timing;
functional FSM state transitions;
functional branch decisions;
SDA/SCL synchronizer/filter logic;
watchdog threshold;
pins;
IOSTANDARD;
DRIVE;
SLEW;
XDMA XCI;
capture/record logic;
formal register offsets/semantics.
```

Changes inside previously protected NVP files are allowed only when proven
diagnostic-only.

Required classification:

```text
NVP_FUNCTIONAL_SOURCE_CHANGE=
    NO

NVP_DIAGNOSTIC_SOURCE_CHANGE=
    YES_R1F_ONLY
```

===================================================================== 5. P0 — CURRENT SEMANTICS AUDIT

Before editing source, audit the exact R1e source.

Create:

```text
02_CURRENT_SEMANTICS_AUDIT\
    LEGACY_OPERATION_INDEX_AUDIT.md

02_CURRENT_SEMANTICS_AUDIT\
    LEGACY_NACK_RECORD_SEMANTICS.md

02_CURRENT_SEMANTICS_AUDIT\
    R7_OPERATION_86_REPLAY.md
```

Prove:

```text
exact legacy op-index type/range;
increment behavior;
wrap/saturation behavior;
all functional fanout from that field;

exact moment each current log field is sampled;

meaning of:
    physical bank;
    metadata bank;
    write_data;
    read_data;
    physical-bank-valid;

transaction kind for the R7 operation-86 records.
```

Do not classify operation 86 as tracker corruption from the old record alone.

Set:

```text
R7_OPERATION_86_CLASSIFICATION=
    LEGAL_TRANSITIONAL_CONTEXT
    or
    TRUE_TRACKER_CONTRADICTION
    or
    INCONCLUSIVE_OVERLOADED_FIELDS
```

This audit is historical context.

R1f instrumentation must make the same ambiguity impossible.

===================================================================== 6. P1 — SAFE REGISTER/DATA PROBE TARGET GATE

The write-address probe is electrically active but sends no register/data byte.

The register-address probe sends a register pointer and STOP.

The data probe performs a real register write.

Therefore the data target must be proven safe before build.

Search only exact local authoritative material:

```text
NVP6134C datasheet if present;
exact source comments;
exact init table;
accepted historical evidence;
existing readback lists.
```

Select and freeze:

```text
R1F_PROBE_BANK=
R1F_PROBE_REGISTER=
R1F_PROBE_DATA=
```

The target must satisfy all:

```text
normal volatile read/write configuration register;

not bank-select 0xFF;

not reset;
not power control;
not clock/PLL;
not video-output enable/mux;
not clean/pulse/self-clearing;
not W1C/W1S;
not interrupt clear;
not calibration trigger;
not undocumented/reserved;

the exact intended post-autoinit value is known;

writing the same value repeatedly is documented or source-proven idempotent;

pre-probe readback can verify the expected value;

post-probe readback can verify no value change;

original bank can be restored and verified.
```

A register merely present in the init table is not sufficient proof.

Create:

```text
03_SAFE_PROBE_TARGET\
    SAFE_IDEMPOTENT_DATA_PROBE_TARGET.md

03_SAFE_PROBE_TARGET\
    REJECTED_CANDIDATES.csv

03_SAFE_PROBE_TARGET\
    PROBE_SETUP_AND_RESTORE_CONTRACT.md
```

Required:

```text
SAFE_DATA_PROBE_TARGET=
    PASS

DATA_PROBE_SIDE_EFFECT_CLASS=
    IDEMPOTENT_SAME_VALUE_WRITE_WITH_PRE_POST_READBACK
```

If no target meets every criterion:

```text
BLOCKED_NO_PROVEN_SAFE_DATA_ACK_PROBE_TARGET
```

Hard stop before source commit.

Do not ask the owner to select a weaker target.

===================================================================== 7. P2 — PASSIVE AUTOINIT PHASE COUNTERS

Add independent diagnostic counters.

They must have zero fanout to functional control.

At every actual ACK sampling state count one opportunity before evaluating the
sample.

Required 32-bit saturating counters:

```text
AUTOINIT_WADDR_ACK_OPPORTUNITIES
AUTOINIT_WADDR_NACKS

AUTOINIT_REGADDR_ACK_OPPORTUNITIES
AUTOINIT_REGADDR_NACKS

AUTOINIT_DATA_ACK_OPPORTUNITIES
AUTOINIT_DATA_NACKS

AUTOINIT_RADDR_ACK_OPPORTUNITIES
AUTOINIT_RADDR_NACKS

AUTOINIT_TRANSACTION_STARTS
AUTOINIT_TRANSACTION_COMPLETIONS
AUTOINIT_FAILED_TRANSACTIONS
AUTOINIT_TIMEOUT_TRANSACTIONS
```

Required invariants:

```text
NACKS<=OPPORTUNITIES for every phase;

sum phase NACK counters equals aggregate NACK_COUNT;

a write transaction opportunity mask is:
    WADDR + REGADDR + DATA as actually reached;

a read transaction opportunity mask is:
    WADDR + REGADDR + RADDR as actually reached;

no phase is counted when an earlier failure prevents that ACK sample;

no counter saturation in any simulation or hardware sample.
```

The legacy aggregate counters and first-error semantics remain unchanged.

===================================================================== 8. P3 — 64-ENTRY FAILED-TRANSACTION LOG

Do not merely widen the old ambiguous 64-bit per-NACK record.

Preserve the legacy eight-record log unchanged for compatibility.

Add a separate R1f failed-transaction log.

```text
R1F_FAILED_TXN_LOG_CAPACITY=
    64

R1F_FAILED_TXN_RECORD_WIDTH_BITS=
    192

R1F_FAILED_TXN_RECORD_WORDS=
    6

R1F_RECORD_VERSION=
    1
```

One record is finalized per failed or timed-out transaction.

Multiple NACK phases in one transaction are represented by a phase bitmap,
not by pretending they are independent transaction failures.

Required fields:

```text
transaction_index_16;
table_slot_index_16, or 0xFFFF when not applicable;
high-level autoinit phase;
transaction kind;
phase-opportunity bitmap;
phase-NACK bitmap;
NACK count within transaction;
timeout flag;

register address;
write data;
write-data-valid;
read data;
read-data-valid;

requested/metadata bank;
physical bank before transaction;
physical-bank-before-valid;
selector value sent;
selector-value-valid;
bank-verify expected;
bank-verify-expected-valid;
bank-verify observed;
bank-verify-observed-valid;
bank-verify result;

physical bank after transaction;
physical-bank-after-valid;
bank-update reason;

legacy 8-bit operation field;
FSM state/context;
record valid;
transaction-completed.
```

The new 16-bit transaction serial:

```text
increments once per actual I2C transaction start;

does not replace or drive the existing functional index;

does not saturate or alias within any modeled sequence;

has zero fanout into functional control.
```

The separate table-slot index records the exact table slot.

Required log counters:

```text
R1F_FAILED_TXN_TOTAL_COUNT
R1F_FAILED_TXN_STORED_COUNT
R1F_FAILED_TXN_OVERFLOW
R1F_FIRST_FAILED_TXN_INDEX
R1F_LAST_FAILED_TXN_INDEX
```

Required behavior:

```text
entries 0..63 are chronological;

no circular overwrite;

entry remains immutable after finalization;

overflow sets only after the 65th failed transaction;

total count continues after overflow;

all unused entries read zero.
```

────────

8.1 Legacy reconciliation

For every simulation:

```text
the legacy first-eight per-NACK records remain byte-identical to the R1e
reference;

the R1f transaction records explain every legacy event by matching:
    transaction;
    phase;
    register;
    valid legacy fields.
```

Required:

```text
LEGACY_FIRST8_RECONCILIATION=
    PASS
```

===================================================================== 9. P4 — BANK-TRACKER INVARIANTS

Add passive diagnostic invariant counters:

```text
BANK_TRACKER_INVARIANT_CHECK_COUNT
BANK_TRACKER_INVARIANT_ERROR_COUNT
FIRST_BANK_TRACKER_INVARIANT_ERROR
```

At minimum check:

```text
target write may execute only when physical bank is valid and equals requested
bank, except exact source-authorized direct-write modes;

successful verified bank selection ends with:
    physical bank valid;
    physical bank after = requested bank;

failed selector write or failed verify invalidates the physical-bank cache
according to exact source semantics;

read transactions mark write_data invalid;

write transactions mark read_data invalid unless a later verify read exists;

selector value, requested bank and verify expected agree when they are defined;

no diagnostic field is interpreted when its valid bit is zero.
```

Required hardware-valid sample:

```text
BANK_TRACKER_INVARIANT_ERROR_COUNT=
    0
```

If nonzero:

```text
BANK_TRACKER_COHERENCE=
    CONTRADICTION_MEASURED
```

Do not auto-patch.

===================================================================== 10. P5 — INTERLEAVED TRI-PHASE POST-AUTOINIT PROBE

Create a new automatic probe engine.

```text
PROBE_PHASES=
    WRITE_ADDRESS_ACK
    REGISTER_ADDRESS_ACK
    DATA_ACK

TARGET_VALID_OPPORTUNITIES_PER_PHASE=
    10000

BLOCK_COUNT_PER_PHASE=
    10

TARGET_VALID_OPPORTUNITIES_PER_BLOCK=
    1000

MAX_TRANSACTION_ATTEMPTS_PER_PHASE=
    12000

PROBE_SCHEDULER=
    ROUND_ROBIN_INTERLEAVED

PROBE_I2C_HZ=
    25000

PROBE_DEVICE_ADDRESS_WRITE=
    0x60
```

The scheduler repeatedly runs:

```text
one address-only transaction if WADDR target not complete;

one register-pointer transaction if REGADDR target not complete;

one idempotent-data-write transaction if DATA target not complete;
```

It continues until every target phase has exactly 10,000 actual opportunities.

A target opportunity is counted only when that phase is physically reached.

Record prerequisite-phase outcomes separately.

────────

10.1 Address-only probe

Transaction:

```text
START;
0x60;
write-address ACK sample;
STOP;
bus free.
```

No register/data byte.

────────

10.2 Register-address probe

Transaction:

```text
START;
0x60;
write-address ACK;
safe register pointer;
register-address ACK;
STOP;
bus free.
```

The register pointer side effect is documented.

No data byte.

────────

10.3 Data probe

Transaction:

```text
START;
0x60;
write-address ACK;
safe register;
register-address ACK;
frozen idempotent data;
data ACK;
STOP;
bus free.
```

The data phase is attempted only when both prerequisite phases ACK.

────────

10.4 Setup and restoration

Before phase probes:

```text
wait for original autoinit terminal init_done;
require init_busy=0;
require original master releasing SCL/SDA;
require stable bus idle;
read and preserve current bank;
select and verify the safe probe bank;
read and verify the safe target register/value.
```

After phase probes:

```text
read target register and require unchanged value;
restore original bank;
read back bank-select and require exact restoration;
release both lines.
```

Any setup/readback/restore failure:

```text
PROBE_ABORTED=
    1

PROBE_RESULT=
    INVALID_ACTIVE_PROBE_SETUP_OR_RESTORE
```

No probe-rate inference.

────────

10.5 Probe counters

For each phase store:

```text
transaction_attempts;
prerequisite-address opportunities/ACK/NACK;
prerequisite-register opportunities/ACK/NACK when applicable;
target-phase opportunities;
target-phase ACKs;
target-phase NACKs;
timeouts;
first target-phase NACK index;
last target-phase NACK index;
maximum consecutive target-phase NACKs;
adjacent NACK-pair count;
binary-sequence run count;
ten block NACK counts.
```

Also preserve a bounded target-phase NACK-index log:

```text
PROBE_NACK_INDEX_LOG_CAPACITY_PER_PHASE=
    512

PROBE_NACK_INDEX_WIDTH=
    16
```

If a phase exceeds 512 stored indices:

```text
index-log overflow is explicit;
aggregate counters remain valid;
exact distribution analysis is limited.
```

Required valid probe result:

```text
PROBE_DONE=1
PROBE_ABORTED=0

WADDR_TARGET_OPPORTUNITIES=10000
REGADDR_TARGET_OPPORTUNITIES=10000
DATA_TARGET_OPPORTUNITIES=10000

for every phase:
    ACKS+NACKS=OPPORTUNITIES

PROBE_TIMEOUT_COUNT_TOTAL=0

safe target pre/post readback equal;
original bank restored and verified.
```

────────

10.6 Probe classification

Required wording:

```text
TRI_PHASE_PROBE_CLASS=
    ACTIVE_POST_AUTOINIT_DIAGNOSTIC

WRITE_ADDRESS_PROBE=
    NON_REGISTER_WRITING

REGISTER_ADDRESS_PROBE=
    REGISTER_POINTER_SETTING_NO_DATA_WRITE

DATA_PROBE=
    PROVEN_IDEMPOTENT_SAME_VALUE_REGISTER_WRITE
```

Do not call the complete tri-phase probe passive.

===================================================================== 11. P6 — REGISTER MAP

Preserve:

```text
all existing formal offsets;
the existing R1e page 0x2000..0x2094;
the existing legacy log 0x10098..0x100D8.
```

Add a versioned R1f read-only map in the existing formally reserved slot-2
address space.

Recommended frozen layout:

```text
0x20A0..0x21FF:
    R1f header, capabilities, autoinit phase counters, log/probe status,
    safe-target identity and invariant counters;

0x2200..0x23FF:
    per-phase probe block statistics and aggregate counters;

0x2400..0x29FF:
    64 failed-transaction records × 24 bytes;

0x2A00..0x2DFF:
    write-address probe NACK indices;

0x2E00..0x31FF:
    register-address probe NACK indices;

0x3200..0x35FF:
    data probe NACK indices.
```

Before implementation, prove there is no address collision.

Required:

```text
R1F_MAGIC
R1F_VERSION
R1F_CAPABILITIES
R1F_RECORD_VERSION
R1F_RECORD_WIDTH
R1F_LOG_CAPACITY
R1F_PROBE_PHASE_MASK
R1F_SAFE_TARGET_BANK_REG_DATA
```

All fields are read-only.

Writes retain the prior reserved/invalid-write behavior and have no effect.

Exact formal Phase 2 must return deterministic zero over the complete R1f
range.

===================================================================== 12. P7 — PRE-INIT FUNCTIONAL EQUIVALENCE

Run paired reference/candidate simulation:

```text
reference:
    exact R1e source f3d9e5...

candidate:
    R1f source.
```

Feed identical inputs.

From configuration through the original terminal init_done event require
cycle-by-cycle equality of:

```text
nvp_rst;
power enables;
original autoinit SCL/SDA release requests;
effective physical SCL/SDA release requests;
init_busy;
init_done;
init_error;
legacy diag_detail[735:0];
aggregate NACK and timeout counts;
first error;
legacy eight-record log;
transaction bytes;
transaction order;
functional state transitions;
bank-cache functional state.
```

R1f passive counters/log outputs are excluded from equality.

Required:

```text
PRE_INIT_DONE_CYCLE_EQUIVALENCE=
    PASS

AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=
    YES

AUTOINIT_FUNCTIONAL_STATE_SEQUENCE_IDENTICAL=
    YES

R1F_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=
    0
```

Any difference:

```text
BLOCKED_R1F_CHANGES_AUTOINIT_BEHAVIOR
```

No build.

===================================================================== 13. P8 — SIMULATION MATRIX

Required simulations:

```text
all-ACK autoinit;

one NACK in each phase;

multiple phase NACKs in one transaction;

13 and 15 NACK patterns from R7;

36-event historical pattern;

64 failed transactions exactly;

65 failed transactions to prove overflow;

operation/transaction index beyond 255, including at least index 300;

bank-select write success/failure;

bank-verify read success/NACK/value mismatch;

an operation-86-like transitional bank context;

every transaction kind;

safe probe setup/readback/restore;

tri-phase probe with:
    all ACK;
    29/10000 address NACK pattern;
    independent Bernoulli patterns;
    clustered patterns;
    prerequisite-phase NACKs;
    target-phase NACKs;
    timeout abort;
    NACK-index-log overflow;

formal zero-page behavior;

host parser version mismatch.
```

Required:

```text
PHASE_OPPORTUNITY_COUNTERS_MATCH_SCOREBOARD=
    PASS

FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD=
    PASS

BANK_BEFORE_AFTER_SEMANTICS=
    PASS

TRANSACTION_INDEX_16_UNIQUE=
    PASS

LEGACY_FIRST8_RECONCILIATION=
    PASS

TRI_PHASE_PROBE_SCOREBOARD=
    PASS

SAFE_TARGET_RESTORATION=
    PASS
```

===================================================================== 14. P9 — SOURCE COMMIT AND CLEAN BUILD

After all pre-build gates pass, create one source commit.

Suggested bit:

```text
ahd_capture_v41_i2c_25khz_r1f_phase_complete_observability.bit
```

Use:

```text
Vivado 2025.2 build 6299465;
part xc7a35tcsg325-2;
top ahd_capture_top_xdma;
exact unchanged XDMA XCI;
provenance-correct build flow.
```

Runtime provenance must reconstruct the exact R1f source commit.

Use:

```text
BUILD_FLAGS=
    0x00000002
```

Do not invent a production flag meaning.

Required build gates:

```text
FULL_BUILDS=1
SYNTHESIS=PASS
PLACE=PASS
ROUTE=PASS
ROUTE_ERRORS=0

WNS>=0
WHS>0
VDO_WNS>0
VDO_WHS>0

DRC_ERRORS=0
DRC_CRITICAL_WARNINGS=0

REQP_1839_SEMANTIC_COUNT=4
REQP_1839_RAW_TEXT_COUNT_NOT_USED_AS_GATE=YES

CDC_CRITICAL=0
CDC_UNKNOWN=0

AUTOINIT_I2C_HZ=25000
EXPECTED_CNT_AT_INIT_DONE=132584734

NVP_TABLE_UNCHANGED=YES
FUNCTIONAL_FSM_UNCHANGED=YES
POR_START_WATCHDOG_UNCHANGED=YES
SDA_SCL_FILTERS_UNCHANGED=YES
NVP_XDC_UNCHANGED=YES
XDMA_XCI_UNCHANGED=YES

PRE_INIT_DONE_CYCLE_EQUIVALENCE=PASS
R1F_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0

R1F_LOG_CAPACITY=64
R1F_TRANSACTION_INDEX_WIDTH=16
R1F_RECORD_WIDTH=192
R1F_PROBE_PHASES=3
R1F_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=10000

SOURCE_COMMIT_TO_BIT_PROVENANCE=PASS
```

No second build.

────────

14.1 Routed-DCP impact audit

Compare exact R1f routed DCP with exact R1e routed DCP.

At minimum:

```text
SCL/SDA IOBUF properties;
OEN-to-IOBUF paths;
pad-to-sync paths;
synchronizer placement;
clocking;
utilization;
BRAM use;
total/dynamic power;
VCCINT/VCCAUX/VCCO aggregate;
NVP hierarchy power;
routing congestion.
```

Required:

```text
R1F_IMPLEMENTATION_DELTA=
    QUANTIFIED

R1F_PLACEMENT_NEUTRAL=
    NOT_CLAIMED
```

Implementation changes are context, not an automatic scientific failure when
all normal build gates pass.

Push the diagnostic branch normally once after build PASS.

===================================================================== 15. P10 — HOST TOOL

Create a version-gated read-only R1f host tool.

It must read and preserve:

```text
normal NVP/video telemetry;
R1e lifecycle page;
R1f header/counters;
all 64 failed-transaction records;
all three probe aggregate/block tables;
all three probe NACK-index logs;
legacy 17-word NACK window.
```

No AXI-Lite write.

Required outputs per Arm A:

```text
raw MMIO inventory;
decoded JSON;
decoded CSV;
failed-transaction CSV;
phase-opportunity CSV;
probe per-phase CSV;
probe block CSV;
probe NACK-index CSV;
bank-invariant report;
lifecycle calculation.
```

Parser requirements:

```text
R1F_MAGIC/version/capabilities exact;

record version exact;

16-bit transaction index used as authoritative;

legacy 8-bit index labeled legacy only;

valid bits enforced;

read/write data never interpreted when invalid;

bank fields never interpreted when invalid;

all unused records zero;

stored count/overflow/total consistent;

legacy first-eight reconciliation verified.
```

===================================================================== 16. P11 — STATISTICAL PLAN FROZEN BEFORE HARDWARE

No statistical test may be selected after results are seen.

────────

16.1 Probe stationarity per phase

For each phase and each Arm-A repetition calculate:

```text
rate;
ppm;
Wilson 95% interval;
first/last NACK index;
adjacent-pair count;
run count;
maximum consecutive NACKs;
ten block rates.
```

Tests:

```text
block-homogeneity chi-square or exact equivalent;

Wald-Wolfowitz runs test;

adjacent-pair count against exact conditional distribution when feasible;

order-statistic context for first/last positions.
```

Required wording:

```text
COMPATIBLE_WITH_STATIONARY_MEMORYLESS_PROCESS
or
EVIDENCE_AGAINST_STATIONARITY_OR_INDEPENDENCE
or
INSUFFICIENT_EVENTS
```

A non-significant p-value is not proof of equality or independence.

────────

16.2 Autoinit phase rates

For every Arm-A repetition calculate:

```text
WADDR_NACK_RATE
REGADDR_NACK_RATE
DATA_NACK_RATE
RADDR_NACK_RATE
```

using measured opportunities.

Do not use raw equal-cell phase counts when opportunities differ.

Use an opportunity-normalized contingency or exact model.

────────

16.3 Autoinit versus matching post-init probe

Compare:

```text
autoinit WADDR versus post-init WADDR probe;

autoinit REGADDR versus post-init REGADDR probe;

autoinit DATA versus post-init DATA probe.
```

For each:

```text
rate difference;
rate ratio;
confidence interval;
Fisher exact or exact binomial/score test.
```

Use Holm correction across the three phase comparisons within each run.

Predeclared support criterion:

```text
AUTOINIT_CONTEXT_RATE_ELEVATION=
    SUPPORTED

only when:
    corrected p<0.01;
    rate-ratio lower 95% bound>2;
    and the direction repeats in at least 2 of 3 Arm-A runs.
```

Otherwise:

```text
NOT_SUPPORTED
or
MIXED
or
INSUFFICIENT_EVENTS.
```

────────

16.4 Replicate consistency

Compare A1/A2/A3 for:

```text
per-phase autoinit rates;
per-phase probe rates;
failed-transaction count;
bank-invariant result;
operation/table-slot distributions;
functional NVP result.
```

Compare B1/B2/B3 for:

```text
aggregate NACK count;
first-eight legacy records;
functional result.
```

Use exact/homogeneity tests where denominators exist.

Do not call three runs equivalent solely because all three PASS or FAIL.

────────

16.5 Bank semantics

Classify:

```text
BANK_TRACKER_COHERENCE=
    PASS_ZERO_INVARIANT_ERRORS
    or
    CONTRADICTION_MEASURED

R7_OPERATION_86_SEMANTICS=
    EXPLAINED_BY_R1F_FIELDS
    or
    REMAINS_INCONCLUSIVE
    or
    TRUE_TRACKER_CONTRADICTION_REPRODUCED.
```

Do not use bank dispersion as independent evidence when bank coherence fails.

===================================================================== 17. P12 — HARDWARE START-STATE GATE

Current expected state from R7:

```text
exact formal Phase 2;
pinned driver loaded;
diagnostic magic zero;
DONE=1.
```

Fresh evidence is authoritative.

Require:

```text
selected JTAG exact and stable;
kernel 7.0.0-29-generic;
next reboot kernel 29;
one endpoint 10ee:7011 / subsystem 0007 / class 058000;
Gen1 x1;
BAR0 128 KiB;
BAR1 64 KiB;
exact pinned driver or accepted clean loader-entry state;
formal runtime identity;
diagnostic magic zero;
no node owner;
zero DMA;
kernel/AER health PASS.
```

If exact formal state is already proven:

```text
BOOTSTRAP_RUN=
    NO
```

If current image is unproven but bootstrap is safe:

```text
BOOTSTRAP_RUN=
    YES_EXACT_FORMAL_ONCE
```

Use the accepted mode-aware observer.

Bootstrap maximum:

```text
1 program;
1 warm reboot;
1 exact driver load;
zero retry.
```

Bootstrap is not B1.

If bootstrap cannot prove formal identity and DONE:

```text
BLOCKED_FORMAL_START_STATE
```

No paired run.

===================================================================== 18. THREE PAIRED REPETITIONS

Frozen sequence:

```text
A1 -> B1 -> A2 -> B2 -> A3 -> B3
```

Every A starts from a freshly proven exact formal B state.

Every B is a full functional control and exact formal restoration.

Do not reorder after seeing results.

────────

18.1 Arm A procedure

For A1, A2 and A3:

```text
rehash exact R1f bit;

require formal-ready receipt;

program once with selected JTAG in transition mode;

require startup HIGH;
same-session DONE=1;
independent DONE=1;
no retry;

wait the exact modeled R1f autoinit+probe completion interval plus margin;

one warm reboot;

kernel 29;

corrected BAR geometry;

one exact explicit-path driver load;

runtime source/provenance/capabilities;

two coherent complete R1f snapshots;

fresh final DONE=1.
```

The required wait is computed and frozen from simulation:

```text
ARM_A_REQUIRED_WAIT_SECONDS=
    max(
        10.0,
        MODELED_R1F_PROBE_COMPLETE_SECONDS_FROM_CONFIGURATION + 2.0
    )
```

Valid R1f sample requires:

```text
phase opportunity counters coherent;

aggregate phase NACK sum equals legacy NACK_COUNT;

failed-transaction log coherent;

no failed-log overflow;

bank invariant errors=0;

all three probes DONE;

all three probes have exactly 10000 target opportunities;

zero probe timeout;

safe target pre/post readback equal;

original bank restored;

final DONE=1.
```

Classify functional NVP PASS/FAIL separately.

────────

18.2 Arm B procedure

For B1, B2 and B3:

```text
rehash exact formal bit;

program once with the same selected JTAG;

startup HIGH;
same-session DONE=1;
independent DONE=1;
no retry;

wait >=5 seconds;

one warm reboot;

kernel 29;

corrected BAR geometry;

one exact pinned-driver load;

formal identity;
diagnostic magic zero;

two coherent normal telemetry snapshots;

legacy ordered NACK window;

complete R1f address range reads deterministic zero;

fresh final DONE=1.
```

B1/B2/B3 are full controls, not restoration-only.

────────

18.3 Failure handling

A valid scientific PASS or FAIL continues automatically to the paired B arm and
then the next repetition.

If any A arm becomes infrastructure-invalid after a consumed program:

```text
run its immediate paired B restoration/control when safe;
hard-stop after that B;
do not continue later repetitions.
```

If any B arm is infrastructure-invalid:

```text
hard-stop;
do not start the next A.
```

No repeat of an invalid arm.

===================================================================== 19. SCIENTIFIC CLASSIFICATION

Required final classifications:

```text
POSTINIT_WADDR_PROCESS
POSTINIT_REGADDR_PROCESS
POSTINIT_DATA_PROCESS

AUTOINIT_PHASE_RATE_HETEROGENEITY

AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA

R1F_REPLICATE_HOMOGENEITY

BANK_TRACKER_COHERENCE

R7_OPERATION_86_SEMANTICS

FAILED_TRANSACTION_DISTRIBUTION

PAIRED_AB_RESULT
```

Conservative interpretation:

```text
POSTINIT_PHASE_STOCHASTICITY=
    may be supported independently for each phase;

AUTOINIT_CONTEXT_DEPENDENCE=
    requires opportunity-normalized, repeated evidence;

PHASE_SPECIFICITY=
    requires measured denominators;

BANK_DISPERSION=
    usable only when bank invariants pass.
```

Always state:

```text
ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO
```

===================================================================== 20. FINAL STATE

At successful task end require:

```text
FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
    A40A0C07 / 0000400B / 00031002

FINAL_DIAGNOSTIC_MAGIC=
    0

FINAL_PINNED_DRIVER_LOADED=
    YES

FINAL_DONE=
    1
```

===================================================================== 21. EVIDENCE AND PUBLICATION

Evidence repository:

```text
lukaszsudul/AHD-diagnostic-evidence
```

New path:

```text
v41-nvp-r1f-phase-complete-observability/
```

Include:

```text
verbatim owner prompt;
R7 identities;
source semantic audits;
safe probe-target audit;
source diff/commit/tree;
record-format specification;
register map;
all simulations/equivalence assertions;
build artifacts and DCP hashes;
routed-impact audit;
host tools/fixtures;
bootstrap evidence if used;
all six arm datasets;
raw and decoded 64-entry logs;
phase counters;
probe indices/block data;
statistical scripts/results;
operation ledger;
single final Markdown report;
SHA-256 manifest.
```

Create:

```text
V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY_EVIDENCE.zip
V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY_EVIDENCE_SHA256.txt
SHA256_MANIFEST.txt
```

No PDF or DOCX.

One normal evidence commit/push.

No tag or Release.

===================================================================== 22. REQUIRED FINAL REPORT BLOCK

The final report must end with:

```text
TASK=
    V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY_AND_REPLICATED_PAIRED_AB

EXPERIMENT_NAME=
    R1f

R7_EVIDENCE_COMMIT=
    16beec37a266c421da5838fbb986301d072cbb50

R7_EVIDENCE_PACKAGE_SHA256=
    A1864DA7EC52AEE852169656808510C42D98FDCE27816D82449946B610DD2A56

BASE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

BASE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1F_SOURCE_COMMIT=
R1F_SOURCE_TREE=
R1F_BIT_SHA256=
R1F_ROUTED_DCP_SHA256=

FULL_BUILDS=
    1

PRE_INIT_DONE_CYCLE_EQUIVALENCE=
AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=
R1F_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=

SAFE_DATA_PROBE_TARGET=
R1F_PROBE_BANK=
R1F_PROBE_REGISTER=
R1F_PROBE_DATA=
SAFE_TARGET_PRE_POST_READBACK_CONTRACT=

LEGACY_OPERATION_INDEX_BEHAVIOR=
R1F_TRANSACTION_INDEX_WIDTH=
    16
R1F_TABLE_SLOT_INDEX_WIDTH=
    16

R1F_FAILED_TXN_LOG_CAPACITY=
    64
R1F_FAILED_TXN_RECORD_WIDTH=
    192
R1F_FAILED_TXN_RECORD_VERSION=
    1

R1F_PHASE_COUNTERS=
    WADDR_REGADDR_DATA_RADDR

R1F_PROBE_PHASES=
    WADDR_REGADDR_DATA
R1F_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=
    10000
R1F_PROBE_BLOCKS_PER_PHASE=
    10
R1F_PROBE_INDEX_LOG_CAPACITY_PER_PHASE=
    512

PAIR_COUNT_PLANNED=
    3
PAIR_COUNT_VALID=

BOOTSTRAP_RUN=
BOOTSTRAP_RESULT=

A1_RESULT=
A1_AUTOINIT_WADDR_OPPORTUNITIES=
A1_AUTOINIT_WADDR_NACKS=
A1_AUTOINIT_REGADDR_OPPORTUNITIES=
A1_AUTOINIT_REGADDR_NACKS=
A1_AUTOINIT_DATA_OPPORTUNITIES=
A1_AUTOINIT_DATA_NACKS=
A1_AUTOINIT_RADDR_OPPORTUNITIES=
A1_AUTOINIT_RADDR_NACKS=
A1_FAILED_TXN_TOTAL=
A1_FAILED_TXN_STORED=
A1_FAILED_TXN_OVERFLOW=
A1_BANK_INVARIANT_ERRORS=
A1_PROBE_WADDR_NACKS=
A1_PROBE_REGADDR_NACKS=
A1_PROBE_DATA_NACKS=
A1_PROBE_TIMEOUTS=
A1_NVP_RESULT=

B1_NACK_COUNT=
B1_NACK_LOG_COUNT=
B1_NACK_LOG_OVERFLOW=
B1_NVP_RESULT=

A2_RESULT=
A2_AUTOINIT_WADDR_OPPORTUNITIES=
A2_AUTOINIT_WADDR_NACKS=
A2_AUTOINIT_REGADDR_OPPORTUNITIES=
A2_AUTOINIT_REGADDR_NACKS=
A2_AUTOINIT_DATA_OPPORTUNITIES=
A2_AUTOINIT_DATA_NACKS=
A2_AUTOINIT_RADDR_OPPORTUNITIES=
A2_AUTOINIT_RADDR_NACKS=
A2_FAILED_TXN_TOTAL=
A2_FAILED_TXN_STORED=
A2_FAILED_TXN_OVERFLOW=
A2_BANK_INVARIANT_ERRORS=
A2_PROBE_WADDR_NACKS=
A2_PROBE_REGADDR_NACKS=
A2_PROBE_DATA_NACKS=
A2_PROBE_TIMEOUTS=
A2_NVP_RESULT=

B2_NACK_COUNT=
B2_NACK_LOG_COUNT=
B2_NACK_LOG_OVERFLOW=
B2_NVP_RESULT=

A3_RESULT=
A3_AUTOINIT_WADDR_OPPORTUNITIES=
A3_AUTOINIT_WADDR_NACKS=
A3_AUTOINIT_REGADDR_OPPORTUNITIES=
A3_AUTOINIT_REGADDR_NACKS=
A3_AUTOINIT_DATA_OPPORTUNITIES=
A3_AUTOINIT_DATA_NACKS=
A3_AUTOINIT_RADDR_OPPORTUNITIES=
A3_AUTOINIT_RADDR_NACKS=
A3_FAILED_TXN_TOTAL=
A3_FAILED_TXN_STORED=
A3_FAILED_TXN_OVERFLOW=
A3_BANK_INVARIANT_ERRORS=
A3_PROBE_WADDR_NACKS=
A3_PROBE_REGADDR_NACKS=
A3_PROBE_DATA_NACKS=
A3_PROBE_TIMEOUTS=
A3_NVP_RESULT=

B3_NACK_COUNT=
B3_NACK_LOG_COUNT=
B3_NACK_LOG_OVERFLOW=
B3_NVP_RESULT=

POSTINIT_WADDR_PROCESS=
POSTINIT_REGADDR_PROCESS=
POSTINIT_DATA_PROCESS=

AUTOINIT_PHASE_RATE_HETEROGENEITY=
AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR=
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR=
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA=
R1F_REPLICATE_HOMOGENEITY=

BANK_TRACKER_COHERENCE=
R7_OPERATION_86_SEMANTICS=
FAILED_TRANSACTION_DISTRIBUTION=

PAIRED_AB_RESULT=

ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2
FINAL_FORMAL_IDENTITY=
FINAL_DIAGNOSTIC_MAGIC=
FINAL_PINNED_DRIVER_LOADED=
FINAL_DONE=

CONDITIONAL_FORMAL_BOOTSTRAP_PROGRAMS=
ARM_A_PROGRAMS=
ARM_B_PROGRAMS=
FPGA_PROGRAM_INVOCATIONS=
WARM_REBOOTS=
DRIVER_LOADS=

PROGRAM_RETRIES=
    0

COLD_STARTS=
    0

PHYSICAL_ACTIONS=
    0

JTAG_FREQUENCY_CHANGES=
    0

PCI_REMOVE_RESCAN_RESETS=
    0

AXI_LITE_WRITES=
    0

C2H_TRANSFERS=
    0

H2C_TRANSFERS=
    0

PHASE3_RESUMED=
    NO

XDMA_DEVELOPMENT_CONTINUED=
    NO

FORMAL_REPOSITORY_MUTATIONS=
    0

OWNER_INTERACTIVE_APPROVAL_REQUESTS=
    0

OWNER_PROMPT_SHA256=
EVIDENCE_PACKAGE_SHA256=
EVIDENCE_REPOSITORY_COMMIT=
PUBLIC_REMOTE_VERIFICATION=
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_R1F_PHASE_COMPLETE_RESULTS
```

===================================================================== 23. HARD STOPS

Stop before source commit if:

```text
exact R1e base is unavailable;
current legacy semantics cannot be audited;
no proven safe idempotent data-probe target exists;
record-map collision exists;
diagnostic-only fanout cannot be guaranteed.
```

Stop before build if:

```text
pre-init equivalence fails;
legacy first-eight reconciliation fails;
16-bit index uniqueness fails;
bank semantics tests fail;
phase counters disagree with scoreboard;
probe setup/restore or target-phase counting fails.
```

Stop before hardware if:

```text
build/timing/DRC/CDC/provenance fails;
exact R1f bit identity unavailable;
host-tool fixtures fail;
formal start-state gate fails;
selected JTAG/kernel/driver/BAR safety fails.
```

Stop during hardware if:

```text
programming fails;
host does not return;
kernel differs;
driver cannot load once;
runtime provenance mismatches;
phase counters are incoherent;
failed-transaction log overflows;
bank invariant error count is nonzero;
probe aborts;
probe opportunity count differs from 10000;
safe target restoration fails;
final DONE fails.
```

No:

```text
second build;
source patch;
probe-target change;
probe-count change;
extra pair;
program retry;
physical recovery;
Phase-3 work.
```

===================================================================== 24. BEGIN

```text
save and hash this prompt
    ->
preserve and verify R7 evidence
    ->
check out exact local R1e source commit/tree
    ->
audit legacy index/log/bank semantics
    ->
audit and freeze one safe idempotent data-probe target
    ->
add passive autoinit phase opportunity/NACK counters
    ->
add independent 16-bit transaction and table-slot indices
    ->
add 64-entry 192-bit failed-transaction log
    ->
add bank before/requested/selector/verify/after semantics and invariants
    ->
add round-robin WADDR/REGADDR/DATA probe
    with 10000 target opportunities per phase
    ->
implement versioned read-only map and host tools
    ->
prove cycle-equivalence through init_done
    ->
run complete simulation matrix
    ->
create one R1f source commit
    ->
perform one clean build and routed-impact audit
    ->
push diagnostic branch
    ->
prove exact formal hardware start state
    ->
optional formal bootstrap only if required
    ->
run:
        A1 -> B1 -> A2 -> B2 -> A3 -> B3
    ->
perform predeclared statistical analysis
    ->
leave exact formal Phase 2 active
    ->
create one authoritative Markdown report
    ->
seal and publish evidence
    ->
HARD STOP.
```

No interactive owner questions.
No second build.
No probe-target improvisation.
No host MMIO writes.
No DMA.
No Phase 3.
No XDMA work.
