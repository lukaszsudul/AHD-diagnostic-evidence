# R1h independent terminal sealing and compile-order audit

Audit result: `PASS_TERMINAL_EVIDENCE_COHERENT`

This is a read-only audit of the sole consumed R1h build session after its
fail-closed termination. The auditor did not invoke Vivado, synthesis,
implementation, programming, host access, or any retry. The only new artifact
is this task-local report.

## Authoritative identity

FACT:

```text
TASK=V41_NVP_R1H_BRAM_BACKED_PHASE_COMPLETE_OBSERVABILITY_AND_LARGE_SAMPLE_AB
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
R1G_SOURCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_COMMITS_ABOVE_R1G=1
SOURCE_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample
SOURCE_WORKTREE_CLEAN=YES
R1H_BUILD_TCL_SHA256=2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18
PREBUILD_MANIFEST_SHA256=192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79
```

FACT: independent rehashing of the finalized prebuild manifest returned:

```text
META_RECORDS=43
SOURCE_SHA256_RECORDS=224
SOURCE_SHA256_VERIFICATION=PASS_224_OF_224
ACCEPTED_LOG_SHA256_RECORDS=32
ACCEPTED_LOG_SHA256_VERIFICATION=PASS_32_OF_32
MISSING_FILES=0
HASH_MISMATCHES=0
UNKNOWN_RECORDS=0
BOUND_MANIFEST_BYTE_IDENTICAL=YES
```

FACT: the bound manifest in `07_BUILD/FULL_BUILD` has the same SHA-256 as the
finalized prebuild manifest. Git independently returned the commit, tree,
direct parent, one-commit topology, empty porcelain status, and successful
`git diff --check` expected by the prebuild release.

## Sole session and irreversible build accounting

TOOL-DERIVED FACT: `vivado.jou` records one batch session, started at
`2026-08-25 00:43:09+02:00`, PID 2468, with the exact task-local build Tcl and
seven arguments binding the source worktree, build root, evidence root,
commit, tree, manifest path, and manifest SHA-256 above. `vivado.log` records
one matching start, one matching command line, and one Vivado exit at
`2026-08-25 00:45:51+02:00`. There are no backup or second-session Vivado
log/journal files for this build and no active `vivado.exe` process at audit
time.

FACT: the build Tcl creates the sentinel using `open ... {WRONLY CREAT EXCL}`
before `create_project`. The resulting sentinel states
`CONSUMED_BEFORE_CREATE_PROJECT=YES` and binds the exact commit, tree,
manifest, Vivado version, and software build:

```text
FULL_CLEAN_BUILDS_CONSUMED=1
CONSUMED_UTC=2026-08-24T22:44:11Z
PROGRAM_RETRY_AUTHORIZED=NO
BUILD_RETRY_RUN=NO
```

Evidence identities:

| Artifact | SHA-256 |
|---|---|
| `vivado.log` | `8CFAB3C70428E0E6FCCC3D9F35BF1AD04D237F9ABF248DF9C0EB2C571170408F` |
| `vivado.jou` | `BB465B7F1BE45CDC889ADE330A8E4FDBC4B47811352A4E20766CE00EB2D64B51` |
| `R1H_ONE_CLEAN_BUILD_CONSUMED.marker` | `58E940C3A916564E3A739CC2935AC8480CBB2662451D72AF51D32AA913EF2760` |
| `R1H_BUILD_TERMINAL_FAILURE.txt` | `BC21A70F01CDBE4EAAA929326711E3A0E0C48BBF9EE31FF017513C003B2BD363` |
| `R1H_PRECONSUMPTION_IDENTITY.txt` | `E601649552817725D6A334FA0E148AFA8C705B34F86D0F9DFEE6A1171CE114B7` |
| `R1H_PREBUILD_MANIFEST_BINDING.txt` | `2518FBD5DB4BB54BFA7619D8319CD87CDE3F6AD841628C8F7180F10122E1BA2E` |
| `R1H_BOUND_PREBUILD_MANIFEST.txt` | `192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79` |
| created project `.xpr` | `35174F780F5AEA58284E037ABDC62F947AC2B7448FC103FEF6854D3ABA6DEF39` |

## Exact failure stage and zero downstream commands

TOOL-DERIVED FACT: the terminal receipt says:

```text
TERMINAL_BUILD_STAGE=PROJECT_SETUP
TERMINAL_ERROR=R1h probe-index BRAM wrapper is not before its probe consumer
SYNTHESIS_RUNS=0
OPT_DESIGN_RUNS=0
PLACE_DESIGN_RUNS=0
ROUTE_DESIGN_RUNS=0
BITSTREAM_RUNS=0
```

SOURCE-DERIVED FACT: the exception is raised at `r1h_build.tcl:1009-1011`.
The next synthesis-stage assignment and the only `synth_design` call are at
lines 1052-1054. The opt/place/phys-opt/route/bit commands are later still.

