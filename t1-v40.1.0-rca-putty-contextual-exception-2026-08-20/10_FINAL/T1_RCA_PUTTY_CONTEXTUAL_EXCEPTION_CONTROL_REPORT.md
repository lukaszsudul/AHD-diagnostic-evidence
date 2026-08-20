# PuTTY contextual-exception RC-A current-hardware control

## Outcome

The owner-authorized username/password literal collision was handled by
structural argument and report auditing. The exact sealed RC-A passed three of
three valid current warm-state samples. Every sample had zero NACKs/timeouts,
no first error, positive VCLK/SAV/frame deltas, a healthy endpoint/kernel gate,
and final DONE=1.

The exact formal Phase-2 image was then restored once and fully proven at
runtime and over fresh JTAG. The formal repository remained unchanged.

The result strongly supports, but does not solely prove, isolation of the
reproduced failure to the v41/reset-autoinit domain. A changed hardware or
electrical state as a global explanation is weakened, not eliminated.

## Required final block

    TASK=
        PUTTY_CONTEXTUAL_SECRET_EXCEPTION_AND_T1_RCA_3RUN_CONTROL

    OWNER_CONTEXTUAL_EXCEPTION=
        YES

    USERNAME_EQUALS_PASSWORD=
        YES

    PLINK_VERSION=
        0.84

    PLINK_SHA256=
        E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915

    PLINK_PW_OPTION_USED=
        NO

    PLINK_PWFILE_OPTION_USED=
        YES

    PASSWORD_IN_PROCESS_ARGUMENT_PASSWORD_ROLE=
        NO

    PASSWORD_IN_PROCESS_ARGUMENT_USERNAME_ROLE=
        YES_AUTHORIZED

    STRUCTURAL_SECRET_HANDLING_GATE=
        PASS

    PASSWORD_AUTH_SESSION_1=
        PASS
    PASSWORD_AUTH_SESSION_2=
        PASS
    PASSWORD_AUTH_SESSION_3=
        PASS
    PASSWORD_AUTH_3_OF_3=
        PASS

    HOST_KEY_FINGERPRINT_MATCH=
        PASS
    SUDO_AUTH_TRUE=
        PASS
    SUDO_REBOOT_PERMISSION=
        PASS
    SSH_PREFLIGHT_CLASSIFICATION=
        SSH_PREFLIGHT_PASS_READY_FOR_T1

    RC_A_BIT_SHA256=
        A43B9280FACFF259F126B0E4FDD56E39C3D136321696EBFC98B79184A747B3B6

    T1_VALID_RUNS=
        3
    T1_PASS_COUNT=
        3
    T1_FAIL_COUNT=
        0
    T1_INVALID_COUNT=
        0

    RUN_01_RESULT=
        PASS
    RUN_01_NACK_COUNT=
        0
    RUN_01_FIRST_ERROR=
        NONE
    RUN_01_VCLK_DELTA=
        148557621
    RUN_01_SAV_DELTA=
        28136
    RUN_01_FRAME_DELTA=
        25

    RUN_02_RESULT=
        PASS
    RUN_02_NACK_COUNT=
        0
    RUN_02_FIRST_ERROR=
        NONE
    RUN_02_VCLK_DELTA=
        148555139
    RUN_02_SAV_DELTA=
        28136
    RUN_02_FRAME_DELTA=
        25

    RUN_03_RESULT=
        PASS
    RUN_03_NACK_COUNT=
        0
    RUN_03_FIRST_ERROR=
        NONE
    RUN_03_VCLK_DELTA=
        148520870
    RUN_03_SAV_DELTA=
        28129
    RUN_03_FRAME_DELTA=
        25

    T1_CLASSIFICATION=
        RCA_CURRENT_HARDWARE_PASS_3_OF_3
    FAILURE_ISOLATED_TO_V41=
        STRONGLY_SUPPORTED_NOT_SOLELY_PROVEN
    CHANGED_HARDWARE_OR_ELECTRICAL_MARGIN=
        WEAKENED_AS_GLOBAL_EXPLANATION_NOT_ELIMINATED
    NEXT_RECOMMENDED_ACTION=
        OFFLINE_T4_V40_1_VERSUS_V41_RESET_AUTOINIT_DOMAIN_AUDIT

    RC_A_PROGRAM_INVOCATIONS=
        3
    RC_A_WARM_REBOOTS=
        3

    FORMAL_RESTORE_PROGRAM_INVOCATIONS=
        1
    FORMAL_RESTORE_EOS=
        HIGH
    FORMAL_RESTORE_DONE=
        1
    FORMAL_RESTORE_WARM_REBOOT=
        1

    FORMAL_PHASE2_ACTIVE_AT_END=
        YES
    FORMAL_IDENTITY_AT_END=
        PASS_A40A0C07_0000400B_00031002
    DIAGNOSTIC_MAGIC_AT_END=
        0x00000000
    FINAL_JTAG_DONE=
        1

    TEMP_PASSWORD_FILES_REMAINING=
        0

    ORIGINAL_CREDENTIAL_FILE_MODIFIED=
        NO

    FORMAL_REPOSITORY_MUTATION=
        0

    AXI_LITE_WRITES=
        0

    C2H_TRANSFERS=
        0

    H2C_TRANSFERS=
        0

    COLD_STARTS=
        0

    PHYSICAL_ACTIONS=
        0

    SOURCE_CHANGES=
        0

    BUILDS=
        0

    PHASE3_RESUMED=
        NO

    PHASE4_STARTED=
        NO

## Hard stop

No T4/T3, recovery or frequency ladder, Z8, retry/polling or v40.2 patch,
Phase 3/4, DMA, further RC-A run, or cold start followed this result.
