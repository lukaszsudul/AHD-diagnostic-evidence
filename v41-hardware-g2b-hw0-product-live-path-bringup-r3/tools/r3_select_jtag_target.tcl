# R3-local read-only canonical JTAG target selector.

namespace eval r3_target {
  variable canonical_id {Xilinx/80802026a98b01}
  variable canonical_suffix {/Xilinx/80802026a98b01}

  proc emit {key value} {
    puts "$key=$value"
    flush stdout
  }

  proc canonical_id_from_path {target_path} {
    variable canonical_id
    variable canonical_suffix
    set normalized [string map {\\ /} [string trim $target_path]]
    if {$normalized eq $canonical_id} { return $canonical_id }
    set n [string length $canonical_suffix]
    if {[string length $normalized] > $n &&
        [string range $normalized end-[expr {$n - 1}] end] eq $canonical_suffix} {
      return $canonical_id
    }
    return {}
  }

  proc classify_paths {paths} {
    set matches {}
    foreach path $paths {
      if {[canonical_id_from_path $path] ne {}} { lappend matches $path }
    }
    if {[llength $paths] != 1} {
      return [dict create status FAIL_TARGET_COUNT count [llength $paths] matches [llength $matches]]
    }
    if {[llength $matches] != 1} {
      return [dict create status FAIL_CANONICAL_ID count 1 matches [llength $matches]]
    }
    return [dict create status PASS count 1 matches 1 selected [lindex $matches 0]]
  }

  proc safe_value {value} {
    return [string map [list "\r" {\r} "\n" {\n}] $value]
  }

  proc write_properties {object output_path} {
    set output_path [file normalize $output_path]
    if {[file exists $output_path]} { error "evidence already exists: $output_path" }
    set fh [open $output_path {WRONLY CREAT EXCL}]
    puts $fh "property_name\tproperty_value"
    foreach name [lsort -dictionary [list_property $object]] {
      if {[catch {get_property $name $object} value]} { set value UNREADABLE }
      puts $fh "$name\t[safe_value $value]"
    }
    close $fh
  }

  proc select_live {} {
    set targets [get_hw_targets -quiet]
    set paths {}
    set i 0
    foreach target $targets {
      set path [string trim $target]
      lappend paths $path
      emit R3_ENUMERATED_TARGET_${i}_PATH $path
      incr i
    }
    set result [classify_paths $paths]
    emit R3_TOTAL_TARGET_COUNT [dict get $result count]
    emit R3_EXACT_CANONICAL_MATCH_COUNT [dict get $result matches]
    emit R3_TARGET_SELECTOR_STATUS [dict get $result status]
    if {[dict get $result status] ne {PASS}} {
      error "R3 target selector failed: [dict get $result status]"
    }
    set selected_path [dict get $result selected]
    set selected [get_hw_targets -quiet $selected_path]
    if {[llength $selected] != 1} { error "selected target object count changed" }
    emit R3_SELECTED_JTAG_CANONICAL_ID [canonical_id_from_path $selected_path]
    emit R3_FULL_JTAG_TARGET_PATH $selected_path
    return [lindex $selected 0]
  }
}
