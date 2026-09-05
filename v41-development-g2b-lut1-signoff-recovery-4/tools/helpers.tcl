proc write_lines_atomic {path lines} {
  file mkdir [file dirname $path]
  set temporary "${path}.[pid].tmp"
  set handle [open $temporary w]
  fconfigure $handle -encoding utf-8 -translation lf
  foreach line $lines { puts $handle $line }
  close $handle
  file rename -force $temporary $path
}


proc write_text_atomic {path value} {
  file mkdir [file dirname $path]
  set temporary "${path}.[pid].tmp"
  set handle [open $temporary w]
  fconfigure $handle -encoding utf-8 -translation lf
  puts -nonewline $handle $value
  close $handle
  file rename -force $temporary $path
}


proc read_text {path} {
  set handle [open $path r]
  fconfigure $handle -encoding utf-8 -translation auto
  set value [read $handle]
  close $handle
  return $value
}


proc safe_value {value} {
  return [string map [list "\r" {\r} "\n" {\n} "=" {:}] $value]
}


proc csv_value {value} {
  return "\"[string map [list "\"" "\"\"" "\r" " " "\n" " "] $value]\""
}


proc sha256_file {path} {
  if {![file isfile $path]} { error "file is absent for SHA-256: $path" }
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set candidate [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $candidate]} { return $candidate }
  }
  error "SHA-256 unavailable for $path"
}


proc property_or_unknown {property object} {
  if {[catch {get_property $property $object} value] || $value eq ""} { return UNKNOWN }
  return $value
}


proc property_is_true {value} {
  return [expr {$value eq "1" || [string equal -nocase $value "true"] ||
                [string equal -nocase $value "yes"]}]
}


proc seconds_since {start_ms} {
  return [format %.3f [expr {double([clock milliseconds] - $start_ms) / 1000.0}]]
}


proc unique_objects_by_name {objects} {
  set by_name [dict create]
  foreach object $objects { dict set by_name [get_property NAME $object] $object }
  set result [list]
  foreach name [lsort -dictionary [dict keys $by_name]] {
    lappend result [dict get $by_name $name]
  }
  return $result
}


proc collection_names {objects} {
  set result [list]
  foreach object $objects { lappend result [get_property NAME $object] }
  return [lsort -dictionary $result]
}


proc route_signature {} {
  return [list \
    [report_route_status -boolean_check ROUTED_FULLY] \
    [report_route_status -boolean_check ERRORS_IN_ROUTES] \
    [llength [report_route_status -return_nets -route_type UNROUTED]] \
    [llength [report_route_status -return_nets -route_type PARTIAL]]]
}


proc routed_worst_slack {delay_type} {
  set paths [get_timing_paths -quiet -delay_type $delay_type -max_paths 1 -nworst 1]
  if {[llength $paths] != 1} { error "one routed $delay_type timing path was not available" }
  set slack [get_property SLACK [lindex $paths 0]]
  if {![string is double -strict $slack]} { error "routed $delay_type slack is not numeric: $slack" }
  return $slack
}


proc check_timing_table_count {text wanted} {
  foreach line [split $text "\n"] {
    if {[regexp [format {checking[ \t]+%s[ \t]*\(([0-9]+)\)} $wanted] $line -> count]} {
      return $count
    }
    set columns [split $line "|"]
    for {set index 0} {$index + 1 < [llength $columns]} {incr index} {
      if {[string trim [lindex $columns $index]] ne $wanted} { continue }
      set count [string trim [lindex $columns [expr {$index + 1}]]]
      if {[string is integer -strict $count]} { return $count }
    }
  }
  return UNKNOWN
}


proc utilization_row {text wanted} {
  set normalized_wanted [string trimright $wanted "*"]
  foreach line [split $text "\n"] {
    set columns [split $line "|"]
    if {[llength $columns] < 7} { continue }
    set actual [string trimright [string trim [lindex $columns 1]] "*"]
    if {$actual ne $normalized_wanted} { continue }
    set used [string map [list "," "" " " ""] [string trim [lindex $columns 2]]]
    set available [string map [list "," "" " " ""] [string trim [lindex $columns 5]]]
    if {![string is double -strict $used] || ![string is double -strict $available] ||
        $available <= 0.0} {
      error "non-numeric utilization row '$wanted': used='$used' available='$available'"
    }
    return [list $used $available]
  }
  error "utilization row '$wanted' not found"
}


