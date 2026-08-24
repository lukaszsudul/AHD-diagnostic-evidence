# R1f one-build script independent static audit

## Identity and result

~~~text
SCRIPT=
    C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\scripts\v41\r1f_build.tcl
SCRIPT_SHA256=
    53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B
SCRIPT_BYTES=52458
TCL_INFO_COMPLETE=1
STATIC_AUDIT=PASS
BUILD_EXECUTED_BY_THIS_AUDIT=NO
~~~

Tcl completeness was independently queried with the Vivado 2025.2 xtclsh
interpreter. The script was not sourced or executed.

## Non-consuming entry gates

Before any executable repository helper is sourced and before the build-
consumption sentinel is created, the script requires:

- exact Git top, branch, requested HEAD and requested tree;
- exact R1e merge base and exactly one commit above the base;
- a completely clean worktree including untracked files;
- Vivado 2025.2 and SW build 6299465;
- build/evidence roots outside the source repository and a new/empty build
  root;
- exact part xc7a35tcsg325-2 and top ahd_capture_top_xdma;
- SHA-256 identity of the prebuild manifest;
- all required META assignments;
- SHA-256 equality for every production source, every changed path, the build
  script, the shared XDMA helper, exact XCI and all XDCs;
- SHA-256 equality for each required accepted simulation/host log;
- frozen 25-kHz, 64-entry, 192-bit, 16-bit-index, three-phase, 10,000-target,
  ten-block, 512-index and 00/85/00 safe-target source contracts.

The repository-owned xdma_config_common.tcl is sourced only after all of those
identity, cleanliness and manifest checks pass. This removes executable-helper
code from the unaudited pre-gate path.

## Source-list completeness

The production SystemVerilog list is the exact R1e list with the obsolete R1e
address-only probe replaced by the required R1f modules:

~~~text
rtl/v41/nvp_i2c_tri_phase_probe.sv
rtl/v41/r1f_failed_txn_logger.sv
rtl/v41/r1f_measurement_regs.sv
rtl/v41/control_status_regs.sv
...
rtl/top/ahd_capture_top_xdma.sv
~~~

The VHDL dependency order is:

~~~text
rtl/nvp/nvp6134c_diagnostics_pkg.vhd
rtl/nvp/r1f_transaction_serial_counter.vhd
rtl/nvp/nvp6134c_i2c_bringup.vhd
rtl/nvp/nvp6134c_autoinit.vhd
~~~

The script imports the exact unchanged XDMA XCI through a hash-verified copy,
disables an IP synthesis checkpoint, queries every configured XDMA property,
and uses the exact seven XDC files in the inherited EARLY/LATE order. It then
queries the actual synthesis compile order and fails if any required unit is
absent or dependency order is wrong.

## Provenance and one-build accounting

The script requires exactly one source commit above the exact R1e base and
reconstructs that 40-hex commit from five 32-bit runtime words. The only build
flag is 0x00000002. It freezes SLOT_COUNT=2 and
ENABLE_MAREK_INIT_TABLE=1 in the queried generic string.

An atomic exclusive-create sentinel is written before create_project. Once
that sentinel is created, any later error is recorded as a terminal consumed-
build failure. There is no preflight execution mode, retry loop, run reset or
second-build branch.

Static command counts are:

~~~text
create_project=1
synth_design=1
opt_design=1
place_design=1
phys_opt_design=1
route_design=1
write_bitstream=1

launch_runs=0
reset_run=0
open_checkpoint=0
read_checkpoint=0
program_hw_devices=0
write_cfgmem=0
~~~

The synthesis and routed checkpoints are outputs of the sole build; no
checkpoint is consumed as an implementation input.

## Implementation gates before bitstream emission

The script creates the bit only after all queried gates pass:

~~~text
SYNTHESIS=PASS_NONEMPTY_NETLIST
PLACE=PASS_NONZERO_PLACED_PRIMITIVES
ROUTE_ERRORS=0
WNS>=0
WHS>0
VDO_WNS>0
VDO_WHS>0
DRC_ERRORS=0
DRC_CRITICAL_WARNINGS=0
REQP_1839_SEMANTIC_COUNT=4
CDC_CRITICAL=0
CDC_UNKNOWN=0
BUS_SKEW_VIOLATIONS=0
~~~

REQP-1839 uses a named DRC result and unique violation objects. Each returned
object must have an REQP-1839# name and is independently inventoried. Raw text
occurrences are retained only as context and are not used as the gate.

The flow also emits complete timing, DRC, CDC, utilization, power,
hierarchical-resource, congestion, clocks, IO, NVP IOBUF, OEN-to-IOBUF,
pad-to-synchronizer and synchronizer-placement evidence. It inventories each
new R1f region and the inherited autoinit/lifecycle regions.

## Release condition

~~~text
R1F_BUILD_SCRIPT_STATIC_AUDIT=PASS
SCRIPT_FROZEN_FOR_ONE_SOURCE_COMMIT=YES
R1F_SOURCE_COMMIT=225544084dbfcaadb8592fcecc947aa1cec4970e
R1F_SOURCE_TREE=cfde8769af95cf20586391c411fab3ddfa2c87b6
SOURCE_TREE_CLEAN=YES
BUILD_ALLOWED_AFTER_EXACT_COMMIT_TREE_CLEAN_MANIFEST_GATES=YES
~~~

The commit and clean-tree gates now pass. The build must not be started until
the final prebuild manifest binds that exact commit/tree, every required
source and every accepted log. Ignored log-only simulator remnants do not
appear in Git status and are not eligible manifest sources.
