CODEX MASTER PROMPT

v41 NVP R1g — VHDL-language compatibility continuation of R1f

Exact child of the frozen R1f diagnostic source

Mechanical syntax compatibility only; no scientific or functional change

Complete frontend/elaboration preflight → one clean build

→ A1/B1 → A2/B2 → A3/B3

FULL OWNER PRE-AUTHORIZATION — NO INTERACTIVE CONFIRMATIONS

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY

EXPERIMENT_NAME:
    R1g

NAMING_BASIS:
    R1g is the next experiment letter after terminal R1f.

TASK_CHARACTER:
    SEPARATELY_AUTHORIZED_CONTINUATION_OF_THE_FROZEN_R1F_EXPERIMENT

PRIMARY_PURPOSE:
    Preserve the complete R1f scientific design and correct only source-language
    constructs that are unsupported by the exact production synthesis frontend.

    Prove that R1g is semantically equivalent to the intended R1f RTL, then
    perform one clean provenance-correct build and, only after full build PASS,
    execute the frozen three-pair hardware campaign:

        A1 -> B1 -> A2 -> B2 -> A3 -> B3.

KNOWN_R1F_BUILD_BLOCKER:
    [Synth 8-2757] VHDL-2008-only sequential conditional signal assignment at
    rtl/nvp/nvp6134c_i2c_bringup.vhd:994.

KNOWN_R1F_LINE:
    r1f_tx_wdata_r <= write_data when is_read_op = '0' else x"00";

REQUIRED_KNOWN_MECHANICAL_REWRITE:
    if is_read_op = '0' then
        r1f_tx_wdata_r <= write_data;
    else
        r1f_tx_wdata_r <= x"00";
    end if;

GLOBAL_VHDL_STANDARD_CHANGE:
    FORBIDDEN

R1F_SCIENTIFIC_SCOPE_CHANGE:
    NO

R1F_REGISTER_MAP_CHANGE:
    NO

R1F_PROBE_TARGET_OR_COUNT_CHANGE:
    NO

R1F_STATISTICAL_PLAN_CHANGE:
    NO

FRONTEND_LANGUAGE_PREFLIGHT:
    REQUIRED_BEFORE_FULL_BUILD

FULL_CLEAN_BUILDS:
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
isolated worktree and branch creation;

bounded recovery of the exact local R1f commit from the exact published patch
when the original local object is missing;

the mechanical VHDL compatibility edits defined here;

all static language audits;

all non-synthesis parser/compiler iterations before the final source commit;

cross-standard equivalence simulations;

one final RTL-elaboration preflight after the R1g commit;

one clean provenance-correct full build;

one normal diagnostic-branch push after build PASS;

conditional exact formal bootstrap;

three Arm-A R1g programs;

three full Arm-B formal programs;

all authorized warm reboots and exact pinned-driver loads;

all bounded read-only MMIO and telemetry;

evidence sealing and one normal evidence publication.
```

A passing gate means continue automatically.

A failed or blocked gate means:

```text
preserve all available evidence;
create the one authoritative final report;
publish safely available evidence;
hard-stop without asking whether to continue.
```

This authorization does not permit any operation outside the exact scope or
above the numerical limits.

===================================================================== 0. AUTHORITATIVE R1f TERMINAL RESULT

Public R1f evidence:

```text
EVIDENCE_REPOSITORY=
    lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT=
    1130c4686a7aaedcf2609dd4a5739d7a7eb73fff

EVIDENCE_PATH=
    v41-nvp-r1f-phase-complete-observability/
```

At task start, resolve and preserve from the exact public sidecars:

```text
R1F_AUTHORITATIVE_REPORT_SHA256=
R1F_EVIDENCE_PACKAGE_SHA256=
R1F_PUBLICATION_RECEIPT_SHA256=
```

Owner-provided identifying bounds:

```text
R1F_AUTHORITATIVE_REPORT_SHA256_PREFIX_SUFFIX=
    2F0D7997...0544C09D

R1F_EVIDENCE_PACKAGE_SHA256_PREFIX_SUFFIX=
    62350D80...F4704E4
```

Do not invent missing middle digits.

Exact R1f source:

```text
R1F_SOURCE_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1F_SOURCE_TREE=
    cfde8769af95cf20586391c411fab3ddfa2c87b6

R1F_PARENT_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1F_PARENT_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

COMMITS_ABOVE_R1E_BASE=
    1
```

Exact R1f reconstruction source:

```text
PUBLISHED_PATCH_PATH=
    v41-nvp-r1f-phase-complete-observability/
    01_SOURCE_IDENTITY/
    0001-Add-R1f-phase-complete-NVP-observability.patch

PUBLISHED_PATCH_GIT_BLOB=
    c2ae3a52a49cef79149cdf1d0b79c9be66c75968
```

Exact R1f pre-build identities:

```text
R1F_PREBUILD_MANIFEST_SHA256=
    34626CAFDF0D2CD6A4DA87B6D7ED6C7146B4C16E7384BD5AA3927BE440859A04

R1F_FROZEN_BUILD_TCL_SHA256=
    53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B

R1F_TERMINAL_BUILD_LOG_SHA256=
    43C05651BEFA0DB30E00B7B16058D424AFEF38FEA2D0E15A9AF0381604A7E4D0

R1F_TERMINAL_FAILURE_RECEIPT_SHA256=
    1073A967F9E551FF716DF18983397B1B71D9082505A849DC4ACDBBA6DDC87AD1

R1F_TERMINAL_AUDIT_SHA256=
    9E4DA8D0F966F652F1EAAA3B4FF39DE305CDB4511AE5570DE1D97797DC44E15E
```

R1f terminal build result:

```text
R1F_CLEAN_BUILDS=
    1

R1F_SYNTHESIS_RUNS=
    1

