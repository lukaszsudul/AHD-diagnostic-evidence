# AHD v41 G2B_BT656_DIAG1-R1 exact-scope CDC constraints.
#
# Wide event and metadata data cross only through the independent-clock trace
# BRAM. The only ordinary net crossings are explicit single-bit toggle/status
# synchronizers; only their seven first-stage D pins receive false paths.
# Exact object counts and ASYNC_REG properties are asserted independently by
# the mandatory post-synthesis structural audit.

set bt656_diag_sync1_cells [get_cells -quiet -hier -regexp \
  {.*BT656_BOUNDARY_TRACE/(clear_sync1_source|arm_sync1_source|abort_sync1_source|armed_sync1_axi|triggered_sync1_axi|done_sync1_axi|overflow_sync1_axi)_reg}]
set bt656_diag_sync1_d [get_pins -quiet -of_objects $bt656_diag_sync1_cells \
  -filter {REF_PIN_NAME == D}]
set_false_path -to $bt656_diag_sync1_d
