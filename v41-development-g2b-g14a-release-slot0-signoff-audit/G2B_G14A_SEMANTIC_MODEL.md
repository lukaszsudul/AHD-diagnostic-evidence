# G2B-G14-A semantic model

## Classification

`RELEASE_SLOT_0_AXI_TO_SOURCE` is a 56-bit stable-data release token. Ordinary release use is qualified by a one-way release-toggle event; reset-overlap accounting is qualified by a separately synchronized transport-reset request and tied to a captured release phase. It is not Gray-coded state, an independent-bit status vector, a conventional request/ack mailbox, or a multibit register captured as one destination data word.

The token comprises:

- `release_generation_axi[0][23:0]`: slot-generation identity.
- `release_epoch_axi[0][31:0]`: reset-epoch identity.
- `release_toggle_axi[0]`: event qualifier, outside the Group-14 source collection.

## Launch and crossing

At accepted C2H beat 511, RTL lines 1791-1805 update generation, epoch, and toggle on the same `userclk1` edge. The toggle crosses to `nvp_vclk1` through `release_sync1_source[0]` and `release_sync2_source[0]`; both stages carry `ASYNC_REG = TRUE` (lines 205-210 and 456-468). When reset issuance overlaps that final beat, `transport_release_phase_hold_axi` explicitly incorporates the same-edge toggle and `transport_req_toggle_axi` is launched on that edge. The transport request crosses its own two `ASYNC_REG` stages, `transport_req_sync1_source` and `transport_req_sync2_source`.

The data fields do not pass through per-bit synchronizers. They are stable-data qualifiers whose physical settling must precede semantic use triggered by the synchronized release toggle or, for reset overlap, the synchronized transport request. Because each second stage is updated nonblocking and the relevant decode reads its previous value on that edge, semantic use cannot occur earlier than two complete `nvp_vclk1` periods after same-edge launch. At the routed period of `6.734 ns`, that gross window is `13.468 ns`.

## Destination behavior

There are three real same-edge endpoint-role families:

1. Normal state transition: a matching token permits only slot 0 `DMA_OWNED -> RELEASABLE`; the following source edge advances `RELEASABLE -> WRITABLE`.
2. Mismatch containment: a generation, epoch, reset-epoch, or state mismatch latches ownership fatal/event/deferred state and disables source admission.
3. Reset-overlap accounting: consumption of the synchronized transport-reset request reads the release token against the captured release phase to determine whether an old committed/owned record is counted as abandoned before reset acknowledgement.

The three families use all 56 source bits as one token. The full one-row-per-cell closure is in `raw/timing/G2B_G14A_OBJECT_INVENTORY.csv`. No other destination register has a direct or blocking-variable-transitive same-edge dependence on the slot-0 token; later effects cross a register boundary.

## Stability and reuse

There is no explicit acknowledgement returned for an ordinary release. Stability is instead guaranteed by slot lifecycle exclusion: release makes the slot writable; the slot must be refilled, committed, ownership-acknowledged, and streamed for 512 beats before that same slot's release payload can be rewritten. Thus the token remains stable through event consumption and far beyond the two-stage synchronization latency.

## Reset and epoch model

The reset epoch prevents a delayed old release from freeing a newer owner of slot 0. During a transport reset, ordinary release decode is suppressed. The AXI side captures the release-toggle phase, explicitly including a same-edge beat-511 release, and launches the transport request. Consumption of the separately synchronized transport request triggers reset-abandoned accounting using the token. The source then withholds transport acknowledgement until the independently synchronized release phase reaches the captured phase. Release history is retired at that barrier.

The release payload/toggle storage survives later `axi_aresetn` episodes by design, and product-top `source_reset`/standalone behavior does not create a second writer. The epoch comparisons make stale tokens fail closed.

## Model result

The semantic object is a coherent payload, but the current timing path set is not a homogeneous bus bundle. Correct sign-off combines an absolute settling bound for the three real endpoint-role families with structural proof of toggle synchronization, payload stability, event ordering, and reset completion retirement.
