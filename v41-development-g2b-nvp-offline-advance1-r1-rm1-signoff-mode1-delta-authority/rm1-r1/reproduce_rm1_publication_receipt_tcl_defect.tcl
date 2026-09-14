set source_commit a7436eb81f69f09ee84301bcf214fcaa2b680ee8
set input_line {  "SourceCommit": "a7436eb81f69f09ee84301bcf214fcaa2b680ee8",}

# This is the exact unsafe construction class used by the failed build harness.
set unsafe_script {set unsafe_pattern "\"SourceCommit\"[ \\t]*:[ \\t]*\"$source_commit\""}
set rc [catch {uplevel #0 $unsafe_script} message options]

if {$rc != 1} {
  puts stderr "REPRO_FAIL=UNSAFE_CONSTRUCTION_DID_NOT_ERROR"
  exit 1
}
if {![string match {*invalid command name*} $message]} {
  puts stderr "REPRO_FAIL=WRONG_ERROR:$message"
  exit 1
}

# Braces protect the character classes while format inserts the already
# authority-validated 40-hex identity as data. Tcl does not recursively
# substitute the returned string.
set safe_pattern [format {"SourceCommit"[ \t]*:[ \t]*"%s"} $source_commit]
if {![regexp -- $safe_pattern $input_line]} {
  puts stderr "REPRO_FAIL=SAFE_PATTERN_DID_NOT_MATCH"
  exit 1
}

puts "RM1_TCL_DEFECT_REPRODUCED=PASS"
puts "ROOT_CAUSE=TCL_COMMAND_SUBSTITUTION_OF_SQUARE_BRACKET_REGEX_INSIDE_DOUBLE_QUOTED_WORD"
puts "UNSAFE_ERROR=$message"
puts "INPUT_LINE=$input_line"
puts "SAFE_PATTERN=$safe_pattern"
puts "DATA_TRIGGERED_COMMAND_EXECUTION_AFTER_CORRECTION=NO"
exit 0
