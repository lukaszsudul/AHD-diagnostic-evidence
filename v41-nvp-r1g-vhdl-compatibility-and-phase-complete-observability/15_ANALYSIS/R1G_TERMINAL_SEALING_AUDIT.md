# R1g terminal sealing audit

## Scope and disposition

This receipt records a strictly read-only audit of the R1g task evidence after the sole authorized clean build terminated. The only filesystem write made by this audit is this receipt. The audit did not open `C:\FPGA\VCDE-DUT-1.txt`, modify source or Git, invoke Vivado, create or modify a ledger, create a manifest or ZIP, or perform any JTAG, SSH, MMIO, reboot, driver, DMA, or other hardware action.

```text
AUDIT_UTC=2026-08-24T17:33:40.0800886Z
CURRENT_EVIDENCE_AUDIT=PASS
ACCOUNTING_CONTRADICTIONS_FOUND=0
UNEXPECTED_HARDWARE_ACTION_EVIDENCE_FOUND=0
SECRET_OR_CREDENTIAL_MATERIAL_FOUND=0
CURRENT_PATH_SAFETY_ISSUES_FOUND=0
FINAL_REPORT_PRESENT_AT_AUDIT=NO
FINAL_EVIDENCE_ZIP_PRESENT_AT_AUDIT=NO
FINAL_PACKAGE_ENTRY_AUDIT=PENDING_FOLLOW_UP_AFTER_PACKAGE_CREATION
```

The task is correctly terminal because of the consumed-build failure described below. `CURRENT_EVIDENCE_AUDIT=PASS` means that the evidence and accounting accurately preserve that failure; it does not convert the failed build into a build PASS or authorize hardware.

## Owner prompt identity

The saved owner prompt existed before the recorded source rewrite and live toolchain actions. Its current SHA-256 exactly matches the operation-ledger identity.

```text
OWNER_PROMPT_PATH=00_R1F_INPUT/R1G_OWNER_PROMPT.md
OWNER_PROMPT_BYTES=45799
OWNER_PROMPT_SHA256=CE2F6A181E5850A3E6137569108E118847A504BEC5130B43FDD97A06FC10D618
OPERATION_LEDGER_OWNER_PROMPT_SHA256=CE2F6A181E5850A3E6137569108E118847A504BEC5130B43FDD97A06FC10D618
OWNER_PROMPT_HASH_GATE=PASS
```

## Sole source commit and clean worktree

Independent Git queries against `C:\FPGA\WORKTREES\V41_NVP_R1G_VHDL_COMPATIBILITY` proved the required direct-child topology, one commit above R1f, one changed VHDL file, and a clean worktree.

```text
R1G_SOURCE_COMMITS=1
R1G_SOURCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_SOURCE_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1G_PARENT_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1G_COMMITS_ABOVE_R1F=1
R1G_CHANGED_FILES=rtl/nvp/nvp6134c_i2c_bringup.vhd
SOURCE_WORKTREE_CLEAN=YES
SOURCE_COMMIT_ACCOUNTING_GATE=PASS
```

## Sole final frontend preflight

Exactly one final-preflight consumed marker is present. Its bound result reports the exact R1g commit/tree, top, part, ordinary non-2008 production language mode, and exit code zero. Direct command-record counting in the preserved console log found one RTL-only `synth_design` command and no implementation, checkpoint, or bitstream command.

```text
FINAL_RTL_ELABORATION_PREFLIGHTS=1
FINAL_RTL_ELABORATION=PASS
PREFLIGHT_RESULT_SHA256=CB8A6C9DE7CC8841038EFE73109B08BBC00057C9C8D0ECA7FA444B9504F61DED
PREFLIGHT_CONSOLE_SHA256=AF9B671DC95F17C4DBA303B72F2DBD5E9154A5CAE1C74ECA46B8EE9F5DAA90C9
PREFLIGHT_SYNTH_DESIGN_INVOCATIONS=1
PREFLIGHT_OPT_DESIGN_INVOCATIONS=0
PREFLIGHT_PLACE_DESIGN_INVOCATIONS=0
PREFLIGHT_PHYS_OPT_DESIGN_INVOCATIONS=0
PREFLIGHT_ROUTE_DESIGN_INVOCATIONS=0
PREFLIGHT_WRITE_CHECKPOINT_INVOCATIONS=0
PREFLIGHT_WRITE_BITSTREAM_INVOCATIONS=0
SYNTH_8_2757_COUNT=0
UNSUPPORTED_LANGUAGE_CONSTRUCT_ERRORS=0
FINAL_PREFLIGHT_ACCOUNTING_GATE=PASS
```

