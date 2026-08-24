# R1h provenance-correct, single-consumption diagnostic build.
#
# There is deliberately no preflight-only or retry execution mode. All
# non-consuming checks finish before the sentinel is created. Creating that
# sentinel consumes the one authorized build even if any later step fails.
#
# Prebuild manifest grammar:
#   META|KEY|VALUE
#   SOURCE_SHA256|repository/relative/path|64_HEX_SHA256
#   ACCEPTED_LOG_SHA256|LABEL|absolute_or_manifest_relative_path|64_HEX_SHA256

if {$argc != 7} {
  puts stderr "usage: r1h_build.tcl REPOSITORY_ROOT BUILD_ROOT EVIDENCE_ROOT SOURCE_GIT_COMMIT SOURCE_GIT_TREE PREBUILD_MANIFEST PREBUILD_MANIFEST_SHA256"
  exit 2
}

set repo_root [file normalize [lindex $argv 0]]
set build_root [file normalize [lindex $argv 1]]
set evidence_root [file normalize [lindex $argv 2]]
set source_commit [string tolower [lindex $argv 3]]
set source_tree [string tolower [lindex $argv 4]]
set prebuild_manifest [file normalize [lindex $argv 5]]
set expected_prebuild_manifest_sha256 [string toupper [lindex $argv 6]]

set expected_branch diag/v41-nvp-r1h-bram-backed-large-sample
set exact_r1e_base_commit f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
set exact_r1f_commit 225544084dbfcaadb8592fcecc947aa1cec4970e
set exact_r1g_parent_commit e112a5addb7ac62700a9a71af81bf368fad0bada
set expected_vivado_version 2025.2
set expected_vivado_sw_build 6299465
set expected_part xc7a35tcsg325-2
set expected_top ahd_capture_top_xdma
set bit_filename ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit
set frozen_r1g_build_tcl [file normalize \
  {C:/FPGA/V41_NVP_R1G_VHDL_COMPATIBILITY/scripts/r1g_build.tcl}]
set expected_frozen_r1g_build_tcl_sha256 \
  C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  foreach line $lines {
    puts $fh $line
  }
  close $fh
}

proc read_text {path} {
  set fh [open $path r]
  fconfigure $fh -encoding utf-8
  set text [read $fh]
  close $fh
  return $text
}

proc require_files {paths} {
  foreach path $paths {
    if {![file isfile $path]} {
      error "required file missing: $path"
    }
  }
}

proc sha256_file {path} {
  if {![file isfile $path]} {
    error "cannot hash missing file: $path"
  }
  set output [exec certutil.exe -hashfile [file nativename $path] SHA256]
  foreach line [split $output "\n"] {
    set compact [string toupper \
      [string map [list " " "" "\t" "" "\r" ""] [string trim $line]]]
    if {[regexp {^[0-9A-F]{64}$} $compact]} {
      return $compact
    }
  }
  error "certutil did not return a SHA-256 digest for $path"
}

proc directory_entries {path} {
  set result [list]
  if {![file exists $path]} {
    return $result
  }
  if {![file isdirectory $path]} {
    error "expected directory, found non-directory: $path"
  }
  foreach pattern [list * .*] {
    foreach item [glob -nocomplain -directory $path $pattern] {
      set tail [file tail $item]
      if {$tail ne "." && $tail ne ".."} {
        lappend result [file normalize $item]
      }
    }
  }
  return [lsort -unique $result]
}

proc path_inside_or_equal {child parent} {
  set child_native [string tolower [file nativename [file normalize $child]]]
  set parent_native [string trimright \
    [string tolower [file nativename [file normalize $parent]]] "\\/"]
  if {$child_native eq $parent_native} {
    return 1
  }
  return [expr {
    [string first "$parent_native\\" $child_native] == 0 ||
    [string first "$parent_native/" $child_native] == 0
  }]
}

proc normalize_repo_relative {repo_root relative_path} {
  set rel [string map [list "\\" "/"] [string trim $relative_path]]
  if {$rel eq "" || [file pathtype $rel] ne "relative"} {
    error "manifest repository path must be nonempty and relative: '$relative_path'"
  }
  set resolved [file normalize [file join $repo_root $rel]]
  if {![path_inside_or_equal $resolved $repo_root] || $resolved eq $repo_root} {
    error "manifest repository path escapes repository root: '$relative_path'"
  }
  return $rel
}

proc relative_path_from_repo {repo_root absolute_path} {
  set root_native [string trimright \
    [file nativename [file normalize $repo_root]] "\\/"]
  set path_native [file nativename [file normalize $absolute_path]]
  set root_lower [string tolower $root_native]
  set path_lower [string tolower $path_native]
  set prefix "$root_lower\\"
  if {[string first $prefix $path_lower] != 0} {
    error "path is not inside repository: $absolute_path"
  }
  set rel_native [string range $path_native \
    [string length "$root_native\\"] end]
  return [string map [list "\\" "/"] $rel_native]
}

proc require_exact_text {text pattern description} {
  if {![regexp -- $pattern $text]} {
    error "frozen source contract not found: $description"
  }
}

proc safe_property {object property} {
  if {[catch {get_property $property $object} value]} {
    return NOT_AVAILABLE
  }
  if {$value eq ""} {
    return EMPTY
  }
  return $value
}

proc parse_nonnegative_integer {value description} {
  set compact [string map [list "," "" " " "" "\t" ""] \
    [string trim $value]]
  if {![regexp {^[0-9]+$} $compact]} {
    error "$description is not a nonnegative integer: '$value'"
  }
  return $compact
}

proc cell_names_by_ref_patterns {ref_name patterns} {
  set result [list]
  foreach cell [get_cells -quiet -hier -filter "REF_NAME == $ref_name"] {
    set name [get_property NAME $cell]
    set name_lower [string tolower $name]
    set accepted 1
    foreach pattern $patterns {
      if {![regexp -- $pattern $name_lower]} {
        set accepted 0
        break
      }
    }
    if {$accepted} {
      lappend result $name
    }
  }
  return [lsort -dictionary -unique $result]
}

proc append_primitive_inventory {lines_var label names} {
  upvar 1 $lines_var lines
  lappend lines "$label=[llength $names]"
  foreach name $names {
    lappend lines "$label|CELL=$name"
  }
}

proc utilization_row {text wanted} {
  set normalized_wanted [string trimright $wanted "*"]
  foreach line [split $text "\n"] {
    set columns [split $line "|"]
    if {[llength $columns] < 7} {
      continue
    }
    set actual [string trimright [string trim [lindex $columns 1]] "*"]
    if {$actual eq $normalized_wanted} {
      return [list [string trim [lindex $columns 2]] \
                   [string trim [lindex $columns 5]]]
    }
  }
  error "utilization row '$wanted' not found"
}

proc compile_order_index {compile_names wanted_path} {
  set wanted [string tolower [file nativename [file normalize $wanted_path]]]
  for {set index 0} {$index < [llength $compile_names]} {incr index} {
    set candidate [string tolower \
      [file nativename [file normalize [lindex $compile_names $index]]]]
    if {$candidate eq $wanted} {
      return $index
    }
  }
  return -1
}

proc write_region_inventory {evidence_root label pattern} {
  set cells [get_cells -quiet -hier -regexp $pattern]
  set nets [get_nets -quiet -hier -regexp $pattern]
  set lines [list \
    "LABEL=$label" \
    "PATTERN=$pattern" \
    "CELL_COUNT=[llength $cells]" \
    "NET_COUNT=[llength $nets]"]
  if {[llength $cells] != 0} {
    foreach cell [lsort [get_property NAME $cells]] {
      lappend lines "CELL=$cell"
    }
  }
  if {[llength $nets] != 0} {
    foreach net [lsort [get_property NAME $nets]] {
      lappend lines "NET=$net"
    }
  }
  set filename [format "R1H_%s_INVENTORY.txt" $label]
  write_lines [file join $evidence_root $filename] $lines
  if {[llength $cells] + [llength $nets] == 0} {
    error "required routed R1h design region has no cells or nets: $label"
  }
  return [expr {[llength $cells] + [llength $nets]}]
}

