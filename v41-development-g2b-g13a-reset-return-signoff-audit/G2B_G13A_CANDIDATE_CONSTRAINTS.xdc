# AHD v41 G2B-G13-A candidate replacement for Group 13 only.
# The original global 3 ns relative-skew relation is intentionally absent.
# Both semantic families receive a 6 ns absolute datapath settling bound.

current_instance -quiet

set g2b_g13a_abandoned_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_g13a_commit_phase_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/reset_commit_phase_hold_source_reg.*}] {IS_SEQUENTIAL == 1}]

set g2b_g13a_abandoned_dst_cells [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/records_abandoned_axi_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_g13a_all_dst_cells [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(records_abandoned_axi|commit_seen_axi|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|axis_state|snapshot_busy_axi|snapshot_valid_axi|fatal_clear_qualified_axi|axi_hard_episode)_reg.*}] {IS_SEQUENTIAL == 1}]

set g2b_g13a_abandoned_dst_d [get_pins -quiet -of_objects $g2b_g13a_abandoned_dst_cells -filter {REF_PIN_NAME == D}]
set g2b_g13a_all_dst_d [get_pins -quiet -of_objects $g2b_g13a_all_dst_cells -filter {REF_PIN_NAME == D}]

set_max_delay -datapath_only -from $g2b_g13a_abandoned_src -to $g2b_g13a_abandoned_dst_cells 6.000
set_max_delay -datapath_only -from $g2b_g13a_commit_phase_src -to $g2b_g13a_all_dst_cells 6.000
