# AHD v41 G2B-NVP-VIDEO-DIAG1-R2
# Exact routed-DCP post-reconciliation sign-off and one-bitstream harness.
#
# The input checkpoint and R1 evidence are immutable inputs.  The only design
# outputs authorized here are one fresh R2 signed-off checkpoint followed by
# one fresh R2 .bit file.  No source, IP, implementation, timing-constraint,
# message-configuration, or debug-probe mutation is performed.

if {$argc != 0} {
  puts stderr "usage: g2b_nvp_video_diag1_r2_signoff.tcl"
  exit 2
}

set task_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R2_20260910T064851Z}
set source_root {C:/FPGA/V41_G2B_NVP_VIDEO_DIAG1}
set r1_report_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full}
set routed_dcp [file join $r1_report_root G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp]
set semantic_summary [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2_CDC_RECONCILIATION_SUMMARY.txt]
set semantic_csv [file join $task_root cdc NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V1.csv]
set semantic_json [file join $task_root cdc NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V1.json]
set semantic_sidecar [file join $task_root cdc NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V1.sha256]
set semantic_alias_csv [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2_SEMANTIC_CDC_MANIFEST.csv]
set semantic_alias_json [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2_SEMANTIC_CDC_MANIFEST.json]
set semantic_alias_sidecar [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2_SEMANTIC_CDC_MANIFEST.sha256]
set extraction_root [file join $task_root cdc raw-extraction]
set extraction_receipt [file join $extraction_root G2B_NVP_VIDEO_DIAG1_R2_DCP_CDC_EXTRACTION_RECEIPT.txt]
set signoff_root [file join $task_root signoff]
set artifact_root [file join $task_root artifacts]
set signed_dcp [file join $artifact_root G2B_NVP_VIDEO_DIAG1_R2_SIGNED_OFF_ROUTED.dcp]
set bitstream [file join $artifact_root G2B_NVP_VIDEO_DIAG1_R2_FOUR_CHANNEL_SCAN.bit]

set expected_source_branch {diag/v41-g2b-nvp-video-scan}
set expected_source_commit {fcab95726761a0666a67e31c283dbdfb9e775074}
set expected_source_tree {bbf1a5fee70a2eb68bb96305ed10934a1559ca6a}
set expected_dcp_sha {45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F}
set expected_cdc1_sha {BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99}
set expected_product_cdc1_sha {A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D}
set expected_product_cdc_report_sha {E53EF11E9A2F5FB1B03B0349203E9D220B999B415EF59B183AD59B6E71025A7E}
set expected_bus_skew_receipt_sha {86C33DA963DF82434EB1DB21F2BA873A3EE60B6A1BB6BD12B1EA563175D1236A}
set expected_build_provenance_sha {DA1D7FA70BC69EC25ED051AD2E278280D7408792630F8169707E769EA7BE76C9}
set expected_profile_receipt_sha {DB05C6DB414AF095E32B2B9570380B2A2BECA177B8357174F222E273A3547434}
set expected_source_architecture_sha {A7C784FD746799842C82491D0D5BCB0495B43662C8FAA81614CD0BD28B952D4B}
set expected_part {xc7a35tcsg325-2}
set expected_top {ahd_capture_top_xdma}
set expected_vivado_version {2025.2}

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set handle [open $path w]
  fconfigure $handle -encoding utf-8 -translation lf
  foreach line $lines { puts $handle $line }
  close $handle
}

