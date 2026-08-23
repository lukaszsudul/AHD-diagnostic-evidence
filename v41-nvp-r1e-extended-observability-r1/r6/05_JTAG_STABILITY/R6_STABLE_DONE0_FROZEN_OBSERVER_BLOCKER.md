# R6 stable-DONE=0 versus frozen pre-program-DONE=1 contract

## Classification

```text
CLASSIFICATION=BLOCKED_R6_STABLE_DONE_0_VS_FROZEN_PREPROGRAM_DONE_1_CONTRACT
JTAG_TRANSPORT_STABILITY_GATE=PASS_10_OF_10
JTAG_PRECHECK_DONE_VALUE=0
FPGA_PROGRAM_INVOCATIONS=0
FORMAL_BOOTSTRAP_PROGRAMS=0
PROGRAM_RETRIES=0
```

## Fresh R6 observation

The two authorized, independent, read-only Hardware Manager sessions both
completed with process exit code 0. Each session produced five accepted
refresh samples. All ten rows recorded:

```text
target_count=1
device_count=1
target_path=localhost:3121/xilinx_tcf/Xilinx/80802026a98b01
canonical_id=Xilinx/80802026a98b01
part=xc7a35t
idcode=0362D093
done=0
refresh_result=PASS
```

The aggregate gate reports `PASS_10_OF_10`, stable readable `DONE=0`, no JTAG
frequency change, no failures, and zero FPGA program operations. Each raw
session independently records five `SAMPLE_n_DONE=0` values,
`SESSION_GATE=PASS`, and `FPGA_PROGRAM_OPERATIONS_THIS_SESSION=0`.

## Frozen observer entry contract

The selected-target programming adapter is:

```text
PATH=C:\FPGA\V41_NVP_R1E_SELECTED_NEW_JTAG_PAIRED_AB_R6\scripts\program_once_startup_high_done_r6_selected.tcl
SHA256=00B612413A5322C4FC94003BDF2E6E48318DA61D0D8362D028D70035B03C47AC
```

Its exact pre-program logic is at lines 123-127:

```tcl
set preprogram_done [get_property $bit5_property $dev]
emit PREPROGRAM_DONE $preprogram_done
if {$preprogram_done ne "1"} {
  error "pre-program DONE gate failed: DONE=$preprogram_done"
}
```

The first program-invocation-consumed marker is emitted later, at lines
129-134, immediately before the sole `program_hw_devices`. Therefore the
observed stable `DONE=0` would be rejected before a program invocation is
consumed.

## R6 authorization boundary

The frozen R6 owner prompt has SHA-256:

```text
8A916697C066C35B94B38FD4AE7B7CBC7114915D6646EF756F1EAB44E2DBBE9D
```

It states that the programming observer may be adapted only in its task-local
target-selection layer (lines 660-661), requires the invocation-count,
startup-HIGH parser, same-session DONE gate, process-exit gate, QPC/wait logic,
and no-retry logic to remain byte-identical (lines 663-671), and directs that
the accepted observer be adapted only by calling the selector (line 1026).
The same prompt explicitly permits stable pre-bootstrap DONE of either 0 or 1
for the read-only transport qualification (line 1173).

No positive authorization changes the inherited pre-program DONE rejection.
Consequently, the transport gate passes, but the frozen programming observer
cannot enter the mandatory bootstrap from this observed state. No observer,
selector, raw log, ledger, or final report was modified to bypass the gate.

## Accounting basis

```text
OPERATION_LEDGER_FPGA_PROGRAM_INVOCATIONS=0
OPERATION_LEDGER_FORMAL_BOOTSTRAP_PROGRAMS=0
FORMAL_BOOTSTRAP_PROGRAM_OUTPUT_FILES=0
PROGRAM_INVOCATION_CONSUMED_MARKERS=0
```

