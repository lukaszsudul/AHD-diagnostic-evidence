# AHD Current Architecture

`PROJECT_STATE_REV = 3`

This architecture separates accepted/proven substrate, accepted but not yet
implemented architecture, active work, planned product layers, and open
decisions. Lifecycle status and engineering maturity are independent.

## End-to-end view

```text
Four physical AHD inputs per card
  → NVP6134C bring-up and selected digital video ingress
  → explicit PRODUCT or RESEARCH_DIAGNOSTIC observability profile
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
| G2B-PRE architecture contract | `ACCEPTED` | `FROZEN_FOR_G2B` | `AHD_C2H_TRANSPORT_ABI_V1`, G2B MMIO, and Linux transport-input contract are frozen |
| G2B-LUT0 resource architecture | `ACCEPTED` | `PASS / IMPLEMENTATION_PENDING` | Dual-profile Plan B accepted; estimate is not qualification evidence |
| PRODUCT profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED` | Qualified R1i behavior, production observability, XDMA Gen2, G2B and frozen ABI/MMIO retained |
| RESEARCH_DIAGNOSTIC profile | `PLANNED` | `AUTHORIZED_NOT_IMPLEMENTED` | PRODUCT functional behavior plus reproducible R-track observability for R2/R3 resumability |
| Application record-to-C2H plane | `BLOCKED` | `BLOCKED_RESOURCE_HEADROOM` | Resource-blocked evidence snapshot is not an accepted offline-qualified implementation |
| G2B-LUT1 | `PLANNED` | `READY / NOT_STARTED` | Authorized to implement the reversible profile boundary using the least invasive supported method |
| G2B hardware qualification | `PLANNED` | `NOT_STARTED / NOT_PROVEN` | No G2B bitstream, DMA capture, Gen2 proof, or throughput result exists |
| Linux/V4L2 product layer | `PLANNED` | `NOT_IMPLEMENTED` | Transport input is frozen; frontend, buffer, identity, and policy work remain later L-track scope |
| Gen2 training, actual `user_clk`, and throughput | `OPEN` | `NOT_PROVEN` | Require later qualification |

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

G2B-PRE freezes the new G2B MMIO contract at `0x3800..0x3BFF`. This is an
accepted interface allocation and semantic contract, not a claim that the
registers exist in the current build. All protected behavior through
`0x37FF` remains compatible and unchanged.

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

The accepted `AHD_C2H_TRANSPORT_ABI_V1` record is exactly 4,096 bytes: a
64-byte header, a 3,840-byte payload containing one complete 1,920-active-pixel
UYVY 4:2:2 line, and 192 bytes of zero padding, with explicit
logical/physical channel identity. Its interface status is `FROZEN_FOR_G2B`.
The freeze makes the interface contract implementation-ready; the complete
G2B implementation remains resource-blocked and not offline-qualified. It
does not mean the formatter, rings, scheduler, or application C2H data plane
is accepted or hardware-qualified.

### Build-profile boundary

`PRODUCT` and `RESEARCH_DIAGNOSTIC` are two elaborations of one functional
product architecture. Both must have identical qualified R1i functional
behavior, XDMA configuration, video-capture semantics, frozen transport ABI,
and externally visible MMIO contract. Research instrumentation is never a
functional dependency.

`PRODUCT` retains the full qualified R1i correction, physical SCL and ACK
behavior, required synchronizers/readiness/recovery, minimum production NVP
and video observability, runtime identity, XDMA Gen2 configuration, G2B
transport/status/counters/reset epoch/capabilities, and the frozen
`AHD_C2H_TRANSPORT_ABI_V1` / `0x3800..0x3BFF` interface. G2B-LUT0-classified
research-only probes, deep histories, lifecycle observers, counters, MMIO
cones, and observation structures may be absent only when their removal
cannot alter any functional or externally visible product semantic.

`RESEARCH_DIAGNOSTIC` is PRODUCT functional behavior plus the observability
needed to resume R2/R3. It may exceed PRODUCT resource targets, but it must
remain reproducibly buildable. No claim is made that the research profile
currently builds or routes after G2B.

G2B-LUT1 may select a reversible repository-supported mechanism such as
generics, Tcl profile selection/defines, generate blocks, or source sets. The
implementation agent, not META-3, must choose the least invasive method.

### Application DMA qualification boundary

Current accepted state:

- PCIe endpoint: `PROVEN`.
- BAR/MMIO: `PROVEN`.
- AXI-Lite: `PROVEN`.
- G2B-PRE transport/MMIO architecture contract: `ACCEPTED` and
  `FROZEN_FOR_G2B`.
- Application C2H payload: not accepted.
- Record-to-AXI-stream/G2B implementation: `BLOCKED_RESOURCE_HEADROOM` and
  not offline-qualified.
- G2B-LUT1 profile implementation gate: `READY`, not started.
- One-channel DMA: not yet qualified.
- Two-channel DMA: not yet qualified.
- Sustained 288 MB/s: not yet qualified.
- G2B hardware qualification: `NOT_STARTED` and `NOT_PROVEN`.

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
future zero-copy/DMABUF path. `AHD_C2H_TRANSPORT_ABI_V1` and its Linux consumer
contract are frozen transport inputs. Every V4L2, identity, multi-card, and
DMABUF item remains `PLANNED` and `NOT_IMPLEMENTED`.

## Architectural invariants

- R-track state is `HOLD`, not closed; research work remains valid and
  resumable through `RESEARCH_DIAGNOSTIC`.
- PRODUCT and RESEARCH_DIAGNOSTIC have identical qualified R1i functional
  behavior; research instrumentation is never required for correctness.
- Removing research instrumentation from PRODUCT must not change NVP
  initialization, I2C protocol behavior, video capture semantics,
  `AHD_C2H_TRANSPORT_ABI_V1`, MMIO contracts, or XDMA configuration.
- NVP autoinit must not become dependent on PCIe link state or application
  stream reset.
- PCIe/reset events may reset or flush the application stream plane but must
  not restart or gate qualified NVP initialization.
- Video-to-XDMA payload crosses through proper dual-clock storage and
  descriptor/release CDC; independent synchronizers are not used for payload.
- Legacy PIO/v40B compatibility and DMA `AHD_C2H_TRANSPORT_ABI_V1` storage are
  separate.
- One physical PCIe lane has one shared failure/bandwidth domain even when two
  logical video channels are active.
- Research instrumentation excluded from PRODUCT remains recoverable through
  the reproducible RESEARCH_DIAGNOSTIC profile; evidence and R-track branches
  are not deleted or modified by META-3.
