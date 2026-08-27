# AHD v41 G1 Two-Channel DMA Architecture

## Product boundary

The product has four physical video inputs and permits at most two simultaneously active logical channels. Two selectors map distinct physical input IDs `0..3` to logical channels 0 and 1. Selection is changed only while a channel is disabled and drained. The DMA architecture is independent of which two inputs are selected.

Repository evidence proves only the current VDO1 digital path. It does not prove the exact second NVP output mode or FPGA pin mapping. That is a later physical-ingress qualification item; it is not silently invented here and does not alter the chosen C2H/scheduler architecture. G2B is deliberately one-channel.

## Alternatives

| Criterion | A — one common FIFO with tagged records | B — two independent XDMA C2H channels | C — per-channel rings plus one C2H scheduler |
|---|---|---|---|
| FPGA resource cost | Lowest control cost, but a shared eight-record store is still required; one busy source can consume all elasticity. | Highest and unmeasured: second XDMA engine/channel state, duplicate formatter/host queues, and extra routing; no x1 line-rate increase. | Moderate and predictable: one existing C2H engine, two four-record rings, one small record scheduler and one formatter. |
| Host complexity | One node/parser, but source fairness and loss attribution are weak. | Two device nodes, two readers/queues, cross-channel timing merge, and separate failure handling. | One node/parser with explicit tags and one global order; per-channel counters remain independent. |
| Throughput efficiency | Good with 4 KiB records; head-of-line and monopolization can increase drops. | Good per stream, but both share the same Gen2 x1 link and descriptor scheduling may add overhead. | Good: 4 KiB packets, work-conserving service, no beat interleave, one descriptor stream. |
| Ordering | Total order only; source fairness not guaranteed. | Per-channel order only; host must construct any total order. | Per-channel sequence plus explicit global streamed order. |
| Backpressure | Shared pool couples both channels immediately. | Channel queues isolate application backpressure, but link/core congestion remains common. | Channel-local rings isolate short stalls/drops; a prolonged shared-link stall eventually fills both. |
| Failure isolation | Weak; one producer can consume the pool. | Strongest at engine/node level. | Strong for buffer/overflow/accounting, shared at formatter/XDMA/link level. |
| Scalability | Tag field scales, but fairness degrades without adding a scheduler—becoming C. | More engines scale poorly on this device and x1 link. | Two active channels are native; four physical selections require no extra C2H engines. |

## Selected model

**Model C: one Gen2 x1 XDMA C2H channel, two private four-record rings, channel-tagged fixed-size records, and work-conserving round-robin arbitration at record boundaries.**

Resource cost and the 288 MB/s requirement dominate this choice. A second XDMA channel consumes scarce LUT/routing resources without increasing the bandwidth of the one physical PCIe lane. A single unpartitioned FIFO is slightly simpler but allows one input to destroy the other input's buffering and makes loss isolation weaker. Model C spends BRAM—which has materially more headroom than LUT—on deterministic per-channel elasticity and keeps only one formatter/engine.

## Exact scheduler behavior

- Eligible means channel enabled, complete descriptor queued, matching reset epoch, and no sticky ownership/protocol fault.
- With one eligible channel, select it immediately.
- With both eligible, select the channel after the most recently completed channel; reset preference is channel 0.
- Lock `(channel, slot, generation, epoch)` from the first offered beat through the beat-511 handshake.
- Never interleave beats from two records.
- On completion, increment the global streamed sequence, release only the selected slot, and rotate preference.
- Equal-size records make simple round-robin byte-fair. No weighted policy is needed for the frozen 4 KiB format.
- An errored channel is removed from eligibility; the healthy channel may continue. A shared formatter/XDMA fault stops both.

## Buffer and resource structure

Each active logical channel has four 4,096-byte slots: 16 KiB and four RAMB36 storage primitives as a structural lower bound. The two-channel DMA store is therefore eight RAMB36 primitives plus small descriptor storage, before synthesis packing. Existing legacy PIO storage is retained separately. The second video frontend/record producer and its clocking are expected to cost more LUT/routing than the scheduler; exact costs are `UNKNOWN` until later synthesis.

## Backpressure and failure isolation

XDMA `TREADY` stalls the selected record in place. The unselected channel can continue filling only its own ring. A full channel drops only its own next record and cannot borrow/overwrite the other channel's slots. Per-channel attempt sequences and drop counters identify the loss; global sequence represents only successfully streamed records. A permanent host/link stall ultimately fills both rings, which is correctly reported as two independent source overflows plus a shared C2H stall condition.

## Selection control

The host writes desired physical IDs and enable bits, then issues an atomic apply command. Hardware accepts only IDs 0 through 3, rejects duplicate enabled selections, and requires both affected channels disabled/drained. Applied selections are read back with a generation number. Mid-record switching, automatic source substitution, and implicit remapping are forbidden.

## Physical-ingress requirement for the later two-channel gate

Before two-channel RTL or hardware qualification, later work must prove one of the following from board/NVP evidence: two independently clocked NVP digital outputs with valid pins/constraints, or an explicitly specified two-channel multiplexed output with a proven demultiplexing/channel-ID contract. R1i's qualified one-port/one-channel initialization is not edited by inference. Any post-R1i output-map programming requires its own reviewed NVP transaction and qualification plan while retaining the R1i I2C safety shell.

## Host model

One reader drains `/dev/xdma*_c2h_0`. It demultiplexes records by logical ID, validates physical mapping, checks per-channel attempt sequences, and checks the global sequence. Separate per-channel files/consumers are host-policy outputs, not separate DMA engines. Throughput is computed from the sum of valid payload bytes for the two active channels.

## Qualification boundary

This selection is frozen for later implementation. It does not claim that the second physical ingress exists, that Gen2 trains, or that 288 MB/s is achieved. Those remain later-gate measurements.
