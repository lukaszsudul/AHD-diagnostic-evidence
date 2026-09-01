# PCB-PIN-1 PROGRAM_B Existing Implementation

## Result

PROGRAM_B historical loop = PARTIAL

Exact current/historical signal name = NONE_IDENTIFIED

The audit request supplies schematic-level evidence of the prototype topology:

```text
FPGA user output -> T12 -> PROGRAM_B_0
```

The accessible RTL, XDC, Git history, and pre-Git routed I/O report do not preserve a signal name or a live implementation of that loop. The physical prototype assertion is therefore retained as task-supplied evidence, while the implementation identity is classified PARTIAL rather than invented.

## Current implementation check

- The current top-level port list in `rtl/top/ahd_capture_top_pcie.v`, lines 77-96, has no PROGRAM_B-driving user output.
- The active `xdc/boards/current/pins.xdc`, lines 1-20, has no T12 assignment and no PROGRAM_B assignment.
- A repository-wide and all-reference Git search found no RTL/XDC implementation of a T12-to-PROGRAM_B feedback loop.
- The `sys_reset` occurrence in an old constraints file is an ordinary capture-core reset. It is not PROGRAM_B and must not be reported as the historical net name.

T12 is therefore not used by the current constrained product design.

## Historical evidence

The pre-Git routed report `AHD_Capture_Card/v39A_SC1/regression_iter7/postroute_20260729_223238/report_io_v39A.rpt` records:

- P10 as the dedicated `PROGRAM_B_0` configuration pin, with no user signal name; and
- T12 as `IO_L22P_T3_A05_D21_14`, a Bank-14 user I/O, with blank signal, direction, and I/O-standard fields.

The historical `C:/FPGA/AHD_Capture_Card/AHD_Capture_Card.srcs/constrs_1/imports/Downloads/ahd_capture_card_pins_v05e_ready.xdc`, lines 82-111, lists control outputs but no self-reconfiguration output. T12 references elsewhere in history are unrelated test labels, not evidence of this circuit.

This establishes that the accessible pre-Git routed FPGA image did not use T12, but it cannot disprove an earlier or PCB-only prototype connection. It also cannot recover the old schematic net label.

## Intended behavior and actual effect

The apparent intent was an FPGA-initiated "self-reset." Electrically, asserting active-low PROGRAM_B is not an ordinary logic reset. It begins a full configuration-memory clear and configuration reload. During that operation global three-state removes the driving user I/O, so a direct feedback loop is self-terminating and its pulse width is not inherently guaranteed.

No current RTL block, recovery flow, product requirement, or constraint depends on the loop. The local PCB requirements call for native MultiBoot and accessible INIT_B/PROGRAM_B service controls, but they do not require a user-GPIO feedback loop.

## Conclusion

- Prototype physical topology: task-supplied evidence only.
- Exact historical net/port name: not recoverable.
- Current RTL/XDC implementation: absent.
- T12 current use: none found.
- Function type: full FPGA reconfiguration, not logic reset.
- Current product/recovery dependency: none found.
- Replacement FPGA GPIO if removed: not required.

The independent architectural decision is recorded in `PCB_PIN1_PROGRAM_B_ARCHITECTURE_DECISION.md`.
