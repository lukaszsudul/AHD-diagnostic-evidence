# Read-only pilot for the governed R2R1 destination-cone extractor.
if {$argc != 0} {
  puts stderr "usage: r2r1_cone_query_pilot.tcl"
  exit 2
}

set task_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z}
set dcp {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp}
set output [file join $task_root cone-proof diagnostic_enable_applied_pilot.txt]

proc property_or_unknown {property object} {
  if {[catch {get_property $property $object} value]} { return UNKNOWN }
  if {$value eq ""} { return EMPTY }
  return $value
}

proc sorted_cells {objects} {
  set pairs [list]
  foreach object $objects {
    lappend pairs [list [get_property NAME $object] $object]
  }
  set result [list]
  foreach pair [lsort -dictionary -index 0 $pairs] {
    lappend result [lindex $pair 1]
  }
  return $result
}

set rc [catch {
  open_checkpoint $dcp
  set destination [get_pins -quiet {G2B_ONECH_C2H/enable_applied_source_reg/D}]
  if {[llength $destination] != 1} {
    error "destination count mismatch: [llength $destination]"
  }
  set startpoints [all_fanin -flat -startpoints_only -only_cells -to $destination]
  if {[llength $startpoints] == 0} { error "empty startpoint set" }

  set handle [open $output w]
  fconfigure $handle -encoding utf-8 -translation lf
  puts $handle "MODE=READ_ONLY_PILOT"
  puts $handle "DCP=$dcp"
  puts $handle "DESTINATION=[get_property NAME $destination]"
  puts $handle "STARTPOINT_COUNT=[llength $startpoints]"
  foreach cell [sorted_cells $startpoints] {
    set clock_names [list]
    foreach pin [get_pins -quiet -of_objects $cell] {
      if {[property_or_unknown IS_CLOCK $pin] ne "1"} { continue }
      foreach clock [get_clocks -quiet -of_objects $pin] {
        lappend clock_names [get_property NAME $clock]
      }
    }
    set clock_names [lsort -unique -dictionary $clock_names]
    puts $handle "STARTPOINT|[get_property NAME $cell]|REF=[property_or_unknown REF_NAME $cell]|CLOCKS=[join $clock_names {;}]"
  }
  close $handle
  close_design
} message options]

if {$rc != 0} {
  catch {close_design}
  puts stderr "R2R1_CONE_PILOT_FAILED: $message"
  puts stderr [dict get $options -errorinfo]
  exit 1
}

puts "R2R1_CONE_PILOT_PASS=$output"
exit 0
