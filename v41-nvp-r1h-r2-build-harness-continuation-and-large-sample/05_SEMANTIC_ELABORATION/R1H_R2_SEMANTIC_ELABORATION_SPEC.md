# R1h-R2 semantic frontend/elaboration preflight specification

## Frozen identity

| Field | Exact value |
|---|---|
| Task | `V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION` |
| Experiment / revision | `R1h` / `R2` |
| Scientific source commit | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` |
| Scientific source tree | `161e561f007912d73dba93c5ecd78e3cc3a6955b` |
| Top | `ahd_capture_top_xdma` |
| Part context | `xc7a35tcsg325-2` |
| Vivado Simulator | `2025.2`, installed under `C:\AMDDesignTools\2025.2\Vivado` |
| Vivado build context | `6299465` |
| Work library | `work` |
| Linked installed libraries | `xpm`, `unisims_ver` |

This is a simulation-frontend binding preflight. It is not synthesis and makes
no optimized-netlist, placement, routing, checkpoint, or bitstream claim. The
part is frozen as context because `xvhdl`/`xvlog`/`xelab` do not select a device.

## Exact inputs

The executable production list is exactly four VHDL files followed by seventeen
SystemVerilog files, as recorded in `R1H_R2_SEMANTIC_SOURCE_LIST.csv`. The only
additional compilation inputs are the accepted simulation-only
`xdma_v41_m1_elaboration_stub.sv` and the installed `glbl.v`.

`rtl/v41/nvp_i2c_address_probe.sv` is deliberately absent. It was present in an
older simulation helper list but is absent from the executable R1h build list
and is not instantiated by the exact R1h top. Adding it here would make this
preflight broader than the production design.

VHDL is analyzed in the installed default production-compatible mode. No
`--2008`, `-2008`, or global/file VHDL-2008 switch is used.

## Exactly-once flow

`Run-R1hR2SemanticElaboration.ps1` performs all fail-closed identity and source
checks before creating `run_01`. Once `run_01/SEMANTIC_PREFLIGHT_STARTED.txt`
exists, the script refuses a second invocation. The only frontend tool calls are:

1. one `xvhdl` analysis of the four exact VHDL files into `work`;
2. one `xvlog --sv` analysis of the seventeen exact production SystemVerilog
   files, the accepted XDMA stub, and installed `glbl.v` into `work`;
3. one `xelab` of `ahd_capture_top_xdma` and `glbl`, linked to `xpm` and
   `unisims_ver`.

No `xsim` runtime is needed. Successful static elaboration and construction of
the snapshot are the semantic binding gate.

The required preceding raw project-setup receipt is first bound to exact
SHA-256 `F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6`.
It is then parsed as exact `KEY=VALUE` records. Blank and malformed records,
contradictory duplicates, and every unexpected duplicate are rejected. The
exact raw receipt has 90 rows and 86 unique keys. Only these four keys may occur
twice, and both values must be byte-identical to the frozen value:

- `FAILED_RECORD_WRAPPER_MODULE_NAME=v41_r1f_failed_txn_logger`
- `FAILED_RECORD_WRAPPER_SOURCE_PATH=rtl/v41/r1f_failed_txn_logger.sv`
- `PROBE_INDEX_WRAPPER_MODULE_NAME=r1h_probe_index_bram_store`
- `PROBE_INDEX_WRAPPER_SOURCE_PATH=rtl/v41/r1h_probe_index_bram_store.sv`

Each allowed key must have exact multiplicity two; no other multiplicity is
accepted. Twenty-three required keys must each have the frozen value, including
source identity, Vivado identity, part/top, semantic-gate result, compile-order
policy, 6+3 source-derived bank counts, and dry-run exit status. Additional
unique, syntactically valid evidence keys produced by the exact receipt are
allowed but cannot satisfy or override a required gate. No whole-text
substring/`Contains` decision is used.

The normalization audit is emitted as a canonical LF-delimited artifact and
bound to SHA-256
`3EBF9874DBD5E78C8105173C6616F541F7F741A6729FF416D6BF52D55B743A4F`.

## Binding proof

Before any frontend call, the runner proves source-derived uniqueness:

| Construct | Declaration count | Production instantiation count | Physical instances represented |
|---|---:|---:|---:|
| `ahd_capture_top_xdma` | 1 | top | 1 |
| `r1h_probe_index_bram_store` | 1 | 1 in `nvp_i2c_tri_phase_probe` | 3 XPM banks through the exact `phase_bank < 3` generate |
| `nvp_i2c_tri_phase_probe` | 1 | 1 in the top | 1 |
| `v41_r1f_failed_txn_logger` | 1 | 1 in the top | 6 XPM banks through the exact `bank_index < 6` generate |
| `v41_r1h_mmio_read_service` | 1 | 1 in the top | 1 |
| simulation-only `xdma_v41_m1` | 1 | 1 in the top | 1 port-contract stub |

The runner also rejects every duplicate SystemVerilog module declaration across
the preflight input set and every duplicate VHDL entity/package declaration.
It rehashes every input after elaboration to prove that the analyzed files did
not change during the run.

`xelab` must then report the compiled parameterized/bound designs for both BRAM
wrappers, the tri-phase consumer, the MMIO read service, and the exact top, and
must build `r1h_r2_semantic_snapshot`. Any error, fatal diagnostic, unresolved
design unit, failed binding, or black box fails closed.

After all exact-top binding checks and the post-elaboration input rehash pass,
the result receipt and console output explicitly emit
`R1H_TEST_ELABORATION=PASS`.

The wrapper-module instantiation counts are one failed-record wrapper and one
probe-index wrapper. The architectural payload-bank counts are independently
source-derived as six and three respectively; the later full-top synthesis gate,
not this frontend preflight, must prove their RAMB18 physical mapping.

## Command-scope audit

`Test-R1hR2SemanticElaborationStatic.ps1` parses the runner as PowerShell AST
without invoking any Xilinx tool. It rejects command invocations named:

`synth_design`, `opt_design`, `place_design`, `phys_opt_design`,
`route_design`, `write_checkpoint`, `write_bitstream`, `vivado`, or `xsim`.

It also requires exactly one scripted call each for `$Xvhdl`, `$Xvlog`, and
`$Xelab`, and checks that the exact 4+17 production lists are frozen while the
stale address-probe file is excluded.

Preparation status: `STATIC_AUDIT_PASS_PREFLIGHT_NOT_EXECUTED`. The AST/parser
audit was run read-only. No `xvhdl`, `xvlog`, `xelab`, Vivado, simulation
runtime, synthesis, implementation, checkpoint, or bitstream command was run
while preparing these artifacts.
