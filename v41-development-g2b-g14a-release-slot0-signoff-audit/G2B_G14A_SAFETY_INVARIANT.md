# G2B-G14-A safety invariant

## Failure being prevented

The timing constraint is intended to prevent a synchronized slot-0 release event from being evaluated with a torn, late, or event-misaligned generation/epoch token. Such a failure could:

- release a newer owner of slot 0;
- falsely declare a valid release stale and latch ownership-fatal containment;
- disable admission spuriously; or
- miscount an old record during reset-overlap abandonment accounting.

## Required correctness properties

`RELATIVE_SKEW` across the current 56-by-20 Cartesian path set is not the governing safety property. The actual invariant is the conjunction below.

| Property | Requirement | Proof source |
|---|---|---|
| `ABSOLUTE_SETTLING` | Every existing payload-dependent path must reach its same-edge semantic endpoint before the relevant synchronized qualifier can authorize evaluation. | Existing governed `6.000 ns` datapath-only cap; candidate family timing results. |
| `STABLE_DATA_UNTIL_EVENT_CONSUMPTION` | Generation and epoch must not change while the event crosses and is consumed. | Slot lifecycle exclusion in RTL. |
| `EVENT_ORDERING` | Token fields and release toggle launch together; a same-edge reset captures that release phase and launches its transport request. Normal use follows the release toggle, while reset accounting follows the transport request. | AXI final-beat/reset assignments and both source decoders. |
| `SYNCHRONIZER_STRUCTURE` | Release toggle and transport-reset request each cross two `ASYNC_REG` stages before their respective uses. | RTL declarations and synchronizer assignments. |
| `COMPLETION_BARRIER` | Reset acknowledgement must wait until the captured release phase is retired. | `transport_retire_pending_source` protocol. |
| `TOKEN_IDENTITY` | Both generation and epoch must match: generation prevents same-epoch slot-reuse alias, while descriptor/current-reset epoch prevents old-lifetime alias. | Generation, descriptor-epoch, and reset-epoch comparisons plus fail-closed mismatch path. |

## Numeric bound authority

The candidate uses `6.000 ns`, exactly the active governed aggregate AXI-to-source mailbox bound in `xdc/common/g2b_cdc.xdc` lines 30-34. It is not derived from a guessed fraction of a clock or introduced by this audit.

The routed source-domain period is `6.734 ns`. Two complete destination periods give a gross earliest-use window of `13.468 ns`; the governed `6.000 ns` cap therefore retains `7.468 ns` gross protocol margin before considering the structural stability guarantee. The timing checks prove the physical cap; the RTL review proves the assumptions that make that cap meaningful.

## Coverage conclusion

The current 3 ns bus-skew check can report a relative arrival spread while failing to prove that any path settles before consumption. It also compares irrelevant destinations and omits reset-accounting endpoints. Three exact semantic-family max-delay checks plus the structural CDC/protocol proof cover the actual invariant and remove those false-confidence modes.

`REPLACEMENT_EQUIVALENCE = SAFER_AND_MORE_SEMANTICALLY_CORRECT`
