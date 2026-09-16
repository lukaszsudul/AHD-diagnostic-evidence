# Read-only physical/configuration identity collector for an exact DCP copy.
if {[version -short] ne {2025.2}} { error {WRONG_VIVADO_VERSION} }
set_param general.maxThreads 1
if {[llength $argv] != 2} { error {ARGS_DCP_AND_OUTPUT_ROOT_REQUIRED} }
set dcp [file normalize [lindex $argv 0]]
set root [file normalize [lindex $argv 1]]
if {![file isfile $dcp] || ![file isdirectory $root] ||
    [llength [glob -nocomplain -directory $root *]] != 0} {
  error {INPUT_OR_OUTPUT_GATE_FAILED}
}
open_checkpoint $dcp
set part [get_property PART [current_design]]
set top [get_property TOP [current_design]]
if {$part ne {xc7a35tcsg325-2} || $top ne {ahd_capture_top_xdma}} {
  error "PART_OR_TOP_MISMATCH:$part:$top"
}
write_xdc -force [file join $root FULL_AS_OPEN_PHYSICAL_AND_TIMING.xdc]
set pairs [list]
foreach net [get_nets -hier -quiet] {
  lappend pairs [list [get_property NAME $net] $net]
}
set f [open [file join $root ROUTE_OBJECTS.tsv] w]
fconfigure $f -encoding utf-8 -translation lf
set count 0
set nonempty 0
foreach pair [lsort -dictionary -index 0 $pairs] {
  lassign $pair name net
  set route [get_property ROUTE $net]
  if {$route ne {}} { incr nonempty }
  puts $f "NET\t$name\t$route"
  incr count
}
close $f
set f [open [file join $root PHYSICAL_RECEIPT.txt] w]
fconfigure $f -encoding utf-8 -translation lf
puts $f "PART=$part"
puts $f "TOP=$top"
puts $f "NETS=$count"
puts $f "NETS_WITH_NONEMPTY_ROUTE=$nonempty"
puts $f {NO_DESIGN_MUTATION=YES}
close $f
close_design
exit 0
