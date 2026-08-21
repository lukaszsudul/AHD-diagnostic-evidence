CODEX MASTER PROMPT

v41 NVP — 25-kHz I²C single-variable diagnostic

One clean build, one paired A/B hardware campaign, exact formal Phase-2 active at end

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_I2C_25KHZ_PAIRED_AB_R1

PRIMARY_PURPOSE:
    Test whether doubling the complete I²C state-tick duration from approximately
    10.016 us to 20.016 us restores reliable NVP6134C initialization and video
    activity in v41.

SCIENTIFIC_VARIABLE:
    top-level generic connection only:

        I2C_HZ:
            50000 -> 25000

PRIMARY_COMPARISON:
    Arm A:
        one newly built exact-Phase-2-derived 25-kHz diagnostic image

    Arm B:
        the exact accepted formal Phase-2 50-kHz image

    Both arms must run in the same hardware session with the same procedure.

BUILD_LIMIT:
    1 clean diagnostic build

HARDWARE_CAMPAIGN_LIMIT:
    1 paired A/B campaign

FINAL_ACTIVE_IMAGE:
    exact formal Phase 2

HARD_STOP_AFTER_PAIR:
    YES
```

===================================================================== 0. CONTROLLING CONTEXT

Current exact control result:

```text
RC-A_CURRENT_HARDWARE=
    PASS_3_OF_3

RC-A_EVERY_RUN=
    INIT_ERROR=0
    NACK_COUNT=0
    TIMEOUT_COUNT=0
    FIRST_ERROR=NONE
    VCLK/SAV/FRAME active
    DONE=1
```

Current formal-v41 failure class:

```text
FORMAL_PHASE2_NVP_FAILURE_REPRODUCED=
    YES

VALID_FAIL_EXAMPLES_INCLUDE=
    INIT_DONE=1
    INIT_ERROR=1
    NACK_COUNT>0
    TIMEOUT_COUNT=0
    VCLK active
    SAV=0
    FRAME=0
```

Latest exact power-breakdown evidence:

```text
EVIDENCE_COMMIT=
    f711325fab4e993bfaf1881626d23c2dac20c8af

POWER_ASSUMPTIONS_COMPARABLE=
    YES

FORMAL_PHASE2_DYNAMIC_POWER_W=
    0.552

RC-A_DYNAMIC_POWER_W=
    0.323

POWER_BREAKDOWN_DECISION_CASE=
    CASE_D_INCONCLUSIVE_REPORT_POWER_LIMITATION

ON_CHIP_SWITCHING_RETURN_PATH_CONTEXT=
    SUPPORTED

PER_BANK_VCCO_14_POWER=
    NOT_EXPOSED_BY_UNMODIFIED_DCP

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_I2C_MARGIN_PROVEN=
    NO
```

The new experiment is motivated by the remaining analog/timing-margin class.

It does not change power rails, I/O properties, placement constraints, clock
source, reset/start timing, table contents, or the I²C state machine.

=====================================================================

1. IMPORTANT SCIENTIFIC INTERPRETATION
=====================================================================

Changing only I2C_HZ is one source-level variable.

Its known consequences are broader than only doubling the nominal SCL bit
period.

It changes every FSM interval expressed in state ticks, including:

```text
LOW/HIGH protocol phases;
START/STOP/ACK dwell;
table-delay tick duration;
NOP tick duration;
final settle tick duration.
```

It does NOT change:

```text
FPGA clock:
    62.5 MHz

local NVP POR:
    320 cycles = 5.12 us

physical R17 LOW interval:
    500 ms

first I²C-start wall-clock delay:
    1.5 s

NVP table;
transaction order;
address;
banking;
register/data bytes;
I²C FSM source;
SDA/SCL filter;
SDA/SCL synchronizers;
released-SCL watchdog wall-clock threshold;
pins;
IOSTANDARD;
DRIVE;
SLEW;
XDMA;
record/capture logic.
```

Therefore call the tested mechanism:

```text
SLOWER_COMPLETE_I2C_TIMING_PROFILE
```

not merely:

```text
one later ACK sample.
```

A PASS strongly supports marginal protocol/settling timing as a contributor.

A FAIL rejects 25 kHz as a sufficient recovery and strongly weakens simple
per-bit timing margin as the sole cause.

A FAIL does NOT prove that only the physical PCB remains.

Still-open classes after a FAIL include:

```text
image-dependent power/ground/switching context;
board-level Vcco or return-path behavior;
analog threshold/rise-time behavior;
implementation sensitivity not reducible to bit duration;
physical assembly.
```

Owner protocol assumption:

```text
I2C_25KHZ_STANDARD_MODE_ACCEPTABLE=
    YES_OWNER_ASSUMPTION
