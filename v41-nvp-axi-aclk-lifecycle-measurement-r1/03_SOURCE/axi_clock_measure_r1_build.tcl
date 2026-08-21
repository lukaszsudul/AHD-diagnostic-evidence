if {$argc != 5} {
  puts stderr "usage: axi_clock_measure_r1_build.tcl REPOSITORY_ROOT BUILD_ROOT EVIDENCE_ROOT SOURCE_GIT_COMMIT BIT_FILENAME"
  exit 2
}

set repo_root [file normalize [lindex $argv 0]]
set build_root [file normalize [lindex $argv 1]]
set evidence_root [file normalize [lindex $argv 2]]
set source_commit [string tolower [lindex $argv 3]]
set bit_filename [lindex $argv 4]
source [file join $repo_root scripts v41 xdma_config_common.tcl]

proc write_lines {path lines} {
  file mkdir [file dirname $path]
  set fh [open $path w]
  fconfigure $fh -translation lf
  foreach line $lines { puts $fh $line }
  close $fh
}

proc require_files {paths} {
  foreach path $paths {
    if {![file isfile $path]} { error "required file missing: $path" }
  }
}

proc read_text {path} {
  set fh [open $path r]
  set text [read $fh]
  close $fh
  return $text
}

proc utilization_row {text wanted} {
  set normalized_wanted [string trimright $wanted "*"]
  foreach line [split $text "\n"] {
    set columns [split $line "|"]
    set actual [string trimright [string trim [lindex $columns 1]] "*"]
    if {[llength $columns] >= 7 && $actual eq $normalized_wanted} {
      return [list [string trim [lindex $columns 2]] \
                   [string trim [lindex $columns 5]]]
    }
  }
  error "utilization row '$wanted' not found"
}

if {![regexp {^[0-9a-f]{40}$} $source_commit]} {
  error "SOURCE_GIT_COMMIT must be exactly 40 lowercase hex digits"
}
set actual_commit [string trim [exec git -C $repo_root rev-parse HEAD]]
if {$actual_commit ne $source_commit} {
  error "repository HEAD $actual_commit does not match requested build commit $source_commit"
}
set source_status [string trim [exec git -C $repo_root status --porcelain --untracked-files=all]]
if {$source_status ne ""} {
  error "hardware build requires a clean source tree: $source_status"
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
  "BUILD_FLAGS=$build_flags"] " "]

file mkdir $build_root
file mkdir $evidence_root
cd $build_root

set project_name v41_axi_clock_measure_r1
set project_dir [file join $build_root project]
create_project -force $project_name $project_dir -part $v41_xdma::part
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]
set_property XPM_LIBRARIES {XPM_CDC XPM_MEMORY} [current_project]

set sv_files [list \
  [file join $repo_root rtl v41 axi_lite_host_bridge.sv] \
  [file join $repo_root rtl v41 axi_clock_lifecycle_monitor.sv] \
  [file join $repo_root rtl v41 axi_clock_measurement_regs.sv] \
  [file join $repo_root rtl v41 control_status_regs.sv] \
  [file join $repo_root rtl pio pio_slot_adapter.sv] \
  [file join $repo_root rtl pio pio_bar_target.sv] \
  [file join $repo_root rtl record bt656_record_producer.sv] \
  [file join $repo_root rtl record capture_mailbox.sv] \
  [file join $repo_root rtl video video_capture.sv] \
  [file join $repo_root rtl video physical_frontend.sv] \
  [file join $repo_root rtl top ahd_capture_top_xdma.sv]]
set vhdl_files [list \
  [file join $repo_root rtl nvp nvp6134c_diagnostics_pkg.vhd] \
  [file join $repo_root rtl nvp nvp6134c_i2c_bringup.vhd] \
  [file join $repo_root rtl nvp nvp6134c_autoinit.vhd]]
