if {$argc < 1} {
  puts stderr "usage: check_tcl_complete.tcl TCL_FILE..."
  exit 2
}

set failed 0
foreach path $argv {
  set fh [open $path r]
  fconfigure $fh -encoding utf-8
  set text [read $fh]
  close $fh
  if {![info complete $text]} {
    puts stderr "TCL_INFO_COMPLETE=FAIL|$path"
    set failed 1
  } else {
    puts "TCL_INFO_COMPLETE=PASS|$path"
  }
}
exit $failed
