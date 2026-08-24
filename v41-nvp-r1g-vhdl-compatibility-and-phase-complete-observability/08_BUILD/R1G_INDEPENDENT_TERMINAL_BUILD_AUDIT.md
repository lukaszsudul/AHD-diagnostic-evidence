# R1g Independent Terminal Build Audit

## Audit scope and result

This is an independent, read-only audit of the single authorized R1g clean-build invocation. The monitor did not invoke Vivado, alter the source worktree, alter the prebuild manifest, alter a ledger, alter a build output, or request a retry.

```text
AUDIT_RESULT=FAIL_EXACT_PLACE_PRECONDITION_RESOURCE_OVERUTILIZATION
BUILD_CONSUMED=YES
SOURCE_OR_LANGUAGE_BLOCKER=NO
HARDWARE_AUTHORIZED_AFTER_THIS_RESULT=NO
SECOND_BUILD_AUTHORIZED=NO
```

The compatibility correction achieved its immediate frontend objective: synthesis completed with zero errors and zero critical warnings, and the prior R1f `Synth 8-2757`/`VRFC 10-1449` language failure did not recur. The sole build then stopped at the `place_design` DRC precondition because the optimized design exceeded the xc7a35t LUT-as-logic and register capacities. The placer explicitly did not run.

## Bound invocation identity

The journal records one Vivado session, PID 2196, beginning 2026-08-24 18:53:18 local time. Repeated live sampling observed one process lineage only: the launching PowerShell process, one `cmd.exe` wrapper, and one `vivado.exe`. No second Vivado or retry invocation was observed. At terminal audit time there was no live Vivado process and no remaining command line invoking the R1g build Tcl.

```text
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
PART=xc7a35tcsg325-2
TOP=ahd_capture_top_xdma
BUILD_TCL_SHA256=C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A
SOURCE_GIT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
SOURCE_GIT_TREE=3a59ebec130103055d24a3a32ecda00dedde5534
R1G_PARENT_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1G_COMMITS_ABOVE_R1F=1
SOURCE_TREE_CLEAN_AT_CONSUMPTION=YES
PREBUILD_MANIFEST_SHA256=F31220B039E26C29C994A6F9B60A5416DE6EE0231C9C9E78CE81E013ECA473B9
PREBUILD_MANIFEST_SOURCE_RECORDS=51
PREBUILD_MANIFEST_ACCEPTED_LOG_RECORDS=37
PREBUILD_MANIFEST_BINDING=PASS
PROVENANCE_ROUND_TRIP=PASS
```

The sole-build sentinel was created at 2026-08-24T16:54:10Z before project creation and is bound to the same source commit, source tree, manifest, and installed Vivado build.

```text
ONE_CLEAN_BUILD_SENTINEL_SHA256=F945D9B15A6B72710EC2B0A0A3942C3B345D8AF66152D129FE853980F1C7E0CA
CONSUMED_BEFORE_CREATE_PROJECT=YES
PROGRAM_RETRY_AUTHORIZED=NO
```

## Actual command execution

Counts below use actual `Command:` execution records in the terminal Vivado log, not Tcl source text echoed as comments.

```text
SYNTH_DESIGN_INVOCATIONS=1
OPT_DESIGN_INVOCATIONS=1
PLACE_DESIGN_INVOCATIONS=1
PHYS_OPT_DESIGN_INVOCATIONS=0
ROUTE_DESIGN_INVOCATIONS=0
WRITE_BITSTREAM_INVOCATIONS=0
BUILD_RETRIES=0
```

The one synthesis checkpoint was emitted before implementation. There is no routed checkpoint, build-result PASS receipt, artifacts directory, or `.bit` file in either the evidence directory or build root.

```text
SYNTHESIS=PASS
SYNTHESIS_ERRORS=0
SYNTHESIS_CRITICAL_WARNINGS=0
SYNTH_8_2757_COUNT=0
VRFC_10_1449_COUNT=0
OPT_DESIGN=PASS
PLACE_DESIGN=FAIL_DRC_PRECONDITION_PLACER_NOT_RUN
PLACE=NOT_RUN
PHYS_OPT=NOT_RUN
ROUTE=NOT_RUN
R1G_ROUTED_DCP_PRESENT=NO
BITSTREAM_GENERATED=NO
```

## Exact terminal blocker

After `opt_design` completed successfully, the `place_design -directive Explore` precondition DRC emitted three `DRC UTLZ-1` errors:

| Resource | Optimized requirement | Available | Excess | Required/available |
|---|---:|---:|---:|---:|
| LUT as Logic | 30,926 | 20,800 | 10,126 | 148.68% |
| Register as Flip Flop | 44,248 | 41,600 | 2,648 | 106.37% |
| Slice Registers | 44,248 | 41,600 | 2,648 | 106.37% |

Vivado reported `DRC finished with 3 Errors, 4 Warnings`, then `Error(s) found during DRC. Placer not run.`, and finally:

```text
TERMINAL_ERROR=ERROR: [Common 17-39] 'place_design' failed due to earlier errors.
```

For context, the pre-optimization synthesis utilization report recorded 32,615 LUT-as-logic cells of 20,800 (156.80%) and 45,262 flip-flops of 41,600 (108.80%). Optimization reduced the counts, but not enough to fit the fixed device.

This is a deterministic implementation-capacity blocker, not a VHDL-language-compatibility failure and not a scientific hardware result.

## Terminal evidence identities

```text
R1G_VIVADO_BUILD_LOG_SHA256=9156A7DA638ADAE8D015F4BADFBF0A4A86D6BBFC3718F92FD7C5AF8BF7C4B42E
R1G_VIVADO_BUILD_LOG_BYTES=357975
R1G_VIVADO_JOURNAL_SHA256=58E928274C8EB1B05093E3947DD3691E897A660F147A0B6AA742B0D00A505076
R1G_VIVADO_JOURNAL_BYTES=1870
R1G_TERMINAL_FAILURE_RECEIPT_SHA256=446B6468DAE7EB456D0477A21DF465925CB963714C285E664F8A43A3188728A7
R1G_SYNTH_DCP_SHA256=DB9FE5C96D3AA42EE43AAB6396E2FBEB1E75335463DFEC4B259EA242C320B34B
R1G_SYNTH_DCP_BYTES=62806179
R1G_POST_SYNTH_UTILIZATION_SHA256=DED9BDC4066622E69332B704A751AADD1B3146C85AD68FFD800B2D37E548A236
R1G_POST_SYNTH_TIMING_SHA256=3548A758999B17143A2F63369C81FF763FDF4EF07E8FA4170292C0B6CD5F4444
```

## Required continuation classification

```text
FULL_CLEAN_BUILDS=1
FULL_SYNTHESIS=PASS
PLACE=NOT_RUN_RESOURCE_OVERUTILIZATION_DRC
ROUTE=NOT_RUN
BITSTREAMS_GENERATED=0
R1G_HARDWARE_ACTIONS=0
R1G_TERMINAL_CLASSIFICATION=BLOCKED_ONE_CLEAN_BUILD_PLACE_PRECONDITION_RESOURCE_OVERUTILIZATION
NEXT_ACTION=PRESERVE_AND_PUBLISH_TERMINAL_EVIDENCE_NO_HARDWARE
```