set xdc_files [list \
  [file join $repo_root xdc boards current xdma_pcie.xdc] \
  [file join $repo_root xdc boards current pins.xdc] \
  [file join $repo_root xdc boards current vdo_input_timing.xdc] \
  [file join $repo_root xdc boards current pcie_pio.xdc] \
  [file join $repo_root xdc boards current nvp_control.xdc] \
  [file join $repo_root xdc common cdc.xdc] \
  [file join $repo_root xdc common configuration_bank.xdc]]
set xdma_source [file join $repo_root ip v41 xdma_v41_m1.xci]
require_files [concat $sv_files $vhdl_files $xdc_files [list $xdma_source]]

add_files -norecurse $sv_files
set_property FILE_TYPE SystemVerilog [get_files $sv_files]
add_files -norecurse $vhdl_files

set input_xci_dir [file join $build_root input_xci]
file mkdir $input_xci_dir
set xdma_copy [file join $input_xci_dir xdma_v41_m1.xci]
file copy -force $xdma_source $xdma_copy
import_ip -files $xdma_copy
set xdma_ip [get_ips xdma_v41_m1]
if {[llength $xdma_ip] != 1} { error "expected exactly one XDMA IP" }
v41_xdma::configure_minimal_c2h_stream $xdma_ip
set imported_xci [get_property IP_FILE $xdma_ip]
set imported_xci_object [get_files -quiet $imported_xci]
if {[llength $imported_xci_object] != 1} {
  error "imported XDMA XCI object not found: $imported_xci"
}
set_property GENERATE_SYNTH_CHECKPOINT false $imported_xci_object
generate_target all $xdma_ip

add_files -fileset constrs_1 -norecurse $xdc_files
set_property PROCESSING_ORDER EARLY [get_files [lindex $xdc_files 0]]
set_property PROCESSING_ORDER LATE [get_files [lrange $xdc_files 1 end]]

set top ahd_capture_top_xdma
set_property top $top [get_filesets sources_1]
set_property generic $generics [get_filesets sources_1]
update_compile_order -fileset sources_1

write_lines [file join $evidence_root PHASE3_BUILD_PROVENANCE.txt] [list \
  "SOURCE_GIT_COMMIT=$source_commit" \
  "SOURCE_TREE_CLEAN=YES" \
  "BUILD_FLAGS=0x00000002" \
  "BUILD_ID_SCHEMA=0x00010000" \
  "GIT_SHA_W0=0x[lindex $git_words 0]" \
  "GIT_SHA_W1=0x[lindex $git_words 1]" \
  "GIT_SHA_W2=0x[lindex $git_words 2]" \
  "GIT_SHA_W3=0x[lindex $git_words 3]" \
  "GIT_SHA_W4=0x[lindex $git_words 4]" \
  "VIVADO_VERSION=2025.2" \
  "VIVADO_SW_BUILD=6299465" \
  "PART=$v41_xdma::part" \
  "TOP=$top" \
  "GENERICS=$generics" \
  "XCI=$xdma_copy"]

synth_design -top $top -part $v41_xdma::part -flatten_hierarchy rebuilt
write_checkpoint -force [file join $evidence_root PHASE3_synth.dcp]
report_utilization -file [file join $evidence_root PHASE3_utilization_post_synth.rpt]
report_timing_summary -delay_type min_max -max_paths 100 \
  -file [file join $evidence_root PHASE3_timing_post_synth.rpt]

opt_design -directive Explore
place_design -directive Explore
phys_opt_design -directive Explore
route_design -directive Explore
write_checkpoint -force [file join $evidence_root PHASE3_routed.dcp]

set route_report [file join $evidence_root PHASE3_route_status.rpt]
set timing_report [file join $evidence_root PHASE3_timing_summary.rpt]
set drc_report [file join $evidence_root PHASE3_drc.rpt]
set bus_skew_report [file join $evidence_root PHASE3_bus_skew.rpt]
set cdc_report [file join $evidence_root PHASE3_cdc.rpt]
set util_report [file join $evidence_root PHASE3_utilization.rpt]

