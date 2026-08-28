# AHD v41 G2B Hardware Non-Access Declaration

This receipt covers the AHD v41 G2B minimal one-channel C2H offline gate on 2026-08-28.

The G2B activity remained strictly offline. The R2 research campaign retained exclusive ownership of the DUT. No check was made to determine whether the DUT was free, and `FPGA_AHD_HW_LOCK` was not requested or acquired.

- `HARDWARE_ACCESS = NO`
- `HW_LOCK = NOT_REQUESTED`
- `R2_INTERFERED_WITH = NO`
- `DUT_AVAILABILITY_PROBED = NO`
- `HARDWARE_QUALIFICATION_CLAIMED = NO`

## Prohibited-operation accounting

| Prohibited operation | Execution count |
|---|---:|
| SSH to DUT | 0 |
| JTAG access | 0 |
| `open_hw` | 0 |
| `connect_hw_server` / hardware-target discovery | 0 |
| `program_hw_devices` | 0 |
| DUT MMIO reads or writes | 0 |
| DUT PCIe enumeration | 0 |
| XDMA host reads or writes | 0 |
| DMA throughput or completion tests | 0 |
| DUT reboot | 0 |
| DUT power cycle | 0 |
| Driver load, unload, bind, unbind, install, or configuration | 0 |
| `FPGA_AHD_HW_LOCK` request or acquisition | 0 |
| Probe of DUT availability | 0 |

The only class of Vivado invocation was `vivado.bat -version`; it was issued twice solely to read and capture the installed software banner. Neither invocation created a project, opened the hardware manager, connected to a hardware server, discovered a target, or accessed the DUT.

Permitted activity was limited to read-only Git and filesystem inspection, offline RTL/XCI/build-harness review, observation of the existing `V:` drive mapping, the software-only Vivado version query, and creation of evidence files outside the source worktree.

No conclusion about PCIe negotiation, XDMA completion, driver behavior, captured video correctness, payload rate, or DMA performance was inferred. All such states remain **NOT HARDWARE QUALIFIED**.
