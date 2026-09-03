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

## PROJECT_STATE_REV 4 — 2026-09-02

Status: `ACCEPTED`
Update type: `ARCHITECTURE_CHANGE`
Authorization literal: `SSOT WRITE AUTHORIZED`
Expected previous revision: `3`
Actual previous revision: `3`
Resulting revision: `4`
Accepted by role: `OWNER_ARCHITECT`
Applied by role: `META_UPDATE_AGENT`
Frozen header SHA-256:
`D7456D989F0D879B2E1FD8777876F5AE786947D789CE1D480CA720316AC7342B`

Reason: promote the accepted ownership CDC architecture and make
`PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` the required Group-9
`OWNERSHIP_AXI_TO_SOURCE` sign-off method.

Authoritative accepted evidence:

- BS1R: `v41-development-g2b-bs1r-single-sink-bus-skew-retry`, commit
  `f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62`.
- BS2: `v41-development-g2b-bs2-alternative-timing-equivalence`, commit
  `4699632c591238fee46ada3b0de37532fddd0b6f`.
- BS3: `v41-development-g2b-bs3-ownership-mailbox-settling-proof`, commit
  `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae`.

Project truth promoted in this revision:

- `GLOBAL_SET_BUS_SKEW_3NS` is `RETIRED_FROM_REQUIRED_SIGNOFF` for Group 9.
- Global Group-9 `report_bus_skew` is retired from required sign-off; no
  repeat invocation is required.
- The required method is `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`.
- Structural proof covers two-stage request and acknowledgement
  synchronizers, a held 58-bit stable-data payload, source hold until
  acknowledgement, and reset/epoch coherency.
- The three semantic payload families are `slot`, `generation`, and `epoch`.
- Maximum settling is `6.000 ns`, based on a `13.468 ns` minimum
  launch-to-use margin and `7.468 ns` gross reserve.
- The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` and is not a
  relaxation of safety.
- `RTL_CHANGE_REQUIRED = NO`.
- `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; the accepted
  candidate is `G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc`.
- G2B-LUT1 readiness is `READY_FOR_SIGNOFF_RECOVERY`; next gate is
  `G2B-LUT1-SIGNOFF-RECOVERY`.
- G2B-HW is lifecycle `BLOCKED` until final offline sign-off, the
  pre-bitstream hard gate, and a bitstream candidate exist.
- `GROUPS_10_TO_17 = UNCHANGED`.
- The named Group-9 sign-off-methodology decision is recorded as an
  `UNNUMBERED_GOVERNED_DECISION`, state `RESOLVED`, decision
  `REPLACE_GLOBAL_BUS_SKEW_WITH_PER_FAMILY_SETTLING_CHECKS`. No `OD-*`
  identifier is invented and every registered `OD-*` entry remains unchanged.

Explicit non-promotions and protection boundary:

- no RTL or FPGA source was modified;
- no active production XDC was modified;
- no Vivado, bitstream, DUT, DMA, or hardware operation was performed;
- no R-track source, branch, evidence, or execution state was modified;
- no final routed sign-off, implementation acceptance, qualification,
  release, hardware readiness, bitstream, or hardware proof is claimed; and
- Groups 10–17 retain their existing requirements.

Affected SSOT files in the revision-4 transaction (`16`):

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

The ordinary publication commit and fresh remote byte/SHA-256 read-back are
post-commit executor completion data. No not-yet-created publication SHA or
precompleted remote read-back is invented in this changelog entry.

## PROJECT_STATE_REV 5 — 2026-09-02

Status: `ACCEPTED`
Update type: `ARCHITECTURE_CHANGE`
Authorization literal: `SSOT WRITE AUTHORIZED`
Expected previous revision: `4`
Actual previous revision: `4`
Resulting revision: `5`
Accepted by role: `OWNER_ARCHITECT`
Applied by role: `META_UPDATE_AGENT`
Write-contract receipt:
`v41-meta-project-state-rev5-group13-reset-return-signoff/META5_WRITE_CONTRACT_RECEIPT.md`

Reason: promote the accepted G13-A reset-return CDC architecture and make
`SETTLING_PLUS_STRUCTURAL_CDC` the required Group-13
`RESET_RETURN_SOURCE_TO_AXI` sign-off method.

