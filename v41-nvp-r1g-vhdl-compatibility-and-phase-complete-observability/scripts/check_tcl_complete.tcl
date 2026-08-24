if {$argc != 1} {
  puts stderr "usage: check_tcl_complete.tcl FILE"
  exit 2
}
set path [file normalize [lindex $argv 0]]
set fh [open $path r]
fconfigure $fh -encoding utf-8
set text [read $fh]
close $fh
set complete [info complete $text]
puts "TCL_FILE=$path"
puts "TCL_INFO_COMPLETE=$complete"
if {!$complete} {
  exit 1
}
exit 0