proc write_text {path value} {
  file mkdir [file dirname $path]
  set handle [open $path w]
  fconfigure $handle -encoding utf-8 -translation lf
  puts -nonewline $handle $value
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

proc read_key_values {path} {
  if {![file isfile $path]} { error "required receipt is missing: $path" }
  set values [dict create]
  foreach raw [split [read_text $path] "\n"] {
    set line [string trim $raw]
    if {$line eq "" || [string match "#*" $line]} { continue }
    if {![regexp {^([A-Z0-9_]+)=(.*)$} $line -> key value]} {
      error "non-canonical receipt line in $path: [single_line $line]"
    }
    if {[dict exists $values $key]} { error "duplicate receipt key $key in $path" }
    dict set values $key $value
  }
  return $values
}

proc require_value {values key expected label} {
  if {![dict exists $values $key]} { error "$label missing key $key" }
  set actual [dict get $values $key]
  if {$actual ne $expected} {
    error "$label $key mismatch: expected=$expected actual=$actual"
  }
  return $actual
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

proc check_timing_table_count {text wanted} {
  foreach line [split $text "\n"] {
    set columns [split $line |]
    for {set index 0} {$index + 1 < [llength $columns]} {incr index} {
      if {[string trim [lindex $columns $index]] ne $wanted} { continue }
      set count [string trim [lindex $columns [expr {$index + 1}]]]
      if {[string is integer -strict $count]} { return $count }
    }
    if {[regexp [format {^[ \t]*%s[ \t]+([0-9]+)} $wanted] $line -> count]} {
      return $count
    }
    if {[regexp [format {checking[ \t]+%s[ \t]*\(([0-9]+)\)} $wanted] $line -> count]} {
      return $count
    }
  }
  return UNKNOWN
}

proc sorted_objects_by_name {objects} {
  set pairs [list]
  foreach object $objects { lappend pairs [list [get_property NAME $object] $object] }
  set result [list]
  foreach pair [lsort -dictionary -index 0 $pairs] { lappend result [lindex $pair 1] }
  return $result
}

proc capture_signatures {root tag} {
  set clock_path [file join $root "CLOCK_SIGNATURE_${tag}.txt"]
  set netlist_path [file join $root "NETLIST_SIGNATURE_${tag}.txt"]
  set route_path [file join $root "ROUTE_STATUS_SIGNATURE_${tag}.txt"]

  set clocks [list]
  foreach clock [sorted_objects_by_name [get_clocks -quiet]] {
    lappend clocks \
      "CLOCK|[get_property NAME $clock]|PERIOD=[property_or_unknown PERIOD $clock]|WAVEFORM=[property_or_unknown WAVEFORM $clock]|IS_GENERATED=[property_or_unknown IS_GENERATED $clock]|MASTER_CLOCK=[property_or_unknown MASTER_CLOCK $clock]|SOURCE_PINS=[single_line [property_or_unknown SOURCE_PINS $clock]]"
  }
  if {[llength $clocks] == 0} { error "clock signature is empty" }
  write_lines $clock_path $clocks

  set netlist_handle [open $netlist_path w]
  fconfigure $netlist_handle -encoding utf-8 -translation lf
  set cell_count 0
  foreach cell [sorted_objects_by_name [get_cells -quiet -hier]] {
    puts $netlist_handle \
      "CELL|[get_property NAME $cell]|REF=[property_or_unknown REF_NAME $cell]|LOC=[property_or_unknown LOC $cell]|BEL=[property_or_unknown BEL $cell]"
    incr cell_count
  }
  set net_count 0
  foreach net [sorted_objects_by_name [get_nets -quiet -hier]] {
    puts $netlist_handle "NET|[get_property NAME $net]"
    incr net_count
  }
  close $netlist_handle
  if {$cell_count == 0 || $net_count == 0} {
    error "netlist signature is empty: cells=$cell_count nets=$net_count"
  }

  # Do not serialize ROUTE or FIXED_ROUTE here.  A single global-constant net
  # in this design has a multi-gigabyte textual ROUTE representation.  Exact
  # route provenance is anchored by the immutable input-DCP SHA-256; this
  # compact signature independently proves stable net identity, route status,
  # fixed-route classification, placement, clocking, and aggregate route state
  # across every report/output stage.
  set routable_count [llength \
    [report_route_status -return_nets -route_type ROUTABLE]]
  set fully_routed_count [llength \
    [report_route_status -return_nets -route_type FULLY_ROUTED]]
  set unrouted_count [llength \
    [report_route_status -return_nets -route_type UNROUTED]]
  set partial_count [llength \
    [report_route_status -return_nets -route_type PARTIAL]]
  set routed_fully [report_route_status -boolean_check ROUTED_FULLY]
  set errors_in_routes [report_route_status -boolean_check ERRORS_IN_ROUTES]
  if {!$routed_fully || $errors_in_routes || $unrouted_count != 0 ||
      $partial_count != 0} {
    error "compact route-status signature found a non-fully-routed design"
  }

  set route_handle [open $route_path w]
  fconfigure $route_handle -encoding utf-8 -translation lf
  puts $route_handle {SCHEMA=G2B_NVP_VIDEO_DIAG1_R2_COMPACT_ROUTE_STATUS_SIGNATURE_V1}
  puts $route_handle "ROUTABLE_NETS=$routable_count"
  puts $route_handle "FULLY_ROUTED_NETS=$fully_routed_count"
  puts $route_handle "UNROUTED_NETS=$unrouted_count"
  puts $route_handle "PARTIALLY_ROUTED_NETS=$partial_count"
  puts $route_handle "ROUTED_FULLY=$routed_fully"
  puts $route_handle "ERRORS_IN_ROUTES=$errors_in_routes"
  set route_net_count 0
  foreach net [sorted_objects_by_name [get_nets -quiet -hier]] {
    puts $route_handle \
      "NET|[get_property NAME $net]|ROUTE_STATUS=[single_line [property_or_unknown ROUTE_STATUS $net]]|IS_ROUTE_FIXED=[single_line [property_or_unknown IS_ROUTE_FIXED $net]]"
    incr route_net_count
  }
  close $route_handle
  if {$route_net_count == 0 || $route_net_count != $net_count} {
    error "compact route-status signature is unusable: route_nets=$route_net_count netlist_nets=$net_count"
  }

  return [dict create \
    CLOCK_SHA256 [sha256_file $clock_path] CLOCK_COUNT [llength $clocks] \
    NETLIST_SHA256 [sha256_file $netlist_path] CELL_COUNT $cell_count NET_COUNT $net_count \
    ROUTE_STATUS_SHA256 [sha256_file $route_path] ROUTE_NET_COUNT $route_net_count \
    ROUTABLE_NET_COUNT $routable_count FULLY_ROUTED_NET_COUNT $fully_routed_count \
    UNROUTED_NET_COUNT $unrouted_count PARTIAL_NET_COUNT $partial_count \
    ROUTED_FULLY $routed_fully ERRORS_IN_ROUTES $errors_in_routes]
}

proc require_same_signatures {expected actual label} {
  foreach key {CLOCK_SHA256 CLOCK_COUNT NETLIST_SHA256 CELL_COUNT NET_COUNT ROUTE_STATUS_SHA256 ROUTE_NET_COUNT ROUTABLE_NET_COUNT FULLY_ROUTED_NET_COUNT UNROUTED_NET_COUNT PARTIAL_NET_COUNT ROUTED_FULLY ERRORS_IN_ROUTES} {
    if {[dict get $expected $key] ne [dict get $actual $key]} {
      error "$label signature mismatch for $key: expected=[dict get $expected $key] actual=[dict get $actual $key]"
    }
  }
}

proc verify_semantic_inputs {} {
  global semantic_summary semantic_csv semantic_json semantic_sidecar
  global semantic_alias_csv semantic_alias_json semantic_alias_sidecar
  global extraction_receipt extraction_root expected_dcp_sha expected_cdc1_sha
  global expected_product_cdc1_sha expected_product_cdc_report_sha

  foreach path [list $semantic_summary $semantic_csv $semantic_json $semantic_sidecar \
      $semantic_alias_csv $semantic_alias_json $semantic_alias_sidecar \
      $extraction_receipt [file join $extraction_root CDC.rpt] \
      [file join $extraction_root G2B_NVP_VIDEO_DIAG1_R2_CDC_1_PHYSICAL_MANIFEST.txt]] {
    if {![file isfile $path] || [file size $path] == 0} {
      error "required fresh semantic/extraction input is missing or empty: $path"
    }
  }
  set summary [read_key_values $semantic_summary]
  foreach requirement [list \
      [list SCHEMA NVP_VIDEO_DIAG1_R2_CDC_RECONCILIATION_SUMMARY_V1] \
      [list RESULT PASS] \
      [list CDC_DISPOSITION PASS_PROFILE_SPECIFIC_SEMANTIC_MANIFEST] \
      [list CLASSIFICATION PROFILE_SPECIFIC_DIAGNOSTIC_CDC_MANIFEST] \
      [list ROUTED_DCP_SHA256 $expected_dcp_sha] \
      [list PRODUCT_CDC_REPORT_SHA256 $expected_product_cdc_report_sha] \
      [list PRODUCT_CDC_1_PHYSICAL_MANIFEST_SHA256 $expected_product_cdc1_sha] \
      [list DIAGNOSTIC_CDC_1_PHYSICAL_MANIFEST_SHA256 $expected_cdc1_sha] \
      [list RAW_CRITICAL_COUNT 427] [list RAW_WARNING_COUNT 874] \
      [list CDC_1_CRITICAL 423] [list CDC_10_CRITICAL 2] [list CDC_13_CRITICAL 2] \
      [list CDC_6_WARNING 13] [list CDC_15_WARNING 861] \
      [list CDC_1_DESTINATION_ROWS_IDENTICAL 423] \
      [list NEW_CDC_1_DESTINATIONS 0] [list MISSING_CDC_1_DESTINATIONS 0] \
      [list CHANGED_CRITICAL_ROWS 302] [list RECONCILED_CRITICAL_ROWS 302] \
      [list UNRECONCILED_CRITICAL_ROWS 0] \
      [list CHANGED_WARNING_ROWS 220] [list RECONCILED_WARNING_ROWS 220] \
      [list UNRECONCILED_WARNING_ROWS 0] \
      [list RULE_DRIFT 0] [list SEVERITY_DRIFT 0] [list CLOCK_PAIR_DRIFT 0] \
      [list EXCEPTION_DRIFT 0] [list DESTINATION_MULTIPLICITY_DRIFT 0] \
      [list SEMANTIC_FAMILY_DRIFT 0] [list PROTOCOL_DRIFT 0] \
      [list REPLACEMENT_GROUP_DRIFT 0] [list DIAGNOSTIC_HIERARCHY_CDC_ROWS 0] \
      [list STRUCTURAL_CDC PASS] [list REPLACEMENT_CHECKS_PASS 17] \
      [list REPLACEMENT_CHECKS_TOTAL 17] [list UNRESOLVED_REPLACEMENT_CHECKS 0]] {
    lassign $requirement key value
    require_value $summary $key $value SEMANTIC_RECONCILIATION
  }

  set extraction [read_key_values $extraction_receipt]
  foreach requirement [list [list RESULT PASS] \
      [list MODE EXACT_ROUTED_DCP_REPORT_ONLY] \
      [list ROUTED_DCP_SHA256 $expected_dcp_sha] \
      [list ROUTED_DCP_HASH_MATCH PASS] [list FULLY_ROUTED YES] \
      [list CRITICAL_TOTAL 427] [list WARNING_TOTAL 874] \
      [list CDC_1_PHYSICAL_MANIFEST_SHA256 $expected_cdc1_sha] \
      [list CLOCK_SIGNATURE_UNCHANGED YES] [list NETLIST_SIGNATURE_UNCHANGED YES] \
      [list ROUTE_SIGNATURE_UNCHANGED YES] [list INPUT_DCP_UNCHANGED YES]] {
    lassign $requirement key value
    require_value $extraction $key $value DCP_CDC_EXTRACTION
  }
  set raw_cdc [file join $extraction_root CDC.rpt]
  set raw_cdc_sha [sha256_file $raw_cdc]
  require_value $extraction RAW_CDC_REPORT_SHA256 $raw_cdc_sha DCP_CDC_EXTRACTION
  require_value $summary DIAGNOSTIC_CDC_REPORT_SHA256 $raw_cdc_sha SEMANTIC_RECONCILIATION
  if {[sha256_file [file join $extraction_root G2B_NVP_VIDEO_DIAG1_R2_CDC_1_PHYSICAL_MANIFEST.txt]] ne $expected_cdc1_sha} {
    error "fresh extraction physical CDC-1 manifest changed after reconciliation"
  }

  set csv_sha [sha256_file $semantic_csv]
  set json_sha [sha256_file $semantic_json]
  require_value $summary SEMANTIC_MANIFEST_CSV_SHA256 $csv_sha SEMANTIC_RECONCILIATION
  require_value $summary SEMANTIC_MANIFEST_JSON_SHA256 $json_sha SEMANTIC_RECONCILIATION
  if {[sha256_file $semantic_alias_csv] ne $csv_sha ||
      [sha256_file $semantic_alias_json] ne $json_sha} {
    error "R2 semantic-manifest aliases are not byte-identical to canonical files"
  }
  return [dict create \
    SUMMARY_SHA256 [sha256_file $semantic_summary] RAW_CDC_SHA256 $raw_cdc_sha \
    CSV_SHA256 $csv_sha JSON_SHA256 $json_sha \
    SIDECAR_SHA256 [sha256_file $semantic_sidecar] \
    ALIAS_SIDECAR_SHA256 [sha256_file $semantic_alias_sidecar]]
}

proc verify_inherited_active_bus_skew {output_root} {
  global r1_report_root routed_dcp expected_dcp_sha expected_bus_skew_receipt_sha
  set receipt_path [file join $r1_report_root BUS_SKEW.rpt]
  if {[sha256_file $receipt_path] ne $expected_bus_skew_receipt_sha} {
    error "inherited active-bus-skew aggregate receipt hash mismatch"
  }
  set values [read_key_values $receipt_path]
  foreach requirement [list \
      [list ROUTED_DCP_SHA256 $expected_dcp_sha] \
      [list FULL_RAW_BUS_SKEW_CONSTRAINTS 11] \
      [list BASE_RAW_BUS_SKEW_CONSTRAINTS 0] \
      [list FULL_BUS_SKEW_CONSTRAINTS 11] [list BASE_BUS_SKEW_CONSTRAINTS 0] \
      [list BASE_MAX_DELAY_CONSTRAINTS 26] [list BASE_FALSE_PATH_CONSTRAINTS 30] \
      [list BASE_CLOCK_GROUP_CONSTRAINTS 1] \
      [list PRE_SETUP_WNS 0.109] [list PRE_HOLD_WHS 0.036] \
      [list POST_SETUP_WNS 0.109] [list POST_HOLD_WHS 0.036] \
      [list RESTORED_BUS_SKEW_CONSTRAINTS 11] \
      [list CLOCK_SIGNATURE_RESTORED YES] [list ROUTE_SIGNATURE_UNCHANGED YES] \
      [list BUS_SKEW_OPERATION_RESULT PASS] [list FULL_TIMING_RESTORATION PASS] \
      [list BUS_SKEW_MET_CONSTRAINTS 11] [list BUS_SKEW_VIOLATIONS 0] \
      [list BUS_SKEW_GATE PASS]] {
    lassign $requirement key value
    require_value $values $key $value INHERITED_ACTIVE_BUS_SKEW
  }
  if {[path_key [dict get $values ROUTED_DCP]] ne [path_key $routed_dcp]} {
    error "inherited active-bus-skew receipt points to another DCP"
  }

  set fixed_artifacts [list \
    [list FULL_RAW_XDC_SHA256 BUS_SKEW_GROUPS/ROUTED_TIMING_FULL_RAW.xdc] \
    [list BASE_RAW_XDC_SHA256 BUS_SKEW_GROUPS/ROUTED_TIMING_WITHOUT_BUS_SKEW_RAW.xdc] \
    [list FULL_SEMANTIC_XDC_SHA256 BUS_SKEW_GROUPS/ROUTED_TIMING_FULL_SEMANTIC_PASS_2.xdc] \
    [list FULL_SEMANTIC_XDC_CANONICAL_SHA256 BUS_SKEW_GROUPS/ROUTED_TIMING_FULL_SEMANTIC_PASS_2_CANONICAL.xdc] \
    [list BASE_SEMANTIC_XDC_SHA256 BUS_SKEW_GROUPS/ROUTED_TIMING_WITHOUT_BUS_SKEW_SEMANTIC_PASS_2.xdc] \
    [list BASE_SEMANTIC_XDC_CANONICAL_SHA256 BUS_SKEW_GROUPS/ROUTED_TIMING_WITHOUT_BUS_SKEW_SEMANTIC_PASS_2_CANONICAL.xdc] \
    [list RESTORED_XDC_SHA256 BUS_SKEW_GROUPS/ROUTED_TIMING_RESTORED.xdc] \
    [list RESTORED_XDC_CANONICAL_SHA256 BUS_SKEW_GROUPS/ROUTED_TIMING_RESTORED_CANONICAL.xdc]]
  foreach item $fixed_artifacts {
    lassign $item key relative
    set path [file join $r1_report_root {*}[split $relative /]]
    if {![file isfile $path] || [sha256_file $path] ne [dict get $values $key]} {
      error "inherited bus-skew artifact mismatch: $relative"
    }
  }

  set group_stems [dict create \
    1 01_CFG_PCIE_TO_NVP 2 02_STATUS_NVP_TO_PCIE \
    3 03_DIAGNOSTIC_GRAY_TO_FIRST_STAGE 4 04_SNAPSHOT_GRAY_SOURCE_TO_AXI \
    5 05_SNAPSHOT_EPOCH_SOURCE_TO_AXI 6 06_HARD_EVENT_BASELINE_SOURCE_TO_AXI \
    7 07_SNAPSHOT_EPOCH_AXI_TO_SOURCE 8 08_TRANSPORT_AXI_TO_SOURCE \
    10 10_DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI \
    11 11_DESCRIPTOR_GENERATION_SOURCE_TO_AXI \
    12 12_DESCRIPTOR_EPOCH_SOURCE_TO_AXI]
  set expected_counts [dict create \
    1 {74 74} 2 {291 291} 3 {96 96} 4 {128 128} 5 {32 32} 6 {4 4} \
    7 {32 32} 8 {38 217} 10 {44 32} 11 {32 24} 12 {128 32}]
  set output [list \
    {SCHEMA=G2B_NVP_VIDEO_DIAG1_R2_INHERITED_ACTIVE_BUS_SKEW_V1} \
    {RESULT=PASS} "ROUTED_DCP_SHA256=$expected_dcp_sha" \
    "R1_AGGREGATE_RECEIPT=$receipt_path" \
    "R1_AGGREGATE_RECEIPT_SHA256=$expected_bus_skew_receipt_sha"]
  set pass_count 0
  foreach group_id {1 2 3 4 5 6 7 8 10 11 12} {
    set stem [dict get $group_stems $group_id]
    lassign [dict get $expected_counts $group_id] expected_sources expected_destinations
    foreach requirement [list \
        [list GROUP_${group_id}_SOURCE_COUNT $expected_sources] \
        [list GROUP_${group_id}_DESTINATION_COUNT $expected_destinations] \
        [list GROUP_${group_id}_NEGATIVE_DISPLAY 0] \
        [list GROUP_${group_id}_VIOLATION_MARKER 0] \
        [list GROUP_${group_id}_RESULT PASS]] {
      lassign $requirement key value
      require_value $values $key $value INHERITED_ACTIVE_BUS_SKEW
    }
    foreach artifact [list \
        [list GROUP_${group_id}_OBJECTS_SHA256 "${stem}_OBJECTS.txt"] \
        [list GROUP_${group_id}_ISOLATED_XDC_SHA256 "${stem}_ISOLATED.xdc"] \
        [list GROUP_${group_id}_RAW_REPORT_SHA256 "${stem}_BUS_SKEW.rpt"]] {
      lassign $artifact key leaf
      set path [file join $r1_report_root BUS_SKEW_GROUPS $leaf]
      if {![file isfile $path] || [sha256_file $path] ne [dict get $values $key]} {
        error "inherited Group $group_id artifact mismatch: $leaf"
      }
    }
    lappend output \
      "GROUP_${group_id}_RESULT=PASS" \
      "GROUP_${group_id}_REPORT_SHA256=[dict get $values GROUP_${group_id}_RAW_REPORT_SHA256]" \
      "GROUP_${group_id}_OBJECTS_SHA256=[dict get $values GROUP_${group_id}_OBJECTS_SHA256]"
    incr pass_count
  }
  if {$pass_count != 11} { error "inherited active-bus-skew pass count is $pass_count/11" }
  lappend output {ACTIVE_BUS_SKEW_GROUPS=11/11} {ACTIVE_BUS_SKEW_VIOLATIONS=0} \
    {CONSTRAINTS_LOADED_OR_MODIFIED=NO} {RESULT=PASS}
  write_lines [file join $output_root G2B_NVP_VIDEO_DIAG1_R2_INHERITED_ACTIVE_BUS_SKEW_VALIDATION.txt] $output
  return $pass_count
}

proc sequential_cells {pattern} {
  return [filter [get_cells -quiet -hier -regexp $pattern] {IS_SEQUENTIAL == 1}]
}

proc object_names {objects} {
  set names [list]
  foreach object $objects { lappend names [get_property NAME $object] }
  return [lsort -dictionary -unique $names]
}

proc require_count {label objects expected} {
  set actual [llength $objects]
  if {$actual != $expected} {
    error "$label object-count drift: expected=$expected actual=$actual"
  }
  return $actual
}

proc promoted_family {index} {
  set group_id 0
  set family UNKNOWN
  set sources [list]
  set destinations [list]
  set expected_sources 0
  set expected_destinations 0
  switch -- $index {
    1 {
      set group_id 9; set family OWNERSHIP_SLOT_SETTLING
      set sources [sequential_cells {.*G2B_ONECH_C2H/(own_slot_hold_axi|axis_slot)_reg.*}]
      set destinations [get_pins -quiet -of_objects \
        [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_ok_hold_source)_reg.*}] \
        -filter {REF_PIN_NAME == D}]
      set expected_sources 2; set expected_destinations 17
    }
    2 {
      set group_id 9; set family OWNERSHIP_GENERATION_SETTLING
      set sources [sequential_cells {.*G2B_ONECH_C2H/(own_generation_hold_axi|axis_generation)_reg.*}]
      set destinations [get_pins -quiet -of_objects \
        [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_ok_hold_source)_reg.*}] \
        -filter {REF_PIN_NAME == D}]
      set expected_sources 24; set expected_destinations 17
    }
    3 {
      set group_id 9; set family OWNERSHIP_EPOCH_SETTLING
      set sources [sequential_cells {.*G2B_ONECH_C2H/(own_epoch_hold_axi|axis_epoch)_reg.*}]
      set destinations [get_pins -quiet -of_objects \
        [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_ok_hold_source)_reg.*}] \
        -filter {REF_PIN_NAME == D}]
      set expected_sources 32; set expected_destinations 17
    }
    4 {
      set group_id 13; set family RESET_ABANDONED_COUNT_STABLE_PAYLOAD
      set sources [sequential_cells {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/records_abandoned_axi_reg.*}]
      set expected_sources 3; set expected_destinations 32
    }
    5 {
      set group_id 13; set family RESET_COMMIT_PHASE_COMPLETION_BARRIER
      set sources [sequential_cells {.*G2B_ONECH_C2H/reset_commit_phase_hold_source_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/(records_abandoned_axi|commit_seen_axi|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|axis_state|snapshot_busy_axi|snapshot_valid_axi|fatal_clear_qualified_axi|axi_hard_episode)_reg.*}]
      set expected_sources 4; set expected_destinations 207
    }
    default {
      if {$index < 6 || $index > 17} { error "unknown promoted family index: $index" }
      set slot [expr {($index - 6) / 3}]
      set within [expr {($index - 6) % 3}]
      set group_id [expr {14 + $slot}]
      set sources [sequential_cells \
        ".*G2B_ONECH_C2H/(release_generation_axi|release_epoch_axi)_reg\\\[$slot\\\].*"]
      set expected_sources 56
      if {$within == 0} {
        set family "RELEASE_SLOT${slot}_NORMAL_STATE_TRANSITION"
        set destinations [sequential_cells \
          ".*G2B_ONECH_C2H/slot_state_source_reg\\\[$slot\\\].*"]
        set expected_destinations 3
      } elseif {$within == 1} {
        set family "RELEASE_SLOT${slot}_MISMATCH_CONTAINMENT"
        set destinations [sequential_cells {.*G2B_ONECH_C2H/(source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}]
        set expected_destinations 4
      } else {
        set family "RELEASE_SLOT${slot}_RESET_OVERLAP_ACCOUNTING"
        set destinations [sequential_cells {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}]
        set expected_destinations 3
      }
    }
  }
  return [list $group_id $family $sources $destinations $expected_sources $expected_destinations]
}

