# AHD Open Decisions

`PROJECT_STATE_REV = 3`

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
