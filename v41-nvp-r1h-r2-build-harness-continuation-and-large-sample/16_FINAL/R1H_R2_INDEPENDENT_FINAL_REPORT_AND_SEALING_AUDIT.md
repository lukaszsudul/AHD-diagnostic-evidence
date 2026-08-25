# R1h-R2 — independent final-report and sealing-readiness audit

## Result

```text
AUDIT_RESULT=PASS_RELEASE_TO_TERMINAL_RESCAN_AND_NONCIRCULAR_SEAL
REPORT_BLOCK_RESULT=PASS_EXACT_178_OF_178
TERMINAL_EVIDENCE_RESULT=PASS
NOT_RUN_RECEIPTS_RESULT=PASS
PACKAGING_READINESS=PASS_SUBJECT_TO_MANDATORY_POST_AUDIT_TERMINAL_RESCAN
BLOCKERS=0
```

This was a fail-closed, read-only audit of the frozen authoritative report and
the existing R1h-R2 task-local evidence. It did not invoke Vivado, synthesis,
implementation, packaging, Git staging/commit/push, host access or hardware.
It made no source-repository mutation. This report is the audit's only
task-local output.

## Frozen identities

```text
TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
SOURCE_WORKTREE_CLEAN=YES
SOURCE_BRANCH_REMOTE_CONTAINS_R1H=0
OWNER_PROMPT_SHA256=395E5DDE111B006792BB75B3F95AF266E9EFF357E787CD854FDC4F35F01402A5
AUTHORITATIVE_REPORT_SHA256=35FE8A9578D1CAE4A78187E76C0B80F6E7EE20E43BE0FBBBABEAE5FDFF297919
AUTHORITATIVE_REPORT_PRESEAL_AUDIT_SHA256=37B06AC369546A5F8505B4124B241C8897E8FE40A86A4D2DD94E198AA2B5D3B1
PUBLICATION_PREFLIGHT_SHA256=7C3417D18094746E67CEC169AED6C108C71E8CAB47985C0CE7A331C78E659211
```

The exact source worktree was independently queried immediately before this
audit: HEAD and tree match the required identities, porcelain status is empty,
and no public remote branch contains the unpushed R1h commit.

## Mechanical audit of the required Section 21 block

The block was parsed independently from the verbatim owner prompt and from the
single `## Required final report block` in the authoritative report.

```text
OWNER_PROMPT_REQUIRED_KEYS=178
OWNER_PROMPT_REQUIRED_KEYS_UNIQUE=178
REPORT_REQUIRED_KEYS=178
REPORT_REQUIRED_KEYS_UNIQUE=178
MISSING_REQUIRED_KEYS=0
UNEXPECTED_REQUIRED_KEYS=0
DUPLICATE_REQUIRED_KEYS=0
BLANK_REQUIRED_VALUES=0
REQUIRED_KEY_ORDER_EQUALITY=PASS_178_OF_178
FIXED_PROMPT_FIELDS=46
FIXED_PROMPT_FIELD_DIFFERENCES=1_FAIL_CLOSED_OVERRIDE_ONLY
TARGETED_DYNAMIC_EVIDENCE_ASSERTIONS=137
TARGETED_DYNAMIC_EVIDENCE_ASSERTION_FAILURES=0
PENDING_DRAFT_TODO_TOKENS=0
```

The sole fixed-field difference is intentional and required by the evidence:
the success-state template says `FINAL_ACTIVE_IMAGE=FORMAL_PHASE2`, while no
bitstream or hardware action existed after the post-synthesis hard stop. The
report therefore correctly uses
`NOT_FRESHLY_VERIFIED_R1H_R2_HARDWARE_NOT_RUN`. It also labels the R7 formal
identity, diagnostic magic and DONE as historical rather than fresh. Claiming
the template's success state would be false.

All other fixed prompt values are exact. Targeted dynamic checks bind the
harness mode, dry-run, semantic elaboration, source identity, memory mapping,
resource figures, later-stage non-execution, bootstrap, every A/B measurement
field, statistical classifications, final-state caveats, operation counters
and non-circular publication placeholders to their exact receipts or mandated
fail-closed representation. In particular:

```text
BOOTSTRAP_RUN=NO_BUILD_BLOCKED
BOOTSTRAP_RESULT=NOT_RUN_NO_R1H_R2_BITSTREAM
ALL_A_B_MEASUREMENT_FIELDS=NOT_RUN_BUILD_BLOCKED
ALL_PROCESS_CLASSIFICATIONS=NOT_RUN_NO_HARDWARE_DATA
PAIR_COUNT_VALID=0
FORMAL_PHASE2_FRESHLY_RECONFIRMED=NO
```