R1F_SYNTHESIS=
    FAIL_RTL_ELABORATION

R1F_IMPLEMENTATION_RUNS=
    0

R1F_BITSTREAMS=
    0

R1F_HARDWARE_ACTIONS=
    0

R1F_CLASSIFICATION=
    BLOCKED_ONE_CLEAN_BUILD_SYNTHESIS_VHDL_2008_CONSTRUCT
```

Exact terminal error:

```text
ERROR:
    [Synth 8-2757] this construct is only supported in VHDL 1076-2008

FILE:
    rtl/nvp/nvp6134c_i2c_bringup.vhd

LINE:
    994

CONSTRUCT:
    diagnostic-only sequential conditional signal assignment

SOURCE_TEXT:
    r1f_tx_wdata_r <= write_data when is_read_op = '0' else x"00";
```

R1f offline gates that passed:

```text
EXACT_BASE_AND_SOURCE_IDENTITY=
    PASS

SAFE_DATA_PROBE_TARGET=
    PASS_BANK00_REG85_DATA00

PRE_INIT_DONE_CYCLE_EQUIVALENCE=
    PASS

AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=
    YES

EFFECTIVE_PRE_INIT_SCL_SDA_EQUALITY=
    PASS

DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=
    0

PHASE_COUNTERS_VS_SCOREBOARD=
    PASS

R7_13_EVENT_PATTERN=
    PASS

R7_15_EVENT_PATTERN=
    PASS

HISTORICAL_36_EVENT_PATTERN=
    PASS

ALL_FOUR_ACK_PHASE_FAILURE_TESTS=
    PASS

ALL_13_TRANSACTION_KINDS=
    PASS

OPERATION_86_TRANSITIONAL_CONTEXT=
    PASS

LEGACY_FIRST8_RECONCILIATION=
    PASS

TRANSACTION_SERIAL_INDEX_300=
    PASS

FAILED_LOG_CAPACITY_64=
    PASS

FAILED_LOG_OVERFLOW_AT_65=
    PASS

BANK_BEFORE_AFTER_AND_INVARIANTS=
    PASS

TRI_PHASE_PROBE_MODEL=
    PASS

SAFE_TARGET_SETUP_READBACK_RESTORE_MODEL=
    PASS

HOST_TOOL_FIXTURES=
    PASS_24_OF_24

PREBUILD_RELEASE=
    PASS

MODELED_ARM_A_WAIT_SECONDS=
    33.536673744
```

No R1f scientific hardware result exists.

R1g must not convert any NOT_RUN R1f result into zero or PASS.

=====================================================================

1. FROZEN R1f SCIENTIFIC DESIGN
=====================================================================

R1g inherits every R1f scientific and register-contract decision unchanged.

────────

1.1 Autoinit profile

```text
AUTOINIT_I2C_HZ=
    25000

AUTOINIT_CLOCK_HZ=
    62500000

ACTIVE_TICK_CYCLES=
    1251

EXPECTED_CNT_AT_INIT_DONE=
    132584734
```

────────

1.2 Safe active probe target

```text
R1F_PROBE_BANK=
    0x00

R1F_PROBE_REGISTER=
    0x85

R1F_PROBE_DATA=
    0x00

REGISTER_NAME=
    SPL_MD_CH1

DATA_PROBE_CONTRACT=
    VERIFIED_BANK0
    PRE_READ_0x00
    SAME_VALUE_WRITES_ONLY
    POST_READ_0x00
    ORIGINAL_BANK_RESTORED_AND_VERIFIED
```

────────

1.3 Passive autoinit counters

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

────────

1.4 Failed-transaction log

```text
CAPACITY=
    64

RECORD_WIDTH_BITS=
    192

WORDS_PER_RECORD=
    6

RECORD_VERSION=
    1

TRANSACTION_INDEX_WIDTH=
    16

TABLE_SLOT_INDEX_WIDTH=
    16

OVERWRITE_MODE=
    NONE_APPEND_ONLY

OVERFLOW_AFTER=
    65TH_FAILED_TRANSACTION
```

────────

1.5 Tri-phase probe

```text
PROBE_PHASES=
    WRITE_ADDRESS_ACK
    REGISTER_ADDRESS_ACK
    DATA_ACK

PROBE_TARGET_OPPORTUNITIES_PER_PHASE=
    10000

PROBE_BLOCKS_PER_PHASE=
    10

PROBE_TARGET_OPPORTUNITIES_PER_BLOCK=
    1000

PROBE_NACK_INDEX_CAPACITY_PER_PHASE=
    512

PROBE_SCHEDULER=
    ROUND_ROBIN_INTERLEAVED

PROBE_I2C_HZ=
    25000

PROBE_DEVICE_ADDRESS_WRITE=
    0x60
```

────────

1.6 Frozen register map

Preserve the exact committed R1f map and all legacy/formal offsets.

Expected R1f diagnostic ranges:

```text
0x20A0..0x21FF:
    header/capabilities/autoinit phase counters/log and probe status/
    safe-target identity/invariant counters

0x2200..0x23FF:
    per-phase probe aggregates and block statistics

0x2400..0x29FF:
    64 failed-transaction records

0x2A00..0x2DFF:
    WADDR probe NACK indices

0x2E00..0x31FF:
    REGADDR probe NACK indices

0x3200..0x35FF:
    DATA probe NACK indices
```

Exact formal Phase 2 must return deterministic zero throughout the R1f/R1g
diagnostic range.

────────

1.7 Frozen statistical plan

Preserve the exact R1f statistical scripts, thresholds and interpretation.

In particular:

```text
PAIR_SEQUENCE=
    A1 -> B1 -> A2 -> B2 -> A3 -> B3

AUTOINIT_CONTEXT_RATE_ELEVATION_SUPPORTED_IF:
    Holm-corrected p < 0.01
    and
    rate-ratio lower 95% bound > 2
    and
    same direction in at least 2 of 3 Arm-A runs
