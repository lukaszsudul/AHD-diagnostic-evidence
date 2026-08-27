# AHD Current Architecture

`PROJECT_STATE_REV = 1`

This architecture separates accepted/proven substrate, accepted but not yet
implemented architecture, active work, planned product layers, and open
decisions. Lifecycle status and engineering maturity are independent.

## End-to-end view

```text
Four physical AHD inputs per card
  → NVP6134C bring-up and selected digital video ingress
  → AHD video frontend / BT.656 validation / record production
  → up to two logical capture channels per card
  → two private four-record rings
  → one shared record formatter and record-boundary round-robin scheduler
  → one XDMA C2H channel per card over PCIe Gen2 x1 or better
  → Linux transport abstraction (XDMA first; LitePCIe possible later)
  → AHD common capture core
  → V4L2 /dev/videoX frontend
  → FFmpeg / GStreamer / OpenCV applications

Planned host: two cards
  → eight physical inputs total
  → maximum four simultaneous streams total
  → maximum two simultaneous streams per card
```

The topology is an architectural requirement. It is not a claim of two-card,
two-channel, Gen2, throughput, or Linux hardware qualification.

## State and maturity matrix

| Component or decision | Lifecycle status | Maturity marker | What is established |
|---|---|---|---|
| R1i NVP/I2C bring-up and one video-presence path | `ACCEPTED` | `PROVEN` | Qualified PoC behavior and exact identity |
| XDMA endpoint, BAR/MMIO, AXI-Lite control plane | `ACCEPTED` | `PROVEN` | Enumeration, driver, BAR discovery, identity/status/scratch scope |
| Current Gen1 x1 donor link configuration | `FROZEN` | `PROVEN` | Control-plane donor only; inadequate for final 288 MB/s target |
| G1 one-C2H/two-ring architecture | `ACCEPTED` | `PLANNED` | Architecture decision accepted; data plane not implemented/qualified |
| Local R1i-a/R1i-b research candidate commits | `PROVISIONAL` | `IMPLEMENTED_UNQUALIFIED` | Research-only source candidates; no product-baseline authority |
| G2A | `ACTIVE` | `ACTIVE` | Work in progress; no accepted execution result represented |
| Application record-to-C2H plane | `PLANNED` | `PLANNED` | Intended for G2B after accepted G2A |
| Linux/V4L2 product layer | `PLANNED` | `PLANNED` | Direction and goals only |
| Gen2 training, actual `user_clk`, throughput, final ABI | `OPEN` | `OPEN` | Require later decisions and qualification |

## Per-card accepted architecture

### Control and initialization plane

The qualified R1i tree is the composition authority. It already inherits the
required XDMA endpoint, AXI-Lite, BAR, capture/record, constraints, and build
substrate from the primary donor. Future integration starts from R1i and must
not merge an older donor over it.

R1i is whole-file/behavior authority for NVP bring-up and autonomous
initialization. The protected behavior includes 25 kHz I2C semantics,
physical/filtered SCL qualification, qualified ACK timing, first qualified
NACK abort, legal STOP, BUS_FREE confirmation, bounded retry/backoff, timeout,
recovered-versus-terminal classification, bank safety/invalidation, existing
MMIO behavior, and R1i telemetry.

### PCIe and MMIO plane

The accepted donor substrate has one XDMA C2H interface, one mandatory unused
H2C interface, a 64-bit AXI4-Stream application interface, AXI-Lite master, and
the existing BAR/control-plane structure. Its Gen1 x1 configuration is retained
as a provenance/control-plane oracle only.

The final product requirement is Gen2 x1 or better. Changing to Gen2 does not
itself prove link training, effective user clock, application DMA correctness,
or 288 MB/s payload.

All behavior through `0x35FF` and the R1i read-only page
`0x3600–0x367F` is frozen. New DMA pages must be disjoint and must pass
exhaustive no-alias and response-equivalence validation.

### Capture and record plane

The accepted G1 target has four physical inputs and at most two active logical
channels per card. Two selectors map distinct physical IDs 0–3 to logical
channels 0 and 1. Selection changes require the affected channel disabled and
drained. The second physical digital ingress remains unproven.

Each logical channel owns a private four-record ring. A shared formatter and
work-conserving round-robin scheduler select only at record boundaries and
never interleave record beats. Channel-local backpressure fills only that
channel's ring; overflow drops a whole record and is explicitly counted. A
shared formatter/link fault affects both channels.

The planned v41D record is 4,096 bytes with approximately 3,840 useful payload
bytes and explicit logical/physical channel identity. The architecture is
accepted, but the transport ABI remains `PROVISIONAL` until a later explicit
interface decision.

### Application DMA qualification boundary

Current accepted state:

- PCIe endpoint: `PROVEN`.
- BAR/MMIO: `PROVEN`.
- AXI-Lite: `PROVEN`.
- Application C2H payload: not accepted.
- Record-to-AXI-stream plane: `PLANNED` for G2B.
- One-channel DMA: not yet qualified.
- Two-channel DMA: not yet qualified.
- Sustained 288 MB/s: not yet qualified.

Enumeration, driver load, or a nonzero byte count alone is not C2H correctness
or throughput evidence.

## Linux and multi-card architecture

The planned software layering is:

```text
V4L2 frontend
  ↓
AHD common video/capture core
  ↓
transport abstraction
  ↓
XDMA backend initially
  ↓
possible future LitePCIe backend
```

Goals are stable `/dev/videoX` presentation, FFmpeg/GStreamer/OpenCV
compatibility, four logical inputs per card, no more than two `STREAMON`
instances per card, stable card/input identity, multi-card operation, and a
future zero-copy/DMABUF path. Every item is `PLANNED`, not current implemented
product state.

## Architectural invariants

- R-track candidates never enter the product baseline without a separate
  Owner/Architect decision and META update.
- NVP autoinit must not become dependent on PCIe link state or application
  stream reset.
- PCIe/reset events may reset or flush the application stream plane but must
  not restart or gate qualified NVP initialization.
- Video-to-XDMA payload crosses through proper dual-clock storage and
  descriptor/release CDC; independent synchronizers are not used for payload.
- Legacy PIO/v40B compatibility and DMA/v41D storage are separate.
- One physical PCIe lane has one shared failure/bandwidth domain even when two
  logical video channels are active.
- Research instrumentation remains until accepted R-track closure and a
  separate diagnostic-reduction decision.
