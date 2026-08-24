# R1g independent authoritative-final-report audit

## Audit identity and decision

```text
AUDIT_UTC=2026-08-24T17:37:54.0626857Z
AUDIT_CLASS=INDEPENDENT_READ_ONLY_REPORT_AND_EVIDENCE_AUDIT
AUDITED_REPORT_PATH=C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\16_FINAL\V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY_FINAL_REPORT.md
AUDITED_REPORT_BYTES=17497
AUDITED_REPORT_SHA256=6BD146E4B8A7C41BB6F407BC9FB4BAA42B4DA7767F6877EFD9DDF6BA3820638B
OWNER_PROMPT_SHA256=CE2F6A181E5850A3E6137569108E118847A504BEC5130B43FDD97A06FC10D618
AUDIT_RESULT=PASS_REPORT_CONTENT_READY_TO_SEAL
REPORT_EDITED_BY_AUDITOR=NO
LEDGERS_EDITED_BY_AUDITOR=NO
MANIFEST_OR_PACKAGE_EDITED_BY_AUDITOR=NO
GIT_ACTIONS_BY_AUDITOR=0
LIVE_OR_HARDWARE_ACTIONS_BY_AUDITOR=0
```

The report is structurally complete and evidence-consistent at the audited
hash. Two populated dynamic values identified in the first audit pass were
corrected by the primary agent and independently rechecked below. No remaining
report-content blocker was found.

## Section 22 terminal-block conformance

The block beginning at report line 192 and ending at the final closing fence
was parsed independently and compared to Section 22 of the saved owner prompt.

```text
PROMPT_SECTION_22_KEYS=167
REPORT_TERMINAL_BLOCK_KEYS=167
KEY_COUNT_MATCH=PASS
KEY_ORDER_MATCH=PASS_167_OF_167
MISSING_KEYS=0
EXTRA_KEYS=0
DUPLICATE_KEYS=0
UNPOPULATED_REPORT_VALUES=0
PROMPT_FIXED_VALUE_KEYS=45
PROMPT_FIXED_VALUES_EXACT=PASS_45_OF_45
TERMINAL_BLOCK_IS_FINAL_REPORT_CONTENT=YES
STRUCTURAL_GATE=PASS
```

No fixed owner value was altered. In particular, the task/experiment/source
identities, required compatibility classifications, frozen scientific
constants, planned pair count, conservative causal statements, prohibited
action counts, and required `NEXT_ACTION` all match exactly.

## Correction verification 1 — total VHDL-2008 occurrence count

The final terminal block now contains:

```text
VHDL2008_CONSTRUCTS_FOUND=6_TOTAL_1_PRODUCTION_5_TESTBENCH_ONLY
```

That is the correct count for *production synthesis blockers*, but the
unqualified Section 22 key asks how many VHDL-2008 constructs were found. The
sealed static audit and prebuild manifest prove six total occurrences:

```text
VHDL2008_CONSTRUCT_OCCURRENCES_TOTAL=6
VHDL2008_PRODUCTION_OCCURRENCES=1
VHDL2008_TESTBENCH_ONLY_OCCURRENCES=5
R1G_PREBUILD_MANIFEST_META_VHDL2008_CONSTRUCTS_FOUND=6
VHDL2008_CONSTRUCTS_REWRITTEN=1
```

The report body also says one production blocker plus five simulation-only
occurrences. The corrected terminal value is therefore consistent with both
the body and the sealed manifest while preserving the scientifically relevant
production/testbench distinction.

```text
CORRECTION_1=PASS_EVIDENCE_NORMALIZED
CORRECTION_1_REMAINING_BLOCKER=NO
```

## Correction verification 2 — placement phase classification

The final terminal block now contains:

```text
PLACE=NOT_RUN_RESOURCE_OVERUTILIZATION_DRC
```

The value truthfully embeds that the placer did not run, and the report body
is explicit on that point. However, the independent terminal build audit uses
the authoritative phase classification:

```text
PLACE_DESIGN=FAIL_DRC_PRECONDITION_PLACER_NOT_RUN
PLACE=NOT_RUN_RESOURCE_OVERUTILIZATION_DRC
```

The actual log proves one `place_design` command failed its pre-place DRC with
three `UTLZ-1` errors and emitted `Placer not run.` Thus `place_design` failed,
while the placement phase itself was not run. The corrected Section 22 value
now exactly matches the independent terminal build audit.

```text
CORRECTION_2=PASS_AUDIT_EXACT
CORRECTION_2_REMAINING_BLOCKER=NO
```

## Dynamic-value evidence reconciliation

All populated dynamic values were reconciled without contradiction:

| Evidence group | Audit result | Independent basis |
|---|---|---|
| R1f report/package identities | PASS | Local report rehash `2F0D7997...0544C09D`; exact package sidecar `62350D80...F4704E4` |
| Production language contract | PASS | Installed-tool/project query evidence and prebuild manifest agree on `VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008` |
| Rewrite count/file and semantics | PASS | One file, one rewrite site, 5 additions/1 deletion; exact same-process if/else |
| Compiler iterations | PASS | Two receipts: expected exact-R1f failure, then R1g `PASS_ALL_FILES` |
| Cross-standard equivalence | PASS | Consolidated gate proves zero semantic differences and all frozen offline gates |
| Final RTL preflight | PASS | Exactly one; exit 0; `Synth 8-2757` count 0; forbidden command counts 0 |
| R1g source identity | PASS | Live clean worktree at commit `e112a5ad...0bada`, tree `3a59ebec...e5534`, direct parent exact R1f |
| Clean-build accounting | PASS | One build, one synthesis, one implementation run; zero retries |
| Synthesis result | PASS | Synthesis completed with 0 errors and 0 critical warnings; synth DCP rehash exact |
| Build blocker | PASS | Three pre-place `DRC UTLZ-1` errors; 30,926/20,800 LUT-as-logic and 44,248/41,600 registers; placer not run |
| Route/timing/REQP/CDC status | PASS | Correctly NOT EVALUATED because placement and route did not run |
| R1g bit and routed DCP | PASS | No `.bit`, no R1g routed DCP, no build-PASS receipt |
| Hardware campaign | PASS | No active binding, reservation, precheck, bootstrap, pair dataset, program, reboot, driver load, MMIO, or DMA evidence |
| Arm measurements/statistics | PASS | Correctly NOT RUN / NOT MEASURED / NOT EVALUATED; no scientific result is fabricated |
| R7 operation-86 semantics | PASS_WITH_HISTORICAL_SCOPE | Exact inherited source audit supports legal transitional context; report explicitly says it is not an R1g hardware observation |
| Operation/prohibited-action counters | PASS | Terminal values match `OPERATION_LEDGER.md`, including all hardware/prohibited counters at zero |
| Owner prompt identity | PASS | Saved prompt independently rehashes to the reported SHA-256 |

The terminal build receipt rehashes to
`446B6468DAE7EB456D0477A21DF465925CB963714C285E664F8A43A3188728A7`,
the final Vivado log to
`9156A7DA638ADAE8D015F4BADFBF0A4A86D6BBFC3718F92FD7C5AF8BF7C4B42E`,
and the synthesis-only DCP to
`DB9FE5C96D3AA42EE43AAB6396E2FBEB1E75335463DFEC4B259EA242C320B34B`.
These agree with the report and independent terminal audit.

## Historical final-state and publication caveats

`FINAL_ACTIVE_IMAGE=FORMAL_PHASE2` is one of the 45 owner-fixed Section 22
values, so it is structurally exact. It must not be interpreted as a fresh R1g
hardware proof: the R1g hardware start-state gate was never entered. The body
correctly discloses this, and every adjacent dynamic final-state field is
explicitly suffixed `R7_RECORDED_NOT_R1G_FRESHLY_RECONFIRMED`. This audit
therefore treats the value only as preserved R7 context plus the proof that R1g
performed zero hardware actions.

The three final publication fields intentionally point to external,
non-circular sidecars/receipt, matching the established R1f publication
pattern. At audit time those new R1g external artifacts do not yet exist under
`16_FINAL`, so their ultimate identities and public verification cannot yet be
independently checked. This is a publication-closure condition, not a reason to
self-embed circular hashes in the report.

```text
FINAL_ACTIVE_IMAGE_FRESHLY_RECONFIRMED_IN_R1G=NO
FINAL_STATE_INTERPRETATION=HISTORICAL_R7_CONTEXT_ONLY
R1G_EVIDENCE_PACKAGE_SIDECAR_PRESENT_AT_AUDIT=NO
R1G_PUBLICATION_RECEIPT_PRESENT_AT_AUDIT=NO
PUBLICATION_FIELDS_AUDIT_STATUS=PENDING_EXTERNAL_CLOSURE
```

## Release decision

The corrected authoritative report is ready for evidence sealing at the SHA-256
recorded above. The external package SHA-256 sidecar and publication receipt
must still be created and independently verified in their normal non-circular
sequence. No source, build, ledger, hardware, scientific, or Git correction is
required or implied.

```text
REPORT_READY_TO_SEAL=YES
REPORT_CONTENT_BLOCKER_COUNT=0
PUBLICATION_CLOSURE_PENDING=YES
NEXT_ACTION=SEAL_PACKAGE_CREATE_EXTERNAL_SIDECAR_AND_PUBLISH
```
