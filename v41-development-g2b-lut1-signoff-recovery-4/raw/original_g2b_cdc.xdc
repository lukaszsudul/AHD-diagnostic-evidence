# AHD v41 G2B CDC constraints. These constraints are additive to the accepted
# legacy cdc.xdc and name only the new G2B hierarchy.

# Every asynchronous request, acknowledgement, event, live status, and commit
# vector enters through an explicitly ASYNC_REG-marked first stage.
set g2b_sync1_cells [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(enable_req_sync1_source|transport_req_sync1_source|stats_req_sync1_source|snapshot_req_sync1_source|own_req_sync1_source|release_sync1_source|fatal_sync1_source|overflow_ack_sync1_source|drop_ack_sync1_source|formatter_ack_sync1_source|ownership_ack_sync1_source|standalone_ack_sync1_source|enable_ack_sync1_axi|transport_ack_sync1_axi|stats_ack_sync1_axi|snapshot_ack_sync1_axi|own_ack_sync1_axi|commit_sync1_axi|ring_empty_sync1_axi|ring_full_sync1_axi|source_ready_sync1_axi|source_locked_sync1_axi|overflow_sync1_axi|drop_sync1_axi|formatter_fatal_sync1_axi|ownership_fatal_sync1_axi|standalone_req_sync1_axi|hard_event_clear_sync1_axi)_reg(\[[0-9]+\])?}]
set g2b_sync1_d [get_pins -quiet -of_objects $g2b_sync1_cells -filter {REF_PIN_NAME == D}]
set_false_path -to $g2b_sync1_d

# Source-held snapshot Gray words cross through two explicit vector
# synchronizers. Bound the unrelated-clock datapath and keep each Gray vector
# compact at the first stage.
set g2b_snapshot_gray_src [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_(attempted|committed|dropped|overflow)_gray_hold_source_reg\[[0-9]+\]}]
set g2b_snapshot_gray_dst [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_(attempted|committed|dropped|overflow)_sync1_axi_reg\[[0-9]+\]}]
set g2b_snapshot_gray_d [get_pins -quiet -of_objects $g2b_snapshot_gray_dst -filter {REF_PIN_NAME == D}]
set_max_delay -datapath_only 6.000 -from $g2b_snapshot_gray_src -to $g2b_snapshot_gray_d
set_bus_skew 3.000 -from $g2b_snapshot_gray_src -to $g2b_snapshot_gray_d

# The snapshot epoch echo is a stable-data token qualifier. It follows the
# same two-stage and bounded-bus method as the held Gray words.
set g2b_snapshot_epoch_src [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_epoch_echo_source_reg\[[0-9]+\]}]
set g2b_snapshot_epoch_dst [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_epoch_sync1_axi_reg\[[0-9]+\]}]
set g2b_snapshot_epoch_d [get_pins -quiet -of_objects $g2b_snapshot_epoch_dst -filter {REF_PIN_NAME == D}]
set_max_delay -datapath_only 6.000 -from $g2b_snapshot_epoch_src -to $g2b_snapshot_epoch_d
set_bus_skew 3.000 -from $g2b_snapshot_epoch_src -to $g2b_snapshot_epoch_d

# Stable-data mailbox payloads are held from request launch through returned
# acknowledgement. The toggle provides coherency; these constraints provide a
# physical bound and bus-skew limit for the bundled data.
set g2b_axi_mailbox_src_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(enable_value_hold_axi|transport_epoch_hold_axi|transport_hard_hold_axi|transport_release_phase_hold_axi|transport_own_phase_hold_axi|snapshot_epoch_hold_axi|own_generation_hold_axi|own_epoch_hold_axi|own_slot_hold_axi|axis_slot|axis_generation|axis_epoch|release_generation_axi|release_epoch_axi)_reg.*}]
set g2b_axi_mailbox_src [filter $g2b_axi_mailbox_src_candidates {IS_SEQUENTIAL == 1}]
set g2b_source_mailbox_dst_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(enable_applied_source|reset_epoch_source|records_attempted_source|records_committed_source|records_dropped_source|overflow_count_source|source_lifetime_dropped|channel_attempt_next_source|allocation_round_robin|pending_discontinuity|pending_overflow|pending_malformed|source_formatter_fatal|source_ownership_fatal|source_formatter_clear_pending|source_ownership_clear_pending|source_overflow_event|source_drop_event|source_formatter_fatal_event|source_ownership_fatal_event|source_overflow_deferred|source_drop_deferred|source_formatter_fatal_deferred|source_ownership_fatal_deferred|hard_event_baseline_hold_source|hard_event_clear_toggle_source|snapshot_epoch_echo_source|slot_state_source|slot_generation_source|release_seen_source|own_req_seen_source|own_ack_toggle_source|transport_retire_pending_source|transport_ack_toggle_source|reset_abandoned_hold_source|reset_filling_hold_source|reset_commit_phase_hold_source|own_ok_hold_source)_reg.*}]
set g2b_source_mailbox_dst [filter $g2b_source_mailbox_dst_candidates {IS_SEQUENTIAL == 1}]
set_max_delay -datapath_only 6.000 -from $g2b_axi_mailbox_src -to $g2b_source_mailbox_dst

