# R5 Tool Command Ledger

Before live JTAG, only local read-only identity checks and no-hardware fixtures
ran. No SSH, programming, reboot, driver, MMIO, or DMA command has run.

JTAG_STABILITY_TCL_SHA256=54F423C6A94B15409CBB02AB8076AD238A384B272B6698674C3C6A1FF41D8ABE
JTAG_STABILITY_SUPERVISOR_SHA256=D770610BDFCECB07495255FB6B6F93A94D931D0C2E0CA9EBB1209FAA6B2352E6
JTAG_STABILITY_STATIC_AUDIT=PASS

READ_ONLY_JTAG_STABILITY_SESSIONS=2
JTAG_STABILITY_ACCEPTED_SAMPLES=0
FPGA_PROGRAM_OPERATIONS_IN_STABILITY_SESSIONS=0
SESSION_1_RESULT=FAIL_LABTOOLS_27_2269_NO_DEVICES_DETECTED
SESSION_2_RESULT=FAIL_LABTOOLS_27_2269_NO_DEVICES_DETECTED
JTAG_TRANSPORT_STABILITY_GATE=FAIL

No command was issued after the stability hard stop. SSH, host discovery,
programming, reboot, driver load, MMIO, and DMA remained unexecuted.

Post-stop activity was limited to local evidence inspection, report completion,
secret scanning, hashing, packaging, and publication preparation. No further
Vivado, JTAG, SSH, host, MMIO, or hardware command was issued.
