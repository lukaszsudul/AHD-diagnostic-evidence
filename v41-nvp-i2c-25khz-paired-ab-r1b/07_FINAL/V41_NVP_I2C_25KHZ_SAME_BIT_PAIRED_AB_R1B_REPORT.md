# V41 NVP 25-kHz paired A/B diagnostic — R1b final report

## Executive result

| Item | Result |
|---|---|
| Prior R1 record | Preserved unchanged at evidence commit `5a81f5b115dddcdddd809a655fced115e113585e` |
| R1b FPGA build/source activity | None; exact sealed R1 bit reused |
| Corrected programming observer | Offline static/fixture/preflight gates PASS |
| Arm A exact 25-kHz program | PASS: startup HIGH, same-session DONE=1, one invocation, no retry |
| Arm A warm reboot | PASS; boot ID changed |
| Arm A driver gate | HARD STOP before loader: kernel `7.0.0-30` versus pinned-module vermagic `7.0.0-29` |
| Arm A functional result | Not measured; infrastructure-invalid |
| Arm B | Exact formal bit restored once; restoration-only, not a paired functional control |
| Paired scientific result | `INCONCLUSIVE_INFRASTRUCTURE` |
| Terminal FPGA state | Exact formal Phase 2 programmed, fresh read-only DONE=1 |
| Terminal host state | Pinned driver not loaded; runtime identity not read |

R1b did not answer whether the 25-kHz timing profile repairs NVP
initialization. The exact diagnostic image programmed successfully, but the
single authorized warm reboot selected kernel `7.0.0-30-generic`; the exact
pinned XDMA module has vermagic `7.0.0-29-generic`. The compatibility gate
failed before the accepted loader was invoked, so runtime provenance and all
NVP/video telemetry remained unread.

The exact formal Phase-2 bit was subsequently programmed once as the mandatory
safe restoration. Vendor startup status was HIGH, same-session `DONE=1` was
observed, the monotonic wait was 5.000408800 seconds, and an independent
zero-program JTAG session ended with `DONE=1`. No second reboot, loader, or
host telemetry was authorized after the infrastructure hard stop. The formal
program is therefore a successful SRAM restoration, not a valid Arm-B
functional control.

## Immutable artifact and no-build proof

R1b reused the exact R1 diagnostic artifact:

```text
DIAGNOSTIC_SOURCE_COMMIT=f007dc172d43d30b02729755e60382f8ce3dbff4
DIAGNOSTIC_SOURCE_TREE=b8f87966c8021396acb6341bd2d7d86a10fd7f13
DIAGNOSTIC_BIT_SIZE=2192144
DIAGNOSTIC_BIT_SHA256=B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191
DIAGNOSTIC_BUILD_PACKAGE_SHA256=918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A
```

