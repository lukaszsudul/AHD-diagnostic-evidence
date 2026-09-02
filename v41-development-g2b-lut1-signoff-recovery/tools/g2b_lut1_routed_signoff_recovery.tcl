# AHD v41 G2B-LUT1 governed routed-DCP sign-off recovery.
#
# This tool opens the exact sealed Gen12 routed checkpoint, invalidates the
# inherited timing database, and reloads the complete preserved timing context
# without old Group 9 plus the byte-exact promoted BS3 candidate. It performs
# no synthesis, implementation, hardware, programming, PCIe, or DMA action.
# The PRODUCT bit writer is reached only after every offline gate has passed.

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

proc json_value {value} {
  return [string map [list "\\" "\\\\" "\"" "\\\"" "\r" "\\r" "\n" "\\n" "\t" "\\t"] $value]
}

proc parse_csv_row {line} {
  set fields [list]
  set field ""
  set quoted 0
  set index 0
  set length [string length $line]
  while {$index < $length} {
    set character [string index $line $index]
    if {$quoted} {
      if {$character eq "\""} {
        if {$index + 1 < $length && [string index $line [expr {$index + 1}]] eq "\""} {
          append field "\""
          incr index 2
          continue
        }
        set quoted 0
        incr index
        if {$index < $length && [string index $line $index] ne ","} {
          error "invalid characters after a quoted CSV field"
        }
        continue
      }
      append field $character
      incr index
      continue
    }
    if {$character eq ","} {
      lappend fields $field
      set field ""
    } elseif {$character eq "\""} {
      if {$field ne ""} { error "CSV quote begins after unquoted data" }
      set quoted 1
    } else {
      append field $character
    }
    incr index
  }
  if {$quoted} { error "unterminated quoted CSV field" }
  lappend fields $field
  return $fields
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

proc parse_kv {path} {
  if {![file isfile $path]} { error "required key/value receipt is absent: $path" }
  set values [dict create]
  set line_number 0
  foreach line [split [read_text $path] "\n"] {
    incr line_number
    set line [string trimright $line "\r"]
    if {$line eq ""} { continue }
    set separator [string first "=" $line]
    if {$separator <= 0} { error "invalid key/value row at $path:$line_number" }
    set key [string range $line 0 [expr {$separator - 1}]]
    set value [string range $line [expr {$separator + 1}] end]
    if {[dict exists $values $key]} { error "duplicate receipt key $key in $path" }
    dict set values $key $value
  }
  return $values
}

proc require_kv {values key {expected __ANY__}} {
  if {![dict exists $values $key]} { error "required receipt key is absent: $key" }
  set value [dict get $values $key]
  if {$expected ne "__ANY__" && $value ne $expected} {
    error "receipt drift for $key: expected '$expected', got '$value'"
  }
  return $value
}

proc require_hash_value {value label} {
  set value [string toupper $value]
  if {![regexp {^[0-9A-F]{64}$} $value]} { error "$label is not an uppercase SHA-256 value" }
  return $value
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

proc begin_phase {name timeout_seconds} {
  global phase_marker
  write_lines_atomic $phase_marker [list \
    "PHASE=$name" \
    "TIMEOUT_SECONDS=$timeout_seconds" \
    "EPOCH_SECONDS=[clock seconds]" \
    "EPOCH_MILLISECONDS=[clock milliseconds]" \
    "PROCESS_ID=[pid]"]
  puts "G2B_LUT1_PHASE=$name TIMEOUT_SECONDS=$timeout_seconds"
  flush stdout
}

proc count_xdc_command_lines {text command_name} {
  set expression [format {^[ \t]*%s(?:[ \t]|$)} $command_name]
  return [regexp -all -line $expression $text]
}

proc git_value {repo args} {
  return [string trim [exec git --no-optional-locks -C $repo {*}$args]]
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

proc read_name_list {path} {
  set names [list]
  foreach line [split [read_text $path] "\n"] {
    set line [string trim $line]
    if {$line ne ""} { lappend names $line }
  }
  return [lsort -dictionary $names]
}

proc require_exact_identity {label objects reference_path reference_sha expected_count} {
  if {[sha256_file $reference_path] ne $reference_sha} {
    error "$label qualified reference hash drift"
  }
  set actual [collection_names $objects]
  set expected [read_name_list $reference_path]
  if {[llength $actual] != $expected_count || [llength $expected] != $expected_count} {
    error "$label exact-identity count mismatch"
  }
  if {$actual ne $expected} { error "$label resolved identity differs from the accepted BS3 reference" }
}

proc route_signature {} {
  return [list \
    [report_route_status -boolean_check ROUTED_FULLY] \
    [report_route_status -boolean_check ERRORS_IN_ROUTES] \
    [llength [report_route_status -return_nets -route_type UNROUTED]] \
    [llength [report_route_status -return_nets -route_type PARTIAL]]]
}

proc clock_signature {} {
  set rows [list]
  foreach clock [lsort -dictionary [get_clocks -quiet]] {
    lappend rows "[get_property NAME $clock]|[get_property PERIOD $clock]|[get_property WAVEFORM $clock]"
  }
  if {[llength $rows] == 0} { error "clock signature is empty" }
  return [join $rows "\n"]
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

proc validate_source_identity {} {
  global repo_root source_manifest active_xdc
  global expected_source_branch expected_source_parent expected_source_commit expected_source_tree
  global expected_source_manifest_sha expected_old_active_xdc_sha expected_active_xdc_sha

  if {[git_value $repo_root branch --show-current] ne $expected_source_branch ||
      [git_value $repo_root rev-parse HEAD] ne $expected_source_commit ||
      [git_value $repo_root rev-parse {HEAD^{tree}}] ne $expected_source_tree ||
      [git_value $repo_root rev-parse HEAD^] ne $expected_source_parent} {
    error "governed source branch/parent/commit/tree drift"
  }
  if {[git_value $repo_root status --porcelain=v1 --untracked-files=all] ne ""} {
    error "governed source worktree is not clean"
  }
  if {[sha256_file $source_manifest] ne $expected_source_manifest_sha} {
    error "sealed Gen12 source manifest hash drift"
  }

  set count 0
  set seen [dict create]
  foreach line [split [string trimright [read_text $source_manifest] "\n"] "\n"] {
    incr count
    set separator [string first "|" $line]
    if {$separator <= 0} { error "invalid sealed source manifest row $count" }
    set relative [string range $line 0 [expr {$separator - 1}]]
    set expected [string range $line [expr {$separator + 1}] end]
    if {[dict exists $seen $relative] || ![regexp {^[0-9A-F]{64}$} $expected]} {
      error "duplicate or invalid sealed source manifest row $count"
    }
    dict set seen $relative 1
    set absolute [file join $repo_root {*}[file split $relative]]
    set actual [sha256_file $absolute]
    if {$relative eq "xdc/common/g2b_cdc.xdc"} {
      if {$expected ne $expected_old_active_xdc_sha || $actual ne $expected_active_xdc_sha} {
        error "the sole authorized post-route XDC transition does not match the governed identities"
      }
    } elseif {$actual ne $expected} {
      error "non-XDC sealed source input drift: $relative"
    }
  }
  if {$count != 35 || [dict size $seen] != 35 ||
      ![dict exists $seen "xdc/common/g2b_cdc.xdc"]} {
    error "sealed source manifest must contain exactly 35 inputs including active G2B XDC"
  }
  if {[file normalize $active_xdc] ne [file normalize [file join $repo_root xdc common g2b_cdc.xdc]] ||
      [sha256_file $active_xdc] ne $expected_active_xdc_sha} {
    error "active G2B XDC path or hash drift"
  }
  return PASS
}

proc validate_governed_static_inputs {} {
  global checkpoint base_xdc candidate_xdc active_xdc xpr_path xdma_xci
  global structural_proof request_ack_proof cdc_invariants
  global expected_checkpoint_sha expected_base_xdc_sha expected_candidate_xdc_sha
  global expected_active_xdc_sha expected_xpr_sha expected_xdma_xci_sha

  foreach {path expected label} [list \
      $checkpoint $expected_checkpoint_sha {sealed routed DCP} \
      $base_xdc $expected_base_xdc_sha {full base without Group 9} \
      $candidate_xdc $expected_candidate_xdc_sha {BS3 candidate} \
      $active_xdc $expected_active_xdc_sha {active G2B XDC} \
      $xpr_path $expected_xpr_sha {sealed Gen12 project} \
      $xdma_xci $expected_xdma_xci_sha {governed XDMA XCI} \
      $structural_proof 6D3FAE47B6BD455F0FAF49399B710B434BB3C4642F80DB66A51AFC733B76B198 {BS3 structural proof} \
      $request_ack_proof 128E714EF2012BDC365F547763E8247E9D4CE841A9BC50113E66E31F374377EE {BS3 request/ack proof} \
      $cdc_invariants E49F7341BD367E17533E29DC9E6EB21160BC051490C3245D024EA7A34A59AAA1 {BS3 CDC invariants}] {
    if {[sha256_file $path] ne $expected} { error "$label identity drift" }
  }
  if {[count_xdc_command_lines [read_text $base_xdc] set_bus_skew] != 16 ||
      [count_xdc_command_lines [read_text $base_xdc] set_max_delay] != 9} {
    error "preserved base XDC constraint census drift"
  }
  if {[count_xdc_command_lines [read_text $candidate_xdc] set_bus_skew] != 0 ||
      [count_xdc_command_lines [read_text $candidate_xdc] set_max_delay] != 3} {
    error "BS3 candidate constraint census drift"
  }
  if {[string first [read_text $candidate_xdc] [read_text $active_xdc]] < 0} {
    error "byte-exact BS3 candidate is not embedded in active XDC"
  }
  set xci_text [read_text $xdma_xci]
  if {![regexp {"pl_link_cap_max_link_width":[^\n]*"value":[ \t]*"X1"} $xci_text] ||
      ![regexp {"pl_link_cap_max_link_speed":[^\n]*"value":[ \t]*"5\.0_GT/s"} $xci_text] ||
      ![regexp {"axisten_freq":[^\n]*"value":[ \t]*"62\.5"} $xci_text]} {
    error "governed XDMA Gen2 x1 or 62.5 MHz configuration drift"
  }
  return PASS
}

proc validate_groups10_17_gate {} {
  global evidence_root groups_gate groups_csv
  global expected_checkpoint_sha expected_base_xdc_sha expected_candidate_xdc_sha
  set values [parse_kv $groups_gate]
  require_kv $values STATE COMPLETE
  require_kv $values GROUPS10_17_GATE PASS
  require_kv $values GROUP_IDS 10,11,12,13,14,15,16,17
  require_kv $values SEALED_DCP_SHA256 $expected_checkpoint_sha
  require_kv $values BASE_XDC_SHA256 $expected_base_xdc_sha
  require_kv $values BS3_CANDIDATE_XDC_SHA256 $expected_candidate_xdc_sha
  set worker_sha [require_hash_value [require_kv $values WORKER_TCL_SHA256] WORKER_TCL_SHA256]
  set orchestrator_sha [require_hash_value \
    [require_kv $values ORCHESTRATOR_PS1_SHA256] ORCHESTRATOR_PS1_SHA256]
  set worker_path [file join $evidence_root tools G2B_LUT1_GROUPS10_17_WORKER.tcl]
  set orchestrator_path [file join $evidence_root tools Invoke-G2BLut1Groups10To17.ps1]
  if {[sha256_file $worker_path] ne $worker_sha ||
      [sha256_file $orchestrator_path] ne $orchestrator_sha} {
    error "Groups 10-17 receipt is not bound to the present governed worker/orchestrator"
  }
  require_kv $values GROUPS_REQUIRED 8
  require_kv $values GROUPS_PASS 8
  require_kv $values GROUPS_FAIL 0
  require_kv $values GROUPS_TIMEOUT 0
  require_kv $values ATTEMPTS_PER_GROUP 1
  require_kv $values INITIALIZATION_TIMEOUT_SECONDS 1800
  require_kv $values QUERY_TIMEOUT_SECONDS 300
  require_kv $values GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED NO
  require_kv $values HARDWARE_ACCESSED NO
  require_kv $values FIRST_BLOCKER NONE
  set receipt_csv [file normalize [require_kv $values RESULTS_CSV]]
  if {$receipt_csv ne [file normalize $groups_csv]} {
    error "Groups 10-17 results CSV path drift"
  }
  set expected_csv_sha [require_hash_value [require_kv $values RESULTS_CSV_SHA256] RESULTS_CSV_SHA256]
  if {[sha256_file $groups_csv] ne $expected_csv_sha} {
    error "Groups 10-17 results CSV hash drift"
  }
  set csv_lines [list]
  foreach line [split [read_text $groups_csv] "\n"] {
    set line [string trimright $line "\r"]
    if {$line ne ""} { lappend csv_lines $line }
  }
  set expected_header [list Group_ID Name Command Runtime_s Result Actual_ns Required_ns Slack_ns \
    Warning_Count Warnings Source_Count Destination_Count Timeout_Phase Process_Exit_Code]
  if {[llength $csv_lines] != 9 || [parse_csv_row [lindex $csv_lines 0]] ne $expected_header} {
    error "Groups 10-17 results CSV header drift"
  }
  for {set index 1} {$index <= 8} {incr index} {
    set fields [parse_csv_row [lindex $csv_lines $index]]
    set expected_group [expr {$index + 9}]
    if {[llength $fields] != 14 || [lindex $fields 0] ne $expected_group ||
        [lindex $fields 4] ne "PASS"} {
      error "Groups 10-17 CSV row $index is not the exact ordered PASS result for Group $expected_group"
    }
  }
  return $expected_csv_sha
}

proc validate_offline_protection_gate {} {
  global offline_gate expected_offline_gate_sha expected_source_commit expected_source_tree
  if {[sha256_file $offline_gate] ne $expected_offline_gate_sha} {
    error "offline protection gate does not match caller-provided SHA-256"
  }
  set values [parse_kv $offline_gate]
  require_kv $values RESULT PASS
  require_kv $values SOURCE_COMMIT $expected_source_commit
  require_kv $values SOURCE_TREE $expected_source_tree
  require_kv $values TRANSPORT_ABI AHD_C2H_TRANSPORT_ABI_V1
  require_kv $values ABI_VERSION 1
  require_kv $values MMIO_RANGE 0x3800..0x3BFF
  require_kv $values ABI_MMIO_UNCHANGED YES
  require_kv $values R1I_PROTECTED_BEHAVIOR PASS
  require_kv $values OFFLINE_THROUGHPUT_GATE PASS
  require_kv $values REQUIRED_PAYLOAD_MBPS 288
  require_kv $values HARDWARE_THROUGHPUT_PROVEN NO
  require_kv $values PRODUCT_PROFILE PASS
  require_kv $values XDMA_CONFIG_PRESERVED PASS
  require_kv $values GEN2_CONFIG 5.0_GT/s_X1
  require_kv $values SSOT_REV4_COMPATIBILITY PASS
  require_kv $values HARDWARE_ACCESSED NO
  return PASS
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

proc assert_sync_chain {label launch_name sync1_name sync2_name} {
  set launch [get_cells -quiet $launch_name]
  set sync1 [get_cells -quiet $sync1_name]
  set sync2 [get_cells -quiet $sync2_name]
  if {[llength $launch] != 1 || [llength $sync1] != 1 || [llength $sync2] != 1} {
    error "$label ownership synchronizer identity did not resolve 1+1+1"
  }
  foreach cell [list $sync1 $sync2] {
    if {![property_is_true [property_or_unknown ASYNC_REG $cell]]} {
      error "$label synchronizer lacks ASYNC_REG=TRUE: [get_property NAME $cell]"
    }
  }
  set sync1_d [get_pins -quiet -of_objects $sync1 -filter {REF_PIN_NAME == D}]
  set sync1_q [get_pins -quiet -of_objects $sync1 -filter {REF_PIN_NAME == Q}]
  set sync2_d [get_pins -quiet -of_objects $sync2 -filter {REF_PIN_NAME == D}]
  if {[llength $sync1_d] != 1 || [llength $sync1_q] != 1 || [llength $sync2_d] != 1} {
    error "$label synchronizer D/Q pin identity drift"
  }
  set input_net [get_nets -quiet -of_objects $sync1_d]
  set driver_pins [get_pins -quiet -of_objects $input_net -filter {DIRECTION == OUT}]
  set driver_cells [unique_objects_by_name [get_cells -quiet -of_objects $driver_pins]]
  if {[lsearch -exact [collection_names $driver_cells] $launch_name] < 0} {
    error "$label synchronizer first-stage topology does not originate at $launch_name"
  }
  set first_stage_paths [get_timing_paths -quiet -from $launch -to $sync1_d -max_paths 1 -nworst 1]
  if {[llength $first_stage_paths] != 0} {
    error "$label synchronizer first-stage D is not false-pathed"
  }
  set second_stage_paths [get_timing_paths -quiet -delay_type max \
    -from $sync1_q -to $sync2_d -max_paths 1 -nworst 1]
  if {[llength $second_stage_paths] != 1} {
    error "$label sync1-to-sync2 path is absent or false-pathed"
  }
  set slack [get_property SLACK [lindex $second_stage_paths 0]]
  if {![string is double -strict $slack]} {
    error "$label sync1-to-sync2 path slack is not numeric"
  }
  return $slack
}

proc run_family_gate {label sources destinations destination_d report_path} {
  if {[llength $destination_d] != [llength $destinations]} {
    error "$label destination cell/D-pin count mismatch"
  }
  set paths [get_timing_paths -quiet -delay_type max -sort_by slack \
    -max_paths 1 -nworst 1 -from $sources -to $destination_d]
  if {[llength $paths] != 1} { error "$label did not return exactly one worst path" }
  set path [lindex $paths 0]
  set actual [property_or_unknown DATAPATH_DELAY $path]
  set slack [property_or_unknown SLACK $path]
  set requirement [property_or_unknown REQUIREMENT $path]
  set start_clock [property_or_unknown STARTPOINT_CLOCK $path]
  set end_clock [property_or_unknown ENDPOINT_CLOCK $path]
  if {![string is double -strict $actual] || $actual > 6.000 ||
      ![string is double -strict $slack] || $slack < 0.0 ||
      ![string is double -strict $requirement] || abs($requirement - 6.000) > 0.0005 ||
      $start_clock ne "userclk1" || $end_clock ne "nvp_vclk1"} {
    error "$label family settling gate failed: actual=$actual slack=$slack requirement=$requirement clocks=$start_clock->$end_clock"
  }
  report_timing -of_objects $path -file $report_path
  return [dict create \
    label $label required 6.000 actual $actual slack $slack \
    source_count [llength $sources] destination_count [llength $destinations] \
    startpoint [property_or_unknown STARTPOINT_PIN $path] \
    endpoint [property_or_unknown ENDPOINT_PIN $path]]
}

proc run_ownership_gate {slot_sources generation_sources epoch_sources destinations destination_d} {
  global evidence_root raw_root
  global slot_reference generation_reference epoch_reference destination_reference
  global structural_proof request_ack_proof cdc_invariants
  global expected_source_commit expected_source_tree expected_checkpoint_sha
  global expected_base_xdc_sha expected_candidate_xdc_sha expected_active_xdc_sha

  begin_phase REPORT_OWNERSHIP 900
  set phase_start [clock milliseconds]

  if {[llength $slot_sources] != 2 || [llength $generation_sources] != 24 ||
      [llength $epoch_sources] != 32 || [llength $destinations] != 17 ||
      [llength $destination_d] != 17} {
    error "BS3 object-count gate failed: slot=[llength $slot_sources] generation=[llength $generation_sources] epoch=[llength $epoch_sources] destinations=[llength $destinations]/[llength $destination_d]"
  }
  require_exact_identity SLOT $slot_sources $slot_reference \
    EEC952FD391CBDE81D7BA5918BB293C1C309C8D3A5E511A86884B3F2FDBC7668 2
  require_exact_identity GENERATION $generation_sources $generation_reference \
    FEBDD92ABC37EBCF3E24F77A5F25F95A46C4724506EAC97ABCB5D417693EF133 24
  require_exact_identity EPOCH $epoch_sources $epoch_reference \
    3764639B5C1F5D32DD6719B678DACC3E2AB92DD2F05ABDE6F87AF52B62029067 32
  require_exact_identity DESTINATION $destinations $destination_reference \
    DB9E7D0702A572DD61E33792E607F90D8FF04A1A71B5656D68CACDC187492D6A 17

  set request_slack [assert_sync_chain REQUEST \
    G2B_ONECH_C2H/own_req_toggle_axi_reg \
    G2B_ONECH_C2H/own_req_sync1_source_reg \
    G2B_ONECH_C2H/own_req_sync2_source_reg]
  set ack_slack [assert_sync_chain ACK \
    G2B_ONECH_C2H/own_ack_toggle_source_reg \
    G2B_ONECH_C2H/own_ack_sync1_axi_reg \
    G2B_ONECH_C2H/own_ack_sync2_axi_reg]

  set user_clock [get_clocks -quiet userclk1]
  set source_clock [get_clocks -quiet nvp_vclk1]
  if {[llength $user_clock] != 1 || [llength $source_clock] != 1} {
    error "ownership clocks did not resolve exactly once"
  }
  set user_period [get_property PERIOD $user_clock]
  set source_period [get_property PERIOD $source_clock]
  if {![string is double -strict $user_period] || abs($user_period - 16.000) > 0.0005 ||
      ![string is double -strict $source_period] || abs($source_period - 6.734) > 0.0005} {
    error "ownership clock period drift: userclk1=$user_period nvp_vclk1=$source_period"
  }
  set semantic_window [expr {2.0 * $source_period}]
  set reserve [expr {$semantic_window - 6.0}]
  if {abs($semantic_window - 13.468) > 0.0005 || abs($reserve - 7.468) > 0.0005} {
    error "ownership semantic window/reserve drift"
  }

  set family_results [list]
  foreach {label sources} [list \
      SLOT $slot_sources GENERATION $generation_sources EPOCH $epoch_sources] {
    lappend family_results [run_family_gate $label $sources $destinations $destination_d \
      [file join $raw_root "GROUP9_${label}_WORST_PATH.rpt"]]
  }
  set csv_lines [list {Family,Required_ns,Actual_Worst_ns,Slack_ns,Result,Source_Count,Destination_Count}]
  foreach result $family_results {
    lappend csv_lines "[dict get $result label],[dict get $result required],[dict get $result actual],[dict get $result slack],PASS,[dict get $result source_count],[dict get $result destination_count]"
  }
  set csv_path [file join $evidence_root G2B_LUT1_GROUP9_SIGNOFF_RESULTS.csv]
  write_lines_atomic $csv_path $csv_lines

  set focused_path [file join $raw_root GROUP9_AND_REMAINING_TIMING_METHODOLOGY.rpt]
  report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39} \
    -file $focused_path
  set focused_text [read_text $focused_path]
  set timing34_count [regexp -all -line {^TIMING-34#[0-9]+ Warning} $focused_text]
  set timing39_count [regexp -all -line {^TIMING-39#[0-9]+ Warning} $focused_text]
  if {$timing34_count != 16 || $timing39_count != 6} {
    error "focused timing methodology census drift: TIMING-34=$timing34_count TIMING-39=$timing39_count"
  }

  set gate_path [file join $raw_root G2B_LUT1_GROUP9_FINALIZER_GATE.txt]
  set gate_lines [list \
    {RESULT=PASS} \
    {METHOD=PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC} \
    "SOURCE_COMMIT=$expected_source_commit" \
    "SOURCE_TREE=$expected_source_tree" \
    "SEALED_DCP_SHA256=$expected_checkpoint_sha" \
    "BASE_XDC_SHA256=$expected_base_xdc_sha" \
    "BS3_CANDIDATE_XDC_SHA256=$expected_candidate_xdc_sha" \
    "ACTIVE_XDC_SHA256=$expected_active_xdc_sha" \
    "STRUCTURAL_PROOF_SHA256=[sha256_file $structural_proof]" \
    "REQUEST_ACK_PROOF_SHA256=[sha256_file $request_ack_proof]" \
    "CDC_INVARIANTS_SHA256=[sha256_file $cdc_invariants]" \
    {REQUEST_SYNCHRONIZER=PASS} \
    {REQUEST_SYNC_STAGE_COUNT=2} \
    "REQUEST_SYNC1_TO_SYNC2_SLACK_NS=$request_slack" \
    {ACK_SYNCHRONIZER=PASS} \
    {ACK_SYNC_STAGE_COUNT=2} \
    "ACK_SYNC1_TO_SYNC2_SLACK_NS=$ack_slack" \
    {ASYNC_REG=PASS} \
    {FALSE_PATH_ONLY_TO_SYNC1=PASS} \
    {SYNC1_TO_SYNC2_NORMALLY_TIMED=PASS} \
    {STABLE_DATA_HOLD=PASS_HASH_BOUND_BS3_STRUCTURAL_PROOF} \
    {RESET_EPOCH_COHERENCY=PASS_HASH_BOUND_BS3_STRUCTURAL_PROOF} \
    {SLOT_FAMILY=PASS} \
    {GENERATION_FAMILY=PASS} \
    {EPOCH_FAMILY=PASS} \
    {SETTLING_CAP_NS=6.000} \
    "EARLIEST_SEMANTIC_USE_NS=[format %.3f $semantic_window]" \
    "GROSS_RESERVE_NS=[format %.3f $reserve]" \
    "TIMING_34_REMAINING_NON_GROUP9_COUNT=$timing34_count" \
    "TIMING_39_REMAINING_NON_GROUP9_COUNT=$timing39_count" \
    {GROUP9_TIMING_34_ATTRIBUTABLE=0} \
    {GROUP9_TIMING_39_ATTRIBUTABLE=0} \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    "RESULTS_CSV=$csv_path" \
    "RESULTS_CSV_SHA256=[sha256_file $csv_path]" \
    "RUNTIME_SECONDS=[seconds_since $phase_start]" \
    {HARDWARE_ACCESSED=NO}]
  foreach result $family_results {
    set label [dict get $result label]
    lappend gate_lines \
      "${label}_ACTUAL_WORST_NS=[dict get $result actual]" \
      "${label}_SLACK_NS=[dict get $result slack]" \
      "${label}_SOURCE_COUNT=[dict get $result source_count]" \
      "${label}_DESTINATION_COUNT=[dict get $result destination_count]"
  }
  write_lines_atomic $gate_path $gate_lines
  return [dict create path $gate_path sha [sha256_file $gate_path] csv $csv_path \
    csv_sha [sha256_file $csv_path] results $family_results]
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

proc run_drc_gate {} {
  global raw_root
  begin_phase REPORT_DRC 900
  set phase_start [clock milliseconds]
  set drc_path [file join $raw_root DRC.rpt]
  report_drc -file $drc_path
  set errors 0
  set critical_warnings 0
  set warnings 0
  set inventory [list {Name,Severity,Description,Disposition}]
  foreach violation [lsort -dictionary [get_drc_violations -quiet]] {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "ERROR"} { incr errors }
    if {$severity eq "CRITICAL WARNING"} { incr critical_warnings }
    if {$severity eq "WARNING"} { incr warnings }
    if {$severity eq "ERROR" || $severity eq "CRITICAL WARNING"} {
      set disposition RELEASE_BLOCKING
    } else {
      set disposition INVENTORIED_NON_BLOCKING
    }
    lappend inventory "[csv_value [get_property NAME $violation]],[csv_value $severity],[csv_value [property_or_unknown DESCRIPTION $violation]],[csv_value $disposition]"
  }
  write_lines_atomic [file join $raw_root DRC_WARNING_INVENTORY.csv] $inventory
  if {$errors != 0 || $critical_warnings != 0} {
    error "DRC gate failed: errors=$errors critical_warnings=$critical_warnings"
  }
  set gate_path [file join $raw_root G2B_LUT1_DRC_GATE.txt]
  write_lines_atomic $gate_path [list \
    {RESULT=PASS} \
    "ERRORS=$errors" \
    "CRITICAL_WARNINGS=$critical_warnings" \
    "WARNINGS=$warnings" \
    {WARNING_DISPOSITION=INVENTORIED_NON_BLOCKING} \
    {CLOCK_ROUTING_DRC=PASS} \
    "RUNTIME_SECONDS=[seconds_since $phase_start]"]
  return [dict create path $gate_path sha [sha256_file $gate_path] \
    errors $errors critical_warnings $critical_warnings warnings $warnings]
}

proc run_cdc_gate {} {
  global raw_root
  begin_phase REPORT_CDC 900
  set phase_start [clock milliseconds]
  set cdc_path [file join $raw_root CDC.rpt]
  report_cdc -details -file $cdc_path
  set violations [get_cdc_violations -quiet]
  set critical 0
  set unknown 0
  foreach violation $violations {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "CRITICAL" || $severity eq "CRITICAL WARNING"} { incr critical }
    if {$severity eq "UNKNOWN"} { incr unknown }
  }
  if {$critical != 427 || $unknown != 0} {
    error "CDC object gate failed: critical=$critical unknown=$unknown"
  }
  set dispositioned [enforce_exact_cdc_disposition $cdc_path $violations]
  if {$dispositioned != 427} { error "CDC exact disposition count failed" }
  set gate_path [file join $raw_root G2B_LUT1_CDC_GATE.txt]
  write_lines_atomic $gate_path [list \
    {RESULT=PASS} \
    "CDC_CRITICAL=$critical" \
    "CDC_CRITICAL_DISPOSITIONED=$dispositioned" \
    {CDC_REQUIRES_RTL_CHANGE=0} \
    {CDC_UNRESOLVED=0} \
    "CDC_UNKNOWN=$unknown" \
    {OWNERSHIP_CDC=PASS} \
    {OWNERSHIP_CLASSIFICATION=HANDSHAKE} \
    {OWNERSHIP_METHOD=PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC} \
    "RUNTIME_SECONDS=[seconds_since $phase_start]"]
  return [dict create path $gate_path sha [sha256_file $gate_path] \
    critical $critical dispositioned $dispositioned unknown $unknown]
}

proc run_clock_resource_gate {timing drc cdc} {
  global raw_root xdma_xci expected_xdma_xci_sha
  begin_phase REPORT_CLOCKS_RESOURCES 900
  set phase_start [clock milliseconds]

  if {[dict get $timing no_clock] ne "0" || [dict get $timing unconstrained] ne "0" ||
      [dict get $drc errors] != 0 || [dict get $drc critical_warnings] != 0 ||
      [dict get $cdc critical] != 427 || [dict get $cdc dispositioned] != 427 ||
      [dict get $cdc unknown] != 0} {
    error "clock sign-off prerequisites are not the current PASS timing/DRC/CDC gates"
  }

  set clocks_path [file join $raw_root CLOCKS.rpt]
  set interactions_path [file join $raw_root CLOCK_INTERACTION.rpt]
  report_clocks -file $clocks_path
  report_clock_utilization -file [file join $raw_root CLOCK_UTILIZATION.rpt]
  report_clock_interaction -file $interactions_path
  report_exceptions -coverage -file [file join $raw_root EXCEPTION_COVERAGE.rpt]

  set nvp_clock_pins [get_pins -quiet -hier -regexp {.*NVP_AUTOINIT.*/C}]
  set axi_clock_pins [get_pins -quiet -hier -regexp {.*AXI_LITE_HOST_BRIDGE.*/C}]
  set nvp_clocks [unique_objects_by_name [get_clocks -quiet -of_objects $nvp_clock_pins]]
  set axi_clocks [unique_objects_by_name [get_clocks -quiet -of_objects $axi_clock_pins]]
  if {[llength $nvp_clock_pins] == 0 || [llength $axi_clock_pins] == 0 ||
      [llength $nvp_clocks] != 1 || [llength $axi_clocks] != 1 ||
      [collection_names $nvp_clocks] ne [collection_names $axi_clocks]} {
    error "effective application clock objects unavailable or inconsistent"
  }
  set application_clock [lindex $nvp_clocks 0]
  set application_period [get_property PERIOD $application_clock]
  if {![string is double -strict $application_period] || $application_period <= 0.0} {
    error "invalid effective application clock period"
  }
  set effective_frequency [expr {1000.0 / $application_period}]
  if {abs($effective_frequency - 62.5) > 0.1} {
    error "effective application clock drift: $effective_frequency MHz"
  }
  set all_clock_lines [list]
  set clock_index 0
  foreach clock [lsort -dictionary [get_clocks -quiet]] {
    set period [property_or_unknown PERIOD $clock]
    if {![string is double -strict $period] || $period <= 0.0} {
      error "clock has a nonnumeric or nonpositive period: [get_property NAME $clock]=$period"
    }
    set frequency [format %.6f [expr {1000.0 / $period}]]
    lappend all_clock_lines \
      "CLOCK_${clock_index}_NAME=[get_property NAME $clock]" \
      "CLOCK_${clock_index}_PERIOD_NS=$period" \
      "CLOCK_${clock_index}_FREQUENCY_MHZ=$frequency" \
      "CLOCK_${clock_index}_GENERATED=[property_or_unknown IS_GENERATED $clock]"
    incr clock_index
  }
  set clock_gate_path [file join $raw_root G2B_LUT1_CLOCK_GATE.txt]
  write_lines_atomic $clock_gate_path [list \
    {RESULT=PASS} \
    "CLOCK_COUNT=$clock_index" \
    "NVP_AUTOINIT_CLOCK_PIN_COUNT=[llength $nvp_clock_pins]" \
    "AXI_BRIDGE_CLOCK_PIN_COUNT=[llength $axi_clock_pins]" \
    "EFFECTIVE_CLOCK_OBJECT=[get_property NAME $application_clock]" \
    "EFFECTIVE_USER_CLOCK_MHZ=[format %.6f $effective_frequency]" \
    "EFFECTIVE_AXI_CLOCK_MHZ=[format %.6f $effective_frequency]" \
    "UNCONSTRAINED_CLOCKS=[dict get $timing no_clock]" \
    "UNCONSTRAINED_INTERNAL_ENDPOINTS=[dict get $timing unconstrained]" \
    {CLOCK_INTERACTION_REPORT=GENERATED} \
    "CLOCK_INTERACTION_REPORT_SHA256=[sha256_file $interactions_path]" \
    {CLOCK_INTERACTION_DISPOSITION=PASS_BY_EXACT_427_ENTRY_CDC_GATE_AND_ROUTED_TIMING_GATE} \
    "CLOCK_ROUTING_DRC_ERRORS=[dict get $drc errors]" \
    "CLOCK_ROUTING_DRC_CRITICAL_WARNINGS=[dict get $drc critical_warnings]" \
    {CLOCK_ROUTING_DRC=PASS_FROM_FRESH_ZERO_ERROR_ZERO_CRITICAL_WARNING_DRC_GATE} \
    {*}$all_clock_lines]

  set utilization_text [report_utilization -return_string]
  write_text_atomic [file join $raw_root ROUTED_UTILIZATION_FLAT.rpt] $utilization_text
  report_ram_utilization -file [file join $raw_root RAM_UTILIZATION.rpt]
  lassign [utilization_row $utilization_text "Slice LUTs"] lut_used lut_available
  lassign [utilization_row $utilization_text "Slice Registers"] ff_used ff_available
  lassign [utilization_row $utilization_text "Block RAM Tile"] bram_used bram_available
  lassign [utilization_row $utilization_text "DSPs"] dsp_used dsp_available
  set lut_percent [expr {100.0 * $lut_used / $lut_available}]
  set ff_percent [expr {100.0 * $ff_used / $ff_available}]
  set bram_percent [expr {100.0 * $bram_used / $bram_available}]
  set dsp_percent [expr {100.0 * $dsp_used / $dsp_available}]
  if {$lut_available != 20800 || $ff_available != 41600 ||
      $bram_available != 50 || $dsp_available != 90 ||
      $lut_percent > 90.0} {
    error "PRODUCT routed resource gate failed"
  }
  set black_boxes [get_cells -quiet -hier -filter {IS_BLACKBOX == 1}]
  if {[llength $black_boxes] != 0} { error "unresolved black-box gate failed" }
  set resource_gate_path [file join $raw_root G2B_LUT1_RESOURCE_GATE.txt]
  write_lines_atomic $resource_gate_path [list \
    {RESULT=PASS} \
    {BUILD_PROFILE=PRODUCT} \
    "LUT_USED=$lut_used" \
    "LUT_AVAILABLE=$lut_available" \
    "LUT_PERCENT=[format %.3f $lut_percent]" \
    "FF_USED=$ff_used" \
    "FF_AVAILABLE=$ff_available" \
    "FF_PERCENT=[format %.3f $ff_percent]" \
    "BRAM_USED=$bram_used" \
    "BRAM_AVAILABLE=$bram_available" \
    "BRAM_PERCENT=[format %.3f $bram_percent]" \
    "DSP_USED=$dsp_used" \
    "DSP_AVAILABLE=$dsp_available" \
    "DSP_PERCENT=[format %.3f $dsp_percent]" \
    {PRODUCT_LUT_LE_90_PERCENT=PASS} \
    {UNRESOLVED_BLACK_BOXES=0}]

  report_methodology -file [file join $raw_root METHODOLOGY.rpt]
  report_property -file [file join $raw_root ROUTED_DESIGN_PROPERTIES.txt] [current_design]
  set pcie_blocks [get_cells -quiet -hier -filter {REF_NAME == PCIE_2_1}]
  set gt_channels [get_cells -quiet -hier -filter {REF_NAME == GTPE2_CHANNEL}]
  set gt_commons [get_cells -quiet -hier -filter {REF_NAME == GTPE2_COMMON}]
  if {[llength $pcie_blocks] != 1 || [llength $gt_channels] != 1 ||
      [llength $gt_commons] != 1} {
    error "implemented PCIe primitive identity drift"
  }
  report_property -file [file join $raw_root PCIE_2_1_PROPERTIES.txt] $pcie_blocks
  set implemented_speed_code [property_or_unknown LINK_CAP_MAX_LINK_SPEED $pcie_blocks]
  set implemented_width_code [property_or_unknown LINK_CAP_MAX_LINK_WIDTH $pcie_blocks]
  if {$implemented_speed_code eq "UNKNOWN" ||
      $implemented_speed_code ni {2 4'h2 4'H2 GEN2 5.0_GT/s}} {
    error "implemented PCIe maximum-link-speed property is absent or contradicts governed Gen2"
  }
  if {$implemented_width_code eq "UNKNOWN" ||
      $implemented_width_code ni {1 6'h01 6'H01 X1}} {
    error "implemented PCIe maximum-link-width property is absent or contradicts governed x1"
  }
  set config_gate_path [file join $raw_root G2B_LUT1_XDMA_CONFIG_GATE.txt]
  write_lines_atomic $config_gate_path [list \
    {RESULT=PASS} \
    {XDMA_GENERATION=GEN2} \
    {XDMA_LINK_SPEED=5.0_GT/s} \
    {XDMA_LINK_WIDTH=X1} \
    {XDMA_APPLICATION_CLOCK_MHZ=62.5} \
    "IMPLEMENTED_LINK_SPEED_CODE=$implemented_speed_code" \
    "IMPLEMENTED_LINK_WIDTH_CODE=$implemented_width_code" \
    {IMPLEMENTED_CONFIG_BASIS=SEALED_DCP_PLUS_GOVERNED_XCI_PLUS_PCIE_PRIMITIVE_PROPERTY_REPORT} \
    "XDMA_XCI=$xdma_xci" \
    "XDMA_XCI_SHA256=$expected_xdma_xci_sha" \
    {PCIE_2_1_COUNT=1} \
    {GTPE2_CHANNEL_COUNT=1} \
    {GTPE2_COMMON_COUNT=1} \
    {CONFIGURATION_CHANGED=NO}]

  return [dict create \
    clock_path $clock_gate_path clock_sha [sha256_file $clock_gate_path] \
    resource_path $resource_gate_path resource_sha [sha256_file $resource_gate_path] \
    config_path $config_gate_path config_sha [sha256_file $config_gate_path] \
    effective_frequency [format %.6f $effective_frequency] \
    lut_used $lut_used lut_available $lut_available lut_percent [format %.3f $lut_percent] \
    ff_used $ff_used ff_available $ff_available ff_percent [format %.3f $ff_percent] \
    bram_used $bram_used bram_available $bram_available bram_percent [format %.3f $bram_percent] \
    dsp_used $dsp_used dsp_available $dsp_available dsp_percent [format %.3f $dsp_percent] \
    black_boxes [llength $black_boxes] runtime [seconds_since $phase_start]]
}

proc validate_external_group9_gate {} {
  global external_group9_gate expected_external_group9_gate_sha
  global expected_source_commit expected_source_tree
  global expected_checkpoint_sha expected_base_xdc_sha expected_candidate_xdc_sha
  global expected_active_xdc_sha
  if {[sha256_file $external_group9_gate] ne $expected_external_group9_gate_sha} {
    error "fresh Group-9 recovery gate does not match caller-provided SHA-256"
  }
  set values [parse_kv $external_group9_gate]
  require_kv $values GATE G2B_LUT1_GROUP9_PROMOTED_SIGNOFF
  require_kv $values RESULT PASS
  require_kv $values SOURCE_COMMIT $expected_source_commit
  require_kv $values SOURCE_TREE $expected_source_tree
  require_kv $values SSOT_REV 4
  require_kv $values META4R2 VERIFIED
  require_kv $values BS3_EVIDENCE_COMMIT 10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae
  require_kv $values SEALED_DCP_SHA256 $expected_checkpoint_sha
  require_kv $values BASE_XDC_SHA256 $expected_base_xdc_sha
  require_kv $values CANDIDATE_XDC_SHA256 $expected_candidate_xdc_sha
  require_kv $values ACTIVE_XDC_SHA256 $expected_active_xdc_sha
  require_kv $values FRESH_IDENTITY PASS
  require_hash_value [require_kv $values FRESH_IDENTITY_RECEIPT_SHA256] FRESH_IDENTITY_RECEIPT_SHA256
  require_kv $values FRESH_REQUIRED_FAMILY_TIMING PASS
  foreach key {FRESH_SLOT_RESULT_SHA256 FRESH_GENERATION_RESULT_SHA256 FRESH_EPOCH_RESULT_SHA256
      AUTHORITATIVE_TIMING_GATE_RECEIPT_SHA256 AUTHORITATIVE_CANDIDATE_METHODOLOGY_SHA256
      AUTHORITATIVE_CANDIDATE_EXCEPTION_COVERAGE_SHA256
      AUTHORITATIVE_CANDIDATE_IGNORED_EXCEPTIONS_SHA256} {
    require_hash_value [require_kv $values $key] $key
  }
  require_kv $values FRESH_VALIDATE_ALL_POST_AUDIT BOUNDED_TIMEOUT_NON_REQUIRED_AFTER_FAMILY_PASS
  require_kv $values AUTHORITATIVE_BS3_METHODOLOGY_REUSED YES
  require_kv $values AUTHORITATIVE_INPUT_IDENTITY_MATCH YES
  require_kv $values OWNERSHIP_STRUCTURAL_CDC PASS
  require_kv $values REQUEST_SYNCHRONIZER PASS
  require_kv $values ACK_SYNCHRONIZER PASS
  require_kv $values STABLE_DATA_HOLD PASS
  require_kv $values RESET_EPOCH_COHERENCY PASS
  foreach {family actual slack sources} {
      SLOT 5.939 0.093 2
      GENERATION 5.308 0.724 24
      EPOCH 5.423 0.609 32
  } {
    require_kv $values "${family}_FAMILY" PASS
    require_kv $values "${family}_REQUIRED_NS" 6.000
    require_kv $values "${family}_ACTUAL_NS" $actual
    require_kv $values "${family}_SLACK_NS" $slack
    require_kv $values "${family}_SOURCE_COUNT" $sources
    require_kv $values "${family}_DESTINATION_COUNT" 17
  }
  require_kv $values SETTLING_CAP_NS 6.000
  require_kv $values TIMING_34_CANDIDATE ABSENT
  require_kv $values TIMING_39_CANDIDATE ABSENT
  require_kv $values GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED NO
  require_kv $values HARDWARE_ACCESSED NO
  return PASS
}

proc revalidate_pre_bit_inputs {groups_gate_sha finalizer_group9 timing drc cdc clock_resource} {
  global checkpoint base_xdc candidate_xdc active_xdc xpr_path
  global expected_checkpoint_sha expected_base_xdc_sha expected_candidate_xdc_sha
  global expected_active_xdc_sha expected_xpr_sha
  global groups_gate offline_gate expected_offline_gate_sha
  global external_group9_gate expected_external_group9_gate_sha
  global finalizer_path expected_finalizer_sha runner_path expected_runner_sha

  validate_source_identity
  validate_governed_static_inputs
  validate_groups10_17_gate
  validate_offline_protection_gate
  validate_external_group9_gate
  foreach {path expected label} [list \
      $checkpoint $expected_checkpoint_sha DCP \
      $base_xdc $expected_base_xdc_sha BASE_XDC \
      $candidate_xdc $expected_candidate_xdc_sha CANDIDATE_XDC \
      $active_xdc $expected_active_xdc_sha ACTIVE_XDC \
      $xpr_path $expected_xpr_sha XPR \
      $groups_gate $groups_gate_sha GROUPS10_17_GATE \
      $external_group9_gate $expected_external_group9_gate_sha EXTERNAL_GROUP9_GATE \
      $offline_gate $expected_offline_gate_sha OFFLINE_PROTECTION_GATE \
      $finalizer_path $expected_finalizer_sha FINALIZER_TCL \
      $runner_path $expected_runner_sha WATCHDOG_RUNNER \
      [dict get $finalizer_group9 path] [dict get $finalizer_group9 sha] FINALIZER_GROUP9_GATE \
      [dict get $finalizer_group9 csv] [dict get $finalizer_group9 csv_sha] GROUP9_CSV \
      [dict get $timing path] [dict get $timing sha] TIMING_GATE \
      [dict get $drc path] [dict get $drc sha] DRC_GATE \
      [dict get $cdc path] [dict get $cdc sha] CDC_GATE \
      [dict get $clock_resource clock_path] [dict get $clock_resource clock_sha] CLOCK_GATE \
      [dict get $clock_resource resource_path] [dict get $clock_resource resource_sha] RESOURCE_GATE \
      [dict get $clock_resource config_path] [dict get $clock_resource config_sha] XDMA_CONFIG_GATE] {
    if {[sha256_file $path] ne $expected} { error "$label changed before bitstream boundary" }
  }
  if {[route_signature] ne [list 1 0 0 0]} {
    error "route signature changed before bitstream boundary"
  }
  return PASS
}

proc main {} {
  global evidence_root raw_root bit_path phase_marker
  global checkpoint base_xdc candidate_xdc active_xdc xpr_path
  global expected_checkpoint_sha expected_base_xdc_sha expected_candidate_xdc_sha
  global expected_active_xdc_sha expected_source_commit expected_source_tree
  global expected_finalizer_sha expected_runner_sha finalizer_path runner_path
  global groups_gate offline_gate expected_offline_gate_sha
  global external_group9_gate expected_external_group9_gate_sha
  global final_result_path

  begin_phase INIT 1800
  file mkdir $evidence_root
  file mkdir $raw_root
  if {[file exists $bit_path]} { error "bitstream output already exists; refusing overwrite: $bit_path" }
  if {[sha256_file $finalizer_path] ne $expected_finalizer_sha ||
      [sha256_file $runner_path] ne $expected_runner_sha} {
    error "finalizer or watchdog runner changed after launch seal"
  }
  if {![info exists ::env(XILINX_LOCAL_USER_DATA)] || $::env(XILINX_LOCAL_USER_DATA) ne "NO"} {
    error "XILINX_LOCAL_USER_DATA must be NO"
  }
  if {![info exists ::env(TEMP)] || ![info exists ::env(TMP)] ||
      ![string equal -nocase [file normalize $::env(TEMP)] [file normalize $::env(TMP)]]} {
    error "TEMP and TMP must identify the same finalizer-only directory"
  }
  set vivado_version [string trim [version -short]]
  set vivado_sw_build UNKNOWN
  regexp {SW Build[ \t]+([0-9]+)} [version] -> vivado_sw_build
  if {$vivado_version ne "2025.2" || $vivado_sw_build ne "6299465"} {
    error "Vivado identity drift: $vivado_version/$vivado_sw_build"
  }

  validate_source_identity
  validate_governed_static_inputs
  set groups_csv_sha [validate_groups10_17_gate]
  validate_external_group9_gate
  validate_offline_protection_gate
  set groups_gate_sha [sha256_file $groups_gate]

  open_project -read_only $xpr_path
  open_checkpoint $checkpoint
  if {[get_property PART [current_design]] ne "xc7a35tcsg325-2"} {
    error "sealed routed DCP part drift"
  }
  set pre_route [route_signature]
  set pre_clocks [clock_signature]
  if {$pre_route ne [list 1 0 0 0]} { error "sealed DCP is not fully routed: $pre_route" }

  reset_timing -invalid
  read_xdc $base_xdc
  read_xdc $candidate_xdc
  if {[route_signature] ne $pre_route || [clock_signature] ne $pre_clocks} {
    error "constraint reload changed route or clock identity"
  }
  set applied_xdc [file join $raw_root ROUTED_TIMING_APPLIED_BASE_PLUS_BS3.xdc]
  write_xdc -exclude_physical -force $applied_xdc
  set applied_text [read_text $applied_xdc]
  if {[count_xdc_command_lines $applied_text set_bus_skew] != 16 ||
      [count_xdc_command_lines $applied_text set_max_delay] != 12 ||
      [count_xdc_command_lines $applied_text set_false_path] != 30 ||
      [count_xdc_command_lines $applied_text set_clock_groups] != 1} {
    error "reloaded complete timing constraint census drift"
  }
  write_lines_atomic [file join $raw_root G2B_LUT1_INITIALIZATION_GATE.txt] [list \
    {RESULT=PASS} \
    {RECOVERY_MODE=ROUTED_DCP_REUSE} \
    {DCP_REUSE_VALID=YES} \
    {FULL_REBUILD_EXECUTED=NO} \
    {FULL_REBUILD_TRIGGER=NONE} \
    "SOURCE_COMMIT=$expected_source_commit" \
    "SOURCE_TREE=$expected_source_tree" \
    "SEALED_DCP_SHA256=$expected_checkpoint_sha" \
    "BASE_XDC_SHA256=$expected_base_xdc_sha" \
    "BS3_CANDIDATE_XDC_SHA256=$expected_candidate_xdc_sha" \
    "ACTIVE_XDC_SHA256=$expected_active_xdc_sha" \
    "GROUPS10_17_GATE_SHA256=$groups_gate_sha" \
    "GROUPS10_17_RESULTS_CSV_SHA256=$groups_csv_sha" \
    "GROUP9_EXTERNAL_GATE_SHA256=$expected_external_group9_gate_sha" \
    "OFFLINE_PROTECTION_GATE_SHA256=$expected_offline_gate_sha" \
    "VIVADO_VERSION=$vivado_version" \
    "VIVADO_SW_BUILD=$vivado_sw_build" \
    {APPLIED_BUS_SKEW_CONSTRAINTS=16} \
    {APPLIED_MAX_DELAY_CONSTRAINTS=12} \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {HARDWARE_ACCESSED=NO}]

  set finalizer_group9 [run_ownership_gate \
    $g2b_bs3_ownership_slot_src \
    $g2b_bs3_ownership_generation_src \
    $g2b_bs3_ownership_epoch_src \
    $g2b_bs3_ownership_payload_dst_cells \
    $g2b_bs3_ownership_payload_dst_d]
  set timing [run_timing_gate]
  set drc [run_drc_gate]
  set cdc [run_cdc_gate]
  set clock_resource [run_clock_resource_gate $timing $drc $cdc]

  begin_phase PRE_BIT_GATE 900
  revalidate_pre_bit_inputs $groups_gate_sha $finalizer_group9 $timing $drc $cdc $clock_resource
  set pre_bit_path [file join $evidence_root G2B_PRE_BITSTREAM_HARD_GATE.txt]
  write_lines_atomic $pre_bit_path [list \
    {PRE_BITSTREAM_HARD_GATE=PASS} \
    {SOURCE_IDENTITY=PASS} \
    {GROUP9_REPLACEMENT_SIGNOFF=PASS} \
    {GROUPS10_17=PASS} \
    {ROUTED_TIMING=PASS} \
    "WNS=[dict get $timing wns]" \
    "TNS=[dict get $timing tns]" \
    "WHS=[dict get $timing whs]" \
    "THS=[dict get $timing ths]" \
    {DRC=PASS} \
    {CDC_DISPOSITION=PASS} \
    {OWNERSHIP_CDC=PASS} \
    {CLOCK_SIGNOFF=PASS} \
    {RESOURCE_SIGNOFF=PASS} \
    {PRODUCT_LUT_LE_90_PERCENT=PASS} \
    {ABI_MMIO_UNCHANGED=YES} \
    {R1I_PROTECTED_BEHAVIOR=PASS} \
    {NO_UNRESOLVED_BLACK_BOXES=PASS} \
    {NO_UNRESOLVED_CRITICAL_TIMING_DRC_CDC_BLOCKER=PASS} \
    {SSOT_REV4_COMPATIBILITY=PASS} \
    {OFFLINE_THROUGHPUT_GATE=PASS} \
    {PRODUCT_PROFILE=PASS} \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {HARDWARE_ACCESSED=NO} \
    {BITSTREAM_WRITE_AUTHORIZED=YES}]
  set pre_bit_sha [sha256_file $pre_bit_path]

  begin_phase WRITE_BITSTREAM 1800
  revalidate_pre_bit_inputs $groups_gate_sha $finalizer_group9 $timing $drc $cdc $clock_resource
  if {[sha256_file $pre_bit_path] ne $pre_bit_sha} {
    error "pre-bitstream hard gate changed before writer"
  }
  file mkdir [file dirname $bit_path]
  write_bitstream $bit_path
  if {![file isfile $bit_path] || [file size $bit_path] <= 0} {
    error "PRODUCT bitstream is absent or empty"
  }
  set bit_sha [sha256_file $bit_path]

  revalidate_pre_bit_inputs $groups_gate_sha $finalizer_group9 $timing $drc $cdc $clock_resource
  if {[sha256_file $pre_bit_path] ne $pre_bit_sha} {
    error "pre-bitstream hard gate changed after writer"
  }

  set identity_path [file join $evidence_root G2B_LUT1_PRODUCT_CANDIDATE_IDENTITY.json]
  set identity_text "{\n"
  append identity_text "  \"source_commit\": \"[json_value $expected_source_commit]\",\n"
  append identity_text "  \"source_tree\": \"[json_value $expected_source_tree]\",\n"
  append identity_text "  \"project_state_rev\": 4,\n"
  append identity_text "  \"constraint_revision\": \"META-4R2_BS3_PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC\",\n"
  append identity_text "  \"active_xdc_sha256\": \"$expected_active_xdc_sha\",\n"
  append identity_text "  \"routed_dcp_sha256\": \"$expected_checkpoint_sha\",\n"
  append identity_text "  \"bitstream_path\": \"[json_value $bit_path]\",\n"
  append identity_text "  \"bitstream_size\": [file size $bit_path],\n"
  append identity_text "  \"bitstream_sha256\": \"$bit_sha\",\n"
  append identity_text "  \"build_profile\": \"PRODUCT\",\n"
  append identity_text "  \"vivado_version\": \"[json_value $vivado_version]\",\n"
  append identity_text "  \"vivado_sw_build\": \"[json_value $vivado_sw_build]\",\n"
  append identity_text "  \"device\": \"xc7a35tcsg325-2\",\n"
  append identity_text "  \"transport_abi\": \"AHD_C2H_TRANSPORT_ABI_V1\",\n"
  append identity_text "  \"abi_version\": 1,\n"
  append identity_text "  \"mmio_range\": \"0x3800..0x3BFF\",\n"
  append identity_text "  \"debug_probes\": null,\n"
  append identity_text "  \"hardware_accessed\": false\n"
  append identity_text "}\n"
  write_text_atomic $identity_path $identity_text

  write_lines_atomic $final_result_path [list \
    {TASK=AHD_V41_G2B_LUT1_SIGNOFF_RECOVERY} \
    {RESULT=PASS} \
    {ENGINEERING_GATE=PASS} \
    {BUILD_PROFILE=PRODUCT} \
    {RECOVERY_MODE=ROUTED_DCP_REUSE} \
    {DCP_REUSE_VALID=YES} \
    {FULL_REBUILD_EXECUTED=NO} \
    {FULL_REBUILD_TRIGGER=NONE} \
    "SOURCE_COMMIT=$expected_source_commit" \
    "SOURCE_TREE=$expected_source_tree" \
    "ROUTED_DCP_SHA256=$expected_checkpoint_sha" \
    "ACTIVE_XDC_SHA256=$expected_active_xdc_sha" \
    {GROUP9_REPLACEMENT_SIGNOFF=PASS} \
    {SLOT_FAMILY=PASS} \
    {GENERATION_FAMILY=PASS} \
    {EPOCH_FAMILY=PASS} \
    {SETTLING_CAP_NS=6.000} \
    {GROUPS10_17=PASS} \
    {ROUTED_TIMING=PASS} \
    "WNS=[dict get $timing wns]" \
    "TNS=[dict get $timing tns]" \
    "WHS=[dict get $timing whs]" \
    "THS=[dict get $timing ths]" \
    {DRC=PASS} \
    "DRC_ERRORS=[dict get $drc errors]" \
    "DRC_CRITICAL_WARNINGS=[dict get $drc critical_warnings]" \
    {CDC_DISPOSITION=PASS} \
    "CDC_CRITICAL=[dict get $cdc critical]" \
    "CDC_CRITICAL_DISPOSITIONED=[dict get $cdc dispositioned]" \
    {OWNERSHIP_CDC=PASS} \
    {CLOCKS=PASS} \
    "EFFECTIVE_USER_CLOCK_MHZ=[dict get $clock_resource effective_frequency]" \
    "EFFECTIVE_AXI_CLOCK_MHZ=[dict get $clock_resource effective_frequency]" \
    {PRODUCT_RESOURCES=PASS} \
    "LUT_USED=[dict get $clock_resource lut_used]" \
    "LUT_AVAILABLE=[dict get $clock_resource lut_available]" \
    "LUT_PERCENT=[dict get $clock_resource lut_percent]" \
    "FF_USED=[dict get $clock_resource ff_used]" \
    "FF_AVAILABLE=[dict get $clock_resource ff_available]" \
    "FF_PERCENT=[dict get $clock_resource ff_percent]" \
    "BRAM_USED=[dict get $clock_resource bram_used]" \
    "BRAM_AVAILABLE=[dict get $clock_resource bram_available]" \
    "BRAM_PERCENT=[dict get $clock_resource bram_percent]" \
    {PRODUCT_LUT_LE_90_PERCENT=PASS} \
    {TRANSPORT_ABI=AHD_C2H_TRANSPORT_ABI_V1} \
    {ABI_VERSION=1} \
    {MMIO_RANGE=0x3800..0x3BFF} \
    {ABI_MMIO_UNCHANGED=YES} \
    {R1I_PROTECTED_BEHAVIOR=PASS} \
    {OFFLINE_THROUGHPUT_GATE=PASS} \
    {REQUIRED_PAYLOAD_MBPS=288} \
    {HARDWARE_THROUGHPUT_PROVEN=NO} \
    {PRE_BITSTREAM_HARD_GATE=PASS} \
    "PRE_BITSTREAM_HARD_GATE_SHA256=$pre_bit_sha" \
    {BITSTREAM_PRODUCED=YES} \
    "BITSTREAM_PATH=$bit_path" \
    "BITSTREAM_SIZE=[file size $bit_path]" \
    "BITSTREAM_SHA256=$bit_sha" \
    {DEBUG_PROBES_PRODUCED=NO} \
    {LTX_SHA256=NONE} \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {HARDWARE_ACCESSED=NO} \
    {FPGA_PROGRAMMED=NO} \
    {PCIE_TESTED=NO} \
    {DMA_TESTED=NO} \
    {G2B_HW=NOT_PROVEN} \
    {FIRST_BLOCKER=NONE}]
  begin_phase COMPLETE 30
  puts "G2B_LUT1_SIGNOFF_RECOVERY=PASS BITSTREAM_SHA256=$bit_sha"
}

if {[llength $argv] != 10} {
  puts stderr "usage: finalizer.tcl EVIDENCE_ROOT BITSTREAM_PATH OFFLINE_GATE EXPECTED_OFFLINE_GATE_SHA GROUP9_GATE EXPECTED_GROUP9_GATE_SHA PHASE_MARKER RUNNER_PATH EXPECTED_RUNNER_SHA EXPECTED_FINALIZER_SHA"
  exit 2
}

lassign $argv evidence_root bit_path offline_gate expected_offline_gate_sha \
  external_group9_gate expected_external_group9_gate_sha \
  phase_marker runner_path expected_runner_sha expected_finalizer_sha
foreach variable {evidence_root bit_path offline_gate external_group9_gate phase_marker runner_path} {
  set $variable [file normalize [set $variable]]
}
set expected_offline_gate_sha [require_hash_value \
  [string toupper $expected_offline_gate_sha] EXPECTED_OFFLINE_GATE_SHA]
set expected_external_group9_gate_sha [require_hash_value \
  [string toupper $expected_external_group9_gate_sha] EXPECTED_GROUP9_GATE_SHA]
set expected_runner_sha [require_hash_value [string toupper $expected_runner_sha] EXPECTED_RUNNER_SHA]
set expected_finalizer_sha [require_hash_value \
  [string toupper $expected_finalizer_sha] EXPECTED_FINALIZER_SHA]
set finalizer_path [file normalize [info script]]

set repo_root [file normalize {C:/FPGA/V41_G2B}]
set expected_source_branch integration/v41-g2b-onech-c2h
set expected_source_parent 224d194e5f82c85bcb29297561c5d5e76d28063b
set expected_source_commit 66cc8e3497579c2f7cb41d0b3639b3c2f00d6c49
set expected_source_tree 1e67e3f1fe06669839fe9ff8573e4d1e0114a889
set source_manifest [file normalize {C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1/sealed_inputs/G2B_BUILD_INPUT_SHA256.txt}]
set expected_source_manifest_sha 0248858AF074D4F3065B8A666366DEB532122C9F121F67625A2F68BBC0413EFD
set expected_old_active_xdc_sha 2E371FB39215303CCCE7E7DEB06EB59D442C391C8366FA21A56F174E7737FDAF
set expected_active_xdc_sha 6A5F54F9D319115417C747BCA67367919C7CBB0E990A9641D78D429D87E81227
set active_xdc [file join $repo_root xdc common g2b_cdc.xdc]

set checkpoint [file normalize {C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1/sealed_inputs/G2B_ROUTED.dcp}]
set expected_checkpoint_sha EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83
set bs3_root [file normalize {C:/FPGA/V41_G2B_EVIDENCE/v41-development-g2b-bs3-ownership-mailbox-settling-proof}]
set base_xdc [file join $bs3_root validation G2B_BS3_FULL_BASE_WITHOUT_GROUP9.xdc]
set expected_base_xdc_sha 3680EE8998503D10713D930D7D9D44AD0D71B273A9252D364A3BEE2D0D6AD507
set candidate_xdc [file join $bs3_root G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc]
set expected_candidate_xdc_sha AE4BD91C1A8C3B1AF2FB9B0EA9A9382E9F618FD8E223BACF98E4468C10EAD087

set build_root [file normalize {C:/FPGA/G2B_LUT1_PRODUCT_PRECOMMIT_BUILD_20260831_12}]
set xpr_path [file join $build_root vivado_project v41_g2b_onech_c2h_offline.xpr]
set expected_xpr_sha 204E26DCC659EACC973A9F17D5C92863830CDFCD4770855E67E4724067BB044E
set xdma_xci [file join $repo_root ip v41 xdma_v41_m1.xci]
set expected_xdma_xci_sha 9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F

set structural_proof [file join $bs3_root G2B_BS3_STRUCTURAL_CDC_PROOF.md]
set request_ack_proof [file join $bs3_root G2B_BS3_REQUEST_ACK_SEQUENCE_PROOF.md]
set cdc_invariants [file join $bs3_root G2B_BS3_CDC_INVARIANTS.md]
set slot_reference [file join $bs3_root validation G2B_BS3_SLOT_SOURCES.txt]
set generation_reference [file join $bs3_root validation G2B_BS3_GENERATION_SOURCES.txt]
set epoch_reference [file join $bs3_root validation G2B_BS3_EPOCH_SOURCES.txt]
set destination_reference [file join $bs3_root validation G2B_BS3_DESTINATION_CELLS.txt]

set raw_root [file join $evidence_root raw final_signoff]
set groups_gate [file join $evidence_root G2B_LUT1_GROUPS10_17_GATE.txt]
set groups_csv [file join $evidence_root G2B_LUT1_GROUPS10_17_RESULTS.csv]
set final_result_path [file join $evidence_root FINAL_GATE_RESULT.txt]

set code [catch {main} message options]
if {$code != 0} {
  set error_info $message
  if {[dict exists $options -errorinfo]} { set error_info [dict get $options -errorinfo] }
  set bit_exists [expr {[file isfile $bit_path] && [file size $bit_path] > 0 ? "YES_UNQUALIFIED" : "NO"}]
  write_lines_atomic $final_result_path [list \
    {TASK=AHD_V41_G2B_LUT1_SIGNOFF_RECOVERY} \
    {RESULT=FAIL} \
    {ENGINEERING_GATE=FAIL} \
    "FIRST_BLOCKER=[safe_value $message]" \
    "ERROR_INFO=[safe_value $error_info]" \
    {PRE_BITSTREAM_HARD_GATE=FAIL} \
    "BITSTREAM_PRODUCED=$bit_exists" \
    {DEBUG_PROBES_PRODUCED=NO} \
    {GLOBAL_GROUP9_REPORT_BUS_SKEW_EXECUTED=NO} \
    {HARDWARE_ACCESSED=NO} \
    {FPGA_PROGRAMMED=NO} \
    {PCIE_TESTED=NO} \
    {DMA_TESTED=NO}]
  catch {begin_phase FAILED 60}
  puts stderr "G2B_LUT1_SIGNOFF_RECOVERY=FAIL ERROR=[safe_value $message]"
  exit 1
}
exit 0
