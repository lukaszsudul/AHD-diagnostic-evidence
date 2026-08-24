# R1h synchronous MMIO read-service test report

## Identity

- Exact R1g parent commit: `e112a5addb7ac62700a9a71af81bf368fad0bada`
- R1g evidence commit: `31786f351a9b8aab86291b5058ce075da5fba46a`
- Candidate DUT: `rtl/v41/r1h_mmio_read_service.sv`
- Candidate DUT SHA-256 at test time: `DFA30D5C4695E02ABFC5EB09ED3FD087DACC45AAE6340A17B00BAFE20D26F2E4`
- Testbench: `tests/v41/tb_r1h_mmio_read_service.sv`
- Testbench SHA-256: `E78696203A4E294C47A1E3A60B347D1DE140661ED6B55FF48AB0B8E45FAE3458`
- Vivado Simulator: 2025.2, SW build 6299465, IP build 6300035
- Production RTL edits made by this test task: zero
- Synthesis/optimization/place/route/bitstream runs made by this test task: zero

## Commands

The commands were run from this evidence directory:

```text
C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat --sv --work work <DUT> <TB>
C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat tb_r1h_mmio_read_service -debug typical -s r1h_mmio_read_service_snapshot
C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat r1h_mmio_read_service_snapshot -tclbatch run.tcl
```

All three final invocations returned process exit code 0. The first XSim launcher
attempt used an absolute Windows path as a Tcl argument. Tcl interpreted the
backslashes as escapes and did not open `run.tcl`; the simulator did not advance
simulation time. That launcher-only failure is preserved in
`xsim_20504.backup.log`. The corrected invocation uses the task-local relative
path `run.tcl`; its complete passing transcript is `xsim.log`.

## Assertions exercised

The self-checking testbench verifies:

1. scalar data are captured on an accepted request and returned as a registered response;
2. record requests emit one BRAM-read pulse, wait for `record_read_valid`, and return exactly its 32-bit data;
3. packed index reads issue ordered low/even and high/odd BRAM reads and pack `{odd, even}`;
4. phase, word and stored-count are snapshotted at request acceptance;
5. changing a live count after acceptance cannot change masking;
6. both halves beyond request-time `stored_count` return deterministic zero;
7. a valid final even index with the following odd index unused returns a zero upper half;
8. response data and valid remain stable for arbitrary downstream backpressure;
9. no second request is accepted and no memory request is emitted while the service is busy;
10. one ready handshake consumes exactly one response without duplication;
11. synchronous reset cancels `RECORD_WAIT`, `INDEX_LOW_WAIT`, `INDEX_HIGH_WAIT`, and `RESPONSE`;
12. the service accepts and completes a fresh request after all reset-abort paths.

## Result

```text
R1H_MMIO_READ_SERVICE_TEST=PASS
ACCEPTED_REQUESTS=10
CONSUMED_RESPONSES=6
RESET_CANCELLED_REQUESTS=4
SCALAR_REGISTERED_RESPONSE=PASS
RECORD_WAIT_AND_DATA=PASS
INDEX_TWO_STEP_PACKING=PASS
REQUEST_TIME_STORED_COUNT_MASKING=PASS
RESPONSE_BACKPRESSURE_STABILITY=PASS
SECOND_REQUEST_WHILE_BUSY=REJECTED
RESET_ALL_PENDING_STATES=PASS
NO_RESPONSE_DUPLICATION=PASS
SIMULATION_FINISH_TIME_NS=436
```

The final XSim marker is:

```text
R1H_MMIO_READ_SERVICE_PASS accepted=10 consumed=6 reset_cancelled=4
```

