set commands {get_drc_checks get_drc_violations report_drc report_property list_property}
puts "VIVADO_VERSION=[version -short]"
set help_path [file normalize [file join [file dirname [info script]] .. 02_SEMANTIC_DRC_PARSER INSTALLED_VIVADO_2025_2_DRC_HELP.txt]]
set help_file [open $help_path w]
close $help_file
foreach command_name $commands {
  puts "===== HELP_BEGIN $command_name ====="
  set marker_file [open $help_path a]
  puts $marker_file "===== HELP_BEGIN $command_name ====="
  set command_help [help $command_name]
  puts $marker_file $command_help
  puts $marker_file "===== HELP_END $command_name ====="
  close $marker_file
  puts "===== HELP_END $command_name ====="
}
exit 0
