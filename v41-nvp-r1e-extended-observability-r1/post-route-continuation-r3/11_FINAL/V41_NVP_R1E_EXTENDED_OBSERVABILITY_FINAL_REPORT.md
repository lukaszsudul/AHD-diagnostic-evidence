# V41 NVP R1e extended observability — R3 final report

## Outcome

R3 corrected only the task-local REQP-1839 acceptance harness and successfully produced the sole R1e bitstream from the exact already-routed DCP. The required fresh hardware start-state gate then failed before Arm A: JTAG transport, FPGA identity, DONE, kernel, endpoint, link, BAR geometry, and zero-node-owner checks passed, but the retained formal boot continuity was broken and the accepted AXI-Lite reader returned 0xFFFFFFFF instead of formal BLOCK_ID=0xA40A0C07.

The controlling no-bootstrap rule therefore required BLOCKED_REQUIRED_FORMAL_START_STATE. No R1e program, formal program, warm reboot, driver load, AXI-Lite write, or DMA transfer occurred. No lifecycle, ordered-NACK, address-probe, Arm-A, or Arm-B scientific sample was collected, and no scientific R1e classification is made.

## Frozen implementation and R2 history

The source remained commit f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd, tree db8b5581a237e19905fd01c6d453793047bc3ba7. The reused routed DCP remained SHA-256 1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1. R2 had already proven namespace-correct design handling and deterministic two-object reporting, then stopped because its aggregate parser gated on five literal text occurrences rather than four semantic violations. R3 preserves R2 unchanged.

## Semantic DRC correction

Installed Vivado 2025.2 help was captured for get_drc_checks, get_drc_violations, report_drc, report_property, and list_property. R3 obtains one REQP-1839 check object, runs a named report for that check, queries violation objects from that named result, deduplicates exact violation object names, and reports every object individually. Fixtures A through F passed. Replaying R2 produced semantic count 4 and raw count 5.

The sole R3 read-only DCP preflight passed with 26,488/26,488 routed nets, WNS +0.617 ns, WHS +0.021 ns, zero route errors, zero DRC errors, zero DRC critical warnings, two deterministic IOBUF property reports, and four semantic REQP-1839 violation objects. Its targeted report contained seven raw text occurrences; that value was recorded and was not used as a gate.

## Bitstream continuation

The write-session static audit found one lexical write_bitstream, zero implementation commands, zero write_checkpoint, and zero set_property commands, matching the original R1e tail's empty BITSTREAM-property assignment set. The sole write-capable continuation passed and produced ahd_capture_v41_i2c_25khz_r1e_observability.bit.

- Size: 2,192,144 bytes
- SHA-256: 0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9
- Source commit/tree: exact frozen R1e identities
- Routed DCP: exact frozen SHA-256

No rebuild or FPGA source change occurred.

## Host tools and hardware precheck

The exact R1e reader and tests were reused byte-for-byte. Remote no-MMIO fixtures passed lifecycle-page decoding, coherent 48-bit reads, expected count 132584734, probe status/count invariants, the 17-word ordered-log window, overflow handling, Wilson intervals, and the zero-NACK bound.

Fresh JTAG found exactly one HS2 210241768436, one xc7a35t, IDCODE 0362D093, and DONE=1. The DUT ran kernel 7.0.0-29-generic; one 10ee:7011 / subsystem 10ee:0007 / class 058000 endpoint was Gen1 x1; the corrected Python BAR parser returned 131,072 and 65,536 bytes; the expected 21 XDMA nodes existed; and no process owned an XDMA node. The only targeted kernel match was the already-known unsigned-module taint message, not a fatal/non-fatal AER or XDMA functional error.

However, the current boot ID a2b8dff1-e296-4b32-a230-fe6d8a2caa49 did not match retained exact-formal closure boot 7f8db2e5-12aa-4421-b44a-28e72fff483f. A raw task reader saw all ones, and the exact accepted xdma_axil_read independently observed 0xFFFFFFFF at offset 0x00000000, failing the expected 0xA40A0C07 identity before any program. JTAG DONE alone cannot identify the application image. The exact formal start state was therefore not proven.

