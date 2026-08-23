CODEX MASTER PROMPT

v41 NVP R1e — selected-new-JTAG bootstrap and complete paired A/B campaign R6

Adopt exact JTAG target Xilinx/80802026a98b01

Reuse the exact existing R1e bitstream; no build, no source change

Fresh transport qualification → mandatory formal bootstrap

→ Arm A R1e → full Arm B formal control → one authoritative final report

FULL OWNER PRE-AUTHORIZATION — NO INTERACTIVE CONFIRMATIONS

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_R1E_SELECTED_NEW_JTAG_BOOTSTRAP_AND_COMPLETE_PAIRED_AB_R6

TASK_CHARACTER:
    NEW_SEPARATELY_AUTHORIZED_HARDWARE_COMPLETION_OF_THE_FROZEN_R1E_EXPERIMENT

PRIMARY_PURPOSE:
    Continue the R1e campaign using the newly selected JTAG adapter that the
    hardware server identifies canonically as:

        Xilinx/80802026a98b01

    Qualify that adapter read-only, establish exact formal Phase 2 through one
    mandatory bootstrap, obtain the complete R1e Arm-A sample, obtain the full
    exact-formal Arm-B control, and leave exact formal Phase 2 active.

CONTROLLED_INFRASTRUCTURE_CHANGE:
    JTAG adapter identity only.

SCIENTIFIC_IMAGE_VARIABLE:
    unchanged.

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

Do not pause to ask for approval of:

```text
task-root creation;
task-local JTAG target-selection adaptation;
target-matcher fixtures;
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

This authorization does not permit any operation outside the explicit scope or
above the numerical limits.

===================================================================== 0. AUTHORITATIVE R5 OUTCOME

R5 POST_COLD_RESET_R2 result supplied by the owner:

```text
UBUNTU_BASELINE=
    PASS_3_OF_3

KERNEL=
    7.0.0-29-generic

R5_REQUIRED_JTAG_ID=
    HS2_210241768436

R5_DISCOVERED_TARGET=
    Xilinx/80802026a98b01

R5_REQUIRED_TARGET_MATCHES=
    0

R5_VALID_JTAG_SAMPLES=
    0_OF_10

R5_DONE=
    UNREADABLE_UNDER_REJECTED_TARGET_IDENTITY

R5_FPGA_PROGRAMS=
    0

R5_WARM_REBOOTS=
    0

R5_DRIVER_LOADS=
    0

R5_MMIO=
    0

R5_DMA=
    0

R5_BOOTSTRAP=
    NOT_RUN

R5_ARM_A=
    NOT_RUN

R5_ARM_B=
    NOT_RUN

R5_FINAL_IMAGE=
    UNPROVEN
```

R5 was blocked only because its target-identity gate still required the prior
HS2 serial.

R6 adopts the newly selected target.

R6 does not amend R5.

At R6 start, locate the exact R5 final report/evidence and record:

```text
R5_REPORT_PATH=
R5_REPORT_SHA256=
R5_EVIDENCE_COMMIT=
R5_EVIDENCE_PACKAGE_SHA256=
```

If a commit cannot be self-read from the report, resolve the containing commit
from the exact public repository path.

Do not invent an evidence identity.

The absence of a self-embedded commit is not a blocker when the exact report
hash, path and containing Git commit are proven.

=====================================================================

1. SELECTED JTAG ADAPTER IDENTITY
=====================================================================

New authoritative JTAG target:

```text
JTAG_ADAPTER_ROLE=
    OWNER_SELECTED_R6_PROGRAMMING_ADAPTER

JTAG_CANONICAL_ID=
    Xilinx/80802026a98b01

JTAG_CANONICAL_SUFFIX=
    /Xilinx/80802026a98b01

LEGACY_HS2_SERIAL=
    210241768436

LEGACY_HS2_REQUIRED=
    NO

LEGACY_HS2_ABSENCE=
    ACCEPTED_EXPECTED

