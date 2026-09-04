# AHD v41 G2B-G15-17-EQ temporary combined analysis candidate.
# Replaces only Groups 15, 16, and 17 after structural/semantic equivalence
# checks in the bounded audit harness have passed. Group 14 remains unchanged.
# Each 56-bit stable release token is constrained to its three real semantic-use
# families with the governed 6.000 ns absolute settling cap.

current_instance -quiet

set g2b_g15eq_release_generation_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_generation_axi_reg\[1\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g15eq_release_epoch_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_epoch_axi_reg\[1\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g15eq_release_payload_src \
    "$g2b_g15eq_release_generation_src $g2b_g15eq_release_epoch_src"
set g2b_g15eq_release_state_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/slot_state_source_reg\[1\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g15eq_release_fault_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g15eq_release_reset_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] \
    {IS_SEQUENTIAL == 1}]

set_max_delay -datapath_only 6.000 -from $g2b_g15eq_release_payload_src -to $g2b_g15eq_release_state_dst_cells
set_max_delay -datapath_only 6.000 -from $g2b_g15eq_release_payload_src -to $g2b_g15eq_release_fault_dst_cells
set_max_delay -datapath_only 6.000 -from $g2b_g15eq_release_payload_src -to $g2b_g15eq_release_reset_dst_cells

set g2b_g16eq_release_generation_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_generation_axi_reg\[2\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g16eq_release_epoch_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_epoch_axi_reg\[2\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g16eq_release_payload_src \
    "$g2b_g16eq_release_generation_src $g2b_g16eq_release_epoch_src"
set g2b_g16eq_release_state_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/slot_state_source_reg\[2\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g16eq_release_fault_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g16eq_release_reset_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] \
    {IS_SEQUENTIAL == 1}]

set_max_delay -datapath_only 6.000 -from $g2b_g16eq_release_payload_src -to $g2b_g16eq_release_state_dst_cells
set_max_delay -datapath_only 6.000 -from $g2b_g16eq_release_payload_src -to $g2b_g16eq_release_fault_dst_cells
set_max_delay -datapath_only 6.000 -from $g2b_g16eq_release_payload_src -to $g2b_g16eq_release_reset_dst_cells

set g2b_g17eq_release_generation_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_generation_axi_reg\[3\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g17eq_release_epoch_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_epoch_axi_reg\[3\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g17eq_release_payload_src \
    "$g2b_g17eq_release_generation_src $g2b_g17eq_release_epoch_src"
set g2b_g17eq_release_state_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/slot_state_source_reg\[3\].*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g17eq_release_fault_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_g17eq_release_reset_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] \
    {IS_SEQUENTIAL == 1}]

set_max_delay -datapath_only 6.000 -from $g2b_g17eq_release_payload_src -to $g2b_g17eq_release_state_dst_cells
set_max_delay -datapath_only 6.000 -from $g2b_g17eq_release_payload_src -to $g2b_g17eq_release_fault_dst_cells
set_max_delay -datapath_only 6.000 -from $g2b_g17eq_release_payload_src -to $g2b_g17eq_release_reset_dst_cells
