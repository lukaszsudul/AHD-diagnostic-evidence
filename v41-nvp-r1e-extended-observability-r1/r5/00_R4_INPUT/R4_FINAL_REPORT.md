# V41 NVP R1e extended-observability final report

## Outcome

R4 ended at the single authorized formal-bootstrap programming attempt. The
exact formal Phase-2 bit was submitted to the exact JTAG target, consuming the
one bootstrap invocation at `2026-08-23T13:24:58Z`. Vivado returned
`[Labtools 27-3165] End of startup status: LOW`; the programming command did
not produce an accepted return marker and no fresh post-program DONE proof was
available. The no-retry gate therefore terminated hardware execution.

No warm reboot or driver load followed the failed bootstrap. Arm A and Arm B
were not run, so R4 produced no lifecycle, ordered-NACK, address-probe, or
paired functional sample. The SRAM image and DONE state after the failed
programming attempt remain unproven. No scientific R1e inference is made from
this infrastructure result.

The final active-image requirements (`FORMAL_PHASE2`, exact formal runtime
identity, pinned driver loaded, and `DONE=1`) were not established. Physical
recovery and a new, separately authorized campaign are outside R4.

## Frozen R1e implementation

R4 reused the already completed R1e implementation without rebuilding or
changing source:

- source commit: `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`
- source tree: `db8b5581a237e19905fd01c6d453793047bc3ba7`
- routed DCP SHA-256: `1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1`
- R1e bit SHA-256: `0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9`
- formal bit SHA-256: `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`

The frozen scientific parameters remained 25-kHz autoinit, 62.5-MHz clock,
1,251-cycle state tick, expected `CNT_AT_INIT_DONE=132584734`, post-init
address byte `0x60`, and 10,000 25-kHz probes.

## Prior execution history

The R1e implementation had already passed source protection, pre-init-done
equivalence, ordered-log address-map, probe simulation, synthesis, placement,
routing, timing, and DRC gates. The original build-tail stopped before
`write_bitstream` because a report-only `report_property` invocation received
two objects. The first continuation stopped on a namespace-invalid comparison
between a Vivado checkpoint design-object name and the HDL top identifier. R2
corrected those issues but stopped because a raw text-occurrence parser counted
one REQP-1839 summary label plus four semantic violations. R3 replaced that
aggregate text gate with semantic DRC-object counting, generated the sole R1e
bitstream, and then stopped because the existing runtime image returned an
unproven all-ones identity.

R4 preserved those historical boundaries and used its newly authorized
one-time exact-formal bootstrap solely to establish a known start state. The
bootstrap programming failure occurred before either scientific arm.

## R4 gates completed before programming

- R3 evidence and package identities: verified.
- Exact R1e source/tree/DCP/bit identities: verified.
- Exact formal bit identity: verified.
- Frozen host tools and offline fixtures: passed.
- Fresh JTAG target/part/IDCODE/DONE precheck: passed before programming.
- Fresh kernel, next-boot kernel, endpoint, link, BAR, driver provenance,
  node-owner, DMA, and kernel/AER safety gates: passed before programming.
- Existing runtime formal identity: not proven; bootstrap selected.

The detailed raw discovery, programming transcript, tool receipts, and
operation accounting are authoritative where they provide values not yet
substituted into the final block below.

## Hardware transition and hard stop

The exact formal bit was rehashed immediately before the bootstrap. The
accepted programming observer began its single `program_hw_devices` invocation
and emitted the consumed marker. Vivado subsequently reported startup LOW and
the command failed. Per the explicit R4 gate:

```text
FORMAL_BOOTSTRAP_RESULT=
    BLOCKED_FORMAL_BOOTSTRAP_PROGRAMMING_FAILURE

CLASSIFICATION=
    BLOCKED_FORMAL_BOOTSTRAP_PROGRAMMING_FAILURE

PROGRAM_RETRIES=
    0
```

The failure prohibited a program retry, reboot, driver load, formal runtime
identity read, Arm A, and Arm B. Because no accepted same-session post-program
DONE result exists, the current SRAM image is not inferred from either the
pre-program state or intended bit path.

## Scientific result

