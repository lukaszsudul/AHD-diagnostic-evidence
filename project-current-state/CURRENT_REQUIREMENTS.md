# AHD Current Requirements

`PROJECT_STATE_REV = 1`

This document separates a frozen requirement from its implementation target
and from actual qualification. A requirement is not evidence that the product
currently meets it.

## Product requirements

| ID | Requirement | Status | Implementation target | Qualification state |
|---|---|---|---|---|
| `REQ-VIDEO-FORMAT` | Video format `1080p25` | `FROZEN` | Preserve through capture and host presentation | R1i video presence proven; end-to-end V4L2 not qualified |
| `REQ-INPUTS-CARD` | 4 physical inputs per card | `FROZEN` | Four selectable Linux/V4L2 input identities; at most two FPGA capture channels active | Only the current VDO1 path is proven; second physical ingress remains open |
| `REQ-ACTIVE-CARD` | Maximum 2 simultaneously active inputs per card | `FROZEN` | Two logical capture channels with enforced selection limit | Two-channel DMA not qualified |
| `REQ-CARDS-HOST` | Planned 2 cards per Linux host | `FROZEN` | Multi-card-capable driver/core and stable identity | Two-card hardware operation not qualified |
| `REQ-PCIE-PAYLOAD` | Sustained application payload `>= 288 MB/s` per card | `FROZEN` | Efficient 4 KiB C2H records over Gen2 x1 or better | Not yet qualified |
| `REQ-PCIE-MIN` | PCIe Gen2 x1 or better | `FROZEN` | Gen2 x1 is the minimum current target | Actual Gen2 training not qualified |
| `REQ-C2H-COUNT` | One XDMA C2H channel per card | `FROZEN` | Shared formatter/engine for up to two logical channels | Architecture accepted; application data plane not qualified |
| `REQ-LINUX-FRONTEND` | Native Linux V4L2 integration | `FROZEN` | Standard `/dev/videoX` presentation through common capture core | `PLANNED`, not implemented |
| `REQ-TRANSPORT-ABSTRACTION` | Linux capture core must be transport-independent | `FROZEN` | XDMA first backend; future LitePCIe backend possible | `PLANNED`; final backend API is open |
| `REQ-CARD-IDENTITY` | Stable card and input identity for multi-card use | `FROZEN` | Persistent mapping independent of enumeration order | Architecture decision remains open |
| `REQ-STREAM-LIMIT` | Four logical inputs/card, maximum two `STREAMON`/card | `FROZEN` | V4L2 policy enforced per physical card | `PLANNED`, not implemented |

## Derived host topology

From the frozen card requirements:

- physical inputs: `4/card × 2 cards = 8 total`;
- maximum active streams: `2/card × 2 cards = 4 total`; and
- per-card concurrency limit remains 2.

This is an architectural requirement, not current two-card hardware
qualification.

## PCIe throughput interpretation

The current donor is PCIe Gen1 x1. Its raw post-8b/10b ceiling is 250 MB/s
before protocol overhead, so it cannot satisfy `>= 288 MB/s` sustained
application payload. It is therefore a `PROVEN` control-plane donor and
`NOT_FINAL_THROUGHPUT_CONFIGURATION`.

Gen2 x1 has a 500 MB/s post-encoding line-rate ceiling. The line-rate ceiling
is not an application-throughput promise. G1's 4,096-byte record with 3,840
useful bytes requires approximately 307.2 MB/s transported record bytes to
deliver 288 MB/s useful payload. Actual link, XDMA, AXI-stream, host, drop, and
long-run measurements remain mandatory.

## C2H implementation target

The accepted G1 target is:

- one XDMA C2H channel per card;
- two private per-logical-channel rings;
- four 4,096-byte records per ring;
- one shared formatter/engine;
- work-conserving round-robin at complete-record boundaries;
- channel-tagged records; and
- approximately 3,840 useful bytes per record.

The architecture decision is accepted. The v41D ABI encoding is
`PROVISIONAL`, application C2H is not accepted, and one-channel/two-channel
qualification has not occurred.

## Linux Video product direction

The frozen direction is:

```text
V4L2 frontend
  ↓
AHD common video/capture core
  ↓
transport abstraction
  ↓
XDMA backend first
  ↓
possible future LitePCIe backend
```

Planned compatibility goals are FFmpeg, GStreamer, OpenCV, multi-card support,
stable card/input identity, and a future zero-copy/DMABUF path. These are
product requirements or goals, not current implementation claims.

## Protected product behavior

Every future implementation must preserve, with status `FROZEN`:

- NVP initialization behavior;
- I2C 25 kHz semantics;
- physical/filtered SCL qualification;
- qualified ACK timing;
- first qualified NACK abort;
- legal STOP;
- BUS_FREE confirmation;
- bounded retry/backoff;
- timeout handling;
- recovered-versus-terminal error distinction;
- bank safety/invalidation;
- existing MMIO semantics; and
- the R1i telemetry page.

Research instrumentation may be reduced only after accepted R-track closure,
an explicit Owner/Architect reduction decision, and a separate authorized META
update.
