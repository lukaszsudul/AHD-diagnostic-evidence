# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R1
# Read-only exact routed-DCP CDC/cone extraction.
#
# One invocation opens exactly one DCP.  It does not modify timing constraints,
# implementation, source repositories, checkpoints, or bitstreams.

if {$argc != 1 || [lindex $argv 0] ni {product diagnostic}} {
  puts stderr "usage: g2b_nvp_video_diag1_r2r1_extract_cones.tcl product|diagnostic"
  exit 2
}

set profile [lindex $argv 0]
set task_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z}
set contract_path [file join $task_root cone-proof changed_destinations.tsv]
set expected_contract_sha {D8FAD3132ADECCDBAFD8189297617D9FC45F79382C07F16EB01208BF82A766B2}
if {$profile eq "product"} {
  set dcp {C:/FPGA/G2B_BT656_FIX1_R1_20260909T090813Z/artifacts/offline-candidate/G2B_BT656_FIX1_R1_SIGNED_OFF_ROUTED.dcp}
  set expected_dcp_sha {5284A91C8D106A14E35A4DCB7A33EC4527A325D3D0F4F9333E6BB73C57255A82}
  set expected_cdc1_sha {A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D}
} else {
  set dcp {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp}
  set expected_dcp_sha {45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F}
  set expected_cdc1_sha {BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99}
}
set output_root [file join $task_root cone-proof $profile]
if {[file exists $output_root] && [llength [glob -nocomplain -directory $output_root *]] != 0} {
  puts stderr "profile output directory is not fresh: $output_root"
  exit 2
}
file mkdir $output_root

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set handle [open $path w]
  fconfigure $handle -encoding utf-8 -translation lf
  foreach line $lines { puts $handle $line }
  close $handle
}

proc read_text {path} {
  set handle [open $path r]
  fconfigure $handle -encoding utf-8
  set value [read $handle]
  close $handle
  return $value
}

proc sha256_file {path} {
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set candidate [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $candidate]} { return $candidate }
  }
  error "SHA-256 unavailable for $path"
}

