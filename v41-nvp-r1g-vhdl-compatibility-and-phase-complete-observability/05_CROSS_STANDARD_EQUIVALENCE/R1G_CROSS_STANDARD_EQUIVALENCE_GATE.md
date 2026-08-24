# R1g cross-standard semantic-equivalence gate

## Outcome

The exact R1f VHDL-2008 simulation reference and the one-rewrite R1g
production-language candidate are semantically equivalent over the complete
accepted R1f verification scope. Five isolated reference/candidate VHDL pairs
passed, including exact normalized VCD equality for every captured top-level
observable in the integrated autoinit, D2b, power-timing, and transaction-
serial tests. The dedicated pre-init test passed its internal cycle-by-cycle
R1e reference assertions in both language modes at the same terminal cycle.

The unchanged SystemVerilog components, register map, tri-phase probe, and
host/reference-model tools were separately hash-proven byte-identical between
the two worktrees and freshly rerun: 11 focused RTL cases and 24 host/model
fixtures all passed.

```text
R1F_VHDL2008_REFERENCE_SIMULATION=PASS
R1G_PRODUCTION_STANDARD_SIMULATION=PASS
CYCLE_BY_CYCLE_ALL_OUTPUT_EQUIVALENCE=PASS
R1F_TO_R1G_SEMANTIC_DIFFERENCES=0
P5_CROSS_STANDARD_EQUIVALENCE_GATE=PASS
```

## Exact source and language identities

```text
R1F_SOURCE_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1F_SOURCE_TREE=cfde8769af95cf20586391c411fab3ddfa2c87b6
R1F_REFERENCE_WORKTREE_CLEAN=YES
R1F_BRINGUP_SHA256=A2865C428B89E9492BB1D62144963558805B036F1A1212C09F968D6059AE9533

R1G_CANDIDATE_PARENT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1G_CANDIDATE_DIFF_FILES=rtl/nvp/nvp6134c_i2c_bringup.vhd
R1G_CANDIDATE_BRINGUP_SHA256=66776D2A97E5DA43446AFEF4DAFF7A3E1B6A5952AC21036B86D18DB01E0F6024
R1G_CANDIDATE_CHANGE=R1F_LINE_994_CONDITIONAL_ASSIGNMENT_TO_COMPLETE_IF_ELSE_ONLY

R1F_REFERENCE_DESIGN_LANGUAGE_MODE=XVHDL_EXPLICIT_2008_ACCEPTED_R1F_MODE
R1G_CANDIDATE_DESIGN_LANGUAGE_MODE=XVHDL_DEFAULT_NON_2008
PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008
GLOBAL_VHDL_STANDARD_CHANGE=NO
FILE_TYPE_VHDL2008_CHANGES=0
READ_VHDL_VHDL2008_OPTION_ADDED=NO
```

The production-language contract is bound by
`02_LANGUAGE_CONTRACT/PRODUCTION_LANGUAGE_CONTRACT.md` SHA-256
`7244E246F127BD401B68746663FD7177C8E28D74F7702156C003D8039A6AEAD5`
and `EXACT_COMPILE_ORDER.txt` SHA-256
`1B0472FBF78388C4608C05C39E0E9289305EB6F64A0AFE98B2326657C71A1581`.
The candidate's prior exact production-mode compiler log is SHA-256
`FC8DCBE32BBAA99E92EF03BE903E123C23EE1A6657BE592181BC620A40D6CDB6`
and records `PASS_ALL_FILES` with no unresolved VHDL-2008 construct.

## Paired method

Each VHDL pair used a fresh isolated simulation directory and library, the
same testbench source, identical default generics and identical stimuli. R1f
design units were analyzed with explicit `--2008`; R1g design units were
analyzed without `--2008` or any relaxation option. Testbenches retained their
accepted simulation language mode and do not change the production-source
language contract.

For VCD-bearing tests, the comparison captured every object directly under
the testbench top. The normalizer removed only the nondeterministic VCD
`$date` block. It did not remove signal declarations, values, event times,
delta ordering, or any other waveform content. Equal normalized SHA-256
therefore proves exact equality over the captured observable traces.