## Sole clean build and exact terminal failure

Exactly one full-build consumed marker, one build log, and one build journal are present. The marker binds the exact R1g commit/tree and prebuild manifest. Direct `Command:` record counting in the terminal build log found one synthesis, one optimization, and one placement invocation, with no physical optimization, routing, checkpoint, or bitstream invocation. The placement command stopped at its DRC precondition; Vivado explicitly states that the placer did not run.

```text
FULL_CLEAN_BUILDS=1
BUILD_RETRIES=0
BUILD_SENTINEL_SHA256=F945D9B15A6B72710EC2B0A0A3942C3B345D8AF66152D129FE853980F1C7E0CA
PREBUILD_MANIFEST_SHA256=F31220B039E26C29C994A6F9B60A5416DE6EE0231C9C9E78CE81E013ECA473B9
BUILD_LOG_SHA256=9156A7DA638ADAE8D015F4BADFBF0A4A86D6BBFC3718F92FD7C5AF8BF7C4B42E
BUILD_JOURNAL_SHA256=58E928274C8EB1B05093E3947DD3691E897A660F147A0B6AA742B0D00A505076
TERMINAL_FAILURE_RECEIPT_SHA256=446B6468DAE7EB456D0477A21DF465925CB963714C285E664F8A43A3188728A7
SYNTH_DCP_SHA256=DB9FE5C96D3AA42EE43AAB6396E2FBEB1E75335463DFEC4B259EA242C320B34B
BUILD_SYNTH_DESIGN_INVOCATIONS=1
BUILD_OPT_DESIGN_INVOCATIONS=1
BUILD_PLACE_DESIGN_INVOCATIONS=1
BUILD_PHYS_OPT_DESIGN_INVOCATIONS=0
BUILD_ROUTE_DESIGN_INVOCATIONS=0
BUILD_WRITE_CHECKPOINT_INVOCATIONS=0
BUILD_WRITE_BITSTREAM_INVOCATIONS=0
FULL_SYNTHESIS=PASS
SYNTHESIS_ERRORS=0
SYNTHESIS_CRITICAL_WARNINGS=0
PLACE_DESIGN=FAIL_DRC_PRECONDITION_PLACER_NOT_RUN
PLACE=NOT_RUN
ROUTE=NOT_RUN
R1G_ROUTED_DCP_PRESENT=NO
R1G_BITSTREAM_PRESENT=NO
BITSTREAMS_GENERATED=0
```

The log contains exactly three `DRC UTLZ-1` resource-overutilization errors at the placement precondition:

| Resource | Required | Available | Excess |
|---|---:|---:|---:|
| LUT as Logic | 30,926 | 20,800 | 10,126 |
| Register as Flip Flop | 44,248 | 41,600 | 2,648 |
| Slice Registers | 44,248 | 41,600 | 2,648 |

The preserved terminal error is exact:

```text
TERMINAL_ERROR=ERROR: [Common 17-39] 'place_design' failed due to earlier errors.
R1G_TERMINAL_CLASSIFICATION=BLOCKED_ONE_CLEAN_BUILD_PLACE_PRECONDITION_RESOURCE_OVERUTILIZATION
SOURCE_OR_LANGUAGE_BLOCKER=NO
SCIENTIFIC_HARDWARE_RESULT=NOT_RUN
HARDWARE_AUTHORIZED_AFTER_BUILD=NO
SECOND_BUILD_AUTHORIZED=NO
```

## Accounting and hardware-action audit

The operation and time ledgers agree with the preserved command logs and directory state. The one implementation-run count correctly begins at `opt_design`; it does not claim that placement ran. The hardware phase directories are empty, the active post-build hardware binding is absent, and no program, configured-image, reboot, driver-load, telemetry, or formal-ready runtime receipt exists.

