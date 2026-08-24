if {$argc != 4} {
  puts stderr "usage: r1g_routed_dcp_impact_audit.tcl R1E_DCP R1G_DCP OUTPUT_DIR EXPECTED_PART"
  exit 2
}

set r1e_dcp [file normalize [lindex $argv 0]]
set r1g_dcp [file normalize [lindex $argv 1]]
set output_dir [file normalize [lindex $argv 2]]
set expected_part [lindex $argv 3]

proc write_lines {path lines} {
  set fh [open $path w]
  fconfigure $fh -translation lf -encoding utf-8
  foreach line $lines {
    puts $fh $line
  }
  close $fh
}

proc read_text {path} {
  set fh [open $path r]
  fconfigure $fh -translation auto -encoding utf-8
  set text [read $fh]
  close $fh
  return $text
}

proc safe_property {object property} {
  set value NOT_AVAILABLE
  if {[catch {set queried [get_property $property $object]}] == 0 &&
      [string length $queried] > 0} {
    set value $queried
  }
  return $value
}

proc write_object_inventory {path objects properties} {
  set lines [list [join [linsert $properties 0 OBJECT] "\t"]]
  foreach object [lsort -dictionary $objects] {
    set row [list $object]
    foreach property $properties {
      lappend row [safe_property $object $property]
    }
    lappend lines [join $row "\t"]
  }
  write_lines $path $lines
}

proc write_filtered_report_lines {source_path output_path patterns} {
  set selected [list]
  foreach line [split [read_text $source_path] "\n"] {
    foreach pattern $patterns {
      if {[regexp -nocase -- $pattern $line]} {
        lappend selected $line
        break
      }
    }
  }
  write_lines $output_path $selected
}

