# R7 publication-readiness and accounting supporting audit

```text
TASK=V41_NVP_R1E_MODE_AWARE_BOOTSTRAP_FROM_DONE0_AND_COMPLETE_PAIRED_AB_R7
AUDIT_MODE=LOCAL_READ_ONLY_EVIDENCE_RECONCILIATION
AUDIT_UTC=2026-08-23T23:40:27.7500414Z
HARDWARE_CAMPAIGN_COMPLETENESS=PASS
FINAL_FORMAL_STATE_EVIDENCE=PASS
SCIENTIFIC_ANALYSIS_EVIDENCE=PASS
PUBLICATION_READINESS=NOT_READY_PENDING_FINAL_ASSEMBLY_AND_LEDGER_RECONCILIATION
LIVE_ACTIONS_PERFORMED_BY_THIS_AUDIT=0
```

## Executed-operation accounting

Raw immutable receipts and contextual logs reconcile to:

```text
READ_ONLY_HOST_BASELINE_SSH_SESSIONS=2
READ_ONLY_PRE_BOOTSTRAP_SAFETY_SSH_SESSIONS=1
PHASE_CONTEXTUAL_SSH_SESSIONS=16
TOTAL_CONTEXTUAL_SSH_SESSIONS=19
READ_ONLY_JTAG_RECONFIRMATION_SESSIONS=1
READ_ONLY_JTAG_RECONFIRMATION_SAMPLES=5
PROGRAMMING_JTAG_SESSIONS=3
INDEPENDENT_IMMEDIATE_DONE_JTAG_SESSIONS=3
INDEPENDENT_FINAL_DONE_JTAG_SESSIONS=3
TOTAL_R7_HARDWARE_MANAGER_SESSIONS=10
FORMAL_BOOTSTRAP_PROGRAMS=1
ARM_A_PROGRAMS=1
ARM_B_PROGRAMS=1
FPGA_PROGRAM_INVOCATIONS=3
WARM_REBOOTS=3
POST_REBOOT_DRIVER_LOADS=3
PROGRAM_RETRIES=0
COLD_STARTS_DURING_R7=0
PHYSICAL_ACTIONS_DURING_R7=0
JTAG_FREQUENCY_CHANGES=0
KERNEL_OR_GRUB_CHANGES=0
PCI_REMOVE_RESCAN_RESETS=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
```

There are exactly three program timing receipts, each with one consumed program
marker, process PASS, startup HIGH/DONE=1, and zero retries. There are exactly
three warm-reboot contextual logs and three exact pinned-loader contextual
logs, all `RESULT=PASS` and `EXIT_CODE=0`.

## Two local helper corrections

The following two task-local corrections are both documented, bounded, and
non-scientific:

1. Bootstrap TCP host-cycle helper whitespace correction.

   The single bootstrap reboot had already been submitted. The original local
   read-only TCP observer reached the false/exception branch and then stopped
   because `return$false` lacked whitespace. That branch proves TCP/22 was not
   connected; the later successful pre-loader SSH session, changed boot ID,
   and kernel 29 prove return. No reboot was repeated. Only the three `return`
   expressions in the local TCP helper were corrected.

   ```text
   INITIAL_WAIT_HELPER_SHA256=35E1406DBBA4F943274E1C3FDF657A962F48952CD0E75ED1DEF2222D38FB9D0F
   CORRECTED_WAIT_HELPER_SHA256=097B25287F8BD261C48F9718C75DD7618F5E908293047C8E61B5D9DBA3A64443
   CORRECTION_AUDIT_SHA256=8F40218CBEF970FD08E767D7C02C86D2DDC35F8B573BB81629BE00EDABE2EA06
   POWERSHELL_PARSE_ERRORS_AFTER_FIX=0
   REPEATED_BOOTSTRAP_REBOOT=NO
   LIVE_ACTIONS_CAUSED_BY_FIX=0
   ```

