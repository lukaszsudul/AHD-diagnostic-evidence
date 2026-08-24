# R1g Routed-DCP Impact Audit Tooling — Static Release Audit

```text
TASK=V41_NVP_R1G_VHDL_COMPATIBILITY_AND_PHASE_COMPLETE_OBSERVABILITY
TOOLING_SCOPE=POST_BUILD_READ_ONLY_ROUTED_DCP_COMPARISON
TOOLING_EXECUTED_AGAINST_R1G_DCP=NO
R1G_DCP_REQUIRED_BEFORE_EXECUTION=YES
R1G_BUILD_PASS_REQUIRED_BEFORE_EXECUTION=YES
R1E_ROUTED_DCP_SHA256_GATE=1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1
R1G_PLACEMENT_NEUTRAL=NOT_CLAIMED
SOURCE_FILES_CHANGED=0
BUILD_OR_PREFLIGHT_COMMANDS_RUN=0
HARDWARE_ACTIONS=0
NETWORK_ACTIONS=0
OPERATION_LEDGER_CHANGED=NO
```

## Runtime gate ordering

The PowerShell wrapper performs these checks before creating the evidence
directory or launching Vivado:

1. exact R1e checkpoint path, byte size and SHA-256;
2. independently supplied expected R1g DCP SHA-256;
3. all mandatory build PASS, timing, DRC, CDC, provenance and bitstream fields;
4. exact R1g source commit/tree and branch;
5. receipt checkpoint path equality and bitstream hash equality;
6. absence of a colocated terminal build-failure receipt;
7. static audit of the Tcl command surface;
8. fresh task-local output directory.

Vivado then gates exact tool version/build and exact part before querying each
checkpoint.

## Read-only Vivado command surface

The Tcl script uses only checkpoint-open/close, object/property queries,
timing-path queries, structural fan-in/fan-out queries, and report commands.
Its expected design-access commands are:

```text
open_checkpoint
current_design
get_property
get_ports
get_cells
get_pins
get_nets
get_clocks
get_timing_paths
all_fanin
all_fanout
report_property
report_timing
report_utilization
report_power
report_design_analysis -congestion
report_clock_utilization
report_clocks
report_io
close_design
```

The wrapper rejects any Tcl command site beginning with project creation,
source ingestion, synthesis, optimization, placement, routing, checkpoint or
bitstream emission, property mutation, run control, or hardware-manager
access.

## Explicit exclusions

```text
create_project=ABSENT
read_vhdl=ABSENT
read_verilog=ABSENT
read_xdc=ABSENT
add_files=ABSENT
synth_design=ABSENT
opt_design=ABSENT
power_opt_design=ABSENT
place_design=ABSENT
phys_opt_design=ABSENT
route_design=ABSENT
write_checkpoint=ABSENT
write_bitstream=ABSENT
set_property=ABSENT
program_hw_devices=ABSENT
HARDWARE_MANAGER_COMMANDS=ABSENT
RETRY_LOOP=ABSENT
```

Output-file creation is confined to a new child directory of the task's
`08_BUILD` directory. It does not modify either checkpoint.
