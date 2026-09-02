# AHD v41 G2B-G13-A — Reset Semantic Proof

## Reset forms

| Reset form | Routed PRODUCT behavior | Relation to Group 13 |
|---|---|---|
| `source_reset` | Synchronously sampled in `SOURCE_DOMAIN`; tied to `1'b0` at the product top | Not an asynchronous release crossing and not a Group-13 source |
| `standalone_transport_reset` | Converted to an acknowledged toggle in RTL; tied to `1'b0` at the product top | Protocol form exists but is inactive in this routed product instance |
| Host stream reset | AXI creates a new transport epoch and toggles the request | Primary non-hard Group-13 transaction |
| `axi_aresetn` hard episode | Sampled in the `posedge axi_clk` process; after a prior high episode it starts a hard transport request | Creates the hard-reset transaction; Group 13 returns source retirement state |

There is no asynchronous reset sensitivity in `SOURCE_DOMAIN` or `AXI_DOMAIN`.
Group 13 therefore is not an asynchronous-assert/synchronous-release reset
synchronizer. Reset assertion and deassertion are observed synchronously by
the two processes; cross-domain coordination is performed by request/ack
toggles.

## Capture and stability

The only procedural assignments to `reset_abandoned_hold_source` and
`reset_commit_phase_hold_source` occur in the block that detects a new
`transport_req_sync2_source` phase (`rtl/g2b/v41_g2b_onech_c2h.sv`, lines
614–708; assignments at 634 and 636). Initial values are declarations. No
ordinary source processing writes either hold register.

On that edge, source:

- counts abandoned and filling slots;
- forces each slot writable and clears generation;
- captures the abandoned count and current four-bit commit-toggle phase;
- records the request phase;
- returns the acknowledgement immediately only if release and ownership
  retirement phases already match, otherwise after that barrier matches.

The payload cannot be overwritten until a later request phase. AXI does not
issue a normal later request while `stream_reset_busy_axi` is active. The hard
follow-up case deliberately issues a new request only after observing the
first acknowledgement; AXI follows the second transaction and does not
complete on the first payload.

## Deassertion and qualified completion

The returned acknowledgement crosses through
`transport_ack_sync1_axi/transport_ack_sync2_axi`, both `ASYNC_REG=TRUE`.
Completion requires all of:

```systemverilog
stream_reset_busy_axi &&
transport_ack_sync2_axi == transport_req_toggle_axi &&
commit_sync2_axi == reset_commit_phase_hold_source &&
hard_episode_qualification
```

Only then does AXI publish the new reset epoch, account the abandoned count,
clear stream/snapshot state, and copy the returned commit phase into
`commit_seen_axi`.

## Epoch/versioning and mixed-state analysis

AXI increments and holds `transport_epoch_hold_axi` before toggling the
request. Source installs that epoch as `reset_epoch_source` while capturing the
return payload. AXI installs it as `reset_epoch_axi` only on the matching
completion edge. The request/ack phase is the transaction version token.

A transient mixture of newly changing binary payload bits is physically
possible immediately after source capture because the payload is stable-data,
not bitwise synchronized. It is not semantically observable: the validity
token has not yet traversed its two stages, and the `6.000 ns` settling bound is
shorter than the earliest use window. For the commit phase, the independent
two-stage `commit_sync` vector and equality barrier additionally prevent
completion until source and AXI phases agree.

`RESET_MIXED_OLD_NEW_STATE_AT_QUALIFIED_USE = PREVENTED`

`RESET_RETURN_STABILITY = PROVEN_BY_SINGLE_CAPTURE_PLUS_ACK_PROTOCOL`

## Commit-phase false-equality exclusion

The completion equality cannot be satisfied by an unseen same-slot parity
alias. `commit_toggle_source` changes only in `SRC_COMMIT` (RTL line 1032).
The transport-request branch (lines 614–730) is exclusive of the ordinary
parser/source-state case and disables new admission at line 647. A slot cannot
toggle twice without AXI first observing/owning/releasing its committed record;
while reset is busy, AXI suppresses commit enqueue and scheduler progress
(lines 1407–1422 and 1713–1743).

Consequently, an actually changed held commit-phase bit cannot undergo a hidden
`0→1→0` or `1→0→1` cycle between capture and qualification. By returned-ack
qualification the held vector is also physically settled. A stale or mixed
`commit_sync2_axi` therefore cannot equal the final held bit for any actually
changed slot until that bit has arrived through its synchronizer. The equality
barrier is a valid completion predicate for this protocol, not a general claim
that arbitrary independently synchronized binary vectors are coherent.

## Functional corroboration

The current core and directed testbench hashes match the qualified receipt at
`C:/FPGA/G2B_LUT1_ONECH_C2H_XSIM_20260831_13/G2B_XSIM_RECEIPT.txt` (1,526
bytes; SHA-256
`9609B4E9CFE643FE63A91C255484189BBAFA165DDF7DD3B34114308AAB1EA38E`).
That receipt records overall `PASS`, `COMMIT_PHASE_RETIREMENT_BARRIER=PASS`,
`TLAST_RESET_SIMULTANEOUS_RELEASE_RETIREMENT=PASS`, and
`SOURCE_RESET_TRANSPORT_REQUEST_COLLISION=PASS`. The directed test forces a
stale synchronized commit phase after acknowledgement, verifies that reset
remains busy until equality, and then verifies correct baseline installation,
no stale commit enqueue, and exactly-once abandoned accounting. This is
corroborative functional evidence; it does not replace the routed settling
check.

`RTL_CHANGE_REQUIRED = NO`. The routed family and supplemental settling checks
passed with positive slack.
