CODEX MASTER PROMPT

v41 NVP R1e — formal bootstrap recovery and complete paired A/B campaign R4

Reuse the exact completed R1e bitstream; no build, no FPGA-source change

Optional one-time formal bootstrap → Arm A R1e → full Arm B formal control

One authoritative final report; full owner pre-authorization

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_R1E_FORMAL_BOOTSTRAP_RECOVERY_AND_COMPLETE_PAIRED_AB_R4

TASK_CHARACTER:
    HARDWARE_COMPLETION_OF_THE_EXISTING_R1E_EXPERIMENT

PRIMARY_PURPOSE:
    Establish a known exact formal Phase-2 start state after R3 found the
    current SRAM image unproven, then obtain the complete R1e Arm-A and exact
    formal Arm-B scientific samples.

R1E_BUILD_STATUS:
    COMPLETE_AND_FROZEN

R1E_BITSTREAM_STATUS:
    AVAILABLE_AND_FROZEN

R1E_HARDWARE_STATUS:
    NOT_YET_RUN

R4_STRATEGY:

    1. Preserve R3 unchanged.

    2. Perform one fresh read-only start-state discovery.

    3. If exact formal Phase 2 is already proven:
           skip bootstrap.

       If the current image remains unproven but the exact JTAG target is safe:
           perform exactly one exact formal Phase-2 bootstrap;
           wait;
           perform exactly one warm reboot;
           load the exact pinned XDMA driver once;
           prove formal runtime identity, BAR access and DONE.

    4. Run Arm A using the exact existing R1e bit.

    5. Run Arm B as a full exact formal Phase-2 functional control and final
       restoration.

    6. Publish one authoritative final R1e report.

FULL_BUILDS_THIS_TASK:
    0

SYNTHESIS_RUNS_THIS_TASK:
    0

IMPLEMENTATION_RUNS_THIS_TASK:
    0

BITSTREAM_GENERATION_THIS_TASK:
    0

FPGA_SOURCE_CHANGES_THIS_TASK:
    0

FORMAL_BOOTSTRAP_PROGRAMS_MAX:
    1

ARM_A_PROGRAMS_MAX:
    1

ARM_B_PROGRAMS_MAX:
    1

FPGA_PROGRAM_INVOCATIONS_MAX:
    3

WARM_REBOOTS_MAX:
    3

POST_REBOOT_DRIVER_LOADS_MAX:
    3

PROGRAM_RETRIES:
    0

FINAL_ACTIVE_IMAGE:
    EXACT_FORMAL_PHASE2
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

The owner grants advance approval for every action explicitly authorized by
this prompt.

Do not pause to ask the owner to approve:

```text
task-root creation;
read-only host/JTAG/PCIe discovery;
the conditional one-time formal bootstrap;
the bootstrap warm reboot;
the bootstrap exact pinned-driver load;
the Arm-A R1e program/reboot/driver load;
the Arm-B formal program/reboot/driver load;
all authorized read-only BAR and telemetry accesses;
evidence sealing;
one normal evidence commit/push;
public remote verification.
```

A passing gate means continue automatically.

A failed or blocked gate means:

```text
preserve all available evidence;
write the one authoritative final report;
publish safely available evidence;
hard-stop without asking whether to continue.
```

This authorization does not permit any action outside the exact scope or above
the numerical limits.

===================================================================== 0. AUTHORITATIVE R3 RESULT

R3 evidence:

```text
EVIDENCE_REPOSITORY=
    lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT=
    f1bf9ed648dc0749fbd2de2ddae38a42917fee9b

EVIDENCE_PACKAGE_SHA256=
    F6D57CCFD2CF4A7754F9562FDA2BE6BA877A95E2F0E5A4CBAAA0601D32A96782
```

Exact R3 bitstream result:

```text
R1E_BIT_FILENAME=
    ahd_capture_v41_i2c_25khz_r1e_observability.bit

R1E_BIT_SIZE_BYTES=
    2192144

R1E_BIT_SHA256=
    0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9

R1E_SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1E_SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1E_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1
```

R3 offline gates:

```text
SEMANTIC_REQP_1839_GATE=
    PASS_4_VIOLATIONS

REPORT_PROPERTY_HANDLING=
    PASS_TWO_OBJECT_DETERMINISTIC_PER_OBJECT

ROUTED_NETS=
    26488_OF_26488

ROUTE_ERRORS=
    0

WNS_NS=
    +0.617

WHS_NS=
    +0.021

DRC_ERRORS=
    0

DRC_CRITICAL_WARNINGS=
    0

R1E_BITSTREAM_GENERATION=
    PASS
```

R3 fresh precheck:

```text
JTAG_TARGET=
    PASS_EXACT_HS2_PART_IDCODE

JTAG_DONE=
    1

KERNEL=
    7.0.0-29-generic

ENDPOINT=
    PASS_10EE_7011_SUBSYSTEM_0007_CLASS_058000

LINK=
    Gen1_x1

BAR_GEOMETRY=
    PASS_128K_64K

XDMA_NODES=
    EXPECTED_21_PRESENT

XDMA_NODE_OWNERS=
    0

FORMAL_RUNTIME_IDENTITY=
    FAIL

EXPECTED_BLOCK_ID=
    0xA40A0C07

RAW_TASK_READER_BLOCK_ID=
    0xFFFFFFFF

ACCEPTED_XDMA_AXIL_READER_BLOCK_ID=
    0xFFFFFFFF

BOOT_CONTINUITY=
    DIFFERENT_FROM_RETAINED_FORMAL_CLOSURE
```

R3 hard stop:

```text
CLASSIFICATION=
    BLOCKED_REQUIRED_FORMAL_START_STATE

FPGA_PROGRAMS=
    0

WARM_REBOOTS=
    0

DRIVER_LOADS=
    0

CURRENT_SRAM_IMAGE=
    UNPROVEN_NOT_MODIFIED_BY_R3
```

Scientific status:

```text
R1E_ARM_A_SAMPLE=
    NOT_RUN

R1E_ARM_B_SAMPLE=
    NOT_RUN

PAIRED_AB_RESULT=
    NOT_EVALUATED_NO_HARDWARE_CAMPAIGN
```

R4 must preserve R3 exactly as historical evidence.

R4 does not reinterpret 0xFFFFFFFF as a valid image identity.

=====================================================================

1. FROZEN R1E SCIENTIFIC CONFIGURATION
=====================================================================

R1e source and implementation are immutable.

```text
AUTOINIT_I2C_HZ=
    25000

AUTOINIT_CLOCK_HZ=
    62500000

ACTIVE_TICK_CYCLES=
    1251

EXPECTED_CNT_AT_INIT_DONE=
    132584734

PROBE_CLASS=
    ACTIVE_NON_REGISTER_WRITING_POST_AUTOINIT_DIAGNOSTIC

PROBE_ADDRESS_BYTE=
    0x60

PROBE_I2C_HZ=
    25000

PROBE_TARGET_COUNT=
    10000

ARM_A_REQUIRED_WAIT_SECONDS=
    10.000000
```

Ordered NACK window:

```text
HEADER_OFFSET=
    0x10098

DATA_START=
    0x1009C

DATA_END=
    0x100D8

CAPACITY=
    8_ORDERED_RECORDS

OVERFLOW_MEANING=
    FIRST_8_RECORDS_ONLY
```

Lifecycle/R1e page:

```text
PAGE_START=
    0x2000

REQUIRED_END=
    0x2094

LIFECYCLE_MAGIC=
    0x314B4C43
```

No scientific parameter may change in R4.

===================================================================== 2. EXACT FORMAL BOOTSTRAP AND CONTROL

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

Exact formal bit:

```text
FILENAME=
    ahd_capture_v41_phase2_p1.bit

SIZE_BYTES=
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

The optional bootstrap is:

```text
a start-state recovery operation;

not Arm B;

not a scientific paired control;

not counted as a repeat of the formal Arm-B sample.
```

Arm B must still run fully after Arm A.

===================================================================== 3. HOST, DRIVER, AND TOOL IDENTITIES

FPGA/JTAG:

```text
HS2_SERIAL=
    210241768436

PART=
    xc7a35t

IDCODE=
    0362D093
```

Ubuntu DUT:

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

PuTTY/Plink:

```text
VERSION=
    0.84

SHA256=
    E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915

REQUIRED_OPTIONS=
    -pwfile
    -batch
    -hostkey
    -noagent
    -noshare

FORBIDDEN=
    -pw
```

Pinned XDMA source:

```text
8721136e74a66500b02d16cb41922d966139cd46
```

Exact pinned module:

```text
ABSOLUTE_PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko

SHA256=
    1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A

VERSION=
    2025.2.0

VERMAGIC_PREFIX=
    7.0.0-29-generic
```

Exact accepted loader:

```text
ABSOLUTE_PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh

SHA256=
    7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F

MODE=
    0644
```

Required loader invocation:

```bash
sudo -S -k -p '' /usr/bin/bash \
  /home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh \
  /home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko \
  1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A \
  <fresh-absolute-evidence-directory>
