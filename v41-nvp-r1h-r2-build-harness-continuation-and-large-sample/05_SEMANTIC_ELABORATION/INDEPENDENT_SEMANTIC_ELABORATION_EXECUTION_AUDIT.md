# Independent execution audit — R1h-R2 semantic elaboration P4

Audit time: `2026-08-25T10:12:14.6886092+02:00`

## Scope and identity

FACT: this report audits the already completed, one-shot `run_01`. The audit
did not invoke `xvhdl`, `xvlog`, `xelab`, `xsim`, Vivado, synthesis,
optimization, implementation, checkpoint, or bitstream commands. It did not
modify the scientific source, runner, or task ledgers.

| Field | Exact value |
|---|---|
| Task | `V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION` |
| Scientific source commit | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` |
| Scientific source tree | `161e561f007912d73dba93c5ecd78e3cc3a6955b` |
| Canonical runner SHA-256 | `265EEA66ED9FA585BD0E8D5DD913492A65AF46983CA4FECD9E5A2653E6E79546` |
| Top | `ahd_capture_top_xdma` |
| Part context | `xc7a35tcsg325-2` |
| Simulator | Vivado Simulator `2025.2` |
| Build context | `6299465` |

FACT: the current source repository remains at the exact commit/tree and has an
empty `git status --porcelain=v1 --untracked-files=all` result after the run.

## One-shot process and invocation proof

NETLIST-INDEPENDENT FACT: `SEMANTIC_PREFLIGHT_STARTED.txt` records exactly one
preflight, exact source identity, exact top/part context, and Vivado
`2025.2 / 6299465`.

FACT: `run_01` contains exactly three `*.command.txt`, three `*.exit.txt`, and
three `*.log` files. Their names are exactly `xvhdl`, `xvlog`, and `xelab`.
There is no fourth command receipt.

| Tool | Exact executable | Executable input contract | Exit |
|---|---|---|---:|
| `xvhdl` | `C:\AMDDesignTools\2025.2\Vivado\bin\xvhdl.bat` | `--work work`, exact four production VHDL files | `0` |
| `xvlog` | `C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat` | `--sv --work work`, exact 17 production SV files, accepted XDMA stub, installed `glbl.v` | `0` |
| `xelab` | `C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat` | exact top plus `glbl`, `-L xpm`, `-L unisims_ver`, exact snapshot | `0` |

FACT: the logs independently contain exactly four VHDL analysis records and
nineteen SystemVerilog analysis records: 17 production sources plus the two
authorized simulation-support inputs.

FACT: no process matching the canonical runner or semantic snapshot remained
active at audit time. The final result receipt records `PROCESS_EXIT_CODE=0`.

FACT: no synthesis, optimization, placement, routing, checkpoint, DCP, or
bitstream artifact exists under `run_01`. The `xsim.dir` hierarchy is the normal
snapshot output of `xelab`; no `xsim` command receipt, log, or process exists.

## Exact artifact reconciliation

The final receipt is a well-formed, duplicate-free `KEY=VALUE` file:

```text
RESULT_ROWS=58
RESULT_UNIQUE_KEYS=58
RESULT_DUPLICATES=0
RESULT_MALFORMED=0
RESULT_SHA256=95A60F11432DA014AAF4B63989AFCF1FFD217139D8B979BB50CFD67EE1B1BDFD
```

All 54 independently enumerated mandatory identity, source-count,
normalization, library, binding, invocation, forbidden-command, and PASS/result
fields match their exact expected values. Mismatch count: `0`.

| Artifact | Exact SHA-256 | Receipt agreement |
|---|---|---|
| `xvhdl.log` | `170984017B7C91FB1FBA0C738693337D3BF647EFD4483DC5A45C1272144CE566` | PASS |
| `xvlog.log` | `47BF368FC25D89165C65F2A19EA4726B4D05E1F5F89C02C1FF907B0690B7D9A2` | PASS |
| `xelab.log` | `B050010614721F9BA14FED94561647A1F1694E02C388EA594027DDB8F3C2961B` | PASS |
| `SEMANTIC_INPUT_SHA256.csv` | `3BD47D6A84C8A9FC2DABE2E5079F048EF5DBCC2E7BF419AD4676B406556011E3` | PASS |
| `DRY_RUN_DUPLICATE_NORMALIZATION_AUDIT.txt` | `3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F` | PASS |

For completeness, the exact command-receipt SHA-256 values are:

```text
XVHDL_COMMAND_SHA256=390103E607A274B2015F25CDF2DCD35B2F60DC43E18CE2AED36278314A9987C6
XVLOG_COMMAND_SHA256=719EDA853D792416B16FFEE2B33DA16286ACD0BE406AC46C03008CBEDC29B3A7
XELAB_COMMAND_SHA256=AE31BCF07726CA18C7083B4E70F4F2CD505C44EB311BBEB8F4A44699EDCE21D9
```

## Log diagnostics and binding audit

NETLIST-DERIVED FACT: the combined three frontend logs contain:

```text
ERROR=0
FATAL=0
SEVERITY_FAILURE=0
DOLLAR_FATAL=0
BLACKBOX=0
UNRESOLVED=0
CANNOT_FIND_MODULE_OR_ENTITY=0
MODULE_OR_ENTITY_NOT_FOUND=0
NOT_BOUND=0
FAILED_TO_BIND=0
```

NETLIST-DERIVED FACT: `xelab.log` contains exactly one occurrence of every
required binding/snapshot marker:

- `work.r1h_probe_index_bram_store_*`;
- `work.nvp_i2c_tri_phase_probe_*`;
- `work.v41_r1f_failed_txn_logger_*`;
- `work.v41_r1h_mmio_read_service`;
- `work.xdma_v41_m1`;
- `work.ahd_capture_top_xdma`;
- `Built simulation snapshot r1h_r2_semantic_snapshot`.

NETLIST-DERIVED FACT: XPM memory elaboration is visible, including three
`xpm_memory_sdpram` compilation markers. This is a binding result, not a
full-top physical RAMB18 mapping claim.

FACT: `xelab` emitted 47 warnings, all code `VRFC 10-8759`, all confined to
the unchanged `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` array-bound diagnostics.
The accepted historical R1h exact-top `xelab_v2.log` has the same 47 warning
lines; independent multiset comparison found zero difference. No warning is an
unresolved unit, black box, binding failure, or error.

## Source pre/post integrity

SOURCE-DERIVED FACT: `SEMANTIC_INPUT_SHA256.csv` contains exactly 23 inputs:

```text
PRODUCTION_VHDL=4
PRODUCTION_SYSTEMVERILOG=17
SIMULATION_SUPPORT=2
```

FACT: independent post-run rehash of every recorded input, including exact
byte length and SHA-256, found `0` mismatches. This independently corroborates
the runner's own prehash/post-rehash gate.

FACT: exact source commit/tree and clean worktree status remain unchanged after
elaboration. Therefore no R1h RTL, XDC, XCI, test, or host source mutation was
introduced by P4.

## Result-field gate

The final receipt states, and the raw logs/artifacts independently support:

```text
SEMANTIC_ELABORATION_PREFLIGHTS=1
SEMANTIC_ELABORATION=PASS
R1H_TEST_ELABORATION=PASS
PROCESS_EXIT_CODE=0
XVHDL_INVOCATIONS=1
XVLOG_INVOCATIONS=1
XELAB_INVOCATIONS=1
UNRESOLVED_MODULES=0
UNRESOLVED_BLACKBOXES=0
FAILED_RECORD_WRAPPER_BINDING=PASS
PROBE_INDEX_WRAPPER_BINDING=PASS
PROBE_CONSUMER_BINDING=PASS
MMIO_READ_SERVICE_BINDING=PASS
SYNTH_DESIGN_INVOCATIONS=0
OPT_DESIGN_INVOCATIONS=0
PLACE_DESIGN_INVOCATIONS=0
PHYS_OPT_DESIGN_INVOCATIONS=0
ROUTE_DESIGN_INVOCATIONS=0
WRITE_CHECKPOINT_INVOCATIONS=0
WRITE_BITSTREAM_INVOCATIONS=0
```

## Independent disposition

```text
INDEPENDENT_SEMANTIC_EXECUTION_AUDIT=
    PASS

SEMANTIC_ELABORATION_PREFLIGHTS=
    1

SEMANTIC_ELABORATION=
    PASS

R1H_TEST_ELABORATION=
    PASS

FRONTEND_PROCESS_EXIT_CODES=
    XVHDL_0_XVLOG_0_XELAB_0

RESULT_PROCESS_EXIT_CODE=
    0

UNRESOLVED_MODULES=
    0

UNRESOLVED_BLACKBOXES=
    0

REQUIRED_BINDINGS=
    PASS_ALL

SOURCE_PRE_POST_HASH=
    PASS_23_OF_23

SOURCE_COMMIT_TREE_CLEAN=
    PASS

SYNTHESIS_OR_IMPLEMENTATION_INVOCATIONS=
    0

NEXT_GATE_RELEASE=
    PASS
```