TARGET_COUNT_REQUIRED=
    1

DEVICE_COUNT_REQUIRED=
    1

FPGA_PART_REQUIRED=
    xc7a35t

FPGA_IDCODE_REQUIRED=
    0362D093

JTAG_FREQUENCY_POLICY=
    USE_CURRENT_ADAPTER_DEFAULT_RECORD_ONLY_NO_CHANGE
```

The selected adapter is a controlled infrastructure change.

It is not an NVP scientific variable because:

```text
the same selected adapter is used for:
    formal bootstrap;
    Arm A;
    Arm B;

the source, DCP and bitstreams are frozen;

the adapter does not alter the generated FPGA image.
```

Do not describe the adapter change as proof of any NVP cause.

────────

1.1 Canonical target matching

The full target path may include a server/transport prefix, for example:

```text
<server-prefix>/xilinx_tcf/Xilinx/80802026a98b01
```

Normalize only for target selection:

```text
the target's canonical final path components must equal:
    Xilinx/80802026a98b01

or the full target path must end exactly with:
    /Xilinx/80802026a98b01
```

Do not use a substring-only serial match.

Do not accept:

```text
a similar prefix;
a serial with added or missing characters;
the legacy HS2 target;
the first enumerated target without identity proof.
```

After the first accepted discovery, freeze:

```text
R6_FULL_JTAG_TARGET_PATH=
```

Every later JTAG session in R6 must use:

```text
the same full path;
the same canonical ID;
the same part;
the same IDCODE.
```

If a harmless server prefix changes between independently launched processes,
the canonical ID, server endpoint, transport class and all available target
properties must remain equal; record the exact variation.

Do not silently relax the gate.

────────

1.2 Property policy

Run:

```tcl
list_property <target>
list_property <device>
```

Record every available target/device property.

Do not require an HS2-specific SERIAL property on the selected Xilinx target.

Target identity is proved by:

```text
canonical target path/ID;
exact one-target enumeration;
transport/server identity;
exact part;
exact IDCODE;
stable read-only samples.
```

===================================================================== 2. PRE-TASK STATE AND COLD-RESET CONTEXT

R5 established:

```text
POST_COLD_RESET_UBUNTU_BASELINE=
    PASS_3_OF_3

POST_COLD_RESET_KERNEL=
    7.0.0-29-generic
```

R5 made no hardware mutation.

R6 must nevertheless establish a fresh current baseline.

Record:

```text
HISTORICAL_PRETASK_COLD_RESET=
    YES_RECORDED_BY_R5

NEW_OWNER_COLD_RESET_REPORTED_AFTER_R5=
    NO

COLD_STARTS_DURING_R6=
    0
```

Do not infer current FPGA SRAM content from R5.

The R6 mandatory exact formal bootstrap establishes the first authoritative
application state.

The final scientific report must record the new selected JTAG identity as a
controlled infrastructure input.

Do not discuss mechanical or human handling details in the scientific
interpretation.

Do not delete or rewrite prior raw evidence.

===================================================================== 3. FROZEN R1e SCIENTIFIC CONFIGURATION

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

Frozen parameters:

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

No scientific parameter may change.

===================================================================== 4. EXACT FORMAL BOOTSTRAP AND CONTROL

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

The R6 bootstrap is mandatory.

It is:

```text
a start-state recovery and selected-adapter programming qualification;

not Arm B;

