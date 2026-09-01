# G2B-BS3 Candidate Timing-Strategy Evaluation

## Decision basis

The forward mailbox launches one registered `{slot,generation,epoch}` token with a request toggle, uses the token only after two source-domain synchronizer stages plus registered detection, and prevents another launch until normal acknowledgement/result completion or explicit reset cancellation/retirement. Its safety property is a common absolute settling deadline, not pairwise route matching.

| Candidate | Safety property it proves | Semantic fit | What it does not prove | Runtime expectation | False-confidence risk | Decision |
|---|---|---|---|---|---|---|
| A. Per-family `set_max_delay -datapath_only` | Every constrained path from a coherent field reaches every payload-dependent endpoint within an absolute cap | Direct fit; slot, generation, and epoch each receive the same 6.000 ns deadline | Request/ack structure, hold behavior, reset retirement, or exact object identity without companion checks | Focused family queries should complete in seconds/minutes after checkpoint setup | Low only when exact names, exception effectiveness, datapath delay, and slack all pass | SELECT |
| B. Narrow per-family `set_bus_skew` | Bounds relative arrival spread within that family | Not required: destination does not independently snapshot an unqualified vector; all fields reconverge under request qualification | Cannot bound a common-mode late arrival and cannot prove hold/control safety | Potentially higher; topology can still create expensive skew enumeration | High because a passing relative check can coexist with unsafe absolute lateness | REJECT |
| C. No payload timing constraint | Nothing physical; relies on presumed protocol dominance | Incomplete for same-edge payload/request launch because structural synchronizer depth alone does not bound data routing | Any absolute settling deadline | Fastest | Very high: all data bits could arrive late together | REJECT |
| D. Explicit point-to-point max-delay commands | Same absolute cap for individually enumerated endpoints | Semantically valid | Structural/reset proof; also becomes verbose and fragile as implementation identities change | Practical but query/maintenance volume grows | Medium: an omitted point silently escapes unless exhaustive identity/coverage checks exist | VALID BUT NOT PREFERRED |
| E. Structural CDC proof plus bounded physical delay cap | Control synchronization, stable-data lifetime, reset/epoch handling, and physical settle-before-use together | Complete match to the implemented bundled-data mailbox | Liveness if a clock stops; MTBF magnitude; counter-wrap/corruption outside the stated fault model | Focused queries practical; full DCP/base setup observed as marginal | Lowest of the evaluated choices because protocol and implementation are both gated | RECOMMENDED COMPOSITE |
| F. False paths, clock groups, multicycle paths, or `set_data_check` substitution | Depending on command, suppresses or reshapes ordinary timing analysis | Does not express this register-to-registered bundled-data absolute deadline as clearly as datapath-only max delay | A reliable absolute cap plus the structural proof | Usually fast | High: suppression can appear clean without proving settling | REJECT |

## Selected method

The replacement is candidate E implemented physically by candidate A:

1. prove the request/ack toggle structure, hold/cancellation behavior, and reset/epoch semantics;
2. apply three 6.000 ns `set_max_delay -datapath_only` constraints to the exact 2/24/32 families and exact 17 payload-dependent destination D pins;
3. fail closed on exact BS0 identities, synchronizer attributes, and 16.000/6.734 ns clock model;
4. require both raw datapath delay at or below 6.000 ns and nonnegative slack;
5. inspect candidate exception coverage/ignored-exception output and focused methodology rules.

This method is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` than the old global relative-skew check. It is not approved merely for speed; it proves the property the handshake actually needs.
