# AHD Open Decisions

`PROJECT_STATE_REV = 7`

Every item below has lifecycle status `OPEN`. An agent may investigate or
publish evidence about an item, but may not silently choose a value or update
project truth. Closure requires an explicit Owner/Architect decision and, when
the SSOT changes, a separate authorized META update.

| ID | Decision | Status | Why unresolved | Required closure evidence / decision |
|---|---|---|---|---|
| `OD-01` | Exact R1i causal mechanism | `OPEN` | R1i proves the intervention works but sole-root-cause attribution is `INCONCLUSIVE` | Accepted R1 controlled evidence discriminating physical SCL, ACK sampling, combined effect, and recovery/readiness |
| `OD-02` | R1i timing margin | `OPEN` | Qualified point behavior is not a complete margin characterization | Triggered margin campaign with controlled timing sweep, failure boundaries, and Owner decision |
| `OD-04` | Actual Gen2 training | `OPEN` | Gen2 is architecturally allowed but not hardware-qualified | Endpoint/parent capability and negotiated 5.0 GT/s x1 evidence, reset/retrain/AER results |
| `OD-05` | Actual `user_clk` after Gen2 | `OPEN` | XCI request, metadata, and routed evidence are not fully consistent | Generated/post-route clock proof and later hardware lifecycle/frequency measurement |
| `OD-07` | Final V4L2 pixel format | `OPEN` | Linux frontend is planned and end-to-end format presentation is not decided | Userspace compatibility analysis and explicit V4L2 format decision |
| `OD-08` | Timestamp architecture | `OPEN` | Source, DMA, host, monotonic, and cross-card timestamp semantics are undecided | Clock-domain/source definition, wrap/synchronization policy, V4L2 mapping, validation plan |
| `OD-09` | Persistent card identity | `OPEN` | Enumeration order is not a stable two-card product identity | Hardware identity source and persistent card/input mapping policy |
| `OD-10` | Future LitePCIe role | `OPEN` | It is only a potential later backend; compatibility and value are unproven | Transport abstraction contract, feature/performance/resource comparison, Owner decision |
| `OD-11` | Actual PRODUCT post-route LUT result | `OPEN` | 17,512 LUT / 84.192% is only a G2B-LUT0 estimate | Paired G2B-LUT1 post-route utilization proving `<=90%`, preferably `80–85%` |
| `OD-12` | Actual PRODUCT and RESEARCH_DIAGNOSTIC timing | `OPEN` | No profile implementation or post-route timing result exists | Complete timing/DRC/CDC requalification of both profiles |
| `OD-13` | Actual G2B hardware result | `OPEN` | No G2B bitstream, DMA capture, or hardware proof exists | Separately authorized hardware qualification after offline acceptance |
| `OD-14` | R2/R3 scientific closure | `OPEN` | R-track is `HOLD`, not closed | Resume research through RESEARCH_DIAGNOSTIC and obtain explicit scientific closure decision |

## Decided at project-state revision 7 — Groups 15–17

| Decision subject | Decision | Lifecycle status | Decision state | Covered groups |
|---|---|---|---|---|
| `GROUPS15_17_RELEASE_SLOT_SIGNOFF_METHODOLOGY` | `PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC` | `ACCEPTED` | `RESOLVED` | 15, 16, 17 |

Record form: `UNNUMBERED_GOVERNED_DECISION`. Owner/Architect approval is
granted by `META-7R_TASK_DIRECTIVE`; accepted evidence is `v41-development-g2b-g15-17-release-slot-equivalence-audit` at `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`.
Routed cones are `PARTIALLY_EQUIVALENT`; safety-protocol equivalence is
`PROVEN`; every slot retains independent timing collections and routed
checks. The global methods are retired; each slot's three-family replacement
is promoted with a `6.000 ns` cap. RTL change required is `NO`.
Active XDC is `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED` for Groups 15–17.
Next task is `G2B-LUT1-SIGNOFF-RECOVERY-4`; Groups 9–14 PASS are preserved and G2B-HW is `BLOCKED`.

`EXISTING_UNRELATED_OD_ENTRIES_CHANGED = NO`. All earlier decision records
below remain verbatim. Their implementation-pending and Groups 15–17 pending
statements describe HISTORICAL promotion-time context and are SUPERSEDED as
current continuation instructions by this revision-7 decision. Their accepted
methods, numerical bounds and evidence identities remain authoritative.

## Decided at project-state revision 6 — Group-14 implementation pending