```

No statistical method may be changed after hardware results are observed.

===================================================================== 2. EXACT FORMAL, JTAG, HOST, AND DRIVER IDENTITIES

Formal repository:

```text
GITHUB_REPOSITORY=
    lukaszsudul/FPGA_AHD

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

JTAG_PATH_SUFFIX=
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
IP=
    10.132.1.111

USER=
    vcdeagent1

REQUIRED_KERNEL=
    7.0.0-29-generic

CREDENTIAL_FILE=
    C:\FPGA\VCDE-DUT-1.txt
```

Pinned XDMA:

```text
SOURCE_COMMIT=
    8721136e74a66500b02d16cb41922d966139cd46

MODULE_PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko

MODULE_SHA256=
    1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A

MODULE_VERSION=
    2025.2.0

MODULE_VERMAGIC_PREFIX=
    7.0.0-29-generic

LOADER_PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh

LOADER_SHA256=
    7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
```

Reuse exact accepted:

```text
mode-aware programming observer;
selected-target selector;
Python BAR parser;
AXI-Lite readers;
R1f host reader/decoder/statistics scripts;
credential and host-key procedure.
```

===================================================================== 3. AUTHORIZATION AND ABSOLUTE LIMITS

Authorized source work:

```text
one isolated R1g branch/worktree;

recovery of exact R1f source when required;

mechanical rewrites of VHDL-2008-only constructs introduced by the exact R1f
delta into semantically equivalent syntax accepted by the exact production
VHDL frontend;

one R1g child commit;

task-local language-audit and build scripts.
```

Authorized offline tools:

```text
unbounded bounded-scope static analysis iterations before the final source
commit;

non-synthesis VHDL compiler/parser iterations before the final source commit;

cross-standard simulation/equivalence runs;

one final post-commit RTL-elaboration preflight;

one full clean build;

one routed-DCP comparison;

one diagnostic-branch push after build PASS.
```

Authorized hardware:

```text
conditional exact formal bootstrap when the fresh formal start state is not
proven;

three Arm-A R1g samples;

three full exact formal Arm-B control samples;

one warm reboot and at most one exact pinned-driver load after every valid
program;

read-only host telemetry.
```

Maximum:

```text
R1G_SOURCE_COMMITS=
    1

FINAL_RTL_ELABORATION_PREFLIGHTS=
    1

FULL_CLEAN_BUILDS=
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
setting the project or any source file to VHDL-2008;

adding `-vhdl2008` to the production build;

changing the exact production language standard;

changing scientific RTL behavior;

changing constants, widths, field positions, valid-bit semantics, probe
scheduling, probe target, opportunity counts, record count, register map or
statistical plan;

second source commit;

second clean build;

source correction after the full build begins;

cold start;
power cycle;
physical action;
JTAG/cable change;
JTAG-frequency change;
kernel/GRUB change;
module rebuild;
PCIe remove/rescan/reset;
host AXI-Lite write;
host NVP/I2C write;
DMA;
Phase 3;
XDMA development;
tag;
Release.
```

===================================================================== 4. TASK ROOT AND GIT POLICY

Create:

```text
C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\
```

Required structure:

```text
00_R1F_INPUT\
01_SOURCE_RECOVERY\
02_LANGUAGE_CONTRACT\
03_STATIC_COMPATIBILITY_AUDIT\
04_MECHANICAL_REWRITE\
05_CROSS_STANDARD_EQUIVALENCE\
06_FINAL_FRONTEND_PREFLIGHT\
07_R1G_SOURCE_IDENTITY\
08_BUILD\
09_HOST_TOOLS\
10_HARDWARE_PRECHECK\
11_BOOTSTRAP\
12_PAIR_1\
13_PAIR_2\
14_PAIR_3\
15_ANALYSIS\
16_FINAL\
scripts\
fixtures\
```

Create immediately:

```text
OPERATION_LEDGER.md
TIME_LEDGER.md
```

Save this prompt verbatim and record its SHA-256 before source mutation.

Branch:

```text
diag/v41-nvp-r1g-vhdl-compatibility
```

Exact parent:

```text
225544084dbfcaadb8592fcecc947aa1cec4970e
```

Required commit topology:

```text
R1E_BASE
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1F_DIAGNOSTIC_COMMIT
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1G_COMPATIBILITY_COMMIT
    one direct child of R1f
```

Do not amend or rebase R1f.

Do not push the R1f branch.

Push only the R1g diagnostic branch after full build PASS.

Initial accounting:

```text
R1G_SOURCE_COMMITS=0
NON_SYNTHESIS_LANGUAGE_COMPILE_ITERATIONS=0
FINAL_RTL_ELABORATION_PREFLIGHTS=0
FULL_CLEAN_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_PROGRAMS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
DMA_TRANSFERS=0
PHYSICAL_ACTIONS=0
```

===================================================================== 5. P0 — EXACT R1f SOURCE RECOVERY

Prefer the exact existing local R1f commit.

Require:

```text
git cat-file -e 225544084dbfcaadb8592fcecc947aa1cec4970e^{commit}

commit tree=
    cfde8769af95cf20586391c411fab3ddfa2c87b6

direct parent=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

parent tree=
    db8b5581a237e19905fd01c6d453793047bc3ba7
```

If the exact local R1f commit is absent, bounded recovery is authorized only
from:

```text
the exact local R1e parent commit;
the exact published R1f patch;
the exact R1f source manifest and evidence package.
```

Recovery must reproduce:

```text
R1F_SOURCE_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1F_SOURCE_TREE=
    cfde8769af95cf20586391c411fab3ddfa2c87b6
```

No approximate reconstruction is accepted.

If the exact tree is reproduced but commit metadata differs:

```text
do not proceed under a new commit identity;