proc verify_prebuild_manifest {
  manifest_path manifest_sha repo_root source_commit source_tree
  build_tcl_sha required_source_paths required_log_labels
} {
  if {![regexp {^[0-9A-F]{64}$} $manifest_sha]} {
    error "PREBUILD_MANIFEST_SHA256 must be exactly 64 uppercase hex digits"
  }
  set actual_manifest_sha [sha256_file $manifest_path]
  if {$actual_manifest_sha ne $manifest_sha} {
    error "prebuild manifest SHA-256 mismatch: expected $manifest_sha, got $actual_manifest_sha"
  }

  array set metadata {}
  array set source_hash {}
  array set accepted_log {}
  set manifest_dir [file dirname $manifest_path]
  set line_number 0
  foreach raw_line [split [read_text $manifest_path] "\n"] {
    incr line_number
    set line [string trim $raw_line]
    if {$line eq "" || [string index $line 0] eq "#"} {
      continue
    }
    set fields [split $line "|"]
    set kind [lindex $fields 0]
    switch -- $kind {
      META {
        if {[llength $fields] != 3} {
          error "invalid META record at manifest line $line_number"
        }
        set key [string trim [lindex $fields 1]]
        set value [string trim [lindex $fields 2]]
        if {$key eq "" || [info exists metadata($key)]} {
          error "empty or duplicate META key '$key' at manifest line $line_number"
        }
        set metadata($key) $value
      }
      SOURCE_SHA256 {
        if {[llength $fields] != 3} {
          error "invalid SOURCE_SHA256 record at manifest line $line_number"
        }
        set rel [normalize_repo_relative $repo_root [lindex $fields 1]]
        set key [string tolower $rel]
        set digest [string toupper [string trim [lindex $fields 2]]]
        if {![regexp {^[0-9A-F]{64}$} $digest] ||
            [info exists source_hash($key)]} {
          error "invalid or duplicate source digest for '$rel'"
        }
        set source_hash($key) $digest
      }
      ACCEPTED_LOG_SHA256 {
        if {[llength $fields] != 4} {
          error "invalid ACCEPTED_LOG_SHA256 record at manifest line $line_number"
        }
        set label [string trim [lindex $fields 1]]
        set log_path [string trim [lindex $fields 2]]
        set digest [string toupper [string trim [lindex $fields 3]]]
        if {$label eq "" || $log_path eq "" ||
            ![regexp {^[0-9A-F]{64}$} $digest] ||
            [info exists accepted_log($label)]} {
          error "invalid or duplicate accepted-log record for '$label'"
        }
        if {[file pathtype $log_path] eq "relative"} {
          set log_path [file normalize [file join $manifest_dir $log_path]]
        } else {
          set log_path [file normalize $log_path]
        }
        if {![file isfile $log_path]} {
          error "accepted log missing for $label: $log_path"
        }
        set actual [sha256_file $log_path]
        if {$actual ne $digest} {
          error "accepted log SHA-256 mismatch for $label: expected $digest, got $actual"
        }
        set accepted_log($label) [list $log_path $digest]
      }
      default {
        error "unknown prebuild manifest record '$kind' at line $line_number"
      }
    }
  }

  array set required_meta [list \
    SOURCE_GIT_COMMIT $source_commit \
    SOURCE_GIT_TREE $source_tree \
    R1H_BUILD_TCL_SHA256 $build_tcl_sha \
    R1G_FROZEN_BUILD_TCL_SHA256 \
      C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A \
    PREBUILD_AUDIT PASS \
    R1H_PREBUILD_RELEASE PASS \
    SCIENTIFIC_SCOPE_REDUCTION NO \
    PRE_INIT_DONE_CYCLE_EQUIVALENCE PASS \
    AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL YES \
    FUNCTIONAL_STATE_SEQUENCE_IDENTICAL YES \
    PROBE_TRANSACTION_STREAM_BYTE_IDENTICAL YES \
    DIAGNOSTIC_EVENT_STREAM_IDENTICAL YES \
    R1H_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT 0 \
    MMIO_TRANSACTION_LEVEL_EQUIVALENCE PASS_ALL_ADDRESSES \
    NVP_TABLE_UNCHANGED YES \
    FUNCTIONAL_FSM_UNCHANGED YES \
    POR_START_WATCHDOG_UNCHANGED YES \
    SDA_SCL_FILTERS_UNCHANGED YES \
    NVP_XDC_UNCHANGED YES \
    XDMA_XCI_UNCHANGED YES \
    SAFE_DATA_PROBE_TARGET PASS \
    RECORD_MAP_COLLISION NONE_PROVEN \
    PHASE_OPPORTUNITY_COUNTERS_MATCH_SCOREBOARD PASS \
    FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD PASS \
    BANK_BEFORE_AFTER_SEMANTICS PASS \
    TRANSACTION_INDEX_16_UNIQUE PASS \
    LEGACY_FIRST8_RECONCILIATION PASS \
    TRI_PHASE_PROBE_SCOREBOARD PASS \
    SAFE_TARGET_RESTORATION PASS \
    EFFECTIVE_PRE_INIT_ARBITRATION PASS \
    R1F_LOG_64_EXACT_OVERFLOW_65 PASS \
    FAILED_RECORD_CAPACITY 64 \
    FAILED_RECORD_WIDTH 192 \
    INDEX_CAPACITY_PER_PHASE 512 \
    PROBE_TARGET_OPPORTUNITIES_PER_PHASE 10000 \
    BRAM_ARCHITECTURE_TESTS PASS \
    MMIO_LATENCY_AND_BACKPRESSURE_TESTS PASS \
    ALL_R1G_SCIENTIFIC_TESTS PASS \
    INHERITED_POWER_TIMING PASS \
    INHERITED_D2B_SEQUENCE PASS \
    R1F_PRODUCTION_TIMING_MODEL PASS \
    HOST_TOOL_FIXTURES PASS \
    STATISTICAL_SCRIPT_FIXTURES PASS]
  foreach key [array names required_meta] {
    if {![info exists metadata($key)] ||
        $metadata($key) ne $required_meta($key)} {
      set actual MISSING
      if {[info exists metadata($key)]} {
        set actual $metadata($key)
      }
      error "prebuild META gate $key expected '$required_meta($key)', got '$actual'"
    }
  }

  foreach rel [lsort -unique $required_source_paths] {
    set normalized [normalize_repo_relative $repo_root $rel]
    set key [string tolower $normalized]
    if {![info exists source_hash($key)]} {
      error "prebuild manifest has no SOURCE_SHA256 for required path: $normalized"
    }
    set actual [sha256_file [file join $repo_root $normalized]]
    if {$actual ne $source_hash($key)} {
      error "committed source SHA-256 mismatch for $normalized: manifest $source_hash($key), actual $actual"
    }
  }

  foreach label $required_log_labels {
    if {![info exists accepted_log($label)]} {
      error "prebuild manifest has no accepted log for required label: $label"
    }
  }

  set summary [list \
    "PREBUILD_MANIFEST=$manifest_path" \
    "PREBUILD_MANIFEST_SHA256=$actual_manifest_sha" \
    "SOURCE_RECORDS=[array size source_hash]" \
    "ACCEPTED_LOG_RECORDS=[array size accepted_log]" \
    "PREBUILD_MANIFEST_BINDING=PASS"]
  foreach label [lsort [array names accepted_log]] {
    lassign $accepted_log($label) log_path digest
    lappend summary "ACCEPTED_LOG|$label|$log_path|$digest"
  }
  return $summary
}

if {![regexp {^[0-9a-f]{40}$} $source_commit]} {
  error "SOURCE_GIT_COMMIT must be exactly 40 lowercase hex digits"
}
if {![regexp {^[0-9a-f]{40}$} $source_tree]} {
  error "SOURCE_GIT_TREE must be exactly 40 lowercase hex digits"
}
if {![file isdirectory $repo_root]} {
  error "repository root is not a directory: $repo_root"
}
if {![file isfile $prebuild_manifest]} {
  error "prebuild manifest is not a file: $prebuild_manifest"
}
if {![file isfile $frozen_r1g_build_tcl]} {
  error "frozen R1g build Tcl is unavailable: $frozen_r1g_build_tcl"
}
set actual_frozen_r1g_build_tcl_sha256 [sha256_file $frozen_r1g_build_tcl]
if {$actual_frozen_r1g_build_tcl_sha256 ne
    $expected_frozen_r1g_build_tcl_sha256} {
  error "frozen R1g build Tcl SHA-256 mismatch"
}
if {[path_inside_or_equal $build_root $repo_root] ||
    [path_inside_or_equal $evidence_root $repo_root]} {
  error "build and evidence roots must be outside the clean source repository"
}
if {[path_inside_or_equal $evidence_root $build_root]} {
  error "evidence root must not be inside the new/empty build root"
}
if {[llength [directory_entries $build_root]] != 0} {
  error "R1h build root must be new or empty: $build_root"
}

set common_tcl [file join $repo_root scripts v41 xdma_config_common.tcl]
if {![file isfile $common_tcl]} {
  error "shared XDMA configuration helper is missing: $common_tcl"
}

set git_top [file normalize [string trim \
  [exec git -C $repo_root rev-parse --show-toplevel]]]
if {[string tolower [file nativename $git_top]] ne
    [string tolower [file nativename $repo_root]]} {
  error "REPOSITORY_ROOT is not the exact Git top: $git_top"
}
set actual_commit [string tolower [string trim \
  [exec git -C $repo_root rev-parse HEAD]]]
set actual_tree [string tolower [string trim \
  [exec git -C $repo_root rev-parse {HEAD^{tree}}]]]
set actual_branch [string trim \
  [exec git -C $repo_root symbolic-ref --short HEAD]]
set source_status [string trim \
  [exec git -C $repo_root status --porcelain --untracked-files=all]]
if {$actual_commit ne $source_commit} {
  error "repository HEAD $actual_commit does not match requested source commit $source_commit"
}
if {$actual_tree ne $source_tree} {
  error "repository tree $actual_tree does not match requested source tree $source_tree"
}
if {$actual_branch ne $expected_branch} {
  error "branch mismatch: expected $expected_branch, got $actual_branch"
}
if {$source_status ne ""} {
  error "one-build flow requires a fully clean source repository: $source_status"
}
set merge_base [string tolower [string trim \
  [exec git -C $repo_root merge-base $exact_r1e_base_commit $source_commit]]]
if {$merge_base ne $exact_r1e_base_commit} {
  error "R1h source is not based on exact R1e commit $exact_r1e_base_commit"
}
set source_commit_count [string trim [exec git -C $repo_root rev-list --count \
  [format "%s..%s" $exact_r1e_base_commit $source_commit]]]
if {$source_commit_count ne "3"} {
  error "R1h branch must contain exactly three source commits above R1e base; got $source_commit_count"
}
set actual_parent_commit [string tolower [string trim \
  [exec git -C $repo_root rev-parse HEAD^]]]
if {$actual_parent_commit ne $exact_r1g_parent_commit} {
  error "R1h commit is not a direct child of exact R1g commit $exact_r1g_parent_commit"
}
set r1g_parent_parent [string tolower [string trim \
  [exec git -C $repo_root rev-parse ${exact_r1g_parent_commit}^]]]
if {$r1g_parent_parent ne $exact_r1f_commit} {
  error "exact R1g parent does not descend directly from exact R1f commit"
}

set vivado_short [string trim [version -short]]
set vivado_detail [version]
if {$vivado_short ne $expected_vivado_version} {
  error "Vivado version mismatch: expected $expected_vivado_version, got $vivado_short"
}
set vivado_sw_build UNKNOWN
regexp {SW Build[ \t]+([0-9]+)} $vivado_detail -> vivado_sw_build
if {$vivado_sw_build ne $expected_vivado_sw_build} {
  error "Vivado SW build mismatch: expected $expected_vivado_sw_build, got $vivado_sw_build"
}

set sv_rel_files [list \
  rtl/v41/axi_lite_host_bridge.sv \
  rtl/v41/axi_clock_lifecycle_monitor.sv \
  rtl/v41/axi_clock_measurement_regs.sv \
  rtl/v41/r1e_measurement_regs.sv \
  rtl/v41/r1h_probe_index_bram_store.sv \
  rtl/v41/nvp_i2c_tri_phase_probe.sv \
  rtl/v41/r1f_failed_txn_logger.sv \
  rtl/v41/r1f_measurement_regs.sv \
  rtl/v41/r1h_mmio_read_service.sv \
  rtl/v41/control_status_regs.sv \
  rtl/pio/pio_slot_adapter.sv \
  rtl/pio/pio_bar_target.sv \
  rtl/record/bt656_record_producer.sv \
  rtl/record/capture_mailbox.sv \
  rtl/video/video_capture.sv \
  rtl/video/physical_frontend.sv \
  rtl/top/ahd_capture_top_xdma.sv]
set vhdl_rel_files [list \
  rtl/nvp/nvp6134c_diagnostics_pkg.vhd \
  rtl/nvp/r1f_transaction_serial_counter.vhd \
  rtl/nvp/nvp6134c_i2c_bringup.vhd \
  rtl/nvp/nvp6134c_autoinit.vhd]
set xdc_rel_files [list \
  xdc/boards/current/xdma_pcie.xdc \
  xdc/boards/current/pins.xdc \
  xdc/boards/current/vdo_input_timing.xdc \
  xdc/boards/current/pcie_pio.xdc \
  xdc/boards/current/nvp_control.xdc \
  xdc/common/cdc.xdc \
  xdc/common/configuration_bank.xdc]
set xdma_rel_file ip/v41/xdma_v41_m1.xci

set sv_files [list]
foreach rel $sv_rel_files {
  lappend sv_files [file normalize [file join $repo_root $rel]]
}
set vhdl_files [list]
foreach rel $vhdl_rel_files {
  lappend vhdl_files [file normalize [file join $repo_root $rel]]
}
set xdc_files [list]
foreach rel $xdc_rel_files {
  lappend xdc_files [file normalize [file join $repo_root $rel]]
}
set xdma_source [file normalize [file join $repo_root $xdma_rel_file]]
require_files [concat $sv_files $vhdl_files $xdc_files [list $xdma_source]]