The reused source contains the single R1 functional change
`.I2C_HZ(50000)` to `.I2C_HZ(25000)`. R1b performed no checkout, FPGA-source
edit, synthesis, implementation, DCP operation, or bitstream generation.

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FORMAL_REPOSITORY_MUTATIONS=0
DIAGNOSTIC_BUILD_REUSED=YES_EXACT_ARTIFACT
```

The exact formal restore bit was 2,192,144 bytes with SHA-256
`7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`.

## Programming-observer correction and recovery

R1b changed only task-local observer plumbing. The corrected Tcl never queries
the unavailable BIT4 EOS property, contains one programming command, and
checks BIT5 DONE before and after the single program. The Windows supervisor
derives EOS solely from Vivado's vendor startup-HIGH line and requires the
consumed, startup, return, DONE, fresh-DONE, Tcl-pass, and exit-zero events in
strict order. Static audit, negative fixtures, the historical-log replay, and
the read-only property preflight all passed before hardware use.

The Arm-A supervisor then preserved a complete valid raw transcript but threw
while appending its derived verdict. This was a post-observation evidence
formatting failure: the raw log contains one consumed program, one vendor
startup-HIGH line, the return marker, same-session DONE=1, the fresh-DONE
marker, the Tcl pass marker, no timeout, and process exit zero. Two offline
postprocess attempts were preserved; the second produced the accepted flat
record. Neither replay accessed JTAG or programmed hardware.

```text
ARM_A_RAW_PROGRAM_LOG_SHA256=B635EC7C6343370C0560E3DA8A29242FDE418D1E7D4895E8A6DE1E23CEC8D67D
OBSERVER_PARSER_SHA256=6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66
PROGRAM_SUPERVISOR_POSTPROCESS_FAILURES=1
PROGRAM_OBSERVER_OFFLINE_RECOVERY_ATTEMPTS=2
PROGRAM_OBSERVER_OFFLINE_RECOVERIES_ACCEPTED=1
PROGRAM_OBSERVER_RECOVERY_HARDWARE_ACTIONS=0
```

## Hardware record

### Arm A — exact 25-kHz diagnostic

The exact diagnostic bit programmed once on HS2 `210241768436`, device
`xc7a35t`, IDCODE `0362D093`. Vivado reported startup HIGH and same-session
DONE=1, with one consumed invocation and no retry. The accepted same-QPC replay
proved 223.944751400 seconds from the fresh-DONE reference to its observation,
well above the 5-second minimum.

One warm reboot changed the boot ID from
`b9d58c87-6574-4596-8ff9-b61052ba26dc` to
`2051bd6b-28c4-4570-8ed9-f127a7002bae`; disappearance and return were both
observed. The post-reboot host reported:

```text
RUNNING_KERNEL=7.0.0-30-generic
PINNED_MODULE_SHA256=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
PINNED_MODULE_VERMAGIC=7.0.0-29-generic
ENDPOINT=10ee:7011_SUBSYSTEM_10ee:0007
LINK=GEN1_X1
BOUND_DRIVER=ABSENT
XDMA_MODULE_PRESENT=NO
XDMA_NODE_COUNT=0
```

The exact compatibility check failed before loader invocation. No same-name
module was loaded or bound, and no XDMA node was open. Runtime Git words,
build flags, diagnostics, and video counters were not read. Arm A is therefore
`INCONCLUSIVE_INFRASTRUCTURE`, not a functional PASS or FAIL.

The post-reboot host-precheck script also emitted a BAR-size arithmetic parsing
error and left the BAR0/BAR1 byte fields blank. This did not cause or resolve
the terminal blocker: the independent kernel/vermagic mismatch was already an
exact fail-closed loader gate. No script correction, retry, or alternate
driver path was attempted.

### Arm B — mandatory exact formal restoration

The exact formal bit was programmed once. The raw supervisor record proves:

```text
PROGRAM_START_UTC=2026-08-22T07:56:43Z
PROGRAM_END_UTC=2026-08-22T07:56:49Z
PROGRAM_INVOCATIONS=1
VENDOR_STARTUP_STATUS=HIGH
PROGRAM_DONE=1
PROCESS_EXIT_CODE=0
COUNT_GATE=PASS
ORDER_GATE=PASS
ACTUAL_WAIT_SECONDS=5.000408800
```

After the hard stop there was no Arm-B warm reboot, driver load, runtime
identity read, or NVP/video sample. A fresh zero-program JTAG session from
07:57:59Z to 07:59:00Z proved the exact target and `DONE=1`. The final FPGA
image is exact formal Phase 2, but the final pinned driver is not loaded and
formal runtime identity/diagnostic magic were not read.

## Scientific classification

```text
ARM_A_RESULT=INCONCLUSIVE_INFRASTRUCTURE
ARM_B_ROLE=MANDATORY_FORMAL_RESTORATION_ONLY
ARM_B_RESULT=RESTORATION_ONLY_PASS
ARM_B_PAIRED_CONTROL_VALID=NO
PAIRED_AB_RESULT=INCONCLUSIVE_INFRASTRUCTURE
I2C_25KHZ_DIAGNOSTIC=INCONCLUSIVE_NOT_FUNCTIONALLY_MEASURED
SLOWER_COMPLETE_I2C_TIMING_PROFILE=NOT_EVALUATED
MARGINAL_PROTOCOL_OR_SETTLING_TIMING=NOT_EVALUATED
SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE=NOT_EVALUATED
ROOT_CAUSE_SOLELY_PROVEN=NO
READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW=NO
READY_TO_RETURN_TO_XDMA=NO
```

R1b neither supports nor rejects the slower complete I2C timing profile. It
does not authorize a third program, another reboot, a module rebuild, an
alternate driver, a new timing value, Phase 3, or XDMA development.

## Required R1b owner block

```text
TASK=
    V41_NVP_I2C_25KHZ_SAME_BIT_PAIRED_AB_R1B

PRIOR_EVIDENCE_COMMIT=
    5a81f5b115dddcdddd809a655fced115e113585e

PRIOR_SAMPLE_CLASSIFICATION=
    INCONCLUSIVE_NOT_FUNCTIONALLY_MEASURED

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

PROGRAM_OBSERVER_FIX=
    REMOVE_UNSUPPORTED_BIT4_EOS_QUERY_USE_VENDOR_STARTUP_HIGH_PLUS_BIT5_DONE

BIT4_EOS_PROPERTY_AVAILABLE=
    NO

BIT4_EOS_PROPERTY_QUERY_ATTEMPTED=
    NO

BIT5_DONE_PROPERTY_AVAILABLE=
    YES

PROGRAM_OBSERVER_STATIC_AUDIT=
    PASS_INITIAL_AND_POSTFIX

PROGRAM_OBSERVER_FIXTURE_GATE=
    PASS_11_OF_11_INITIAL_AND_POSTFIX

