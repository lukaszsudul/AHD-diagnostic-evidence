# G2B-HW0-PRODUCT-R1 Final Hardware State

Final state was captured after the stop decision and while both task locks were
still held.

| Field | Exact final value |
|---|---|
| Candidate | Exact verified candidate still loaded in volatile SRAM by unbroken operation chain |
| FPGA | `xc7a35t`, IDCODE `0362D093` |
| DONE | `1` in five of five final samples |
| AHD endpoint / BDF | Absent / `N/A` |
| Driver binding | None; `xdma` not loaded and driver sysfs absent |
| Device nodes | No XDMA nodes; count `0` |
| Last MMIO state | `NOT_REACHED_NO_MMIO_ACCESS` |
| Stream | `NEVER_ENABLED` |
| Linux task lock | Released after capture; `PASS` |
| Windows task lock | Released after capture; `PASS` |

The DUT boot ID remained
`37131b8d-0e38-4b4e-b77a-b3bda55b4e97`. There was no reboot or power-cycle.

## Protected state

| Protected item | Modified |
|---|---|
| `C:\FPGA\FPGA_AHD` | `NO` |
| `C:\FPGA\V41_G2B` tracked source | `NO` |
| Active XDC | `NO` |
| Project SSOT | `NO` |
| Persistent Flash | `NO` |
| Driver files | `NO` |
| Package state | `NO` |
| Unrelated PCIe endpoints | `NO` |

Program operations were limited to the one authorized volatile-SRAM load.
Final blocker: `BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE`.
