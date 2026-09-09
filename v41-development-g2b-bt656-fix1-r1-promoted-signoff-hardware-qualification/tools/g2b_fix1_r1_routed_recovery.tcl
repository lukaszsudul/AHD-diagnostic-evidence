# AHD v41 G2B: one-channel application C2H, offline build only.
#
# Build-flow authority: scripts/v41/g2a_build.tcl from accepted G2A commit
# 224d194e5f82c85bcb29297561c5d5e76d28063b.  Part, top, XDMA configuration,
# legacy source/XDC ordering, and synth/opt/place/phys_opt/route sequencing
# remain unchanged.  G2B adds only its RTL and additive CDC constraints.
#
# G2B has two deliberately distinct provenance modes.  The default and
# PROVENANCE_ONLY modes require a clean, exact post-implementation commit.
# PRECOMMIT_FULL_BUILD permits the implementation to remain uncommitted only
# when every build input matches a caller-supplied canonical SHA-256 manifest.
# The precommit bitstream is marked dirty in BUILD_FLAGS and is never described
# as commit-identical.  No checkpoint is read or reused in either build mode.

if {$argc != 7 && $argc != 8 && $argc != 9} {
  puts stderr "usage: g2b_build.tcl REPO_ROOT BUILD_ROOT EVIDENCE_ROOT SOURCE_COMMIT SOURCE_TREE BIT_FILENAME PRODUCT|RESEARCH_DIAGNOSTIC ?PROVENANCE_ONLY|POSTCOMMIT_FULL_BUILD|PRECOMMIT_FULL_BUILD? ?PRECOMMIT_INPUT_MANIFEST?"
  exit 2
}

lassign [lrange $argv 0 6] repo_root build_root evidence_root source_commit source_tree bit_filename build_profile
if {$build_profile ni {PRODUCT RESEARCH_DIAGNOSTIC}} {
  error "BUILD_PROFILE must be exactly PRODUCT or RESEARCH_DIAGNOSTIC"
}
set enable_rtrack_diagnostics [expr {$build_profile eq "RESEARCH_DIAGNOSTIC" ? 1 : 0}]
set execution_mode POSTCOMMIT_FULL_BUILD
set precommit_manifest ""
if {$argc == 8} {
  set execution_mode [lindex $argv 7]
  if {$execution_mode ni {PROVENANCE_ONLY POSTCOMMIT_FULL_BUILD FIX1_R1_ROUTED_DCP_RECOVERY}} {
    error "eight-argument execution mode must be PROVENANCE_ONLY, POSTCOMMIT_FULL_BUILD, or FIX1_R1_ROUTED_DCP_RECOVERY"
  }
} elseif {$argc == 9} {
  set execution_mode [lindex $argv 7]
  if {$execution_mode ne "PRECOMMIT_FULL_BUILD"} {
    error "nine-argument execution mode must be exactly PRECOMMIT_FULL_BUILD"
  }
  set precommit_manifest [file normalize [lindex $argv 8]]
}
set precommit_mode [expr {$execution_mode eq "PRECOMMIT_FULL_BUILD"}]

set repo_root [file normalize $repo_root]
set build_root [file normalize $build_root]
set evidence_root [file normalize $evidence_root]

set accepted_g2a_base_commit 224d194e5f82c85bcb29297561c5d5e76d28063b
set accepted_g2a_base_tree 283f98c02e6f9c61716875415cf000682f8ab856
set accepted_product_commit 92e9b3d914134c044371779def1ee18eaaeda98a
set accepted_product_tree cf6bf82249c90782eab1978c68541ed9c0e6430b
set accepted_fix_candidate_commit bf19702beca9bd85e950fa7ee59fd8ed08b1b2dc
set accepted_fix_candidate_tree 2f72f4fa5dd756443c2d79eb7b75d75badefe921
set qualified_r1i_commit 20c3323d79d3896edc586d6db1df7deee60f9e41
set qualified_r1i_tree 70d801fd7a879080da399bfa9ee95fd6eb008e16
set qualified_r1i_tag v41-r1i-qualified-poc-20260827
set accepted_xdma_xci_blob 450aa334e2bda4396cd5a7270ba15895c7f7ed54
set accepted_xdma_config_tcl_blob ea9c2b5a463e6c4e15743d53abab734ba5fdf516
set expected_branch fix/v41-g2b-bt656-line0-sof
set expected_part xc7a35tcsg325-2
set expected_top ahd_capture_top_xdma
set expected_vivado_version 2025.2
set expected_vivado_sw_build 6299465
set expected_user_clock_mhz 62.5
set clock_tolerance_mhz 0.1

# Compile order remains the accepted G2A order with the two G2B units inserted
# immediately before the modified top.  The dedicated G2B CDC constraint file
# follows the frozen legacy cdc.xdc, so it cannot perturb the legacy source
# ordering or silently replace a legacy exception.
set sv_rel_files {
  rtl/v41/axi_lite_host_bridge.sv
  rtl/v41/axi_clock_lifecycle_monitor.sv
  rtl/v41/axi_clock_measurement_regs.sv
  rtl/v41/r1e_measurement_regs.sv
  rtl/v41/r1h_probe_index_bram_store.sv
  rtl/v41/nvp_i2c_tri_phase_probe.sv
  rtl/v41/r1f_failed_txn_logger.sv
  rtl/v41/r1f_measurement_regs.sv
  rtl/v41/r1h_mmio_read_service.sv
  rtl/v41/g2b_product_profile_read_service.sv
  rtl/v41/control_status_regs.sv
  rtl/pio/pio_slot_adapter.sv
  rtl/pio/pio_bar_target.sv
  rtl/record/bt656_record_producer.sv
  rtl/record/capture_mailbox.sv
  rtl/video/video_capture.sv
  rtl/video/physical_frontend.sv
  rtl/g2b/v41_g2b_mmio_router.sv
  rtl/g2b/v41_g2b_onech_c2h.sv
  rtl/top/ahd_capture_top_xdma.sv
}
set vhdl_rel_files {
  rtl/nvp/nvp6134c_diagnostics_pkg.vhd
  rtl/nvp/r1f_transaction_serial_counter.vhd
  rtl/nvp/nvp6134c_i2c_bringup.vhd
  rtl/nvp/nvp6134c_autoinit.vhd
}
set xdc_rel_files {
  xdc/boards/current/xdma_pcie.xdc
  xdc/boards/current/pins.xdc
  xdc/boards/current/vdo_input_timing.xdc
  xdc/boards/current/pcie_pio.xdc
  xdc/boards/current/nvp_control.xdc
  xdc/common/cdc.xdc
  xdc/common/g2b_cdc.xdc
  xdc/common/configuration_bank.xdc
}

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  foreach line $lines { puts $fh $line }
  close $fh
}

proc write_text {path value} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  puts -nonewline $fh $value
  close $fh
}

proc read_text {path} {
  set fh [open $path r]
  fconfigure $fh -encoding utf-8
  set value [read $fh]
  close $fh
  return $value
}

proc single_line {value} {
  return [string map [list "\r" {\r} "\n" {\n}] $value]
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

proc git_value {args} {
  global repo_root
  return [string trim [exec git --no-optional-locks -C $repo_root {*}$args]]
}

proc sha256_file {path} {
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set candidate [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $candidate]} { return $candidate }
  }
  error "SHA-256 unavailable for $path"
}

proc require_files {paths} {
  foreach path $paths {
    if {![file isfile $path]} { error "required input missing: $path" }
  }
}

# Canonical precommit-manifest format: one UTF-8/LF line per input in the
# exact order returned here, RELATIVE/POSIX/PATH|UPPERCASE_SHA256, including a
# final LF.  Hashing the harness itself prevents build-rule changes after seal.
proc canonical_build_input_hashes {} {
  global repo_root sv_rel_files vhdl_rel_files xdc_rel_files
  set rel_files [concat $sv_rel_files $vhdl_rel_files $xdc_rel_files [list \
    ip/v41/xdma_v41_m1.xci \
    scripts/v41/xdma_config_common.tcl \
    scripts/v41/g2b_build.tcl]]
  set seen [dict create]
  set result [list]
  foreach rel $rel_files {
    if {[file pathtype $rel] ne "relative" || [string first {\\} $rel] >= 0} {
      error "non-canonical build input path: $rel"
    }
    if {[dict exists $seen $rel]} { error "duplicate build input path: $rel" }
    dict set seen $rel 1
    set path [file join $repo_root $rel]
    if {![file isfile $path]} { error "required build input missing: $path" }
    lappend result "$rel|[sha256_file $path]"
  }
  return $result
}

proc validate_precommit_input_manifest {manifest_path expected_lines} {
  global repo_root build_root evidence_root
  if {$manifest_path eq "" || ![file isfile $manifest_path]} {
    error "PRECOMMIT_FULL_BUILD requires an existing explicit input hash manifest"
  }
  if {[path_is_within $manifest_path $repo_root] ||
      [path_is_within $manifest_path $build_root] ||
      [path_is_within $manifest_path $evidence_root]} {
    error "precommit input manifest must be outside repository, build, and evidence roots"
  }
  set expected "[join $expected_lines \n]\n"
  set actual [string map [list "\r\n" "\n" "\r" "\n"] [read_text $manifest_path]]
  if {$actual ne $expected} {
    set expected_split [split [string trimright $expected "\n"] "\n"]
    set actual_split [split [string trimright $actual "\n"] "\n"]
    set mismatch 0
    set limit [expr {max([llength $expected_split], [llength $actual_split])}]
    while {$mismatch < $limit &&
           [lindex $expected_split $mismatch] eq [lindex $actual_split $mismatch]} {
      incr mismatch
    }
    error "PRECOMMIT_INPUT_MANIFEST_MISMATCH at canonical line [expr {$mismatch + 1}]"
  }
  return [sha256_file $manifest_path]
}

proc source_seal_is_current {} {
  global source_commit source_tree expected_branch precommit_mode actual_status
  global precommit_manifest precommit_manifest_sha sealed_input_hashes
  if {[catch {
    set identity_ok [expr {
      [git_value rev-parse HEAD] eq $source_commit &&
      [git_value rev-parse {HEAD^{tree}}] eq $source_tree &&
      [git_value symbolic-ref --short HEAD] eq $expected_branch}]
    set status_now [git_value status --porcelain --untracked-files=all]
    set hashes_now [canonical_build_input_hashes]
    set seal_ok [expr {$identity_ok && $hashes_now eq $sealed_input_hashes}]
    if {$precommit_mode} {
      set manifest_now \
        [validate_precommit_input_manifest $precommit_manifest $sealed_input_hashes]
      set seal_ok [expr {$seal_ok && $status_now eq $actual_status &&
                         $manifest_now eq $precommit_manifest_sha}]
    } else {
      set seal_ok [expr {$seal_ok && $status_now eq ""}]
    }
  }]} {
    return 0
  }
  return $seal_ok
}

proc effective_config_dict {ip} {
  set result [dict create]
  foreach property [lsort [list_property $ip]] {
    if {[string match {CONFIG.*} $property]} {
      dict set result $property [get_property $property $ip]
    }
  }
  return $result
}

proc assert_config_dict_equal {expected actual label} {
  set expected_keys [lsort [dict keys $expected]]
  set actual_keys [lsort [dict keys $actual]]
  if {$expected_keys ne $actual_keys} {
    error "$label CONFIG property-name drift"
  }
  foreach property $expected_keys {
    set expected_value [dict get $expected $property]
    set actual_value [dict get $actual $property]
    if {$actual_value ne $expected_value} {
      error "$label CONFIG drift for $property: expected '$expected_value', got '$actual_value'"
    }
  }
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
    if {![string is double -strict $used] || ![string is double -strict $available] || $available <= 0.0} {
      error "non-numeric utilization row '$wanted': used='$used' available='$available'"
    }
    return [list $used $available]
  }
  error "utilization row '$wanted' not found"
}

proc resource_metrics {stage} {
  global evidence_root
  set text [report_utilization -return_string]
  write_text [file join $evidence_root "${stage}_UTILIZATION_FLAT.rpt"] $text
  lassign [utilization_row $text "Slice LUTs"] lut_used lut_available
  lassign [utilization_row $text "Slice Registers"] ff_used ff_available
  lassign [utilization_row $text "Block RAM Tile"] bram_used bram_available
  lassign [utilization_row $text "DSPs"] dsp_used dsp_available
  return [dict create \
    LUT_USED $lut_used LUT_AVAILABLE $lut_available \
    LUT_PERCENT [expr {100.0 * $lut_used / $lut_available}] \
    FF_USED $ff_used FF_AVAILABLE $ff_available \
    FF_PERCENT [expr {100.0 * $ff_used / $ff_available}] \
    BRAM_USED $bram_used BRAM_AVAILABLE $bram_available \
    BRAM_PERCENT [expr {100.0 * $bram_used / $bram_available}] \
    DSP_USED $dsp_used DSP_AVAILABLE $dsp_available \
    DSP_PERCENT [expr {100.0 * $dsp_used / $dsp_available}]]
}

proc evaluate_resource_gate {stage metrics} {
  global evidence_root
  set lut_percent [dict get $metrics LUT_PERCENT]
  set ff_percent [dict get $metrics FF_PERCENT]
  set bram_percent [dict get $metrics BRAM_PERCENT]
  set dsp_percent [dict get $metrics DSP_PERCENT]
  set gate PASS
  set reason NONE
  if {$lut_percent > 90.0} {
    set gate FAIL
    set reason LUT_GT_90_PERCENT
  } elseif {$ff_percent > 80.0} {
    set gate FAIL
    set reason FF_GT_80_PERCENT
  } elseif {$bram_percent > 80.0} {
    set gate FAIL
    set reason BRAM_GT_80_PERCENT
  } elseif {$dsp_percent > 85.0} {
    set gate FAIL
    set reason DSP_GT_85_PERCENT
  }
  write_lines [file join $evidence_root "${stage}_RESOURCE_GATE.txt"] [list \
    "STAGE=$stage" \
    "LUT_USED=[dict get $metrics LUT_USED]" \
    "LUT_AVAILABLE=[dict get $metrics LUT_AVAILABLE]" \
    "LUT_PERCENT=[format %.3f $lut_percent]" \
    "LUT_LIMIT_PERCENT=90.000" \
    "FF_USED=[dict get $metrics FF_USED]" \
    "FF_AVAILABLE=[dict get $metrics FF_AVAILABLE]" \
    "FF_PERCENT=[format %.3f $ff_percent]" \
    "FF_LIMIT_PERCENT=80.000" \
    "BRAM_USED=[dict get $metrics BRAM_USED]" \
    "BRAM_AVAILABLE=[dict get $metrics BRAM_AVAILABLE]" \
    "BRAM_PERCENT=[format %.3f $bram_percent]" \
    "BRAM_LIMIT_PERCENT=80.000" \
    "DSP_USED=[dict get $metrics DSP_USED]" \
    "DSP_AVAILABLE=[dict get $metrics DSP_AVAILABLE]" \
    "DSP_PERCENT=[format %.3f $dsp_percent]" \
    "DSP_LIMIT_PERCENT=85.000" \
    "RESOURCE_GATE=$gate" "RESOURCE_GATE_REASON=$reason"]
  return [list $gate $reason]
}

proc record_action {action} {
  global action_counts evidence_root stage
  dict incr action_counts $action
  set lines [list "STAGE=$stage"]
  dict for {key value} $action_counts { lappend lines "$key=$value" }
  write_lines [file join $evidence_root G2B_OPERATION_COUNTS.txt] $lines
}

proc unique_objects_by_name {objects} {
  set by_name [dict create]
  foreach object $objects {
    set name [get_property NAME $object]
    dict set by_name $name $object
  }
  set result [list]
  foreach name [lsort [dict keys $by_name]] { lappend result [dict get $by_name $name] }
  return $result
}

proc clocks_for_pattern {pattern} {
  set result [list]
  foreach clock [get_clocks -quiet] {
    if {[string match $pattern [get_property NAME $clock]]} { lappend result $clock }
  }
  foreach net [get_nets -quiet -hier $pattern] {
    if {![catch {get_clocks -quiet -of_objects $net} clocks]} {
      foreach clock $clocks { lappend result $clock }
    }
    foreach pin [get_pins -quiet -of_objects $net] {
      if {![catch {get_clocks -quiet -of_objects $pin} clocks]} {
        foreach clock $clocks { lappend result $clock }
      }
    }
  }
  foreach pin [get_pins -quiet -hier $pattern] {
    if {![catch {get_clocks -quiet -of_objects $pin} clocks]} {
      foreach clock $clocks { lappend result $clock }
    }
  }
  return [unique_objects_by_name $result]
}

proc property_or_unknown {property object} {
  if {[catch {get_property $property $object} value] || $value eq ""} { return UNKNOWN }
  return $value
}

