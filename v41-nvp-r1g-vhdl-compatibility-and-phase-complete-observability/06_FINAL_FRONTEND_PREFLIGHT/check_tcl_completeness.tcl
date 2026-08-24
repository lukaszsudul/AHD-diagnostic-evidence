if {$argc == 0} {
  puts stderr "usage: check_tcl_completeness.tcl FILE ..."
  exit 2
}

set overall 1
foreach path $argv {
  set fh [open $path r]
  fconfigure $fh -encoding utf-8
  set text [read $fh]
  close $fh
  set complete [info complete $text]
  puts "FILE=$path"
  puts "INFO_COMPLETE=$complete"
  if {!$complete} {
    set overall 0
  }
}
puts "ALL_TCL_COMPLETE=$overall"
exit [expr {$overall ? 0 : 1}]
