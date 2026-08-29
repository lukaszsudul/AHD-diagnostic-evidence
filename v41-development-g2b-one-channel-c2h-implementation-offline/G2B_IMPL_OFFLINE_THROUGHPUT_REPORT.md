# AHD v41 G2B-IMPL Offline Throughput Analysis

## Scope and claim boundary

This report is theoretical and offline-only. It uses the frozen
`AHD_C2H_TRANSPORT_ABI_V1` record geometry and the generated G2A/G2B
post-synthesis `userclk1` timing object at 62.5 MHz. It is not hardware DMA
evidence and does not prove negotiated PCIe link state, sustained XDMA
behavior, host-memory performance, real-video capture rate, or the required
288 MB/s application payload on hardware.

`HARDWARE_THROUGHPUT_PROVEN = NO`

## Frozen record arithmetic

| Quantity | Value |
|---|---:|
| Total record bytes | 4,096 |
| Header bytes | 64 |
| UYVY payload bytes | 3,840 |
| Zero-padding bytes | 192 |
| AXI beats | 512 |
| Bytes per beat | 8 |
| Payload efficiency | 3,840 / 4,096 = 93.75% |
| Total non-payload overhead | 256 / 4,096 = 6.25% |
| Header fraction | 64 / 4,096 = 1.5625% |
| Padding fraction | 192 / 4,096 = 4.6875% |

## Requirement conversion

The frozen application-payload requirement remains at least 288,000,000
bytes/s. At 3,840 payload bytes per record, this requires exactly 75,000
records/s. Those records consume 307,200,000 transport bytes/s, of which
19,200,000 bytes/s are header and padding overhead.

## Interface and Gen2 x1 ceilings

At 62.5 MHz and 8 bytes per AXI beat, the ideal application stream ceiling is
500,000,000 transport bytes/s. This corresponds to 122,070.3125 complete
records/s and 468,750,000 payload bytes/s before PCIe/XDMA/host effects.

PCIe Gen2 x1 is 5 GT/s with 8b/10b encoding, giving a 500,000,000-byte/s raw
encoded-lane ceiling before protocol overhead. The required 307,200,000
transport bytes/s is 61.44% of that raw ceiling and leaves 192,800,000 bytes/s
of raw arithmetic headroom.

## Disposition

The frozen geometry is theoretically compatible with the required application
payload on the 64-bit/62.5 MHz interface and a Gen2 x1 raw lane. Protocol
overhead, XDMA efficiency, PCIe transaction behavior, host memory, driver
behavior, source cadence, and backpressure reduce the practical rate.
Accordingly this calculation is an offline readiness input only. The 288 MB/s
requirement remains unproven until a later authorized hardware gate measures
real bounded and sustained captures.
