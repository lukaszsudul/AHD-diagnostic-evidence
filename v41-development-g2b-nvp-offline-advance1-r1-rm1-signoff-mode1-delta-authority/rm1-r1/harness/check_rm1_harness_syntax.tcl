proc rm1_extract_named_procs {target slave wanted} {
  set fh [open $target r]
  fconfigure $fh -encoding utf-8
  set lines [split [read $fh] "\n"]
  close $fh
  set command ""
  set found [dict create]
  foreach line $lines {
    append command $line "\n"
    if {![info complete $command]} { continue }
    if {![catch {lindex $command 0} head] && $head eq "proc"} {
      set name [lindex $command 1]
      if {$name in $wanted} {
        if {[dict exists $found $name]} { error "DUPLICATE_TEST_PROC=$name" }
        interp eval $slave $command
        dict set found $name 1
      }
    }
    set command ""
  }
  foreach name $wanted {
    if {![dict exists $found $name]} { error "MISSING_TEST_PROC=$name" }
  }
}

proc rm1_mock_json_escape {value} {
  return [string map [list "\\" "\\\\" "\"" "\\\""] $value]
}

proc rm1_mock_binding_json {strings integers} {
  set fields [list]
  dict for {key value} $strings {
    lappend fields "  \"$key\": \"[rm1_mock_json_escape $value]\""
  }
  dict for {key value} $integers {
    lappend fields "  \"$key\": $value"
  }
  return "{\n[join $fields ",\n"]\n}"
}

proc rm1_expect_binding_failure {slave text label focus_sha affected_sha publication_sha} {
  interp eval $slave [list set ::mock_binding_text $text]
  set code [catch {interp eval $slave [list rm1_binding_receipt_gate \
    C:/rm1/binding.json $focus_sha $affected_sha $publication_sha]} detail]
  if {$code == 0} { error "BINDING_MOCK_NEGATIVE_DID_NOT_FAIL=$label" }
}

proc rm1_mock_binding_gate {target} {
  set slave [interp create]
  interp eval $slave {
    proc read_text {path} { return $::mock_binding_text }
  }
  set wanted {
    rm1_json_decode_string rm1_json_string_field rm1_json_integer_field
    rm1_binding_receipt_gate}
  rm1_extract_named_procs $target $slave $wanted

  set focus_path [file nativename [file normalize C:/rm1/focused.json]]
  set affected_path [file nativename [file normalize C:/rm1/affected.json]]
  set publication_path [file nativename [file normalize C:/rm1/publication.json]]
  set focus_sha [string repeat A 64]
  set affected_sha [string repeat B 64]
  set publication_sha [string repeat C 64]
  set strings [dict create \
    Task AHD_V41_G2B_NVP_DIAG2_RM1_PRE_VIVADO_RECEIPT_BINDING \
    Result PASS SourceCommit [string repeat 1 40] SourceTree [string repeat 2 40] \
    Branch diag/v41-g2b-nvp-video-diag2-rm1 \
    ExpectedParent fc37d815b5d64ef90dfbd99c57ae4cc09567b56f \
    DirectParentBinding PASS AuthorizedChangedSetBinding PASS \
    FocusedReceipt $focus_path FocusedReceiptSHA256 $focus_sha \
    FocusedHashAfterBinding PASS AffectedR3Receipt $affected_path \
    AffectedR3ReceiptSHA256 $affected_sha AffectedInputHashBinding PASS \
    PublicationReadbackReceipt $publication_path \
    PublicationReadbackReceiptSHA256 $publication_sha \
    RemoteRefReadback PASS CommitPinnedBlobReadback PASS \
    FullVivadoBuildStarted NO HardwareAccessed NO]
  set integers [dict create AuthorizedChangedSetFiles 11 FocusedHashAfterFiles 11 \
    AffectedInputHashFiles 11]
  set exact [rm1_mock_binding_json $strings $integers]
  foreach {name value} [list \
      source_commit [string repeat 1 40] source_tree [string repeat 2 40] \
      expected_branch diag/v41-g2b-nvp-video-diag2-rm1 \
      expected_parent fc37d815b5d64ef90dfbd99c57ae4cc09567b56f \
      focused_receipt [file normalize C:/rm1/focused.json] \
      affected_receipt [file normalize C:/rm1/affected.json] \
      publication_receipt [file normalize C:/rm1/publication.json]] {
    interp eval $slave [list set ::$name $value]
  }
  interp eval $slave [list set ::mock_binding_text $exact]
  if {[catch {interp eval $slave [list rm1_binding_receipt_gate \
      C:/rm1/binding.json $focus_sha $affected_sha $publication_sha]} detail]} {
    interp delete $slave
    error "BINDING_MOCK_POSITIVE_FAILED=$detail"
  }

  set bad_strings $strings
  dict set bad_strings FocusedReceiptSHA256 [string repeat D 64]
  rm1_expect_binding_failure $slave [rm1_mock_binding_json $bad_strings $integers] \
    FOCUSED_SHA $focus_sha $affected_sha $publication_sha
  set bad_strings $strings
  dict set bad_strings AffectedR3Receipt [file nativename [file normalize C:/rm1/other.json]]
  rm1_expect_binding_failure $slave [rm1_mock_binding_json $bad_strings $integers] \
    AFFECTED_PATH $focus_sha $affected_sha $publication_sha
  set bad_strings $strings
  dict set bad_strings PublicationReadbackReceiptSHA256 [string repeat D 64]
  rm1_expect_binding_failure $slave [rm1_mock_binding_json $bad_strings $integers] \
    PUBLICATION_SHA $focus_sha $affected_sha $publication_sha
  set duplicate [string replace $exact end end \
    ",\n  \"FocusedReceiptSHA256\": \"$focus_sha\"\n\}"]
  rm1_expect_binding_failure $slave $duplicate DUPLICATE_FIELD \
    $focus_sha $affected_sha $publication_sha
  interp delete $slave
}

