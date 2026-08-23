if {$argc != 1} {
  puts stderr {usage: test_mode_aware_preconditions.tcl OUTPUT_CSV}
  exit 2
}

set ::r7_mode_aware_library_only 1
source {C:/FPGA/V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7/scripts/program_once_mode_aware.tcl}

set output_path [file normalize [lindex $argv 0]]
if {[file exists $output_path]} {
  puts stderr "fixture output must be fresh: $output_path"
  exit 2
}

set bootstrap {BOOTSTRAP_FROM_STABLE_UNKNOWN_SRAM}
set transition {TRANSITION_FROM_PROVEN_CONFIGURED_IMAGE}
set cases [list \
  [list B0 $bootstrap FORMAL_BOOTSTRAP NO_RECEIPT_REQUIRED 1 {0 0 0 0 0} PASS] \
  [list B1 $bootstrap FORMAL_BOOTSTRAP NO_RECEIPT_REQUIRED 1 {1 1 1 1 1} PASS] \
  [list B2 $bootstrap FORMAL_BOOTSTRAP NO_RECEIPT_REQUIRED 1 {UNREADABLE UNREADABLE UNREADABLE UNREADABLE UNREADABLE} FAIL_UNREADABLE_OR_UNSTABLE_DONE] \
  [list B3 $bootstrap FORMAL_BOOTSTRAP NO_RECEIPT_REQUIRED 1 {0 0 1 1 1} FAIL_UNREADABLE_OR_UNSTABLE_DONE] \
  [list B4 $bootstrap FORMAL_BOOTSTRAP NO_RECEIPT_REQUIRED 1 {0 0 0 0 0} PASS] \
  [list T0 $transition ARM_A_R1E FORMAL_READY_RECEIPT 1 {1 1 1 1 1} PASS] \
  [list T1 $transition ARM_A_R1E FORMAL_READY_RECEIPT 1 {0 0 0 0 0} FAIL_PROVEN_CONFIGURED_IMAGE_LOST] \
  [list T2 $transition ARM_A_R1E {} 1 {1 1 1 1 1} FAIL_MISSING_OR_INVALID_CONFIGURED_IMAGE_RECEIPT] \
  [list T3 $transition ARM_A_R1E VALID_ARM_A_RECEIPT 1 {1 1 1 1 1} FAIL_MISSING_OR_INVALID_CONFIGURED_IMAGE_RECEIPT] \
  [list C2 $bootstrap FORMAL_BOOTSTRAP NO_RECEIPT_REQUIRED 0 {0 0 0 0 0} FAIL_SELECTED_TARGET_MISMATCH]]

# Extra internal receipt-role assertions cover both allowed Arm-B receipts.
foreach receipt {VALID_ARM_A_RECEIPT ARM_A_TERMINAL_SAFE_DONE1_RECEIPT} {
  set result [r7_mode_observer::classify_preprogram $transition ARM_B_FORMAL $receipt 1 {1 1 1 1 1}]
  if {[dict get $result status] ne {PASS}} {
    puts stderr "internal Arm-B receipt fixture failed: $receipt"
    exit 1
  }
}

set handle [open $output_path {WRONLY CREAT EXCL}]
puts $handle {fixture,mode,role,receipt,target_match,done_samples,expected_precondition,actual_precondition,result}
set failures 0
foreach case $cases {
  lassign $case fixture mode role receipt target_match done_samples expected
  set classification [r7_mode_observer::classify_preprogram $mode $role $receipt $target_match $done_samples]
  set actual [dict get $classification status]
  set result [expr {$actual eq $expected ? {PASS} : {FAIL}}]
  if {$result ne {PASS}} { incr failures }
  set sample_text [join $done_samples {|}]
  puts $handle "$fixture,$mode,$role,$receipt,$target_match,$sample_text,$expected,$actual,$result"
  puts "PRECONDITION_FIXTURE_$fixture=$result EXPECTED=$expected ACTUAL=$actual"
}
close $handle

puts "PRECONDITION_FIXTURE_COUNT=[llength $cases]"
puts "PRECONDITION_FIXTURE_FAILURES=$failures"
puts {ARM_B_RECEIPT_ROLE_FIXTURES=PASS_BOTH_ALLOWED_RECEIPTS}
if {$failures != 0} {
  puts {MODE_AWARE_PRECONDITION_FIXTURES=FAIL}
  exit 1
}
puts {MODE_AWARE_PRECONDITION_FIXTURES=PASS_ALL}
exit 0