report_route_status -file $route_report
report_timing_summary -delay_type min_max -max_paths 100 -file $timing_report
report_drc -file $drc_report
check_timing -verbose -file [file join $evidence_root PHASE3_check_timing.rpt]
report_exceptions -coverage -file [file join $evidence_root PHASE3_exception_coverage.rpt]
report_bus_skew -file $bus_skew_report
report_clock_interaction -file [file join $evidence_root PHASE3_clock_interaction.rpt]
report_cdc -details -file $cdc_report
report_utilization -file $util_report
report_utilization -hierarchical -hierarchical_depth 20 \
  -file [file join $evidence_root PHASE3_utilization_hierarchical.rpt]
report_clock_utilization -file [file join $evidence_root PHASE3_clock_utilization.rpt]
report_design_analysis -congestion \
  -file [file join $evidence_root PHASE3_congestion.rpt]
report_methodology -file [file join $evidence_root PHASE3_methodology.rpt]
report_property -file [file join $evidence_root PHASE3_design_properties.txt] \
  [current_design]

set vdo_ports [get_ports {vdo1_data[*]}]
if {[llength $vdo_ports] != 8} { error "expected eight VDO ports" }
report_timing -delay_type max -from $vdo_ports -max_paths 32 -nworst 4 \
  -file [file join $evidence_root PHASE3_vdo_setup_paths.rpt]
report_timing -delay_type min -from $vdo_ports -max_paths 32 -nworst 4 \
  -file [file join $evidence_root PHASE3_vdo_hold_paths.rpt]

set worst_setup [get_timing_paths -quiet -delay_type max -max_paths 1 -nworst 1]
set worst_hold [get_timing_paths -quiet -delay_type min -max_paths 1 -nworst 1]
set vdo_setup [get_timing_paths -quiet -delay_type max -from $vdo_ports -max_paths 1 -nworst 1]
set vdo_hold [get_timing_paths -quiet -delay_type min -from $vdo_ports -max_paths 1 -nworst 1]
if {[llength $worst_setup] != 1 || [llength $worst_hold] != 1 ||
    [llength $vdo_setup] != 1 || [llength $vdo_hold] != 1} {
  error "required timing path class is empty"
}
set wns [get_property SLACK $worst_setup]
set whs [get_property SLACK $worst_hold]
set vdo_wns [get_property SLACK $vdo_setup]
set vdo_whs [get_property SLACK $vdo_hold]
set tns [expr {$wns >= 0.0 ? 0.0 : "NEGATIVE_SEE_REPORT"}]
set ths [expr {$whs >= 0.0 ? 0.0 : "NEGATIVE_SEE_REPORT"}]

set drc_errors 0
set drc_critical_warnings 0
set drc_warnings 0
foreach violation [get_drc_violations -quiet] {
  switch -- [get_property SEVERITY $violation] {
    Error { incr drc_errors }
    {Critical Warning} { incr drc_critical_warnings }
    Warning { incr drc_warnings }
  }
}

