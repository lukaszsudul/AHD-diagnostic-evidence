# AHD v41 G1 C2H Data-Plane Architecture

## Decision

The product data plane shall use one XDMA C2H AXI4-Stream channel, a four-record dual-clock ring for each active logical video channel, and record-boundary arbitration. The existing 4,096-byte/512-beat transport geometry is retained because it is naturally aligned, has no partial final beat, and amortizes PCIe overhead. The single-channel v40B record header is not sufficient for a two-channel stream, so C2H uses a versioned, channel-tagged `v41D` header while the legacy v40B PIO record and parser remain unchanged.

```text
selected physical input 0..3
  -> protected NVP/output configuration boundary
  -> video physical frontend (8-bit at recovered VCLK)
  -> BT.656 line parser / record producer
  -> channel-local four-slot 4 KiB dual-clock record ring
  -> channel descriptor CDC queue
  -> record-boundary round-robin scheduler
  -> 64-bit C2H formatter with two-beat prefetch/skid storage
  -> XDMA S_AXIS_C2H_0
  -> PCIe Gen2 x1
  -> host /dev/xdma*_c2h_0 reader and record validator
```

The legacy PIO capture mode and DMA streaming mode are mutually exclusive. The donor record producer may be extended with a streaming mode, but its legacy behavior and byte-exact v40B output must remain unchanged when DMA mode is disabled. DMA records use separate storage so C2H cannot steal the legacy PIO RAM read port or change protected MMIO latency.

## New RTL blocks required in a later implementation gate

| Block | Clock domain | Exact role |
|---|---|---|
| `v41_dma_record_sink` | one instance per active video clock | Admits only whole records, writes a selected free slot, creates the commit descriptor, increments attempt/commit/drop counters, and marks a discontinuity after a drop. |
| `v41_dma_record_ring` | write: video clock; read: XDMA user clock | Four 4,096-byte slots per logical channel using one 64-bit dual-clock block-RAM bank per slot, plus ownership generation/epoch state. |
| `v41_record_commit_cdc` | video to XDMA and return | Transfers committed slot descriptors with a bundled-data/toggle or asynchronous-FIFO protocol and returns release acknowledgements only after beat 511 is accepted. |
| `v41_c2h_record_scheduler` | XDMA user clock | Work-conserving round-robin selection between non-empty enabled channels; locks selection for the complete 512-beat record. |
| `v41_c2h_record_formatter` | XDMA user clock | Reads the selected slot, substitutes the v41D version/channel fields, drives AXI4-Stream, and enforces all framing invariants. |
| `v41_c2h_counter_bank` | XDMA user clock, with source snapshots | Holds global/channel streamed-byte, stall, protocol, reset-epoch, interrupt, and error counters. |
| `v41_mmio_extension_router` | XDMA user clock | Transparently passes all existing addresses to the exact R1i register block and intercepts only the new `0x3800..0x3BFF` pages. |
| `v41_c2h_irq_latch` | XDMA user clock | Optional advisory IRQ0 request, held until XDMA acknowledgement; correctness never depends on the interrupt. |

Names are contractual role names; G2 may adjust syntax but must not combine clock-domain ownership in a way that weakens these boundaries.

## Source and record contract

- Source input: 8-bit BT.656 byte stream in each active recovered-video-clock domain.
- Source payload: 3,840 UYVY bytes from one validated active video line.
- Stored/output record: exactly 4,096 bytes.
- Header: 64 bytes.
- Payload: bytes `64..3903`, exactly 3,840 bytes.
- Final area: bytes `3904..4095`, exactly 192 zero bytes.
- AXI output: 64 bits, 512 accepted beats per record.
- Byte mapping: record byte `8*n+k` maps to `TDATA[8*k +: 8]` on beat `n`.

### v41D header

All fields are little-endian 32-bit words. Existing v40B fields keep their meaning unless stated otherwise.

| Offset | v41D value |
|---:|---|
| `0x00` | Magic `0x4C444841` |
| `0x04` | DMA record version `0x00004101` |
| `0x08` | Firmware/build ID |
| `0x0C` | Source frame sequence |
| `0x10` | Source line sequence |
| `0x14` | Source capture sequence |
| `0x18` | Useful payload length, `3840` |
| `0x1C` | Existing v40B flags, including valid/discontinuity/overflow/malformed context |
| `0x20` | Active logical-channel count at admission (`1` or `2`) |
| `0x24` | Source slot generation and slot number, retained for provenance/debug |
| `0x28` | Source malformed-record count snapshot |
| `0x2C` | Source dropped-record count snapshot |
| `0x30` | Logical channel ID (`0` or `1`) |
| `0x34` | Selected physical input ID (`0..3`) |
| `0x38` | Per-channel attempt sequence; increments on every admitted or whole-record-dropped attempt |
| `0x3C` | Global streamed-record sequence assigned by the scheduler |