not a scientific paired-control sample.
```

Arm B must still run fully after Arm A.

===================================================================== 5. HOST, DRIVER, AND FROZEN TOOL IDENTITIES

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

Reuse exact passed R3/R4 frozen tools:

```text
programming observer;
Python BAR parser;
accepted AXI-Lite reader;
R1e full reader/decoder;
ordered-log decoder;
lifecycle calculator;
probe statistics calculator.
```

The existing programming observer may be adapted only in its task-local target
selection layer.

The following must remain byte-identical:

```text
program invocation-count logic;
vendor startup HIGH parser;
same-session DONE gate;
process-exit gate;
wait/QPC logic;
no-retry logic.
```

Create and hash a separate target-selector adapter rather than modifying the
scientific reader/decoder.

===================================================================== 6. AUTHORIZATION AND ABSOLUTE LIMITS

Authorized task-local work:

```text
preserve and verify R5 evidence;
create the exact new-target selector;
run target-selector fixtures;
locate and rehash exact R1e/formal bits;
run frozen host-tool fixtures;
perform fresh read-only selected-JTAG qualification;
perform one exact formal bootstrap;
execute Arm A;
execute full Arm B;
create and publish one authoritative final report/evidence package.
```

Authorized JTAG and hardware operations:

```text
JTAG qualification:
    two independent read-only Hardware Manager sessions;
    five refresh samples per session;
    zero program operations.

Bootstrap:
    one exact formal program;
    one independent read-only DONE confirmation session;
    one >=5-second wait;
    one warm reboot;
    one exact pinned-driver load;
    formal identity/DONE proof.

Arm A:
    one exact R1e program;
    one independent read-only DONE confirmation session;
    one >=10-second wait;
    one warm reboot;
    one exact pinned-driver load;
    full R1e telemetry;
    final DONE.

Arm B:
    one exact formal program;
    one independent read-only DONE confirmation session;
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
JTAG-frequency change;
fallback to legacy HS2;
fallback to another target;
cold start;
power cycle;
physical action during R6;
JTAG/cable reseat during R6;
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

===================================================================== 7. TASK ROOT AND EVIDENCE POLICY

Create:

```text
C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6\
```

Required structure:

```text
00_R5_INPUT\
01_ARTIFACT_IDENTITY\
02_TARGET_SELECTOR\
03_HOST_TOOL_PREFLIGHT\
04_HOST_BASELINE\
05_JTAG_STABILITY\
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
READ_ONLY_JTAG_STABILITY_SESSIONS=0
JTAG_STABILITY_SAMPLES=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
HISTORICAL_PRETASK_COLD_RESET=YES_RECORDED_R5
COLD_STARTS_DURING_R6=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS_DURING_TASK=0
FORMAL_REPOSITORY_MUTATIONS=0
```

────────

7.1 One authoritative final report

Create exactly one authoritative final report:

```text
V41_NVP_R1E_EXTENDED_OBSERVABILITY_FINAL_REPORT.md
```

It must integrate:

```text
frozen implementation history;
R3 bitstream completion;
R4 bootstrap boundary;
R5 old-target identity gate;
R6 selected-target qualification;
R6 formal bootstrap;
Arm A;
full Arm B;
lifecycle/log/probe analysis;
final formal state;
complete operation accounting.
```

Earlier reports remain preserved in Git history.

Do not create a competing second final report.

The final scientific report records:

```text
R6_SELECTED_JTAG_CANONICAL_ID=
    Xilinx/80802026a98b01

JTAG_INFRASTRUCTURE_CHANGE=
    OWNER_SELECTED_NEW_ADAPTER_BEFORE_R6
```

It must not claim that the adapter change proves an NVP cause.

===================================================================== 8. P0 — R5 EVIDENCE AND ARTIFACT IDENTITY

Preserve and verify the exact R5 report/evidence found in Section 0.

Locate the R1e bit only in bounded known locations:

```text
R3/R4/R5 task roots;
R3/R4/R5 evidence packages;
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

===================================================================== 9. P1 — TARGET-SELECTOR ADAPTATION AND FIXTURES

Create task-local:

```text
scripts\select_r6_jtag_target.tcl
```

The selector must:

```text
enumerate all targets;
record every full target path;
record all available target properties;
require total target count=1;
normalize the exact one target;
require canonical ID Xilinx/80802026a98b01;
return exactly that target object;
never fall back to first target.
```

Required fixtures:

```text
A:
    localhost:3121/xilinx_tcf/Xilinx/80802026a98b01
    -> PASS

