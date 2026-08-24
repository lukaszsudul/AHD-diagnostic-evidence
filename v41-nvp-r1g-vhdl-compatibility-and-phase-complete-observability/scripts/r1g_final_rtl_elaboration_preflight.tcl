# R1g single-consumption production-front-end RTL elaboration preflight.
#
# This script deliberately stops after `synth_design -rtl`. It creates no
# synthesized-netlist checkpoint, runs no optimization or implementation, and
# emits no bitstream. The preflight sentinel is created before project setup so
# every invocation consumes the one authorized final-preflight allowance.

if {$argc != 5} {
  puts stderr "usage: r1g_final_rtl_elaboration_preflight.tcl REPOSITORY_ROOT WORK_ROOT EVIDENCE_ROOT SOURCE_GIT_COMMIT SOURCE_GIT_TREE"
  exit 2
}

set repo_root [file normalize [lindex $argv 0]]
set work_root [file normalize [lindex $argv 1]]
set evidence_root [file normalize [lindex $argv 2]]
set source_commit [string tolower [lindex $argv 3]]
set source_tree [string tolower [lindex $argv 4]]

set expected_branch diag/v41-nvp-r1g-vhdl-compatibility
set exact_r1f_parent 225544084dbfcaadb8592fcecc947aa1cec4970e
set exact_r1f_tree cfde8769af95cf20586391c411fab3ddfa2c87b6
set expected_vivado_version 2025.2
set expected_vivado_sw_build 6299465
set expected_part xc7a35tcsg325-2
set expected_top ahd_capture_top_xdma
set expected_xdma_sha256 EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C
set expected_common_tcl_sha256 3A76FC7893B2188871B340E326B53C7EE39B93C19EF416EAD2611CA9FDA9CDC7

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -encoding utf-8 -translation lf
  foreach line $lines {
    puts $fh $line
  }
  close $fh
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