```

Never use:

```text
modprobe xdma;
a relative module path;
modinfo-selected alternate path;
another kernel module;
PCIe remove/rescan;
driver_override.
```

Reuse exact passed R3 host tools and programming observer from the R3 evidence
manifest.

Do not rewrite them unless an exact hash mismatch is found—in that case hard
stop.

===================================================================== 4. AUTHORIZATION AND ABSOLUTE LIMITS

Authorized task-local work:

```text
preserve and verify R3 evidence;
locate and rehash the exact R1e and formal bits;
run host-tool fixtures;
run one fresh read-only start-state discovery;
conditionally execute one exact formal bootstrap;
execute Arm A;
execute full Arm B;
create and publish one final report/evidence package.
```

Authorized hardware transitions:

```text
Bootstrap, conditional:
    exact formal program once;
    wait >=5 seconds;
    one warm reboot;
    exact driver load once;
    formal identity/DONE verification.

Arm A:
    exact R1e program once;
    wait >=10 seconds;
    one warm reboot;
    exact driver load once;
    full R1e telemetry;
    final DONE.

Arm B:
    exact formal program once;
    wait >=5 seconds;
    one warm reboot;
    exact driver load once;
    full functional control telemetry;
    final DONE.
```

Maximum:

```text
FORMAL_BOOTSTRAP_PROGRAMS<=1

ARM_A_PROGRAMS<=1

ARM_B_PROGRAMS<=1

FPGA_PROGRAM_INVOCATIONS<=3

WARM_REBOOTS<=3

POST_REBOOT_DRIVER_LOADS<=3

PROGRAM_RETRIES=0
```

Not authorized:

```text
build;
synthesis;
place;
route;
write_bitstream;
FPGA source edit;
new FPGA source commit;
DCP modification;
second bootstrap;
second Arm-A sample;
second Arm-B sample;
fourth FPGA program;
cold start;
power cycle;
physical action;
JTAG/cable reseat;
kernel or GRUB change;
module rebuild;
PCIe reset/rescan;
AXI-Lite write;
NVP/I2C write;
DMA;
Phase 3;
XDMA development;
tag;
Release.
```

===================================================================== 5. TASK ROOT AND EVIDENCE POLICY

Create:

```text
C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4\
```

Required structure:

```text
00_R3_INPUT\
01_ARTIFACT_IDENTITY\
02_HOST_TOOL_PREFLIGHT\
03_START_STATE_DISCOVERY\
04_FORMAL_BOOTSTRAP\
05_ARM_A_R1E\
06_ARM_B_FORMAL\
07_ANALYSIS\
08_FINAL\
scripts\
fixtures\
```

Create immediately:

```text
OPERATION_LEDGER.md
TIME_LEDGER.md
```

Save this prompt verbatim and record its SHA-256 before any hardware command.

Initial operation accounting:

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS=0
FORMAL_REPOSITORY_MUTATIONS=0
```

────────

5.1 One authoritative final report

Create exactly one authoritative final R1e report:

```text
V41_NVP_R1E_EXTENDED_OBSERVABILITY_FINAL_REPORT.md
```

It must integrate:

```text
the frozen source/build history;
R1/R2/R3 infrastructure boundaries;
the exact R1e bit;
R4 start-state recovery;
optional bootstrap;
Arm A;
full Arm B;
lifecycle/log/probe analysis;
final formal state;
complete accounting.
```

Do not create a competing second “final report”.

Earlier reports remain preserved by Git history and under historical evidence.

────────

5.2 Reporting of unrelated pre-task handling

The final scientific report must discuss only fresh R4 gates and events that
affected the executed scientific samples.

Do not discuss unrelated pre-task human handling that did not alter the exact
source, bitstream or measured sample.

Do not delete or rewrite raw evidence.

Report only the fresh live R4 JTAG result.

===================================================================== 6. P0 — R3 EVIDENCE AND BIT IDENTITY

Verify:

```text
R3_EVIDENCE_COMMIT=
    f1bf9ed648dc0749fbd2de2ddae38a42917fee9b

R3_EVIDENCE_PACKAGE_SHA256=
    F6D57CCFD2CF4A7754F9562FDA2BE6BA877A95E2F0E5A4CBAAA0601D32A96782
```

Locate the exact R1e bit only in bounded known locations:

```text
the R3 task root;
the R3 evidence package;
the public R3 evidence path.
```

Do not scan the entire drive.

Require:

```text
R1E_BIT_FILENAME=
    ahd_capture_v41_i2c_25khz_r1e_observability.bit

R1E_BIT_SIZE_BYTES=
    2192144

R1E_BIT_SHA256=
    0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9

R1E_SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1E_SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1E_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1
```

Rehash the exact formal bit.

Create:

```text
01_ARTIFACT_IDENTITY\ARTIFACT_IDENTITY.md
01_ARTIFACT_IDENTITY\ARTIFACT_SHA256.txt
01_ARTIFACT_IDENTITY\NO_BUILD_NO_SOURCE_CHANGE_PROOF.md
```

Any mismatch:

```text
BLOCKED_EXACT_ARTIFACT_IDENTITY
```

with zero programs.

===================================================================== 7. P1 — HOST TOOL AND INFRASTRUCTURE FIXTURE GATE

Recover exact accepted R3 tools from the R3 evidence manifest:

```text
programming observer;
Python BAR parser;
accepted AXI-Lite reader;
R1e full reader/decoder;
ordered-log decoder;
lifecycle calculator;
probe statistics calculator.
```

Require exact hash equality with the R3 manifest.

Run all no-hardware fixtures:

```text
programming transcript parser;
BAR0=131072/BAR1=65536 parser;
0xFFFFFFFF identity rejection;
formal identity acceptance;
lifecycle coherent read;
expected count=132584734;
ordered-log count/overflow rules;
probe invariant rules;
Wilson interval;
zero-NACK upper bound;
formal R1e-page-zero rule.
```

Required:

```text
HOST_TOOL_HASH_GATE=
    PASS

HOST_TOOL_FIXTURES=
    PASS_ALL

ALL_ONES_IDENTITY_ACCEPTED=
    NO
```

Any failure:

```text
BLOCKED_HOST_TOOL_PREFLIGHT
```

with zero programs.

===================================================================== 8. P2 — FRESH READ-ONLY START-STATE DISCOVERY

Run exactly one fresh discovery sequence.

Read only:

```text
current UTC;
hostname/user;
kernel;
boot ID;
uptime start;
next-boot kernel proof;

JTAG:
    target count;
    HS2;
    part;
    IDCODE;
    DONE;

PCIe:
    endpoint count;
    vendor/device/subsystem/class;
    BDF;
    link;
    raw resource table;
    corrected BAR geometry;

driver:
    loaded modules named xdma;
    exact module version/vermagic/hash;
    BDF binding;
    expected nodes;
    node owners;

kernel/AER health;

runtime:
    raw task reader BLOCK_ID;
    exact accepted reader BLOCK_ID;
    PROTOCOL;
    CAPABILITIES;
    DIAGNOSTIC_MAGIC when readable.
```

Required safety gates:

```text
one exact JTAG target;
DONE=1;
kernel=7.0.0-29-generic;
next reboot remains kernel 29;
zero or one expected 10ee:7011 endpoint;
no wrong or multiple FPGA endpoint;
no wrong same-name xdma module;
no XDMA node owner;
zero DMA;
no fatal kernel/AER issue;
exact formal bit available.
```

────────

8.1 Start-state classification

Use exactly one:

A. Formal state already proven

```text
START_STATE_CLASSIFICATION=
    FORMAL_PHASE2_ALREADY_PROVEN

Requirements:
    expected endpoint/link/BARs;
    exact accepted driver path and binding;
    raw and accepted readers both return:
        BLOCK_ID=0xA40A0C07
        PROTOCOL=0x0000400B
        CAPABILITIES=0x00031002
        DIAGNOSTIC_MAGIC=0;
    DONE=1.
```

Then:

```text
FORMAL_BOOTSTRAP_RUN=
    NO

proceed directly to Arm A.
```

B. Formal state not proven, bootstrap is safe

```text
START_STATE_CLASSIFICATION=
    REQUIRES_EXACT_FORMAL_BOOTSTRAP
```

Allowed examples:

```text
reader returns 0xFFFFFFFF;
reader returns another non-formal identity;
expected endpoint is absent;
driver/nodes are absent;
current image is otherwise unknown;
boot continuity differs.
```

Requirements:

```text
exact JTAG target safe;
formal bit exact;
no foreign/multiple endpoint;
no node owner;
zero DMA;
no fatal kernel/AER issue;
one bootstrap program remains authorized.
```

Proceed to Section 9.

C. Unsafe or contradictory state

```text
START_STATE_CLASSIFICATION=
    BLOCKED_UNSAFE_OR_CONTRADICTORY_START_STATE
```

Examples:

```text
wrong/multiple JTAG target;
wrong/multiple foreign endpoint;
wrong xdma module loaded/bound;
node owner;
critical kernel/AER issue;
exact formal bit unavailable;
operation ledger contradiction.
```

Hard stop without programming.

Do not treat 0xFFFFFFFF as formal identity.

Do not require historical boot-ID continuity once bootstrap is selected.

===================================================================== 9. P3 — CONDITIONAL EXACT FORMAL BOOTSTRAP

Run only when:

