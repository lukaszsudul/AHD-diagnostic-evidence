# AHD Open Decisions

`PROJECT_STATE_REV = 1`

Every item below has lifecycle status `OPEN`. An agent may investigate or
publish evidence about an item, but may not silently choose a value or update
project truth. Closure requires an explicit Owner/Architect decision and, when
the SSOT changes, a separate authorized META update.

| ID | Decision | Status | Why unresolved | Required closure evidence / decision |
|---|---|---|---|---|
| `OD-01` | Exact R1i causal mechanism | `OPEN` | R1i proves the intervention works but sole-root-cause attribution is `INCONCLUSIVE` | Accepted R1 controlled evidence discriminating physical SCL, ACK sampling, combined effect, and recovery/readiness |
| `OD-02` | R1i timing margin | `OPEN` | Qualified point behavior is not a complete margin characterization | Triggered margin campaign with controlled timing sweep, failure boundaries, and Owner decision |
| `OD-03` | Diagnostic reduction | `OPEN` | Substantial overhead exists but exact removable R1i LUT count is `UNKNOWN` | Accepted R-track closure, fanout/behavior proof, A/B resource/functional evidence, ABI review |
| `OD-04` | Actual Gen2 training | `OPEN` | Gen2 is architecturally allowed but not hardware-qualified | Endpoint/parent capability and negotiated 5.0 GT/s x1 evidence, reset/retrain/AER results |
| `OD-05` | Actual `user_clk` after Gen2 | `OPEN` | XCI request, metadata, and routed evidence are not fully consistent | Generated/post-route clock proof and later hardware lifecycle/frequency measurement |
| `OD-06` | Final C2H transport ABI | `OPEN` | v41D is a concrete G1 plan but explicitly not fully implementation-frozen | Golden vectors, parser/device agreement, reset/drop/timestamp semantics, interface acceptance |
| `OD-07` | Final V4L2 pixel format | `OPEN` | Linux frontend is planned and end-to-end format presentation is not decided | Userspace compatibility analysis and explicit V4L2 format decision |
| `OD-08` | Timestamp architecture | `OPEN` | Source, DMA, host, monotonic, and cross-card timestamp semantics are undecided | Clock-domain/source definition, wrap/synchronization policy, V4L2 mapping, validation plan |
| `OD-09` | Persistent card identity | `OPEN` | Enumeration order is not a stable two-card product identity | Hardware identity source and persistent card/input mapping policy |
| `OD-10` | Future LitePCIe role | `OPEN` | It is only a potential later backend; compatibility and value are unproven | Transport abstraction contract, feature/performance/resource comparison, Owner decision |

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
