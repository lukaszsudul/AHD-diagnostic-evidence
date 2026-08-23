# R5 POST_COLD_RESET_R2 program-phase supervisor static audit

No Vivado, Hardware Manager, JTAG, FPGA-program, reboot, driver, or DUT action
was executed during this audit.

## Frozen accepted observer identities

```text
PROGRAM_TCL=
    C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\program_once_startup_high_done.tcl
PROGRAM_TCL_SHA256=
    7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653

OBSERVER_PARSER=
    C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\ProgramObserverCommon.ps1
OBSERVER_PARSER_SHA256=
    6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66

OBSERVER_AND_PARSER_BYTE_IDENTICAL_TO_ACCEPTED_R4_R1C=
    YES
```

Neither accepted file was edited. The historical Tcl role names remain inside
the accepted observer; they select formal versus 25-kHz programming behavior
and do not bind any obsolete bitstream.

## R5 supervisor identity

```text
SUPERVISOR=
    C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\Invoke-R5ProgramPhaseOnce.ps1
SUPERVISOR_SHA256=
    F27D4FB38AB8E080D30F647BA87D8CFC87F2A35B14A4B125DB03F15DCD099A44

STATIC_CHECKER=
    C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\Test-R5ProgramPhaseSupervisorStatic.ps1
STATIC_CHECKER_SHA256=
    CA585A0C04E384739201A3FF2B561D048A0AE4A7205FFE9DBCFDA10284A0AA9A
```

The supervisor accepts exactly one phase per invocation:

```powershell
& 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\Invoke-R5ProgramPhaseOnce.ps1' -Phase FormalBootstrap
& 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\Invoke-R5ProgramPhaseOnce.ps1' -Phase ArmA
& 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5\scripts\Invoke-R5ProgramPhaseOnce.ps1' -Phase ArmB
```

These are phase-specific commands for the parent runbook, not commands run by
this audit.

## Exact artifact bindings

| Phase | Artifact | Size | SHA-256 | Fixed wait |
|---|---|---:|---|---:|
| FormalBootstrap | `ahd_capture_v41_phase2_p1.bit` | 2192144 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | 5.0 s |
| ArmA | `ahd_capture_v41_i2c_25khz_r1e_observability.bit` | 2192144 | `0BDE629B9AA1DD2846E4314E94D7C6734825037CBCC2D7271DF7ACBABE8A7DB9` | 10.0 s |
| ArmB | `ahd_capture_v41_phase2_p1.bit` | 2192144 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | 5.0 s |

The artifact paths, filename, size, SHA-256, source commit, and source tree are
internal constants. The caller cannot provide alternative bit identities or
wait durations. No historical R1 bit filename, source commit, or SHA-256 is
bound by the supervisor.

## Observer and invocation gates

```text
PROGRAM_TCL_HASH_EXACT=PASS
OBSERVER_PARSER_HASH_EXACT=PASS
PROGRAM_HW_DEVICES_EXECUTABLE_COUNT=1
PROGRAM_FILE_ASSIGNMENT_EXECUTABLE_COUNT=1
BIT4_EOS_QUERY_COUNT=0
SUPERVISOR_POWERSHELL_PARSE=PASS
SUPERVISOR_PHASE_SET_EXACT=PASS
SUPERVISOR_PROCESS_START_SYNTACTIC_COUNT=1
SUPERVISOR_PROGRAM_COMMAND_COUNT=0
SUPERVISOR_CALLER_BIT_PARAMETERS=0
FORMAL_NAME_SIZE_SHA_BINDING=PASS
R1E_NAME_SIZE_SHA_BINDING=PASS
OLD_R1_BIT_BINDING_COUNT=0
FIXED_PHASE_WAITS=PASS_5_10_5
ISOLATED_VIVADO_LOG_AND_JOURNAL=PASS
FRESH_PHASE_OUTPUT_GATE=PASS
QPC_RETURN_AND_FRESH_DONE_REFERENCE=PASS
QPC_WAIT_RECEIPT=PASS
NO_RETRY_CLASSIFICATION=PASS
SUPPORTED_VIVADO_BAT=PASS
RAW_VIVADO_EXE_COUNT=0
STATIC_AUDIT=PASS
```

The accepted observer contains one `program_hw_devices` call, preceded by the
consumed marker. It requires exact target/part/IDCODE and pre-program DONE=1,
then requires vendor startup HIGH, a same-session fresh DONE=1, exactly one
program return, and process exit zero. Its parser rejects duplicate, missing,
misordered, timed-out, startup-LOW, DONE=0, and program-error transcripts.

## Parser fixtures

```text
PROGRAM_OBSERVER_FIXTURE_COUNT=11
PROGRAM_OBSERVER_FIXTURE_FAILURES=0
PROGRAM_OBSERVER_FIXTURE_GATE=PASS
```

## Isolated evidence and QPC receipt

Each phase has its own fixed evidence directory and fresh one-shot names:

```text
PROGRAM_SUPERVISOR.log
PROGRAM_VIVADO.log
PROGRAM_VIVADO.jou
PROGRAM_WAIT_RECEIPT.txt
```

All twelve phase-output paths were absent during this audit. The supervisor
will refuse to launch if any output for the selected phase already exists.
The log timestamps every captured stdout/stderr record with
`Stopwatch.GetTimestamp()`. After a passing observer result, the fixed wait is
measured from the later QPC tick of the program-return and same-session
fresh-DONE markers. The wait receipt records the QPC frequency, both source
markers, selected reference, end tick, required seconds, actual ticks/seconds,
and PASS gate.

## Discrepancy result

```text
ACCEPTED_OBSERVER_DISCREPANCIES=0
EXACT_ARTIFACT_BINDING_DISCREPANCIES=0
OLD_R1_BIT_BINDING_DISCREPANCIES=0
RETRY_PATHS=0
PROGRAM_PHASE_SUPERVISOR_STATIC_RESULT=PASS
```
