# V41 NVP R1e extended-observability final report — R5 POST_COLD_RESET_R2

## Outcome

R5 hard-stopped at the mandatory JTAG transport-stability gate before any FPGA
programming. The post-cold-reset host baseline passed in three independent
read-only SSH sessions, all on boot ID
`dd140158-f8dc-46eb-9a05-27bb532713aa` with kernel
`7.0.0-29-generic` and monotonically increasing uptime over 5.69 seconds.

Both authorized read-only Hardware Manager sessions then enumerated exactly
one target, but the required HS2 target was absent. The sole observed target in
each session was:

```text
localhost:3121/xilinx_tcf/Xilinx/80802026a98b01
```

The exact HS2 match count was zero in both sessions. Neither session opened an
accepted device or entered the five-sample refresh loop; consequently there
were zero accepted samples and `DONE` was unreadable. The terminal
classification is:

```text
BLOCKED_JTAG_TRANSPORT_NOT_STABLE
```

No formal bootstrap, Arm A, or Arm B program was attempted. No in-task reboot,
driver load, MMIO access, AXI-Lite write, DMA transfer, PCIe reset/rescan,
source change, build, or physical action occurred. The final SRAM image,
formal runtime identity, driver state, and `DONE` remain unproven.

## Pre-task reset and continuity scope

The owner-performed cold reset occurred before R5 and is recorded as required:

```text
PRE_TASK_OWNER_COLD_RESET=YES
PRE_TASK_COLD_RESET_SCOPE=UBUNTU_HOST_POWER_REMOVAL_FPGA_CARD_RETENTION_NOT_ASSUMED
HISTORICAL_BOOT_CONTINUITY_WITH_R4=NOT_APPLICABLE_PRETASK_COLD_RESET
COLD_STARTS_DURING_TASK=0
```

R5 made no assumption that an SRAM image, endpoint, driver binding, runtime
identity, or `DONE` state survived that pre-task event. The stable host boot ID
was established afresh and was not compared with R4 as a continuity gate.

## Frozen R1e implementation and historical boundary

The offline gates reverified the frozen experiment without rebuilding:

| Object | Exact identity |
|---|---|
| R4 evidence commit | `7aad5cbdcce4142532f34e4ce31a022b2f6ff435` |
| R4 evidence ZIP SHA-256 | `8F30EDA6E135BC5097EBA5F36524FD0E3187D9FF8E483694E01D75C8DA30AEFB` |
| R1e source commit | `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd` |
| R1e source tree | `db8b5581a237e19905fd01c6d453793047bc3ba7` |
| Routed DCP SHA-256 | `1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1` |
| R1e bit SHA-256 | `0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9` |
| Formal Phase-2 bit SHA-256 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` |

The R4 evidence package and all 113 manifest entries rehashed exactly. The
source worktree was clean at the frozen source commit/tree. Programming
observer, BAR parser, identity, lifecycle, ordered-log, probe, Wilson, and
formal-page-zero fixtures all passed before live qualification.

R3 remains the stage that generated the sole R1e bitstream from the exact
routed DCP. R4 stopped at its formal-bootstrap programming boundary and did not
produce an Arm-A or Arm-B scientific sample. R5 preserves those records and
does not reinterpret them.

## Fresh R5 qualification evidence

### Post-cold-reset host stability

Three separate non-privileged SSH processes used the exact pinned host key and
credential helper. Each returned hostname `VCDE-DUT-1`, user `vcdeagent1`,
kernel `7.0.0-29-generic`, and the same valid boot ID. Uptime increased from
2715.62 to 2721.31 seconds. The aggregate gates were:

```text
POST_COLD_RESET_HOST_STABILITY_GATE=PASS_3_OF_3
REMOTE_UPTIME_SPAN_SECONDS=5.690000
LOCAL_MONOTONIC_SPAN_SECONDS=6.945853
NO_OBSERVED_REBOOT_OR_SHUTDOWN_TRANSITION=YES
```

These sessions did not inspect PCIe, driver, MMIO, or FPGA application state.

### JTAG transport stability

The task-local JTAG harness passed its static read-only audit. Both independent
Vivado sessions started, and neither timed out. The results were:

| Field | Session 1 | Session 2 |
|---|---:|---:|
| Process exit code | 1 | 1 |
| Initial target count | 1 | 1 |
| Exact HS2 match count | 0 | 0 |
| Observed target | `Xilinx/80802026a98b01` | `Xilinx/80802026a98b01` |
| Accepted device enumeration | Not reached | Not reached |
| Completed refresh samples | 0 | 0 |
| Readable `DONE` samples | 0 | 0 |
| FPGA program operations | 0 | 0 |

The required result was ten stable samples from HS2 serial `210241768436`.
Because the exact target match failed before device enumeration, the aggregate
matrix contains no sample rows and the hard stop was mandatory.

## Scientific status

No R1e scientific sample was obtained:

- no formal-bootstrap qualification;
- no Arm-A lifecycle capture;
- no Arm-A ordered-NACK log;
- no Arm-A 10,000-address-probe result;
- no Arm-A NVP functional result;
- no Arm-B exact-formal functional control; and
- no final formal identity verification.

Therefore the paired experiment is not evaluated. Control-flow shortening,
stochastic address/bus margin, autoinit operation/phase context, and
post-init-versus-autoinit context dependence are all unclassified. The fresh
JTAG mismatch is an infrastructure blocker, not an NVP result.

## Terminal accounting

The actual counts, rather than authorized maxima, are reported below. The
three read-only SSH baseline sessions and two read-only JTAG sessions are the
only live external observations. Programming, reboot, driver, MMIO, and DMA
counts are all zero. The separate terminal accounting audit found no
contradiction among the raw session logs, aggregate gates, and ledgers.

## Required final block

```text
TASK=
    V41_NVP_R1E_JTAG_RECOVERED_BOOTSTRAP_AND_COMPLETE_PAIRED_AB_R5