proc check_timing_table_count {text wanted} {
  foreach line [split $text "\n"] {
    set columns [split $line "|"]
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

proc cdc_severity_counts {text} {
  set critical 0
  set unknown 0
  foreach line [split $text "\n"] {
    if {![regexp -nocase {CDC-[0-9]+} $line]} { continue }
    if {[regexp -nocase {Critical} $line]} { incr critical }
    if {[regexp -nocase {Unknown} $line]} { incr unknown }
  }
  return [list $critical $unknown]
}

proc count_matching_rows {rows expression} {
  set count 0
  foreach row $rows {
    if {[regexp -- $expression $row]} { incr count }
  }
  return $count
}

# report_cdc intentionally identifies acknowledged stable-data mailboxes as
# CDC-1 because their payload is not a conventional bitwise synchronizer.  The
# payload is held from request launch through the returned two-flop-toggle ack;
# the XDC supplies a 6 ns datapath bound and 3 ns bus-skew bound.  Accept only
# the endpoint-exact reviewed manifest below.  The two CDC-10 rows are likewise
# exact level crossings into named two-flop ASYNC_REG chains.  The final two
# rows are the accepted G2A XDMA PIPE-clock CDC-13 views.  This is a strict
# disposition, not a waiver: any object, clock direction, rule, exception,
# depth, family count, or canonical SHA change is fatal.
proc enforce_exact_cdc_disposition {cdc_path cdc_violations} {
  global repo_root build_root evidence_root

  set expected_counts [dict create CDC-1 423 CDC-10 2 CDC-13 2]
  # Endpoint-exact manifests were independently regenerated from the original
  # nonincremental FIX1 build report and the FIX1-R1 report of the same routed
  # DCP.  Both reports produce identical 423/2/2 canonical rows.  The former
  # recovery-4 constants described the pre-hardened DCP and are not reused.
  set expected_hashes [dict create \
    CDC-1 A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D \
    CDC-10 1299D9C60B923DDD13CA4F773393AEB34906D46A96AB0A7139EB6A499A4E9D39 \
    CDC-13 CF8C6175F013504F041F12CD9C4F56D549998EEAAA340B4BEBD56D6F005A0B18]
  set expected_total_hash 47E141801B3DA3494DE70C3941B4113FFFF52000001BD3D42D8D1B9AA21E69E2
  # FIX1-R1 uses the exact immutable hardened tree.  This hash is recorded
  # from that tree and is checked only by this task-local recovery harness.
  set expected_g2b_xdc_sha 9D6911E4BD8B365853BD04FDB9F4C59F1C99E6F08436EE61DB1AE8C8E6FFA7AE

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

  set cdc_text [read_text $cdc_path]
  set source_clock UNKNOWN
  set destination_clock UNKNOWN
  set summary_counts [dict create]
  set rows_by_id [dict create CDC-1 [list] CDC-10 [list] CDC-13 [list]]
  set parsed_total 0
  foreach line [split $cdc_text "\n"] {
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
      # Exact CDC-1 form accepted below by canonical manifest hash.
    } elseif {[regexp {^[ \t]*[0-9]+[ \t]+(CDC-10)[ \t]+Critical[ \t]+Combinational logic detected before a synchronizer[ \t]+2[ \t]+(False Path)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]*$} \
        $line -> row_id exception source_endpoint destination_endpoint]} {
      # Exact CDC-10 form accepted below by canonical manifest hash.
    } elseif {[regexp {^[ \t]*[0-9]+[ \t]+(CDC-13)[ \t]+Critical[ \t]+1-bit CDC path on a non-FD primitive[ \t]+0[ \t]+(False Path)[ \t]+([^ \t]+)[ \t]+([^ \t]+)[ \t]*$} \
        $line -> row_id exception source_endpoint destination_endpoint]} {
      # Exact CDC-13 form accepted below by canonical manifest hash.
    } elseif {[regexp {^[ \t]*[0-9]+[ \t]+CDC-[0-9]+[ \t]+Critical[ \t]+} $line]} {
      error "unexpected detailed critical CDC row: [single_line $line]"
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
  foreach id [list CDC-1 CDC-10 CDC-13] {
    if {![dict exists $summary_counts $id]} {
      error "missing critical CDC summary for $id"
    }
    set expected_count [dict get $expected_counts $id]
    set object_count [dict get $object_counts $id]
    set summary_count [dict get $summary_counts $id]
    set rows [lsort -ascii [dict get $rows_by_id $id]]
    if {$object_count != $expected_count || $summary_count != $expected_count ||
        [llength $rows] != $expected_count} {
      error "$id critical CDC count mismatch: expected=$expected_count objects=$object_count summary=$summary_count rows=[llength $rows]"
    }
    set id_token [string map {- _} $id]
    set manifest_path [file join $evidence_root "G2B_CDC_CRITICAL_${id_token}_CANONICAL.txt"]
    write_lines $manifest_path $rows
    set actual_hash [sha256_file $manifest_path]
    set expected_hash [dict get $expected_hashes $id]
    if {$actual_hash ne $expected_hash} {
      error "$id critical CDC canonical manifest drift: expected=$expected_hash actual=$actual_hash"
    }
    lappend hash_receipt "${id}_COUNT=$expected_count" "${id}_SHA256=$actual_hash"
    set all_rows [concat $all_rows $rows]
  }
  set all_rows [lsort -ascii $all_rows]
  set total_manifest_path [file join $evidence_root G2B_CDC_CRITICAL_ALL_CANONICAL.txt]
  write_lines $total_manifest_path $all_rows
  set total_hash [sha256_file $total_manifest_path]
  if {$object_total != 427 || $parsed_total != 427 ||
      [llength $all_rows] != 427 || $total_hash ne $expected_total_hash} {
    error "critical CDC total manifest mismatch: objects=$object_total parsed=$parsed_total rows=[llength $all_rows] hash=$total_hash"
  }

  set cdc1_rows [dict get $rows_by_id CDC-1]
  # Synthesis selected bit 0 and phase bit 1 as equivalent representative
  # launch cells in this exact hardened DCP.  The endpoint manifest above is
  # the primary identity gate; these counts partition all 423 rows exactly.
  set family_counts [dict create \
    OWNERSHIP_AXI_TO_SOURCE [count_matching_rows $cdc1_rows {\|G2B_ONECH_C2H/axis_slot_reg\[0\]/C\|G2B_ONECH_C2H/(own_ok_hold_source|slot_state_source)_reg}] \
    RELEASE_AXI_TO_SOURCE [count_matching_rows $cdc1_rows {\|G2B_ONECH_C2H/release_(epoch|generation)_axi_reg}] \
    TRANSPORT_HARD_AXI_TO_SOURCE [count_matching_rows $cdc1_rows {\|G2B_ONECH_C2H/transport_hard_hold_axi_reg/C\|}] \
    TRANSPORT_PHASE_AXI_TO_SOURCE [count_matching_rows $cdc1_rows {\|G2B_ONECH_C2H/transport_release_phase_hold_axi_reg\[0\]/C\|}] \
    OWNERSHIP_RESULT_SOURCE_TO_AXI [count_matching_rows $cdc1_rows {\|G2B_ONECH_C2H/own_ok_hold_source_reg/C\|}] \
    RESET_RESULT_SOURCE_TO_AXI [count_matching_rows $cdc1_rows {\|G2B_ONECH_C2H/reset_commit_phase_hold_source_reg\[1\]/C\|}]]
  set expected_family_counts [dict create \
    OWNERSHIP_AXI_TO_SOURCE 10 RELEASE_AXI_TO_SOURCE 7 \
    TRANSPORT_HARD_AXI_TO_SOURCE 43 TRANSPORT_PHASE_AXI_TO_SOURCE 8 \
    OWNERSHIP_RESULT_SOURCE_TO_AXI 70 RESET_RESULT_SOURCE_TO_AXI 285]
  foreach family [dict keys $expected_family_counts] {
    if {[dict get $family_counts $family] != [dict get $expected_family_counts $family]} {
      error "critical CDC semantic family drift: $family expected=[dict get $expected_family_counts $family] actual=[dict get $family_counts $family]"
    }
  }

  set async_chain_cells [get_cells -quiet -hier -regexp \
    {.*G2B_ONECH_C2H/(fatal_sync1_source|fatal_sync2_source|source_ready_sync1_axi|source_ready_sync2_axi)_reg}]
  if {[llength $async_chain_cells] != 4} {
    error "expected four CDC-10 ASYNC_REG chain cells, found [llength $async_chain_cells]"
  }
  foreach chain_cell $async_chain_cells {
    if {[string toupper [property_or_unknown ASYNC_REG $chain_cell]] ni {"TRUE" "1"}} {
      error "CDC-10 chain cell lacks ASYNC_REG=TRUE: [get_property NAME $chain_cell]"
    }
  }

  set g2b_xdc [file join $repo_root xdc common g2b_cdc.xdc]
  set actual_g2b_xdc_sha [sha256_file $g2b_xdc]
  if {$actual_g2b_xdc_sha ne $expected_g2b_xdc_sha} {
    error "reviewed G2B CDC XDC drift: expected=$expected_g2b_xdc_sha actual=$actual_g2b_xdc_sha"
  }

  # The accelerated DCP path deliberately does not regenerate an IP project.
  # Verify the exact generated-XDMA clauses in the full routed timing export
  # that is active in the reused checkpoint.
  set generated_xdc [file join $evidence_root BUS_SKEW_GROUPS ROUTED_TIMING_FULL_RAW.xdc]
  if {![file isfile $generated_xdc]} {
    error "full routed timing export is unavailable for generated-XDMA clause verification"
  }
  set generated_xdc_text [read_text $generated_xdc]
  foreach required_clause [list \
      {set_false_path -to [get_pins inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S0]} \
      {set_false_path -to [get_pins inst/gt_top_i/pipe_wrapper_i/pipe_clock_int.pipe_clock_i/pclk_i1_bufgctrl.pclk_i1/S1]} \
      {set_clock_groups -name pcieclkmux -physically_exclusive -group clk_125mhz_mux_x0y0 -group clk_250mhz_mux_x0y0}] {
    if {[string first $required_clause $generated_xdc_text] < 0} {
      error "required generated-XDC CDC clause missing: $required_clause"
    }
  }

  set disposition_lines [list \
    {DISPOSITION=PASS_EXACT_REVIEWED_G2B_PROTOCOLS_AND_GEN2_XDMA_PIPE_CLOCK_MUX} \
    {CDC_CRITICAL_TOTAL=427} {CDC_CRITICAL_DISPOSITIONED=427} {CDC_UNKNOWN=0} \
    {*}$hash_receipt "CDC_CRITICAL_TOTAL_SHA256=$total_hash" \
    "G2B_CDC_XDC=$g2b_xdc" "G2B_CDC_XDC_SHA256=$actual_g2b_xdc_sha"]
  foreach family [lsort [dict keys $expected_family_counts]] {
    lappend disposition_lines "${family}_COUNT=[dict get $family_counts $family]"
  }
  lappend disposition_lines \
    {CDC_1_PROTOCOL=ACKNOWLEDGED_STABLE_DATA_MAILBOX} \
    {CDC_1_MAX_DELAY_DATAPATH_ONLY_NS=6.000} \
    {CDC_1_TRANSPORT_MAX_DELAY_DATAPATH_ONLY_NS=2.500} \
    {CDC_1_BUS_SKEW_NS=3.000} \
    {CDC_10_PROTOCOL=EXACT_TWO_STAGE_ASYNC_REG_LEVEL_SYNCHRONIZERS} \
    {CDC_13_PROTOCOL=GENERATED_XDMA_PIPE_CLOCK_MUX} \
    "GENERATED_XDC=$generated_xdc" \
    {GENERATED_XDC_S0_FALSE_PATH=PASS} \
    {GENERATED_XDC_S1_FALSE_PATH=PASS} \
    {GENERATED_XDC_CLOCKS_PHYSICALLY_EXCLUSIVE=PASS} \
    {UNEXPECTED_CRITICAL_CDC_ROWS=0} \
    {BROAD_CDC_WAIVER_APPLIED=NO}
  write_lines [file join $evidence_root G2B_CDC_EXACT_DISPOSITION.txt] $disposition_lines
  return 427
}

proc count_xdc_command_lines {text command_name} {
  set expression [format {^[ \t]*%s(?:[ \t]|$)} $command_name]
  return [regexp -all -line $expression $text]
}

proc strip_bus_skew_constraints {input_path output_path} {
  set removed 0
  set output_lines [list]
  foreach line [split [read_text $input_path] "\n"] {
    if {[string match {set_bus_skew *} [string trimleft $line]]} {
      incr removed
      continue
    }
    lappend output_lines $line
  }
  write_lines $output_path $output_lines
  return $removed
}

proc canonicalize_xdc {input_path output_path} {
  set canonical_lines [list]
  foreach line [split [read_text $input_path] "\n"] {
    set line [string trim $line]
    if {$line eq "" || [string match {#*} $line]} { continue }
    regsub -all {[ \t]+} $line { } line
    lappend canonical_lines $line
  }
  # XDC is Tcl: current_instance and variable definitions make command order
  # semantically significant.  Normalize comments/blank space only.
  write_lines $output_path $canonical_lines
  return [sha256_file $output_path]
}

proc routed_clock_signature {} {
  set rows [list]
  foreach clock [lsort -dictionary [get_clocks -quiet]] {
    lappend rows "[get_property NAME $clock]|[get_property PERIOD $clock]|[get_property WAVEFORM $clock]"
  }
  if {[llength $rows] == 0} { error "routed clock signature is empty" }
  return [join $rows "\n"]
}

proc routed_route_signature {} {
  return [list \
    [report_route_status -boolean_check ROUTED_FULLY] \
    [report_route_status -boolean_check ERRORS_IN_ROUTES] \
    [llength [report_route_status -return_nets -route_type UNROUTED]] \
    [llength [report_route_status -return_nets -route_type PARTIAL]]]
}

proc routed_worst_slack {delay_type} {
  set paths [get_timing_paths -quiet -delay_type $delay_type -max_paths 1 -nworst 1]
  if {[llength $paths] != 1} {
    error "one routed $delay_type timing path was not available"
  }
  set slack [get_property SLACK [lindex $paths 0]]
  if {![string is double -strict $slack]} {
    error "routed $delay_type slack is not numeric: $slack"
  }
  return $slack
}

proc sequential_cells {pattern} {
  return [filter [get_cells -quiet -hier -regexp $pattern] {IS_SEQUENTIAL == 1}]
}

proc resolve_bus_skew_group {group_id} {
  set name UNKNOWN
  set sources [list]
  set destinations [list]
  set expected_sources 0
  set expected_destinations 0
  switch -- $group_id {
    1 {
      set name CFG_PCIE_TO_NVP
      set sources [get_cells -quiet -hier -regexp {.*MAILBOX/cfg_hold_pcie_reg\[[0-9]+\]}]
      set destinations [get_cells -quiet -hier -regexp {.*MAILBOX/nvp_cfg_(abort|arm|capture_generation|clear_errors|line_count_requested|single_line|target_line|window_16_lines)_reg(\[[0-9]+\])?}]
      set expected_sources 74
      set expected_destinations 74
    }
    2 {
      set name STATUS_NVP_TO_PCIE
      set sources [get_cells -quiet -hier -regexp {.*MAILBOX/status_hold_nvp_reg\[[0-9]+\]}]
      set destinations [get_cells -quiet -hier -regexp {.*MAILBOX/status_bus_pcie_reg\[[0-9]+\]}]
      set expected_sources 291
      set expected_destinations 291
    }
    3 {
      set name DIAGNOSTIC_GRAY_TO_FIRST_STAGE
      set sources [get_cells -quiet -hier -regexp {.*(active_sav_gray_nvp_reg|slot_commit_gray_nvp_reg|vclk_edge_gray_nvp_reg)\[[0-9]+\]}]
      set stages [get_cells -quiet -hier -regexp {.*(active_sav_gray_sync1_pcie_reg|slot_commit_gray_sync1_pcie_reg|vclk_edge_gray_sync1_user_reg)\[[0-9]+\]}]
      set destinations [get_pins -quiet -of_objects $stages -filter {REF_PIN_NAME == D}]
      set expected_sources 96
      set expected_destinations 96
    }
    4 {
      set name SNAPSHOT_GRAY_SOURCE_TO_AXI
      set sources [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_(attempted|committed|dropped|overflow)_gray_hold_source_reg\[[0-9]+\]}]
      set stages [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_(attempted|committed|dropped|overflow)_sync1_axi_reg\[[0-9]+\]}]
      set destinations [get_pins -quiet -of_objects $stages -filter {REF_PIN_NAME == D}]
      set expected_sources 128
      set expected_destinations 128
    }
    5 {
      set name SNAPSHOT_EPOCH_SOURCE_TO_AXI
      set sources [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_epoch_echo_source_reg\[[0-9]+\]}]
      set stages [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_epoch_sync1_axi_reg\[[0-9]+\]}]
      set destinations [get_pins -quiet -of_objects $stages -filter {REF_PIN_NAME == D}]
      set expected_sources 32
      set expected_destinations 32
    }
    6 {
      set name HARD_EVENT_BASELINE_SOURCE_TO_AXI
      set sources [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/hard_event_baseline_hold_source_reg\[[0-9]+\]}]
      set stages [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/hard_event_baseline_sync1_axi_reg\[[0-9]+\]}]
      set destinations [get_pins -quiet -of_objects $stages -filter {REF_PIN_NAME == D}]
      set expected_sources 4
      set expected_destinations 4
    }
    7 {
      set name SNAPSHOT_EPOCH_AXI_TO_SOURCE
      set sources [sequential_cells {.*G2B_ONECH_C2H/snapshot_epoch_hold_axi_reg\[[0-9]+\]}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/snapshot_epoch_echo_source_reg\[[0-9]+\]}]
      set expected_sources 32
      set expected_destinations 32
    }
    8 {
      set name TRANSPORT_AXI_TO_SOURCE
      set sources [sequential_cells {.*G2B_ONECH_C2H/(transport_epoch_hold_axi|transport_hard_hold_axi|transport_release_phase_hold_axi|transport_own_phase_hold_axi)_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/(reset_epoch_source|records_attempted_source|records_committed_source|records_dropped_source|overflow_count_source|source_lifetime_dropped|release_seen_source|own_req_seen_source|own_ack_toggle_source|transport_retire_pending_source|transport_ack_toggle_source|reset_abandoned_hold_source|reset_filling_hold_source|reset_commit_phase_hold_source|source_formatter_fatal|source_ownership_fatal|source_formatter_clear_pending|source_ownership_clear_pending|hard_event_baseline_hold_source|hard_event_clear_toggle_source|enable_applied_source)_reg.*}]
      set expected_sources 38
      set expected_destinations 217
    }
    9 {
      set name OWNERSHIP_AXI_TO_SOURCE
      set sources [sequential_cells {.*G2B_ONECH_C2H/(own_slot_hold_axi|own_generation_hold_axi|own_epoch_hold_axi|axis_slot|axis_generation|axis_epoch)_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_req_seen_source|own_ack_toggle_source|own_ok_hold_source)_reg.*}]
      set expected_sources 58
      set expected_destinations 19
    }
    10 {
      set name DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI
      set sources [sequential_cells {.*G2B_ONECH_C2H/desc_attempt_source_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/axis_attempt_reg.*}]
      set expected_sources 44
      set expected_destinations 32
    }
    11 {
      set name DESCRIPTOR_GENERATION_SOURCE_TO_AXI
      set sources [sequential_cells {.*G2B_ONECH_C2H/desc_generation_source_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/(axis_generation|own_generation_hold_axi)_reg.*}]
      set expected_sources 32
      set expected_destinations 24
    }
    12 {
      set name DESCRIPTOR_EPOCH_SOURCE_TO_AXI
      set sources [sequential_cells {.*G2B_ONECH_C2H/desc_epoch_source_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/(axis_epoch|own_epoch_hold_axi)_reg.*}]
      set expected_sources 128
      set expected_destinations 32
    }
    13 {
      set name RESET_RETURN_SOURCE_TO_AXI
      set sources [sequential_cells {.*G2B_ONECH_C2H/(reset_abandoned_hold_source|reset_commit_phase_hold_source)_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/(records_abandoned_axi|commit_seen_axi|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|axis_state|snapshot_busy_axi|snapshot_valid_axi|fatal_clear_qualified_axi|axi_hard_episode)_reg.*}]
      set expected_sources 7
      set expected_destinations 207
    }
    14 -
    15 -
    16 -
    17 {
      set slot [expr {$group_id - 14}]
      set name "RELEASE_SLOT_${slot}_AXI_TO_SOURCE"
      set sources [sequential_cells ".*G2B_ONECH_C2H/(release_generation_axi|release_epoch_axi)_reg\\\[$slot\\\].*"]
      # Match the accepted XDC exactly: every per-slot release source uses the
      # common all-slot release/ownership destination collection.
      set destinations [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|release_seen_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source)_reg.*}]
      set expected_sources 56
      set expected_destinations 20
    }
    default { error "unknown routed bus-skew group: $group_id" }
  }
  return [list $name $sources $destinations $expected_sources $expected_destinations]
}

proc sorted_object_names {objects} {
  set names [list]
  foreach object $objects { lappend names [get_property NAME $object] }
  set unique_names [lsort -dictionary -unique $names]
  if {[llength $unique_names] != [llength $names]} {
    error "duplicate objects resolved in routed bus-skew collection"
  }
  return $unique_names
}

proc parse_compact_bus_skew_metric {report_path label} {
  set rows [list]
  set report_text [read_text $report_path]
  foreach line [split $report_text "\n"] {
    if {[regexp {(?:^|[ \t])(Slow|Fast)[ \t]+(-?[0-9]+(?:\.[0-9]+)?)[ \t]+(-?[0-9]+(?:\.[0-9]+)?)[ \t]+(-?[0-9]+(?:\.[0-9]+)?)[ \t]*$} \
        $line -> corner requirement actual slack]} {
      lappend rows [list $corner $requirement $actual $slack]
    }
  }
  if {[llength $rows] != 1} {
    error "$label compact bus-skew metric-row count failed: rows=[llength $rows]"
  }
  lassign [lindex $rows 0] corner requirement actual slack
  if {![string is double -strict $requirement] ||
      ![string is double -strict $actual] ||
      ![string is double -strict $slack] ||
      abs($requirement - 3.000) > 0.0005} {
    error "$label compact bus-skew metric is invalid: corner=$corner requirement=$requirement actual=$actual slack=$slack"
  }
  # The report is limited to three decimals.  Treat a displayed -0.000 as a
  # violation rather than allowing Tcl's numeric negative zero to compare as
  # nonnegative.
  set negative_display [string match {-*} $slack]
  set violation_marker [regexp -nocase {Slack[ \t]*\([ \t]*VIOLATED[ \t]*\)} $report_text]
  return [list $corner $requirement $actual $slack $negative_display $violation_marker]
}

proc normalize_timing_xdc_fixed_point {
    input_path expected_input_sha output_root stem expected_clock_signature
    expected_bus_skew_count} {
  set current_path $input_path
  set current_sha $expected_input_sha
  set previous_canonical_sha NONE
  for {set pass 1} {$pass <= 4} {incr pass} {
    reset_timing -invalid
    if {[sha256_file $current_path] ne $current_sha} {
      error "$stem timing XDC changed before normalization pass $pass"
    }
    read_xdc $current_path
    if {[routed_clock_signature] ne $expected_clock_signature} {
      error "$stem clock signature changed during normalization pass $pass"
    }
    set pass_path [file join $output_root "${stem}_PASS_${pass}.xdc"]
    set canonical_path \
      [file join $output_root "${stem}_PASS_${pass}_CANONICAL.xdc"]
    write_xdc -exclude_physical -force $pass_path
    set pass_sha [sha256_file $pass_path]
    set pass_count \
      [count_xdc_command_lines [read_text $pass_path] set_bus_skew]
    if {$pass_count != $expected_bus_skew_count} {
      error "$stem normalization pass $pass bus-skew count drift: expected=$expected_bus_skew_count actual=$pass_count"
    }
    set canonical_sha [canonicalize_xdc $pass_path $canonical_path]
    if {$previous_canonical_sha ne "NONE" &&
        $canonical_sha eq $previous_canonical_sha} {
      return [list $pass_path $pass_sha $canonical_sha $pass]
    }
    set current_path $pass_path
    set current_sha $pass_sha
    set previous_canonical_sha $canonical_sha
  }
  error "$stem timing XDC did not reach a semantic fixed point within four passes"
}

# Vivado does not expose a selector for one existing bus-skew constraint.
# Reporting overlapping groups together proved prohibitively expensive on the
# qualification host.  FIX1-R1 recognizes the promoted architecture: exactly
# eleven active relative-skew groups and six retired replacement-method groups.
# Export the exact routed timing constraints, remove only set_bus_skew, and
# reconstruct/report one active group at a time.  The
# placed/routed netlist and every non-skew timing constraint remain unchanged;
# the full timing XDC is restored and identity-checked before later hard gates.
proc run_exact_routed_bus_skew_gate {evidence_root routed_dcp_path routed_dcp_sha} {
  set raw_root [file join $evidence_root BUS_SKEW_GROUPS]
  file mkdir $raw_root
  set aggregate_path [file join $evidence_root BUS_SKEW.rpt]
  set full_raw [file join $raw_root ROUTED_TIMING_FULL_RAW.xdc]
  set base_raw [file join $raw_root ROUTED_TIMING_WITHOUT_BUS_SKEW_RAW.xdc]
  set restored_xdc [file join $raw_root ROUTED_TIMING_RESTORED.xdc]
  set restored_canonical [file join $raw_root ROUTED_TIMING_RESTORED_CANONICAL.xdc]

  set pre_clock_signature [routed_clock_signature]
  set pre_route_signature [routed_route_signature]
  set pre_setup_slack [routed_worst_slack max]
  set pre_hold_slack [routed_worst_slack min]
  write_xdc -exclude_physical -force $full_raw
  set full_raw_sha [sha256_file $full_raw]
  set full_raw_count [count_xdc_command_lines [read_text $full_raw] set_bus_skew]
  if {$full_raw_count != 11} {
    error "routed timing export must contain exactly 11 active bus-skew constraints; found $full_raw_count"
  }
  set removed_count [strip_bus_skew_constraints $full_raw $base_raw]
  set base_raw_sha [sha256_file $base_raw]
  set base_raw_count [count_xdc_command_lines [read_text $base_raw] set_bus_skew]
  if {$removed_count != 11 || $base_raw_count != 0} {
    error "bus-skew base derivation failed: removed=$removed_count active=$base_raw_count"
  }

  set aggregate_lines [list \
    {BUS_SKEW_STATE=RUNNING} \
    "ROUTED_DCP=$routed_dcp_path" \
    "ROUTED_DCP_SHA256=$routed_dcp_sha" \
    "FULL_RAW_XDC_SHA256=$full_raw_sha" \
    "BASE_RAW_XDC_SHA256=$base_raw_sha" \
    "FULL_RAW_BUS_SKEW_CONSTRAINTS=$full_raw_count" \
    "BASE_RAW_BUS_SKEW_CONSTRAINTS=$base_raw_count" \
    "PRE_SETUP_WNS=$pre_setup_slack" \
    "PRE_HOLD_WHS=$pre_hold_slack"]
  write_lines $aggregate_path $aggregate_lines

  set full_semantic_sha NONE
  set full_canonical_sha NONE
  set full_normalization_passes UNKNOWN
  set base_semantic_sha NONE
  set base_canonical_sha NONE
  set base_normalization_passes UNKNOWN
  set full_bus_skew_count UNKNOWN
  set base_bus_skew_count UNKNOWN
  set max_delay_count UNKNOWN
  set false_path_count UNKNOWN
  set clock_group_count UNKNOWN
  set met_count 0
  set violation_count 0
  set group_names [list]
  set restore_source $full_raw
  set restore_source_sha $full_raw_sha

  set operation_code [catch {
    # Vivado can progressively factor shared endpoint collections across more
    # than one write_xdc/read_xdc cycle.  Use the first order-preserving fixed
    # point (bounded at four passes), and reject any clock or constraint-count
    # drift before isolating a bus-skew group.
    lassign [normalize_timing_xdc_fixed_point \
        $full_raw $full_raw_sha $raw_root ROUTED_TIMING_FULL_SEMANTIC \
        $pre_clock_signature 11] \
      full_semantic full_semantic_sha full_canonical_sha \
      full_normalization_passes
    set full_bus_skew_count 11
    set restore_source $full_semantic
    set restore_source_sha $full_semantic_sha

    lassign [normalize_timing_xdc_fixed_point \
        $base_raw $base_raw_sha $raw_root ROUTED_TIMING_WITHOUT_BUS_SKEW_SEMANTIC \
        $pre_clock_signature 0] \
      base_semantic base_semantic_sha base_canonical_sha \
      base_normalization_passes
    set base_bus_skew_count 0
    set base_text [read_text $base_semantic]
    set max_delay_count [count_xdc_command_lines $base_text set_max_delay]
    set false_path_count [count_xdc_command_lines $base_text set_false_path]
    set clock_group_count [count_xdc_command_lines $base_text set_clock_groups]
    if {$max_delay_count == 0 || $false_path_count == 0 || $clock_group_count == 0} {
      error "non-skew timing constraints were not retained: max_delay=$max_delay_count false_path=$false_path_count clock_groups=$clock_group_count"
    }

    lappend aggregate_lines \
      "FULL_SEMANTIC_XDC_SHA256=$full_semantic_sha" \
      "FULL_SEMANTIC_XDC_CANONICAL_SHA256=$full_canonical_sha" \
      "FULL_NORMALIZATION_PASSES=$full_normalization_passes" \
      "BASE_SEMANTIC_XDC_SHA256=$base_semantic_sha" \
      "BASE_SEMANTIC_XDC_CANONICAL_SHA256=$base_canonical_sha" \
      "BASE_NORMALIZATION_PASSES=$base_normalization_passes" \
      "FULL_BUS_SKEW_CONSTRAINTS=$full_bus_skew_count" \
      "BASE_BUS_SKEW_CONSTRAINTS=$base_bus_skew_count" \
      "BASE_MAX_DELAY_CONSTRAINTS=$max_delay_count" \
      "BASE_FALSE_PATH_CONSTRAINTS=$false_path_count" \
      "BASE_CLOCK_GROUP_CONSTRAINTS=$clock_group_count"
    write_lines $aggregate_path $aggregate_lines

    foreach group_id {1 2 3 4 5 6 7 8 10 11 12} {
      reset_timing -invalid
      if {[sha256_file $base_semantic] ne $base_semantic_sha} {
        error "semantic skew-free timing XDC changed before group $group_id"
      }
      read_xdc $base_semantic
      if {[routed_clock_signature] ne $pre_clock_signature} {
        error "clock signature changed before routed bus-skew group $group_id"
      }
      lassign [resolve_bus_skew_group $group_id] \
        group_name sources destinations expected_sources expected_destinations
      if {[lsearch -exact $group_names $group_name] >= 0} {
        error "duplicate routed bus-skew group name: $group_name"
      }
      lappend group_names $group_name
      set source_names [sorted_object_names $sources]
      set destination_names [sorted_object_names $destinations]
      set source_count [llength $source_names]
      set destination_count [llength $destination_names]
      if {$source_count != $expected_sources ||
          $destination_count != $expected_destinations} {
        error "$group_name collection drift: source=$source_count/$expected_sources destination=$destination_count/$expected_destinations"
      }

      set group_tag [format {%02d_%s} $group_id $group_name]
      set inventory_path [file join $raw_root "${group_tag}_OBJECTS.txt"]
      set isolated_xdc [file join $raw_root "${group_tag}_ISOLATED.xdc"]
      set report_path [file join $raw_root "${group_tag}_BUS_SKEW.rpt"]
      set inventory_lines [list]
      foreach name $source_names { lappend inventory_lines "SOURCE=$name" }
      foreach name $destination_names { lappend inventory_lines "DESTINATION=$name" }
      write_lines $inventory_path $inventory_lines
      set inventory_sha [sha256_file $inventory_path]

      set_bus_skew 3.000 -from $sources -to $destinations
      write_xdc -exclude_physical -force $isolated_xdc
      set isolated_count \
        [count_xdc_command_lines [read_text $isolated_xdc] set_bus_skew]
      if {$isolated_count != 1} {
        error "$group_name isolation failed: active bus-skew constraints=$isolated_count"
      }
      set report_start [clock milliseconds]
      report_bus_skew -no_detailed_paths -max_paths 1 -nworst 1 \
        -warn_on_violation -file $report_path
      set elapsed_ms [expr {[clock milliseconds] - $report_start}]
      lassign [parse_compact_bus_skew_metric $report_path $group_name] \
        corner requirement actual slack negative_display violation_marker
      if {$slack < 0.0 || $negative_display || $violation_marker} {
        incr violation_count
        set disposition VIOLATION
      } else {
        incr met_count
        set disposition PASS
      }
      lappend aggregate_lines \
        "GROUP_${group_id}_NAME=$group_name" \
        "GROUP_${group_id}_SOURCE_COUNT=$source_count" \
        "GROUP_${group_id}_DESTINATION_COUNT=$destination_count" \
        "GROUP_${group_id}_OBJECTS_SHA256=$inventory_sha" \
        "GROUP_${group_id}_ISOLATED_XDC_SHA256=[sha256_file $isolated_xdc]" \
        "GROUP_${group_id}_RAW_REPORT_SHA256=[sha256_file $report_path]" \
        "GROUP_${group_id}_CORNER=$corner" \
        "GROUP_${group_id}_REQUIREMENT_NS=$requirement" \
        "GROUP_${group_id}_ACTUAL_NS=$actual" \
        "GROUP_${group_id}_SLACK_NS=$slack" \
        "GROUP_${group_id}_NEGATIVE_DISPLAY=$negative_display" \
        "GROUP_${group_id}_VIOLATION_MARKER=$violation_marker" \
        "GROUP_${group_id}_REPORT_ELAPSED_MS=$elapsed_ms" \
        "GROUP_${group_id}_RESULT=$disposition"
      write_lines $aggregate_path $aggregate_lines
      if {$disposition ne "PASS"} {
        error "$group_name routed bus-skew violation: requirement=$requirement actual=$actual slack=$slack"
      }
    }
    if {[llength $group_names] != 11 || $met_count != 11 || $violation_count != 0} {
      error "routed bus-skew aggregate failed: groups=[llength $group_names] met=$met_count violations=$violation_count"
    }
  } operation_message operation_options]

  # Restore the complete timing view even when a group report or parser fails.
  # A failed restoration is itself fatal and is recorded alongside the primary
  # cause; no later implementation or bitstream stage can run in either case.
  set restore_code [catch {
    if {[sha256_file $restore_source] ne $restore_source_sha} {
      error "full timing restoration source changed before read"
    }
    reset_timing -invalid
    read_xdc $restore_source
    set post_clock_signature [routed_clock_signature]
    if {$post_clock_signature ne $pre_clock_signature} {
      error "clock signature changed after restoring full routed timing XDC"
    }
    write_xdc -exclude_physical -force $restored_xdc
    set restored_text [read_text $restored_xdc]
    set restored_bus_skew_count \
      [count_xdc_command_lines $restored_text set_bus_skew]
    set restored_canonical_sha \
      [canonicalize_xdc $restored_xdc $restored_canonical]
    if {$restored_bus_skew_count != 11} {
      error "restored full timing XDC has $restored_bus_skew_count bus-skew constraints"
    }
    if {$full_canonical_sha ne "NONE" &&
        $restored_canonical_sha ne $full_canonical_sha} {
      error "full routed timing XDC restoration identity failed: expected=$full_canonical_sha actual=$restored_canonical_sha"
    }
    set post_route_signature [routed_route_signature]
    set post_setup_slack [routed_worst_slack max]
    set post_hold_slack [routed_worst_slack min]
    if {$post_route_signature ne $pre_route_signature ||
        abs($post_setup_slack - $pre_setup_slack) > 0.0005 ||
        abs($post_hold_slack - $pre_hold_slack) > 0.0005} {
      error "routed design changed across bus-skew isolation: route=$post_route_signature/$pre_route_signature setup=$post_setup_slack/$pre_setup_slack hold=$post_hold_slack/$pre_hold_slack"
    }
  } restore_message restore_options]

  if {$operation_code != 0 || $restore_code != 0} {
    lappend aggregate_lines \
      "BUS_SKEW_OPERATION_RESULT=[expr {$operation_code == 0 ? {PASS} : {FAIL}}]" \
      "BUS_SKEW_OPERATION_DETAIL=[single_line $operation_message]" \
      "FULL_TIMING_RESTORATION=[expr {$restore_code == 0 ? {PASS} : {FAIL}}]" \
      "FULL_TIMING_RESTORATION_DETAIL=[single_line $restore_message]" \
      "BUS_SKEW_MET_CONSTRAINTS=$met_count" \
      "BUS_SKEW_VIOLATIONS=$violation_count" \
      {BUS_SKEW_GATE=FAIL}
    write_lines $aggregate_path $aggregate_lines
    if {$operation_code != 0} {
      if {$restore_code != 0} {
        error "bus-skew operation failed: $operation_message; full timing restoration also failed: $restore_message"
      }
      return -options $operation_options $operation_message
    }
    return -options $restore_options $restore_message
  }

  lappend aggregate_lines \
    "RESTORED_XDC_SHA256=[sha256_file $restored_xdc]" \
    "RESTORED_XDC_CANONICAL_SHA256=$restored_canonical_sha" \
    "RESTORED_BUS_SKEW_CONSTRAINTS=$restored_bus_skew_count" \
    "POST_SETUP_WNS=$post_setup_slack" \
    "POST_HOLD_WHS=$post_hold_slack" \
    {CLOCK_SIGNATURE_RESTORED=YES} \
    {ROUTE_SIGNATURE_UNCHANGED=YES} \
    {BUS_SKEW_OPERATION_RESULT=PASS} \
    {FULL_TIMING_RESTORATION=PASS} \
    "BUS_SKEW_MET_CONSTRAINTS=$met_count" \
    "BUS_SKEW_VIOLATIONS=$violation_count" \
    {BUS_SKEW_GATE=PASS}
  write_lines $aggregate_path $aggregate_lines
  return [list $violation_count $met_count [sha256_file $aggregate_path]]
}