proc compile_order_index {compile_names required_path} {
  set required_native [string tolower \
    [file nativename [file normalize $required_path]]]
  set index 0
  foreach name $compile_names {
    set name_native [string tolower \
      [file nativename [file normalize $name]]]
    if {$name_native eq $required_native} {
      return $index
    }
    incr index
  }
  return -1
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
if {[path_inside_or_equal $work_root $repo_root] ||
    [path_inside_or_equal $evidence_root $repo_root]} {
  error "work and evidence roots must be outside the clean source repository"
}
if {[path_inside_or_equal $evidence_root $work_root]} {
  error "evidence root must not be inside the disposable work root"
}
if {[llength [directory_entries $work_root]] != 0} {
  error "preflight work root must be new or empty: $work_root"
}

set actual_commit [string tolower [string trim \
  [exec git -C $repo_root rev-parse HEAD]]]
set actual_tree [string tolower [string trim \
  [exec git -C $repo_root rev-parse {HEAD^{tree}}]]]
set actual_parent [string tolower [string trim \
  [exec git -C $repo_root rev-parse HEAD^]]]
set parent_tree [string tolower [string trim \
  [exec git -C $repo_root rev-parse {HEAD^^{tree}}]]]
set actual_branch [string trim \
  [exec git -C $repo_root symbolic-ref --short HEAD]]
set source_status [string trim \
  [exec git -C $repo_root status --porcelain --untracked-files=all]]
set commits_above_r1f [string trim [exec git -C $repo_root rev-list --count \
  [format "%s..%s" $exact_r1f_parent $source_commit]]]

if {$actual_commit ne $source_commit || $actual_tree ne $source_tree} {
  error "repository commit/tree does not match requested R1g identity"
}
if {$actual_parent ne $exact_r1f_parent || $parent_tree ne $exact_r1f_tree} {
  error "R1g source is not a direct child of the exact R1f commit/tree"
}
if {$commits_above_r1f ne "1"} {
  error "R1g must contain exactly one commit above R1f; got $commits_above_r1f"
}
if {$actual_branch ne $expected_branch} {
  error "branch mismatch: expected $expected_branch, got $actual_branch"
}
if {$source_status ne ""} {
  error "final preflight requires a fully clean source repository: $source_status"
}

set vivado_short [string trim [version -short]]
set vivado_detail [version]
set vivado_sw_build UNKNOWN
regexp {SW Build[ \t]+([0-9]+)} $vivado_detail -> vivado_sw_build
if {$vivado_short ne $expected_vivado_version ||
    $vivado_sw_build ne $expected_vivado_sw_build} {
  error "Vivado identity mismatch: $vivado_short / $vivado_sw_build"
}

set sv_rel_files [list \
  rtl/v41/axi_lite_host_bridge.sv \
  rtl/v41/axi_clock_lifecycle_monitor.sv \
  rtl/v41/axi_clock_measurement_regs.sv \
  rtl/v41/r1e_measurement_regs.sv \
  rtl/v41/nvp_i2c_tri_phase_probe.sv \
  rtl/v41/r1f_failed_txn_logger.sv \
  rtl/v41/r1f_measurement_regs.sv \
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
set xdma_source [file normalize \
  [file join $repo_root ip v41 xdma_v41_m1.xci]]
set common_tcl [file normalize \
  [file join $repo_root scripts v41 xdma_config_common.tcl]]
foreach required [concat $sv_files $vhdl_files $xdc_files \
    [list $xdma_source $common_tcl]] {
  if {![file isfile $required]} {
    error "required preflight input missing: $required"
  }
}
if {[sha256_file $xdma_source] ne $expected_xdma_sha256 ||
    [sha256_file $common_tcl] ne $expected_common_tcl_sha256} {
  error "frozen XDMA XCI or configuration helper identity mismatch"
}

set git_words [list]
for {set word_index 0} {$word_index < 5} {incr word_index} {
  set first [expr {$word_index * 8}]
  lappend git_words [string range $source_commit $first [expr {$first + 7}]]
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

file mkdir $evidence_root
set sentinel [file join $evidence_root \
  R1G_FINAL_RTL_ELABORATION_PREFLIGHT_CONSUMED.marker]
if {[file exists $sentinel]} {
  error "the sole final RTL elaboration preflight was already consumed: $sentinel"
}
set sentinel_fh [open $sentinel {WRONLY CREAT EXCL}]
fconfigure $sentinel_fh -encoding utf-8 -translation lf
puts $sentinel_fh "FINAL_RTL_ELABORATION_PREFLIGHTS=1"
puts $sentinel_fh "SOURCE_GIT_COMMIT=$source_commit"
puts $sentinel_fh "SOURCE_GIT_TREE=$source_tree"
puts $sentinel_fh "SOURCE_PARENT_COMMIT=$actual_parent"
puts $sentinel_fh "CONSUMED_BEFORE_CREATE_PROJECT=YES"
puts $sentinel_fh \
  "CONSUMED_UTC=[clock format [clock seconds] -gmt true -format {%Y-%m-%dT%H:%M:%SZ}]"
close $sentinel_fh

set flow_rc [catch {
  file mkdir $work_root
  cd $work_root
  source $common_tcl
  if {$v41_xdma::part ne $expected_part} {
    error "shared XDMA part mismatch"
  }

  create_project -in_memory -part $expected_part
  set_property target_language Verilog [current_project]
  set_property simulator_language Mixed [current_project]
  set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]
  config_ip_cache -use_cache_location [file join $work_root ip_cache]

  add_files -norecurse $sv_files
  set_property FILE_TYPE SystemVerilog [get_files $sv_files]
  add_files -norecurse $vhdl_files

  set input_xci_dir [file join $work_root input_xci]
  file mkdir $input_xci_dir
  set xdma_copy [file join $input_xci_dir xdma_v41_m1.xci]
  file copy $xdma_source $xdma_copy
  if {[sha256_file $xdma_copy] ne $expected_xdma_sha256} {
    error "copied XDMA XCI identity mismatch"
  }
  import_ip -files $xdma_copy
  set xdma_ip [get_ips -quiet xdma_v41_m1]
  if {[llength $xdma_ip] != 1} {
    error "expected exactly one imported XDMA IP"
  }
  v41_xdma::configure_minimal_c2h_stream $xdma_ip
  dict for {property expected} [v41_xdma::minimal_c2h_stream_config] {
    if {[get_property $property $xdma_ip] ne $expected} {
      error "queried imported XDMA property mismatch for $property"
    }
  }
  set imported_xci [get_property IP_FILE $xdma_ip]
  set imported_xci_object [get_files -quiet $imported_xci]
  if {[llength $imported_xci_object] != 1} {
    error "imported XDMA XCI object not found"
  }
  set_property GENERATE_SYNTH_CHECKPOINT false $imported_xci_object
  generate_target all $xdma_ip

  add_files -fileset constrs_1 -norecurse $xdc_files
  set_property PROCESSING_ORDER EARLY [get_files [lindex $xdc_files 0]]
  set_property PROCESSING_ORDER LATE [get_files [lrange $xdc_files 1 end]]
  set_property top $expected_top [get_filesets sources_1]
  set_property generic $generics [get_filesets sources_1]
  update_compile_order -fileset sources_1

  set queried_part [get_property PART [current_project]]
  set queried_top [get_property TOP [get_filesets sources_1]]
  set queried_generics [get_property GENERIC [get_filesets sources_1]]
  if {$queried_part ne $expected_part || $queried_top ne $expected_top ||
      $queried_generics ne $generics} {
    error "queried project part/top/generic contract mismatch"
  }

  set compile_lines [list]
  set compile_names [list]
  set compile_index 0
  foreach object [get_files -compile_order sources -used_in synthesis] {
    set name [get_property NAME $object]
    lappend compile_names $name
    lappend compile_lines \
      "[format %03d $compile_index]|[get_property FILE_TYPE $object]|[get_property LIBRARY $object]|$name"
    incr compile_index
  }
  set prior_index -1
  foreach required $vhdl_files {
    set this_index [compile_order_index $compile_names $required]
    if {$this_index < 0 || $this_index <= $prior_index} {
      error "queried VHDL compile order violates the frozen dependency order"
    }
    set object [get_files -quiet $required]
    if {[llength $object] != 1 || [get_property FILE_TYPE $object] ne "VHDL" ||
        [get_property LIBRARY $object] ne "xil_defaultlib"} {
      error "production VHDL file-type/library contract mismatch for $required"
    }
    set prior_index $this_index
  }
  write_lines [file join $evidence_root \
    R1G_FINAL_RTL_PREFLIGHT_COMPILE_ORDER.txt] $compile_lines

  # The only allowed final-preflight frontend invocation.
  synth_design -rtl -name r1g_rtl_preflight -top $expected_top \
    -part $expected_part

  if {[current_design] eq "" ||
      [llength [get_cells -quiet -hier]] == 0} {
    error "RTL elaboration returned no open design/cells"
  }
  write_lines [file join $evidence_root \
    R1G_FINAL_RTL_ELABORATION_RESULT.txt] [list \
    "FINAL_RTL_ELABORATION_PREFLIGHTS=1" \
    "FINAL_RTL_ELABORATION=PASS" \
    "SOURCE_GIT_COMMIT=$source_commit" \
    "SOURCE_GIT_TREE=$source_tree" \
    "R1G_PARENT_COMMIT=$actual_parent" \
    "R1G_COMMITS_ABOVE_R1F=$commits_above_r1f" \
    "PRODUCTION_VHDL_STANDARD=VIVADO_FILE_TYPE_VHDL_DEFAULT_NON_2008" \
    "GLOBAL_VHDL_STANDARD_CHANGE=NO" \
    "FILE_TYPE_VHDL2008_CHANGES=0" \
    "READ_VHDL_VHDL2008_OPTION_ADDED=NO" \
    "SYNTH_DESIGN_MODE=RTL_ELABORATION_ONLY" \
    "SYNTH_8_2757_COUNT=0" \
    "UNSUPPORTED_LANGUAGE_CONSTRUCT_ERRORS=0" \
    "TOP_ELABORATED=$queried_top" \
    "PART=$queried_part" \
    "VIVADO_VERSION=$vivado_short" \
    "VIVADO_SW_BUILD=$vivado_sw_build" \
    "OPT_DESIGN_INVOCATIONS=0" \
    "PLACE_DESIGN_INVOCATIONS=0" \
    "PHYS_OPT_DESIGN_INVOCATIONS=0" \
    "ROUTE_DESIGN_INVOCATIONS=0" \
    "WRITE_CHECKPOINT_INVOCATIONS=0" \
    "WRITE_BITSTREAM_INVOCATIONS=0" \
    "PROCESS_EXIT_CODE=0"]
  close_project
} flow_error flow_options]

if {$flow_rc != 0} {
  write_lines [file join $evidence_root \
    R1G_FINAL_RTL_ELABORATION_FAILURE.txt] [list \
    "FINAL_RTL_ELABORATION_PREFLIGHTS=1" \
    "FINAL_RTL_ELABORATION=FAIL" \
    "SOURCE_GIT_COMMIT=$source_commit" \
    "SOURCE_GIT_TREE=$source_tree" \
    "ERROR=$flow_error" \
    "ERROR_INFO=[dict get $flow_options -errorinfo]" \
    "PROGRAM_RETRY_AUTHORIZED=NO"]
  puts stderr "R1G_FINAL_RTL_ELABORATION=FAIL: $flow_error"
  exit 1
}

puts "R1G_FINAL_RTL_ELABORATION=PASS"
puts "R1G_FINAL_RTL_ELABORATION_PREFLIGHTS=1"
exit 0