```

If an exact local NVP datasheet is available, verify that it contains no
minimum-SCL or bus-timeout contradiction.

Absence of a local datasheet is not a task blocker; record:

```text
DEVICE_SPECIFIC_MINIMUM_SCL=
    NOT_INDEPENDENTLY_PROVEN
```

and continue under the owner-authorized assumption.

===================================================================== 2. AUTHORITATIVE SOURCE AND HARDWARE IDENTITIES

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
```

Provenance-correct build base:

```text
BASE_BRANCH=
    dev/v41-xdma-offline-next

BASE_COMMIT=
    8464af66611f7c22b8a36a4aab915d598eedda3f

BASE_TREE=
    4bf1988785baf4bae46bdfaf5bb12d0d25f26e68

DIRECT_PARENT=
    c89e88bcdf389614c884fb129e8b2d42a585bccb

BASE_TO_PARENT_FUNCTIONAL_DIFF=
    NONE

BASE_TO_PARENT_ONLY_TRACKED_CHANGE=
    scripts/v41/phase3_build.tcl
```

The base is authorized because the only change above the formal checkpoint is
the already-proven provenance build-script correction.

Exact formal functional source:

```text
FORMAL_FUNCTIONAL_SOURCE_COMMIT=
    fd32fcb65be3f1a59c569874195d1faeaf7d27e9
```

Exact formal Phase-2 bit:

```text
FILENAME=
    ahd_capture_v41_phase2_p1.bit

SIZE=
    2192144

SHA256=
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

Exact current formal top-level setting:

```systemverilog
v40a_nvp_autoinit #(
    .CLK_HZ(NVP_AUTOINIT_CLK_HZ),
    .I2C_HZ(50000),
    .ENABLE_MAREK_INIT_TABLE(ENABLE_MAREK_INIT_TABLE)
) NVP_AUTOINIT (...);
```

Exact NVP clock:

```text
NVP_AUTOINIT_CLK_HZ=
    62500000

NVP_AUTOINIT_CLOCK=
    axi_aclk / autonomous_clk

NVP_POR_CYCLES=
    320
```

Protected NVP blobs:

```text
rtl/nvp/nvp6134c_autoinit.vhd
    5dc0230cd569f03d68452055db6b10c5fcade751

rtl/nvp/nvp6134c_i2c_bringup.vhd
    cfe33464d8e75c514462786593b278d90b4059a4

rtl/nvp/nvp6134c_diagnostics_pkg.vhd
    7ddd60fc86da49cda1adcd7af7b772b337c95df6

xdc/boards/current/nvp_control.xdc
    2e4a6f56d5dfa227a968492fe4476d25721f09f9
```

FPGA/JTAG:

```text
PART=
    xc7a35t

IDCODE=
    0362D093

HS2_SERIAL=
    210241768436
```

Ubuntu DUT:

```text
IP=
    10.132.1.111

USER=
    vcdeagent1

CREDENTIAL_FILE=
    C:\FPGA\VCDE-DUT-1.txt
```

Pinned XDMA source:

```text
8721136e74a66500b02d16cb41922d966139cd46
```

Pinned module:

```text
PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko

SHA256=
    1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
```

Accepted loader:

```text
PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh

SHA256=
    7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F

MODE=
    0644

INVOCATION=
    sudo /usr/bin/bash <loader> <module> <module-sha> <fresh-evidence-dir>
```

Never use:

```text
modprobe xdma
```

because Ubuntu has a same-named in-tree platform driver.

Vivado:

```text
VERSION=
    2025.2 build 6299465

SETTINGS=
    C:\AMDDesignTools\2025.2\settings64.bat

SUPPORTED_LAUNCHER=
    C:\AMDDesignTools\2025.2\Vivado\2025.2\bin\vivado.bat
```

Never call the raw unwrapped\win64.o\vivado.exe.

===================================================================== 3. OWNER AUTHORIZATION AND LIMITS

Authorized offline:

```text
one isolated diagnostic branch and worktree;
one source commit;
one clean diagnostic build;
task-local numerical scripts;
focused simulations;
existing regression replay;
synthesis/place/route/bitstream;
preservation of synth/routed DCP and reports;
one normal diagnostic-branch push;
one evidence-repository commit/push.
```

Authorized hardware:

```text
one paired A/B campaign:

    Arm A:
        one 25-kHz diagnostic SRAM program;
        one wait;
        one Ubuntu warm reboot;
        at most one exact pinned-driver load;
        read-only NVP/video telemetry;
        one final read-only DONE session.

    Arm B:
        one exact formal Phase-2 SRAM program;
        the same wait rule;
        one Ubuntu warm reboot;
        at most one exact pinned-driver load;
        read-only formal identity and NVP/video telemetry;
        one final read-only DONE session.