proc run_promoted_replacements {root} {
  set raw_root [file join $root PROMOTED_REPLACEMENTS]
  file mkdir $raw_root
  set csv [list [csv_row [list \
    CheckIndex Group Family SourceCount DestinationCount RequiredNs \
    DatapathDelayNs SlackNs RuntimeMs Result ReportSHA256 ObjectsSHA256]]]
  set group_counts [dict create]
  set pass_count 0
  for {set index 1} {$index <= 17} {incr index} {
    lassign [promoted_family $index] \
      group family sources destinations expected_sources expected_destinations
    set source_names [object_names $sources]
    set destination_names [object_names $destinations]
    require_count "$family sources" $source_names $expected_sources
    require_count "$family destinations" $destination_names $expected_destinations
    set tag [format {%02d_G%02d_%s} $index $group $family]
    set objects_path [file join $raw_root "${tag}_OBJECTS.txt"]
    set report_path [file join $raw_root "${tag}_TIMING.rpt"]
    set object_lines [list]
    foreach name $source_names { lappend object_lines "SOURCE=$name" }
    foreach name $destination_names { lappend object_lines "DESTINATION=$name" }
    write_lines $objects_path $object_lines
    set started [clock milliseconds]
    set paths [get_timing_paths -quiet -delay_type max -sort_by slack \
      -max_paths 1 -nworst 1 -from $sources -to $destinations]
    set elapsed [expr {[clock milliseconds] - $started}]
    if {[llength $paths] != 1} {
      error "$family expected exactly one worst path; found [llength $paths]"
    }
    set path [lindex $paths 0]
    set slack [get_property SLACK $path]
    set datapath [property_or_unknown DATAPATH_DELAY $path]
    if {![string is double -strict $slack] || ![string is double -strict $datapath] ||
        $slack < 0.0 || $datapath > 6.0005} {
      error "$family promoted settling gate failed: datapath=$datapath slack=$slack"
    }
    report_timing -of_objects $paths -file $report_path
    lappend csv [csv_row [list \
      $index $group $family $expected_sources $expected_destinations 6.000 \
      $datapath $slack $elapsed PASS [sha256_file $report_path] \
      [sha256_file $objects_path]]]
    dict incr group_counts $group
    incr pass_count
    write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_PROMOTED_REPLACEMENT_RESULTS.csv] $csv
  }
  foreach requirement {{9 3} {13 2} {14 3} {15 3} {16 3} {17 3}} {
    lassign $requirement group expected
    set actual [expr {[dict exists $group_counts $group] ? [dict get $group_counts $group] : 0}]
    if {$actual != $expected} {
      error "promoted Group $group count mismatch: expected=$expected actual=$actual"
    }
  }
  if {$pass_count != 17} { error "promoted replacement gate is $pass_count/17" }
  return $pass_count
}

