# V41 NVP R1g VHDL compatibility and phase-complete observability final report

## Outcome

R1g achieved its language-compatibility objective but did not produce an
implementable image. The exact R1f source was recovered, the exact production
VHDL contract was derived, and the one R1f-introduced synthesis-incompatible
construct was mechanically rewritten. The rewritten design passed the exact
default non-2008 compiler, the full cross-standard equivalence suite, the
accepted R1f scoreboards and host fixtures, and the sole authorized
post-commit RTL-elaboration preflight. The former `Synth 8-2757` blocker did
not recur.

The one authorized clean build then completed synthesis and `opt_design`
without errors. Its single `place_design` invocation stopped at the placer
precondition DRC because the exact xc7a35t target lacks sufficient resources:

```text
DRC UTLZ-1: LUT as Logic       30,926 required / 20,800 available
DRC UTLZ-1: Register as FF     44,248 required / 41,600 available
DRC UTLZ-1: Slice Registers    44,248 required / 41,600 available
```

The placer did not run. There was no `phys_opt_design`, `route_design`, routed
DCP, or bitstream. The exact terminal classification is:

```text
BLOCKED_ONE_CLEAN_BUILD_PLACE_PRECONDITION_RESOURCE_OVERUTILIZATION
```

The one-build authorization was consumed. The owner contract forbids a source
correction or second build after build start, so the task stopped before the
hardware start-state gate. No JTAG, SSH, FPGA program, reboot, driver load,
MMIO, DMA, or physical action occurred in R1g.

## Frozen input and source identity

| Object | Exact identity |
|---|---|
| R1f public evidence commit | `1130c4686a7aaedcf2609dd4a5739d7a7eb73fff` |
| R1f authoritative report SHA-256 | `2F0D7997B2226C7A770F9221ED2BB095B1C2A53EB5BB74882629C5900544C09D` |
| R1f evidence package SHA-256 | `62350D80ACAA86E897E73B4DD0EFCF9D3DC34D58783DE20016790DB56F4704E4` |
| Exact R1f parent commit | `225544084dbfcaadb8592fcecc947aa1cec4970e` |
| Exact R1f parent tree | `cfde8769af95cf20586391c411fab3ddfa2c87b6` |
| R1g source commit | `e112a5addb7ac62700a9a71af81bf368fad0bada` |
| R1g source tree | `3a59ebec130103055d24a3a32ecda00dedde5534` |
| Commits above R1f | 1 |
| Owner prompt SHA-256 | `CE2F6A181E5850A3E6137569108E118847A504BEC5130B43FDD97A06FC10D618` |
| R1g prebuild manifest SHA-256 | `F31220B039E26C29C994A6F9B60A5416DE6EE0231C9C9E78CE81E013ECA473B9` |
| R1g build Tcl SHA-256 | `C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A` |

The R1g commit is one direct child of the exact R1f commit. It changes only
`rtl/nvp/nvp6134c_i2c_bringup.vhd`, with five added lines and one removed
line. The source worktree was clean at preflight and build release. Because
the diagnostic-branch push was authorized only after full build PASS, the R1g
source branch was not pushed.

## Production-language contract and compatibility correction

Installed Vivado 2025.2 build 6299465 and the exact frozen R1f build flow prove
the production contract is unqualified Vivado `FILE_TYPE=VHDL` in
`xil_defaultlib`, with no `read_vhdl -vhdl2008`, no `xvhdl --2008`, and no
`VHDL 2008` file-type override. The task records this operationally exact mode
as `VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008`; it does not invent a narrower
93-versus-2002 label not exposed by the installed interface.

The complete R1e-to-R1f VHDL changed-line inventory contains 1,278 rows across
eight files. It found exactly one production synthesis blocker: the sequential
conditional signal assignment at R1f line 994. Five other VHDL-2008 constructs
occur only in simulation testbenches and are outside the production synthesis
file list.

The sole source rewrite preserved the target, condition, values, process,
clock branch, assignment coverage, priority, width, and delta-cycle semantics:

```vhdl
if is_read_op = '0' then
  r1f_tx_wdata_r <= write_data;
else
  r1f_tx_wdata_r <= x"00";
end if;
```

Reversing that one hunk reconstructs the exact R1f source hash. No global or
file VHDL standard changed, and no scientific constant, functional FSM,
register map, record field, valid bit, probe schedule, safe target, count, or
statistical method changed.