```

Maximum:

```text
CLEAN_DIAGNOSTIC_BUILDS=
    1

PAIRED_AB_CAMPAIGNS=
    1

FPGA_PROGRAM_INVOCATIONS=
    2

WARM_REBOOTS=
    2

POST_REBOOT_DRIVER_LOADER_INVOCATIONS=
    2
```

One pre-Arm-A driver-loader invocation is permitted only if:

```text
exact formal Phase 2 is already active and proven;
the endpoint exists;
the exact pinned driver is absent;
no reboot or FPGA program is required.
```

Not authorized:

```text
formal bootstrap program;
cold start;
power cycle;
physical action;
JTAG/cable reseat;
programming retry;
third FPGA program;
second diagnostic run;
second build;
source correction after build;
PCIe remove/rescan;
FLR;
bus/bridge reset;
setpci;
driver_override;
module-unload loop;
AXI-Lite write;
NVP/I2C write;
capture-arm write;
C2H/H2C DMA;
NVP table change;
NVP FSM change;
clock-source change;
POR change;
start-delay change;
SDA/SCL filter change;
watchdog change;
pin/XDC change;
IOSTANDARD/DRIVE/SLEW change;
XDMA XCI regeneration;
Phase-3 resume;
XDMA development;
tag;
PR;
merge;
Release.
```

If the required initial exact formal Phase-2 state cannot be proven:

```text
BLOCKED_REQUIRED_FORMAL_START_STATE

FPGA_PROGRAMS=
    0
```

and hard stop.

Every program attempt is consumed when program_hw_devices begins.

No retry after:

```text
EOS LOW;
program error;
DONE != 1.
```

===================================================================== 4. TASK ROOT AND GIT POLICY

Create ASCII-only task root:

```text
C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\
```

Required structure:

```text
00_INPUT_IDENTITY\
01_SOURCE_DIFF\
02_NUMERICAL_GATE\
03_SIMULATION\
04_BUILD\
05_HARDWARE_PRECHECK\
06_ARM_A_25KHZ\
07_ARM_B_FORMAL_50KHZ\
08_COMPARISON\
09_FINAL\
```

Create:

```text
OPERATION_LEDGER.md
TIME_LEDGER.md
```

Diagnostic branch:

```text
diag/v41-nvp-i2c-25khz-r1
```

Create it in an isolated ASCII-path worktree based exactly at:

```text
8464af66611f7c22b8a36a4aab915d598eedda3f
```

Do not check out or mutate the formal worktree.

Allowed final tracked functional diff:

```text
one line in:
    rtl/top/ahd_capture_top_xdma.sv

from:
    .I2C_HZ(50000)

to:
    .I2C_HZ(25000)
```

No generic default is changed.

No protected NVP file is changed.

No XDC, XCI, register-map or capture file is changed.

Focused documentation/test scripts may be task-local and untracked.

If any additional tracked source file changes:

```text
BLOCKED_NOT_SINGLE_SOURCE_VARIABLE
```

The diagnostic source commit must contain exactly the approved one-line
functional diff.

The build must embed that exact commit in runtime GIT_SHA_W0..W4.

Use the already-established provenance flag:

```text
BUILD_FLAGS=
    0x00000002
```

Do not invent a new BUILD_FLAGS meaning.

===================================================================== 5. P0 — EXACT SOURCE FREEZE

Record and verify:

```text
base commit/tree/parent;
clean status;
top-level blob;
build-script blob;
XCI hash;
protected NVP blobs;
NVP pin/control XDC;
register-contract files;
Vivado version;
part.
```

Prove:

```text
base functional RTL/XDC/XCI equals formal Phase-2;
base-to-formal-checkpoint difference is provenance script only;
final functional diff is the one I2C_HZ line only.
```

Create:

```text
00_INPUT_IDENTITY\SOURCE_IDENTITY.md
00_INPUT_IDENTITY\PROTECTED_BLOB_MATRIX.csv
01_SOURCE_DIFF\EXACT_SINGLE_LINE_DIFF.patch
01_SOURCE_DIFF\DIFF_CLASSIFICATION.md
```

===================================================================== 6. P1 — EXACT NUMERICAL GATE

Use the exact source formula:

```vhdl
DIVIDER := CLK_HZ / (I2C_HZ * 2)
```

Current qualified values:

```text
CLK_HZ=
    62500000

I2C_HZ=
    50000

DIVIDER=
    625

TICK_COUNTER_CYCLES=
    626

STATE_TICK_US=
    10.016