```text
START_STATE_CLASSIFICATION=
    REQUIRES_EXACT_FORMAL_BOOTSTRAP
```

This is a separately authorized start-state recovery operation.

It is not Arm B.

Before programming:

```text
rehash formal bit;
verify exact JTAG target;
verify no node owner;
verify zero DMA;
verify operation ledger.
```

Program exact formal Phase 2 once through the accepted programming observer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Wait:

```text
>=5.000000 seconds
```

from the later accepted same-QPC program-return/fresh-DONE marker.

Perform exactly one warm reboot.

Require:

```text
host disappears;
host returns;
new boot ID;
kernel=7.0.0-29-generic.
```

Before loader:

```text
one expected endpoint;
Gen1 x1;
BAR0=131072;
BAR1=65536;
endpoint unbound;
no loaded wrong xdma;
no node owner.
```

Invoke exact loader once with fresh directory:

```text
/home/vcdeagent1/FPGA_AHD_HOST/
v41_nvp_r1e_r4/bootstrap_driver
```

Require:

```text
loader exit=0;
exact module hash/version/vermagic;
expected node set;
BDF bound to exact driver;
kernel/AER health PASS.
```

Verify with both readers:

```text
BLOCK_ID=0xA40A0C07
PROTOCOL=0x0000400B
CAPABILITIES=0x00031002
DIAGNOSTIC_MAGIC=0
```

Read fresh final bootstrap JTAG:

```text
DONE=1
```

Required:

```text
FORMAL_BOOTSTRAP_RESULT=
    PASS_FORMAL_READY

FORMAL_BOOTSTRAP_PROGRAMS=
    1

FORMAL_BOOTSTRAP_WARM_REBOOTS=
    1

FORMAL_BOOTSTRAP_DRIVER_LOADS=
    1
```

If bootstrap cannot prove formal runtime identity:

```text
BLOCKED_FORMAL_BOOTSTRAP_IDENTITY_OR_ACCESS
```

Hard stop.

No second bootstrap.

Do not collect or count bootstrap telemetry as Arm B.

===================================================================== 10. P4 — FORMAL-READY ENTRY GATE FOR ARM A

Arm A may start only when:

```text
FORMAL_READY=
    YES
```

Prove immediately before Arm A:

```text
kernel=7.0.0-29-generic;
exact JTAG target;
DONE=1;
one expected endpoint;
Gen1 x1;
BAR0=128 KiB;
BAR1=64 KiB;
exact pinned driver loaded/bound;
formal identity exact;
diagnostic magic=0;
no node owner;
zero DMA;
kernel/AER health PASS.
```

Record:

```text
FORMAL_READY_SOURCE=
    EXISTING_PROVEN_STATE
    or
    EXACT_FORMAL_BOOTSTRAP
```

===================================================================== 11. ARM A — EXACT R1e EXTENDED OBSERVABILITY

Immediately before programming:

```text
rehash exact R1e bit;
verify bit/source/DCP manifest;
verify exact target;
verify formal-ready state;
verify operation ledger.
```

Program exactly once through the accepted programming observer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Wait:

```text
>=10.000000 seconds
```

from the later accepted same-QPC marker.

Perform exactly one warm reboot.

Require:

```text
host disappearance;
host return;
new boot ID;
kernel=7.0.0-29-generic.
```

Run corrected BAR parser before loader.

Require:

```text
one expected endpoint;
Gen1 x1;
BAR0=131072;
BAR1=65536;
endpoint unbound;
no wrong xdma;
no node owner.
```

Invoke exact loader once with fresh directory:

```text
/home/vcdeagent1/FPGA_AHD_HOST/
v41_nvp_r1e_r4/arm_a_driver
```

Require exact driver/nodes and healthy host/kernel state.

Verify runtime:

```text
GIT_SHA=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

BUILD_FLAGS=
    0x00000002

common identity=
    A40A0C07 / 0000400B / 00031002

lifecycle magic/version=
    PASS

R1e magic/version/capabilities=
    PASS

ACTIVE_I2C_HZ=
    25000

EXPECTED_CNT_AT_INIT_DONE=
    132584734

PROBE_TARGET_COUNT=
    10000
```

Collect two full read-only snapshots approximately one second apart.

Each snapshot must include:

```text
normal NVP/video telemetry;

0x2000..0x2094 lifecycle/R1e page;

0x10098..0x100D8 ordered NACK header/log.
```

Static fields must match T0/T1:

```text
CNT_AT_INIT_DONE;
expected constants;
probe counters/status;
probe first/last/max streak;
NACK header;
all ordered records;
INIT_DONE/ERROR;
NACK/TIMEOUT;
FIRST_ERROR;
ORIGINAL_FF;
RESTORED_FF.
```

