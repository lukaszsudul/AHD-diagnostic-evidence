# Offline test receipt

The inherited SCAN1 master/core/host gate completed `24/24 PASS` in `simulation/inherited-scan1-gate-r3`; the inherited ACQ executor/integration gate completed `20/20 PASS` in `simulation/inherited-acq-integration`. The CONT1R3 Python T01–T32 gate completed `32/32 PASS` in `simulation/CONT1R3_OFFLINE_OBSERVABILITY_GATE.log`. Its directed RTL telemetry gate completed `6/6 PASS`, with parent/candidate cycle comparison, in `simulation/parent-candidate-equivalence/xsim.log`.

Earlier task-local bootstrap failures (Windows Python application alias and harness stderr handling) and an initial testbench assertion mistake were preserved in separate logs and did not change the frozen source semantics. The final receipts above, not those failed bootstrap attempts, support this gate. No hardware access occurred during testing.

The preregistration was frozen before implementation and before any DUT contact: SHA-256 `18CDD7FBC67ABDB799475CE509BC686C3A2CD0E7153BC4E44910ABC809B5DF8C`.