PHYSICAL_SCL_PERIOD_US=
    20.032

PHYSICAL_SCL_HZ=
    approximately 49920.1278
```

Required diagnostic values:

```text
CLK_HZ=
    62500000

I2C_HZ=
    25000

DIVIDER=
    1250

TICK_COUNTER_CYCLES=
    1251

STATE_TICK_US=
    20.016

PHYSICAL_SCL_PERIOD_US=
    40.032

PHYSICAL_SCL_HZ=
    approximately 24980.0160
```

Must remain unchanged:

```text
LOCAL_POR_CYCLES=
    320

LOCAL_POR_US=
    5.120

C_RESET_HOLD_CYCLES=
    31250000

PHYSICAL_R17_LOW_SECONDS=
    0.500

C_START_CYCLE=
    93750000

FIRST_I2C_START_SECONDS=
    1.500
```

Also prove unchanged:

```text
released-SCL-low watchdog threshold in wall-clock time;
SDA/SCL synchronizer depth;
SDA/SCL filter depth;
transaction count;
transaction order;
operation bytes;
bank-selection sequence;
NACK-log semantics;
first-error semantics.
```

Generate an exact table for every timing component at 50 and 25 kHz.

Explicitly identify all tick-based intervals that double, including:

```text
transaction phases;
NOP timing;
table-delay timing;
final settle timing.
```

Calculate from exact RTL/table:

```text
TOTAL_AUTOINIT_FROM_FIRST_ACTIVE_CLOCK_50KHZ_US
TOTAL_AUTOINIT_FROM_FIRST_ACTIVE_CLOCK_25KHZ_US

TOTAL_FROM_POR_RELEASE_50KHZ_US
TOTAL_FROM_POR_RELEASE_25KHZ_US

TOTAL_FROM_FIRST_I2C_START_50KHZ_US
TOTAL_FROM_FIRST_I2C_START_25KHZ_US
```

Sanity expectation only:

```text
25-kHz successful total:
    approximately 2.12 s
```

Do not use 2.12 s as the calculation input or exact gate.

The script and cycle-accurate simulation are authoritative.

If script and simulation disagree:

```text
BLOCKED_NUMERICAL_OR_MODEL_CONTRADICTION
```

No build.

Create:

```text
02_NUMERICAL_GATE\I2C_50K_VS_25K_TIMING.csv
02_NUMERICAL_GATE\AUTOINIT_OPERATION_COUNTS.csv
02_NUMERICAL_GATE\NUMERICAL_GATE.md
02_NUMERICAL_GATE\raw_calculation.log
```

===================================================================== 7. P2 — SIMULATION AND FUNCTIONAL-EQUALITY GATE

Run existing unmodified NVP regressions at the formal 50-kHz setting.

Run the same regressions with only:

```text
I2C_HZ=25000
```

Required 25-kHz successful test:

```text
all-ACK sequence completes;
INIT_DONE=1;
INIT_ERROR=0;
NACK_COUNT=0;
TIMEOUT_COUNT=0.
```

Compare 50 versus 25 kHz:

```text
exact same transaction count;
exact same write/read count;
exact same operation order;
exact same address/register/data bytes;
exact same bank sequence;
exact same result/diagnostic semantics;
only timestamps/cycle spacing differ.
```

Run existing fault tests:

```text
address-byte NACK;
register-byte NACK;
data-byte NACK;
read-address NACK;
SDA stuck;
SCL released-low watchdog;
reset/restart behavior.
```

Required:

```text
error classification and step mapping unchanged;
watchdog wall-clock threshold unchanged;
no new retry behavior;
no write-stream change.
```

Create:

```text
03_SIMULATION\SIMULATION_MATRIX.csv
03_SIMULATION\TRANSACTION_STREAM_50K.csv
03_SIMULATION\TRANSACTION_STREAM_25K.csv
03_SIMULATION\TRANSACTION_STREAM_DIFF.md
03_SIMULATION\SIMULATION_GATE.md
raw logs/waveforms.
```

Any functional-stream difference:

```text
BLOCKED_NOT_SINGLE_TIMING_VARIABLE
```

No build.

===================================================================== 8. P3 — CLEAN BUILD AND OFFLINE GATES

Create one clean diagnostic source commit after P0–P2 pass.

Bit filename:

```text
ahd_capture_v41_i2c_25khz_r1.bit
```

Use:

```text
part:
    xc7a35tcsg325-2

top:
    ahd_capture_top_xdma

Vivado:
    2025.2 build 6299465

