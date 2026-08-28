# R2 Cold-Reset Baseline Receipt

- Owner cold reset recognized: `YES`
- Counted as formal trial: `NO`
- Primary classification: `UNPROGRAMMED_OR_FPGA_UNKNOWN`
- Resolved detail: `UNPROGRAMMED`
- Corresponding PCIe state: `PCIe_NOT_ENUMERATED`

## Host and SSH

- ICMP reachability: `PASS`
- TCP/22 reachability: `PASS`
- SSH authentication/read-only command: `PASS`
- hostname: `VCDE-DUT-1`
- user: `vcdeagent1`
- kernel: `7.0.0-29-generic`
- boot ID: `c53a4c28-4120-4527-89e2-1108cfaaa2f3`

## FPGA and PCIe

- JTAG part: `xc7a35t`
- JTAG IDCODE: `0362D093`
- DONE: `0` in `5/5` stable samples
- FPGA programming invocations during observation: `0`
- Xilinx PCIe functions: `NONE`
- class 0580 functions: `NONE`
- `0000:01:00.0`: AMD bridge `1022:43f4`, not DUT
- XDMA module: `NOT_LOADED`
- XDMA nodes: `NONE`

## Runtime identity

- current firmware identity: `UNREADABLE_UNPROGRAMMED`
- current MMIO identity: `UNREADABLE_ENDPOINT_ABSENT`
- BLOCK_ID: `UNREADABLE`
- PROTOCOL: `UNREADABLE`
- CAPABILITIES: `UNREADABLE`
- diagnostic magic: `UNREADABLE`

No driver load/unload, reboot, reset, programming, power action, MMIO write, DMA, or remote disk write was performed.

Evidence: `raw/REMOTE_IDENTITY.txt`, `raw/REMOTE_PCIE_DRIVER_PREFLIGHT.txt`, `raw/REMOTE_PCIE_TOPOLOGY.txt`, and sanitized `raw/JTAG_DONE_SAMPLES_SANITIZED.csv`.