Valid instrumentation sample requires:

```text
PROBE_DONE=1;
PROBE_ABORTED=0;
PROBE_COUNT=10000;
PROBE_ACK_COUNT+PROBE_NACK_COUNT=10000;
PROBE_TIMEOUT_COUNT=0;
lifecycle read coherent;
ordered-log consistency PASS;
final DONE=1.
```

Classify NVP functional result independently:

```text
R1E_NVP_PASS
R1E_NVP_FAIL
R1E_INFRASTRUCTURE_INVALID
```

Read fresh final JTAG DONE.

No second Arm-A sample.

===================================================================== 12. ARM B — FULL EXACT FORMAL CONTROL AND FINAL RESTORE

Arm B is mandatory whenever safe and one program authorization remains.

It is both:

```text
the interleaved exact formal 50-kHz functional control;
the final exact formal restoration.
```

Rehash exact formal bit.

Program once through the accepted programming observer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Wait:

```text
>=5.000000 seconds
```

Perform one warm reboot.

Require:

```text
new boot ID;
kernel 29;
corrected BAR geometry;
exact driver;
formal identity;
diagnostic magic=0;
host/kernel/AER health.
```

Use fresh loader directory:

```text
/home/vcdeagent1/FPGA_AHD_HOST/
v41_nvp_r1e_r4/arm_b_driver
```

Collect full T0/T1 formal NVP/video telemetry.

Additionally read:

```text
0x10098..0x100D8:
    formal ordered NACK header/log;

0x2000..0x20FF:
    deterministic zero/reserved page.
```

Require:

```text
full functional Arm-B sample;
ordered-log consistency;
R1e page zero;
fresh final DONE=1.
```

Arm B is not complete with programming/DONE alone.

At task end:

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

===================================================================== 13. SCIENTIFIC ANALYSIS

────────

13.1 Arm-A lifecycle

Compute:

```text
ACTUAL_CNT_AT_INIT_DONE

EXPECTED_CNT_AT_INIT_DONE=
    132584734

SIGNED_COUNT_ERROR_CYCLES=
    ACTUAL-EXPECTED

SHORTENING_CYCLES=
    max(EXPECTED-ACTUAL,0)

EXTENSION_CYCLES=
    max(ACTUAL-EXPECTED,0)

SHORTENING_TICKS_EXACT=
    SHORTENING_CYCLES/1251

NEAREST_TICKS

RESIDUAL_CYCLES
```

Preserve the pre-increment capture convention.

────────

13.2 Ordered NACK records

For Arm A and Arm B report:

```text
aggregate NACK_COUNT;
log count;
overflow;
first eight ordered records;
phase distribution;
operation-index distribution;
bank/register distribution;
first-error consistency.
```

If overflow:

```text
ORDERED_LOG_COMPLETENESS=
    FIRST_8_RECORDS_ONLY
```

Do not infer omitted records.

────────

13.3 Address-probe statistics

For valid Arm A:

```text
N=10000;
ACK count;
NACK count;
timeout count;
NACK rate;
ppm;
Wilson 95% interval;
first NACK index;
last NACK index;
maximum consecutive NACKs.
```

The probe measures only post-autoinit write-address ACK reliability at 25 kHz.

────────

13.4 Control-flow/log reconciliation

Use the exact FSM model and ordered records.

Classify:

```text
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=
    YES
    PARTIAL_FIRST_8_ONLY
    NON_UNIQUE
    CONTRADICTION
    NOT_APPLICABLE
```

A contradiction means hard-stop for audit, not an automatic source patch.

────────

13.5 Combined interpretation

Use the conservative R1e matrix:

```text
STOCHASTIC_ADDRESS_OR_BUS_MARGIN
AUTOINIT_OPERATION_OR_PHASE_CONTEXT
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG
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

===================================================================== 14. PAIRED A/B CLASSIFICATION

Use only the new R4 Arm A and Arm B samples.

Bootstrap data is contextual only.

Possible outcomes:

```text
A_VALID_B_VALID:
    classify the complete scientific pair.

A_INVALID_B_VALID:
    PAIRED_AB_RESULT=INCONCLUSIVE_ARM_A_INFRASTRUCTURE
    preserve full Arm-B control.

A_VALID_B_INVALID:
    PAIRED_AB_RESULT=INCONCLUSIVE_ARM_B_INFRASTRUCTURE

A_INVALID_B_INVALID:
    PAIRED_AB_RESULT=INCONCLUSIVE_INFRASTRUCTURE

A_OR_B_NOT_RUN_FOR_SAFETY:
    report exact safety blocker.
