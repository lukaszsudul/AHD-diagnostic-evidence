# AHD v41 G2B NVP DIAG2-RM1 fresh routed build stage.
#
# This file is intentionally task-local.  It builds only the mutually-exclusive
# RM1 profile, writes one routed handoff DCP plus raw reports, and never writes a
# bitstream.  The companion finalizer is the sole bitstream writer.

if {$argc != 16} {
  puts stderr "usage: g2b_nvp_diag2_rm1_build.tcl REPO_ROOT BUILD_ROOT EVIDENCE_ROOT SOURCE_COMMIT SOURCE_TREE FOCUSED_RECEIPT AFFECTED_R3_RECEIPT RECEIPT_BINDING PUBLICATION_READBACK_RECEIPT R3_DONOR_BUILD_TCL PRE_VIVADO_SEAL PRE_VIVADO_SEAL_SHA256 FOCUSED_SHA256 AFFECTED_SHA256 BINDING_SHA256 PUBLICATION_SHA256"
  exit 2
}
lassign $argv repo_root build_root evidence_root source_commit source_tree \
  focused_receipt affected_receipt binding_receipt publication_receipt \
  donor_build_tcl pre_vivado_seal expected_pre_vivado_seal_sha \
  expected_focused_sha expected_affected_sha expected_binding_sha \
  expected_publication_sha

set repo_root [file normalize $repo_root]
set build_root [file normalize $build_root]
set evidence_root [file normalize $evidence_root]
set focused_receipt [file normalize $focused_receipt]
set affected_receipt [file normalize $affected_receipt]
set binding_receipt [file normalize $binding_receipt]
set publication_receipt [file normalize $publication_receipt]
set donor_build_tcl [file normalize $donor_build_tcl]
set pre_vivado_seal [file normalize $pre_vivado_seal]
set build_script_path [file normalize [info script]]

set expected_parent fc37d815b5d64ef90dfbd99c57ae4cc09567b56f
set expected_branch diag/v41-g2b-nvp-video-diag2-rm1
set expected_part xc7a35tcsg325-2
set expected_top ahd_capture_top_xdma
set expected_vivado_version 2025.2
set expected_donor_sha 74CA15C2FCEADBC59876249E8EEB08D71D7FD787A0F7B422DC69BE737FB57D59
set expected_xdma_xci_blob 450aa334e2bda4396cd5a7270ba15895c7f7ed54
set expected_xdma_config_blob ea9c2b5a463e6c4e15743d53abab734ba5fdf516
set expected_build_flags 0x00000802
set lut_hard_max 20384
set lut_preferred_max 19760
set authorized_changes [dict create \
  rtl/g2b/v41_g2b_onech_c2h.sv M \
  rtl/top/ahd_capture_top_xdma.sv M \
  rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv A \
  rtl/diagnostic/g2b_nvp_rm1_route_controller.sv A \
  rtl/g2b/g2b_nvp_video_diag2_rm1.sv A \
  xdc/common/g2b_nvp_diag2_rm1_cdc.xdc A \
  tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1 A \
  tests/nvp_video_diag/tb_g2b_nvp_diag2_rm1_focused.sv A \
  tests/nvp_video_diag/tb_g2b_nvp_rm1_route_controller.sv A \
  tests/nvp_video_diag/tb_g2b_nvp_rm1_parser_tap.sv A \
  tests/nvp_video_diag/run_nvp_diag2_rm1_focused_gate.ps1 A]

set sv_rel_files {
  rtl/v41/axi_lite_host_bridge.sv
  rtl/v41/axi_clock_lifecycle_monitor.sv
  rtl/v41/axi_clock_measurement_regs.sv
  rtl/v41/r1e_measurement_regs.sv
  rtl/v41/r1h_probe_index_bram_store.sv
  rtl/v41/nvp_i2c_tri_phase_probe.sv
  rtl/v41/nvp_i2c_fixed_master.sv
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
  rtl/g2b/g2b_nvp_video_diag.sv
  rtl/diagnostic/g2b_nvp_rm1_route_controller.sv
  rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv
  rtl/g2b/g2b_nvp_video_diag2_rm1.sv
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
  xdc/common/g2b_nvp_diag2_rm1_cdc.xdc
  xdc/common/configuration_bank.xdc
}

# Import only procedure declarations from the immutable R3 donor.  No donor
# top-level statement is evaluated.  This retains the exact, previously proven
# 11-group bus-skew and 17 promoted-replacement algorithms without inheriting
# the R3 profile, source list, LUT-reduction rule, or output writers.
proc import_donor_procedures {path} {
  set fh [open $path r]
  fconfigure $fh -encoding utf-8
  set collecting 0
  set script ""
  set count 0
  while {[gets $fh line] >= 0} {
    if {!$collecting && [regexp {^[ \t]*proc[ \t]+} $line]} {
      set collecting 1
      set script "$line\n"
    } elseif {$collecting} {
      append script "$line\n"
    }
    if {$collecting && [info complete $script]} {
      uplevel #0 $script
      incr count
      set collecting 0
      set script ""
    }
  }
  close $fh
  if {$collecting} { error "incomplete donor procedure declaration" }
  if {$count < 50} { error "unexpected donor procedure count: $count" }
  return $count
}

proc rm1_git {args} {
  global repo_root
  return [string trim [exec git --no-optional-locks -C $repo_root {*}$args]]
}

proc rm1_changed_set_current {} {
  global source_commit expected_parent authorized_changes
  set parent_words [regexp -all -inline {\S+} \
    [rm1_git rev-list --parents -n 1 $source_commit]]
  if {[llength $parent_words] != 2 ||
      [string tolower [lindex $parent_words 0]] ne $source_commit ||
      [string tolower [lindex $parent_words 1]] ne $expected_parent} {
    error "RM1 direct parent mismatch"
  }
  set output [rm1_git diff-tree --no-commit-id --name-status -r \
    --find-renames --find-copies --find-copies-harder \
    $expected_parent $source_commit]
  set seen [dict create]
  set rows [list]
  foreach raw_line [split $output "\n"] {
    set line [string trimright $raw_line "\r"]
    if {$line eq ""} { continue }
    set columns [split $line "\t"]
    if {[llength $columns] != 2} { error "RM1 rename/copy or malformed diff: $line" }
    lassign $columns status rel
    if {[file pathtype $rel] ne "relative" || [string first "\\" $rel] >= 0 ||
        [regexp {(^|/)\.\.(/|$)} $rel] || [dict exists $seen $rel]} {
      error "RM1 noncanonical or duplicate changed path: $rel"
    }
    if {![dict exists $authorized_changes $rel] ||
        [dict get $authorized_changes $rel] ne $status} {
      error "RM1 unauthorized changed path: $status:$rel"
    }
    dict set seen $rel 1
    lappend rows "$status|$rel"
  }
  if {[dict size $seen] != 11 || [dict size $authorized_changes] != 11} {
    error "RM1 authorized changed set count mismatch: [dict size $seen]/11"
  }
  dict for {rel status} $authorized_changes {
    if {![dict exists $seen $rel]} { error "RM1 authorized changed path missing: $status:$rel" }
  }
  return [lsort -ascii $rows]
}

proc rm1_canonical_inputs {} {
  global repo_root sv_rel_files vhdl_rel_files xdc_rel_files
  global focused_receipt affected_receipt binding_receipt publication_receipt
  global donor_build_tcl pre_vivado_seal build_script_path
  set paths [concat $sv_rel_files $vhdl_rel_files $xdc_rel_files [list \
    ip/v41/xdma_v41_m1.xci scripts/v41/xdma_config_common.tcl]]
  set rows [list]
  set seen [dict create]
  foreach rel $paths {
    if {[file pathtype $rel] ne "relative" || [string first {\\} $rel] >= 0} {
      error "noncanonical build input: $rel"
    }
    if {[dict exists $seen $rel]} { error "duplicate build input: $rel" }
    dict set seen $rel 1
    set path [file join $repo_root $rel]
    if {![file isfile $path]} { error "missing build input: $path" }
    lappend rows "$rel|[sha256_file $path]"
  }
  set harness_root [file dirname $build_script_path]
  set harness_files [list]
  foreach name {
      g2b_nvp_diag2_rm1_build.tcl
      g2b_nvp_diag2_rm1_finalize.tcl
      invoke_rm1_one_shot_build.ps1
      bind_rm1_receipts_to_source.ps1
      run_rm1_affected_regressions.ps1
      check_rm1_build_harness.ps1
      check_rm1_harness_syntax.tcl
      RM1_PUBLICATION_READBACK_RECEIPT_SCHEMA.json
      RM1_BUILD_HARNESS_README.md} {
    lappend harness_files [file join $harness_root $name]
  }
  foreach external [concat [list $focused_receipt $affected_receipt \
      $binding_receipt $publication_receipt $pre_vivado_seal \
      $donor_build_tcl] $harness_files] {
    if {![file isfile $external]} { error "missing external build authority: $external" }
    lappend rows "EXTERNAL:[file normalize $external]|[sha256_file $external]"
  }
  return $rows
}

proc rm1_source_seal_current {} {
  global source_commit source_tree expected_branch sealed_inputs sealed_changed_set
  if {[catch {
    set ok [expr {
      [rm1_git rev-parse HEAD] eq $source_commit &&
      [rm1_git rev-parse {HEAD^{tree}}] eq $source_tree &&
       [rm1_git symbolic-ref --short HEAD] eq $expected_branch &&
       [rm1_git status --porcelain=v1 --untracked-files=all] eq "" &&
       [rm1_changed_set_current] eq $sealed_changed_set &&
       [rm1_canonical_inputs] eq $sealed_inputs}]
  }]} { return 0 }
  return $ok
}