No historical R7 state is promoted to a fresh R1h-R2 observation. No OOC
memory result is promoted to full-top evidence: the full-top 6+3 RAMB18 claim
is bound to the synthesized DCP primitive inventory. No routed, timing, DRC,
CDC or bitstream PASS is claimed because those stages did not run.

## Terminal build and resource evidence

The report's principal evidence references were independently rehashed:

| Artifact | SHA-256 | Result |
|---|---|---|
| `06_BUILD/FULL_BUILD/R1H_BUILD_TERMINAL_FAILURE.txt` | `FD5CFEBCC50836FE16B7C64AACE0BEBB9603C06F2DB1D631451D28008BD78B28` | PASS |
| `06_BUILD/FULL_BUILD/R1H_POST_SYNTH_RESOURCE_GATE.txt` | `92F3779DD14BDFFA05C551EB6728393FC1A1AE5715716D01628842CDC48EFC42` | PASS |
| `06_BUILD/FULL_BUILD/R1H_synth.dcp` | `807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E` | PASS |
| `06_BUILD/R1H_R2_full_build_vivado.log` | `F1FD8ED7702F0FC3F2C014D9EADB2EE578FFB1D28CB4F1E72F6CC6AFF8780795` | PASS |
| `06_BUILD/R1H_R2_FULL_BUILD_PRELAUNCH_AND_MONITOR_AUDIT.md` | `0B1047FA437375890C0BF2D81F8F1C385B552CB38358091B9C990571F6EF1856` | PASS |
| `07_RESOURCE_GATES/R1H_R2_INDEPENDENT_POST_SYNTH_RESOURCE_AUDIT.md` | `7AC5BA922A2C4F3DB9C7301BBB81DD7EF74BF0889B3EBC2A26C3C7B0D641224E` | PASS |

The exact terminal nomenclature is preserved without conflating the combined
Tcl exception with its proven sub-cause:

```text
R1H_R2_TASK_SPEC_HARD_STOP_CLASS=BLOCKED_R1H_R2_POST_SYNTH_RESOURCE_OR_MAPPING_GATE
EXACT_HARNESS_TERMINAL_ERROR=BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING
CAUSE_DISAMBIGUATION=POST_SYNTH_RESOURCE_MARGIN_GATE_FAIL_LUT_ONLY
POST_SYNTH_MEMORY_MAPPING_GATE=PASS
POST_SYNTH_SLICE_LUTS=19255
POST_SYNTH_SLICE_LUTS_LIMIT=18720
POST_SYNTH_SLICE_LUT_EXCESS=535
POST_SYNTH_SLICE_REGISTERS=20395
POST_SYNTH_SLICE_REGISTERS_LIMIT=37440
```

Full-top mapping is exactly six failed-record RAMB18 plus one RAMB18 for each
of WADDR, REGADDR and DATA. New payload RAMB18 total is nine; failed-record
RAM64M/RAMD64E are zero; bounded logger/index-region FDRE counts are 81 and 3.
The report correctly distinguishes this mapping PASS from the sole failing
Slice-LUT headroom predicate.

## Operation accounting and mandatory NOT-RUN evidence

The operation ledger, atomic build sentinel, terminal receipt and stage
receipts reconcile to:

```text
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
PROJECT_SETUP_DRY_RUNS=1
SEMANTIC_ELABORATION_PREFLIGHTS=1
FULL_CLEAN_BUILDS=1
SYNTH_DESIGN_INVOCATIONS=1
OPT_DESIGN_INVOCATIONS=0
PLACE_DESIGN_INVOCATIONS=0
ROUTE_DESIGN_INVOCATIONS=0
BITSTREAMS=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_READS=0
AXI_LITE_WRITES=0
DMA_TRANSFERS=0
PHYSICAL_ACTIONS=0
SOURCE_BRANCH_PUSHES=0
```

All eight mandatory post-stop receipts exist, are non-empty and were rehashed:

| Stage | Receipt SHA-256 |
|---|---|
| Routed impact | `4D3A0A729CD8C805F3285AF11FEAA20BCEF891174D21B98F4BADC2DB73F369AF` |
| Host tools | `624E2E1D7FD15B6B4D8C0CD667D07356D37D0DDE80E3EC5D2AA06ABD922E6321` |
| Hardware precheck | `9AE5E027207BB5A3B1EBD06921199457F7AC4A44F79D23C8DA9A2E8BEF00C9FD` |
| Bootstrap | `1C24EC0B7DBE10839A93332BBEACCAFDDE776E993B2AFA826266BB43671F44B3` |
| Pair 1 | `A16E663956BAAFAB8BC6944282C47BE351FFB686243DBDC869804DC01595FD97` |
| Pair 2 | `9C98CC584A3786C55D33DF17311576018524D9DAA443A02CA36D07D110E9D983` |
| Pair 3 | `1DE2149443891431CC91801DF318F54CC07F61C4466DD5963A9066FF52B75CCF` |
| Statistical analysis | `A8A3EB7E0D8E4E312FCF6C24CA80DABB5E17959DB72B0CE8E28FB2139F77A2F8` |