PRIOR_LOG_REPLAY=
    PASS_RETAINED_FAIL_POST_PROGRAM_OBSERVER_BIT4

READ_ONLY_PROPERTY_PREFLIGHT=
    PASS_BIT5_PRESENT_BIT4_ABSENT_DONE_1_ZERO_PROGRAMS

ARM_A_PROGRAM=
    PASS_SINGLE_INVOCATION_RAW_EVIDENCE_REPLAYED

ARM_A_VENDOR_STARTUP_STATUS=
    HIGH

ARM_A_DONE=
    1

ARM_A_PROGRAM_RESULT=
    PASS_STARTUP_HIGH_DONE_1_REPLAYED_AFTER_POSTPROCESS_APPEND_FAILURE

ARM_A_WAIT_SECONDS=
    223.944751400_AT_ACCEPTED_SAME_QPC_RECOVERY_OBSERVATION

ARM_A_BOOT_ID_CHANGED=
    YES_B9D58C87_TO_2051BD6B

ARM_A_DRIVER=
    BLOCKED_PREINVOCATION_KERNEL_7_0_0_30_VS_PINNED_MODULE_VERMAGIC_7_0_0_29

ARM_A_RUNTIME_GIT_SHA=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_RUNTIME_BUILD_FLAGS=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_INIT_DONE=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_INIT_ERROR=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_NACK_COUNT=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_TIMEOUT_COUNT=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_FIRST_ERROR=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_VCLK_HZ=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_SAV_RATE=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_FRAME_RATE=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_RESULT=
    INCONCLUSIVE_INFRASTRUCTURE

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

ARM_B_PROGRAM=
    PASS_SINGLE_INVOCATION_FORMAL_RESTORATION_ONLY

ARM_B_VENDOR_STARTUP_STATUS=
    HIGH

ARM_B_DONE=
    1

ARM_B_PROGRAM_RESULT=
    PASS_STARTUP_HIGH_DONE_1

ARM_B_WAIT_SECONDS=
    5.000408800

ARM_B_BOOT_ID_CHANGED=
    NOT_APPLICABLE_NO_REBOOT_RESTORATION_ONLY_AFTER_INFRASTRUCTURE_HARD_STOP

ARM_B_DRIVER=
    NOT_LOADED

ARM_B_FORMAL_IDENTITY=
    NOT_READ_NO_POST_RESTORE_HOST_SESSION

ARM_B_DIAGNOSTIC_MAGIC=
    NOT_READ_NO_POST_RESTORE_HOST_SESSION

ARM_B_INIT_DONE=
    NOT_READ

ARM_B_INIT_ERROR=
    NOT_READ

ARM_B_NACK_COUNT=
    NOT_READ

ARM_B_TIMEOUT_COUNT=
    NOT_READ

ARM_B_FIRST_ERROR=
    NOT_READ

ARM_B_VCLK_HZ=
    NOT_READ

ARM_B_SAV_RATE=
    NOT_READ

ARM_B_FRAME_RATE=
    NOT_READ

ARM_B_RESULT=
    RESTORATION_ONLY_PASS_NOT_PAIRED_CONTROL

PAIRED_AB_RESULT=
    INCONCLUSIVE_INFRASTRUCTURE

I2C_25KHZ_DIAGNOSTIC=
    INCONCLUSIVE_NOT_FUNCTIONALLY_MEASURED

SLOWER_COMPLETE_I2C_TIMING_PROFILE=
    NOT_EVALUATED

SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE=
    NOT_EVALUATED

ROOT_CAUSE_SOLELY_PROVEN=
    NO

READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW=
    NO

READY_TO_RETURN_TO_XDMA=
    NO

NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_KERNEL_PINNED_MODULE_COMPATIBILITY_BLOCKER_BEFORE_ANY_NEW_HARDWARE_RUN

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
    NOT_READ_NO_POST_RESTORE_HOST_SESSION

FINAL_DIAGNOSTIC_MAGIC=
    NOT_READ_NO_POST_RESTORE_HOST_SESSION

FINAL_PINNED_DRIVER_LOADED=
    NO_KERNEL_VERMAGIC_MISMATCH

FINAL_DONE=
    1

FPGA_PROGRAM_INVOCATIONS=
    2

WARM_REBOOTS=
    1

POST_REBOOT_DRIVER_LOADER_INVOCATIONS=
    0

PROGRAM_RETRIES=
    0

COLD_STARTS=
    0

PHYSICAL_ACTIONS=
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

EVIDENCE_REPOSITORY_COMMIT=
    NOT_SELF_EMBEDDABLE_RECORDED_IN_LOCAL_EVIDENCE_PUBLICATION_RECEIPT.md

EVIDENCE_PACKAGE_SHA256=
    NOT_SELF_EMBEDDABLE_SEE_EXTERNAL_SHA256_SIDECAR
```
