# CODEX MASTER PROMPT
## v41 NVP — 25-kHz same-bit paired A/B R1c
## Kernel 7.0.0-29 gate, corrected BAR parser, explicit pinned-module path,
## full Arm-B functional control, and agreed evidence publication
## ZERO BUILD — ZERO FPGA SOURCE CHANGE — EXACT EXISTING BITS ONLY

```text
PROJECT:
    AHD Capture Card

TASK:
    V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C

PURPOSE:
    Obtain the first valid paired functional comparison of:

        Arm A:
            the exact existing 25-kHz diagnostic image

        Arm B:
            the exact formal Phase-2 50-kHz image

    after the owner restored Ubuntu kernel `7.0.0-29-generic`.

R1C_SCOPE:
    unchanged FPGA experiment;
    same 25-kHz bit;
    no rebuild;
    no FPGA-source change;
    corrected task-local infrastructure only.

MANDATORY_R1C_INFRASTRUCTURE_CORRECTIONS:

    1. Kernel:
        current and post-reboot kernel must be exactly
        `7.0.0-29-generic`.

    2. BAR parser:
        no Bash `16#0x...` arithmetic;
        use the preflighted Python parser defined in this prompt.

    3. XDMA loader:
        invoke the accepted loader through `/usr/bin/bash`;
        pass the exact absolute module path containing:
        `dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko`.

    4. Evidence:
        preserve this prompt verbatim;
        seal local evidence before network publication;
        publish to the agreed new R1c path.

    5. Arm B:
        full interleaved functional control;
        program + wait + reboot + kernel gate + exact loader +
        BAR gate + identity + T0/T1 telemetry + final DONE;
        not restoration-only.

BUILD_COUNT:
    0

FPGA_SOURCE_CHANGES:
    0

FPGA_PROGRAM_LIMIT:
    2

WARM_REBOOT_LIMIT:
    2

PROGRAM_RETRIES:
    0

FINAL_ACTIVE_IMAGE:
    exact formal Phase 2

HARD_STOP_AFTER_R1C_PAIR:
    YES
```

=====================================================================
0. AUTHORITATIVE PRIOR EVIDENCE
=====================================================================

R1 evidence:

```text
R1_EVIDENCE_COMMIT=
    5a81f5b115dddcdddd809a655fced115e113585e

R1_RESULT=
    INCONCLUSIVE_INFRASTRUCTURE

R1_STOP=
    unsupported REGISTER.IR.BIT4_EOS property after successful programming
```

R1b evidence:

```text
R1B_EVIDENCE_COMMIT=
    b773cf667fc6f3277e518535a3e070f3f8a59303

R1B_RESULT=
    INCONCLUSIVE_INFRASTRUCTURE

R1B_ARM_A_PROGRAM=
    PASS_VENDOR_STARTUP_HIGH_SAME_SESSION_DONE_1

R1B_ARM_A_REBOOT=
    PASS

R1B_TERMINAL_BLOCKER=
    RUNNING_KERNEL_7.0.0-30-generic
    VERSUS
    PINNED_MODULE_VERMAGIC_7.0.0-29-generic

R1B_LOADER_INVOCATIONS=
    0

R1B_ARM_A_TELEMETRY=
    NOT_RUN

R1B_ARM_B_ROLE=
    RESTORATION_ONLY_NOT_FUNCTIONAL_CONTROL

R1B_FINAL_FPGA=
    EXACT_FORMAL_PHASE2_DONE_1

R1B_FINAL_DRIVER=
    NOT_LOADED
```

R1b also exposed a non-terminal BAR parser defect:

```text
BAD_INPUT_TOKEN_EXAMPLE=
    0x00000000f6e1ffff

BAD_BASH_EXPRESSION=
    16#0x00000000f6e1ffff

RESULT=
    value too great for base

R1B_BAR0_BYTES=
    blank

R1B_BAR1_BYTES=
    blank
```

The kernel/vermagic mismatch was independently sufficient to stop R1b.

R1c must fix both infrastructure issues before Arm A programming:

```text
KERNEL_GATE=
    EXACT_7.0.0-29

BAR_PARSER_GATE=
    PASS_131072_65536
```

Owner declaration:

```text
OWNER_CHANGED_KERNEL_TO=
    7.0.0-29-generic
```

This is an input declaration, not a fresh observation.

Codex must verify it.

=====================================================================
1. EXACT REUSED ARTIFACTS
=====================================================================

------------------------------------------------------------
1.1 25-kHz diagnostic image
------------------------------------------------------------

```text
SOURCE_BRANCH=
    diag/v41-nvp-i2c-25khz-r1

SOURCE_COMMIT=
    f007dc172d43d30b02729755e60382f8ce3dbff4

SOURCE_TREE=
    b8f87966c8021396acb6341bd2d7d86a10fd7f13

TRACKED_FUNCTIONAL_DIFF_COUNT=
    1

TRACKED_FUNCTIONAL_DIFF=
    rtl/top/ahd_capture_top_xdma.sv:
        .I2C_HZ(50000)
        ->
        .I2C_HZ(25000)

