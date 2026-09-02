# AHD v41 G2B-G13-A — Focused CDC Correlation

## Evidence scope

This audit correlates governed RTL/netlist structure with the existing routed
CDC report at
`C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_EVIDENCE_20260831_12/CDC.rpt` (324,851
bytes; SHA-256
`FD1962A3353C5F6288989A39453C038709F5C1F41F1D6422D74D9AD28D5F553E`).
The predecessor did not run a fresh general CDC report after its Group-13
blocker, and this audit does not attempt global CDC closure.

## Relevant crossings

| Crossing | Existing CDC evidence | Focused classification | Disposition |
|---|---|---|---|
| `transport_req_toggle_axi` → two source sync stages | `CDC-3`, Info, report item 357, two stages | `HANDSHAKE`, `INTENTIONAL_SYNCHRONIZER` | Required validity request; accepted structure |
| `transport_ack_toggle_source` → two AXI sync stages | `CDC-3`, Info, report item 1020, two stages | `HANDSHAKE`, `INTENTIONAL_SYNCHRONIZER` | Required returned-valid token; accepted structure |
| `commit_toggle_source[3:0]` → `commit_sync1/2_axi` | `CDC-6`, Warning, report item 445, two stages | `INTENTIONAL_SYNCHRONIZER` | Four independent per-slot toggle phases; equality barrier, not a binary/Gray word |
| `reset_abandoned_hold_source[2:0]` → `records_abandoned_axi` | `CDC-15`, Warning, report items beginning 653 | `STABLE_DATA` | Held from request capture through ack; absolute settling required |
| `reset_commit_phase_hold_source[3:0]` → AXI completion cone | `CDC-1` Critical and `CDC-15` Warning, including items 297 and 427 onward | `STABLE_DATA`, `COMBINATIONAL_AGGREGATION` | Tool cannot infer mailbox qualification; ack/equality structural proof plus absolute settling required |

The `CDC-1`/`CDC-15` findings are relevant and are not dismissed as noise.
They correctly identify unsynchronized stable-data fanout and clock-enable
reconvergence. Their safe disposition depends on the protocol facts that the
report cannot infer: single-edge capture, stable hold, synchronized validity,
phase equality, and bounded settling.

A focused endpoint parse of the authoritative CDC report finds abandoned-hold
fanout only in `records_abandoned_axi`. Commit-phase-hold fanout falls either in
the original Group-13 destination families or the supplemental
transport-follow-up/request holds, `commit_fifo_{head,tail,count}`, and
`shadow_last_{global,channel,valid}` categories. No additional
`error_status`/`stored_enable` family appears. The supplemental decomposition
is therefore exhaustive for this focused historical CDC evidence; it is not a
list of examples and is not represented as fresh global CDC closure.

The exact set check is:

- 517 historical CDC rows containing `reset_commit_phase_hold_source` reduce
  to 286 unique destination cells after endpoint-pin roles are stripped;
- the 207 original Group-13 cells plus the 79 supplemental cells form exactly
  those 286 cells (`missing = 0`, `extra = 0`); and
- the abandoned-hold return has exactly 32 historical rows to
  `records_abandoned_axi[0:31]/D`, matching the candidate's 32-cell scope.

The 517 commit-phase rows decompose by endpoint role as `D = 159`, `CE = 263`,
`R = 31`, and `S = 64`. A D-pin-only replacement would omit 358 historically
reported control endpoints. This is why both candidate constraints and all
routed validations target destination cells, allowing every timing endpoint
pin rather than only the D-pin inventory.

Three other CDC rows terminate *into* the abandoned-hold source flops and are
not source-to-AXI return paths. This exact-direction distinction prevents them
from being miscounted as missing family endpoints.

## Reset-specific CDC category

`ASYNC_RESET_SYNC_RELEASE` is not the Group-13 mechanism. Existing `CDC-9`
findings elsewhere in the design concern unrelated reset synchronizers. Group
13 carries reset-transaction results as held data and handshake state.

## Focused conclusion

- Abandoned-count family: `STABLE_DATA`.
- Commit-phase family: `STABLE_DATA` plus `COMBINATIONAL_AGGREGATION`.
- Validity/control: `HANDSHAKE` and `INTENTIONAL_SYNCHRONIZER`.
- Gray CDC: not used by Group 13.
- RTL change: not required if routed settling passes.
- Global CDC closure: outside this audit and still part of later routed hard
  gates.
