# AHD v41 G2B-NVP-VIDEO-DIAG1-R2
# Exact routed-DCP identity and raw CDC extraction harness.
#
# This harness is deliberately report-only.  It opens the one governed R1
# routed checkpoint, queries the already-routed design, writes task-local R2
# evidence, and closes the design.  It never reads or resets XDC, sets a
# property, runs implementation, writes a checkpoint, or writes a bitstream.

if {$argc != 0} {
  puts stderr "usage: g2b_nvp_video_diag1_r2_extract.tcl"
  exit 2
}

set task_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R2_20260910T064851Z}
set output_root [file join $task_root cdc raw-extraction]
set routed_dcp {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp}
set expected_routed_dcp_sha {45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F}
set expected_cdc1_manifest_sha {BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99}
set expected_part {xc7a35tcsg325-2}
set expected_top {ahd_capture_top_xdma}
set expected_vivado_version {2025.2}
set expected_source_commit {fcab95726761a0666a67e31c283dbdfb9e775074}
set expected_source_tree {bbf1a5fee70a2eb68bb96305ed10934a1559ca6a}

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
    set candidate [string toupper \
      [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $candidate]} { return $candidate }
  }
  error "SHA-256 unavailable for $path"
}

proc path_key {path} {
  return [string tolower [string trimright [file normalize $path] "/\\"]]
}

proc path_is_within {child parent} {
  set child_key [path_key $child]
  set parent_key [path_key $parent]
  if {$child_key eq $parent_key} { return 1 }
  return [expr {[string first "${parent_key}/" $child_key] == 0}]
}

proc single_line {value} {
  return [string map [list "\r" {\r} "\n" {\n} "\t" {\t}] $value]
}