| ID / question | Decision | Lifecycle status | Decision state | Accepted evidence |
|---|---|---|---|---|
| Unnumbered governed decision / Group-14 `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off methodology | `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC` | `ACCEPTED` | `RESOLVED` | G14-A `9e91315968453e859006077191cd5fc711fc6b96`, directory `v41-development-g2b-g14a-release-slot0-signoff-audit` |

This is a named, unnumbered governed decision; no `OD-*` identifier is
invented. It retires the global `GLOBAL_SET_BUS_SKEW_3NS` and Group-14
`report_bus_skew` from required `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off for
the historical 56-source/20-destination scope and promotes
`SETTLING_PLUS_STRUCTURAL_CDC`. The accepted method requires exactly the
`RELEASE_SLOT0_NORMAL_STATE_TRANSITION`,
`RELEASE_SLOT0_MISMATCH_CONTAINMENT`, and
`RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING` families, each with a `6.000 ns`
absolute datapath-only settling bound, plus the accepted held-token lifetime,
two-stage release-toggle and transport-request synchronization, event ordering,
captured release-phase retirement, completion barrier, token identity,
destination-use ordering, and reset/release coherency proof.

`RTL_CHANGE_REQUIRED = NO`. `ACTIVE_XDC_CHANGE =
AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`; the candidate authority is
`G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from the accepted G14-A evidence commit.

Implementation of `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` and the remaining
routed hard gates remain pending at `G2B-LUT1-SIGNOFF-RECOVERY-3`; G2B-HW
remains `BLOCKED`. Group 9 PASS, Groups 10–12 PASS, and Group 13 PASS are
preserved, while Groups 15–17 remain pending. All 12 registered `OD-*`
open-decision entries above, the existing OD-03 decided record, and the
revision-4 Group-9 and revision-5 Group-13 unnumbered decisions below are
unchanged.

## Decided at project-state revision 5 — Group-13 implementation pending

| ID / question | Decision | Lifecycle status | Decision state | Accepted evidence |
|---|---|---|---|---|
| Unnumbered governed decision / Group-13 `RESET_RETURN_SOURCE_TO_AXI` sign-off methodology | `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC` | `ACCEPTED` | `RESOLVED` | G13-A `10c7c2898d162af8e2262b3f99861c7d560c4557`, directory `v41-development-g2b-g13a-reset-return-signoff-audit` |

This is a named, unnumbered governed decision; no `OD-*` identifier is
invented. It retires the global `GLOBAL_SET_BUS_SKEW_3NS` and Group-13
`report_bus_skew` from required `RESET_RETURN_SOURCE_TO_AXI` sign-off and
promotes `SETTLING_PLUS_STRUCTURAL_CDC`. The accepted method requires exactly
the `RESET_ABANDONED_COUNT_STABLE_PAYLOAD` and
`RESET_COMMIT_PHASE_COMPLETION_BARRIER` families, `6.000 ns` absolute
datapath-only settling, retained broad aggregate `6.000 ns` coverage, and the
accepted structural request/acknowledgement, stable-hold, live commit-phase
equality, hard-episode, coherency, sequencing, and atomic epoch/state proof.

Implementation of `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc` and the remaining
routed hard gates remain pending at `G2B-LUT1-SIGNOFF-RECOVERY-2`; G2B-HW
remains `BLOCKED`. All 12 registered `OD-*` open-decision entries above, the
existing OD-03 decided record, and the revision-4 Group-9 unnumbered decision
below are unchanged.

## Decided at project-state revision 4 — sign-off recovery pending

| ID / question | Decision | Lifecycle status | Decision state | Accepted evidence |
|---|---|---|---|---|
| Unnumbered governed decision / Group-9 `OWNERSHIP_AXI_TO_SOURCE` sign-off methodology | `REPLACE_GLOBAL_BUS_SKEW_WITH_PER_FAMILY_SETTLING_CHECKS` | `ACCEPTED` | `RESOLVED` | BS1R `f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62`; BS2 `4699632c591238fee46ada3b0de37532fddd0b6f`; BS3 `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae` |

This is a named, unnumbered governed decision; no `OD-*` identifier is
invented. It retires `GLOBAL_SET_BUS_SKEW_3NS` from required Group-9 sign-off
and promotes `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC`. Implementation of the
accepted candidate XDC and final routed sign-off remain pending, and G2B-HW
remains `BLOCKED`. All 12 registered `OD-*` open-decision entries above and
the existing `OD-03` decided record below are unchanged.

## Decided at project-state revision 3 — implementation pending

| ID / question | Decision | Lifecycle status | Decision state | Accepted evidence |
|---|---|---|---|---|
| `OD-03` / How can G2B fit safely in XC7A35T? | Use `PRODUCT` + `RESEARCH_DIAGNOSTIC` profiles and remove G2B-LUT0-classified research-only instrumentation from PRODUCT while preserving full qualified R1i functional behavior and all external product semantics | `ACCEPTED` | `DECIDED / IMPLEMENTATION_PENDING` | `v41-development-g2b-lut0-resource-attribution`, commit `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` |

This decision authorizes the architecture and G2B-LUT1 implementation scope;
it does not select a source mechanism, prove the LUT target, qualify timing,
produce a bitstream, prove hardware, or close R2/R3. R-track state is `HOLD`,
not `CLOSED`, `CANCELLED`, or `SUPERSEDED`.

## Closed at project-state revision 2

`OD-06 / Final C2H transport ABI` is removed from the open table after
Owner/Architect acceptance of G2B-PRE and this authorized META-2 transaction.
The closed interface facts have lifecycle status `FROZEN`; G2B implementation
remains `NOT_IMPLEMENTED`, hardware remains `NOT_PROVEN`, and the closure does
not decide `OD-07` through `OD-10`.

| Closed technical subdecision | Frozen resolution | Status | Accepted evidence |
|---|---|---|---|
| Offset `0x38` semantics | Per-logical-channel `channel_attempt_sequence`; assign current value before increment at each eligible attempt; first value 0 per epoch; dropped, malformed, and aborted attempts consume a value modulo `2^32` | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Offset `0x3C` semantics | Shared `global_stream_sequence`; assign at `COMMITTED -> DMA_OWNED` before beat 0; increment only on beat-511 handshake; first value 0 and complete records contiguous per epoch | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Reset epoch | Header `0x08` and MMIO `0x3838` carry one shared per-card modulo-`2^32` transport epoch; configuration establishes 0 and each completed transport-reset episode advances exactly once | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Sequence reset/wrap/drop behavior | Transport sequences wrap modulo `2^32`, reset only on a new transport epoch, preserve defined source-sequence independence, and expose failed eligible attempts as per-channel gaps without consuming global order | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Build identity | No per-record build ID; `0x08` is reset epoch and the complete legacy read-only MMIO identity tuple is authoritative for the device session | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Flags | Bits 0, 2, 3, 4, 5, and 6 are `SOF`, `DISCONTINUITY`, `OVERFLOW_OCCURRED`, `MALFORMED_PRECEDING`, `VALID`, and `WINDOW_END`; bit 1 and bits `7..31` are zero, with no speculative EOF/reset/source/drop flag | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Channel identity | Logical IDs 0 and 1 and physical IDs 0 through 3 are frozen zero-extended namespaces; G2B emits logical 0, physical 0, active count 1 without claiming channel-1 implementation | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Payload/frame reconstruction | Each record carries one validated 1,920-pixel active UYVY line; lines `0..1079`, SOF on line 0, no EOF; a complete frame requires every ordered line under one identity | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Padding | Bytes `3904..4095` are formatter-generated zero with full `TKEEP`; stale/unwritten RAM is forbidden and Linux validates zero before ignoring padding | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Ownership/drop/backpressure/reset | Four private slots use the frozen five-state ownership cycle; committed data is immutable; whole-record drop preserves owned records; AXI stall signals remain stable; reset exposes no suffix and resumes at beat 0 | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| MMIO base/range | G2B exclusively claims `0x3800..0x3BFF`; defined words end at `0x3858`, the rest is reserved-zero, `0x3C00..0x3FFF` stays future-reserved, and all behavior through `0x37FF` remains protected | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Control/status | `CONTROL` at `0x380C` and `STATUS` at `0x3810` have exact enable, statistics reset, stream reset, live state, source, busy, snapshot, and fatal semantics | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Counters/capabilities/errors | Exact register addresses, widths, increment/clear rules, support-versus-implementation capability split, six sticky errors, fatal recovery, and last-cause priority are frozen | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Read coherency | Cross-domain counters use explicit request/acknowledge coherent snapshots, stable shadows, sequence-valid bits, and an epoch-before/after retry rule; torn live reads are forbidden | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Forward compatibility | Major mismatch is rejected; ABI 1.0 reserved fields must be zero; compatible minor evolution preserves the complete base layout/geometry/semantics; layout or mandatory semantic change requires a new major and record version | `FROZEN` | `v41-development-g2b-pre-c2h-abi-mmio-freeze`, commit `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |

## Additional qualification dependencies

The following are not separate architecture decisions but remain unqualified
conditions tied to the open items:

- the second physical NVP digital ingress/pin or multiplexing contract;
- one-channel application DMA correctness;
- two-channel DMA correctness and loss isolation;
- sustained `>= 288 MB/s` payload with zero unexplained drops;
- two-card simultaneous operation;
- Linux/V4L2 implementation and application compatibility; and
- future DMABUF/zero-copy behavior.

None may be reported as accepted solely because prerequisite evidence or an
engineering gate passes.
