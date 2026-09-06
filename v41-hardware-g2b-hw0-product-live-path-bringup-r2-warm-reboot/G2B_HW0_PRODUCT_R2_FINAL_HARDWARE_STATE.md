# G2B-HW0-PRODUCT-R2 Final Hardware State

Final-state validation: `PASS`

## FPGA

- Exact candidate remained in volatile SRAM: `YES`.
- FPGA: `xc7a35t`, IDCODE `0362D093`, chain index 0.
- Final JTAG samples: five of five `DONE=1`.
- R2 SRAM programs: `0`.
- Flash programs: `0`.

## PCIe and driver

- Endpoint: `0000:01:00.0`, `10ee:7011`, subsystem `10ee:0007`, class `058000`.
- Upstream/root port: `0000:00:01.1`.
- Link: PCIe Gen2 x1.
- Endpoint binding: `UNBOUND`.
- XDMA module: `UNLOADED`.
- XDMA nodes: `0`.
- Module loads, binds, and unbinds: `0 / 0 / 0`.

## Runtime operations

- Legacy MMIO reads/writes: `0 / 0`.
- G2B MMIO reads/writes: `0 / 0`.
- Stream enable writes: `0`.
- DMA operations: `0`.
- PCIe rescans/resets: `0 / 0`.
- Warm reboots: `1`.
- Power cycles: `0`.

The final Linux and JTAG captures were taken while both locks were held. The
post-reboot Linux lock was released first; the controller lock was released
last at `2026-09-06T07:34:55.6004821Z`. The candidate was intentionally left
in volatile SRAM. No previous image was restored.

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
| Unrelated endpoint configuration | `NO` |

Engineering first blocker: `BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE`.
