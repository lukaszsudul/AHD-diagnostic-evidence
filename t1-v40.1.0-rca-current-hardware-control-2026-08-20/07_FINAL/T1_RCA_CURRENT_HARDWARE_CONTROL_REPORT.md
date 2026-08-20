# T1 exact v40.1.0 RC-A current-hardware control report

## Executive result

The scientific campaign did not start. The correct SSH server was reachable in
the approved Windows host context and its ED25519 fingerprint matched the
sealed identity, but non-interactive authentication failed for both approved
AHD key paths. No protected password channel callable non-interactively by the
task was available. The required three successful SSH commands and sudo reboot
gate therefore could not pass.

The hard gate was obeyed: zero JTAG sessions, zero FPGA programs, zero reboots,
zero BAR/NVP/video accesses, zero writes, and zero source/build actions. The
formal repository remained clean and identical to the required remote branch.
Because no current RC-A sample exists, no firmware, hardware, electrical, or
intermittency inference is scientifically valid.

## Classification

```text
T1_CLASSIFICATION=INCONCLUSIVE_INFRASTRUCTURE_SSH
EXACT_BLOCKER=NONINTERACTIVE_SSH_AUTHENTICATION_REJECTED_AND_NO_TASK_ACCESSIBLE_PROTECTED_PASSWORD_CHANNEL
SCIENTIFIC_PASS_FAIL_INFERENCE=NONE
```

## Formal-state disposition

The owner-declared starting image was the accepted formal Phase-2 reference.
No action capable of changing FPGA SRAM, host boot state, power, cabling, or
physical state occurred, so that declared start was preserved by zero mutation.
Fresh runtime identity, diagnostic magic, and JTAG DONE were intentionally not
claimed because the task stopped at the earlier mandatory SSH gate.

## Required exact block

```text
TASK=T1_EXACT_V40_1_0_RCA_CURRENT_HARDWARE_CONTROL

SSH_OWNER_CONFIRMED_WORKING=YES

SSH_AUTOMATION_GATE=FAIL_NONINTERACTIVE_AUTHENTICATION
SUDO_WARM_REBOOT_GATE=NOT_TESTED_SSH_AUTHENTICATION_FAILED

RC_A_BIT_SHA256=A43B9280FACFF259F126B0E4FDD56E39C3D136321696EBFC98B79184A747B3B6

RC_A_SOURCE_COMMIT=55ce0df41552bb74e0923f89eff43977b040f2e5

T1_PLANNED_RUNS=3

T1_VALID_RUNS=0
T1_PASS_COUNT=0
T1_FAIL_COUNT=0
T1_INVALID_COUNT=0

RUN_01_RESULT=NOT_RUN_SSH_GATE_FAILED
RUN_01_NACK_COUNT=NOT_OBSERVED
RUN_01_FIRST_ERROR=NOT_OBSERVED
RUN_01_VCLK_DELTA=NOT_OBSERVED
RUN_01_SAV_DELTA=NOT_OBSERVED
RUN_01_FRAME_DELTA=NOT_OBSERVED

RUN_02_RESULT=NOT_RUN_SSH_GATE_FAILED
RUN_02_NACK_COUNT=NOT_OBSERVED
RUN_02_FIRST_ERROR=NOT_OBSERVED
RUN_02_VCLK_DELTA=NOT_OBSERVED
RUN_02_SAV_DELTA=NOT_OBSERVED
RUN_02_FRAME_DELTA=NOT_OBSERVED

RUN_03_RESULT=NOT_RUN_SSH_GATE_FAILED
RUN_03_NACK_COUNT=NOT_OBSERVED
RUN_03_FIRST_ERROR=NOT_OBSERVED
RUN_03_VCLK_DELTA=NOT_OBSERVED
RUN_03_SAV_DELTA=NOT_OBSERVED
RUN_03_FRAME_DELTA=NOT_OBSERVED

T1_CLASSIFICATION=INCONCLUSIVE_INFRASTRUCTURE_SSH
FAILURE_ISOLATED_TO_V41=NOT_ASSESSABLE
CHANGED_HARDWARE_OR_ELECTRICAL_MARGIN=NOT_ASSESSABLE
NEXT_RECOMMENDED_ACTION=PROVIDE_APPROVED_NONINTERACTIVE_SSH_AND_SUDO_AUTOMATION_THEN_RERUN_T1

RC_A_PROGRAM_INVOCATIONS=0
RC_A_WARM_REBOOTS=0

FORMAL_RESTORE_PROGRAM_INVOCATIONS=0
FORMAL_RESTORE_EOS=NOT_RUN
FORMAL_RESTORE_DONE=NOT_RUN
FORMAL_RESTORE_WARM_REBOOT=NOT_RUN

FORMAL_PHASE2_ACTIVE_AT_END=AUTHORITATIVE_START_PRESERVED_BY_ZERO_MUTATION_NOT_FRESHLY_VERIFIED
FORMAL_IDENTITY_AT_END=NOT_READ_SSH_GATE_FAILED
DIAGNOSTIC_MAGIC_AT_END=NOT_READ_SSH_GATE_FAILED
FINAL_JTAG_DONE=NOT_RUN_SSH_GATE_HARD_STOP

FORMAL_REPOSITORY_MUTATION=0

AXI_LITE_WRITES=0

C2H_TRANSFERS=0

H2C_TRANSFERS=0

COLD_STARTS=0

PHYSICAL_ACTIONS=0

SOURCE_CHANGES=0

BUILDS=0

PHASE3_RESUMED=NO

PHASE4_STARTED=NO
```

## Hard stop

No T3/T4, recovery ladder, Z8, retry/polling experiment, v40.2 work, Phase 3,
Phase 4, DMA, further RC-A sample, or cold start followed this classification.