proc rm1_require_receipt {path patterns label} {
  if {![file isfile $path]} { error "$label receipt missing: $path" }
  set text [read_text $path]
  foreach pattern $patterns {
    if {![regexp -- $pattern $text]} {
      error "$label receipt contract missing: $pattern"
    }
  }
  return [sha256_file $path]
}

proc rm1_json_decode_string {encoded label} {
  set decoded ""
  set length [string length $encoded]
  for {set index 0} {$index < $length} {incr index} {
    set character [string index $encoded $index]
    if {$character ne "\\"} {
      append decoded $character
      continue
    }
    incr index
    if {$index >= $length} { error "$label has a truncated JSON escape" }
    set escape [string index $encoded $index]
    if {$escape eq "\""} {
      append decoded "\""
    } elseif {$escape eq "\\"} {
      append decoded "\\"
    } elseif {$escape eq "/"} {
      append decoded "/"
    } elseif {$escape eq "b"} {
      append decoded [format %c 8]
    } elseif {$escape eq "f"} {
      append decoded [format %c 12]
    } elseif {$escape eq "n"} {
      append decoded [format %c 10]
    } elseif {$escape eq "r"} {
      append decoded [format %c 13]
    } elseif {$escape eq "t"} {
      append decoded [format %c 9]
    } elseif {$escape eq "u"} {
      if {$index + 4 >= $length} { error "$label has a truncated JSON unicode escape" }
      set hex [string range $encoded [expr {$index + 1}] [expr {$index + 4}]]
      if {![regexp {^[0-9A-Fa-f]{4}$} $hex]} {
        error "$label has an invalid JSON unicode escape"
      }
      scan $hex %x codepoint
      if {$codepoint >= 0xD800 && $codepoint <= 0xDFFF} {
        error "$label uses an unsupported JSON surrogate escape"
      }
      append decoded [format %c $codepoint]
      incr index 4
    } else {
      error "$label has an invalid JSON escape"
    }
  }
  return $decoded
}

proc rm1_json_string_field {text field label} {
  if {![regexp {^[A-Za-z][A-Za-z0-9]*$} $field]} {
    error "$label has an invalid requested JSON field name"
  }
  set pattern [format {"%s"[ \t\r\n]*:[ \t\r\n]*"((?:\\["\\/bfnrt]|\\u[0-9A-Fa-f]{4}|[^"\\])*)"} $field]
  set count [regexp -all -- $pattern $text]
  if {$count != 1 || ![regexp -- $pattern $text -> encoded]} {
    error "$label JSON string field cardinality mismatch: $field=$count/1"
  }
  return [rm1_json_decode_string $encoded "$label.$field"]
}

proc rm1_json_integer_field {text field label} {
  if {![regexp {^[A-Za-z][A-Za-z0-9]*$} $field]} {
    error "$label has an invalid requested JSON integer field name"
  }
  set pattern [format {"%s"[ \t\r\n]*:[ \t\r\n]*(-?(?:0|[1-9][0-9]*))[ \t\r\n]*[,\}]} $field]
  set count [regexp -all -- $pattern $text]
  if {$count != 1 || ![regexp -- $pattern $text -> value]} {
    error "$label JSON integer field cardinality mismatch: $field=$count/1"
  }
  return $value
}

proc rm1_binding_receipt_gate {path focused_sha affected_sha publication_sha} {
  global source_commit source_tree expected_branch expected_parent
  global focused_receipt affected_receipt publication_receipt
  set text [read_text $path]
  set values [dict create]
  foreach field {
      Task Result SourceCommit SourceTree Branch ExpectedParent
      DirectParentBinding AuthorizedChangedSetBinding
      FocusedReceipt FocusedReceiptSHA256 FocusedHashAfterBinding
      AffectedR3Receipt AffectedR3ReceiptSHA256 AffectedInputHashBinding
      PublicationReadbackReceipt PublicationReadbackReceiptSHA256
      RemoteRefReadback CommitPinnedBlobReadback FullVivadoBuildStarted
      HardwareAccessed} {
    dict set values $field [rm1_json_string_field $text $field RECEIPT_BINDING]
  }
  foreach pair [list \
      [list Task AHD_V41_G2B_NVP_DIAG2_RM1_PRE_VIVADO_RECEIPT_BINDING] \
      [list Result PASS] [list SourceCommit $source_commit] \
      [list SourceTree $source_tree] [list Branch $expected_branch] \
      [list ExpectedParent $expected_parent] [list DirectParentBinding PASS] \
      [list AuthorizedChangedSetBinding PASS] [list FocusedHashAfterBinding PASS] \
      [list AffectedInputHashBinding PASS] [list RemoteRefReadback PASS] \
      [list CommitPinnedBlobReadback PASS] [list FullVivadoBuildStarted NO] \
      [list HardwareAccessed NO]] {
    lassign $pair field expected
    if {[dict get $values $field] ne $expected} {
      error "RECEIPT_BINDING field mismatch: $field"
    }
  }
  foreach {field expected} {
      AuthorizedChangedSetFiles 11 FocusedHashAfterFiles 11
      AffectedInputHashFiles 11} {
    if {[rm1_json_integer_field $text $field RECEIPT_BINDING] != $expected} {
      error "RECEIPT_BINDING integer field mismatch: $field"
    }
  }
  set rows [list]
  foreach item [list \
      [list FOCUSED FocusedReceipt FocusedReceiptSHA256 $focused_receipt $focused_sha] \
      [list AFFECTED_R3 AffectedR3Receipt AffectedR3ReceiptSHA256 $affected_receipt $affected_sha] \
      [list PUBLICATION PublicationReadbackReceipt PublicationReadbackReceiptSHA256 \
        $publication_receipt $publication_sha]] {
    lassign $item name path_field sha_field current_path current_sha
    set recorded_path [dict get $values $path_field]
    set expected_path [file nativename $current_path]
    set recorded_sha [dict get $values $sha_field]
    if {$recorded_path ne $expected_path} {
      error "RECEIPT_BINDING exact path mismatch: $name"
    }
    if {![regexp {^[0-9A-F]{64}$} $recorded_sha] || $recorded_sha ne $current_sha} {
      error "RECEIPT_BINDING current SHA-256 mismatch: $name"
    }
    lappend rows "BINDING_${name}_PATH=$recorded_path" \
      "BINDING_${name}_SHA256=$recorded_sha" "BINDING_${name}_CURRENT=PASS"
  }
  return $rows
}

proc rm1_pre_vivado_seal_gate {} {
  global pre_vivado_seal expected_pre_vivado_seal_sha
  global focused_receipt affected_receipt binding_receipt publication_receipt
  global expected_focused_sha expected_affected_sha expected_binding_sha
  global expected_publication_sha donor_build_tcl expected_donor_sha build_script_path
  if {![file isfile $pre_vivado_seal] ||
      [sha256_file $pre_vivado_seal] ne $expected_pre_vivado_seal_sha} {
    error "launcher pre-Vivado seal SHA-256 mismatch"
  }
  set harness_root [file dirname $build_script_path]
  set expected_paths [dict create \
    FOCUSED_RECEIPT $focused_receipt \
    AFFECTED_R3_RECEIPT $affected_receipt \
    RECEIPT_BINDING $binding_receipt \
    PUBLICATION_READBACK_RECEIPT $publication_receipt \
    R3_DONOR_BUILD_TCL $donor_build_tcl]
  foreach {label name} {
      BUILD_HARNESS g2b_nvp_diag2_rm1_build.tcl
      FINALIZER g2b_nvp_diag2_rm1_finalize.tcl
      LAUNCHER invoke_rm1_one_shot_build.ps1
      BINDER bind_rm1_receipts_to_source.ps1
      AFFECTED_RUNNER run_rm1_affected_regressions.ps1
      STATIC_CHECKER check_rm1_build_harness.ps1
      TCL_SYNTAX_CHECKER check_rm1_harness_syntax.tcl
      PUBLICATION_SCHEMA RM1_PUBLICATION_READBACK_RECEIPT_SCHEMA.json
      README RM1_BUILD_HARNESS_README.md} {
    dict set expected_paths $label [file normalize [file join $harness_root $name]]
  }
  set expected_receipt_hashes [dict create \
    FOCUSED_RECEIPT $expected_focused_sha \
    AFFECTED_R3_RECEIPT $expected_affected_sha \
    RECEIPT_BINDING $expected_binding_sha \
    PUBLICATION_READBACK_RECEIPT $expected_publication_sha \
    R3_DONOR_BUILD_TCL $expected_donor_sha]
  set observed [dict create]
  set observed_casefold_paths [dict create]
  set rows [list]
  foreach raw_line [split [read_text $pre_vivado_seal] "\n"] {
    set line [string trimright $raw_line "\r"]
    if {$line eq ""} { continue }
    set fields [split $line |]
    if {[llength $fields] != 3} { error "malformed launcher pre-Vivado seal row" }
    lassign $fields label recorded_path recorded_sha
    if {![dict exists $expected_paths $label] || [dict exists $observed $label]} {
      error "unexpected/duplicate launcher pre-Vivado seal label: $label"
    }
    set normalized_expected_path [file normalize [dict get $expected_paths $label]]
    set casefold_path [string tolower $normalized_expected_path]
    if {[dict exists $observed_casefold_paths $casefold_path]} {
      error "launcher pre-Vivado seal case-alias/duplicate path: $label"
    }
    dict set observed_casefold_paths $casefold_path $label
    set expected_path [file nativename $normalized_expected_path]
    if {$recorded_path ne $expected_path} {
      error "launcher pre-Vivado seal path mismatch: $label"
    }
    if {![regexp {^[0-9A-F]{64}$} $recorded_sha]} {
      error "launcher pre-Vivado seal SHA format mismatch: $label"
    }
    if {![file isfile [dict get $expected_paths $label]]} {
      error "launcher pre-Vivado sealed input missing: $label"
    }
    if {[sha256_file [dict get $expected_paths $label]] ne $recorded_sha} {
      error "launcher pre-Vivado seal current SHA mismatch: $label"
    }
    if {[dict exists $expected_receipt_hashes $label] &&
        [dict get $expected_receipt_hashes $label] ne $recorded_sha} {
      error "launcher expected receipt SHA mismatch: $label"
    }
    dict set observed $label 1
    lappend rows "PRE_VIVADO_SEAL=$label|$recorded_path|$recorded_sha"
  }
  if {[dict size $expected_paths] != 14 || [dict size $observed] != 14 ||
      [dict size $observed_casefold_paths] != 14} {
    error "launcher pre-Vivado seal set mismatch: [dict size $observed]/14"
  }
  dict for {label expected_path} $expected_paths {
    if {![dict exists $observed $label]} {
      error "launcher pre-Vivado seal label missing: $label"
    }
  }
  return [lsort -ascii $rows]
}

