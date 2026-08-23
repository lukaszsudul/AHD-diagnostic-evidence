# V41 NVP R1e extended-observability final report — R5

## Outcome

R5 hard-stopped at the mandatory read-only JTAG transport-stability gate.
Both independently launched Hardware Manager sessions enumerated exactly one
target and exactly one match for HS2 serial `210241768436`. In both sessions,
opening that target failed with:

```text
[Labtools 27-2269] No devices detected on target
localhost:3121/xilinx_tcf/Digilent/210241768436.
```

Consequently, neither session obtained a device object. No refresh sample was
completed, `DONE` was unreadable, and the required 10-of-10 stability result
was not available. Both authorized read-only stability sessions were consumed.
The prescribed hard stop was applied before host discovery or programming.

No FPGA program, reboot, driver load, SSH session, MMIO access, AXI-Lite write,
or DMA transfer occurred in R5. The current SRAM image and `DONE` state remain
unproven. Arm A and Arm B were not run, so no R1e scientific result or paired
A/B classification is available.

## Frozen experiment identity

R5 reused the completed R1e implementation without rebuilding or editing FPGA
source. The local identity gate reverified the following immutable objects:

| Object | Identity |
|---|---|
| R1e source commit | `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd` |
| R1e source tree | `db8b5581a237e19905fd01c6d453793047bc3ba7` |
| Routed DCP SHA-256 | `1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1` |
| R1e bit SHA-256 | `0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9` |
| Formal Phase-2 bit SHA-256 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` |
| R4 evidence commit | `7aad5cbdcce4142532f34e4ce31a022b2f6ff435` |
| R4 evidence ZIP SHA-256 | `8F30EDA6E135BC5097EBA5F36524FD0E3187D9FF8E483694E01D75C8DA30AEFB` |

The R3 stage had completed the sole R1e bitstream from the exact routed DCP.
R4 later stopped during its formal-bootstrap programming attempt and collected
no Arm-A or Arm-B sample. Those historical records remain unchanged. R5 made
no source, DCP, or bitstream change.

## Offline entry gates

The R4 evidence worktree was clean at the required commit, its package hash
matched, and all 113 entries in its SHA-256 manifest rehashed correctly with
zero missing, mismatched, or malformed records. Both bitstreams, the routed
DCP, and the R1e Git commit/tree matched their frozen identities.

The frozen host-tool gate passed. Fresh offline fixtures passed for:

- the programming transcript observer, including startup-HIGH/LOW handling
  and same-session `DONE` ordering;
- corrected 128-KiB/64-KiB BAR parsing;
- formal identity acceptance and all-ones rejection;
- coherent lifecycle-counter decoding;
- ordered-log count and overflow rules;
- probe invariants;
- Wilson and zero-NACK bounds; and
- formal R1e-page-zero behavior.

No offline failure contributed to the R5 terminal result.

## R5 JTAG transport-stability result

The task-local stability harness passed static review before either session.
It contained zero programming or other hardware-mutation commands and was
fixed at two sequential sessions with five read-only refreshes per session.

| Field | Session 1 | Session 2 |
|---|---:|---:|
| Process started | Yes | Yes |
| Process timed out | No | No |
| Process exit code | 1 | 1 |
| Initial target count | 1 | 1 |
| Intended target match count | 1 | 1 |
| `open_hw_target` | Failed | Failed |
| Successful device enumerations | 0 | 0 |
| Completed refresh samples | 0 | 0 |
| Readable `DONE` samples | 0 | 0 |
| FPGA program operations | 0 | 0 |

The session matrices contain headers only because failure preceded device
enumeration and the fixed refresh loop. The aggregate gate therefore recorded:

```text
READ_ONLY_JTAG_STABILITY_SESSIONS=2
JTAG_STABILITY_SAMPLES=0
JTAG_PRECHECK_DONE_VALUE=UNREADABLE
JTAG_TRANSPORT_STABILITY_GATE=FAIL
HARD_STOP_CLASSIFICATION=BLOCKED_JTAG_TRANSPORT_NOT_STABLE
```

The required pre-bootstrap host safety discovery was not started because it
comes after a passing 10-of-10 JTAG gate. The mandatory bootstrap authorization
was not consumed.

## Scientific status

No R5 NVP observation was made:

- Arm A lifecycle count: not measured;
- Arm A ordered-NACK log: not measured;
- Arm A 10,000-probe result: not measured;
- Arm A functional result: not measured;
- Arm B ordered-NACK log and functional control: not measured; and
- paired A/B result: not evaluated.

There is therefore no basis for classifying stochastic address/bus margin,
autoinit phase context, post-init versus autoinit context dependence, or
control-flow shortening. The R5 transport failure is infrastructure evidence,
not an NVP scientific result.

## Final state and accounting

R5 performed only the two authorized read-only Hardware Manager sessions. It
did not modify the FPGA, DUT host, repository, or formal image. Because the
device could not be opened for property reads, the final SRAM image, formal
runtime identity, diagnostic magic, pinned-driver state, and `DONE` value are
all unproven by R5.

## Required final block

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
    0

JTAG_PRECHECK_DONE_VALUE=
    UNREADABLE_NO_DEVICE_OBJECT

JTAG_TRANSPORT_STABILITY_GATE=
    FAIL_BLOCKED_JTAG_TRANSPORT_NOT_STABLE

PRE_BOOTSTRAP_KERNEL=
    NOT_READ_HOST_DISCOVERY_NOT_RUN
PRE_BOOTSTRAP_ENDPOINT_STATE=
    NOT_READ_HOST_DISCOVERY_NOT_RUN
PRE_BOOTSTRAP_DRIVER_STATE=
    NOT_READ_HOST_DISCOVERY_NOT_RUN
PRE_BOOTSTRAP_NODE_OWNERS=
    NOT_READ_HOST_DISCOVERY_NOT_RUN
PRE_BOOTSTRAP_DMA=
    NOT_READ_HOST_DISCOVERY_NOT_RUN
PRE_BOOTSTRAP_HOST_SAFETY_GATE=
    NOT_RUN_JTAG_STABILITY_GATE_FAILED

FORMAL_BOOTSTRAP_PROGRAM=
    NOT_RUN_JTAG_STABILITY_GATE_FAILED
FORMAL_BOOTSTRAP_VENDOR_STARTUP=
    NOT_APPLICABLE
FORMAL_BOOTSTRAP_SAME_SESSION_DONE=
    NOT_APPLICABLE
FORMAL_BOOTSTRAP_INDEPENDENT_DONE=
    NOT_APPLICABLE
FORMAL_BOOTSTRAP_WAIT_SECONDS=
    0
FORMAL_BOOTSTRAP_BOOT_ID_CHANGED=
    NOT_APPLICABLE
FORMAL_BOOTSTRAP_KERNEL=
    NOT_READ
FORMAL_BOOTSTRAP_BAR0_BYTES=
    NOT_READ
FORMAL_BOOTSTRAP_BAR1_BYTES=
    NOT_READ
FORMAL_BOOTSTRAP_DRIVER=
    NOT_LOADED
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
    NOT_RUN_JTAG_STABILITY_GATE_FAILED
ARM_A_VENDOR_STARTUP=
    NOT_APPLICABLE
ARM_A_SAME_SESSION_DONE=
    NOT_APPLICABLE
ARM_A_INDEPENDENT_DONE=
    NOT_APPLICABLE
ARM_A_WAIT_SECONDS=
    0
ARM_A_BOOT_ID_CHANGED=
    NOT_APPLICABLE
ARM_A_KERNEL=
    NOT_READ
ARM_A_BAR0_BYTES=
    NOT_READ
ARM_A_BAR1_BYTES=
    NOT_READ
ARM_A_DRIVER=
    NOT_LOADED
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
    NOT_RUN_JTAG_STABILITY_GATE_FAILED
ARM_B_VENDOR_STARTUP=
    NOT_APPLICABLE
ARM_B_SAME_SESSION_DONE=
    NOT_APPLICABLE
ARM_B_INDEPENDENT_DONE=
    NOT_APPLICABLE
ARM_B_WAIT_SECONDS=
    0
ARM_B_BOOT_ID_CHANGED=
    NOT_APPLICABLE
ARM_B_KERNEL=
    NOT_READ
ARM_B_BAR0_BYTES=
    NOT_READ
ARM_B_BAR1_BYTES=
    NOT_READ
ARM_B_DRIVER=
    NOT_LOADED
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
    UNPROVEN_NOT_MODIFIED_BY_R5

FINAL_FORMAL_IDENTITY=
    UNPROVEN_NOT_READ_R5
FINAL_DIAGNOSTIC_MAGIC=
    UNPROVEN_NOT_READ_R5
FINAL_PINNED_DRIVER_LOADED=
    UNPROVEN_NOT_QUERIED_R5
FINAL_DONE=
    UNPROVEN_UNREADABLE_R5

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
    070F457D04D5569AB4DE54E00285CA155A0E4687B5A156B16D8776F389673522
EVIDENCE_PACKAGE_SHA256=
    RECORDED_IN_V41_NVP_R1E_R5_COMPLETE_MEASUREMENT_EVIDENCE_SHA256.txt
EVIDENCE_REPOSITORY_COMMIT=
    RECORDED_OUT_OF_BAND_AFTER_THE_SINGLE_EVIDENCE_COMMIT
PUBLIC_REMOTE_VERIFICATION=
    RECORDED_OUT_OF_BAND_AFTER_PUSH
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_BLOCKED_R5_JTAG_TRANSPORT_RESULT
```