FACT: the Vivado journal contains only the top-level `source` command. The
runtime portion of `vivado.log` contains project creation, XDMA import/target
generation, the terminal Tcl error, and exit; it contains no executed
`synth_design`, `write_checkpoint`, `opt_design`, `place_design`,
`phys_opt_design`, `route_design`, or `write_bitstream` command. Occurrences
inside the commented source echo are not command executions.

FACT: recursive inspection of the exact build root and exact full-build
evidence root found:

```text
SYNTH_DCP_COUNT=0
ROUTED_DCP_COUNT=0
BITSTREAM_COUNT=0
R1H_BUILD_RESULT_EXISTS=NO
R1H_QUERIED_SYNTHESIS_COMPILE_ORDER_RECEIPT_EXISTS=NO
R1H_POST_SYNTH_RESOURCE_GATE_RECEIPT_EXISTS=NO
```

CONCLUSION: synthesis, integrated primitive mapping, post-synthesis LUT/FF
margin, optimization, placement, routing, timing, DRC, CDC, provenance-to-bit,
and bitstream results are all `NOT_RUN` or `NOT_AVAILABLE`. None may be
reported as PASS or FAIL.

## What the compile-order evidence proves

### Evidence before interpretation

SOURCE-DERIVED FACT: the executing Tcl's explicit `sv_rel_files` list places
`r1h_probe_index_bram_store.sv` immediately before
`nvp_i2c_tri_phase_probe.sv`. The generated planned inventory correspondingly
records them at entries 008 and 009 after the four VHDL files.

TOOL-DERIVED FACT: after `update_compile_order`, the Tcl queried
`get_files -compile_order sources -used_in synthesis`. It first proved that
both paths were present. It then compared their list indexes and raised the
terminal error only when the wrapper index was greater than or equal to the
probe index. Because the paths are distinct and both are present, the observed
relation was strictly:

```text
QUERIED_INDEX(r1h_probe_index_bram_store.sv) >
QUERIED_INDEX(nvp_i2c_tri_phase_probe.sv)
```

The exact numeric queried indexes are UNAVAILABLE because the script writes
`R1H_QUERIED_SYNTHESIS_COMPILE_ORDER.txt` only after the assertion that
terminated the flow.

TOOL-DERIVED FACT: the saved project serializes the same relative relation:
the `sources_1` XML file elements are probe ordinal 007, wrapper ordinal 015,
and top ordinal 021. Project-file serialization is corroborating context, not
a substitute for the unavailable queried-order receipt.

SOURCE-DERIVED FACT: both files are standalone SystemVerilog module design
units. The probe contains no cross-file `include`, package import, interface,
typedef, macro, or bind dependency on the wrapper. Its only dependency is the
ordinary module instantiation
`r1h_probe_index_bram_store INDEX_PAYLOAD_STORE` at
`nvp_i2c_tri_phase_probe.sv:687`. Thus the asserted textual declaration-before-
consumer ordering is not an RTL semantic contract in these sources.

FACT: the existing precommit Vivado 2025.2 full-top XSim lane successfully
analyzed and elaborated both design units and built the top snapshot. That lane
used wrapper-before-probe command ordering, so it proves the module interface
and top integration, but does not itself execute the reversed order returned
by the production project query.

### Fail-closed classification

```text
SCRIPT_ASSERTION_AS_TERMINAL_CAUSE=PROVEN
VIVADO_QUERIED_RELATIVE_ORDER_WRAPPER_AFTER_PROBE=PROVEN
COMPILER_REPORTED_SYSTEMVERILOG_ERROR=NO
SYNTHESIS_REPORTED_ERROR=NO
SYSTEMVERILOG_TEXTUAL_DECLARATION_ORDER_REQUIREMENT=NOT_PRESENT_IN_EXACT_SOURCES
COMPILE_ORDER_ASSERTION_CLASS=OVERCONSTRAINED_NON_SEMANTIC_SCRIPT_POLICY
PRODUCTION_FRONTEND_ACCEPTANCE_OF_QUERIED_ORDER=NOT_DETERMINABLE_NOT_ATTEMPTED
ACTUAL_R1H_SYNTHESIS_BLOCKER=NOT_DETERMINABLE_SYNTHESIS_NOT_RUN
```

INFERENCE: the evidence strongly distinguishes a false-positive project-setup
policy gate from a compiler diagnosis. It does **not** authorize the stronger
claim that the full production frontend would necessarily accept and
synthesize the project: that experiment never began and a retry is forbidden.

## Secondary documentation discrepancy

FACT: task-local `R1H_PLANNED_SOURCE_ORDER.md` says the executing build Tcl
adds `rtl/v41/nvp_i2c_address_probe.sv`. The exact executing Tcl and its
generated `R1H_PLANNED_SOURCE_AND_CONSTRAINT_ORDER.txt` do not contain that
file. The exact frozen R1g build Tcl also omits it, and source search finds its
module declaration but no instantiation in production RTL.

