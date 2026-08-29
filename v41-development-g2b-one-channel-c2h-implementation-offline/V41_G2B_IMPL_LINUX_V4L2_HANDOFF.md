# AHD v41 G2B-IMPL Linux/V4L2 Handoff

## FROZEN CONTRACT

- Transport: `AHD_C2H_TRANSPORT_ABI_V1`, version 1.
- MMIO: `0x3800..0x3BFF`; legacy behavior through `0x37FF` remains protected;
  `0x3C00..0x3FFF` remains future-reserved.
- Record: 4,096 bytes = 64-byte header + 3,840-byte UYVY payload + 192 zero
  bytes; 512 64-bit AXI beats, `TKEEP=0xFF`, TLAST only on beat 511.
- Payload: one complete 1,920-pixel active line, `U0 Y0 V0 Y1` byte order,
  left-to-right, without blanking or BT.656 markers.
- Identity: logical channel 0, physical input 0 for this implementation.
- `channel_attempt_sequence` counts every eligible attempt, including drops;
  `global_stream_sequence` counts only fully streamed records.
- `reset_epoch` is shared stream state. Session start requires disabled C2H,
  `RESET_STREAM_STATE`, completion/empty checks, fatal recovery if applicable,
  epoch capture, and explicit enable.
- Counter reads use the explicit coherent snapshot command/status protocol.

## IMPLEMENTED OFFLINE

The source snapshot implements one application C2H channel, a private
four-slot record ring, deterministic header/payload/padding formatting,
oldest-committed AXI scheduling, complete-record backpressure behavior, frozen
MMIO controls and snapshots, sequence/epoch handling, and an offline host
parser. Focused simulation, byte-exact golden-vector, parser, frame-fixture,
CDC static, and R1i-protection checks passed.

The clean build passed synthesis and optimization but exceeded the post-opt LUT
headroom gate (21,412 / 20,800 LUTs). It therefore has no qualified integration
commit or bitstream, and is not an offline-qualified candidate. Exact source,
test, build, and evidence identities are supplied by the main report.

The reference parser consumes fixed 4,096-byte boundaries, validates structure
and padding, tracks epoch and sequence continuity, extracts 3,840-byte UYVY
lines, and reconstructs frame metadata. It is an offline validation/reference
tool, not a production capture API.

## HARDWARE NOT PROVEN

No DUT was accessed in G2B-IMPL. Runtime firmware identity, negotiated Gen2 x1,
MMIO behavior on a card, XDMA capture, real AHD payload, sustained rate,
backpressure on hardware, and repeatability remain unproven. Simulated lines and
the 1,080-line simulated frame fixture must never be described as hardware DMA
or camera evidence.

The next dependency is architecture review and resource closure, followed by a
fresh complete offline build. Only after that passes can the separately
authorized G2B-HW one-channel gate begin. Two-channel scheduling/arbitration and
shared global-stream behavior with both inputs remain later dependencies. The
application payload requirement of at least 288 MB/s remains a hardware
measurement dependency.

## V4L2 NOT IMPLEMENTED

No V4L2 node, vb2 queue, DMABUF path, production XDMA ingestion service,
multi-card enumeration, or two-channel userspace policy is included. A Linux
implementation must preserve fixed record boundaries, fail-stop structural
validation, the session-start reset rule, epoch changes, attempt/global
sequence semantics, payload extraction, and coherent MMIO snapshots. It must
not infer hardware proof from build-time capability values or from the offline
fixture.
