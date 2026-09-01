# G2B-BS3 Structural CDC Proof

## Result

`OWNERSHIP_CDC_STRUCTURE = PASS_WITH_DISPOSITION`

The request/ack structure and protocol hold invariants are proven. Reset/epoch safety is proven with explicit clock-progress, configuration-initialization, synchronizer-resolution, and finite-counter fault-model assumptions. The direct forward bundled-data `CDC-1` rows are dispositioned by the acknowledged stable-data protocol plus the BS3 absolute settling checks; they are not waived as ordinary synchronized bits.

## Proof table

| Proof obligation | Classification | Evidence |
|---|---|---|
| Request crosses intended stages | PROVEN | `own_req_toggle_axi -> own_req_sync1_source -> own_req_sync2_source`; both stages `ASYNC_REG=TRUE`; routed `CDC-3`, depth 2. |
| Ack crosses intended stages | PROVEN | `own_ack_toggle_source -> own_ack_sync1_axi -> own_ack_sync2_axi`; both stages `ASYNC_REG=TRUE`; routed `CDC-3`, depth 2. |
| Only first synchronizer stage is false-pathed | PROVEN | Production `g2b_cdc.xdc` resolves first-stage D pins; sync1-to-sync2 remains normally timed. |
| Payload is one registered 58-bit token | PROVEN | Exact routed sources are 2 slot + 24 generation + 32 epoch registers; same-edge logical hold duplicates were merged. |
| Payload is held during request propagation | PROVEN | Only assignment site is `scheduler_pop`; normal state becomes `AXIS_WAIT_OWN`, and reset/busy guards prohibit another pop during cancellation. |
| Destination samples only on synchronized new request | PROVEN | Ownership state/result/failure update block requires sync2-vs-seen mismatch and transport quiescence. |
| All payload-dependent cones settle before use | PROVEN_WITH_ASSUMPTION | Structural window 13.468 ns; becomes physically closed only with passing 6.000 ns per-family validation. |
| Source cannot overwrite before ack or reset retirement | PROVEN | Normal FSM states exclude a pop; if reset forces `AXIS_IDLE` before ack, `stream_reset_busy_axi` and retirement guards still exclude a pop. |
| Return result is stable until consumed or cancelled | PROVEN | `own_ok_hold_source` changes only with a later source request; normal AXI consumption waits for ack sync2, while reset explicitly aborts the old AXIS transaction. |
| Transport reset retires lagging request phase | PROVEN_WITH_ASSUMPTION | `transport_retire_pending_source` withholds reset ack until request sync2 equals captured phase; assumes both clocks progress. |
| Epoch/generation reject stale identity | PROVEN_WITH_ASSUMPTION | Selected generation, descriptor epoch, and current reset epoch must all equal the held token; modulo-wrap assumption applies. |
| Product reset asymmetry is safe | PROVEN_WITH_ASSUMPTION | Toggle phases/epoch survive `axi_aresetn`; product `source_reset` and standalone reset inputs are tied low; hard transport reset performs cross-domain retirement. |

## Destination decomposition

The old 19 destinations comprise:

- 12 `slot_state_source` state bits: payload-dependent;
- 1 `own_ok_hold_source`: payload-dependent result;
- 3 ownership fatal/event/deferred registers: payload-dependent failure effects;
- 1 `enable_applied_source`: payload-dependent failure interlock;
- 2 `own_req_seen_source`/`own_ack_toggle_source`: control bookkeeping, not payload-dependent.

The candidate therefore constrains exactly 17 payload-dependent destination D pins and structurally checks the two bookkeeping registers as part of the control protocol.

## Existing routed CDC correlation

The Gen12 focused evidence reports `CDC-1=423`, `CDC-10=2`, and `CDC-13=2` globally. Exact Group-9 correlation found 89 `CDC-1` overlap rows and no `CDC-10`/`CDC-13` overlap. Only four rows are direct 58-source forward-payload crossings; BS3 closes those with the request-qualified stable-data proof and settling bound. Another 69 launch from reverse `own_ok_hold_source`; they are dispositioned by ack qualification plus the retained source-to-AXI 6.000 ns bound. The remaining 16 terminate on old Group-9 sink cells from release/transport sources outside the 58 and remain under their separately preserved protocols/constraints. BS3 does not disposition any other global CDC finding.

## Reset/epoch proof

Mailbox phases are not independently reset by `axi_aresetn`. Initial reset before `axi_seen_high` is masked; a later low creates one hard episode, with `axi_hard_episode` preventing retrigger while held low. During transport reset, AXI captures the current ownership-request phase. Source-domain transport-reset processing has priority over ordinary ownership decoding, installs the new epoch, clears slot generations/states, and aligns seen/ack phases. If the captured request has not reached sync2, completion waits. A hard reset overlapping an active transport reset is coalesced through `transport_followup_hard_axi`, not expressed as a cancelling second toggle. AXI completes reset only after source transport acknowledgement and captured commit phase return. A new ownership token must use the new epoch and a new toggle phase.

No timing replacement can provide liveness if either clock stops. No formal proof of modulo arithmetic was attempted; counter-wrap non-alias is recorded as an architectural assumption.

## RTL decision

`RTL_CHANGE_REQUIRED = NO`

No mailbox RTL invariant was found violated. The literal “one full cycle of payload stability before request launch” is not implemented, but it is not necessary: same-edge registered launch plus a 6.000 ns absolute cap leaves 7.468 ns before the earliest request-use edge. The required change is constraint/sign-off methodology only.
