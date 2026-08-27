# AHD v41 G1 Gen2 XDMA Change Plan

## Decision and exact delta

Qualified R1i and the primary donor contain byte-identical XDMA XCI, configuration helper, and active PCIe XDC. G2A shall change one intentional XDMA user property:

```tcl
CONFIG.pl_link_cap_max_link_speed {2.5_GT/s}
```

to:

```tcl
CONFIG.pl_link_cap_max_link_speed {5.0_GT/s}
```

This change must appear in both:

- `ip/v41/xdma_v41_m1.xci`, component parameter `pl_link_cap_max_link_speed`; and
- `scripts/v41/xdma_config_common.tcl`, because the build reapplies the dictionary and would otherwise force Gen1.

The generated model encoding `PL_LINK_CAP_MAX_LINK_SPEED` is expected to move from `1` to `2` when Vivado regenerates the IP. It is generated output and shall not be hand-edited. Generated checksums/content may change as a consequence; every effective `CONFIG.*` property is diffed and any unexplained user-property delta is a stop.

## Properties that remain unchanged

| Area | Frozen value |
|---|---|
| IP/version | `xilinx.com:ip:xdma:4.2`, revision 2 |
| FPGA | `xc7a35tcsg325-2` |
| PCIe block | `X0Y0` |
| Link width | `X1` |
| Reference clock | `100_MHz` differential |
| Free-run frequency property | `100_MHz` |
| DMA interface | AXI4-Stream |
| AXI stream width | 64 bits; 8-bit `TKEEP` |
| Requested AXI stream clock | `axisten_freq=62.5` (actual behavior below) |
| C2H engines | one (`xdma_wnum_chnl=1`) |
| H2C engines | one mandatory unused engine (`xdma_rnum_chnl=1`) |
| H2C application policy | Unsupported; application `TREADY=0`; host must not submit H2C |
| User interrupts | one |
| Interrupt capability | MSI enabled, one vector; MSI-X disabled |
| AXI-Lite master | enabled, 32-bit, 128 KiB aperture at zero |
| User BAR/driver-visible architecture | unchanged; observed user BAR0 128 KiB and XDMA configuration aperture 64 KiB |
| Vendor/device | `10EE:7011` |
| Subsystem | `10EE:0007` |
| Class code | `058000` |
| PERST | dedicated, active low |
| Bypass/debug/MM DMA | disabled |
| Extended tags | enabled as in donor |

The property helper currently does not assert every invariant. G2A shall add a read-only assertion list for at least `axisten_freq`, `dedicate_perst`, MSI/MSI-X, BAR enables/sizes, IDs/class, interface/width, C2H/H2C counts, IRQ count, and disabled bypass/debug modes. These checks shall not change invariant values.

## Clock expectation

`TO_BE_VERIFIED_IN_G2/G3`

Repository evidence is internally inconsistent: component property `axisten_freq` is 62.5, generated interface metadata says 125 MHz, and routed/hardware-correlated evidence measured approximately 62.5 MHz and explicitly corrected the old 125 MHz assumption. Gen2 may also alter clock availability/reset sequencing even if nominal frequency remains unchanged.

G2A shall request 62.5 MHz, inspect generated clocks and post-route periods, and stop if effective `axi_aclk` is not the qualified 62.5 MHz expectation. G3 later measures frequency and lifecycle across PERST/link states. No NVP timing constant may be silently rescaled.

## Top-level and reset wiring

Top-level PCIe lane, refclock, PERST, AXI-Lite, one C2H, mandatory H2C, config-management, and IRQ ports remain structurally the same. In G2A the C2H application signals remain at their existing safe inactive tie-off; G2B replaces only that tie-off with the reviewed adapter. H2C remains backpressured.

`sys_rst_n` continues through the dedicated input buffer to XDMA. `axi_aresetn` resets AXI/MMIO/C2H application logic. NVP autoinit remains outside `axi_aresetn` and `user_lnk_up` control; its current use of `axi_aclk` is an explicit verification condition.

## XDC and timing

No intentional active board-XDC text change is required for Gen2 x1. The same one-lane pin/GT/refclock/PERST locations remain. The inactive legacy vendor PCIe XDC is not introduced.

IP regeneration may change generated internal clocks, exceptions, clock buffers, reset logic, soft logic, placement pressure, and route timing. G2A must run and archive generated-clock, clock-interaction, setup/hold, CDC, reset, DRC, route, congestion, and utilization reports. The existing 6 ns CDC max-delay and 3 ns bus-skew constraints are revalidated against resolved objects and the actual clock.

## Host compatibility

No PCI ID, BAR ABI, driver ABI, channel count, node naming, interrupt mode, or driver installation change is expected. The existing pinned XDMA driver is reused after ordinary environment validation. A later hardware validation script changes its expected negotiated speed from 2.5 GT/s to 5.0 GT/s and continues requiring width x1. It must capture endpoint and parent capabilities/status rather than checking only one string.

## Resource impact

Gen2 retains the same PCIe hard block, one GTP lane/common, and stream width, but the generated soft-logic/routing/resource delta is `UNKNOWN` because no repository Gen2 build exists. Measured Gen1 XDMA standalone use was 10,773 LUT, 12,062 FF, and 21.5 BRAM tiles. G2A records a before/after hierarchical delta; no zero-cost assumption is permitted.

## G2A acceptance for the change

The Gen2 configuration portion passes only if the speed property is the sole explained user-property delta, every invariant holds, requested/effective clock evidence is acceptable, active XDC resolution is clean, timing/DRC/CDC/routing/resource gates pass, and source/runtime provenance is sealed. Link training and throughput are later hardware gates, not G2A claims.
