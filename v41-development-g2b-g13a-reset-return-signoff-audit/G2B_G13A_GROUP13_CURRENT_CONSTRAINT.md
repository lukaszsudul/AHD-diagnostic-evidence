# AHD v41 G2B-G13-A — Current Group-13 Constraint

## Authority

| Item | Verified value |
|---|---|
| Governed source worktree | `C:/FPGA/V41_G2B` |
| Branch | `integration/v41-g2b-onech-c2h` |
| Commit | `66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49` |
| Tree | `1e67e3f1fe06669839fe9ff8573e4d1e0114a889` |
| Active XDC | `xdc/common/g2b_cdc.xdc` |
| Active-XDC SHA-256 | `6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227` |
| XDC lines | 163–165 |

## Exact definition

```tcl
set g2b_reset_return_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(reset_abandoned_hold_source|reset_commit_phase_hold_source)_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_reset_return_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(records_abandoned_axi|commit_seen_axi|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|axis_state|snapshot_busy_axi|snapshot_valid_axi|fatal_clear_qualified_axi|axi_hard_episode)_reg.*}] {IS_SEQUENTIAL == 1}]
set_bus_skew 3.000 -from $g2b_reset_return_src -to $g2b_reset_return_dst
```

The source collection resolves to seven routed sequential cells:

- `reset_abandoned_hold_source_reg[0:2]` — three cells.
- `reset_commit_phase_hold_source_reg[0:3]` — four cells.

The destination collection resolves to 207 routed sequential cells. Its
registered families are `records_abandoned_axi` (32), `commit_seen_axi` (4),
`stream_reset_busy_axi` (1), `stream_reset_is_hard_axi` (1),
`transport_followup_hard_axi` (1), `reset_epoch_axi` (32),
`global_stream_next_axi` (32), `last_global_axi` (32), `last_channel_axi` (32),
`last_global_valid_axi` (1), `reset_events_axi` (32), `axis_state` (3),
`snapshot_busy_axi` (1), `snapshot_valid_axi` (1),
`fatal_clear_qualified_axi` (1), and `axi_hard_episode` (1).
`last_channel_valid_axi` is present in the selector but has no distinct routed
cell in this checkpoint. The exact 7/207 routed names are sealed in the
predecessor object inventory at
`../v41-development-g2b-lut1-signoff-recovery/raw/groups10_17/group_13_RESET_RETURN_SOURCE_TO_AXI/13_RESET_RETURN_SOURCE_TO_AXI_OBJECTS.txt`
(evidence commit `765f5a5d4760f7a685447651dc68179b2fd96846`, SHA-256
`7B2AF4B8422B58B208590FD3AB9A675819FF7DD56DFAB44789984DA2BBB6C380`)
and reproduced by this audit's
`raw/timing/G2B_G13A_OBJECT_INVENTORY.csv`.

## Domains and pre-existing absolute bound

The seven source flops are in `nvp_vclk1` (`source_clk`, period `6.734 ns`).
The destination flops are in `userclk1` (`axi_clk`, period `16.000 ns`). These
are unrelated clock domains.

The active XDC already has a broader, unchanged source-mailbox constraint at
lines 135–148:

```tcl
set_max_delay -datapath_only 6.000 \
  -from $g2b_source_mailbox_src \
  -to $g2b_axi_mailbox_dst
```

Both Group-13 source families and their wider AXI fanout are members of that
absolute-settling relation. The Group-13 `set_bus_skew` is an additional
relative-arrival comparison; it is not the only physical bound.

## Recovered engineering intent

The XDC comments describe source-to-AXI bundled data split at a protocol
capture boundary so unrelated scheduler consumers are not compared. RTL
inspection refines the intent: the reset-return values are stable payloads
published with a returned transport acknowledgement. AXI must not consume a
new abandoned count or commit phase until the acknowledgement and commit-phase
barrier are satisfied. The protected property is therefore settling before a
validity event, not a mutual 3 ns arrival spread across all seven sources and
207 heterogeneous endpoints.

## Historical Group-13 execution

The predecessor resolved the exact 7/207 inventory, started
`report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 -warn_on_violation`,
and terminated it after `301.094 s` from `QUERY_STARTED.marker`. No result row
was produced. This audit accepts that timeout and does not repeat the full
query.