attempt exact metadata-preserving recovery from the published patch once;

if exact commit remains unavailable:
    BLOCKED_EXACT_R1F_COMMIT_NOT_RECOVERABLE.
```

Create:

```text
01_SOURCE_RECOVERY\R1F_GIT_IDENTITY.md
01_SOURCE_RECOVERY\R1F_SOURCE_SHA256.txt
01_SOURCE_RECOVERY\R1F_PATCH_IDENTITY.md
```

===================================================================== 6. P1 — DERIVE THE EXACT PRODUCTION LANGUAGE CONTRACT

Do not assume the language standard from memory.

Audit the exact frozen R1f build Tcl and every invoked helper.

Capture installed Vivado 2025.2 help for:

```text
read_vhdl;
synth_design;
xvhdl;
xelab;
get_files;
get_property FILE_TYPE;
get_property USED_IN_SYNTHESIS;
report_compile_order.
```

Derive and record:

```text
R1F_PRODUCTION_VHDL_STANDARD=
R1F_READ_VHDL_COMMANDS=
R1F_VHDL_FILE_TYPES=
R1F_LIBRARY_ASSIGNMENTS=
R1F_COMPILE_ORDER=
R1F_SYNTH_TOP=
    ahd_capture_top_xdma

R1F_PART=
    xc7a35tcsg325-2
```

Required:

```text
R1G_PRODUCTION_VHDL_STANDARD=
    EXACTLY_EQUAL_TO_R1F_PRODUCTION_VHDL_STANDARD

GLOBAL_VHDL_STANDARD_CHANGE=
    NO

FILE_TYPE_VHDL2008_CHANGES=
    0

READ_VHDL_VHDL2008_OPTION_ADDED=
    NO
```

Create:

```text
02_LANGUAGE_CONTRACT\PRODUCTION_LANGUAGE_CONTRACT.md
02_LANGUAGE_CONTRACT\EXACT_COMPILE_ORDER.txt
02_LANGUAGE_CONTRACT\INSTALLED_TOOL_HELP\
```

Any ambiguity in the exact production language contract:

```text
BLOCKED_PRODUCTION_VHDL_LANGUAGE_CONTRACT_NOT_PROVEN
```

No source edit.

===================================================================== 7. P2 — COMPLETE STATIC COMPATIBILITY AUDIT

Audit only:

```text
VHDL files changed by R1f;
and exact VHDL context needed to classify their constructs.
```

Do not rewrite unchanged inherited VHDL merely for style.

Generate an exact R1e-to-R1f changed-line inventory.

For every changed VHDL construct classify:

```text
legal in exact production standard;
VHDL-2008-only;
uncertain;
comment/string only.
```

At minimum audit for:

```text
sequential conditional signal assignment;
sequential selected signal assignment;
conditional expressions;
selected expressions;
process(all);
all-keyword sensitivity;
matching case/case?;
matching relational operators;
external names;
generic packages/types/subprograms;
record/array features requiring 2008;
context declarations;
protected-type usage;
VHDL-2008 aggregates or port-map forms;
any construct named by the installed frontend error/help.
```

Regex may discover candidates but may not be the acceptance gate.

Every candidate must be confirmed by:

```text
exact source context;
and
the exact production-mode compiler/parser.
```

Required known finding:

```text
FILE=
    rtl/nvp/nvp6134c_i2c_bringup.vhd

R1F_LINE=
    994

CLASSIFICATION=
    SEQUENTIAL_CONDITIONAL_SIGNAL_ASSIGNMENT_VHDL2008_ONLY
```

Create:

```text
03_STATIC_COMPATIBILITY_AUDIT\
    R1F_CHANGED_VHDL_LINE_INVENTORY.csv

03_STATIC_COMPATIBILITY_AUDIT\
    VHDL2008_CONSTRUCT_INVENTORY.csv

03_STATIC_COMPATIBILITY_AUDIT\
    STATIC_AUDIT_REPORT.md
```

Before editing, freeze:

```text
R1G_COMPATIBILITY_REWRITE_COUNT=
R1G_COMPATIBILITY_REWRITE_FILES=
```

No functional rewrite is allowed.

===================================================================== 8. P3 — MECHANICAL COMPATIBILITY REWRITE

The known required replacement is exact:

```vhdl
-- R1f
r1f_tx_wdata_r <= write_data when is_read_op = '0' else x"00";
```

to:

```vhdl
-- R1g
if is_read_op = '0' then
  r1f_tx_wdata_r <= write_data;
else
  r1f_tx_wdata_r <= x"00";
end if;
```

For any additional proven incompatible construct, use only the narrow
mechanical equivalent:

```text
sequential conditional assignment:
    if / elsif / else

sequential selected assignment:
    case

process(all):
    exact explicit sensitivity list derived from read dependencies

conditional/selected expression:
    temporary variable or exact if/case assignment with complete branches
```

Required properties:

```text
same clocked process;
same reset branch;
same assignment target;
same assignment timing;
same value width;
same branch condition;
same complete assignment coverage;
same priority;
same default;
same delta-cycle semantics;
no latch;
no additional register;
no removed register.
```

Forbidden rewrite patterns:

```text
moving a sequential assignment outside its process;

changing signal assignment to variable assignment unless equivalence is
formally proven and no delta-cycle behavior changes;

adding a default assignment in a different clock branch;

changing x"00" to another encoding;

changing condition polarity;

changing the functional FSM;

changing the diagnostic record schema.
```

Create:

```text
04_MECHANICAL_REWRITE\
    R1F_TO_R1G_COMPATIBILITY.patch

04_MECHANICAL_REWRITE\
    REWRITE_SEMANTICS_TABLE.csv

04_MECHANICAL_REWRITE\
    SOURCE_CHANGE_SCOPE.md