PROMPT_REVISION=
    POST_COLD_RESET_R2

PRE_TASK_OWNER_COLD_RESET=
    YES

PRE_TASK_COLD_RESET_SCOPE=
    UBUNTU_HOST_POWER_REMOVAL_FPGA_CARD_RETENTION_NOT_ASSUMED

HISTORICAL_BOOT_CONTINUITY_WITH_R4=
    NOT_APPLICABLE_PRETASK_COLD_RESET

POST_COLD_RESET_BOOT_ID_BASELINE=
    dd140158-f8dc-46eb-9a05-27bb532713aa

POST_COLD_RESET_HOST_STABILITY_GATE=
    PASS_3_OF_3

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

READ_ONLY_POST_COLD_RESET_HOST_STABILITY_SESSIONS=
    3

READ_ONLY_JTAG_STABILITY_SESSIONS=
    2

JTAG_STABILITY_SAMPLES=
    0

JTAG_PRECHECK_DONE_VALUE=
    UNREADABLE_NO_EXACT_HS2_MATCH
JTAG_TRANSPORT_STABILITY_GATE=
    FAIL_BLOCKED_JTAG_TRANSPORT_NOT_STABLE

PRE_BOOTSTRAP_KERNEL=
    7.0.0-29-generic_FROM_HOST_STABILITY_BASELINE
PRE_BOOTSTRAP_ENDPOINT_STATE=
    NOT_READ_JTAG_GATE_FAILED
PRE_BOOTSTRAP_DRIVER_STATE=
    NOT_READ_JTAG_GATE_FAILED
PRE_BOOTSTRAP_NODE_OWNERS=
    NOT_READ_JTAG_GATE_FAILED
PRE_BOOTSTRAP_DMA=
    NOT_READ_JTAG_GATE_FAILED
PRE_BOOTSTRAP_HOST_SAFETY_GATE=
    NOT_RUN_JTAG_GATE_FAILED

FORMAL_BOOTSTRAP_PROGRAM=
    NOT_RUN_JTAG_GATE_FAILED
FORMAL_BOOTSTRAP_VENDOR_STARTUP=
    NOT_APPLICABLE_NOT_RUN
FORMAL_BOOTSTRAP_SAME_SESSION_DONE=
    NOT_APPLICABLE_NOT_RUN