exact unchanged XDMA XCI;
exact provenance-correct build script.
```

Preserve:

```text
source manifest;
source commit/tree;
single-line diff;
build script and SHA;
XCI copy and SHA;
complete Vivado log/journal;
synth DCP;
routed DCP;
bit;
bit SHA;
timing;
VDO;
DRC;
CDC;
methodology;
route status;
clock reports;
I/O reports;
fan-in/fan-out;
utilization;
power report;
provenance report.
```

Do not delete DCPs.

Required offline gates:

```text
FULL_BUILDS=
    1

SYNTHESIS=
    PASS

PLACE=
    PASS

ROUTE=
    PASS

ROUTE_ERRORS=
    0

WNS>=0
WHS>0
VDO_WNS>0
VDO_WHS>0

DRC_ERRORS=
    0

DRC_CRITICAL_WARNINGS=
    0

CDC_CRITICAL=
    0

CDC_UNKNOWN=
    0

AUTOINIT_CLOCK=
    axi_aclk

AUTOINIT_CLOCK_PERIOD_NS=
    16.000

I2C_HZ_ELABORATED=
    25000

DIVIDER_ELABORATED=
    1250

PHYSICAL_SCL_HZ_CALCULATED=
    approximately 24980.016

LOCAL_POR_UNCHANGED=
    YES

R17_HOLD_UNCHANGED=
    YES

FIRST_START_UNCHANGED=
    YES

NVP_PROTECTED_BLOBS_UNCHANGED=
    YES

XDMA_XCI_UNCHANGED=
    YES

PIN_XDC_UNCHANGED=
    YES

REGISTER_CONTRACT_53_OF_53_UNCHANGED=
    YES

NVP_FUNCTIONAL_DIFF=
    ONLY_TOP_LEVEL_I2C_HZ_GENERIC_50000_TO_25000

SOURCE_COMMIT_TO_BIT_PROVENANCE=
    PASS
```

REQP-1839:

```text
do not fix;
record count;
require no increase over the accepted baseline.
```

If any gate fails:

```text
no hardware action;
no second build;
publish/report blocker;
hard stop.
```

Push the diagnostic branch normally once after all gates pass.

No force-push.

===================================================================== 9. P4 — HARDWARE START-STATE GATE

The task requires exact formal Phase 2 active before Arm A.

Perform fresh read-only discovery:

```text
SSH user/host/kernel/boot ID;
exact JTAG target/IDCODE/DONE;
endpoint identity/count;
Gen1 x1;
BAR0 128 KiB;
BAR1 64 KiB;
driver binding;
loaded xdma modules;
device nodes;
kernel/AER health.
```

Require:

```text
one target:
    HS2 210241768436
    xc7a35t
    0362D093

DONE=
    1

one endpoint:
    10ee:7011
    subsystem 10ee:0007

formal runtime identity:
    A40A0C07 / 0000400B / 00031002

diagnostic magic:
    0
```

If the exact pinned driver is absent but endpoint/formal image are proven:

```text
invoke the accepted loader once through /usr/bin/bash;
no reboot;
no PCIe reset/rescan.
```

Reject a wrong same-name xdma module.

Require:

```text
no process has an XDMA node open;
zero DMA activity;
no stale Vivado/hw_server ownership.
```

If exact formal Phase 2 is not proven:

```text
BLOCKED_REQUIRED_FORMAL_START_STATE
```

No bootstrap is authorized in this task.

Do not count any precheck telemetry as Arm B.

===================================================================== 10. ARM A — 25-kHz DIAGNOSTIC IMAGE

Immediately before programming:

```text
rehash diagnostic bit;
verify exact source commit/tree;
verify expected runtime GIT words;
verify operation ledger;
open a fresh supported Hardware Manager session.
```

Program exactly once.

Require:

```text
EOS=HIGH
DONE=1
```

No retry.

Record:

```text
PROGRAM_START_UTC
PROGRAM_END_UTC
fresh DONE timestamp
bit path/hash
target identity.
```

Wait using a monotonic Windows stopwatch:

```text
WAIT_REFERENCE=
    later of program completion and fresh DONE=1

