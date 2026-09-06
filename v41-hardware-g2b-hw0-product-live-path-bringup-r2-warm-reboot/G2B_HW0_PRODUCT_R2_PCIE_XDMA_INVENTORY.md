# G2B-HW0-PRODUCT-R2 PCIe and XDMA Inventory

## PCIe

| Field | Value |
|---|---|
| Exact endpoint | `0000:01:00.0` |
| Vendor/device | `10ee:7011` |
| Subsystem | `10ee:0007` |
| Class | `058000` |
| Upstream/root port | `0000:00:01.1` |
| LnkCap | `Speed 5GT/s, Width x1` |
| LnkSta | `Speed 5GT/s, Width x1` |
| Current speed/width | `5.0 GT/s PCIe / x1` |
| PCIe Gen2 x1 gate | `PASS` |
| Current endpoint driver | `NONE` |

## Installed module feasibility

| Field | Value |
|---|---|
| Installed module name | `xdma` |
| Path | `/lib/modules/7.0.0-29-generic/kernel/drivers/dma/xilinx/xdma.ko.zst` |
| Module version | `N/A (modinfo version field absent)` |
| SHA-256 | `523ED1F77A4700773EF1DF846A54592D7396774826ACABBCB222E104CC5A9490` |
| Module alias | `platform:xdma` only |
| Matching platform devices | `0` |
| HDMI/unrelated endpoints matching installed module | `0` |
| Exact `10ee:7011` PCI modalias resolution | `NO MODULE` |
| PCI XDMA driver sysfs | `ABSENT` |
| XDMA nodes | `0` |
| Module loads in R2 | `0` |
| Driver binds/unbinds in R2 | `0 / 0` |

The exact endpoint is a PCI device, while the installed module registers only
a platform-bus alias. It cannot bind this BDF or produce the required user and
C2H nodes. The conditional authorization to load an already installed module
did not require an irrelevant load. The governed decision was
`DO_NOT_LOAD_OR_BIND` and the exact blocker is `BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE`.

No `driver_override`, `new_id`, module load/unload, compilation, installation,
PCIe rescan/reset, MMIO access, or DMA operation occurred.