B:
    Xilinx/80802026a98b01
    -> PASS

C:
    Digilent/210241768436
    -> FAIL_OLD_TARGET_NOT_SELECTED

D:
    Xilinx/80802026a98b0
    -> FAIL_NEAR_MATCH

E:
    Xilinx/80802026a98b010
    -> FAIL_NEAR_MATCH

F:
    two targets, one exact new target
    -> FAIL_TARGET_COUNT_NOT_ONE

G:
    two exact matching targets
    -> FAIL_DUPLICATE

H:
    no targets
    -> FAIL_NO_TARGET.
```

Required:

```text
TARGET_SELECTOR_FIXTURES=
    PASS_ALL

TARGET_MATCH_MODE=
    EXACT_CANONICAL_ID_OR_EXACT_PATH_SUFFIX

FALLBACK_TO_FIRST_TARGET=
    NO

LEGACY_HS2_REQUIRED=
    NO
```

Adapt the accepted programming observer only by calling this selector.

Static audit:

```text
program_hw_devices count remains exactly one;
vendor-startup parser unchanged;
same-session DONE gate unchanged;
no retry loop;
no JTAG frequency set_property.
```

Any failure:

```text
BLOCKED_NEW_JTAG_TARGET_SELECTOR
```

with zero live JTAG sessions.

===================================================================== 10. P2 — FROZEN HOST-TOOL FIXTURE GATE

Recover exact accepted R3/R4 tools and require manifest hash equality.

Run no-hardware fixtures for:

```text
programming transcript parser;
startup HIGH/LOW;
same-session DONE;
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

with zero live JTAG sessions.

===================================================================== 11. P3 — FRESH UBUNTU BASELINE

Run three independent read-only SSH sessions across at least five seconds.

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
R6_HOST_BASELINE=
    PASS_3_OF_3

R6_BOOT_ID_BASELINE=
```

Read-only next-boot gate must prove the next warm reboot remains kernel 29.

No GRUB write.

Failure:

```text
BLOCKED_R6_HOST_BASELINE_OR_NEXT_BOOT_KERNEL
```

with zero JTAG sessions.

===================================================================== 12. P4 — SELECTED-JTAG TRANSPORT-STABILITY QUALIFICATION

Run exactly two independent read-only Hardware Manager sessions.

Each session:

```text
uses the selected-target selector;
requires one total target;
freezes/compares the full accepted target path;
opens exact selected target;
requires one device;
requires part xc7a35t;
requires IDCODE 0362D093;
records list_property for target and device;
performs five refresh_hw_device operations;
waits approximately 0.5 seconds between samples;
records DONE after every refresh;
closes cleanly.
```

Required across all ten samples:

```text
canonical target ID exact;
full target path stable or only a documented harmless server prefix variation;
target count=1;
device count=1;
part exact;
IDCODE exact;
DONE readable;
DONE stable;
zero refresh errors;
zero target loss;
zero duplicate target;
zero legacy-HS2 requirement.
```

DONE may be stable 0 or stable 1 before bootstrap.

Required:

```text
READ_ONLY_JTAG_STABILITY_SESSIONS=
    2

JTAG_STABILITY_SAMPLES=
    10

R6_SELECTED_JTAG_CANONICAL_ID=
    Xilinx/80802026a98b01

R6_FULL_JTAG_TARGET_PATH=

JTAG_TRANSPORT_STABILITY_GATE=
    PASS_10_OF_10
