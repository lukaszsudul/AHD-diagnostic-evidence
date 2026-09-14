set ::passed 0

proc pass {id} {
  incr ::passed
  puts "RM1_TCL_${id}_PASS"
}

proc require_true {condition message} {
  if {![uplevel 1 [list expr $condition]]} {
    error $message
  }
}

proc split_tsv_exact {line expected_count} {
  set fields [split $line "\t"]
  if {[llength $fields] != $expected_count} {
    error "TSV_FIELD_COUNT=[llength $fields]/$expected_count"
  }
  return $fields
}

proc publication_identity_patterns {source_commit source_tree} {
  if {![regexp {^[0-9a-f]{40}$} $source_commit] ||
      ![regexp {^[0-9a-f]{40}$} $source_tree]} {
    error "IDENTITY_FORMAT_INVALID"
  }
  return [list \
    [format {"SourceCommit"[ \t]*:[ \t]*"%s"} $source_commit] \
    [format {"SourceTree"[ \t]*:[ \t]*"%s"} $source_tree]]
}

proc require_sha_equal {actual expected} {
  if {![regexp {^[0-9A-F]{64}$} $actual] || $actual ne $expected} {
    error "SHA_MISMATCH"
  }
}

proc require_artifact {path} {
  if {![file isfile $path]} {
    error "ARTIFACT_MISSING"
  }
}

proc require_unique_tsv_labels {records} {
  set seen [dict create]
  foreach record $records {
    set fields [split_tsv_exact $record 3]
    set label [lindex $fields 0]
    if {[dict exists $seen $label]} {
      error "DUPLICATE_RECORD=$label"
    }
    dict set seen $label 1
  }
  return [dict size $seen]
}

proc canonical_receipt {records} {
  return [join [lsort -ascii $records] "\n"]
}

set source_commit a7436eb81f69f09ee84301bcf214fcaa2b680ee8
set source_tree cce4a561a30d58d4accc2a45e4eb8d72e5a7ec26

# T1 literal tab-separated record.
set fields [split_tsv_exact "LABEL\tC:/evidence/file.json\tABC" 3]
require_true {[lindex $fields 1] eq "C:/evidence/file.json"} T1_BAD_FIELD
pass T1

# T2 escaped backslash+t remains data and is not treated as a delimiter.
set fields [split_tsv_exact {LABEL\tC:/literal\ttext\tABC} 1]
require_true {[lindex $fields 0] eq {LABEL\tC:/literal\ttext\tABC}} T2_BAD_LITERAL
pass T2

# T3 empty middle field.
set fields [split_tsv_exact "A\t\tB" 3]
require_true {[lindex $fields 1] eq ""} T3_EMPTY_FIELD_LOST
pass T3

# T4 leading empty field.
set fields [split_tsv_exact "\tA\tB" 3]
require_true {[lindex $fields 0] eq ""} T4_LEADING_EMPTY_LOST
pass T4

# T5 trailing empty field.
set fields [split_tsv_exact "A\tB\t" 3]
require_true {[lindex $fields 2] eq ""} T5_TRAILING_EMPTY_LOST
pass T5

# T6 spaces in path.
set fields [split_tsv_exact "LABEL\tC:/Folder With Space/file.json\tABC" 3]
require_true {[lindex $fields 1] eq "C:/Folder With Space/file.json"} T6_SPACE_PATH_CHANGED
pass T6

# T7 square brackets remain literal data.
set fields [split_tsv_exact {LABEL	[not_a_command]	ABC} 3]
require_true {[lindex $fields 1] eq {[not_a_command]}} T7_BRACKETS_CHANGED
pass T7

# T8 Windows backslashes remain literal data.
set windows_path {C:\FPGA\Folder\file.json}
set fields [split_tsv_exact "LABEL\t$windows_path\tABC" 3]
require_true {[lindex $fields 1] eq $windows_path} T8_BACKSLASH_PATH_CHANGED
pass T8

# T9 Unicode path/name remains literal data.
set unicode_path {C:\Users\Łukasz Suduł\dowód.json}
set fields [split_tsv_exact "LABEL\t$unicode_path\tABC" 3]
require_true {[lindex $fields 1] eq $unicode_path} T9_UNICODE_CHANGED
pass T9

# T10 malformed field count fails explicitly.
set rc [catch {split_tsv_exact "ONLY\tTWO" 3} message]
require_true {$rc == 1 && [string match {TSV_FIELD_COUNT=*} $message]} T10_NOT_FAIL_CLOSED
pass T10

# T11 expected publication receipt identity is accepted.
set receipt [format {{
  "Result": "PASS",
  "SourceCommit": "%s",
  "SourceTree": "%s",
  "RemoteRefReadback": "PASS",
  "CommitPinnedBlobReadback": "PASS"
}} $source_commit $source_tree]
foreach pattern [publication_identity_patterns $source_commit $source_tree] {
  require_true {[regexp -- $pattern $receipt]} T11_IDENTITY_NOT_ACCEPTED
}
pass T11

# T12 wrong hash is rejected.
set rc [catch {require_sha_equal [string repeat A 64] [string repeat B 64]} message]
require_true {$rc == 1 && $message eq "SHA_MISMATCH"} T12_WRONG_HASH_ACCEPTED
pass T12

# T13 missing artifact is rejected.
set missing [file join [file dirname [info script]] __definitely_missing__.json]
set rc [catch {require_artifact $missing} message]
require_true {$rc == 1 && $message eq "ARTIFACT_MISSING"} T13_MISSING_ACCEPTED
pass T13

# T14 duplicate record is rejected.
set rc [catch {require_unique_tsv_labels [list "A\tP1\tH1" "A\tP2\tH2"]} message]
require_true {$rc == 1 && $message eq "DUPLICATE_RECORD=A"} T14_DUPLICATE_ACCEPTED
pass T14

# T15 data containing a Tcl command never executes.
set ::command_substitution_sentinel 0
set hostile {[set ::command_substitution_sentinel 1]}
set fields [split_tsv_exact "LABEL\t$hostile\tABC" 3]
require_true {$::command_substitution_sentinel == 0} T15_DATA_EXECUTED
require_true {[lindex $fields 1] eq $hostile} T15_DATA_CHANGED
set build_text [read [set fh [open [file join [file dirname [info script]] g2b_nvp_diag2_rm1_build.tcl] r]]]
close $fh
require_true {[regexp -all -line {\[format \{"Source(Commit|Tree)"\[ \\t\]\*:\[ \\t\]\*"%s"\}} $build_text] == 2} T15_SAFE_BUILD_PATTERN_MISSING
require_true {![string match {*"\\"SourceCommit\\"[ \\\\t]*:*} $build_text]} T15_UNSAFE_BUILD_PATTERN_REMAINS
pass T15

# T16 canonical receipt output is deterministic.
set records [list "TREE\t$source_tree\tB" "COMMIT\t$source_commit\tA"]
set first [canonical_receipt $records]
set second [canonical_receipt [lreverse $records]]
require_true {$first eq $second} T16_NONDETERMINISTIC_OUTPUT
pass T16

if {$::passed != 16} {
  puts stderr "RM1_TCL_HARNESS_REGRESSION=$::passed/16 FAIL"
  exit 1
}
puts "RM1_TCL_HARNESS_REGRESSION=16/16 PASS"
puts "DATA_TRIGGERED_COMMAND_EXECUTION_AFTER_CORRECTION=NO"
exit 0
