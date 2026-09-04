# Groups 15-17 current constraints

## Authority

The active file is `C:\FPGA\V41_G2B\xdc\common\g2b_cdc.xdc` at source commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`. Its SHA-256 is `49CE028909F25303807E85E8835BD3379F1C6965EC302E08812105C280736C4A`. The build includes this file. No competing Groups 15-17 definition was found.

The shared destination collection at line 117 is exactly:

```tcl
set g2b_release_payload_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(slot_state_source|release_seen_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] {IS_SEQUENTIAL == 1}]
```

## Group 15 — RELEASE_SLOT_1_AXI_TO_SOURCE

Active XDC lines 180-183:

```tcl
set g2b_release1_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[1\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release1_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[1\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release1_payload_src "$g2b_release1_generation_src $g2b_release1_epoch_src"
set_bus_skew 3.000 -from $g2b_release1_payload_src -to $g2b_release_payload_dst
```

- Required value: 3.000 ns relative bus skew.
- Resolved sources: 24 generation + 32 epoch = 56 sequential objects.
- Resolved destinations: 20 sequential objects.
- Clock relation: `userclk1` to `nvp_vclk1`.

## Group 16 — RELEASE_SLOT_2_AXI_TO_SOURCE

Active XDC lines 184-187:

```tcl
set g2b_release2_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[2\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release2_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[2\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release2_payload_src "$g2b_release2_generation_src $g2b_release2_epoch_src"
set_bus_skew 3.000 -from $g2b_release2_payload_src -to $g2b_release_payload_dst
```

- Required value: 3.000 ns relative bus skew.
- Resolved sources: 24 generation + 32 epoch = 56 sequential objects.
- Resolved destinations: 20 sequential objects.
- Clock relation: `userclk1` to `nvp_vclk1`.

## Group 17 — RELEASE_SLOT_3_AXI_TO_SOURCE

Active XDC lines 188-191:

```tcl
set g2b_release3_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[3\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release3_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[3\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release3_payload_src "$g2b_release3_generation_src $g2b_release3_epoch_src"
set_bus_skew 3.000 -from $g2b_release3_payload_src -to $g2b_release_payload_dst
```

- Required value: 3.000 ns relative bus skew.
- Resolved sources: 24 generation + 32 epoch = 56 sequential objects.
- Resolved destinations: 20 sequential objects.
- Clock relation: `userclk1` to `nvp_vclk1`.

## Engineering intent and comparability

The original engineering intent was to keep the generation/epoch stable-data release token coherent while it crossed from AXI to the source domain and was consumed after a synchronized release event. The global destination expression does not model that intent accurately. For each slot it combines 3 relevant state registers, 4 relevant shared fault/admission registers, 4 release-history registers, and 9 state registers belonging to other slots. It omits the 3 real reset-overlap accounting registers.

The independently bounded path samples returned the same heterogeneous role partition for every group: 21 rows to the three normal-state endpoints and 28 rows to the four mismatch endpoints, with no reset-accounting endpoint. Clock-domain equality does not turn those reconvergent, differently qualified roles into a coherent destination capture bus.

Therefore:

- `GROUP15_PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`
- `GROUP16_PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`
- `GROUP17_PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`

No global Groups 15-17 `report_bus_skew` command was executed.