```

Required:

```text
R1G_SOURCE_CHANGE_CLASS=
    VHDL_LANGUAGE_COMPATIBILITY_ONLY

R1G_FUNCTIONAL_RTL_CHANGE=
    NO

R1G_DIAGNOSTIC_SEMANTICS_CHANGE=
    NO

R1G_SCIENTIFIC_PARAMETER_CHANGE=
    NO
```

===================================================================== 9. P4 — NON-SYNTHESIS COMPILER ITERATIONS

Before the final source commit, run the exact installed VHDL compiler/parser in
the exact production language mode.

Use the exact production:

```text
file list;
library assignments;
compile order;
include paths;
generics visible to elaboration.
```

The installed help determines exact command syntax.

Allowed before the commit:

```text
multiple non-synthesis compiler/parser iterations limited to the frozen R1f
VHDL delta and exact project source list.
```

Every failed iteration must be preserved.

A failure may be corrected only when:

```text
it is another proven language-compatibility issue;

the correction remains mechanical;

the correction is added to the frozen rewrite inventory;

all equivalence gates are rerun.
```

Not allowed in this phase:

```text
synth_design;
opt_design;
place_design;
route_design;
write_bitstream.
```

Required final compiler result before equivalence:

```text
EXACT_PRODUCTION_MODE_VHDL_COMPILE=
    PASS_ALL_FILES

UNRESOLVED_VHDL2008_CONSTRUCTS=
    0
```

===================================================================== 10. P5 — CROSS-STANDARD SEMANTIC EQUIVALENCE

Compile two libraries/design variants.

Reference:

```text
exact R1f commit;
the exact language mode previously used by the accepted R1f simulations;
no source modification.
```

Candidate:

```text
R1g mechanical rewrite;
exact production synthesis language mode.
```

Use identical testbench stimuli and generics.

Compare cycle by cycle:

```text
every original functional NVP output;
effective SCL/SDA open-drain release requests;
reset and power controls;
init_busy/done/error;
legacy diag_detail[735:0];
legacy first-error fields;
legacy aggregate counters;
legacy eight-record log;

every R1f phase opportunity/NACK counter;
16-bit transaction serial;
16-bit table-slot index;
all 64 failed-transaction records;
all bank semantic fields and invariants;
all tri-phase probe counters;
all probe index logs;
all R1f read-only register-page values.
```

Run the complete accepted R1f simulation matrix, including:

```text
all ACK;
isolated WADDR/REGADDR/DATA/RADDR NACK;
multiple NACK phases in one transaction;
13-event pattern;
15-event pattern;
36-event pattern;
64 failed transactions;
65 failed transactions;
transaction index 300;
all 13 transaction kinds;
operation-86 transitional context;
bank selector write/verify cases;
tri-phase probe all-ACK and error patterns;
safe-target setup/readback/restore;
formal-zero page model.
```

Required:

```text
R1F_VHDL2008_REFERENCE_SIMULATION=
    PASS

R1G_PRODUCTION_STANDARD_SIMULATION=
    PASS

CYCLE_BY_CYCLE_ALL_OUTPUT_EQUIVALENCE=
    PASS

R1F_TO_R1G_SEMANTIC_DIFFERENCES=
    0

LEGACY_FIRST8_RECONCILIATION=
    PASS

PRE_INIT_DONE_CYCLE_EQUIVALENCE_TO_R1E=
    PASS

AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=
    YES

R1G_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=
    0
```

Any difference:

```text
BLOCKED_R1G_NOT_SEMANTICALLY_EQUIVALENT_TO_R1F
```

No source commit.

===================================================================== 11. P6 — CREATE THE ONE R1g SOURCE COMMIT

After all language and equivalence gates pass:

```text
verify parent commit exact;
verify worktree contains only the frozen compatibility rewrite;
create one source commit.
```

Suggested commit message:

```text
Make R1f diagnostics compatible with production VHDL frontend
```

Require:

```text
R1G_PARENT_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1G_COMMITS_ABOVE_R1F=
    1

R1G_SOURCE_COMMIT=
R1G_SOURCE_TREE=

R1G_CHANGED_FILES=
R1G_CHANGED_LINES=
```

Create:

```text
07_R1G_SOURCE_IDENTITY\
    R1G_COMMIT_TREE_PROOF.md

07_R1G_SOURCE_IDENTITY\
    R1G_SOURCE_SHA256.txt

07_R1G_SOURCE_IDENTITY\
    R1F_TO_R1G_COMMIT.patch
```

The source worktree must be clean.

No second source commit.

===================================================================== 12. P7 — FINAL POST-COMMIT RTL-ELABORATION PREFLIGHT

This is separately authorized from the full clean build.

Run exactly one disposable in-memory RTL-elaboration session using the exact
production frontend, source list, compile order, libraries, top, part and
language standard.

Use the installed Vivado help to select the supported elaboration-only mode.

Preferred semantic requirement:

```text
synth_design front-end elaboration only;
no optimized synthesized netlist acceptance claim;
no checkpoint;
no implementation;
no bitstream.
```

The preflight may invoke synth_design only in the exact installed
elaboration/RTL-only mode.

Static command audit must prove:

```text
no opt_design;
no place_design;
no phys_opt_design;
no route_design;
no write_checkpoint;
no write_bitstream;
no retry loop.
```

Required:

```text
FINAL_RTL_ELABORATION_PREFLIGHTS=
    1

FINAL_RTL_ELABORATION=
    PASS

SYNTH_8_2757_COUNT=
    0

UNSUPPORTED_LANGUAGE_CONSTRUCT_ERRORS=
    0

TOP_ELABORATED=
    ahd_capture_top_xdma

PART=
    xc7a35tcsg325-2

PROCESS_EXIT_CODE=
    0