The formatter patches only beats 0, 6, and 7 as needed; payload and other donor fields remain byte-identical. A host must select the parser by the version at `0x04`. The existing v40B golden record remains the regression oracle for legacy mode; a new v41D golden record is required in G2B.

## AXI4-Stream rules

- `TKEEP=8'hFF` on every beat.
- `TLAST=0` for beats 0 through 510 and `TLAST=1` only on beat 511.
- The first `TVALID` is not asserted until a complete committed record and its descriptor are owned in the XDMA clock domain.
- Once a record starts, the source does not intentionally insert bubbles. Synchronous RAM latency is hidden by a two-beat prefetch/skid stage.
- A beat index advances only on `TVALID && TREADY`.
- While `TVALID && !TREADY`, `TDATA`, `TKEEP`, and `TLAST` remain stable and the stall-cycle counter increments.
- The selected channel and slot remain locked until the beat-511 handshake.
- Slot ownership returns to the video domain only after that final handshake.
- A missing/early/late `TLAST`, illegal `TKEEP`, descriptor/slot generation mismatch, unexpected channel switch, or counter invariant failure increments `STREAM_PROTOCOL_ERRORS`, latches a cause code, and stops new packet admission until reset or an approved clear operation. An in-flight packet is never silently truncated.

## Backpressure, overflow, and drop policy

Video cannot be backpressured. XDMA backpressure therefore consumes committed slots. Each logical channel owns four slots; one channel cannot consume the other channel's storage. At the next eligible record boundary, if that channel has no free slot:

1. no byte of the new record is written or offered to C2H;
2. the per-channel attempt sequence increments once;
3. `DROPPED_RECORDS[channel]` and `FIFO_OVERFLOW[channel]` increment once;
4. global dropped/overflow counters increment once;
5. the next admitted record carries the existing discontinuity/overflow context; and
6. the other channel remains independently serviceable.

Partial-record drop, overwrite-oldest, and cross-channel slot borrowing are forbidden. Arbitrarily long `TREADY` deassertion may ultimately cause whole-record drops, but it may not corrupt the in-flight record. G8 requires all drop and overflow counters to remain zero.

Four slots provide 16,384 bytes per channel. At a planning load of 153.6 MB/s of transported record bytes per channel, this is about 106.7 microseconds of channel-local buffering. It is a bounded elasticity provision, not proof against host stalls.

## Counters and error handling

Minimum global counters are committed records, streamed records, record bytes, useful payload bytes, dropped records, FIFO overflows, C2H stall cycles, protocol errors, DMA/reset events, IRQ requests/acknowledgements, H2C attempts, and the last global sequence. Each channel also exposes state, physical selection, attempts, commits, streams, drops, overflows, source frame/line/capture sequence, last streamed attempt sequence, FIFO occupancy/high-water mark, and sticky error cause.

Counters are wrapping 64-bit for bytes/cycles and wrapping 32-bit for records/events. MMIO provides a coherent snapshot protocol; software never infers a 64-bit value from independently changing low/high words. Sticky error bits use write-one-to-clear only in the new page and do not alter R1i telemetry.

The following invariant is checked modulo counter width outside reset:

```text
attempted = committed + dropped + currently-being-built
committed = streamed + queued + in-flight
useful_payload_bytes = streamed * 3840
record_bytes = streamed * 4096
```

## Reset behavior

PERST/XDMA user reset flushes the scheduler, formatter, descriptor queues, and DMA slot ownership through a synchronized stream-reset/epoch handshake. Any uncompleted transport record is abandoned; after reset, the first published beat is beat 0 of a new complete record with a new reset epoch. Capture admission remains disabled until every active video domain acknowledges the epoch. Reset loss is counted and made visible to the host.

PCIe reset must not reset, start, or gate the R1i NVP/I2C autoinit engine. It may reset the application capture/stream plane. NVP reset and source loss abort only the affected uncommitted record, mark a discontinuity, and leave the other channel operational.

## Channel identity and selection

Two logical channels, IDs 0 and 1, map to two distinct physical input IDs selected from 0 through 3. Selection changes are accepted only while the affected channel is disabled, its ring is empty, and no record is in flight. Duplicate active physical selections and values above 3 are rejected and counted. G2B implements only the proven physical-input-0 to logical-channel-0 path. The repository does not prove the second NVP digital-output/pin mode; that physical-ingress qualification is a later two-channel gate and does not change the shared-C2H architecture.

## Frozen verification obligations

Later implementation must prove byte-exact legacy v40B mode, byte-exact v41D output, all 512 beat positions, stable ready/valid behavior, record-granular admission/drop, no cross-channel ownership leak, fair record scheduling, coherent counter snapshots, clean reset epochs, and zero protocol errors. PCIe enumeration or a nonzero byte count alone is not C2H correctness evidence.