```

Any failure:

```text
BLOCKED_SELECTED_JTAG_TRANSPORT_NOT_STABLE
```

No program and no physical action.

===================================================================== 13. P5 — PRE-BOOTSTRAP HOST SAFETY DISCOVERY

The current application identity is not a prerequisite.

Read only:

```text
current kernel/boot ID;
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
JTAG stability PASS.
```

Record any current reader result as contextual only.

0xFFFFFFFF remains unproven.

Do not unload/unbind a current driver.

Do not reset/rescan PCIe.

Unsafe state:

```text
BLOCKED_UNSAFE_PRE_BOOTSTRAP_HOST_STATE
```

with zero programs.

===================================================================== 14. P6 — MANDATORY EXACT FORMAL BOOTSTRAP

Before program:

```text
rehash exact formal bit;
verify selected target full path/canonical ID;
verify exact part/IDCODE;
verify JTAG stability PASS;
verify no node owner;
verify zero task DMA;
verify operation ledger.
```

Program exact formal Phase 2 once through the accepted observer using the R6
selected-target layer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no timeout;
no retry.
```

Open one independent read-only session using the same selected adapter.

Require:

```text
same canonical ID;
same exact target path policy;
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
new boot ID relative to R6_BOOT_ID_BASELINE;
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
endpoint in accepted loader-entry state;
no wrong xdma;
no node owner.
```

Invoke exact loader once with fresh directory:

```text
/home/vcdeagent1/FPGA_AHD_HOST/
v41_nvp_r1e_r6/bootstrap_driver
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

Fresh selected-adapter JTAG:

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
    R6_EXACT_FORMAL_BOOTSTRAP_WITH_SELECTED_JTAG
```

Failure means hard stop.

No second bootstrap.

Bootstrap telemetry is not Arm B.

===================================================================== 15. P7 — ARM-A ENTRY GATE

Immediately before Arm A prove:

```text
kernel=7.0.0-29-generic;
same selected JTAG adapter;
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

===================================================================== 16. ARM A — EXACT R1e EXTENDED OBSERVABILITY

Immediately before programming:

```text
rehash exact R1e bit;
verify bit/source/DCP manifest;
verify selected adapter/target;
verify formal-ready state;
verify operation ledger.
```

Program once through the accepted observer using the R6 selected-target layer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Run one independent immediate read-only session using the same adapter.

Require:

```text
same selected target;
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
v41_nvp_r1e_r6/arm_a_driver
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

===================================================================== 17. ARM B — FULL EXACT FORMAL CONTROL AND FINAL RESTORE

Arm B is mandatory whenever the selected target remains safe and one program
authorization remains.

Rehash exact formal bit.

Program once through the same selected-adapter observer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no retry.
```

Run one independent immediate read-only session with the same adapter.

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
v41_nvp_r1e_r6/arm_b_driver
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

===================================================================== 18. SCIENTIFIC ANALYSIS

────────

18.1 Arm-A lifecycle

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

18.2 Ordered NACK records

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

18.3 Address-probe statistics

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

18.4 Control-flow/log reconciliation

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

18.5 Combined interpretation

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

The selected JTAG adapter identity is infrastructure context only.

Do not infer an NVP cause from the adapter change itself.

===================================================================== 19. PAIRED A/B CLASSIFICATION

Use only R6 Arm A and Arm B.

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

===================================================================== 20. EVIDENCE AND PUBLICATION

Evidence repository:

```text
lukaszsudul/AHD-diagnostic-evidence
```

Existing path:

```text
v41-nvp-r1e-extended-observability-r1/
```

Preserve all existing Git history.

Add R6 evidence under:

```text
v41-nvp-r1e-extended-observability-r1/r6/
```

At the path root update/create the one authoritative:

```text
V41_NVP_R1E_EXTENDED_OBSERVABILITY_FINAL_REPORT.md
```

Do not force-push or delete historical evidence.

Required evidence:

```text
verbatim R6 prompt;
R5 report/evidence identities;
exact bit identities;
target-selector source and fixtures;
full selected-target property inventory;
ten-sample selected-JTAG stability matrix;
host baseline and pre-bootstrap safety discovery;
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
V41_NVP_R1E_R6_COMPLETE_MEASUREMENT_EVIDENCE.zip
V41_NVP_R1E_R6_COMPLETE_MEASUREMENT_EVIDENCE_SHA256.txt
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

===================================================================== 21. REQUIRED SINGLE FINAL REPORT BLOCK

