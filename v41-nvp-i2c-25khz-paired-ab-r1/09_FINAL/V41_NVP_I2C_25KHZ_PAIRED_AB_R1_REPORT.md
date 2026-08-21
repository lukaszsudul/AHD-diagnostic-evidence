# V41 NVP 25-kHz paired A/B diagnostic — R1 final report

## Executive result

| Item | Result |
|---|---|
| Exact one-line 25-kHz source change | PASS |
| Numerical/model agreement | PASS |
| Equal transaction stream | PASS |
| One clean diagnostic build | PASS |
| Arm A infrastructure | INVALID after the consumed program's required EOS-property observer failed |
| Arm A functional result | NOT MEASURED |
| Paired A/B scientific result | INCONCLUSIVE_INFRASTRUCTURE |
| Exact formal restoration | PASS — startup HIGH, DONE=1 |
| Formal restoration context | NVP FAIL: INIT_ERROR=1, NACK=19, SAV/frame=0 |
| Terminal hardware state | Exact formal Phase 2, pinned XDMA loaded, DONE=1 |

The experiment did not answer whether 25 kHz repairs NVP initialization. The
diagnostic image was programmed once, but the prescribed post-program
supervisor failed when Vivado did not expose `REGISTER.IR.BIT4_EOS`. Although
the vendor program engine reported startup HIGH and a later zero-program JTAG
session proved DONE=1, fail-closed procedure accounting prohibited the Arm-A
reboot and telemetry. No functional observation exists for the 25-kHz image.

Under the prompt's infrastructure-invalid branch, the second and final FPGA
program was used only to restore exact formal Phase 2. That restoration passed
all infrastructure gates and produced a contextual formal NVP failure. It is
not substituted for a missing paired Arm-B sample and supports no new claim
about the 25-kHz variable.

## Source and numerical freeze

The diagnostic branch is based on
`8464af66611f7c22b8a36a4aab915d598eedda3f`. Commit
`f007dc172d43d30b02729755e60382f8ce3dbff4` contains exactly one functional
change: the top-level `I2C_HZ` connection changes from 50000 to 25000. Protected
NVP RTL, XCI, pin XDC, reset/start logic, watchdog, and the 53-entry register
contract are unchanged.

The exact success model contains 31,043 FSM tick actions, 31,042 inter-action
intervals, and 275 bus transactions (220 writes and 55 reads). At 62.5 MHz:

| Profile | Divider | Tick | Physical SCL | Full lifecycle from first active clock |
|---|---:|---:|---:|---:|
| Formal 50 kHz setting | 625 | 10.016 us | 49,920.1278 Hz | 1,810,922.864 us |
| Diagnostic 25 kHz setting | 1250 | 20.016 us | 24,980.0160 Hz | 2,121,355.744 us |

The focused cycle simulation and deterministic calculator agree exactly. Both
profiles emit the same transaction bytes and operation order. The slower
profile changes all tick-based protocol, NOP, table-delay, and settle intervals;
it does not change POR, the 500-ms R17 hold, the 1.5-s first-start setting, or
the released-SCL watchdog wall-clock threshold.

`DEVICE_SPECIFIC_MINIMUM_SCL=NOT_INDEPENDENTLY_PROVEN`; the run proceeded under
the owner's `I2C_25KHZ_STANDARD_MODE_ACCEPTABLE=YES_OWNER_ASSUMPTION`.

## Build result

One clean Vivado 2025.2 build completed. Strict post-build gates passed:

```text
WNS_NS=0.617
WHS_NS=0.032
VDO_WNS_NS=0.617
VDO_WHS_NS=0.601
ROUTE_ERRORS=0
DRC_ERRORS=0
DRC_CRITICAL_WARNINGS=0
CDC_CRITICAL=0
CDC_UNKNOWN=0
REQP_1839_COUNT=4
```

The resulting bitstream is 2,192,144 bytes with SHA-256
`B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191`.
The sealed build package SHA-256 is
`918E0972F94CEF0D21D87A4D92177B9DB69FF9558F6BA3217571FE68D41CCA3A`.

## Hardware sequence

Fresh discovery proved the initial exact formal Phase-2 state, exact JTAG
target/IDCODE/DONE, one expected endpoint, exact pinned driver, and the formal
runtime identity. Its pre-campaign context was a valid functional FAIL and was
kept separate from Arm B.

Arm A consumed exactly one programming invocation. `program_hw_devices`
returned with vendor startup HIGH, then the task supervisor failed because the
requested BIT4 EOS property was unavailable. It emitted `FAIL_NO_RETRY`. A
separate read-only exact-target session proved DONE=1 and a 5.012176700-second
wait was recorded, but no reboot, driver load, provenance read, or functional
telemetry followed. Arm A is therefore infrastructure-invalid.