proc run_structural_cdc {root} {
  set families [list \
    [list OWNERSHIP_REQUEST_ACK \
      [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(own_req_sync1_source|own_req_sync2_source|own_ack_sync1_axi|own_ack_sync2_axi)_reg}] 4] \
    [list RESET_REQUEST_ACK \
      [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(transport_req_sync1_source|transport_req_sync2_source|transport_ack_sync1_axi|transport_ack_sync2_axi)_reg}] 4] \
    [list RESET_COMMIT_RETURN \
      [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/commit_sync(1|2)_axi_reg\[[0-3]\]}] 8] \
    [list RELEASE_SLOT_TOGGLES \
      [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_sync(1|2)_source_reg\[[0-3]\]}] 8]]
  set lines [list]
  foreach item $families {
    lassign $item family cells expected
    require_count $family $cells $expected
    foreach cell $cells {
      set async [string toupper [property_or_unknown ASYNC_REG $cell]]
      if {$async ni {TRUE 1}} {
        error "$family synchronizer lacks ASYNC_REG=TRUE: [get_property NAME $cell]"
      }
      lappend lines "$family|[get_property NAME $cell]|ASYNC_REG=TRUE|ROUTED_RAW_VALUE=$async"
    }
  }
  lappend lines \
    {OWNERSHIP_CDC=PASS} {RESET_RETURN_CDC=PASS} {RELEASE_SLOT_CDC=PASS} \
    {STABLE_DATA_PROTOCOL=PASS_SEMANTIC_MANIFEST_AND_PROMOTED_CHECKS} \
    {EARLIEST_SEMANTIC_USE_NS=13.468} {SETTLING_CAP_NS=6.000} \
    {GOVERNED_GROSS_RESERVE_NS=7.468} {RESULT=PASS}
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_STRUCTURAL_CDC.txt] $lines
  return PASS
}