```

No automatic repeat.

===================================================================== 15. EVIDENCE AND PUBLICATION

Evidence repository:

```text
lukaszsudul/AHD-diagnostic-evidence
```

Preferred existing path:

```text
v41-nvp-r1e-extended-observability-r1/
```

Preserve all existing Git history.

Add R4 continuation and completed campaign in one normal new commit.

At the path root, update/create the one authoritative:

```text
V41_NVP_R1E_EXTENDED_OBSERVABILITY_FINAL_REPORT.md
```

Do not force-push or delete historical evidence.

Required evidence:

```text
verbatim R4 prompt;
R3 commit/package identities;
exact bit identities;
host-tool fixtures;
fresh discovery;
bootstrap decision and raw evidence;
bootstrap raw logs if run;
Arm-A raw program/reboot/driver/telemetry/DONE;
Arm-B raw program/reboot/driver/telemetry/DONE;
decoded ordered logs;
lifecycle calculations;
probe statistics;
paired comparison;
operation ledger;
secret scan;
single final report;
SHA-256 manifest.
```

Create:

```text
V41_NVP_R1E_R4_COMPLETE_MEASUREMENT_EVIDENCE.zip
V41_NVP_R1E_R4_COMPLETE_MEASUREMENT_EVIDENCE_SHA256.txt
SHA256_MANIFEST.txt
```

No PDF or DOCX.

Normal commit/push only.

No tag or Release.

If publication fails:

```text
retain sealed local evidence;
record the exact blocker;
do not alter the scientific result.
```

===================================================================== 16. REQUIRED SINGLE FINAL REPORT BLOCK

The one final report must end with:

```text
TASK=
    V41_NVP_R1E_FORMAL_BOOTSTRAP_RECOVERY_AND_COMPLETE_PAIRED_AB_R4

FINAL_REPORT_COUNT=
    1

R3_EVIDENCE_COMMIT=
    f1bf9ed648dc0749fbd2de2ddae38a42917fee9b

R3_EVIDENCE_PACKAGE_SHA256=
    F6D57CCFD2CF4A7754F9562FDA2BE6BA877A95E2F0E5A4CBAAA0601D32A96782

R3_HARD_STOP=
    BLOCKED_REQUIRED_FORMAL_START_STATE

R1E_SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1E_SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1E_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

R1E_BIT_SHA256=
    0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9

FULL_BUILDS_THIS_TASK=
    0

SYNTHESIS_RUNS_THIS_TASK=
    0

IMPLEMENTATION_RUNS_THIS_TASK=
    0

BITSTREAMS_GENERATED_THIS_TASK=
    0

FPGA_SOURCE_CHANGES_THIS_TASK=
    0

START_STATE_DISCOVERY=
START_STATE_CLASSIFICATION=
START_STATE_RAW_READER_BLOCK_ID=
START_STATE_ACCEPTED_READER_BLOCK_ID=

FORMAL_BOOTSTRAP_RUN=
FORMAL_BOOTSTRAP_PROGRAM=
FORMAL_BOOTSTRAP_WAIT_SECONDS=
FORMAL_BOOTSTRAP_BOOT_ID_CHANGED=
FORMAL_BOOTSTRAP_KERNEL=
FORMAL_BOOTSTRAP_DRIVER=
FORMAL_BOOTSTRAP_IDENTITY=
FORMAL_BOOTSTRAP_DONE=

FORMAL_READY=
FORMAL_READY_SOURCE=

ARM_A_PROGRAM=
ARM_A_WAIT_SECONDS=
ARM_A_BOOT_ID_CHANGED=
ARM_A_KERNEL=
ARM_A_BAR0_BYTES=
ARM_A_BAR1_BYTES=
ARM_A_DRIVER=
ARM_A_RUNTIME_PROVENANCE=
ARM_A_CNT_AT_INIT_DONE=
ARM_A_EXPECTED_CNT_AT_INIT_DONE=
    132584734
ARM_A_SIGNED_COUNT_ERROR_CYCLES=
ARM_A_SHORTENING_CYCLES=
ARM_A_SHORTENING_TICKS_EXACT=
ARM_A_SHORTENING_TICKS_NEAREST=
ARM_A_SHORTENING_RESIDUAL_CYCLES=
ARM_A_NACK_COUNT=
ARM_A_NACK_LOG_COUNT=
ARM_A_NACK_LOG_OVERFLOW=
ARM_A_ORDERED_NACK_RECORDS=
ARM_A_PROBE_COUNT=
ARM_A_PROBE_ACK_COUNT=
ARM_A_PROBE_NACK_COUNT=
ARM_A_PROBE_TIMEOUT_COUNT=
ARM_A_PROBE_NACK_RATE=
ARM_A_PROBE_NACK_RATE_PPM=
ARM_A_PROBE_WILSON95=
ARM_A_PROBE_FIRST_NACK_INDEX=
ARM_A_PROBE_LAST_NACK_INDEX=
ARM_A_PROBE_MAX_CONSECUTIVE_NACKS=
ARM_A_NVP_RESULT=
ARM_A_FINAL_DONE=

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