proc audit_checkpoint {label dcp output_dir expected_part} {
  open_checkpoint $dcp

  set design [current_design]
  set actual_part [safe_property $design PART]
  if {![string equal -nocase $actual_part $expected_part]} {
    error "$label checkpoint part mismatch: expected $expected_part, got $actual_part"
  }

  set nvp_ports [get_ports -quiet {nvp_scl nvp_sda}]
  if {[llength $nvp_ports] != 2} {
    error "$label checkpoint does not contain exactly two NVP I2C ports"
  }
  set nvp_iobufs [get_cells -quiet -hier -regexp \
    {.*NVP_(SCL|SDA)_IOBUF.*}]
  if {[llength $nvp_iobufs] != 2} {
    error "$label checkpoint does not contain exactly two routed NVP IOBUF cells"
  }
  set nvp_t_pins [get_pins -quiet -of_objects $nvp_iobufs \
    -filter {REF_PIN_NAME == T}]
  set nvp_o_pins [get_pins -quiet -of_objects $nvp_iobufs \
    -filter {REF_PIN_NAME == O}]
  if {[llength $nvp_t_pins] != 2 || [llength $nvp_o_pins] != 2} {
    error "$label NVP IOBUF T/O pin inventory is incomplete"
  }

  set nvp_oen_paths [get_timing_paths -quiet -delay_type max \
    -to $nvp_t_pins -max_paths 32 -nworst 16]
  if {[llength $nvp_oen_paths] == 0} {
    error "$label OEN-to-NVP-IOBUF path class is empty"
  }

  set nvp_sync_cells [get_cells -quiet -hier -regexp \
    {.*(sda_sync|scl_sync).*}]
  if {[llength $nvp_sync_cells] == 0} {
    error "$label SCL/SDA synchronizer inventory is empty"
  }
  set sync_first_cells [get_cells -quiet -hier -regexp \
    {.*(sda_sync(_r)?|scl_sync(_r)?)_reg\[0\]$}]
  set sync_first_d [get_pins -quiet -of_objects $sync_first_cells \
    -filter {REF_PIN_NAME == D}]
  if {[llength $sync_first_d] == 0} {
    error "$label first-stage SCL/SDA synchronizer D-pin inventory is empty"
  }
  set pad_sync_paths [get_timing_paths -quiet -delay_type max \
    -from $nvp_o_pins -to $sync_first_d -max_paths 32 -nworst 16]
  if {[llength $pad_sync_paths] == 0} {
    error "$label NVP-pad-to-synchronizer path class is empty"
  }

  set utilization_report [file join $output_dir ${label}_utilization.rpt]
  set utilization_hier_report \
    [file join $output_dir ${label}_utilization_hierarchical.rpt]
  set power_report [file join $output_dir ${label}_power_hierarchical.rpt]
  set congestion_report [file join $output_dir ${label}_congestion.rpt]

  report_utilization -file $utilization_report
  report_utilization -hierarchical -hierarchical_depth 20 \
    -file $utilization_hier_report
  report_power -hierarchical_depth 20 -file $power_report
  report_design_analysis -congestion -file $congestion_report
  report_clock_utilization \
    -file [file join $output_dir ${label}_clock_utilization.rpt]
  report_clocks -file [file join $output_dir ${label}_clocks.rpt]
  report_io -file [file join $output_dir ${label}_io.rpt]

  report_property -all \
    -file [file join $output_dir ${label}_nvp_iobuf_properties.rpt] \
    $nvp_iobufs
  report_timing -delay_type max -to $nvp_t_pins \
    -max_paths 32 -nworst 16 \
    -file [file join $output_dir ${label}_nvp_oen_to_iobuf_paths.rpt]
  report_timing -delay_type max -from $nvp_o_pins -to $sync_first_d \
    -max_paths 32 -nworst 16 \
    -file [file join $output_dir ${label}_nvp_pad_to_synchronizer_paths.rpt]

  write_object_inventory \
    [file join $output_dir ${label}_nvp_port_properties.tsv] \
    $nvp_ports {NAME PACKAGE_PIN IOSTANDARD DRIVE SLEW PULLTYPE LOC}
  write_object_inventory \
    [file join $output_dir ${label}_nvp_iobuf_inventory.tsv] \
    $nvp_iobufs {NAME REF_NAME LOC BEL SITE DONT_TOUCH}
  write_object_inventory \
    [file join $output_dir ${label}_nvp_synchronizer_placement.tsv] \
    $nvp_sync_cells {NAME REF_NAME LOC BEL SITE ASYNC_REG SHREG_EXTRACT}
  write_object_inventory \
    [file join $output_dir ${label}_nvp_first_stage_synchronizers.tsv] \
    $sync_first_cells {NAME REF_NAME LOC BEL SITE ASYNC_REG SHREG_EXTRACT}

  write_lines [file join $output_dir ${label}_nvp_output_fanin.txt] \
    [lsort -dictionary [get_property NAME [all_fanin -flat -to $nvp_t_pins]]]
  write_lines [file join $output_dir ${label}_nvp_input_fanout.txt] \
    [lsort -dictionary [get_property NAME [all_fanout -flat -from $nvp_o_pins]]]

  set all_cells [get_cells -quiet -hier]
  array set primitive_counts {}
  set primitive_total 0
  set lut_count 0
  set ff_count 0
  set ramb18_count 0
  set ramb36_count 0
  set clocking_cells [list]
  set bram_cells [list]
  foreach cell $all_cells {
    set ref_name [safe_property $cell REF_NAME]
    if {$ref_name eq "NOT_AVAILABLE"} {
      continue
    }
    incr primitive_total
    if {![info exists primitive_counts($ref_name)]} {
      set primitive_counts($ref_name) 0
    }
    incr primitive_counts($ref_name)
    if {[regexp {^LUT} $ref_name]} {
      incr lut_count
    }
    if {[regexp {^FD} $ref_name]} {
      incr ff_count
    }
    if {$ref_name eq "RAMB18E1"} {
      incr ramb18_count
      lappend bram_cells $cell
    }
    if {$ref_name eq "RAMB36E1"} {
      incr ramb36_count
      lappend bram_cells $cell
    }
    if {[regexp {^(BUFG|BUFH|BUFR|MMCME|PLLE)} $ref_name]} {
      lappend clocking_cells $cell
    }
  }

  set primitive_lines [list "REF_NAME\tCOUNT"]
  foreach ref_name [lsort -dictionary [array names primitive_counts]] {
    lappend primitive_lines "$ref_name\t$primitive_counts($ref_name)"
  }
  write_lines [file join $output_dir ${label}_primitive_histogram.tsv] \
    $primitive_lines
  write_object_inventory \
    [file join $output_dir ${label}_clocking_placement.tsv] \
    $clocking_cells {NAME REF_NAME LOC BEL SITE}
  write_object_inventory \
    [file join $output_dir ${label}_bram_placement.tsv] \
    $bram_cells {NAME REF_NAME LOC BEL SITE}

  set clocks [get_clocks -quiet]
  write_object_inventory [file join $output_dir ${label}_clock_inventory.tsv] \
    $clocks {NAME PERIOD WAVEFORM IS_GENERATED SOURCE_PINS MASTER_CLOCK}

  write_filtered_report_lines $power_report \
    [file join $output_dir ${label}_power_selected_lines.txt] \
    [list {Total On-Chip Power} {Dynamic.*\(W\)} {Device Static.*\(W\)} \
      {Vccint} {Vccaux} {Vcco} {nvp} {probe} {autoinit}]
  write_filtered_report_lines $congestion_report \
    [file join $output_dir ${label}_congestion_selected_lines.txt] \
    [list {congestion} {level} {north} {south} {east} {west} {window}]

  set metrics [list \
    "LABEL=$label" \
    "DCP=$dcp" \
    "PART=$actual_part" \
    "DESIGN=[safe_property $design NAME]" \
    "CELL_COUNT=[llength $all_cells]" \
    "NET_COUNT=[llength [get_nets -quiet -hier]]" \
    "PRIMITIVE_COUNT=$primitive_total" \
    "LUT_PRIMITIVE_COUNT=$lut_count" \
    "FF_PRIMITIVE_COUNT=$ff_count" \
    "RAMB18E1_COUNT=$ramb18_count" \
    "RAMB36E1_COUNT=$ramb36_count" \
    "CLOCK_COUNT=[llength $clocks]" \
    "CLOCKING_PRIMITIVE_COUNT=[llength $clocking_cells]" \
    "NVP_PORT_COUNT=[llength $nvp_ports]" \
    "NVP_IOBUF_COUNT=[llength $nvp_iobufs]" \
    "NVP_OEN_PATH_COUNT=[llength $nvp_oen_paths]" \
    "NVP_SYNCHRONIZER_CELL_COUNT=[llength $nvp_sync_cells]" \
    "NVP_FIRST_STAGE_CELL_COUNT=[llength $sync_first_cells]" \
    "NVP_PAD_TO_SYNC_PATH_COUNT=[llength $pad_sync_paths]"]
  write_lines [file join $output_dir ${label}_metrics.txt] $metrics
  close_design
}

