# AHD v41 G2B-G13-A — Semantic Model

## Classification

`RESET_RETURN_SOURCE_TO_AXI` is a stable-data return mailbox associated with a
toggle/acknowledgement reset protocol. It is not a reset net, a reset-release
vector, a Gray bus, or seven independently synchronized status bits.

The crossing has two payload families:

1. A three-bit binary abandoned-record snapshot.
2. A four-bit per-slot commit-toggle phase snapshot.

The payloads are captured together when the synchronized transport request is
accepted in `source_clk`. They are held until a later transport request. A
single-bit transport acknowledgement returns through a two-stage `ASYNC_REG`
chain. The live per-slot commit toggle also returns through a two-stage
`ASYNC_REG` vector. AXI consumes the held values only when the acknowledgement
matches the request and the synchronized live commit phase equals the held
phase.

Mapped to the task taxonomy, this is:

| Taxonomy | Classification |
|---|---|
| synchronized reset-return status | No — payload is held data, not independently synchronized status |
| Gray-coded status bundle | No |
| toggle/handshake return | Yes — transport request/acknowledgement is the validity protocol |
| multi-bit coherent snapshot | Yes — abandoned count and per-slot commit phase are captured at one source edge |
| independent synchronized control bits | Only the per-slot live commit toggles are independently synchronized for the equality barrier |
| reset epoch vector | Versioned reset epoch exists, but it travels AXI-to-source; the returned payload is associated with its request/ack phase |
| reset release observability | No |
| combinational aggregation after synchronization | Yes — the held commit phase reconverges with synchronized phase/ack into the reset-completion predicate |
| other | Stable-data mailbox qualified by acknowledgement |

## RTL sequence

- AXI publishes an epoch, hard qualifier, release phase, ownership phase, and
  toggled transport request.
- The two-stage source request synchronizer detects the new phase.
- Source clears/retires slot state and captures
  `reset_abandoned_hold_source` and `reset_commit_phase_hold_source`.
- Source returns `transport_ack_toggle_source` immediately if the retirement
  phases already match, or after they match.
- AXI's two-stage acknowledgement synchronizer returns validity.
- AXI additionally waits for `commit_sync2_axi ==
  reset_commit_phase_hold_source` before updating reset-completion state and
  consuming the abandoned count.

## Structural comparability

`PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`

| Inspection dimension | Focused evidence |
|---|---|
| Source domains | All seven held-payload flops use `nvp_vclk1` |
| Destination domain | All 207 original destination cells use `userclk1` |
| Validity synchronizer | Returned acknowledgement crosses two `ASYNC_REG` stages |
| Live-phase synchronizer | Four per-slot commit phases cross two `ASYNC_REG` stages |
| Path depth | Bounded worst-slack path has five logic levels |
| Fanout | Bounded worst-slack path reports maximum fanout 116 |
| Endpoint roles | Routed paths terminate on data/control endpoint roles including `D`, `CE`, `S`, and `R` |
| Logic roles | Arithmetic accounting, captured state, state-machine control, enables, set/reset, and status |
| Reconvergence | Held commit phase reconverges with returned acknowledgement and synchronized live-phase equality |
| Semantic families | Two: abandoned-count stable payload and commit-phase completion barrier |

The original relation combines two different payload meanings and compares
their paths against a reconvergent destination cone containing arithmetic data
paths, direct state capture, equality-controlled enables, status clear paths,
32-bit counters, and state-machine registers. Logic depth and endpoint roles
differ materially. A global arrival-spread number can be dominated by two
paths that are never jointly sampled as one bus and therefore does not prove
the protocol invariant.

The two payload families are valid for absolute settling checks. They are not
valid for a mutual global skew check.
