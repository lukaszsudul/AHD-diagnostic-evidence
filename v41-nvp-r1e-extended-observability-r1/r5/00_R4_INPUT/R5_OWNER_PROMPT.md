CODEX MASTER PROMPT

v41 NVP R1e — JTAG-recovered formal bootstrap and complete paired A/B campaign R5

Reuse the exact existing R1e bitstream; no build, no source change

Fresh JTAG transport-stability gate → mandatory exact-formal bootstrap

→ Arm A R1e → full Arm B formal control → one authoritative final report

FULL OWNER PRE-AUTHORIZATION — NO INTERACTIVE CONFIRMATIONS

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_R1E_JTAG_RECOVERED_BOOTSTRAP_AND_COMPLETE_PAIRED_AB_R5

TASK_CHARACTER:
    NEW_SEPARATELY_AUTHORIZED_HARDWARE_COMPLETION_OF_THE_FROZEN_R1E_EXPERIMENT

PRIMARY_PURPOSE:
    After the owner completed and independently checked the pre-task JTAG
    connection recovery, establish a known exact formal Phase-2 start state and
    obtain the complete R1e Arm-A and exact formal Arm-B scientific samples.

R1E_BUILD_STATUS:
    COMPLETE_AND_FROZEN

R1E_BITSTREAM_STATUS:
    AVAILABLE_AND_FROZEN

R1E_HARDWARE_SCIENTIFIC_SAMPLE:
    NOT_YET_OBTAINED

R5_SEQUENCE:
    fresh read-only JTAG transport-stability qualification;
    exact formal Phase-2 bootstrap;
    exact formal runtime identity proof;
    Arm A exact R1e;
    Arm B exact formal full functional control and final restore;
    combined lifecycle / ordered-NACK / address-probe analysis;
    evidence publication.

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

FORMAL_BOOTSTRAP_PROGRAMS:
    1

ARM_A_PROGRAMS:
    1

ARM_B_PROGRAMS:
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

Do not pause to request approval for:

```text
task-root creation;
read-only JTAG stability sessions;
read-only host/PCIe discovery;
the one exact formal bootstrap;
the bootstrap warm reboot and exact driver load;
the Arm-A R1e program/reboot/driver load;
the Arm-B formal program/reboot/driver load;
all authorized read-only MMIO/telemetry;
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

This authorization does not permit any action outside the exact scope or above
the numerical limits.

===================================================================== 0. AUTHORITATIVE R4 OUTCOME

R4 evidence:

```text
EVIDENCE_REPOSITORY=
    lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT=
    7aad5cbdcce4142532f34e4ce31a022b2f6ff435

EVIDENCE_PACKAGE_SHA256=
    8F30EDA6E135BC5097EBA5F36524FD0E3187D9FF8E483694E01D75C8DA30AEFB
```

R4 exact frozen artifacts:

```text
R1E_SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1E_SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1E_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

R1E_BIT_SHA256=
    0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
```

R4 pre-program gates:

```text
R3/R1E_ARTIFACT_IDENTITIES=
    PASS

HOST_TOOL_FIXTURES=
    PASS

JTAG_PRECHECK_BEFORE_PROGRAM=
    PASS_EXACT_HS2_PART_IDCODE_DONE_1

KERNEL_ENDPOINT_LINK_BAR_DRIVER_SAFETY=
    PASS

EXISTING_RUNTIME_FORMAL_IDENTITY=
    NOT_PROVEN
```

R4 bootstrap result:

```text
FORMAL_BOOTSTRAP_PROGRAM_INVOCATIONS=
    1

VENDOR_STARTUP_STATUS=
    LOW_LABTOOLS_27_3165

PROGRAM_RETURN_MARKER=
    NOT_ACCEPTED

POST_PROGRAM_DONE=
    NOT_PROVEN

PROGRAM_RETRIES=
    0

WARM_REBOOTS=
    0

DRIVER_LOADS=
    0

ARM_A=
    NOT_RUN

ARM_B=
    NOT_RUN

FINAL_SRAM_IMAGE=
    UNPROVEN