proc cdc1_family {row} {
  set matches [list]
  foreach {family expression} [list \
      OWNERSHIP_AXI_TO_SOURCE {\|G2B_ONECH_C2H/axis_slot_reg\[1\]/C\|G2B_ONECH_C2H/(own_ok_hold_source|slot_state_source)_reg} \
      RELEASE_AXI_TO_SOURCE {\|G2B_ONECH_C2H/release_(epoch|generation)_axi_reg} \
      TRANSPORT_HARD_AXI_TO_SOURCE {\|G2B_ONECH_C2H/transport_hard_hold_axi_reg/C\|} \
      TRANSPORT_PHASE_AXI_TO_SOURCE {\|G2B_ONECH_C2H/transport_release_phase_hold_axi_reg\[0\]/C\|} \
      OWNERSHIP_RESULT_SOURCE_TO_AXI {\|G2B_ONECH_C2H/own_ok_hold_source_reg/C\|} \
      RESET_RESULT_SOURCE_TO_AXI {\|G2B_ONECH_C2H/reset_commit_phase_hold_source_reg\[2\]/C\|}] {
    if {[regexp -- $expression $row]} { lappend matches $family }
  }
  if {[llength $matches] != 1} {
    error "CDC-1 row did not map to exactly one governed semantic family: $row"
  }
  return [lindex $matches 0]
}

# Exact accepted 427-entry disposition retained from Gen12. The canonical
# endpoint hashes remain frozen; only the active-XDC identity and ownership
# Group-9 method are advanced to the META-4/BS3 authority.