For the pre-init test, each design variant additionally compiled the exact
R1e source into a separate `r1e_ref` library. The testbench itself compared
the reference and candidate cycle by cycle through the original terminal
`init_done`; a normalized terminal transcript comparison then required both
language-mode runs to emit the same assertions at the same time.

Captured command records prove zero candidate-design `--2008` uses. The
separate `FORBIDDEN_COMMAND_AUDIT.txt` proves this phase invoked no synthesis,
optimization, placement, routing, checkpoint, or bitstream command.

## Direct cross-standard results

| Pair | Compared surface | Exact result |
|---|---|---|
| Transaction serial | 7 top-level variables; 29,452 bytes per VCD | normalized VCD SHA `343DF81AD146D259205A7C29B38BF5FAC0B6E6BAAAC08680687210439AFB1FD3`; PASS |
| Integrated autoinit matrix | 67 top-level variables; 240,273,754 bytes per VCD | normalized VCD SHA `EB9EBD6D242B778766D6CB22F4469B1EB4B49780241F325F2954DCE3326E8378`; PASS |
| Inherited D2b sequence | 52 top-level variables; 8,825,939 bytes per VCD | normalized VCD SHA `CF83CE9B40854234651C05FCC39599022263D25D1EBC1A306AF4DA7390F1F877`; PASS |
| Inherited power timing | 13 top-level variables; 6,062 bytes per VCD | normalized VCD SHA `CF687CCCB338B2C71234753477BF0B3B15DBDDF6B4DAFBF6FC2134AEDC88C56C`; PASS |
| Pre-init R1e equivalence | internal cycle-by-cycle assertions plus terminal transcript | all three assertions at `2121355816 ns`; normalized transcript SHA `850532A5AF3C9776856253D3A3DF5C2A52CD7322F0D78A54D69D2FE6B928AE7C`; PASS |

The integrated 67-variable trace includes clocks and bus samples; original
SCL/SDA release requests; busy/done/error; legacy state, phase, transaction,
first-error, aggregate-counter and first-eight-log signals; all R1f phase and
transaction counters; the 16-bit serial; the 192-bit failed-transaction
record and valid pulse; and all bank-invariant outputs. The integrated
testbench also terminally passed its exact 13-, 15-, and 36-event patterns,
all four isolated ACK-phase failures, every transaction kind, operation-86
transitional context, phase/counter scoreboards, and legacy-first-eight
reconciliation in both language modes.

Exact pair receipt SHA-256 values are:

```text
SERIAL_PAIR_RECEIPT_SHA256=C4894AAFF7D10B187BF4E1F614A3413003763E2541F73F0C1FA559308CD4AD1B
AUTOINIT_PAIR_RECEIPT_SHA256=B8447E63CB87371D800DF3FE473A278ADA946A60E38326D9ECA605E529945600
D2B_PAIR_RECEIPT_SHA256=0D068D8278BC401E196262FF98B7BA0252040B93C0B29F5274A382DA9FC78DEC
POWER_PAIR_RECEIPT_SHA256=05201CFDD23BD62E83715A8A6BF9DBF82008B7A2D4FF6CB3D47100468A275F8F
PREINIT_PAIR_RECEIPT_SHA256=05406B7FCA46B3BF4017E199F348EBD64CE15E7422376750604EC3F1E09C8B72
```

## Fresh unchanged-component and host matrix

The reference/candidate SHA-256 inventory covers 18 unchanged component,
testbench, decoder, statistics, and fixture sources. Every entry is byte-
identical. The inventory SHA-256 is
`6A05E4637C3FD7CE3BBCFF87DF71BFB3C9B0544317EC7DB320A8686B2C6BB2B7`.

The fresh candidate matrix passed:

- effective pre-init open-drain arbitration;
- failed-transaction logger chronology, immutability, exact capacity 64 and
  overflow on event 65;
- complete measurement-register decode and deterministic formal zero for all
  1,368 DWORDs in the R1f range;
