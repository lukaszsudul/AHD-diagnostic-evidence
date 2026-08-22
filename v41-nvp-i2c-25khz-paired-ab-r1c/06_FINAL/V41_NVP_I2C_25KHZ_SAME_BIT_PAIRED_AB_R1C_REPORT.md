# v41 NVP — 25-kHz same-bit paired A/B R1c

## Executive result

The R1c campaign completed with both arms infrastructure-valid and with exact
runtime provenance. The exact reused 25-kHz image did **not** recover NVP video:
it completed with `INIT_ERROR=1`, 8 NACKs, and zero SAV/frame activity. The new
exact formal 50-kHz control also failed, with 15 NACKs and zero SAV/frame
activity.

The owner prompt's Case-5 precedence applies because it explicitly identifies
“A has fewer NACKs but remains FAIL” as a partial/mixed result. Therefore:

```text
PAIRED_AB_RESULT=PARTIAL_OR_MIXED_EFFECT_SINGLE_SAMPLE
I2C_25KHZ_DIAGNOSTIC=NOT_A_FULL_PASS
READY_TO_RETURN_TO_XDMA=NO
```

The seven-NACK reduction and changed first-error locus show a single-sample
partial effect from the slower complete I2C timing profile. They do not show
recovery, do not establish a sole cause, and do not authorize an automatic
repeat or Phase-3 integration.

## Exact paired results

| Gate or metric | Arm A: exact 25 kHz | Arm B: exact formal 50 kHz |
|---|---:|---:|
| Program observer | startup HIGH, DONE=1, PASS | startup HIGH, DONE=1, PASS |
| Monotonic wait | 5.004167500 s | 5.002957100 s |
| Boot changed | yes | yes |
| Kernel | 7.0.0-29-generic | 7.0.0-29-generic |
| BAR0 / BAR1 | 131072 / 65536 bytes | 131072 / 65536 bytes |
| Runtime provenance | `f007dc17...`, flags `0x2` | formal zero Git words, flags `0x0` |
| Common identity | A40A0C07 / 400B / 31002 | A40A0C07 / 400B / 31002 |
| `INIT_DONE` / `INIT_ERROR` | 1 / 1 | 1 / 1 |
| NACK / timeout | 8 / 0 | 15 / 0 |
| First error | code 02, step 2D, reg ED | code 01, step 02, reg CA |
| VCLK interval | 147.776–149.234 MHz | 147.785–149.158 MHz |
| SAV rate / frame rate | 0 / 0 | 0 / 0 |
| Reset / VDD1x / VDD3x | 1 / 1 / 1 | 1 / 1 / 1 |
| Final DONE | 1 | 1 |
| Functional result | valid FAIL | valid FAIL |

Each telemetry transaction used exactly 40 MMIO reads and zero AXI-Lite
writes, C2H transfers, or H2C transfers. Static telemetry fields matched
between T0 and T1 in both arms. The VCLK intervals passed the predeclared
140–160-MHz range; video activity did not.

## Infrastructure and provenance

- The diagnostic bit was reused byte-for-byte: 2,192,144 bytes, SHA-256
  `B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191`.
- The formal bit was reused byte-for-byte: 2,192,144 bytes, SHA-256
  `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`.
- R1c performed zero builds, synthesis, implementation, bitstream generation,
  or FPGA-source changes.
- The accepted programming observer was reused exactly. Both programs had one
  consumed invocation, vendor startup HIGH, same-session BIT5 DONE=1, process
  exit 0, valid ordering, and no retry.
- The Python BAR parser uses `int(token, 0)`. Nine offline fixtures, including
  the prior `0x`-token failure replay, passed.
- All three authorized loader invocations used the exact explicit module and
  accepted-loader paths. The final formal boot retains the pinned driver,
  expected 21 nodes, formal identity, diagnostic magic 0, and DONE=1.

The first Arm-A post-reboot preloader attempt stopped read-only because
`modinfo -F vermagic` emitted the exact value with a conventional trailing
space. Its evidence was preserved. The narrowly audited second attempt
preserved the raw value, removed trailing whitespace only into a separate
normalized field, and then compared the full normalized vermagic exactly. No
loader or programming budget was consumed by that read-only adaptation.

## Interpretation limits

The 25-kHz profile was not sufficient for recovery. The NACK reduction is
consistent with timing sensitivity but is only one paired sample and occurred
without video recovery. Image-dependent power/ground/switching context,
board/analog I2C margin, implementation sensitivity, and physical assembly
remain open. Root cause is not solely proven. No statement that “only the PCB
remains” is supported.