set vivado_short [string trim [version -short]]
set vivado_detail [version]
set vivado_sw_build UNKNOWN
regexp {SW Build[ \t]+([0-9]+)} $vivado_detail -> vivado_sw_build
if {$vivado_short ne "2025.2" || $vivado_sw_build ne "6299465"} {
  puts stderr "exact Vivado gate failed: version=$vivado_short SW_BUILD=$vivado_sw_build"
  exit 3
}
if {![file isfile $r1e_dcp] || ![file isfile $r1g_dcp]} {
  puts stderr "one or both routed checkpoint paths do not name regular files"
  exit 4
}
if {![file isdirectory $output_dir]} {
  puts stderr "output directory must be created and identity-gated by the wrapper"
  exit 5
}

set audit_rc [catch {
  audit_checkpoint R1E $r1e_dcp $output_dir $expected_part
  audit_checkpoint R1G $r1g_dcp $output_dir $expected_part
} audit_error audit_options]

if {$audit_rc != 0} {
  catch {close_design}
  set error_info UNKNOWN
  if {[dict exists $audit_options -errorinfo]} {
    set error_info [dict get $audit_options -errorinfo]
  }
  write_lines [file join $output_dir R1G_ROUTED_DCP_IMPACT_AUDIT_FAILURE.txt] \
    [list \
      "AUDIT_RESULT=FAIL_READ_ONLY_QUERY" \
      "R1E_DCP=$r1e_dcp" \
      "R1G_DCP=$r1g_dcp" \
      "ERROR=$audit_error" \
      "ERROR_INFO=$error_info" \
      "DESIGN_MUTATIONS=0" \
      "CHECKPOINT_WRITES=0"]
  puts stderr $audit_error
  exit 1
}

write_lines [file join $output_dir R1G_ROUTED_DCP_IMPACT_AUDIT_STATUS.txt] \
  [list \
    "AUDIT_RESULT=PASS_READ_ONLY_DCP_COMPARISON" \
    "R1G_IMPLEMENTATION_DELTA=QUANTIFIED" \
    "R1G_PLACEMENT_NEUTRAL=NOT_CLAIMED" \
    "R1E_DCP=$r1e_dcp" \
    "R1G_DCP=$r1g_dcp" \
    "VIVADO_VERSION=$vivado_short" \
    "VIVADO_SW_BUILD=$vivado_sw_build" \
    "PART=$expected_part" \
    "SCL_SDA_IOBUF_PROPERTY_COMPARISON=CAPTURED" \
    "OEN_TO_IOBUF_PATH_COMPARISON=CAPTURED" \
    "PAD_TO_SYNCHRONIZER_PATH_COMPARISON=CAPTURED" \
    "SYNCHRONIZER_PLACEMENT_COMPARISON=CAPTURED" \
    "CLOCKING_COMPARISON=CAPTURED" \
    "UTILIZATION_AND_BRAM_COMPARISON=CAPTURED" \
    "ROUTING_CONGESTION_COMPARISON=CAPTURED" \
    "POWER_AGGREGATE_RAIL_AND_NVP_HIERARCHY_COMPARISON=CAPTURED" \
    "DESIGN_MUTATIONS=0" \
    "CHECKPOINT_WRITES=0"]

puts "AUDIT_RESULT=PASS_READ_ONLY_DCP_COMPARISON"
puts "R1G_IMPLEMENTATION_DELTA=QUANTIFIED"
puts "R1G_PLACEMENT_NEUTRAL=NOT_CLAIMED"
exit 0