BIT_FILENAME=
    ahd_capture_v41_i2c_25khz_r1.bit

BIT_SIZE_BYTES=
    2192144

BIT_SHA256=
    B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191

BUILD_PACKAGE_SHA256=
    918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A
```

Expected original local bit path:

```text
C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\
04_BUILD\FULL_BUILD_EVIDENCE\artifacts\
ahd_capture_v41_i2c_25khz_r1.bit
```

The bit may be recovered only from:

```text
that exact local path;
or the exact sealed build package with the expected package SHA-256.
```

No DCP-to-bit export is allowed.

------------------------------------------------------------
1.2 Exact formal Phase-2 control
------------------------------------------------------------

```text
FORMAL_BRANCH=
    v41/xdma-v40.1.0-base

FORMAL_CHECKPOINT_COMMIT=
    c89e88bcdf389614c884fb129e8b2d42a585bccb

FORMAL_CHECKPOINT_TREE=
    417820c69c134161fcafae0947dc5976919814d1

FORMAL_TAG=
    v41.0.0-phase2-p2

BIT_FILENAME=
    ahd_capture_v41_phase2_p1.bit

BIT_SIZE_BYTES=
    2192144

BIT_SHA256=
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

Required artifact accounting:

```text
DIAGNOSTIC_BUILD_REUSED=
    YES_EXACT_ARTIFACT

FULL_BUILDS=
    0

SYNTHESIS_RUNS=
    0

IMPLEMENTATION_RUNS=
    0

BITSTREAMS_GENERATED=
    0

FPGA_SOURCE_CHANGES=
    0

FORMAL_REPOSITORY_MUTATIONS=
    0
```

Any hash, size, filename, source-commit, or source-tree mismatch:

```text
BLOCKED_EXACT_ARTIFACT_IDENTITY
```

with zero hardware operations.

=====================================================================
2. HOST, DRIVER, AND TOOL IDENTITIES
=====================================================================

Ubuntu DUT:

```text
IP=
    10.132.1.111

USER=
    vcdeagent1

CREDENTIAL_FILE=
    C:\FPGA\VCDE-DUT-1.txt
```

Required kernel:

```text
KERNEL=
    7.0.0-29-generic
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

Exact pinned module path:

```text
/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
```

Required module SHA-256:

```text
1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
```

Required module version/vermagic:

```text
VERSION=
    2025.2.0

VERMAGIC_PREFIX=
    7.0.0-29-generic
```

Accepted loader path:

```text
/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh
```

Required loader SHA-256:

```text
7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
```

Loader mode:

```text
0644
```

Never use:

```text
modprobe xdma
relative module path
symlink-selected module path
a module found through `modinfo -n xdma`
a same-name in-tree platform driver
```

Vivado:

```text
VERSION=
    2025.2 build 6299465

SETTINGS=
    C:\AMDDesignTools\2025.2\settings64.bat

SUPPORTED_LAUNCHER=
    C:\AMDDesignTools\2025.2\Vivado\2025.2\bin\vivado.bat

FORBIDDEN_LAUNCHER=
    C:\AMDDesignTools\2025.2\Vivado\bin\unwrapped\win64.o\vivado.exe
```

FPGA/JTAG:

```text
HS2_SERIAL=
    210241768436

PART=
    xc7a35t

IDCODE=
    0362D093
```

=====================================================================
3. OWNER AUTHORIZATION AND LIMITS
=====================================================================

Authorized task-local work:

```text
copy this prompt verbatim into the task evidence root;
reuse the accepted corrected R1b programming observer;
create/fix the task-local BAR parser;
create task-local host-precheck wrappers;
create evidence reports/packages;
publish evidence to the agreed public evidence path.
```

Authorized hardware:

```text
Arm A:
    one exact 25-kHz diagnostic program;
    one monotonic wait;
    one Ubuntu warm reboot;
    at most one exact post-reboot driver load;
    full read-only runtime/NVP/video telemetry;
    one final read-only JTAG DONE session.

Arm B:
    one exact formal 50-kHz program;
    the same wait rule;
    one Ubuntu warm reboot;
    at most one exact post-reboot driver load;
    full formal identity and full read-only NVP/video telemetry;
    one final read-only JTAG DONE session.
```

Arm B authorization is explicit:

```text
ARM_B_ROLE=
    FULL_INTERLEAVED_FUNCTIONAL_CONTROL_AND_FINAL_RESTORE

ARM_B_RESTORATION_ONLY=
    FORBIDDEN_WHEN_HOST_AND_JTAG_REMAIN_SAFE
```

Maximum operations:

```text
FPGA_PROGRAM_INVOCATIONS=
    2

WARM_REBOOTS=
    2

POST_REBOOT_DRIVER_LOADER_INVOCATIONS=
    2

OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS=
    1

TOTAL_DRIVER_LOADER_INVOCATIONS_MAX=
    3

PROGRAM_RETRIES=
    0
