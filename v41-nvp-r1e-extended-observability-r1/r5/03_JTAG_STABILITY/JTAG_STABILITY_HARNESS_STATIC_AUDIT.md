# R5 JTAG stability harness static audit

This audit covers the task-local implementation only. No Vivado process,
Hardware Manager session, JTAG connection, refresh, or FPGA operation was
started while preparing or auditing these files.

## Files

- `scripts/r5_jtag_stability_session.tcl`
  - SHA-256: `54F423C6A94B15409CBB02AB8076AD238A384B272B6698674C3C6A1FF41D8ABE`
- `scripts/Invoke-R5JtagTransportStability.ps1`
  - SHA-256: `D770610BDFCECB07495255FB6B6F93A94D931D0C2E0CA9EBB1209FAA6B2352E6`
- `scripts/Test-R5JtagStabilityHarnessStatic.ps1`

## Audited execution model

The Tcl file implements one read-only Hardware Manager session. It accepts
only session index 1 or 2, selects the exact target
`localhost:3121/xilinx_tcf/Digilent/210241768436`, requires one target and one
device, captures the device `list_property` result, and runs a fixed loop of
five `refresh_hw_device` samples. Each successful sample records a Tcl
monotonic-millisecond timestamp, UTC, target/device counts, actual target name,
actual HS2 serial, part, normalized IDCODE, readable DONE value, and refresh
result. Four 500 ms delays separate the five samples. Cleanup closes the target
and disconnects/closes Hardware Manager.

The PowerShell supervisor invokes that Tcl file in exactly two sequential
Vivado batch processes. It waits for the first process to terminate before
starting the second. The accepted Vivado settings wrapper and supported
launcher are hash-gated. Separate raw stdout/stderr, Vivado log/journal,
property list, and five-row matrix paths are used for each process. The
aggregate gate requires ten rows, exact identity/counts, successful refreshes,
strictly increasing per-session monotonic timestamps, a readable DONE value in
every sample, and one stable DONE value across all ten samples. Either 0 or 1
is accepted only when stable.

## Static results

```text
TCL_SESSION_INDEX_DOMAIN=PASS
TCL_SAMPLE_COUNT_FIVE=PASS
TCL_DELAY_500_MS=PASS
TCL_REFRESH_IN_FIXED_LOOP=PASS
TCL_EXACT_TARGET=PASS
TCL_EXACT_PART=PASS
TCL_EXACT_IDCODE=PASS
TCL_DONE_READ_EACH_SAMPLE=PASS
TCL_MONOTONIC_TIMESTAMP=PASS
TCL_LIST_PROPERTY_CAPTURE=PASS
TCL_CLEAN_CLOSE=PASS
SUPERVISOR_EXACT_TWO_SESSIONS=PASS
SUPERVISOR_SEQUENTIAL_WAIT=PASS
SUPERVISOR_EXACT_SAMPLE_GATE=PASS
SUPERVISOR_STABLE_DONE_GATE=PASS
SUPERVISOR_SUPPORTED_SETTINGS=PASS
SUPERVISOR_SUPPORTED_LAUNCHER=PASS
SUPERVISOR_PER_SESSION_RAW_LOGS=PASS
SUPERVISOR_COMBINED_MATRIX=PASS
TCL_FORBIDDEN_HARDWARE_MUTATION_COMMAND_COUNT=0
STATIC_AUDIT=PASS
```

The PowerShell AST parser reported zero syntax errors. The Tcl payload contains
no executable property assignment, hardware-programming operation, bitstream or
checkpoint write, VIO commit, synthesis, optimization, placement, or routing
command. Its only hardware-device action inside the sample loop is the
read-only refresh followed by property reads.

## Expected live outputs

- `03_JTAG_STABILITY/JTAG_STABILITY_MATRIX.csv`
- `03_JTAG_STABILITY/SESSION_1_RAW.log`
- `03_JTAG_STABILITY/SESSION_2_RAW.log`
- `03_JTAG_STABILITY/SESSION_1_MATRIX.csv`
- `03_JTAG_STABILITY/SESSION_2_MATRIX.csv`
- `03_JTAG_STABILITY/SESSION_1_LIST_PROPERTY.txt`
- `03_JTAG_STABILITY/SESSION_2_LIST_PROPERTY.txt`
- `03_JTAG_STABILITY/SESSION_1_VIVADO.log` and `.jou`
- `03_JTAG_STABILITY/SESSION_2_VIVADO.log` and `.jou`
- `03_JTAG_STABILITY/JTAG_STABILITY_GATE.md`

The live supervisor is intentionally one-shot: it requires all evidence output
paths to be absent before launch and contains no retry loop.