The one final report must end with:

```text
TASK=
    V41_NVP_R1E_SELECTED_NEW_JTAG_BOOTSTRAP_AND_COMPLETE_PAIRED_AB_R6

FINAL_REPORT_COUNT=
    1

R5_REPORT_SHA256=
R5_EVIDENCE_COMMIT=
R5_EVIDENCE_PACKAGE_SHA256=

R5_STOP_CLASSIFICATION=
    BLOCKED_REQUIRED_OLD_HS2_TARGET_NOT_PRESENT

R5_DISCOVERED_TARGET=
    Xilinx/80802026a98b01

R5_FPGA_PROGRAMS=
    0

R6_JTAG_INFRASTRUCTURE_CHANGE=
    OWNER_SELECTED_NEW_ADAPTER_BEFORE_R6

R6_SELECTED_JTAG_CANONICAL_ID=
    Xilinx/80802026a98b01

R6_FULL_JTAG_TARGET_PATH=
R6_JTAG_TRANSPORT_CLASS=
R6_JTAG_SERVER_ENDPOINT=
R6_JTAG_FREQUENCY_REPORTED=
R6_JTAG_FREQUENCY_CHANGED=
    NO

LEGACY_HS2_REQUIRED=
    NO

TARGET_SELECTOR_FIXTURES=
TARGET_MATCH_MODE=
    EXACT_CANONICAL_ID_OR_EXACT_PATH_SUFFIX

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

R6_HOST_BASELINE=
R6_BOOT_ID_BASELINE=
NEXT_REBOOT_KERNEL_PROVEN=

READ_ONLY_JTAG_STABILITY_SESSIONS=
    2

JTAG_STABILITY_SAMPLES=
    10

JTAG_PRECHECK_DONE_VALUE=
JTAG_TRANSPORT_STABILITY_GATE=

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

HISTORICAL_PRETASK_COLD_RESET=
    YES_RECORDED_R5

COLD_STARTS_DURING_R6=
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

===================================================================== 22. HARD STOPS

Stop before live JTAG if:

```text
R5 evidence identity cannot be proven;
R1e or formal bit hash differs;
target-selector fixtures fail;
frozen host-tool hashes/fixtures fail.
```

Stop after selected-JTAG stability if:

```text
total target count !=1;
canonical ID differs;
full target policy is inconsistent;
part/IDCODE differs;
DONE unreadable;
DONE changes;
refresh error occurs;
target disappears or duplicates;
stability is not 10/10.
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
fallback to old HS2;
fallback to another JTAG target;
JTAG-frequency adjustment;
second bootstrap;
program retry;
fourth FPGA program;
second Arm-A sample;
second Arm-B sample;
build;
source patch;
new bit;
physical recovery during R6;
Phase-3 work.
```

Arm B must still be attempted as a full control after an Arm-A terminal result
when the selected target remains safe and one program authorization remains.

===================================================================== 23. BEGIN

```text
save and hash this prompt
    ->
preserve and verify R5 evidence
    ->
locate and rehash exact existing R1e bit
    ->
rehash exact formal bit
    ->
create and fixture-test exact selected-target selector
    ->
verify frozen R3/R4 host tools and fixtures
    ->
establish fresh Ubuntu baseline and next-boot kernel
    ->
run two independent read-only sessions on:
        Xilinx/80802026a98b01
    with five refresh samples each
    ->
require selected-JTAG stability 10/10
    ->
run pre-bootstrap host safety discovery
    ->
program exact formal bootstrap once with selected JTAG
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
        program exact R1e once with the same selected JTAG
        require same-session and independent DONE
        wait at least 10 seconds
        warm reboot
        load exact driver
        collect lifecycle + probe + ordered log + normal telemetry
        final DONE
    ->
Arm B:
        program exact formal once with the same selected JTAG
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
No JTAG fallback.
No JTAG-frequency change.
No physical action during R6.
No Phase 3.
No XDMA work.