```

Not authorized:

```text
build;
synthesis;
implementation;
DCP export;
source edit;
new source commit;
new bitstream;
formal bootstrap program;
cold start;
power cycle;
physical action;
JTAG/cable reseat;
third FPGA program;
second diagnostic run;
program retry;
kernel installation/change;
GRUB write;
PCIe remove/rescan;
FLR;
bridge/bus reset;
setpci;
driver_override;
module-unload loop;
AXI-Lite write;
NVP/I2C write;
capture-arm write;
C2H/H2C DMA;
Phase-3 resume;
XDMA development;
tag;
PR;
merge;
Release.
```

If the exact formal start state or persistent kernel-29 selection cannot be
proven:

```text
BLOCKED_REQUIRED_R1C_START_STATE
```

with zero programs.

=====================================================================
4. TASK ROOT AND PUBLICATION AGREEMENT
=====================================================================

Create ASCII-only task root:

```text
C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1C\
```

Required structure:

```text
00_SCOPE_AND_PRIOR_EVIDENCE\
01_ARTIFACT_IDENTITY\
02_INFRASTRUCTURE_PREFLIGHT\
03_ARM_A_25KHZ\
04_ARM_B_FORMAL_50KHZ\
05_COMPARISON\
06_FINAL\
scripts\
fixtures\
```

Create immediately:

```text
OPERATION_LEDGER.md
TIME_LEDGER.md
```

Before any hardware action, save this entire prompt verbatim as:

```text
00_SCOPE_AND_PRIOR_EVIDENCE\
    OWNER_PROMPT_R1C_VERBATIM.md
```

Record its SHA-256.

Do not omit or paraphrase it.

Agreed evidence publication:

```text
REPOSITORY=
    lukaszsudul/AHD-diagnostic-evidence

VISIBILITY=
    PUBLIC

BRANCH=
    main

NEW_PATH=
    v41-nvp-i2c-25khz-paired-ab-r1c/

OVERWRITE_R1_OR_R1B=
    NO

NORMAL_COMMIT_PUSH=
    YES

FORCE_PUSH=
    NO

TAG=
    NO

RELEASE=
    NO
```

Publication order:

```text
1. complete local evidence;
2. run secret scan;
3. create SHA-256 manifest;
4. seal local evidence ZIP;
5. verify ZIP integrity;
6. only then perform one normal evidence commit/push;
7. verify the public remote commit and directory;
8. create a local publication receipt containing the remote commit.
```

The remote commit cannot self-embed its own SHA.

Record that limitation explicitly.

If Git LFS is available and the established repository policy tracks the ZIP:

```text
publish the sealed evidence ZIP through the existing LFS policy.
```

If LFS is unavailable:

```text
publish all raw/Markdown/CSV/log evidence normally;
publish ZIP filename, size and SHA-256 sidecar;
retain the ZIP locally;
do not make the scientific result depend on LFS.
```

=====================================================================
5. P0 — PRESERVE R1 AND R1B CONTEXT
=====================================================================

Create:

```text
00_SCOPE_AND_PRIOR_EVIDENCE\
    R1_R1B_IMMUTABLE_CONTEXT.md

00_SCOPE_AND_PRIOR_EVIDENCE\
    PRIOR_EVIDENCE_IDENTITIES.txt
```

Required:

```text
R1_EVIDENCE_COMMIT=
    5a81f5b115dddcdddd809a655fced115e113585e

R1B_EVIDENCE_COMMIT=
    b773cf667fc6f3277e518535a3e070f3f8a59303

R1_RESULT=
    INCONCLUSIVE_INFRASTRUCTURE

R1B_RESULT=
    INCONCLUSIVE_INFRASTRUCTURE

R1C_PURPOSE=
    NEW_SEPARATELY_AUTHORIZED_SAME_BIT_SAMPLE

R1_AND_R1B_RECORDS_MUTATED=
    NO
```

Do not overwrite prior evidence paths.

=====================================================================
6. P1 — EXACT ARTIFACT IDENTITY AND NO-BUILD GATE
=====================================================================

Locate the bits only in bounded known roots:

```text
C:\FPGA\V41_NVP_I2C_25KHZ_PAIRED_AB_R1\
C:\FPGA\FPGA_AHD_v41_V40_1_0_PHASE2_EVIDENCE\
the exact sealed R1 build-package location.
```

Do not scan the entire drive.

Require and rehash:

```text
DIAGNOSTIC_BIT_FILENAME=
    ahd_capture_v41_i2c_25khz_r1.bit

DIAGNOSTIC_BIT_SIZE=
    2192144

DIAGNOSTIC_BIT_SHA256=
    B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191

FORMAL_BIT_FILENAME=
    ahd_capture_v41_phase2_p1.bit

FORMAL_BIT_SIZE=
    2192144

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
```

Create:

```text
01_ARTIFACT_IDENTITY\ARTIFACT_IDENTITY.md
01_ARTIFACT_IDENTITY\ARTIFACT_SHA256.txt
01_ARTIFACT_IDENTITY\NO_BUILD_NO_SOURCE_CHANGE_PROOF.md
```

Require:

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FORMAL_REPOSITORY_MUTATIONS=0
```

Any mismatch:

```text
BLOCKED_EXACT_ARTIFACT_IDENTITY
```

with zero programs.

=====================================================================
7. P2 — REUSE THE ACCEPTED POST-FIX PROGRAM OBSERVER
=====================================================================

Recover the accepted R1b post-fix task-local programming observer from the R1b
local/evidence package.

Expected accepted identities:

```text
POSTFIX_SUPERVISOR_SHA256=
    2F6CF02E14E5461F9710C3F1E803F0DC325628C04D64E3C925502E88BFA315AF

OBSERVER_PARSER_SHA256=
    6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66
```

The exact accepted observer behavior:

```text
never query REGISTER.IR.BIT4_EOS;

require exact vendor line:
    [Labtools 27-3164] End of startup status: HIGH

require same-session:
    REGISTER.IR.BIT5_DONE=1

require:
    one program invocation;
    strict event ordering;
    process exit code 0;
    no timeout;
    no program error.
```

Do not write a third programming-observer design when exact accepted post-fix
artifacts are available.

If the local files differ from the accepted SHA-256:

```text
BLOCKED_PROGRAM_OBSERVER_IDENTITY
```

No hardware.

Before use, rerun:

```text
static command-count audit;
all 11 accepted fixtures;
prior-R1 replay;
prior-R1b raw-log replay;
evidence-append fixture;
same-QPC wait fixture.
```

Required:

```text
BIT4_EOS_QUERY_COUNT=0
PROGRAM_HW_DEVICES_COMMAND_COUNT=1
BIT5_DONE_PROPERTY_PRESENT=YES
FIXTURES=PASS_11_OF_11
PRIOR_R1_REMAINS_FAIL=YES
PRIOR_R1B_RAW_PROGRAM_REPLAY=PASS_STARTUP_HIGH_DONE_1
POSTPROCESS_APPEND_FIXTURE=PASS
```

No offline repair after live programming is planned or required.

Any live supervisor/postprocess error:

```text
INFRASTRUCTURE_INVALID
```

No programming retry.

=====================================================================
8. P3 — CORRECTED BAR PARSER
=====================================================================

Create task-local:

```text
scripts\parse_pci_bars.py
```

The parser is read-only.

It must read:

```text
/sys/bus/pci/devices/<BDF>/resource
```

and parse line 0 as BAR0 and line 1 as BAR1.

Required parsing rule:

```python
start = int(start_text, 0)
end   = int(end_text, 0)

if start == 0 and end == 0:
    size = 0
elif end < start:
    fail
else:
    size = end - start + 1
```

Never use shell arithmetic:

```text
16#0x...
```

Required output:

```text
BAR0_START=
BAR0_END=
BAR0_FLAGS=
BAR0_BYTES=

BAR1_START=
BAR1_END=
BAR1_FLAGS=
BAR1_BYTES=
```

Expected endpoint geometry:

```text
BAR0_BYTES=
    131072

BAR1_BYTES=
    65536
```

------------------------------------------------------------
8.1 BAR parser fixture gate
------------------------------------------------------------

Required fixtures:

```text
normal R1b-like values:
    0x00000000f6e00000 0x00000000f6e1ffff
    -> 131072

    0x00000000f6e20000 0x00000000f6e2ffff
    -> 65536

uppercase hex;
leading zeros;
all-zero unused BAR;
end smaller than start;
missing token;
non-hex token;
extra whitespace.
```

Require:

```text
BAR_PARSER_FIXTURES=
    PASS_ALL

R1B_BAD_TOKEN_REPLAY=
    PASS_NO_16_HASH_0X_ERROR
```

------------------------------------------------------------
8.2 Independent support evidence
------------------------------------------------------------

Preserve raw:

```text
cat /sys/bus/pci/devices/<BDF>/resource
lspci -Dnnvv -s <BDF>
```

Where possible, compare the parser output with:

```text
resource0/resource1 stat sizes;
lspci Region size text.
```

The Python resource-table result is the authoritative BAR byte gate.

Do not leave BAR fields blank.

Any parser failure or wrong geometry:

```text
BLOCKED_BAR_GEOMETRY_OR_PARSER
```

before driver/telemetry use.

=====================================================================
9. P4 — KERNEL-29 AND NEXT-REBOOT PERSISTENCE GATE
=====================================================================

Before any FPGA program, read only:

```text
uname -r
/proc/cmdline
current boot ID
uptime start
/lib/modules/7.0.0-29-generic
exact module vermagic
bootloader configuration evidence
```

Require:

```text
CURRENT_KERNEL=
    7.0.0-29-generic

PROC_CMDLINE_BOOT_IMAGE=
    resolves to vmlinuz-7.0.0-29-generic

PINNED_MODULE_VERMAGIC_PREFIX=
    7.0.0-29-generic

CURRENT_KERNEL_EQUALS_PINNED_VERMAGIC=
    YES
```

Read-only next-boot persistence gate:

```text
detect the active bootloader;

for GRUB:
    inspect /etc/default/grub;
    inspect `grub-editenv list`;
    inspect the exact relevant menu entries in /boot/grub/grub.cfg;

require the persistent/default next boot to resolve to:
    7.0.0-29-generic;

require no one-shot `next_entry` selecting another kernel.
```

