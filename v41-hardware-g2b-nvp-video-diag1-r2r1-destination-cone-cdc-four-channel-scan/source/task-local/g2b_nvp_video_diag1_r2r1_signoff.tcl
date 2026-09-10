# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R1
# Exact routed-DCP post-reconciliation sign-off and one-bitstream harness.
#
# The input checkpoint and R1 evidence are immutable inputs.  The only design
# outputs authorized here are one fresh R2R1 signed-off checkpoint followed by
# one fresh R2R1 .bit file.  No source, IP, implementation, timing-constraint,
# message-configuration, or debug-probe mutation is performed.

if {$argc != 0} {
  puts stderr "usage: g2b_nvp_video_diag1_r2r1_signoff.tcl"
  exit 2
}

set task_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z}
set recovery_harness [file join $task_root scripts g2b_nvp_video_diag1_r2r1_signoff.tcl]
set source_root {C:/FPGA/V41_G2B_NVP_VIDEO_DIAG1}
set r1_report_root {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full}
set routed_dcp [file join $r1_report_root G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp]
set product_routed_dcp {C:/FPGA/G2B_BT656_FIX1_R1_20260909T090813Z/artifacts/offline-candidate/G2B_BT656_FIX1_R1_SIGNED_OFF_ROUTED.dcp}
set product_extraction_root [file join $task_root cone-proof product]
set diagnostic_extraction_root [file join $task_root cone-proof diagnostic]
set product_extraction_receipt [file join $product_extraction_root EXTRACTION_RECEIPT.txt]
set diagnostic_extraction_receipt [file join $diagnostic_extraction_root EXTRACTION_RECEIPT.txt]
set support_csv [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_SUPPORT.csv]
set support_evidence_manifest [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_EVIDENCE_SHA256.txt]
set semantic_summary [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_RECONCILIATION_RECEIPT.txt]
# Phase I names the canonical manifest without the G2B prefix, while the
# evidence list requires the prefixed names.  Both spellings are mandatory and
# must be byte-identical; this preserves the literal contract without silently
# choosing one side of the prompt's naming inconsistency.
set semantic_csv [file join $task_root cdc NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.csv]
set semantic_json [file join $task_root cdc NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.json]
set semantic_sidecar [file join $task_root cdc NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.sha256]
set semantic_alias_csv [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.csv]
set semantic_alias_json [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.json]
set semantic_alias_sidecar [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.sha256]
set source_identity_report [file join $task_root reports G2B_NVP_VIDEO_DIAG1_R2R1_G2B_FUNCTIONAL_BODY_IDENTITY.md]
set source_tap_report [file join $task_root reports G2B_NVP_VIDEO_DIAG1_R2R1_DIAGNOSTIC_TAP_NONINTERFERENCE.md]
set signoff_root [file join $task_root signoff]
set artifact_root [file join $task_root artifacts]
set signed_dcp [file join $artifact_root G2B_NVP_VIDEO_DIAG1_R2R1_SIGNED_OFF_ROUTED.dcp]
set bitstream [file join $artifact_root G2B_NVP_VIDEO_DIAG1_R2R1_FOUR_CHANNEL_SCAN.bit]

set expected_source_branch {diag/v41-g2b-nvp-video-scan}
set expected_source_commit {fcab95726761a0666a67e31c283dbdfb9e775074}
set expected_source_tree {bbf1a5fee70a2eb68bb96305ed10934a1559ca6a}
set expected_product_dcp_sha {5284A91C8D106A14E35A4DCB7A33EC4527A325D3D0F4F9333E6BB73C57255A82}
set expected_dcp_sha {45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F}
set expected_cdc1_sha {BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99}
set expected_product_cdc1_sha {A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D}
set expected_bus_skew_receipt_sha {86C33DA963DF82434EB1DB21F2BA873A3EE60B6A1BB6BD12B1EA563175D1236A}
set expected_retired_bus_skew_receipt_sha {4DCD7C3EA406285B0B6A388C3E0EDC39E4D3A3A286AD14B05CBC858DF75408F1}
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

