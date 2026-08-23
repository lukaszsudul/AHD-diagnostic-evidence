# V41 NVP R1e extended-observability final report

## Outcome

The R1e scientific hardware campaign remains unexecuted. The R2 continuation
correctly resolved both earlier namespace and report-property problems, opened
the exact routed checkpoint, recorded the checkpoint object and HDL top in
their separate namespaces, found both expected IOBUFs, emitted both property
reports, and completed the full report-only tail.

The sole read-only preflight then exited 1 in its final aggregate parser. The
generated DRC report semantically contains four `REQP-1839` violations, equal
to the accepted baseline. The helper counted five literal appearances because
the summary row contains the rule label in addition to four detailed records.
This is a task-local report-parser defect and not a routed-design, DRC, or NVP
scientific result.

Because R2 authorizes only one read-only preflight and requires process exit 0
before the write session, no correction/rerun was permitted. No bitstream was
written and Arm A/Arm B were not entered.

## Methods and immutable implementation history

The implementation reached a fully routed DCP. The original build-tail
execution stopped on report-property cardinality; the first continuation
stopped on a namespace-invalid design-name assertion; R2 reused the exact same
DCP and corrected only task-local harness logic. All three boundaries occurred
after implementation and did not modify source, the routed DCP, or hardware.

The exact R1e source is commit
`f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`, tree
`db8b5581a237e19905fd01c6d453793047bc3ba7`. Protected NVP blobs remain
unchanged. Pre-`init_done` equivalence passed for 1,814,611 cycles; the ordered
legacy NACK-window audit and 10,000-probe simulation passed.

The reused routed DCP SHA-256 is
`1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1`.
R2 revalidated 26,488 fully routed nets out of 26,488 routable nets, zero route
errors, WNS +0.617 ns, WHS +0.021 ns, zero DRC errors, zero DRC critical
warnings, and four semantic `REQP-1839` warnings.

## Scientific status and limitations

No lifecycle, ordered-NACK, address-probe, or paired functional sample was
collected. Consequently no inference is made about control-flow shortening,
post-autoinit write-address ACK reliability, operation/phase concentration, or
the Arm A/Arm B comparison.

The intended ordered log remains capacity eight; overflow would expose only
the first eight records. The intended probe is active but non-register-writing
and measures only post-autoinit write-address ACK behavior. It would not measure
register/data/read-address reliability or analog voltage/rise time. Added logic
may alter implementation placement even when dormant.

