# AHD v41 G1 One-Channel DMA Contract

## G6 architecture

The one-channel path is the first functional instance of the common product data plane:

```text
physical input 0 (initial qualified selection)
 -> R1i-qualified NVP bring-up
 -> VDO1 physical frontend / BT.656 validation
 -> continuous line-record producer
 -> logical channel 0 four-slot DMA ring
 -> fixed channel-0 scheduler selection
 -> v41D 4 KiB formatter
 -> XDMA C2H channel 0
 -> one host reader
```

G6 shall initially map physical input 0 to logical channel 0. A later validated selection may choose any physical input `0..3`; the mapping is explicit in every record. The one-channel implementation uses the same record format, ring, formatter, counters, and host parser as the two-channel product, so adding channel 1 does not change the host ABI.

## Source and storage

- Input is the existing 8-bit VDO1 BT.656 stream at its recovered video clock.
- The protected R1i initialization completes independently of DMA enable.
- DMA streaming is enabled only after `INIT_DONE=1`, `INIT_ERROR=0`, the selected video frontend is locally released, and the host commits an enable request through the new control page.
- The producer emits one 3,840-byte active-line payload in one 4,096-byte record.
- Four DMA slots are private to logical channel 0. Legacy PIO slots remain a separate, mutually exclusive compatibility path.
- A committed slot cannot be rewritten until the beat-511 C2H handshake returns ownership.

## Record and packet boundary

The host contract is exactly one v41D record per 4,096 bytes and one AXI `TLAST` per 512 beats. No partial packet, implicit delimiter, or resynchronization scan is allowed. `TKEEP` is `0xFF` on all beats. The first record after enable or reset starts at beat 0 and carries the current reset epoch and explicit physical/logical identity in MMIO/header context.

## Frame and record association

Each record contains source frame, source line, source capture sequence, per-channel attempt sequence, and global streamed sequence. The host verifies:

- logical channel ID is always 0;
- physical input matches the committed selection;
- the per-channel attempt sequence advances by one unless a device-reported whole-record drop explains a gap;
- global streamed sequence advances by one;
- line sequence is plausible within a frame and `SOF` agrees with the frame transition;
- payload length is exactly 3,840 and the record length is exactly 4,096; and
- discontinuity/overflow/malformed flags agree with counter deltas.

A frame is associated by `(physical_input_id, source_frame_sequence)`. A line/record is associated by `(logical_channel_id, channel_attempt_sequence)`; the global sequence is transport order, not source-time order.

## Backpressure and loss

The formatter holds an in-flight record stable for any `TREADY` stall. The producer continues until all four channel-0 slots are owned. A further eligible line is dropped whole before its first byte is admitted, increments attempt/drop/overflow exactly once, and marks the next record discontinuous. Overwrite, partial record, and silent sequence repair are forbidden.

## Error telemetry

The one-channel gate requires device and host agreement for attempts, commits, streams, drops, FIFO overflow/high-water mark, malformed source records, C2H stall cycles, record/useful byte counts, protocol errors, DMA/reset events, and last sequences. `INIT_DONE`, `INIT_ERROR`, total NACK, retry exhausted, SCL timeout, and bank-safety status remain separately visible from R1i/product telemetry.

Sticky protocol or ownership errors stop new admission until an explicit disable/flush/clear/re-enable sequence. Source malformed records are not sent as valid payload. A link/user reset flushes the DMA session, increments its reset epoch, and never restarts NVP autoinit.

## Host receive contract

The host opens the existing XDMA C2H channel-0 node, reads buffers whose sizes are multiples of 4,096, parses records in place, and fails rather than scanning forward on a bad magic/version. It reports record bytes and useful payload bytes separately. The one-channel gate is correctness, not the final 288 MB/s qualification.

## G6 acceptance boundary

One-channel DMA is frozen architecturally here but remains unimplemented and unproven. G6 later requires exact record comparison, sequence continuity, controlled backpressure tests, reset recovery, zero unexplained drops, counter agreement, and a declared-duration capture. Enumeration, driver load, MMIO access, or one nonzero transfer does not pass G6.
