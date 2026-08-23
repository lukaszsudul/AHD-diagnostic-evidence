CODEX MASTER PROMPT

v41 NVP R1e — mode-aware bootstrap from stable DONE=0 and complete paired A/B campaign R7

Reuse selected JTAG Xilinx/80802026a98b01

Reuse exact existing R1e/formal bitstreams; no build, no FPGA-source change

Correct only the task-local pre-program DONE contract

→ exact formal bootstrap → Arm A R1e → full Arm B formal control

FULL OWNER PRE-AUTHORIZATION — NO INTERACTIVE CONFIRMATIONS

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_R1E_MODE_AWARE_BOOTSTRAP_FROM_DONE0_AND_COMPLETE_PAIRED_AB_R7

TASK_CHARACTER:
    NEW_SEPARATELY_AUTHORIZED_HARDWARE_COMPLETION_OF_THE_FROZEN_R1E_EXPERIMENT

PRIMARY_PURPOSE:
    Complete the R1e scientific campaign after R6 proved that the selected new
    JTAG transport is stable but exposed one task-local observer-contract
    contradiction:

        R6 JTAG preflight:
            selected target exact;
            part/IDCODE exact;
            stable DONE=0 in 10/10 samples.

        frozen old observer:
            required PRE_PROGRAM_DONE=1 for every role.

    R7 changes only the host-side pre-program DONE contract:

        BOOTSTRAP mode:
            a readable, stable pre-program DONE of either 0 or 1 is accepted;

        TRANSITION mode:
            pre-program DONE must equal 1.

    All post-program success gates remain unchanged and strict.

CONTROLLED_INFRASTRUCTURE_CHANGE:
    TASK_LOCAL_PROGRAMMING_OBSERVER_PRECONDITION_ONLY

SCIENTIFIC_IMAGE_VARIABLE:
    UNCHANGED

SELECTED_JTAG:
    Xilinx/80802026a98b01

R1E_BUILD_STATUS:
    COMPLETE_AND_FROZEN

R1E_BITSTREAM_STATUS:
    AVAILABLE_AND_FROZEN

R1E_HARDWARE_SCIENTIFIC_SAMPLE:
    NOT_YET_OBTAINED

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
task-local programming-observer contract adaptation;
observer fixtures and historical-log replay;
read-only selected-JTAG reconfirmation;
read-only Ubuntu/PCIe safety discovery;
the exact formal bootstrap;
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

This authorization does not permit any operation outside the explicit scope or
above the numerical limits.

===================================================================== 0. AUTHORITATIVE R6 OUTCOME

R6 result supplied by the owner:

```text
R6_CLASSIFICATION=
    BLOCKED_R6_STABLE_DONE_0_VS_FROZEN_PREPROGRAM_DONE_1_CONTRACT

R6_SELECTED_JTAG=
    Xilinx/80802026a98b01

R6_SELECTED_JTAG_STABILITY=
    PASS_10_OF_10

R6_FPGA_PART=
    xc7a35t

R6_FPGA_IDCODE=
    0362D093

R6_PREPROGRAM_DONE=
    STABLE_0

R6_HOST_BASELINE=
    PASS

R6_PRE_BOOTSTRAP_SAFETY=
    PASS

R6_OLD_OBSERVER_PREPROGRAM_REQUIREMENT=
    DONE_MUST_EQUAL_1

R6_FPGA_PROGRAMS=
    0

R6_WARM_REBOOTS=
    0

R6_DRIVER_LOADS=
    0

R6_MMIO=
    0

R6_DMA=
    0

R6_BOOTSTRAP=
    NOT_RUN

R6_ARM_A=
    NOT_RUN

R6_ARM_B=
    NOT_RUN

R6_SCIENTIFIC_RESULT=
    NOT_EVALUATED

R6_FINAL_FPGA_IMAGE=
    UNPROVEN
```

R6 proves:

```text
SELECTED_JTAG_TRANSPORT=
    QUALIFIED

PREPROGRAM_DONE_0=
    READABLE_AND_STABLE

R6_STOP_CAUSE=
    HOST_OBSERVER_CONTRACT_ONLY
```

R6 does not prove:

```text
a valid application image;
a formal runtime identity;
an R1e scientific result.
```

At R7 start, locate the exact R6 final report/evidence and record:

```text
R6_REPORT_PATH=
R6_REPORT_SHA256=
R6_EVIDENCE_COMMIT=
R6_EVIDENCE_PACKAGE_SHA256=
```