ARM_B_PROGRAM=
ARM_B_WAIT_SECONDS=
ARM_B_BOOT_ID_CHANGED=
ARM_B_KERNEL=
ARM_B_BAR0_BYTES=
ARM_B_BAR1_BYTES=
ARM_B_DRIVER=
ARM_B_FORMAL_IDENTITY=
ARM_B_DIAGNOSTIC_MAGIC=
ARM_B_R1E_PAGE_ZERO=
ARM_B_NACK_COUNT=
ARM_B_NACK_LOG_COUNT=
ARM_B_NACK_LOG_OVERFLOW=
ARM_B_ORDERED_NACK_RECORDS=
ARM_B_NVP_RESULT=
ARM_B_FINAL_DONE=

PAIRED_AB_RESULT=
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=
STOCHASTIC_ADDRESS_OR_BUS_MARGIN=
AUTOINIT_OPERATION_OR_PHASE_CONTEXT=
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=

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

FORMAL_BOOTSTRAP_PROGRAMS=
ARM_A_PROGRAMS=
ARM_B_PROGRAMS=
FPGA_PROGRAM_INVOCATIONS=

FORMAL_BOOTSTRAP_WARM_REBOOTS=
ARM_A_WARM_REBOOTS=
ARM_B_WARM_REBOOTS=
WARM_REBOOTS=

FORMAL_BOOTSTRAP_DRIVER_LOADS=
ARM_A_DRIVER_LOADS=
ARM_B_DRIVER_LOADS=
DRIVER_LOADS=

PROGRAM_RETRIES=
    0

COLD_STARTS=
    0

PHYSICAL_ACTIONS_DURING_TASK=
    0

KERNEL_OR_GRUB_CHANGES=
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

EVIDENCE_PACKAGE_SHA256=
EVIDENCE_REPOSITORY_COMMIT=
PUBLIC_REMOTE_VERIFICATION=
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_COMPLETED_R1E_RESULTS
```

===================================================================== 17. HARD STOPS

Stop before any program if:

```text
R3 evidence identity cannot be proven;
R1e or formal bit hash differs;
host-tool fixtures fail;
wrong/multiple JTAG target;
wrong/multiple foreign endpoint;
wrong same-name xdma module;
node owner exists;
critical kernel/AER issue;
exact formal bit unavailable.
```

Stop bootstrap after its single program if:

```text
programming fails;
host does not return;
kernel differs;
driver cannot load once;
formal runtime identity is not exact;
DONE != 1.
```

Stop Arm A or Arm B if:

```text
programming fails;
host does not return;
kernel differs;
BAR parser fails;
driver cannot load once;
runtime identity/provenance mismatches;
telemetry is incoherent;
probe invariants fail;
ordered-log consistency fails;
final DONE fails.
```

No:

```text
second bootstrap;
program retry;
fourth FPGA program;
second Arm-A run;
second Arm-B run;
build;
source patch;
new bit;
physical recovery action;
Phase-3 work.
```

Arm B must still be attempted as a full control after an Arm-A terminal result
when the exact target remains safe and one program authorization remains.

===================================================================== 18. BEGIN

```text
save and hash this prompt
    ->
preserve and verify R3 evidence
    ->
locate and rehash exact existing R1e bit
    ->
rehash exact formal bit
    ->
verify exact R3 host tools and fixtures
    ->
run one fresh read-only start-state discovery
    ->
if formal identity is already exact:
        skip bootstrap
    else if bootstrap is safe:
        program exact formal once
        wait
        reboot
        load exact driver
        prove formal identity and DONE
    else:
        hard stop
    ->
prove FORMAL_READY
    ->
Arm A:
        program exact R1e once
        wait 10 seconds
        reboot
        load exact driver
        collect lifecycle + probe + ordered log + normal telemetry
        final DONE
    ->
Arm B:
        program exact formal once
        wait at least 5 seconds
        reboot
        load exact driver
        collect full formal control + ordered log
        prove R1e page zero
        final DONE
    ->
combined scientific analysis
    ->
leave exact formal Phase 2 active
    ->
create one authoritative final report
    ->
seal and publish evidence
    ->
HARD STOP.
```

No interactive owner questions.
No build.
No FPGA-source changes.
No bitstream generation.
No program retry.
No Phase 3.
No XDMA work.