- tri-phase main, abort/restore, timeout, attempt-limit, secondary-restoration
  failure, index-overflow, and idle-timeout cases;
- the exact production timing model and frozen
  `ARM_A_REQUIRED_WAIT_SECONDS=33.536673744`;
- all 24 decoder, statistics, and tri-phase reference-model fixtures.

```text
COMPONENT_MATRIX_RESULT=PASS_ALL
SYSTEMVERILOG_CASES_PASS=11
HOST_TOOL_FIXTURES=PASS_24_OF_24
COMPONENT_MATRIX_RECEIPT_SHA256=C2851D45025156F1A7A4FE68E39EDCC32094FE95A2876C66D31A9EAE49630D43
HOST_FIXTURE_LOG_SHA256=1C8EF038414DA5FE1D8E8D69A1CD07899ABE733E976BB4F0681D549A24312894
```

This preserves the accepted R1f verification split: focused current RTL
proves protocol, counting, restoration, map and overflow mechanics; the
production-sized 29/10000, independent-Bernoulli, clustered, and 512-entry
distribution cases remain executable reference-model fixtures. This gate does
not relabel those accepted model cases as synthesized-RTL executions.

## Preserved harness iterations

Two task-local harness defects were preserved and corrected without a source
change:

1. The initial serial attempt did not simulate because a backslash-containing
   Tcl path was interpreted as escapes. Its classification receipt SHA-256 is
   `111C0C2327B4F3C3D1195A31BEEB04A51FCA90DB91EFB40B7FEB4134754CA125`.
2. The first executed serial pair passed both simulations, but the initial
   transcript normalizer retained the expected R1f/R1g source-root difference
   after an identical stop time. Its classification receipt SHA-256 is
   `BBA795201BF15A38A56DA586A3D34E489F4647B2BA705C55749E98C2371D16A4`.

Neither event was a semantic failure, invoked synthesis, or caused an RTL
edit. The passing comparator removes only source-path text from stop-line
normalization; the VCD comparison is independent and removes only `$date`.

## Required P5 release assignments

```text
R1F_VHDL2008_REFERENCE_SIMULATION=PASS
R1G_PRODUCTION_STANDARD_SIMULATION=PASS

CYCLE_BY_CYCLE_ALL_OUTPUT_EQUIVALENCE=PASS
R1F_TO_R1G_SEMANTIC_DIFFERENCES=0

LEGACY_FIRST8_RECONCILIATION=PASS
PRE_INIT_DONE_CYCLE_EQUIVALENCE_TO_R1E=PASS
AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
AUTOINIT_FUNCTIONAL_STATE_SEQUENCE_IDENTICAL=YES

PHASE_OPPORTUNITY_COUNTERS_MATCH_SCOREBOARD=PASS
FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD=PASS
BANK_BEFORE_AFTER_SEMANTICS=PASS
TRANSACTION_INDEX_16_UNIQUE=PASS
TRI_PHASE_PROBE_SCOREBOARD=PASS_COMBINED_FOCUSED_RTL_AND_FROZEN_REFERENCE_MODEL
SAFE_TARGET_RESTORATION=PASS
FORMAL_COMPLETE_R1F_RANGE_ZERO=PASS_ALL_1368_DWORDS

R1G_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0
R1G_FUNCTIONAL_RTL_CHANGE=NO
R1G_DIAGNOSTIC_SEMANTICS_CHANGE=NO
R1G_SCIENTIFIC_PARAMETER_CHANGE=NO

EXACT_PRODUCTION_MODE_VHDL_COMPILE=PASS_ALL_FILES
UNRESOLVED_VHDL2008_CONSTRUCTS=0

SYNTH_DESIGN_INVOKED=NO
IMPLEMENTATION_INVOKED=NO
BITSTREAM_WRITTEN=NO

P5_CROSS_STANDARD_EQUIVALENCE_GATE=PASS
NEXT_GATE=P6_CREATE_ONE_R1G_SOURCE_COMMIT
```