The exact formal bit was then programmed through a previously accepted
restoration script. Vivado reported startup HIGH and DONE=1. After a
5.016797600-second wait, one warm reboot changed the boot ID from
`7f8db2e5-12aa-4421-b44a-28e72fff483f` to
`b9d58c87-6574-4596-8ff9-b61052ba26dc`. The exact pinned module was loaded once
through the exact accepted loader. Endpoint IDs, Gen1 x1 link, 128-KiB BAR0,
64-KiB BAR1, 21-node set, zero node owners, and kernel/AER health all passed.

Formal runtime identity was `A40A0C07 / 0000400B / 00031002`, diagnostic magic
was zero, and all five runtime Git words plus build flags were zero as in the
accepted formal closure. Its contextual sample observed VCLK between
147.824014589 and 149.230416016 MHz, `INIT_ERROR=1`, 19 NACKs, no timeout, and
zero SAV/frame activity. The final exact-target JTAG session reported DONE=1.

## Retained-evidence limitations

The accepted formal-restoration Tcl and transcript predate the task's canonical
operation-event schema. The reboot disappearance monitor's output was not
retained, and the formal wait record preserves the calculated duration but not
its raw reference/end ticks. These are evidence-format limitations, not an
unresolved hardware-state blocker: vendor startup HIGH, `DONE=1`, the changed
boot ID and low uptime, exact formal runtime identity, the exact pinned driver,
and the final independent `DONE=1` session jointly prove safe restoration.

## Scientific classification

```text
PAIRED_AB_RESULT=INCONCLUSIVE_INFRASTRUCTURE
I2C_25KHZ_DIAGNOSTIC=INCONCLUSIVE_NOT_FUNCTIONALLY_MEASURED
SLOWER_COMPLETE_I2C_TIMING_PROFILE=NOT_EVALUATED
SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE=NOT_EVALUATED
ROOT_CAUSE_SOLELY_PROVEN=NO
```

The run neither supports nor rejects the slower complete I2C timing profile.
It does not authorize Phase-3 integration, a repeat, a new timing value, or
continued XDMA work. Any next experiment requires owner review and separate
authorization.

## Required final block