Do not write GRUB state.

If the bootloader selection cannot be proved unambiguously:

```text
BLOCKED_NEXT_REBOOT_KERNEL_NOT_PROVEN
```

with zero programs.

Create:

```text
02_INFRASTRUCTURE_PREFLIGHT\
    KERNEL_AND_BOOT_SELECTION_GATE.md

02_INFRASTRUCTURE_PREFLIGHT\
    KERNEL_AND_BOOT_RAW.log
```

This gate exists to prevent a third kernel/vermagic invalid sample.

=====================================================================
10. P5 — EXACT LOADER COMMAND AND FIXTURES
=====================================================================

Use the following exact argument structure for every authorized load:

```bash
sudo -S -k -p '' /usr/bin/bash \
  /home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh \
  /home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko \
  1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A \
  <FRESH_ABSOLUTE_EVIDENCE_DIRECTORY>
```

Required fresh evidence directories:

```text
pre-Arm-A optional load:
    /home/vcdeagent1/FPGA_AHD_HOST/
    v41_nvp_i2c_25khz_r1c/pre_arm_a_driver

Arm A:
    /home/vcdeagent1/FPGA_AHD_HOST/
    v41_nvp_i2c_25khz_r1c/arm_a_driver

Arm B:
    /home/vcdeagent1/FPGA_AHD_HOST/
    v41_nvp_i2c_25khz_r1c/arm_b_driver
```

Each path must be fresh/empty.

Do not reuse an old loader evidence directory.

Immediately before each load require:

```text
uname -r=7.0.0-29-generic;
module SHA exact;
module vermagic exact;
loader SHA exact;
no loaded module named xdma;
endpoint unbound;
no XDMA node open;
zero task DMA operations.
```

Immediately after load require:

```text
loader exit=0;
exact BDF bound to /sys/bus/pci/drivers/xdma;
expected 21-node set;
no critical kernel/AER/probe error;
exact loader evidence says PASS.
```

No second loader invocation for the same arm.

=====================================================================
11. P6 — FRESH FORMAL START-STATE GATE
=====================================================================

Before Arm A, require exact formal Phase 2 active.

Read only:

```text
SSH user/host/current boot ID/kernel;
one exact JTAG target;
part/IDCODE/DONE;
one endpoint;
vendor/device/subsystem/class;
link;
raw resource table;
corrected BAR parser;
driver state;
loaded modules;
node set;
kernel/AER health;
formal identity;
diagnostic magic.
```

Require:

```text
KERNEL=
    7.0.0-29-generic

HS2=
    210241768436

PART=
    xc7a35t

IDCODE=
    0362D093

DONE=
    1

ENDPOINT=
    10ee:7011

SUBSYSTEM=
    10ee:0007

CLASS=
    058000

LINK=
    Gen1 x1

BAR0_BYTES=
    131072

BAR1_BYTES=
    65536

FORMAL_IDENTITY=
    A40A0C07 / 0000400B / 00031002

DIAGNOSTIC_MAGIC=
    0
```

If exact pinned driver is absent but formal image, endpoint, kernel and BARs are
proven:

```text
invoke the exact loader once with the explicit `dma_ip_drivers/...` module path.
```

Reject any wrong same-name `xdma`.

Require:

```text
no process owns any XDMA node;
zero DMA activity;
no stale Vivado/hw_server owner.
```

No formal bootstrap is authorized.

Failure:

```text
BLOCKED_REQUIRED_FORMAL_START_STATE
```

with zero programs.

=====================================================================
12. ARM A — EXACT 25-kHz SAME BIT
=====================================================================

Immediately before programming:

```text
rehash exact diagnostic bit;
verify accepted observer identities/gates;
verify kernel-persistence gate;
verify operation ledger;
verify exact target;
verify zero XDMA node owners and zero DMA.
```

Program exactly once through the accepted corrected observer.

Require:

```text
VENDOR_STARTUP_STATUS=
    HIGH

SAME_SESSION_DONE=
    1

PROGRAM_INVOCATIONS=
    1

PROCESS_EXIT_CODE=
    0

PROGRAM_RESULT=
    PASS_STARTUP_HIGH_DONE_1

BIT4_EOS_QUERY_ATTEMPTED=
    NO
```

No retry.

Wait:

```text
ACTUAL_WAIT_SECONDS>=5.000000
```

from the later same-QPC marker:

```text
program-return;
fresh-DONE.
```

Perform exactly one Ubuntu warm reboot.

Require:

```text
host disappearance;
host return;
new boot ID.
```

Before loader:

```text
CURRENT_KERNEL=
    7.0.0-29-generic

CURRENT_KERNEL_EQUALS_PINNED_VERMAGIC=
    YES
```

Then run the corrected BAR parser.

Require:

```text
one expected endpoint;
Gen1 x1;
BAR0=131072;
BAR1=65536;
endpoint unbound;
no wrong xdma module;
kernel/AER health suitable for loader.
```

Invoke the exact loader once using the explicit module path from Section 10.

