# G2B-HW0-DRV-REUSE0 Final DUT State

Final read-only capture: `2026-09-06T11:22:53Z`.

## Identity and preserved endpoint

| Property | Final value |
|---|---|
| Logical host / hostname / address | `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111` |
| Machine ID | `0e90f50d9465492b80258da5658446f8` |
| Authenticated user | `vcdeagent1` |
| Architecture | `x86_64` |
| Boot ID | `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac` |
| Kernel | `7.0.0-29-generic` |
| Endpoint | `0000:01:00.0`, present |
| Vendor/device | `10ee:7011` |
| Subsystem | `10ee:0007` |
| Modalias | `pci:v000010EEd00007011sv000010EEsd00000007bc05sc80i00` |
| Driver | `UNBOUND` |
| `driver_override` | `(null)` |
| Link | `5.0 GT/s PCIe`, width `1` |
| `xdma` module | `NOT LOADED` |
| `/dev/xdma*` nodes | `0` |
| Concurrent relevant mutator | `NONE DETECTED` |

The boot ID matches the initial fresh audit capture. The endpoint, link, driver state, module state, override, and node count also match. The audit did not change hardware state.

## Operation ledger

| Operation | Count / state |
|---|---|
| Module loads | `0` |
| Module unloads | `0` |
| Driver binds | `0` |
| Driver unbinds | `0` |
| `driver_override` writes | `0` |
| PCI rescans/resets | `0` |
| MMIO reads/writes | `0 / 0` |
| DMA operations | `0` |
| Driver builds/rebuilds | `0` |
| Package installations/changes | `0` |
| FPGA SRAM programs | `0` |
| Flash programs | `0` |
| Reboots | `0` |
| Power cycles | `0` |

## Protected state

- Endpoint bound by this task: `NO`.
- XDMA nodes created by this task: `NO`.
- AHD source repository modified: `NO`.
- HDMI source repository modified: `NO`.
- AHD SSOT modified: `NO`.
- HDMI SSOT modified: `NO`.
- Existing platform module modified: `NO`.
- Governed HDMI module moved or rewritten: `NO`; its governed DUT path was absent.
- Exact PRODUCT candidate: no FPGA operation was performed; this audit makes no new SRAM-content inference beyond the accepted R2 record.

Raw proof is in `G2B_HW0_DRV_REUSE0_FINAL_DUT_READONLY_STATE.log`.