proc rule_id {object_name} {
  if {![regexp {^([A-Z]+-[0-9]+)#[0-9]+$} $object_name -> rule]} {
    error "unrecognized violation object name: $object_name"
  }
  return $rule
}

proc check_rule_counts {label objects expected_counts allowed_severities path} {
  set actual [dict create]
  set rows [list [csv_row [list Name Severity Rule]]]
  foreach object $objects {
    set name [get_property NAME $object]
    set severity [string toupper [property_or_unknown SEVERITY $object]]
    if {[lsearch -exact $allowed_severities $severity] < 0} {
      error "$label unexpected severity: $name severity=$severity"
    }
    set rule [rule_id $name]
    if {![dict exists $expected_counts $rule]} {
      error "$label unexpected rule: $name"
    }
    dict incr actual $rule
    lappend rows [csv_row [list $name $severity $rule]]
  }
  foreach rule [dict keys $expected_counts] {
    set count [expr {[dict exists $actual $rule] ? [dict get $actual $rule] : 0}]
    if {$count != [dict get $expected_counts $rule]} {
      error "$label count mismatch for $rule: expected=[dict get $expected_counts $rule] actual=$count"
    }
  }
  if {[dict size $actual] != [dict size $expected_counts]} {
    error "$label unexpected rule-key multiplicity"
  }
  write_lines $path $rows
}

proc parse_cdc_report {root path expected_cdc1_sha} {
  set descriptions [dict create]
  set source_clock UNKNOWN
  set destination_clock UNKNOWN
  set cdc_type UNKNOWN
  set counts [dict create]
  set severity_counts [dict create Critical 0 Warning 0 Info 0 Unknown 0]
  set cdc1 [list]
  set diagnostic_rows [list]
  set total 0
  foreach line [split [read_text $path] "\n"] {
    if {[regexp {^[ \t]*(CDC-[0-9]+)[ \t]+(Critical|Warning|Info|Unknown)[ \t]+([0-9]+)[ \t]+(.+)[ \t]*$} \
        $line -> rule severity count description]} {
      dict set descriptions $rule [string trim $description]
      continue
    }
    if {[regexp {^Source Clock:[ \t]*(.+?)[ \t]*$} $line -> value]} {
      set source_clock [string trim $value]; continue
    }
    if {[regexp {^Destination Clock:[ \t]*(.+?)[ \t]*$} $line -> value]} {
      set destination_clock [string trim $value]; continue
    }
    if {[regexp {^CDC Type:[ \t]*(.+?)[ \t]*$} $line -> value]} {
      set cdc_type [string trim $value]; continue
    }
    if {![regexp {^[ \t]*([0-9]+)[ \t]+(CDC-[0-9]+)[ \t]+(Critical|Warning|Info|Unknown)[ \t]+(.+)$} \
        $line -> row rule severity remainder]} { continue }
    if {![dict exists $descriptions $rule] || $source_clock eq "UNKNOWN" ||
        $destination_clock eq "UNKNOWN" || $cdc_type eq "UNKNOWN"} {
      error "CDC detail row lacks summary/clock context: [single_line $line]"
    }
    set description [dict get $descriptions $rule]
    if {[string first $description $remainder] != 0} {
      error "CDC description drift: [single_line $line]"
    }
    set tokens [regexp -all -inline {[^ \t]+} \
      [string trim [string range $remainder [string length $description] end]]]
    if {[llength $tokens] < 4} { error "unparseable CDC detail row: [single_line $line]" }
    set depth [lindex $tokens 0]
    set source [lindex $tokens end-1]
    set destination [lindex $tokens end]
    set exception [join [lrange $tokens 1 end-2] " "]
    if {![string is integer -strict $depth]} { error "invalid CDC depth: [single_line $line]" }
    dict incr counts "$rule|$severity"
    dict incr severity_counts $severity
    incr total
    if {$rule eq "CDC-1" && $severity eq "Critical"} {
      lappend cdc1 "$rule|$source_clock->$destination_clock|$exception|$source|$destination"
    }
    set haystack [string tolower "$source|$destination"]
    foreach token {g2b_nvp_video_diag nvp_video_diag current_result_word current_result_valid current_result_generation current_result_session scan_fsm} {
      if {[string first $token $haystack] >= 0} {
        lappend diagnostic_rows "$rule|$severity|$source_clock->$destination_clock|$source|$destination"
        break
      }
    }
  }
  set expected [dict create \
    {CDC-1|Critical} 423 {CDC-3|Info} 30 {CDC-6|Warning} 13 \
    {CDC-9|Info} 6 {CDC-10|Critical} 2 {CDC-13|Critical} 2 \
    {CDC-15|Warning} 861]
  foreach key [dict keys $expected] {
    set actual [expr {[dict exists $counts $key] ? [dict get $counts $key] : 0}]
    if {$actual != [dict get $expected $key]} {
      error "fresh signoff CDC count mismatch for $key: expected=[dict get $expected $key] actual=$actual"
    }
  }
  if {[dict size $counts] != 7 || $total != 1337 ||
      [dict get $severity_counts Critical] != 427 ||
      [dict get $severity_counts Warning] != 874 ||
      [dict get $severity_counts Info] != 36 ||
      [dict get $severity_counts Unknown] != 0 ||
      [llength $diagnostic_rows] != 0} {
    error "fresh signoff CDC aggregate mismatch: total=$total critical=[dict get $severity_counts Critical] warning=[dict get $severity_counts Warning] info=[dict get $severity_counts Info] diagnostic_rows=[llength $diagnostic_rows]"
  }
  set manifest_path [file join $root G2B_NVP_VIDEO_DIAG1_R2_SIGNOFF_CDC_1_PHYSICAL_MANIFEST.txt]
  write_lines $manifest_path [lsort -ascii $cdc1]
  set manifest_sha [sha256_file $manifest_path]
  if {$manifest_sha ne $expected_cdc1_sha} {
    error "fresh signoff CDC-1 physical manifest mismatch: expected=$expected_cdc1_sha actual=$manifest_sha"
  }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_DIAGNOSTIC_HIERARCHY_CDC_ROWS.txt] \
    [concat [list "DIAGNOSTIC_HIERARCHY_CDC_ROWS=[llength $diagnostic_rows]"] $diagnostic_rows]
  return [dict create TOTAL $total CRITICAL 427 WARNING 874 INFO 36 \
    CDC1_SHA256 $manifest_sha DIAGNOSTIC_ROWS 0]
}

proc run_cdc_gate {root expected_cdc1_sha} {
  set path [file join $root CDC.rpt]
  report_cdc -details -file $path
  set violations [get_cdc_violations -quiet]
  set critical [list]
  set warning [list]
  set info [list]
  foreach violation $violations {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity in {CRITICAL {CRITICAL WARNING}}} { lappend critical $violation }
    if {$severity eq "WARNING"} { lappend warning $violation }
    if {$severity eq "INFO"} { lappend info $violation }
  }
  check_rule_counts CDC_CRITICAL $critical \
    [dict create CDC-1 423 CDC-10 2 CDC-13 2] {CRITICAL {CRITICAL WARNING}} \
    [file join $root G2B_NVP_VIDEO_DIAG1_R2_CDC_CRITICAL_OBJECTS.csv]
  check_rule_counts CDC_WARNING $warning \
    [dict create CDC-6 13 CDC-15 861] {WARNING} \
    [file join $root G2B_NVP_VIDEO_DIAG1_R2_CDC_WARNING_OBJECTS.csv]
  check_rule_counts CDC_INFO $info \
    [dict create CDC-3 30 CDC-9 6] {INFO} \
    [file join $root G2B_NVP_VIDEO_DIAG1_R2_CDC_INFO_OBJECTS.csv]
  set parsed [parse_cdc_report $root $path $expected_cdc1_sha]
  if {[llength $violations] != [dict get $parsed TOTAL]} {
    error "fresh signoff CDC report/object multiplicity mismatch"
  }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_RAW_CDC_REPRODUCTION.txt] [list \
    {RESULT=PASS} "RAW_CDC_REPORT=$path" "RAW_CDC_REPORT_SHA256=[sha256_file $path]" \
    {CRITICAL_TOTAL=427} {CDC_1_CRITICAL=423} {CDC_10_CRITICAL=2} \
    {CDC_13_CRITICAL=2} {WARNING_TOTAL=874} {CDC_6_WARNING=13} \
    {CDC_15_WARNING=861} "CDC_1_PHYSICAL_MANIFEST_SHA256=[dict get $parsed CDC1_SHA256]" \
    {DIAGNOSTIC_HIERARCHY_CDC_ROWS=0} \
    {CDC_DISPOSITION=PASS_PROFILE_SPECIFIC_SEMANTIC_MANIFEST}]
  return $parsed
}

