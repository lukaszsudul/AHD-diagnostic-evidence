# AHD Project-State Changelog

This file is append-only. Published revision entries must never be edited,
deleted, reordered, squashed into another entry, or rewritten. A correction
requires a new authorized project-state revision.

## PROJECT_STATE_REV 1 — 2026-08-28

Status: `ACCEPTED`
Update type: `META_GOVERNANCE_CHANGE` and initial state capture
Authorization: `META-0_TASK_DIRECTIVE` containing `SSOT WRITE AUTHORIZED`
Expected previous revision: `ABSENT`
Accepted by role: `OWNER_ARCHITECT`
Applied by role: `META_UPDATE_AGENT`

Created the first AHD v41 current-state and architecture SSOT and froze its
governance, update policy, machine schema, evidence mapping, integrity
manifest, optimistic concurrency control, and stale-agent detection.

Initial project truth recorded:

- Product: G-1 `ACCEPTED`, G0 `ACCEPTED`, G1 `ACCEPTED`, G2A `ACTIVE`.
- Research: R0 `ACCEPTED`, R1 `ACTIVE`; R1i-a/R1i-b remain research-only.
- Linux Video: L0 `PLANNED`; V4L2 with transport abstraction is a planned
  architecture direction, not implemented state.
- META: META-0 governance infrastructure is accepted only by this creation
  task; no wider Owner acceptance is inferred.
- Qualified FPGA baseline: R1i at commit
  `20c3323d79d3896edc586d6db1df7deee60f9e41`, tree
  `70d801fd7a879080da399bfa9ee95fd6eb008e16`, frozen tag
  `v41-r1i-qualified-poc-20260827`.
- Product PCIe requirement: Gen2 x1 or better and sustained application
  payload `>= 288 MB/s` per card; Gen2 and throughput remain unqualified.
- Video topology: 4 physical inputs/card, max 2 active/card, planned 2
  cards/host.
- Accepted G1 C2H architecture: one C2H/card, two private four-record rings,
  shared formatter/engine, record-boundary round-robin, channel-tagged records.
- Transport ABI and v41D implementation contract remain `PROVISIONAL`.

Evidence repository snapshot before creation:
`f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd`. The snapshot contained no prior
`project-current-state/` directory and no newer G2A, R1, L0, Linux, or V4L2
evidence package. Evidence `PASS` was not treated as acceptance; accepted
labels derive from the explicit Owner/Architect-approved META-0 input.

## PROJECT_STATE_REV 2 — 2026-08-29

Status: `ACCEPTED`
Update type: `INTERFACE_CHANGE` with required requirement, track, and revision
bookkeeping
Authorization: `META-2_TASK_DIRECTIVE`; Owner/Architect acceptance `YES`; META
update explicitly requested
Expected previous revision: `1`
Actual previous revision: `1`
Resulting revision: `2`
Accepted by role: `OWNER_ARCHITECT`
Applied by role: `META_UPDATE_AGENT`

Reason: G2B-PRE accepted; C2H transport ABI and MMIO frozen for
implementation.

Authoritative accepted evidence:

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Directory: `v41-development-g2b-pre-c2h-abi-mmio-freeze`.
- Immutable evidence commit:
  `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e`.
- Original evidence payload commit:
  `9fdcca4e3a40b931f07db01ad404b4a3cfc24b10`.

Project truth promoted in this revision:

- G2B-PRE architecture freeze: `ACCEPTED`.
- Transport ABI: `AHD_C2H_TRANSPORT_ABI_V1`, version `1`, lifecycle
  `FROZEN`, semantic state `FROZEN_FOR_G2B`.
- Record geometry: `4096` bytes total, `64` header, `3840` UYVY payload,
  and `192` formatter-generated zero-padding bytes.
- G2B MMIO: lifecycle `FROZEN` at `0x3800..0x3BFF`; legacy behavior through
  `0x37FF` remains protected and compatible.
- Linux consumer contract: frozen as the transport input contract. It does
  not freeze or implement the V4L2 architecture.
- G2B implementation readiness: `READY`; implementation remains
  `NOT_IMPLEMENTED` and hardware qualification remains `NOT_STARTED` /
  `NOT_PROVEN`.

One tracked SSOT decision was closed: `OD-06 / Final C2H transport ABI`. Its
accepted G2B-PRE decision log closes these 15 technical groups:

1. offset `0x38` semantics;
2. offset `0x3C` semantics;
3. reset epoch;
4. sequence reset, wrap, and drop behavior;
5. build identity;
6. flags;
7. channel identity;
8. payload and frame reconstruction;
9. padding;
10. ownership, drop, backpressure, and reset;
11. MMIO base and range;
12. control and status;
13. counters, capabilities, and errors;
14. read coherency; and
15. forward compatibility.

`OD-01..OD-05` and `OD-07..OD-10` remain `OPEN`. No R-track status or R2
finding was promoted.

No implementation or qualification result was promoted: one-channel C2H RTL,
one-channel hardware DMA, two-channel DMA, sustained `>= 288 MB/s`, hardware
Gen2 negotiation, G2B bitstream, G2B host capture, V4L2, DMABUF, and multi-card
Linux policy all remain not implemented, not proven, not qualified, or open as
applicable. No FPGA source, RTL, XCI, XDC, or R-track content was changed; no
Vivado, DUT, FPGA programming, or DMA operation was performed.

Affected SSOT files in the revision-2 transaction (`16`):