```text
SYNTHESIS_RUNS=1
IMPLEMENTATION_RUNS=1
FPGA_PROGRAMS=0
CONDITIONAL_FORMAL_BOOTSTRAP_PROGRAMS=0
ARM_A_PROGRAMS=0
ARM_B_PROGRAMS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
COLD_STARTS=0
PHYSICAL_ACTIONS=0
JTAG_FREQUENCY_CHANGES=0
PCI_REMOVE_RESCAN_RESETS=0
AXI_LITE_WRITES=0
DMA_TRANSFERS=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHASE3_RESUMED=NO
XDMA_DEVELOPMENT_CONTINUED=NO
FORMAL_REPOSITORY_MUTATIONS=0
OWNER_INTERACTIVE_APPROVAL_REQUESTS=0
BOOTSTRAP_EVIDENCE_FILE_COUNT=0
PAIR_1_EVIDENCE_FILE_COUNT=0
PAIR_2_EVIDENCE_FILE_COUNT=0
PAIR_3_EVIDENCE_FILE_COUNT=0
ACTIVE_HARDWARE_BINDING_PRESENT=NO
HARDWARE_ACCOUNTING_GATE=PASS_ZERO_ACTIONS
```

## Secret and credential scan

The scan covered the 1,116 pre-audit files then present under the task root (584,772,731 bytes) using filename review and content-pattern searches across text/source/log formats. It did not traverse or read the external credential file. No private-key header, known cloud/GitHub/Slack/OpenAI token form, credential-bearing URL, literal PuTTY `-pw` value, or password assignment was found. The only `VCDE-DUT-1.txt` reference is the path specified in the saved owner prompt; no credential file or credential content is present under the task root.

```text
EXTERNAL_CREDENTIAL_FILE_OPENED=NO
PRIVATE_KEY_HEADERS_FOUND=0
KNOWN_TOKEN_FORMS_FOUND=0
CREDENTIALIZED_URLS_FOUND=0
LITERAL_PUTTY_PW_VALUES_FOUND=0
PASSWORD_ASSIGNMENT_CANDIDATES_FOUND=0
CREDENTIAL_FILE_COPIES_FOUND=0
CREDENTIAL_PATH_REFERENCE_FILES=00_R1F_INPUT/R1G_OWNER_PROMPT.md
SECRET_SCAN_GATE=PASS
```

## Current package-path safety

No ZIP or final task manifest existed at this audit point, so no claim is made about final archive entries. The current evidence tree has no filesystem reparse points, no non-default NTFS alternate data streams, no relative path that escapes the task root, and no relative path containing a drive-designating colon. The longest pre-audit relative path is 197 characters (236 characters absolute), which remains below the conventional Windows 260-character absolute-path boundary in the current location.

```text
REPARSE_POINTS=0
NONDEFAULT_ALTERNATE_DATA_STREAMS=0
RELATIVE_PATH_ESCAPES=0
RELATIVE_PATHS_WITH_COLON=0
MAX_RELATIVE_PATH_LENGTH_PRE_AUDIT=197
MAX_ABSOLUTE_PATH_LENGTH_PRE_AUDIT=236
CURRENT_PATH_SAFETY_GATE=PASS
FINAL_ZIP_PATH_TRAVERSAL_GATE=PENDING_PACKAGE_CREATION
FINAL_ZIP_SECRET_SCAN_GATE=PENDING_PACKAGE_CREATION
FINAL_ZIP_MANIFEST_COVERAGE_GATE=PENDING_PACKAGE_CREATION
```

## Audit conclusion

The evidence available before final reporting and packaging is internally consistent and safe to proceed to terminal report generation and evidence sealing. The authoritative outcome must remain the single-build place-precondition resource-overutilization blocker, with zero hardware actions and no R1g scientific sample. A follow-up audit must inspect the final report, manifest, ZIP entry names/content, package hash sidecar, and publication material before public release is claimed.

```text
PRESEAL_RELEASE=PASS_FOR_TERMINAL_REPORT_AND_PACKAGE_CREATION
BUILD_RESULT=FAILED_TERMINAL_NO_RETRY
HARDWARE_RESULT=NOT_RUN
NEXT_AUDIT=FINAL_REPORT_MANIFEST_ZIP_AND_PUBLICATION_RECEIPT
```