If the report cannot self-embed the containing Git commit, resolve the exact
containing commit from the public repository path.

Do not invent an evidence identity.

R7 preserves R6 unchanged.

R7 does not retroactively classify any R6 operation as a program attempt.

=====================================================================

1. SCIENTIFIC AND IMPLEMENTATION IDENTITIES
=====================================================================

Exact R1e source:

```text
SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

BIT_FILENAME=
    ahd_capture_v41_i2c_25khz_r1e_observability.bit

BIT_SIZE_BYTES=
    2192144

BIT_SHA256=
    0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9
```

Frozen R1e parameters:

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

No source, bit, DCP, timing, probe, log, register-map or decoder parameter may
change in R7.

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

The formal bootstrap is mandatory.

It is:

```text
a start-state recovery operation;
a bootstrap-mode observer qualification;
not Arm B;
not a scientific paired-control sample.
```

Arm B must still run fully after Arm A.

===================================================================== 3. SELECTED JTAG IDENTITY

Authoritative R7 target:

```text
JTAG_ADAPTER_ROLE=
    OWNER_SELECTED_PROGRAMMING_ADAPTER

JTAG_CANONICAL_ID=
    Xilinx/80802026a98b01

JTAG_CANONICAL_SUFFIX=
    /Xilinx/80802026a98b01

LEGACY_HS2_SERIAL=
    210241768436

LEGACY_HS2_REQUIRED=
    NO

TARGET_COUNT_REQUIRED=
    1

DEVICE_COUNT_REQUIRED=
    1

FPGA_PART_REQUIRED=
    xc7a35t

FPGA_IDCODE_REQUIRED=
    0362D093

JTAG_FREQUENCY_POLICY=
    RECORD_CURRENT_DEFAULT_NO_CHANGE
```

Reuse the exact R6 target-selector when its hash matches the R6 evidence
manifest.

The full path may contain a server prefix.

The accepted target must:

```text
have canonical final path components exactly:
    Xilinx/80802026a98b01

or end exactly with:
    /Xilinx/80802026a98b01.
```

No substring or first-target fallback is allowed.

Freeze the full selected path at the first live accepted R7 discovery:

```text
R7_FULL_JTAG_TARGET_PATH=
```

Use the same selected target for:

```text
formal bootstrap;
Arm A;
Arm B;
all independent DONE sessions.
```

The JTAG adapter identity is infrastructure context only.

It is not an NVP scientific variable.

===================================================================== 4. UBUNTU, DRIVER, AND FROZEN TOOL IDENTITIES

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
relative module path;
alternate module selected by name;
another kernel module;
PCIe remove/rescan;
driver_override.
```

Reuse exact frozen R3/R4/R6:

```text
target selector;
vendor-startup transcript parser;
same-session DONE parser;
Python BAR parser;
accepted AXI-Lite reader;
R1e full reader/decoder;
ordered-log decoder;
lifecycle calculator;
probe statistics calculator.
```

Only the programming observer’s pre-program DONE contract may change.

All post-program logic must remain byte-equivalent or structurally equivalent
to the accepted R6 observer.

===================================================================== 5. AUTHORIZATION AND ABSOLUTE LIMITS

Authorized task-local work:

```text
preserve and verify R6 evidence;
create the mode-aware pre-program DONE wrapper/observer;
run observer fixtures and historical-log replay;
locate and rehash exact R1e/formal bits;
run frozen host-tool fixtures;
perform one fresh selected-JTAG reconfirmation session;
perform one exact formal bootstrap;
execute Arm A;
execute full Arm B;
create and publish one authoritative final report/evidence package.
```

Authorized JTAG and hardware operations:

```text
Fresh R7 JTAG reconfirmation:
    one independent read-only Hardware Manager session;
    five refresh samples;
    zero program operations.

Bootstrap:
    one exact formal program in BOOTSTRAP mode;
    one independent read-only DONE confirmation session;
    one >=5-second wait;
    one warm reboot;
    one exact pinned-driver load;
    formal identity/DONE proof.

Arm A:
    one exact R1e program in TRANSITION mode;
    one independent read-only DONE confirmation session;
    one >=10-second wait;
    one warm reboot;
    one exact pinned-driver load;
    full R1e telemetry;
    final DONE.

