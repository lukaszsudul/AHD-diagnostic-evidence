# Offline R4 analysis-tool preflight

## Frozen input schema

The analysis tool was derived directly from the exact task-local copy of the
R3 read-only reader:

```text
PATH=C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4\scripts\read_nvp_r1e.py
SHA256=0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037
```

The reader emits a JSON object with `T0` and `T1`. Each snapshot contains the
complete local register dictionary, the `0x2000..0x20FF` R1e page, the raw
17-word legacy ordered-log window, decoded ordered-log metadata/records,
lifecycle arithmetic, probe statistics, and a coherent freerun count.

`scripts/analyze_r4_telemetry.py` accepts either that bare JSON or a captured
command log containing it. It independently rechecks T0/T1 static equality,
formal-page zero behavior, Arm-A lifecycle/probe invariants, Wilson intervals,
ordered-log distributions, first-error consistency, and conservative combined
classifications. Its automatic control-flow classification never asserts
`YES`; exact FSM replay must be supplied explicitly for that claim.

## Offline fixture execution

The fixtures ran locally using the Python 3.13.0 interpreter bundled with the
approved Vivado 2025.2 installation. No network, DUT, JTAG, MMIO, or generated
FPGA artifact was accessed.

```text
PYTHON=C:\AMDDesignTools\2025.2\tps\win64\python-3.13.0\python.exe
PYTHON_VERSION=3.13.0
PY_COMPILE=PASS
FIXTURES_RUN=5
FIXTURES_PASSED=5
FIXTURES_FAILED=0
RESULT=PASS_ALL
```

Coverage:

- zero post-init probe NACKs plus an autoinit address-phase NACK;
- nonzero probe NACKs plus a dispersed autoinit log;
- overflowing ordered log forcing first-eight-only control-flow scope;
- rejection of a probe-count invariant failure;
- extraction of reader JSON from a prefixed/suffixed command log.

## R4 terminal applicability

The formal-bootstrap program failed before Arm A and Arm B. Consequently no
R4 reader JSON exists and the telemetry analyzer is not used to create a
scientific result for this task. The final report records all lifecycle,
ordered-log, probe, and paired fields as `NOT_MEASURED`, `NOT_COMPUTABLE`, or
`NOT_RUN` as appropriate.
