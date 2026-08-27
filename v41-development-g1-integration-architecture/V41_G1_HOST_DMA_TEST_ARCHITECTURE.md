# AHD v41 G1 Host DMA Test Architecture

## Scope

Host tooling extends the accepted Linux XDMA/MMIO procedure; it does not reinstall, replace, or modify the driver. The same pinned official XDMA module, device identity, BAR mapping, and nodes are revalidated before any DMA test. The historical Phase-2 script remains a control-plane test and is never credited as application-DMA evidence.

## Tool decomposition

| Tool/role | Required behavior |
|---|---|
| Environment preflight | Record kernel/module identity, XDMA nodes, endpoint and parent `LnkCap/LnkSta`, sysfs current/max speed/width, BARs, MaxPayload/MRRS, AER counters, and current MMIO identity. Require 5.0 GT/s x1 for later Gen2 hardware gates. |
| MMIO controller | Read frozen identity/R1i pages; atomically select/enable/drain channels; request coherent DMA snapshots; never write legacy reserved locations. |
| C2H reader | Open only the existing C2H channel-0 node, use 4 KiB-aligned multi-megabyte buffers and multiple outstanding buffers/reader operations where supported, and timestamp accepted byte ranges. |
| v41D parser | Parse fixed 4,096-byte records in place; validate magic/version/length/IDs/flags; fail on a bad boundary rather than scanning for a new magic. |
| Sequence checker | Track global sequence and independent per-channel attempt/frame/line/capture sequences; reconcile every gap with device drop/reset/error counters. |
| Payload checker | For deterministic source patterns, verify full 3,840-byte payload and zero final area; otherwise compute a record payload hash and structural UYVY checks. |
| Metrics collector | Report record bytes, useful bytes, elapsed/warm-up intervals, decimal MB/s, MiB/s, per-channel rates, CPU load, copy count, buffer size/depth, and device/driver counters. |
| Soak supervisor | Periodically snapshot counters/link/AER state, detect no-progress, preserve the first failure context, and stop without clearing evidence. |

## Basic C2H correctness sequence

1. Run the existing enumeration/driver/BAR/identity/scratch checks without driver installation.
2. Confirm new DMA counters are reset/idle and R1i `INIT_DONE/INIT_ERROR` is acceptable.
3. Select physical input 0 for logical channel 0, apply, and enable one-channel streaming.
4. Read at least one 4 KiB-aligned batch; require every byte count to be an integer number of records.
5. Validate the complete v41D header, 3,840-byte payload, 192 zero bytes, and sequence/counter agreement.
6. Disable/drain, take a coherent snapshot, and compare host records/bytes with FPGA committed/streamed/drop/protocol counters.

## One-channel capture

Use one reader and one parser pipeline. Default design point is eight aligned 16 MiB buffers (128 MiB working set), configurable downward for the host. Record physical/logical IDs, source format, duration, first/last sequences, every discontinuity, and output file hashes. Storage-to-disk performance is reported separately; RAM-only capture is the correctness/throughput reference unless the gate explicitly includes disk.

## Two-channel capture

Use the same single C2H reader. The parser demultiplexes by logical ID into two validators/optional files. It verifies the applied physical selection, equal-work-conserving scheduler behavior when both sources are continuously eligible, independent per-channel sequence/drop state, and the one global transport order. One missing channel, duplicate selection, unexplained starvation, or a cross-channel identity change is a failure.

## Throughput measurement

- Warm-up and measured intervals are declared before the run.
- Time uses a monotonic high-resolution clock around host-received buffers.
- Useful application bytes are the sum of validated `payload_length` fields; record header/padding, descriptors, and PCIe overhead are excluded.
- Report `useful_bytes / seconds / 1,000,000` and `/1,048,576`.
- Also report record bytes, XDMA/device C2H bytes, host read bytes, parser-accepted bytes, and any copy bytes.
- Cross-check FPGA 64-bit snapshot counters and host counts at both interval boundaries.
- Capture negotiated speed/width and endpoint/parent link/AER state for the same interval.
- G8 passes only at `>=288 MB/s` decimal with exactly two active channels and zero drops, lost frames, FIFO overflow, DMA errors, or PCIe reset/recovery events.

## Backpressure and negative tests

Correctness tooling must deliberately pause/slow the reader to fill the ring, then verify stable in-flight AXI behavior indirectly through exact packets, whole-record-only drops, sequence gaps equal to drop deltas, per-channel isolation, and recovery after drain. It also tests reset during idle and during transfer, malformed source suppression, invalid/duplicate selection rejection, sticky protocol errors, H2C unsupported behavior without submitting ordinary product H2C traffic, and counter wrap/snapshot logic in simulation or accelerated test modes.

## Long-run tiers

- Smoke: 1,000 records, full byte validation.
- Correctness: at least 60 seconds per one- and two-channel mode, full headers/sequences and sampled payload hashes.
- Throughput: at least 10 measured minutes after declared warm-up, full counter/link capture.
- Soak: at least 8 hours with periodic snapshots and first-failure preservation; duration may be raised by the later qualification gate.

These are tooling architecture defaults, not executed G1 tests.

## Evidence outputs

Every run package contains command/configuration, source/channel mapping, tool/source hash, module/driver identity, link state, start/end MMIO snapshots, raw interval byte counters, parsed summaries, first error record, drop/frame accounting, CPU/copy conditions, and SHA-256 manifests. Secrets, proprietary source, and authentication material are excluded.
