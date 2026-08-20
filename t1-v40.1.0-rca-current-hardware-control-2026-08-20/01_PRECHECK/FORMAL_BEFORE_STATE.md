# Formal before-state disposition

The formal repository identity was verified and remained clean. Fresh host,
PCIe/BAR/NVP/video, and JTAG evidence was not collected because the mandatory
SSH automation gate failed first and required an immediate zero-program stop.

```text
EXPECTED_STARTING_IMAGE=FORMAL_PHASE2_ACCEPTED_REFERENCE
FRESH_FORMAL_RUNTIME_IDENTITY=NOT_READ_SSH_GATE_FAILED
FRESH_DIAGNOSTIC_MAGIC=NOT_READ_SSH_GATE_FAILED
FRESH_PCIE_XDMA_HEALTH=NOT_READ_SSH_GATE_FAILED
FRESH_JTAG_DONE=NOT_RUN_SSH_GATE_HARD_STOP
FPGA_PROGRAM_OPERATIONS=0
HOST_REBOOTS=0
```

No image transition, reboot, cold start, or physical action occurred, so the
owner-declared starting image was preserved by zero mutation; this is not
presented as a fresh runtime verification.