2. Configured-image receipt duplicate-identical BAR parsing correction.

   The first formal-ready receipt construction stopped locally and created no
   receipt because the already-passed post-loader evidence prints each BAR
   value twice: once inside the parser block and once in the summary. The
   helper now accepts repeated values only when the set has exactly one unique
   value; missing or conflicting values still fail. The sealed formal-ready
   receipt was then created from unchanged evidence. No hardware action or
   scientific behavior changed.

   ```text
   INITIAL_RECEIPT_HELPER_SHA256=1896EF7E8F28713BFE8A1A59B2E510F3371E4E665AB6F40104D123449F2372E4
   CORRECTED_RECEIPT_HELPER_SHA256=9FAFEE34C81DE05115E301A485681848F55F496D15A0F1B8A75B51CD0C2BFB9E
   CORRECTION_AUDIT_SHA256=15211B4C9F7BFF7B3C05B42DF1D11F19E37B1DA9946560033DB531C25A7EB24E
   BAR0_MATCHES=2 UNIQUE_VALUES=1 VALUE=131072
   BAR1_MATCHES=2 UNIQUE_VALUES=1 VALUE=65536
   CONFLICTING_REPEATED_VALUES_ACCEPTED=NO
   FIRST_FAILED_CALL_CREATED_RECEIPT=NO
   LIVE_ACTIONS_CAUSED_BY_FIX=0
   ```

Neither correction changes FPGA source, bitstream, DCP, the programmed image,
JTAG selection/frequency, I2C traffic, host kernel/driver, or captured sample.

## Arm-B TCP sampling-window reconciliation

The Arm-B warm reboot was submitted once and passed its contextual command
gate. The bounded TCP observer started after the host had already returned and
recorded 296/296 UP samples over 300.513053200 seconds, so its own no-down gate
is correctly retained as `FAIL`. It performed no state change. The immediately
following accepted pre-loader session proves the boot transition independently:

```text
TCP_OBSERVER_GATE=FAIL_NO_DOWN_SEEN
TCP_OBSERVER_INTERPRETATION=SAMPLING_WINDOW_MISSED_DOWN_INTERVAL
TCP_OBSERVER_SAMPLES=296
TCP_OBSERVER_UP_SAMPLES=296
TCP_OBSERVER_DOWN_SAMPLES=0
TCP_OBSERVER_SPAN_SECONDS=300.513053200
TCP_OBSERVER_STATE_CHANGES=0
WARM_REBOOT_EVIDENCE_SHA256=1F404201DA238E439D6B7EFDBFB0869C7D3EB3B97CB8A8311F101534201C8C29
PREVIOUS_BOOT_ID=c6cf85f0-0a06-4d2f-8656-5bca7cbb19a3
CURRENT_BOOT_ID=e2a2517a-c275-4ea9-bf11-83c0db94111e
BOOT_ID_CHANGED=YES
CURRENT_KERNEL=7.0.0-29-generic
BAR0_BYTES=131072
BAR1_BYTES=65536
PRELOADER_EVIDENCE_SHA256=1E1C02358552EF1607E05D3216DECD9850BE93646705593CFA39148D3B83BE0A
SECOND_ARM_B_REBOOT=NO
REBOOT_TRANSITION_PROOF=PASS_BY_SUCCESSFUL_SUBMISSION_PLUS_CHANGED_BOOT_ID
SAMPLING_AUDIT_SHA256=CE57A7F9B57D423345F41A3455EDD9DE7A7C6558D8F7681249573D584CFD2080
```

The final report must not claim that the Arm-B TCP observer saw DOWN. It may
state that the reboot transition is proven by successful submission plus the
changed boot ID and returned, valid kernel/endpoint/BAR state.

## Scientific and final-state evidence

