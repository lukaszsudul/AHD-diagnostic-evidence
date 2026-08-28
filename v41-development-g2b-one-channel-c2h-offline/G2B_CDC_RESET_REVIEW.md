# AHD v41 G2B CDC and Reset Review

## Review result

`BLOCKED PRE-IMPLEMENTATION REVIEW`

No G2B CDC or reset RTL exists to statically verify. The required architecture was reviewed, but structural CDC, reset-recovery/removal, clock-interaction, bus-skew, generated-clock, and reset-order simulations were not run because implementation stopped at `G2B_RECORD_ABI_NOT_FROZEN`.

## Authorities

Read-only G1 evidence root in this clean evidence clone:

`v41-development-g1-integration-architecture/`

- `V41_G1_CLOCK_RESET_CDC_PLAN.md`
- `V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md`
- `V41_G1_ONE_CHANNEL_DMA_CONTRACT.md`
- `V41_G2_IMPLEMENTATION_CONTRACT.md`

Accepted source base: commit `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`.

## Clock-domain receipt

| Domain | G2B role | Reset authority |
|---|---|---|
| PCIe reference, 100 MHz differential | XDMA/PCIe hard block | dedicated active-low PERST |
| XDMA user/AXI, accepted effective 62.5 MHz | C2H AXIS, AXI-Lite, formatter, ring read side, counters | synchronized `axi_aresetn` |
| R1i NVP/I2C logical autonomous lifecycle | protected POR, autoinit, I2C, telemetry; may share `axi_aclk` net | protected R1i sequencing only; never `axi_aresetn` or link-up |
| VDO1 recovered video clock, G1 expectation 148.5 MHz | frontend, BT.656 parser, record producer, ring write side | local application/video reset, async assertion and synchronous release |

No new application clock or AXI-stream clock converter is permitted. All C2H AXIS signals and formatter state remain synchronous to accepted `axi_aclk`.

## Required crossings for a future implementation

| Crossing | Required mechanism | Review rule |
|---|---|---|
| `INIT_DONE/INIT_ERROR` to VDO1 clock | two-flop status synchronizer plus local reset synchronizer | no combinational asynchronous fanout |
| AXI control/config to video domain | acknowledged mailbox or async command FIFO with bundled data held through ack | apply only while disabled/drained |
| Record data video→AXI | dual-clock block RAM | video writes; AXI reads only an owned matching slot |
| Commit descriptor video→AXI | small async FIFO or proven toggle/bundled-data handshake | channel/slot/generation/epoch stable until release |
| Slot release AXI→video | per-slot toggle/ack synchronizer | release only after beat-511 handshake |
| Stream reset/epoch AXI↔video | async-assert/sync-release plus explicit epoch handshake | admission off until both domains agree |
| Live monotonic counters video→AXI | source-registered Gray code through two synchronizers | approximate status only |
| Coherent multiword status/counters | snapshot request/ack handshake | low/high words from one frozen snapshot |
| Source event pulses | toggle synchronizer or event counter | no direct one-cycle pulse crossing |

Any future implementation must also prove ownership, slot generation, and epoch match before a read; no stale descriptor may cross an epoch.

## Reset behavior required by G1

- PERST/`axi_aresetn` may reset the application stream plane: formatter, fixed scheduler path, descriptors, DMA slot ownership, and new MMIO session counters.
- It must not reset, start, gate, or replay the protected R1i NVP/I2C autoinit engine.
- A link/user reset flushes queued and in-flight DMA state, increments the stream reset epoch, counts abandoned records, and requires host re-enable.
- Capture admission remains disabled until the video domain acknowledges the new epoch.
- The first post-reset C2H output must begin at beat 0 of a new complete record; no old suffix may be published.
- NVP/source loss aborts only an uncommitted source record and propagates a discontinuity; it does not permit partial C2H truncation.
- Reset assertion may be asynchronous where safety requires; every deassertion is synchronized with at least two stages, or four where the existing XPM contract uses four.

## Unresolved reset/record coupling

The CDC mechanisms are architecturally specified, but the record ABI does not say how its two new sequences behave across an epoch:

- C2H architecture lines 69–70 define the attempt/global sequence fields without reset/initial/wrap values.
- C2H architecture line 118 requires a new reset epoch and a new complete record after reset.
- One-channel contract line 32 says the first record carries the epoch in “MMIO/header context,” but no header word is allocated to the epoch.
- Clock/reset plan line 61 requires epoch increment and stream restart but does not resolve the record encoding.

CDC RTL cannot safely assign or transport those externally visible values until the ABI authority resolves them.

## Static review status

| Check | Status |
|---|---|
| G1 CDC architecture read | `COMPLETE` |
| Source/AXI domains identified | `COMPLETE` |
| New data CDC structural check | `NOT RUN — NO RTL` |
| New control CDC structural check | `NOT RUN — NO RTL` |
| Reset CDC/recovery-removal | `NOT RUN — NO RTL` |
| Counter/status CDC | `NOT RUN — NO RTL` |
| Bus-skew/XDC query resolution | `NOT RUN — NO RTL` |
| Independent reset-order simulation | `NOT RUN — NO RTL` |
| R1i protected reset independence regression | `NOT RUN — NO SOURCE CHANGE` |

This document is a requirements receipt, not evidence that G2B CDC/reset implementation passes.