proc rm1_profile_cells {instance_pattern ref_pattern} {
  set matches [dict create]
  foreach cell [get_cells -quiet -hier] {
    set name [get_property NAME $cell]
    set ref [property_or_unknown REF_NAME $cell]
    if {[regexp -- $instance_pattern $name] || [regexp -- $ref_pattern $ref]} {
      dict set matches $name $cell
    }
  }
  return [dict values $matches]
}

proc rm1_cell_inventory {path label objects} {
  set rows [list "LABEL=$label" "COUNT=[llength $objects]"]
  foreach object [lsort -command {apply {{a b} {
      return [string compare [get_property NAME $a] [get_property NAME $b]]
    }}} $objects] {
    lappend rows "CELL=[get_property NAME $object]|REF_NAME=[property_or_unknown REF_NAME $object]"
  }
  write_lines $path $rows
}

proc rm1_profile_gate {stage} {
  global evidence_root
  set wrapper [rm1_profile_cells {(^|[/.])NVP_DIAG2_RM1_CORE($|[/.])} {^g2b_nvp_video_diag2_rm1($|_)}]
  set route [rm1_profile_cells {(^|[/.])RM1_ROUTE_CONTROLLER($|[/.])} {^g2b_nvp_rm1_route_controller($|_)}]
  set monitor [rm1_profile_cells {(^|[/.])RM1_RAW_MARKER_MONITOR($|[/.])} {^g2b_nvp_raw_marker_monitor($|_)}]
  set fixed_i2c [rm1_profile_cells {(^|[/.])NVP_VIDEO_DIAG_I2C_MASTER($|[/.])} {^nvp_i2c_fixed_master($|_)}]
  set bram [rm1_profile_cells {RM1_SNAPSHOT_RAM} {^RAMB(18|36)E1$}]
  set r3 [rm1_profile_cells {(^|[/.])NVP_VIDEO_DIAG_CORE($|[/.])} {^g2b_nvp_video_diag($|_)}]
  set tri [rm1_profile_cells {POST_INIT_TRI_PHASE_PROBE} {^nvp_i2c_tri_phase_probe($|_)}]
  set history [rm1_profile_cells {R1F_FAILED_TXN_LOGGER|R1H_MMIO_READ_SERVICE|LIFECYCLE_MONITOR} {^(v41_r1f_failed_txn_logger|v41_r1h_mmio_read_service|v41_axi_clock_lifecycle_monitor)($|_)}]
  set forbidden [rm1_profile_cells {SCAN1|ACQ1|MODE1|BGDCOL.*(HISTORY|SESSION)} {^(g2b_nvp_camera_scan|g2b_nvp_camera_acq|g2b_nvp_camera_mode1)($|_)}]

  # A rebuilt hierarchy may absorb a module boundary.  Unique internal state
  # inventories are the secondary proof that each required RM1 unit remains.
  set route_state [get_cells -quiet -hier -regexp {.*RM1_ROUTE_CONTROLLER/.*state.*_reg.*}]
  set monitor_state [get_cells -quiet -hier -regexp {.*RM1_RAW_MARKER_MONITOR/.*state.*_reg.*}]
  set bram_primitives [get_cells -quiet -hier -regexp {.*RM1_SNAPSHOT_RAM.*} -filter {REF_NAME =~ RAMB*}]
  set wrapper_ok [expr {[llength $wrapper] > 0 || ([llength $route_state] > 0 && [llength $monitor_state] > 0)}]
  set route_ok [expr {[llength $route] > 0 || [llength $route_state] > 0}]
  set monitor_ok [expr {[llength $monitor] > 0 || [llength $monitor_state] > 0}]
  set bram_ok [expr {[llength $bram_primitives] == 1}]
  set fixed_ok [expr {[llength $fixed_i2c] > 0}]
  set absent_ok [expr {[llength $r3] == 0 && [llength $tri] == 0 &&
                       [llength $history] == 0 && [llength $forbidden] == 0}]
  set result [expr {$wrapper_ok && $route_ok && $monitor_ok && $bram_ok &&
                    $fixed_ok && $absent_ok ? {PASS} : {FAIL}}]
  set receipt [file join $evidence_root "${stage}_RM1_PROFILE_ELABORATION.txt"]
  write_lines $receipt [list \
    "STAGE=$stage" {PROFILE=ENABLE_NVP_VIDEO_DIAG2_RM1} \
    {ENABLE_NVP_VIDEO_DIAG2_RM1=1} {ENABLE_NVP_VIDEO_DIAGNOSTIC=0} \
    {ENABLE_RTRACK_DIAGNOSTICS=0} \
    "RM1_WRAPPER_BOUNDARY_COUNT=[llength $wrapper]" \
    "RM1_ROUTE_BOUNDARY_COUNT=[llength $route]" \
    "RM1_MONITOR_BOUNDARY_COUNT=[llength $monitor]" \
    "RM1_ROUTE_STATE_COUNT=[llength $route_state]" \
    "RM1_MONITOR_STATE_COUNT=[llength $monitor_state]" \
    "RM1_SNAPSHOT_BRAM_PRIMITIVE_COUNT=[llength $bram_primitives]" \
    "FIXED_I2C_MASTER_COUNT=[llength $fixed_i2c]" \
    "R3_CORE_COUNT=[llength $r3]" \
    "RTRACK_TRI_PROBE_COUNT=[llength $tri]" \
    "RTRACK_HISTORY_COUNT=[llength $history]" \
    "SCAN1_ACQ1_MODE1_BGDCOL_HISTORY_COUNT=[llength $forbidden]" \
    {GENERIC_HOST_NVP_I2C_COUNT=0_BY_SOURCE_CONTRACT} \
    "PROFILE_ELABORATION_GATE=$result"]
  rm1_cell_inventory [file join $evidence_root "${stage}_RM1_REQUIRED_CELLS.txt"] REQUIRED_RM1 \
    [concat $wrapper $route $monitor $fixed_i2c $bram_primitives]
  if {$result ne "PASS"} { error "RM1 profile elaboration gate failed at $stage" }
}

proc rm1_resource_gate {stage} {
  global evidence_root lut_hard_max lut_preferred_max
  set metrics [resource_metrics $stage]
  set lut_used_raw [dict get $metrics LUT_USED]
  set lut_available_raw [dict get $metrics LUT_AVAILABLE]
  set lut_used [expr {wide(round($lut_used_raw))}]
  set lut_available [expr {wide(round($lut_available_raw))}]
  if {abs($lut_used_raw - $lut_used) > 0.000001 ||
      abs($lut_available_raw - $lut_available) > 0.000001} {
    error "$stage LUT counts are not integral"
  }
  set ff_percent [dict get $metrics FF_PERCENT]
  set bram_percent [dict get $metrics BRAM_PERCENT]
  set dsp_percent [dict get $metrics DSP_PERCENT]
  set hard_pass [expr {$lut_available == 20800 && $lut_used <= $lut_hard_max &&
                       $ff_percent <= 95.0 && $bram_percent <= 90.0 &&
                       $dsp_percent <= 90.0}]
  set preferred [expr {$lut_used <= $lut_preferred_max ? {PASS} : {ADVISORY_MISS}}]
  write_lines [file join $evidence_root "${stage}_RM1_RESOURCE_GATE.txt"] [list \
    "STAGE=$stage" "LUT_USED=$lut_used" "LUT_AVAILABLE=$lut_available" \
    "LUT_PERCENT=[format %.3f [dict get $metrics LUT_PERCENT]]" \
    "LUT_HARD_MAX=$lut_hard_max" {LUT_HARD_LIMIT_PERCENT=98.000} \
    "LUT_PREFERRED_MAX=$lut_preferred_max" {LUT_PREFERRED_LIMIT_PERCENT=95.000} \
    "LUT_PREFERRED_GATE=$preferred" \
    "FF_PERCENT=[format %.3f $ff_percent]" {FF_LIMIT_PERCENT=95.000} \
    "BRAM_PERCENT=[format %.3f $bram_percent]" {BRAM_LIMIT_PERCENT=90.000} \
    "DSP_PERCENT=[format %.3f $dsp_percent]" {DSP_LIMIT_PERCENT=90.000} \
    "RESOURCE_GATE=[expr {$hard_pass ? {PASS} : {FAIL}}]"]
  if {!$hard_pass} { error "$stage RM1 resource hard gate failed" }
  return $metrics
}

proc rm1_violation_blob {violation} {
  set parts [list]
  foreach property [list_property $violation] {
    if {[catch {get_property $property $violation} value]} { continue }
    lappend parts "$property=$value"
  }
  return [string toupper [join $parts {|}]]
}

proc rm1_protocol_endpoint_leaf {value} {
  set normalized [string toupper [string trim $value " {}\t\r\n"]]
  if {[regexp {(^|/)RM1_RAW_MARKER_MONITOR/([^/]+/[A-Z0-9_]+)$} \
      $normalized -> prefix leaf]} {
    return $leaf
  }
  return UNKNOWN
}