FORMAL_BOOTSTRAP_INDEPENDENT_DONE=
    NOT_APPLICABLE_NOT_RUN
FORMAL_BOOTSTRAP_WAIT_SECONDS=
    0
FORMAL_BOOTSTRAP_BOOT_ID_CHANGED=
    NOT_APPLICABLE_NOT_RUN
FORMAL_BOOTSTRAP_KERNEL=
    NOT_READ
FORMAL_BOOTSTRAP_BAR0_BYTES=
    NOT_READ
FORMAL_BOOTSTRAP_BAR1_BYTES=
    NOT_READ
FORMAL_BOOTSTRAP_DRIVER=
    NOT_RUN_STATE_UNPROVEN
FORMAL_BOOTSTRAP_RAW_READER_IDENTITY=
    NOT_READ
FORMAL_BOOTSTRAP_ACCEPTED_READER_IDENTITY=
    NOT_READ
FORMAL_BOOTSTRAP_DIAGNOSTIC_MAGIC=
    NOT_READ
FORMAL_BOOTSTRAP_FINAL_DONE=
    UNPROVEN
FORMAL_READY=
    NO

ARM_A_PROGRAM=
    NOT_RUN_JTAG_GATE_FAILED
ARM_A_VENDOR_STARTUP=
    NOT_APPLICABLE_NOT_RUN
ARM_A_SAME_SESSION_DONE=
    NOT_APPLICABLE_NOT_RUN
ARM_A_INDEPENDENT_DONE=
    NOT_APPLICABLE_NOT_RUN
ARM_A_WAIT_SECONDS=
    0
ARM_A_BOOT_ID_CHANGED=
    NOT_APPLICABLE_NOT_RUN
ARM_A_KERNEL=
    NOT_READ
ARM_A_BAR0_BYTES=
    NOT_READ
ARM_A_BAR1_BYTES=
    NOT_READ
ARM_A_DRIVER=
    NOT_RUN_STATE_UNPROVEN
ARM_A_RUNTIME_PROVENANCE=
    NOT_READ
ARM_A_CNT_AT_INIT_DONE=
    NOT_MEASURED
ARM_A_EXPECTED_CNT_AT_INIT_DONE=
    132584734
ARM_A_SIGNED_COUNT_ERROR_CYCLES=
    NOT_COMPUTABLE_NO_SAMPLE
ARM_A_SHORTENING_CYCLES=
    NOT_COMPUTABLE_NO_SAMPLE
ARM_A_SHORTENING_TICKS_EXACT=
    NOT_COMPUTABLE_NO_SAMPLE
ARM_A_SHORTENING_TICKS_NEAREST=
    NOT_COMPUTABLE_NO_SAMPLE
ARM_A_SHORTENING_RESIDUAL_CYCLES=
    NOT_COMPUTABLE_NO_SAMPLE
ARM_A_NACK_COUNT=
    NOT_MEASURED
ARM_A_NACK_LOG_COUNT=
    NOT_MEASURED
ARM_A_NACK_LOG_OVERFLOW=
    NOT_MEASURED
ARM_A_ORDERED_NACK_RECORDS=
    NOT_MEASURED
ARM_A_PROBE_COUNT=
    NOT_MEASURED
ARM_A_PROBE_ACK_COUNT=
    NOT_MEASURED
ARM_A_PROBE_NACK_COUNT=
    NOT_MEASURED
ARM_A_PROBE_TIMEOUT_COUNT=
    NOT_MEASURED
ARM_A_PROBE_NACK_RATE=
    NOT_COMPUTABLE_NO_SAMPLE
ARM_A_PROBE_NACK_RATE_PPM=
    NOT_COMPUTABLE_NO_SAMPLE
ARM_A_PROBE_WILSON95=
    NOT_COMPUTABLE_NO_SAMPLE
ARM_A_PROBE_FIRST_NACK_INDEX=
    NOT_MEASURED
ARM_A_PROBE_LAST_NACK_INDEX=
    NOT_MEASURED
ARM_A_PROBE_MAX_CONSECUTIVE_NACKS=
    NOT_MEASURED
ARM_A_NVP_RESULT=
    NOT_RUN
