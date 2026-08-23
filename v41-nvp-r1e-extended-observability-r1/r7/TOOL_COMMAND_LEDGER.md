# R7 mode-aware DONE0 tool command ledger

This terminal accounting reconciles every live command class to the immutable
phase receipts and contextual logs. All MMIO operations were read-only; no
individual dword total was used as an operation limit, so MMIO is counted by
validated read session rather than by register access.

```text
JTAG_READ_ONLY_RECONFIRMATION_SESSIONS=1
JTAG_READ_ONLY_RECONFIRMATION_SAMPLES=5
JTAG_PROGRAMMING_SESSIONS=3
JTAG_INDEPENDENT_IMMEDIATE_DONE_SESSIONS=3
JTAG_INDEPENDENT_FINAL_DONE_SESSIONS=3
JTAG_INDEPENDENT_DONE_SESSIONS=6
SSH_BASELINE_SESSIONS=2
SSH_PRE_BOOTSTRAP_SAFETY_SESSIONS=1
SSH_RUNTIME_VALIDATOR_SESSIONS=8
SSH_WARM_REBOOT_SUBMISSIONS=3
SSH_PINNED_LOADER_INVOCATIONS=3
SSH_TELEMETRY_SESSIONS=2
TOTAL_CONTEXTUAL_SSH_SESSIONS=19
FPGA_PROGRAM_INVOCATIONS=3
FORMAL_BOOTSTRAP_PROGRAMS=1
ARM_A_PROGRAMS=1
ARM_B_PROGRAMS=1
WARM_REBOOTS=3
DRIVER_LOADS=3
MMIO_READ_SESSIONS=7
MMIO_WRITES=0
DMA_TRANSFERS=0
PROGRAM_RETRIES=0
```

The 19 contextual SSH sessions comprise two baseline sessions, one
pre-bootstrap safety session, eight runtime-validator sessions, three warm
reboot submissions, three exact pinned-loader invocations, and two T0/T1
telemetry sessions. The ten Hardware Manager sessions comprise one read-only
reconfirmation, three programming sessions, three immediate independent-DONE
sessions, and three final independent-DONE sessions.