proc rm1_expected_cdc_protocol {} {
  set expected [dict create]
  foreach pair {
    {CLEAR_TOGGLE_AXI_REG/C CLEAR_SYNC1_SOURCE_REG/D}
    {ARM_TOGGLE_AXI_REG/C ARM_SYNC1_SOURCE_REG/D}
    {FREEZE_TOGGLE_AXI_REG/C FREEZE_SYNC1_SOURCE_REG/D}
    {FREEZE_MANUAL_TOGGLE_AXI_REG/C FREEZE_MANUAL_SYNC1_SOURCE_REG/D}
    {ACK_TOGGLE_AXI_REG/C ACK_SYNC1_SOURCE_REG/D}
    {ABORT_EPOCH_TOGGLE_AXI_REG/C ABORT_EPOCH_SYNC1_SOURCE_REG/D}
    {ARMED_SOURCE_REG/C ARMED_SYNC1_AXI_REG/D}
    {DONE_TOGGLE_SOURCE_REG/C DONE_SYNC1_AXI_REG/D}
    {SNAPSHOT_VALID_SOURCE_REG/C VALID_SYNC1_AXI_REG/D}
    {TRACE_OVERFLOW_SOURCE_REG/C OVERFLOW_SYNC1_AXI_REG/D}
    {ACK_DONE_TOGGLE_SOURCE_REG/C ACK_DONE_SYNC1_AXI_REG/D}
    {ABORT_ACK_TOGGLE_SOURCE_REG/C ABORT_ACK_SYNC1_AXI_REG/D}
  } {
    lassign $pair source destination
    dict set expected "CDC-3|INFO|FALSE PATH|$source|$destination" 1
  }
  for {set bit 0} {$bit < 16} {incr bit} {
    dict set expected "CDC-15|WARNING|FALSE PATH|ARM_SESSION_HOLD_AXI_REG\[$bit\]/C|SESSION_SOURCE_REG\[$bit\]/D" 1
  }
  for {set bit 0} {$bit < 3} {incr bit} {
    dict set expected "CDC-15|WARNING|FALSE PATH|ARM_ROUTE_HOLD_AXI_REG\[$bit\]/C|ROUTE_SOURCE_REG\[$bit\]/D" 1
  }
  for {set bit 0} {$bit < 2} {incr bit} {
    dict set expected "CDC-15|WARNING|FALSE PATH|ARM_WINDOW_HOLD_AXI_REG\[$bit\]/C|WINDOW_SOURCE_REG\[$bit\]/D" 1
  }
  if {[dict size $expected] != 33} { error "internal RM1 CDC allowlist size mismatch" }
  return $expected
}

proc rm1_expected_xdc_destinations {} {
  set expected [dict create]
  foreach destination {
    CLEAR_SYNC1_SOURCE_REG/D ARM_SYNC1_SOURCE_REG/D
    FREEZE_SYNC1_SOURCE_REG/D FREEZE_MANUAL_SYNC1_SOURCE_REG/D
    ACK_SYNC1_SOURCE_REG/D ABORT_EPOCH_SYNC1_SOURCE_REG/D
    ARMED_SYNC1_AXI_REG/D DONE_SYNC1_AXI_REG/D VALID_SYNC1_AXI_REG/D
    OVERFLOW_SYNC1_AXI_REG/D ACK_DONE_SYNC1_AXI_REG/D
    ABORT_ACK_SYNC1_AXI_REG/D
  } {
    dict set expected $destination 1
  }
  for {set bit 0} {$bit < 16} {incr bit} {
    dict set expected "SESSION_SOURCE_REG\[$bit\]/D" 1
  }
  for {set bit 0} {$bit < 3} {incr bit} {
    dict set expected "ROUTE_SOURCE_REG\[$bit\]/D" 1
  }
  for {set bit 0} {$bit < 2} {incr bit} {
    dict set expected "WINDOW_SOURCE_REG\[$bit\]/D" 1
  }
  if {[dict size $expected] != 33} {
    error "internal RM1 XDC destination set size mismatch"
  }
  return $expected
}

proc rm1_xdc_destination_pin_gate {} {
  set sync1_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/(clear_sync1_source|arm_sync1_source|freeze_sync1_source|freeze_manual_sync1_source|ack_sync1_source|abort_epoch_sync1_source|armed_sync1_axi|done_sync1_axi|valid_sync1_axi|overflow_sync1_axi|ack_done_sync1_axi|abort_ack_sync1_axi)_reg}]
  set session_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/session_source_reg\[[0-9]+\]}]
  set route_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/route_source_reg\[[0-9]+\]}]
  set window_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/window_source_reg\[[0-9]+\]}]
  set mailbox_cells [concat $session_cells $route_cells $window_cells]
  set sync1_d_resolved [get_pins -quiet -of_objects $sync1_cells \
    -filter {REF_PIN_NAME == D}]
  set mailbox_d_resolved [get_pins -quiet -of_objects $mailbox_cells \
    -filter {REF_PIN_NAME == D}]
  if {[llength $sync1_cells] != 12 || [llength $sync1_d_resolved] != 12 ||
      [llength $session_cells] != 16 || [llength $route_cells] != 3 ||
      [llength $window_cells] != 2 || [llength $mailbox_cells] != 21 ||
      [llength $mailbox_d_resolved] != 21} {
    error "RM1 XDC resolved cell/D-pin collections are not exact 12+21"
  }
  set expected_destinations [rm1_expected_xdc_destinations]
  set sync_cell_names [dict create]
  foreach cell $sync1_cells {
    set cell_name [get_property NAME $cell]
    if {[dict exists $sync_cell_names $cell_name]} {
      error "duplicate RM1 XDC synchronizer cell: $cell_name"
    }
    dict set sync_cell_names $cell_name 1
  }
  set mailbox_cell_names [dict create]
  foreach cell $mailbox_cells {
    set cell_name [get_property NAME $cell]
    if {[dict exists $mailbox_cell_names $cell_name]} {
      error "duplicate RM1 XDC mailbox cell: $cell_name"
    }
    dict set mailbox_cell_names $cell_name 1
  }
  set observed [dict create]
  set observed_cells [dict create]
  set rows [list]
  foreach pin [concat $sync1_d_resolved $mailbox_d_resolved] {
    set pin_name [get_property NAME $pin]
    set destination [rm1_protocol_endpoint_leaf $pin_name]
    if {$destination eq "UNKNOWN" || ![dict exists $expected_destinations $destination] ||
        [dict exists $observed $destination]} {
      error "unexpected/duplicate RM1 XDC destination pin: $pin_name"
    }
    set parent_cells [get_cells -quiet -of_objects $pin]
    if {[llength $parent_cells] != 1} {
      error "RM1 XDC destination parent-cell count != 1: $pin_name"
    }
    set cell_name [get_property NAME [lindex $parent_cells 0]]
    if {[dict exists $observed_cells $cell_name]} {
      error "duplicate RM1 XDC destination cell: $cell_name"
    }
    set mailbox [regexp {^(SESSION_SOURCE_REG\[[0-9]+\]|ROUTE_SOURCE_REG\[[0-9]+\]|WINDOW_SOURCE_REG\[[0-9]+\])/D$} $destination]
    if {($mailbox && ![dict exists $mailbox_cell_names $cell_name]) ||
        (!$mailbox && ![dict exists $sync_cell_names $cell_name])} {
      error "RM1 XDC destination pin/cell collection mismatch: $pin_name"
    }
    dict set observed $destination 1
    dict set observed_cells $cell_name 1
    lappend rows "RM1_XDC_DESTINATION=$destination|PIN=$pin_name|CELL=$cell_name"
  }
  if {[dict size $expected_destinations] != 33 || [dict size $observed] != 33 ||
      [dict size $observed_cells] != 33 || [dict size $sync_cell_names] != 12 ||
      [dict size $mailbox_cell_names] != 21} {
    error "RM1 XDC resolved destination set mismatch: pins=[dict size $observed]/33 cells=[dict size $observed_cells]/33 sync=[dict size $sync_cell_names]/12 mailbox=[dict size $mailbox_cell_names]/21"
  }
  dict for {destination count} $expected_destinations {
    if {![dict exists $observed $destination]} {
      error "missing RM1 XDC destination pin: $destination"
    }
  }
  lappend rows {RM1_XDC_SYNC1_CELLS=12/12} {RM1_XDC_SYNC1_D_PINS=12/12} \
    {RM1_XDC_MAILBOX_CELLS=21/21} {RM1_XDC_MAILBOX_D_PINS=21/21}
  return [lsort -ascii $rows]
}