A separate 46-assertion semantic reconciliation across these receipts had zero
failures. Published R1h host-fixture reuse remains explicitly historical; it
is not reported as a fresh post-build R1h-R2 host gate.

## Task-tree and sealing readiness

Immediately before this report was added, the complete task tree, including
the frozen publication preflight, had this read-only safety result:

```text
REQUIRED_DIRECTORIES_PRESENT=19_OF_19
TASK_FILES_BEFORE_THIS_AUDIT_REPORT=142
TASK_DIRECTORIES=25
TASK_BYTES_BEFORE_THIS_AUDIT_REPORT=57994905
RESOLVED_PATHS_OUTSIDE_TASK_ROOT=0
REPARSE_POINTS=0
NONDEFAULT_ALTERNATE_DATA_STREAMS=0
CASEFOLD_PATH_COLLISION_GROUPS=0
UNSAFE_OR_RESERVED_PATH_ROWS=0
SENSITIVE_FILENAME_CANDIDATES=0
MAX_ABSOLUTE_PATH_CHARS=134
MAX_RELATIVE_PATH_CHARS=84
ALL_FILE_BYTE_SIGNATURE_PATTERNS=8
ALL_FILE_BYTE_SIGNATURE_HITS=0
```

The byte-signature scan covered all 142 then-existing files, including the
synthesis checkpoint, for private-key headers and common high-confidence token,
bearer-header and inline-credential URL forms. The named credential file
`C:\FPGA\VCDE-DUT-1.txt` was not opened, copied, hashed or inspected. Its path
appears once, only in the required verbatim owner prompt. No credential-like
filename is present below the task root.

The manifest, ZIP and ZIP sidecar were correctly absent at audit time; this
audit did not create them. The authoritative report's three external values
are deliberately non-circular:

```text
EVIDENCE_PACKAGE_SHA256=SEE_EXTERNAL_SHA256_SIDECAR_NONCIRCULAR
EVIDENCE_REPOSITORY_COMMIT=SEE_EXTERNAL_PUBLICATION_RECEIPT
PUBLIC_REMOTE_VERIFICATION=SEE_EXTERNAL_PUBLICATION_RECEIPT
```

Because this audit report is a new final payload file, the sealing owner must
perform one terminal whole-tree reparse/path/collision/secret scan after this
file is frozen and before generating the manifest. It must include this report
and `R1H_R2_PUBLICATION_PREFLIGHT.md`. This is a mandatory sequencing step, not
an audit blocker.

Publication preflight is PASS subject to that terminal rescan and exactly
three path-scoped Git LFS rules for the new ZIP, `**/*.vcd` and `**/*.dcp` under
the new evidence directory. In particular, `R1H_synth.dcp` and the final ZIP
must be verified as LFS pointers with object IDs and sizes matching the working
files. No source branch may be pushed because full-build PASS was not reached.

## Independent release decision

```text
AUTHORITATIVE_REPORT=FROZEN_AND_EVIDENCE_CONSISTENT
R1H_R2_TERMINAL_CLASSIFICATION=BLOCKED_R1H_R2_POST_SYNTH_RESOURCE_OR_MAPPING_GATE
RESOURCE_FAILURE=SLICE_LUT_MARGIN_ONLY_EXCESS_535
MEMORY_MAPPING=PASS_EXACT_6_PLUS_3_RAMB18
IMPLEMENTATION_AND_HARDWARE=NOT_RUN
FORMAL_PHASE2_FRESHLY_RECONFIRMED=NO
SEALING_RELEASE=PASS_AFTER_MANDATORY_POST_AUDIT_TERMINAL_RESCAN
PUBLICATION_RELEASE=PASS_AFTER_TERMINAL_RESCAN_LFS_GATE_NORMAL_ONE_COMMIT_AND_REMOTE_VERIFICATION
SOURCE_OR_GIT_MUTATION_BY_THIS_AUDIT=NO
PACKAGE_OR_PUBLICATION_BY_THIS_AUDIT=NO
BLOCKERS=0
```