proc csv_quote {value} {
  set value [string map [list "\r" {\r} "\n" {\n} "\t" {\t} {"} {""}] $value]
  return [format {"%s"} $value]
}

proc csv_row {values} {
  set fields [list]
  foreach value $values { lappend fields [csv_quote $value] }
  return [join $fields ,]
}

proc property_or_unknown {property object} {
  if {[catch {get_property $property $object} value]} { return UNKNOWN }
  if {$value eq ""} { return EMPTY }
  return $value
}

proc regex_quote {value} {
  regsub -all {[][(){}.^$*+?|\\]} $value {\\&} result
  return $result
}

proc sorted_objects_by_name {objects} {
  set pairs [list]
  foreach object $objects { lappend pairs [list [get_property NAME $object] $object] }
  set result [list]
  foreach pair [lsort -dictionary -index 0 $pairs] { lappend result [lindex $pair 1] }
  return $result
}

proc cell_clock_names {cell} {
  set names [list]
  foreach pin [get_pins -quiet -of_objects $cell] {
    if {[property_or_unknown IS_CLOCK $pin] ne "1"} { continue }
    foreach clock [get_clocks -quiet -of_objects $pin] {
      lappend names [get_property NAME $clock]
    }
  }
  return [lsort -unique -dictionary $names]
}

proc parse_cdc_and_write_manifest {raw_path manifest_path} {
  set text [read_text $raw_path]
  set descriptions [dict create]
  set source_clock UNKNOWN
  set destination_clock UNKNOWN
  set cdc_type UNKNOWN
  set rows 0
  set critical 0
  set warning 0
  set info 0
  set cdc1 [list]
  foreach line [split $text "\n"] {
    if {[regexp {^[ \t]*(CDC-[0-9]+)[ \t]+(Critical|Warning|Info|Unknown)[ \t]+([0-9]+)[ \t]+(.+)[ \t]*$} $line -> rule severity count description]} {
      dict set descriptions $rule [string trim $description]
      continue
    }
    if {[regexp {^Source Clock:[ \t]*(.+?)[ \t]*$} $line -> value]} {
      set source_clock [string trim $value]
      continue
    }
    if {[regexp {^Destination Clock:[ \t]*(.+?)[ \t]*$} $line -> value]} {
      set destination_clock [string trim $value]
      continue
    }
    if {[regexp {^CDC Type:[ \t]*(.+?)[ \t]*$} $line -> value]} {
      set cdc_type [string trim $value]
      continue
    }
    if {![regexp {^[ \t]*([0-9]+)[ \t]+(CDC-[0-9]+)[ \t]+(Critical|Warning|Info|Unknown)[ \t]+(.+)$} $line -> section_row rule severity remainder]} {
      continue
    }
    if {![dict exists $descriptions $rule]} { error "CDC row has no description: $line" }
    set description [dict get $descriptions $rule]
    if {[string first $description $remainder] != 0} { error "CDC description drift: $line" }
    set tail [string trim [string range $remainder [string length $description] end]]
    set tokens [regexp -all -inline {[^ \t]+} $tail]
    if {[llength $tokens] < 4} { error "unparseable CDC row: $line" }
    set exception [join [lrange $tokens 1 end-2] " "]
    set source_endpoint [lindex $tokens end-1]
    set destination_endpoint [lindex $tokens end]
    incr rows
    if {$severity eq "Critical"} { incr critical }
    if {$severity eq "Warning"} { incr warning }
    if {$severity eq "Info"} { incr info }
    if {$rule eq "CDC-1" && $severity eq "Critical"} {
      lappend cdc1 "$rule|$source_clock->$destination_clock|$exception|$source_endpoint|$destination_endpoint"
    }
  }
  write_lines $manifest_path [lsort -ascii $cdc1]
  return [list $rows $critical $warning $info [llength $cdc1]]
}

proc read_destinations {path} {
  set text [read_text $path]
  set lines [split [string trimright $text "\r\n"] "\n"]
  if {[llength $lines] != 523} { error "destination contract line count is [llength $lines], expected 523" }
  set header [split [string trimright [lindex $lines 0] "\r"] "\t"]
  set expected [list RowID Rule Severity DestinationEndpoint ProductPhysicalSource DiagnosticPhysicalSource SourceClock DestinationClock Exception SemanticFamily GoverningToken ProtocolProof EarliestUseBarrier ReplacementGroup]
  if {$header ne $expected} { error "destination contract header mismatch" }
  set result [list]
  foreach line [lrange $lines 1 end] {
    set fields [split [string trimright $line "\r"] "\t"]
    if {[llength $fields] != 14} { error "destination contract field count mismatch: $line" }
    lappend result $fields
  }
  return $result
}

set design_open 0
set rc [catch {
  if {![file exists $dcp]} { error "DCP absent: $dcp" }
  if {![file exists $contract_path]} { error "destination contract absent: $contract_path" }
  set contract_sha [sha256_file $contract_path]
  if {$contract_sha ne $expected_contract_sha} { error "destination contract hash mismatch: expected=$expected_contract_sha actual=$contract_sha" }
  set dcp_size_before [file size $dcp]
  set dcp_mtime_before [file mtime $dcp]
  set dcp_sha_before [sha256_file $dcp]
  if {$dcp_sha_before ne $expected_dcp_sha} {
    error "DCP hash mismatch: expected=$expected_dcp_sha actual=$dcp_sha_before"
  }
  open_checkpoint $dcp
  set design_open 1
  set vivado_version [version -short]
  if {![string match {2025.2*} $vivado_version]} { error "Vivado version mismatch: $vivado_version" }
  set part [get_property PART [current_design]]
  set top [get_property TOP [current_design]]
  if {$part ne "xc7a35tcsg325-2"} { error "part mismatch: $part" }
  if {$top ne "ahd_capture_top_xdma"} { error "top mismatch: $top" }
  set design_cell_count [llength [get_cells -quiet -hier]]
  if {$design_cell_count <= 0} { error "empty design cell inventory" }
  if {![report_route_status -boolean_check ROUTED_FULLY]} { error "DCP is not fully routed" }
  if {[report_route_status -boolean_check ERRORS_IN_ROUTES]} { error "DCP has route errors" }
  if {[llength [report_route_status -return_nets -route_type UNROUTED]] != 0} { error "DCP has unrouted nets" }
  if {[llength [report_route_status -return_nets -route_type PARTIAL]] != 0} { error "DCP has partially routed nets" }

  set raw_cdc [file join $output_root CDC.rpt]
  report_cdc -details -file $raw_cdc
  set cdc1_manifest [file join $output_root CDC_1_PHYSICAL_MANIFEST.txt]
  lassign [parse_cdc_and_write_manifest $raw_cdc $cdc1_manifest] cdc_rows critical_count warning_count info_count cdc1_count
  if {$cdc_rows != 1337 || $critical_count != 427 || $warning_count != 874 || $info_count != 36 || $cdc1_count != 423} {
    error "raw CDC authority count mismatch: rows=$cdc_rows critical=$critical_count warning=$warning_count info=$info_count cdc1=$cdc1_count"
  }
  set cdc1_sha [sha256_file $cdc1_manifest]
  if {$cdc1_sha ne $expected_cdc1_sha} {
    error "CDC-1 manifest reproduction failed: expected=$expected_cdc1_sha actual=$cdc1_sha"
  }

  set rows [read_destinations $contract_path]
  set inventory_path [file join $output_root DESTINATION_STARTPOINT_INVENTORY.csv]
  set summary_path [file join $output_root DESTINATION_EXTRACTION_SUMMARY.csv]
  set inventory [open $inventory_path w]
  set summary [open $summary_path w]
  foreach handle [list $inventory $summary] { fconfigure $handle -encoding utf-8 -translation lf }
  puts $inventory [csv_row [list Profile RowID DestinationPin DestinationCell ExpectedDestinationClock ResolvedDestinationClocks StartpointCell StartpointRef StartpointClocks ClockRelation]]
  puts $summary [csv_row [list Profile RowID DestinationPin DestinationCell ExpectedDestinationClock ResolvedDestinationClocks ReportRepresentative ReportRepresentativeCell RepresentativeInStartpoints PhysicalStartpointCount FullConeCellCount CrossClockStartpointCount SameClockStartpointCount StaticStartpointCount DiagnosticHierarchyConeCellCount]]

  set processed 0
  foreach row $rows {
    lassign $row row_id rule severity destination_endpoint product_rep diagnostic_rep source_clock expected_destination_clock exception semantic_family governing_token protocol barrier replacement
    puts "R2R1_CONE_QUERY_STARTED|PROFILE=$profile|ROW=$row_id|DESTINATION=$destination_endpoint"
    flush stdout
    set destination [get_pins -quiet -hier -regexp "^[regex_quote $destination_endpoint]$"]
    if {[llength $destination] != 1} { error "$row_id destination count [llength $destination]: $destination_endpoint" }
    if {[get_property NAME $destination] ne $destination_endpoint} { error "$row_id exact destination name mismatch" }
    set destination_cell [get_cells -quiet -of_objects $destination]
    if {[llength $destination_cell] != 1} { error "$row_id destination cell count [llength $destination_cell]" }
    if {[property_or_unknown IS_SEQUENTIAL $destination_cell] ne "1"} { error "$row_id destination owner is not sequential" }
    set destination_clocks [cell_clock_names $destination_cell]
    if {[llength $destination_clocks] != 1 || [lindex $destination_clocks 0] ne $expected_destination_clock} {
      error "$row_id destination clock mismatch: expected=$expected_destination_clock actual=$destination_clocks"
    }
    set startpoints [sorted_objects_by_name [all_fanin -flat -startpoints_only -only_cells -to $destination]]
    if {[llength $startpoints] == 0} { error "$row_id empty physical startpoint set" }
    if {[llength $startpoints] > $design_cell_count} { error "$row_id unreasonable physical startpoint count [llength $startpoints]" }
    set cone_cells [sorted_objects_by_name [all_fanin -flat -only_cells -to $destination]]
    if {[llength $cone_cells] == 0 || [llength $cone_cells] > $design_cell_count} { error "$row_id invalid full cone size [llength $cone_cells]" }
    set report_representative [expr {$profile eq "product" ? $product_rep : $diagnostic_rep}]
    set representative_pin [get_pins -quiet -hier -regexp "^[regex_quote $report_representative]$"]
    if {[llength $representative_pin] != 1} { error "$row_id report representative pin count [llength $representative_pin]: $report_representative" }
    set representative_cell [get_cells -quiet -of_objects $representative_pin]
    if {[llength $representative_cell] != 1} { error "$row_id report representative cell count [llength $representative_cell]" }
    set representative_clocks [cell_clock_names $representative_cell]
    if {[llength $representative_clocks] != 1 || [lindex $representative_clocks 0] ne $source_clock} {
      error "$row_id report representative clock mismatch: expected=$source_clock actual=$representative_clocks"
    }
    set startpoint_names [list]
    foreach startpoint $startpoints { lappend startpoint_names [get_property NAME $startpoint] }
    set cone_names [list]
    foreach cone_cell $cone_cells { lappend cone_names [get_property NAME $cone_cell] }
    foreach startpoint_name $startpoint_names {
      if {[lsearch -exact $cone_names $startpoint_name] < 0} { error "$row_id startpoint is absent from full fanin cone: $startpoint_name" }
    }
    set representative_name [get_property NAME $representative_cell]
    set representative_in_startpoints [expr {[lsearch -exact $startpoint_names $representative_name] >= 0 ? "YES" : "NO"}]
    if {$representative_in_startpoints ne "YES"} { error "$row_id report representative is absent from exact destination startpoints: $representative_name" }
    set cross 0
    set same 0
    set static 0
    foreach cell $startpoints {
      set clocks [cell_clock_names $cell]
      if {[llength $clocks] > 1} { error "$row_id multi-clock startpoint [get_property NAME $cell]: $clocks" }
      if {[llength $clocks] == 0} {
        set ref_name [property_or_unknown REF_NAME $cell]
        if {$ref_name ni {GND VCC}} { error "$row_id non-static clockless startpoint [get_property NAME $cell] ref=$ref_name" }
        set relation STATIC
        incr static
      } elseif {[lsearch -exact $clocks $expected_destination_clock] >= 0 && [llength $clocks] == 1} {
        set relation SAME_CLOCK
        incr same
      } else {
        set relation CROSS_CLOCK
        incr cross
      }
      puts $inventory [csv_row [list $profile $row_id $destination_endpoint [get_property NAME $destination_cell] $expected_destination_clock [join $destination_clocks {;}] [get_property NAME $cell] [property_or_unknown REF_NAME $cell] [join $clocks {;}] $relation]]
    }
    set diagnostic_hierarchy_count 0
    foreach cell $cone_cells {
      if {[string match {GEN_NVP_VIDEO_DIAG*} [get_property NAME $cell]]} { incr diagnostic_hierarchy_count }
    }
    if {$diagnostic_hierarchy_count != 0} { error "$row_id functional destination cone contains diagnostic hierarchy cells: $diagnostic_hierarchy_count" }
    puts $summary [csv_row [list $profile $row_id $destination_endpoint [get_property NAME $destination_cell] $expected_destination_clock [join $destination_clocks {;}] $report_representative $representative_name $representative_in_startpoints [llength $startpoints] [llength $cone_cells] $cross $same $static $diagnostic_hierarchy_count]]
    flush $inventory
    flush $summary
    incr processed
    puts "R2R1_CONE_QUERY_FINISHED|PROFILE=$profile|ROW=$row_id|DESTINATIONS=$processed/522|STARTPOINTS=[llength $startpoints]|CROSS_CLOCK=$cross"
    flush stdout
  }
  close $inventory
  close $summary

  set tap_path [file join $output_root DIAGNOSTIC_TAP_FANOUT.csv]
  set tap_lines [list [csv_row [list Tap PinCount Direction NetCount AllFanoutEndpointCellCount FunctionalG2BEndpointCount DiagnosticEndpointCount Disposition]]]
  foreach tap [list diag_stored_enable diag_c2h_active diag_ring_empty diag_ring_full] {
    set tap_pin_name "G2B_ONECH_C2H/$tap"
    set tap_pin_pattern "^[regex_quote $tap_pin_name]$"
    set pins [get_pins -quiet -hier -regexp $tap_pin_pattern]
    if {$profile eq "product"} {
      if {[llength $pins] != 0} { error "PRODUCT unexpectedly contains diagnostic tap $tap" }
      lappend tap_lines [csv_row [list $tap 0 ABSENT 0 0 0 0 PRODUCT_ABSENT_EXPECTED]]
      continue
    }
    if {[llength $pins] != 1} { error "diagnostic tap $tap pin count [llength $pins]" }
    set direction [get_property DIRECTION $pins]
    if {$direction ne "OUT"} { error "diagnostic tap $tap direction $direction" }
    set nets [get_nets -quiet -of_objects $pins]
    set downstream [all_fanout -flat -endpoints_only -only_cells -from $pins]
    set functional_count 0
    set diagnostic_count 0
    foreach cell $downstream {
      set cell_name [get_property NAME $cell]
      if {[string match {G2B_ONECH_C2H/*} $cell_name]} { incr functional_count }
      if {[string match {GEN_NVP_VIDEO_DIAG*} $cell_name]} { incr diagnostic_count }
    }
    if {$functional_count != 0} { error "diagnostic output $tap feeds back into G2B functional cells: $functional_count" }
    if {[llength $downstream] == 0 || $diagnostic_count == 0} { error "diagnostic output $tap has no resolved diagnostic observation endpoint" }
    lappend tap_lines [csv_row [list $tap 1 $direction [llength $nets] [llength $downstream] $functional_count $diagnostic_count PASS_DIAGNOSTIC_ONLY_FANOUT]]
  }
  write_lines $tap_path $tap_lines

  close_design
  set design_open 0
  set dcp_size_after [file size $dcp]
  set dcp_mtime_after [file mtime $dcp]
  set dcp_sha_after [sha256_file $dcp]
  if {$dcp_sha_after ne $dcp_sha_before || $dcp_size_after != $dcp_size_before || $dcp_mtime_after != $dcp_mtime_before} {
    error "input DCP changed during report-only extraction"
  }

  set receipt [file join $output_root EXTRACTION_RECEIPT.txt]
  write_lines $receipt [list \
    {RESULT=PASS} "PROFILE=$profile" {MODE=EXACT_ROUTED_DCP_REPORT_ONLY} "VIVADO_VERSION=$vivado_version" "PART=$part" "TOP=$top" "DESIGN_CELL_COUNT=$design_cell_count" \
    "DCP=$dcp" "DCP_SHA256=$dcp_sha_before" "DCP_SIZE=$dcp_size_before" \
    "CDC_ROWS=$cdc_rows" "CRITICAL_TOTAL=$critical_count" "WARNING_TOTAL=$warning_count" "INFO_TOTAL=$info_count" \
    "CDC_1_COUNT=$cdc1_count" "CDC_1_PHYSICAL_MANIFEST_SHA256=$cdc1_sha" \
    {CHANGED_DESTINATIONS_PROCESSED=522} \
    "STARTPOINT_INVENTORY_SHA256=[sha256_file $inventory_path]" \
    "EXTRACTION_SUMMARY_SHA256=[sha256_file $summary_path]" \
    "TAP_FANOUT_SHA256=[sha256_file $tap_path]" \
    {CONSTRAINTS_CHANGED=NO} {IMPLEMENTATION_CHANGED=NO} {DCP_CHANGED=NO} {BITSTREAM_WRITTEN=NO}]
} message options]

if {$rc != 0} {
  if {$design_open} { catch {close_design} }
  puts stderr "R2R1_CONE_EXTRACTION_FAILED|PROFILE=$profile|ERROR=$message"
  puts stderr [dict get $options -errorinfo]
  exit 1
}
puts "R2R1_CONE_EXTRACTION_PASS|PROFILE=$profile|OUTPUT=$output_root"
exit 0
