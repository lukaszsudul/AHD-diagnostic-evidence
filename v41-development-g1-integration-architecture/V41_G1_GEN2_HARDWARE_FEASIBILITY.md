# AHD v41 G1 Gen2 Hardware Feasibility

## Disposition

`G2_IMPLEMENTATION_ALLOWED`

This authorizes an offline Gen2 x1 XCI/build attempt only. It does not claim 5 GT/s training, board signal-integrity margin, host compatibility, DMA correctness, or 288 MB/s.

## Repository evidence

| Area | Evidence | Finding |
|---|---|---|
| FPGA/PCIe block | `xc7a35tcsg325-2`, Series-7 PCIe hard block `PCIE_X0Y0`, XDMA 4.2 | Repository/G0 device audit supports a Gen2 x1 candidate on the -2 device. |
| Lane count | Top ports are `[0:0]`; RX G4/G3, TX B2/B1; `GTPE2_CHANNEL_X0Y3`, common `X0Y0` | Exactly one routed lane is evidenced. No x2/x4 fallback is claimed. |
| Reference clock | Differential D6/D5, `IBUFDS_GTE2_X0Y0`, 10.000 ns constraint | Required 100 MHz architecture is present and proven at Gen1. |
| Reset | C8, LVCMOS33 pull-up, dedicated active-low input to XDMA | Direct PERST path is present and proven at Gen1. |
| Connector/PCB | No schematic, layout, connector declaration, insertion-loss/SI or compliance artifact in repository | 5 GT/s physical margin is an evidence gap, not a contradiction. |
| Host root port | Accepted ASUS/AMD platform and Gen1 x1 negotiation; exact parent `LnkCap` block absent | Platform is plausibly capable, but exact 5 GT/s capability/negotiation is unproven. |
| XDC | Active `xdma_pcie.xdc` and historically named `pcie_pio.xdc` bind the existing lane/refclk/reset/hard-block sites | No intentional board-XDC delta is indicated for Gen2 x1. |

Qualified R1i and the donor used the same lane/refclock/reset XDC and the same XCI. Existing Gen1 operation demonstrates continuity, polarity, basic reset, connector insertion, and lane mapping; it does not establish Gen2 eye margin.

## Missing evidence that does not block G2A

- Board schematic and PCB layout.
- Mechanical connector-width declaration.
- 5 GT/s insertion-loss/crosstalk/compliance analysis.
- Endpoint and parent root-port `LnkCap` read-back.
- Gen2-configured IP generation and implementation reports.
- 5.0 GT/s x1 negotiation, retrain, reset, AER, and long-run evidence.
- Application C2H transfer and sustained throughput evidence.

No repository artifact contradicts the existing single lane operating at 5 GT/s. Per the gate rule, missing schematic/SI evidence is recorded as a later validation gap rather than invented as a PCB blocker.

## Required later hardware validation

After separately authorized hardware work, capture endpoint and parent `LnkCap/LnkSta`, sysfs current/max speed and width, negotiated 5.0 GT/s x1, PERST/function-reset/retrain behavior, AER/replay/recovery counters, repeated cold/warm enumeration, and a declared-duration stable-link run. Board/SI review becomes mandatory if 5 GT/s training is unstable or error counters rise.

## Boundaries

- Wider than x1 is not supported by current repository lane evidence.
- A Gen2 link-up is not DMA correctness.
- DMA correctness is not 288 MB/s qualification.
- G8 alone qualifies sustained application payload.

The correct G1 feasibility result is therefore `G2_IMPLEMENTATION_ALLOWED`, with explicit later board/host/link validation.