## Compiler, equivalence, and final frontend gates

Two bounded non-synthesis compiler iterations were preserved. Iteration 1
compiled exact R1f in production mode and reproduced the expected line-994
language error. Iteration 2 compiled R1g with the same source list, libraries,
order, include context, and non-2008 contract and passed all production VHDL
files.

The complete cross-standard gate passed with zero semantic differences. It
includes cycle-by-cycle pre-init equality to R1e, byte-identical autoinit
transactions, effective open-drain arbitration equality, legacy and R1f
diagnostics, 16-bit transaction serial index 300, failed-log capacity 64 and
overflow at 65, all phase and transaction-kind cases, the operation-86-like
bank context, the full tri-phase probe suite, safe-target setup/restoration,
the formal-zero model, and the accepted host fixtures. The consolidated gate
SHA-256 is
`AD1B793125EAD205CB9681828452736154DADBBEA26166C7ECFF245EB87991D5`.

The single post-commit RTL-only preflight used the exact production frontend,
top, part, sources, libraries, order, XCI, XDC, and generics. It invoked one
`synth_design -rtl`, exited zero, elaborated `ahd_capture_top_xdma`, and
reported zero `Synth 8-2757` or unsupported-language errors. It invoked no
optimization, placement, routing, checkpoint, or bitstream command.

## Sole clean-build evidence

The build sentinel was atomically created once before project creation and is
bound to the exact R1g commit/tree, prebuild manifest, build script, and Vivado
identity. The full build used part `xc7a35tcsg325-2`, top
`ahd_capture_top_xdma`, the unchanged XDMA XCI and XDC set, the unchanged
production VHDL contract, and `BUILD_FLAGS=0x00000002`.

Full synthesis completed successfully with zero errors and zero critical
warnings. It generated a synthesis-only DCP with SHA-256
`DB9FE5C96D3AA42EE43AAB6396E2FBEB1E75335463DFEC4B259EA242C320B34B`.
`opt_design -directive Explore` also completed successfully. The only
`place_design -directive Explore` invocation then failed its DRC precondition:
the design requires 10,126 more LUT-as-logic cells than the device provides
and 2,648 more flip-flop/slice-register cells than it provides. These
requirements are 148.68% and 106.37% of the respective available resources.

The terminal failure receipt SHA-256 is
`446B6468DAE7EB456D0477A21DF465925CB963714C285E664F8A43A3188728A7`,
and the final Vivado log SHA-256 is
`9156A7DA638ADAE8D015F4BADFBF0A4A86D6BBFC3718F92FD7C5AF8BF7C4B42E`.
The independent terminal audit SHA-256 is
`84CE35A9FEA0C7D0BC8B4CAD01D169BA049368AC0C44CCDB21827234A1D9E444`.

This result proves the mechanical VHDL correction cleared the known frontend
blocker. It also proves that the complete frozen R1f/R1g diagnostic design, as
synthesized for the exact xc7a35t, cannot pass the placement resource gate.
It does not authorize reducing instrumentation or changing the target device.

## Routed-impact and hardware gates

The routed-impact comparison was correctly not run because no R1g routed DCP
exists. Its NOT-RUN receipt SHA-256 is
`F25279E28DD6530E8270BBA922F61C95D267DD611473B6F40D689421147552D5`.
The exact R1e routed DCP was independently reverified at
`1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1`,
but no physical R1g comparison is possible.

The hardware toolchain remained fail-closed. The independent hardware release
audit verified all inherited and task-local tool hashes, the frozen
`A1 -> B1 -> A2 -> B2 -> A3 -> B3` order, the exact
`33.536673744`-second Arm-A wait, the selected JTAG/formal/driver identities,
and the seven-program maximum. It also proved there was no active R1g binding,
no live precheck, and zero hardware or prohibited actions. Its SHA-256 is
`386DF590AE6C945FE398AB8003D5A3717C1CEB1B421609B51B090BB640563CCC`.

The formal Phase-2 identity, diagnostic magic, pinned driver, and DONE values
below are the preserved R7 terminal context. They were not freshly
reconfirmed in R1g and were not used to release hardware.

## Scientific status and interpretation

No R1g bitstream or R1g hardware sample exists. Therefore no A/B pair,
autoinit phase rate, post-init phase process, bank-invariant hardware result,
failed-transaction distribution, or replicate statistic was evaluated. All
such fields remain explicitly NOT RUN or NOT MEASURED; none is converted to
zero or PASS.

