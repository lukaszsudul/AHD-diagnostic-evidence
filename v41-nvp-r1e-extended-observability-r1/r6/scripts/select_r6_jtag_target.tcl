# R6 canonical JTAG-target selector.
# Sourcing this file has no hardware effect. Live enumeration occurs only when
# r6_target::select_live_target is called by an authorized Hardware Manager
# session.

namespace eval r6_target {
  variable canonical_id {Xilinx/80802026a98b01}
  variable canonical_suffix {/Xilinx/80802026a98b01}
  variable legacy_id {Digilent/210241768436}

  proc emit {key value} {
    puts "$key=$value"
    flush stdout
  }

  proc normalized_path {target_path} {
    return [string map {\\ /} [string trim $target_path]]
  }

  proc canonical_id_from_path {target_path} {
    variable canonical_id
    variable canonical_suffix
    set normalized [normalized_path $target_path]
    if {$normalized eq $canonical_id} {
      return $canonical_id
    }
    set suffix_length [string length $canonical_suffix]
    if {[string length $normalized] > $suffix_length &&
        [string range $normalized end-[expr {$suffix_length - 1}] end] eq $canonical_suffix} {
      return $canonical_id
    }
    return {}
  }

  proc classify_nonmatch {target_path} {
    variable canonical_id
    variable legacy_id
    set normalized [normalized_path $target_path]
    if {$normalized eq $legacy_id || [string match "*/$legacy_id" $normalized]} {
      return FAIL_OLD_TARGET_NOT_SELECTED
    }

    set expected_leaf [lindex [split $canonical_id /] end]
    set actual_components [split $normalized /]
    set actual_vendor [lindex $actual_components end-1]
    set actual_leaf [lindex $actual_components end]
    if {$actual_vendor eq {Xilinx} &&
        ([string first $actual_leaf $expected_leaf] == 0 ||
         [string first $expected_leaf $actual_leaf] == 0)} {
      return FAIL_NEAR_MATCH
    }
    return FAIL_CANONICAL_ID_MISMATCH
  }

  proc classify_target_paths {target_paths} {
    set total_count [llength $target_paths]
    if {$total_count == 0} {
      return [dict create status FAIL_NO_TARGET selected_path {} canonical_id {} total_count 0 exact_match_count 0]
    }

    set exact_matches {}
    foreach target_path $target_paths {
      if {[canonical_id_from_path $target_path] ne {}} {
        lappend exact_matches $target_path
      }
    }
    set exact_match_count [llength $exact_matches]

    if {$total_count != 1} {
      set status [expr {$exact_match_count > 1 ? {FAIL_DUPLICATE} : {FAIL_TARGET_COUNT_NOT_ONE}}]
      return [dict create status $status selected_path {} canonical_id {} total_count $total_count exact_match_count $exact_match_count]
    }

    set only_target [lindex $target_paths 0]
    set canonical [canonical_id_from_path $only_target]
    if {$canonical eq {}} {
      return [dict create status [classify_nonmatch $only_target] selected_path {} canonical_id {} total_count 1 exact_match_count 0]
    }

    return [dict create status PASS selected_path $only_target canonical_id $canonical total_count 1 exact_match_count 1]
  }

  proc safe_property_value {value} {
    return [string map [list "\r" {\r} "\n" {\n}] $value]
  }

  proc record_object_properties {label object} {
    set properties [lsort -dictionary [list_property $object]]
    emit ${label}_PROPERTY_COUNT [llength $properties]
    set property_index 0
    foreach property_name $properties {
      if {[catch {get_property $property_name $object} property_value]} {
        set property_value {UNREADABLE}
      }
      emit ${label}_PROPERTY_${property_index}_NAME $property_name
      emit ${label}_PROPERTY_${property_index}_VALUE [safe_property_value $property_value]
      incr property_index
    }
    return $properties
  }

  proc write_object_properties {object output_path} {
    set normalized_output [file normalize $output_path]
    if {[file exists $normalized_output]} {
      error "property evidence already exists: $normalized_output"
    }
    set handle [open $normalized_output {WRONLY CREAT EXCL}]
    set properties [lsort -dictionary [list_property $object]]
    puts $handle "property_name\tproperty_value"
    foreach property_name $properties {
      if {[catch {get_property $property_name $object} property_value]} {
        set property_value {UNREADABLE}
      }
      puts $handle "$property_name\t[safe_property_value $property_value]"
    }
    close $handle
    return [llength $properties]
  }

  proc select_live_target {} {
    set targets [get_hw_targets -quiet]
    set target_paths {}
    set target_index 0
    foreach target $targets {
      set target_path [string trim $target]
      lappend target_paths $target_path
      emit R6_ENUMERATED_TARGET_${target_index}_PATH $target_path
      record_object_properties R6_ENUMERATED_TARGET_${target_index} $target
      incr target_index
    }

    set classification [classify_target_paths $target_paths]
    emit R6_TOTAL_TARGET_COUNT [dict get $classification total_count]
    emit R6_EXACT_CANONICAL_MATCH_COUNT [dict get $classification exact_match_count]
    emit R6_TARGET_SELECTOR_STATUS [dict get $classification status]
    if {[dict get $classification status] ne {PASS}} {
      error "R6 target selector failed: [dict get $classification status]"
    }

    set selected_path [dict get $classification selected_path]
    set selected_objects [get_hw_targets -quiet $selected_path]
    if {[llength $selected_objects] != 1} {
      error "R6 selected target object count changed: [llength $selected_objects]"
    }
    emit R6_SELECTED_JTAG_CANONICAL_ID [dict get $classification canonical_id]
    emit R6_FULL_JTAG_TARGET_PATH $selected_path
    emit R6_TARGET_MATCH_MODE EXACT_CANONICAL_ID_OR_EXACT_PATH_SUFFIX
    emit R6_FALLBACK_TO_FIRST_TARGET NO
    emit R6_LEGACY_HS2_REQUIRED NO
    return [lindex $selected_objects 0]
  }
}
