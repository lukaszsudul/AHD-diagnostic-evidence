# AHD v41 G2B-G14-A temporary analysis candidate for Group 14 only.
#
# This candidate replaces only the Group-14 relation:
#   set_bus_skew 3.000 -from $g2b_release0_payload_src \
#                         -to $g2b_release_payload_dst
#
# Slot-0 release generation and epoch are stable-data qualifier fields launched
# on the same AXI edge as release_toggle_axi[0].  The toggle crosses two
# ASYNC_REG stages before source-domain semantic use.  The existing aggregate
# AXI-to-source mailbox constraint already establishes 6.000 ns as the governed
# absolute datapath settling cap.  The exact semantic-use families below retain
# that bound without comparing reconvergent control paths by relative skew.

current_instance -quiet

set g2b_g14a_release_generation_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_generation_axi_reg\[0\].*}] \
    {IS_SEQUENTIAL == 1}]

set g2b_g14a_release_epoch_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/release_epoch_axi_reg\[0\].*}] \
    {IS_SEQUENTIAL == 1}]

set g2b_g14a_release_payload_src \
    "$g2b_g14a_release_generation_src $g2b_g14a_release_epoch_src"

# Normal release: the matching slot-0 token permits only the DMA_OWNED to
# RELEASABLE state transition.
set g2b_g14a_release_state_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/slot_state_source_reg\[0\].*}] \
    {IS_SEQUENTIAL == 1}]

# Mismatched generation/epoch/state is contained by the ownership-fatal event
# channel and by disabling admission.
set g2b_g14a_release_fault_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] \
    {IS_SEQUENTIAL == 1}]

# A release coincident with a transport reset participates in the abandoned
# record count before the reset completion barrier retires the captured phase.
# This real payload use was outside the old Group-14 destination collection but
# is inside the retained aggregate 6.000 ns mailbox constraint.
set g2b_g14a_release_reset_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}] \
    {IS_SEQUENTIAL == 1}]

set_max_delay -datapath_only 6.000 \
    -from $g2b_g14a_release_payload_src \
    -to $g2b_g14a_release_state_dst_cells

set_max_delay -datapath_only 6.000 \
    -from $g2b_g14a_release_payload_src \
    -to $g2b_g14a_release_fault_dst_cells

set_max_delay -datapath_only 6.000 \
    -from $g2b_g14a_release_payload_src \
    -to $g2b_g14a_release_reset_dst_cells