Arm B:
    one exact formal program in TRANSITION mode;
    one independent read-only DONE confirmation session;
    one >=5-second wait;
    one warm reboot;
    one exact pinned-driver load;
    full formal-control telemetry;
    final DONE.
```

Maximum:

```text
READ_ONLY_R7_JTAG_RECONFIRMATION_SESSIONS=
    1

R7_JTAG_RECONFIRMATION_SAMPLES=
    5

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
FPGA source edit;
new FPGA source commit;
DCP mutation;
post-program observer weakening;
second bootstrap;
second Arm-A sample;
second Arm-B sample;
fourth FPGA program;
fallback to legacy HS2;
fallback to another target;
JTAG-frequency change;
cold start;
power cycle;
physical action during R7;
JTAG/cable reseat during R7;
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
C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\
```

Required structure:

```text
00_R6_INPUT\
01_ARTIFACT_IDENTITY\
02_MODE_AWARE_OBSERVER\
03_HOST_TOOL_PREFLIGHT\
04_HOST_BASELINE\
05_JTAG_RECONFIRMATION\
06_PRE_BOOTSTRAP_SAFETY\
07_FORMAL_BOOTSTRAP\
08_ARM_A_R1E\
09_ARM_B_FORMAL\
10_ANALYSIS\
11_FINAL\
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
READ_ONLY_R7_JTAG_RECONFIRMATION_SESSIONS=0
R7_JTAG_RECONFIRMATION_SAMPLES=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
HISTORICAL_PRETASK_COLD_RESET=YES_RECORDED_R5
COLD_STARTS_DURING_R7=0
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
R4 programming boundary;
R5/R6 target and pre-DONE gates;
R7 mode-aware observer;
R7 formal bootstrap;
Arm A;
full Arm B;
lifecycle/log/probe analysis;
final formal state;
complete operation accounting.
```

Earlier reports remain preserved in Git history.

Do not create a competing second final report.

===================================================================== 7. P0 — R6 EVIDENCE AND ARTIFACT IDENTITY

Preserve and verify the exact R6 report/evidence found in Section 0.

Locate the R1e bit only in bounded known locations:

```text
R3/R4/R5/R6 task roots;
R3/R4/R5/R6 evidence packages;
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

Rehash exact formal bit:

```text
FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
```

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

with zero live JTAG and zero programs.

===================================================================== 8. P1 — MODE-AWARE PROGRAMMING OBSERVER

Purpose:

```text
allow stable DONE=0 only for the initial bootstrap from unconfigured or
otherwise unknown SRAM;

preserve PRE_PROGRAM_DONE=1 for Arm A and Arm B transitions.
```

Create task-local:

```text
scripts\program_once_mode_aware.tcl
scripts\Run-ProgramOnceModeAware.ps1
```

Accepted modes:

```text
BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM

TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE
```

No other mode is accepted.

────────

8.1 Pre-program sampling common to both modes

Within the same Hardware Manager session that will program:

```text
select the exact R7 target;
require one exact FPGA device;
record target/device property inventories;
perform five consecutive pre-program refresh_hw_device operations;
wait approximately 0.25 seconds between samples;
record DONE after every refresh.
```

Required common gate:

```text
DONE_PROPERTY_AVAILABLE=
    YES

PREPROGRAM_DONE_SAMPLES=
    5

PREPROGRAM_DONE_READABLE=
    YES_5_OF_5

PREPROGRAM_DONE_STABLE=
    YES

TARGET_PART_IDCODE_STABLE=
    YES
```

If DONE is unreadable or changes:

```text
PROGRAM_PRECONDITION=
    FAIL_UNREADABLE_OR_UNSTABLE_DONE
```

No program invocation.

────────

8.2 Bootstrap mode

For:

```text
MODE=
    BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM
```

Allowed stable sample sets:

```text
0,0,0,0,0
or
1,1,1,1,1
```

Required:

```text
PREPROGRAM_DONE_VALUE=
    0_OR_1_STABLE

PREPROGRAM_DONE_0_ACCEPTED=
    YES_BOOTSTRAP_MODE_ONLY

PREPROGRAM_DONE_1_ACCEPTED=
    YES_BOOTSTRAP_MODE
```

A stable pre-program DONE=1 does not prove image identity.

No runtime identity is required before bootstrap.

────────

8.3 Transition mode

For:

```text
MODE=
    TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE
```

Required sample set:

```text
1,1,1,1,1
```

Required task-provided receipt:

```text
PROVEN_CONFIGURED_IMAGE_RECEIPT=
    FORMAL_READY_RECEIPT
    or
    VALID_ARM_A_RECEIPT
```

For Arm A:

```text
receipt=
    FORMAL_READY_RECEIPT
```

For Arm B:

```text
receipt=
    VALID_ARM_A_RECEIPT
    or
    ARM_A_TERMINAL_SAFE_DONE1_RECEIPT
```

A stable pre-program DONE=0 in TRANSITION mode:

```text
PROGRAM_PRECONDITION=
    FAIL_PROVEN_CONFIGURED_IMAGE_LOST
```

No program invocation.

────────

8.4 Post-program gates — unchanged for both modes

The following logic must remain equivalent to the accepted R6 observer:

```text
exactly one `program_hw_devices`;

exact vendor stdout:
    [Labtools 27-3164] End of startup status: HIGH;

program-return marker after vendor startup HIGH;

same-session REGISTER.IR.BIT5_DONE=1;

process exit code=0;

no timeout;

no program error;

no retry loop;

never query REGISTER.IR.BIT4_EOS.
```

Required success:

```text
PROGRAM_RESULT=
    PASS_STARTUP_HIGH_DONE_1

PROGRAM_INVOCATIONS=
    1

PROGRAM_RETRIES=
    0
```

No post-program gate is relaxed.

────────

8.5 Auditable observer delta

Create:

```text
02_MODE_AWARE_OBSERVER\
    R6_TO_R7_OBSERVER_DIFF.patch

02_MODE_AWARE_OBSERVER\
    OBSERVER_DELTA_CLASSIFICATION.md
```

Require:

```text
OBSERVER_DELTA_CLASSIFICATION=
    PREPROGRAM_DONE_MODE_AND_RECEIPT_ONLY

POSTPROGRAM_VENDOR_STARTUP_LOGIC_CHANGED=
    NO

POSTPROGRAM_DONE_LOGIC_CHANGED=
    NO

PROGRAM_INVOCATION_COUNT_LOGIC_CHANGED=
    NO

NO_RETRY_LOGIC_CHANGED=
    NO

TARGET_SELECTOR_CHANGED=
    NO

JTAG_FREQUENCY_CHANGED=
    NO
```

Any extra semantic change:

```text
BLOCKED_OBSERVER_DELTA_OUTSIDE_PREPROGRAM_CONTRACT
```

===================================================================== 9. P2 — OBSERVER FIXTURES AND R6 REPLAY

Run fixtures before live JTAG.

Required fixtures:

```text
B0:
    bootstrap mode;
    stable pre-DONE 0;
    startup HIGH;
    post-DONE 1;
    expected PASS.

B1:
    bootstrap mode;
    stable pre-DONE 1;
    startup HIGH;
    post-DONE 1;
    expected PASS.

B2:
    bootstrap mode;
    pre-DONE unreadable;
    expected FAIL before program.

B3:
    bootstrap mode;
    pre-DONE 0,0,1,1,1;
    expected FAIL before program.

B4:
    bootstrap mode;
    startup LOW;
    expected consumed one program and FAIL no retry.

T0:
    transition mode;
    stable pre-DONE 1;
    valid receipt;
    startup HIGH;
    post-DONE 1;
    expected PASS.

T1:
    transition mode;
    stable pre-DONE 0;
    valid receipt;
    expected FAIL before program.

T2:
    transition mode;
    stable pre-DONE 1;
    missing receipt;
    expected FAIL before program.

T3:
    transition mode;
    stable pre-DONE 1;
    invalid receipt role;
    expected FAIL before program.

C0:
    any mode;
    duplicate program invocation marker;
    expected FAIL.

C1:
    any mode;
    BIT4_EOS query present;
    expected static-audit FAIL.

C2:
    any mode;
    selected target mismatch;
    expected FAIL before program.
```

Replay the exact R6 evidence.

Required:

```text
R6_REPLAY_SELECTED_TARGET=
    PASS

R6_REPLAY_PREPROGRAM_DONE=
    STABLE_0

R6_OLD_OBSERVER_CLASSIFICATION=
    BLOCKED_PREPROGRAM_DONE_NOT_1

R7_BOOTSTRAP_PRECONDITION_REPLAY=
    PASS_STABLE_DONE_0_ACCEPTED

R6_RETROACTIVE_PROGRAM_RESULT=
    NOT_CREATED

R6_FPGA_PROGRAMS_REMAIN=
    0
```