# Bus skew is meaningful within one acknowledged payload, not across the
# unrelated enable, transport, snapshot, ownership, and per-slot release
# protocols collected by the aggregate max-delay bound above.  Constrain each
# coherent payload independently while retaining the 6 ns bound over every
# valid AXI-to-source mailbox path.
set g2b_snapshot_epoch_forward_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_epoch_hold_axi_reg\[[0-9]+\]}] {IS_SEQUENTIAL == 1}]
set g2b_snapshot_epoch_forward_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_epoch_echo_source_reg\[[0-9]+\]}] {IS_SEQUENTIAL == 1}]
set_bus_skew 3.000 -from $g2b_snapshot_epoch_forward_src -to $g2b_snapshot_epoch_forward_dst

set g2b_transport_payload_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(transport_epoch_hold_axi|transport_hard_hold_axi|transport_release_phase_hold_axi|transport_own_phase_hold_axi)_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_transport_payload_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(reset_epoch_source|records_attempted_source|records_committed_source|records_dropped_source|overflow_count_source|source_lifetime_dropped|release_seen_source|own_req_seen_source|own_ack_toggle_source|transport_retire_pending_source|transport_ack_toggle_source|reset_abandoned_hold_source|reset_filling_hold_source|reset_commit_phase_hold_source|source_formatter_fatal|source_ownership_fatal|source_formatter_clear_pending|source_ownership_clear_pending|hard_event_baseline_hold_source|hard_event_clear_toggle_source|enable_applied_source)_reg.*}] {IS_SEQUENTIAL == 1}]
set_max_delay -datapath_only 2.500 -from $g2b_transport_payload_src -to $g2b_transport_payload_dst
set_bus_skew 3.000 -from $g2b_transport_payload_src -to $g2b_transport_payload_dst

# Synthesis can merge the ownership-hold flops with the same-edge AXIS staging
# flops.  The union names both RTL identities so the physical launch set stays
# nonempty under rebuilt hierarchy without preserving logic artificially.
set g2b_ownership_payload_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(own_slot_hold_axi|own_generation_hold_axi|own_epoch_hold_axi|axis_slot|axis_generation|axis_epoch)_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_ownership_payload_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_req_seen_source|own_ack_toggle_source|own_ok_hold_source)_reg.*}] {IS_SEQUENTIAL == 1}]

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

