# AHD v41 G1 Clock, Reset, and CDC Plan

## Clock domains

| Domain | Source / expectation | Consumers | Reset authority |
|---|---|---|---|
| PCIe reference | 100 MHz differential on D6/D5 through `IBUFDS_GTE2` | XDMA/PCIe hard block and GTP | Dedicated active-low PERST on C8 |
| XDMA user / AXI | XCI requests `axisten_freq=62.5`; actual Gen2 value is `TO_BE_VERIFIED_IN_G2/G3` | XDMA C2H/H2C interfaces, AXI-Lite bridge, MMIO extension, scheduler, formatter | `axi_aresetn`, synchronized locally |
| R1i NVP/I2C logical autonomous domain | Qualified implementation maps it to `axi_aclk`, with `CLK_HZ=62,500,000`; it is not reset by `axi_aresetn` or `user_lnk_up` | NVP POR, autoinit, I2C engine, R1i telemetry | R1i 320-cycle POR and protected NVP sequencing only |
| Video input domains | One recovered VCLK per active NVP digital output; current VDO1 XDC is 6.734 ns/148.5 MHz | Physical frontend, BT.656 parser, record producer/ring write side | Local video/capture reset, async assert and synchronous release |
| Host/control logical domain | Same physical clock as XDMA user clock | AXI-Lite bridge/control plane | `axi_aresetn` only; host-visible session state resets with XDMA |

The NVP/I2C and AXI domains are listed separately because their reset/lifecycle contracts differ even when they share a clock net.

## R1i clock protection

Qualified R1i uses `autonomous_clk = axi_aclk`, hard-codes `NVP_AUTOINIT_CLK_HZ=62500000`, and counts a 320-cycle POR. The XCI simultaneously contains a requested 62.5 MHz value and stale-looking 125 MHz interface metadata; routed evidence measured 62.5 MHz. Therefore:

1. G2A preserves the exact R1i clock mapping and constants.
2. Gen2 configuration must retain requested `CONFIG.axisten_freq=62.5`.
3. G2A must inspect the regenerated IP clock and implemented clock period. If it is not exactly the qualified 62.5 MHz expectation, G2A stops before bitstream acceptance; constants are not silently retimed.
4. G3 must measure clock availability/frequency across PERST, link-down, retrain, and host reset.
5. R1i POR, NVP reset, autoinit start, I2C progress, and final settle must never be gated by `user_lnk_up`, `axi_aresetn`, DMA enable, driver state, or host commands.

The current physical dependency on XDMA's `axi_aclk` is explicit qualification debt, not permission to add further PCIe dependencies. If the Gen2 core cannot supply a continuous qualified clock, a separate owner-approved clock-source redesign/qualification gate is required. The repository does not expose a proven alternate 62.5 MHz clock, and the prior `IBUFDS_GTE2.ODIV2`/BUFG topology is not to be resurrected by inference.

## Reset hierarchy

- `sys_rst_n`/PERST resets the XDMA core and causes `axi_aresetn` assertion.
- `axi_aresetn` resets AXI-Lite, the C2H formatter/scheduler, DMA descriptors, new MMIO session counters, and application stream state.
- PERST/`axi_aresetn` does **not** reset or restart the R1i NVP/I2C engine.
- R1i `nvp_por_reset` controls the protected NVP power/reset/autoinit sequence.
- `INIT_DONE/INIT_ERROR` releases or holds video application logic through a locally synchronized video reset; it does not reset PCIe.
- PCIe stream reset is synchronized into each active video domain to flush DMA rings/admission. It is application-plane reset only and must not drive NVP chip reset or I2C reset.
- Reset assertion may be asynchronous where required for safety; every deassertion is synchronized with at least two stages, four where the existing XPM contract already uses four.

## Required CDC boundaries

| Crossing | Required mechanism | Rule |
|---|---|---|
| SCL/SDA pads to NVP clock | Exact R1i two-flop synchronizers, `ASYNC_REG=TRUE`, shift extraction disabled, then three-sample filter | Protocol decisions use filtered signals only; do not touch in G2. |
| `INIT_DONE/INIT_ERROR` to each video clock | Two-flop status synchronizer plus local reset synchronizer | No combinational async fanout into video logic. |
| AXI channel config to video domain | Request/ack mailbox or asynchronous command FIFO with bundled data held through acknowledgement | Apply only while disabled/drained; count rejects. |
| Record data video to AXI | Dual-clock block RAM; video writes, AXI reads | Ownership, generation, slot, and epoch must match before read. |
| Commit descriptor video to AXI | Small asynchronous FIFO or proven toggle/bundled-data handshake | Descriptor is stable from commit until synchronized release. |
| Slot release AXI to video | Per-slot toggle/acknowledgement synchronization | Release only after beat 511 handshake. |
| Stream reset/epoch AXI to video and ack back | Async-assert/sync-release reset plus explicit epoch handshake | Admission remains off until both sides agree on epoch. |
| Monotonic diagnostic counters video to AXI | Registered Gray code through two synchronizers for live approximate status | Source register precedes Gray synchronizer; decode only after second stage. |
| Coherent multiword counters/status | Snapshot request/ack handshake | Low/high MMIO words come from one frozen snapshot. |
| Video/source event pulses | Toggle synchronizer or event counter | Never use a one-cycle pulse directly across domains. |
| NVP/PCIe reset indications into monitoring | One source register per reset synchronizer | Preserve the existing one-source/one-synchronizer topology to avoid CDC-11 fanout. |

## C2H clocking

The C2H AXI stream is synchronous to XDMA `axi_aclk`; no AXI-stream clock converter is introduced. The scheduler, RAM read side, prefetch/skid stage, `TVALID/TREADY/TKEEP/TLAST`, and streamed counters all use that clock. Only committed records cross from video domains through storage/descriptor CDC.

The existing absolute CDC constraints (6 ns max delay and 3 ns bus skew) are hierarchy- and clock-sensitive. G2A/G2B must prove every query resolves and re-evaluate them against the regenerated actual clock. Generated IP clocks, clock interaction, reset recovery/removal, and asynchronous paths require explicit reports; textual XDC identity is not sufficient.

## Host reset effects

Driver unload, function reset, link reset, or PERST may terminate a DMA session. The stream plane increments a reset epoch, flushes queued/in-flight descriptors, counts abandoned records, and requires host re-enable after link/control recovery. It does not power-cycle NVP, pulse `nvp_rst`, replay autoinit, or clear protected R1i diagnostic history. A clean post-reset stream always restarts at record beat 0.

## Verification obligations

Later gates must run structural CDC, reset-recovery/removal, clock-interaction, generated-clock, and bus-skew checks; simulate independent reset orderings; verify no stale slot crosses an epoch; and demonstrate that NVP initialization proceeds under every permitted PCIe reset/link state. Any accidental `user_lnk_up`/`axi_aresetn` dependency in the NVP path is a gate failure.
