# G2B-BS3 CDC Invariants

## Primary functional invariant

For every ownership transaction, the complete `{slot,generation,epoch}` token launched with the request must have reached a stable value at every payload-dependent destination D cone before the source domain semantically recognizes the synchronized request. The token must then remain unchanged until the acknowledgement and stable result have returned and been consumed, or until reset explicitly cancels and retires the old transaction. Only a token whose slot state, generation, descriptor epoch, and current reset epoch all match may create the `COMMITTED -> DMA_OWNED` transition.

This invariant is about a common absolute settling deadline and protocol hold time. It does not require every routed payload path to have arrival times within 3.000 ns of every other path.

## Required properties

| ID | Property | Classification | Evidence/disposition |
|---|---|---|---|
| A1 | Payload is stable for a full source cycle before request launch | VIOLATED | Payload and request are registered on the same AXI edge. This literal property is not the implemented contract and is not required once A2/A3 hold. |
| A2 | Payload is registered no later than request launch | PROVEN | Payload assignments and request toggle are in the same `scheduler_pop` branch/AXI edge. |
| A3 | Every payload-dependent cone settles before synchronized request use | PROVEN_WITH_ASSUMPTION | Structural window is at least 13.468 ns; BS3 requires and validates a 6.000 ns datapath-only cap for all three fields. |
| B | Payload remains stable while request crosses sync1/sync2 | PROVEN | Only `scheduler_pop` writes it; normal launch leaves `AXIS_IDLE`, while reset/busy guards prevent a new pop during cancellation. |
| C | Destination makes an ownership state/result decision only after synchronized request validity | PROVEN | Decision is gated by `own_req_sync2_source != own_req_seen_source` and transport-quiescent guards. |
| D | Source cannot overwrite a live payload before acknowledgement returns or reset retires it | PROVEN | Normal wait/prefetch/stream/error states prevent `scheduler_pop`; if reset forces idle early, `stream_reset_busy_axi` and retirement guards keep the scheduler blocked. |
| E | AXI consumes `own_ok_hold_source` only after synchronized acknowledgement, unless reset cancels the transaction | PROVEN | Normal consumption requires `AXIS_WAIT_OWN && own_ack_sync2_axi == own_req_toggle_axi`; reset aborts rather than consuming the old result. |
| F | Reverse result remains stable through AXI consumption | PROVEN | Result changes only on a later source-domain request; retained source-to-AXI max-delay protection applies. |
| G | A stale ownership request cannot replay after transport reset | PROVEN_WITH_ASSUMPTION | The transport handler immediately aligns seen/ack to the captured phase; while sync2 lags, the retirement barrier withholds transport acknowledgement and re-aligns seen/ack when sync2 arrives. Assumes clock progress/config initialization. |
| H | A stale ack cannot satisfy a new request | PROVEN_WITH_ASSUMPTION | Normal operation is phase-specific. Across reset, AXIS wait is aborted, old commits/enable are flushed, and a new capture/commit sequence provides separation while equal-depth ack synchronization resolves; assumes normal synchronizer resolution and clock progress. |
| I | Generation/epoch prevent stale ownership acceptance | PROVEN_WITH_ASSUMPTION | Exact 24-bit generation and dual 32-bit epoch equality; modulo-wrap alias is an architectural assumption. |
| J | A result is consumed or explicitly retired before a later ownership token can replace it | PROVEN | A later `scheduler_pop` is impossible until normal ack processing/stream completion or reset cancellation/retirement has completed. |

## Physical constraint invariant

Each of the three forward payload families has the same requirement:

`payload family datapath delay <= 6.000 ns < 2 * 6.734 ns = 13.468 ns`

The resulting policy margin is 7.468 ns before the earliest semantic-use edge. Applying the same absolute deadline to slot, generation, and epoch preserves atomic-token coherence without requiring pairwise route matching.

## Assumptions

- `userclk1` and `nvp_vclk1` continue to toggle for protocol liveness.
- FPGA configuration initialization is supported and preserved as required by the RTL architecture.
- The sign-off Tcl harness rejects anything other than the qualified 2/24/32 launch registers, 17 payload-dependent receivers, exact synchronizer identities, and the qualified clock periods. The declarative candidate XDC intentionally contains no unsupported procedural assertions.
- The one-outstanding/retirement protocol prevents a normally live token from surviving either finite-counter wrap. Any arbitrarily retained or corrupted internal token across a 24-bit generation wrap or independent 32-bit epoch wrap is outside the proved fault model.
- Normal implementation sign-off continues to check the retained reverse `own_ok_hold_source` maximum-delay relationship.