After load require:

```text
exact driver and node set;
BARs remain exact;
kernel/AER health PASS;
no node owner;
zero DMA.
```

Read runtime identity/provenance:

```text
BLOCK_ID=
    0xA40A0C07

PROTOCOL=
    0x0000400B

CAPABILITIES=
    0x00031002

RUNTIME_GIT_SHA=
    f007dc172d43d30b02729755e60382f8ce3dbff4

BUILD_FLAGS=
    0x00000002
```

Collect full T0/T1 read-only telemetry approximately one second apart.

Use the same exact read-only offsets/tool/parser for both arms.

Read:

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

Normalize rate fields using exact timestamps:

```text
VCLK_HZ
SAV_RATE
FRAME_RATE
```

Require one final fresh read-only JTAG session:

```text
DONE=1
```

Arm-A PASS:

```text
infrastructure/provenance valid;
INIT_DONE=1;
INIT_ERROR=0;
NACK_COUNT=0;
TIMEOUT_COUNT=0;
VCLK_HZ normal;
SAV_RATE>0;
FRAME_RATE approximately 25 Hz;
DONE=1.
```

Arm-A valid functional FAIL:

```text
infrastructure/provenance valid;
one or more functional criteria fail.
```

Arm-A infrastructure invalid:

```text
no scientific Arm-A classification;
no retry.
```

Proceed to full Arm B whenever safe.

=====================================================================
13. ARM B — FULL FORMAL CONTROL AND FINAL RESTORE
=====================================================================

This section is mandatory whenever:

```text
the exact formal bit can be safely programmed;
SSH/JTAG identity remain valid;
the two-program task limit is not exceeded.
```

Required role:

```text
ARM_B_ROLE=
    FULL_INTERLEAVED_FUNCTIONAL_CONTROL_AND_FINAL_RESTORE

ARM_B_RESTORATION_ONLY=
    NO
```

Rehash exact formal bit.

Program exactly once through the same accepted corrected observer.

Require:

```text
vendor startup HIGH;
same-session DONE=1;
one invocation;
exit code 0;
no BIT4 EOS query;
no retry.
```

Wait:

```text
ACTUAL_WAIT_SECONDS>=5.000000
```

using the same QPC rule.

Perform exactly one warm reboot.

Require:

```text
host disappearance;
host return;
new boot ID;
CURRENT_KERNEL=7.0.0-29-generic.
```

Run the same corrected BAR parser.

Require:

```text
endpoint 10ee:7011 / 10ee:0007 / class 058000;
Gen1 x1;
BAR0=131072;
BAR1=65536;
no wrong same-name xdma;
no node owner;
zero DMA.
```

Invoke the exact loader once using the explicit:

```text
/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
```

module path.

Require:

```text
exact driver;
expected 21-node set;
kernel/AER health PASS;
formal identity:
    A40A0C07 / 0000400B / 00031002;
diagnostic magic=0.
```

Collect the full T0/T1 telemetry using the exact same tool, offsets, field list,
interval method, static-coherence rules and rate normalization as Arm A.

Read fresh final JTAG:

```text
DONE=1
```

At task end require:

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

Arm B is not complete until its functional telemetry is collected or a fresh,
explicit Arm-B infrastructure blocker is recorded.

A successful formal program plus DONE alone is not a completed Arm-B control.

=====================================================================
14. PAIRED A/B CLASSIFICATION
=====================================================================

Use only the new R1c samples.

Historical R1/R1b and pre-Arm-A formal telemetry are context only.

------------------------------------------------------------
CASE 1 — A PASS / B FAIL
------------------------------------------------------------

```text
PAIRED_AB_RESULT=
    A_PASS_B_FAIL

I2C_25KHZ_DIAGNOSTIC=
    PASS_R1C

SLOWER_COMPLETE_I2C_TIMING_PROFILE=
    STRONGLY_SUPPORTED_AS_RECOVERY

MARGINAL_PROTOCOL_OR_SETTLING_TIMING=
    STRONGLY_SUPPORTED_AS_CONTRIBUTOR

ROOT_CAUSE_SOLELY_PROVEN=
    NO

READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW=
    YES

READY_TO_RETURN_TO_XDMA=
    AFTER_SEPARATELY_AUTHORIZED_PHASE3_INTEGRATION_AND_NVP_REVALIDATION
```

Do not resume Phase 3 in this task.

------------------------------------------------------------
CASE 2 — A FAIL / B FAIL
------------------------------------------------------------

```text
PAIRED_AB_RESULT=
    A_FAIL_B_FAIL

I2C_25KHZ_DIAGNOSTIC=
    FAIL_R1C

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

Do not state that only the PCB remains.

------------------------------------------------------------
CASE 3 — A PASS / B PASS
------------------------------------------------------------

```text
PAIRED_AB_RESULT=
    A_PASS_B_PASS

CLASSIFICATION=
    NON_DISCRIMINATING_FORMAL_CONTROL_DID_NOT_REPRODUCE

READY_TO_RETURN_TO_XDMA=
    NO
