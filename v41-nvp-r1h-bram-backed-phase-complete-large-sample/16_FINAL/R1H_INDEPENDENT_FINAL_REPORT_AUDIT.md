# R1h independent authoritative-final-report audit

Audit result: `PASS_NO_BLOCKER`

This audit is read-only with respect to the R1h source tree and the
authoritative report. The only created artifact is this task-local audit
report. No Vivado session, build, synthesis, implementation, checkpoint,
bitstream, hardware, host, MMIO, DMA, Git commit, or push was performed.

## Audited identities

FACT:

```text
TASK=V41_NVP_R1H_BRAM_BACKED_PHASE_COMPLETE_OBSERVABILITY_AND_LARGE_SAMPLE_AB
OWNER_PROMPT_PATH=C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\00_R1G_INPUT\OWNER_PROMPT_VERBATIM.txt
OWNER_PROMPT_SHA256=870B78B78A37AB09486DC63CCADB81C5F4CB1398C02DDE935D35BF89B5DEDB9A
AUDITED_REPORT_PATH=C:\FPGA\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE\16_FINAL\R1H_AUTHORITATIVE_FINAL_REPORT.md
AUDITED_REPORT_SHA256=E7B41C0DD5CF21499BE55D8C4019F07694B1255252AB7539A1A376E7839B6468
TERMINAL_RECEIPT_SHA256=BC21A70F01CDBE4EAAA929326711E3A0E0C48BBF9EE31FF017513C003B2BD363
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
```

Independent Git queries returned:

```text
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_COMMITS_ABOVE_R1G=1
SOURCE_WORKTREE_DIRTY_LINES=0
R1H_REMOTE_BRANCH_PRESENT=NO
```

These values exactly match the report. The source branch was not published
after the failed build, as required by the build-PASS-only source-push gate.

## Required final-block structure

The final block was parsed independently from the exact saved owner prompt and
from the report section headed `Required final report block`.

```text
PROMPT_KEY_COUNT=154
REPORT_KEY_COUNT=154
KEY_SEQUENCE_EXACTLY_EQUAL=YES
MISSING_KEYS=0
EXTRA_KEYS=0
DUPLICATE_KEYS=0
BLANK_VALUES=0
REPORT_ENDS_AT_FINAL_BLOCK_CLOSING_FENCE=YES
LINES_AFTER_FINAL_BLOCK=0
```

All 37 prompt-supplied nonblank fixed values match byte-for-byte except
`FINAL_ACTIVE_IMAGE`. The prompt's `FORMAL_PHASE2` value is explicitly a
successful-end requirement. The task did not reach hardware, and the report
uses:

```text
FINAL_ACTIVE_IMAGE=NOT_FRESHLY_VERIFIED_R1H_HARDWARE_NOT_RUN
```

AUDIT CONCLUSION: this is a required fail-closed truth override, not a defect.
Reporting `FORMAL_PHASE2` would incorrectly promote historical R7 context to a
fresh R1h observation, contrary to the prompt's explicit start-state and
historical-context rules.

## Dynamic identity and accounting audit

The terminal receipt and exclusive build-consumption sentinel independently
support the report's build identity and counters:

```text
FULL_CLEAN_BUILDS=1
TERMINAL_BUILD_STAGE=PROJECT_SETUP
TERMINAL_ERROR=R1h probe-index BRAM wrapper is not before its probe consumer
SYNTHESIS_RUNS=0
OPT_DESIGN_RUNS=0
PLACE_DESIGN_RUNS=0
ROUTE_DESIGN_RUNS=0
BITSTREAM_RUNS=0
PROGRAM_RETRY_AUTHORIZED=NO
```

The build Tcl raises the exact exception at lines 1009--1011; its sole
`synth_design` command is later at line 1054. The preserved project records
the probe source at XML line 145 and the BRAM wrapper at XML line 201,
corroborating the queried reverse relative order. No queried-order receipt was
created because the script writes it only after the failing assertion.

The report correctly classifies the terminal event as a project-setup Tcl
assertion, not as a compiler, synthesis, optimization, placement, route,
timing, DRC, CDC, or bitstream result. It also correctly avoids claiming that
the production frontend would necessarily accept or synthesize the full
design.

All full-project post-synthesis primitive and utilization fields in the final
block are `NOT_AVAILABLE...SYNTHESIS_NOT_RUN`; all downstream implementation
fields are `NOT_RUN` or `NOT_AVAILABLE`. The report describes the six record
RAMB18E1 and three index RAMB18E1 results only as pre-commit component/OOC
evidence and explicitly refuses to promote them to an integrated full-top
mapping. This separation is accurate and contains no resource-gate overclaim.

## Scientific, hardware, and final-state truth audit

The report's `SCIENTIFIC_SCOPE_REDUCTION=NO`, storage capacities, opportunity
counts, synchronous one-outstanding service classification, and absence of the
old combinational 512:1 source architecture are supported by the exact source,
pre-commit equivalence/simulation receipts, and component inference evidence.
The report does not claim a full-top post-synthesis proof for those component
mapping results.

Because no bitstream exists, hardware eligibility was never reached. The
report truthfully records:

```text
PAIR_COUNT_VALID=0
CONDITIONAL_FORMAL_BOOTSTRAP_PROGRAMS=0
ARM_A_PROGRAMS=0
ARM_B_PROGRAMS=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
COLD_STARTS=0
PHYSICAL_ACTIONS=0
JTAG_FREQUENCY_CHANGES=0
PCI_REMOVE_RESCAN_RESETS=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
```

Every A/B datum is marked `NOT_RUN_BUILD_BLOCKED`, every requested scientific
classification is marked `NOT_RUN_NO_HARDWARE_DATA` (or an equally explicit
historical-context form), and no missing hardware observation is represented
as zero or PASS. Final Formal identity, diagnostic magic, driver state, DONE,
and active image are all explicitly marked not freshly verified, with R7 used
only as historical context.

## Publication placeholders and conclusion

The final block uses non-circular external references for the package hash and
publication receipt:

```text
EVIDENCE_PACKAGE_SHA256=SEE_EXTERNAL_SHA256_SIDECAR_NONCIRCULAR
EVIDENCE_REPOSITORY_COMMIT=SEE_EXTERNAL_PUBLICATION_RECEIPT
PUBLIC_REMOTE_VERIFICATION=SEE_EXTERNAL_PUBLICATION_RECEIPT
```

This is coherent for a report that must itself be inside the package and must
precede the publication commit. The actual values must be supplied by the
external package sidecar and publication receipt; the report does not invent
them.

Final decision:

```text
INDEPENDENT_FINAL_REPORT_AUDIT=PASS
FINAL_BLOCK_SCHEMA=PASS_154_OF_154_EXACT_ORDER
FIXED_PROMPT_VALUES=PASS_WITH_FAIL_CLOSED_FINAL_ACTIVE_IMAGE_OVERRIDE
DYNAMIC_IDENTITIES=PASS
BUILD_ACCOUNTING=PASS
RESOURCE_STAGE_SEPARATION=PASS
HARDWARE_ACCOUNTING=PASS
HISTORICAL_FORMAL_STATE_HANDLING=PASS
OVERCLAIMS_FOUND=0
BLOCKING_CORRECTIONS_REQUIRED=0
AUTHORIZED_NEXT_ACTION=SEAL_PACKAGE_PUBLISH_AVAILABLE_EVIDENCE_AND_HARD_STOP
```