proc rm1_cdc_gate {} {
  global evidence_root
  set path [file join $evidence_root CDC.rpt]
  report_cdc -details -file $path
  set violations [get_cdc_violations -quiet]
  set legacy_counts [dict create]
  set expected_protocol [rm1_expected_cdc_protocol]
  set xdc_destination_rows [rm1_xdc_destination_pin_gate]
  set observed_protocol [dict create]
  set rm1_total 0
  set rm1_unmatched 0
  set rm1_info 0
  set rm1_warning 0
  set rm1_unresolved_critical 0
  set rm1_unresolved_warning 0
  set unknown 0
  set rows [list]
  foreach xdc_row $xdc_destination_rows { lappend rows $xdc_row }
  foreach violation $violations {
    set name [get_property NAME $violation]
    set rule [lindex [split $name #] 0]
    set severity [string toupper [property_or_unknown SEVERITY $violation]]
    set exception [string toupper [property_or_unknown EXCEPTION $violation]]
    set source_raw [property_or_unknown STARTPOINT_PIN $violation]
    set destination_raw [property_or_unknown ENDPOINT_PIN $violation]
    set source [rm1_protocol_endpoint_leaf $source_raw]
    set destination [rm1_protocol_endpoint_leaf $destination_raw]
    set blob [rm1_violation_blob $violation]
    if {$severity eq "UNKNOWN"} { incr unknown }
    if {$source ne "UNKNOWN" || $destination ne "UNKNOWN" ||
        [string first RM1_RAW_MARKER_MONITOR $blob] >= 0} {
      incr rm1_total
      if {$severity eq "INFO"} { incr rm1_info }
      if {$severity eq "WARNING"} { incr rm1_warning }
      set key "$rule|$severity|$exception|$source|$destination"
      set disposed [dict exists $expected_protocol $key]
      if {$disposed} {
        dict incr observed_protocol $key
      } else {
        incr rm1_unmatched
        if {$severity in {CRITICAL {CRITICAL WARNING} ERROR}} { incr rm1_unresolved_critical }
        if {$severity eq "WARNING"} { incr rm1_unresolved_warning }
      }
      lappend rows "RM1|$name|RULE=$rule|SEVERITY=$severity|EXCEPTION=$exception|STARTPOINT_PIN=$source_raw|ENDPOINT_PIN=$destination_raw|SOURCE=$source|DESTINATION=$destination|DISPOSITION=[expr {$disposed ? {EXACT_PROTOCOL_CANDIDATE} : {UNRESOLVED}}]"
    } else {
      dict incr legacy_counts "$severity|$rule"
      lappend rows "INHERITED|$name|SEVERITY=$severity"
    }
  }
  # R3 warning/critical rule populations remain an exact inherited boundary.
  set expected [dict create \
    "CRITICAL|CDC-1" 423 "CRITICAL|CDC-10" 2 "CRITICAL|CDC-13" 2 \
    "WARNING|CDC-6" 13 "WARNING|CDC-15" 861]
  set inherited_ok 1
  dict for {key value} $legacy_counts {
    if {$key ni [dict keys $expected] &&
        ([string match {CRITICAL*|*} $key] || [string match {WARNING|*} $key])} {
      set inherited_ok 0
    }
  }
  dict for {key value} $expected {
    set actual [expr {[dict exists $legacy_counts $key] ? [dict get $legacy_counts $key] : 0}]
    if {$actual != $value} { set inherited_ok 0 }
    lappend rows "INHERITED_EXPECTED=$key|EXPECTED=$value|ACTUAL=$actual"
  }
  set protocol_mismatches 0
  set false_path_destination_pins 0
  dict for {key expected_count} $expected_protocol {
    set actual [expr {[dict exists $observed_protocol $key] ? [dict get $observed_protocol $key] : 0}]
    if {$actual != $expected_count} { incr protocol_mismatches }
    if {$actual == 1 && [lindex [split $key |] 2] eq "FALSE PATH"} {
      incr false_path_destination_pins
    }
    lappend rows "RM1_EXPECTED=$key|EXPECTED=$expected_count|ACTUAL=$actual|DISPOSITION=[expr {$actual == $expected_count ? {EXACT_PROTOCOL} : {UNRESOLVED}}]"
  }
  set sync1_cells [get_cells -quiet -hier -regexp \
    {.*RM1_RAW_MARKER_MONITOR/(clear_sync1_source|arm_sync1_source|freeze_sync1_source|freeze_manual_sync1_source|ack_sync1_source|abort_epoch_sync1_source|armed_sync1_axi|done_sync1_axi|valid_sync1_axi|overflow_sync1_axi|ack_done_sync1_axi|abort_ack_sync1_axi)_reg}]
  set async_ok [expr {[llength $sync1_cells] == 12}]
  foreach cell $sync1_cells {
    if {[string toupper [property_or_unknown ASYNC_REG $cell]] ni {TRUE 1}} {
      set async_ok 0
    }
  }
  set rm1_unresolved [expr {$rm1_unmatched + $protocol_mismatches}]
  set result [expr {$unknown == 0 && $rm1_total == 33 && $rm1_info == 12 &&
                    $rm1_warning == 21 && $rm1_unresolved == 0 &&
                    $false_path_destination_pins == 33 &&
                    $rm1_unresolved_critical == 0 && $rm1_unresolved_warning == 0 &&
                    $inherited_ok && $async_ok ? {PASS} : {FAIL}}]
  lappend rows "RM1_CDC_FINDINGS=$rm1_total/33" {RM1_CDC3_INFO=12_REQUIRED} \
    "RM1_CDC3_INFO_ACTUAL=$rm1_info" {RM1_CDC15_WARNING=21_REQUIRED} \
    "RM1_CDC15_WARNING_ACTUAL=$rm1_warning" "RM1_UNRESOLVED_CDC=$rm1_unresolved" \
    "RM1_FALSE_PATH_DESTINATION_PINS=$false_path_destination_pins/33" \
    {RM1_XDC_DESTINATION_PINS=33/33} \
    "INHERITED_R3_RULE_POPULATION=[expr {$inherited_ok ? {PASS} : {FAIL}}]" \
    "RM1_ASYNC_REG_FIRST_STAGES=[llength $sync1_cells]/12" \
    "RM1_ASYNC_REG_GATE=[expr {$async_ok ? {PASS} : {FAIL}}]" \
    "UNKNOWN_CDC=$unknown" "NEW_UNRESOLVED_CRITICAL_CDC=$rm1_unresolved_critical" \
    "NEW_UNRESOLVED_WARNING_CDC=$rm1_unresolved_warning" "CDC_GATE=$result"
  write_lines [file join $evidence_root G2B_NVP_DIAG2_RM1_CDC_GATE.txt] $rows
  if {$result ne "PASS"} { error "RM1 CDC gate failed" }
  return $rm1_total
}

proc rm1_drc_methodology_gate {} {
  global evidence_root
  set outputs [list]
  foreach label {DRC METHODOLOGY} {
    set path [file join $evidence_root "${label}.rpt"]
    if {$label eq "DRC"} {
      report_drc -file $path
      set violations [get_drc_violations -quiet]
    } else {
      report_methodology -file $path
      set violations [get_methodology_violations -quiet]
    }
    set errors 0
    set critical 0
    set warnings 0
    set advisory 0
    set informational 0
    set unknown_or_unrecognized 0
    foreach violation $violations {
      set severity [string toupper [property_or_unknown SEVERITY $violation]]
      switch -- $severity {
        ERROR { incr errors }
        "CRITICAL WARNING" - CRITICAL { incr critical }
        WARNING { incr warnings }
        ADVISORY { incr advisory }
        INFO - INFORMATION { incr informational }
        default { incr unknown_or_unrecognized }
      }
    }
    set result [expr {$errors == 0 && $critical == 0 &&
                      $unknown_or_unrecognized == 0 ? {PASS} : {FAIL}}]
    write_lines [file join $evidence_root "G2B_NVP_DIAG2_RM1_${label}_GATE.txt"] [list \
      "${label}_ERRORS=$errors" "${label}_CRITICAL_WARNINGS=$critical" \
      "${label}_WARNINGS=$warnings" "${label}_ADVISORIES=$advisory" \
      "${label}_INFORMATIONAL=$informational" \
      "${label}_UNKNOWN_OR_UNRECOGNIZED_SEVERITY=$unknown_or_unrecognized" \
      "${label}_GATE=$result"]
    if {$result ne "PASS"} { error "$label hard gate failed" }
    lappend outputs $warnings
  }
  return $outputs
}

proc rm1_expected_check_timing_counts {} {
  return [dict create \
    no_clock 0 constant_clock 0 pulse_width_clock 2 \
    unconstrained_internal_endpoints 0 no_input_delay 0 no_output_delay 0 \
    multiple_clock 0 generated_clocks 0 loops 0 partial_input_delay 0 \
    partial_output_delay 0 latch_loops 0]
}

proc rm1_parse_check_timing_counts {text label} {
  set expected [rm1_expected_check_timing_counts]
  set observed [dict create]
  foreach raw_line [split $text "\n"] {
    set line [string trimright $raw_line "\r"]
    if {[regexp {^[ \t]*[0-9]+\.[ \t]+checking[ \t]+([a-z_]+)[ \t]+\(([0-9]+)\)[ \t]*$} \
        $line -> category count]} {
      dict lappend observed $category $count
    }
  }
  if {[dict size $observed] != [dict size $expected]} {
    error "$label check_timing category set mismatch"
  }
  dict for {category values} $observed {
    if {![dict exists $expected $category]} {
      error "$label unexpected check_timing category: $category"
    }
    if {[llength $values] != 2 || [lindex $values 0] ne [lindex $values 1] ||
        ![string is integer -strict [lindex $values 0]]} {
      error "$label check_timing count is not duplicated/consistent: $category=$values"
    }
  }
  set result [dict create]
  dict for {category wanted} $expected {
    if {![dict exists $observed $category]} {
      error "$label missing check_timing category: $category"
    }
    set actual [lindex [dict get $observed $category] 0]
    if {$actual != $wanted} {
      error "$label check_timing count mismatch: $category expected=$wanted actual=$actual"
    }
    dict set result $category $actual
  }
  return $result
}

proc rm1_unconstrained_path_table {text label} {
  set lines [split $text "\n"]
  set markers [list]
  for {set index 0} {$index < [llength $lines]} {incr index} {
    if {[string trim [string trimright [lindex $lines $index] "\r"]] eq
        {| Unconstrained Path Table}} {
      lappend markers $index
    }
  }
  if {[llength $markers] != 1} { error "$label unconstrained table section count != 1" }
  set header_index -1
  set from_index -1
  set to_index -1
  for {set index [expr {[lindex $markers 0] + 1}]} {$index < [llength $lines]} {incr index} {
    set line [string trimright [lindex $lines $index] "\r"]
    if {[regexp {^[ \t]*Path Group[ \t]+From Clock[ \t]+To Clock[ \t]*$} $line]} {
      set header_index $index
      set from_index [string first {From Clock} $line]
      set to_index [string first {To Clock} $line]
      break
    }
    if {$index > [lindex $markers 0] + 20} { break }
  }
  if {$header_index < 0 || $from_index <= 0 || $to_index <= $from_index} {
    error "$label unconstrained table header missing or malformed"
  }
  set rows [list]
  for {set index [expr {$header_index + 1}]} {$index < [llength $lines]} {incr index} {
    set line [string trimright [lindex $lines $index] "\r"]
    set trimmed [string trim $line]
    if {$trimmed eq ""} { continue }
    set compact [string map [list " " "" "\t" ""] $trimmed]
    if {[regexp {^-+$} $compact]} {
      if {[string length $compact] >= 40 && [llength $rows] > 0} { break }
      continue
    }
    if {[string index $trimmed 0] eq {|}} { break }
    set group [string trim [string range $line 0 [expr {$from_index - 1}]]]
    set from [string trim [string range $line $from_index [expr {$to_index - 1}]]]
    set to [string trim [string range $line $to_index end]]
    if {$group ne {(none)}} { error "$label unexpected unconstrained path group row: $line" }
    lappend rows "$group|$from|$to"
  }
  set rows [lsort -ascii $rows]
  if {[llength $rows] != 0} {
    error "$label raw unconstrained path table is not empty: $rows"
  }
  return $rows
}

proc rm1_unconstrained_gate {timing_path check_path receipt_path label} {
  set timing_text [read_text $timing_path]
  set check_text [read_text $check_path]
  set timing_counts [rm1_parse_check_timing_counts $timing_text "$label timing-summary"]
  set check_counts [rm1_parse_check_timing_counts $check_text "$label standalone"]
  if {$timing_counts ne $check_counts} { error "$label embedded/standalone check_timing mismatch" }
  set table_rows [rm1_unconstrained_path_table $timing_text $label]
  set rows [list "LABEL=$label" {REPORT_UNCONSTRAINED_OPTION=REQUIRED_AND_PRESENT}]
  dict for {category count} $timing_counts {
    lappend rows "CHECK_TIMING_$category=$count"
  }
  lappend rows \
    "RAW_NO_INPUT_DELAY=[dict get $timing_counts no_input_delay]" \
    "RAW_NO_OUTPUT_DELAY=[dict get $timing_counts no_output_delay]" \
    "RAW_UNCONSTRAINED_PATH_TABLE_ROWS=[llength $table_rows]" \
    {RAW_UNCONSTRAINED_ENDPOINTS=0} {UNCONSTRAINED_ENDPOINTS=0} \
    {UNCONSTRAINED_GATE=PASS}
  write_lines $receipt_path $rows
  return [dict create RAW_TABLE_ROWS [llength $table_rows] RAW_ENDPOINTS 0]
}

proc rm1_timing_route_gate {} {
  global evidence_root
  set timing_path [file join $evidence_root TIMING_SUMMARY.rpt]
  set check_path [file join $evidence_root CHECK_TIMING.rpt]
  set route_path [file join $evidence_root ROUTE_STATUS.rpt]
  report_timing_summary -delay_type min_max -check_timing_verbose \
    -report_unconstrained -max_paths 100 -nworst 1 -file $timing_path
  report_timing -delay_type max -max_paths 100 -nworst 1 \
    -file [file join $evidence_root ROUTED_SETUP_TIMING.rpt]
  report_timing -delay_type min -max_paths 100 -nworst 1 \
    -file [file join $evidence_root ROUTED_HOLD_TIMING.rpt]
  check_timing -verbose -file $check_path
  report_route_status -file $route_path
  set wns [routed_worst_slack max]
  set whs [routed_worst_slack min]
  set failing_setup [llength [get_timing_paths -quiet -delay_type max -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set failing_hold [llength [get_timing_paths -quiet -delay_type min -slack_lesser_than 0.0 -max_paths 1 -nworst 1]]
  set tns [expr {$failing_setup == 0 ? 0.0 : -1.0}]
  set ths [expr {$failing_hold == 0 ? 0.0 : -1.0}]
  set unconstrained [rm1_unconstrained_gate $timing_path $check_path \
    [file join $evidence_root G2B_NVP_DIAG2_RM1_UNCONSTRAINED_GATE.txt] BUILD]
  set fully [report_route_status -boolean_check ROUTED_FULLY]
  set route_errors [report_route_status -boolean_check ERRORS_IN_ROUTES]
  set unrouted [llength [report_route_status -return_nets -route_type UNROUTED]]
  set partial [llength [report_route_status -return_nets -route_type PARTIAL]]
  set result [expr {$fully && !$route_errors && $unrouted == 0 && $partial == 0 &&
                     $wns >= 0.0 && $whs >= 0.0 && $failing_setup == 0 &&
                    $failing_hold == 0 && [dict get $unconstrained RAW_ENDPOINTS] == 0 ? {PASS} : {FAIL}}]
  write_lines [file join $evidence_root G2B_NVP_DIAG2_RM1_TIMING_ROUTE_GATE.txt] [list \
    "FULLY_ROUTED=$fully" "ERRORS_IN_ROUTES=$route_errors" \
    "UNROUTED_NETS=$unrouted" "PARTIAL_NETS=$partial" \
    "WNS=[format %.3f $wns]" "TNS=[format %.3f $tns]" \
    "WHS=[format %.3f $whs]" "THS=[format %.3f $ths]" \
    "RAW_UNCONSTRAINED_PATH_TABLE_ROWS=[dict get $unconstrained RAW_TABLE_ROWS]" \
    "RAW_UNCONSTRAINED_ENDPOINTS=[dict get $unconstrained RAW_ENDPOINTS]" \
    "TIMING_ROUTE_GATE=$result"]
  if {$result ne "PASS"} { error "RM1 timing/route gate failed" }
  return [list $wns $tns $whs $ths [dict get $unconstrained RAW_TABLE_ROWS]]
}

if {![file isdirectory $repo_root]} { error "REPO_ROOT is not a directory" }
foreach path [list $build_root $evidence_root] {
  if {[file exists $path]} { error "fresh output required: $path" }
}
if {[string first [string tolower "$repo_root/"] [string tolower "$build_root/"]] == 0 ||
    [string first [string tolower "$repo_root/"] [string tolower "$evidence_root/"]] == 0} {
  error "build/evidence roots must be outside repository"
}
if {![regexp {^[0-9a-f]{40}$} $source_commit] || ![regexp {^[0-9a-f]{40}$} $source_tree]} {
  error "SOURCE_COMMIT and SOURCE_TREE must be lowercase 40-hex identities"
}
foreach value [list $expected_pre_vivado_seal_sha $expected_focused_sha \
    $expected_affected_sha $expected_binding_sha $expected_publication_sha] {
  if {![regexp {^[0-9A-F]{64}$} $value]} {
    error "launcher pre-Vivado SHA authority must be uppercase 64-hex"
  }
}
if {![file isfile $donor_build_tcl]} { error "R3 donor harness missing" }

# Minimal helpers are defined before donor import only for validating its SHA.
proc rm1_bootstrap_sha256 {path} {
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set value [string toupper [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $value]} { return $value }
  }
  error "SHA-256 unavailable for $path"
}
if {[rm1_bootstrap_sha256 $donor_build_tcl] ne $expected_donor_sha} {
  error "immutable R3 donor harness hash mismatch"
}
set donor_proc_count [import_donor_procedures $donor_build_tcl]
if {[rm1_bootstrap_sha256 $donor_build_tcl] ne $expected_donor_sha} {
  error "immutable R3 donor harness changed during procedure import"
}

set actual_commit [rm1_git rev-parse HEAD]
set actual_tree [rm1_git rev-parse {HEAD^{tree}}]
set actual_branch [rm1_git symbolic-ref --short HEAD]
set actual_status [rm1_git status --porcelain=v1 --untracked-files=all]
if {$actual_commit ne $source_commit || $actual_tree ne $source_tree ||
    $actual_branch ne $expected_branch || $actual_status ne ""} {
  error "RM1 source identity/branch/cleanliness mismatch"
}
set sealed_changed_set [rm1_changed_set_current]
if {[rm1_git hash-object -- ip/v41/xdma_v41_m1.xci] ne $expected_xdma_xci_blob ||
    [rm1_git hash-object -- scripts/v41/xdma_config_common.tcl] ne $expected_xdma_config_blob} {
  error "accepted XDMA authority drift"
}
set pre_vivado_seal_rows [rm1_pre_vivado_seal_gate]
set focused_sha [rm1_require_receipt $focused_receipt [list \
  {"Result"[ \t]*:[ \t]*"PASS"} {"TestsPassed"[ \t]*:[ \t]*18} \
  {"TestsRequired"[ \t]*:[ \t]*18} \
  {"RouteControllerIntegration"[ \t]*:[ \t]*"PASS"} \
  {"ParserTapIntegration"[ \t]*:[ \t]*"PASS"} \
  {"SourceChangedDuringGate"[ \t]*:[ \t]*false}] FOCUSED]
if {$focused_sha ne $expected_focused_sha} {
  error "focused receipt changed after launcher seal"
}
set affected_sha [rm1_require_receipt $affected_receipt [list \
  {"Result"[ \t]*:[ \t]*"PASS"} \
  {"R3ProtectedInputsVsParent"[ \t]*:[ \t]*"BYTE_IDENTICAL"} \
  {"CompleteR3Regression"[ \t]*:[ \t]*"25/25 PASS"} \
  {"HardwareAccessed"[ \t]*:[ \t]*"NO"}] AFFECTED_R3]
if {$affected_sha ne $expected_affected_sha} {
  error "affected-R3 receipt changed after launcher seal"
}
set publication_sha [rm1_require_receipt $publication_receipt [list \
  {"Result"[ \t]*:[ \t]*"PASS"} \
  [format {"SourceCommit"[ \t]*:[ \t]*"%s"} $source_commit] \
  [format {"SourceTree"[ \t]*:[ \t]*"%s"} $source_tree] \
  {"RemoteRefReadback"[ \t]*:[ \t]*"PASS"} \
  {"CommitPinnedBlobReadback"[ \t]*:[ \t]*"PASS"}] PUBLICATION_READBACK]
if {$publication_sha ne $expected_publication_sha} {
  error "publication receipt changed after launcher seal"
}
set binding_sha [rm1_require_receipt $binding_receipt [list \
  {"Result"[ \t]*:[ \t]*"PASS"} \
  {"FocusedHashAfterBinding"[ \t]*:[ \t]*"PASS"} \
  {"AffectedInputHashBinding"[ \t]*:[ \t]*"PASS"} \
  {"DirectParentBinding"[ \t]*:[ \t]*"PASS"} \
  {"AuthorizedChangedSetBinding"[ \t]*:[ \t]*"PASS"} \
  {"AuthorizedChangedSetFiles"[ \t]*:[ \t]*11} \
  {"RemoteRefReadback"[ \t]*:[ \t]*"PASS"} \
  {"CommitPinnedBlobReadback"[ \t]*:[ \t]*"PASS"}] RECEIPT_BINDING]
if {$binding_sha ne $expected_binding_sha} {
  error "binding receipt changed after launcher seal"
}
set binding_validation_rows [rm1_binding_receipt_gate $binding_receipt \
  $focused_sha $affected_sha $publication_sha]

set sealed_inputs [rm1_canonical_inputs]
file mkdir $build_root
file mkdir $evidence_root
set build_input_manifest [file join $evidence_root G2B_NVP_DIAG2_RM1_BUILD_INPUT_SHA256.txt]
write_lines $build_input_manifest $sealed_inputs
set build_input_manifest_sha [sha256_file $build_input_manifest]
write_lines [file join $evidence_root G2B_NVP_DIAG2_RM1_PRE_VIVADO_SEAL_GATE.txt] \
  [concat [list {RESULT=PASS} "PRE_VIVADO_SEAL=$pre_vivado_seal" \
    "PRE_VIVADO_SEAL_SHA256=$expected_pre_vivado_seal_sha"] \
    $pre_vivado_seal_rows $binding_validation_rows]

set git_words [list]
for {set index 0} {$index < 5} {incr index} {
  lappend git_words [string range $source_commit [expr {$index * 8}] [expr {$index * 8 + 7}]]
}
set generics "SLOT_COUNT=2"
for {set index 0} {$index < 5} {incr index} {
  append generics " GIT_SHA_W$index=32'h[lindex $git_words $index]"
}
append generics " BUILD_FLAGS=32'h00000802 ENABLE_MAREK_INIT_TABLE=1"
append generics " ENABLE_RTRACK_DIAGNOSTICS=0 ENABLE_NVP_VIDEO_DIAGNOSTIC=0"
append generics " ENABLE_NVP_VIDEO_DIAG2_RM1=1"

set action_counts [dict create SYNTH_DESIGN 0 OPT_DESIGN 0 PLACE_DESIGN 0 PHYS_OPT_DESIGN 0 ROUTE_DESIGN 0 WRITE_BITSTREAM 0 WRITE_DEBUG_PROBES 0]
set stage PREFLIGHT
set terminal [list \
  {TASK=AHD_V41_G2B_NVP_DIAG2_RM1} \
  {CANDIDATE_CLASSIFICATION=RM1_R1_OFFLINE_QUALIFIED_NO_DMA_RAW_MARKER_CANDIDATE_PENDING_BUILD} \
  "SOURCE_COMMIT=$source_commit" "SOURCE_TREE=$source_tree" \
  "EXPECTED_PARENT=$expected_parent" {DIRECT_PARENT_BINDING=PASS} \
  {AUTHORIZED_CHANGED_SET=11/11} \
  "SOURCE_BRANCH=$actual_branch" {SOURCE_CLEAN=PASS} \
  "PRE_VIVADO_SEAL=$pre_vivado_seal" \
  "PRE_VIVADO_SEAL_SHA256=$expected_pre_vivado_seal_sha" \
  "FOCUSED_RECEIPT=$focused_receipt" "FOCUSED_RECEIPT_SHA256=$focused_sha" \
  "AFFECTED_R3_RECEIPT=$affected_receipt" "AFFECTED_R3_RECEIPT_SHA256=$affected_sha" \
  "RECEIPT_BINDING=$binding_receipt" "RECEIPT_BINDING_SHA256=$binding_sha" \
  "PUBLICATION_READBACK_RECEIPT=$publication_receipt" \
  "PUBLICATION_READBACK_RECEIPT_SHA256=$publication_sha" \
  {REMOTE_BRANCH_PUBLICATION=PASS_PRE_VIVADO} \
  {COMMIT_PINNED_BLOB_READBACK=PASS_PRE_VIVADO} \
  "R3_DONOR_BUILD_TCL=$donor_build_tcl" "R3_DONOR_BUILD_TCL_SHA256=$expected_donor_sha" \
  "R3_DONOR_PROCEDURES_IMPORTED=$donor_proc_count" \
  "BUILD_INPUT_MANIFEST_SHA256=$build_input_manifest_sha" \
  {DONOR_TOP_LEVEL_EXECUTED=NO} {CHECKPOINT_REUSE=NO} \
  {ENABLE_NVP_VIDEO_DIAG2_RM1=1} {ENABLE_NVP_VIDEO_DIAGNOSTIC=0} \
  {ENABLE_RTRACK_DIAGNOSTICS=0} "BUILD_FLAGS=$expected_build_flags" \
  {MMIO_RANGE=0x3C00..0x3FFF} {HARDWARE_ACCESSED=NO}]
write_lines [file join $evidence_root G2B_NVP_DIAG2_RM1_PREFLIGHT.txt] $terminal

set build_code [catch {
  if {![info exists ::env(XILINX_LOCAL_USER_DATA)] || $::env(XILINX_LOCAL_USER_DATA) ne "NO"} {
    error "XILINX_LOCAL_USER_DATA must be NO"
  }
  if {[version -short] ne $expected_vivado_version} {
    error "Vivado version mismatch: expected=$expected_vivado_version actual=[version -short]"
  }
  set common_tcl [file join $repo_root scripts v41 xdma_config_common.tcl]
  source $common_tcl
  if {![namespace exists ::v41_xdma] || ![llength [info commands ::v41_xdma::configure_minimal_c2h_stream]]} {
    error "accepted XDMA helper unavailable"
  }

  set sv_files [list]
  foreach rel $sv_rel_files { lappend sv_files [file join $repo_root $rel] }
  set vhdl_files [list]
  foreach rel $vhdl_rel_files { lappend vhdl_files [file join $repo_root $rel] }
  set xdc_files [list]
  foreach rel $xdc_rel_files { lappend xdc_files [file join $repo_root $rel] }
  require_files [concat $sv_files $vhdl_files $xdc_files]

  set stage PROJECT_SETUP
  cd $build_root
  set project_dir [file join $build_root vivado_project]
  create_project v41_g2b_nvp_diag2_rm1 $project_dir -part $expected_part
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
  set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]
  config_ip_cache -use_cache_location [file join $build_root ip_cache]
  add_files -norecurse $sv_files
  set_property FILE_TYPE SystemVerilog [get_files $sv_files]
  add_files -norecurse $vhdl_files

  set xdma_source [file join $repo_root ip v41 xdma_v41_m1.xci]
  set input_xci_dir [file join $build_root input_xci]
  file mkdir $input_xci_dir
  set xdma_copy [file join $input_xci_dir xdma_v41_m1.xci]
  file copy $xdma_source $xdma_copy
  if {[sha256_file $xdma_source] ne [sha256_file $xdma_copy]} {
    error "local XDMA copy identity mismatch"
  }
  import_ip -files $xdma_copy
  set xdma_ip [get_ips -quiet xdma_v41_m1]
  if {[llength $xdma_ip] != 1} { error "expected one local XDMA IP" }
  ::v41_xdma::configure_minimal_c2h_stream $xdma_ip
  ::v41_xdma::assert_frozen_g1_invariants $xdma_ip
  set configured [effective_config_dict $xdma_ip]
  set imported_xci [get_files -quiet [get_property IP_FILE $xdma_ip]]
  if {[llength $imported_xci] != 1} { error "local XDMA XCI object missing" }
  set_property GENERATE_SYNTH_CHECKPOINT false $imported_xci
  generate_target all $xdma_ip
  assert_config_dict_equal $configured [effective_config_dict $xdma_ip] POST_GENERATION_XDMA
  ::v41_xdma::assert_frozen_g1_invariants $xdma_ip
  ::v41_xdma::dump_effective_config $xdma_ip [file join $evidence_root G2B_NVP_DIAG2_RM1_XDMA_CONFIG.txt]

  add_files -fileset constrs_1 -norecurse $xdc_files
  set_property PROCESSING_ORDER EARLY [get_files [lindex $xdc_files 0]]
  set_property PROCESSING_ORDER LATE [get_files [lrange $xdc_files 1 end]]
  set_property top $expected_top [get_filesets sources_1]
  set_property generic $generics [get_filesets sources_1]
  update_compile_order -fileset sources_1
  report_compile_order -fileset sources_1 -used_in synthesis -file [file join $evidence_root G2B_NVP_DIAG2_RM1_COMPILE_ORDER.rpt]
  set rm1_xdc [file join $repo_root xdc common g2b_nvp_diag2_rm1_cdc.xdc]
  set rm1_xdc_count [llength [get_files -quiet $rm1_xdc]]
  if {$rm1_xdc_count != 1} { error "RM1 XDC inclusion must be exactly one" }
  write_lines [file join $evidence_root G2B_NVP_DIAG2_RM1_PROFILE_MMIO_SOURCE_RECEIPT.txt] [list \
    {RESULT=PASS} {PROFILE=ENABLE_NVP_VIDEO_DIAG2_RM1} \
    {ENABLE_NVP_VIDEO_DIAG2_RM1=1} {ENABLE_NVP_VIDEO_DIAGNOSTIC=0} \
    {ENABLE_RTRACK_DIAGNOSTICS=0} "GENERIC=$generics" \
    {FIXED_I2C_MASTER_SOURCE=rtl/v41/nvp_i2c_fixed_master.sv} \
    {RM1_ROUTE_SOURCE=rtl/diagnostic/g2b_nvp_rm1_route_controller.sv} \
    {RM1_MONITOR_SOURCE=rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv} \
    {RM1_WRAPPER_SOURCE=rtl/g2b/g2b_nvp_video_diag2_rm1.sv} \
    {R3_CORE_SOURCE_PARSED_FOR_DEAD_GENERATE_ONLY=YES} \
    {SCAN1_SOURCE_INCLUDED=NO} {ACQ1_SOURCE_INCLUDED=NO} {MODE1_SOURCE_INCLUDED=NO} \
    "RM1_XDC_COUNT=$rm1_xdc_count" {MMIO_START=0x3C00} {MMIO_END=0x3FFF}]

  set stage SYNTHESIS
  dict incr action_counts SYNTH_DESIGN
  synth_design -top $expected_top -part $expected_part -flatten_hierarchy rebuilt
  rm1_profile_gate POST_SYNTH
  set synth_dcp [file join $evidence_root G2B_NVP_DIAG2_RM1_SYNTH.dcp]
  write_checkpoint $synth_dcp
  report_utilization -hierarchical -hierarchical_depth 20 -file [file join $evidence_root POST_SYNTH_UTILIZATION_HIER.rpt]

  set stage OPT_DESIGN
  dict incr action_counts OPT_DESIGN
  opt_design
  rm1_profile_gate POST_OPT
  set post_opt_metrics [rm1_resource_gate POST_OPT]
  set post_opt_dcp [file join $evidence_root G2B_NVP_DIAG2_RM1_POST_OPT.dcp]
  write_checkpoint $post_opt_dcp

  set stage PLACE_DESIGN
  dict incr action_counts PLACE_DESIGN
  place_design
  set stage PHYS_OPT_DESIGN
  dict incr action_counts PHYS_OPT_DESIGN
  phys_opt_design
  set stage ROUTE_DESIGN
  dict incr action_counts ROUTE_DESIGN
  route_design -directive AggressiveExplore
  set routed_dcp [file join $evidence_root G2B_NVP_DIAG2_RM1_ROUTED.dcp]
  write_checkpoint $routed_dcp
  set routed_dcp_sha [sha256_file $routed_dcp]

  set stage ROUTED_HARD_GATES
  rm1_profile_gate ROUTED
  lassign [rm1_timing_route_gate] wns tns whs ths raw_unconstrained_rows
  set routed_metrics [rm1_resource_gate ROUTED]
  report_utilization -hierarchical -hierarchical_depth 20 -file [file join $evidence_root ROUTED_UTILIZATION_HIER.rpt]
  report_exceptions -coverage -file [file join $evidence_root EXCEPTION_COVERAGE.rpt]
  report_clocks -file [file join $evidence_root CLOCKS.rpt]
  report_clock_interaction -file [file join $evidence_root CLOCK_INTERACTION.rpt]
  report_ram_utilization -file [file join $evidence_root RAM_UTILIZATION.rpt]

  lassign [run_exact_routed_bus_skew_gate $evidence_root $routed_dcp $routed_dcp_sha] \
    skew_violations skew_pass skew_sha
  if {$skew_violations != 0 || $skew_pass != 11} {
    error "RM1 inherited active bus-skew gate failed"
  }
  fix1_r1_source_retired_absence_gate
  set promoted_pass [fix1_r1_run_promoted_replacements]
  if {$promoted_pass != 17} { error "RM1 promoted replacement gate failed" }
  fix1_r1_structural_cdc_gate
  fix1_r1_write_all_groups_matrix
  set rm1_cdc_findings [rm1_cdc_gate]
  lassign [rm1_drc_methodology_gate] drc_warnings methodology_warnings

  foreach action {SYNTH_DESIGN OPT_DESIGN PLACE_DESIGN PHYS_OPT_DESIGN ROUTE_DESIGN} {
    if {[dict get $action_counts $action] != 1} { error "operation count mismatch: $action" }
  }
  if {[dict get $action_counts WRITE_BITSTREAM] != 0 ||
      [dict get $action_counts WRITE_DEBUG_PROBES] != 0} {
    error "unauthorized output writer executed in build stage"
  }
  if {![rm1_source_seal_current]} { error "source seal changed during build" }

  set stage ROUTED_HANDOFF
  set handoff [file join $evidence_root G2B_NVP_DIAG2_RM1_ROUTED_BUILD_HANDOFF.txt]
  write_lines $handoff [list \
    {RESULT=PASS} {PROFILE_ELABORATION=PASS} \
    "SOURCE_COMMIT=$source_commit" "SOURCE_TREE=$source_tree" \
    "EXPECTED_PARENT=$expected_parent" {DIRECT_PARENT_BINDING=PASS} \
    {AUTHORIZED_CHANGED_SET=11/11} \
    "PRE_VIVADO_SEAL=$pre_vivado_seal" \
    "PRE_VIVADO_SEAL_SHA256=$expected_pre_vivado_seal_sha" \
    "FOCUSED_RECEIPT=$focused_receipt" "FOCUSED_RECEIPT_SHA256=$focused_sha" \
    "AFFECTED_R3_RECEIPT=$affected_receipt" \
    "AFFECTED_R3_RECEIPT_SHA256=$affected_sha" \
    "RECEIPT_BINDING=$binding_receipt" "RECEIPT_BINDING_SHA256=$binding_sha" \
    "PUBLICATION_READBACK_RECEIPT=$publication_receipt" \
    "PUBLICATION_READBACK_RECEIPT_SHA256=$publication_sha" \
    "R3_DONOR_BUILD_TCL=$donor_build_tcl" \
    "R3_DONOR_BUILD_TCL_SHA256=$expected_donor_sha" \
    "ROUTED_DCP=$routed_dcp" "ROUTED_DCP_SHA256=$routed_dcp_sha" \
    "BUILD_INPUT_MANIFEST_SHA256=$build_input_manifest_sha" \
    "WNS=[format %.3f $wns]" "TNS=[format %.3f $tns]" \
    "WHS=[format %.3f $whs]" "THS=[format %.3f $ths]" \
    "RAW_UNCONSTRAINED_PATH_TABLE_ROWS=$raw_unconstrained_rows" \
    {RAW_UNCONSTRAINED_ENDPOINTS=0} {UNCONSTRAINED_GATE=PASS} \
    "LUT_USED=[dict get $routed_metrics LUT_USED]" \
    "LUT_AVAILABLE=[dict get $routed_metrics LUT_AVAILABLE]" \
    "LUT_PERCENT=[format %.3f [dict get $routed_metrics LUT_PERCENT]]" \
    {LUT_HARD_GATE=PASS_LE_98_PERCENT} \
    "LUT_PREFERRED_GATE=[expr {[dict get $routed_metrics LUT_USED] <= $lut_preferred_max ? {PASS} : {ADVISORY_MISS}}]" \
    {ACTIVE_BUS_SKEW_GROUPS=11/11} {PROMOTED_REPLACEMENT_CHECKS=17/17} \
    "BUS_SKEW_REPORT_SHA256=$skew_sha" \
    "RM1_CDC_FINDINGS_DISPOSITIONED=$rm1_cdc_findings" \
    {NEW_UNRESOLVED_CRITICAL_CDC=0} {NEW_UNRESOLVED_WARNING_CDC=0} \
    "DRC_WARNINGS=$drc_warnings" {DRC_HARD_GATE=PASS} \
    "METHODOLOGY_WARNINGS=$methodology_warnings" {METHODOLOGY_HARD_GATE=PASS} \
    {BITSTREAM_PRODUCED=NO} {WRITE_BITSTREAM_COUNT=0} \
    {WRITE_DEBUG_PROBES_COUNT=0} {HARDWARE_ACCESSED=NO}]
  lappend terminal "STAGE=$stage" {BUILD=PASS_ROUTED_HANDOFF} \
    "ROUTED_DCP_SHA256=$routed_dcp_sha" {BITSTREAM_PRODUCED=NO}
} failure failure_options]

if {$build_code != 0} {
  lappend terminal "STAGE=$stage" {BUILD=FAIL} "ERROR=[single_line $failure]"
  if {[dict exists $failure_options -errorinfo]} {
    lappend terminal "ERROR_INFO=[single_line [dict get $failure_options -errorinfo]]"
  }
  write_lines [file join $evidence_root G2B_NVP_DIAG2_RM1_BUILD_RESULT.txt] $terminal
  puts stderr "RM1_BUILD_FAIL: $failure"
  catch {close_project}
  exit 1
}
dict for {key value} $action_counts { lappend terminal "$key=$value" }
write_lines [file join $evidence_root G2B_NVP_DIAG2_RM1_BUILD_RESULT.txt] $terminal
catch {close_project}
puts "RM1_ROUTED_BUILD_HANDOFF_PASS BITSTREAM_PRODUCED=NO"
exit 0