# FIX1-R1 is a task-local routed-checkpoint recovery mode.  It deliberately
# lives outside the source repository and changes no RTL, XDC, IP, or
# repository build harness.
proc fix1_r1_require_count {label objects expected} {
  set actual [llength $objects]
  if {$actual != $expected} {
    error "$label object-count drift: expected=$expected actual=$actual"
  }
  return $actual
}

proc fix1_r1_rule_id {object_name} {
  if {![regexp {^([A-Z]+-[0-9]+)#[0-9]+$} $object_name -> rule]} {
    error "unrecognized report-check object name: $object_name"
  }
  return $rule
}

proc fix1_r1_check_rule_counts {label objects expected_counts allowed_severities output_path} {
  set actual_counts [dict create]
  set rows [list "Name,Severity,Rule"]
  foreach object $objects {
    set name [get_property NAME $object]
    set severity [string toupper [property_or_unknown SEVERITY $object]]
    if {[lsearch -exact $allowed_severities $severity] < 0} {
      error "$label unexpected severity: $name severity=$severity"
    }
    set rule [fix1_r1_rule_id $name]
    if {![dict exists $expected_counts $rule]} {
      error "$label unexpected finding: $name severity=$severity"
    }
    dict incr actual_counts $rule
    lappend rows "\"$name\",\"$severity\",\"$rule\""
  }
  foreach rule [dict keys $expected_counts] {
    set actual [expr {[dict exists $actual_counts $rule] ? [dict get $actual_counts $rule] : 0}]
    if {$actual != [dict get $expected_counts $rule]} {
      error "$label count drift for $rule: expected=[dict get $expected_counts $rule] actual=$actual"
    }
  }
  write_lines $output_path $rows
}

proc fix1_r1_netlist_signature {path} {
  set rows [list]
  foreach cell [lsort -dictionary [get_cells -quiet -hier]] {
    lappend rows "CELL|[get_property NAME $cell]|[property_or_unknown REF_NAME $cell]"
  }
  foreach net [lsort -dictionary [get_nets -quiet -hier]] {
    lappend rows "NET|[get_property NAME $net]"
  }
  if {[llength $rows] == 0} { error "netlist signature collection is empty" }
  write_lines $path $rows
  return [sha256_file $path]
}

proc fix1_r1_source_retired_absence_gate {} {
  global repo_root evidence_root
  set xdc_path [file join $repo_root xdc common g2b_cdc.xdc]
  set text [read_text $xdc_path]
  # g2b_cdc.xdc is only one component of the routed timing view: it contains
  # eight of the eleven active relations.  The remaining three are supplied
  # by the other unchanged PRODUCT XDC components.  The governed aggregate
  # count is therefore proved from write_xdc after the routed DCP is open;
  # requiring all eleven in this one source file was the stale-harness error.
  set active_count [count_xdc_command_lines $text set_bus_skew]
  if {$active_count != 8} {
    error "g2b_cdc.xdc active set_bus_skew component drift: expected=8 actual=$active_count"
  }
  set retired [dict create \
    9 {g2b_ownership_payload_src} \
    13 {g2b_g13a_} \
    14 {g2b_release0_payload_src} \
    15 {g2b_release1_payload_src} \
    16 {g2b_release2_payload_src} \
    17 {g2b_release3_payload_src}]
  set lines [list]
  foreach group_id {9 13 14 15 16 17} {
    set token [dict get $retired $group_id]
    set present 0
    foreach line [split $text "\n"] {
      set trimmed [string trimleft $line]
      if {[string match {set_bus_skew *} $trimmed] &&
          [string first $token $trimmed] >= 0} {
        set present 1
      }
    }
    lappend lines "GROUP_${group_id}_RETIRED_SET_BUS_SKEW_PRESENT=[expr {$present ? {YES} : {NO}}]"
    if {$present} { error "retired Group $group_id global set_bus_skew relation is active" }
  }
  lappend lines "G2B_CDC_XDC_ACTIVE_SET_BUS_SKEW_COMPONENT_COUNT=$active_count" \
    {ROUTED_EXPORTED_ACTIVE_SET_BUS_SKEW_COUNT=11_VERIFIED_BY_ROUTED_GATE} \
    {RETIRED_RELATIONS_PRESENT=0} {RESULT=PASS}
  write_lines [file join $evidence_root G2B_FIX1_R1_RETIRED_BUS_SKEW_ABSENCE.txt] $lines
}

proc fix1_r1_promoted_family {family_index} {
  set group_id 0
  set family UNKNOWN
  set sources [list]
  set destinations [list]
  set expected_sources 0
  set expected_destinations 0
  switch -- $family_index {
    1 {
      set group_id 9
      set family OWNERSHIP_SLOT_SETTLING
      set sources [sequential_cells {.*G2B_ONECH_C2H/(own_slot_hold_axi|axis_slot)_reg.*}]
      set destinations [get_pins -quiet -of_objects \
        [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_ok_hold_source)_reg.*}] \
        -filter {REF_PIN_NAME == D}]
      set expected_sources 2
      set expected_destinations 17
    }
    2 {
      set group_id 9
      set family OWNERSHIP_GENERATION_SETTLING
      set sources [sequential_cells {.*G2B_ONECH_C2H/(own_generation_hold_axi|axis_generation)_reg.*}]
      set destinations [get_pins -quiet -of_objects \
        [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_ok_hold_source)_reg.*}] \
        -filter {REF_PIN_NAME == D}]
      set expected_sources 24
      set expected_destinations 17
    }
    3 {
      set group_id 9
      set family OWNERSHIP_EPOCH_SETTLING
      set sources [sequential_cells {.*G2B_ONECH_C2H/(own_epoch_hold_axi|axis_epoch)_reg.*}]
      set destinations [get_pins -quiet -of_objects \
        [sequential_cells {.*G2B_ONECH_C2H/(slot_state_source|source_ownership_fatal|source_ownership_fatal_event|source_ownership_fatal_deferred|enable_applied_source|own_ok_hold_source)_reg.*}] \
        -filter {REF_PIN_NAME == D}]
      set expected_sources 32
      set expected_destinations 17
    }
    4 {
      set group_id 13
      set family RESET_ABANDONED_COUNT_STABLE_PAYLOAD
      set sources [sequential_cells {.*G2B_ONECH_C2H/reset_abandoned_hold_source_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/records_abandoned_axi_reg.*}]
      set expected_sources 3
      set expected_destinations 32
    }
    5 {
      set group_id 13
      set family RESET_COMMIT_PHASE_COMPLETION_BARRIER
      set sources [sequential_cells {.*G2B_ONECH_C2H/reset_commit_phase_hold_source_reg.*}]
      set destinations [sequential_cells {.*G2B_ONECH_C2H/(records_abandoned_axi|commit_seen_axi|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|axis_state|snapshot_busy_axi|snapshot_valid_axi|fatal_clear_qualified_axi|axi_hard_episode)_reg.*}]
      set expected_sources 4
      set expected_destinations 207
    }
    default {
      if {$family_index < 6 || $family_index > 17} {
        error "unknown promoted family index: $family_index"
      }
      set slot [expr {($family_index - 6) / 3}]
      set within [expr {($family_index - 6) % 3}]
      set group_id [expr {14 + $slot}]
      set sources [sequential_cells ".*G2B_ONECH_C2H/(release_generation_axi|release_epoch_axi)_reg\\\[$slot\\\].*"]
      set expected_sources 56
      if {$within == 0} {
        set family "RELEASE_SLOT${slot}_NORMAL_STATE_TRANSITION"
        set destinations [sequential_cells ".*G2B_ONECH_C2H/slot_state_source_reg\\\[$slot\\\].*"]
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

proc fix1_r1_structural_cdc_gate {} {
  global evidence_root
  set family_sets [list \
    [list OWNERSHIP_REQUEST_ACK \
      [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(own_req_sync1_source|own_req_sync2_source|own_ack_sync1_axi|own_ack_sync2_axi)_reg}] 4] \
    [list RESET_REQUEST_ACK \
      [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(transport_req_sync1_source|transport_req_sync2_source|transport_ack_sync1_axi|transport_ack_sync2_axi)_reg}] 4] \
    [list RESET_COMMIT_RETURN \
      [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/commit_sync(1|2)_axi_reg\[[0-3]\]}] 8] \
    [list RELEASE_SLOT_TOGGLES \
      [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/release_sync(1|2)_source_reg\[[0-3]\]}] 8]]
  set lines [list]
  foreach item $family_sets {
    lassign $item family cells expected
    fix1_r1_require_count $family $cells $expected
    foreach cell $cells {
      set async_reg [string toupper [property_or_unknown ASYNC_REG $cell]]
      if {$async_reg ni {"TRUE" "1"}} {
        error "$family synchronizer lacks ASYNC_REG=TRUE: [get_property NAME $cell]"
      }
      lappend lines "$family|[get_property NAME $cell]|ASYNC_REG=TRUE|ROUTED_RAW_VALUE=$async_reg"
    }
  }
  lappend lines \
    {OWNERSHIP_CDC=PASS} {RESET_RETURN_CDC=PASS} {RELEASE_SLOT_CDC=PASS} \
    {STABLE_DATA_PROTOCOL=PASS_EXACT_COMMIT_TREE_AND_PROMOTED_CONSTRAINTS} \
    {EARLIEST_SEMANTIC_USE_NS=13.468} {SETTLING_CAP_NS=6.000} \
    {GOVERNED_GROSS_RESERVE_NS=7.468} \
    {DIRECT_RAW_USE_BEFORE_SYNC_REQUEST=NO_EXACT_INHERITED_STRUCTURAL_PROOF} \
    {RESULT=PASS}
  write_lines [file join $evidence_root G2B_FIX1_R1_STRUCTURAL_CDC.txt] $lines
}

proc fix1_r1_run_promoted_replacements {} {
  global evidence_root
  set raw_root [file join $evidence_root PROMOTED_REPLACEMENTS]
  file mkdir $raw_root
  set csv [list "CheckIndex,Group,Family,SourceCount,DestinationCount,RequiredNs,DatapathDelayNs,SlackNs,RuntimeMs,Result,ReportSHA256,ObjectsSHA256"]
  set matrix [dict create]
  set pass_count 0
  for {set family_index 1} {$family_index <= 17} {incr family_index} {
    lassign [fix1_r1_promoted_family $family_index] \
      group_id family sources destinations expected_sources expected_destinations
    set source_names [sorted_object_names $sources]
    set destination_names [sorted_object_names $destinations]
    fix1_r1_require_count "$family sources" $source_names $expected_sources
    fix1_r1_require_count "$family destinations" $destination_names $expected_destinations
    set tag [format {%02d_G%02d_%s} $family_index $group_id $family]
    set objects_path [file join $raw_root "${tag}_OBJECTS.txt"]
    set report_path [file join $raw_root "${tag}_TIMING.rpt"]
    set object_lines [list]
    foreach name $source_names { lappend object_lines "SOURCE=$name" }
    foreach name $destination_names { lappend object_lines "DESTINATION=$name" }
    write_lines $objects_path $object_lines
    set start_ms [clock milliseconds]
    set paths [get_timing_paths -quiet -delay_type max -sort_by slack \
      -max_paths 1 -nworst 1 -from $sources -to $destinations]
    set elapsed_ms [expr {[clock milliseconds] - $start_ms}]
    if {[llength $paths] != 1} {
      error "$family expected exactly one worst timing path; found [llength $paths]"
    }
    set path [lindex $paths 0]
    set slack [get_property SLACK $path]
    if {![string is double -strict $slack] || $slack < 0.0} {
      error "$family promoted 6.000 ns settling check failed: slack=$slack"
    }
    set datapath [property_or_unknown DATAPATH_DELAY $path]
    report_timing -of_objects $paths -file $report_path
    lappend csv "$family_index,$group_id,$family,$expected_sources,$expected_destinations,6.000,$datapath,$slack,$elapsed_ms,PASS,[sha256_file $report_path],[sha256_file $objects_path]"
    dict incr matrix $group_id
    incr pass_count
    write_lines [file join $evidence_root G2B_FIX1_R1_PROMOTED_REPLACEMENT_RESULTS.csv] $csv
  }
  foreach requirement [list [list 9 3] [list 13 2] [list 14 3] [list 15 3] [list 16 3] [list 17 3]] {
    lassign $requirement group_id expected
    set actual [expr {[dict exists $matrix $group_id] ? [dict get $matrix $group_id] : 0}]
    if {$actual != $expected} {
      error "Group $group_id promoted replacement count failed: expected=$expected actual=$actual"
    }
  }
  if {$pass_count != 17} {
    error "promoted replacement aggregate failed: pass=$pass_count/17"
  }
  return $pass_count
}

proc fix1_r1_read_key_values {path} {
  set values [dict create]
  foreach line [split [read_text $path] "\n"] {
    if {![regexp {^([^=]+)=(.*)$} $line -> key value]} { continue }
    dict set values $key [string trim $value]
  }
  return $values
}

proc fix1_r1_verify_completed_measurement_receipts {expected_dcp_sha} {
  global evidence_root
  set bus_path [file join $evidence_root BUS_SKEW.rpt]
  set promoted_path [file join $evidence_root G2B_FIX1_R1_PROMOTED_REPLACEMENT_RESULTS.csv]
  set retired_path [file join $evidence_root G2B_FIX1_R1_RETIRED_BUS_SKEW_ABSENCE.txt]
  set expected_bus_sha F58BEC3B29EF12EF3162A728C9DEE792FA45B5BFD8177E3B3E6B7F949D2C919C
  set expected_promoted_sha 44251DFEAD5ECF21C3ABE0F62F2B9C1B7C7536B5FE3FE901B086F8B1FA3F61B6
  set expected_retired_sha 4DCD7C3EA406285B0B6A388C3E0EDC39E4D3A3A286AD14B05CBC858DF75408F1
  foreach item [list \
      [list $bus_path $expected_bus_sha BUS_SKEW] \
      [list $promoted_path $expected_promoted_sha PROMOTED_REPLACEMENTS] \
      [list $retired_path $expected_retired_sha RETIRED_ABSENCE]] {
    lassign $item path expected_sha label
    if {![file isfile $path]} { error "$label completed-run receipt is missing: $path" }
    set actual_sha [sha256_file $path]
    if {$actual_sha ne $expected_sha} {
      error "$label completed-run receipt hash mismatch: expected=$expected_sha actual=$actual_sha"
    }
  }

  set bus [fix1_r1_read_key_values $bus_path]
  foreach item [list \
      [list ROUTED_DCP_SHA256 $expected_dcp_sha] \
      [list FULL_RAW_BUS_SKEW_CONSTRAINTS 11] \
      [list BASE_RAW_BUS_SKEW_CONSTRAINTS 0] \
      [list RESTORED_BUS_SKEW_CONSTRAINTS 11] \
      [list BUS_SKEW_MET_CONSTRAINTS 11] \
      [list BUS_SKEW_VIOLATIONS 0] \
      [list BUS_SKEW_GATE PASS] \
      [list FULL_TIMING_RESTORATION PASS] \
      [list ROUTE_SIGNATURE_UNCHANGED YES] \
      [list CLOCK_SIGNATURE_RESTORED YES]] {
    lassign $item key expected
    if {![dict exists $bus $key] || [dict get $bus $key] ne $expected} {
      error "completed bus-skew receipt mismatch: $key expected=$expected actual=[expr {[dict exists $bus $key] ? [dict get $bus $key] : {MISSING}}]"
    }
  }
  set active_names [dict create \
    1 CFG_PCIE_TO_NVP 2 STATUS_NVP_TO_PCIE 3 DIAGNOSTIC_GRAY_TO_FIRST_STAGE \
    4 SNAPSHOT_GRAY_SOURCE_TO_AXI 5 SNAPSHOT_EPOCH_SOURCE_TO_AXI \
    6 HARD_EVENT_BASELINE_SOURCE_TO_AXI 7 SNAPSHOT_EPOCH_AXI_TO_SOURCE \
    8 TRANSPORT_AXI_TO_SOURCE 10 DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI \
    11 DESCRIPTOR_GENERATION_SOURCE_TO_AXI 12 DESCRIPTOR_EPOCH_SOURCE_TO_AXI]
  foreach group_id {1 2 3 4 5 6 7 8 10 11 12} {
    set name [dict get $active_names $group_id]
    if {![dict exists $bus GROUP_${group_id}_RESULT] ||
        [dict get $bus GROUP_${group_id}_RESULT] ne "PASS"} {
      error "completed active bus-skew Group $group_id is not PASS"
    }
    set prefix [format {%02d_%s} $group_id $name]
    foreach item [list \
        [list "${prefix}_OBJECTS.txt" GROUP_${group_id}_OBJECTS_SHA256] \
        [list "${prefix}_ISOLATED.xdc" GROUP_${group_id}_ISOLATED_XDC_SHA256] \
        [list "${prefix}_BUS_SKEW.rpt" GROUP_${group_id}_RAW_REPORT_SHA256]] {
      lassign $item filename hash_key
      set path [file join $evidence_root BUS_SKEW_GROUPS $filename]
      if {![file isfile $path] || ![dict exists $bus $hash_key] ||
          [sha256_file $path] ne [dict get $bus $hash_key]} {
        error "completed active bus-skew artifact mismatch: $filename"
      }
    }
  }

  set promoted_lines [split [string trim [read_text $promoted_path]] "\n"]
  if {[llength $promoted_lines] != 18} {
    error "completed promoted replacement row count mismatch: [expr {[llength $promoted_lines] - 1}]/17"
  }
  set group_counts [dict create]
  for {set row 1} {$row < 18} {incr row} {
    set fields [split [lindex $promoted_lines $row] ,]
    if {[llength $fields] != 12 || [lindex $fields 9] ne "PASS"} {
      error "completed promoted replacement row $row is malformed or not PASS"
    }
    set check_index [lindex $fields 0]
    set group_id [lindex $fields 1]
    set family [lindex $fields 2]
    set tag [format {%02d_G%02d_%s} $check_index $group_id $family]
    set report_path [file join $evidence_root PROMOTED_REPLACEMENTS "${tag}_TIMING.rpt"]
    set objects_path [file join $evidence_root PROMOTED_REPLACEMENTS "${tag}_OBJECTS.txt"]
    if {![file isfile $report_path] || [sha256_file $report_path] ne [lindex $fields 10] ||
        ![file isfile $objects_path] || [sha256_file $objects_path] ne [lindex $fields 11]} {
      error "completed promoted replacement artifact mismatch: $tag"
    }
    dict incr group_counts $group_id
  }
  foreach requirement [list [list 9 3] [list 13 2] [list 14 3] [list 15 3] [list 16 3] [list 17 3]] {
    lassign $requirement group_id expected
    if {![dict exists $group_counts $group_id] || [dict get $group_counts $group_id] != $expected} {
      error "completed promoted replacement Group $group_id count mismatch"
    }
  }
  write_lines [file join $evidence_root G2B_FIX1_R1_COMPLETED_MEASUREMENTS_RESUME_RECEIPT.txt] [list \
    {SOURCE_PHASE=FIX1_R1_ROUTED_DCP_RECOVERY_THIRD_EXECUTION} \
    "ROUTED_DCP_SHA256=$expected_dcp_sha" \
    "BUS_SKEW_RECEIPT_SHA256=$expected_bus_sha" \
    "PROMOTED_REPLACEMENT_RECEIPT_SHA256=$expected_promoted_sha" \
    "RETIRED_ABSENCE_RECEIPT_SHA256=$expected_retired_sha" \
    {ACTIVE_BUS_SKEW_GROUPS_VERIFIED=11/11} \
    {PROMOTED_REPLACEMENT_CHECKS_VERIFIED=17/17} \
    {RETIRED_RELATIONS_ABSENT_VERIFIED=6/6} \
    {RESULT=PASS}]
  return [list 0 11 $expected_bus_sha 17]
}

