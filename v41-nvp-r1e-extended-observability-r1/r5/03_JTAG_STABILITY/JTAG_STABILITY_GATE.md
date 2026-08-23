# R5 JTAG transport-stability gate

READ_ONLY_JTAG_STABILITY_SESSIONS=2
JTAG_REFRESH_SAMPLES_PER_SESSION=5
JTAG_STABILITY_SAMPLES=0
JTAG_PRECHECK_DONE_VALUE=UNSTABLE_OR_UNREADABLE
FPGA_PROGRAM_OPERATIONS=0
JTAG_TRANSPORT_STABILITY_GATE=FAIL

FAILURES:
aggregate sample count is 0, expected 10
DONE is not stable and readable across all samples
session 1 exit code was not zero
session 1 has 0 samples, expected 5
session 1 property list is missing
session 1 sample indices are not 1..5
session 2 exit code was not zero
session 2 has 0 samples, expected 5
session 2 property list is missing
session 2 sample indices are not 1..5
