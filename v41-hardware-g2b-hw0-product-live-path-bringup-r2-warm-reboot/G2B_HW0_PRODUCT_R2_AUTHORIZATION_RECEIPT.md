# G2B-HW0-PRODUCT-R2 Authorization Receipt

| Authorization or boundary | Contract | Actual |
|---|---|---|
| Owner hardware authorization | `GRANTED` | `HONORED` |
| Owner warm-reboot authorization | `GRANTED` | `HONORED` |
| Maximum warm reboots | `1` | `1` |
| Power-cycle authorization | `DENIED` | `0` |
| SRAM reprogramming in R2 | `DENIED` | `0` |
| Flash programming | `DENIED` | `0` |
| Legacy MMIO reads | `GRANTED` | `0`, because T2 was not reached |
| Legacy MMIO writes | `DENIED` | `0` |
| Documented G2B control writes | only `0x3800..0x3BFF` after T1 | `0` |
| XDMA module load | at most one only if safe and relevant | `0` |
| Exact AHD bind | at most one only if safe | `0` |
| Second reboot | not authorized | `0` |
| PCIe rescan/reset | not authorized | `0` |
| Power cycle | not authorized | `0` |

The only remote reboot command was a normal graceful operating-system warm
reboot. The earlier controller-local wrapper rejection launched no child
process and delivered no remote command, so it did not consume a warm reboot.
The one successful remote delivery exhausted the authorized reboot budget.

The installed platform-only `xdma` module was not loaded because it could not
bind `0000:01:00.0`. No driver override, `new_id`, compilation, installation,
module replacement, global unload, or unrelated-device operation occurred.
First blocker: `BLOCKED — SAFE_AHD_XDMA_BIND_UNAVAILABLE`.