```

If no exact elaboration-only mode is supported:

```text
BLOCKED_NO_NON_BUILD_PRODUCTION_FRONTEND_ELABORATION_MODE
```

Do not silently consume the full build as a substitute.

No second final preflight.

===================================================================== 13. P8 — R1g PREBUILD RELEASE

Create a new R1g prebuild manifest.

Require equality to R1f for everything except:

```text
R1g child commit/tree;
mechanically rewritten source-file hashes;
provenance values derived from the R1g commit.
```

Exact unchanged identities must include:

```text
NVP table;
probe target and counts;
register map;
host tools;
statistical scripts;
XDC;
XDMA XCI;
topology;
build Tcl structure;
part/top;
all constants.
```

The R1f frozen build Tcl must remain byte-identical unless it embeds a fixed
source identity.

If a source-identity field must be updated:

```text
generate a task-local provenance wrapper;

do not alter synthesis/implementation commands;

audit the delta independently.
```

Required:

```text
R1G_PREBUILD_RELEASE=
    PASS

R1G_PREBUILD_MANIFEST_SHA256=
R1G_BUILD_TCL_SHA256=

R1F_TO_R1G_BUILD_COMMAND_DELTA=
    ZERO_OR_PROVEN_PROVENANCE_ONLY
```

===================================================================== 14. P9 — ONE CLEAN PROVENANCE-CORRECT BUILD

Consume exactly one clean build after every prior gate passes.

Use:

```text
Vivado 2025.2 build 6299465;
part xc7a35tcsg325-2;
top ahd_capture_top_xdma;
exact unchanged XDMA XCI;
exact unchanged XDC;
exact production VHDL standard;
R1g source commit.
```

Suggested bit:

```text
ahd_capture_v41_i2c_25khz_r1g_phase_complete_observability.bit
```

Runtime provenance must reconstruct the exact R1g commit.

Use:

```text
BUILD_FLAGS=
    0x00000002
```

Required gates:

```text
FULL_CLEAN_BUILDS=
    1

FULL_SYNTHESIS=
    PASS

PLACE=
    PASS

ROUTE=
    PASS

ROUTE_ERRORS=
    0

WNS>=
    0

WHS>
    0

VDO_WNS>
    0

VDO_WHS>
    0

DRC_ERRORS=
    0

DRC_CRITICAL_WARNINGS=
    0

REQP_1839_SEMANTIC_COUNT=
    4

REQP_1839_RAW_TEXT_COUNT_USED_AS_GATE=
    NO

CDC_CRITICAL=
    0

CDC_UNKNOWN=
    0

AUTOINIT_I2C_HZ=
    25000

EXPECTED_CNT_AT_INIT_DONE=
    132584734

R1F_LOG_CAPACITY=
    64

R1F_RECORD_WIDTH=
    192

R1F_TRANSACTION_INDEX_WIDTH=
    16

R1F_PROBE_PHASES=
    3

R1F_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=
    10000

NVP_TABLE_UNCHANGED=
    YES

FUNCTIONAL_FSM_UNCHANGED=
    YES

POR_START_WATCHDOG_UNCHANGED=
    YES

SDA_SCL_FILTERS_UNCHANGED=
    YES

NVP_XDC_UNCHANGED=
    YES

XDMA_XCI_UNCHANGED=
    YES

SOURCE_COMMIT_TO_BIT_PROVENANCE=
    PASS
```

No source correction and no second build after the full build begins.

If the build fails:

```text
classify exact build blocker;
publish evidence;
no hardware.
```

===================================================================== 15. P10 — ROUTED-DCP IMPACT AUDIT

Compare exact R1g routed DCP with exact R1e routed DCP:

```text
R1E_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1
```

At minimum compare:

```text
SCL/SDA IOBUF properties;
OEN-to-IOBUF paths;
pad-to-synchronizer paths;
synchronizer placement;
clocking;
utilization;
BRAM use;
routing congestion;
total/dynamic power;
VCCINT/VCCAUX/VCCO aggregate;
NVP hierarchy power.
```

Required:

```text
R1G_IMPLEMENTATION_DELTA=
    QUANTIFIED

R1G_PLACEMENT_NEUTRAL=
    NOT_CLAIMED

R1G_LANGUAGE_REWRITE_CAUSED_FUNCTIONAL_NETLIST_CHANGE=
    NO_BY_LOGICAL_EQUIVALENCE_AND_EXPECTED_RTL
```

Normal placement/routing differences from R1e are context, not automatic
failure when all build gates pass.

Push the R1g diagnostic branch normally once after build PASS.

===================================================================== 16. P11 — HOST TOOL GATE

Reuse the exact R1f host tools and statistical scripts.

Require hash equality with the R1f evidence manifest.

Run all 24 accepted fixtures plus:

```text
R1g runtime source-commit fixture;
R1g bit-capability fixture;
formal complete-R1f-range-zero fixture.
```

Required:

```text
HOST_TOOL_HASH_GATE=
    PASS

HOST_TOOL_FIXTURES=
    PASS_ALL

R1F_RECORD_VERSION=
    1

R1F_REGISTER_MAP=
    UNCHANGED
```

No host MMIO writer may exist in the hardware path.

===================================================================== 17. P12 — FRESH HARDWARE START-STATE GATE

R7’s terminal formal state is historical context only.

Fresh evidence is authoritative.

Require read-only:

```text
selected JTAG exact and stable;
kernel 7.0.0-29-generic;
next reboot remains kernel 29;
one endpoint 10ee:7011 / subsystem 0007 / class 058000;
Gen1 x1;
BAR0 128 KiB;
BAR1 64 KiB;
exact pinned driver or accepted clean loader-entry state;
formal identity;
diagnostic magic zero;
no node owner;
zero task DMA;
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

Use the accepted R7 mode-aware observer.

Bootstrap maximum:

```text
one exact formal program;
one >=5-second wait;
one warm reboot;
one exact pinned-driver load;
zero retry.
```

