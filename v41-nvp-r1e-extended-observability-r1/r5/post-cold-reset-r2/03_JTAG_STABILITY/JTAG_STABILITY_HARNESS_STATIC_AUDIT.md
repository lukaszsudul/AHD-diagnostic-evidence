# R5 POST_COLD_RESET_R2 JTAG stability harness static audit

This audit covers task-local files only. It did not start Vivado, Hardware
Manager, hw_server, cs_server, JTAG, or any hardware operation.

## Harness identities

```text
TCL_PATH=C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\r5_jtag_stability_session.tcl
TCL_SHA256=F01EF1211FBFE2F507F23B1B194445A71196E24904D6A8A3609A5219FEBCAC99
SUPERVISOR_PATH=C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\Invoke-R5JtagTransportStability.ps1
SUPERVISOR_SHA256=C69388150B1C604A0D1EFB210D2A5A920652EC9E0F8C6FF4CEE507800E459600
STATIC_CHECKER_PATH=C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\Test-R5JtagStabilityHarnessStatic.ps1
STATIC_CHECKER_SHA256=E12E9B5ED22950DF87BC911A3E61C4C3E7EDFED5B96DA9AD7FA0D7A00F58CD75
```

Normalized file content is identical to the previously audited R5 stability
harness; the new files have a fresh terminal newline and new byte hashes.

## Audited execution model

The Tcl payload implements exactly one read-only Hardware Manager client
session. It accepts session index 1 or 2, requires the exact target
`localhost:3121/xilinx_tcf/Digilent/210241768436`, one target, one device,
`xc7a35t`, and IDCODE `0362D093`. It captures `list_property` and performs five
fixed `refresh_hw_device` samples separated by 500 ms. Every successful sample
records a monotonic timestamp, UTC, target/device counts, observed target and
HS2 serial, part, normalized IDCODE, readable DONE value, and refresh result.

The PowerShell supervisor launches exactly two sequential Vivado batch
processes. The first process must terminate before the second begins. It uses
the hash-gated accepted Vivado 2025.2 settings wrapper and supported launcher,
and produces separate stdout/stderr, Vivado log/journal, property list, and
matrix evidence for each process. The aggregate gate requires all ten rows,
exact identities, successful refreshes, strictly increasing per-session
monotonic timestamps, and one stable readable DONE value across all samples.
Stable DONE 0 or stable DONE 1 is accepted.

## Static audit

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
POWERSHELL_PARSE_ERRORS=0
STATIC_AUDIT=PASS
```

The Tcl payload has no executable property assignment, FPGA-program command,
bitstream/checkpoint write, VIO commit, synthesis, optimization, placement, or
routing command. Its hardware-device action is the authorized read-only
refresh followed by property reads.

## Fresh-output gate

Before any live launch, all of these paths were verified absent:

```text
JTAG_STABILITY_MATRIX.csv=ABSENT_PASS
JTAG_STABILITY_GATE.md=ABSENT_PASS
SESSION_1_MATRIX.csv=ABSENT_PASS
SESSION_1_LIST_PROPERTY.txt=ABSENT_PASS
SESSION_1_RAW.log=ABSENT_PASS
SESSION_1_VIVADO.log=ABSENT_PASS
SESSION_1_VIVADO.jou=ABSENT_PASS
SESSION_2_MATRIX.csv=ABSENT_PASS
SESSION_2_LIST_PROPERTY.txt=ABSENT_PASS
SESSION_2_RAW.log=ABSENT_PASS
SESSION_2_VIVADO.log=ABSENT_PASS
SESSION_2_VIVADO.jou=ABSENT_PASS
```

The supervisor repeats those freshness checks immediately before launching.
It is one-shot and contains no retry loop.