proc enforce_exact_cdc_disposition {cdc_path cdc_violations} {
  global raw_root active_xdc build_root expected_active_xdc_sha

  set expected_counts [dict create CDC-1 423 CDC-10 2 CDC-13 2]
  set expected_hashes [dict create \
    CDC-1 F72A1FB2EBDF7317743CDD4F4E337F4C01C269FB88AC646F5DA8846F7EB29AFF \
    CDC-10 499C4B2893BF73BAA43CC049B232E661397D3BC92EEDA92582940845FCAE475A \
    CDC-13 CF8C6175F013504F041F12CD9C4F56D549998EEAAA340B4BEBD56D6F005A0B18]
  set expected_total_hash 5CF02643FB84CD6BCAE407CFAE8786D6BE62275EB14D1D4DD682BAE9DD48F049
  set object_counts [dict create CDC-1 0 CDC-10 0 CDC-13 0]
  set object_total 0
  foreach violation $cdc_violations {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity ne "CRITICAL" && $severity ne "CRITICAL WARNING"} { continue }
    incr object_total
    set object_name [get_property NAME $violation]
    if {![regexp {^(CDC-[0-9]+)#[0-9]+$} $object_name -> object_id] ||
        ![dict exists $expected_counts $object_id]} {
      error "unexpected critical CDC violation object: $object_name"
    }
    dict incr object_counts $object_id
  }

  set source_clock UNKNOWN
  set destination_clock UNKNOWN
  set summary_counts [dict create]
  set rows_by_id [dict create CDC-1 [list] CDC-10 [list] CDC-13 [list]]
  set parsed_total 0
  foreach line [split [read_text $cdc_path] "\n"] {
    if {[regexp {^Source Clock:[ \t]*(.+?)[ \t]*$} $line -> value]} {
      set source_clock [string trim $value]
      continue
    }
    if {[regexp {^Destination Clock:[ \t]*(.+?)[ \t]*$} $line -> value]} {
      set destination_clock [string trim $value]
      continue
    }
    if {[regexp {^[ \t]*(CDC-[0-9]+)[ \t]+Critical[ \t]+([0-9]+)[ \t]+} \
        $line -> summary_id summary_count]} {
      if {![dict exists $expected_counts $summary_id]} {
        error "unexpected critical CDC summary: $summary_id count=$summary_count"
      }
      dict set summary_counts $summary_id $summary_count
      continue
    }
    set row_id ""
    set exception ""
    set source_endpoint ""
    set destination_endpoint ""
    if {[regexp {^[ \t]*[0-9]+[ \t]+(CDC-1)[ \t]+Critical[ \t]+1-bit unknown CDC circuitry[ \t]+0[ \t]+(Max Delay Datapath Only)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]*$} \
        $line -> row_id exception source_endpoint destination_endpoint]} {
      # Canonical CDC-1 row.
    } elseif {[regexp {^[ \t]*[0-9]+[ \t]+(CDC-10)[ \t]+Critical[ \t]+Combinational logic detected before a synchronizer[ \t]+2[ \t]+(False Path)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]*$} \
        $line -> row_id exception source_endpoint destination_endpoint]} {
      # Canonical CDC-10 row.
    } elseif {[regexp {^[ \t]*[0-9]+[ \t]+(CDC-13)[ \t]+Critical[ \t]+1-bit CDC path on a non-FD primitive[ \t]+0[ \t]+(False Path)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]*$} \
        $line -> row_id exception source_endpoint destination_endpoint]} {
      # Canonical CDC-13 row.
    } elseif {[regexp {^[ \t]*[0-9]+[ \t]+CDC-[0-9]+[ \t]+Critical[ \t]+} $line]} {
      error "unexpected detailed critical CDC row: [safe_value $line]"
    } else {
      continue
    }
    if {$source_clock eq "UNKNOWN" || $destination_clock eq "UNKNOWN"} {
      error "critical CDC row lacks source/destination clock context"
    }
    dict lappend rows_by_id $row_id \
      "$row_id|$source_clock->$destination_clock|$exception|$source_endpoint|$destination_endpoint"
    incr parsed_total
  }

  set all_rows [list]
  set hash_receipt [list]
  foreach id {CDC-1 CDC-10 CDC-13} {
    if {![dict exists $summary_counts $id]} { error "missing critical CDC summary for $id" }
    set expected_count [dict get $expected_counts $id]
    set object_count [dict get $object_counts $id]
    set summary_count [dict get $summary_counts $id]
    set rows [lsort -ascii [dict get $rows_by_id $id]]
    if {$object_count != $expected_count || $summary_count != $expected_count ||
        [llength $rows] != $expected_count} {
      error "$id critical CDC count mismatch: expected=$expected_count objects=$object_count summary=$summary_count rows=[llength $rows]"
    }
    set id_token [string map {- _} $id]
    set manifest_path [file join $raw_root "G2B_CDC_CRITICAL_${id_token}_CANONICAL.txt"]
    write_lines_atomic $manifest_path $rows
    set actual_hash [sha256_file $manifest_path]
    if {$actual_hash ne [dict get $expected_hashes $id]} {
      error "$id critical CDC canonical manifest drift: $actual_hash"
    }
    lappend hash_receipt "${id}_COUNT=$expected_count" "${id}_SHA256=$actual_hash"
    set all_rows [concat $all_rows $rows]
  }
  set all_rows [lsort -ascii $all_rows]
  set total_manifest [file join $raw_root G2B_CDC_CRITICAL_ALL_CANONICAL.txt]
  write_lines_atomic $total_manifest $all_rows
  set total_hash [sha256_file $total_manifest]
  if {$object_total != 427 || $parsed_total != 427 || [llength $all_rows] != 427 ||
      $total_hash ne $expected_total_hash} {
    error "critical CDC total manifest mismatch: objects=$object_total parsed=$parsed_total rows=[llength $all_rows] hash=$total_hash"
  }

  set cdc1_rows [dict get $rows_by_id CDC-1]
  set family_counts [dict create]
  foreach row $cdc1_rows { dict incr family_counts [cdc1_family $row] }
  set expected_family_counts [dict create \
    OWNERSHIP_AXI_TO_SOURCE 4 RELEASE_AXI_TO_SOURCE 13 \
    TRANSPORT_HARD_AXI_TO_SOURCE 43 TRANSPORT_PHASE_AXI_TO_SOURCE 8 \
    OWNERSHIP_RESULT_SOURCE_TO_AXI 73 RESET_RESULT_SOURCE_TO_AXI 282]
  foreach family [dict keys $expected_family_counts] {
    if {![dict exists $family_counts $family] ||
        [dict get $family_counts $family] != [dict get $expected_family_counts $family]} {
      error "critical CDC semantic family drift: $family"
    }
  }

  set async_chain_cells [get_cells -quiet -hier [list \
    G2B_ONECH_C2H/fatal_sync1_source_reg \
    G2B_ONECH_C2H/fatal_sync2_source_reg \
    G2B_ONECH_C2H/source_ready_sync1_axi_reg \
    G2B_ONECH_C2H/source_ready_sync2_axi_reg]]
  if {[llength $async_chain_cells] != 4} { error "expected four CDC-10 ASYNC_REG chain cells" }
  foreach cell $async_chain_cells {
    if {![property_is_true [property_or_unknown ASYNC_REG $cell]]} {
      error "CDC-10 chain cell lacks ASYNC_REG=TRUE: [get_property NAME $cell]"
    }
  }

  if {[sha256_file $active_xdc] ne $expected_active_xdc_sha} {
    error "reviewed active G2B CDC XDC drift during CDC disposition"
  }
  set generated_pattern [file join $build_root vivado_project *.gen sources_1 ip \
    xdma_v41_m1 ip_0 source xdma_v41_m1_pcie2_ip-PCIE_X0Y0.xdc]
  set generated_files [glob -nocomplain -types f -- $generated_pattern]
  if {[llength $generated_files] != 1} { error "expected one generated XDMA PCIe XDC" }
  set generated_xdc [lindex $generated_files 0]
  if {[sha256_file $generated_xdc] ne "DD00E1DA9D2CAA6F27EBA21DB3BB6F73FC16A6F75C18C3394DB93430C815916B"} {
    error "generated XDMA PCIe XDC drift"
  }
  set generated_text [read_text $generated_xdc]
  foreach clause [list \
      {set_false_path -to [get_pins {inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0}]} \
      {set_false_path -to [get_pins {inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1}]} \
      {set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y0 -group clk_250mhz_mux_x0y0}] {
    if {[string first $clause $generated_text] < 0} {
      error "required generated-XDC CDC clause missing"
    }
  }

  set disposition_csv [list \
    {Rule,Clock_Pair,Exception,Source,Destination,Classification,Semantic_Family,Disposition}]
  foreach row $all_rows {
    lassign [split $row "|"] id clock_pair exception source_endpoint destination_endpoint
    if {$id eq "CDC-1"} {
      set family [cdc1_family $row]
      set classification HANDSHAKE
      if {$family eq "OWNERSHIP_AXI_TO_SOURCE"} {
        set disposition BS3_PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC
      } else {
        set disposition EXACT_REVIEWED_STABLE_DATA_PROTOCOL
      }
    } elseif {$id eq "CDC-10"} {
      set family EXACT_TWO_STAGE_LEVEL_SYNCHRONIZER
      set classification INTENTIONAL_SYNCHRONIZER
      set disposition ASYNC_REG_TWO_STAGE_CHAIN
    } else {
      set family XDMA_PIPE_CLOCK_MUX
      set classification FALSE_POSITIVE
      set disposition GENERATED_XDMA_FALSE_PATH_AND_PHYSICAL_EXCLUSIVITY
    }
    lappend disposition_csv "[csv_value $id],[csv_value $clock_pair],[csv_value $exception],[csv_value $source_endpoint],[csv_value $destination_endpoint],[csv_value $classification],[csv_value $family],[csv_value $disposition]"
  }
  write_lines_atomic [file join $raw_root G2B_LUT1_CDC_DISPOSITION.csv] $disposition_csv

  set disposition_lines [list \
    {RESULT=PASS} \
    {DISPOSITION=PASS_EXACT_427_ENTRY_REVIEWED_PROTOCOL_AND_XDMA_MUX_SET} \
    {CDC_CRITICAL_TOTAL=427} \
    {CDC_CRITICAL_DISPOSITIONED=427} \
    {CDC_REQUIRES_RTL_CHANGE=0} \
    {CDC_UNRESOLVED=0} \
    {CDC_UNKNOWN=0} \
    {*}$hash_receipt \
    "CDC_CRITICAL_TOTAL_SHA256=$total_hash" \
    "ACTIVE_G2B_CDC_XDC=$active_xdc" \
    "ACTIVE_G2B_CDC_XDC_SHA256=$expected_active_xdc_sha"]
  foreach family [lsort [dict keys $expected_family_counts]] {
    lappend disposition_lines "${family}_COUNT=[dict get $family_counts $family]"
  }
  lappend disposition_lines \
    {OWNERSHIP_GROUP9_METHOD=PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC} \
    {OWNERSHIP_GROUP9_CLASSIFICATION=HANDSHAKE} \
    {OWNERSHIP_SLOT_MAX_DELAY_NS=6.000} \
    {OWNERSHIP_GENERATION_MAX_DELAY_NS=6.000} \
    {OWNERSHIP_EPOCH_MAX_DELAY_NS=6.000} \
    {OWNERSHIP_GLOBAL_SKEW_REQUIREMENT=RETIRED_BY_META_4R2} \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {CDC_1_PROTOCOL=ACKNOWLEDGED_STABLE_DATA_MAILBOX} \
    {CDC_1_TRANSPORT_MAX_DELAY_DATAPATH_ONLY_NS=2.500} \
    {CDC_10_PROTOCOL=EXACT_TWO_STAGE_ASYNC_REG_LEVEL_SYNCHRONIZERS} \
    {CDC_13_PROTOCOL=GENERATED_XDMA_PIPE_CLOCK_MUX} \
    "GENERATED_XDC=$generated_xdc" \
    {GENERATED_XDC_S0_FALSE_PATH=PASS} \
    {GENERATED_XDC_S1_FALSE_PATH=PASS} \
    {GENERATED_XDC_CLOCKS_PHYSICALLY_EXCLUSIVE=PASS} \
    {UNEXPECTED_CRITICAL_CDC_ROWS=0} \
    {BROAD_CDC_WAIVER_APPLIED=NO}
  write_lines_atomic [file join $raw_root G2B_CDC_EXACT_DISPOSITION.txt] $disposition_lines
  return 427
}