FINAL_DONE=
    UNPROVEN
```

R4 scientific status:

```text
R1E_ARM_A_SAMPLE=
    NOT_RUN

R1E_ARM_B_SAMPLE=
    NOT_RUN

PAIRED_AB_RESULT=
    NOT_EVALUATED_NO_HARDWARE_CAMPAIGN
```

R5 preserves R4 unchanged.

R5 is a new, separately authorized campaign.

=====================================================================

1. PRE-TASK JTAG RECOVERY DECLARATION AND REPORTING RULE
=====================================================================

Owner declaration:

```text
OWNER_PRETASK_JTAG_CONNECTION_RECOVERY_COMPLETED=
    YES

OWNER_PRETASK_JTAG_CONNECTION_TESTED=
    YES
```

This declaration is context only.

Fresh R5 evidence controls all gates.

The pre-task handling occurred outside R5 and did not modify:

```text
R1e source;
R1e routed DCP;
R1e bitstream;
formal bitstream;
or an R1e scientific sample.
```

Do not discuss the cause or details of the pre-task handling in:

```text
the executive summary;
the scientific interpretation;
the paired A/B classification;
the publication receipt;
or the final report narrative.
```

Do not delete or rewrite raw historical evidence.

The R5 final report records only fresh R5 results:

```text
JTAG_TRANSPORT_STABILITY_GATE=
    PASS / FAIL

FORMAL_BOOTSTRAP_PROGRAM=
    PASS / FAIL
```

If the fresh R5 JTAG gate fails, report that current failure normally.

===================================================================== 2. FROZEN R1e SCIENTIFIC CONFIGURATION

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

No source, bit, timing, probe, log, register-map or host-decoder parameter may
change in R5.

===================================================================== 3. EXACT FORMAL BOOTSTRAP AND CONTROL

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

The R5 bootstrap is mandatory.

It is:

```text
a start-state recovery and programming-infrastructure qualification;

not Arm B;

not a scientific control sample;

not counted as a repeated Arm-B observation.
```

Arm B must still run fully after Arm A.

===================================================================== 4. HOST, DRIVER, AND TOOL IDENTITIES

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

Required loader form:

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
an alternate module selected by name;
another kernel module;
PCIe remove/rescan;
driver_override.
```

Reuse exact passed R3/R4:

```text
programming observer;
Python BAR parser;
accepted AXI-Lite reader;
R1e full reader/decoder;
ordered-log decoder;
lifecycle calculator;
probe statistics calculator.
```

Require their hashes from the R3/R4 evidence manifests.

Do not rewrite them.

Any hash mismatch:

```text
BLOCKED_FROZEN_HOST_TOOL_IDENTITY
```

===================================================================== 5. AUTHORIZATION AND ABSOLUTE LIMITS

Authorized task-local work:

```text
preserve and verify R4 evidence;
locate and rehash exact R1e/formal bits;
run frozen host-tool fixtures;
perform the fresh read-only JTAG stability qualification;
perform one exact formal bootstrap;
execute Arm A;
execute full Arm B;
create and publish one authoritative final report/evidence package.
```

Authorized hardware:

```text
JTAG transport qualification:
    two independent read-only Hardware Manager sessions;
    five refresh samples per session;
    zero program operations.

Bootstrap:
    one exact formal program;
    one >=5-second wait;
    one warm reboot;
    one exact pinned-driver load;
    formal identity and DONE proof.

Arm A:
    one exact R1e program;
    one >=10-second wait;
    one warm reboot;
    one exact pinned-driver load;
    full R1e telemetry;
    final DONE.

Arm B:
    one exact formal program;
    one >=5-second wait;
    one warm reboot;
    one exact pinned-driver load;
    full formal-control telemetry;
    final DONE.
```

Maximum:

```text
READ_ONLY_JTAG_STABILITY_SESSIONS=
    2

JTAG_REFRESH_SAMPLES_PER_SESSION=
    5

TOTAL_JTAG_STABILITY_SAMPLES=
    10

FORMAL_BOOTSTRAP_PROGRAMS=
    1

ARM_A_PROGRAMS=
    1

ARM_B_PROGRAMS=
    1

FPGA_PROGRAM_INVOCATIONS=
    3

WARM_REBOOTS=
    3

POST_REBOOT_DRIVER_LOADS=
    3

PROGRAM_RETRIES=
    0
```

Not authorized:

```text
build;
synthesis;
place;
route;
write_bitstream;
source edit;
new FPGA source commit;
DCP mutation;
second bootstrap;
second Arm-A sample;
second Arm-B sample;
fourth FPGA program;
cold start;
power cycle;
physical action during R5;
JTAG/cable reseat during R5;
kernel/GRUB change;
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

===================================================================== 6. TASK ROOT AND EVIDENCE POLICY

Create:

```text
C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\
```

Required structure:

```text
00_R4_INPUT\
01_ARTIFACT_IDENTITY\
02_HOST_TOOL_PREFLIGHT\
03_JTAG_STABILITY\
04_HOST_SAFETY_DISCOVERY\
05_FORMAL_BOOTSTRAP\
06_ARM_A_R1E\
07_ARM_B_FORMAL\
08_ANALYSIS\
09_FINAL\
scripts\
fixtures\
```

Create immediately:

```text
OPERATION_LEDGER.md
TIME_LEDGER.md
```

Save this prompt verbatim and record its SHA-256 before any JTAG or SSH
operation.

Initial accounting:

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
READ_ONLY_JTAG_STABILITY_SESSIONS=0
JTAG_STABILITY_SAMPLES=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS_DURING_TASK=0
FORMAL_REPOSITORY_MUTATIONS=0
```

────────

6.1 One authoritative final report

Create exactly one authoritative final report:

```text
V41_NVP_R1E_EXTENDED_OBSERVABILITY_FINAL_REPORT.md
```

It must integrate:

```text
frozen implementation history;
R3 bitstream completion;
R4 bootstrap boundary;
R5 JTAG stability qualification;
R5 formal bootstrap;
Arm A;
full Arm B;
lifecycle/log/probe analysis;
final formal state;
complete operation accounting.
```

Earlier reports remain preserved in Git history.

Do not create a competing second final report.

===================================================================== 7. P0 — R4 EVIDENCE AND ARTIFACT IDENTITY

Verify:

```text
R4_EVIDENCE_COMMIT=
    7aad5cbdcce4142532f34e4ce31a022b2f6ff435

R4_EVIDENCE_PACKAGE_SHA256=
    8F30EDA6E135BC5097EBA5F36524FD0E3187D9FF8E483694E01D75C8DA30AEFB
```

Locate the R1e bit only in bounded known locations:

```text
the R3/R4 task roots;
the R3/R4 evidence packages;
the public R1e evidence path.
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

Rehash exact formal bit.

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

with zero JTAG sessions and zero programs.

===================================================================== 8. P1 — FROZEN HOST-TOOL FIXTURE GATE

Recover the exact accepted tools from R3/R4 evidence manifests.

Require exact hashes.

Run no-hardware fixtures for:

```text
programming transcript parser;
vendor startup HIGH/LOW handling;
same-session DONE;
Python BAR parser 128/64 KiB;
0xFFFFFFFF identity rejection;
formal identity acceptance;
lifecycle coherent 48-bit read;
expected count 132584734;
ordered-log count/overflow rules;
probe invariants;
Wilson interval;
zero-NACK upper bound;
formal R1e-page-zero behavior.
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

with zero JTAG sessions and zero programs.

===================================================================== 9. P2 — READ-ONLY JTAG TRANSPORT-STABILITY QUALIFICATION

Purpose:

```text
qualify the fresh physical JTAG transport before consuming the one new formal
bootstrap program authorization.
```

Do not use current application identity as this gate.

Current DONE may be 0 or 1 after R4.

The transport gate is based on stable target enumeration and property reads.

────────

9.1 Session structure

Run exactly two independent read-only Hardware Manager sessions.

For each session:

```text
start through supported Vivado launcher;
open hardware manager;
connect to the intended hw_server;
enumerate targets;
select exact HS2 210241768436;
enumerate devices;
select exact xc7a35t / IDCODE 0362D093;
capture list_property;
perform five consecutive refresh_hw_device operations;
after each refresh record:
    session index;
    sample index;
    monotonic timestamp;
    target count;
    device count;
    HS2 serial;
    part;
    IDCODE;
    DONE value;
    refresh result;
    stdout/stderr.
close session cleanly.
```

No programming command is permitted.

Wait approximately 0.5 seconds between refresh samples.

Close the first session completely before opening the second.

────────

9.2 Stability requirements

Require across all ten samples:

```text
target count=1;
device count=1;
HS2 serial exact;
part exact;
IDCODE exact;
zero transport/refresh errors;
zero target loss;
zero target duplication;
DONE property readable in every sample;
DONE value stable across all samples.
```

The stable DONE value may be:

```text
0
or
1
```

because the current SRAM image is unproven.

Required:

```text
READ_ONLY_JTAG_STABILITY_SESSIONS=
    2

JTAG_STABILITY_SAMPLES=
    10

JTAG_TRANSPORT_STABILITY_GATE=
    PASS_10_OF_10
```

Any mismatch, unreadable property, changing DONE, target loss or refresh error:

```text
BLOCKED_JTAG_TRANSPORT_NOT_STABLE
```

No program and no physical action.

Create:

```text
03_JTAG_STABILITY\JTAG_STABILITY_MATRIX.csv
03_JTAG_STABILITY\SESSION_1_RAW.log
03_JTAG_STABILITY\SESSION_2_RAW.log
03_JTAG_STABILITY\JTAG_STABILITY_GATE.md
```

===================================================================== 10. P3 — PRE-BOOTSTRAP HOST SAFETY DISCOVERY

The current SRAM application identity is not a prerequisite.

Read only:

```text
hostname/user;
kernel;
boot ID;
uptime start;
next-boot kernel proof;

PCIe endpoint count and identities;
link and BARs when an expected endpoint exists;

loaded modules named xdma;
driver binding;
node set;
node owners;
task DMA count;
kernel/AER health.
```

Required safety gates:

```text
kernel=7.0.0-29-generic;
next reboot remains kernel 29;
zero or one expected 10ee:7011 / subsystem 0007 endpoint;
no foreign/multiple FPGA endpoint;
no wrong same-name xdma module;
no XDMA node owner;
zero task DMA;
no fatal kernel/AER issue;
exact formal bit available;
exact JTAG stability gate PASS.
```

The existing reader result may be recorded but is not a bootstrap entry gate.

If it returns 0xFFFFFFFF, record it as unproven.

Unsafe conditions:

```text
wrong/multiple endpoint;
wrong module;
node owner;
critical kernel/AER issue;
operation-ledger contradiction.
```

Classification:

```text
BLOCKED_UNSAFE_PRE_BOOTSTRAP_HOST_STATE
```

with zero programs.

Do not unload or unbind the existing driver.

Do not reset or rescan PCIe.

===================================================================== 11. P4 — MANDATORY EXACT FORMAL BOOTSTRAP

Before programming:

```text
rehash exact formal bit;
verify exact JTAG target;
verify JTAG stability PASS;
verify no node owner;
verify zero task DMA;
verify operation ledger.
```

Program exact formal Phase 2 once through the accepted programming observer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one program invocation;
process exit code=0;
no timeout;
no retry.
```

After the programming process closes, run one new independent read-only JTAG
session.

Require:

```text
exact target;
exact part/IDCODE;
fresh independent DONE=1.
```

This independent session is state confirmation, not a program retry.

Wait:

```text
>=5.000000 seconds
```

from the later accepted same-QPC:

```text
program-return marker;
same-session fresh-DONE marker.
```

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
10ee:7011 / subsystem 0007 / class 058000;
Gen1 x1;
BAR0=131072;
BAR1=65536;
corrected Python BAR parser PASS;
endpoint unbound or expected clean loader-entry state;
no wrong xdma;
no node owner.
```