array set frozen_sha256 [list \
  rtl/v41/r1e_measurement_regs.sv \
    034F8C63258CA6436817CFFE1605CDF23EF04030047CCE36146E115F3C374939 \
  rtl/nvp/nvp6134c_diagnostics_pkg.vhd \
    36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156 \
  ip/v41/xdma_v41_m1.xci \
    EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C \
  xdc/boards/current/xdma_pcie.xdc \
    65568DD132FE9C65231BCE50CA5F7364702E303659DB36AAAA1057C318282F6A \
  xdc/boards/current/pins.xdc \
    A8849CD13E75CAB2F509449617440ABE359BAA2B42ACAAE869BA25B581E6F8B9 \
  xdc/boards/current/vdo_input_timing.xdc \
    6B5E11BBB1556449CF00C85986FE77903B7852B495FCC3BE65D553C08E6E2E78 \
  xdc/boards/current/pcie_pio.xdc \
    BE7BFB70921AD272661071408C0820B4EC4BB60AB7C1102340011E57D8BE8503 \
  xdc/boards/current/nvp_control.xdc \
    B2AE6FA7446A094D68149A8016F89FD4E7F72CA438200772CF0E4B33D7E2F318 \
  xdc/common/cdc.xdc \
    E37500150FD91D324AA6488FB36DE6674561BF18DC220E3CD61CC0DA42C48A62 \
  xdc/common/configuration_bank.xdc \
    3F94073A8054B28FA4168FC6137430058FAE4EA46B3C5D035AFE637D2A135C68]
set frozen_input_lines [list]
foreach rel [lsort [array names frozen_sha256]] {
  set actual [sha256_file [file join $repo_root $rel]]
  if {$actual ne $frozen_sha256($rel)} {
    error "frozen input SHA-256 mismatch for $rel: expected $frozen_sha256($rel), got $actual"
  }
  lappend frozen_input_lines "$actual|$rel"
}

set top_text [read_text [file join $repo_root rtl top ahd_capture_top_xdma.sv]]
set r1e_regs_text [read_text [file join $repo_root rtl v41 r1e_measurement_regs.sv]]
set tri_probe_text [read_text [file join $repo_root rtl v41 nvp_i2c_tri_phase_probe.sv]]
set logger_text [read_text [file join $repo_root rtl v41 r1f_failed_txn_logger.sv]]
set r1f_regs_text [read_text [file join $repo_root rtl v41 r1f_measurement_regs.sv]]
set index_store_text [read_text \
  [file join $repo_root rtl v41 r1h_probe_index_bram_store.sv]]
set mmio_service_text [read_text \
  [file join $repo_root rtl v41 r1h_mmio_read_service.sv]]
set serial_text [read_text \
  [file join $repo_root rtl nvp r1f_transaction_serial_counter.vhd]]
require_exact_text $top_text \
  {localparam[ \t]+integer[ \t]+NVP_AUTOINIT_CLK_HZ[ \t]*=[ \t]*62500000[ \t]*;} \
  "AUTOINIT_CLOCK_HZ=62500000"
require_exact_text $top_text {\.I2C_HZ\(25000\)} \
  "AUTOINIT_I2C_HZ=25000"
require_exact_text $top_text \
  {\.ENABLE_MAREK_INIT_TABLE\(ENABLE_MAREK_INIT_TABLE\)} \
  "ENABLE_MAREK_INIT_TABLE generic propagation"
require_exact_text $tri_probe_text \
  {parameter[ \t]+integer[ \t]+PROBE_I2C_HZ[ \t]*=[ \t]*25000} \
  "R1f tri-phase PROBE_I2C_HZ=25000"