ACTUAL_WAIT_SECONDS>=5.000000
```

Then:

```text
one Ubuntu warm reboot;
host disappearance and return;
new boot ID;
exact pinned-driver loader at most once through /usr/bin/bash.
```

Require:

```text
endpoint/link/BARs;
exact driver and nodes;
kernel/AER health;
runtime GIT_SHA exact diagnostic source commit;
BUILD_FLAGS=0x00000002;
common identity A40A0C07 / 0000400B / 00031002;
DONE=1.
```

Collect T0 and T1 approximately one second apart.

Read only:

```text
INIT_BUSY
INIT_DONE
INIT_ERROR
NACK_COUNT
TIMEOUT_COUNT
FIRST_ERROR tuple
ORIGINAL_FF
RESTORED_FF
VCLK
SAV
FRAME
reset/power/SCL/SDA status
full available NACK log.
```

Static fields must match between T0/T1.

Normalize using the exact timestamp interval:

```text
VCLK_HZ
SAV_RATE
FRAME_RATE
```

Fresh final read-only JTAG DONE required.

Arm-A PASS:

```text
infrastructure valid;
runtime provenance exact;
INIT_DONE=1;
INIT_ERROR=0;
NACK_COUNT=0;
TIMEOUT_COUNT=0;
VCLK_HZ in established normal range;
SAV_RATE>0;
FRAME_RATE consistent with approximately 25 Hz;
DONE=1.
```

Arm-A valid functional FAIL:

```text
infrastructure/provenance valid;
any functional criterion fails.
```

No second diagnostic run.

===================================================================== 11. ARM B — EXACT FORMAL 50-kHz CONTROL AND FINAL RESTORE

Arm B is both:

```text
the interleaved formal control;
the mandatory final restoration.
```

Rehash exact formal bit:

```text
7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
```

Open a fresh supported Hardware Manager session.

Program exactly once.

Require:

```text
EOS=HIGH
DONE=1
```

No retry.

Use the same wait rule:

```text
ACTUAL_WAIT_SECONDS>=5.000000
```

Then:

```text
one Ubuntu warm reboot;
host disappearance and return;
new boot ID;
exact pinned-driver loader at most once.
```

Require:

```text
endpoint 10ee:7011 / 10ee:0007;
Gen1 x1;
BAR0 128 KiB;
BAR1 64 KiB;
exact driver/nodes;
BLOCK_ID=0xA40A0C07;
PROTOCOL=0x0000400B;
CAPABILITIES=0x00031002;
DIAGNOSTIC_MAGIC=0;
kernel/AER health;
DONE=1.
```

Run the exact same T0/T1 read-only NVP/video procedure as Arm A.

Normalize rates using actual timestamps.

Fresh final JTAG DONE required.

At task end:

```text
FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_PINNED_DRIVER_LOADED=
    YES
```

===================================================================== 12. PAIRED A/B CLASSIFICATION

Use only the new interleaved pair.

Historical formal failures are context, not Arm B.

────────

CASE 1 — A PASS / B FAIL

```text
PAIRED_AB_RESULT=
    A_PASS_B_FAIL

I2C_25KHZ_DIAGNOSTIC=
    PASS_R1

SLOWER_COMPLETE_I2C_TIMING_PROFILE=
    STRONGLY_SUPPORTED_AS_RECOVERY

MARGINAL_PROTOCOL_OR_SETTLING_TIMING=
    STRONGLY_SUPPORTED_AS_CONTRIBUTOR

ROOT_CAUSE_SOLELY_PROVEN=
    NO

READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW=
    YES

READY_TO_RETURN_TO_XDMA=
    AFTER_OWNER_AUTHORIZES_PHASE3_INTEGRATION_BUILD_AND_NVP_REVALIDATION
```

Do not resume Phase 3 or XDMA inside this task.

────────

CASE 2 — A FAIL / B FAIL

```text
PAIRED_AB_RESULT=
    A_FAIL_B_FAIL

I2C_25KHZ_DIAGNOSTIC=
    FAIL_R1

SLOWER_COMPLETE_I2C_TIMING_PROFILE=
    NOT_SUFFICIENT

SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE=
    STRONGLY_WEAKENED

REMAINING_LEADING_CLASSES=
    IMAGE_DEPENDENT_POWER_GROUND_SWITCHING_CONTEXT
    BOARD_OR_ANALOG_I2C_MARGIN
    IMPLEMENTATION_SENSITIVITY
    PHYSICAL_ASSEMBLY

READY_TO_RETURN_TO_XDMA=
    NO
```

Do not state:

```text
only the PCB remains.
```

────────

CASE 3 — A PASS / B PASS

```text
PAIRED_AB_RESULT=
    A_PASS_B_PASS

CLASSIFICATION=
    NON_DISCRIMINATING_FORMAL_CONTROL_DID_NOT_REPRODUCE

READY_TO_RETURN_TO_XDMA=
    NO
```

No timing-margin claim.

────────

CASE 4 — A FAIL / B PASS

```text
PAIRED_AB_RESULT=
    A_FAIL_B_PASS

CLASSIFICATION=
    CONTRADICTORY_DIAGNOSTIC_WORSE_THAN_FORMAL

READY_TO_RETURN_TO_XDMA=
    NO
