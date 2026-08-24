set output_dir [file normalize [file dirname [info script]]]
set project_path [file normalize {C:/FPGA/V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY_BUILD/vivado_project/v41_r1f_phase_complete_observability.xpr}]
set repository_root [file normalize {C:/FPGA/WORKTREES/V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY}]

proc safe_property {object property} {
  if {[catch {get_property $property $object} value]} {
    return NOT_AVAILABLE
  }
  if {$value eq ""} {
    return EMPTY
  }
  return $value
}

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  foreach line $lines {
    puts $fh $line
  }
  close $fh
}

open_project -read_only $project_path

set project_lines [list \
  "QUERY_MODE=OPEN_PROJECT_READ_ONLY" \
  "VIVADO_VERSION_SHORT=[version -short]" \
  "VIVADO_VERSION_DETAIL=[string map [list \n { | } \r {}] [version]]" \
  "PROJECT_PATH=$project_path" \
  "PART=[get_property PART [current_project]]" \
  "TARGET_LANGUAGE=[get_property TARGET_LANGUAGE [current_project]]" \
  "SIMULATOR_LANGUAGE=[get_property SIMULATOR_LANGUAGE [current_project]]" \
  "XPM_LIBRARIES=[get_property XPM_LIBRARIES [current_project]]" \
  "TOP=[get_property TOP [get_filesets sources_1]]" \
  "GENERIC=[get_property GENERIC [get_filesets sources_1]]"]
write_lines [file join $output_dir PROJECT_QUERY project_contract.txt] $project_lines

set compile_objects [get_files -compile_order sources -used_in synthesis]
set compile_lines [list]
set index 0
foreach object $compile_objects {
  set name [get_property NAME $object]
  lappend compile_lines [join [list \
    [format %03d $index] \
    [safe_property $object FILE_TYPE] \
    [safe_property $object LIBRARY] \
    [safe_property $object USED_IN] \
    [safe_property $object USED_IN_SYNTHESIS] \
    $name] |]
  incr index
}
write_lines [file join $output_dir PROJECT_QUERY queried_compile_order.txt] $compile_lines

set vhdl_rel_files [list \
  rtl/nvp/nvp6134c_diagnostics_pkg.vhd \
  rtl/nvp/r1f_transaction_serial_counter.vhd \
  rtl/nvp/nvp6134c_i2c_bringup.vhd \
  rtl/nvp/nvp6134c_autoinit.vhd]
set vhdl_lines [list]
foreach rel $vhdl_rel_files {
  set path [file normalize [file join $repository_root $rel]]
  set objects [get_files -quiet $path]
  if {[llength $objects] != 1} {
    error "expected one project object for $rel, got [llength $objects]"
  }
  set object [lindex $objects 0]
  lappend vhdl_lines [join [list \
    $rel \
    [safe_property $object FILE_TYPE] \
    [safe_property $object LIBRARY] \
    [safe_property $object USED_IN] \
    [safe_property $object USED_IN_SYNTHESIS] \
    [safe_property $object IS_ENABLED]] |]
}
write_lines [file join $output_dir PROJECT_QUERY r1f_vhdl_file_properties.txt] $vhdl_lines

report_compile_order -fileset sources_1 -sources -used_in synthesis \
  -file [file join $output_dir PROJECT_QUERY report_compile_order_sources_synthesis.txt]

write_lines [file join $output_dir PROJECT_QUERY query_summary.txt] [list \
  "PROJECT_QUERY=PASS" \
  "OPEN_PROJECT_READ_ONLY=YES" \
  "PROJECT_CREATED=NO" \
  "SYNTH_DESIGN_INVOKED=NO" \
  "COMPILE_OBJECT_COUNT=[llength $compile_objects]" \
  "R1F_VHDL_OBJECT_COUNT=[llength $vhdl_rel_files]"]

close_project
exit 0