proc run_timing_gate {} {
  global raw_root
  begin_phase REPORT_TIMING 900
  set phase_start [clock milliseconds]

  set route_path [file join $raw_root ROUTE_STATUS.rpt]
  set summary_path [file join $raw_root TIMING_SUMMARY.rpt]
  set setup_path [file join $raw_root ROUTED_SETUP_TIMING.rpt]
  set hold_path [file join $raw_root ROUTED_HOLD_TIMING.rpt]
  set recovery_removal_path [file join $raw_root ROUTED_RECOVERY_REMOVAL_TIMING.rpt]
  set check_path [file join $raw_root CHECK_TIMING.rpt]
  report_route_status -file $route_path
  report_timing_summary -delay_type min_max -max_paths 1000 \
    -report_unconstrained -check_timing_verbose -file $summary_path
  report_timing -delay_type max -max_paths 1000 -nworst 10 -file $setup_path
  report_timing -delay_type min -max_paths 1000 -nworst 10 -file $hold_path
  report_timing -delay_type min_max -max_paths 1000 -nworst 10 \
    -file $recovery_removal_path
  check_timing -verbose -file $check_path

  set route_now [route_signature]
  if {$route_now ne [list 1 0 0 0]} { error "final route gate failed: $route_now" }
  set wns [routed_worst_slack max]
  set whs [routed_worst_slack min]
  set failing_setup [llength [get_timing_paths -quiet -delay_type max \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set failing_hold [llength [get_timing_paths -quiet -delay_type min \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  if {$wns < 0.0 || $whs < 0.0 || $failing_setup != 0 || $failing_hold != 0} {
    error "final routed timing gate failed: WNS=$wns WHS=$whs setup_fail=$failing_setup hold_fail=$failing_hold"
  }
  set check_text [read_text $check_path]
  set check_counts [dict create]
  foreach category {no_clock unconstrained_internal_endpoints loops latch_loops} {
    set count [check_timing_table_count $check_text $category]
    if {$count ne "0"} { error "check_timing gate failed for $category: $count" }
    dict set check_counts $category $count
  }
  set summary_text [read_text $summary_path]
  set recovery_count [regexp -all -nocase {\(recovery check against} $summary_text]
  set removal_count [regexp -all -nocase {\(removal check against} $summary_text]
  if {$recovery_count == 0 || $removal_count == 0} {
    error "recovery/removal paths expected for this routed design were not exposed"
  }

  set gate_path [file join $raw_root G2B_LUT1_TIMING_GATE.txt]
  write_lines_atomic $gate_path [list \
    {RESULT=PASS} \
    {ROUTED=PASS} \
    {FULLY_ROUTED=1} \
    {ERRORS_IN_ROUTES=0} \
    {UNROUTED_NETS=0} \
    {PARTIAL_NETS=0} \
    {SETUP=PASS} \
    "WNS=$wns" \
    {TNS=0.0} \
    {HOLD=PASS} \
    "WHS=$whs" \
    {THS=0.0} \
    {RECOVERY_REMOVAL=PASS} \
    "RECOVERY_DETAIL_COUNT=$recovery_count" \
    "REMOVAL_DETAIL_COUNT=$removal_count" \
    "NO_CLOCK_COUNT=[dict get $check_counts no_clock]" \
    "UNCONSTRAINED_INTERNAL_ENDPOINTS=[dict get $check_counts unconstrained_internal_endpoints]" \
    "TIMING_LOOP_COUNT=[dict get $check_counts loops]" \
    "LATCH_LOOP_COUNT=[dict get $check_counts latch_loops]" \
    "RUNTIME_SECONDS=[seconds_since $phase_start]"]
  return [dict create path $gate_path sha [sha256_file $gate_path] \
    wns $wns tns 0.0 whs $whs ths 0.0 \
    no_clock [dict get $check_counts no_clock] \
    unconstrained [dict get $check_counts unconstrained_internal_endpoints] \
    loops [dict get $check_counts loops] latch_loops [dict get $check_counts latch_loops]]
}


proc begin_phase {name seconds} {phase $name $seconds}