proc run_timing_gate {root} {
  set summary [file join $root TIMING_SUMMARY.rpt]
  set setup [file join $root ROUTED_SETUP_TIMING.rpt]
  set hold [file join $root ROUTED_HOLD_TIMING.rpt]
  set check [file join $root CHECK_TIMING.rpt]
  set route [file join $root ROUTE_STATUS.rpt]
  set clocks [file join $root CLOCKS.rpt]
  set interaction [file join $root CLOCK_INTERACTION.rpt]
  report_timing_summary -delay_type min_max -check_timing_verbose \
    -report_unconstrained -max_paths 10 -nworst 1 -file $summary
  report_timing -delay_type max -max_paths 100 -nworst 1 -file $setup
  report_timing -delay_type min -max_paths 100 -nworst 1 -file $hold
  check_timing -verbose -file $check
  report_route_status -file $route
  report_clocks -file $clocks
  report_clock_interaction -file $interaction

  set max_paths [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
  set min_paths [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
  if {[llength $max_paths] != 1 || [llength $min_paths] != 1} {
    error "complete routed timing endpoints are unavailable"
  }
  set wns [get_property SLACK [lindex $max_paths 0]]
  set whs [get_property SLACK [lindex $min_paths 0]]
  set failing_setup [llength [get_timing_paths -quiet -delay_type max \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set failing_hold [llength [get_timing_paths -quiet -delay_type min \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  if {![string is double -strict $wns] || ![string is double -strict $whs] ||
      $wns < 0.0 || $whs < 0.0 || $failing_setup != 0 || $failing_hold != 0 ||
      abs($wns - 0.109) > 0.0005 || abs($whs - 0.036) > 0.0005} {
    error "routed timing gate failed: WNS=$wns WHS=$whs setup_fail=$failing_setup hold_fail=$failing_hold"
  }
  set check_text [read_text $check]
  foreach zero_check {no_clock unconstrained_internal_endpoints multiple_clock generated_clocks loops partial_input_delay partial_output_delay latch_loops} {
    set value [check_timing_table_count $check_text $zero_check]
    if {$value eq "UNKNOWN" || $value != 0} {
      error "check_timing gate failed: $zero_check=$value"
    }
  }
  set timing_text [read_text $summary]
  if {[regexp -nocase {Pulse Width Slack[^\n]*-[0-9]} $timing_text] ||
      [regexp -nocase {VIOLATED} $timing_text]} {
    error "complete timing summary contains a violation"
  }
  set route_text [read_text $route]
  set routable [route_metric $route_text {# of routable nets}]
  set routed [route_metric $route_text {# of fully routed nets}]
  set route_errors [route_metric $route_text {# of nets with routing errors}]
  set unrouted [llength [report_route_status -return_nets -route_type UNROUTED]]
  set partial [llength [report_route_status -return_nets -route_type PARTIAL]]
  if {$routable != $routed || $route_errors != 0 || $unrouted != 0 ||
      $partial != 0 || ![report_route_status -boolean_check ROUTED_FULLY]} {
    error "complete route gate failed: routable=$routable routed=$routed errors=$route_errors unrouted=$unrouted partial=$partial"
  }
  set user_clocks [get_clocks -quiet userclk1]
  require_count USERCLK1 $user_clocks 1
  set user_period [get_property PERIOD [lindex $user_clocks 0]]
  set user_mhz [expr {1000.0 / $user_period}]
  if {abs($user_mhz - 62.5) > 0.1} {
    error "application clock frequency drift: $user_mhz MHz"
  }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_TIMING_GATE.txt] [list \
    {RESULT=PASS} {FULLY_ROUTED=YES} "ROUTABLE_NETS=$routable" \
    "FULLY_ROUTED_NETS=$routed" "UNROUTED_NETS=$unrouted" \
    "PARTIALLY_ROUTED_NETS=$partial" "WNS=[format %.3f $wns]" {TNS=0.000} \
    "WHS=[format %.3f $whs]" {THS=0.000} \
    {INTERNAL_UNCONSTRAINED_ENDPOINTS=0} {TIMING_LOOPS=0} \
    {UNEXPECTED_CLOCKS=0} {MISSING_GENERATED_CLOCKS=0} \
    "EFFECTIVE_USER_CLOCK_MHZ=[format %.6f $user_mhz]"]
  return [dict create WNS $wns WHS $whs ROUTABLE_NETS $routable]
}

proc run_drc_methodology_gates {root} {
  set drc_path [file join $root DRC.rpt]
  report_drc -file $drc_path
  set drc_errors [list]
  set drc_critical [list]
  set drc_warnings [list]
  foreach violation [get_drc_violations -quiet] {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "ERROR"} { lappend drc_errors $violation }
    if {$severity eq "CRITICAL WARNING"} { lappend drc_critical $violation }
    if {$severity eq "WARNING"} { lappend drc_warnings $violation }
  }
  if {[llength $drc_errors] != 0 || [llength $drc_critical] != 0} {
    error "DRC hard gate failed: errors=[llength $drc_errors] critical=[llength $drc_critical]"
  }
  check_rule_counts DRC_WARNING $drc_warnings \
    [dict create IOSR-1 2 PDCN-1569 1 REQP-1839 12 RTSTAT-10 1] {WARNING} \
    [file join $root G2B_NVP_VIDEO_DIAG1_R2_DRC_WARNING_OBJECTS.csv]
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_DRC_GATE.txt] [list \
    {DRC=PASS} {DRC_ERRORS=0} {DRC_CRITICAL_WARNINGS=0} \
    {DRC_WARNINGS=16} {ALL_WARNINGS_EXACT_PRIOR_DISPOSITION=YES}]

  set methodology_path [file join $root METHODOLOGY.rpt]
  report_methodology -file $methodology_path
  set methodology_errors [list]
  set methodology_critical [list]
  set methodology_warnings [list]
  foreach violation [get_methodology_violations -quiet] {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "ERROR"} { lappend methodology_errors $violation }
    if {$severity eq "CRITICAL WARNING"} { lappend methodology_critical $violation }
    if {$severity eq "WARNING"} { lappend methodology_warnings $violation }
  }
  if {[llength $methodology_errors] != 0 || [llength $methodology_critical] != 0} {
    error "methodology hard gate failed: errors=[llength $methodology_errors] critical=[llength $methodology_critical]"
  }
  check_rule_counts METHODOLOGY_WARNING $methodology_warnings \
    [dict create LUTAR-1 2 TIMING-9 1 TIMING-34 11 TIMING-39 1] {WARNING} \
    [file join $root G2B_NVP_VIDEO_DIAG1_R2_METHODOLOGY_WARNING_OBJECTS.csv]
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_METHODOLOGY_GATE.txt] [list \
    {METHODOLOGY=PASS} {METHODOLOGY_ERRORS=0} \
    {METHODOLOGY_CRITICAL_WARNINGS=0} {METHODOLOGY_WARNINGS=15} \
    {ALL_WARNINGS_EXACT_PRIOR_DISPOSITION=YES} \
    {NO_MESSAGE_SUPPRESSION_COMMANDS_EXECUTED=YES}]
  return PASS
}

proc utilization_row {text wanted} {
  set normalized [string trimright $wanted *]
  foreach line [split $text "\n"] {
    set columns [split $line |]
    if {[llength $columns] < 7} { continue }
    set actual [string trimright [string trim [lindex $columns 1]] *]
    if {$actual ne $normalized} { continue }
    set used [string map [list "," "" " " ""] [string trim [lindex $columns 2]]]
    set available [string map [list "," "" " " ""] [string trim [lindex $columns 5]]]
    if {![string is double -strict $used] || ![string is double -strict $available] ||
        $available <= 0.0} {
      error "non-numeric utilization row $wanted"
    }
    return [list $used $available]
  }
  error "utilization row not found: $wanted"
}

proc run_resource_gate {root} {
  set text [report_utilization -return_string]
  write_text [file join $root ROUTED_UTILIZATION_FLAT.rpt] $text
  report_utilization -hierarchical -hierarchical_depth 20 \
    -file [file join $root ROUTED_UTILIZATION_HIER.rpt]
  lassign [utilization_row $text {Slice LUTs}] lut used_lut_available
  lassign [utilization_row $text {Slice Registers}] ff used_ff_available
  lassign [utilization_row $text {Block RAM Tile}] bram used_bram_available
  lassign [utilization_row $text {DSPs}] dsp used_dsp_available
  set lut_percent [expr {100.0 * $lut / $used_lut_available}]
  set ff_percent [expr {100.0 * $ff / $used_ff_available}]
  set bram_percent [expr {100.0 * $bram / $used_bram_available}]
  set dsp_percent [expr {100.0 * $dsp / $used_dsp_available}]
  if {$used_lut_available != 20800 || $used_ff_available != 41600 ||
      $used_bram_available != 50 || $used_dsp_available != 90 ||
      $lut_percent > 98.0 || $ff_percent > 95.0 ||
      $bram_percent > 90.0 || $dsp_percent > 90.0} {
    error "resource gate failed: LUT=$lut/$used_lut_available FF=$ff/$used_ff_available BRAM=$bram/$used_bram_available DSP=$dsp/$used_dsp_available"
  }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_RESOURCE_GATE.txt] [list \
    {RESULT=PASS} "LUT_USED=$lut" "LUT_AVAILABLE=$used_lut_available" \
    "LUT_PERCENT=[format %.3f $lut_percent]" {LUT_LIMIT_PERCENT=98.000} \
    "LUT_ENGINEERING_PREFERRED=[expr {$lut_percent <= 92.0 ? {PASS} : {ADVISORY_MISS}}]" \
    "FF_USED=$ff" "FF_AVAILABLE=$used_ff_available" \
    "FF_PERCENT=[format %.3f $ff_percent]" {FF_LIMIT_PERCENT=95.000} \
    "BRAM_USED=$bram" "BRAM_AVAILABLE=$used_bram_available" \
    "BRAM_PERCENT=[format %.3f $bram_percent]" {BRAM_LIMIT_PERCENT=90.000} \
    "DSP_USED=$dsp" "DSP_AVAILABLE=$used_dsp_available" \
    "DSP_PERCENT=[format %.3f $dsp_percent]" {DSP_LIMIT_PERCENT=90.000}]
  return [dict create LUT $lut LUT_AVAILABLE $used_lut_available LUT_PERCENT $lut_percent \
    FF $ff FF_AVAILABLE $used_ff_available FF_PERCENT $ff_percent \
    BRAM $bram BRAM_AVAILABLE $used_bram_available BRAM_PERCENT $bram_percent \
    DSP $dsp DSP_AVAILABLE $used_dsp_available DSP_PERCENT $dsp_percent]
}

proc run_diagnostic_identity_gate {root} {
  global r1_report_root expected_build_provenance_sha expected_profile_receipt_sha
  global expected_source_architecture_sha expected_source_commit expected_source_tree
  set provenance_path [file join $r1_report_root G2B_BUILD_PROVENANCE.txt]
  set profile_path [file join $r1_report_root G2B_PROFILE_ELABORATION_RECEIPT.txt]
  set architecture_path [file join $r1_report_root G2B_NVP_VIDEO_DIAG1_R1_SOURCE_ARCHITECTURE_GATE.txt]
  if {[sha256_file $provenance_path] ne $expected_build_provenance_sha ||
      [sha256_file $profile_path] ne $expected_profile_receipt_sha ||
      [sha256_file $architecture_path] ne $expected_source_architecture_sha} {
    error "immutable R1 diagnostic provenance receipt hash mismatch"
  }
  set provenance [read_key_values $provenance_path]
  foreach requirement [list [list BUILD_PROFILE NVP_VIDEO_DIAGNOSTIC] \
      [list REPOSITORY_HEAD $expected_source_commit] \
      [list REPOSITORY_HEAD_TREE $expected_source_tree] \
      [list SOURCE_BRANCH diag/v41-g2b-nvp-video-scan] \
      [list SOURCE_CLEAN PASS] [list ENABLE_RTRACK_DIAGNOSTICS 0] \
      [list ENABLE_NVP_VIDEO_DIAGNOSTIC 1] [list BUILD_FLAGS 32'h00000402] \
      [list CHECKPOINT_REUSE NO]] {
    lassign $requirement key value
    require_value $provenance $key $value R1_BUILD_PROVENANCE
  }
  set profile [read_key_values $profile_path]
  foreach requirement {{BUILD_PROFILE NVP_VIDEO_DIAGNOSTIC} {ENABLE_RTRACK_DIAGNOSTICS 0} \
      {ENABLE_NVP_VIDEO_DIAGNOSTIC 1} {PRODUCT_R1I_READ_SERVICE_COUNT 1} \
      {NVP_VIDEO_DIAG_CORE_COUNT 1} {NVP_VIDEO_DIAG_I2C_MASTER_COUNT 1} \
      {PROFILE_ELABORATION_GATE PASS}} {
    lassign $requirement key value
    require_value $profile $key $value R1_PROFILE_RECEIPT
  }
  set architecture [read_key_values $architecture_path]
  foreach requirement {{RESULT_STORAGE_ARCHITECTURE_GATE PASS} \
      {ONCHIP_SESSION_HISTORY_ENTRIES 0} {ONCHIP_CURRENT_RESULT_WORDS 8} \
      {ONCHIP_CURRENT_SNAPSHOT_DATA_BITS 256} {RESERVED_MMIO_ZERO_DEFAULT PASS} \
      {DIAG_VERSION 0x00010001} {DIAG_CAPABILITIES 0x000003FF}} {
    lassign $requirement key value
    require_value $architecture $key $value R1_SOURCE_ARCHITECTURE
  }

  set core_cells [get_cells -quiet -hier -regexp {.*GEN_NVP_VIDEO_DIAG_CORE\.NVP_VIDEO_DIAG_CORE}]
  set i2c_cells [get_cells -quiet -hier -regexp {.*GEN_NVP_VIDEO_DIAG_I2C\.NVP_VIDEO_DIAG_I2C_MASTER}]
  require_count NVP_VIDEO_DIAG_CORE $core_cells 1
  require_count NVP_VIDEO_DIAG_I2C_MASTER $i2c_cells 1
  set old_cells [get_cells -quiet -hier -regexp {.*(result_words|result_reset_index|table_word).*}]
  set old_nets [get_nets -quiet -hier -regexp {.*(result_words|result_reset_index|table_word).*}]
  if {[llength $old_cells] != 0 || [llength $old_nets] != 0} {
    error "retired on-chip session-history structures are present"
  }
  set family_lines [list]
  set family_count 0
  for {set index 0} {$index < 8} {incr index} {
    set cells [sequential_cells ".*current_result_word_${index}_reg.*"]
    if {[llength $cells] == 0} { error "current_result_word_$index storage is absent" }
    lappend family_lines "CURRENT_RESULT_WORD_${index}_SEQUENTIAL_CELLS=[llength $cells]"
    incr family_count
  }
  foreach token {current_result_valid current_result_session current_result_generation} {
    set objects [concat [get_cells -quiet -hier -regexp ".*${token}.*"] \
      [get_nets -quiet -hier -regexp ".*${token}.*"]]
    if {[llength $objects] == 0} { error "diagnostic snapshot identity token is absent: $token" }
  }
  set black_boxes [get_cells -quiet -hier -filter {IS_BLACKBOX == 1}]
  if {[llength $black_boxes] != 0} { error "black-box gate failed: [llength $black_boxes]" }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2_DIAGNOSTIC_IDENTITY_GATE.txt] [concat [list \
    {RESULT=PASS} {BUILD_PROFILE=NVP_VIDEO_DIAGNOSTIC} \
    {BUILD_FLAGS=32'h00000402} {DIAG_MAGIC=0x4E565034} \
    {DIAG_VERSION=0x00010001} {DIAG_CAPABILITIES=0x000003FF} \
    {DIAG_MAGIC_VERSION_AUTHORITY=EXACT_SOURCE_COMMIT_TREE_AND_DCP_HASH} \
    {NVP_VIDEO_DIAG_CORE_COUNT=1} {NVP_VIDEO_DIAG_I2C_MASTER_COUNT=1} \
    {ONCHIP_16_SESSION_HISTORY=ABSENT} {CURRENT_SESSION_SNAPSHOT_WORDS=8} \
    {HOST_OWNED_SESSION_HISTORY=PRESENT} {TRANSPORT_ABI_CHANGED=NO} \
    {PRODUCT_MMIO_CHANGED=NO} {VDO_XDC_CHANGED=NO} {BLACK_BOX_COUNT=0}] \
    $family_lines]
  return PASS
}

set design_open 0
set operation_code [catch {
  foreach variable {task_root source_root r1_report_root routed_dcp semantic_summary \
      semantic_csv semantic_json semantic_sidecar semantic_alias_csv \
      semantic_alias_json semantic_alias_sidecar extraction_root extraction_receipt \
      signoff_root artifact_root signed_dcp bitstream} {
    set $variable [file normalize [set $variable]]
  }
  if {![file isdirectory $task_root] || ![file isdirectory $source_root] ||
      ![file isdirectory $r1_report_root] || ![file isfile $routed_dcp] ||
      ![path_is_within $signoff_root $task_root] ||
      ![path_is_within $artifact_root $task_root]} {
    error "fixed R2 task/source/DCP path authority mismatch"
  }
  if {[file exists $signoff_root]} {
    if {[llength [glob -nocomplain -directory $signoff_root *]] != 0} {
      error "fresh signoff output directory is not empty: $signoff_root"
    }
  } else {
    file mkdir $signoff_root
  }
  file mkdir $artifact_root
  if {[file exists $signed_dcp] || [file exists $bitstream] ||
      [llength [glob -nocomplain -directory $artifact_root *.ltx]] != 0} {
    error "R2 signed-DCP/bitstream/LTX output authority is not fresh"
  }

  set vivado_version [version -short]
  if {$vivado_version ne $expected_vivado_version} {
    error "Vivado version mismatch: expected=$expected_vivado_version actual=$vivado_version"
  }
  set source_branch [string trim [exec git --no-optional-locks -C $source_root branch --show-current]]
  set source_commit [string trim [exec git --no-optional-locks -C $source_root rev-parse HEAD]]
  set source_tree [string trim [exec git --no-optional-locks -C $source_root rev-parse {HEAD^{tree}}]]
  set source_status [string trim [exec git --no-optional-locks -C $source_root status --short]]
  if {$source_branch ne $expected_source_branch || $source_commit ne $expected_source_commit ||
      $source_tree ne $expected_source_tree || $source_status ne ""} {
    error "NVP_DIAG1_R2_SOURCE_AUTHORITY_CONTRADICTION"
  }

  set original_dcp_size [file size $routed_dcp]
  set original_dcp_mtime [file mtime $routed_dcp]
  set original_dcp_sha [sha256_file $routed_dcp]
  if {$original_dcp_sha ne $expected_dcp_sha} {
    error "NVP_DIAG1_R2_EXACT_ROUTED_DCP_UNAVAILABLE: expected=$expected_dcp_sha actual=$original_dcp_sha"
  }
  set semantic [verify_semantic_inputs]
  set active_bus_skew_pass [verify_inherited_active_bus_skew $signoff_root]

  open_checkpoint $routed_dcp
  set design_open 1
  if {[get_property PART [current_design]] ne $expected_part ||
      [get_property TOP [current_design]] ne $expected_top} {
    error "exact routed DCP part/top mismatch"
  }
  if {![report_route_status -boolean_check ROUTED_FULLY] ||
      [report_route_status -boolean_check ERRORS_IN_ROUTES] ||
      [llength [report_route_status -return_nets -route_type UNROUTED]] != 0 ||
      [llength [report_route_status -return_nets -route_type PARTIAL]] != 0} {
    error "exact routed DCP is not fully routed"
  }
  set signatures_pre [capture_signatures $signoff_root PRE_SIGNOFF]

  set promoted_pass [run_promoted_replacements $signoff_root]
  set structural [run_structural_cdc $signoff_root]
  set cdc [run_cdc_gate $signoff_root $expected_cdc1_sha]
  set timing [run_timing_gate $signoff_root]
  run_drc_methodology_gates $signoff_root
  set resources [run_resource_gate $signoff_root]
  run_diagnostic_identity_gate $signoff_root
  if {$active_bus_skew_pass != 11 || $promoted_pass != 17 || $structural ne "PASS"} {
    error "governed Group 1-17 aggregate did not pass"
  }

  set signatures_post [capture_signatures $signoff_root POST_SIGNOFF]
  require_same_signatures $signatures_pre $signatures_post REPORT_ONLY_SIGNOFF
  if {[sha256_file $routed_dcp] ne $original_dcp_sha ||
      [file size $routed_dcp] != $original_dcp_size ||
      [file mtime $routed_dcp] != $original_dcp_mtime} {
    error "original routed DCP changed before authorized output stage"
  }

  write_checkpoint $signed_dcp
  if {![file isfile $signed_dcp] || [file size $signed_dcp] == 0} {
    error "signed-off R2 routed DCP was not created"
  }
  set signed_dcp_sha [sha256_file $signed_dcp]
  close_design
  set design_open 0

  open_checkpoint $signed_dcp
  set design_open 1
  if {[get_property PART [current_design]] ne $expected_part ||
      [get_property TOP [current_design]] ne $expected_top ||
      ![report_route_status -boolean_check ROUTED_FULLY] ||
      [report_route_status -boolean_check ERRORS_IN_ROUTES] ||
      [llength [report_route_status -return_nets -route_type UNROUTED]] != 0 ||
      [llength [report_route_status -return_nets -route_type PARTIAL]] != 0} {
    error "fresh signed-off checkpoint identity/route gate failed"
  }
  set signatures_signed [capture_signatures $signoff_root SIGNED_DCP_REOPEN]
  require_same_signatures $signatures_pre $signatures_signed SIGNED_DCP_REOPEN

  write_bitstream $bitstream
  if {![file isfile $bitstream] || [file size $bitstream] == 0} {
    error "R2 diagnostic bitstream was not generated"
  }
  set bitstream_size [file size $bitstream]
  set bitstream_sha [sha256_file $bitstream]
  if {[llength [glob -nocomplain -directory $artifact_root *.ltx]] != 0} {
    error "unexpected LTX was created"
  }
  set signatures_after_bit [capture_signatures $signoff_root AFTER_BITSTREAM]
  require_same_signatures $signatures_pre $signatures_after_bit AFTER_BITSTREAM
  close_design
  set design_open 0

  if {[sha256_file $routed_dcp] ne $original_dcp_sha ||
      [file size $routed_dcp] != $original_dcp_size ||
      [file mtime $routed_dcp] != $original_dcp_mtime} {
    error "original routed DCP changed during sign-off/output generation"
  }
  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R2_SIGNED_OFF_DCP_MANIFEST.txt] [list \
    {RESULT=PASS} "ORIGINAL_ROUTED_DCP=$routed_dcp" \
    "ORIGINAL_ROUTED_DCP_SHA256=$original_dcp_sha" \
    "SIGNED_OFF_ROUTED_DCP=$signed_dcp" "SIGNED_OFF_ROUTED_DCP_SHA256=$signed_dcp_sha" \
    "SIGNED_OFF_ROUTED_DCP_SIZE=[file size $signed_dcp]" \
    "ROUTE_STATUS_SIGNATURE_SHA256=[dict get $signatures_pre ROUTE_STATUS_SHA256]" \
    "CLOCK_SIGNATURE_SHA256=[dict get $signatures_pre CLOCK_SHA256]" \
    "NETLIST_SIGNATURE_SHA256=[dict get $signatures_pre NETLIST_SHA256]" \
    {ROUTE_STATUS_SIGNATURE_UNCHANGED=YES} \
    {ROUTE_IDENTITY_BASIS=EXACT_INPUT_DCP_SHA256_PLUS_COMPACT_ROUTE_STATUS_AND_PLACEMENT_SIGNATURES} \
    {CLOCK_SIGNATURE_UNCHANGED=YES} \
    {NETLIST_SIGNATURE_UNCHANGED=YES} {ORIGINAL_DCP_UNCHANGED=YES}]
  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R2_BITSTREAM_MANIFEST.txt] [list \
    {RESULT=PASS} "BITSTREAM=$bitstream" "BITSTREAM_SIZE=$bitstream_size" \
    "BITSTREAM_SHA256=$bitstream_sha" "SIGNED_OFF_DCP_SHA256=$signed_dcp_sha" \
    "SOURCE_COMMIT=$source_commit" "SOURCE_TREE=$source_tree" \
    {BUILD_FLAGS=32'h00000402} {DIAG_MAGIC=0x4E565034} \
    {DIAG_VERSION=0x00010001} \
    "SEMANTIC_CDC_MANIFEST_CSV_SHA256=[dict get $semantic CSV_SHA256]" \
    "SEMANTIC_CDC_MANIFEST_JSON_SHA256=[dict get $semantic JSON_SHA256]" \
    "PHYSICAL_CDC_1_MANIFEST_SHA256=[dict get $cdc CDC1_SHA256]" \
    {CANDIDATE_CLASSIFICATION=G2B_NVP_VIDEO_DIAG1_R2_CDC_RECONCILED_CANDIDATE} \
    {WRITE_CHECKPOINT_COUNT=1} {WRITE_BITSTREAM_COUNT=1} {LTX=NONE_EXPECTED}]
  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R2_SIGNOFF_RESULT.txt] [list \
    {RESULT=PASS} {CDC_DISPOSITION=PASS_PROFILE_SPECIFIC_SEMANTIC_MANIFEST} \
    {ACTIVE_BUS_SKEW_GROUPS=11/11} {ACTIVE_BUS_SKEW_VIOLATIONS=0} \
    {PROMOTED_REPLACEMENT_CHECKS=17/17} {STRUCTURAL_CDC=PASS} \
    {ALL_GOVERNED_GROUPS_1_TO_17=PASS} {FULLY_ROUTED=YES} \
    "WNS=[format %.3f [dict get $timing WNS]]" {TNS=0.000} \
    "WHS=[format %.3f [dict get $timing WHS]]" {THS=0.000} \
    {DRC=PASS} {METHODOLOGY=PASS} {RESOURCE_GATE=PASS} \
    "LUT_USED=[dict get $resources LUT]" "FF_USED=[dict get $resources FF]" \
    "BRAM_USED=[dict get $resources BRAM]" "DSP_USED=[dict get $resources DSP]" \
    "SIGNED_OFF_DCP=$signed_dcp" "SIGNED_OFF_DCP_SHA256=$signed_dcp_sha" \
    "BITSTREAM=$bitstream" "BITSTREAM_SHA256=$bitstream_sha" \
    {SOURCE_CHANGED=NO} {RTL_CHANGED=NO} {XDC_CHANGED=NO} {IP_CHANGED=NO} \
    {CONSTRAINT_MUTATION_COMMANDS=0} {IMPLEMENTATION_COMMANDS=0} \
    {WRITE_CHECKPOINT_COUNT=1} {WRITE_BITSTREAM_COUNT=1} {WRITE_DEBUG_PROBES_COUNT=0}]
} operation_message operation_options]

if {$operation_code != 0} {
  if {$design_open} { catch {close_design} }
  catch {
    file mkdir $signoff_root
    write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R2_SIGNOFF_FAILURE.txt] [list \
      {RESULT=FAIL} "ERROR=[single_line $operation_message]"]
  }
  puts stderr "G2B_NVP_VIDEO_DIAG1_R2_SIGNOFF_FAIL: $operation_message"
  if {[dict exists $operation_options -errorinfo]} {
    puts stderr [dict get $operation_options -errorinfo]
  }
  exit 1
}

puts "G2B_NVP_VIDEO_DIAG1_R2_SIGNOFF_PASS"
exit 0
