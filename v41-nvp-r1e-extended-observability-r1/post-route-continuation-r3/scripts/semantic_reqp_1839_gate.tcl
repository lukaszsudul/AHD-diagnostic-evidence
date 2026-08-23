namespace eval r1e_semantic {
  variable accepted_count 4
  variable result_name R3_REQP_1839_SEMANTIC
}

proc r1e_semantic::write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -translation lf
  foreach line $lines { puts $fh $line }
  close $fh
}

proc r1e_semantic::read_text {path} {
  set fh [open $path r]
  set value [read $fh]
  close $fh
  return $value
}

proc r1e_semantic::object_names {getter violation} {
  if {[catch {set objects [$getter -quiet -of_objects $violation]} message]} {
    return [list "QUERY_STATUS=NOT_EXPOSED" "DETAIL=$message"]
  }
  if {[llength $objects] == 0} {
    return [list "QUERY_STATUS=EMPTY"]
  }
  return [concat [list "QUERY_STATUS=EXPOSED" "OBJECT_COUNT=[llength $objects]"] \
    [lsort -dictionary -unique [get_property NAME $objects]]]
}

proc r1e_semantic::gate {output_root} {
  variable accepted_count
  variable result_name
  file mkdir $output_root

  set checks [get_drc_checks -quiet REQP-1839]
  set check_count [llength $checks]
  if {$check_count != 1} {
    error "REQP-1839 check-object cardinality is $check_count, expected 1"
  }
  set check_object [lindex $checks 0]
  report_property -all -file [file join $output_root REQP_1839_check_properties.txt] $check_object

  set semantic_report [file join $output_root REQP_1839_semantic_report.rpt]
  report_drc -name $result_name -checks $check_object -file $semantic_report

  # Vivado 2025.2 documents -name as the association between a report_drc
  # result set and get_drc_violations. The REQP-1839* object-name pattern
  # limits that named result to this exact rule's violation objects.
  set violation_objects [get_drc_violations -quiet -name $result_name {REQP-1839*}]
  set violation_names [lsort -dictionary -unique [get_property NAME $violation_objects]]
  set semantic_count [llength $violation_names]

  set inventory [list \
    "REQP_1839_CHECK_OBJECT_COUNT=$check_count" \
    "REQP_1839_CHECK_OBJECT=[get_property NAME $check_object]" \
    "REQP_1839_RESULT_NAME=$result_name" \
    "REQP_1839_RETURNED_OBJECT_COUNT=[llength $violation_objects]" \
    "REQP_1839_DEDUPLICATED_OBJECT_COUNT=$semantic_count" \
    "DEDUPLICATION_KEY=EXACT_VIOLATION_OBJECT_NAME"]

  set index 0
  foreach violation_name $violation_names {
    if {![string match "REQP-1839#*" $violation_name]} {
      error "violation object is not associated with exact REQP-1839 rule: $violation_name"
    }
    set one_violation [get_drc_violations -quiet -name $result_name [list $violation_name]]
    if {[llength $one_violation] != 1} {
      error "per-violation cardinality failure for $violation_name"
    }
    set property_path [file join $output_root [format "REQP_1839_violation_%02d_properties.txt" $index]]
    report_property -all -file $property_path $one_violation
    write_lines [file join $output_root [format "REQP_1839_violation_%02d_property_names.txt" $index]] \
      [lsort -dictionary [list_property $one_violation]]
    write_lines [file join $output_root [format "REQP_1839_violation_%02d_cells.txt" $index]] \
      [object_names get_cells $one_violation]
    write_lines [file join $output_root [format "REQP_1839_violation_%02d_pins.txt" $index]] \
      [object_names get_pins $one_violation]
    write_lines [file join $output_root [format "REQP_1839_violation_%02d_nets.txt" $index]] \
      [object_names get_nets $one_violation]
    lappend inventory "VIOLATION_INDEX=$index OBJECT_NAME=$violation_name PROPERTY_FILE=[file tail $property_path]"
    incr index
  }

  set raw_count [regexp -all {REQP-1839} [read_text $semantic_report]]
  write_lines [file join $output_root REQP_1839_semantic_inventory.txt] $inventory
  write_lines [file join $output_root REQP_1839_SEMANTIC_GATE.txt] [list \
    "REQP_1839_CHECK_OBJECT_COUNT=$check_count" \
    "REQP_1839_SEMANTIC_VIOLATION_COUNT=$semantic_count" \
    "REQP_1839_ACCEPTED_BASELINE=$accepted_count" \
    "REQP_1839_RAW_TEXT_OCCURRENCES=$raw_count" \
    "RAW_TEXT_OCCURRENCES_USED_AS_GATE=NO" \
    "REQP_1839_GATE=[expr {$semantic_count == $accepted_count ? "PASS" : "FAIL"}]"]
  puts "REQP_1839_CHECK_OBJECT_COUNT=$check_count"
  puts "REQP_1839_SEMANTIC_VIOLATION_COUNT=$semantic_count"
  puts "REQP_1839_RAW_TEXT_OCCURRENCES=$raw_count"
  puts "RAW_TEXT_OCCURRENCES_USED_AS_GATE=NO"
  if {$semantic_count != $accepted_count} {
    error "semantic REQP-1839 violation count is $semantic_count, accepted baseline is $accepted_count"
  }
  return [dict create check_count $check_count semantic_count $semantic_count raw_count $raw_count]
}