```text
R1E_ARM_A_SAMPLE=
    NOT_RUN_BOOTSTRAP_PROGRAMMING_FAILED

R1E_ARM_B_SAMPLE=
    NOT_RUN_BOOTSTRAP_PROGRAMMING_FAILED

PAIRED_AB_RESULT=
    NOT_EVALUATED_NO_HARDWARE_CAMPAIGN

CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=
    NOT_APPLICABLE_NO_ARM_A_SAMPLE

STOCHASTIC_ADDRESS_OR_BUS_MARGIN=
    NOT_EVALUATED_NO_ARM_A_PROBE_SAMPLE

AUTOINIT_OPERATION_OR_PHASE_CONTEXT=
    NOT_EVALUATED_NO_ORDERED_LOG_SAMPLE

POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=
    NOT_EVALUATED_NO_ARM_A_SAMPLE
```

The task does not prove a root cause, VCCO droop, ground bounce, or analog
margin. It also does not yield a failed NVP functional sample: no R1e image was
programmed and neither A/B arm was observed.

## Evidence and follow-up

The sealed evidence package includes the prompt, frozen artifact and tool
proofs, complete fresh discovery, exact programming observer transcript,
Vivado log/journal, the consumed-invocation receipt, operation ledger, secret
scan, and this report. The package hash is recorded in its sidecar. A Git
commit cannot self-embed its own hash, so the containing evidence commit and
remote verification are recorded by the external publication receipt and the
task handoff.

The next permissible action is owner/auditor review of the bootstrap
programming failure and, if desired, a new separately authorized hardware
recovery campaign. R4 itself is complete and cannot retry.

## Required final block

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
    PASS_READ_ONLY_DISCOVERY_COMPLETED
START_STATE_CLASSIFICATION=
    REQUIRES_EXACT_FORMAL_BOOTSTRAP
START_STATE_RAW_READER_BLOCK_ID=
    0xFFFFFFFF
START_STATE_ACCEPTED_READER_BLOCK_ID=
    0xFFFFFFFF

FORMAL_BOOTSTRAP_RUN=
    YES
FORMAL_BOOTSTRAP_PROGRAM=
    FAIL_VENDOR_STARTUP_LOW_LABTOOLS_27_3165
FORMAL_BOOTSTRAP_WAIT_SECONDS=
    0_NOT_REACHED
FORMAL_BOOTSTRAP_BOOT_ID_CHANGED=
    NO_REBOOT_NOT_REACHED
FORMAL_BOOTSTRAP_KERNEL=
    NOT_RECHECKED_AFTER_FAILED_PROGRAM
FORMAL_BOOTSTRAP_DRIVER=
    NO_NEW_LOAD_REBOOT_NOT_REACHED_PREEXISTING_PINNED_DRIVER_NOT_REVALIDATED
FORMAL_BOOTSTRAP_IDENTITY=
    NOT_VERIFIED_PROGRAMMING_FAILED
FORMAL_BOOTSTRAP_DONE=
    NOT_PROVEN

FORMAL_READY=
    NO
FORMAL_READY_SOURCE=
    NONE_BOOTSTRAP_FAILED

ARM_A_PROGRAM=
    NOT_RUN_BOOTSTRAP_PROGRAMMING_FAILED
ARM_A_WAIT_SECONDS=
    0_NOT_RUN
ARM_A_BOOT_ID_CHANGED=
    NO_NOT_RUN
ARM_A_KERNEL=
    NOT_RUN
ARM_A_BAR0_BYTES=
    NOT_RUN
ARM_A_BAR1_BYTES=
    NOT_RUN
ARM_A_DRIVER=
    NOT_RUN
ARM_A_RUNTIME_PROVENANCE=
    NOT_RUN
ARM_A_CNT_AT_INIT_DONE=
    NOT_MEASURED
ARM_A_EXPECTED_CNT_AT_INIT_DONE=
    132584734
ARM_A_SIGNED_COUNT_ERROR_CYCLES=
    NOT_COMPUTABLE
ARM_A_SHORTENING_CYCLES=
    NOT_COMPUTABLE
ARM_A_SHORTENING_TICKS_EXACT=
    NOT_COMPUTABLE
ARM_A_SHORTENING_TICKS_NEAREST=
    NOT_COMPUTABLE