ARM_A_FINAL_DONE=
    UNPROVEN

ARM_B_PROGRAM=
    NOT_RUN_JTAG_GATE_FAILED
ARM_B_VENDOR_STARTUP=
    NOT_APPLICABLE_NOT_RUN
ARM_B_SAME_SESSION_DONE=
    NOT_APPLICABLE_NOT_RUN
ARM_B_INDEPENDENT_DONE=
    NOT_APPLICABLE_NOT_RUN
ARM_B_WAIT_SECONDS=
    0
ARM_B_BOOT_ID_CHANGED=
    NOT_APPLICABLE_NOT_RUN
ARM_B_KERNEL=
    NOT_READ
ARM_B_BAR0_BYTES=
    NOT_READ
ARM_B_BAR1_BYTES=
    NOT_READ
ARM_B_DRIVER=
    NOT_RUN_STATE_UNPROVEN
ARM_B_FORMAL_IDENTITY=
    UNPROVEN_NOT_READ_R5
ARM_B_DIAGNOSTIC_MAGIC=
    UNPROVEN_NOT_READ_R5
ARM_B_R1E_PAGE_ZERO=
    NOT_READ
ARM_B_NACK_COUNT=
    NOT_MEASURED
ARM_B_NACK_LOG_COUNT=
    NOT_MEASURED
ARM_B_NACK_LOG_OVERFLOW=
    NOT_MEASURED
ARM_B_ORDERED_NACK_RECORDS=
    NOT_MEASURED
ARM_B_NVP_RESULT=
    NOT_RUN
ARM_B_FINAL_DONE=
    UNPROVEN

PAIRED_AB_RESULT=
    NOT_EVALUATED_NO_HARDWARE_CAMPAIGN
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=
    NOT_EVALUATED_NO_SAMPLE
STOCHASTIC_ADDRESS_OR_BUS_MARGIN=
    NOT_EVALUATED_NO_SAMPLE
AUTOINIT_OPERATION_OR_PHASE_CONTEXT=
    NOT_EVALUATED_NO_SAMPLE
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=
    NOT_EVALUATED_NO_SAMPLE

ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO

FINAL_ACTIVE_IMAGE=
    UNPROVEN_AFTER_PRETASK_COLD_RESET_NOT_MODIFIED_BY_R5

FINAL_FORMAL_IDENTITY=
    UNPROVEN_NOT_READ_R5
FINAL_DIAGNOSTIC_MAGIC=
    UNPROVEN_NOT_READ_R5
FINAL_PINNED_DRIVER_LOADED=
    UNPROVEN_NOT_QUERIED_R5
FINAL_DONE=
    UNPROVEN_UNREADABLE_NO_EXACT_HS2_MATCH

FORMAL_BOOTSTRAP_PROGRAMS=
    0

ARM_A_PROGRAMS=
    0

ARM_B_PROGRAMS=
    0

FPGA_PROGRAM_INVOCATIONS=
    0

FORMAL_BOOTSTRAP_WARM_REBOOTS=
    0
ARM_A_WARM_REBOOTS=
    0
ARM_B_WARM_REBOOTS=
    0
WARM_REBOOTS=
    0

FORMAL_BOOTSTRAP_DRIVER_LOADS=
    0
ARM_A_DRIVER_LOADS=
    0
ARM_B_DRIVER_LOADS=
    0
DRIVER_LOADS=
    0

PROGRAM_RETRIES=
    0

COLD_STARTS_DURING_TASK=
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
    60F21D81F2CD2C15E4DF46CA78BF3DC885A70599C39C1FC41FA894E83D50C17B
EVIDENCE_PACKAGE_SHA256=
    RECORDED_IN_V41_NVP_R1E_R5_COMPLETE_MEASUREMENT_EVIDENCE_SHA256.txt
EVIDENCE_REPOSITORY_COMMIT=
    RECORDED_OUT_OF_BAND_AFTER_THE_SINGLE_EVIDENCE_COMMIT
PUBLIC_REMOTE_VERIFICATION=
    RECORDED_OUT_OF_BAND_AFTER_PUSH
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_BLOCKED_R5_JTAG_TRANSPORT_RESULT
```
