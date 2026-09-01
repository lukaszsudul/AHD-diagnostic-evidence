# AHD v41 G2B-BS3 candidate replacement for Group 9 only.
#
# Promotion model: replace the single production
#   set_bus_skew 3.000 -from $g2b_ownership_payload_src \
#                         -to $g2b_ownership_payload_dst
# statement with this stanza. All unrelated constraints, including the
# existing aggregate 6.000 ns AXI-to-source mailbox max-delay cap, remain
# unchanged.
#
# OWNERSHIP_AXI_TO_SOURCE is a bundled stable-data mailbox. The three payload
# fields launch with own_req_toggle_axi and remain fixed until after the
# returned acknowledgement. Two source-clock synchronizer stages plus
# registered request detection provide an earliest semantic-use window of
# two nvp_vclk1 periods (2 * 6.734 ns = 13.468 ns). These checks require every
# payload-dependent destination cone to settle within 6.000 ns, leaving
# 7.468 ns before the earliest semantic use. Relative arrival spread is not
# the correctness property, so this candidate intentionally has no ownership
# set_bus_skew command.

set g2b_bs3_ownership_slot_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(own_slot_hold_axi|axis_slot)_reg.*}] \
    {IS_SEQUENTIAL == 1}]

set g2b_bs3_ownership_generation_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(own_generation_hold_axi|axis_generation)_reg.*}] \
    {IS_SEQUENTIAL == 1}]

set g2b_bs3_ownership_epoch_src [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(own_epoch_hold_axi|axis_epoch)_reg.*}] \
    {IS_SEQUENTIAL == 1}]

# Only registers whose next-state cones semantically depend on the ownership
# payload are included. own_req_seen_source and own_ack_toggle_source are
# request-token bookkeeping driven by own_req_sync2_source, not payload sinks.
set g2b_bs3_ownership_payload_dst_cells [filter \
    [get_cells -quiet -hier -regexp \
      {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_ok_hold_source)_reg.*}] \
    {IS_SEQUENTIAL == 1}]
set g2b_bs3_ownership_payload_dst_d [get_pins -quiet \
    -of_objects $g2b_bs3_ownership_payload_dst_cells \
    -filter {REF_PIN_NAME == D}]

# The mandatory sign-off recipe checks these collections and fails closed
# unless the implementation resolves exactly 2 + 24 + 32 source registers
# and 17 payload-dependent destination registers/D pins. Vivado XDC files do
# not support procedural `if`; the executable object-count assertions belong
# in the bounded sign-off Tcl harness, not in this declarative constraint file.

set_max_delay -datapath_only 6.000 \
    -from $g2b_bs3_ownership_slot_src \
    -to $g2b_bs3_ownership_payload_dst_d
set_max_delay -datapath_only 6.000 \
    -from $g2b_bs3_ownership_generation_src \
    -to $g2b_bs3_ownership_payload_dst_d
set_max_delay -datapath_only 6.000 \
    -from $g2b_bs3_ownership_epoch_src \
    -to $g2b_bs3_ownership_payload_dst_d
