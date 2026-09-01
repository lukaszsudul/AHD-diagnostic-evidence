# G2B-BS3 Request/Acknowledgement Sequence Proof

## Normal ownership transaction

The labels below denote active clock edges, not equal wall-clock intervals because the two clocks are asynchronous.

1. **A0 — AXI launch (`userclk1`)**: `scheduler_pop` loads `{slot,generation,epoch}`, toggles `own_req_toggle_axi`, and sets `axis_state=AXIS_WAIT_OWN`.
2. **S1 — first eligible source edge (`nvp_vclk1`)**: `own_req_sync1_source` captures the request phase. The payload continues settling but is already required to complete within 6.000 ns of A0.
3. **S2 — second source edge**: `own_req_sync2_source` captures sync1. The procedural new-request test still sees the prior sync2 value because assignments are nonblocking.
4. **S3 — third source edge**: the test sees `own_req_sync2_source != own_req_seen_source`. At least 13.468 ns have elapsed since launch in the earliest phase case. The source evaluates selected state, generation, descriptor epoch, and current epoch; it registers the success/failure effects and `own_ok_hold_source`, records the request phase, and launches `own_ack_toggle_source`.
5. **A1 — first eligible AXI edge after S3**: `own_ack_sync1_axi` captures the ack phase.
6. **A2 — second AXI edge**: `own_ack_sync2_axi` captures sync1; the procedural equality test still sees the prior sync2 value.
7. **A3 — third AXI edge**: `AXIS_WAIT_OWN && own_ack_sync2_axi == own_req_toggle_axi` becomes true. AXI consumes the stable `own_ok_hold_source`. Success enters prefetch; failure enters error hold.
8. **Later AXI edges**: success streams the record. Only the final beat handshake launches the generation/epoch-qualified release and returns `axis_state` to idle. A later ownership payload can be launched only by a new `scheduler_pop` from idle.

## Safety deductions

- At A0 the payload is registered no later than the request.
- Between A0 and S3, the 6.000 ns bound expires at least 7.468 ns before the earliest semantic-use edge.
- Between A0 and A3 in normal operation, `axis_state != AXIS_IDLE`, so the payload cannot be overwritten. If reset forces idle earlier, `stream_reset_busy_axi` and retirement guards still prevent `scheduler_pop`.
- At S3 result and ack launch together. The reverse result has a retained 6.000 ns cap and at least 32.000 ns before ack-based AXI use.
- A3 consumes the result before any later `scheduler_pop` is possible; the reset alternative explicitly cancels/retires the old result before scheduling can resume.
- Metastability can postpone request or ack recognition by a cycle; postponement increases data settling/hold time and cannot create premature use.

## Failure transaction

The same timing sequence applies. A state/generation/epoch mismatch keeps `own_ok_hold_source=0`, latches the ownership fatal state/event, disables source admission, and still acknowledges the request. AXI observes the low result only after ack sync2, records the ownership error, and enters `AXIS_ERROR_HOLD`. No new payload can overwrite the failed token before recovery.

## Reset overlap

Transport reset has priority over ordinary ownership decoding. AXI captures `own_req_toggle_axi` in `transport_own_phase_hold_axi`. Source aligns `own_req_seen_source` and `own_ack_toggle_source` to that captured phase; if sync2 has not reached it, `transport_retire_pending_source` delays transport acknowledgement. Reset aborts AXIS wait, flushes old commits/enable, and keeps `scheduler_pop` blocked until phase retirement and a new enable/capture/commit sequence. This converts a lagging pre-reset request into a retired phase, not a new post-reset transaction. Reset installs a new epoch, so an old token fails epoch equality. If `axi_aresetn` falls during an already-active transport reset, `transport_followup_hard_axi` records a follow-up episode and reuses the pending epoch rather than issuing a cancelling toggle.

## Sequence result

- Request synchronizer: `PASS`.
- Ack synchronizer: `PASS`.
- Stable-data hold: `PASS`.
- Settle-before-use: requires the passing BS3 6.000 ns per-family timing checks.
- Reset/stale-phase safety: `PASS_WITH_ASSUMPTION` for eventual clock progress, normal synchronizer resolution, supported configuration initialization, and the stated finite-counter fault model.