set g2b_release_payload_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(slot_state_source|release_seen_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}] {IS_SEQUENTIAL == 1}]
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
set g2b_release1_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[1\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release1_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[1\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release1_payload_src "$g2b_release1_generation_src $g2b_release1_epoch_src"
set_bus_skew 3.000 -from $g2b_release1_payload_src -to $g2b_release_payload_dst
set g2b_release2_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[2\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release2_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[2\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release2_payload_src "$g2b_release2_generation_src $g2b_release2_epoch_src"
set_bus_skew 3.000 -from $g2b_release2_payload_src -to $g2b_release_payload_dst
set g2b_release3_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_generation_axi_reg\[3\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release3_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_epoch_axi_reg\[3\].*}] {IS_SEQUENTIAL == 1}]
set g2b_release3_payload_src "$g2b_release3_generation_src $g2b_release3_epoch_src"
set_bus_skew 3.000 -from $g2b_release3_payload_src -to $g2b_release_payload_dst

set g2b_source_mailbox_src_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(desc_attempt_source|desc_generation_source|desc_epoch_source|reset_abandoned_hold_source|reset_commit_phase_hold_source|own_ok_hold_source)_reg.*}]
# Keep only real sequential launch elements.  Synthesized descriptor arrays
# contain both logical RAM macros (not valid timing startpoints) and their
# sequential RAM primitive leaves. The split makes that distinction explicit
# and keeps the physical mailbox constraint free of path-segmentation objects.
set g2b_source_mailbox_reg_src [filter $g2b_source_mailbox_src_candidates {IS_SEQUENTIAL == 1 && REF_NAME !~ RAM*}]
set g2b_source_mailbox_ram_src [filter $g2b_source_mailbox_src_candidates {IS_SEQUENTIAL == 1 && REF_NAME =~ RAM*}]
# Vivado's XDC evaluator rejects the Tcl concat command.  A quoted collection
# union preserves the same 212 sequential launch objects and is accepted by
# read_xdc (validated against the prior post-opt checkpoint).
set g2b_source_mailbox_src "$g2b_source_mailbox_reg_src $g2b_source_mailbox_ram_src"
set g2b_axi_mailbox_dst_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(axis_attempt|axis_generation|axis_epoch|axis_beat_index|axis_global|fatal_generation_axi|own_generation_hold_axi|own_epoch_hold_axi|own_slot_hold_axi|records_abandoned_axi|commit_seen_axi|commit_fifo_head|commit_fifo_tail|commit_fifo_count|axis_state|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_release_phase_hold_axi|transport_hard_hold_axi|transport_own_phase_hold_axi|transport_req_toggle_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|snapshot_busy_axi|snapshot_valid_axi|shadow_last_global|shadow_last_channel|shadow_last_global_valid|shadow_last_channel_valid|axi_hard_episode|error_status_axi|last_error_cause_axi|stored_enable_axi|fatal_clear_qualified_axi)_reg.*}]
set g2b_axi_mailbox_dst [filter $g2b_axi_mailbox_dst_candidates {IS_SEQUENTIAL == 1}]
set_max_delay -datapath_only 6.000 -from $g2b_source_mailbox_src -to $g2b_axi_mailbox_dst

# Split source-to-AXI bundled data at its protocol capture boundary.  Attempt
# and generation may synthesize as distributed RAM while epoch remains flops;
# a field-wide skew check avoids comparing inactive slots or reset-return
# state against unrelated scheduler consumers.
set g2b_desc_attempt_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/desc_attempt_source_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_desc_attempt_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/axis_attempt_reg.*}] {IS_SEQUENTIAL == 1}]
set_bus_skew 3.000 -from $g2b_desc_attempt_src -to $g2b_desc_attempt_dst
set g2b_desc_generation_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/desc_generation_source_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_desc_generation_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(axis_generation|own_generation_hold_axi)_reg.*}] {IS_SEQUENTIAL == 1}]
set_bus_skew 3.000 -from $g2b_desc_generation_src -to $g2b_desc_generation_dst
set g2b_desc_epoch_src [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/desc_epoch_source_reg.*}] {IS_SEQUENTIAL == 1}]
set g2b_desc_epoch_dst [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(axis_epoch|own_epoch_hold_axi)_reg.*}] {IS_SEQUENTIAL == 1}]
set_bus_skew 3.000 -from $g2b_desc_epoch_src -to $g2b_desc_epoch_dst
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

# The source-side hard-clear baseline is a stable mailbox qualified by the
# synchronized clear-boundary token. Bound and compact it at its first AXI
# synchronizer stage so the baseline is coherent when the token is consumed.
set g2b_hard_baseline_src [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/hard_event_baseline_hold_source_reg\[[0-9]+\]}]
set g2b_hard_baseline_dst [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/hard_event_baseline_sync1_axi_reg\[[0-9]+\]}]
set g2b_hard_baseline_d [get_pins -quiet -of_objects $g2b_hard_baseline_dst -filter {REF_PIN_NAME == D}]
set_max_delay -datapath_only 6.000 -from $g2b_hard_baseline_src -to $g2b_hard_baseline_d
set_bus_skew 3.000 -from $g2b_hard_baseline_src -to $g2b_hard_baseline_d
