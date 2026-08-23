# R5 post-cold-reset R2 tool command ledger

Before live qualification, activity is limited to local filesystem
preservation, prompt capture, exact identity checks, and no-hardware fixtures.

```text
JTAG_COMMANDS=2_READ_ONLY_HARDWARE_MANAGER_SESSIONS
SSH_SESSIONS=3
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
MMIO_READS=0
MMIO_WRITES=0
DMA_TRANSFERS=0
```

All three SSH sessions were read-only post-cold-reset host-stability samples.
They used the accepted `-pwfile` helper, produced `PASS_3_OF_3`, and left no
password temporary file. No sudo or remote mutation command was used.

Both independent JTAG sessions were read-only and contained zero program or
property-write commands. Each enumerated one nonmatching Xilinx target and
terminated before device enumeration or refresh sampling. No command was
issued after the JTAG hard stop except local evidence inspection and sealing.

Final read-only audits reconciled the two raw Vivado transcripts, zero-row
sample matrices, aggregate gate, operation counters, authoritative report,
and secret-scan result. No discrepancy or unrecorded live operation was found.