proc canonicalize_xdc {input_path output_path} {
  set canonical_lines [list]
  foreach line [split [read_text $input_path] "\n"] {
    set line [string trim $line]
    if {$line eq "" || [string match {#*} $line]} { continue }
    regsub -all {[ \t]+} $line { } line
    lappend canonical_lines $line
  }
  # XDC is Tcl: command ordering and current_instance scope remain semantic.
  # Normalize comments/blank space only.  In particular this removes the
  # output-path-specific "Command Used" header written by write_xdc.
  write_lines $output_path $canonical_lines
  return [sha256_file $output_path]
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

proc parse_csv_line {line} {
  set fields [list]
  set field ""
  set quoted 0
  set length [string length $line]
  for {set index 0} {$index < $length} {incr index} {
    set character [string index $line $index]
    if {$quoted} {
      if {$character eq {"}} {
        if {$index + 1 < $length && [string index $line [expr {$index + 1}]] eq {"}} {
          append field {"}
          incr index
        } else {
          set quoted 0
        }
      } else {
        append field $character
      }
      continue
    }
    if {$character eq ","} {
      lappend fields $field
      set field ""
    } elseif {$character eq {"}} {
      if {$field ne ""} { error "quote begins inside an unquoted CSV field" }
      set quoted 1
    } else {
      append field $character
    }
  }
  if {$quoted} { error "unterminated quoted CSV field" }
  lappend fields $field
  return $fields
}

proc read_csv_records {path} {
  if {![file isfile $path] || [file size $path] == 0} {
    error "required CSV is missing or empty: $path"
  }
  set records [list]
  foreach raw [split [read_text $path] "\n"] {
    set line [string trimright $raw "\r"]
    if {$line eq ""} { continue }
    lappend records [parse_csv_line $line]
  }
  if {[llength $records] == 0} { error "CSV contains no records: $path" }
  return $records
}

proc require_text {path literal label} {
  if {![file isfile $path] || [file size $path] == 0} {
    error "$label is missing or empty: $path"
  }
  if {[string first $literal [read_text $path]] < 0} {
    error "$label does not contain required literal: $literal"
  }
}

proc count_command_lines {text command} {
  set count 0
  foreach line [split $text "\n"] {
    if {[regexp [format {^[ \t]*%s([ \t]|$)} $command] $line]} { incr count }
  }
  return $count
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
  set constraint_path [file join $root "TIMING_CONSTRAINT_SIGNATURE_${tag}.xdc"]
  set constraint_canonical_path [file join $root "TIMING_CONSTRAINT_SIGNATURE_${tag}_CANONICAL.xdc"]

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

  write_xdc -exclude_physical -force $constraint_path
  set constraint_text [read_text $constraint_path]
  set constraint_raw_sha [sha256_file $constraint_path]
  set constraint_canonical_sha [canonicalize_xdc $constraint_path $constraint_canonical_path]
  set bus_skew_count [count_command_lines $constraint_text set_bus_skew]
  set max_delay_count [count_command_lines $constraint_text set_max_delay]
  set false_path_count [count_command_lines $constraint_text set_false_path]
  set clock_group_count [count_command_lines $constraint_text set_clock_groups]
  if {$bus_skew_count != 11 || $max_delay_count != 26 ||
      $false_path_count != 30 || $clock_group_count != 1} {
    error "full timing-view command-count drift: set_bus_skew=$bus_skew_count set_max_delay=$max_delay_count set_false_path=$false_path_count set_clock_groups=$clock_group_count"
  }

  # Do not serialize ROUTE or FIXED_ROUTE here.  A single global-constant net
  # in this design has a multi-gigabyte textual ROUTE representation.  Exact
  # route provenance is anchored by the immutable input-DCP SHA-256 and the
  # per-net pin/port/PIP signatures above.
  # The authoritative summary counts two nets that the ROUTED object selector
  # omits.  Parse the same route-status summary used by the accepted R1 gate,
  # and combine it with the independent boolean/error/UNROUTED/PARTIAL checks.
  set route_report [report_route_status -return_string]
  if {![regexp {# of routable nets[. ]*: *([0-9]+)} $route_report -> routable_count] ||
      ![regexp {# of fully routed nets[. ]*: *([0-9]+)} $route_report -> fully_routed_count]} {
    error "authoritative route-status summary counts could not be parsed"
  }
  set unrouted_count [llength \
    [report_route_status -return_nets -route_type UNROUTED]]
  set partial_count [llength \
    [report_route_status -return_nets -route_type PARTIAL]]
  set routed_fully [report_route_status -boolean_check ROUTED_FULLY]
  set errors_in_routes [report_route_status -boolean_check ERRORS_IN_ROUTES]
  if {!$routed_fully || $errors_in_routes || $routable_count != 36180 ||
      $fully_routed_count != 36180 || $unrouted_count != 0 || $partial_count != 0} {
    error "compact route-status signature found a non-fully-routed design"
  }

  write_text $route_path [join [list \
    {SCHEMA=G2B_NVP_VIDEO_DIAG1_R2R1_COMPACT_ROUTE_STATUS_SIGNATURE_V1} \
    "ROUTABLE_NETS=$routable_count" \
    "FULLY_ROUTED_NETS=$fully_routed_count" \
    "UNROUTED_NETS=$unrouted_count" \
    "PARTIALLY_ROUTED_NETS=$partial_count" \
    "ROUTED_FULLY=$routed_fully" \
    "ERRORS_IN_ROUTES=$errors_in_routes" \
    {RAW_REPORT_BEGIN} $route_report {RAW_REPORT_END}] "\n"]

  return [dict create \
    CLOCK_SHA256 [sha256_file $clock_path] CLOCK_COUNT [llength $clocks] \
    NETLIST_SHA256 [sha256_file $netlist_path] CELL_COUNT $cell_count NET_COUNT $net_count \
    CONSTRAINT_RAW_SHA256 $constraint_raw_sha \
    CONSTRAINT_SHA256 $constraint_canonical_sha \
    ACTIVE_BUS_SKEW_COUNT $bus_skew_count MAX_DELAY_COUNT $max_delay_count \
    FALSE_PATH_COUNT $false_path_count CLOCK_GROUP_COUNT $clock_group_count \
    ROUTE_STATUS_SHA256 [sha256_file $route_path] \
    ROUTABLE_NET_COUNT $routable_count FULLY_ROUTED_NET_COUNT $fully_routed_count \
    UNROUTED_NET_COUNT $unrouted_count PARTIAL_NET_COUNT $partial_count \
    ROUTED_FULLY $routed_fully ERRORS_IN_ROUTES $errors_in_routes]
}

proc require_same_signatures {expected actual label} {
  foreach key {CLOCK_SHA256 CLOCK_COUNT NETLIST_SHA256 CELL_COUNT NET_COUNT CONSTRAINT_SHA256 ACTIVE_BUS_SKEW_COUNT MAX_DELAY_COUNT FALSE_PATH_COUNT CLOCK_GROUP_COUNT ROUTE_STATUS_SHA256 ROUTABLE_NET_COUNT FULLY_ROUTED_NET_COUNT UNROUTED_NET_COUNT PARTIAL_NET_COUNT ROUTED_FULLY ERRORS_IN_ROUTES} {
    if {[dict get $expected $key] ne [dict get $actual $key]} {
      error "$label signature mismatch for $key: expected=[dict get $expected $key] actual=[dict get $actual $key]"
    }
  }
}

proc resolve_task_evidence {relative label} {
  global task_root
  if {$relative eq "" || [file pathtype $relative] ne "relative" ||
      [string first "\\" $relative] >= 0} {
    error "$label must be a nonempty task-relative forward-slash path: $relative"
  }
  set path [file normalize [file join $task_root {*}[split $relative /]]]
  if {![path_is_within $path $task_root] || ![file isfile $path] || [file size $path] == 0} {
    error "$label does not resolve to a nonempty task-local file: $relative"
  }
  return $path
}

proc verify_tap_fanout_csv {path profile} {
  set records [read_csv_records $path]
  set expected_header [list Tap PinCount Direction NetCount AllFanoutEndpointCellCount FunctionalG2BEndpointCount DiagnosticEndpointCount Disposition]
  if {[lindex $records 0] ne $expected_header || [llength $records] != 5} {
    error "$profile diagnostic-tap CSV schema/count mismatch"
  }
  set expected_taps [list diag_stored_enable diag_c2h_active diag_ring_empty diag_ring_full]
  set seen [list]
  foreach row [lrange $records 1 end] {
    if {[llength $row] != 8} { error "$profile diagnostic-tap CSV row width mismatch" }
    lassign $row tap pin_count direction net_count endpoint_count functional_count diagnostic_count disposition
    if {[lsearch -exact $expected_taps $tap] < 0 || [lsearch -exact $seen $tap] >= 0} {
      error "$profile diagnostic-tap CSV has an unexpected/duplicate tap: $tap"
    }
    lappend seen $tap
    if {$profile eq "product"} {
      if {$pin_count ne "0" || $direction ne "ABSENT" || $net_count ne "0" ||
          $endpoint_count ne "0" || $functional_count ne "0" ||
          $diagnostic_count ne "0" || $disposition ne "PRODUCT_ABSENT_EXPECTED"} {
        error "PRODUCT tap absence proof failed for $tap"
      }
    } else {
      set expected_pin_count [expr {$tap eq "diag_c2h_active" ? 7 : 1}]
      if {$pin_count ne "$expected_pin_count" || $direction ne "OUT" || $functional_count ne "0" ||
          ![string is integer -strict $net_count] || $net_count < 1 ||
          ![string is integer -strict $endpoint_count] || $endpoint_count < 1 ||
          ![string is integer -strict $diagnostic_count] || $diagnostic_count < 1 ||
          $disposition ne "PASS_SOURCE_DRIVER_DELTA_DIAGNOSTIC_ONLY_PORT_NAMES_OPTIMIZED"} {
        error "diagnostic routed-tap noninterference failed for $tap"
      }
    }
  }
  if {[lsort -dictionary $seen] ne [lsort -dictionary $expected_taps]} {
    error "$profile diagnostic-tap set mismatch"
  }
  return PASS
}

proc verify_cone_extraction {profile root receipt_path dcp expected_dcp_sha expected_manifest_sha} {
  foreach leaf {EXTRACTION_RECEIPT.txt CDC.rpt CDC_1_PHYSICAL_MANIFEST.txt DESTINATION_STARTPOINT_INVENTORY.csv DESTINATION_EXTRACTION_SUMMARY.csv DIAGNOSTIC_TAP_FANOUT.csv} {
    set path [file join $root $leaf]
    if {![file isfile $path] || [file size $path] == 0} {
      error "$profile cone extraction artifact is missing or empty: $path"
    }
  }
  if {[sha256_file $dcp] ne $expected_dcp_sha} {
    error "$profile exact DCP hash changed before signoff"
  }
  set values [read_key_values $receipt_path]
  foreach requirement [list [list RESULT PASS] [list PROFILE $profile] \
      [list MODE EXACT_ROUTED_DCP_REPORT_ONLY] [list VIVADO_VERSION 2025.2] \
      [list PART xc7a35tcsg325-2] [list TOP ahd_capture_top_xdma] \
      [list DCP_SHA256 $expected_dcp_sha] [list CDC_1_COUNT 423] \
      [list CDC_1_PHYSICAL_MANIFEST_SHA256 $expected_manifest_sha] \
      [list CHANGED_DESTINATIONS_PROCESSED 522] [list CONSTRAINTS_CHANGED NO] \
      [list IMPLEMENTATION_CHANGED NO] [list DCP_CHANGED NO] \
      [list BITSTREAM_WRITTEN NO]] {
    lassign $requirement key value
    require_value $values $key $value "[string toupper $profile]_CONE_EXTRACTION"
  }
  if {[path_key [dict get $values DCP]] ne [path_key $dcp]} {
    error "$profile cone extraction receipt points to another DCP"
  }
  set manifest [file join $root CDC_1_PHYSICAL_MANIFEST.txt]
  set inventory [file join $root DESTINATION_STARTPOINT_INVENTORY.csv]
  set summary [file join $root DESTINATION_EXTRACTION_SUMMARY.csv]
  set taps [file join $root DIAGNOSTIC_TAP_FANOUT.csv]
  if {[sha256_file $manifest] ne $expected_manifest_sha ||
      [sha256_file $inventory] ne [dict get $values STARTPOINT_INVENTORY_SHA256] ||
      [sha256_file $summary] ne [dict get $values EXTRACTION_SUMMARY_SHA256] ||
      [sha256_file $taps] ne [dict get $values TAP_FANOUT_SHA256]} {
    error "$profile cone extraction artifact hash mismatch"
  }
  if {$profile eq "diagnostic"} {
    set tap_detail [file join $root DIAGNOSTIC_TAP_FANOUT_DETAIL.txt]
    if {![file isfile $tap_detail] || [file size $tap_detail] == 0 ||
        [sha256_file $tap_detail] ne [dict get $values TAP_FANOUT_DETAIL_SHA256]} {
      error "diagnostic tap-detail artifact/hash mismatch"
    }
    foreach requirement [list \
        [list TAP_PROOF_METHOD EXACT_SOURCE_DRIVER_ALL_FANOUT_TWO_DCP_DELTA] \
        [list TAP_BOUNDARY_NAME_DISPOSITION FORMAL_PORT_NAMES_OPTIMIZED_SOURCE_ANCHORS_USED] \
        [list PRODUCT_DCP_SHA256_FOR_TAP_DELTA 5284A91C8D106A14E35A4DCB7A33EC4527A325D3D0F4F9333E6BB73C57255A82]] {
      lassign $requirement key value
      require_value $values $key $value DIAGNOSTIC_TAP_DELTA
    }
    foreach requirement {{CDC_ROWS 1337} {CRITICAL_TOTAL 427} {WARNING_TOTAL 874} {INFO_TOTAL 36}} {
      lassign $requirement key value
      require_value $values $key $value DIAGNOSTIC_CONE_EXTRACTION
    }
  }
  verify_tap_fanout_csv $taps $profile
  return [dict create \
    RECEIPT_SHA256 [sha256_file $receipt_path] \
    RAW_CDC_SHA256 [sha256_file [file join $root CDC.rpt]] \
    CDC1_SHA256 [sha256_file $manifest] \
    INVENTORY_SHA256 [sha256_file $inventory] \
    SUMMARY_SHA256 [sha256_file $summary] TAP_SHA256 [sha256_file $taps]]
}

proc verify_support_csv {path evidence_manifest} {
  set records [read_csv_records $path]
  set expected_header [list RowID Rule Severity DestinationPin DestinationCell DestinationClock ProductReportRepresentative DiagnosticReportRepresentative ProductPhysicalStartpoints DiagnosticPhysicalStartpoints ProductSemanticFamilies DiagnosticSemanticFamilies NewFamilies MissingFamilies ProductGoverningTokens DiagnosticGoverningTokens ProtocolDrift ExceptionDrift BarrierDrift ReplacementGroupDrift ProofClass Disposition EvidencePath]
  if {[lindex $records 0] ne $expected_header || [llength $records] != 523} {
    error "destination-cone support CSV schema/count mismatch"
  }
  set proof_counts [dict create]
  set severity_counts [dict create]
  set same_family_critical_counts [dict create RESET_COMMIT 0 OWNERSHIP 0]
  set row_proofs [dict create]
  set exact_cross [list CDC1-CHG-0286 CDC1-CHG-0288 CDC1-CHG-0289 CDC1-CHG-0290 CDC1-CHG-0300 CDC1-CHG-0301 CDC1-CHG-0302]
  set exact_composite [list WARN-CHG-0218 WARN-CHG-0219 WARN-CHG-0220]
  set exact_cross_destinations [dict create \
    CDC1-CHG-0286 {G2B_ONECH_C2H/enable_applied_source_reg/D} \
    CDC1-CHG-0288 {G2B_ONECH_C2H/slot_state_source_reg[0][0]/D} \
    CDC1-CHG-0289 {G2B_ONECH_C2H/slot_state_source_reg[0][1]/D} \
    CDC1-CHG-0290 {G2B_ONECH_C2H/slot_state_source_reg[0][2]/D} \
    CDC1-CHG-0300 {G2B_ONECH_C2H/source_ownership_fatal_deferred_reg/D} \
    CDC1-CHG-0301 {G2B_ONECH_C2H/source_ownership_fatal_event_reg/D} \
    CDC1-CHG-0302 {G2B_ONECH_C2H/source_ownership_fatal_reg/D}]
  set exact_composite_destinations [dict create \
    WARN-CHG-0218 {G2B_ONECH_C2H/reset_abandoned_hold_source_reg[0]/D} \
    WARN-CHG-0219 {G2B_ONECH_C2H/reset_abandoned_hold_source_reg[1]/D} \
    WARN-CHG-0220 {G2B_ONECH_C2H/reset_abandoned_hold_source_reg[2]/D}]
  set expected_evidence_lines [list]
  foreach row [lrange $records 1 end] {
    if {[llength $row] != 23} { error "destination-cone support row width mismatch" }
    set row_id [lindex $row 0]
    set rule [lindex $row 1]
    set severity [lindex $row 2]
    set product_startpoints [lindex $row 8]
    set diagnostic_startpoints [lindex $row 9]
    set product_families [lindex $row 10]
    set diagnostic_families [lindex $row 11]
    set new_families [lindex $row 12]
    set missing_families [lindex $row 13]
    set product_tokens [lindex $row 14]
    set diagnostic_tokens [lindex $row 15]
    set proof [lindex $row 20]
    set disposition [lindex $row 21]
    set evidence [lindex $row 22]
    if {[dict exists $row_proofs $row_id]} { error "duplicate destination-cone RowID: $row_id" }
    if {$severity ni {Critical Warning} || $rule ni {CDC-1 CDC-15} ||
        $product_startpoints eq "" || $product_startpoints eq "\[\]" ||
        $diagnostic_startpoints eq "" || $diagnostic_startpoints eq "\[\]" ||
        $product_families eq "" || $product_families eq "\[\]" ||
        $diagnostic_families eq "" || $diagnostic_families eq "\[\]" ||
        $product_tokens eq "" || $product_tokens eq "\[\]" ||
        $diagnostic_tokens eq "" || $diagnostic_tokens eq "\[\]" ||
        $new_families ne "\[\]" || $missing_families ne "\[\]" ||
        [lindex $row 16] ne "0" || [lindex $row 17] ne "0" ||
        [lindex $row 18] ne "0" || [lindex $row 19] ne "0" ||
        $disposition ne "PASS"} {
      error "destination-cone support row is not a complete zero-drift PASS: $row_id"
    }
    if {$product_families ne $diagnostic_families ||
        $product_tokens ne $diagnostic_tokens} {
      error "destination-cone semantic-family/governing-token sets differ: $row_id"
    }
    if {$proof ni {SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE COMPOSITE_RELEASE_TOKEN_EQUIVALENCE}} {
      error "unauthorized destination-cone proof class: $row_id $proof"
    }
    if {$proof eq "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE" && [lsearch -exact $exact_cross $row_id] < 0} {
      error "destination-cone proof class applied to an unexpected row: $row_id"
    }
    if {$proof eq "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE" && [lsearch -exact $exact_composite $row_id] < 0} {
      error "composite release-token proof class applied to an unexpected row: $row_id"
    }
    if {$proof eq "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE"} {
      if {[lindex $row 3] ne [dict get $exact_cross_destinations $row_id] ||
          [string first {release_epoch_axi_reg[0][9]/C} [lindex $row 6]] < 0 ||
          [string first {axis_slot_reg[1]/C} [lindex $row 7]] < 0 ||
          [string first {OWNERSHIP_STABLE_PAYLOAD} $product_families] < 0 ||
          [string first {RELEASE_TOKEN_STABLE_PAYLOAD} $product_families] < 0} {
        error "exact R2 cross-family representative/destination contract failed: $row_id"
      }
    }
    if {$proof eq "SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE" && $severity eq "Critical"} {
      set has_reset [expr {[string first {RESET_COMMIT_STABLE_PAYLOAD} $product_families] >= 0}]
      set has_ownership [expr {[string first {OWNERSHIP_STABLE_PAYLOAD} $product_families] >= 0}]
      if {$has_reset == $has_ownership} {
        error "critical same-family row is not uniquely reset-commit or ownership: $row_id"
      }
      dict incr same_family_critical_counts [expr {$has_reset ? {RESET_COMMIT} : {OWNERSHIP}}]
    }
    if {$proof eq "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE"} {
      if {[lindex $row 3] ne [dict get $exact_composite_destinations $row_id] ||
          [string first {release_generation_axi_reg} [lindex $row 6]] < 0 ||
          [string first {release_epoch_axi_reg} [lindex $row 7]] < 0 ||
          [string first {RELEASE_GENERATION_FIELD} $product_families] < 0 ||
          [string first {RELEASE_EPOCH_FIELD} $product_families] < 0 ||
          [string first {RELEASE_TOKEN_STABLE_PAYLOAD} $product_families] < 0 ||
          [string first {OWNERSHIP_STABLE_PAYLOAD} $product_families] >= 0} {
        error "composite release-token child/parent separation failed: $row_id"
      }
      foreach slot {0 1 2 3} {
        if {[string first "\"Slot\":\"$slot\"" $product_families] < 0} {
          error "composite release-token slot $slot is absent: $row_id"
        }
      }
      if {$product_tokens ne {["transport_req_toggle_axi_to_transport_req_sync2_source"]}} {
        error "composite transport-request governing token is not exact: $row_id"
      }
    }
    set evidence_path [resolve_task_evidence $evidence "support evidence for $row_id"]
    lappend expected_evidence_lines "$row_id=$evidence|[sha256_file $evidence_path]"
    dict set row_proofs $row_id $proof
    dict incr proof_counts $proof
    dict incr severity_counts $severity
  }
  foreach requirement [list \
      [list SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE 512] \
      [list DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE 7] \
      [list COMPOSITE_RELEASE_TOKEN_EQUIVALENCE 3]] {
    lassign $requirement proof expected
    set actual [expr {[dict exists $proof_counts $proof] ? [dict get $proof_counts $proof] : 0}]
    if {$actual != $expected} { error "destination-cone proof-class count mismatch for $proof: $actual/$expected" }
  }
  if {[dict size $proof_counts] != 3 || [dict get $severity_counts Critical] != 302 ||
      [dict get $severity_counts Warning] != 220 || [dict size $severity_counts] != 2} {
    error "destination-cone support severity/proof partition mismatch"
  }
  if {[dict get $same_family_critical_counts RESET_COMMIT] != 285 ||
      [dict get $same_family_critical_counts OWNERSHIP] != 10} {
    error "critical same-family family partition mismatch: reset_commit=[dict get $same_family_critical_counts RESET_COMMIT]/285 ownership=[dict get $same_family_critical_counts OWNERSHIP]/10"
  }
  foreach row_id [concat $exact_cross $exact_composite] {
    if {![dict exists $row_proofs $row_id]} { error "required destination-cone row is absent: $row_id" }
  }
  foreach row_id $exact_cross {
    if {[dict get $row_proofs $row_id] ne "DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE"} {
      error "required cross-family row has the wrong proof class: $row_id"
    }
  }
  foreach row_id $exact_composite {
    if {[dict get $row_proofs $row_id] ne "COMPOSITE_RELEASE_TOKEN_EQUIVALENCE"} {
      error "required composite-token row has the wrong proof class: $row_id"
    }
  }
  if {![file isfile $evidence_manifest] || [file size $evidence_manifest] == 0} {
    error "destination-cone evidence hash manifest is missing or empty: $evidence_manifest"
  }
  set actual_evidence_lines [list]
  foreach raw [split [string trimright [read_text $evidence_manifest] "\r\n"] "\n"] {
    lappend actual_evidence_lines [string trimright $raw "\r"]
  }
  if {$actual_evidence_lines ne $expected_evidence_lines} {
    error "destination-cone evidence hash manifest does not bind all 522 support rows in contract order"
  }
  return [dict create ROW_COUNT 522 ROW_PROOFS $row_proofs SHA256 [sha256_file $path] \
    EVIDENCE_SHA256 [sha256_file $evidence_manifest]]
}

proc verify_manifest_csv {path support} {
  set records [read_csv_records $path]
  set expected_header [list RowID ProductPhysicalSource DiagnosticPhysicalSource DestinationEndpoint Rule Severity SourceClock DestinationClock Exception SemanticFamilyOrSupportSet GoverningToken Protocol EarliestUseBarrier ReplacementGroup ProofClass RowDisposition EvidencePath]
  if {[lindex $records 0] ne $expected_header || [llength $records] != 1338} {
    error "semantic V2 manifest schema/count mismatch"
  }
  set proofs [dict create]
  set severities [dict create]
  set manifest_rows [dict create]
  set support_rows [dict get $support ROW_PROOFS]
  foreach row [lrange $records 1 end] {
    if {[llength $row] != 17} { error "semantic V2 manifest row width mismatch" }
    set row_id [lindex $row 0]
    set proof [lindex $row 14]
    set disposition [lindex $row 15]
    set evidence [lindex $row 16]
    if {[dict exists $manifest_rows $row_id]} { error "duplicate semantic V2 RowID: $row_id" }
    if {$proof ni {BYTE_IDENTICAL SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE COMPOSITE_RELEASE_TOKEN_EQUIVALENCE} ||
        $disposition ne "PASS" || [lindex $row 3] eq "" || [lindex $row 4] eq "" ||
        [lindex $row 5] ni {Critical Warning Info} || [lindex $row 6] eq "" ||
        [lindex $row 7] eq "" || [lindex $row 8] eq "" || [lindex $row 9] eq "" ||
        [lindex $row 10] eq "" || [lindex $row 11] eq "" ||
        [lindex $row 12] eq "" || [lindex $row 13] eq ""} {
      error "semantic V2 manifest row is incomplete or uses an unauthorized PASS class: $row_id"
    }
    resolve_task_evidence $evidence "semantic manifest evidence for $row_id"
    if {[dict exists $support_rows $row_id] && [dict get $support_rows $row_id] ne $proof} {
      error "semantic/support proof-class mismatch for $row_id"
    }
    dict set manifest_rows $row_id $proof
    dict incr proofs $proof
    dict incr severities [lindex $row 5]
  }
  foreach row_id [dict keys $support_rows] {
    if {![dict exists $manifest_rows $row_id]} { error "support row absent from semantic V2 manifest: $row_id" }
  }
  foreach requirement [list [list BYTE_IDENTICAL 815] \
      [list SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE 512] \
      [list DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE 7] \
      [list COMPOSITE_RELEASE_TOKEN_EQUIVALENCE 3]] {
    lassign $requirement proof expected
    set actual [expr {[dict exists $proofs $proof] ? [dict get $proofs $proof] : 0}]
    if {$actual != $expected} { error "semantic V2 proof-class count mismatch for $proof: $actual/$expected" }
  }
  if {[dict size $proofs] != 4 || [dict get $severities Critical] != 427 ||
      [dict get $severities Warning] != 874 || [dict get $severities Info] != 36 ||
      [dict size $severities] != 3} {
    error "semantic V2 severity/proof aggregate mismatch"
  }
  return [dict create ROW_COUNT 1337 SHA256 [sha256_file $path]]
}

proc verify_semantic_inputs {} {
  global task_root routed_dcp product_routed_dcp
  global product_extraction_root diagnostic_extraction_root
  global product_extraction_receipt diagnostic_extraction_receipt support_csv
  global support_evidence_manifest
  global semantic_summary semantic_csv semantic_json semantic_sidecar
  global semantic_alias_csv semantic_alias_json semantic_alias_sidecar
  global source_identity_report source_tap_report expected_source_commit expected_source_tree
  global expected_dcp_sha expected_product_dcp_sha expected_cdc1_sha expected_product_cdc1_sha

  foreach path [list $semantic_summary $semantic_csv $semantic_json $semantic_sidecar \
      $semantic_alias_csv $semantic_alias_json $semantic_alias_sidecar $support_csv \
      $support_evidence_manifest \
      $source_identity_report $source_tap_report $product_extraction_receipt \
      $diagnostic_extraction_receipt] {
    if {![file isfile $path] || [file size $path] == 0} {
      error "required R2R1 semantic/signoff prerequisite is missing or empty: $path"
    }
  }
  require_text $source_identity_report {G2B_FUNCTIONAL_BODY_IDENTITY = PASS} SOURCE_FUNCTIONAL_IDENTITY
  require_text $source_identity_report {DIAGNOSTIC_TAPS_ONLY = YES} SOURCE_FUNCTIONAL_IDENTITY
  require_text $source_identity_report {FUNCTIONAL_OWNERSHIP_LOGIC_CHANGED = NO} SOURCE_FUNCTIONAL_IDENTITY
  require_text $source_identity_report {FUNCTIONAL_RELEASE_LOGIC_CHANGED = NO} SOURCE_FUNCTIONAL_IDENTITY
  require_text $source_identity_report {FUNCTIONAL_RESET_LOGIC_CHANGED = NO} SOURCE_FUNCTIONAL_IDENTITY
  require_text $source_tap_report {SOURCE_LEVEL_DIAGNOSTIC_TAP_NONINTERFERENCE = PASS} SOURCE_TAP_NONINTERFERENCE

  set product [verify_cone_extraction product $product_extraction_root \
    $product_extraction_receipt $product_routed_dcp $expected_product_dcp_sha $expected_product_cdc1_sha]
  set diagnostic [verify_cone_extraction diagnostic $diagnostic_extraction_root \
    $diagnostic_extraction_receipt $routed_dcp $expected_dcp_sha $expected_cdc1_sha]
  set support [verify_support_csv $support_csv $support_evidence_manifest]
  set manifest [verify_manifest_csv $semantic_csv $support]

  set csv_sha [dict get $manifest SHA256]
  set json_sha [sha256_file $semantic_json]
  if {[sha256_file $semantic_alias_csv] ne $csv_sha ||
      [sha256_file $semantic_alias_json] ne $json_sha ||
      [sha256_file $semantic_alias_sidecar] ne [sha256_file $semantic_sidecar]} {
    error "canonical and evidence-list semantic V2 names are not byte-identical"
  }
  set sidecar [read_key_values $semantic_sidecar]
  require_value $sidecar CSV_SHA256 $csv_sha SEMANTIC_V2_SIDECAR
  require_value $sidecar JSON_SHA256 $json_sha SEMANTIC_V2_SIDECAR

  set family_definitions [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv]
  set row_partition [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_ROW_PARTITION.csv]
  set semantic_model [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MODEL.json]
  set comparer_receipt [file join $task_root cdc G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_COMPARER_RECEIPT.json]
  require_text $comparer_receipt [dict get $support EVIDENCE_SHA256] DESTINATION_CONE_COMPARER_RECEIPT
  set summary [read_key_values $semantic_summary]
  foreach requirement [list \
      [list SCHEMA NVP_VIDEO_DIAG1_R2R1_CDC_RECONCILIATION_SUMMARY_V2] \
      [list RESULT PASS] [list CDC_DISPOSITION PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST] \
      [list CLASSIFICATION PROFILE_SPECIFIC_DIAGNOSTIC_CDC_MANIFEST_V2] \
      [list SOURCE_COMMIT $expected_source_commit] [list SOURCE_TREE $expected_source_tree] \
      [list PRODUCT_ROUTED_DCP_SHA256 $expected_product_dcp_sha] \
      [list DIAGNOSTIC_ROUTED_DCP_SHA256 $expected_dcp_sha] \
      [list PRODUCT_CDC_1_PHYSICAL_MANIFEST_SHA256 $expected_product_cdc1_sha] \
      [list DIAGNOSTIC_CDC_1_PHYSICAL_MANIFEST_SHA256 $expected_cdc1_sha] \
      [list RAW_CRITICAL_COUNT 427] [list RAW_WARNING_COUNT 874] \
      [list CDC_1_DESTINATIONS 423] [list NEW_CDC_DESTINATIONS 0] \
      [list MISSING_CDC_DESTINATIONS 0] [list RULE_DRIFT_COUNT 0] \
      [list SEVERITY_DRIFT_COUNT 0] [list CLOCK_PAIR_DRIFT_COUNT 0] \
      [list DESTINATION_MULTIPLICITY_DRIFT_COUNT 0] \
      [list CDC_1_BYTE_IDENTICAL_ROWS 121] [list CDC_10_BYTE_IDENTICAL_ROWS 2] \
      [list CDC_13_BYTE_IDENTICAL_ROWS 2] \
      [list CRITICAL_SAME_FAMILY_ROWS 295] [list CRITICAL_SAME_FAMILY_RECONCILED 295] \
      [list CROSS_FAMILY_CRITICAL_ROWS 7] [list CROSS_FAMILY_CRITICAL_RECONCILED 7] \
      [list TOTAL_CHANGED_CRITICAL_ROWS 302] [list TOTAL_CHANGED_CRITICAL_RECONCILED 302] \
      [list WARNING_SAME_FAMILY_ROWS 217] [list WARNING_SAME_FAMILY_RECONCILED 217] \
      [list COMPOSITE_RELEASE_WARNING_ROWS 3] [list COMPOSITE_RELEASE_WARNING_RECONCILED 3] \
      [list TOTAL_CHANGED_WARNING_ROWS 220] [list TOTAL_CHANGED_WARNING_RECONCILED 220] \
      [list TOTAL_MANIFEST_ROWS 1337] [list BYTE_IDENTICAL_ROWS 815] \
      [list SAME_FAMILY_ROWS 512] [list DESTINATION_CONE_ROWS 7] \
      [list COMPOSITE_RELEASE_ROWS 3] [list CHANGED_SUPPORT_ROWS 522] \
      [list CHANGED_SUPPORT_PASS_ROWS 522] [list UNRECONCILED_CRITICAL_ROWS 0] \
      [list UNRECONCILED_WARNING_ROWS 0] [list NEW_FAMILY_COUNT 0] \
      [list MISSING_FAMILY_COUNT 0] [list SOURCE_CLOCK_DRIFT_COUNT 0] \
      [list GOVERNING_TOKEN_DRIFT_COUNT 0] [list PROTOCOL_DRIFT_COUNT 0] \
      [list EXCEPTION_DRIFT_COUNT 0] [list BARRIER_DRIFT_COUNT 0] \
      [list REPLACEMENT_GROUP_DRIFT_COUNT 0] [list DIAGNOSTIC_HIERARCHY_CDC_ROWS 0] \
      [list UNCLASSIFIED_CROSS_CLOCK_STARTPOINTS 0] \
      [list DIAGNOSTIC_SOURCE_FAMILIES_IN_FUNCTIONAL_CONES 0] \
      [list ARBITRARY_SOURCE_NORMALIZATION_USED NO] \
      [list OWNERSHIP_RELEASE_MERGED NO] [list COMPOSITE_CHILD_FIELDS_PRESERVED YES] \
      [list ENABLE_APPLIED_SUPPORT_SET PASS] [list SLOT_STATE0_SUPPORT_SET PASS] \
      [list OWNERSHIP_FATAL_DEFERRED_SUPPORT_SET PASS] \
      [list OWNERSHIP_FATAL_EVENT_SUPPORT_SET PASS] [list OWNERSHIP_FATAL_SUPPORT_SET PASS] \
      [list RESET_ABANDONED_COMPOSITE_SUPPORT_SET PASS] \
      [list STRUCTURAL_CDC PASS] [list REPLACEMENT_CHECKS_PASS 17] \
      [list REPLACEMENT_CHECKS_TOTAL 17] [list UNRESOLVED_REPLACEMENT_CHECKS 0] \
      [list SEMANTIC_MANIFEST_CSV_SHA256 $csv_sha] \
      [list SEMANTIC_MANIFEST_JSON_SHA256 $json_sha] \
      [list SUPPORT_CSV_SHA256 [dict get $support SHA256]] \
      [list SOURCE_FAMILY_DEFINITIONS_SHA256 [sha256_file $family_definitions]] \
      [list ROW_PARTITION_SHA256 [sha256_file $row_partition]] \
      [list SEMANTIC_MODEL_SHA256 [sha256_file $semantic_model]] \
      [list DESTINATION_CONE_COMPARER_RECEIPT_SHA256 [sha256_file $comparer_receipt]] \
      [list PRODUCT_RAW_CDC_REPORT_SHA256 [dict get $product RAW_CDC_SHA256]] \
      [list DIAGNOSTIC_RAW_CDC_REPORT_SHA256 [dict get $diagnostic RAW_CDC_SHA256]] \
      [list PRODUCT_EXTRACTION_RECEIPT_SHA256 [dict get $product RECEIPT_SHA256]] \
      [list DIAGNOSTIC_EXTRACTION_RECEIPT_SHA256 [dict get $diagnostic RECEIPT_SHA256]] \
      [list SOURCE_FUNCTIONAL_IDENTITY_REPORT_SHA256 [sha256_file $source_identity_report]] \
      [list DIAGNOSTIC_TAP_FANOUT_CSV_SHA256 [dict get $diagnostic TAP_SHA256]] \
      [list G2B_FUNCTIONAL_BODY_IDENTITY PASS] \
      [list DIAGNOSTIC_TAP_NONINTERFERENCE PASS]] {
    lassign $requirement key value
    require_value $summary $key $value SEMANTIC_RECONCILIATION_V2
  }
  return [dict create SUMMARY_SHA256 [sha256_file $semantic_summary] \
    CSV_SHA256 $csv_sha JSON_SHA256 $json_sha SUPPORT_SHA256 [dict get $support SHA256] \
    SUPPORT_EVIDENCE_SHA256 [dict get $support EVIDENCE_SHA256] \
    SIDECAR_SHA256 [sha256_file $semantic_sidecar] \
    PRODUCT_RAW_CDC_SHA256 [dict get $product RAW_CDC_SHA256] \
    DIAGNOSTIC_RAW_CDC_SHA256 [dict get $diagnostic RAW_CDC_SHA256] \
    PRODUCT_EXTRACTION_RECEIPT_SHA256 [dict get $product RECEIPT_SHA256] \
    DIAGNOSTIC_EXTRACTION_RECEIPT_SHA256 [dict get $diagnostic RECEIPT_SHA256] \
    SOURCE_IDENTITY_SHA256 [sha256_file $source_identity_report] \
    SOURCE_TAP_REPORT_SHA256 [sha256_file $source_tap_report] \
    DIAGNOSTIC_TAP_CSV_SHA256 [dict get $diagnostic TAP_SHA256]]
}

proc verify_inherited_active_bus_skew {output_root} {
  global r1_report_root routed_dcp expected_dcp_sha expected_bus_skew_receipt_sha
  global expected_retired_bus_skew_receipt_sha
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
  set retired_path [file join $r1_report_root G2B_FIX1_R1_RETIRED_BUS_SKEW_ABSENCE.txt]
  if {[sha256_file $retired_path] ne $expected_retired_bus_skew_receipt_sha} {
    error "inherited retired-bus-skew absence receipt hash mismatch"
  }
  set retired [read_key_values $retired_path]
  foreach requirement [list [list RETIRED_RELATIONS_PRESENT 0] [list RESULT PASS] \
      [list ROUTED_EXPORTED_ACTIVE_SET_BUS_SKEW_COUNT 11_VERIFIED_BY_ROUTED_GATE]] {
    lassign $requirement key value
    require_value $retired $key $value INHERITED_RETIRED_BUS_SKEW_ABSENCE
  }
  foreach group_id {9 13 14 15 16 17} {
    require_value $retired GROUP_${group_id}_RETIRED_SET_BUS_SKEW_PRESENT NO \
      INHERITED_RETIRED_BUS_SKEW_ABSENCE
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
  set inherited_full_raw [file join $r1_report_root BUS_SKEW_GROUPS ROUTED_TIMING_FULL_RAW.xdc]
  set inherited_canonical [file join $output_root G2B_NVP_VIDEO_DIAG1_R2R1_INHERITED_FULL_TIMING_CANONICAL.xdc]
  set inherited_canonical_sha [canonicalize_xdc $inherited_full_raw $inherited_canonical]

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
    {SCHEMA=G2B_NVP_VIDEO_DIAG1_R2R1_INHERITED_ACTIVE_BUS_SKEW_V1} \
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
    {RETIRED_BUS_SKEW_RELATIONS_PRESENT=0} \
    "RETIRED_ABSENCE_RECEIPT_SHA256=$expected_retired_bus_skew_receipt_sha" \
    {CONSTRAINTS_LOADED_OR_MODIFIED=NO} {RESULT=PASS}
  write_lines [file join $output_root G2B_NVP_VIDEO_DIAG1_R2R1_INHERITED_ACTIVE_BUS_SKEW_VALIDATION.txt] $output
  return [dict create PASS_COUNT $pass_count \
    FULL_RAW_XDC_SHA256 [dict get $values FULL_RAW_XDC_SHA256] \
    FULL_CANONICAL_XDC_SHA256 $inherited_canonical_sha \
    RECEIPT_SHA256 $expected_bus_skew_receipt_sha \
    RETIRED_ABSENCE_SHA256 $expected_retired_bus_skew_receipt_sha]
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
    write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_PROMOTED_REPLACEMENT_RESULTS.csv] $csv
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
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_STRUCTURAL_CDC.txt] $lines
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
  set manifest_path [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_SIGNOFF_CDC_1_PHYSICAL_MANIFEST.txt]
  write_lines $manifest_path [lsort -ascii $cdc1]
  set manifest_sha [sha256_file $manifest_path]
  if {$manifest_sha ne $expected_cdc1_sha} {
    error "fresh signoff CDC-1 physical manifest mismatch: expected=$expected_cdc1_sha actual=$manifest_sha"
  }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_DIAGNOSTIC_HIERARCHY_CDC_ROWS.txt] \
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
    [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_CDC_CRITICAL_OBJECTS.csv]
  check_rule_counts CDC_WARNING $warning \
    [dict create CDC-6 13 CDC-15 861] {WARNING} \
    [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_CDC_WARNING_OBJECTS.csv]
  check_rule_counts CDC_INFO $info \
    [dict create CDC-3 30 CDC-9 6] {INFO} \
    [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_CDC_INFO_OBJECTS.csv]
  set parsed [parse_cdc_report $root $path $expected_cdc1_sha]
  if {[llength $violations] != [dict get $parsed TOTAL]} {
    error "fresh signoff CDC report/object multiplicity mismatch"
  }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_RAW_CDC_REPRODUCTION.txt] [list \
    {RESULT=PASS} "RAW_CDC_REPORT=$path" "RAW_CDC_REPORT_SHA256=[sha256_file $path]" \
    {CRITICAL_TOTAL=427} {CDC_1_CRITICAL=423} {CDC_10_CRITICAL=2} \
    {CDC_13_CRITICAL=2} {WARNING_TOTAL=874} {CDC_6_WARNING=13} \
    {CDC_15_WARNING=861} "CDC_1_PHYSICAL_MANIFEST_SHA256=[dict get $parsed CDC1_SHA256]" \
    {DIAGNOSTIC_HIERARCHY_CDC_ROWS=0} \
    {CDC_DISPOSITION=PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST}]
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
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_TIMING_GATE.txt] [list \
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
    [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_DRC_WARNING_OBJECTS.csv]
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_DRC_GATE.txt] [list \
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
    [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_METHODOLOGY_WARNING_OBJECTS.csv]
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_METHODOLOGY_GATE.txt] [list \
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
      $lut != 18677 || $ff != 20173 || $bram != 26.5 || $dsp != 0 ||
      $lut_percent > 98.0 || $ff_percent > 95.0 ||
      $bram_percent > 90.0 || $dsp_percent > 90.0} {
    error "resource gate failed: LUT=$lut/$used_lut_available FF=$ff/$used_ff_available BRAM=$bram/$used_bram_available DSP=$dsp/$used_dsp_available"
  }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_RESOURCE_GATE.txt] [list \
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
  # Vivado legally merges current_result_session_id with current_session_id in
  # this frozen design because the snapshot is latched before CAPTURE_READY and
  # the session cannot advance while current_result_valid is asserted.  Verify
  # the retained implementation object rather than requiring an optimized-away
  # source-register basename.
  foreach token {current_result_valid current_session_id current_result_generation} {
    set objects [concat [get_cells -quiet -hier -regexp ".*${token}.*"] \
      [get_nets -quiet -hier -regexp ".*${token}.*"]]
    if {[llength $objects] == 0} { error "diagnostic snapshot identity token is absent: $token" }
  }
  set black_boxes [get_cells -quiet -hier -filter {IS_BLACKBOX == 1}]
  if {[llength $black_boxes] != 0} { error "black-box gate failed: [llength $black_boxes]" }
  write_lines [file join $root G2B_NVP_VIDEO_DIAG1_R2R1_DIAGNOSTIC_IDENTITY_GATE.txt] [concat [list \
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
  foreach variable {task_root recovery_harness source_root r1_report_root routed_dcp product_routed_dcp \
      product_extraction_root diagnostic_extraction_root product_extraction_receipt \
      diagnostic_extraction_receipt support_csv semantic_summary semantic_csv \
      support_evidence_manifest \
      semantic_json semantic_sidecar semantic_alias_csv semantic_alias_json \
      semantic_alias_sidecar source_identity_report source_tap_report signoff_root \
      artifact_root signed_dcp bitstream} {
    set $variable [file normalize [set $variable]]
  }
  if {![file isdirectory $task_root] || ![file isdirectory $source_root] ||
      ![file isdirectory $r1_report_root] || ![file isfile $routed_dcp] ||
      ![file isfile $product_routed_dcp] || ![file isfile $recovery_harness] ||
      ![path_is_within $signoff_root $task_root] ||
      ![path_is_within $artifact_root $task_root]} {
    error "fixed R2R1 task/source/DCP path authority mismatch"
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
      [llength [glob -nocomplain -directory $artifact_root *.dcp]] != 0 ||
      [llength [glob -nocomplain -directory $artifact_root *.bit]] != 0 ||
      [llength [glob -nocomplain -directory $artifact_root *.ltx]] != 0} {
    error "R2R1 signed-DCP/bitstream/LTX output authority is not fresh"
  }

  set vivado_version [version -short]
  if {$vivado_version ne $expected_vivado_version} {
    error "Vivado version mismatch: expected=$expected_vivado_version actual=$vivado_version"
  }
  set source_branch [string trim [exec git --no-optional-locks -C $source_root branch --show-current]]
  set source_commit [string trim [exec git --no-optional-locks -C $source_root rev-parse HEAD]]
  set source_tree [string trim [exec git --no-optional-locks -C $source_root rev-parse {HEAD^{tree}}]]
  set source_status [string trim [exec git --no-optional-locks -C $source_root status --short --untracked-files=no]]
  if {$source_branch ne $expected_source_branch || $source_commit ne $expected_source_commit ||
      $source_tree ne $expected_source_tree || $source_status ne ""} {
    error "NVP_DIAG1_R2R1_SOURCE_AUTHORITY_CONTRADICTION"
  }

  set original_dcp_size [file size $routed_dcp]
  set original_dcp_mtime [file mtime $routed_dcp]
  set original_dcp_sha [sha256_file $routed_dcp]
  set product_dcp_size [file size $product_routed_dcp]
  set product_dcp_mtime [file mtime $product_routed_dcp]
  set product_dcp_sha [sha256_file $product_routed_dcp]
  set recovery_harness_sha [sha256_file $recovery_harness]
  if {$original_dcp_sha ne $expected_dcp_sha} {
    error "NVP_DIAG1_R2R1_EXACT_ROUTED_DCP_UNAVAILABLE: expected=$expected_dcp_sha actual=$original_dcp_sha"
  }
  if {$product_dcp_sha ne $expected_product_dcp_sha} {
    error "NVP_DIAG1_R2R1_EXACT_PRODUCT_DCP_UNAVAILABLE: expected=$expected_product_dcp_sha actual=$product_dcp_sha"
  }
  set semantic [verify_semantic_inputs]
  set active_bus_skew [verify_inherited_active_bus_skew $signoff_root]

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
  if {[dict get $signatures_pre CONSTRAINT_SHA256] ne \
      [dict get $active_bus_skew FULL_CANONICAL_XDC_SHA256]} {
    error "current diagnostic DCP timing view differs from the exact inherited 11-active/6-retired governed view"
  }

  set promoted_pass [run_promoted_replacements $signoff_root]
  set structural [run_structural_cdc $signoff_root]
  set cdc [run_cdc_gate $signoff_root $expected_cdc1_sha]
  set timing [run_timing_gate $signoff_root]
  run_drc_methodology_gates $signoff_root
  set resources [run_resource_gate $signoff_root]
  run_diagnostic_identity_gate $signoff_root
  if {[dict get $active_bus_skew PASS_COUNT] != 11 ||
      $promoted_pass != 17 || $structural ne "PASS"} {
    error "governed Group 1-17 aggregate did not pass"
  }

  set signatures_post [capture_signatures $signoff_root POST_SIGNOFF]
  require_same_signatures $signatures_pre $signatures_post REPORT_ONLY_SIGNOFF
  if {[sha256_file $routed_dcp] ne $original_dcp_sha ||
      [file size $routed_dcp] != $original_dcp_size ||
      [file mtime $routed_dcp] != $original_dcp_mtime ||
      [sha256_file $product_routed_dcp] ne $product_dcp_sha ||
      [file size $product_routed_dcp] != $product_dcp_size ||
      [file mtime $product_routed_dcp] != $product_dcp_mtime ||
      [sha256_file $recovery_harness] ne $recovery_harness_sha} {
    error "original PRODUCT/diagnostic DCP or task-local harness changed before authorized output stage"
  }

  write_checkpoint $signed_dcp
  if {![file isfile $signed_dcp] || [file size $signed_dcp] == 0} {
    error "signed-off R2R1 routed DCP was not created"
  }
  if {[llength [glob -nocomplain -directory $artifact_root *.dcp]] != 1 ||
      [llength [glob -nocomplain -directory $artifact_root *.bit]] != 0} {
    error "signed-off DCP output cardinality is not exactly one before bitstream generation"
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
    error "R2R1 diagnostic bitstream was not generated"
  }
  set bitstream_size [file size $bitstream]
  set bitstream_sha [sha256_file $bitstream]
  if {[llength [glob -nocomplain -directory $artifact_root *.dcp]] != 1 ||
      [llength [glob -nocomplain -directory $artifact_root *.bit]] != 1 ||
      [llength [glob -nocomplain -directory $artifact_root *.ltx]] != 0} {
    error "signed-DCP/bitstream cardinality or LTX gate failed"
  }
  set signatures_after_bit [capture_signatures $signoff_root AFTER_BITSTREAM]
  require_same_signatures $signatures_pre $signatures_after_bit AFTER_BITSTREAM
  close_design
  set design_open 0

  if {[sha256_file $routed_dcp] ne $original_dcp_sha ||
      [file size $routed_dcp] != $original_dcp_size ||
      [file mtime $routed_dcp] != $original_dcp_mtime ||
      [sha256_file $product_routed_dcp] ne $product_dcp_sha ||
      [file size $product_routed_dcp] != $product_dcp_size ||
      [file mtime $product_routed_dcp] != $product_dcp_mtime ||
      [sha256_file $recovery_harness] ne $recovery_harness_sha} {
    error "original PRODUCT/diagnostic DCP or task-local harness changed during sign-off/output generation"
  }
  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R2R1_SIGNED_OFF_DCP_MANIFEST.txt] [list \
    {RESULT=PASS} "ORIGINAL_ROUTED_DCP=$routed_dcp" \
    "ORIGINAL_ROUTED_DCP_SHA256=$original_dcp_sha" \
    "PRODUCT_ROUTED_DCP=$product_routed_dcp" \
    "PRODUCT_ROUTED_DCP_SHA256=$product_dcp_sha" \
    "SIGNED_OFF_ROUTED_DCP=$signed_dcp" "SIGNED_OFF_ROUTED_DCP_SHA256=$signed_dcp_sha" \
    "SIGNED_OFF_ROUTED_DCP_SIZE=[file size $signed_dcp]" \
    "ROUTE_STATUS_SIGNATURE_SHA256=[dict get $signatures_pre ROUTE_STATUS_SHA256]" \
    "PLACED_NETLIST_SIGNATURE_SHA256=[dict get $signatures_pre NETLIST_SHA256]" \
    "CLOCK_SIGNATURE_SHA256=[dict get $signatures_pre CLOCK_SHA256]" \
    "NETLIST_SIGNATURE_SHA256=[dict get $signatures_pre NETLIST_SHA256]" \
    "TIMING_CONSTRAINT_SIGNATURE_SHA256=[dict get $signatures_pre CONSTRAINT_SHA256]" \
    "ACTIVE_BUS_SKEW_RECEIPT_SHA256=[dict get $active_bus_skew RECEIPT_SHA256]" \
    "RETIRED_BUS_SKEW_ABSENCE_SHA256=[dict get $active_bus_skew RETIRED_ABSENCE_SHA256]" \
    {ACTIVE_SET_BUS_SKEW_COUNT=11} {RETIRED_SET_BUS_SKEW_RELATIONS_PRESENT=0} \
    {ROUTE_STATUS_SIGNATURE_UNCHANGED=YES} \
    {ROUTE_SIGNATURE_UNCHANGED=YES} \
    {ROUTE_IDENTITY_BASIS=ACCEPTED_FIX1_R1_COMPACT_ROUTE_STATUS_PLUS_PLACED_NETLIST_CLOCK_AND_XDC_SIGNATURES} \
    {CLOCK_SIGNATURE_UNCHANGED=YES} \
    {NETLIST_SIGNATURE_UNCHANGED=YES} {FULL_TIMING_RESTORATION=PASS} \
    {ORIGINAL_DCP_UNCHANGED=YES}]
  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R2R1_BITSTREAM_MANIFEST.txt] [list \
    {RESULT=PASS} "BITSTREAM=$bitstream" "BITSTREAM_SIZE=$bitstream_size" \
    "BITSTREAM_SHA256=$bitstream_sha" "SIGNED_OFF_DCP_SHA256=$signed_dcp_sha" \
    "SOURCE_COMMIT=$source_commit" "SOURCE_TREE=$source_tree" \
    "RECOVERY_HARNESS=$recovery_harness" "RECOVERY_HARNESS_SHA256=$recovery_harness_sha" \
    {BUILD_FLAGS=32'h00000402} {DIAG_MAGIC=0x4E565034} \
    {DIAG_VERSION=0x00010001} \
    "SOURCE_ROUTED_DCP_SHA256=$original_dcp_sha" \
    "SEMANTIC_CDC_MANIFEST_CSV_SHA256=[dict get $semantic CSV_SHA256]" \
    "SEMANTIC_CDC_MANIFEST_JSON_SHA256=[dict get $semantic JSON_SHA256]" \
    "DESTINATION_CONE_SUPPORT_CSV_SHA256=[dict get $semantic SUPPORT_SHA256]" \
    "DESTINATION_CONE_EVIDENCE_SHA256_MANIFEST_SHA256=[dict get $semantic SUPPORT_EVIDENCE_SHA256]" \
    "PRODUCT_PHYSICAL_CDC_1_MANIFEST_SHA256=$expected_product_cdc1_sha" \
    "PHYSICAL_CDC_1_MANIFEST_SHA256=[dict get $cdc CDC1_SHA256]" \
    {CANDIDATE_CLASSIFICATION=G2B_NVP_VIDEO_DIAG1_R2R1_DESTINATION_CONE_CDC_CANDIDATE} \
    {WRITE_CHECKPOINT_COUNT=1} {WRITE_BITSTREAM_COUNT=1} {LTX=NONE_EXPECTED}]
  write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R2R1_SIGNOFF_RESULT.txt] [list \
    {RESULT=PASS} {CDC_DISPOSITION=PASS_PROFILE_SPECIFIC_DESTINATION_CONE_MANIFEST} \
    {ACTIVE_BUS_SKEW_GROUPS=11/11} {ACTIVE_BUS_SKEW_VIOLATIONS=0} \
    {RETIRED_BUS_SKEW_RELATIONS_PRESENT=0} \
    {PROMOTED_REPLACEMENT_CHECKS=17/17} {STRUCTURAL_CDC=PASS} \
    {SEMANTIC_MANIFEST_V2_ROWS=1337} {CHANGED_ROWS_RECONCILED=522/522} \
    {DESTINATION_CONE_SUPPORT_SET_ROWS=7/7} {COMPOSITE_RELEASE_TOKEN_ROWS=3/3} \
    {ALL_GOVERNED_GROUPS_1_TO_17=PASS} {FULLY_ROUTED=YES} \
    {ROUTED_NETS=36180/36180} {UNROUTED_NETS=0} {PARTIALLY_ROUTED_NETS=0} \
    "WNS=[format %.3f [dict get $timing WNS]]" {TNS=0.000} \
    "WHS=[format %.3f [dict get $timing WHS]]" {THS=0.000} \
    {DRC=PASS} {METHODOLOGY=PASS} {RESOURCE_GATE=PASS} \
    "LUT_USED=[dict get $resources LUT]" "FF_USED=[dict get $resources FF]" \
    "BRAM_USED=[dict get $resources BRAM]" "DSP_USED=[dict get $resources DSP]" \
    "SIGNED_OFF_DCP=$signed_dcp" "SIGNED_OFF_DCP_SHA256=$signed_dcp_sha" \
    "BITSTREAM=$bitstream" "BITSTREAM_SHA256=$bitstream_sha" \
    {ROUTE_SIGNATURE_UNCHANGED=YES} {CLOCK_SIGNATURE_UNCHANGED=YES} \
    {NETLIST_SIGNATURE_UNCHANGED=YES} {FULL_TIMING_RESTORATION=PASS} \
    {SOURCE_CHANGED=NO} {RTL_CHANGED=NO} {XDC_CHANGED=NO} {IP_CHANGED=NO} \
    {CONSTRAINT_MUTATION_COMMANDS=0} {IMPLEMENTATION_COMMANDS=0} \
    {WRITE_CHECKPOINT_COUNT=1} {WRITE_BITSTREAM_COUNT=1} {WRITE_DEBUG_PROBES_COUNT=0}]
} operation_message operation_options]

if {$operation_code != 0} {
  if {$design_open} { catch {close_design} }
  catch {
    file mkdir $signoff_root
    write_lines [file join $signoff_root G2B_NVP_VIDEO_DIAG1_R2R1_SIGNOFF_FAILURE.txt] [list \
      {RESULT=FAIL} "ERROR=[single_line $operation_message]"]
  }
  puts stderr "G2B_NVP_VIDEO_DIAG1_R2R1_SIGNOFF_FAIL: $operation_message"
  if {[dict exists $operation_options -errorinfo]} {
    puts stderr [dict get $operation_options -errorinfo]
  }
  exit 1
}

puts "G2B_NVP_VIDEO_DIAG1_R2R1_SIGNOFF_PASS"
exit 0