Authoritative accepted evidence:

- G13-A: `v41-development-g2b-g13a-reset-return-signoff-audit`, commit
  `10c7c2898d162af8e2262b3f99861c7d560c4557`.

Project truth promoted in this revision:

- The historical Group-13 `set_bus_skew 3.000 -from
  $g2b_reset_return_src -to $g2b_reset_return_dst` covered seven sources and
  207 destinations and is `RETIRED_FROM_REQUIRED_SIGNOFF`.
- Global Group-13 `report_bus_skew` is retired from required sign-off; its
  verified timeout remains historical evidence and no repeat is required.
- `PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`.
- The required method is `SETTLING_PLUS_STRUCTURAL_CDC` and the decision is
  `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`.
- The exact two semantic families are
  `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` and
  `RESET_COMMIT_PHASE_COMPLETION_BARRIER`.
- Each family requires a `6.000 ns` absolute datapath-only settling check to
  all timing endpoint roles on its selected destination cells.
- The unchanged broad source-mailbox `6.000 ns` max-delay relation remains
  mandatory and retains the validated 79-cell supplemental fanout coverage of
  the commit-phase family; that coverage is not a third family.
- Structural proof requires single-edge capture, stable hold while
  acknowledgement is outstanding, two-stage request/acknowledgement and live
  commit-phase synchronization, matching acknowledgement/request phase,
  live/held commit-phase equality, hard-episode qualification, reset-return
  coherency, destination-use sequencing, and atomic epoch/state publication on
  qualified completion; commit-phase parity alias is excluded by exclusive
  reset handling with admission disabled and commit enqueue/scheduler progress
  suppressed while reset is busy.
- Reset assertion/deassertion are synchronously observed; Group 13 is not an
  async-assert/sync-release reset crossing.
- The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` and is not a
  relaxation of safety.
- `RTL_CHANGE_REQUIRED = NO`.
- `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; the accepted
  candidate is `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc`.
- The named Group-13 sign-off-methodology decision is recorded as an
  `UNNUMBERED_GOVERNED_DECISION`, state `RESOLVED`, without inventing an
  `OD-*` identifier or changing any existing open/decided record.
- Group-9 `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` remains promoted and its
  global `report_bus_skew` remains retired; `GROUP9_GOVERNANCE_REGRESSION = NO`.
- `GROUPS_10_TO_12 = PRESERVE_PREVIOUS_RESULTS` and
  `GROUPS_14_TO_17 = PENDING_UNCHANGED`.
- G2B-LUT1 remains `READY_FOR_SIGNOFF_RECOVERY`; next gate is
  `G2B-LUT1-SIGNOFF-RECOVERY-2`.
- G2B-HW remains lifecycle `BLOCKED`, `NOT_STARTED`, and `NOT_PROVEN`.

Explicit non-promotions and protection boundary:

- no RTL or FPGA source was modified;
- no active production XDC was modified;
- no Vivado, bitstream, DUT, JTAG, PCIe, DMA, reboot, or power-cycle operation
  was performed;
- no R-track source, branch, evidence, or execution state was modified;
- no final routed sign-off, implementation acceptance, qualification,
  release, hardware readiness, bitstream, or hardware proof is claimed; and
- Groups 14–17 retain their existing requirements and pending state.

Affected SSOT files in the revision-5 transaction (`16`):

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

The ordinary publication commit and fresh remote byte/SHA-256 read-back are
post-commit executor completion data. No not-yet-created publication SHA or
precompleted remote read-back is invented in this changelog entry.

## PROJECT_STATE_REV 6 — 2026-09-03

Status: `ACCEPTED`
Update type: `ARCHITECTURE_CHANGE`
Authorization literal: `SSOT WRITE AUTHORIZED`
Expected previous revision: `5`
Actual previous revision: `5`
Resulting revision: `6`
Accepted by role: `OWNER_ARCHITECT`
Applied by role: `META_UPDATE_AGENT`
Write-contract receipt:
`v41-meta-project-state-rev6-group14-release-slot-signoff/META6_WRITE_CONTRACT_RECEIPT.md`