## Operation accounting and final state

```text
FPGA_PROGRAM_INVOCATIONS=2
WARM_REBOOTS=2
OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS=1
POST_REBOOT_DRIVER_LOADER_INVOCATIONS=2
TOTAL_DRIVER_LOADER_INVOCATIONS=3
PROGRAM_RETRIES=0
MMIO_READS=120
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
FINAL_ACTIVE_IMAGE=FORMAL_PHASE2
FINAL_PINNED_DRIVER_LOADED=YES
FINAL_DONE=1
```

The final local process receipt also records zero `vivado`, `hw_server`, and
`cs_server` processes after the final JTAG session. No further hardware action
was issued after the required final DONE observation.

## Evidence publication convention

The measurement ZIP includes this report, so its SHA-256 cannot be embedded in
the report without circularity. The exact ZIP hash is recorded in the external
SHA-256 sidecar. Likewise, the public Git commit cannot contain its own hash;
the verified commit and remote-tree result are recorded afterward in the local
publication receipt.

```text
R1C_BUILD_PACKAGE_DUPLICATED=NO
R1C_REUSES_R1_BUILD_PACKAGE_SHA256=918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A
```

## Required final block

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
    7.0.0-29-generic

NEXT_REBOOT_KERNEL_PROVEN=
    7.0.0-29-generic

PINNED_MODULE_VERMAGIC=
    7.0.0-29-generic SMP preempt mod_unload modversions

KERNEL_MODULE_COMPATIBILITY_PRE_ARM_A=
    PASS_EXACT_KERNEL_AND_NORMALIZED_VERMAGIC

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
    2F6CF02E14E5461F9710C3F1E803F0DC325628C04D64E3C925502E88BFA315AF

PROGRAM_OBSERVER_PARSER_SHA256=
    6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66

PROGRAM_OBSERVER_STATIC_AUDIT=
    PASS

PROGRAM_OBSERVER_FIXTURES=
    PASS_11_OF_11

PROGRAM_OBSERVER_PRIOR_REPLAYS=
    PASS_R1_FAILURE_AND_R1B_PASS_REPRODUCED

PROGRAM_OBSERVER_POSTPROCESS_APPEND_FIXTURE=
    PASS

BAR_PARSER_LANGUAGE=
    PYTHON3

BAR_PARSER_USES_INT_BASE_ZERO=
    YES

BAR_PARSER_BASH_16_HASH_0X_USED=
    NO

BAR_PARSER_FIXTURES=
    PASS_9_OF_9

R1B_BAR_ERROR_REPLAY=
    PASS_NO_16_HASH_0X_ERROR

PRE_ARM_A_BAR0_BYTES=
    131072

PRE_ARM_A_BAR1_BYTES=
    65536

PRE_ARM_A_DRIVER_LOAD_REQUIRED=
    YES

PRE_ARM_A_DRIVER_LOADER_RESULT=
    PASS_EXACT_PINNED_XDMA

EXPLICIT_MODULE_PATH=
    /home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko

ARM_A_PROGRAM=
    PASS_EXACT_DIAGNOSTIC_BIT_ONE_INVOCATION

ARM_A_VENDOR_STARTUP_STATUS=
    HIGH

ARM_A_DONE=
    1

ARM_A_PROGRAM_RESULT=
    PASS_STARTUP_HIGH_DONE_1

ARM_A_WAIT_SECONDS=
    5.004167500

ARM_A_BOOT_ID_CHANGED=
    YES

ARM_A_KERNEL=
    7.0.0-29-generic

ARM_A_BAR0_BYTES=
    131072

ARM_A_BAR1_BYTES=
    65536

ARM_A_LOADER_COMMAND_PATH_GATE=
    PASS_EXPLICIT_ABSOLUTE_MODULE_AND_LOADER_PATHS

ARM_A_DRIVER=
    PASS_EXACT_PINNED_XDMA

ARM_A_RUNTIME_GIT_SHA=
    f007dc172d43d30b02729755e60382f8ce3dbff4

ARM_A_RUNTIME_BUILD_FLAGS=
    0x00000002

ARM_A_FORMAL_COMMON_IDENTITY=
    0xA40A0C07/0x0000400B/0x00031002

ARM_A_INIT_DONE=
    1

