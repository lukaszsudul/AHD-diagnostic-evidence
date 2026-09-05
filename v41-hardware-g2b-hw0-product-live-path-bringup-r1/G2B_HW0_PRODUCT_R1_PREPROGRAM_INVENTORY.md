# G2B-HW0-PRODUCT-R1 Pre-program Inventory

Result: `PASS`

The fresh read-only DUT inventory completed at `2026-09-05T21:55:37Z`, before
the only SRAM programming operation.

| Item | Pre-program state |
|---|---|
| DUT / kernel | `VCDE-DUT-1 / 7.0.0-29-generic` |
| Boot ID | `37131b8d-0e38-4b4e-b77a-b3bda55b4e97` |
| Relevant DUT processes | None |
| Relevant pre-existing task locks | None |
| JTAG target count / device count | `1 / 1` |
| FPGA | `xc7a35t`, IDCODE `0362D093`, chain index 0 |
| Five JTAG DONE samples | `0,0,0,0,0` |
| Exact AHD/Xilinx endpoint | Absent |
| Historical AHD root `0000:00:01.1` | Absent |
| `xdma` loaded | `NO` |
| XDMA node count | `0` |

The visible external PCIe tree was AMD Phoenix GPP bridge `0000:00:02.1` to
AMD 600-series switch upstream `0000:01:00.0`, then buses 03 through 09. That
current `0000:01:00.0` is `1022:43f4`, not the historical AHD endpoint. The
inventory retained full topology, link, AER, node, module, process, and kernel
log output in `raw/PREPROGRAM_DUT_INVENTORY_READONLY.log`.

The pre-program inventory made zero MMIO accesses, PCI writes, rescans, resets,
driver changes, DMA accesses, reboots, or power actions.