```text
ARM_A_INSTRUMENTATION_VALID=YES
ARM_A_CNT_AT_INIT_DONE=132688568
ARM_A_SIGNED_COUNT_ERROR_CYCLES=+103834_EXTENSION
ARM_A_NACK_COUNT=13
ARM_A_ORDERED_LOG=8_RECORDS_OVERFLOW_FIRST_8_ONLY
ARM_A_PROBE_COUNT=10000
ARM_A_PROBE_ACK_COUNT=9971
ARM_A_PROBE_NACK_COUNT=29
ARM_A_PROBE_TIMEOUT_COUNT=0
ARM_A_PROBE_NACK_RATE=0.0029
ARM_A_NVP_RESULT=R1E_NVP_FAIL
ARM_B_INSTRUMENTATION_VALID=YES
ARM_B_NACK_COUNT=15
ARM_B_ORDERED_LOG=8_RECORDS_OVERFLOW_FIRST_8_ONLY
ARM_B_R1E_PAGE_ZERO=YES
ARM_B_NVP_RESULT=FORMAL_NVP_FAIL
PAIRED_AB_RESULT=COMPLETE_VALID_PAIRED_SAMPLE
PAIRED_ANALYSIS_JSON_SHA256=A652E813A583CC863B4A0F806ACD1A865226CE2EE2B7CAD8129F9C00830990F1
PAIRED_ANALYSIS_MARKDOWN_SHA256=95D720F4EE9DBF063F7CD6732FCA7B586267F26CF694BFEE18983AE1F9FBF847
```

Final Arm-B evidence proves kernel 29, exact BARs, exact pinned module, 21
nodes, no owners/DMA, formal identity `A40A0C07/0000400B/00031002`, R1e page
zero, two coherent read-only telemetry snapshots, and selected-JTAG DONE=1.

```text
FINAL_ACTIVE_IMAGE=FORMAL_PHASE2
FINAL_PINNED_DRIVER_LOADED=YES
FINAL_DONE=1
FINAL_POSTLOADER_EVIDENCE_SHA256=4EB482D0E1C5090FB31CCCA66BF31066C31B661E94A40F4BBAE323E4510A6B01
FINAL_TELEMETRY_EVIDENCE_SHA256=293816D592DAE922ED6471EA0B3A225D5AF9E004FDB91EADA4A8F4020FC54689
FINAL_DONE_RECEIPT_SHA256=49C73C165E95A75E7DEE54E057C8FA3E17ED79FC1BCE3127AFA381E3B1B92A67
```

## Publication blockers and required reconciliation

The scientific campaign is complete, but publication artifacts were not yet
assembled at this audit boundary. The following are required before claiming
publication PASS:

```text
AUTHORITATIVE_FINAL_REPORT_PRESENT=NO
FINAL_SHA256_MANIFEST_PRESENT=NO
R7_EVIDENCE_ZIP_PRESENT=NO
R7_EVIDENCE_ZIP_SIDECAR_PRESENT=NO
EVIDENCE_REPOSITORY_COMMIT_PROOF_PRESENT=NO
PUBLIC_REMOTE_VERIFICATION_PRESENT=NO
PACKAGE_LEVEL_SECRET_SCAN_PRESENT=NO
```

`TOOL_COMMAND_LEDGER.md` is still the initial zero-action snapshot and
contradicts the executed raw evidence. It must be reconciled to the counts in
this audit before packaging. `OPERATION_LEDGER.md` and `TIME_LEDGER.md` include
the terminal Arm-B telemetry/DONE event and their top-level operation counts
are consistent.

The pre-correction 22-row host-tool manifest and its static audit remain valid
historical pre-execution records, but now show exactly two expected hash/size
mismatches: `Wait-R7HostCycle.ps1` and
`New-R7ConfiguredImageReceipt.ps1`. Preserve those historical files; ensure the
new final SHA-256 manifest records the corrected files and both correction
audits.

```text
TOOL_COMMAND_LEDGER_RECONCILIATION_REQUIRED=YES
PRE_CORRECTION_HOST_TOOL_MANIFEST_MISMATCHES=2_DOCUMENTED_EXPECTED
FINAL_MANIFEST_MUST_USE_CORRECTED_HELPER_HASHES=YES
FINAL_REPORT_MUST_DISCLOSE_ARM_B_TCP_WINDOW=YES
PUBLICATION_CAN_PROCEED_AFTER_LISTED_RECONCILIATION=YES
SCIENTIFIC_RESULT_CHANGED_BY_PUBLICATION_BLOCKERS=NO
```