proc fix1_r1_run_cdc_gate {} {
  global evidence_root
  set cdc_path [file join $evidence_root CDC.rpt]
  report_cdc -details -file $cdc_path
  set violations [get_cdc_violations -quiet]
  set critical 0
  set warnings [list]
  foreach violation $violations {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "CRITICAL" || $severity eq "CRITICAL WARNING"} { incr critical }
    if {$severity eq "WARNING"} { lappend warnings $violation }
  }
  set dispositioned [enforce_exact_cdc_disposition $cdc_path $violations]
  if {$critical != 427 || $dispositioned != 427} {
    error "critical CDC disposition failed: current=$critical dispositioned=$dispositioned"
  }
  fix1_r1_check_rule_counts CDC_WARNING $warnings \
    [dict create CDC-6 13 CDC-15 861] {WARNING} \
    [file join $evidence_root G2B_FIX1_R1_CDC_WARNING_OBJECTS.csv]
  write_lines [file join $evidence_root G2B_FIX1_R1_CDC_GATE.txt] [list \
    {CDC_REPORT_EXECUTED=YES} \
    "CURRENT_CRITICAL_CDC_FINDINGS=$critical" \
    "CRITICAL_CDC_FINDINGS_DISPOSITIONED=$dispositioned" \
    {UNRESOLVED_CRITICAL_CDC_FINDINGS=0} \
    {CURRENT_WARNING_CDC_FINDINGS=874} \
    {WARNING_CDC_FINDINGS_DISPOSITIONED=874} \
    {UNRESOLVED_WARNING_CDC_FINDINGS=0} \
    {OWNERSHIP_CDC=PASS} {RESET_RETURN_CDC=PASS} {RELEASE_SLOT_CDC=PASS} \
    {BROAD_CDC_WAIVER_APPLIED=NO} {RESULT=PASS}]
  return [list $critical $dispositioned]
}

proc fix1_r1_run_drc_gate {} {
  global evidence_root
  set path [file join $evidence_root DRC.rpt]
  report_drc -file $path
  set errors 0
  set critical 0
  set warnings [list]
  foreach violation [get_drc_violations -quiet] {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "ERROR"} { incr errors }
    if {$severity eq "CRITICAL WARNING"} { incr critical }
    if {$severity eq "WARNING"} { lappend warnings $violation }
  }
  if {$errors != 0 || $critical != 0} {
    error "DRC hard gate failed: errors=$errors critical_warnings=$critical"
  }
  fix1_r1_check_rule_counts DRC_WARNING $warnings \
    [dict create PDCN-1569 1 REQP-1839 12 RTSTAT-10 1] {WARNING} \
    [file join $evidence_root G2B_FIX1_R1_DRC_WARNING_OBJECTS.csv]
  write_lines [file join $evidence_root G2B_FIX1_R1_DRC_GATE.txt] [list \
    {DRC=PASS} "DRC_ERRORS=$errors" "DRC_CRITICAL_WARNINGS=$critical" \
    {DRC_WARNINGS=14} {ALL_WARNINGS_EXACT_ACCEPTED_DISPOSITION=YES}]
}

proc fix1_r1_run_methodology_gate {} {
  global evidence_root
  set path [file join $evidence_root METHODOLOGY.rpt]
  report_methodology -file $path
  if {[catch {get_methodology_violations -quiet} violations]} {
    error "methodology violation objects unavailable: $violations"
  }
  set errors 0
  set critical 0
  set warnings [list]
  foreach violation $violations {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "ERROR"} { incr errors }
    if {$severity eq "CRITICAL WARNING"} { incr critical }
    if {$severity eq "WARNING"} { lappend warnings $violation }
  }
  if {$errors != 0 || $critical != 0} {
    error "methodology hard gate failed: errors=$errors critical_warnings=$critical"
  }
  fix1_r1_check_rule_counts METHODOLOGY_WARNING $warnings \
    [dict create LUTAR-1 2 TIMING-9 1 TIMING-34 11 TIMING-39 1] {WARNING} \
    [file join $evidence_root G2B_FIX1_R1_METHODOLOGY_WARNING_OBJECTS.csv]
  write_lines [file join $evidence_root G2B_FIX1_R1_METHODOLOGY_GATE.txt] [list \
    {METHODOLOGY=PASS} "METHODOLOGY_ERRORS=$errors" \
    "METHODOLOGY_CRITICAL_WARNINGS=$critical" {METHODOLOGY_WARNINGS=15} \
    {ALL_WARNINGS_EXACT_ACCEPTED_DISPOSITION=YES} \
    {NO_WAIVER_OR_MESSAGE_SUPPRESSION=YES}]
}

proc fix1_r1_route_metric {text label} {
  foreach line [split $text "\n"] {
    if {[string first $label $line] < 0} { continue }
    if {[regexp {: *([0-9,]+) *:} $line -> value]} {
      return [string map [list "," ""] $value]
    }
  }
  error "route metric not found: $label"
}