ARM_A_INIT_ERROR=
    1

ARM_A_NACK_COUNT=
    8

ARM_A_TIMEOUT_COUNT=
    0

ARM_A_FIRST_ERROR=
    CODE_0x02_STEP_0x2D_META_0x01_PHYS_0x01_REG_0xED_VALUE_0x00

ARM_A_VCLK_HZ=
    147776427.625907_TO_149234386.368764

ARM_A_SAV_RATE=
    0.000000

ARM_A_FRAME_RATE=
    0.000000

ARM_A_RESULT=
    VALID_FUNCTIONAL_FAIL

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

ARM_B_ROLE=
    FULL_INTERLEAVED_FUNCTIONAL_CONTROL_AND_FINAL_RESTORE

ARM_B_PROGRAM=
    PASS_EXACT_FORMAL_BIT_ONE_INVOCATION

ARM_B_VENDOR_STARTUP_STATUS=
    HIGH

ARM_B_DONE=
    1

ARM_B_PROGRAM_RESULT=
    PASS_STARTUP_HIGH_DONE_1

ARM_B_WAIT_SECONDS=
    5.002957100

ARM_B_BOOT_ID_CHANGED=
    YES

ARM_B_KERNEL=
    7.0.0-29-generic

ARM_B_BAR0_BYTES=
    131072

ARM_B_BAR1_BYTES=
    65536

ARM_B_LOADER_COMMAND_PATH_GATE=
    PASS_EXPLICIT_ABSOLUTE_MODULE_AND_LOADER_PATHS

ARM_B_DRIVER=
    PASS_EXACT_PINNED_XDMA

ARM_B_FORMAL_IDENTITY=
    0xA40A0C07/0x0000400B/0x00031002

ARM_B_DIAGNOSTIC_MAGIC=
    0x00000000

ARM_B_INIT_DONE=
    1

ARM_B_INIT_ERROR=
    1

ARM_B_NACK_COUNT=
    15

ARM_B_TIMEOUT_COUNT=
    0

ARM_B_FIRST_ERROR=
    CODE_0x01_STEP_0x02_META_0x01_PHYS_0x01_REG_0xCA_VALUE_0x66

ARM_B_VCLK_HZ=
    147785016.335241_TO_149157931.307508

ARM_B_SAV_RATE=
    0.000000

ARM_B_FRAME_RATE=
    0.000000

ARM_B_RESULT=
    VALID_FUNCTIONAL_FAIL

ARM_B_PAIRED_CONTROL_VALID=
    YES

PAIRED_AB_RESULT=
    PARTIAL_OR_MIXED_EFFECT_SINGLE_SAMPLE

I2C_25KHZ_DIAGNOSTIC=
    NOT_A_FULL_PASS

SLOWER_COMPLETE_I2C_TIMING_PROFILE=
    PARTIAL_EFFECT_OBSERVED_NOT_SUFFICIENT_FOR_RECOVERY

SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE=
    NOT_ESTABLISHED_BY_SINGLE_PARTIAL_SAMPLE

ROOT_CAUSE_SOLELY_PROVEN=
    NO

READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW=
    NO

READY_TO_RETURN_TO_XDMA=
    NO

NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_NO_AUTOMATIC_REPEAT

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
    0xA40A0C07/0x0000400B/0x00031002

FINAL_DIAGNOSTIC_MAGIC=
    0x00000000

FINAL_PINNED_DRIVER_LOADED=
    YES

FINAL_DONE=
    1

FPGA_PROGRAM_INVOCATIONS=
    2

WARM_REBOOTS=
    2

OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS=
    1

POST_REBOOT_DRIVER_LOADER_INVOCATIONS=
    2

TOTAL_DRIVER_LOADER_INVOCATIONS=
    3

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
    D8F258D95F5543E6AEF592B5A9A5DBDE8F982F4AC87A971D3A7FB38F2259CBB1

EVIDENCE_PACKAGE_SHA256=
    NOT_SELF_EMBEDDABLE_SEE_EXTERNAL_SHA256_SIDECAR

EVIDENCE_REPOSITORY_COMMIT=
    NOT_SELF_EMBEDDABLE_RECORDED_IN_EVIDENCE_PUBLICATION_RECEIPT.md

PUBLIC_REMOTE_VERIFICATION=
    NOT_SELF_EMBEDDABLE_RECORDED_IN_EVIDENCE_PUBLICATION_RECEIPT.md
```
