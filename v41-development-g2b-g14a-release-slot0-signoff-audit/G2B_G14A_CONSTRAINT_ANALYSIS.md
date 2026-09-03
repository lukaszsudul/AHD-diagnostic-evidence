# G2B-G14-A constraint analysis

## Decision

The current Group-14 path set is not a legitimate homogeneous bus-skew comparison set. The payload is coherent, but it is consumed as stable data through reconvergent equality/control logic, and the active destination collection mixes unrelated slot state and toggle-history endpoints while omitting reset-overlap accounting. The correct disposition is:

`GROUP14_FINAL_DISPOSITION = REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`

The temporary candidate replaces only Group 14 with three `set_max_delay -datapath_only 6.000` checks over the real endpoint-role families. The numeric cap is inherited from the already-governed aggregate AXI-to-source mailbox constraint. Structural proof supplies stability, event ordering, synchronizer, epoch, and completion-barrier guarantees.

## Candidate evaluation

| Candidate | Exact property proven | Property not proven | Equivalence to actual intent | Expected runtime | False-confidence risk | RTL impact | XDC impact |
|---|---|---|---|---|---|---|---|
| KEEP_CURRENT_BUS_SKEW | Relative spread no greater than 3 ns over tool-resolved paths | Absolute settling, payload stability, event order, reset-accounting closure | Not equivalent | PATHOLOGICAL; prior query exceeded 300 s | High: irrelevant endpoints and missing real sinks | None | None |
| KEEP_NARROW_BUS_SKEW | Relative spread over a smaller chosen endpoint set | No coherent destination data bundle exists; absolute deadline and protocol still unproven | Not equivalent | Unqualified and potentially pathological | High: a faster skew number would still prove the wrong invariant | None | Group-14 scope rewrite |
| PER_FAMILY_SETTLING | Absolute 6 ns physical settling at the three real endpoint-role families | Structural stability, event order, reset retirement | Necessary but incomplete alone | PRACTICAL | Medium if used without protocol proof | None | Three Group-14 max-delay checks |
| SETTLING_PLUS_STRUCTURAL_CDC | Absolute settling plus stable-data lifecycle, two-stage qualifier synchronization, ordering, generation/epoch token identity, and reset barrier | Does not prove arbitrary behavior outside the reviewed protocol | SAFER_AND_MORE_SEMANTICALLY_CORRECT | PRACTICAL | Low | None | Replace Group 14 only after META approval |
| STRUCTURAL_CDC_ONLY | Synchronizer and protocol topology | Routed physical settling before consumption | Weaker than intent | PRACTICAL | High: structure alone has no path-delay bound | None | Remove Group-14 timing check |
| MAX_DELAY_PLUS_STRUCTURAL_CDC | Same exact implementation property as selected settling-plus-structural strategy | No additional property beyond selected strategy | SAFER_AND_MORE_SEMANTICALLY_CORRECT | PRACTICAL | Low | None | Three Group-14 datapath-only max delays |
| REDESIGN_CDC | Could create explicit captured data and request/ack semantics | Unnecessary unless current structural invariant fails | Not required by evidence | High implementation/reverification cost | Low after redesign, but disproportionate | Major | Subsequent XDC redesign |

## Candidate scope

`G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` is temporary evidence. It:

- selects the exact 24 generation and 32 epoch source cells for slot 0;
- selects three slot-0 state destination cells;
- selects four mismatch-containment destination cells;
- selects three reset-overlap accounting destination cells;
- applies the governed `6.000 ns` datapath-only max delay to each family; and
- does not alter clocks, Groups 9-13, Groups 15-17, or unrelated exceptions.

The reset-overlap family is a real Group-14 payload use missing from the old destination collection. Adding it is safety closure, not scope expansion into unrelated behavior.

The published candidate SHA-256 is `094F7182116FC2A2C68479B8BDB6A6C2327F14DA6ABFEB244EC7F26D7BE2809A`, exactly the bytes identity-checked and applied by the worker. Its introductory comment describes the ordinary release-toggle path in shorthand; the authoritative CDC proof distinguishes the separate transport-request qualifier for reset accounting. The Tcl selectors and constraints implement all three families exactly as validated.

## Validation and equivalence

All three candidate timing families pass. The worst measured datapath is `5.554 ns` with `0.478 ns` slack. The structural proof confirms that data remains stable, the event uses two ASYNC_REG stages, invalid tokens fail closed, and reset acknowledgement retires the captured release phase.

`REPLACEMENT_EQUIVALENCE = SAFER_AND_MORE_SEMANTICALLY_CORRECT`

`RTL_CHANGE_REQUIRED = NO`

`CANDIDATE_XDC_READY_FOR_META = YES_WITH_OWNER_ARCHITECT_REVIEW`

Owner/architect review is required because only a future governed META action may promote the temporary XDC and update the SSOT. This audit modified neither.