The R1f/R1g offline audit still supports the historical classification of R7
operation 86 as legal transitional context in the exact source. That source
classification is not a new R1g hardware observation. The placement-capacity
failure is an implementation feasibility result and provides no evidence for
an NVP electrical or analog root cause.

## Accounting and publication contract

Exactly one R1g source commit, two non-synthesis compiler iterations, one
final RTL-elaboration preflight, one clean build, one synthesis run, and one
implementation run were consumed. The implementation run reached successful
`opt_design` and one failed `place_design` precondition. Bitstreams generated,
programs, reboots, driver loads, retries, writes, DMA transfers, physical
actions, and formal-repository mutations all remain zero.

The evidence package identity and public repository identity are kept in
external non-circular sidecars and a publication receipt. The terminal block
therefore uses explicit external-receipt references for the three values that
cannot be self-embedded without changing the report or package identity.

```text
TASK=
    V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY

EXPERIMENT_NAME=
    R1g

R1F_EVIDENCE_COMMIT=
    1130c4686a7aaedcf2609dd4a5739d7a7eb73fff

R1F_EVIDENCE_PACKAGE_SHA256=
    62350D80ACAA86E897E73B4DD0EFCF9D3DC34D58783DE20016790DB56F4704E4
R1F_AUTHORITATIVE_REPORT_SHA256=
    2F0D7997B2226C7A770F9221ED2BB095B1C2A53EB5BB74882629C5900544C09D

R1F_SOURCE_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1F_SOURCE_TREE=
    cfde8769af95cf20586391c411fab3ddfa2c87b6

R1F_TERMINAL_CLASSIFICATION=
    BLOCKED_ONE_CLEAN_BUILD_SYNTHESIS_VHDL_2008_CONSTRUCT

R1F_TERMINAL_FILE=
    rtl/nvp/nvp6134c_i2c_bringup.vhd

R1F_TERMINAL_LINE=
    994

R1F_TERMINAL_CONSTRUCT=
    SEQUENTIAL_CONDITIONAL_SIGNAL_ASSIGNMENT

R1F_TERMINAL_BUILD_LOG_SHA256=
    43C05651BEFA0DB30E00B7B16058D424AFEF38FEA2D0E15A9AF0381604A7E4D0

PRODUCTION_VHDL_STANDARD=
    VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008
GLOBAL_VHDL_STANDARD_CHANGE=
    NO

VHDL2008_CONSTRUCTS_FOUND=
    6_TOTAL_1_PRODUCTION_5_TESTBENCH_ONLY
VHDL2008_CONSTRUCTS_REWRITTEN=
    1
R1G_COMPATIBILITY_REWRITE_FILES=
    rtl/nvp/nvp6134c_i2c_bringup.vhd
R1G_COMPATIBILITY_REWRITE_COUNT=
    1

KNOWN_LINE_994_REWRITE=
    PASS_IF_ELSE_EQUIVALENT

R1G_SOURCE_CHANGE_CLASS=
    VHDL_LANGUAGE_COMPATIBILITY_ONLY

R1G_FUNCTIONAL_RTL_CHANGE=
    NO

R1G_DIAGNOSTIC_SEMANTICS_CHANGE=
    NO

R1G_SCIENTIFIC_PARAMETER_CHANGE=
    NO

R1F_TO_R1G_SEMANTIC_DIFFERENCES=
    0

NON_SYNTHESIS_LANGUAGE_COMPILE_ITERATIONS=
    2
EXACT_PRODUCTION_MODE_VHDL_COMPILE=
    PASS_ALL_FILES
FINAL_RTL_ELABORATION_PREFLIGHTS=
    1
FINAL_RTL_ELABORATION=
    PASS
SYNTH_8_2757_COUNT=
    0

R1G_PARENT_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e

R1G_SOURCE_COMMIT=
    e112a5addb7ac62700a9a71af81bf368fad0bada
R1G_SOURCE_TREE=
    3a59ebec130103055d24a3a32ecda00dedde5534
R1G_BIT_SHA256=
    NOT_GENERATED
R1G_ROUTED_DCP_SHA256=
    NOT_GENERATED

FULL_CLEAN_BUILDS=
    1

FULL_SYNTHESIS=
    PASS
PLACE=
    NOT_RUN_RESOURCE_OVERUTILIZATION_DRC
ROUTE=
    NOT_RUN_PLACE_GATE_FAILED
ROUTE_ERRORS=
    NOT_EVALUATED_ROUTE_NOT_RUN
WNS=
    NOT_EVALUATED_NO_ROUTED_DESIGN
WHS=
    NOT_EVALUATED_NO_ROUTED_DESIGN
DRC_ERRORS=
    3_AT_PLACE_PRECONDITION
DRC_CRITICAL_WARNINGS=
    0
REQP_1839_SEMANTIC_COUNT=
    NOT_EVALUATED_ROUTE_NOT_RUN
CDC_CRITICAL=
    NOT_EVALUATED_ROUTE_NOT_RUN
CDC_UNKNOWN=
    NOT_EVALUATED_ROUTE_NOT_RUN
SOURCE_COMMIT_TO_BIT_PROVENANCE=
    NOT_APPLICABLE_NO_BITSTREAM

SAFE_DATA_PROBE_TARGET=
    PASS_BANK00_REG85_DATA00

R1G_TRANSACTION_INDEX_WIDTH=
    16

R1G_FAILED_TXN_LOG_CAPACITY=
    64

R1G_FAILED_TXN_RECORD_WIDTH=
    192

R1G_PROBE_PHASES=
    WADDR_REGADDR_DATA

R1G_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=
    10000

PAIR_COUNT_PLANNED=
    3

PAIR_COUNT_VALID=
    0

BOOTSTRAP_RUN=
    NO_BUILD_GATE_FAILED_BEFORE_HARDWARE
BOOTSTRAP_RESULT=
    NOT_RUN

A1_RESULT=
    NOT_RUN_BUILD_GATE_FAILED_BEFORE_HARDWARE
A1_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_MEASURED
A1_AUTOINIT_WADDR_NACKS=
    NOT_MEASURED
A1_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_MEASURED
A1_AUTOINIT_REGADDR_NACKS=
    NOT_MEASURED
A1_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_MEASURED
A1_AUTOINIT_DATA_NACKS=
    NOT_MEASURED
A1_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_MEASURED
A1_AUTOINIT_RADDR_NACKS=
    NOT_MEASURED
A1_FAILED_TXN_TOTAL=
    NOT_MEASURED
A1_FAILED_TXN_STORED=
    NOT_MEASURED
A1_FAILED_TXN_OVERFLOW=
    NOT_MEASURED
A1_BANK_INVARIANT_ERRORS=
    NOT_MEASURED
A1_PROBE_WADDR_NACKS=
    NOT_MEASURED
A1_PROBE_REGADDR_NACKS=
    NOT_MEASURED
A1_PROBE_DATA_NACKS=
    NOT_MEASURED
A1_PROBE_TIMEOUTS=
    NOT_MEASURED
A1_NVP_RESULT=
    NOT_RUN

B1_NACK_COUNT=
    NOT_MEASURED
B1_NACK_LOG_COUNT=
    NOT_MEASURED
B1_NACK_LOG_OVERFLOW=
    NOT_MEASURED
B1_NVP_RESULT=
    NOT_RUN

A2_RESULT=
    NOT_RUN_BUILD_GATE_FAILED_BEFORE_HARDWARE
A2_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_MEASURED
A2_AUTOINIT_WADDR_NACKS=
    NOT_MEASURED
A2_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_MEASURED
A2_AUTOINIT_REGADDR_NACKS=
    NOT_MEASURED
A2_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_MEASURED
A2_AUTOINIT_DATA_NACKS=
    NOT_MEASURED
A2_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_MEASURED
A2_AUTOINIT_RADDR_NACKS=
    NOT_MEASURED
A2_FAILED_TXN_TOTAL=
    NOT_MEASURED
A2_FAILED_TXN_STORED=
    NOT_MEASURED
A2_FAILED_TXN_OVERFLOW=
    NOT_MEASURED
A2_BANK_INVARIANT_ERRORS=
    NOT_MEASURED
A2_PROBE_WADDR_NACKS=
    NOT_MEASURED
A2_PROBE_REGADDR_NACKS=
    NOT_MEASURED
A2_PROBE_DATA_NACKS=
    NOT_MEASURED
A2_PROBE_TIMEOUTS=
    NOT_MEASURED
A2_NVP_RESULT=
    NOT_RUN

B2_NACK_COUNT=
    NOT_MEASURED
B2_NACK_LOG_COUNT=
    NOT_MEASURED
B2_NACK_LOG_OVERFLOW=
    NOT_MEASURED
B2_NVP_RESULT=
    NOT_RUN

A3_RESULT=
    NOT_RUN_BUILD_GATE_FAILED_BEFORE_HARDWARE
A3_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_MEASURED
A3_AUTOINIT_WADDR_NACKS=
    NOT_MEASURED
A3_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_MEASURED
A3_AUTOINIT_REGADDR_NACKS=
    NOT_MEASURED
A3_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_MEASURED
A3_AUTOINIT_DATA_NACKS=
    NOT_MEASURED
A3_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_MEASURED
A3_AUTOINIT_RADDR_NACKS=
    NOT_MEASURED
A3_FAILED_TXN_TOTAL=
    NOT_MEASURED
A3_FAILED_TXN_STORED=
    NOT_MEASURED
A3_FAILED_TXN_OVERFLOW=
    NOT_MEASURED
A3_BANK_INVARIANT_ERRORS=
    NOT_MEASURED
A3_PROBE_WADDR_NACKS=
    NOT_MEASURED
A3_PROBE_REGADDR_NACKS=
    NOT_MEASURED
A3_PROBE_DATA_NACKS=
    NOT_MEASURED
A3_PROBE_TIMEOUTS=
    NOT_MEASURED
A3_NVP_RESULT=
    NOT_RUN

B3_NACK_COUNT=
    NOT_MEASURED
B3_NACK_LOG_COUNT=
    NOT_MEASURED
B3_NACK_LOG_OVERFLOW=
    NOT_MEASURED
B3_NVP_RESULT=
    NOT_RUN

POSTINIT_WADDR_PROCESS=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE
POSTINIT_REGADDR_PROCESS=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE
POSTINIT_DATA_PROCESS=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE

AUTOINIT_PHASE_RATE_HETEROGENEITY=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE
AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE
R1G_REPLICATE_HOMOGENEITY=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE

BANK_TRACKER_COHERENCE=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE
R7_OPERATION_86_SEMANTICS=
    LEGAL_TRANSITIONAL_CONTEXT_FROM_EXACT_SOURCE_AUDIT
FAILED_TRANSACTION_DISTRIBUTION=
    NOT_EVALUATED_NO_R1G_HARDWARE_SAMPLE

PAIRED_AB_RESULT=
    NOT_RUN_BUILD_GATE_FAILED_AT_PLACE_RESOURCE_OVERUTILIZATION

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

FINAL_FORMAL_IDENTITY=
    A40A0C07 / 0000400B / 00031002_R7_RECORDED_NOT_R1G_FRESHLY_RECONFIRMED
FINAL_DIAGNOSTIC_MAGIC=
    0_R7_RECORDED_NOT_R1G_FRESHLY_RECONFIRMED
FINAL_PINNED_DRIVER_LOADED=
    YES_R7_RECORDED_NOT_R1G_FRESHLY_RECONFIRMED
FINAL_DONE=
    1_R7_RECORDED_NOT_R1G_FRESHLY_RECONFIRMED

CONDITIONAL_FORMAL_BOOTSTRAP_PROGRAMS=
    0
ARM_A_PROGRAMS=
    0
ARM_B_PROGRAMS=
    0
FPGA_PROGRAM_INVOCATIONS=
    0
WARM_REBOOTS=
    0
DRIVER_LOADS=
    0

PROGRAM_RETRIES=
    0

COLD_STARTS=
    0

PHYSICAL_ACTIONS=
    0

JTAG_FREQUENCY_CHANGES=
    0

PCI_REMOVE_RESCAN_RESETS=
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

OWNER_PROMPT_SHA256=
    CE2F6A181E5850A3E6137569108E118847A504BEC5130B43FDD97A06FC10D618
EVIDENCE_PACKAGE_SHA256=
    SEE_EXTERNAL_NONCIRCULAR_SHA256_SIDECAR
EVIDENCE_REPOSITORY_COMMIT=
    SEE_EXTERNAL_PUBLICATION_RECEIPT
PUBLIC_REMOTE_VERIFICATION=
    SEE_EXTERNAL_PUBLICATION_RECEIPT
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_R1G_RESULTS
```