```

------------------------------------------------------------
CASE 4 — A FAIL / B PASS
------------------------------------------------------------

```text
PAIRED_AB_RESULT=
    A_FAIL_B_PASS

CLASSIFICATION=
    CONTRADICTORY_DIAGNOSTIC_WORSE_THAN_FORMAL

READY_TO_RETURN_TO_XDMA=
    NO
```

------------------------------------------------------------
CASE 5 — PARTIAL OR MIXED EFFECT
------------------------------------------------------------

Examples:

```text
A has fewer NACKs but remains FAIL;
A has NACK=0 but SAV/frame remains zero;
static fields differ between T0/T1;
one functional sub-gate passes while the full result fails.
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

No automatic repeat.

------------------------------------------------------------
CASE 6 — INFRASTRUCTURE INVALID
------------------------------------------------------------

```text
PAIRED_AB_RESULT=
    INCONCLUSIVE_INFRASTRUCTURE
```

No scientific inference.

Still preserve the full valid Arm-B control if obtained.

=====================================================================
15. EVIDENCE CONTENT AND PUBLICATION
=====================================================================

Required local evidence:

```text
verbatim owner prompt and SHA;
R1/R1b immutable references;
artifact identities;
no-build/no-source-change proof;
accepted observer identities;
observer fixtures/replays;
corrected BAR parser source;
BAR parser fixtures;
R1b BAR-error replay;
kernel and boot-selection proof;
explicit loader command manifest;
formal start-state precheck;
raw Arm-A program/wait/reboot/kernel/BAR/loader/identity/telemetry/DONE;
raw Arm-B program/wait/reboot/kernel/BAR/loader/identity/telemetry/DONE;
paired comparison;
operation ledger;
security scan;
final Markdown report;
SHA-256 manifest.
```

Create:

```text
06_FINAL\
    V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C_REPORT.md

V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE.zip

V41_NVP_I2C_25KHZ_PAIRED_AB_R1C_MEASUREMENT_EVIDENCE_SHA256.txt
```

Before publication require:

```text
ZIP_INTEGRITY=PASS
SECRET_SCAN=PASS
TEMP_PASSWORD_FILES_REMAINING=0
ORIGINAL_CREDENTIAL_FILE_MODIFIED=NO
```

Publish under exactly:

```text
v41-nvp-i2c-25khz-paired-ab-r1c/
```

The publication must clearly state:

```text
R1C_BUILD_PACKAGE_DUPLICATED=
    NO

R1C_REUSES_R1_BUILD_PACKAGE_SHA256=
    918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A
```

Remote verification:

```text
public directory exists;
commit is on main;
remote tree contains expected reports/raw data;
normal non-LFS files re-download and hash correctly;
LFS object verified if used.
```

Create a local:

```text
06_FINAL\EVIDENCE_PUBLICATION_RECEIPT.md
```

after remote verification.

=====================================================================
16. REQUIRED FINAL REPORT BLOCK
=====================================================================

```text
TASK=
    V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1C

R1_EVIDENCE_COMMIT=
    5a81f5b115dddcdddd809a655fced115e113585e

R1B_EVIDENCE_COMMIT=
    b773cf667fc6f3277e518535a3e070f3f8a59303

OWNER_DECLARED_KERNEL_CHANGE=
    7.0.0-29-generic

CURRENT_KERNEL_PRE_ARM_A=
NEXT_REBOOT_KERNEL_PROVEN=
PINNED_MODULE_VERMAGIC=
KERNEL_MODULE_COMPATIBILITY_PRE_ARM_A=

DIAGNOSTIC_SOURCE_COMMIT=
    f007dc172d43d30b02729755e60382f8ce3dbff4

DIAGNOSTIC_SOURCE_TREE=
    b8f87966c8021396acb6341bd2d7d86a10fd7f13

DIAGNOSTIC_BIT_SHA256=
    B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191

DIAGNOSTIC_BUILD_PACKAGE_SHA256=
    918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A

FULL_BUILDS=
    0

SYNTHESIS_RUNS=
    0

IMPLEMENTATION_RUNS=
    0

BITSTREAMS_GENERATED=
    0

FPGA_SOURCE_CHANGES=
    0

PROGRAM_OBSERVER_SHA256=
PROGRAM_OBSERVER_PARSER_SHA256=
PROGRAM_OBSERVER_STATIC_AUDIT=
PROGRAM_OBSERVER_FIXTURES=
PROGRAM_OBSERVER_PRIOR_REPLAYS=
PROGRAM_OBSERVER_POSTPROCESS_APPEND_FIXTURE=

BAR_PARSER_LANGUAGE=
    PYTHON3

BAR_PARSER_USES_INT_BASE_ZERO=
    YES

BAR_PARSER_BASH_16_HASH_0X_USED=
    NO

BAR_PARSER_FIXTURES=
R1B_BAR_ERROR_REPLAY=

PRE_ARM_A_BAR0_BYTES=
PRE_ARM_A_BAR1_BYTES=

PRE_ARM_A_DRIVER_LOAD_REQUIRED=
PRE_ARM_A_DRIVER_LOADER_RESULT=

EXPLICIT_MODULE_PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko

ARM_A_PROGRAM=
ARM_A_VENDOR_STARTUP_STATUS=
ARM_A_DONE=
ARM_A_PROGRAM_RESULT=
ARM_A_WAIT_SECONDS=
ARM_A_BOOT_ID_CHANGED=
ARM_A_KERNEL=
ARM_A_BAR0_BYTES=
ARM_A_BAR1_BYTES=
ARM_A_LOADER_COMMAND_PATH_GATE=
ARM_A_DRIVER=
ARM_A_RUNTIME_GIT_SHA=
ARM_A_RUNTIME_BUILD_FLAGS=
ARM_A_FORMAL_COMMON_IDENTITY=
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

ARM_B_ROLE=
    FULL_INTERLEAVED_FUNCTIONAL_CONTROL_AND_FINAL_RESTORE

ARM_B_PROGRAM=
ARM_B_VENDOR_STARTUP_STATUS=
ARM_B_DONE=
ARM_B_PROGRAM_RESULT=
ARM_B_WAIT_SECONDS=
ARM_B_BOOT_ID_CHANGED=
ARM_B_KERNEL=
ARM_B_BAR0_BYTES=
ARM_B_BAR1_BYTES=
ARM_B_LOADER_COMMAND_PATH_GATE=
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
ARM_B_PAIRED_CONTROL_VALID=

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

FPGA_PROGRAM_INVOCATIONS=
    2

WARM_REBOOTS=
    2

OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS=
POST_REBOOT_DRIVER_LOADER_INVOCATIONS=
TOTAL_DRIVER_LOADER_INVOCATIONS=

PROGRAM_RETRIES=
    0

COLD_STARTS=
    0

PHYSICAL_ACTIONS=
    0

KERNEL_CHANGES_DURING_TASK=
    0

GRUB_WRITES=
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

FORMAL_REPOSITORY_MUTATIONS=
    0

OWNER_PROMPT_SHA256=
EVIDENCE_PACKAGE_SHA256=
EVIDENCE_REPOSITORY_COMMIT=
PUBLIC_REMOTE_VERIFICATION=
```