proc rm1_expect_preseal_failure {slave text label {expected_glob *}} {
  interp eval $slave [list set ::mock_preseal_text $text]
  set code [catch {interp eval $slave rm1_pre_vivado_seal_gate} detail]
  if {$code == 0} { error "PRESEAL_MOCK_NEGATIVE_DID_NOT_FAIL=$label" }
  if {![string match $expected_glob $detail]} {
    error "PRESEAL_MOCK_NEGATIVE_WRONG_FAILURE=$label:$detail"
  }
}

proc rm1_mock_preseal_gate {target} {
  set temporary_paths [list]
  foreach tag {focused affected binding publication seal} {
    set channel [file tempfile path "rm1_${tag}_XXXXXX"]
    puts -nonewline $channel $tag
    close $channel
    dict set temporary $tag [file normalize $path]
    lappend temporary_paths [file normalize $path]
  }
  set donor [file normalize \
    {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R3_20260910T200154Z/scripts/g2b_nvp_video_diag1_r3_build.tcl}]
  if {![file isfile $donor]} { error "PRESEAL_MOCK_DONOR_MISSING=$donor" }
  set harness_root [file dirname [file normalize $target]]
  set expected_paths [dict create \
    FOCUSED_RECEIPT [dict get $temporary focused] \
    AFFECTED_R3_RECEIPT [dict get $temporary affected] \
    RECEIPT_BINDING [dict get $temporary binding] \
    PUBLICATION_READBACK_RECEIPT [dict get $temporary publication] \
    R3_DONOR_BUILD_TCL $donor]
  foreach {label name} {
      BUILD_HARNESS g2b_nvp_diag2_rm1_build.tcl
      FINALIZER g2b_nvp_diag2_rm1_finalize.tcl
      LAUNCHER invoke_rm1_one_shot_build.ps1
      BINDER bind_rm1_receipts_to_source.ps1
      AFFECTED_RUNNER run_rm1_affected_regressions.ps1
      STATIC_CHECKER check_rm1_build_harness.ps1
      TCL_SYNTAX_CHECKER check_rm1_harness_syntax.tcl
      PUBLICATION_SCHEMA RM1_PUBLICATION_READBACK_RECEIPT_SCHEMA.json
      README RM1_BUILD_HARNESS_README.md} {
    dict set expected_paths $label [file normalize [file join $harness_root $name]]
  }
  if {[dict size $expected_paths] != 14} { error "PRESEAL_MOCK_EXPECTED_SET_NOT_14" }

  set donor_sha 74CA15C2FCEADBC59876249E8EEB08D71D7FD787A0F7B422DC69BE737FB57D59
  set mock_hashes [dict create]
  set rows [list]
  set index 1
  dict for {label path} $expected_paths {
    if {$label eq "R3_DONOR_BUILD_TCL"} {
      set sha $donor_sha
    } else {
      set sha [format %064X $index]
    }
    dict set mock_hashes [file normalize $path] $sha
    lappend rows "$label|[file nativename $path]|$sha"
    incr index
  }
  set seal_sha [string repeat F 64]
  dict set mock_hashes [dict get $temporary seal] $seal_sha
  set exact [join $rows "\n"]

  set slave [interp create]
  interp eval $slave {
    proc read_text {path} { return $::mock_preseal_text }
    proc sha256_file {path} {
      set normalized [file normalize $path]
      if {![dict exists $::mock_hashes $normalized]} {
        error "PRESEAL_MOCK_UNSEALED_PATH=$normalized"
      }
      return [dict get $::mock_hashes $normalized]
    }
  }
  rm1_extract_named_procs $target $slave {rm1_pre_vivado_seal_gate}
  foreach {name value} [list \
      build_script_path [file normalize $target] \
      pre_vivado_seal [dict get $temporary seal] \
      expected_pre_vivado_seal_sha $seal_sha \
      focused_receipt [dict get $temporary focused] \
      affected_receipt [dict get $temporary affected] \
      binding_receipt [dict get $temporary binding] \
      publication_receipt [dict get $temporary publication] \
      donor_build_tcl $donor expected_donor_sha $donor_sha \
      expected_focused_sha [dict get $mock_hashes [dict get $temporary focused]] \
      expected_affected_sha [dict get $mock_hashes [dict get $temporary affected]] \
      expected_binding_sha [dict get $mock_hashes [dict get $temporary binding]] \
      expected_publication_sha [dict get $mock_hashes [dict get $temporary publication]] \
      mock_hashes $mock_hashes mock_preseal_text $exact] {
    interp eval $slave [list set ::$name $value]
  }
  if {[catch {interp eval $slave rm1_pre_vivado_seal_gate} detail] ||
      [llength $detail] != 14} {
    interp delete $slave
    error "PRESEAL_MOCK_POSITIVE_FAILED=$detail"
  }

  set donor_line "R3_DONOR_BUILD_TCL|[file nativename $donor]|$donor_sha"
  set wrong_donor_line "R3_DONOR_BUILD_TCL|[file nativename $donor]|[string repeat D 64]"
  rm1_expect_preseal_failure $slave [string map [list $donor_line $wrong_donor_line] $exact] \
    DONOR_SHA
  set without_donor [join [lsearch -all -inline -not -glob [split $exact "\n"] \
    {R3_DONOR_BUILD_TCL|*}] "\n"]
  rm1_expect_preseal_failure $slave $without_donor MISSING_DONOR
  rm1_expect_preseal_failure $slave "$exact\n$donor_line" DUPLICATE_DONOR

  set focused_path [dict get $temporary focused]
  set affected_path [dict get $temporary affected]
  set publication_path [dict get $temporary publication]
  set focused_sha [dict get $mock_hashes $focused_path]
  set affected_sha [dict get $mock_hashes $affected_path]
  set publication_sha [dict get $mock_hashes $publication_path]
  set affected_line "AFFECTED_R3_RECEIPT|[file nativename $affected_path]|$affected_sha"
  set publication_line \
    "PUBLICATION_READBACK_RECEIPT|[file nativename $publication_path]|$publication_sha"
  set alias_affected [string toupper $focused_path]
  set alias_publication [string tolower $focused_path]
  set alias_text [string map [list \
    $affected_line "AFFECTED_R3_RECEIPT|[file nativename $alias_affected]|$focused_sha" \
    $publication_line \
      "PUBLICATION_READBACK_RECEIPT|[file nativename $alias_publication]|$focused_sha"] $exact]
  interp eval $slave [list set ::affected_receipt $alias_affected]
  interp eval $slave [list set ::publication_receipt $alias_publication]
  interp eval $slave [list set ::expected_affected_sha $focused_sha]
  interp eval $slave [list set ::expected_publication_sha $focused_sha]
  rm1_expect_preseal_failure $slave $alias_text CASE_ALIAS_OMNIBUS \
    {*case-alias/duplicate path*}
  interp delete $slave
  foreach path $temporary_paths { file delete -- $path }
}

