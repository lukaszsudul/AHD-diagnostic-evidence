# G2B-BS3 Protocol Timing Margin

## Clock and synchronizer facts

| Item | Value |
|---|---:|
| AXI sender clock (`userclk1`) | 16.000 ns |
| Source receiver clock (`nvp_vclk1`) | 6.734 ns |
| Request synchronizer | 2 source-domain stages |
| Ack synchronizer | 2 AXI-domain stages |
| Request recognition | Procedural sync2-vs-seen test, one edge after sync2 is updated |
| Ack recognition | Procedural ack-sync2 equality test, one edge after sync2 is updated |

## Forward settling window

Payload and request launch on the same AXI edge. At the first eligible source edge, sync1 may capture the request. At the next source edge sync2 captures sync1, while the procedural decision still sees the prior sync2 value. The source can first evaluate the new request at the following edge.

Consequently, the earliest semantic-use edge is separated from launch by two complete destination periods:

`2 * 6.734 ns = 13.468 ns`

Clock phase, routing delay, or metastability can delay recognition; none can create an earlier semantic-use edge than this structural lower bound.

## Margin policy

The chosen constraint is 6.000 ns for each of slot, generation, and epoch. It is not equal to the theoretical window:

| Quantity | Value |
|---|---:|
| Theoretical minimum launch-to-use window | 13.468 ns |
| Candidate absolute datapath cap | 6.000 ns |
| Remaining gross policy margin | 7.468 ns |
| Routed FDRE-setup-adjusted margin | approximately 7.436 ns |
| Remaining margin in source-clock periods | 1.109 periods |
| Cap below one source-clock period | 0.734 ns |
| Fraction of theoretical window consumed | 44.55% |

The value is retained from the already-present aggregate acknowledged-mailbox cap, so BS3 does not invent or relax a number. It is below one complete 6.734 ns destination cycle and leaves more than one additional destination cycle before the earliest decision. The approximately 7.436 ns adjusted figure conservatively subtracts the 0.032 ns FDRE setup term shown by the successful routed BS3 paths. Because the intended physical cap is a true 6.000 ns datapath limit, BS3 requires both `DATAPATH_DELAY <= 6.000 ns` and nonnegative reported slack; slack alone could permit approximately 6.032 ns when that setup term is present. The three fields receive the identical deadline so their atomic-token semantics remain common even though they are reported separately.

`RECOMMENDED_MAX_DELAY_PER_FAMILY = 6.000 ns`

## Hold duration and acknowledgement return

The acknowledgement launched with the source decision cannot be consumed by AXI until it traverses two 16.000 ns synchronizer stages and the registered equality test observes sync2. In the aligned, no-metastability earliest-edge sequence, consumption is the third following AXI edge, 48.000 ns after the original launch. Independently of forward clock phase, ack-to-use provides at least two complete AXI periods (32.000 ns); metastability can only extend it.

In a normal transaction the forward payload is held for at least that interval and, structurally, much longer: acknowledgement success advances through prefetch and a 512-beat stream before scheduling can return to idle, and backpressure can extend the hold indefinitely. In a reset-overlap transaction the old result need not be consumed; reset explicitly cancels/retires it, and `stream_reset_busy_axi` prevents reuse of idle state until retirement. Therefore overwrite exclusion is protocol-dominant rather than a narrowly timed pulse assumption.

The reverse `own_ok_hold_source` result is launched with the ack and is covered by the retained 6.000 ns source-to-AXI aggregate max-delay relationship. Against the two-AXI-period minimum ack-use window of 32.000 ns, that retained cap leaves 26.000 ns.

## Numerical-bound decision

A numerical bound is supported; `REQUIRES_ARCHITECTURAL_PARAMETER` is not required for this implementation. The proof is for the routed STA model in which the fastest qualified `nvp_vclk1` period is 6.734 ns; any tolerance/jitter outside that model must be incorporated before promotion. Future changes to the clock period, synchronizer depth, request detection point, or payload launch/hold behavior invalidate the derivation. The sign-off harness must gate clock identity/period as well as object identities/counts so such a change cannot silently inherit 6.000 ns.
