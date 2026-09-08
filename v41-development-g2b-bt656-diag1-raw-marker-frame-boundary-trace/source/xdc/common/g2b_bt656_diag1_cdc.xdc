# AHD v41 G2B_BT656_DIAG1 trace CDC constraints.
#
# The diagnostic module is an observational island. Single-bit command and
# status crossings use explicit two-stage ASYNC_REG chains. Frozen trace
# metadata uses a stable-data mailbox: source metadata becomes immutable with
# DONE, metadata traverses two bitwise ASYNC_REG stages, and DONE traverses
# three stages before any host read is accepted.

set bt656_diag_sync1_cells [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE/(clear_sync1_source|arm_sync1_source|abort_sync1_source|armed_sync1_axi|triggered_sync1_axi|done_sync1_axi|overflow_sync1_axi)_reg}]
set bt656_diag_sync1_d [get_pins -quiet -of_objects $bt656_diag_sync1_cells \
  -filter {REF_PIN_NAME == D}]
set_false_path -to $bt656_diag_sync1_d

# Source-held frozen metadata to the first AXI sampler. Six nanoseconds is the
# same governed absolute settling cap as the existing G2B stable-data
# mailboxes. Three nanoseconds bounds field-wide arrival spread.
set bt656_diag_metadata_src [filter [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE/(valid_entries_source|pre_count_source|pre_start_source|post_count_source|trigger_logical_index_source|stop_reason_source|trigger_frame_source|trigger_line_source|clocks_since_trigger_source)_reg.*}] {IS_SEQUENTIAL == 1}]
set bt656_diag_metadata_dst [filter [get_cells -quiet -hier -regexp {.*BT656_BOUNDARY_TRACE/(valid_entries_sync1_axi|pre_count_sync1_axi|pre_start_sync1_axi|post_count_sync1_axi|trigger_index_sync1_axi|stop_reason_sync1_axi|trigger_frame_sync1_axi|trigger_line_sync1_axi|trigger_clocks_sync1_axi)_reg.*}] {IS_SEQUENTIAL == 1}]
set bt656_diag_metadata_d [get_pins -quiet -of_objects \
  $bt656_diag_metadata_dst -filter {REF_PIN_NAME == D}]
set_max_delay -datapath_only 6.000 \
  -from $bt656_diag_metadata_src -to $bt656_diag_metadata_d
set_bus_skew 3.000 \
  -from $bt656_diag_metadata_src -to $bt656_diag_metadata_d
