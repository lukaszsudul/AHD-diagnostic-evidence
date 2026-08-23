# R6 selected-new-JTAG tool command ledger

Before the live qualification gates, work is limited to local prompt capture,
exact identity checks, target-selector fixtures, and frozen no-hardware tool
fixtures.

```text
JTAG_READ_ONLY_STABILITY_SESSIONS=2
SSH_BASELINE_SESSIONS=3
SSH_PRE_BOOTSTRAP_SAFETY_SESSIONS=1
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
MMIO_READS=0
MMIO_WRITES=0
DMA_TRANSFERS=0
TASK_TERMINAL_CLASSIFICATION=BLOCKED_R6_STABLE_DONE_0_VS_FROZEN_PREPROGRAM_DONE_1_CONTRACT
```

The three baseline sessions were read-only and used the exact pinned
`-pwfile` transport. They proved the same boot ID and current/next kernel 29;
all password temporary files were deleted.

The two JTAG stability sessions were read-only and collected ten accepted
refresh samples. The selected target identity, part and IDCODE were exact,
`DONE=0` was stable/readable across all samples, and no programming or
frequency-change operation occurred.

One additional privileged-but-read-only SSH session completed the
pre-bootstrap safety discovery. It performed no MMIO, DMA, driver, reboot, or
host mutation and passed all safety gates.

No programming wrapper was invoked. The selected-target transport qualified
with stable `DONE=0`, but the frozen observer requires pre-program `DONE=1`
and R6 permits only target-selection adaptation. Accordingly the task stopped
before `program_hw_devices`; program, reboot and driver-load counts remain zero.