set bus_skew_violations [regexp -all {Slack \(VIOLATED\)} [read_text $bus_skew_report]]
set cdc_critical_types [regexp -all -line {^CDC-[0-9]+[ \t]+Critical[ \t]+} [read_text $cdc_report]]
set route_errors 1
regexp {# of nets with routing errors[^:]*:[ \t]*([0-9]+)} \
  [read_text $route_report] -> route_errors

set util_text [report_utilization -return_string]
lassign [utilization_row $util_text "Slice LUTs*"] lut_used lut_available
lassign [utilization_row $util_text "Slice Registers"] ff_used ff_available
lassign [utilization_row $util_text "Block RAM Tile"] bram_used bram_available
lassign [utilization_row $util_text "DSPs"] dsp_used dsp_available
set lut_free_pct [expr {100.0 * ($lut_available - $lut_used) / $lut_available}]
set ff_free_pct [expr {100.0 * ($ff_available - $ff_used) / $ff_available}]
set bram_free_pct [expr {100.0 * ($bram_available - $bram_used) / $bram_available}]
set dsp_free_pct [expr {100.0 * ($dsp_available - $dsp_used) / $dsp_available}]
set ramb36_used [llength [get_cells -hier -filter {REF_NAME == RAMB36E1}]]
set ramb18_used [llength [get_cells -hier -filter {REF_NAME == RAMB18E1}]]
set bufg_used [llength [get_cells -hier -filter {REF_NAME =~ BUFG*}]]
set mmcm_used [llength [get_cells -hier -filter {REF_NAME =~ MMCM*}]]

set gate PASS
if {$route_errors != 0 || $drc_errors != 0 || $drc_critical_warnings != 0 ||
    $bus_skew_violations != 0 || $cdc_critical_types != 0 ||
    $wns < 0.0 || $whs <= 0.0 || $vdo_wns < 0.0 || $vdo_whs <= 0.0 ||
    $lut_free_pct < 10.0 || $ff_free_pct < 10.0 || $bram_free_pct < 10.0} {
  set gate FAIL
}

set bit_path [file join $evidence_root artifacts $bit_filename]
set bit_generated NO
if {$gate eq "PASS"} {
  file mkdir [file dirname $bit_path]
  write_bitstream -force $bit_path
  set bit_generated YES
}

write_lines [file join $evidence_root PHASE3_BUILD_RESULT.txt] [list \
  "PHASE=3" \
  "SOURCE_GIT_COMMIT=$source_commit" \
  "PROJECT_CREATION=PASS" \
  "SYNTHESIS=PASS" \
  "IMPLEMENTATION=PASS" \
  "ROUTE=PASS" \
  "ROUTE_ERRORS=$route_errors" \
  "WNS=$wns" "TNS=$tns" "WHS=$whs" "THS=$ths" \
  "VDO_WNS=$vdo_wns" "VDO_WHS=$vdo_whs" \
  "DRC_ERRORS=$drc_errors" \
  "DRC_CRITICAL_WARNINGS=$drc_critical_warnings" \
  "DRC_WARNINGS=$drc_warnings" \
  "BUS_SKEW_VIOLATIONS=$bus_skew_violations" \
  "CDC_CRITICAL_TYPES=$cdc_critical_types" \
  "LUT_USED=$lut_used" "LUT_AVAILABLE=$lut_available" \
  "LUT_FREE_PERCENT=[format %.2f $lut_free_pct]" \
  "FF_USED=$ff_used" "FF_AVAILABLE=$ff_available" \
  "FF_FREE_PERCENT=[format %.2f $ff_free_pct]" \
  "BRAM_TILE_USED=$bram_used" "BRAM_TILE_AVAILABLE=$bram_available" \
  "BRAM_FREE_PERCENT=[format %.2f $bram_free_pct]" \
  "RAMB36_USED=$ramb36_used" "RAMB18_USED=$ramb18_used" \
  "BUFG_USED=$bufg_used" "MMCM_USED=$mmcm_used" \
  "DSP_USED=$dsp_used" "DSP_AVAILABLE=$dsp_available" \
  "DSP_FREE_PERCENT=[format %.2f $dsp_free_pct]" \
  "BITSTREAM=$bit_path" \
  "BITSTREAM_GENERATED=$bit_generated" \
  "PHASE3_IMPLEMENTATION_GATE=$gate"]

puts "PHASE3_IMPLEMENTATION_GATE=$gate"
puts "WNS=$wns WHS=$whs VDO_WNS=$vdo_wns VDO_WHS=$vdo_whs"
puts "LUT_FREE=[format %.2f $lut_free_pct]% FF_FREE=[format %.2f $ff_free_pct]% BRAM_FREE=[format %.2f $bram_free_pct]%"
close_project
if {$gate eq "FAIL"} { exit 1 }