```text
TASK=
    V41_NVP_I2C_25KHZ_PAIRED_AB_R1

TASK_TYPE=
    ONE_BUILD_ONE_PAIRED_AB_CAMPAIGN

POWER_CONTEXT_EVIDENCE_COMMIT=
    f711325fab4e993bfaf1881626d23c2dac20c8af

BASE_COMMIT=
    8464af66611f7c22b8a36a4aab915d598eedda3f

BASE_DIRECT_PARENT=
    c89e88bcdf389614c884fb129e8b2d42a585bccb

DIAGNOSTIC_BRANCH=
    diag/v41-nvp-i2c-25khz-r1

DIAGNOSTIC_SOURCE_COMMIT=
    f007dc172d43d30b02729755e60382f8ce3dbff4

DIAGNOSTIC_SOURCE_TREE=
    b8f87966c8021396acb6341bd2d7d86a10fd7f13

TRACKED_FUNCTIONAL_DIFF_COUNT=
    1

TRACKED_FUNCTIONAL_DIFF=
    rtl/top/ahd_capture_top_xdma.sv_I2C_HZ_50000_TO_25000

PROTECTED_NVP_BLOBS_UNCHANGED=
    YES

XDMA_XCI_UNCHANGED=
    YES

PIN_XDC_UNCHANGED=
    YES

REGISTER_CONTRACT_UNCHANGED=
    YES

CLK_HZ=
    62500000

FORMAL_I2C_HZ=
    50000

DIAGNOSTIC_I2C_HZ=
    25000

FORMAL_DIVIDER=
    625

DIAGNOSTIC_DIVIDER=
    1250

FORMAL_TICK_US=
    10.016

DIAGNOSTIC_TICK_US=
    20.016

FORMAL_SCL_HZ=
    approximately 49920.1278

DIAGNOSTIC_SCL_HZ=
    approximately 24980.0160

LOCAL_POR_US=
    5.120

R17_LOW_SECONDS=
    0.500

FIRST_I2C_START_SECONDS=
    1.500

FORMAL_FULL_AUTOINIT_US=
    1810922.864000

DIAGNOSTIC_FULL_AUTOINIT_US=
    2121355.744000

AUTOINIT_SCRIPT_SIMULATION_MATCH=
    YES

SCL_RELEASED_LOW_WATCHDOG_UNCHANGED=
    YES

TRANSACTION_STREAM_BYTE_IDENTICAL=
    YES

OPERATION_ORDER_IDENTICAL=
    YES

FULL_BUILD=
    PASS_ONE_CLEAN_BUILD

FULL_BUILD_WNS=
    0.617

FULL_BUILD_WHS=
    0.032

FULL_BUILD_VDO_WNS=
    0.617

FULL_BUILD_VDO_WHS=
    0.601

FULL_BUILD_DRC_ERRORS=
    0

FULL_BUILD_DRC_CRITICAL_WARNINGS=
    0

FULL_BUILD_CDC_CRITICAL=
    0

FULL_BUILD_CDC_UNKNOWN=
    0

FULL_BUILD_REQP_1839_COUNT=
    4

DIAGNOSTIC_BIT_SHA256=
    B125940D11CD5400F176E773A49C0A3529FF0ADEA08293E1601245DBC5FBE191

DIAGNOSTIC_RUNTIME_GIT_SHA=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

DIAGNOSTIC_RUNTIME_BUILD_FLAGS=
    NOT_READ_INFRASTRUCTURE_HARD_STOP

ARM_A_PROGRAM=
    EXECUTED_ONCE_PROGRAM_HW_DEVICES_RETURNED_POST_OBSERVER_INFRASTRUCTURE_INVALID

ARM_A_EOS=
    HIGH_VENDOR_END_OF_STARTUP_STATUS

ARM_A_POST_PROGRAM_OBSERVER=
    FAIL_UNAVAILABLE_BIT4_EOS_PROPERTY

ARM_A_DONE=
    1_FRESH_SEPARATE_READ_ONLY_SESSION

ARM_A_WAIT_SECONDS=
    5.012176700

ARM_A_BOOT_ID_CHANGED=
    NOT_APPLICABLE_NO_REBOOT

ARM_A_DRIVER=
    NOT_RUN_FAIL_CLOSED

ARM_A_INIT_DONE=
    NOT_MEASURED

ARM_A_INIT_ERROR=
    NOT_MEASURED

ARM_A_NACK_COUNT=
    NOT_MEASURED

ARM_A_TIMEOUT_COUNT=
    NOT_MEASURED

ARM_A_FIRST_ERROR=
    NOT_MEASURED

ARM_A_VCLK_HZ=
    NOT_MEASURED

ARM_A_SAV_RATE=
    NOT_MEASURED

ARM_A_FRAME_RATE=
    NOT_MEASURED

ARM_A_RESULT=
    INFRASTRUCTURE_INVALID

FORMAL_BIT_SHA256=
    7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2

ARM_B_PROGRAM=
    PASS_MANDATORY_FORMAL_RESTORATION_ONLY

ARM_B_EOS=
    HIGH_VENDOR_STARTUP_STATUS

ARM_B_DONE=
    1

ARM_B_WAIT_SECONDS=
    5.016797600

ARM_B_BOOT_ID_CHANGED=
    YES_7F8DB2E5_TO_B9D58C87

ARM_B_DRIVER=
    PASS_EXACT_PINNED_MODULE_AND_ACCEPTED_LOADER

ARM_B_FORMAL_IDENTITY=
    A40A0C07_0000400B_00031002

ARM_B_DIAGNOSTIC_MAGIC=
    00000000

ARM_B_INIT_DONE=
    1

ARM_B_INIT_ERROR=
    1

ARM_B_NACK_COUNT=
    19

ARM_B_TIMEOUT_COUNT=
    0

ARM_B_FIRST_ERROR=
    CODE_0x02_STEP_0x12_META_0x05_PHYS_0x05_REG_0x58_VALUE_0x02

ARM_B_VCLK_HZ=
    147824014.589273_TO_149230416.016308

ARM_B_SAV_RATE=
    0

ARM_B_FRAME_RATE=
    0

ARM_B_RESULT=
    FORMAL_RESTORE_CONTEXT_NVP_FAIL

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
    OWNER_AND_AUDITOR_REVIEW_OF_INFRASTRUCTURE_INVALID_DIAGNOSTIC_AND_SUCCESSFUL_FORMAL_RESTORE

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
    A40A0C07_0000400B_00031002

FINAL_DIAGNOSTIC_MAGIC=
    00000000

FINAL_PINNED_DRIVER_LOADED=
    YES

FINAL_DONE=
    1

CLEAN_DIAGNOSTIC_BUILDS=
    1

PAIRED_AB_CAMPAIGNS=
    1

PAIRED_AB_CAMPAIGNS_COMPLETED=
    0

FPGA_PROGRAM_INVOCATIONS=
    2

WARM_REBOOTS=
    1

POST_REBOOT_DRIVER_LOADER_INVOCATIONS=
    1

COLD_STARTS=
    0

PHYSICAL_ACTIONS=
    0

PROGRAM_RETRIES=
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

FORMAL_BRANCH_MUTATIONS=
    0

EVIDENCE_REPOSITORY_COMMIT=
    NOT_SELF_EMBEDDABLE_RECORDED_IN_LOCAL_EVIDENCE_PUBLICATION_RECEIPT.md

EVIDENCE_PACKAGE_SHA256=
    NOT_SELF_EMBEDDABLE_SEE_V41_NVP_I2C_25KHZ_PAIRED_AB_R1_MEASUREMENT_PACKAGE_SHA256.txt
```