```

Hard stop for review.

────────

CASE 5 — PARTIAL EFFECT

Examples:

```text
A NACK count lower than B but still >0;
A INIT_ERROR=0/NACK=0 but SAV or FRAME remains zero;
A first-error moves materially but functional PASS is absent.
```

Classify:

```text
PAIRED_AB_RESULT=
    PARTIAL_OR_MIXED_EFFECT_SINGLE_SAMPLE

I2C_25KHZ_DIAGNOSTIC=
    NOT_A_FULL_PASS

READY_TO_RETURN_TO_XDMA=
    NO
```

Report exact data.

No automatic second run or source change.

────────

CASE 6 — INFRASTRUCTURE INVALID

```text
PAIRED_AB_RESULT=
    INCONCLUSIVE_INFRASTRUCTURE
```

No scientific inference.

If Arm A programmed successfully and safe formal restoration remains possible,
Arm B may still execute only as the authorized restoration.

===================================================================== 13. EVIDENCE AND ARTIFACT PRESERVATION

Diagnostic repository branch:

```text
diag/v41-nvp-i2c-25khz-r1
```

Evidence repository:

```text
lukaszsudul/AHD-diagnostic-evidence
```

Preferred path:

```text
v41-nvp-i2c-25khz-paired-ab-r1/
```

Include:

```text
owner experiment statement;
power-breakdown input context;
this prompt;
source/base identities;
single-line diff;
numerical scripts/results;
50-kHz versus 25-kHz timing table;
transaction-stream equality proof;
simulation logs/waveforms;
build script and SHA;
source commit/tree;
XCI identity;
synth/routed DCP hashes;
bit/hash;
full Vivado logs/reports;
Arm-A raw program/reboot/driver/telemetry logs;
Arm-B raw program/reboot/driver/telemetry logs;
A/B comparison;
operation ledger;
final Markdown report;
SHA-256 manifest.
```

Preserve bit and DCP package in ZIP/LFS according to existing evidence policy.

No PDF or DOCX.

One normal evidence commit/push.

No force-push.

No tag.

No Release.

If publication fails:

```text
preserve a sealed local package;
report exact blocker;
do not retry via an unsafe channel.
```

===================================================================== 14. FINAL REPORT

Create:

```text
09_FINAL\
    V41_NVP_I2C_25KHZ_PAIRED_AB_R1_REPORT.md
```

Required final block:

```text
TASK=
    V41_NVP_I2C_25KHZ_PAIRED_AB_R1

TASK_TYPE=
    ONE_BUILD_ONE_PAIRED_AB_CAMPAIGN

POWER_CONTEXT_EVIDENCE_COMMIT=
    f711325fab4e993bfaf1881626d23c2dac20c8af

BASE_COMMIT=
    8464af66611f7c22b8a36a4aab915d598eedda3f

BASE_DIRECT_PARENT=
    c89e88bcdf389614c884fb129e8b2d42a585bccb

DIAGNOSTIC_BRANCH=
    diag/v41-nvp-i2c-25khz-r1

DIAGNOSTIC_SOURCE_COMMIT=
DIAGNOSTIC_SOURCE_TREE=

TRACKED_FUNCTIONAL_DIFF_COUNT=
    1

TRACKED_FUNCTIONAL_DIFF=
    rtl/top/ahd_capture_top_xdma.sv_I2C_HZ_50000_TO_25000

PROTECTED_NVP_BLOBS_UNCHANGED=
XDMA_XCI_UNCHANGED=
PIN_XDC_UNCHANGED=
REGISTER_CONTRACT_UNCHANGED=

CLK_HZ=
    62500000

FORMAL_I2C_HZ=
    50000

DIAGNOSTIC_I2C_HZ=
    25000

FORMAL_DIVIDER=
    625

DIAGNOSTIC_DIVIDER=
    1250

FORMAL_TICK_US=
    10.016

DIAGNOSTIC_TICK_US=
    20.016

FORMAL_SCL_HZ=
    approximately 49920.1278

DIAGNOSTIC_SCL_HZ=
    approximately 24980.0160

LOCAL_POR_US=
    5.120

R17_LOW_SECONDS=
    0.500

FIRST_I2C_START_SECONDS=
    1.500

FORMAL_FULL_AUTOINIT_US=
DIAGNOSTIC_FULL_AUTOINIT_US=
AUTOINIT_SCRIPT_SIMULATION_MATCH=

SCL_RELEASED_LOW_WATCHDOG_UNCHANGED=
TRANSACTION_STREAM_BYTE_IDENTICAL=
OPERATION_ORDER_IDENTICAL=