ARM_A_SHORTENING_RESIDUAL_CYCLES=
    NOT_COMPUTABLE
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
    NOT_COMPUTABLE
ARM_A_PROBE_NACK_RATE_PPM=
    NOT_COMPUTABLE
ARM_A_PROBE_WILSON95=
    NOT_COMPUTABLE
ARM_A_PROBE_FIRST_NACK_INDEX=
    NOT_MEASURED
ARM_A_PROBE_LAST_NACK_INDEX=
    NOT_MEASURED
ARM_A_PROBE_MAX_CONSECUTIVE_NACKS=
    NOT_MEASURED
ARM_A_NVP_RESULT=
    NOT_RUN_BOOTSTRAP_PROGRAMMING_FAILED
ARM_A_FINAL_DONE=
    NOT_RUN

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

ARM_B_PROGRAM=
    NOT_RUN_BOOTSTRAP_PROGRAMMING_FAILED
ARM_B_WAIT_SECONDS=
    0_NOT_RUN
ARM_B_BOOT_ID_CHANGED=
    NO_NOT_RUN
ARM_B_KERNEL=
    NOT_RUN
ARM_B_BAR0_BYTES=
    NOT_RUN
ARM_B_BAR1_BYTES=
    NOT_RUN
ARM_B_DRIVER=
    NOT_RUN
ARM_B_FORMAL_IDENTITY=
    NOT_RUN
ARM_B_DIAGNOSTIC_MAGIC=
    NOT_RUN
ARM_B_R1E_PAGE_ZERO=
    NOT_RUN
ARM_B_NACK_COUNT=
    NOT_MEASURED
ARM_B_NACK_LOG_COUNT=
    NOT_MEASURED
ARM_B_NACK_LOG_OVERFLOW=
    NOT_MEASURED
ARM_B_ORDERED_NACK_RECORDS=
    NOT_MEASURED
ARM_B_NVP_RESULT=
    NOT_RUN_BOOTSTRAP_PROGRAMMING_FAILED
ARM_B_FINAL_DONE=
    NOT_RUN

PAIRED_AB_RESULT=
    NOT_EVALUATED_NO_HARDWARE_CAMPAIGN
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=
    NOT_APPLICABLE_NO_ARM_A_SAMPLE
STOCHASTIC_ADDRESS_OR_BUS_MARGIN=
    NOT_EVALUATED_NO_ARM_A_PROBE_SAMPLE
AUTOINIT_OPERATION_OR_PHASE_CONTEXT=
    NOT_EVALUATED_NO_ORDERED_LOG_SAMPLE
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=
    NOT_EVALUATED_NO_ARM_A_SAMPLE

ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO

FINAL_ACTIVE_IMAGE=
    UNPROVEN_AFTER_FAILED_FORMAL_BOOTSTRAP_PROGRAM

FINAL_FORMAL_IDENTITY=
    NOT_VERIFIED_AFTER_FAILED_BOOTSTRAP_PROGRAM
FINAL_DIAGNOSTIC_MAGIC=
    NOT_VERIFIED_AFTER_FAILED_BOOTSTRAP_PROGRAM
FINAL_PINNED_DRIVER_LOADED=
    NOT_REVALIDATED_AFTER_FAILED_FORMAL_BOOTSTRAP_PROGRAM
FINAL_DONE=
    NOT_PROVEN

FORMAL_BOOTSTRAP_PROGRAMS=
    1
ARM_A_PROGRAMS=
    0
ARM_B_PROGRAMS=
    0
FPGA_PROGRAM_INVOCATIONS=
    1

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

EVIDENCE_PACKAGE_SHA256=
    RECORDED_IN_V41_NVP_R1E_R4_COMPLETE_MEASUREMENT_EVIDENCE_SHA256.txt
EVIDENCE_REPOSITORY_COMMIT=
    RECORDED_OUT_OF_BAND_AFTER_THE_SINGLE_EVIDENCE_COMMIT
PUBLIC_REMOTE_VERIFICATION=
    RECORDED_OUT_OF_BAND_AFTER_PUSH
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_FAILED_FORMAL_BOOTSTRAP_PROGRAMMING
```