```text
TASK=
    V41_NVP_R1E_NAMESPACE_CORRECT_POST_ROUTE_CONTINUATION_AND_PAIRED_AB_R2

PRIOR_CONTINUATION_EVIDENCE_COMMIT=
    6f3241601d83862802e11a2049668c8430cd29d7

PRIOR_CONTINUATION_EVIDENCE_PACKAGE_SHA256=
    B2C20EBD965FF2DEEF95B203607C46A7060D3DAAEB7ECD2A97100017679BC2C4

PRIOR_CONTINUATION_BLOCKER=
    BLOCKED_SINGLE_POST_ROUTE_CONTINUATION_TOP_IDENTITY_HARNESS_MISMATCH

FINAL_REPORT_COUNT=
    1

SOURCE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

SOURCE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

TRACKED_SOURCE_FILES_CHANGED=
    18

PROTECTED_NVP_BLOBS_UNCHANGED=
    YES

PRE_INIT_DONE_EQUIVALENCE=
    PASS

PRE_INIT_DONE_EQUIVALENCE_CYCLES=
    1814611

ORDERED_NACK_LEGACY_WINDOW_AUDIT=
    PASS

PROBE_TARGET_COUNT=
    10000

PROBE_SIMULATION=
    PASS

PRIOR_SYNTHESIS=
    PASS

PRIOR_PLACE=
    PASS

PRIOR_ROUTE=
    PASS

PRIOR_ROUTE_ERRORS=
    0

PRIOR_WNS_NS=
    +0.617

PRIOR_WHS_NS=
    +0.021

PRIOR_DRC_ERRORS=
    0

PRIOR_DRC_CRITICAL_WARNINGS=
    0

PRIOR_REQP_1839_COUNT=
    4

PRIOR_ROUTED_DCP_SHA256=
    1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1

CHECKPOINT_CURRENT_DESIGN_NAME=
    checkpoint_PHASE3_routed
RTL_TOP_FROM_BUILD_MANIFEST=
    ahd_capture_top_xdma
DESIGN_NAME_EQUALITY_REQUIRED=
    NO
DESIGN_IDENTITY_PRIMARY_GATE=
    EXACT_DCP_SHA256_PLUS_SOURCE_BUILD_MANIFEST
DESIGN_IDENTITY_GATE=
    PASS_NAMESPACE_CORRECT

CURRENT_DESIGN_TO_RTL_TOP_EQUALITY_COMPARISON_COUNT=
    0

REPORT_PROPERTY_ROOT_CAUSE=
    MULTI_OBJECT_LIST_PASSED_TO_SINGLE_OBJECT_COMMAND

REPORT_PROPERTY_MATCH_COUNT=
    2

REPORT_PROPERTY_FIX=
    DETERMINISTIC_PER_OBJECT_REPORTING

R2_PREFLIGHT_SEMANTIC_REQP_1839_COUNT=
    4
R2_PREFLIGHT_RAW_REQP_1839_TEXT_OCCURRENCES=
    5
R2_PREFLIGHT_PROCESS_EXIT_CODE=
    1
R2_HARD_STOP_CLASSIFICATION=
    BLOCKED_R2_READ_ONLY_PREFLIGHT_REQP_1839_TEXT_OCCURRENCE_PARSER

SOURCE_CHANGES_THIS_TASK=
    0

FULL_BUILDS_THIS_TASK=
    0

SYNTHESIS_RUNS_THIS_TASK=
    0

PLACE_RUNS_THIS_TASK=
    0

ROUTE_RUNS_THIS_TASK=
    0

READ_ONLY_DCP_PREFLIGHT_SESSIONS=
    1

WRITE_CAPABLE_CONTINUATION_SESSIONS=
    0

WRITE_BITSTREAM_ATTEMPTS=
    0

R1E_BIT_SHA256=
    NOT_AVAILABLE
R1E_BIT_SOURCE_COMMIT=
    NOT_APPLICABLE_NO_BIT
R1E_BIT_SOURCE_TREE=
    NOT_APPLICABLE_NO_BIT

ARM_A_REQUIRED_WAIT_SECONDS=
    10.000000_FROZEN_NOT_USED
ARM_A_PROGRAM=
    NOT_EXECUTED_HARD_STOP_BEFORE_BITSTREAM
ARM_A_KERNEL=
    NOT_READ
ARM_A_DRIVER=
    NOT_LOADED
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
ARM_A_PROBE_WILSON95=
    NOT_COMPUTABLE
ARM_A_NVP_RESULT=
    NOT_RUN
ARM_A_FINAL_DONE=
    NOT_READ

ARM_B_PROGRAM=
    NOT_EXECUTED
ARM_B_KERNEL=
    NOT_READ
ARM_B_DRIVER=
    NOT_LOADED
ARM_B_FORMAL_IDENTITY=
    NOT_FRESHLY_READ_THIS_TASK
ARM_B_DIAGNOSTIC_MAGIC=
    NOT_FRESHLY_READ_THIS_TASK
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
    NOT_READ

PAIRED_AB_RESULT=
    INCONCLUSIVE_NO_HARDWARE_CAMPAIGN
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=
    NOT_EVALUATED
STOCHASTIC_ADDRESS_OR_BUS_MARGIN=
    NOT_EVALUATED
AUTOINIT_OPERATION_OR_PHASE_CONTEXT=
    NOT_EVALUATED
ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO
GROUND_BOUNCE_PROVEN=
    NO
ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_PINNED_DRIVER_LOADED=
    PRIOR_STATE_UNCHANGED_NOT_RELOADED_THIS_TASK
FINAL_DONE=
    NOT_FRESHLY_READ_AFTER_PREFLIGHT_HARD_STOP

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
    SEE_V41_NVP_R1E_POST_ROUTE_CONTINUATION_R2_EVIDENCE_SHA256.txt
EVIDENCE_REPOSITORY_COMMIT=
    SELF_REFERENTIAL_FIELD_SEE_GIT_COMMIT_CONTAINING_THIS_REPORT
PUBLIC_REMOTE_VERIFICATION=
    SEE_PUBLICATION_RECEIPT.txt
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_R2_PREFLIGHT_HARD_STOP
```