require_exact_text $r1e_regs_text {64'd132584734} \
  "EXPECTED_CNT_AT_INIT_DONE=132584734"
require_exact_text $logger_text \
  {input[ \t]+logic[ \t]+\[191:0\][ \t]+r1f_failed_txn_record} \
  "R1F_FAILED_TXN_RECORD_WIDTH=192"
require_exact_text $logger_text \
  {for[ \t]*\(bank_index[ \t]*=[ \t]*0;[ \t]*bank_index[ \t]*<[ \t]*6;} \
  "R1h failed-record payload has six parallel 32-bit banks"
require_exact_text $logger_text \
  {\.MEMORY_PRIMITIVE\("block"\)} \
  "R1h failed-record payload explicitly requests block memory"
require_exact_text $logger_text \
  {\.MEMORY_SIZE\(2048\)} \
  "R1h failed-record bank is exactly 64x32"
require_exact_text $index_store_text \
  {for[ \t]*\(phase_bank[ \t]*=[ \t]*0;[ \t]*phase_bank[ \t]*<[ \t]*3;} \
  "R1h probe-index payload has three independent phase banks"
require_exact_text $index_store_text \
  {\.MEMORY_SIZE\(8192\)} \
  "R1h probe-index bank is exactly 512x16"
require_exact_text $index_store_text \
  {\.MEMORY_PRIMITIVE\("block"\)} \
  "R1h probe-index payload explicitly requests block memory"
require_exact_text $mmio_service_text \
  {IDLE,[ \t\r\n]+RECORD_WAIT,[ \t\r\n]+INDEX_LOW_WAIT,[ \t\r\n]+INDEX_HIGH_WAIT,[ \t\r\n]+RESPONSE} \
  "R1h synchronous one-outstanding MMIO read-service states"
require_exact_text $mmio_service_text \
  {assign[ \t]+req_ready[ \t]*=[ \t]*\(state[ \t]*==[ \t]*IDLE\)[ \t]*&&[ \t]*!reset;} \
  "R1h MMIO accepts a request only while idle and outside reset"
require_exact_text $mmio_service_text \
  {assign[ \t]+rsp_valid[ \t]*=[ \t]*\(state[ \t]*==[ \t]*RESPONSE\)[ \t]*&&[ \t]*!reset;} \
  "R1h MMIO holds a response only in the response state outside reset"
require_exact_text $top_text \
  {\.clk\(axi_aclk\),[ \t]*\.reset\(\(~axi_aresetn\)[ \t]*\|\|[ \t]*nvp_por_reset\)} \
  "R1h MMIO service reset covers AXI reset and NVP POR reset"
if {[regexp {logic[ \t]+\[191:0\][ \t]+record_mem[ \t]*\[0:63\]} \
    $logger_text]} {
  error "forbidden R1g distributed failed-record payload remains in R1h"
}
if {[regexp {logic[ \t]+\[15:0\][ \t]+nack_index_memory[ \t]*\[0:2\][ \t]*\[0:511\]} \
    $tri_probe_text]} {
  error "forbidden R1g FF-backed probe-index payload remains in R1h"
}
require_exact_text $serial_text \
  {current_index[ \t]*:[ \t]*out[ \t]+std_logic_vector\(15 downto 0\)} \
  "R1F_TRANSACTION_INDEX_WIDTH=16"
require_exact_text $r1f_regs_text \
  {14'h20b0:[ \t]+read_data[ \t]*=[ \t]*32'd192;} \
  "R1F map record width=192"
require_exact_text $r1f_regs_text \
  {14'h20b8:[ \t]+read_data[ \t]*=[ \t]*32'd64;} \
  "R1F map log capacity=64"
require_exact_text $r1f_regs_text \
  {14'h20bc:[ \t]+read_data[ \t]*=[ \t]*32'h00000007;} \
  "R1F probe phase mask=WADDR_REGADDR_DATA"
require_exact_text $r1f_regs_text \
  {14'h20cc:[ \t]+read_data[ \t]*=[ \t]*32'd10000;} \
  "R1F probe target opportunities per phase=10000"
require_exact_text $r1f_regs_text \
  {14'h20d0:[ \t]+read_data[ \t]*=[ \t]*32'd10;} \
  "R1F probe blocks per phase=10"
require_exact_text $r1f_regs_text \
  {14'h20dc:[ \t]+read_data[ \t]*=[ \t]*32'd512;} \
  "R1F probe NACK index capacity per phase=512"
require_exact_text $tri_probe_text \
  {localparam[ \t]+logic[ \t]+\[7:0\][ \t]+SAFE_BANK[ \t]*=[ \t]*8'h00;} \
  "R1F safe probe bank=0x00"
require_exact_text $tri_probe_text \
  {localparam[ \t]+logic[ \t]+\[7:0\][ \t]+SAFE_REG[ \t]*=[ \t]*8'h85;} \
  "R1F safe probe register=0x85"
require_exact_text $tri_probe_text \
  {localparam[ \t]+logic[ \t]+\[7:0\][ \t]+SAFE_DATA[ \t]*=[ \t]*8'h00;} \
  "R1F safe probe data=0x00"
require_exact_text $top_text \
  {\.TARGET_OPPORTUNITIES_PER_PHASE\(10000\)} \
  "top freezes 10000 target opportunities per probe phase"
require_exact_text $top_text {\.BLOCK_COUNT_PER_PHASE\(10\)} \
  "top freezes 10 blocks per probe phase"
require_exact_text $top_text {\.NACK_INDEX_CAPACITY_PER_PHASE\(512\)} \
  "top freezes 512 NACK indices per probe phase"
require_exact_text $top_text \
  {\.SAFE_PROBE_BANK\(8'h00\),[ \t]*\.SAFE_PROBE_REGISTER\(8'h85\)} \
  "measurement map safe probe bank/register identity"
require_exact_text $top_text \
  {\.SAFE_PROBE_DATA\(8'h00\),[ \t]*\.SAFE_PROBE_TARGET_PROVEN\(1'b1\)} \
  "measurement map safe probe data/proven target identity"

set changed_output [exec git -C $repo_root -c core.quotepath=false \
  diff --name-only $exact_r1e_base_commit $source_commit --]
set changed_paths [list]
foreach changed [split $changed_output "\n"] {
  set changed [string trim $changed]
  if {$changed ne ""} {
    lappend changed_paths [string map [list "\\" "/"] $changed]
  }
}
set required_manifest_sources [lsort -unique [concat \
  $sv_rel_files $vhdl_rel_files $xdc_rel_files [list \
    $xdma_rel_file \
    scripts/v41/r1f_build.tcl \
    scripts/v41/xdma_config_common.tcl] \
  $changed_paths]]
set required_log_labels [list \
  PRE_INIT_EQUIVALENCE \
  EFFECTIVE_PRE_INIT_ARBITRATION \
  AUTOINIT_PHASE_AND_FAILED_TXN_SCOREBOARD \
  LEGACY_FIRST8_RECONCILIATION \
  TRANSACTION_INDEX_16 \
  FAILED_TXN_LOGGER_64_65 \
  TRI_PHASE_PROBE_SUCCESS \
  TRI_PHASE_PROBE_ABORT_RESTORE \
  TRI_PHASE_PROBE_SCL_TIMEOUT \
  TRI_PHASE_PROBE_ATTEMPT_LIMIT \
  TRI_PHASE_PROBE_SECONDARY_RESTORE_FAILURE \
  TRI_PHASE_PROBE_INDEX_OVERFLOW \
  TRI_PHASE_PROBE_IDLE_TIMEOUT \
  R1F_REGISTER_MAP \
  TOP_INTEGRATION \
  INHERITED_POWER_TIMING \
  INHERITED_D2B_SEQUENCE \
  R1F_PRODUCTION_TIMING_MODEL \
  HOST_TOOL_FIXTURES \
  R1H_FAILED_TXN_BRAM_ARCHITECTURE \
  R1H_PROBE_INDEX_BRAM_ARCHITECTURE \
  R1H_MEMORY_INFERENCE_ELABORATION \
  R1H_EVENT_STREAM_EQUIVALENCE \
  R1H_MMIO_TRANSACTION_EQUIVALENCE \
  R1H_MMIO_BACKPRESSURE \
  R1G_VS_R1H_DECODED_FIXTURE_EQUALITY \
  STATISTICAL_SCRIPT_FIXTURES]
set build_tcl_sha [sha256_file [file normalize [info script]]]
set manifest_summary [verify_prebuild_manifest \
  $prebuild_manifest $expected_prebuild_manifest_sha256 $repo_root \
  $source_commit $source_tree $build_tcl_sha \
  $required_manifest_sources $required_log_labels]

# The repository-owned helper is executable Tcl. Source it only after the
# exact Git identity/cleanliness and every manifest-bound source hash pass.
source $common_tcl
if {$v41_xdma::part ne $expected_part} {
  error "shared XDMA part mismatch: expected $expected_part, got $v41_xdma::part"
}

set git_words [list]
for {set word_index 0} {$word_index < 5} {incr word_index} {
  set first [expr {$word_index * 8}]
  lappend git_words [string range $source_commit $first [expr {$first + 7}]]
}
set reconstructed_commit [join $git_words ""]
if {$reconstructed_commit ne $source_commit} {
  error "provenance round trip failed: $reconstructed_commit != $source_commit"
}
set build_flags 32'h00000002
set generics [join [list \
  "SLOT_COUNT=2" \
  "GIT_SHA_W0=32'h[lindex $git_words 0]" \
  "GIT_SHA_W1=32'h[lindex $git_words 1]" \
  "GIT_SHA_W2=32'h[lindex $git_words 2]" \
  "GIT_SHA_W3=32'h[lindex $git_words 3]" \
  "GIT_SHA_W4=32'h[lindex $git_words 4]" \
  "BUILD_FLAGS=$build_flags" \
  "ENABLE_MAREK_INIT_TABLE=1"] " "]

set sentinel [file join $evidence_root R1H_ONE_CLEAN_BUILD_CONSUMED.marker]
set bit_path [file join $evidence_root artifacts $bit_filename]
if {[file exists $sentinel]} {
  error "the sole R1h clean build was already consumed: $sentinel"
}
if {[file exists $bit_path]} {
  error "R1h bit output already exists before the authorized build: $bit_path"
}

file mkdir $evidence_root
write_lines [file join $evidence_root R1H_PRECONSUMPTION_IDENTITY.txt] [list \
  "SOURCE_GIT_COMMIT=$source_commit" \
  "SOURCE_GIT_TREE=$source_tree" \
  "SOURCE_BRANCH=$actual_branch" \
  "SOURCE_TREE_CLEAN=YES" \
  "R1E_BASE_COMMIT=$exact_r1e_base_commit" \
  "R1F_SOURCE_COMMIT=$exact_r1f_commit" \
  "R1G_SOURCE_COMMIT=$exact_r1g_parent_commit" \
  "R1H_PARENT_COMMIT=$actual_parent_commit" \
  "R1H_COMMITS_ABOVE_R1E=$source_commit_count" \
  "R1G_FROZEN_BUILD_TCL=$frozen_r1g_build_tcl" \
  "R1G_FROZEN_BUILD_TCL_SHA256=$actual_frozen_r1g_build_tcl_sha256" \
  "VIVADO_VERSION_ACTUAL=$vivado_short" \
  "VIVADO_SW_BUILD_ACTUAL=$vivado_sw_build" \
  "PART_EXPECTED=$expected_part" \
  "TOP_EXPECTED=$expected_top" \
  "PREBUILD_MANIFEST_SHA256=$expected_prebuild_manifest_sha256" \
  "PRECONSUMPTION_GATE=PASS"]
write_lines [file join $evidence_root R1H_PREBUILD_MANIFEST_BINDING.txt] \
  $manifest_summary
file copy -force $prebuild_manifest \
  [file join $evidence_root R1H_BOUND_PREBUILD_MANIFEST.txt]
write_lines [file join $evidence_root R1H_FROZEN_INPUT_SHA256.txt] \
  $frozen_input_lines

set planned_inventory [list]
set planned_index 0
foreach rel $vhdl_rel_files {
  lappend planned_inventory \
    "[format %03d $planned_index]|VHDL|$rel|[sha256_file [file join $repo_root $rel]]"
  incr planned_index
}
foreach rel $sv_rel_files {
  lappend planned_inventory \
    "[format %03d $planned_index]|SYSTEMVERILOG|$rel|[sha256_file [file join $repo_root $rel]]"
  incr planned_index
}
lappend planned_inventory \
  "[format %03d $planned_index]|XCI|$xdma_rel_file|[sha256_file $xdma_source]"
incr planned_index
foreach rel $xdc_rel_files {
  lappend planned_inventory \
    "[format %03d $planned_index]|XDC|$rel|[sha256_file [file join $repo_root $rel]]"
  incr planned_index
}
write_lines [file join $evidence_root R1H_PLANNED_SOURCE_AND_CONSTRAINT_ORDER.txt] \
  $planned_inventory

write_lines [file join $evidence_root R1H_EXPECTED_RUNTIME_PROVENANCE.txt] [list \
  "BIT_SOURCE_COMMIT=$source_commit" \
  "BIT_SOURCE_TREE=$source_tree" \
  "EXPECTED_GIT_SHA_W0=0x[lindex $git_words 0]" \
  "EXPECTED_GIT_SHA_W1=0x[lindex $git_words 1]" \
  "EXPECTED_GIT_SHA_W2=0x[lindex $git_words 2]" \
  "EXPECTED_GIT_SHA_W3=0x[lindex $git_words 3]" \
  "EXPECTED_GIT_SHA_W4=0x[lindex $git_words 4]" \
  "EXPECTED_BUILD_FLAGS=0x00000002" \
  "SLOT_COUNT=2" \
  "ENABLE_MAREK_INIT_TABLE=1" \
  "AUTOINIT_I2C_HZ=25000" \
  "AUTOINIT_CLOCK_HZ=62500000" \
  "EXPECTED_CNT_AT_INIT_DONE=132584734" \
  "R1F_LOG_CAPACITY=64" \
  "R1F_TRANSACTION_INDEX_WIDTH=16" \
  "R1F_TABLE_SLOT_INDEX_WIDTH=16" \
  "R1F_RECORD_WIDTH=192" \
  "R1F_PROBE_PHASES=3" \
  "R1F_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=10000" \
  "R1F_PROBE_BLOCKS_PER_PHASE=10" \
  "R1F_PROBE_INDEX_LOG_CAPACITY_PER_PHASE=512" \
  "R1F_PROBE_BANK=0x00" \
  "R1F_PROBE_REGISTER=0x85" \
  "R1F_PROBE_DATA=0x00" \
  "RECONSTRUCTED_GIT_SHA=$reconstructed_commit" \
  "PROVENANCE_ROUND_TRIP=PASS" \
  "BUILD_FLAGS_MEANING=DIAGNOSTIC_SOURCE_IDENTITY_NO_PRODUCTION_MEANING" \
  "VIVADO_GENERIC_STRING=$generics"]

# Atomic creation is the irreversible one-build accounting boundary.
set sentinel_fh [open $sentinel {WRONLY CREAT EXCL}]
fconfigure $sentinel_fh -encoding utf-8 -translation lf
puts $sentinel_fh "R1H_ONE_CLEAN_BUILD_CONSUMED=YES"
puts $sentinel_fh "SOURCE_GIT_COMMIT=$source_commit"
puts $sentinel_fh "SOURCE_GIT_TREE=$source_tree"
puts $sentinel_fh "PREBUILD_MANIFEST_SHA256=$expected_prebuild_manifest_sha256"
puts $sentinel_fh "VIVADO_VERSION=$vivado_short"
puts $sentinel_fh "VIVADO_SW_BUILD=$vivado_sw_build"
puts $sentinel_fh "CONSUMED_BEFORE_CREATE_PROJECT=YES"
puts $sentinel_fh \
  "CONSUMED_UTC=[clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]"
close $sentinel_fh

set build_stage PRE_PROJECT
set synthesis_runs 0
set opt_design_runs 0
set place_design_runs 0
set route_design_runs 0
set bitstream_runs 0
set flow_rc [catch {
  set build_stage PROJECT_SETUP
  file mkdir $build_root
  cd $build_root

  set project_name v41_r1h_bram_backed_phase_complete
  set project_dir [file join $build_root vivado_project]
  create_project $project_name $project_dir -part $expected_part
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
  set xdma_source_sha [sha256_file $xdma_source]
  set xdma_copy_preimport_sha [sha256_file $xdma_copy]
  if {$xdma_source_sha ne $xdma_copy_preimport_sha} {
    error "import-copy XDMA XCI differs from exact source before import"
  }
  import_ip -files $xdma_copy
  set xdma_ip [get_ips -quiet xdma_v41_m1]
  if {[llength $xdma_ip] != 1} {
    error "expected exactly one imported XDMA IP"
  }
  v41_xdma::configure_minimal_c2h_stream $xdma_ip
  set xdma_property_lines [list \
    "SOURCE_XCI=$xdma_source" \
    "SOURCE_XCI_SHA256=$xdma_source_sha" \
    "PREIMPORT_COPY_SHA256=$xdma_copy_preimport_sha"]
  dict for {property expected} [v41_xdma::minimal_c2h_stream_config] {
    set actual [get_property $property $xdma_ip]
    if {$actual ne $expected} {
      error "queried imported XDMA property mismatch for $property: expected '$expected', got '$actual'"
    }
    lappend xdma_property_lines \
      "$property|EXPECTED=$expected|ACTUAL=$actual|PASS"
  }
  set imported_xci [get_property IP_FILE $xdma_ip]
  set imported_xci_object [get_files -quiet $imported_xci]
  if {[llength $imported_xci_object] != 1} {
    error "imported XDMA XCI object not found: $imported_xci"
  }
  set_property GENERATE_SYNTH_CHECKPOINT false $imported_xci_object
  generate_target all $xdma_ip
  lappend xdma_property_lines \
    "GENERATE_SYNTH_CHECKPOINT=[get_property GENERATE_SYNTH_CHECKPOINT $imported_xci_object]"
  write_lines [file join $evidence_root R1H_XDMA_IMPORTED_PROPERTY_AUDIT.txt] \
    $xdma_property_lines

  add_files -fileset constrs_1 -norecurse $xdc_files
  set_property PROCESSING_ORDER EARLY [get_files [lindex $xdc_files 0]]
  set_property PROCESSING_ORDER LATE [get_files [lrange $xdc_files 1 end]]

  set top $expected_top
  set_property top $top [get_filesets sources_1]
  set_property generic $generics [get_filesets sources_1]
  update_compile_order -fileset sources_1

  set queried_part [get_property PART [current_project]]
  set queried_top [get_property TOP [get_filesets sources_1]]
  set queried_generics [get_property GENERIC [get_filesets sources_1]]
  if {$queried_part ne $expected_part || $queried_top ne $expected_top ||
      $queried_generics ne $generics} {
    error "queried project part/top/generic contract differs from frozen R1f configuration"
  }

  set xdc_order_lines [list]
  for {set index 0} {$index < [llength $xdc_files]} {incr index} {
    set xdc_path [lindex $xdc_files $index]
    set expected_order [expr {$index == 0 ? "EARLY" : "LATE"}]
    set actual_order [get_property PROCESSING_ORDER [get_files $xdc_path]]
    if {$actual_order ne $expected_order} {
      error "XDC processing order mismatch for $xdc_path"
    }
    lappend xdc_order_lines \
      "[format %02d $index]|$expected_order|[relative_path_from_repo $repo_root $xdc_path]|[sha256_file $xdc_path]"
  }
  write_lines [file join $evidence_root R1H_XDC_ORDER_AND_SHA256.txt] \
    $xdc_order_lines

  set actual_compile_objects \
    [get_files -compile_order sources -used_in synthesis]
  set actual_compile_names [list]
  set actual_compile_lines [list]
  set compile_index 0
  foreach object $actual_compile_objects {
    set name [get_property NAME $object]
    lappend actual_compile_names $name
    lappend actual_compile_lines \
      "[format %03d $compile_index]|[get_property FILE_TYPE $object]|$name"
    incr compile_index
  }
  foreach required [concat $vhdl_files $sv_files] {
    if {[compile_order_index $actual_compile_names $required] < 0} {
      error "required synthesis source absent from queried compile order: $required"
    }
  }
  set prior_index -1
  foreach required $vhdl_files {
    set this_index [compile_order_index $actual_compile_names $required]
    if {$this_index <= $prior_index} {
      error "queried VHDL analysis order violates frozen R1f dependency order"
    }
    set prior_index $this_index
  }
  set top_compile_index [compile_order_index $actual_compile_names \
    [file join $repo_root rtl top ahd_capture_top_xdma.sv]]
  foreach required [list \
    [file join $repo_root rtl v41 r1h_probe_index_bram_store.sv] \
    [file join $repo_root rtl v41 nvp_i2c_tri_phase_probe.sv] \
    [file join $repo_root rtl v41 r1f_failed_txn_logger.sv] \
    [file join $repo_root rtl v41 r1f_measurement_regs.sv] \
    [file join $repo_root rtl v41 r1h_mmio_read_service.sv] \
    [file join $repo_root rtl v41 control_status_regs.sv]] {
    if {[compile_order_index $actual_compile_names $required] >=
        $top_compile_index} {
      error "R1h SystemVerilog dependency is not before the queried top compile unit: $required"
    }
  }
  set index_store_compile_index [compile_order_index $actual_compile_names \
    [file join $repo_root rtl v41 r1h_probe_index_bram_store.sv]]
  set probe_compile_index [compile_order_index $actual_compile_names \
    [file join $repo_root rtl v41 nvp_i2c_tri_phase_probe.sv]]
  if {$index_store_compile_index >= $probe_compile_index} {
    error "R1h probe-index BRAM wrapper is not before its probe consumer"
  }
  write_lines [file join $evidence_root R1H_QUERIED_SYNTHESIS_COMPILE_ORDER.txt] \
    $actual_compile_lines

  write_lines [file join $evidence_root R1H_BUILD_PROVENANCE.txt] [list \
    "SOURCE_GIT_COMMIT=$source_commit" \
    "SOURCE_GIT_TREE=$source_tree" \
    "SOURCE_BRANCH=$actual_branch" \
    "SOURCE_TREE_CLEAN=YES" \
    "BUILD_FLAGS=0x00000002" \
    "GIT_SHA_W0=0x[lindex $git_words 0]" \
    "GIT_SHA_W1=0x[lindex $git_words 1]" \
    "GIT_SHA_W2=0x[lindex $git_words 2]" \
    "GIT_SHA_W3=0x[lindex $git_words 3]" \
    "GIT_SHA_W4=0x[lindex $git_words 4]" \
    "VIVADO_VERSION_QUERIED=$vivado_short" \
    "VIVADO_SW_BUILD_QUERIED=$vivado_sw_build" \
    "PART_QUERIED=$queried_part" \
    "TOP_QUERIED=$queried_top" \
    "GENERICS_QUERIED=$queried_generics" \
    "SLOT_COUNT=2" \
    "ENABLE_MAREK_INIT_TABLE=1" \
    "AUTOINIT_I2C_HZ=25000" \
    "AUTOINIT_CLOCK_HZ=62500000" \
    "EXPECTED_CNT_AT_INIT_DONE=132584734" \
    "R1F_LOG_CAPACITY=64" \
    "R1F_TRANSACTION_INDEX_WIDTH=16" \
    "R1F_TABLE_SLOT_INDEX_WIDTH=16" \
    "R1F_RECORD_WIDTH=192" \
    "R1F_PROBE_PHASES=3" \
    "R1F_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=10000" \
    "R1F_PROBE_BLOCKS_PER_PHASE=10" \
    "R1F_PROBE_INDEX_LOG_CAPACITY_PER_PHASE=512" \
    "R1F_PROBE_BANK=0x00" \
    "R1F_PROBE_REGISTER=0x85" \
    "R1F_PROBE_DATA=0x00" \
    "XCI_SOURCE=$xdma_source" \
    "XCI_SOURCE_SHA256=$xdma_source_sha" \
    "PREBUILD_MANIFEST_SHA256=$expected_prebuild_manifest_sha256" \
    "NO_INCREMENTAL_CHECKPOINT_INPUT=YES"]

  set build_stage SYNTHESIS
  set synthesis_runs 1
  synth_design -top $top -part $expected_part -flatten_hierarchy rebuilt
  set synthesized_cells [get_cells -quiet -hier]
  set synthesized_nets [get_nets -quiet -hier]
  set synthesis_status [expr {
    [llength $synthesized_cells] > 0 && [llength $synthesized_nets] > 0
      ? "PASS" : "FAIL"
  }]
  if {$synthesis_status ne "PASS"} {
    error "queried post-synthesis netlist is empty"
  }
  set synth_dcp [file join $evidence_root R1H_synth.dcp]
  write_checkpoint -force $synth_dcp
  set synth_dcp_sha256 [sha256_file $synth_dcp]
  set post_synth_util_report \
    [file join $evidence_root R1H_utilization_post_synth.rpt]
  report_utilization -file $post_synth_util_report
  report_utilization -hierarchical -hierarchical_depth 20 \
    -file [file join $evidence_root R1H_utilization_hierarchical_post_synth.rpt]
  report_timing_summary -delay_type min_max -max_paths 100 \
    -file [file join $evidence_root R1H_timing_post_synth.rpt]

  set build_stage POST_SYNTH_RESOURCE_GATE
  # Mandatory R1h post-synthesis resource gate. This block must remain
  # textually and operationally before opt_design/place_design. Attributes in
  # RTL are not evidence: only leaf primitives in the exact synthesized
  # netlist satisfy the mapping contract.
  set post_synth_util_text [report_utilization -return_string]
  lassign [utilization_row $post_synth_util_text "Slice LUTs*"] \
    post_synth_slice_luts_raw post_synth_slice_luts_available_raw
  lassign [utilization_row $post_synth_util_text "LUT as Logic"] \
    post_synth_logic_luts_raw post_synth_logic_luts_available_raw
  lassign [utilization_row $post_synth_util_text "LUT as Memory"] \
    post_synth_lutram_raw post_synth_lutram_available_raw
  lassign [utilization_row $post_synth_util_text "Slice Registers"] \
    post_synth_slice_registers_raw post_synth_registers_available_raw
  set post_synth_slice_luts [parse_nonnegative_integer \
    $post_synth_slice_luts_raw POST_SYNTH_SLICE_LUTS]
  set post_synth_logic_luts [parse_nonnegative_integer \
    $post_synth_logic_luts_raw POST_SYNTH_LOGIC_LUTS]
  set post_synth_lutram [parse_nonnegative_integer \
    $post_synth_lutram_raw POST_SYNTH_LUTRAM]
  set post_synth_slice_registers [parse_nonnegative_integer \
    $post_synth_slice_registers_raw POST_SYNTH_SLICE_REGISTERS]
  set post_synth_slice_luts_available [parse_nonnegative_integer \
    $post_synth_slice_luts_available_raw POST_SYNTH_SLICE_LUTS_AVAILABLE]
  set post_synth_registers_available [parse_nonnegative_integer \
    $post_synth_registers_available_raw POST_SYNTH_SLICE_REGISTERS_AVAILABLE]
  set post_synth_muxf7 [llength \
    [get_cells -quiet -hier -filter {REF_NAME == MUXF7}]]
  set post_synth_muxf8 [llength \
    [get_cells -quiet -hier -filter {REF_NAME == MUXF8}]]
  set post_synth_ramb18 [llength \
    [get_cells -quiet -hier -filter {REF_NAME == RAMB18E1}]]
  set post_synth_ramb36 [llength \
    [get_cells -quiet -hier -filter {REF_NAME == RAMB36E1}]]

  set record_region [list {r1f_failed_txn_logger}]
  set index_region [list {index_payload_store}]
  set waddr_region [list {index_payload_store} {gen_index_bram\[0\]}]
  set regaddr_region [list {index_payload_store} {gen_index_bram\[1\]}]
  set data_region [list {index_payload_store} {gen_index_bram\[2\]}]

  set record_ramb18 [cell_names_by_ref_patterns RAMB18E1 $record_region]
  set record_ramb36 [cell_names_by_ref_patterns RAMB36E1 $record_region]
  set waddr_ramb18 [cell_names_by_ref_patterns RAMB18E1 $waddr_region]
  set regaddr_ramb18 [cell_names_by_ref_patterns RAMB18E1 $regaddr_region]
  set data_ramb18 [cell_names_by_ref_patterns RAMB18E1 $data_region]
  set index_ramb36 [cell_names_by_ref_patterns RAMB36E1 $index_region]
  set record_ram64m [cell_names_by_ref_patterns RAM64M $record_region]
  set record_ramd64e [cell_names_by_ref_patterns RAMD64E $record_region]
  set index_ram64m [cell_names_by_ref_patterns RAM64M $index_region]
  set index_ramd64e [cell_names_by_ref_patterns RAMD64E $index_region]
  set record_fdre [cell_names_by_ref_patterns FDRE $record_region]
  set index_fdre [cell_names_by_ref_patterns FDRE $index_region]

  set record_payload_ff_all [list]
  set index_payload_ff_all [list]
  foreach ff_ref {FDRE FDSE FDCE FDPE} {
    set record_payload_ff_all [concat $record_payload_ff_all \
      [cell_names_by_ref_patterns $ff_ref $record_region]]
    set index_payload_ff_all [concat $index_payload_ff_all \
      [cell_names_by_ref_patterns $ff_ref $index_region]]
  }
  set record_payload_ff_all [lsort -dictionary -unique $record_payload_ff_all]
  set index_payload_ff_all [lsort -dictionary -unique $index_payload_ff_all]

  set new_payload_ramb18_total [expr {
    [llength $record_ramb18] + [llength $waddr_ramb18] +
    [llength $regaddr_ramb18] + [llength $data_ramb18]
  }]
  set new_payload_ramb36_total [expr {
    [llength $record_ramb36] + [llength $index_ramb36]
  }]

  set primitive_lines [list \
    "SOURCE_GIT_COMMIT=$source_commit" \
    "SOURCE_GIT_TREE=$source_tree" \
    "VIVADO_VERSION=$vivado_short" \
    "VIVADO_SW_BUILD=$vivado_sw_build" \
    "R1H_SYNTH_DCP=$synth_dcp" \
    "R1H_SYNTH_DCP_SHA256=$synth_dcp_sha256"]
  append_primitive_inventory primitive_lines \
    FAILED_RECORD_PAYLOAD_RAMB18 $record_ramb18
  append_primitive_inventory primitive_lines \
    FAILED_RECORD_PAYLOAD_RAMB36 $record_ramb36
  append_primitive_inventory primitive_lines \
    WADDR_INDEX_PAYLOAD_RAMB18 $waddr_ramb18
  append_primitive_inventory primitive_lines \
    REGADDR_INDEX_PAYLOAD_RAMB18 $regaddr_ramb18
  append_primitive_inventory primitive_lines \
    DATA_INDEX_PAYLOAD_RAMB18 $data_ramb18
  append_primitive_inventory primitive_lines \
    INDEX_PAYLOAD_RAMB36 $index_ramb36
  append_primitive_inventory primitive_lines \
    FAILED_RECORD_PAYLOAD_RAM64M $record_ram64m
  append_primitive_inventory primitive_lines \
    FAILED_RECORD_PAYLOAD_RAMD64E $record_ramd64e
  append_primitive_inventory primitive_lines \
    INDEX_PAYLOAD_RAM64M $index_ram64m
  append_primitive_inventory primitive_lines \
    INDEX_PAYLOAD_RAMD64E $index_ramd64e
  append_primitive_inventory primitive_lines \
    FAILED_RECORD_PAYLOAD_FDRE $record_fdre
  append_primitive_inventory primitive_lines \
    INDEX_PAYLOAD_FDRE_TOTAL $index_fdre
  append_primitive_inventory primitive_lines \
    FAILED_RECORD_REGION_ALL_FF $record_payload_ff_all
  append_primitive_inventory primitive_lines \
    INDEX_PAYLOAD_REGION_ALL_FF $index_payload_ff_all
  lappend primitive_lines \
    "R1H_NEW_PAYLOAD_RAMB18_TOTAL=$new_payload_ramb18_total" \
    "R1H_NEW_PAYLOAD_RAMB36_TOTAL=$new_payload_ramb36_total"
  write_lines [file join $evidence_root \
    R1H_POST_SYNTH_PAYLOAD_PRIMITIVE_INVENTORY.txt] $primitive_lines

  set post_synth_mapping_gate PASS
  if {[llength $record_ramb18] != 6 ||
      [llength $waddr_ramb18] != 1 ||
      [llength $regaddr_ramb18] != 1 ||
      [llength $data_ramb18] != 1 ||
      $new_payload_ramb18_total != 9 ||
      $new_payload_ramb36_total != 0 ||
      [llength $record_ram64m] != 0 ||
      [llength $record_ramd64e] != 0 ||
      [llength $index_ram64m] != 0 ||
      [llength $index_ramd64e] != 0 ||
      [llength $record_fdre] > 192 ||
      [llength $index_fdre] > 192 ||
      [llength $record_payload_ff_all] > 192 ||
      [llength $index_payload_ff_all] > 192} {
    set post_synth_mapping_gate FAIL
  }

  set post_synth_resource_margin_gate PASS
  if {$post_synth_slice_luts_available != 20800 ||
      $post_synth_registers_available != 41600 ||
      $post_synth_slice_luts > 18720 ||
      $post_synth_slice_registers > 37440} {
    set post_synth_resource_margin_gate FAIL
  }
  set post_synth_combined_gate [expr {
    $post_synth_mapping_gate eq "PASS" &&
    $post_synth_resource_margin_gate eq "PASS" ? "PASS" : "FAIL"
  }]

  write_lines [file join $evidence_root R1H_POST_SYNTH_RESOURCE_GATE.txt] [list \
    "SOURCE_GIT_COMMIT=$source_commit" \
    "SOURCE_GIT_TREE=$source_tree" \
    "VIVADO_VERSION=$vivado_short" \
    "VIVADO_SW_BUILD=$vivado_sw_build" \
    "SYNTHESIS=$synthesis_status" \
    "R1H_SYNTH_DCP=$synth_dcp" \
    "R1H_SYNTH_DCP_SHA256=$synth_dcp_sha256" \
    "POST_SYNTH_SLICE_LUTS=$post_synth_slice_luts" \
    "POST_SYNTH_SLICE_LUTS_LIMIT=18720" \
    "POST_SYNTH_LOGIC_LUTS=$post_synth_logic_luts" \
    "POST_SYNTH_LUTRAM=$post_synth_lutram" \
    "POST_SYNTH_SLICE_REGISTERS=$post_synth_slice_registers" \
    "POST_SYNTH_SLICE_REGISTERS_LIMIT=37440" \
    "POST_SYNTH_MUXF7=$post_synth_muxf7" \
    "POST_SYNTH_MUXF8=$post_synth_muxf8" \
    "POST_SYNTH_RAMB18=$post_synth_ramb18" \
    "POST_SYNTH_RAMB36=$post_synth_ramb36" \
    "POST_SYNTH_SLICE_LUTS_AVAILABLE=$post_synth_slice_luts_available" \
    "POST_SYNTH_SLICE_REGISTERS_AVAILABLE=$post_synth_registers_available" \
    "FAILED_RECORD_PAYLOAD_RAMB18=[llength $record_ramb18]" \
    "FAILED_RECORD_PAYLOAD_RAMB36=[llength $record_ramb36]" \
    "WADDR_INDEX_PAYLOAD_RAMB18=[llength $waddr_ramb18]" \
    "REGADDR_INDEX_PAYLOAD_RAMB18=[llength $regaddr_ramb18]" \
    "DATA_INDEX_PAYLOAD_RAMB18=[llength $data_ramb18]" \
    "R1H_NEW_PAYLOAD_RAMB18_TOTAL=$new_payload_ramb18_total" \
    "R1H_NEW_PAYLOAD_RAMB36_TOTAL=$new_payload_ramb36_total" \
    "FAILED_RECORD_PAYLOAD_FDRE=[llength $record_fdre]" \
    "INDEX_PAYLOAD_FDRE_TOTAL=[llength $index_fdre]" \
    "FAILED_RECORD_REGION_ALL_FF=[llength $record_payload_ff_all]" \
    "INDEX_PAYLOAD_REGION_ALL_FF=[llength $index_payload_ff_all]" \
    "FAILED_RECORD_PAYLOAD_RAM64M=[llength $record_ram64m]" \
    "FAILED_RECORD_PAYLOAD_RAMD64E=[llength $record_ramd64e]" \
    "INDEX_PAYLOAD_RAM64M=[llength $index_ram64m]" \
    "INDEX_PAYLOAD_RAMD64E=[llength $index_ramd64e]" \
    "POST_SYNTH_MEMORY_MAPPING_GATE=$post_synth_mapping_gate" \
    "POST_SYNTH_RESOURCE_MARGIN_GATE=$post_synth_resource_margin_gate" \
    "OPT_DESIGN_STARTED_BEFORE_GATE=NO" \
    "PLACE_DESIGN_STARTED_BEFORE_GATE=NO" \
    "POST_SYNTH_COMBINED_GATE=$post_synth_combined_gate"]
  if {$post_synth_combined_gate ne "PASS"} {
    error "BLOCKED_R1H_POST_SYNTH_RESOURCE_MARGIN_OR_MEMORY_MAPPING"
  }

  set build_stage OPT_DESIGN
  set opt_design_runs 1
  opt_design -directive Explore
  set opt_status PASS
  set build_stage PLACE_DESIGN
  set place_design_runs 1
  place_design -directive Explore
  set leaf_cells \
    [get_cells -quiet -hier -filter {PRIMITIVE_LEVEL == LEAF}]
  set placed_cell_count 0
  foreach cell $leaf_cells {
    if {[safe_property $cell LOC] ni [list EMPTY NOT_AVAILABLE]} {
      incr placed_cell_count
    }
  }
  set place_status [expr {$placed_cell_count > 0 ? "PASS" : "FAIL"}]
  if {$place_status ne "PASS"} {
    error "queried placed primitive count is zero"
  }
  set build_stage PHYS_OPT_DESIGN
  phys_opt_design -directive Explore
  set build_stage ROUTE_DESIGN
  set route_design_runs 1
  route_design -directive Explore
  set routed_dcp [file join $evidence_root R1H_routed.dcp]
  write_checkpoint -force $routed_dcp
  set routed_dcp_sha256 [sha256_file $routed_dcp]

  set route_report [file join $evidence_root R1H_route_status.rpt]
  set timing_report [file join $evidence_root R1H_timing_summary.rpt]
  set drc_report [file join $evidence_root R1H_drc.rpt]
  set bus_skew_report [file join $evidence_root R1H_bus_skew.rpt]
  set cdc_report [file join $evidence_root R1H_cdc.rpt]
  set util_report [file join $evidence_root R1H_utilization.rpt]
  set power_report \
    [file join $evidence_root R1H_power_aggregate_and_hierarchical.rpt]

  report_route_status -file $route_report
  report_timing_summary -delay_type min_max -max_paths 1000 \
    -file $timing_report
  report_timing -delay_type max -max_paths 1000 -nworst 20 \
    -file [file join $evidence_root R1H_timing_complete_setup.rpt]
  report_timing -delay_type min -max_paths 1000 -nworst 20 \
    -file [file join $evidence_root R1H_timing_complete_hold.rpt]
  report_drc -file $drc_report
  check_timing -verbose \
    -file [file join $evidence_root R1H_check_timing.rpt]
  report_exceptions -coverage \
    -file [file join $evidence_root R1H_exception_coverage.rpt]
  report_bus_skew -file $bus_skew_report
  report_clock_interaction \
    -file [file join $evidence_root R1H_clock_interaction.rpt]
  report_cdc -details -file $cdc_report
  report_utilization -file $util_report
  report_utilization -hierarchical -hierarchical_depth 20 \
    -file [file join $evidence_root R1H_utilization_hierarchical.rpt]
  report_clock_utilization \
    -file [file join $evidence_root R1H_clock_utilization.rpt]
  report_design_analysis -congestion \
    -file [file join $evidence_root R1H_congestion.rpt]
  report_methodology \
    -file [file join $evidence_root R1H_methodology.rpt]
  report_power -hierarchical_depth 20 -file $power_report
  report_io -file [file join $evidence_root R1H_io.rpt]
  report_clocks -file [file join $evidence_root R1H_clocks.rpt]
  report_property -file [file join $evidence_root R1H_design_properties.txt] \
    [current_design]

  set nvp_io_ports [get_ports -quiet {nvp_scl nvp_sda}]
  if {[llength $nvp_io_ports] != 2} {
    error "expected exactly two NVP I2C ports"
  }
  set nvp_iobuf_cells [get_cells -quiet -hier -regexp \
    {.*NVP_(SCL|SDA)_IOBUF.*}]
  if {[llength $nvp_iobuf_cells] != 2} {
    error "expected exactly two routed NVP IOBUF cells"
  }
  report_property \
    -file [file join $evidence_root R1H_nvp_iobuf_properties.txt] \
    $nvp_iobuf_cells
  set nvp_t_pins [get_pins -quiet -of_objects $nvp_iobuf_cells \
    -filter {REF_PIN_NAME == T}]
  set nvp_o_pins [get_pins -quiet -of_objects $nvp_iobuf_cells \
    -filter {REF_PIN_NAME == O}]
  if {[llength $nvp_t_pins] != 2 || [llength $nvp_o_pins] != 2} {
    error "NVP IOBUF T/O pin inventory is incomplete"
  }
  set nvp_oen_paths [get_timing_paths -quiet -delay_type max \
    -to $nvp_t_pins -max_paths 16 -nworst 8]
  if {[llength $nvp_oen_paths] == 0} {
    error "OEN-to-NVP-IOBUF timing path class is empty"
  }
  report_timing -delay_type max -to $nvp_t_pins -max_paths 32 -nworst 16 \
    -file [file join $evidence_root R1H_nvp_oen_to_iobuf_paths.rpt]

  set nvp_sync_cells [get_cells -quiet -hier -regexp \
    {.*(sda_sync|scl_sync).*}]
  if {[llength $nvp_sync_cells] < 8} {
    error "expected at least eight inherited/probe SCL/SDA synchronizer cells"
  }
  set sync_placement_lines [list \
    "SYNCHRONIZER_CELL_COUNT=[llength $nvp_sync_cells]"]
  foreach cell [lsort -dictionary $nvp_sync_cells] {
    lappend sync_placement_lines \
      "CELL=[safe_property $cell NAME]|REF=[safe_property $cell REF_NAME]|LOC=[safe_property $cell LOC]|BEL=[safe_property $cell BEL]|ASYNC_REG=[safe_property $cell ASYNC_REG]|SHREG_EXTRACT=[safe_property $cell SHREG_EXTRACT]"
  }
  write_lines [file join $evidence_root R1H_nvp_synchronizer_placement.txt] \
    $sync_placement_lines
  set sync_first_cells [get_cells -quiet -hier -regexp \
    {.*(sda_sync(_r)?|scl_sync(_r)?)_reg\[0\]$}]
  set sync_first_d [get_pins -quiet -of_objects $sync_first_cells \
    -filter {REF_PIN_NAME == D}]
  if {[llength $sync_first_d] < 4} {
    error "first-stage SCL/SDA synchronizer D-pin inventory is incomplete"
  }
  set pad_sync_paths [get_timing_paths -quiet -delay_type max \
    -from $nvp_o_pins -to $sync_first_d -max_paths 16 -nworst 8]
  if {[llength $pad_sync_paths] == 0} {
    error "NVP-pad-to-synchronizer timing path class is empty"
  }
  report_timing -delay_type max -from $nvp_o_pins -to $sync_first_d \
    -max_paths 32 -nworst 16 \
    -file [file join $evidence_root R1H_nvp_pad_to_synchronizer_paths.rpt]
  write_lines [file join $evidence_root R1H_nvp_output_fanin.txt] \
    [lsort [get_property NAME [all_fanin -flat -to $nvp_t_pins]]]
  write_lines [file join $evidence_root R1H_nvp_input_fanout.txt] \
    [lsort [get_property NAME [all_fanout -flat -from $nvp_o_pins]]]

  set tri_probe_inventory [write_region_inventory $evidence_root \
    POST_INIT_TRI_PHASE_PROBE {.*POST_INIT_TRI_PHASE_PROBE.*}]
  set failed_logger_inventory [write_region_inventory $evidence_root \
    R1F_FAILED_TXN_LOGGER {.*R1F_FAILED_TXN_LOGGER.*}]
  set measurement_regs_inventory [write_region_inventory $evidence_root \
    R1F_MEASUREMENT_REGS {.*R1F_MEASUREMENT_REGS.*}]
  set index_store_inventory [write_region_inventory $evidence_root \
    R1H_PROBE_INDEX_STORE {.*INDEX_PAYLOAD_STORE.*}]
  set mmio_service_inventory [write_region_inventory $evidence_root \
    R1H_MMIO_READ_SERVICE {.*R1H_MMIO_READ_SERVICE.*}]
  set serial_inventory [write_region_inventory $evidence_root \
    R1F_TRANSACTION_SERIAL \
    {.*(R1F_TRANSACTION_SERIAL|r1f_transaction_serial).*}]
  set lifecycle_inventory [write_region_inventory $evidence_root \
    LIFECYCLE_MONITOR {.*(LIFECYCLE_MONITOR|lifecycle).*}]
  set autoinit_inventory [write_region_inventory $evidence_root \
    NVP_AUTOINIT {.*(NVP_AUTOINIT|nvp_autoinit).*}]

  set vdo_ports [get_ports -quiet {vdo1_data[*]}]
  if {[llength $vdo_ports] != 8} {
    error "expected exactly eight VDO input ports"
  }
  report_timing -delay_type max -from $vdo_ports -max_paths 32 -nworst 4 \
    -file [file join $evidence_root R1H_vdo_setup_paths.rpt]
  report_timing -delay_type min -from $vdo_ports -max_paths 32 -nworst 4 \
    -file [file join $evidence_root R1H_vdo_hold_paths.rpt]

  set worst_setup [get_timing_paths -quiet -delay_type max \
    -max_paths 1 -nworst 1]
  set worst_hold [get_timing_paths -quiet -delay_type min \
    -max_paths 1 -nworst 1]
  set vdo_setup [get_timing_paths -quiet -delay_type max -from $vdo_ports \
    -max_paths 1 -nworst 1]
  set vdo_hold [get_timing_paths -quiet -delay_type min -from $vdo_ports \
    -max_paths 1 -nworst 1]
  if {[llength $worst_setup] != 1 || [llength $worst_hold] != 1 ||
      [llength $vdo_setup] != 1 || [llength $vdo_hold] != 1} {
    error "required global or VDO timing path class is empty"
  }
  set wns [get_property SLACK $worst_setup]
  set whs [get_property SLACK $worst_hold]
  set vdo_wns [get_property SLACK $vdo_setup]
  set vdo_whs [get_property SLACK $vdo_hold]
  foreach value [list $wns $whs $vdo_wns $vdo_whs] {
    if {![string is double -strict $value]} {
      error "queried timing slack is not numeric: $value"
    }
  }

  set drc_errors 0
  set drc_critical_warnings 0
  set drc_warnings 0
  set all_drc_violations [get_drc_violations -quiet]
  foreach violation $all_drc_violations {
    set severity [string toupper [get_property SEVERITY $violation]]
    switch -- $severity {
      ERROR { incr drc_errors }
      {CRITICAL WARNING} { incr drc_critical_warnings }
      WARNING { incr drc_warnings }
    }
  }
  set reqp_checks [get_drc_checks -quiet REQP-1839]
  if {[llength $reqp_checks] != 1} {
    error "Vivado did not expose exactly one REQP-1839 DRC check object"
  }
  set reqp_check [lindex $reqp_checks 0]
  report_property -all \
    -file [file join $evidence_root R1H_REQP_1839_CHECK_PROPERTIES.txt] \
    $reqp_check
  set reqp_result_name R1F_REQP_1839_SEMANTIC
  set reqp_semantic_report \
    [file join $evidence_root R1H_REQP_1839_SEMANTIC.rpt]
  report_drc -name $reqp_result_name -checks $reqp_check \
    -file $reqp_semantic_report
  set reqp_1839_objects [get_drc_violations -quiet \
    -name $reqp_result_name {REQP-1839*}]
  set reqp_1839_names [list]
  if {[llength $reqp_1839_objects] != 0} {
    set reqp_1839_names \
      [lsort -dictionary -unique [get_property NAME $reqp_1839_objects]]
  }
  set reqp_1839_semantic_count [llength $reqp_1839_names]
  set reqp_1839_raw_text_count \
    [regexp -all {REQP-1839} [read_text $reqp_semantic_report]]
  set reqp_1839_lines [list \
    "REQP_1839_CHECK_OBJECT_COUNT=[llength $reqp_checks]" \
    "REQP_1839_CHECK_OBJECT=[get_property NAME $reqp_check]" \
    "REQP_1839_RESULT_NAME=$reqp_result_name" \
    "REQP_1839_RETURNED_OBJECT_COUNT=[llength $reqp_1839_objects]" \
    "REQP_1839_SEMANTIC_COUNT=$reqp_1839_semantic_count" \
    "REQP_1839_RAW_TEXT_COUNT=$reqp_1839_raw_text_count" \
    "REQP_1839_RAW_TEXT_COUNT_NOT_USED_AS_GATE=YES"]
  set reqp_index 0
  foreach violation_name $reqp_1839_names {
    if {![string match "REQP-1839#*" $violation_name]} {
      error "named REQP result exposed a foreign violation object: $violation_name"
    }
    set one_violation [get_drc_violations -quiet \
      -name $reqp_result_name [list $violation_name]]
    if {[llength $one_violation] != 1} {
      error "per-violation REQP object cardinality failure: $violation_name"
    }
    report_property -all \
      -file [file join $evidence_root \
        [format "R1H_REQP_1839_VIOLATION_%02d_PROPERTIES.txt" $reqp_index]] \
      $one_violation
    lappend reqp_1839_lines \
      "VIOLATION_INDEX=$reqp_index|OBJECT=$violation_name"
    incr reqp_index
  }
  write_lines [file join $evidence_root R1H_REQP_1839_VIOLATION_OBJECTS.txt] \
    $reqp_1839_lines

  set route_text [read_text $route_report]
  set route_errors -1
  if {![regexp -nocase \
      {# of nets with routing errors[^:]*:[ \t]*([0-9]+)} \
      $route_text -> route_errors]} {
    regexp -nocase \
      {number of nets with routing errors[^:]*:[ \t]*([0-9]+)} \
      $route_text -> route_errors
  }
  set route_status [expr {$route_errors == 0 ? "PASS" : "FAIL"}]
  set bus_skew_violations \
    [regexp -all {Slack \(VIOLATED\)} [read_text $bus_skew_report]]
  set cdc_text [read_text $cdc_report]
  set cdc_critical [regexp -all -line \
    {^CDC-[0-9]+[ \t]+Critical[ \t]+} $cdc_text]
  set cdc_unknown [regexp -all -line \
    {^CDC-[0-9]+[ \t]+Unknown[ \t]+} $cdc_text]

  set util_text [report_utilization -return_string]
  lassign [utilization_row $util_text "Slice LUTs*"] \
    lut_used lut_available
  lassign [utilization_row $util_text "Slice Registers"] \
    ff_used ff_available
  lassign [utilization_row $util_text "Block RAM Tile"] \
    bram_used bram_available
  lassign [utilization_row $util_text "DSPs"] \
    dsp_used dsp_available
  set ramb36_used [llength \
    [get_cells -quiet -hier -filter {REF_NAME == RAMB36E1}]]
  set ramb18_used [llength \
    [get_cells -quiet -hier -filter {REF_NAME == RAMB18E1}]]
  set bufg_used [llength \
    [get_cells -quiet -hier -filter {REF_NAME =~ BUFG*}]]
  set mmcm_used [llength \
    [get_cells -quiet -hier -filter {REF_NAME =~ MMCM*}]]

  array set ram_type_count {}
  foreach cell $leaf_cells {
    set ref_name [safe_property $cell REF_NAME]
    if {[regexp {^(RAM|RAMB|SRL)} $ref_name]} {
      if {![info exists ram_type_count($ref_name)]} {
        set ram_type_count($ref_name) 0
      }
      incr ram_type_count($ref_name)
    }
  }
  set ram_lines [list \
    "RAMB36_USED=$ramb36_used" \
    "RAMB18_USED=$ramb18_used"]
  foreach ref_name [lsort [array names ram_type_count]] {
    lappend ram_lines \
      "REF_NAME=$ref_name|COUNT=$ram_type_count($ref_name)"
  }
  write_lines [file join $evidence_root R1H_ram_bram_distributed_inventory.txt] \
    $ram_lines

  set implementation_gate PASS
  if {$synthesis_status ne "PASS" ||
      $place_status ne "PASS" ||
      $route_status ne "PASS" ||
      $route_errors != 0 ||
      $wns < 0.0 ||
      $whs <= 0.0 ||
      $vdo_wns <= 0.0 ||
      $vdo_whs <= 0.0 ||
      $drc_errors != 0 ||
      $drc_critical_warnings != 0 ||
      $reqp_1839_semantic_count != 4 ||
      $cdc_critical != 0 ||
      $cdc_unknown != 0 ||
      $bus_skew_violations != 0} {
    set implementation_gate FAIL
  }

  set bit_generated NO
  set bit_sha256 NOT_GENERATED
  set source_commit_to_bit_provenance NOT_APPLICABLE_NO_BIT
  if {$implementation_gate eq "PASS"} {
    file mkdir [file dirname $bit_path]
    set build_stage WRITE_BITSTREAM
    set bitstream_runs 1
    write_bitstream $bit_path
    set bit_generated YES
    set bit_sha256 [sha256_file $bit_path]
    set source_commit_to_bit_provenance PASS
  }

  write_lines [file join $evidence_root R1H_BUILD_RESULT.txt] [list \
    "TASK=V41_NVP_R1H_BRAM_BACKED_PHASE_COMPLETE_OBSERVABILITY_AND_LARGE_SAMPLE_AB" \
    "FULL_BUILDS=1" \
    "SYNTHESIS_RUNS=$synthesis_runs" \
    "OPT_DESIGN_RUNS=$opt_design_runs" \
    "PLACE_DESIGN_RUNS=$place_design_runs" \
    "ROUTE_DESIGN_RUNS=$route_design_runs" \
    "BITSTREAM_RUNS=$bitstream_runs" \
    "SOURCE_GIT_COMMIT=$source_commit" \
    "SOURCE_GIT_TREE=$source_tree" \
    "SOURCE_BRANCH=$actual_branch" \
    "VIVADO_VERSION=$vivado_short" \
    "VIVADO_SW_BUILD=$vivado_sw_build" \
    "PART=$queried_part" \
    "TOP=$queried_top" \
    "SCIENTIFIC_SCOPE_REDUCTION=NO" \
    "MMIO_READ_SERVICE=SYNCHRONOUS_ONE_OUTSTANDING" \
    "COMBINATIONAL_INDEX_512_TO_1_MUX=ABSENT_SOURCE_AND_NETLIST_GATED" \
    "PROJECT_CREATION=PASS" \
    "SYNTHESIS=$synthesis_status" \
    "SYNTHESIZED_CELL_COUNT=[llength $synthesized_cells]" \
    "SYNTHESIZED_NET_COUNT=[llength $synthesized_nets]" \
    "R1H_SYNTH_DCP=$synth_dcp" \
    "R1H_SYNTH_DCP_SHA256=$synth_dcp_sha256" \
    "POST_SYNTH_SLICE_LUTS=$post_synth_slice_luts" \
    "POST_SYNTH_LOGIC_LUTS=$post_synth_logic_luts" \
    "POST_SYNTH_LUTRAM=$post_synth_lutram" \
    "POST_SYNTH_SLICE_REGISTERS=$post_synth_slice_registers" \
    "POST_SYNTH_MUXF7=$post_synth_muxf7" \
    "POST_SYNTH_MUXF8=$post_synth_muxf8" \
    "POST_SYNTH_RAMB18=$post_synth_ramb18" \
    "POST_SYNTH_RAMB36=$post_synth_ramb36" \
    "FAILED_RECORD_PAYLOAD_RAMB18=[llength $record_ramb18]" \
    "WADDR_INDEX_PAYLOAD_RAMB18=[llength $waddr_ramb18]" \
    "REGADDR_INDEX_PAYLOAD_RAMB18=[llength $regaddr_ramb18]" \
    "DATA_INDEX_PAYLOAD_RAMB18=[llength $data_ramb18]" \
    "R1H_NEW_PAYLOAD_RAMB18_TOTAL=$new_payload_ramb18_total" \
    "FAILED_RECORD_PAYLOAD_FDRE=[llength $record_fdre]" \
    "INDEX_PAYLOAD_FDRE_TOTAL=[llength $index_fdre]" \
    "FAILED_RECORD_PAYLOAD_RAM64M=[llength $record_ram64m]" \
    "FAILED_RECORD_PAYLOAD_RAMD64E=[llength $record_ramd64e]" \
    "POST_SYNTH_MEMORY_MAPPING_GATE=$post_synth_mapping_gate" \
    "POST_SYNTH_RESOURCE_MARGIN_GATE=$post_synth_resource_margin_gate" \
    "OPT_DESIGN=$opt_status" \
    "PLACE=$place_status" \
    "PLACED_PRIMITIVE_COUNT=$placed_cell_count" \
    "ROUTE=$route_status" \
    "ROUTE_ERRORS=$route_errors" \
    "WNS=$wns" \
    "WHS=$whs" \
    "VDO_WNS=$vdo_wns" \
    "VDO_WHS=$vdo_whs" \
    "DRC_ERRORS=$drc_errors" \
    "DRC_CRITICAL_WARNINGS=$drc_critical_warnings" \
    "DRC_WARNINGS=$drc_warnings" \
    "BUS_SKEW_VIOLATIONS=$bus_skew_violations" \
    "CDC_CRITICAL=$cdc_critical" \
    "CDC_UNKNOWN=$cdc_unknown" \
    "REQP_1839_SEMANTIC_COUNT=$reqp_1839_semantic_count" \
    "REQP_1839_RAW_TEXT_COUNT=$reqp_1839_raw_text_count" \
    "REQP_1839_RAW_TEXT_COUNT_NOT_USED_AS_GATE=YES" \
    "LUT_USED=$lut_used" \
    "LUT_AVAILABLE=$lut_available" \
    "FF_USED=$ff_used" \
    "FF_AVAILABLE=$ff_available" \
    "BRAM_TILE_USED=$bram_used" \
    "BRAM_TILE_AVAILABLE=$bram_available" \
    "RAMB36_USED=$ramb36_used" \
    "RAMB18_USED=$ramb18_used" \
    "DSP_USED=$dsp_used" \
    "DSP_AVAILABLE=$dsp_available" \
    "BUFG_USED=$bufg_used" \
    "MMCM_USED=$mmcm_used" \
    "POST_INIT_TRI_PHASE_PROBE_OBJECTS=$tri_probe_inventory" \
    "R1F_FAILED_TXN_LOGGER_OBJECTS=$failed_logger_inventory" \
    "R1F_MEASUREMENT_REGS_OBJECTS=$measurement_regs_inventory" \
    "R1H_PROBE_INDEX_STORE_OBJECTS=$index_store_inventory" \
    "R1H_MMIO_READ_SERVICE_OBJECTS=$mmio_service_inventory" \
    "R1F_TRANSACTION_SERIAL_OBJECTS=$serial_inventory" \
    "LIFECYCLE_MONITOR_OBJECTS=$lifecycle_inventory" \
    "NVP_AUTOINIT_OBJECTS=$autoinit_inventory" \
    "AUTOINIT_I2C_HZ=25000" \
    "AUTOINIT_CLOCK_HZ=62500000" \
    "EXPECTED_CNT_AT_INIT_DONE=132584734" \
    "R1F_LOG_CAPACITY=64" \
    "R1F_TRANSACTION_INDEX_WIDTH=16" \
    "R1F_TABLE_SLOT_INDEX_WIDTH=16" \
    "R1F_RECORD_WIDTH=192" \
    "R1F_PROBE_PHASES=3" \
    "R1F_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=10000" \
    "R1F_PROBE_BLOCKS_PER_PHASE=10" \
    "R1F_PROBE_INDEX_LOG_CAPACITY_PER_PHASE=512" \
    "R1F_PROBE_BANK=0x00" \
    "R1F_PROBE_REGISTER=0x85" \
    "R1F_PROBE_DATA=0x00" \
    "NVP_TABLE_UNCHANGED=YES_HASH_BOUND" \
    "FUNCTIONAL_FSM_UNCHANGED=YES_PREBUILD_BOUND" \
    "POR_START_WATCHDOG_UNCHANGED=YES_PREBUILD_BOUND" \
    "SDA_SCL_FILTERS_UNCHANGED=YES_PREBUILD_BOUND" \
    "XDMA_XCI_UNCHANGED=YES_HASH_BOUND" \
    "XDC_SET_UNCHANGED=YES_HASH_BOUND" \
    "PREBUILD_MANIFEST_BINDING=PASS" \
    "R1H_BUILD_TCL_SHA256=$build_tcl_sha" \
    "SOURCE_COMMIT_TO_BIT_PROVENANCE=$source_commit_to_bit_provenance" \
    "R1H_ROUTED_DCP=$routed_dcp" \
    "R1H_ROUTED_DCP_SHA256=$routed_dcp_sha256" \
    "BITSTREAM=$bit_path" \
    "BITSTREAM_GENERATED=$bit_generated" \
    "BITSTREAM_SHA256=$bit_sha256" \
    "R1H_IMPLEMENTATION_GATE=$implementation_gate"]

  if {$implementation_gate ne "PASS"} {
    error "R1h implementation gate failed; the one build is consumed and no bitstream was emitted"
  }

  close_project
  puts "R1H_IMPLEMENTATION_GATE=PASS"
  puts "R1H_BITSTREAM_SHA256=$bit_sha256"
} flow_error flow_options]

if {$flow_rc != 0} {
  catch {close_project}
  set error_info UNKNOWN
  if {[dict exists $flow_options -errorinfo]} {
    set error_info [dict get $flow_options -errorinfo]
  }
  write_lines [file join $evidence_root R1H_BUILD_TERMINAL_FAILURE.txt] [list \
    "R1H_ONE_CLEAN_BUILD_CONSUMED=YES" \
    "TERMINAL_BUILD_STAGE=$build_stage" \
    "SYNTHESIS_RUNS=$synthesis_runs" \
    "OPT_DESIGN_RUNS=$opt_design_runs" \
    "PLACE_DESIGN_RUNS=$place_design_runs" \
    "ROUTE_DESIGN_RUNS=$route_design_runs" \
    "BITSTREAM_RUNS=$bitstream_runs" \
    "SOURCE_GIT_COMMIT=$source_commit" \
    "SOURCE_GIT_TREE=$source_tree" \
    "PROGRAM_RETRY_AUTHORIZED=NO" \
    "TERMINAL_ERROR=$flow_error" \
    "ERROR_INFO_BEGIN" \
    $error_info \
    "ERROR_INFO_END"]
  puts stderr "R1H_ONE_CLEAN_BUILD_CONSUMED=YES"
  puts stderr "R1H_BUILD_TERMINAL_FAILURE=$flow_error"
  exit 1
}

exit 0