## Scientific status and limitations

PAIRED_AB_RESULT=NOT_EVALUATED_NO_HARDWARE_CAMPAIGN

No statement can be made from R3 about lifecycle shortening, ordered autoinit NACK distribution, post-autoinit write-address ACK reliability, stochastic address/bus margin, or operation/phase context. The R1e probe remains an active, non-register-writing post-autoinit diagnostic, but it was never executed in hardware during R3.

ROOT_CAUSE_SOLELY_PROVEN=NO

BOARD_VCCO_DROOP_PROVEN=NO

GROUND_BOUNCE_PROVEN=NO

ANALOG_MARGIN_DIRECTLY_MEASURED=NO

## Required final block

    TASK=
        V41_NVP_R1E_SEMANTIC_DRC_POST_ROUTE_CONTINUATION_AND_PAIRED_AB_R3

    FINAL_REPORT_COUNT=
        1

    R2_TASK=
        V41_NVP_R1E_NAMESPACE_CORRECT_POST_ROUTE_CONTINUATION_AND_PAIRED_AB_R2

    R2_REPORT_SHA256=
        AB3C55E22E662E8BDF498EB2317F37A06A6D3DAE0E9CC6A5B356C939FDFDA4BD
    R2_EVIDENCE_COMMIT=
        5452b3790122742acc8df7767c3a424bc7f56fb2

    R2_HARD_STOP_CLASSIFICATION=
        BLOCKED_R2_READ_ONLY_PREFLIGHT_REQP_1839_TEXT_OCCURRENCE_PARSER

    SOURCE_COMMIT=
        f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

    SOURCE_TREE=
        db8b5581a237e19905fd01c6d453793047bc3ba7

    ROUTED_DCP_SHA256=
        1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

    CURRENT_DESIGN_NAME=
        checkpoint_PHASE3_routed

    RTL_TOP_FROM_BUILD_MANIFEST=
        ahd_capture_top_xdma

    DESIGN_IDENTITY_GATE=
        PASS_NAMESPACE_CORRECT

    REPORT_PROPERTY_MATCH_COUNT=
        2

    REPORT_PROPERTY_FIX=
        PASS_DETERMINISTIC_PER_OBJECT

    R2_RAW_REQP_1839_TEXT_OCCURRENCES=
        5

    R3_RAW_TEXT_OCCURRENCES_USED_AS_GATE=
        NO

    R3_REQP_1839_CHECK_OBJECT_COUNT=
        1

    R3_REQP_1839_SEMANTIC_VIOLATION_COUNT=
        4

    R3_REQP_1839_ACCEPTED_BASELINE=
        4

    R3_REQP_1839_GATE=
        PASS

    READ_ONLY_DCP_PREFLIGHT_SESSIONS=
        1

    READ_ONLY_PREFLIGHT_PROCESS_EXIT_CODE=
        0

    WRITE_CAPABLE_CONTINUATION_SESSIONS=
        1

    WRITE_BITSTREAM_ATTEMPTS=
        1

    FULL_BUILDS_THIS_TASK=
        0

    SYNTHESIS_RUNS_THIS_TASK=
        0

    PLACE_RUNS_THIS_TASK=
        0

    ROUTE_RUNS_THIS_TASK=
        0

    SOURCE_CHANGES_THIS_TASK=
        0

    R1E_BIT_SHA256=
        0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9
    R1E_BIT_SOURCE_COMMIT=
        f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
    R1E_BIT_SOURCE_TREE=
        db8b5581a237e19905fd01c6d453793047bc3ba7
    R1E_BIT_ROUTED_DCP_SHA256=
        1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

    ARM_A_REQUIRED_WAIT_SECONDS=
        10.000000

    ARM_A_PROGRAM=
        NOT_RUN_BLOCKED_REQUIRED_FORMAL_START_STATE
    ARM_A_KERNEL=
        NOT_RUN
    ARM_A_DRIVER=
        NOT_RUN
    ARM_A_RUNTIME_PROVENANCE=
        NOT_READ
    ARM_A_CNT_AT_INIT_DONE=
        NOT_MEASURED
    ARM_A_SIGNED_COUNT_ERROR_CYCLES=
        NOT_MEASURED
    ARM_A_SHORTENING_CYCLES=
        NOT_MEASURED
    ARM_A_SHORTENING_TICKS=
        NOT_MEASURED
    ARM_A_SHORTENING_RESIDUAL_CYCLES=
        NOT_MEASURED
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
        NOT_MEASURED
    ARM_A_PROBE_WILSON95=
        NOT_MEASURED
    ARM_A_NVP_RESULT=
        NOT_EVALUATED
    ARM_A_FINAL_DONE=
        NOT_READ_ARM_A_NOT_PROGRAMMED

    ARM_B_PROGRAM=
        NOT_RUN_ARM_A_NEVER_ENTERED
    ARM_B_KERNEL=
        NOT_RUN
    ARM_B_DRIVER=
        NOT_RUN
    ARM_B_FORMAL_IDENTITY=
        NOT_PROVEN_AT_START_ACCEPTED_READER_RETURNED_FFFFFFFF
    ARM_B_DIAGNOSTIC_MAGIC=
        NOT_READ_AFTER_BLOCK_ID_FAILURE
    ARM_B_R1E_PAGE_ZERO=
        NOT_VALIDATED_CURRENT_MMIO_RETURNED_FFFFFFFF
    ARM_B_NACK_COUNT=
        NOT_MEASURED
    ARM_B_NACK_LOG_COUNT=
        NOT_MEASURED
    ARM_B_NACK_LOG_OVERFLOW=
        NOT_MEASURED
    ARM_B_ORDERED_NACK_RECORDS=
        NOT_MEASURED
    ARM_B_NVP_RESULT=
        NOT_EVALUATED
    ARM_B_FINAL_DONE=
        NOT_RUN

    PAIRED_AB_RESULT=
        NOT_EVALUATED_NO_HARDWARE_CAMPAIGN
    CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=
        NOT_EVALUATED
    STOCHASTIC_ADDRESS_OR_BUS_MARGIN=
        NOT_EVALUATED
    AUTOINIT_OPERATION_OR_PHASE_CONTEXT=
        NOT_EVALUATED
    POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=
        NOT_EVALUATED

    ROOT_CAUSE_SOLELY_PROVEN=
        NO

    FINAL_ACTIVE_IMAGE=
        UNPROVEN_CURRENT_SRAM_IMAGE_NOT_MUTATED_BY_R3

    FINAL_PINNED_DRIVER_LOADED=
        NOT_PROVEN_CURRENT_BOOT
    FINAL_DONE=
        1

    FPGA_PROGRAM_INVOCATIONS=
        0

    WARM_REBOOTS=
        0

    POST_REBOOT_DRIVER_LOADS=
        0

    PROGRAM_RETRIES=
        0

    COLD_STARTS=
        0

    PHYSICAL_ACTIONS_DURING_TASK=
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
        RECORDED_IN_V41_NVP_R1E_SEMANTIC_DRC_CONTINUATION_R3_EVIDENCE_SHA256.txt
    EVIDENCE_REPOSITORY_COMMIT=
        RECORDED_OUT_OF_BAND_AFTER_THE_SINGLE_EVIDENCE_COMMIT
    PUBLIC_REMOTE_VERIFICATION=
        RECORDED_OUT_OF_BAND_AFTER_PUSH
    NEXT_ACTION=
        OWNER_AND_AUDITOR_REVIEW_OF_BLOCKED_REQUIRED_FORMAL_START_STATE_AND_COMPLETED_R1E_BITSTREAM
