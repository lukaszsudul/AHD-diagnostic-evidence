# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R1 tap-only recovery.
# Opens PRODUCT then DIAGNOSTIC read-only, binds the already-complete 522-row
# diagnostic artifacts by exact SHA-256, proves source-driver fanout delta, and
# writes the tap CSV plus diagnostic receipt last. Never regenerates cone rows.
set task_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z}
set out [file join $task_root cone-proof diagnostic]
set product_dcp {C:/FPGA/G2B_BT656_FIX1_R1_20260909T090813Z/artifacts/offline-candidate/G2B_BT656_FIX1_R1_SIGNED_OFF_ROUTED.dcp}
set diagnostic_dcp {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp}
set product_sha {5284A91C8D106A14E35A4DCB7A33EC4527A325D3D0F4F9333E6BB73C57255A82}
set diagnostic_sha {45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F}
set sealed [dict create CDC.rpt F9CC51195413F92F59BDA721DCA10FBB86B3BD6D9C7FE8B31837DA10C2FE0043 CDC_1_PHYSICAL_MANIFEST.txt BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99 DESTINATION_STARTPOINT_INVENTORY.csv DE2A85B421E0B5A4BA6333C965AA631F9645A95FB7D3241A665CD1ACB2C62947 DESTINATION_EXTRACTION_SUMMARY.csv 2BD10C3C202D310BA3A7E7FB25F64A6BE496037F3E76AA961CF0588565B4ABC5]
set taps {diag_stored_enable diag_c2h_active diag_ring_empty diag_ring_full}
set anchors [dict create diag_stored_enable {G2B_ONECH_C2H/stored_enable_axi_reg} diag_c2h_active {G2B_ONECH_C2H/ring_empty_sync2_axi_reg G2B_ONECH_C2H/axis_state_reg[0] G2B_ONECH_C2H/axis_state_reg[1] G2B_ONECH_C2H/axis_state_reg[2] G2B_ONECH_C2H/commit_fifo_count_reg[0] G2B_ONECH_C2H/commit_fifo_count_reg[1] G2B_ONECH_C2H/commit_fifo_count_reg[2]} diag_ring_empty {G2B_ONECH_C2H/ring_empty_sync2_axi_reg} diag_ring_full {G2B_ONECH_C2H/ring_full_sync2_axi_reg}]
proc sha256 {path} {
  foreach line [split [exec certutil.exe -hashfile [file nativename $path] SHA256] "\n"] {
    set v [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $v]} {return $v}
  }; error "SHA-256 unavailable: $path"
}
proc write_lines {path lines} {set h [open $path w]; fconfigure $h -encoding utf-8 -translation lf; foreach x $lines {puts $h $x}; close $h}
proc csvq {v} {return "\"[string map [list \" \"\"] $v]\""}
proc csvrow {values} {set r {}; foreach v $values {lappend r [csvq $v]}; return [join $r ,]}
proc objnames {objects} {set r {}; foreach o $objects {lappend r [get_property NAME $o]}; return [lsort -unique -dictionary $r]}
proc minus {a b} {set r {}; foreach x $a {if {[lsearch -exact $b $x] < 0} {lappend r $x}}; return $r}
proc regex_quote {value} {regsub -all {[][(){}.^$*+?|\\]} $value {\\&} result; return $result}
proc collect {dcp expected anchors taps} {
  set size [file size $dcp]; set mtime [file mtime $dcp]
  if {[sha256 $dcp] ne $expected} {error "DCP hash mismatch: $dcp"}
  open_checkpoint $dcp
  if {![string match {2025.2*} [version -short]] || [get_property PART [current_design]] ne {xc7a35tcsg325-2} || [get_property TOP [current_design]] ne {ahd_capture_top_xdma}} {error "DCP identity mismatch: $dcp"}
  if {![report_route_status -boolean_check ROUTED_FULLY] || [report_route_status -boolean_check ERRORS_IN_ROUTES] || [llength [report_route_status -return_nets -route_type UNROUTED]] || [llength [report_route_status -return_nets -route_type PARTIAL]]} {error "DCP route-state mismatch: $dcp"}
  set result [dict create DESIGN_CELL_COUNT [llength [get_cells -quiet -hier]]]
  foreach tap $taps {
    set pins {}
    foreach name [dict get $anchors $tap] {
      set cell [get_cells -quiet -hier -regexp "^[regex_quote $name]$"]
      if {[llength $cell] != 1 || [get_property IS_SEQUENTIAL $cell] ne {1}} {error "$tap exact anchor mismatch: $name"}
      set q [get_pins -quiet -of_objects $cell -filter {DIRECTION == OUT}]
      if {[llength $q] != 1} {error "$tap anchor output mismatch: $name"}; lappend pins $q
    }
    set nets [objnames [get_nets -quiet -of_objects $pins]]
    set endpoints [objnames [all_fanout -flat -endpoints_only -only_cells -from $pins]]
    if {![llength $nets] || ![llength $endpoints]} {error "$tap empty source-driver fanout"}
    dict set result $tap [dict create CELLS [dict get $anchors $tap] PINS [objnames $pins] NETS $nets ENDPOINTS $endpoints]
  }
  close_design
  if {[file size $dcp] != $size || [file mtime $dcp] != $mtime || [sha256 $dcp] ne $expected} {error "DCP changed: $dcp"}
  return $result
}
set rc [catch {
  foreach leaf [dict keys $sealed] {set p [file join $out $leaf]; if {![file isfile $p] || [sha256 $p] ne [dict get $sealed $leaf]} {error "sealed artifact mismatch: $leaf"}}
  set tap_path [file join $out DIAGNOSTIC_TAP_FANOUT.csv]; set detail_path [file join $out DIAGNOSTIC_TAP_FANOUT_DETAIL.txt]; set receipt [file join $out EXTRACTION_RECEIPT.txt]
  foreach p [list $tap_path $detail_path $receipt] {if {[file exists $p]} {error "finalizer target exists: $p"}}
  set pdat [collect $product_dcp $product_sha $anchors $taps]
  set ddat [collect $diagnostic_dcp $diagnostic_sha $anchors $taps]
  set csv [list [csvrow {Tap PinCount Direction NetCount AllFanoutEndpointCellCount FunctionalG2BEndpointCount DiagnosticEndpointCount Disposition}]]
  set detail [list {CLASSIFICATION=EXACT_SOURCE_DRIVER_ALL_FANOUT_TWO_DCP_DELTA} {FORMAL_DIAGNOSTIC_PORT_NAMES=OPTIMIZED_AWAY}]
  foreach tap $taps {
    set p [dict get $pdat $tap]; set d [dict get $ddat $tap]
    if {[dict get $p CELLS] ne [dict get $d CELLS]} {error "$tap anchor-cell drift"}
    set added [minus [dict get $d ENDPOINTS] [dict get $p ENDPOINTS]]; set removed [minus [dict get $p ENDPOINTS] [dict get $d ENDPOINTS]]
    set diagnostic {}; set functional {}; set other {}
    foreach e $added {if {[string match {GEN_NVP_VIDEO_DIAG_CORE.NVP_VIDEO_DIAG_CORE/*} $e]} {lappend diagnostic $e} elseif {[string match {G2B_ONECH_C2H/*} $e]} {lappend functional $e} else {lappend other $e}}
    if {[llength $removed] || [llength $functional] || [llength $other] || ![llength $diagnostic]} {error "$tap non-diagnostic delta: removed=[llength $removed] functional=[llength $functional] other=[llength $other] diagnostic=[llength $diagnostic]"}
    lappend csv [csvrow [list $tap [llength [dict get $d PINS]] OUT [llength [dict get $d NETS]] [llength [dict get $d ENDPOINTS]] 0 [llength $diagnostic] PASS_SOURCE_DRIVER_DELTA_DIAGNOSTIC_ONLY_PORT_NAMES_OPTIMIZED]]
    lappend detail "TAP=$tap" "SOURCE_CELLS=[join [dict get $d CELLS] {|}]" "PRODUCT_ENDPOINTS=[join [dict get $p ENDPOINTS] {|}]" "DIAGNOSTIC_ENDPOINTS=[join [dict get $d ENDPOINTS] {|}]" "ADDED_DIAGNOSTIC_ENDPOINTS=[join $diagnostic {|}]" {ADDED_FUNCTIONAL_G2B_ENDPOINTS=0} {REMOVED_ENDPOINTS=0} {RESULT=PASS}
  }
  write_lines $detail_path $detail; write_lines $tap_path $csv
  write_lines $receipt [list {RESULT=PASS} {PROFILE=diagnostic} {MODE=EXACT_ROUTED_DCP_REPORT_ONLY} {VIVADO_VERSION=2025.2} {PART=xc7a35tcsg325-2} {TOP=ahd_capture_top_xdma} "DESIGN_CELL_COUNT=[dict get $ddat DESIGN_CELL_COUNT]" "DCP=$diagnostic_dcp" "DCP_SHA256=$diagnostic_sha" "DCP_SIZE=[file size $diagnostic_dcp]" {CDC_ROWS=1337} {CRITICAL_TOTAL=427} {WARNING_TOTAL=874} {INFO_TOTAL=36} {CDC_1_COUNT=423} "CDC_1_PHYSICAL_MANIFEST_SHA256=[dict get $sealed CDC_1_PHYSICAL_MANIFEST.txt]" {CHANGED_DESTINATIONS_PROCESSED=522} "STARTPOINT_INVENTORY_SHA256=[dict get $sealed DESTINATION_STARTPOINT_INVENTORY.csv]" "EXTRACTION_SUMMARY_SHA256=[dict get $sealed DESTINATION_EXTRACTION_SUMMARY.csv]" "TAP_FANOUT_SHA256=[sha256 $tap_path]" "TAP_FANOUT_DETAIL_SHA256=[sha256 $detail_path]" {TAP_PROOF_METHOD=EXACT_SOURCE_DRIVER_ALL_FANOUT_TWO_DCP_DELTA} {TAP_BOUNDARY_NAME_DISPOSITION=FORMAL_PORT_NAMES_OPTIMIZED_SOURCE_ANCHORS_USED} "PRODUCT_DCP_SHA256_FOR_TAP_DELTA=$product_sha" {CONSTRAINTS_CHANGED=NO} {IMPLEMENTATION_CHANGED=NO} {DCP_CHANGED=NO} {BITSTREAM_WRITTEN=NO}]
} message options]
if {$rc} {catch {close_design}; puts stderr "R2R1_TAP_FINALIZER_FAILED|ERROR=$message"; puts stderr [dict get $options -errorinfo]; exit 1}
puts {R2R1_TAP_FINALIZER_PASS}; exit 0
