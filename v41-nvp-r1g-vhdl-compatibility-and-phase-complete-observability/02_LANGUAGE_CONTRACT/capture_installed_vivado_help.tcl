set output_dir [file normalize [file dirname [info script]]]

proc capture_help {command_name} {
  puts "BEGIN_INSTALLED_HELP=$command_name"
  uplevel #0 [list $command_name -help]
  puts "END_INSTALLED_HELP=$command_name"
}

set version_path [file join $output_dir INSTALLED_TOOL_HELP vivado_version.txt]
file mkdir [file dirname $version_path]
set version_fh [open $version_path w]
fconfigure $version_fh -encoding utf-8 -translation lf
puts $version_fh [version]
close $version_fh

capture_help read_vhdl
capture_help synth_design
capture_help get_files
capture_help get_property
capture_help report_compile_order

set summary_path [file join $output_dir INSTALLED_TOOL_HELP capture_summary.txt]
set summary_fh [open $summary_path w]
fconfigure $summary_fh -encoding utf-8 -translation lf
puts $summary_fh "HELP_CAPTURE=PASS"
puts $summary_fh "VIVADO_VERSION_SHORT=[version -short]"
puts $summary_fh "COMMANDS=read_vhdl,synth_design,get_files,get_property,report_compile_order"
puts $summary_fh "PROJECT_CREATED=NO"
puts $summary_fh "SYNTH_DESIGN_INVOKED=NO"
close $summary_fh

exit 0