proc fix1_r1_run_final_timing_and_resource_gates {} {
  global evidence_root expected_user_clock_mhz clock_tolerance_mhz
  set timing_summary [file join $evidence_root TIMING_SUMMARY.rpt]
  set setup_path [file join $evidence_root ROUTED_SETUP_TIMING.rpt]
  set hold_path [file join $evidence_root ROUTED_HOLD_TIMING.rpt]
  set check_path [file join $evidence_root CHECK_TIMING.rpt]
  set route_path [file join $evidence_root ROUTE_STATUS.rpt]
  set clocks_path [file join $evidence_root CLOCKS.rpt]
  set clock_interaction_path [file join $evidence_root CLOCK_INTERACTION.rpt]
  report_timing_summary -delay_type min_max -check_timing_verbose \
    -report_unconstrained -max_paths 10 -nworst 1 -file $timing_summary
  report_timing -delay_type max -max_paths 100 -nworst 1 -file $setup_path
  report_timing -delay_type min -max_paths 100 -nworst 1 -file $hold_path
  check_timing -verbose -file $check_path
  report_route_status -file $route_path
  report_clocks -file $clocks_path
  report_clock_interaction -file $clock_interaction_path

  set wns [routed_worst_slack max]
  set whs [routed_worst_slack min]
  set failing_setup [llength [get_timing_paths -quiet -delay_type max \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set failing_hold [llength [get_timing_paths -quiet -delay_type min \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  if {$wns < 0.0 || $whs < 0.0 || $failing_setup != 0 || $failing_hold != 0} {
    error "ordinary timing gate failed: WNS=$wns WHS=$whs setup_failures=$failing_setup hold_failures=$failing_hold"
  }
  set check_text [read_text $check_path]
  foreach zero_check {no_clock unconstrained_internal_endpoints multiple_clock generated_clocks loops partial_input_delay partial_output_delay latch_loops} {
    set value [check_timing_table_count $check_text $zero_check]
    if {$value eq "UNKNOWN" || $value != 0} {
      error "check_timing gate failed: $zero_check=$value"
    }
  }
  set timing_text [read_text $timing_summary]
  if {[regexp -nocase {Pulse Width Slack[^\n]*-[0-9]} $timing_text] ||
      [regexp -nocase {VIOLATED} $timing_text]} {
    error "timing summary contains a pulse-width or timing violation"
  }

  set route_text [read_text $route_path]
  set routable [fix1_r1_route_metric $route_text {# of routable nets}]
  set fully_routed [fix1_r1_route_metric $route_text {# of fully routed nets}]
  set route_errors [fix1_r1_route_metric $route_text {# of nets with routing errors}]
  set unrouted [llength [report_route_status -return_nets -route_type UNROUTED]]
  set partial [llength [report_route_status -return_nets -route_type PARTIAL]]
  if {$routable != $fully_routed || $route_errors != 0 || $unrouted != 0 || $partial != 0 ||
      ![report_route_status -boolean_check ROUTED_FULLY]} {
    error "route gate failed: routable=$routable fully=$fully_routed errors=$route_errors unrouted=$unrouted partial=$partial"
  }

  set user_clocks [get_clocks -quiet userclk1]
  fix1_r1_require_count USERCLK1 $user_clocks 1
  set user_period [get_property PERIOD [lindex $user_clocks 0]]
  set user_mhz [expr {1000.0 / $user_period}]
  set nvp_pins [get_pins -quiet -hier -regexp {.*NVP_AUTOINIT.*/C}]
  set axi_pins [get_pins -quiet -hier -regexp {.*AXI_LITE_HOST_BRIDGE.*/C}]
  set nvp_clocks [unique_objects_by_name [get_clocks -quiet -of_objects $nvp_pins]]
  set axi_clocks [unique_objects_by_name [get_clocks -quiet -of_objects $axi_pins]]
  if {[llength $nvp_clocks] == 0 || [llength $axi_clocks] == 0 ||
      [sorted_object_names $nvp_clocks] ne [sorted_object_names $axi_clocks]} {
    error "AXI/user application clock binding failed"
  }
  set axi_period [get_property PERIOD [lindex $axi_clocks 0]]
  set axi_mhz [expr {1000.0 / $axi_period}]
  if {abs($user_mhz - $expected_user_clock_mhz) > $clock_tolerance_mhz ||
      abs($axi_mhz - $expected_user_clock_mhz) > $clock_tolerance_mhz} {
    error "application clock frequency drift: user=$user_mhz axi=$axi_mhz"
  }

  set metrics [resource_metrics ROUTED]
  set lut_percent [dict get $metrics LUT_PERCENT]
  set ff_percent [dict get $metrics FF_PERCENT]
  set bram_percent [dict get $metrics BRAM_PERCENT]
  set dsp_percent [dict get $metrics DSP_PERCENT]
  if {$lut_percent > 90.0 || $ff_percent > 95.0 ||
      $bram_percent > 90.0 || $dsp_percent > 90.0} {
    error "resource hard gate failed: LUT=$lut_percent FF=$ff_percent BRAM=$bram_percent DSP=$dsp_percent"
  }

  set debug_count 0
  if {![catch {get_debug_cores -quiet} debug_cores]} {
    set debug_count [llength $debug_cores]
  }
  set diag_cells [get_cells -quiet -hier -regexp {.*(BT656_DIAG1|DIAG1_TRACE|RAW_MARKER_TRACE|RTRACK_TRACE).*}]
  if {$debug_count != 0 || [llength $diag_cells] != 0} {
    error "PRODUCT diagnostic instrumentation gate failed: debug_cores=$debug_count diagnostic_cells=[llength $diag_cells]"
  }

  write_lines [file join $evidence_root G2B_FIX1_R1_TIMING_RESOURCE_CLOCK_GATE.txt] [list \
    {FULLY_ROUTED=YES} "ROUTABLE_NETS=$routable" "FULLY_ROUTED_NETS=$fully_routed" \
    "UNROUTED_NETS=$unrouted" "PARTIALLY_ROUTED_NETS=$partial" \
    "WNS=[format %.3f $wns]" {TNS=0.000} "WHS=[format %.3f $whs]" {THS=0.000} \
    {INTERNAL_UNCONSTRAINED_ENDPOINTS=0} {TIMING_LOOPS=0} \
    "EFFECTIVE_USER_CLOCK_MHZ=[format %.6f $user_mhz]" \
    "EFFECTIVE_AXI_CLOCK_MHZ=[format %.6f $axi_mhz]" \
    "LUT_USED=[dict get $metrics LUT_USED]" "LUT_AVAILABLE=[dict get $metrics LUT_AVAILABLE]" \
    "LUT_PERCENT=[format %.3f $lut_percent]" \
    "FF_USED=[dict get $metrics FF_USED]" "FF_AVAILABLE=[dict get $metrics FF_AVAILABLE]" \
    "FF_PERCENT=[format %.3f $ff_percent]" \
    "BRAM_USED=[dict get $metrics BRAM_USED]" "BRAM_AVAILABLE=[dict get $metrics BRAM_AVAILABLE]" \
    "BRAM_PERCENT=[format %.3f $bram_percent]" \
    "DSP_USED=[dict get $metrics DSP_USED]" "DSP_AVAILABLE=[dict get $metrics DSP_AVAILABLE]" \
    "DSP_PERCENT=[format %.3f $dsp_percent]" \
    {DIAGNOSTIC_TRACE_PRESENT=NO} {DIAGNOSTIC_MMIO_0x3C00_PRESENT=NO_PRODUCT_PROFILE} \
    {ILA_PRESENT=NO} {VIO_PRESENT=NO} {LTX_EXPECTED=NO} {RESULT=PASS}]
  return [list $wns $whs $routable $metrics $user_mhz $axi_mhz]
}

proc fix1_r1_write_all_groups_matrix {} {
  global evidence_root
  set rows [list "Group,Name,Method,Result"]
  set names [dict create \
    1 CFG_PCIE_TO_NVP 2 STATUS_NVP_TO_PCIE 3 DIAGNOSTIC_GRAY_TO_FIRST_STAGE \
    4 SNAPSHOT_GRAY_SOURCE_TO_AXI 5 SNAPSHOT_EPOCH_SOURCE_TO_AXI \
    6 HARD_EVENT_BASELINE_SOURCE_TO_AXI 7 SNAPSHOT_EPOCH_AXI_TO_SOURCE \
    8 TRANSPORT_AXI_TO_SOURCE 9 OWNERSHIP_AXI_TO_SOURCE \
    10 DESCRIPTOR_ATTEMPT_SOURCE_TO_AXI 11 DESCRIPTOR_GENERATION_SOURCE_TO_AXI \
    12 DESCRIPTOR_EPOCH_SOURCE_TO_AXI 13 RESET_RETURN_SOURCE_TO_AXI \
    14 RELEASE_SLOT_0_AXI_TO_SOURCE 15 RELEASE_SLOT_1_AXI_TO_SOURCE \
    16 RELEASE_SLOT_2_AXI_TO_SOURCE 17 RELEASE_SLOT_3_AXI_TO_SOURCE]
  foreach group_id {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17} {
    if {$group_id in {9 13 14 15 16 17}} {
      set method PROMOTED_SETTLING_PLUS_STRUCTURAL_CDC
      set result PASS_PROMOTED_REPLACEMENT
    } else {
      set method ACTIVE_SET_BUS_SKEW_3NS
      set result PASS_ACTIVE_BUS_SKEW
    }
    lappend rows "$group_id,[dict get $names $group_id],$method,$result"
  }
  write_lines [file join $evidence_root G2B_FIX1_R1_ALL_GROUPS_1_17_MATRIX.csv] $rows
}

proc fix1_r1_recovery_main {} {
  global env repo_root build_root evidence_root source_commit source_tree
  if {![info exists env(G2B_FIX1_R1_ROUTED_DCP)] ||
      ![info exists env(G2B_FIX1_R1_ARTIFACT_ROOT)]} {
    error "FIX1-R1 routed recovery environment is incomplete"
  }
  set routed_dcp [file normalize $env(G2B_FIX1_R1_ROUTED_DCP)]
  set artifact_root [file normalize $env(G2B_FIX1_R1_ARTIFACT_ROOT)]
  file mkdir $build_root
  file mkdir $evidence_root
  file mkdir $artifact_root
  set expected_dcp_sha 45D04813DC3B9C354235F28959067EF8B8F021CCB180E7454A060D44B8FE4173
  if {![file isfile $routed_dcp]} { error "source routed DCP is unavailable: $routed_dcp" }
  set actual_dcp_sha [sha256_file $routed_dcp]
  if {$actual_dcp_sha ne $expected_dcp_sha} {
    error "source routed DCP hash mismatch: expected=$expected_dcp_sha actual=$actual_dcp_sha"
  }
  if {[git_value symbolic-ref --short HEAD] ne "fix/v41-g2b-bt656-line0-sof" ||
      [git_value rev-parse HEAD] ne $source_commit ||
      [git_value rev-parse {HEAD^{tree}}] ne $source_tree ||
      [git_value status --porcelain --untracked-files=all] ne ""} {
    error "FIX1_R1_SOURCE_AUTHORITY_OPERATIONAL_CONTRADICTION"
  }
  open_checkpoint $routed_dcp
  if {[get_property PART [current_design]] ne "xc7a35tcsg325-2"} {
    error "routed DCP part mismatch: [get_property PART [current_design]]"
  }
  set pre_clock_signature [routed_clock_signature]
  set pre_route_signature [routed_route_signature]
  set pre_wns [routed_worst_slack max]
  set pre_whs [routed_worst_slack min]
  if {abs($pre_wns - 0.148) > 0.0005 || abs($pre_whs - 0.044) > 0.0005} {
    error "accepted routed timing identity mismatch: WNS=$pre_wns WHS=$pre_whs"
  }
  set pre_netlist_sha [fix1_r1_netlist_signature \
    [file join $evidence_root NETLIST_SIGNATURE_PRE.txt]]

  fix1_r1_source_retired_absence_gate
  if {[info exists env(G2B_FIX1_R1_RESUME_COMPLETED_MEASUREMENTS)] &&
      $env(G2B_FIX1_R1_RESUME_COMPLETED_MEASUREMENTS) eq "1"} {
    lassign [fix1_r1_verify_completed_measurement_receipts $actual_dcp_sha] \
      skew_violations skew_pass skew_report_sha promoted_pass
  } else {
    lassign [run_exact_routed_bus_skew_gate $evidence_root $routed_dcp $actual_dcp_sha] \
      skew_violations skew_pass skew_report_sha
    if {$skew_violations != 0 || $skew_pass != 11} {
      error "active bus-skew aggregate failed: pass=$skew_pass violations=$skew_violations"
    }
    set promoted_pass [fix1_r1_run_promoted_replacements]
  }
  fix1_r1_structural_cdc_gate
  fix1_r1_write_all_groups_matrix

  set post_clock_signature [routed_clock_signature]
  set post_route_signature [routed_route_signature]
  set post_wns [routed_worst_slack max]
  set post_whs [routed_worst_slack min]
  set post_netlist_sha [fix1_r1_netlist_signature \
    [file join $evidence_root NETLIST_SIGNATURE_POST.txt]]
  if {$post_clock_signature ne $pre_clock_signature ||
      $post_route_signature ne $pre_route_signature ||
      $post_netlist_sha ne $pre_netlist_sha ||
      abs($post_wns - $pre_wns) > 0.0005 ||
      abs($post_whs - $pre_whs) > 0.0005} {
    error "full timing restoration identity failed after promoted reconciliation"
  }

  lassign [fix1_r1_run_final_timing_and_resource_gates] \
    wns whs routable resource user_mhz axi_mhz
  fix1_r1_run_cdc_gate
  fix1_r1_run_drc_gate
  fix1_r1_run_methodology_gate

  set signed_dcp [file join $artifact_root G2B_BT656_FIX1_R1_SIGNED_OFF_ROUTED.dcp]
  set bit_path [file join $artifact_root G2B_BT656_FIX1_R1_PRODUCT.bit]
  write_checkpoint -force $signed_dcp
  set signed_dcp_sha [sha256_file $signed_dcp]
  if {[routed_route_signature] ne $pre_route_signature} {
    error "route signature changed before bitstream generation"
  }
  write_bitstream -force $bit_path
  if {![file isfile $bit_path] || [file size $bit_path] == 0} {
    error "PRODUCT bitstream was not generated"
  }
  set bit_sha [sha256_file $bit_path]

  write_lines [file join $evidence_root G2B_FIX1_R1_RECOVERY_RESULT.txt] [list \
    {RESULT=PASS} {RECOVERY_MODE=ROUTED_DCP_REUSE} \
    "SOURCE_COMMIT=$source_commit" "SOURCE_TREE=$source_tree" \
    "SOURCE_ROUTED_DCP=$routed_dcp" "SOURCE_ROUTED_DCP_SHA256=$actual_dcp_sha" \
    {ACTIVE_RELATIVE_BUS_SKEW_GROUPS=1,2,3,4,5,6,7,8,10,11,12} \
    {ACTIVE_RELATIVE_BUS_SKEW_GROUP_COUNT=11} \
    {PROMOTED_REPLACEMENT_GROUPS=9,13,14,15,16,17} \
    {PROMOTED_REPLACEMENT_GROUP_COUNT=6} {TOTAL_GOVERNED_GROUPS=17} \
    "ACTIVE_BUS_SKEW_GROUPS_PASS=$skew_pass" "ACTIVE_BUS_SKEW_VIOLATIONS=$skew_violations" \
    "PROMOTED_REPLACEMENT_CHECKS_PASS=$promoted_pass" \
    {PROMOTED_REPLACEMENT_FAILURES=0} {ALL_GOVERNED_GROUPS_1_TO_17=PASS} \
    {FULL_TIMING_RESTORATION=PASS} {ROUTE_SIGNATURE_UNCHANGED=YES} \
    {CLOCK_SIGNATURE_UNCHANGED=YES} {NETLIST_SIGNATURE_UNCHANGED=YES} \
    "NETLIST_SIGNATURE_SHA256=$post_netlist_sha" \
    "WNS=[format %.3f $wns]" {TNS=0.000} "WHS=[format %.3f $whs]" {THS=0.000} \
    "SIGNED_OFF_DCP=$signed_dcp" "SIGNED_OFF_DCP_SHA256=$signed_dcp_sha" \
    "BITSTREAM=$bit_path" "BITSTREAM_SIZE=[file size $bit_path]" \
    "BITSTREAM_SHA256=$bit_sha" \
    {CANDIDATE_CLASSIFICATION=BT656_FIX1_R1_OFFLINE_QUALIFIED_PRODUCT_CANDIDATE} \
    {LTX=NONE_EXPECTED_PRODUCT_PROFILE}]
  close_design
}

if {$execution_mode eq "FIX1_R1_ROUTED_DCP_RECOVERY"} {
  set result_path [file join $evidence_root G2B_FIX1_R1_RECOVERY_RESULT.txt]
  set result_code [catch {fix1_r1_recovery_main} result_message result_options]
  if {$result_code != 0} {
    write_lines $result_path [list \
      {RESULT=FAIL} "DETAIL=[single_line $result_message]" \
      "ERRORINFO=[single_line [dict get $result_options -errorinfo]]"]
    catch {close_design}
    puts stderr $result_message
    exit 1
  }
  puts "FIX1_R1_ROUTED_DCP_RECOVERY=PASS"
  exit 0
}

# Path and argument validation happens before either execution mode writes.
if {![file isdirectory $repo_root]} { error "REPO_ROOT is not a directory: $repo_root" }
if {[path_is_within $build_root $repo_root] || [path_is_within $evidence_root $repo_root]} {
  error "BUILD_ROOT and EVIDENCE_ROOT must both be outside REPO_ROOT"
}
if {[path_is_within $evidence_root $build_root] || [path_is_within $build_root $evidence_root]} {
  error "BUILD_ROOT and EVIDENCE_ROOT must be disjoint"
}
if {$bit_filename eq "" || [file tail $bit_filename] ne $bit_filename ||
    ![string equal -nocase [file extension $bit_filename] ".bit"]} {
  error "BIT_FILENAME must be a leaf filename ending in .bit"
}
if {![regexp {^[0-9a-f]{40}$} $source_commit]} {
  error "SOURCE_COMMIT must be exactly 40 lowercase hex digits"
}
if {![regexp {^[0-9a-f]{40}$} $source_tree]} {
  error "SOURCE_TREE must be exactly 40 lowercase hex digits"
}

# Exact integration source identity.  A postcommit build must be the single
# clean direct child of accepted G2A.  A precommit build must still have G2A as
# HEAD and is instead bound byte-for-byte by the explicit input manifest.
set actual_commit [git_value rev-parse HEAD]
set actual_tree [git_value rev-parse {HEAD^{tree}}]
set actual_branch [git_value symbolic-ref --short HEAD]
set actual_status [git_value status --porcelain --untracked-files=all]
set actual_g2a_base_tree [git_value rev-parse "${accepted_g2a_base_commit}^{tree}"]
set actual_g2a_parent [git_value rev-parse "${accepted_g2a_base_commit}^"]
set actual_product_tree [git_value rev-parse "${accepted_product_commit}^{tree}"]
set actual_fix_candidate_tree [git_value rev-parse "${accepted_fix_candidate_commit}^{tree}"]
set actual_fix_candidate_parent [git_value rev-parse "${accepted_fix_candidate_commit}^"]
set actual_r1i_tree [git_value rev-parse "${qualified_r1i_commit}^{tree}"]
set actual_tag_commit [git_value rev-list -n 1 $qualified_r1i_tag]
set actual_xdma_xci_blob [git_value hash-object -- ip/v41/xdma_v41_m1.xci]
set actual_xdma_config_tcl_blob \
  [git_value hash-object -- scripts/v41/xdma_config_common.tcl]

if {$actual_commit ne $source_commit} { error "repository HEAD does not match requested SOURCE_COMMIT" }
if {$actual_tree ne $source_tree} { error "repository HEAD tree does not match requested SOURCE_TREE" }
if {$actual_branch ne $expected_branch} { error "source branch mismatch: expected $expected_branch, got $actual_branch" }
if {$actual_g2a_base_tree ne $accepted_g2a_base_tree} { error "BLOCKED - G2A_BASE_TREE_MISMATCH" }
if {$actual_g2a_parent ne $qualified_r1i_commit} { error "BLOCKED - G2A_BASE_PARENT_MISMATCH" }
if {$actual_product_tree ne $accepted_product_tree} { error "BLOCKED - ACCEPTED_PRODUCT_TREE_MISMATCH" }
if {$actual_fix_candidate_tree ne $accepted_fix_candidate_tree} { error "BLOCKED - ACCEPTED_FIX_CANDIDATE_TREE_MISMATCH" }
if {$actual_fix_candidate_parent ne $accepted_product_commit} { error "BLOCKED - FIX_CANDIDATE_PARENT_MISMATCH" }
if {$actual_r1i_tree ne $qualified_r1i_tree} { error "BLOCKED - R1I_BASE_TREE_MISMATCH" }
if {$actual_tag_commit ne $qualified_r1i_commit} {
  error "qualified immutable R1i tag does not resolve to frozen R1i commit"
}
if {$actual_xdma_xci_blob ne $accepted_xdma_xci_blob ||
    $actual_xdma_config_tcl_blob ne $accepted_xdma_config_tcl_blob} {
  error "BLOCKED - UNEXPECTED_XDMA_CONFIG_DRIFT"
}

set sealed_input_hashes [canonical_build_input_hashes]
set precommit_manifest_sha NONE
set precommit_manifest_line_count NOT_APPLICABLE
if {$precommit_mode} {
  if {$actual_commit ne $accepted_g2a_base_commit || $actual_tree ne $accepted_g2a_base_tree} {
    error "PRECOMMIT_FULL_BUILD must run with accepted G2A as exact repository HEAD"
  }
  if {$actual_status eq ""} {
    error "PRECOMMIT_FULL_BUILD requires a manifest-sealed dirty implementation worktree"
  }
  set precommit_manifest_sha \
    [validate_precommit_input_manifest $precommit_manifest $sealed_input_hashes]
  set precommit_manifest_line_count [llength $sealed_input_hashes]
  set actual_merge_base $accepted_g2a_base_commit
  set direct_parent PRECOMMIT_NOT_APPLICABLE
  set integration_commit_count 0
  set direct_base_relation PRECOMMIT_HEAD_IS_ACCEPTED_G2A_BASE
  set source_clean NO
  set source_identity_kind MANIFEST_SEALED_UNCOMMITTED_WORKTREE
  set precommit_manifest_display [file nativename $precommit_manifest]
  set git_words_semantics REPOSITORY_HEAD_NOT_COMPLETE_SOURCE_IDENTITY
  set reported_source_commit NONE
  set base_build_flags 3
  set source_to_bit_provenance PASS_MANIFEST_SEALED_DIRTY_WORKTREE
} else {
  if {$actual_status ne ""} { error "G2B postcommit source tree is not clean: $actual_status" }
  set actual_merge_base [git_value merge-base $accepted_g2a_base_commit $source_commit]
  set direct_parent [git_value rev-parse "${source_commit}^"]
  set integration_commit_count \
    [git_value rev-list --count "${accepted_g2a_base_commit}..${source_commit}"]
  set product_merge_base [git_value merge-base $accepted_product_commit $source_commit]
  set correction_commit_count \
    [git_value rev-list --count "${accepted_product_commit}..${source_commit}"]
  if {$actual_merge_base ne $accepted_g2a_base_commit ||
      $product_merge_base ne $accepted_product_commit ||
      $direct_parent ne $accepted_fix_candidate_commit ||
      $correction_commit_count ne "2"} {
    error "postcommit FIX1 source is not the hardened child of the accepted correction candidate"
  }
  set direct_base_relation PASS_HARDENED_CHILD_OF_ACCEPTED_FIX_CANDIDATE
  set source_clean PASS
  set source_identity_kind CLEAN_EXACT_GIT_COMMIT
  set precommit_manifest_display NOT_APPLICABLE
  set git_words_semantics CLEAN_SOURCE_COMMIT
  set reported_source_commit $source_commit
  set base_build_flags 2
  set source_to_bit_provenance PASS_CLEAN_EXACT_COMMIT
}

# Five-word round trip: narrowly adopted provenance intent from the secondary
# donor.  Keep the reconstructed_commit assignment stable for negative tests.
set git_words [list]
for {set word_index 0} {$word_index < 5} {incr word_index} {
  set first [expr {$word_index * 8}]
  set word [string range $source_commit $first [expr {$first + 7}]]
  if {![regexp {^[0-9a-f]{8}$} $word]} { error "invalid 8-hex provenance word $word_index" }
  lappend git_words $word
}
set reconstructed_commit [join $git_words ""]
if {$reconstructed_commit ne $source_commit} {
  error "provenance round-trip mismatch: $reconstructed_commit != $source_commit"
}

# BUILD_FLAGS[8] identifies PRODUCT and BUILD_FLAGS[9] identifies
# RESEARCH_DIAGNOSTIC.  Bits [1:0] retain the established clean/dirty manifest
# provenance semantics.
set profile_build_flag [expr {$build_profile eq "PRODUCT" ? 0x00000100 : 0x00000200}]
set build_flags [format "32'h%08X" [expr {$base_build_flags | $profile_build_flag}]]

# SLOT_COUNT remains the protected R1i PIO slot parameter.  The private G2B
# transport ring is structurally fixed at four slots inside its own module.
set generics "SLOT_COUNT=2"
for {set word_index 0} {$word_index < 5} {incr word_index} {
  append generics " GIT_SHA_W$word_index=32'h[lindex $git_words $word_index]"
}
append generics " BUILD_FLAGS=$build_flags ENABLE_MAREK_INIT_TABLE=1"
append generics " ENABLE_RTRACK_DIAGNOSTICS=$enable_rtrack_diagnostics"

# The evidence root is the only path created in provenance-only mode.
file mkdir $evidence_root
set provenance_lines [list \
  "TASK=AHD_V41_G2B_ONE_CHANNEL_C2H_OFFLINE_IMPLEMENTATION" \
  "BUILD_PROFILE=$build_profile" \
  "ENABLE_RTRACK_DIAGNOSTICS=$enable_rtrack_diagnostics" \
  "EXECUTION_MODE=$execution_mode" \
  "SOURCE_IDENTITY_KIND=$source_identity_kind" \
  "COMMITTED_IMPLEMENTATION_SOURCE=$reported_source_commit" \
  "SOURCE_COMMIT_REQUESTED=$source_commit" \
  "REPOSITORY_HEAD=$actual_commit" \
  "SOURCE_TREE_REQUESTED=$source_tree" \
  "REPOSITORY_HEAD_TREE=$actual_tree" \
  "SOURCE_BRANCH_EXPECTED=$expected_branch" \
  "SOURCE_BRANCH_ACTUAL=$actual_branch" \
  "ACCEPTED_G2A_BASE_COMMIT=$accepted_g2a_base_commit" \
  "ACCEPTED_G2A_BASE_TREE=$accepted_g2a_base_tree" \
  "ACCEPTED_PRODUCT_COMMIT=$accepted_product_commit" \
  "ACCEPTED_PRODUCT_TREE=$accepted_product_tree" \
  "ACCEPTED_FIX_CANDIDATE_COMMIT=$accepted_fix_candidate_commit" \
  "ACCEPTED_FIX_CANDIDATE_TREE=$accepted_fix_candidate_tree" \
  "QUALIFIED_R1I_COMMIT=$qualified_r1i_commit" \
  "QUALIFIED_R1I_TREE=$qualified_r1i_tree" \
  "QUALIFIED_R1I_TAG=$qualified_r1i_tag" \
  "R1I_TAG_RESOLUTION=PASS" \
  "XDMA_XCI_GIT_BLOB=$actual_xdma_xci_blob" \
  "XDMA_CONFIG_TCL_GIT_BLOB=$actual_xdma_config_tcl_blob" \
  "DIRECT_PARENT=$direct_parent" \
  "MERGE_BASE_WITH_G2A=$actual_merge_base" \
  "DIRECT_BASE_RELATION=$direct_base_relation" \
  "INTEGRATION_COMMIT_COUNT=$integration_commit_count" \
  "SOURCE_HEAD_MATCH=PASS" \
  "SOURCE_TREE_MATCH=PASS" \
  "SOURCE_BRANCH_MATCH=PASS" \
  "SOURCE_CLEAN=$source_clean" \
  "WORKTREE_STATUS=[single_line $actual_status]" \
  "PRECOMMIT_INPUT_MANIFEST=$precommit_manifest_display" \
  "PRECOMMIT_INPUT_MANIFEST_SHA256=$precommit_manifest_sha" \
  "PRECOMMIT_INPUT_MANIFEST_LINES=$precommit_manifest_line_count" \
  "GIT_SHA_W0=[lindex $git_words 0]" \
  "GIT_SHA_W1=[lindex $git_words 1]" \
  "GIT_SHA_W2=[lindex $git_words 2]" \
  "GIT_SHA_W3=[lindex $git_words 3]" \
  "GIT_SHA_W4=[lindex $git_words 4]" \
  "GIT_SHA_WORDS_SEMANTICS=$git_words_semantics" \
  "RECONSTRUCTED_REPOSITORY_HEAD=$reconstructed_commit" \
  "BUILD_FLAGS=$build_flags" \
  "BUILD_FLAGS_DIRTY_BIT=[expr {$precommit_mode ? 1 : 0}]" \
  "BUILD_FLAGS_MANIFEST_VERIFIED_BIT=1" \
  "BUILD_FLAGS_PRODUCT_BIT=[expr {$build_profile eq {PRODUCT} ? 1 : 0}]" \
  "BUILD_FLAGS_RESEARCH_DIAGNOSTIC_BIT=[expr {$build_profile eq {RESEARCH_DIAGNOSTIC} ? 1 : 0}]" \
  "PROVENANCE_ROUND_TRIP=PASS" \
  "VIVADO_GENERIC_STRING=$generics" \
  "PROVENANCE_PREFLIGHT=PASS"]
if {$execution_mode eq "PROVENANCE_ONLY"} {
  lappend provenance_lines "PROVENANCE_ONLY_EXIT_BEFORE_BUILD=PASS"
} else {
  lappend provenance_lines "PROVENANCE_ONLY_EXIT_BEFORE_BUILD=NOT_APPLICABLE"
}
write_lines [file join $evidence_root G2B_EXPECTED_RUNTIME_PROVENANCE.txt] $provenance_lines
if {$precommit_mode} {
  write_lines [file join $evidence_root G2B_PRECOMMIT_INPUT_SHA256.txt] $sealed_input_hashes
}
puts "G2B_PROVENANCE_ROUND_TRIP=PASS REPOSITORY_HEAD=$actual_commit HEAD_TREE=$actual_tree IDENTITY=$source_identity_kind"
if {$execution_mode eq "PROVENANCE_ONLY"} {
  puts "G2B_PROVENANCE_ONLY_PREFLIGHT=PASS"
  exit 0
}

# Nothing below this point is reached by PROVENANCE_ONLY.
set stage FULL_BUILD_PREFLIGHT
set action_counts [dict create \
  SYNTH_DESIGN 0 OPT_DESIGN 0 PLACE_DESIGN 0 PHYS_OPT_DESIGN 0 \
  ROUTE_DESIGN 0 WRITE_BITSTREAM 0 WRITE_DEBUG_PROBES 0]
set project_creation NOT_RUN
set ip_generation NOT_RUN
set synthesis NOT_RUN
set optimization NOT_RUN
set placement NOT_RUN
set physical_optimization NOT_RUN
set routing NOT_RUN
set timing_gate NOT_RUN
set drc_gate NOT_RUN
set cdc_gate NOT_RUN
set bus_skew_gate NOT_RUN
set black_box_gate NOT_RUN
set clock_gate NOT_RUN
set resource_gate NOT_RUN
set resource_gate_reason NOT_RUN
set post_opt_resource_gate NOT_RUN
set post_opt_resource_gate_reason NOT_RUN
set congestion_gate NOT_RUN
set source_post_build NOT_RUN
set fully_routed UNKNOWN
set errors_in_routes UNKNOWN
set unrouted_nets UNKNOWN
set partial_nets UNKNOWN
set wns UNKNOWN
set tns UNKNOWN
set whs UNKNOWN
set ths UNKNOWN
set failing_setup UNKNOWN
set failing_hold UNKNOWN
set no_clock_count UNKNOWN
set unconstrained_internal_count UNKNOWN
set drc_errors UNKNOWN
set drc_critical_warnings UNKNOWN
set drc_warnings UNKNOWN
set cdc_critical UNKNOWN
set cdc_unknown UNKNOWN
set cdc_critical_dispositioned 0
set cdc_disposition NOT_RUN
set g2b_axi_to_source_mailbox_wns UNKNOWN
set g2b_source_to_axi_mailbox_wns UNKNOWN
set bus_skew_violations UNKNOWN
set bus_skew_met_constraints UNKNOWN
set bus_skew_report_sha NONE
set black_box_count UNKNOWN
set post_opt_metrics [dict create]
set final_metrics [dict create]
set effective_axi_clock_mhz UNKNOWN
set effective_user_clock_mhz UNKNOWN
set bit_generated NO
set bit_sha NONE
set ltx_generated NO
set ltx_sha NONE
set ltx_error NONE
set routed_clock_object_count UNKNOWN
set nvp_clock_pin_count UNKNOWN
set axi_bridge_clock_pin_count UNKNOWN
set xdc_collection_gate NOT_RUN
set cfg_src_count UNKNOWN
set cfg_dst_count UNKNOWN
set status_src_count UNKNOWN
set status_dst_count UNKNOWN
set toggle_first_stage_count UNKNOWN
set toggle_first_d_count UNKNOWN
set diag_gray_source_count UNKNOWN
set diag_gray_first_d_count UNKNOWN
set g2b_module_cell_count UNKNOWN
set g2b_mmio_router_cell_count UNKNOWN
set g2b_mmio_router_source_rel rtl/g2b/v41_g2b_mmio_router.sv
set g2b_mmio_router_source_path \
  [file normalize [file join $repo_root $g2b_mmio_router_source_rel]]
set g2b_mmio_router_source_object_count UNKNOWN
set g2b_mmio_router_used_in_synthesis UNKNOWN
set g2b_mmio_router_compile_order_count UNKNOWN
set g2b_mmio_router_compile_order_index UNKNOWN
set g2b_mmio_router_source_sha NONE
set g2b_mmio_router_source_gate NOT_RUN
set g2b_mmio_router_cell_disposition UNKNOWN
set g2b_first_stage_count UNKNOWN
set g2b_second_stage_count UNKNOWN
set g2b_first_stage_d_count UNKNOWN
set g2b_toggle_source_count UNKNOWN
set g2b_gray_hold_source_count UNKNOWN
set g2b_gray_first_d_count UNKNOWN
set g2b_axi_mailbox_source_count UNKNOWN
set g2b_source_mailbox_destination_count UNKNOWN
set g2b_source_mailbox_source_count UNKNOWN
set g2b_source_mailbox_reg_source_count UNKNOWN
set g2b_source_mailbox_ram_source_count UNKNOWN
set g2b_axi_mailbox_destination_count UNKNOWN
set g2b_axi_mailbox_alias_source_count UNKNOWN
set g2b_source_mailbox_added_destination_count UNKNOWN
set g2b_source_mailbox_descriptor_source_count UNKNOWN
set g2b_desc_attempt_ram_source_count UNKNOWN
set g2b_desc_generation_ram_source_count UNKNOWN
set g2b_desc_epoch_reg_source_count UNKNOWN
set g2b_axi_mailbox_added_destination_count UNKNOWN
set g2b_timing_start_count UNKNOWN
set g2b_timing_end_count UNKNOWN
set g2b_cdc_xdc_file_count UNKNOWN
set nvp_init_async_reset_pin_count UNKNOWN
set pcie_refclk_ibuf_count UNKNOWN
set gt_channel_count UNKNOWN
set gt_common_count UNKNOWN
set pcie_hard_block_count UNKNOWN
set vivado_version UNKNOWN
set vivado_sw_build UNKNOWN
set ip_config_property_count UNKNOWN
set xdma_source_sha NONE
set xdma_copy_sha NONE
set bufg_used UNKNOWN
set mmcm_used UNKNOWN
set pll_used UNKNOWN
set synth_dcp_sha NONE
set post_opt_dcp_sha NONE
set routed_dcp_sha NONE

set bit_path [file join $evidence_root artifacts $bit_filename]
set ltx_filename "[file rootname $bit_filename].ltx"
set ltx_path [file join $evidence_root artifacts $ltx_filename]

set build_result [catch {
  if {![info exists ::env(XILINX_LOCAL_USER_DATA)] || $::env(XILINX_LOCAL_USER_DATA) ne "NO"} {
    error "XILINX_LOCAL_USER_DATA must be NO in the Vivado child environment"
  }
  if {![info exists ::env(XILINX_TCLAPP_REPO)]} {
    error "XILINX_TCLAPP_REPO is missing from the Vivado child environment"
  }
  set expected_tclapp_repo [file normalize C:/AMDDesignTools/2025.2/Vivado/data/XilinxTclStore]
  if {![string equal -nocase [path_key $::env(XILINX_TCLAPP_REPO)] [path_key $expected_tclapp_repo]]} {
    error "XILINX_TCLAPP_REPO does not identify the frozen Vivado 2025.2 Tcl store"
  }
  if {![info exists ::env(TEMP)] || ![info exists ::env(TMP)] ||
      ![string equal -nocase [path_key $::env(TEMP)] [path_key $::env(TMP)]]} {
    error "TEMP and TMP must identify the same child-only directory"
  }
  if {![string is ascii -strict $::env(TEMP)] || ![string is ascii -strict $build_root] ||
      ![string is ascii -strict $evidence_root]} {
    error "TEMP, BUILD_ROOT, and EVIDENCE_ROOT must be ASCII-only"
  }

  set vivado_version [string trim [version -short]]
  regexp {SW Build[ \t]+([0-9]+)} [version] -> vivado_sw_build
  if {$vivado_version ne $expected_vivado_version || $vivado_sw_build ne $expected_vivado_sw_build} {
    error "wrong Vivado version/build: version=$vivado_version SW_BUILD=$vivado_sw_build"
  }

  if {[file exists $build_root]} {
    set existing [glob -nocomplain -directory $build_root *]
    foreach candidate [glob -nocomplain -directory $build_root .*] {
      if {[file tail $candidate] ni {. ..}} { lappend existing $candidate }
    }
    if {[llength $existing] != 0} { error "BUILD_ROOT is not empty; clean full build required" }
  }
  set evidence_entries [glob -nocomplain -directory $evidence_root *]
  foreach candidate [glob -nocomplain -directory $evidence_root .*] {
    if {[file tail $candidate] ni {. ..}} { lappend evidence_entries $candidate }
  }
  set expected_receipt [file join $evidence_root G2B_EXPECTED_RUNTIME_PROVENANCE.txt]
  set allowed_preexisting [dict create [path_key $expected_receipt] 1]
  if {$precommit_mode} {
    dict set allowed_preexisting \
      [path_key [file join $evidence_root G2B_PRECOMMIT_INPUT_SHA256.txt]] 1
  }
  foreach candidate $evidence_entries {
    if {![dict exists $allowed_preexisting [path_key $candidate]]} {
      error "EVIDENCE_ROOT is not fresh; unexpected pre-existing entry: $candidate"
    }
  }
  if {[file exists $bit_path] || [file exists $ltx_path] ||
      [file exists [file join $evidence_root G2B_BUILD_RESULT.txt]]} {
    error "G2B build evidence/output is already consumed; use a new clean launch root"
  }
  file mkdir $build_root
  set marker [file join $build_root G2B_BUILD_CONSUMED.marker]
  set marker_fh [open $marker {WRONLY CREAT EXCL}]
  puts $marker_fh "SOURCE_IDENTITY_KIND=$source_identity_kind"
  puts $marker_fh "SOURCE_COMMIT=$reported_source_commit"
  puts $marker_fh "REPOSITORY_HEAD=$source_commit"
  puts $marker_fh "REPOSITORY_HEAD_TREE=$source_tree"
  puts $marker_fh "PRECOMMIT_INPUT_MANIFEST_SHA256=$precommit_manifest_sha"
  puts $marker_fh "UTC=[clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]"
  close $marker_fh
  file mkdir [file dirname $bit_path]

  set sv_files [list]
  set vhdl_files [list]
  set xdc_files [list]
  foreach kind {sv vhdl xdc} {
    foreach rel [set [format %s_rel_files $kind]] {
      set path [file join $repo_root $rel]
      lappend [format %s_files $kind] $path
    }
  }
  set xdma_source [file join $repo_root ip v41 xdma_v41_m1.xci]
  set common_tcl [file join $repo_root scripts v41 xdma_config_common.tcl]
  require_files [concat $sv_files $vhdl_files $xdc_files [list $xdma_source $common_tcl]]
  set xdma_source_sha [sha256_file $xdma_source]
  set current_input_hashes [canonical_build_input_hashes]
  if {$current_input_hashes ne $sealed_input_hashes} {
    error "G2B build inputs changed after provenance seal"
  }
  write_lines [file join $evidence_root G2B_BUILD_INPUT_SHA256.txt] $current_input_hashes

  source $common_tcl
  if {![namespace exists ::v41_xdma] || ![llength [info commands ::v41_xdma::configure_minimal_c2h_stream]]} {
    error "authoritative XDMA configuration namespace/procedure unavailable"
  }
  if {$v41_xdma::part ne $expected_part} { error "XDMA helper part drift" }

  set stage PROJECT_SETUP
  cd $build_root
  set project_dir [file join $build_root vivado_project]
  set project_creation FAIL
  create_project v41_g2b_onech_c2h_offline $project_dir -part $expected_part
  set project_creation PASS
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
  set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]
  config_ip_cache -use_cache_location [file join $build_root ip_cache]

  add_files -norecurse $sv_files
  set_property FILE_TYPE SystemVerilog [get_files $sv_files]
  add_files -norecurse $vhdl_files

  set input_xci_dir [file join $build_root input_xci]
  file mkdir $input_xci_dir
  set xdma_copy [file join $input_xci_dir xdma_v41_m1.xci]
  file copy $xdma_source $xdma_copy
  set xdma_copy_sha [sha256_file $xdma_copy]
  if {$xdma_copy_sha ne $xdma_source_sha} {
    error "local XDMA XCI copy does not match committed input"
  }
  set ip_generation FAIL
  import_ip -files $xdma_copy
  set xdma_ip [get_ips -quiet xdma_v41_m1]
  if {[llength $xdma_ip] != 1} { error "expected exactly one local XDMA IP object" }
  v41_xdma::configure_minimal_c2h_stream $xdma_ip
  v41_xdma::assert_frozen_g1_invariants $xdma_ip
  if {[get_property CONFIG.pl_link_cap_max_link_speed $xdma_ip] ne "5.0_GT/s" ||
      [get_property CONFIG.pl_link_cap_max_link_width $xdma_ip] ne "X1" ||
      [get_property CONFIG.axisten_freq $xdma_ip] ne "62.5"} {
    error "BLOCKED - UNEXPECTED_XDMA_CONFIG_DRIFT"
  }
  set configured_effective_config [effective_config_dict $xdma_ip]
  set ip_config_property_count [dict size $configured_effective_config]
  if {$ip_config_property_count == 0} { error "no effective XDMA CONFIG properties found" }

  set imported_xci [get_property IP_FILE $xdma_ip]
  set imported_xci_object [get_files -quiet $imported_xci]
  if {[llength $imported_xci_object] != 1} { error "imported local XCI file object unavailable" }
  set_property GENERATE_SYNTH_CHECKPOINT false $imported_xci_object
  set synth_checkpoint_property [string tolower [get_property GENERATE_SYNTH_CHECKPOINT $imported_xci_object]]
  if {$synth_checkpoint_property ni {false 0}} {
    error "XDMA synthesis checkpoint must be disabled for integrated clean synthesis"
  }
  generate_target all $xdma_ip
  set generated_effective_config [effective_config_dict $xdma_ip]
  assert_config_dict_equal $configured_effective_config $generated_effective_config \
    "post-generation XDMA"
  v41_xdma::assert_frozen_g1_invariants $xdma_ip
  v41_xdma::dump_effective_config $xdma_ip \
    [file join $evidence_root G2B_XDMA_EFFECTIVE_CONFIG.txt]
  report_property -file [file join $evidence_root G2B_XDMA_IP_PROPERTIES.txt] $xdma_ip
  report_ip_status -file [file join $evidence_root G2B_XDMA_IP_STATUS.rpt]
  set ip_generation PASS

  add_files -fileset constrs_1 -norecurse $xdc_files
  set_property PROCESSING_ORDER EARLY [get_files [lindex $xdc_files 0]]
  set_property PROCESSING_ORDER LATE [get_files [lrange $xdc_files 1 end]]
  set_property top $expected_top [get_filesets sources_1]
  set_property generic $generics [get_filesets sources_1]
  update_compile_order -fileset sources_1
  if {[get_property PART [current_project]] ne $expected_part ||
      [get_property TOP [get_filesets sources_1]] ne $expected_top ||
      [get_property GENERIC [get_filesets sources_1]] ne $generics} {
    error "project part/top/runtime provenance mismatch"
  }

  # The combinational MMIO router can be legally absorbed by rebuilt
  # hierarchy. Prove that its exact sealed source is an active synthesis input
  # instead of requiring a non-semantic post-route instance label. Functional
  # behavior is independently gated by the exhaustive router regression.
  set g2b_mmio_router_source_sha \
    [sha256_file $g2b_mmio_router_source_path]
  set g2b_mmio_router_source_objects \
    [get_files -quiet $g2b_mmio_router_source_path]
  set g2b_mmio_router_source_object_count \
    [llength $g2b_mmio_router_source_objects]
  set g2b_mmio_router_source_object_name NONE
  set g2b_mmio_router_used_in_synthesis UNKNOWN
  set g2b_mmio_router_used_in_synthesis_ok 0
  if {$g2b_mmio_router_source_object_count == 1} {
    set g2b_mmio_router_source_object \
      [lindex $g2b_mmio_router_source_objects 0]
    set g2b_mmio_router_source_object_name \
      [get_property NAME $g2b_mmio_router_source_object]
    set g2b_mmio_router_used_in_synthesis \
      [get_property USED_IN_SYNTHESIS $g2b_mmio_router_source_object]
    set g2b_mmio_router_used_in_synthesis_ok [expr {
      [string tolower $g2b_mmio_router_used_in_synthesis] in
        {1 true yes on}
    }]
  }
  set synthesis_compile_order [get_files -compile_order sources \
    -used_in synthesis -of_objects [get_filesets sources_1]]
  set g2b_mmio_router_compile_order_count 0
  set g2b_mmio_router_compile_order_index NONE
  set compile_order_index 0
  foreach compile_object $synthesis_compile_order {
    incr compile_order_index
    if {[path_key [get_property NAME $compile_object]] eq
        [path_key $g2b_mmio_router_source_path]} {
      incr g2b_mmio_router_compile_order_count
      set g2b_mmio_router_compile_order_index $compile_order_index
    }
  }
  set g2b_mmio_router_source_gate FAIL
  if {$g2b_mmio_router_source_object_count == 1 &&
      $g2b_mmio_router_used_in_synthesis_ok &&
      $g2b_mmio_router_compile_order_count == 1} {
    set g2b_mmio_router_source_gate PASS
  }
  write_lines \
    [file join $evidence_root G2B_MMIO_ROUTER_SOURCE_INCLUSION.txt] [list \
      "SOURCE_RELATIVE_PATH=$g2b_mmio_router_source_rel" \
      "SOURCE_EXPECTED_PATH=$g2b_mmio_router_source_path" \
      "SOURCE_OBJECT_NAME=$g2b_mmio_router_source_object_name" \
      "SOURCE_OBJECT_COUNT=$g2b_mmio_router_source_object_count" \
      "USED_IN_SYNTHESIS=$g2b_mmio_router_used_in_synthesis" \
      "SYNTHESIS_COMPILE_ORDER_MATCHES=$g2b_mmio_router_compile_order_count" \
      "SYNTHESIS_COMPILE_ORDER_INDEX=$g2b_mmio_router_compile_order_index" \
      "SOURCE_SHA256=$g2b_mmio_router_source_sha" \
      {SOURCE_SEALED_BY_BUILD_INPUT_MANIFEST=YES} \
      {FUNCTIONAL_PROOF=EXTERNAL_EXHAUSTIVE_ROUTER_REGRESSION} \
      "GATE=$g2b_mmio_router_source_gate"]
  if {$g2b_mmio_router_source_gate ne "PASS"} {
    error "G2B MMIO router exact-source synthesis inclusion gate failed"
  }
  report_compile_order -fileset sources_1 -used_in synthesis \
    -file [file join $evidence_root G2B_COMPILE_ORDER.rpt]

  write_lines [file join $evidence_root G2B_BUILD_PROVENANCE.txt] [list \
    "BUILD_PROFILE=$build_profile" \
    "ENABLE_RTRACK_DIAGNOSTICS=$enable_rtrack_diagnostics" \
    "SOURCE_IDENTITY_KIND=$source_identity_kind" \
    "REPOSITORY_HEAD=$source_commit" "REPOSITORY_HEAD_TREE=$source_tree" \
    "SOURCE_BRANCH=$expected_branch" "SOURCE_CLEAN=$source_clean" \
    "ACCEPTED_G2A_BASE_COMMIT=$accepted_g2a_base_commit" \
    "ACCEPTED_G2A_BASE_TREE=$accepted_g2a_base_tree" \
    "DIRECT_PARENT=$direct_parent" \
    "MERGE_BASE_WITH_G2A=$actual_merge_base" \
    "DIRECT_BASE_RELATION=$direct_base_relation" \
    "PRECOMMIT_INPUT_MANIFEST_SHA256=$precommit_manifest_sha" \
    "XDMA_XCI_GIT_BLOB=$actual_xdma_xci_blob" \
    "XDMA_CONFIG_TCL_GIT_BLOB=$actual_xdma_config_tcl_blob" \
    "XDMA_SOURCE_SHA256=$xdma_source_sha" \
    "XDMA_LOCAL_COPY_SHA256=$xdma_copy_sha" \
    "PART=$expected_part" "TOP=$expected_top" "GENERIC=$generics" \
    "BUILD_FLAGS=$build_flags" \
    "VIVADO_VERSION=$vivado_version" "VIVADO_SW_BUILD=$vivado_sw_build" \
    "VIVADO_PROCESS_ID=[pid]" "HARNESS_VIVADO_PROCESS_COUNT=1" \
    "FLOW=ACCEPTED_G2A_CLEAN_SYNTH_OPT_PLACE_PHYS_OPT_ROUTE" \
    "CHECKPOINT_REUSE=NO" "IP_CACHE=LOCAL_CLEAN" \
    "GENERATE_SYNTH_CHECKPOINT=false" \
    "XDMA_EFFECTIVE_CONFIG_PROPERTIES=$ip_config_property_count" \
    "G2B_MMIO_ROUTER_SOURCE_OBJECTS=$g2b_mmio_router_source_object_count" \
    "G2B_MMIO_ROUTER_USED_IN_SYNTHESIS=$g2b_mmio_router_used_in_synthesis" \
    "G2B_MMIO_ROUTER_COMPILE_ORDER_MATCHES=$g2b_mmio_router_compile_order_count" \
    "G2B_MMIO_ROUTER_COMPILE_ORDER_INDEX=$g2b_mmio_router_compile_order_index" \
    "G2B_MMIO_ROUTER_SOURCE_SHA256=$g2b_mmio_router_source_sha" \
    "G2B_MMIO_ROUTER_SOURCE_GATE=$g2b_mmio_router_source_gate" \
    "SOURCE_TO_BIT_PROVENANCE=PENDING"]

  set stage SYNTHESIS
  record_action SYNTH_DESIGN
  set synthesis FAIL
  synth_design -top $expected_top -part $expected_part -flatten_hierarchy rebuilt
  if {[llength [get_cells -quiet -hier]] == 0} { error "empty synthesized design" }
  # Rebuilt hierarchy uses both slash-separated module scopes and dot-separated
  # generate scopes, and can retain a stable REF_NAME even when the source
  # instance label is rewritten.  Count the union of both identities so the
  # profile receipt proves elaborated content rather than a naming convention.
  proc profile_cells {instance_name ref_name} {
    set matches [dict create]
    foreach cell [get_cells -quiet -hier] {
      set cell_name [get_property NAME $cell]
      set cell_ref [get_property -quiet REF_NAME $cell]
      if {[regexp [format {(^|[/.])%s$} $instance_name] $cell_name] ||
          [string match "${ref_name}*" $cell_ref]} {
        dict set matches $cell_name $cell
      }
    }
    return [dict values $matches]
  }
  set profile_probe_cells [profile_cells POST_INIT_TRI_PHASE_PROBE \
    nvp_i2c_tri_phase_probe]
  set profile_lifecycle_cells [profile_cells LIFECYCLE_MONITOR \
    v41_axi_clock_lifecycle_monitor]
  set profile_failed_history_cells [profile_cells R1F_FAILED_TXN_LOGGER \
    v41_r1f_failed_txn_logger]
  set profile_r1h_cells [profile_cells R1H_MMIO_READ_SERVICE \
    v41_r1h_mmio_read_service]
  set profile_product_service_cells [profile_cells PRODUCT_R1I_READ_SERVICE \
    v41_g2b_product_profile_read_service]
  set profile_probe_count [llength $profile_probe_cells]
  set profile_lifecycle_count [llength $profile_lifecycle_cells]
  set profile_failed_history_count [llength $profile_failed_history_cells]
  set profile_r1h_count [llength $profile_r1h_cells]
  set profile_product_service_count [llength $profile_product_service_cells]
  set profile_gate PASS
  if {$build_profile eq "PRODUCT"} {
    if {$profile_probe_count != 0 || $profile_lifecycle_count != 0 ||
        $profile_failed_history_count != 0 || $profile_r1h_count != 0 ||
        $profile_product_service_count == 0} {
      set profile_gate FAIL
    }
  } else {
    if {$profile_probe_count == 0 || $profile_lifecycle_count == 0 ||
        $profile_failed_history_count == 0 || $profile_r1h_count == 0 ||
        $profile_product_service_count != 0} {
      set profile_gate FAIL
    }
  }
  write_lines [file join $evidence_root G2B_PROFILE_ELABORATION_RECEIPT.txt] [list \
    "BUILD_PROFILE=$build_profile" \
    "ENABLE_RTRACK_DIAGNOSTICS=$enable_rtrack_diagnostics" \
    "POST_INIT_TRI_PHASE_PROBE_COUNT=$profile_probe_count" \
    "LIFECYCLE_MONITOR_COUNT=$profile_lifecycle_count" \
    "FAILED_TXN_LOGGER_COUNT=$profile_failed_history_count" \
    "R1H_RESEARCH_READ_SERVICE_COUNT=$profile_r1h_count" \
    "PRODUCT_R1I_READ_SERVICE_COUNT=$profile_product_service_count" \
    "PROFILE_ELABORATION_GATE=$profile_gate"]
  if {$profile_gate ne "PASS"} {
    error "build-profile elaboration content mismatch"
  }
  set synthesis PASS
  set synth_dcp_path [file join $evidence_root G2B_SYNTH.dcp]
  write_checkpoint -force $synth_dcp_path
  set synth_dcp_sha [sha256_file $synth_dcp_path]
  report_utilization -file [file join $evidence_root POST_SYNTH_UTILIZATION_FLAT.rpt]
  report_utilization -hierarchical -hierarchical_depth 20 \
    -file [file join $evidence_root POST_SYNTH_UTILIZATION_HIER.rpt]
  report_timing_summary -delay_type min_max -max_paths 100 \
    -file [file join $evidence_root POST_SYNTH_TIMING_SUMMARY.rpt]

  set stage OPT_DESIGN
  record_action OPT_DESIGN
  set optimization FAIL
  opt_design
  set optimization PASS
  set post_opt_metrics [resource_metrics POST_OPT]
  set post_opt_dcp_path [file join $evidence_root G2B_POST_OPT.dcp]
  write_checkpoint -force $post_opt_dcp_path
  set post_opt_dcp_sha [sha256_file $post_opt_dcp_path]
  report_utilization -hierarchical -hierarchical_depth 20 \
    -file [file join $evidence_root POST_OPT_UTILIZATION_HIER.rpt]
  lassign [evaluate_resource_gate POST_OPT $post_opt_metrics] \
    post_opt_resource_gate post_opt_resource_gate_reason
  if {$post_opt_resource_gate ne "PASS"} {
    set stage RESOURCE_HEADROOM_GATE_POST_OPT
    error "BLOCKED - RESOURCE_HEADROOM_REQUIRES_ARCHITECT_REVIEW: $post_opt_resource_gate_reason"
  }

  set stage PLACE_DESIGN
  record_action PLACE_DESIGN
  set placement FAIL
  place_design
  set placement PASS

  set stage PHYS_OPT_DESIGN
  record_action PHYS_OPT_DESIGN
  set physical_optimization FAIL
  phys_opt_design
  set physical_optimization PASS

  set stage ROUTE_DESIGN
  record_action ROUTE_DESIGN
  set routing FAIL
  route_design -directive AggressiveExplore
  set routed_dcp_path [file join $evidence_root G2B_ROUTED.dcp]
  write_checkpoint -force $routed_dcp_path
  set routed_dcp_sha [sha256_file $routed_dcp_path]

  set stage ROUTED_REPORTS
  report_route_status -file [file join $evidence_root ROUTE_STATUS.rpt]
  set fully_routed [report_route_status -boolean_check ROUTED_FULLY]
  set errors_in_routes [report_route_status -boolean_check ERRORS_IN_ROUTES]
  set unrouted_nets [llength [report_route_status -return_nets -route_type UNROUTED]]
  set partial_nets [llength [report_route_status -return_nets -route_type PARTIAL]]

  set timing_summary_path [file join $evidence_root TIMING_SUMMARY.rpt]
  report_timing_summary -delay_type min_max -max_paths 1000 \
    -report_unconstrained -check_timing_verbose -file $timing_summary_path
  report_timing -delay_type max -max_paths 1000 -nworst 10 \
    -file [file join $evidence_root ROUTED_SETUP_TIMING.rpt]
  report_timing -delay_type min -max_paths 1000 -nworst 10 \
    -file [file join $evidence_root ROUTED_HOLD_TIMING.rpt]
  set check_timing_path [file join $evidence_root CHECK_TIMING.rpt]
  check_timing -verbose -file $check_timing_path
  report_drc -file [file join $evidence_root DRC.rpt]
  set cdc_path [file join $evidence_root CDC.rpt]
  report_cdc -details -file $cdc_path
  set bus_skew_path [file join $evidence_root BUS_SKEW.rpt]
  lassign [run_exact_routed_bus_skew_gate \
    $evidence_root $routed_dcp_path $routed_dcp_sha] \
    bus_skew_violations bus_skew_met_constraints bus_skew_report_sha
  report_exceptions -coverage -file [file join $evidence_root EXCEPTION_COVERAGE.rpt]
  report_clocks -file [file join $evidence_root CLOCKS.rpt]
  report_clock_utilization -file [file join $evidence_root CLOCK_UTILIZATION.rpt]
  report_clock_interaction -file [file join $evidence_root CLOCK_INTERACTION.rpt]
  report_ram_utilization -file [file join $evidence_root RAM_UTILIZATION.rpt]
  set congestion_path [file join $evidence_root CONGESTION.rpt]
  report_design_analysis -congestion -min_congestion_level 5 -file $congestion_path
  report_methodology -file [file join $evidence_root METHODOLOGY.rpt]
  report_property -file [file join $evidence_root ROUTED_DESIGN_PROPERTIES.txt] [current_design]
  set final_metrics [resource_metrics ROUTED]
  report_utilization -hierarchical -hierarchical_depth 20 \
    -file [file join $evidence_root ROUTED_UTILIZATION_HIER.rpt]

  # Re-resolve every active project-owned CDC/XDC collection in the routed
  # netlist.  Textual constraint identity is insufficient: empty queries are
  # an implementation-gate failure even if a generic report is otherwise
  # clean.  Source/destination widths must also remain paired.
  set cfg_src [get_cells -quiet -hier -regexp {.*MAILBOX/cfg_hold_pcie_reg\[[0-9]+\]}]
  set cfg_dst [get_cells -quiet -hier -regexp {.*MAILBOX/nvp_cfg_(abort|arm|capture_generation|clear_errors|line_count_requested|single_line|target_line|window_16_lines)_reg(\[[0-9]+\])?}]
  set status_src [get_cells -quiet -hier -regexp {.*MAILBOX/status_hold_nvp_reg\[[0-9]+\]}]
  set status_dst [get_cells -quiet -hier -regexp {.*MAILBOX/status_bus_pcie_reg\[[0-9]+\]}]
  set toggle_first_stages [get_cells -quiet -hier -regexp {.*(MAILBOX/(cfg_req_sync1_nvp|cfg_ack_sync1_pcie|status_req_sync1_pcie|status_ack_sync1_nvp)_reg|BAR_TARGET/(release_sync1_reg|commit_sync1_reg)(\[[0-9]+\])?)}]
  set toggle_first_d [get_pins -quiet -of_objects $toggle_first_stages -filter {REF_PIN_NAME == D}]
  set diag_gray_sources [get_cells -quiet -hier -regexp {.*(active_sav_gray_nvp_reg|slot_commit_gray_nvp_reg|vclk_edge_gray_nvp_reg)\[[0-9]+\]}]
  set diag_gray_first_stages [get_cells -quiet -hier -regexp {.*(active_sav_gray_sync1_pcie_reg|slot_commit_gray_sync1_pcie_reg|vclk_edge_gray_sync1_user_reg)\[[0-9]+\]}]
  set diag_gray_first_d [get_pins -quiet -of_objects $diag_gray_first_stages -filter {REF_PIN_NAME == D}]
  set g2b_module_cells [get_cells -quiet -hier G2B_ONECH_C2H]
  set g2b_mmio_router_cells [get_cells -quiet -hier G2B_MMIO_ROUTER]
  set g2b_first_stages [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/.*_sync1_.*_reg(\[[0-9]+\])?}]
  set g2b_second_stages [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/.*_sync2_.*_reg(\[[0-9]+\])?}]
  set g2b_first_stage_d [get_pins -quiet -of_objects $g2b_first_stages -filter {REF_PIN_NAME == D}]
  set g2b_toggle_sources [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/.*toggle_(axi|source)_reg(\[[0-9]+\])?}]
  set g2b_gray_hold_sources [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_.*_gray_hold_source_reg\[[0-9]+\]}]
  set g2b_gray_first_stages [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/snapshot_.*_sync1_axi_reg\[[0-9]+\]}]
  set g2b_gray_first_d [get_pins -quiet -of_objects $g2b_gray_first_stages -filter {REF_PIN_NAME == D}]
  set g2b_axi_mailbox_source_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(enable_value_hold_axi|transport_epoch_hold_axi|transport_hard_hold_axi|transport_release_phase_hold_axi|transport_own_phase_hold_axi|snapshot_epoch_hold_axi|own_generation_hold_axi|own_epoch_hold_axi|own_slot_hold_axi|axis_slot|axis_generation|axis_epoch|release_generation_axi|release_epoch_axi)_reg.*}]
  set g2b_axi_mailbox_sources [filter $g2b_axi_mailbox_source_candidates {IS_SEQUENTIAL == 1}]
  set g2b_axi_mailbox_alias_source_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/axis_(slot|generation|epoch)_reg.*}]
  set g2b_axi_mailbox_alias_sources [filter $g2b_axi_mailbox_alias_source_candidates {IS_SEQUENTIAL == 1}]
  set g2b_source_mailbox_destination_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(enable_applied_source|reset_epoch_source|records_attempted_source|records_committed_source|records_dropped_source|overflow_count_source|source_lifetime_dropped|channel_attempt_next_source|allocation_round_robin|pending_discontinuity|pending_overflow|pending_malformed|source_formatter_fatal|source_ownership_fatal|source_formatter_clear_pending|source_ownership_clear_pending|source_overflow_event|source_drop_event|source_formatter_fatal_event|source_ownership_fatal_event|source_overflow_deferred|source_drop_deferred|source_formatter_fatal_deferred|source_ownership_fatal_deferred|hard_event_baseline_hold_source|hard_event_clear_toggle_source|snapshot_epoch_echo_source|slot_state_source|slot_generation_source|release_seen_source|own_req_seen_source|own_ack_toggle_source|transport_retire_pending_source|transport_ack_toggle_source|reset_abandoned_hold_source|reset_filling_hold_source|reset_commit_phase_hold_source|own_ok_hold_source)_reg.*}]
  set g2b_source_mailbox_destinations [filter $g2b_source_mailbox_destination_candidates {IS_SEQUENTIAL == 1}]
  set g2b_source_mailbox_added_destination_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(hard_event_baseline_hold_source|hard_event_clear_toggle_source)_reg.*}]
  set g2b_source_mailbox_added_destinations [filter $g2b_source_mailbox_added_destination_candidates {IS_SEQUENTIAL == 1}]
  set g2b_source_mailbox_source_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(desc_attempt_source|desc_generation_source|desc_epoch_source|reset_abandoned_hold_source|reset_commit_phase_hold_source|own_ok_hold_source)_reg.*}]
  set g2b_source_mailbox_reg_sources [filter $g2b_source_mailbox_source_candidates {IS_SEQUENTIAL == 1 && REF_NAME !~ RAM*}]
  set g2b_source_mailbox_ram_sources [filter $g2b_source_mailbox_source_candidates {IS_SEQUENTIAL == 1 && REF_NAME =~ RAM*}]
  set g2b_source_mailbox_sources [concat $g2b_source_mailbox_reg_sources $g2b_source_mailbox_ram_sources]
  set g2b_source_mailbox_descriptor_source_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/desc_(attempt|generation|epoch)_source_reg.*}]
  set g2b_source_mailbox_descriptor_sources [filter $g2b_source_mailbox_descriptor_source_candidates {IS_SEQUENTIAL == 1}]
  set g2b_desc_attempt_ram_sources [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/desc_attempt_source_reg.*}] {IS_SEQUENTIAL == 1 && REF_NAME =~ RAM*}]
  set g2b_desc_generation_ram_sources [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/desc_generation_source_reg.*}] {IS_SEQUENTIAL == 1 && REF_NAME =~ RAM*}]
  set g2b_desc_epoch_reg_sources [filter [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/desc_epoch_source_reg.*}] {IS_SEQUENTIAL == 1 && REF_NAME !~ RAM*}]
  set g2b_axi_mailbox_destination_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(axis_attempt|axis_generation|axis_epoch|axis_beat_index|axis_global|fatal_generation_axi|own_generation_hold_axi|own_epoch_hold_axi|own_slot_hold_axi|records_abandoned_axi|commit_seen_axi|commit_fifo_head|commit_fifo_tail|commit_fifo_count|axis_state|stream_reset_busy_axi|stream_reset_is_hard_axi|transport_release_phase_hold_axi|transport_hard_hold_axi|transport_own_phase_hold_axi|transport_req_toggle_axi|transport_followup_hard_axi|reset_epoch_axi|global_stream_next_axi|last_global_axi|last_channel_axi|last_global_valid_axi|last_channel_valid_axi|reset_events_axi|snapshot_busy_axi|snapshot_valid_axi|shadow_last_global|shadow_last_channel|shadow_last_global_valid|shadow_last_channel_valid|axi_hard_episode|error_status_axi|last_error_cause_axi|stored_enable_axi|fatal_clear_qualified_axi)_reg.*}]
  set g2b_axi_mailbox_destinations [filter $g2b_axi_mailbox_destination_candidates {IS_SEQUENTIAL == 1}]
  set g2b_axi_mailbox_added_destination_candidates [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/(axis_beat_index|axis_global|fatal_generation_axi|transport_release_phase_hold_axi|transport_hard_hold_axi|transport_own_phase_hold_axi|transport_req_toggle_axi)_reg.*}]
  set g2b_axi_mailbox_added_destinations [filter $g2b_axi_mailbox_added_destination_candidates {IS_SEQUENTIAL == 1}]
  set g2b_register_cells [get_cells -quiet -hier -regexp {.*G2B_ONECH_C2H/.*_reg(\[[0-9]+\])?}]
  set g2b_timing_starts [get_pins -quiet -of_objects $g2b_register_cells -filter {REF_PIN_NAME =~ Q*}]
  set g2b_timing_ends [get_pins -quiet -of_objects $g2b_register_cells -filter {REF_PIN_NAME == D}]
  set g2b_cdc_xdc_files \
    [get_files -quiet [file join $repo_root xdc common g2b_cdc.xdc]]
  set nvp_init_async_reset_pins [get_pins -quiet -hier -regexp {.*(NVP_PHYSICAL_FRONTEND/ingress_reset_sync_reg\[[0-9]+\]/PRE|nvp_ready_sync_reg\[[0-9]+\]/CLR)}]
  set pcie_refclk_ibufs [get_cells -quiet -hier PCIE_REFCLK_IBUF]
  set gt_channels [get_cells -quiet -hier -filter {REF_NAME == GTPE2_CHANNEL}]
  set gt_commons [get_cells -quiet -hier -filter {REF_NAME == GTPE2_COMMON}]
  set pcie_hard_blocks [get_cells -quiet -hier -filter {REF_NAME == PCIE_2_1}]

  set cfg_src_count [llength $cfg_src]
  set cfg_dst_count [llength $cfg_dst]
  set status_src_count [llength $status_src]
  set status_dst_count [llength $status_dst]
  set toggle_first_stage_count [llength $toggle_first_stages]
  set toggle_first_d_count [llength $toggle_first_d]
  set diag_gray_source_count [llength $diag_gray_sources]
  set diag_gray_first_d_count [llength $diag_gray_first_d]
  set g2b_module_cell_count [llength $g2b_module_cells]
  set g2b_mmio_router_cell_count [llength $g2b_mmio_router_cells]
  set g2b_mmio_router_cell_disposition \
    INFORMATIONAL_ONLY_LEGAL_HIERARCHY_FLATTENING
  set g2b_first_stage_count [llength $g2b_first_stages]
  set g2b_second_stage_count [llength $g2b_second_stages]
  set g2b_first_stage_d_count [llength $g2b_first_stage_d]
  set g2b_toggle_source_count [llength $g2b_toggle_sources]
  set g2b_gray_hold_source_count [llength $g2b_gray_hold_sources]
  set g2b_gray_first_d_count [llength $g2b_gray_first_d]
  set g2b_axi_mailbox_source_count [llength $g2b_axi_mailbox_sources]
  set g2b_source_mailbox_destination_count [llength $g2b_source_mailbox_destinations]
  set g2b_source_mailbox_source_count [llength $g2b_source_mailbox_sources]
  set g2b_source_mailbox_reg_source_count [llength $g2b_source_mailbox_reg_sources]
  set g2b_source_mailbox_ram_source_count [llength $g2b_source_mailbox_ram_sources]
  set g2b_axi_mailbox_destination_count [llength $g2b_axi_mailbox_destinations]
  set g2b_axi_mailbox_alias_source_count [llength $g2b_axi_mailbox_alias_sources]
  set g2b_source_mailbox_added_destination_count [llength $g2b_source_mailbox_added_destinations]
  set g2b_source_mailbox_descriptor_source_count [llength $g2b_source_mailbox_descriptor_sources]
  set g2b_desc_attempt_ram_source_count [llength $g2b_desc_attempt_ram_sources]
  set g2b_desc_generation_ram_source_count [llength $g2b_desc_generation_ram_sources]
  set g2b_desc_epoch_reg_source_count [llength $g2b_desc_epoch_reg_sources]
  set g2b_axi_mailbox_added_destination_count [llength $g2b_axi_mailbox_added_destinations]
  set g2b_timing_start_count [llength $g2b_timing_starts]
  set g2b_timing_end_count [llength $g2b_timing_ends]
  set g2b_cdc_xdc_file_count [llength $g2b_cdc_xdc_files]
  set nvp_init_async_reset_pin_count [llength $nvp_init_async_reset_pins]
  set pcie_refclk_ibuf_count [llength $pcie_refclk_ibufs]
  set gt_channel_count [llength $gt_channels]
  set gt_common_count [llength $gt_commons]
  set pcie_hard_block_count [llength $pcie_hard_blocks]
  write_lines [file join $evidence_root G2B_ROUTED_XDC_CDC_OBJECT_COVERAGE.txt] [list \
    "CFG_SRC=$cfg_src_count" "CFG_DST=$cfg_dst_count" \
    "STATUS_SRC=$status_src_count" "STATUS_DST=$status_dst_count" \
    "TOGGLE_FIRST_STAGES=$toggle_first_stage_count" \
    "TOGGLE_FIRST_D=$toggle_first_d_count" \
    "DIAG_GRAY_SOURCES=$diag_gray_source_count" \
    "DIAG_GRAY_FIRST_D=$diag_gray_first_d_count" \
    "G2B_MODULE_CELLS=$g2b_module_cell_count" \
    "G2B_MMIO_ROUTER_CELLS=$g2b_mmio_router_cell_count" \
    "G2B_MMIO_ROUTER_SOURCE_OBJECTS=$g2b_mmio_router_source_object_count" \
    "G2B_MMIO_ROUTER_USED_IN_SYNTHESIS=$g2b_mmio_router_used_in_synthesis" \
    "G2B_MMIO_ROUTER_COMPILE_ORDER_MATCHES=$g2b_mmio_router_compile_order_count" \
    "G2B_MMIO_ROUTER_COMPILE_ORDER_INDEX=$g2b_mmio_router_compile_order_index" \
    "G2B_MMIO_ROUTER_SOURCE_SHA256=$g2b_mmio_router_source_sha" \
    "G2B_MMIO_ROUTER_SOURCE_GATE=$g2b_mmio_router_source_gate" \
    "G2B_MMIO_ROUTER_CELL_DISPOSITION=$g2b_mmio_router_cell_disposition" \
    "G2B_FIRST_STAGES=$g2b_first_stage_count" \
    "G2B_SECOND_STAGES=$g2b_second_stage_count" \
    "G2B_FIRST_STAGE_D=$g2b_first_stage_d_count" \
    "G2B_TOGGLE_SOURCES=$g2b_toggle_source_count" \
    "G2B_GRAY_HOLD_SOURCES=$g2b_gray_hold_source_count" \
    "G2B_GRAY_FIRST_D=$g2b_gray_first_d_count" \
    "G2B_AXI_MAILBOX_SOURCES=$g2b_axi_mailbox_source_count" \
    "G2B_SOURCE_MAILBOX_DESTINATIONS=$g2b_source_mailbox_destination_count" \
    "G2B_SOURCE_MAILBOX_SOURCES=$g2b_source_mailbox_source_count" \
    "G2B_SOURCE_MAILBOX_REG_SOURCES=$g2b_source_mailbox_reg_source_count" \
    "G2B_SOURCE_MAILBOX_RAM_SOURCES=$g2b_source_mailbox_ram_source_count" \
    "G2B_AXI_MAILBOX_DESTINATIONS=$g2b_axi_mailbox_destination_count" \
    "G2B_AXI_MAILBOX_ALIAS_SOURCES=$g2b_axi_mailbox_alias_source_count" \
    "G2B_SOURCE_MAILBOX_ADDED_DESTINATIONS=$g2b_source_mailbox_added_destination_count" \
    "G2B_SOURCE_MAILBOX_DESCRIPTOR_SOURCES=$g2b_source_mailbox_descriptor_source_count" \
    "G2B_DESC_ATTEMPT_RAM_SOURCES=$g2b_desc_attempt_ram_source_count" \
    "G2B_DESC_GENERATION_RAM_SOURCES=$g2b_desc_generation_ram_source_count" \
    "G2B_DESC_EPOCH_REG_SOURCES=$g2b_desc_epoch_reg_source_count" \
    "G2B_AXI_MAILBOX_ADDED_DESTINATIONS=$g2b_axi_mailbox_added_destination_count" \
    "G2B_TIMING_STARTS=$g2b_timing_start_count" \
    "G2B_TIMING_ENDS=$g2b_timing_end_count" \
    "G2B_CDC_XDC_FILES=$g2b_cdc_xdc_file_count" \
    "NVP_INIT_ASYNC_RESET_PINS=$nvp_init_async_reset_pin_count" \
    "PCIE_REFCLK_IBUF=$pcie_refclk_ibuf_count" \
    "GTPE2_CHANNEL=$gt_channel_count" "GTPE2_COMMON=$gt_common_count" \
    "PCIE_2_1=$pcie_hard_block_count"]

  if {$cfg_src_count == 0 || $cfg_src_count != $cfg_dst_count ||
      $status_src_count == 0 || $status_src_count != $status_dst_count ||
      $toggle_first_stage_count == 0 || $toggle_first_stage_count != $toggle_first_d_count ||
      $diag_gray_source_count == 0 || $diag_gray_source_count != $diag_gray_first_d_count ||
      $g2b_module_cell_count == 0 || $g2b_mmio_router_source_gate ne "PASS" ||
      $g2b_first_stage_count == 0 || $g2b_second_stage_count == 0 ||
      $g2b_first_stage_d_count == 0 || $g2b_toggle_source_count == 0 ||
      $g2b_gray_hold_source_count == 0 || $g2b_gray_first_d_count == 0 ||
      $g2b_axi_mailbox_source_count == 0 || $g2b_source_mailbox_destination_count == 0 ||
      $g2b_source_mailbox_source_count == 0 || $g2b_axi_mailbox_destination_count == 0 ||
      $g2b_source_mailbox_reg_source_count == 0 ||
      $g2b_source_mailbox_ram_source_count == 0 ||
      $g2b_axi_mailbox_alias_source_count == 0 ||
      $g2b_source_mailbox_added_destination_count == 0 ||
      $g2b_source_mailbox_descriptor_source_count == 0 ||
      $g2b_desc_attempt_ram_source_count == 0 ||
      $g2b_desc_generation_ram_source_count == 0 ||
      $g2b_desc_epoch_reg_source_count == 0 ||
      $g2b_axi_mailbox_added_destination_count == 0 ||
      $g2b_timing_start_count == 0 || $g2b_timing_end_count == 0 ||
      $g2b_cdc_xdc_file_count == 0 ||
      $nvp_init_async_reset_pin_count == 0 || $pcie_refclk_ibuf_count != 1 ||
      $gt_channel_count != 1 || $gt_common_count != 1 || $pcie_hard_block_count != 1} {
    set xdc_collection_gate FAIL
    error "routed XDC/CDC collection gate failed; see G2B_ROUTED_XDC_CDC_OBJECT_COVERAGE.txt"
  }
  set xdc_collection_gate PASS

  report_timing -delay_type max -from $cfg_src -to $cfg_dst -max_paths 100 \
    -file [file join $evidence_root MAX_DELAY_CFG.rpt]
  report_timing -delay_type max -from $status_src -to $status_dst -max_paths 100 \
    -file [file join $evidence_root MAX_DELAY_STATUS.rpt]
  report_timing -delay_type max -from $diag_gray_sources -to $diag_gray_first_d -max_paths 100 \
    -file [file join $evidence_root MAX_DELAY_DIAG_GRAY.rpt]
  report_timing -delay_type max -from $g2b_gray_hold_sources -to $g2b_gray_first_d -max_paths 100 \
    -file [file join $evidence_root MAX_DELAY_G2B_SNAPSHOT_GRAY.rpt]
  report_timing -delay_type max -from $g2b_axi_mailbox_sources \
    -to $g2b_source_mailbox_destinations -max_paths 250 \
    -file [file join $evidence_root MAX_DELAY_G2B_AXI_TO_SOURCE_MAILBOX.rpt]
  report_timing -delay_type max -from $g2b_source_mailbox_sources \
    -to $g2b_axi_mailbox_destinations -max_paths 250 \
    -file [file join $evidence_root MAX_DELAY_G2B_SOURCE_TO_AXI_MAILBOX.rpt]
  set g2b_axi_to_source_mailbox_paths [get_timing_paths -quiet -delay_type max \
    -from $g2b_axi_mailbox_sources -to $g2b_source_mailbox_destinations \
    -max_paths 1 -nworst 1]
  set g2b_source_to_axi_mailbox_paths [get_timing_paths -quiet -delay_type max \
    -from $g2b_source_mailbox_sources -to $g2b_axi_mailbox_destinations \
    -max_paths 1 -nworst 1]
  if {[llength $g2b_axi_to_source_mailbox_paths] != 1 ||
      [llength $g2b_source_to_axi_mailbox_paths] != 1} {
    error "G2B directional mailbox max-delay paths unavailable"
  }
  set g2b_axi_to_source_mailbox_wns \
    [get_property SLACK [lindex $g2b_axi_to_source_mailbox_paths 0]]
  set g2b_source_to_axi_mailbox_wns \
    [get_property SLACK [lindex $g2b_source_to_axi_mailbox_paths 0]]
  if {![string is double -strict $g2b_axi_to_source_mailbox_wns] ||
      ![string is double -strict $g2b_source_to_axi_mailbox_wns] ||
      $g2b_axi_to_source_mailbox_wns < 0.0 ||
      $g2b_source_to_axi_mailbox_wns < 0.0} {
    error "G2B directional mailbox max-delay gate failed: axi_to_source=$g2b_axi_to_source_mailbox_wns source_to_axi=$g2b_source_to_axi_mailbox_wns"
  }
  report_timing -delay_type max -from $g2b_timing_starts -to $g2b_timing_ends \
    -max_paths 250 -nworst 10 \
    -file [file join $evidence_root G2B_C2H_CRITICAL_PATHS.rpt]

  set stage ROUTED_HARD_GATES
  if {$fully_routed != 1 || $errors_in_routes != 0 || $unrouted_nets != 0 || $partial_nets != 0} {
    set routing FAIL
    error "route gate failed: fully=$fully_routed errors=$errors_in_routes unrouted=$unrouted_nets partial=$partial_nets"
  }
  set routing PASS
  set congestion_text [read_text $congestion_path]
  set placer_congestion_clear [regexp -nocase \
    {No congestion windows are found above level 5} $congestion_text]
  set router_congestion_clear [regexp -nocase \
    {No initial estimated congestion windows are found above level 5} $congestion_text]
  if {!$placer_congestion_clear || !$router_congestion_clear} {
    set congestion_gate FAIL
    error "congestion gate failed: unresolved level-5-or-higher hotspot"
  }
  set congestion_gate PASS

  set worst_setup [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
  set worst_hold [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
  if {[llength $worst_setup] != 1 || [llength $worst_hold] != 1} {
    set timing_gate FAIL
    error "required setup/hold timing path class is absent"
  }
  set wns [get_property SLACK $worst_setup]
  set whs [get_property SLACK $worst_hold]
  if {![string is double -strict $wns] || ![string is double -strict $whs]} {
    set timing_gate FAIL
    error "actual timing slack is not numeric"
  }
  set failing_setup [llength [get_timing_paths -quiet -delay_type max \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set failing_hold [llength [get_timing_paths -quiet -delay_type min \
    -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set tns [expr {$failing_setup == 0 ? 0.0 : "NEGATIVE_SEE_TIMING_SUMMARY"}]
  set ths [expr {$failing_hold == 0 ? 0.0 : "NEGATIVE_SEE_TIMING_SUMMARY"}]
  if {$wns < 0.0 || $whs < 0.0 || $failing_setup != 0 || $failing_hold != 0} {
    set timing_gate FAIL
    error "timing gate failed: WNS=$wns TNS=$tns WHS=$whs THS=$ths"
  }
  set check_timing_text [read_text $check_timing_path]
  set no_clock_count [check_timing_table_count $check_timing_text no_clock]
  set unconstrained_internal_count \
    [check_timing_table_count $check_timing_text unconstrained_internal_endpoints]
  if {$no_clock_count eq "UNKNOWN" || $unconstrained_internal_count eq "UNKNOWN"} {
    set timing_gate FAIL
    error "check_timing did not expose required no_clock/unconstrained counts"
  }
  if {$no_clock_count != 0 || $unconstrained_internal_count != 0} {
    set timing_gate FAIL
    error "unconstrained critical timing gate failed: no_clock=$no_clock_count unconstrained_internal_endpoints=$unconstrained_internal_count"
  }
  set timing_gate PASS

  set drc_errors 0
  set drc_critical_warnings 0
  set drc_warnings 0
  foreach violation [get_drc_violations -quiet] {
    set severity [string toupper [get_property SEVERITY $violation]]
    if {$severity eq "ERROR"} { incr drc_errors }
    if {$severity eq "CRITICAL WARNING"} { incr drc_critical_warnings }
    if {$severity eq "WARNING"} { incr drc_warnings }
  }
  if {$drc_errors != 0 || $drc_critical_warnings != 0} {
    set drc_gate FAIL
    error "DRC gate failed: errors=$drc_errors critical_warnings=$drc_critical_warnings"
  }
  set drc_gate PASS

  if {[catch {get_cdc_violations -quiet} cdc_violations]} {
    set cdc_gate FAIL
    error "CDC violation objects unavailable: $cdc_violations"
  }
  set cdc_critical 0
  set cdc_unknown 0
  set cdc_object_lines [list "CDC_VIOLATION_OBJECTS=[llength $cdc_violations]"]
  foreach violation $cdc_violations {
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    if {$severity eq "CRITICAL" || $severity eq "CRITICAL WARNING"} { incr cdc_critical }
    if {$severity eq "UNKNOWN"} { incr cdc_unknown }
    lappend cdc_object_lines \
      "CDC_VIOLATION=[get_property NAME $violation]|SEVERITY=$severity"
  }
  write_lines [file join $evidence_root CDC_VIOLATION_OBJECTS.txt] $cdc_object_lines
  if {$cdc_unknown != 0} {
    set cdc_gate FAIL
    error "CDC gate failed: unknown=$cdc_unknown"
  }
  set cdc_critical_dispositioned 0
  set cdc_disposition NOT_REQUIRED_ZERO_CRITICAL_AND_UNKNOWN
  if {$cdc_critical != 0} {
    if {[catch {
      set cdc_critical_dispositioned \
        [enforce_exact_cdc_disposition $cdc_path $cdc_violations]
    } cdc_disposition_failure]} {
      set cdc_gate FAIL
      error $cdc_disposition_failure
    }
    set cdc_disposition PASS_EXACT_REVIEWED_G2B_PROTOCOLS_AND_GEN2_XDMA_PIPE_CLOCK_MUX
  }
  if {$cdc_critical_dispositioned != $cdc_critical} {
    set cdc_gate FAIL
    error "CDC gate failed: critical=$cdc_critical dispositioned=$cdc_critical_dispositioned"
  }
  set cdc_gate PASS

  if {$bus_skew_violations != 0 || $bus_skew_met_constraints != 17} {
    set bus_skew_gate FAIL
    error "bus-skew gate failed: violations=$bus_skew_violations met=$bus_skew_met_constraints"
  }
  set bus_skew_gate PASS
  write_lines [file join $evidence_root G2B_FINAL_CDC_GATE.txt] [list \
    {FINAL_CDC_GATE=PASS} \
    "CDC_CRITICAL=$cdc_critical" "CDC_UNKNOWN=$cdc_unknown" \
    "CDC_CRITICAL_DISPOSITIONED=$cdc_critical_dispositioned" \
    "CDC_DISPOSITION=$cdc_disposition" \
    "G2B_AXI_TO_SOURCE_MAILBOX_WNS=$g2b_axi_to_source_mailbox_wns" \
    "G2B_SOURCE_TO_AXI_MAILBOX_WNS=$g2b_source_to_axi_mailbox_wns" \
    "BUS_SKEW_GATE=$bus_skew_gate" \
    "BUS_SKEW_VIOLATIONS=$bus_skew_violations" \
    "BUS_SKEW_MET_CONSTRAINTS=$bus_skew_met_constraints" \
    "BUS_SKEW_REPORT_SHA256=$bus_skew_report_sha" \
    {RAW_MULTIBIT_CDC_INTRODUCED=NO} \
    {GRAY_COUNTER_CROSSINGS=BOUNDED_AND_SYNCHRONIZED} \
    {MAILBOX_TOGGLE_CROSSINGS=ACKNOWLEDGED_AND_BOUNDED} \
    {RESET_DOMAIN_PROTOCOL=EXACT_REVIEWED_MANIFEST} \
    {SNAPSHOT_COHERENCY=ACKNOWLEDGED_STABLE_DATA_AND_GRAY_HOLD} \
    {BROAD_CDC_WAIVER_APPLIED=NO}]

  set black_boxes [get_cells -quiet -hier -filter {IS_BLACKBOX == 1}]
  set black_box_count [llength $black_boxes]
  set black_box_lines [list "BLACK_BOX_COUNT=$black_box_count"]
  foreach cell $black_boxes {
    lappend black_box_lines "BLACK_BOX=[get_property NAME $cell]|REF_NAME=[property_or_unknown REF_NAME $cell]"
  }
  lappend black_box_lines "BLACK_BOX_GATE=[expr {$black_box_count == 0 ? {PASS} : {FAIL}}]"
  write_lines [file join $evidence_root BLACK_BOXES.txt] $black_box_lines
  if {$black_box_count != 0} {
    set black_box_gate FAIL
    error "unresolved black-box gate failed: count=$black_box_count"
  }
  set black_box_gate PASS

  lassign [evaluate_resource_gate ROUTED $final_metrics] \
    resource_gate resource_gate_reason
  set bufg_used [llength [get_cells -quiet -hier -filter {REF_NAME =~ BUFG*}]]
  set mmcm_used [llength [get_cells -quiet -hier -filter {REF_NAME =~ MMCM*}]]
  set pll_used [llength [get_cells -quiet -hier -filter {REF_NAME =~ PLL*}]]
  # The exported XDMA axi_aclk is the application/user clock consumed by R1i.
  # Resolve it from routed timing objects; interface metadata is not accepted
  # as proof of its implementation frequency.
  set nvp_clock_pins [get_pins -quiet -hier -regexp {.*NVP_AUTOINIT.*/C}]
  set axi_bridge_clock_pins [get_pins -quiet -hier -regexp {.*AXI_LITE_HOST_BRIDGE.*/C}]
  set nvp_clock_pin_count [llength $nvp_clock_pins]
  set axi_bridge_clock_pin_count [llength $axi_bridge_clock_pins]
  set nvp_application_clocks [unique_objects_by_name \
    [get_clocks -quiet -of_objects $nvp_clock_pins]]
  set axi_application_clocks [unique_objects_by_name \
    [get_clocks -quiet -of_objects $axi_bridge_clock_pins]]
  set nvp_application_clock_names [list]
  foreach clock_object $nvp_application_clocks {
    lappend nvp_application_clock_names [get_property NAME $clock_object]
  }
  set nvp_application_clock_names [lsort $nvp_application_clock_names]
  set axi_application_clock_names [list]
  foreach clock_object $axi_application_clocks {
    lappend axi_application_clock_names [get_property NAME $clock_object]
  }
  set axi_application_clock_names [lsort $axi_application_clock_names]
  set axi_clock_objects [unique_objects_by_name [concat \
    [clocks_for_pattern *axi_aclk*] \
    [get_clocks -quiet userclk1] \
    $nvp_application_clocks $axi_application_clocks]]
  set clock_binding AXI_ACLK_NET_PIN_PLUS_PROTECTED_CONSUMERS_AND_USERCLK1
  set routed_clock_object_count [llength $axi_clock_objects]
  set clock_receipt [list \
    "XCI_REQUESTED_AXISTEN_FREQ=[get_property CONFIG.axisten_freq $xdma_ip]" \
    "XCI_REQUESTED_FREE_RUN_FREQ=[get_property CONFIG.free_run_freq $xdma_ip]" \
    "CLOCK_BINDING=$clock_binding" \
    "NVP_AUTOINIT_CLOCK_PIN_COUNT=$nvp_clock_pin_count" \
    "NVP_AUTOINIT_CLOCK_OBJECTS=[join $nvp_application_clock_names ,]" \
    "AXI_BRIDGE_CLOCK_PIN_COUNT=$axi_bridge_clock_pin_count" \
    "AXI_BRIDGE_CLOCK_OBJECTS=[join $axi_application_clock_names ,]" \
    "AXI_USER_CLOCK_OBJECT_COUNT=$routed_clock_object_count"]
  if {$nvp_clock_pin_count == 0 || $axi_bridge_clock_pin_count == 0 ||
      [llength $nvp_application_clocks] == 0 || [llength $axi_application_clocks] == 0 ||
      $nvp_application_clock_names ne $axi_application_clock_names ||
      $routed_clock_object_count == 0} {
    set clock_gate BLOCKED
    lappend clock_receipt "EFFECTIVE_AXI_CLOCK_MHZ=UNKNOWN" \
      "EFFECTIVE_USER_CLOCK_MHZ=UNKNOWN" "CLOCK_GATE=BLOCKED" \
      "CLOCK_BLOCKER=GEN2_CHANGED_APPLICATION_CLOCK"
    write_lines [file join $evidence_root G2B_CLOCK_OBJECT_RECEIPT.txt] $clock_receipt
    error "BLOCKED - GEN2_CHANGED_APPLICATION_CLOCK: routed axi_aclk timing object unavailable"
  }
  set clock_index 0
  set first_frequency UNKNOWN
  set clock_frequency_mismatch 0
  foreach clock_object $axi_clock_objects {
    set period [get_property PERIOD $clock_object]
    if {![string is double -strict $period] || $period <= 0.0} {
      lappend clock_receipt "CLOCK_${clock_index}_PERIOD=INVALID"
      set clock_frequency_mismatch 1
      incr clock_index
      continue
    }
    set frequency [expr {1000.0 / $period}]
    if {$first_frequency eq "UNKNOWN"} { set first_frequency $frequency }
    if {abs($frequency - $expected_user_clock_mhz) > $clock_tolerance_mhz} {
      set clock_frequency_mismatch 1
    }
    lappend clock_receipt \
      "CLOCK_${clock_index}_NAME=[get_property NAME $clock_object]" \
      "CLOCK_${clock_index}_PERIOD_NS=[format %.6f $period]" \
      "CLOCK_${clock_index}_FREQUENCY_MHZ=[format %.6f $frequency]" \
      "CLOCK_${clock_index}_SOURCE_PINS=[property_or_unknown SOURCE_PINS $clock_object]" \
      "CLOCK_${clock_index}_WAVEFORM=[property_or_unknown WAVEFORM $clock_object]"
    incr clock_index
  }
  if {$first_frequency ne "UNKNOWN"} {
    set effective_axi_clock_mhz [format %.6f $first_frequency]
    set effective_user_clock_mhz $effective_axi_clock_mhz
  }
  if {$clock_frequency_mismatch} {
    set clock_gate BLOCKED
    lappend clock_receipt "EFFECTIVE_AXI_CLOCK_MHZ=$effective_axi_clock_mhz" \
      "EFFECTIVE_USER_CLOCK_MHZ=$effective_user_clock_mhz" "CLOCK_GATE=BLOCKED" \
      "CLOCK_BLOCKER=GEN2_CHANGED_APPLICATION_CLOCK"
    write_lines [file join $evidence_root G2B_CLOCK_OBJECT_RECEIPT.txt] $clock_receipt
    error "BLOCKED - GEN2_CHANGED_APPLICATION_CLOCK: routed application clock is not approximately 62.5 MHz"
  }
  lappend clock_receipt "EFFECTIVE_AXI_CLOCK_MHZ=$effective_axi_clock_mhz" \
    "EFFECTIVE_USER_CLOCK_MHZ=$effective_user_clock_mhz" \
    "EXPECTED_APPLICATION_CLOCK_MHZ=$expected_user_clock_mhz" \
    "CLOCK_TOLERANCE_MHZ=$clock_tolerance_mhz" "CLOCK_GATE=PASS"
  write_lines [file join $evidence_root G2B_CLOCK_OBJECT_RECEIPT.txt] $clock_receipt
  set clock_gate PASS

  foreach action {SYNTH_DESIGN OPT_DESIGN PLACE_DESIGN PHYS_OPT_DESIGN ROUTE_DESIGN} {
    if {[dict get $action_counts $action] != 1} { error "flow invocation count mismatch for $action" }
  }
  if {[dict get $action_counts WRITE_BITSTREAM] != 0 ||
      [dict get $action_counts WRITE_DEBUG_PROBES] != 0} {
    error "output writers ran before all hard gates passed"
  }

  if {![source_seal_is_current]} {
    error "source identity or sealed input manifest changed before bitstream"
  }

  set prebit_resource_disposition \
    [expr {$resource_gate eq "PASS" ? {PASS} : {FAIL_RESOURCE_HEADROOM}}]
  set prebit_gate_result \
    [expr {$resource_gate eq "PASS" ? {PASS} : {FAIL}}]
  write_lines [file join $evidence_root G2B_PRE_BITSTREAM_HARD_GATE.txt] [list \
    "SOURCE_IDENTITY_KIND=$source_identity_kind" \
    "REPOSITORY_HEAD=$source_commit" "REPOSITORY_HEAD_TREE=$source_tree" \
    "PRECOMMIT_INPUT_MANIFEST_SHA256=$precommit_manifest_sha" \
    "SOURCE_TO_BIT_PROVENANCE=$source_to_bit_provenance" \
    "PROJECT_CREATION=$project_creation" "IP_GENERATION=$ip_generation" \
    "SYNTHESIS=$synthesis" "OPTIMIZATION=$optimization" \
    "PLACEMENT=$placement" "PHYSICAL_OPTIMIZATION=$physical_optimization" \
    "ROUTING=$routing" "FULLY_ROUTED=$fully_routed" \
    "ERRORS_IN_ROUTES=$errors_in_routes" "UNROUTED_NETS=$unrouted_nets" \
    "PARTIAL_NETS=$partial_nets" "WNS=$wns" "TNS=$tns" \
    "WHS=$whs" "THS=$ths" "NO_CLOCK_COUNT=$no_clock_count" \
    "UNCONSTRAINED_INTERNAL_ENDPOINTS=$unconstrained_internal_count" \
    "DRC_ERRORS=$drc_errors" "DRC_CRITICAL_WARNINGS=$drc_critical_warnings" \
    "CDC_CRITICAL=$cdc_critical" "CDC_UNKNOWN=$cdc_unknown" \
    "CDC_CRITICAL_DISPOSITIONED=$cdc_critical_dispositioned" \
    "CDC_DISPOSITION=$cdc_disposition" \
    "G2B_AXI_TO_SOURCE_MAILBOX_WNS=$g2b_axi_to_source_mailbox_wns" \
    "G2B_SOURCE_TO_AXI_MAILBOX_WNS=$g2b_source_to_axi_mailbox_wns" \
    "BUS_SKEW_VIOLATIONS=$bus_skew_violations" \
    "BUS_SKEW_MET_CONSTRAINTS=$bus_skew_met_constraints" \
    "BUS_SKEW_REPORT_SHA256=$bus_skew_report_sha" \
    "BLACK_BOX_COUNT=$black_box_count" "CLOCK_GATE=$clock_gate" \
    "XDC_COLLECTION_GATE=$xdc_collection_gate" \
    "G2B_MMIO_ROUTER_SOURCE_OBJECTS=$g2b_mmio_router_source_object_count" \
    "G2B_MMIO_ROUTER_USED_IN_SYNTHESIS=$g2b_mmio_router_used_in_synthesis" \
    "G2B_MMIO_ROUTER_COMPILE_ORDER_MATCHES=$g2b_mmio_router_compile_order_count" \
    "G2B_MMIO_ROUTER_COMPILE_ORDER_INDEX=$g2b_mmio_router_compile_order_index" \
    "G2B_MMIO_ROUTER_SOURCE_SHA256=$g2b_mmio_router_source_sha" \
    "G2B_MMIO_ROUTER_SOURCE_GATE=$g2b_mmio_router_source_gate" \
    "G2B_MMIO_ROUTER_CELLS=$g2b_mmio_router_cell_count" \
    "G2B_MMIO_ROUTER_CELL_DISPOSITION=$g2b_mmio_router_cell_disposition" \
    "POST_OPT_RESOURCE_GATE=$post_opt_resource_gate" \
    "POST_OPT_RESOURCE_GATE_REASON=$post_opt_resource_gate_reason" \
    "ROUTED_RESOURCE_GATE=$resource_gate" \
    "ROUTED_RESOURCE_GATE_REASON=$resource_gate_reason" \
    "RESOURCE_DISPOSITION=$prebit_resource_disposition" \
    "CONGESTION_GATE=$congestion_gate" \
    "SYNTH_DCP_SHA256=$synth_dcp_sha" \
    "POST_OPT_DCP_SHA256=$post_opt_dcp_sha" \
    "ROUTED_DCP_SHA256=$routed_dcp_sha" "RESULT=$prebit_gate_result"]

  if {$resource_gate ne "PASS"} {
    set stage RESOURCE_HEADROOM_GATE_ROUTED
    error "BLOCKED - RESOURCE_HEADROOM_REQUIRES_ARCHITECT_REVIEW: $resource_gate_reason"
  }

  set stage WRITE_BITSTREAM
  record_action WRITE_BITSTREAM
  write_bitstream $bit_path
  if {![file isfile $bit_path] || [file size $bit_path] == 0} {
    error "bitstream missing or empty after write_bitstream"
  }
  set bit_generated YES
  set bit_sha [sha256_file $bit_path]

  # A design can legitimately contain no debug probes.  The attempt is
  # mandatory; absence is explicitly receipted but is not a design gate.
  set stage WRITE_DEBUG_PROBES
  record_action WRITE_DEBUG_PROBES
  if {[catch {write_debug_probes -force $ltx_path} ltx_failure]} {
    set ltx_error [single_line $ltx_failure]
  }
  if {[file isfile $ltx_path] && [file size $ltx_path] > 0} {
    set ltx_generated YES
    set ltx_sha [sha256_file $ltx_path]
  }
  write_lines [file join $evidence_root G2B_DEBUG_PROBES_RECEIPT.txt] [list \
    "LTX_PATH=$ltx_path" "WRITE_DEBUG_PROBES_ATTEMPTED=YES" \
    "LTX_PRODUCED=$ltx_generated" "LTX_SHA256=$ltx_sha" "LTX_ERROR=$ltx_error"]

  if {![source_seal_is_current]} {
    error "source identity or sealed input manifest changed after build"
  }
  set source_post_build PASS
  set stage COMPLETE
} build_failure build_options]

set offline_build_qualification \
  [expr {$build_result == 0 ? {PASS} : {FAIL}}]
set terminal_lines [list \
  "TASK=AHD_V41_G2B_ONE_CHANNEL_C2H_OFFLINE_IMPLEMENTATION" \
  "BUILD_PROFILE=$build_profile" \
  "ENABLE_RTRACK_DIAGNOSTICS=$enable_rtrack_diagnostics" \
  "EXECUTION_MODE=$execution_mode" "STAGE=$stage" \
  "SOURCE_IDENTITY_KIND=$source_identity_kind" \
  "SOURCE_COMMIT=$reported_source_commit" \
  "REPOSITORY_HEAD=$source_commit" "REPOSITORY_HEAD_TREE=$source_tree" \
  "SOURCE_CLEAN=$source_clean" \
  "PRECOMMIT_INPUT_MANIFEST_SHA256=$precommit_manifest_sha" \
  "ACCEPTED_G2A_BASE_COMMIT=$accepted_g2a_base_commit" \
  "ACCEPTED_G2A_BASE_TREE=$accepted_g2a_base_tree" \
  "QUALIFIED_R1I_COMMIT=$qualified_r1i_commit" \
  "QUALIFIED_R1I_TREE=$qualified_r1i_tree" \
  "INTEGRATION_BRANCH=$expected_branch" \
  "VIVADO_VERSION=$vivado_version" "VIVADO_SW_BUILD=$vivado_sw_build" \
  "PROJECT_CREATION=$project_creation" "IP_GENERATION=$ip_generation" \
  "XDMA_CONFIG_PROPERTY_COUNT=$ip_config_property_count" \
  "XDMA_XCI_GIT_BLOB=$actual_xdma_xci_blob" \
  "XDMA_SOURCE_SHA256=$xdma_source_sha" \
  "XDMA_LOCAL_COPY_SHA256=$xdma_copy_sha" \
  "SYNTHESIS=$synthesis" "OPTIMIZATION=$optimization" \
  "PLACEMENT=$placement" "PHYSICAL_OPTIMIZATION=$physical_optimization" \
  "ROUTING=$routing" "FULLY_ROUTED=$fully_routed" \
  "ERRORS_IN_ROUTES=$errors_in_routes" "UNROUTED_NETS=$unrouted_nets" \
  "PARTIAL_NETS=$partial_nets" "TIMING_GATE=$timing_gate" \
  "WNS=$wns" "TNS=$tns" "WHS=$whs" "THS=$ths" \
  "FAILING_SETUP_PATHS=$failing_setup" "FAILING_HOLD_PATHS=$failing_hold" \
  "NO_CLOCK_COUNT=$no_clock_count" \
  "UNCONSTRAINED_INTERNAL_ENDPOINTS=$unconstrained_internal_count" \
  "DRC_GATE=$drc_gate" "DRC_ERRORS=$drc_errors" \
  "DRC_CRITICAL_WARNINGS=$drc_critical_warnings" "DRC_WARNINGS=$drc_warnings" \
  "CDC_GATE=$cdc_gate" "CDC_CRITICAL=$cdc_critical" "CDC_UNKNOWN=$cdc_unknown" \
  "CDC_CRITICAL_DISPOSITIONED=$cdc_critical_dispositioned" \
  "CDC_DISPOSITION=$cdc_disposition" \
  "G2B_AXI_TO_SOURCE_MAILBOX_WNS=$g2b_axi_to_source_mailbox_wns" \
  "G2B_SOURCE_TO_AXI_MAILBOX_WNS=$g2b_source_to_axi_mailbox_wns" \
  "BUS_SKEW_GATE=$bus_skew_gate" "BUS_SKEW_VIOLATIONS=$bus_skew_violations" \
  "BUS_SKEW_MET_CONSTRAINTS=$bus_skew_met_constraints" \
  "BUS_SKEW_REPORT_SHA256=$bus_skew_report_sha" \
  "BLACK_BOX_GATE=$black_box_gate" "BLACK_BOX_COUNT=$black_box_count" \
  "CLOCK_GATE=$clock_gate" "ROUTED_CLOCK_OBJECT_COUNT=$routed_clock_object_count" \
  "NVP_AUTOINIT_CLOCK_PIN_COUNT=$nvp_clock_pin_count" \
  "AXI_BRIDGE_CLOCK_PIN_COUNT=$axi_bridge_clock_pin_count" \
  "EFFECTIVE_USER_CLOCK_MHZ=$effective_user_clock_mhz" \
  "EFFECTIVE_AXI_CLOCK_MHZ=$effective_axi_clock_mhz" \
  "XDC_COLLECTION_GATE=$xdc_collection_gate" \
  "CFG_SRC=$cfg_src_count" "CFG_DST=$cfg_dst_count" \
  "STATUS_SRC=$status_src_count" "STATUS_DST=$status_dst_count" \
  "TOGGLE_FIRST_STAGES=$toggle_first_stage_count" "TOGGLE_FIRST_D=$toggle_first_d_count" \
  "DIAG_GRAY_SOURCES=$diag_gray_source_count" "DIAG_GRAY_FIRST_D=$diag_gray_first_d_count" \
  "G2B_MODULE_CELLS=$g2b_module_cell_count" \
  "G2B_MMIO_ROUTER_CELLS=$g2b_mmio_router_cell_count" \
  "G2B_MMIO_ROUTER_SOURCE_OBJECTS=$g2b_mmio_router_source_object_count" \
  "G2B_MMIO_ROUTER_USED_IN_SYNTHESIS=$g2b_mmio_router_used_in_synthesis" \
  "G2B_MMIO_ROUTER_COMPILE_ORDER_MATCHES=$g2b_mmio_router_compile_order_count" \
  "G2B_MMIO_ROUTER_COMPILE_ORDER_INDEX=$g2b_mmio_router_compile_order_index" \
  "G2B_MMIO_ROUTER_SOURCE_SHA256=$g2b_mmio_router_source_sha" \
  "G2B_MMIO_ROUTER_SOURCE_GATE=$g2b_mmio_router_source_gate" \
  "G2B_MMIO_ROUTER_CELL_DISPOSITION=$g2b_mmio_router_cell_disposition" \
  "G2B_FIRST_STAGES=$g2b_first_stage_count" \
  "G2B_SECOND_STAGES=$g2b_second_stage_count" \
  "G2B_FIRST_STAGE_D=$g2b_first_stage_d_count" \
  "G2B_TOGGLE_SOURCES=$g2b_toggle_source_count" \
  "G2B_GRAY_HOLD_SOURCES=$g2b_gray_hold_source_count" \
  "G2B_GRAY_FIRST_D=$g2b_gray_first_d_count" \
  "G2B_AXI_MAILBOX_SOURCES=$g2b_axi_mailbox_source_count" \
  "G2B_SOURCE_MAILBOX_DESTINATIONS=$g2b_source_mailbox_destination_count" \
  "G2B_SOURCE_MAILBOX_SOURCES=$g2b_source_mailbox_source_count" \
  "G2B_SOURCE_MAILBOX_REG_SOURCES=$g2b_source_mailbox_reg_source_count" \
  "G2B_SOURCE_MAILBOX_RAM_SOURCES=$g2b_source_mailbox_ram_source_count" \
  "G2B_AXI_MAILBOX_DESTINATIONS=$g2b_axi_mailbox_destination_count" \
  "G2B_AXI_MAILBOX_ALIAS_SOURCES=$g2b_axi_mailbox_alias_source_count" \
  "G2B_SOURCE_MAILBOX_ADDED_DESTINATIONS=$g2b_source_mailbox_added_destination_count" \
  "G2B_SOURCE_MAILBOX_DESCRIPTOR_SOURCES=$g2b_source_mailbox_descriptor_source_count" \
  "G2B_DESC_ATTEMPT_RAM_SOURCES=$g2b_desc_attempt_ram_source_count" \
  "G2B_DESC_GENERATION_RAM_SOURCES=$g2b_desc_generation_ram_source_count" \
  "G2B_DESC_EPOCH_REG_SOURCES=$g2b_desc_epoch_reg_source_count" \
  "G2B_AXI_MAILBOX_ADDED_DESTINATIONS=$g2b_axi_mailbox_added_destination_count" \
  "G2B_TIMING_STARTS=$g2b_timing_start_count" \
  "G2B_TIMING_ENDS=$g2b_timing_end_count" \
  "G2B_CDC_XDC_FILES=$g2b_cdc_xdc_file_count" \
  "NVP_INIT_ASYNC_RESET_PINS=$nvp_init_async_reset_pin_count" \
  "PCIE_REFCLK_IBUF=$pcie_refclk_ibuf_count" \
  "GTPE2_CHANNEL=$gt_channel_count" "GTPE2_COMMON=$gt_common_count" \
  "PCIE_2_1=$pcie_hard_block_count" \
  "POST_OPT_RESOURCE_GATE=$post_opt_resource_gate" \
  "POST_OPT_RESOURCE_GATE_REASON=$post_opt_resource_gate_reason" \
  "RESOURCE_GATE=$resource_gate" "RESOURCE_GATE_REASON=$resource_gate_reason" \
  "BUFG_USED=$bufg_used" \
  "CONGESTION_GATE=$congestion_gate" \
  "MMCM_USED=$mmcm_used" "PLL_USED=$pll_used" \
  "SYNTH_DCP_SHA256=$synth_dcp_sha" \
  "POST_OPT_DCP_SHA256=$post_opt_dcp_sha" \
  "ROUTED_DCP_SHA256=$routed_dcp_sha" \
  "BITSTREAM_PATH=$bit_path" "BITSTREAM_PRODUCED=$bit_generated" \
  "BITSTREAM_SHA256=$bit_sha" "LTX_PATH=$ltx_path" \
  "LTX_PRODUCED=$ltx_generated" "LTX_SHA256=$ltx_sha" \
  "SOURCE_POST_BUILD=$source_post_build" "CHECKPOINT_REUSE=NO" \
  "HARDWARE_ACCESSED=NO" "HARDWARE_PROVEN=NO" \
  "G2B_ONE_CHANNEL_RTL_INCLUDED=YES" \
  "G2B_OFFLINE_BUILD_QUALIFICATION=$offline_build_qualification"]

if {[dict size $post_opt_metrics] != 0} {
  foreach key {LUT_USED LUT_AVAILABLE LUT_PERCENT FF_USED FF_AVAILABLE FF_PERCENT BRAM_USED BRAM_AVAILABLE BRAM_PERCENT DSP_USED DSP_AVAILABLE DSP_PERCENT} {
    set value [dict get $post_opt_metrics $key]
    if {[string match *_PERCENT $key]} { set value [format %.3f $value] }
    lappend terminal_lines "POST_OPT_${key}=$value"
  }
}
if {[dict size $final_metrics] != 0} {
  foreach key {LUT_USED LUT_AVAILABLE LUT_PERCENT FF_USED FF_AVAILABLE FF_PERCENT BRAM_USED BRAM_AVAILABLE BRAM_PERCENT DSP_USED DSP_AVAILABLE DSP_PERCENT} {
    set value [dict get $final_metrics $key]
    if {[string match *_PERCENT $key]} { set value [format %.3f $value] }
    lappend terminal_lines "ROUTED_${key}=$value"
  }
}
dict for {key value} $action_counts { lappend terminal_lines "$key=$value" }

if {$build_result != 0} {
  # Record whether the source stayed sealed even on a failed tool/design gate.
  set failure_source_identity FAIL
  if {[source_seal_is_current]} {
    set failure_source_identity PASS
  }
  lappend terminal_lines "SOURCE_IDENTITY_AFTER_FAILURE=$failure_source_identity" \
    "BUILD=FAIL" "ERROR=[single_line $build_failure]"
  if {[dict exists $build_options -errorinfo]} {
    lappend terminal_lines "ERROR_INFO=[single_line [dict get $build_options -errorinfo]]"
  }
  write_lines [file join $evidence_root G2B_BUILD_RESULT.txt] $terminal_lines
  puts stderr "G2B_BUILD_FAIL: $build_failure"
  catch {close_project}
  exit 1
}

foreach action {SYNTH_DESIGN OPT_DESIGN PLACE_DESIGN PHYS_OPT_DESIGN ROUTE_DESIGN WRITE_BITSTREAM WRITE_DEBUG_PROBES} {
  if {[dict get $action_counts $action] != 1} {
    lappend terminal_lines "BUILD=FAIL" "ERROR=terminal operation-count mismatch for $action"
    write_lines [file join $evidence_root G2B_BUILD_RESULT.txt] $terminal_lines
    catch {close_project}
    exit 1
  }
}
lappend terminal_lines "BUILD=PASS" \
  "SOURCE_TO_BIT_PROVENANCE=$source_to_bit_provenance"
write_lines [file join $evidence_root G2B_BUILD_RESULT.txt] $terminal_lines
catch {close_project}
puts "G2B_BUILD_PASS BITSTREAM_SHA256=$bit_sha LTX_PRODUCED=$ltx_generated LTX_SHA256=$ltx_sha"
exit 0
