# G2B-G14-A current Group-14 constraint

## Authority

- Source checkout: `C:\FPGA\V41_G2B`
- Branch: `integration/v41-g2b-onech-c2h`
- Commit: `64feb60de5d07f400e6b92527bfe54838b3372ee`
- Tree: `26399ed456941e26d5ee4b1b2ca50392338fa24a`
- File: `xdc/common/g2b_cdc.xdc`, lines 117-121
- File SHA-256: `C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C`

The governed Group-13 replacement is present at lines 163-179 of the same file. No source or active XDC was changed for this audit.

## Exact XDC expression

```tcl
set g2b_release_payload_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(slot_state_source|release_seen_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_release0_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[0\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release0_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[0\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release0_payload_src "$g2b_release0_generation_src $g2b_release0_epoch_src"
set_bus_skew 3.000 -from $g2b_release0_payload_src -to $g2b_release_payload_dst
```

Required relative skew: `3.000 ns`.

## Routed resolution

The exact routed resolution was recovered from the recovery-2 object receipt and independently asserted in the bounded worker:

- Source collection: `$g2b_release0_payload_src`
- Source count: `56`
- Source clock: `userclk1`, period `16.000 ns`
- Generation objects: `G2B_ONECH_C2H/release_generation_axi_reg[0][0]` through `[0][23]` (`24` cells)
- Epoch objects: `G2B_ONECH_C2H/release_epoch_axi_reg[0][0]` through `[0][31]` (`32` cells)
- Destination collection: `$g2b_release_payload_dst`
- Destination count: `20`
- Destination clock: `nvp_vclk1`, period `6.734 ns`

The 20 exact destination cells are:

1. `G2B_ONECH_C2H/enable_applied_source_reg`
2. `G2B_ONECH_C2H/release_seen_source_reg[0]`
3. `G2B_ONECH_C2H/release_seen_source_reg[1]`
4. `G2B_ONECH_C2H/release_seen_source_reg[2]`
5. `G2B_ONECH_C2H/release_seen_source_reg[3]`
6. `G2B_ONECH_C2H/slot_state_source_reg[0][0]`
7. `G2B_ONECH_C2H/slot_state_source_reg[0][1]`
8. `G2B_ONECH_C2H/slot_state_source_reg[0][2]`
9. `G2B_ONECH_C2H/slot_state_source_reg[1][0]`
10. `G2B_ONECH_C2H/slot_state_source_reg[1][1]`
11. `G2B_ONECH_C2H/slot_state_source_reg[1][2]`
12. `G2B_ONECH_C2H/slot_state_source_reg[2][0]`
13. `G2B_ONECH_C2H/slot_state_source_reg[2][1]`
14. `G2B_ONECH_C2H/slot_state_source_reg[2][2]`
15. `G2B_ONECH_C2H/slot_state_source_reg[3][0]`
16. `G2B_ONECH_C2H/slot_state_source_reg[3][1]`
17. `G2B_ONECH_C2H/slot_state_source_reg[3][2]`
18. `G2B_ONECH_C2H/source_ownership_fatal_deferred_reg`
19. `G2B_ONECH_C2H/source_ownership_fatal_event_reg`
20. `G2B_ONECH_C2H/source_ownership_fatal_reg`

`raw/timing/G2B_G14A_OBJECT_INVENTORY.csv` is the complete one-row-per-object authority. The older `56/8` inventory under `G2B_LUT1_AUDIT_TOOLS` is stale and was not used.

## Engineering intent recovered from behavior

The 56 source bits are one slot-0 release token: a 24-bit generation plus a 32-bit reset epoch. They are launched on the same AXI edge as a release toggle. Ordinary release and mismatch handling are qualified by that synchronized toggle; when the final release overlaps transport reset, reset accounting is qualified by the separately synchronized transport request and retirement waits for the captured release phase. The intended protection is that the token settles and remains associated with the qualifying control before the source domain uses it. This is a stable-data event-qualified mailbox requirement, not a requirement that the delays of unrelated reconvergent control endpoints remain within 3 ns of one another.

The active XDC already establishes a governed `6.000 ns` absolute `set_max_delay -datapath_only` from the aggregate AXI mailbox source collection, including these release fields, to the aggregate source mailbox destination collection. That existing bound is the numeric authority used by the candidate; it was not invented by this audit.

## Structural comparability

`PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`

The source fields are coherent, but the destination collection is not a coherent capture bundle. It mixes toggle-history registers, all four slots' state registers, and fault/admission registers. Only seven old-scope endpoints are direct slot-0 payload consumers, while three real reset-accounting consumers are absent. The real paths reconverge through comparators and control logic with different roles, logic depths, fanout, and endpoint pins. A global relative skew over this Cartesian scope does not express the release-token safety property.

| Comparability factor | Observed Group-14 result |
|---|---|
| Source clocks | One clock, `userclk1`; homogeneous by clock only. |
| Destination clocks | One clock, `nvp_vclk1`; homogeneous by clock only. |
| Endpoint roles | Heterogeneous: toggle history, four slots' state, ownership-fault state, and admission state. |
| Synchronizer stages | Payload has no per-bit synchronizer; ordinary and reset qualifiers each have separate two-stage ASYNC_REG chains. |
| Logic depth | Real family worst paths differ: 8 levels for normal/fault and 6 for reset accounting. |
| Fanout | Worst-path `MAX_FANOUT` differs: 4 for normal/fault and 3 for reset accounting. |
| Reconvergence | Yes; generation/epoch equality and state/epoch controls reconverge before different register controls/data pins. |
| Semantic equivalence | Absent across the old 20 destinations; 13 are not direct slot-0 payload-use endpoints. |
| Path exceptions | The real returned paths carry the existing `MaxDelay Path 6.000ns -datapath_only`; skew is not reported as a path property. |
