if {$argc != 1} {
  puts stderr {usage: test_select_r6_jtag_target.tcl OUTPUT_CSV}
  exit 2
}

source [file join [file dirname [info script]] select_r6_jtag_target.tcl]

set output_path [file normalize [lindex $argv 0]]
if {[file exists $output_path]} {
  puts stderr "fixture output must be fresh: $output_path"
  exit 2
}

set cases [list \
  [list A [list {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01}] PASS] \
  [list B [list {Xilinx/80802026a98b01}] PASS] \
  [list C [list {Digilent/210241768436}] FAIL_OLD_TARGET_NOT_SELECTED] \
  [list D [list {Xilinx/80802026a98b0}] FAIL_NEAR_MATCH] \
  [list E [list {Xilinx/80802026a98b010}] FAIL_NEAR_MATCH] \
  [list F [list {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01} {localhost:3121/xilinx_tcf/Other/1234}] FAIL_TARGET_COUNT_NOT_ONE] \
  [list G [list {localhost:3121/xilinx_tcf/Xilinx/80802026a98b01} {otherhost:3121/xilinx_tcf/Xilinx/80802026a98b01}] FAIL_DUPLICATE] \
  [list H [list] FAIL_NO_TARGET]]

set handle [open $output_path {WRONLY CREAT EXCL}]
puts $handle {fixture,target_count,expected,actual,result}
set failure_count 0
foreach fixture $cases {
  lassign $fixture name paths expected
  set classification [r6_target::classify_target_paths $paths]
  set actual [dict get $classification status]
  set result [expr {$actual eq $expected ? {PASS} : {FAIL}}]
  if {$result ne {PASS}} { incr failure_count }
  puts $handle "$name,[llength $paths],$expected,$actual,$result"
  puts "FIXTURE_$name=$result EXPECTED=$expected ACTUAL=$actual"
}
close $handle

puts "TARGET_SELECTOR_FIXTURE_COUNT=[llength $cases]"
puts "TARGET_SELECTOR_FIXTURE_FAILURES=$failure_count"
puts {TARGET_MATCH_MODE=EXACT_CANONICAL_ID_OR_EXACT_PATH_SUFFIX}
puts {FALLBACK_TO_FIRST_TARGET=NO}
puts {LEGACY_HS2_REQUIRED=NO}
if {$failure_count != 0} {
  puts {TARGET_SELECTOR_FIXTURES=FAIL}
  exit 1
}
puts {TARGET_SELECTOR_FIXTURES=PASS_ALL}
exit 0