CONCLUSION: this is a task-local planned-order documentation inconsistency,
not the observed terminal error and not proof of a missing production module.
It should be disclosed; no file is corrected under the consumed one-commit,
one-build authorization.

## Hardware and final-state seal

FACT: hardware preparation scripts and offline fixtures exist, but the
bootstrap, pair, and analysis directories contain no campaign datasets. No
R1h bit exists, so the hardware eligibility gate was never reached.

```text
FPGA_PROGRAMS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS=0
PAIR_COUNT_VALID=0
FORMAL_PHASE2_FRESHLY_RECONFIRMED=NO
FINAL_ACTIVE_IMAGE=NOT_FRESHLY_VERIFIED_R1H_HARDWARE_NOT_RUN
```

Historical R7 Formal Phase 2 identity must not be promoted into a fresh R1h
final-state claim.

## Values for the authoritative final report

```text
R1H_PARENT_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_BIT_SHA256=NOT_GENERATED
R1H_ROUTED_DCP_SHA256=NOT_GENERATED

SCIENTIFIC_SCOPE_REDUCTION=NO
MMIO_READ_SERVICE=SYNCHRONOUS_ONE_OUTSTANDING_SOURCE_VERIFIED
COMBINATIONAL_INDEX_512_TO_1_MUX=ABSENT_SOURCE_VERIFIED_FULL_NETLIST_NOT_AVAILABLE

FAILED_RECORD_PAYLOAD_RAMB18=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
WADDR_INDEX_PAYLOAD_RAMB18=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
REGADDR_INDEX_PAYLOAD_RAMB18=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
DATA_INDEX_PAYLOAD_RAMB18=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
R1H_NEW_PAYLOAD_RAMB18_TOTAL=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
FAILED_RECORD_PAYLOAD_FDRE=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
INDEX_PAYLOAD_FDRE_TOTAL=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
FAILED_RECORD_PAYLOAD_RAM64M=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
FAILED_RECORD_PAYLOAD_RAMD64E=NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN

FULL_CLEAN_BUILDS=1
SYNTHESIS_RUNS=0
POST_SYNTH_SLICE_LUTS=NOT_AVAILABLE
POST_SYNTH_LOGIC_LUTS=NOT_AVAILABLE
POST_SYNTH_SLICE_REGISTERS=NOT_AVAILABLE
POST_SYNTH_RAMB18=NOT_AVAILABLE
POST_SYNTH_RAMB36=NOT_AVAILABLE
POST_SYNTH_RESOURCE_MARGIN_GATE=NOT_RUN
OPT_DESIGN=NOT_RUN
PLACE=NOT_RUN
ROUTE=NOT_RUN
ROUTE_ERRORS=NOT_AVAILABLE
WNS=NOT_AVAILABLE
WHS=NOT_AVAILABLE
DRC_ERRORS=NOT_AVAILABLE
DRC_CRITICAL_WARNINGS=NOT_AVAILABLE
REQP_1839_SEMANTIC_COUNT=NOT_AVAILABLE
CDC_CRITICAL=NOT_AVAILABLE
CDC_UNKNOWN=NOT_AVAILABLE
SOURCE_COMMIT_TO_BIT_PROVENANCE=NOT_APPLICABLE_NO_BIT

TERMINAL_BUILD_STAGE=PROJECT_SETUP
TERMINAL_CLASSIFICATION=BLOCKED_ONE_CLEAN_BUILD_PROJECT_SETUP_COMPILE_ORDER_ASSERTION
BUILD_RETRY_AUTHORIZED=NO
BUILD_RETRY_RUN=NO
HARDWARE_ELIGIBLE=NO
PAIR_COUNT_VALID=0
BOOTSTRAP_RUN=NO
BOOTSTRAP_RESULT=NOT_RUN_BUILD_BLOCKED
ARM_A_PROGRAMS=0
ARM_B_PROGRAMS=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
FORMAL_PHASE2_FRESHLY_RECONFIRMED=NO
FINAL_FORMAL_IDENTITY=NOT_FRESHLY_VERIFIED
FINAL_DIAGNOSTIC_MAGIC=NOT_FRESHLY_VERIFIED
FINAL_PINNED_DRIVER_LOADED=NOT_FRESHLY_VERIFIED
FINAL_DONE=NOT_FRESHLY_VERIFIED
```

Final audit decision:

```text
INDEPENDENT_TERMINAL_SEALING_AUDIT=PASS
EVIDENCE_INCONSISTENCY=NO_FOR_COMMIT_TREE_MANIFEST_SENTINEL_SESSION_AND_COUNTERS
ONE_BUILD_LIMIT_EXHAUSTED=YES
SOURCE_FIX_AFTER_BUILD_START=0
SECOND_SOURCE_COMMIT=0
SECOND_BUILD=0
HARDWARE_ACTIONS=0
AUTHORIZED_NEXT_ACTION=SEAL_REPORT_AND_PUBLISH_AVAILABLE_EVIDENCE_THEN_HARD_STOP
```