Do not retroactively claim that R6 programmed anything.

Required fixture result:

```text
MODE_AWARE_OBSERVER_FIXTURES=
    PASS_ALL

R6_REPLAY=
    PASS_EXPECTED_CONTRACT_DIFFERENCE
```

Any failure:

```text
BLOCKED_MODE_AWARE_OBSERVER_FIXTURE_OR_REPLAY
```

with zero live JTAG.

===================================================================== 10. P3 — FROZEN HOST-TOOL FIXTURE GATE

Recover exact frozen R3/R4/R6 tools and require manifest hash equality.

Run no-hardware fixtures for:

```text
target selector;
program transcript parser;
Python BAR parser;
0xFFFFFFFF identity rejection;
formal identity acceptance;
lifecycle coherent read;
expected count 132584734;
ordered-log count/overflow;
probe invariants;
Wilson interval;
zero-NACK upper bound;
formal R1e-page-zero.
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

with zero live JTAG.

===================================================================== 11. P4 — FRESH UBUNTU BASELINE

Run two independent read-only SSH sessions across at least three seconds.

Record:

```text
hostname;
user;
kernel;
boot ID;
uptime;
UTC.
```

Require:

```text
same hostname/user;
kernel=7.0.0-29-generic;
same boot ID;
monotonic uptime;
no observed reboot/shutdown.
```

Set:

```text
R7_HOST_BASELINE=
    PASS_2_OF_2

R7_BOOT_ID_BASELINE=
```

Read-only next-boot gate must prove the next warm reboot remains kernel 29.

No GRUB write.

Failure:

```text
BLOCKED_R7_HOST_BASELINE_OR_NEXT_BOOT_KERNEL
```

with zero live JTAG.

===================================================================== 12. P5 — FRESH SELECTED-JTAG RECONFIRMATION

R6 already established 10/10 transport stability and performed no mutation.

R7 requires one new independent read-only reconfirmation session.

Run:

```text
one Hardware Manager session;
exact selected target;
five refresh_hw_device samples;
approximately 0.5 seconds between samples;
zero program operations.
```

Require in every sample:

```text
target count=1;
canonical ID Xilinx/80802026a98b01;
same full target-path policy;
device count=1;
part xc7a35t;
IDCODE 0362D093;
DONE readable;
DONE stable;
zero refresh errors.
```

Expected but not mandatory historical value:

```text
DONE=0
```

Allowed stable values:

```text
0
or
1.
```

No image identity is inferred.

Required:

```text
READ_ONLY_R7_JTAG_RECONFIRMATION_SESSIONS=
    1

R7_JTAG_RECONFIRMATION_SAMPLES=
    5

R7_PREPROGRAM_DONE_VALUE=

R7_JTAG_RECONFIRMATION_GATE=
    PASS_5_OF_5
```

Any failure:

```text
BLOCKED_R7_SELECTED_JTAG_NOT_STABLE
```

No program.

===================================================================== 13. P6 — PRE-BOOTSTRAP HOST SAFETY DISCOVERY

The current runtime identity is not a prerequisite.

Read only:

```text
kernel/boot ID;
PCIe endpoint count and identities;
link/BARs if endpoint exists;
loaded modules named xdma;
binding/nodes if present;
node owners;
task DMA count;
kernel/AER health.
```

Required:

```text
kernel=7.0.0-29-generic;
next reboot remains kernel 29;
zero or one expected 10ee:7011/subsystem 0007 endpoint;
endpoint absence accepted before bootstrap;
no foreign/multiple FPGA endpoint;
no wrong same-name xdma module;
driver/node absence accepted before bootstrap;
no node owner;
zero task DMA;
no fatal kernel/AER issue;
exact formal bit available;
R7 JTAG reconfirmation PASS.
```

Record any current reader output as contextual only.

0xFFFFFFFF remains unproven.

Do not unload/unbind.

Do not reset/rescan PCIe.

Unsafe state:

```text
BLOCKED_UNSAFE_PRE_BOOTSTRAP_HOST_STATE
```

with zero programs.

===================================================================== 14. P7 — MANDATORY EXACT FORMAL BOOTSTRAP

Role:

```text
PROGRAM_ROLE=
    FORMAL_BOOTSTRAP

OBSERVER_MODE=
    BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM
```

Before program:

```text
rehash exact formal bit;
verify exact selected target;
verify exact part/IDCODE;
verify R7 JTAG reconfirmation PASS;
verify no node owner;
verify zero task DMA;
verify operation ledger.
```

Run the mode-aware observer once.

Accept pre-program:

```text
stable DONE=0
or
stable DONE=1.
```

Require post-program:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no timeout;
no retry.
```

Open one independent read-only session using the same selected JTAG.

Require:

```text
same canonical target;
same part/IDCODE;
fresh independent DONE=1.
```

Wait:

```text
>=5.000000 seconds
```

from the later accepted same-QPC marker.

Perform one warm reboot.

Require:

```text
host disappears;
host returns;
new boot ID relative to R7_BOOT_ID_BASELINE;
kernel=7.0.0-29-generic.
```

Before loader:

```text
one expected endpoint;
10ee:7011 / subsystem 0007 / class 058000;
Gen1 x1;
BAR0=131072;
BAR1=65536;
Python BAR parser PASS;
accepted clean loader-entry state;
no wrong xdma;
no node owner.
```

Invoke exact loader once with fresh directory:

```text
/home/vcdeagent1/FPGA_AHD_HOST/
v41_nvp_r1e_r7/bootstrap_driver
```

Require:

```text
loader exit=0;
exact module path/hash/version/vermagic;
expected 21-node set;
exact binding;
kernel/AER health PASS.
```

Verify with both readers:

```text
BLOCK_ID=0xA40A0C07
PROTOCOL=0x0000400B
CAPABILITIES=0x00031002
DIAGNOSTIC_MAGIC=0
```

Fresh selected-JTAG read-only session:

```text
DONE=1
```

Create signed/hashed task receipt:

```text
FORMAL_READY_RECEIPT
```

Receipt includes:

```text
formal bit SHA;
program transcript SHA;
same-session DONE;
independent DONE;
boot ID;
kernel;
BAR geometry;
driver/module identity;
formal runtime identity;
diagnostic magic;
timestamp;
operation-ledger state.
```

Required:

```text
FORMAL_BOOTSTRAP_RESULT=
    PASS_FORMAL_READY

FORMAL_READY=
    YES

FORMAL_READY_RECEIPT=
    PASS
```

No second bootstrap.

Failure means hard stop.

Bootstrap is not Arm B.

===================================================================== 15. P8 — ARM-A ENTRY GATE

Immediately before Arm A prove read only:

```text
FORMAL_READY_RECEIPT valid;
kernel 29;
same selected JTAG;
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

Required:

```text
PROGRAM_ROLE=
    ARM_A_R1E

OBSERVER_MODE=
    TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE

PROVEN_CONFIGURED_IMAGE_RECEIPT=
    FORMAL_READY_RECEIPT
```

===================================================================== 16. ARM A — EXACT R1e EXTENDED OBSERVABILITY

Immediately before program:

```text
rehash exact R1e bit;
verify bit/source/DCP manifest;
verify selected adapter/target;
verify formal-ready receipt;
verify operation ledger.
```

Run the mode-aware observer once in transition mode.

Require pre-program:

```text
DONE samples=1,1,1,1,1;
FORMAL_READY_RECEIPT valid.
```

Require post-program:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Run one independent immediate read-only selected-JTAG session.

Require:

```text
same selected target;
fresh DONE=1.
```

Create:

```text
ARM_A_TERMINAL_SAFE_DONE1_RECEIPT
```

after the independent DONE gate.

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
v41_nvp_r1e_r7/arm_a_driver
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
fresh final DONE=1.
```

Classify:

```text
R1E_NVP_PASS
R1E_NVP_FAIL
R1E_INFRASTRUCTURE_INVALID
```

No second Arm-A run.

===================================================================== 17. P9 — ARM-B ENTRY GATE

Arm B is mandatory whenever:

```text
the selected target remains safe;
one program authorization remains;
exact formal bit is available.
```

Required:

```text
PROGRAM_ROLE=
    ARM_B_FORMAL

OBSERVER_MODE=
    TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE
```

Accepted receipt:

```text
VALID_ARM_A_RECEIPT
or
ARM_A_TERMINAL_SAFE_DONE1_RECEIPT
```

If Arm A became infrastructure-invalid after a valid program but the
independent post-program DONE=1 receipt exists, Arm B may proceed as safe final
control/restoration.

Before program require:

```text
stable pre-program DONE=1;
accepted Arm-A receipt;
same selected target;
no node owner;
zero DMA.
```