proc rm1_mock_xdc {target mode} {
  set slave [interp create]
  interp eval $slave [list set ::mock_mode $mode]
  interp eval $slave {
    set ::mock_false_path_counts [list]
    proc mock_cells {leaf count} {
      set result [list]
      for {set index 0} {$index < $count} {incr index} {
        lappend result "TOP/RM1_RAW_MARKER_MONITOR/${leaf}_reg\[$index\]"
      }
      return $result
    }
    proc get_cells {args} {
      set pattern [lindex $args end]
      if {[string first {(clear_sync1_source|} $pattern] >= 0} {
        set names {
          clear_sync1_source arm_sync1_source freeze_sync1_source
          freeze_manual_sync1_source ack_sync1_source abort_epoch_sync1_source
          armed_sync1_axi done_sync1_axi valid_sync1_axi overflow_sync1_axi
          ack_done_sync1_axi abort_ack_sync1_axi}
        if {$::mock_mode eq "missing_sync"} { set names [lrange $names 0 10] }
        set result [list]
        foreach name $names { lappend result "TOP/RM1_RAW_MARKER_MONITOR/${name}_reg" }
        return $result
      }
      if {[string index $pattern end] eq {$} &&
          [string first {RM1_RAW_MARKER_MONITOR/} $pattern] >= 0 &&
          [string first {_source_reg\[} $pattern] < 0} {
        return [list TOP/RM1_RAW_MARKER_MONITOR/exact_sync1_reg]
      }
      foreach {leaf width} {session_source 16 route_source 3 window_source 2} {
        if {[string first "${leaf}_reg" $pattern] >= 0} {
          if {[string index $pattern end] eq {$}} {
            return [list "TOP/RM1_RAW_MARKER_MONITOR/${leaf}_reg\[0\]"]
          }
          if {$::mock_mode eq "extra_mailbox" && $leaf eq "session_source"} {
            incr width
          }
          return [mock_cells $leaf $width]
        }
      }
      error "MOCK_UNEXPECTED_GET_CELLS_PATTERN:$pattern"
    }
    proc get_pins {args} {
      set at [lsearch -exact $args -of_objects]
      if {$at < 0 || $at + 1 >= [llength $args]} { error "MOCK_GET_PINS_MALFORMED" }
      set result [list]
      foreach cell [lindex $args [expr {$at + 1}]] { lappend result "$cell/D" }
      return $result
    }
    proc set_false_path {args} {
      if {[llength $args] != 2 || [lindex $args 0] ne "-to"} {
        error "MOCK_SET_FALSE_PATH_MALFORMED"
      }
      lappend ::mock_false_path_counts [llength [lindex $args 1]]
    }
  }
  set code [catch {interp eval $slave [list source $target]} detail]
  if {$mode eq "exact"} {
    if {$code != 0} {
      interp delete $slave
      error "XDC_MOCK_POSITIVE_FAILED:$detail"
    }
    set counts [interp eval $slave {set ::mock_false_path_counts}]
    interp delete $slave
    if {$counts ne {12 21}} { error "XDC_MOCK_FALSE_PATH_COUNTS:$counts" }
    return
  }
  interp delete $slave
  if {$code == 0} { error "XDC_MOCK_NEGATIVE_DID_NOT_FAIL:$mode" }
}

if {$argc < 1} {
  puts stderr "usage: check_rm1_harness_syntax.tcl FILE..."
  exit 2
}
foreach target $argv {
  set fh [open $target r]
  fconfigure $fh -encoding utf-8
  set text [read $fh]
  close $fh
  if {![info complete $text]} {
    puts stderr "TCL_SCRIPT_INCOMPLETE=$target"
    exit 1
  }
  puts "TCL_SCRIPT_COMPLETE=$target"
  if {[file tail $target] eq "g2b_nvp_diag2_rm1_build.tcl"} {
    rm1_mock_binding_gate $target
    rm1_mock_preseal_gate $target
    puts "BINDING_MOCK_EXACT_PATH_SHA=PASS"
    puts "BINDING_MOCK_NEGATIVE_FOCUSED_SHA=PASS"
    puts "BINDING_MOCK_NEGATIVE_AFFECTED_PATH=PASS"
    puts "BINDING_MOCK_NEGATIVE_PUBLICATION_SHA=PASS"
    puts "BINDING_MOCK_NEGATIVE_DUPLICATE_FIELD=PASS"
    puts "PRESEAL_MOCK_EXACT_14_WITH_DONOR=PASS"
    puts "PRESEAL_MOCK_NEGATIVE_DONOR_SHA=PASS"
    puts "PRESEAL_MOCK_NEGATIVE_MISSING_DONOR=PASS"
    puts "PRESEAL_MOCK_NEGATIVE_DUPLICATE_DONOR=PASS"
    puts "PRESEAL_MOCK_NEGATIVE_CASE_ALIAS_OMNIBUS=PASS"
  }
  if {[string tolower [file extension $target]] eq ".xdc"} {
    rm1_mock_xdc $target exact
    rm1_mock_xdc $target missing_sync
    rm1_mock_xdc $target extra_mailbox
    puts "XDC_MOCK_EXACT_12_PLUS_21=PASS"
    puts "XDC_MOCK_NEGATIVE_MISSING_SYNC=PASS"
    puts "XDC_MOCK_NEGATIVE_EXTRA_MAILBOX=PASS"
  }
}
exit 0
