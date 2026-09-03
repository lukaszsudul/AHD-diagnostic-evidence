# META-6 Group-14 Sign-Off Promotion

## Evidence-qualified disposition

| Field | Accepted value |
|---|---|
| Group | `14` |
| Name | `RELEASE_SLOT_0_AXI_TO_SOURCE` |
| Original sign-off | `GLOBAL_SET_BUS_SKEW_3NS` |
| Original constraint | `set_bus_skew 3.000 -from $g2b_release0_payload_src -to $g2b_release_payload_dst` |
| Original source/destination count | `56 / 20` |
| Previous timeout | `VERIFIED` (`301.299 s`) |
| Full `report_bus_skew` retried | `NO` |
| `report_timing` | `PASS`; `0.184 s`; worst datapath `5.554 ns`; slack `0.478 ns` |
| `get_timing_paths` | `PASS`; `77.190 s`; 49 paths returned under max 64; 7 destination endpoints |
| Path-set comparability | `INVALID_FOR_SKEW_COMPARISON` |
| Semantic classification | `56-bit generation/epoch stable-data release token; normal use follows a two-stage release-toggle synchronizer; reset accounting follows a two-stage transport-request synchronizer and captured release-phase retirement` |
| Promoted sign-off | `SETTLING_PLUS_STRUCTURAL_CDC` |
| Replacement equivalence | `SAFER_AND_MORE_SEMANTICALLY_CORRECT` |
| Group-14 CDC structure | `PASS_WITH_DISPOSITION` |
| Sign-off runtime | `PRACTICAL` |
| RTL change required | `NO` |

## Exact semantic families

| Family | Physical scope | Required settling and proof | Routed validation | Structural/use meaning |
|---|---|---|---|---|
| `RELEASE_SLOT0_NORMAL_STATE_TRANSITION` | 56 held token sources to 3 slot-0 state destination bits | `6.000 ns` absolute datapath-only; `ABSOLUTE_SETTLING + STABLE_DATA_UNTIL_QUALIFIED_USE + RELEASE_TOGGLE_EVENT_ORDERING + TWO_STAGE_RELEASE_TOGGLE_SYNCHRONIZER + TOKEN_IDENTITY` | worst actual `5.467 ns`; slack `0.563 ns`; runtime `63.236 s`; `PASS` | Matching slot-0 token authorizes `DMA_OWNED` to `RELEASABLE` |
| `RELEASE_SLOT0_MISMATCH_CONTAINMENT` | 56 held token sources to 4 ownership-fatal/admission destination registers | `6.000 ns` absolute datapath-only; `ABSOLUTE_SETTLING + STABLE_DATA_UNTIL_QUALIFIED_USE + RELEASE_TOGGLE_EVENT_ORDERING + TWO_STAGE_RELEASE_TOGGLE_SYNCHRONIZER + FAIL_CLOSED_GENERATION_EPOCH_IDENTITY` | worst actual `5.554 ns`; slack `0.478 ns`; runtime `0.117 s`; `PASS` | Mismatched generation, epoch, reset epoch, or ownership state fails closed |
| `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING` | 56 held token sources to 3 reset-abandoned accounting destination bits | `6.000 ns` absolute datapath-only; `ABSOLUTE_SETTLING + STABLE_DATA_UNTIL_QUALIFIED_USE + TRANSPORT_REQUEST_EVENT_ORDERING + TWO_STAGE_TRANSPORT_REQUEST_SYNCHRONIZER + COMPLETION_BARRIER + TOKEN_IDENTITY` | worst actual `4.191 ns`; slack `1.839 ns`; runtime `0.111 s`; `PASS` | Synchronized transport request uses the same-episode token for reset abandonment accounting before captured-phase retirement |

Exactly three semantic families are governed. The candidate contains exactly
three `set_max_delay -datapath_only 6.000` commands and no other applied
numerical limit. The `6.000 ns` value is the existing governed aggregate
AXI-to-source mailbox bound, not an invented value or a value copied from
another sign-off group. The routed destination-domain period is `6.734 ns`;
two complete destination periods supply a `13.468 ns` gross earliest-use window
and retain `7.468 ns` gross protocol margin at the governed cap.

## Structural CDC obligations

The required safety invariant is the inseparable conjunction of:

1. `ABSOLUTE_SETTLING`: every payload-dependent path reaches its same-edge
   semantic endpoint before the relevant synchronized qualifier can authorize
   evaluation.
2. `STABLE_DATA_UNTIL_EVENT_CONSUMPTION`: the 24-bit generation and 32-bit
   epoch token cannot change while the relevant event crosses and is consumed;
   another token cannot launch until slot refill, commit, AXI ownership, and a
   complete 512-beat stream have occurred.
3. `EVENT_ORDERING`: token fields and release toggle launch together on the
   accepted final stream beat; a same-edge reset captures that release phase
   and launches its transport request. Normal use follows the release toggle;
   reset accounting follows the transport request.
4. `SYNCHRONIZER_STRUCTURE`: `release_toggle_axi[0]` crosses
   `release_sync1_source[0]` and `release_sync2_source[0]`; the reset qualifier
   crosses `transport_req_sync1_source` and `transport_req_sync2_source`. Each
   chain has two destination-domain `ASYNC_REG` stages before its use.
5. `COMPLETION_BARRIER`: during reset, ordinary release decoding is suppressed;
   transport acknowledgement waits until the independently synchronized
   release vector equals the captured phase and the release phase is retired.
6. `TOKEN_IDENTITY`: normal use requires release generation equal to slot
   generation, release epoch equal to descriptor epoch and current reset epoch,
   and slot state `DMA_OWNED`. Generation prevents same-epoch reuse alias;
   epoch prevents old-lifetime alias. Any mismatch latches ownership-fatal
   containment and disables admission.

`release_seen_source[0]` is consumed/reset-retired event history, not a payload
capture register. Reset-overlap accounting is triggered by the synchronized
transport request, uses generation and epoch for `release_matches`, computes
the abandoned-record value, forces slots writable, and preserves
destination-use and reset/release coherency through captured-phase retirement.
Timing alone is not sufficient; structural proof alone is not sufficient.

## Implementation boundary

- Active production XDC change: `AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`.
- Candidate authority: `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` at
  `9e91315968453e859006077191cd5fc711fc6b96`.
- Candidate SHA-256:
  `094F7182116FC2A2C68479B8BDB6A6C2327F14DA6ABFEB244EC7F26D7BE2809A`.
- Group 9: `PRESERVE_PASS`; do not repeat.
- Groups 10–12: `PRESERVE_PASS`; do not repeat.
- Group 13: `PRESERVE_PASS`; do not repeat.
- Groups 15–17: `PENDING_UNCHANGED`.
- Next allowed step: `G2B-LUT1-SIGNOFF-RECOVERY-3`.
- Bitstream: only after all remaining hard gates pass; not part of META-6.