===================================================================== 18. ARM B — FULL EXACT FORMAL CONTROL AND FINAL RESTORE

Rehash exact formal bit.

Run the mode-aware observer once in transition mode.

Require pre-program:

```text
DONE samples=1,1,1,1,1;
accepted Arm-A receipt.
```

Require post-program:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Run one independent immediate read-only selected-JTAG session.

Require:

```text
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
v41_nvp_r1e_r7/arm_b_driver
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

===================================================================== 19. SCIENTIFIC ANALYSIS

────────

19.1 Arm-A lifecycle

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

19.2 Ordered NACK records

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

19.3 Address-probe statistics

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

19.4 Control-flow/log reconciliation

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

19.5 Combined interpretation

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

The observer-contract change and selected JTAG are infrastructure context only.

Do not infer an NVP cause from either.

===================================================================== 20. PAIRED A/B CLASSIFICATION

Use only R7 Arm A and Arm B.

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

===================================================================== 21. EVIDENCE AND PUBLICATION

Evidence repository:

```text
lukaszsudul/AHD-diagnostic-evidence
```

Existing path:

```text
v41-nvp-r1e-extended-observability-r1/
```

Preserve all existing Git history.

Add R7 evidence under:

```text
v41-nvp-r1e-extended-observability-r1/r7/
```

At the path root update/create the one authoritative:

```text
V41_NVP_R1E_EXTENDED_OBSERVABILITY_FINAL_REPORT.md
```

Do not force-push or delete historical evidence.

Required evidence:

```text
verbatim R7 prompt;
R6 report/evidence identities;
exact bit identities;
R6-to-R7 observer diff;
mode-aware observer source;
all observer fixtures;
R6 historical-log replay;
frozen target-selector/tool identities;
fresh host baseline;
five-sample selected-JTAG reconfirmation;
pre-bootstrap host safety discovery;
bootstrap raw pre-DONE/program/reboot/driver/identity/DONE;
formal-ready receipt;
Arm-A raw pre-DONE/program/reboot/driver/telemetry/DONE;
Arm-A receipt;
Arm-B raw pre-DONE/program/reboot/driver/telemetry/DONE;
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
V41_NVP_R1E_R7_COMPLETE_MEASUREMENT_EVIDENCE.zip
V41_NVP_R1E_R7_COMPLETE_MEASUREMENT_EVIDENCE_SHA256.txt
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

===================================================================== 22. REQUIRED SINGLE FINAL REPORT BLOCK

The one final report must end with:

```text
TASK=
    V41_NVP_R1E_MODE_AWARE_BOOTSTRAP_FROM_DONE0_AND_COMPLETE_PAIRED_AB_R7

FINAL_REPORT_COUNT=
    1

R6_REPORT_SHA256=
R6_EVIDENCE_COMMIT=
R6_EVIDENCE_PACKAGE_SHA256=

R6_STOP_CLASSIFICATION=
    BLOCKED_R6_STABLE_DONE_0_VS_FROZEN_PREPROGRAM_DONE_1_CONTRACT

R6_SELECTED_JTAG=
    Xilinx/80802026a98b01

R6_JTAG_TRANSPORT_STABILITY=
    PASS_10_OF_10

R6_PREPROGRAM_DONE=
    STABLE_0

R6_FPGA_PROGRAMS=
    0

R7_OBSERVER_DELTA_CLASSIFICATION=
    PREPROGRAM_DONE_MODE_AND_RECEIPT_ONLY

R7_BOOTSTRAP_PREPROGRAM_DONE_0_ACCEPTED=
    YES

R7_TRANSITION_PREPROGRAM_DONE_0_ACCEPTED=
    NO

R7_POSTPROGRAM_GATES_CHANGED=
    NO

MODE_AWARE_OBSERVER_SHA256=
MODE_AWARE_OBSERVER_FIXTURES=
R6_REPLAY_RESULT=

R7_SELECTED_JTAG_CANONICAL_ID=
    Xilinx/80802026a98b01

R7_FULL_JTAG_TARGET_PATH=

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

R7_HOST_BASELINE=
R7_BOOT_ID_BASELINE=
NEXT_REBOOT_KERNEL_PROVEN=

READ_ONLY_R7_JTAG_RECONFIRMATION_SESSIONS=
    1

R7_JTAG_RECONFIRMATION_SAMPLES=
    5

R7_PREPROGRAM_DONE_VALUE=
R7_JTAG_RECONFIRMATION_GATE=

PRE_BOOTSTRAP_ENDPOINT_STATE=
PRE_BOOTSTRAP_DRIVER_STATE=
PRE_BOOTSTRAP_NODE_OWNERS=
PRE_BOOTSTRAP_DMA=
PRE_BOOTSTRAP_HOST_SAFETY_GATE=

FORMAL_BOOTSTRAP_OBSERVER_MODE=
    BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM

FORMAL_BOOTSTRAP_PREPROGRAM_DONE_SAMPLES=
FORMAL_BOOTSTRAP_PREPROGRAM_DONE_VALUE=
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
FORMAL_READY_RECEIPT=

ARM_A_OBSERVER_MODE=
    TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE

ARM_A_PREPROGRAM_DONE_SAMPLES=
ARM_A_PREPROGRAM_DONE_VALUE=
ARM_A_PROVEN_CONFIGURED_RECEIPT=
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
ARM_A_TERMINAL_SAFE_DONE1_RECEIPT=

ARM_B_OBSERVER_MODE=
    TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE

ARM_B_PREPROGRAM_DONE_SAMPLES=
ARM_B_PREPROGRAM_DONE_VALUE=
ARM_B_PROVEN_CONFIGURED_RECEIPT=
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

HISTORICAL_PRETASK_COLD_RESET=
    YES_RECORDED_R5

COLD_STARTS_DURING_R7=
    0

PHYSICAL_ACTIONS_DURING_TASK=
    0

JTAG_FREQUENCY_CHANGES=
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

===================================================================== 23. HARD STOPS

Stop before live JTAG if:

```text
R6 evidence identity cannot be proven;
R1e or formal bit hash differs;
observer diff contains anything beyond the pre-program mode/receipt contract;
mode-aware observer fixtures fail;
R6 replay fails;
frozen target-selector/host-tool hashes or fixtures fail.
```

Stop after fresh JTAG reconfirmation if:

```text
target count !=1;
canonical ID differs;
part/IDCODE differs;
DONE unreadable;
DONE changes;
refresh error occurs;
stability is not 5/5.
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

Stop bootstrap before program if:

```text
pre-DONE is unreadable;
pre-DONE is unstable;
mode is not bootstrap;
target/part/IDCODE changes.
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

Stop Arm A or Arm B before program if:

```text
transition-mode pre-DONE !=1;
required configured-image receipt is absent/invalid;
selected target changes;
node owner exists;
task DMA is nonzero.
```

Stop Arm A or Arm B after program if:

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
post-program gate weakening;
bootstrap-mode use for Arm A or Arm B;
transition-mode acceptance of DONE=0;
fallback to another JTAG;
JTAG-frequency adjustment;
second bootstrap;
program retry;
fourth FPGA program;
second Arm-A sample;
second Arm-B sample;
build;
source patch;
new bit;
physical recovery during R7;
Phase-3 work.
```

Arm B must still be attempted as a full control after an Arm-A terminal result
when the selected target remains safe, an accepted Arm-A DONE1 receipt exists,
and one program authorization remains.

===================================================================== 24. BEGIN

```text
save and hash this prompt
    ->
preserve and verify R6 evidence
    ->
locate and rehash exact existing R1e bit
    ->
rehash exact formal bit
    ->
create mode-aware observer with only the pre-program contract delta
    ->
run all observer fixtures
    ->
replay R6 as:
        old observer BLOCKED
        R7 bootstrap precondition PASS
        no retroactive program
    ->
verify frozen selected-target and host tools
    ->
establish fresh Ubuntu baseline and next-boot kernel
    ->
run one selected-JTAG read-only session with five refresh samples
    ->
require stability 5/5
    ->
run pre-bootstrap host safety discovery
    ->
program exact formal bootstrap once in BOOTSTRAP mode
    accepting stable pre-DONE 0 or 1
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
create FORMAL_READY_RECEIPT
    ->
Arm A:
        require transition-mode pre-DONE=1 and formal-ready receipt
        program exact R1e once
        require same-session and independent DONE
        wait at least 10 seconds
        warm reboot
        load exact driver
        collect lifecycle + probe + ordered log + normal telemetry
        final DONE
    ->
Arm B:
        require transition-mode pre-DONE=1 and Arm-A receipt
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
No post-program gate weakening.
No program retry.
No JTAG fallback.
No JTAG-frequency change.
No physical action during R7.
No Phase 3.
No XDMA work.