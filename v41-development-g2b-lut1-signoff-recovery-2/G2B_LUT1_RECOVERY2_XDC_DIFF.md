# G2B-LUT1 Recovery 2 XDC Scope Audit

## Disposition

`XDC_SCOPE_AUDIT = PASS`

The proposed source change is limited to the META-5-authorized Group-13
replacement in `xdc/common/g2b_cdc.xdc`. No other tracked source file is
modified.

## Authorities and identities

| Item | Identity |
|---|---|
| Source branch | `integration/v41-g2b-onech-c2h` |
| Source parent / pre-change HEAD | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` |
| Pre-change active XDC SHA-256 | `6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227` |
| META-5 promotion commit | `bbdeb474ce9d7e5f0db3e8ca8afb5448eef8f314` |
| G13-A evidence commit | `10c7c2898d162af8e2262b3f99861c7d560c4557` |
| G13-A candidate Git blob | `415317598b98cfeb8c01df41ab519cc5ee3ad5fa` |
| G13-A candidate SHA-256 | `E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312` |
| Proposed active XDC SHA-256 | `C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C` |

The complete byte sequence of `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc` is an
exact substring of the proposed active XDC.

## Authorized semantic delta

Removed exactly once:

```tcl
set g2b_reset_return_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(reset_abandoned_hold_source|reset_commit_phase_hold_source)_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_reset_return_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(records_abandoned_axi|commit_seen_axi|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|axis_state|snapshot_busy_axi|snapshot_valid_axi|fatal_clear_qualified_axi|axi_hard_episode)_reg.*}] {IS_SEQUENTIAL == 1}]
set_bus_skew 3.000 -from $g2b_reset_return_src -to $g2b_reset_return_dst
```

Inserted byte-for-byte from G13-A:

- family `RESET_ABANDONED_COUNT_STABLE_PAYLOAD`, with its exact selectors and
  `set_max_delay -datapath_only ... 6.000` constraint;
- family `RESET_COMMIT_PHASE_COMPLETION_BARRIER`, with its exact selectors and
  `set_max_delay -datapath_only ... 6.000` constraint;
- no Group-13 `set_bus_skew` command.

The active-XDC census changes from 13 to 12 `set_bus_skew` commands and from
9 to 11 `set_max_delay` commands. The `set_false_path` count remains 1.

## Scope checks

| Required invariant | Result | Evidence |
|---|---|---|
| Group 9 unchanged from META-4 implementation | PASS | Git diff has one hunk beginning at the former Group-13 block; the complete BS3 stanza remains byte-identical to source parent `66cc8e3`. |
| Groups 10-12 unchanged | PASS | Descriptor attempt, generation, and epoch selectors and 3.000 ns constraints are outside and unchanged by the sole hunk. |
| Only Group 13 changed | PASS | Git reports one modified tracked path and a `17 insertions / 3 deletions` Group-13-only hunk. |
| Groups 14-17 unchanged | PASS | All four release-slot selectors and 3.000 ns constraints remain outside and unchanged by the sole hunk. |
| Clocks unchanged | PASS | No clock command or clock-bearing source file is changed. |
| False paths unchanged | PASS | The active-XDC `set_false_path` census remains 1, and its line is outside the sole hunk. |
| Unrelated max-delay unchanged | PASS | The pre-existing broad source-to-AXI aggregate `set_max_delay -datapath_only 6.000 -from $g2b_source_mailbox_src -to $g2b_axi_mailbox_dst` and every other pre-existing max-delay command remain byte-identical. The only two additions are the exact G13-A family constraints. |
| ABI/MMIO unaffected | PASS | No RTL, host tool, ABI, or MMIO file is modified. |
| R1i behavior unaffected | PASS | No RTL, XCI, R-track, NVP, startup, or HDMI file is modified. |

`UNRELATED_XDC_CHANGED = NO`

