# G2B-HW0-PRODUCT-R1 Authorization Receipt

## Exact grants and denials

| Contract field | Value |
|---|---|
| `OWNER_HARDWARE_AUTHORIZATION` | `GRANTED` |
| `ADDITIONAL_LEGACY_MMIO_READ_AUTHORIZATION` | `GRANTED` |
| Authorized legacy read range 1 | `0x0000..0x0030`, aligned read-only |
| Authorized legacy read range 2 | `0x0080..0x00B4`, aligned read-only |
| `LEGACY_MMIO_WRITE_AUTHORIZATION` | `DENIED` |
| G2B page | `0x3800..0x3BFF`, documented controls only |
| SRAM programming | Exactly one invocation of the verified candidate |
| PCIe recovery | At most one exact AHD-only targeted operation, conditionally |
| XDMA binding | At most one exact BDF bind, conditionally |
| Flash / reboot / power-cycle | `DENIED` / `DENIED` / `DENIED` |

Legacy and G2B accesses were contingent on T1. T1 blocked before a mapped AHD
user device existed, so the granted legacy reads and G2B controls were not
used. Reserved G2B offsets were not written.

## Actual operation accounting

| Operation | Count/result |
|---|---|
| FPGA SRAM programs | `1` |
| Automatic program retries | `0` |
| Flash / CFGMEM / PROGRAM_B operations | `0 / 0 / 0` |
| Automatic endpoint wait | `1`, read-only, no endpoint |
| Targeted PCIe recovery operations | `0` |
| PCI config writes / rescans / resets | `0 / 0 / 0` |
| XDMA module loads / unloads / exact binds | `0 / 0 / 0` |
| Legacy MMIO reads / writes | `0 / 0` |
| G2B MMIO reads / writes | `0 / 0` |
| DMA captures | `0` |
| Reboots / power-cycles | `0 / 0` |

Execution honored the mandatory stop literal `BLOCKED — SAFE_TARGETED_PCIE_RECOVERY_UNAVAILABLE`. The verified
candidate was left in volatile SRAM, `DONE=1`; no rollback image was loaded.