=====================================================================
17. HARD STOPS
=====================================================================

Stop before hardware if:

```text
exact bit identity differs;
accepted observer identity or fixtures fail;
BAR parser fixtures fail;
R1b BAR-error replay fails;
current kernel is not 7.0.0-29-generic;
next warm reboot kernel cannot be proven as 7.0.0-29-generic;
module vermagic does not match;
formal start state is not proven;
wrong JTAG target;
wrong endpoint;
wrong same-name xdma module loaded/bound;
kernel/AER critical condition;
any XDMA node is open;
task DMA count is nonzero.
```

Stop during an arm if:

```text
vendor startup HIGH is absent;
same-session DONE != 1;
Vivado exits nonzero;
program ordering/count gate fails;
host does not disappear/return;
post-reboot kernel is not 7.0.0-29-generic;
BAR parser fails or BAR geometry differs;
loader exact path/hash/vermagic gate fails;
loader cannot pass in one invocation;
runtime provenance/identity mismatch;
telemetry static fields are incoherent;
final DONE != 1;
operation limits are exceeded.
```

No blocker may be resolved through:

```text
program retry;
third program;
second diagnostic run;
build;
source patch;
kernel change;
GRUB write;
module rebuild;
alternate module path;
modprobe;
PCIe reset/rescan;
physical action;
Phase-3 work.
```

Arm B must still be attempted as a full functional control when safe and within
the two-program limit.

=====================================================================
18. BEGIN
=====================================================================

```text
save this prompt verbatim and hash it
    ->
preserve R1/R1b immutable references
    ->
locate and rehash exact existing diagnostic/formal bits
    ->
prove no build and no FPGA-source change
    ->
recover and verify exact accepted R1b post-fix programming observer
    ->
run observer fixtures/replays/append fixture
    ->
create and test corrected Python BAR parser
    ->
replay the R1b `16#0x...` BAR defect successfully
    ->
prove current kernel and persistent next reboot are 7.0.0-29-generic
    ->
prove module/loader exact identities and explicit paths
    ->
prove exact formal Phase-2 start state
    ->
optionally load the exact pinned driver once if absent
    ->
Arm A:
        exact same 25-kHz bit
        one program
        wait
        one warm reboot
        kernel-29 gate
        corrected BAR gate
        exact explicit-path loader
        full identity/provenance and T0/T1 telemetry
        final DONE
    ->
Arm B:
        exact formal bit
        one program
        same wait
        one warm reboot
        kernel-29 gate
        corrected BAR gate
        exact explicit-path loader
        full formal identity and full T0/T1 telemetry
        final DONE
    ->
paired A/B classification
    ->
leave exact formal Phase 2 active with pinned driver loaded
    ->
seal local evidence
    ->
publish to public agreed R1c path
    ->
verify remote
    ->
HARD STOP.
```

No build.
No FPGA-source change.
No program retry.
No restoration-only Arm B.
No Phase 3.
No XDMA work.