- `project-current-state/ACTIVE_BASELINES.md`
- `project-current-state/CHANGELOG.md`
- `project-current-state/COMPATIBILITY_MATRIX.csv`
- `project-current-state/CURRENT_ARCHITECTURE.md`
- `project-current-state/CURRENT_INTERFACES.md`
- `project-current-state/CURRENT_REQUIREMENTS.md`
- `project-current-state/CURRENT_RESOURCE_STATE.md`
- `project-current-state/CURRENT_STATUS.md`
- `project-current-state/CURRENT_TRACKS.md`
- `project-current-state/EVIDENCE_MAP.md`
- `project-current-state/GOVERNANCE.md`
- `project-current-state/OPEN_DECISIONS.md`
- `project-current-state/PROJECT_STATE.json`
- `project-current-state/README.md`
- `project-current-state/SHA256_MANIFEST.txt`
- `project-current-state/TRACK_STATUS.json`

The publication commit, non-force push result, and remote byte/SHA-256
read-back are required completion data recorded in the META-2 evidence receipt
under `v41-meta-project-state-rev2-g2b-pre-promotion/`; no not-yet-created
publication SHA is invented in this changelog entry.

## PROJECT_STATE_REV 3 — 2026-08-29

Status: `ACCEPTED`
Update type: `ARCHITECTURE_CHANGE`, `REQUIREMENT_CHANGE`, and
`BLOCKER_CHANGE` with required track/revision bookkeeping
Authorization: `META-3_TASK_DIRECTIVE`; explicit Owner/Architect build-profile
decision and authorized META promotion/publication task
Expected previous revision: `2`
Actual previous revision: `2`
Resulting revision: `3`
Accepted by role: `OWNER_ARCHITECT`
Applied by role: `META_UPDATE_AGENT`

Reason: G2B-LUT0 accepted; dual PRODUCT / RESEARCH_DIAGNOSTIC build-profile
architecture authorized to recover resource headroom.

Authoritative accepted evidence:

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Directory: `v41-development-g2b-lut0-resource-attribution`.
- Immutable evidence commit:
  `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4`.
- Evidence subtree: `05fd1075e0a8deb5082accccb0a88a3f18dfca54`.
- Engineering result: `PASS`.

Project truth promoted in this revision:

- G2B-LUT0 resource architecture: `ACCEPTED`.
- R-track execution state: `HOLD`, not closed, cancelled, or superseded; R2/R3
  scientific closure remains open.
- PRODUCT profile: `AUTHORIZED_NOT_IMPLEMENTED`.
- RESEARCH_DIAGNOSTIC profile: `AUTHORIZED_NOT_IMPLEMENTED`, preserving
  reproducible R-track resumability.
- PRODUCT routed LUT hard gate: `<= 90%`; preferred target: `80–85%`.
- G2B-IMPL: lifecycle `BLOCKED`, implementation state
  `BLOCKED_RESOURCE_HEADROOM`; G2B-LUT1 readiness: `READY`.
- G2B resource recovery: `PLAN_ACCEPTED_IMPLEMENTATION_PENDING`.
- R1i functional behavior must be identical across profiles, and research
  instrumentation may never be required for functional correctness.
- Profile selection may change only observability/resource elaboration. It
  must not change NVP initialization, I2C behavior, video-capture semantics,
  XDMA configuration, `AHD_C2H_TRANSPORT_ABI_V1`, or frozen MMIO
  `0x3800..0x3BFF` semantics.

Accepted G2B-LUT0 resource evidence records blocked G2B at 21,412 / 20,800 LUT
(102.942%), G2A at 18,178 / 20,800 LUT, estimated research/diagnostic cost of
approximately 3,900 LUT (range 3,500–4,300), and an estimated PRODUCT Plan-B
result of approximately 17,512 LUT (84.192%). These estimates are planning
inputs, not qualification evidence.

Explicit non-promotions and protection boundary:

- no source profile implementation exists yet;
- no LUT target has been proven or marked achieved;
- no accepted offline-qualified G2B implementation exists;
- no G2B bitstream was produced;
- no G2B hardware result exists and hardware remains `NOT_PROVEN`;
- V4L2 remains `NOT_IMPLEMENTED`;
- no FPGA source, RTL, XCI, XDC, R-track branch, or research evidence was
  modified or deleted; and
- no Vivado, DUT, FPGA programming, DMA, or hardware operation was performed.

Affected SSOT files in the revision-3 transaction (`16`):

- `project-current-state/ACTIVE_BASELINES.md`
- `project-current-state/CHANGELOG.md`
- `project-current-state/COMPATIBILITY_MATRIX.csv`
- `project-current-state/CURRENT_ARCHITECTURE.md`
- `project-current-state/CURRENT_INTERFACES.md`
- `project-current-state/CURRENT_REQUIREMENTS.md`
- `project-current-state/CURRENT_RESOURCE_STATE.md`
- `project-current-state/CURRENT_STATUS.md`
- `project-current-state/CURRENT_TRACKS.md`
- `project-current-state/EVIDENCE_MAP.md`
- `project-current-state/GOVERNANCE.md`
- `project-current-state/OPEN_DECISIONS.md`
- `project-current-state/PROJECT_STATE.json`
- `project-current-state/README.md`
- `project-current-state/SHA256_MANIFEST.txt`
- `project-current-state/TRACK_STATUS.json`

The publication commit, non-force push result, and remote byte/SHA-256
read-back are completion data recorded in the META-3 evidence receipt under
`v41-meta-project-state-rev3-build-profile-authorization/`; no not-yet-created
publication SHA is invented in this changelog entry.
