# AHD v41 G2B-NVP-DIAG2-RM1 exact-scope CDC constraints.
#
# Counter snapshots and trace data cross only through RM1_SNAPSHOT_RAM.  The
# ordinary asynchronous crossings are explicit one-bit command/status first
# stages.  Route/session/window form one stable-data mailbox: AXI holds every
# bit unchanged from ARM acceptance through ACK, and the source captures it
# only after the two-stage ARM toggle.  The structural audit checks both the
# exact destination set and the absence of any other wide source/AXI sampler.

set rm1_sync1_cells [get_cells -quiet -hier -regexp \
  {.*RM1_RAW_MARKER_MONITOR/(clear_sync1_source|arm_sync1_source|freeze_sync1_source|freeze_manual_sync1_source|ack_sync1_source|abort_epoch_sync1_source|armed_sync1_axi|done_sync1_axi|valid_sync1_axi|overflow_sync1_axi|ack_done_sync1_axi|abort_ack_sync1_axi)_reg}]
set rm1_sync1_d [get_pins -quiet -of_objects $rm1_sync1_cells \
  -filter {REF_PIN_NAME == D}]
if {[llength $rm1_sync1_cells] != 12} {
  error "RM1_CDC_XDC_SYNC1_CELL_COUNT=[llength $rm1_sync1_cells]/12"
}
if {[llength $rm1_sync1_d] != 12} {
  error "RM1_CDC_XDC_SYNC1_D_PIN_COUNT=[llength $rm1_sync1_d]/12"
}
foreach rm1_sync1_leaf {
    clear_sync1_source arm_sync1_source freeze_sync1_source
    freeze_manual_sync1_source ack_sync1_source abort_epoch_sync1_source
    armed_sync1_axi done_sync1_axi valid_sync1_axi overflow_sync1_axi
    ack_done_sync1_axi abort_ack_sync1_axi} {
  set rm1_exact_sync1 [get_cells -quiet -hier -regexp \
    ".*RM1_RAW_MARKER_MONITOR/${rm1_sync1_leaf}_reg$"]
  if {[llength $rm1_exact_sync1] != 1} {
    error "RM1_CDC_XDC_EXACT_SYNC1_${rm1_sync1_leaf}=[llength $rm1_exact_sync1]/1"
  }
}
set_false_path -to $rm1_sync1_d

set rm1_arm_session_cells [get_cells -quiet -hier -regexp \
  {.*RM1_RAW_MARKER_MONITOR/session_source_reg\[[0-9]+\]}]
set rm1_arm_route_cells [get_cells -quiet -hier -regexp \
  {.*RM1_RAW_MARKER_MONITOR/route_source_reg\[[0-9]+\]}]
set rm1_arm_window_cells [get_cells -quiet -hier -regexp \
  {.*RM1_RAW_MARKER_MONITOR/window_source_reg\[[0-9]+\]}]
if {[llength $rm1_arm_session_cells] != 16} {
  error "RM1_CDC_XDC_SESSION_CELL_COUNT=[llength $rm1_arm_session_cells]/16"
}
if {[llength $rm1_arm_route_cells] != 3} {
  error "RM1_CDC_XDC_ROUTE_CELL_COUNT=[llength $rm1_arm_route_cells]/3"
}
if {[llength $rm1_arm_window_cells] != 2} {
  error "RM1_CDC_XDC_WINDOW_CELL_COUNT=[llength $rm1_arm_window_cells]/2"
}
foreach {rm1_vector_leaf rm1_vector_width} {
    session_source 16
    route_source 3
    window_source 2} {
  for {set rm1_bit 0} {$rm1_bit < $rm1_vector_width} {incr rm1_bit} {
    set rm1_vector_pattern [format \
      {.*RM1_RAW_MARKER_MONITOR/%s_reg\[%d\]$} $rm1_vector_leaf $rm1_bit]
    set rm1_exact_mailbox [get_cells -quiet -hier -regexp \
      $rm1_vector_pattern]
    if {[llength $rm1_exact_mailbox] != 1} {
      error "RM1_CDC_XDC_EXACT_${rm1_vector_leaf}_${rm1_bit}=[llength $rm1_exact_mailbox]/1"
    }
  }
}
set rm1_arm_mailbox_cells [concat \
  $rm1_arm_session_cells $rm1_arm_route_cells $rm1_arm_window_cells]
set rm1_arm_mailbox_d [get_pins -quiet -of_objects $rm1_arm_mailbox_cells \
  -filter {REF_PIN_NAME == D}]
if {[llength $rm1_arm_mailbox_cells] != 21} {
  error "RM1_CDC_XDC_MAILBOX_CELL_COUNT=[llength $rm1_arm_mailbox_cells]/21"
}
if {[llength $rm1_arm_mailbox_d] != 21} {
  error "RM1_CDC_XDC_MAILBOX_D_PIN_COUNT=[llength $rm1_arm_mailbox_d]/21"
}
set_false_path -to $rm1_arm_mailbox_d