Bootstrap is not B1.

If bootstrap cannot prove formal identity and DONE:

```text
BLOCKED_FORMAL_START_STATE
```

No A/B campaign.

===================================================================== 18. P13 — THREE INTERLEAVED PAIRED REPETITIONS

Frozen order:

```text
A1 -> B1 -> A2 -> B2 -> A3 -> B3
```

Do not reorder after observing results.

Every A arm starts from a freshly proven exact formal state.

Every B arm is a full functional control and exact formal restoration.

────────

18.1 Arm A procedure

For A1, A2 and A3:

```text
rehash exact R1g bit;

require valid formal-ready receipt;

program once with selected JTAG in transition mode;

require:
    pre-program DONE 1,1,1,1,1;
    vendor startup HIGH;
    same-session DONE=1;
    independent DONE=1;
    one invocation;
    exit code 0;
    zero retry;

wait:
    >=33.536673744 seconds
    using the accepted monotonic QPC method;

perform one warm reboot;

require kernel 29;

require corrected BAR geometry;

invoke one exact explicit-path driver load;

verify runtime:
    exact R1g source commit;
    BUILD_FLAGS=0x00000002;
    common identity;
    R1f/R1g magic/version/capabilities;

collect two coherent complete read-only snapshots;

read fresh final DONE=1.
```

A valid Arm-A instrumentation sample requires:

```text
phase opportunity counters coherent;

sum phase NACK counters equals aggregate NACK_COUNT;

failed-transaction total/stored count coherent;

failed-transaction overflow=0;

bank invariant error count=0;

all three probes DONE;

all three probes ABORTED=0;

WADDR target opportunities=10000;

REGADDR target opportunities=10000;

DATA target opportunities=10000;

probe timeouts=0;

safe target pre-read=0x00;

safe target post-read=0x00;

original bank restored and verified;

final DONE=1.
```

Classify NVP PASS/FAIL separately.

────────

18.2 Arm B procedure

For B1, B2 and B3:

```text
rehash exact formal bit;

program once with same selected JTAG in transition mode;

require startup HIGH;
same-session DONE=1;
independent DONE=1;
zero retry;

wait >=5 seconds;

one warm reboot;

kernel 29;

corrected BAR geometry;

one exact pinned-driver load;

formal runtime identity;
diagnostic magic zero;

two coherent normal NVP/video telemetry snapshots;

legacy ordered-NACK window;

complete R1f/R1g diagnostic range deterministic zero;

fresh final DONE=1.
```

B1/B2/B3 are full controls, not restoration-only.

────────

18.3 Failure handling

A valid scientific PASS or FAIL continues automatically to the paired B arm
and then the next repetition.

If any A arm becomes infrastructure-invalid after a consumed program:

```text
run its immediate paired B restoration/control when safe;
hard-stop after that B;
do not continue later repetitions.
```

If any B arm is infrastructure-invalid:

```text
hard-stop;
do not begin the next A.
```

No repeat of an invalid arm.

===================================================================== 19. P14 — FROZEN STATISTICAL ANALYSIS

Use the exact pre-hardware R1f statistical plan.

For every A arm and probe phase report:

```text
rate;
ppm;
Wilson 95%;
first/last NACK index;
adjacent-pair count;
run count;
maximum consecutive NACKs;
ten block rates;
stationarity/independence classification.
```

For every autoinit phase report:

```text
opportunities;
NACKs;
rate;
confidence interval.
```

Compare matching autoinit and post-init phases:

```text
WADDR versus WADDR;
REGADDR versus REGADDR;
DATA versus DATA.
```

Report:

```text
rate difference;
rate ratio;
95% interval;
exact/Fisher/score p-value;
Holm-adjusted p-value.
```

Repeatability:

```text
A1/A2/A3 phase-rate homogeneity;
A1/A2/A3 failed-transaction distribution;
B1/B2/B3 aggregate-NACK behavior;
pairwise directional consistency.
```

Required final classifications:

```text
POSTINIT_WADDR_PROCESS
POSTINIT_REGADDR_PROCESS
POSTINIT_DATA_PROCESS

AUTOINIT_PHASE_RATE_HETEROGENEITY

AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA

R1G_REPLICATE_HOMOGENEITY

BANK_TRACKER_COHERENCE

R7_OPERATION_86_SEMANTICS

FAILED_TRANSACTION_DISTRIBUTION

PAIRED_AB_RESULT
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
v41-nvp-r1g-vhdl-compatibility-and-phase-complete-observability/
```

Include:

```text
verbatim R1g prompt;

R1f evidence identities and terminal report;

exact source recovery proof;

production VHDL-language contract;

complete VHDL-2008 construct inventory;

mechanical rewrite patch and semantics table;

all failed and passing non-synthesis compiler iterations;

R1f-reference versus R1g-candidate equivalence evidence;

final RTL-elaboration preflight;

R1g source commit/tree and manifest;

full build artifacts and DCP/bit hashes;

routed-impact audit;

host tools and fixtures;

bootstrap evidence if used;

all six arm datasets;

raw/decoded 64-entry logs;

autoinit phase counters;

probe aggregate/block/index data;

statistical scripts and results;

operation ledger;

single authoritative Markdown report;

SHA-256 manifest.
```

Create:

```text
V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY_EVIDENCE.zip

V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY_EVIDENCE_SHA256.txt

SHA256_MANIFEST.txt
```

No PDF or DOCX.

One normal evidence commit/push.

No force-push.

No tag or Release.

===================================================================== 22. REQUIRED SINGLE FINAL REPORT BLOCK

The final report must end with:

```text
TASK=
    V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY

EXPERIMENT_NAME=
    R1g

R1F_EVIDENCE_COMMIT=
    1130c4686a7aaedcf2609dd4a5739d7a7eb73fff

R1F_EVIDENCE_PACKAGE_SHA256=
R1F_AUTHORITATIVE_REPORT_SHA256=

R1F_SOURCE_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1F_SOURCE_TREE=
    cfde8769af95cf20586391c411fab3ddfa2c87b6

R1F_TERMINAL_CLASSIFICATION=
    BLOCKED_ONE_CLEAN_BUILD_SYNTHESIS_VHDL_2008_CONSTRUCT

R1F_TERMINAL_FILE=
    rtl/nvp/nvp6134c_i2c_bringup.vhd

R1F_TERMINAL_LINE=
    994

R1F_TERMINAL_CONSTRUCT=
    SEQUENTIAL_CONDITIONAL_SIGNAL_ASSIGNMENT

R1F_TERMINAL_BUILD_LOG_SHA256=
    43C05651BEFA0DB30E00B7B16058D424AFEF38FEA2D0E15A9AF0381604A7E4D0

PRODUCTION_VHDL_STANDARD=
GLOBAL_VHDL_STANDARD_CHANGE=
    NO

VHDL2008_CONSTRUCTS_FOUND=
VHDL2008_CONSTRUCTS_REWRITTEN=
R1G_COMPATIBILITY_REWRITE_FILES=
R1G_COMPATIBILITY_REWRITE_COUNT=

KNOWN_LINE_994_REWRITE=
    PASS_IF_ELSE_EQUIVALENT

R1G_SOURCE_CHANGE_CLASS=
    VHDL_LANGUAGE_COMPATIBILITY_ONLY

R1G_FUNCTIONAL_RTL_CHANGE=
    NO

R1G_DIAGNOSTIC_SEMANTICS_CHANGE=
    NO

R1G_SCIENTIFIC_PARAMETER_CHANGE=
    NO

R1F_TO_R1G_SEMANTIC_DIFFERENCES=
    0

NON_SYNTHESIS_LANGUAGE_COMPILE_ITERATIONS=
EXACT_PRODUCTION_MODE_VHDL_COMPILE=
FINAL_RTL_ELABORATION_PREFLIGHTS=
    1
FINAL_RTL_ELABORATION=
SYNTH_8_2757_COUNT=

R1G_PARENT_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1G_SOURCE_COMMIT=
R1G_SOURCE_TREE=
R1G_BIT_SHA256=
R1G_ROUTED_DCP_SHA256=

FULL_CLEAN_BUILDS=
    1

FULL_SYNTHESIS=
PLACE=
ROUTE=
ROUTE_ERRORS=
WNS=
WHS=
DRC_ERRORS=
DRC_CRITICAL_WARNINGS=
REQP_1839_SEMANTIC_COUNT=
CDC_CRITICAL=
CDC_UNKNOWN=
SOURCE_COMMIT_TO_BIT_PROVENANCE=

SAFE_DATA_PROBE_TARGET=
    PASS_BANK00_REG85_DATA00

R1G_TRANSACTION_INDEX_WIDTH=
    16

R1G_FAILED_TXN_LOG_CAPACITY=
    64

R1G_FAILED_TXN_RECORD_WIDTH=
    192

R1G_PROBE_PHASES=
    WADDR_REGADDR_DATA

R1G_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=
    10000

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
R1G_REPLICATE_HOMOGENEITY=

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
    OWNER_AND_AUDITOR_REVIEW_OF_R1G_RESULTS
```

===================================================================== 23. HARD STOPS

Stop before source edit if:

```text
exact R1f commit/tree cannot be recovered;
R1f evidence identity cannot be proven;
production VHDL-language contract is ambiguous.
```

Stop before source commit if:

```text
a proposed change is not mechanical language compatibility;
global/file VHDL standard changes;
compiler still finds unsupported constructs;
cross-standard equivalence differs;
pre-init equivalence differs;
R1f scoreboards or host fixtures fail.
```

Stop before full build if:

```text
R1g parent is not exact R1f;
more than one child commit exists;
final RTL-elaboration preflight fails;
SYNTH 8-2757 remains;
prebuild manifest/build-command audit fails.
```

Stop before hardware if:

```text
full build/timing/DRC/CDC/provenance fails;
exact R1g bit identity is unavailable;
host-tool fixtures fail;
formal start state cannot be proven;
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
any target opportunity count differs from 10000;
safe target restoration fails;
final DONE fails.
```

No:

```text
VHDL-2008 project switch;
second source commit;
second final preflight;
second clean build;
source patch after build start;
probe-target/count change;
extra pair;
program retry;
physical recovery;
Phase-3 work.
```

===================================================================== 24. BEGIN

```text
save and hash this prompt
    ->
preserve and verify R1f evidence
    ->
recover exact R1f commit/tree
    ->
derive the exact production VHDL-language contract
    ->
inventory every R1f-introduced VHDL construct
    ->
freeze all compatibility rewrites
    ->
mechanically replace line 994 and every other proven incompatible construct
    ->
run exact production-mode non-synthesis compiler iterations
    ->
run full R1f-reference versus R1g-candidate cross-standard equivalence
    ->
rerun complete R1f simulation/scoreboard/host-tool gates
    ->
create one R1g child commit
    ->
run one final production-front-end RTL-elaboration preflight
    ->
create and verify R1g prebuild manifest
    ->
perform one clean provenance-correct build
    ->
run routed-DCP impact audit
    ->
push R1g diagnostic branch after build PASS
    ->
prove fresh exact formal hardware start state
    ->
optional exact formal bootstrap only if required
    ->
run:
        A1 -> B1 -> A2 -> B2 -> A3 -> B3
    ->
perform the frozen R1f statistical analysis
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
No global VHDL-2008 switch.
No second source commit.
No second clean build.
No host MMIO writes.
No DMA.
No Phase 3.
No XDMA work.
