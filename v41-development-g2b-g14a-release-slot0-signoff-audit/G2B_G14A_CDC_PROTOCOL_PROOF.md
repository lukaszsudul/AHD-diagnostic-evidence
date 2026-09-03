# G2B-G14-A CDC and protocol proof

## Crossing mechanism

- Data/state crossing: 24-bit generation plus 32-bit epoch travels as stable data from `userclk1` to combinational comparisons in `nvp_vclk1`.
- Ordinary-release event crossing: `release_toggle_axi[0]` travels through `release_sync1_source[0]` and `release_sync2_source[0]`.
- Reset-accounting qualifier crossing: `transport_req_toggle_axi` travels through `transport_req_sync1_source` and `transport_req_sync2_source`.
- Synchronization depth: two destination-domain stages on each qualifier chain, all marked `ASYNC_REG = TRUE`.
- Destination event history: `release_seen_source[0]` records the consumed or reset-retired toggle phase; it is not a payload capture register.

## Launch-to-consume ordering

Generation, epoch, and toggle are updated together on the final accepted AXI stream beat. For ordinary release, the destination compares `release_sync2_source[0]` with `release_seen_source[0]` and consumes the stable token only when they differ. If reset is launched on that same edge, AXI captures the updated release phase and toggles the transport request; reset-overlap accounting executes only when `transport_req_sync2_source != transport_req_seen_source`. Nonblocking update ordering on either two-stage chain provides at least two complete destination periods between same-edge launch and semantic use. The bounded family max-delay checks show worst routed datapath delays of `5.467 ns`, `5.554 ns`, and `4.191 ns`, each below the governed `6.000 ns` cap.

## Stability proof

An ordinary release has no direct request/ack response. Stability is guaranteed by protocol ownership:

1. The slot-0 token is written only at the final beat of slot-0 streaming.
2. A valid token changes slot 0 from `DMA_OWNED` to `RELEASABLE`, then to `WRITABLE` on the next source edge.
3. Before slot 0 can launch another release, it must be refilled, committed, handed to AXI ownership, and stream another full 512-beat record.
4. Therefore neither token field can be overwritten before the synchronized event is consumed.

The two payload read sites in RTL are the ordinary release decoder and transport-reset overlap accounting. Their complete same-edge register closure is exactly the ten endpoints in the three candidate families.

## Fail-closed token validation

Normal consumption requires all of:

- release generation equals the slot generation;
- release epoch equals the descriptor epoch;
- release epoch equals the current reset epoch; and
- slot state is `DMA_OWNED`.

Failure latches the ownership-fatal path and disables admission. A stale token cannot silently release a newer owner.

## Reset/epoch behavior

When transport reset is active, ordinary release decoding is suppressed. The AXI-side reset request captures the release phase and explicitly XORs in a same-edge final-beat release. Consumption of the two-stage synchronized transport request—not a release-toggle mismatch—triggers the source to use generation and epoch for `release_matches`, compute `reset_abandoned_hold_source`, and force slots writable. It then delays transport acknowledgement until the independently synchronized release vector equals the captured phase. It also advances/compares reset epoch so an old-lifetime token cannot qualify a newer owner of slot 0.

Reset episode storage intentionally survives later AXI reset behavior long enough to retire the protocol. Product integration does not introduce a second source-domain writer. The protocol thus supplies `STABLE_DATA_UNTIL_EVENT_CONSUMPTION`, `EVENT_ORDERING`, `SYNCHRONIZER_STRUCTURE`, `COMPLETION_BARRIER`, and `TOKEN_IDENTITY` in addition to the physical settling checks. Token identity includes independent generation equality for same-epoch slot reuse and epoch equality for reset-lifetime separation.

## Classification

`GROUP14_CDC_STRUCTURE = PASS_WITH_DISPOSITION`

The RTL CDC/protocol structure is sound and requires no RTL change. Disposition is required because the active Group-14 bus-skew scope does not express or completely cover this structure's safety invariant.