proc csv_quote {value} {
  set value [single_line $value]
  set value [string map [list {"} {""}] $value]
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

proc route_metric {text label} {
  foreach line [split $text "\n"] {
    if {[string first $label $line] < 0} { continue }
    if {[regexp {: *([0-9,]+) *:} $line -> value]} {
      return [string map [list "," ""] $value]
    }
  }
  error "route metric not found: $label"
}

proc sorted_objects_by_name {objects} {
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

proc write_clock_inventory_and_signature {root tag} {
  set inventory_path [file join $root "CLOCK_INVENTORY_${tag}.csv"]
  set signature_path [file join $root "CLOCK_SIGNATURE_${tag}.txt"]
  set inventory [list [csv_row [list \
    Name Period Waveform IsGenerated MasterClock SourcePins ClockRoots]]]
  set signature [list]
  foreach clock [sorted_objects_by_name [get_clocks -quiet]] {
    set name [get_property NAME $clock]
    set period [property_or_unknown PERIOD $clock]
    set waveform [property_or_unknown WAVEFORM $clock]
    set generated [property_or_unknown IS_GENERATED $clock]
    set master [property_or_unknown MASTER_CLOCK $clock]
    set source_pins [property_or_unknown SOURCE_PINS $clock]
    set roots [property_or_unknown CLOCK_ROOT $clock]
    lappend inventory [csv_row [list \
      $name $period $waveform $generated $master $source_pins $roots]]
    lappend signature \
      "$name|PERIOD=$period|WAVEFORM=$waveform|IS_GENERATED=$generated|MASTER_CLOCK=$master|SOURCE_PINS=[single_line $source_pins]"
  }
  if {[llength $signature] == 0} { error "clock signature is empty" }
  write_lines $inventory_path $inventory
  write_lines $signature_path $signature
  return [list [sha256_file $inventory_path] [sha256_file $signature_path] \
    [llength $signature]]
}

proc write_netlist_inventory_and_signature {root tag} {
  set cell_path [file join $root "CELL_INVENTORY_${tag}.csv"]
  set net_path [file join $root "NET_INVENTORY_${tag}.csv"]
  set signature_path [file join $root "NETLIST_SIGNATURE_${tag}.txt"]

  set cell_handle [open $cell_path w]
  set net_handle [open $net_path w]
  set signature_handle [open $signature_path w]
  foreach handle [list $cell_handle $net_handle $signature_handle] {
    fconfigure $handle -encoding utf-8 -translation lf
  }
  puts $cell_handle [csv_row [list \
    Name RefName PrimitiveType IsSequential IsPrimitive Loc Bel]]
  puts $net_handle [csv_row [list Name IsClock IsStatic RouteStatus]]

  set cell_count 0
  foreach cell [sorted_objects_by_name [get_cells -quiet -hier]] {
    set name [get_property NAME $cell]
    set ref_name [property_or_unknown REF_NAME $cell]
    puts $cell_handle [csv_row [list \
      $name $ref_name [property_or_unknown PRIMITIVE_TYPE $cell] \
      [property_or_unknown IS_SEQUENTIAL $cell] \
      [property_or_unknown IS_PRIMITIVE $cell] \
      [property_or_unknown LOC $cell] [property_or_unknown BEL $cell]]]
    puts $signature_handle "CELL|$name|$ref_name"
    incr cell_count
  }

  set net_count 0
  foreach net [sorted_objects_by_name [get_nets -quiet -hier]] {
    set name [get_property NAME $net]
    puts $net_handle [csv_row [list \
      $name [property_or_unknown IS_CLOCK $net] \
      [property_or_unknown IS_STATIC $net] \
      [property_or_unknown ROUTE_STATUS $net]]]
    puts $signature_handle "NET|$name"
    incr net_count
  }
  close $cell_handle
  close $net_handle
  close $signature_handle
  if {$cell_count == 0 || $net_count == 0} {
    error "netlist inventory is empty: cells=$cell_count nets=$net_count"
  }
  return [list \
    [sha256_file $cell_path] [sha256_file $net_path] \
    [sha256_file $signature_path] $cell_count $net_count]
}

proc write_route_signature {root tag} {
  set path [file join $root "ROUTE_SIGNATURE_${tag}.txt"]
  set handle [open $path w]
  fconfigure $handle -encoding utf-8 -translation lf
  set net_count 0
  set nonempty_route_count 0
  foreach net [sorted_objects_by_name [get_nets -quiet -hier]] {
    set name [get_property NAME $net]
    set route [property_or_unknown ROUTE $net]
    set fixed_route [property_or_unknown FIXED_ROUTE $net]
    set route_status [property_or_unknown ROUTE_STATUS $net]
    if {$route ni {EMPTY UNKNOWN}} { incr nonempty_route_count }
    puts $handle "NET|$name|ROUTE=[single_line $route]|FIXED_ROUTE=[single_line $fixed_route]|ROUTE_STATUS=[single_line $route_status]"
    incr net_count
  }
  close $handle
  if {$net_count == 0 || $nonempty_route_count == 0} {
    error "route signature is not usable: nets=$net_count nonempty_routes=$nonempty_route_count"
  }
  return [list [sha256_file $path] $net_count $nonempty_route_count]
}

proc write_cdc_object_properties {root violations} {
  set object_path [file join $root CDC_VIOLATION_OBJECTS.csv]
  set property_path [file join $root CDC_VIOLATION_PROPERTIES_LONG.csv]
  set object_handle [open $object_path w]
  set property_handle [open $property_path w]
  foreach handle [list $object_handle $property_handle] {
    fconfigure $handle -encoding utf-8 -translation lf
  }
  puts $object_handle [csv_row [list \
    ObjectIndex ObjectName Rule Ordinal Severity Class PropertyCount]]
  puts $property_handle [csv_row [list \
    ObjectIndex ObjectName Rule Ordinal Severity Property Value]]

  set object_index 0
  foreach violation [sorted_objects_by_name $violations] {
    incr object_index
    set name [get_property NAME $violation]
    if {![regexp {^(CDC-[0-9]+)#([0-9]+)$} $name -> rule ordinal]} {
      error "unexpected CDC violation object name: $name"
    }
    set severity [property_or_unknown SEVERITY $violation]
    set properties [lsort -dictionary -unique [list_property $violation]]
    puts $object_handle [csv_row [list \
      $object_index $name $rule $ordinal $severity \
      [property_or_unknown CLASS $violation] [llength $properties]]]
    foreach property $properties {
      puts $property_handle [csv_row [list \
        $object_index $name $rule $ordinal $severity $property \
        [property_or_unknown $property $violation]]]
    }
  }
  close $object_handle
  close $property_handle
  return [list [sha256_file $object_path] [sha256_file $property_path] $object_index]
}

proc parse_cdc_report {root raw_path expected_cdc1_sha} {
  set text [read_text $raw_path]
  set summary_descriptions [dict create]
  set summary_counts [dict create]
  set source_clock UNKNOWN
  set destination_clock UNKNOWN
  set cdc_type UNKNOWN
  set rule_ordinals [dict create]
  set actual_rule_counts [dict create]
  set severity_counts [dict create Critical 0 Warning 0 Info 0 Unknown 0]
  set rows [list]
  set clock_pair_counts [dict create]
  set exception_counts [dict create]
  set global_row 0

  foreach line [split $text "\n"] {
    if {[regexp {^[ \t]*(CDC-[0-9]+)[ \t]+(Critical|Warning|Info|Unknown)[ \t]+([0-9]+)[ \t]+(.+)[ \t]*$} \
        $line -> rule severity count description]} {
      dict set summary_descriptions $rule [string trim $description]
      dict set summary_counts "$rule|$severity" $count
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
    if {![regexp {^[ \t]*([0-9]+)[ \t]+(CDC-[0-9]+)[ \t]+(Critical|Warning|Info|Unknown)[ \t]+(.+)$} \
        $line -> section_row rule severity remainder]} {
      continue
    }
    if {![dict exists $summary_descriptions $rule]} {
      error "CDC detail row has no summary description: [single_line $line]"
    }
    if {$source_clock eq "UNKNOWN" || $destination_clock eq "UNKNOWN" ||
        $cdc_type eq "UNKNOWN"} {
      error "CDC detail row lacks clock/type context: [single_line $line]"
    }
    set description [dict get $summary_descriptions $rule]
    if {[string first $description $remainder] != 0} {
      error "CDC detail description drift for $rule: [single_line $line]"
    }
    set tail [string trim [string range $remainder [string length $description] end]]
    set tokens [regexp -all -inline {[^ \t]+} $tail]
    if {[llength $tokens] < 4} {
      error "CDC detail row is not parseable: [single_line $line]"
    }
    set depth [lindex $tokens 0]
    set source_endpoint [lindex $tokens end-1]
    set destination_endpoint [lindex $tokens end]
    set exception [join [lrange $tokens 1 end-2] " "]
    if {![string is integer -strict $depth] || $exception eq "" ||
        $source_endpoint eq "" || $destination_endpoint eq ""} {
      error "CDC detail attributes are invalid: [single_line $line]"
    }

    incr global_row
    dict incr rule_ordinals $rule
    set ordinal [dict get $rule_ordinals $rule]
    set violation_name "$rule#$ordinal"
    dict incr actual_rule_counts "$rule|$severity"
    if {![dict exists $severity_counts $severity]} {
      dict set severity_counts $severity 0
    }
    dict incr severity_counts $severity
    dict incr clock_pair_counts \
      "$source_clock|$destination_clock|$cdc_type|$rule|$severity"
    dict incr exception_counts "$rule|$severity|$exception"
    lappend rows [list \
      $global_row $section_row $violation_name $rule $severity \
      $source_clock $destination_clock $cdc_type $depth $exception \
      $source_endpoint $destination_endpoint $description]
  }

  set expected_counts [dict create \
    {CDC-1|Critical} 423 {CDC-3|Info} 30 {CDC-6|Warning} 13 \
    {CDC-9|Info} 6 {CDC-10|Critical} 2 {CDC-13|Critical} 2 \
    {CDC-15|Warning} 861]
  foreach key [dict keys $expected_counts] {
    set actual [expr {[dict exists $actual_rule_counts $key] ? \
      [dict get $actual_rule_counts $key] : 0}]
    set summary [expr {[dict exists $summary_counts $key] ? \
      [dict get $summary_counts $key] : -1}]
    set expected [dict get $expected_counts $key]
    if {$actual != $expected || $summary != $expected} {
      error "CDC count mismatch for $key: expected=$expected summary=$summary rows=$actual"
    }
  }
  if {[dict size $actual_rule_counts] != [dict size $expected_counts] ||
      $global_row != 1337 || [dict get $severity_counts Critical] != 427 ||
      [dict get $severity_counts Warning] != 874 ||
      [dict get $severity_counts Info] != 36 ||
      [dict get $severity_counts Unknown] != 0} {
    error "complete CDC row-count gate failed: rows=$global_row critical=[dict get $severity_counts Critical] warning=[dict get $severity_counts Warning] info=[dict get $severity_counts Info] unknown=[dict get $severity_counts Unknown] rule_keys=[dict size $actual_rule_counts]"
  }

  set header [csv_row [list \
    GlobalRow SectionRow ViolationName Rule Severity SourceClock \
    DestinationClock CDCType Depth Exception PhysicalSource \
    DestinationEndpoint Description]]
  set all_lines [list $header]
  set critical_lines [list $header]
  set warning_lines [list $header]
  set cdc1_manifest [list]
  set cdc1_destinations [list]
  set physical_sources [list]
  foreach row $rows {
    set encoded [csv_row $row]
    lappend all_lines $encoded
    set rule [lindex $row 3]
    set severity [lindex $row 4]
    set source_clock [lindex $row 5]
    set destination_clock [lindex $row 6]
    set exception [lindex $row 9]
    set source_endpoint [lindex $row 10]
    set destination_endpoint [lindex $row 11]
    if {$severity eq "Critical"} { lappend critical_lines $encoded }
    if {$severity eq "Warning"} { lappend warning_lines $encoded }
    lappend physical_sources \
      "$rule|$severity|$source_clock->$destination_clock|$exception|$source_endpoint|$destination_endpoint"
    if {$rule eq "CDC-1" && $severity eq "Critical"} {
      lappend cdc1_manifest \
        "$rule|$source_clock->$destination_clock|$exception|$source_endpoint|$destination_endpoint"
      lappend cdc1_destinations \
        "$destination_clock|$destination_endpoint"
    }
  }
  set all_path [file join $root CDC_ROWS_ALL.csv]
  set critical_path [file join $root CDC_ROWS_CRITICAL.csv]
  set warning_path [file join $root CDC_ROWS_WARNING.csv]
  set cdc1_path [file join $root G2B_NVP_VIDEO_DIAG1_R2_CDC_1_PHYSICAL_MANIFEST.txt]
  set destinations_path [file join $root G2B_NVP_VIDEO_DIAG1_R2_CDC_1_DESTINATION_MANIFEST.txt]
  set sources_path [file join $root G2B_NVP_VIDEO_DIAG1_R2_CDC_PHYSICAL_SOURCE_MANIFEST.txt]
  write_lines $all_path $all_lines
  write_lines $critical_path $critical_lines
  write_lines $warning_path $warning_lines
  write_lines $cdc1_path [lsort -ascii $cdc1_manifest]
  write_lines $destinations_path [lsort -ascii $cdc1_destinations]
  write_lines $sources_path [lsort -ascii $physical_sources]
  set cdc1_sha [sha256_file $cdc1_path]
  if {$cdc1_sha ne $expected_cdc1_sha} {
    error "CDC-1 physical manifest mismatch: expected=$expected_cdc1_sha actual=$cdc1_sha"
  }

  set rule_lines [list [csv_row [list Rule Severity SummaryCount ParsedCount]]]
  foreach key [lsort -dictionary [dict keys $expected_counts]] {
    lassign [split $key |] rule severity
    lappend rule_lines [csv_row [list $rule $severity \
      [dict get $summary_counts $key] [dict get $actual_rule_counts $key]]]
  }
  set rule_path [file join $root CDC_RULE_COUNTS.csv]
  write_lines $rule_path $rule_lines

  set pair_lines [list [csv_row [list \
    SourceClock DestinationClock CDCType Rule Severity Count]]]
  foreach key [lsort -dictionary [dict keys $clock_pair_counts]] {
    lassign [split $key |] src dst type rule severity
    lappend pair_lines [csv_row [list \
      $src $dst $type $rule $severity [dict get $clock_pair_counts $key]]]
  }
  set pair_path [file join $root CDC_CLOCK_PAIR_COUNTS.csv]
  write_lines $pair_path $pair_lines

  set exception_lines [list [csv_row [list Rule Severity Exception Count]]]
  foreach key [lsort -dictionary [dict keys $exception_counts]] {
    lassign [split $key |] rule severity exception
    lappend exception_lines [csv_row [list \
      $rule $severity $exception [dict get $exception_counts $key]]]
  }
  set exception_path [file join $root CDC_EXCEPTION_COUNTS.csv]
  write_lines $exception_path $exception_lines

  return [list \
    $global_row [dict get $severity_counts Critical] \
    [dict get $severity_counts Warning] [dict get $severity_counts Info] \
    $cdc1_sha [sha256_file $all_path] [sha256_file $critical_path] \
    [sha256_file $warning_path] [sha256_file $destinations_path] \
    [sha256_file $sources_path] [sha256_file $rule_path] \
    [sha256_file $pair_path] [sha256_file $exception_path]]
}

set design_open 0
set operation_code [catch {
  set task_root [file normalize $task_root]
  set output_root [file normalize $output_root]
  set routed_dcp [file normalize $routed_dcp]
  set expected_task_root [file normalize \
    {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R2_20260910T064851Z}]
  set expected_dcp_path [file normalize \
    {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp}]
  if {[path_key $task_root] ne [path_key $expected_task_root] ||
      ![path_is_within $output_root $task_root] ||
      [path_key $routed_dcp] ne [path_key $expected_dcp_path]} {
    error "fixed R2 task/DCP path authority mismatch"
  }
  if {![file isfile $routed_dcp]} {
    error "exact routed DCP is unavailable: $routed_dcp"
  }
  if {[file exists $output_root]} {
    set existing [glob -nocomplain -directory $output_root *]
    if {[llength $existing] != 0} {
      error "fresh extraction output directory is not empty: $output_root"
    }
  } else {
    file mkdir $output_root
  }

  set vivado_version [version -short]
  if {$vivado_version ne $expected_vivado_version} {
    error "Vivado version mismatch: expected=$expected_vivado_version actual=$vivado_version"
  }
  set dcp_size_before [file size $routed_dcp]
  set dcp_mtime_before [file mtime $routed_dcp]
  set dcp_sha_before [sha256_file $routed_dcp]
  if {$dcp_sha_before ne $expected_routed_dcp_sha} {
    error "exact routed DCP hash mismatch: expected=$expected_routed_dcp_sha actual=$dcp_sha_before"
  }

  open_checkpoint $routed_dcp
  set design_open 1
  set design [current_design]
  set part [get_property PART $design]
  set top [get_property TOP $design]
  if {$part ne $expected_part || $top ne $expected_top} {
    error "routed DCP design identity mismatch: part=$part top=$top"
  }

  set route_report [file join $output_root ROUTE_STATUS.rpt]
  report_route_status -file $route_report
  set fully_routed [report_route_status -boolean_check ROUTED_FULLY]
  set errors_in_routes [report_route_status -boolean_check ERRORS_IN_ROUTES]
  set unrouted_nets [llength \
    [report_route_status -return_nets -route_type UNROUTED]]
  set partial_nets [llength \
    [report_route_status -return_nets -route_type PARTIAL]]
  set route_text [read_text $route_report]
  set routable_nets [route_metric $route_text {# of routable nets}]
  set fully_routed_nets [route_metric $route_text {# of fully routed nets}]
  if {!$fully_routed || $errors_in_routes || $unrouted_nets != 0 ||
      $partial_nets != 0 || $routable_nets != $fully_routed_nets} {
    error "routed DCP route gate failed: fully=$fully_routed errors=$errors_in_routes routable=$routable_nets routed=$fully_routed_nets unrouted=$unrouted_nets partial=$partial_nets"
  }

  lassign [write_clock_inventory_and_signature $output_root PRE_CDC] \
    clock_inventory_pre_sha clock_signature_pre_sha clock_count
  lassign [write_netlist_inventory_and_signature $output_root PRE_CDC] \
    cell_inventory_pre_sha net_inventory_pre_sha netlist_signature_pre_sha \
    cell_count net_count
  lassign [write_route_signature $output_root PRE_CDC] \
    route_signature_pre_sha route_net_count route_nonempty_count

  set raw_cdc_path [file join $output_root CDC.rpt]
  report_cdc -details -file $raw_cdc_path
  set raw_cdc_sha [sha256_file $raw_cdc_path]
  set cdc_violations [get_cdc_violations -quiet]
  lassign [write_cdc_object_properties $output_root $cdc_violations] \
    cdc_objects_sha cdc_properties_sha cdc_object_count
  lassign [parse_cdc_report \
      $output_root $raw_cdc_path $expected_cdc1_manifest_sha] \
    cdc_row_count critical_count warning_count info_count cdc1_manifest_sha \
    all_rows_sha critical_rows_sha warning_rows_sha destinations_sha \
    physical_sources_sha rule_counts_sha clock_pairs_sha exception_counts_sha
  if {$cdc_object_count != $cdc_row_count} {
    error "CDC report/object multiplicity mismatch: report=$cdc_row_count objects=$cdc_object_count"
  }

  lassign [write_clock_inventory_and_signature $output_root POST_CDC] \
    clock_inventory_post_sha clock_signature_post_sha clock_count_post
  lassign [write_netlist_inventory_and_signature $output_root POST_CDC] \
    cell_inventory_post_sha net_inventory_post_sha netlist_signature_post_sha \
    cell_count_post net_count_post
  lassign [write_route_signature $output_root POST_CDC] \
    route_signature_post_sha route_net_count_post route_nonempty_count_post
  if {$clock_signature_post_sha ne $clock_signature_pre_sha ||
      $netlist_signature_post_sha ne $netlist_signature_pre_sha ||
      $route_signature_post_sha ne $route_signature_pre_sha ||
      $clock_count_post != $clock_count || $cell_count_post != $cell_count ||
      $net_count_post != $net_count || $route_net_count_post != $route_net_count ||
      $route_nonempty_count_post != $route_nonempty_count} {
    error "design signature changed across report-only CDC extraction"
  }

  close_design
  set design_open 0
  set dcp_size_after [file size $routed_dcp]
  set dcp_mtime_after [file mtime $routed_dcp]
  set dcp_sha_after [sha256_file $routed_dcp]
  if {$dcp_sha_after ne $dcp_sha_before || $dcp_size_after != $dcp_size_before ||
      $dcp_mtime_after != $dcp_mtime_before} {
    error "input routed DCP changed during extraction"
  }

  write_lines [file join $output_root G2B_NVP_VIDEO_DIAG1_R2_DCP_CDC_EXTRACTION_RECEIPT.txt] [list \
    {RESULT=PASS} \
    {MODE=EXACT_ROUTED_DCP_REPORT_ONLY} \
    "VIVADO_VERSION=$vivado_version" \
    "SOURCE_COMMIT=$expected_source_commit" \
    "SOURCE_TREE=$expected_source_tree" \
    "ROUTED_DCP=$routed_dcp" \
    "ROUTED_DCP_SIZE=$dcp_size_before" \
    "ROUTED_DCP_MTIME_EPOCH=$dcp_mtime_before" \
    "ROUTED_DCP_SHA256=$dcp_sha_before" \
    "PART=$part" "TOP=$top" \
    {ROUTED_DCP_REUSE=PASS} {ROUTED_DCP_HASH_MATCH=PASS} \
    {FULLY_ROUTED=YES} "ROUTABLE_NETS=$routable_nets" \
    "FULLY_ROUTED_NETS=$fully_routed_nets" \
    "UNROUTED_NETS=$unrouted_nets" "PARTIALLY_ROUTED_NETS=$partial_nets" \
    "ROUTE_STATUS_SHA256=[sha256_file $route_report]" \
    "RAW_CDC_REPORT=$raw_cdc_path" "RAW_CDC_REPORT_SHA256=$raw_cdc_sha" \
    "CDC_OBJECT_COUNT=$cdc_object_count" "CDC_ROW_COUNT=$cdc_row_count" \
    "CRITICAL_TOTAL=$critical_count" "WARNING_TOTAL=$warning_count" \
    "INFO_TOTAL=$info_count" {CDC_1_CRITICAL=423} {CDC_10_CRITICAL=2} \
    {CDC_13_CRITICAL=2} {CDC_6_WARNING=13} {CDC_15_WARNING=861} \
    "CDC_1_PHYSICAL_MANIFEST_SHA256=$cdc1_manifest_sha" \
    "CDC_ROWS_ALL_SHA256=$all_rows_sha" \
    "CDC_ROWS_CRITICAL_SHA256=$critical_rows_sha" \
    "CDC_ROWS_WARNING_SHA256=$warning_rows_sha" \
    "CDC_DESTINATION_MANIFEST_SHA256=$destinations_sha" \
    "CDC_PHYSICAL_SOURCE_MANIFEST_SHA256=$physical_sources_sha" \
    "CDC_RULE_COUNTS_SHA256=$rule_counts_sha" \
    "CDC_CLOCK_PAIR_COUNTS_SHA256=$clock_pairs_sha" \
    "CDC_EXCEPTION_COUNTS_SHA256=$exception_counts_sha" \
    "CDC_OBJECTS_SHA256=$cdc_objects_sha" \
    "CDC_PROPERTIES_LONG_SHA256=$cdc_properties_sha" \
    "CLOCK_COUNT=$clock_count" "CELL_COUNT=$cell_count" "NET_COUNT=$net_count" \
    "ROUTE_NET_COUNT=$route_net_count" \
    "ROUTE_NONEMPTY_PROPERTY_COUNT=$route_nonempty_count" \
    "CLOCK_INVENTORY_PRE_SHA256=$clock_inventory_pre_sha" \
    "CLOCK_INVENTORY_POST_SHA256=$clock_inventory_post_sha" \
    "CLOCK_SIGNATURE_PRE_SHA256=$clock_signature_pre_sha" \
    "CLOCK_SIGNATURE_POST_SHA256=$clock_signature_post_sha" \
    "CELL_INVENTORY_PRE_SHA256=$cell_inventory_pre_sha" \
    "CELL_INVENTORY_POST_SHA256=$cell_inventory_post_sha" \
    "NET_INVENTORY_PRE_SHA256=$net_inventory_pre_sha" \
    "NET_INVENTORY_POST_SHA256=$net_inventory_post_sha" \
    "NETLIST_SIGNATURE_PRE_SHA256=$netlist_signature_pre_sha" \
    "NETLIST_SIGNATURE_POST_SHA256=$netlist_signature_post_sha" \
    "ROUTE_SIGNATURE_PRE_SHA256=$route_signature_pre_sha" \
    "ROUTE_SIGNATURE_POST_SHA256=$route_signature_post_sha" \
    {CLOCK_SIGNATURE_UNCHANGED=YES} \
    {NETLIST_SIGNATURE_UNCHANGED=YES} \
    {ROUTE_SIGNATURE_UNCHANGED=YES} \
    {CONSTRAINT_COMMANDS_EXECUTED=NONE} \
    {IMPLEMENTATION_COMMANDS_EXECUTED=NONE} \
    {CHECKPOINT_WRITES=0} {BITSTREAM_WRITES=0} \
    "ROUTED_DCP_SHA256_AFTER_CLOSE=$dcp_sha_after" \
    {INPUT_DCP_UNCHANGED=YES}]
} operation_message operation_options]

if {$operation_code != 0} {
  if {$design_open} { catch {close_design} }
  catch {
    file mkdir $output_root
    write_lines [file join $output_root G2B_NVP_VIDEO_DIAG1_R2_DCP_CDC_EXTRACTION_FAILURE.txt] [list \
      {RESULT=FAIL} "ERROR=[single_line $operation_message]"]
  }
  puts stderr "G2B_NVP_VIDEO_DIAG1_R2_DCP_CDC_EXTRACTION_FAIL: $operation_message"
  if {[dict exists $operation_options -errorinfo]} {
    puts stderr [dict get $operation_options -errorinfo]
  }
  exit 1
}

puts "G2B_NVP_VIDEO_DIAG1_R2_DCP_CDC_EXTRACTION_PASS"
exit 0