Invoke exact loader once with fresh directory:

```text
/home/vcdeagent1/FPGA_AHD_HOST/
v41_nvp_r1e_r5/bootstrap_driver
```

Require:

```text
loader exit=0;
exact module path/hash/version/vermagic;
expected 21-node set;
exact BDF binding;
kernel/AER health PASS.
```

Verify using both readers:

```text
RAW_TASK_READER_BLOCK_ID=
    0xA40A0C07

ACCEPTED_READER_BLOCK_ID=
    0xA40A0C07

PROTOCOL=
    0x0000400B

CAPABILITIES=
    0x00031002

DIAGNOSTIC_MAGIC=
    0x00000000
```

Read fresh final bootstrap JTAG:

```text
DONE=1
```

Required:

```text
FORMAL_BOOTSTRAP_RESULT=
    PASS_FORMAL_READY

FORMAL_READY=
    YES

FORMAL_READY_SOURCE=
    R5_EXACT_FORMAL_BOOTSTRAP
```

No second bootstrap.

Failure means hard stop.

Bootstrap telemetry is not Arm B.

===================================================================== 12. P5 — ARM-A ENTRY GATE

Immediately before Arm A, prove read only:

```text
kernel=7.0.0-29-generic;
exact target;
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

Require:

```text
FORMAL_READY=
    YES
```

===================================================================== 13. ARM A — EXACT R1e EXTENDED OBSERVABILITY

Immediately before program:

```text
rehash exact R1e bit;
verify bit/source/DCP manifest;
verify exact target;
verify formal-ready state;
verify operation ledger.
```

Program once through the accepted programming observer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Run one independent immediate read-only JTAG session.

Require:

```text
exact target;
fresh DONE=1.
```

Wait:

```text
>=10.000000 seconds
```

from the later accepted same-QPC marker.

Perform one warm reboot.

Require:

```text
new boot ID;
kernel 29;
corrected BAR geometry;
exact explicit-path XDMA load;
expected node set;
host/kernel/AER health.
```

Use fresh loader directory:

```text
/home/vcdeagent1/FPGA_AHD_HOST/
v41_nvp_r1e_r5/arm_a_driver
```

Verify runtime:

```text
GIT_SHA=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

BUILD_FLAGS=
    0x00000002

COMMON_IDENTITY=
    A40A0C07 / 0000400B / 00031002

LIFECYCLE_MAGIC_VERSION=
    PASS

R1E_MAGIC_VERSION_CAPABILITIES=
    PASS

ACTIVE_I2C_HZ=
    25000

EXPECTED_CNT_AT_INIT_DONE=
    132584734

PROBE_TARGET_COUNT=
    10000
```

Collect two full read-only snapshots approximately one second apart.

Each snapshot includes:

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

Classify:

```text
R1E_NVP_PASS
R1E_NVP_FAIL
R1E_INFRASTRUCTURE_INVALID
```

Read fresh final JTAG DONE.

No second Arm-A run.

===================================================================== 14. ARM B — FULL EXACT FORMAL CONTROL AND FINAL RESTORE

Arm B is mandatory whenever the exact target remains safe and one program
authorization remains.

It is both:

```text
the interleaved exact formal 50-kHz functional control;
the final exact formal restoration.
```

Rehash exact formal bit.

Program once through the accepted observer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Run one independent immediate read-only JTAG session.

Require:

```text
exact target;
fresh DONE=1.
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
exact pinned driver;
formal identity;
diagnostic magic=0;
host/kernel/AER health.
```

Use fresh loader directory:

```text
/home/vcdeagent1/FPGA_AHD_HOST/
v41_nvp_r1e_r5/arm_b_driver
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

===================================================================== 15. SCIENTIFIC ANALYSIS

────────

15.1 Arm-A lifecycle

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

Preserve the exact pre-increment capture convention.

────────

15.2 Ordered NACK records

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

15.3 Address-probe statistics

For valid Arm A report:

```text
N=10000;
ACK count;
NACK count;
timeout count;
NACK rate;
NACK rate ppm;
Wilson 95% interval;
first NACK index;
last NACK index;
maximum consecutive NACKs.
```

The probe measures only post-autoinit write-address ACK reliability at 25 kHz.

────────

15.4 Control-flow/log reconciliation

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

A contradiction is an audit stop, not an automatic source patch.

────────

15.5 Combined interpretation

Produce:

```text
PAIRED_AB_RESULT
STOCHASTIC_ADDRESS_OR_BUS_MARGIN
AUTOINIT_OPERATION_OR_PHASE_CONTEXT
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG
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

===================================================================== 16. PAIRED A/B CLASSIFICATION

Use only the new R5 Arm-A and Arm-B samples.

Bootstrap is contextual only.

Possible outcomes:

```text
A_VALID_B_VALID:
    classify complete pair.

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

===================================================================== 17. EVIDENCE AND PUBLICATION

Evidence repository:

```text
lukaszsudul/AHD-diagnostic-evidence
```

Existing path:

```text
v41-nvp-r1e-extended-observability-r1/
```

Preserve all existing Git history.

Add R5 raw evidence under:

```text
v41-nvp-r1e-extended-observability-r1/r5/
```

At the path root update/create the one authoritative:

```text
V41_NVP_R1E_EXTENDED_OBSERVABILITY_FINAL_REPORT.md
```

Do not force-push or delete historical evidence.

Required evidence:

```text
verbatim R5 prompt;
R4 commit/package identities;
exact bit identities;
host-tool fixtures;
ten-sample JTAG stability matrix;
pre-bootstrap host safety discovery;
bootstrap raw program/reboot/driver/identity/DONE;
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
V41_NVP_R1E_R5_COMPLETE_MEASUREMENT_EVIDENCE.zip
V41_NVP_R1E_R5_COMPLETE_MEASUREMENT_EVIDENCE_SHA256.txt
SHA256_MANIFEST.txt
```

No PDF or DOCX.

Normal commit/push only.

No tag or Release.

If publication fails:

```text
retain sealed local evidence;
record exact blocker;
do not alter the scientific result.
```

===================================================================== 18. REQUIRED SINGLE FINAL REPORT BLOCK

The one final report must end with:

```text
TASK=
    V41_NVP_R1E_JTAG_RECOVERED_BOOTSTRAP_AND_COMPLETE_PAIRED_AB_R5

FINAL_REPORT_COUNT=
    1

R4_EVIDENCE_COMMIT=
    7aad5cbdcce4142532f34e4ce31a022b2f6ff435

R4_EVIDENCE_PACKAGE_SHA256=
    8F30EDA6E135BC5097EBA5F36524FD0E3187D9FF8E483694E01D75C8DA30AEFB

R4_HARD_STOP=
    BLOCKED_FORMAL_BOOTSTRAP_PROGRAMMING_FAILURE

R1E_SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

R1E_SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1E_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

R1E_BIT_SHA256=
    0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

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

READ_ONLY_JTAG_STABILITY_SESSIONS=
    2

JTAG_STABILITY_SAMPLES=
    10

JTAG_PRECHECK_DONE_VALUE=
JTAG_TRANSPORT_STABILITY_GATE=

PRE_BOOTSTRAP_KERNEL=
PRE_BOOTSTRAP_ENDPOINT_STATE=
PRE_BOOTSTRAP_DRIVER_STATE=
PRE_BOOTSTRAP_NODE_OWNERS=
PRE_BOOTSTRAP_DMA=
PRE_BOOTSTRAP_HOST_SAFETY_GATE=

FORMAL_BOOTSTRAP_PROGRAM=
FORMAL_BOOTSTRAP_VENDOR_STARTUP=
FORMAL_BOOTSTRAP_SAME_SESSION_DONE=
FORMAL_BOOTSTRAP_INDEPENDENT_DONE=
FORMAL_BOOTSTRAP_WAIT_SECONDS=
FORMAL_BOOTSTRAP_BOOT_ID_CHANGED=
FORMAL_BOOTSTRAP_KERNEL=
FORMAL_BOOTSTRAP_BAR0_BYTES=
FORMAL_BOOTSTRAP_BAR1_BYTES=
FORMAL_BOOTSTRAP_DRIVER=
FORMAL_BOOTSTRAP_RAW_READER_IDENTITY=
FORMAL_BOOTSTRAP_ACCEPTED_READER_IDENTITY=
FORMAL_BOOTSTRAP_DIAGNOSTIC_MAGIC=
FORMAL_BOOTSTRAP_FINAL_DONE=
FORMAL_READY=

ARM_A_PROGRAM=
ARM_A_VENDOR_STARTUP=
ARM_A_SAME_SESSION_DONE=
ARM_A_INDEPENDENT_DONE=
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

ARM_B_PROGRAM=
ARM_B_VENDOR_STARTUP=
ARM_B_SAME_SESSION_DONE=
ARM_B_INDEPENDENT_DONE=
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
    1

ARM_A_PROGRAMS=
    1

ARM_B_PROGRAMS=
    1

FPGA_PROGRAM_INVOCATIONS=
    3

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

OWNER_PROMPT_SHA256=
EVIDENCE_PACKAGE_SHA256=
EVIDENCE_REPOSITORY_COMMIT=
PUBLIC_REMOTE_VERIFICATION=
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_COMPLETED_R1E_RESULTS
```