FULL_BUILD=
FULL_BUILD_WNS=
FULL_BUILD_WHS=
FULL_BUILD_VDO_WNS=
FULL_BUILD_VDO_WHS=
FULL_BUILD_DRC_ERRORS=
FULL_BUILD_DRC_CRITICAL_WARNINGS=
FULL_BUILD_CDC_CRITICAL=
FULL_BUILD_CDC_UNKNOWN=
FULL_BUILD_REQP_1839_COUNT=

DIAGNOSTIC_BIT_SHA256=
DIAGNOSTIC_RUNTIME_GIT_SHA=
DIAGNOSTIC_RUNTIME_BUILD_FLAGS=

ARM_A_PROGRAM=
ARM_A_EOS=
ARM_A_DONE=
ARM_A_WAIT_SECONDS=
ARM_A_BOOT_ID_CHANGED=
ARM_A_DRIVER=
ARM_A_INIT_DONE=
ARM_A_INIT_ERROR=
ARM_A_NACK_COUNT=
ARM_A_TIMEOUT_COUNT=
ARM_A_FIRST_ERROR=
ARM_A_VCLK_HZ=
ARM_A_SAV_RATE=
ARM_A_FRAME_RATE=
ARM_A_RESULT=

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

ARM_B_PROGRAM=
ARM_B_EOS=
ARM_B_DONE=
ARM_B_WAIT_SECONDS=
ARM_B_BOOT_ID_CHANGED=
ARM_B_DRIVER=
ARM_B_FORMAL_IDENTITY=
ARM_B_DIAGNOSTIC_MAGIC=
ARM_B_INIT_DONE=
ARM_B_INIT_ERROR=
ARM_B_NACK_COUNT=
ARM_B_TIMEOUT_COUNT=
ARM_B_FIRST_ERROR=
ARM_B_VCLK_HZ=
ARM_B_SAV_RATE=
ARM_B_FRAME_RATE=
ARM_B_RESULT=

PAIRED_AB_RESULT=
I2C_25KHZ_DIAGNOSTIC=
SLOWER_COMPLETE_I2C_TIMING_PROFILE=
SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE=
ROOT_CAUSE_SOLELY_PROVEN=
READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW=
READY_TO_RETURN_TO_XDMA=
NEXT_ACTION=

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
FINAL_DIAGNOSTIC_MAGIC=
FINAL_PINNED_DRIVER_LOADED=
FINAL_DONE=

CLEAN_DIAGNOSTIC_BUILDS=
    1

PAIRED_AB_CAMPAIGNS=
    1

FPGA_PROGRAM_INVOCATIONS=
    2

WARM_REBOOTS=
    2

POST_REBOOT_DRIVER_LOADER_INVOCATIONS=
    2

COLD_STARTS=
    0

PHYSICAL_ACTIONS=
    0

PROGRAM_RETRIES=
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

TAGS=
    0

RELEASES=
    0

FORMAL_BRANCH_MUTATIONS=
    0

EVIDENCE_REPOSITORY_COMMIT=
EVIDENCE_PACKAGE_SHA256=
```

===================================================================== 15. HARD STOPS

Stop before build if:

```text
source base/provenance is not exact;
diff contains more than the one allowed generic connection;
protected NVP blob changes;
numerical script and simulation disagree;
transaction stream differs;
watchdog behavior changes;
register contract changes.
```

Stop before hardware if:

```text
build/timing/DRC/CDC/provenance fails;
exact diagnostic bit identity unavailable;
exact formal start state not proven;
wrong JTAG target;
wrong endpoint;
wrong same-name XDMA module loaded or bound;
kernel/AER critical condition.
```

Stop during hardware if:

```text
EOS LOW;
program error;
DONE != 1;
host does not return;
driver cannot load once;
runtime provenance mismatch;
telemetry static fields are incoherent;
formal identity mismatch;
operation ledger exceeds limits.
```

Do not resolve a blocker through:

```text
second build;
source patch;
program retry;
physical action;
PCIe reset/rescan;
new timing value;
another diagnostic run;
Phase-3 work.
```

===================================================================== 16. BEGIN

```text
freeze exact source and identities
    ->
apply exactly one I2C_HZ generic change
    ->
calculate exact 50-kHz and 25-kHz timing
    ->
prove reset/start/watchdog unchanged
    ->
run equal transaction-stream simulations
    ->
create one diagnostic source commit
    ->
perform one clean build and all offline gates
    ->
push diagnostic branch
    ->
prove exact formal Phase-2 start state
    ->
Arm A: one 25-kHz program/wait/reboot/read
    ->
Arm B: one exact formal 50-kHz program/same wait/reboot/read
    ->
classify paired A/B
    ->
leave exact formal Phase 2 active
    ->
publish evidence
    ->
HARD STOP.
```

Do not resume Phase 3.
Do not continue XDMA in this task.

```
```