# AHD v41 G2B-G13-A — Safety Invariant

## Required invariant

For each accepted transport-reset request:

1. The source captures the abandoned-count and commit-phase payloads in one
   `source_clk` edge.
2. Those payloads remain unchanged while the corresponding acknowledgement is
   outstanding.
3. Every payload-dependent AXI data/control cone settles within `6.000 ns` of
   that source capture.
4. AXI may semantically consume the payload only after the returned
   acknowledgement has passed its two-stage synchronizer and the independently
   synchronized live commit vector equals the held commit phase.
5. Reset epoch/state publication occurs on that qualified completion edge, so
   no mixed old/new returned state is externally accepted.

This is `SETTLING_BEFORE_VALID` plus `STABLE_UNTIL_ACK` and structural
synchronizer proof.

## Timing window

`userclk1` has a routed period of `16.000 ns`. Even when the held payload and
acknowledgement launch on the same source edge, the acknowledgement must pass
the `sync1` and `sync2` flops. Because the completion logic reads the previous
`sync2` value in the same nonblocking AXI process, the earliest semantic use is
two complete AXI periods after the earliest stage-1 capture, approximately
`32.000 ns` after launch. Metastability can delay validity; it cannot make it
earlier.

The `6.000 ns` datapath-only bound therefore leaves approximately `26.000 ns`
of gross launch-to-use reserve in that nominal earliest-cycle model. This is
not formal timing slack or a metastability margin. The bound is also the
already governed aggregate source-mailbox cap, so the replacement does not
relax absolute physical settling.

## Why 3 ns mutual skew is not required

No AXI edge is allowed to treat the seven raw bits as valid merely because one
bit arrived. The acknowledgement is the validity event. A binary count may
transition on several bits, and the four commit-phase bits are per-slot toggle
phases, but both values settle long before qualified use. Relative arrival
spread among an abandoned-count bit, a commit-phase bit, and an unrelated
completion-controlled endpoint is not a correctness property.

The replacement is safe only as the conjunction of the absolute settling cap
and structural protocol proof. Synchronizer structure alone would not prove a
physical payload bound; max delay alone would not prove hold/qualification.