===================================================================== 19. HARD STOPS

Stop before JTAG stability sessions if:

```text
R4 evidence identity cannot be proven;
R1e or formal bit hash differs;
frozen host-tool hashes/fixtures fail.
```

Stop after the read-only stability gate if:

```text
target/device count differs;
HS2/part/IDCODE differs;
refresh error occurs;
DONE is unreadable;
DONE changes across samples;
JTAG stability is not 10/10.
```

Stop before bootstrap if:

```text
kernel/next-boot gate fails;
foreign/multiple endpoint exists;
wrong same-name xdma is loaded/bound;
node owner exists;
task DMA is nonzero;
critical kernel/AER issue exists.
```

Stop bootstrap after its single program if:

```text
vendor startup is not HIGH;
same-session DONE !=1;
independent DONE !=1;
host does not return;
kernel differs;
BAR parser fails;
driver cannot load once;
formal runtime identity is not exact;
final bootstrap DONE !=1.
```

Stop Arm A or Arm B if:

```text
programming fails;
independent DONE fails;
host does not return;
kernel differs;
BAR parser fails;
driver cannot load once;
runtime identity/provenance mismatches;
telemetry is incoherent;
probe invariants fail;
ordered-log consistency fails;
lifecycle read is incoherent;
final DONE fails.
```

No:

```text
second bootstrap;
program retry;
fourth FPGA program;
second Arm-A sample;
second Arm-B sample;
build;
source patch;
new bit;
physical recovery during task;
Phase-3 work.
```

Arm B must still be attempted as a full control after an Arm-A terminal result
when the exact target remains safe and one program authorization remains.

===================================================================== 20. BEGIN

```text
save and hash this prompt
    ->
preserve and verify R4 evidence
    ->
locate and rehash exact existing R1e bit
    ->
rehash exact formal bit
    ->
verify frozen R3/R4 host tools and fixtures
    ->
run two independent read-only JTAG sessions
    with five refresh samples each
    ->
require JTAG stability 10/10
    ->
run pre-bootstrap host safety discovery
    ->
program exact formal bootstrap once
    ->
require startup HIGH and same-session plus independent DONE=1
    ->
wait at least 5 seconds
    ->
warm reboot
    ->
load exact pinned driver
    ->
prove exact formal runtime identity and DONE
    ->
Arm A:
        program exact R1e once
        require same-session and independent DONE
        wait at least 10 seconds
        warm reboot
        load exact driver
        collect lifecycle + probe + ordered log + normal telemetry
        final DONE
    ->
Arm B:
        program exact formal once
        require same-session and independent DONE
        wait at least 5 seconds
        warm reboot
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
No physical action during R5.
No Phase 3.
No XDMA work.