Reason: promote the accepted G14-A release-slot CDC architecture and make
`SETTLING_PLUS_STRUCTURAL_CDC` the required Group-14
`RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off method.

Authoritative accepted evidence:

- G14-A: `v41-development-g2b-g14a-release-slot0-signoff-audit`, commit
  `9e91315968453e859006077191cd5fc711fc6b96`.

Project truth promoted in this revision:

- The historical Group-14 `set_bus_skew 3.000 -from
  $g2b_release0_payload_src -to $g2b_release_payload_dst` covered 56 sources
  and 20 destinations and is `RETIRED_FROM_REQUIRED_SIGNOFF`.
- Global Group-14 `report_bus_skew` is retired from required sign-off; its
  verified bounded pathological runtime remains historical evidence and no
  repeat is required.
- `PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`.
- The required method is `SETTLING_PLUS_STRUCTURAL_CDC` and the decision is
  `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`.
- The exact three semantic families are
  `RELEASE_SLOT0_NORMAL_STATE_TRANSITION`,
  `RELEASE_SLOT0_MISMATCH_CONTAINMENT`, and
  `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`.
- Each family requires `6.000 ns` absolute datapath-only settling. Routed
  candidate results are respectively `5.467 ns`, `5.554 ns`, and `4.191 ns`
  worst actual delay, with `0.563 ns`, `0.478 ns`, and `1.839 ns` slack.
- Structural proof requires a held 24-bit generation plus 32-bit epoch token;
  launch with the release toggle on the accepted final stream beat; two-stage
  `ASYNC_REG` release-toggle synchronization before ordinary use; two-stage
  `ASYNC_REG` transport-request synchronization before reset-overlap use;
  stable data until the relevant event is consumed; generation, descriptor
  epoch, current reset epoch, and `DMA_OWNED` identity qualification;
  fail-closed mismatch containment; reset suppression of ordinary decoding;
  captured release-phase retirement before transport acknowledgement;
  destination-use ordering; and reset/release coherency.
- The invariant remains the conjunction of `ABSOLUTE_SETTLING`,
  `STABLE_DATA_UNTIL_EVENT_CONSUMPTION`, `EVENT_ORDERING`,
  `SYNCHRONIZER_STRUCTURE`, `COMPLETION_BARRIER`, and `TOKEN_IDENTITY`.
- The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` and is not a
  relaxation of safety.
- `RTL_CHANGE_REQUIRED = NO`.
- `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; the accepted
  candidate authority is `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from the G14-A
  evidence commit.
- The named Group-14 sign-off-methodology decision is recorded as an
  `UNNUMBERED_GOVERNED_DECISION`, state `RESOLVED`, without inventing an
  `OD-*` identifier or changing any existing open/decided record.
- Group-9 and Group-13 promoted methods remain authoritative;
  `GROUP9_GOVERNANCE_REGRESSION = NO` and
  `GROUP13_GOVERNANCE_REGRESSION = NO`.
- `GROUP9 = PRESERVE_PASS`, `GROUPS_10_TO_12 = PRESERVE_PASS`,
  `GROUP13 = PRESERVE_PASS`, and `GROUPS_15_TO_17 = PENDING_UNCHANGED`.
- G2B-LUT1 remains `READY_FOR_SIGNOFF_RECOVERY`; next gate is
  `G2B-LUT1-SIGNOFF-RECOVERY-3`.
- G2B-HW remains lifecycle `BLOCKED`, `NOT_STARTED`, and `NOT_PROVEN`.

Explicit non-promotions and protection boundary:

- no RTL or FPGA source was modified;
- no active production XDC was modified;
- no Vivado, bitstream, DUT, JTAG, PCIe, DMA, reboot, or power-cycle operation
  was performed;
- no R-track source, branch, evidence, or execution state was modified;
- no final routed sign-off, implementation acceptance, qualification,
  release, hardware readiness, bitstream, or hardware proof is claimed; and
- Groups 15–17 retain their existing requirements and pending state.

Affected SSOT files in the revision-6 transaction (`16`):

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

The ordinary publication commit and fresh remote byte/SHA-256 read-back are
post-commit executor completion data. No not-yet-created publication SHA or
precompleted remote read-back is invented in this changelog entry.
