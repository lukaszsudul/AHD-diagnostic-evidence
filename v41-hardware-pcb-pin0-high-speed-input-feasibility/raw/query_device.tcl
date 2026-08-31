set out_dir [file normalize [pwd]]
set part_name xc7a35t-csg325-2
set proposed_pins {E16 B16 C16 A17 B17 C17 C18 E17 D18 R16 R18 T15 T18 T17 U17 V17 U16 V16 K17 L18 M17 N17 C13 J18}

create_project -in_memory -part $part_name pcb_pin0_device_query
read_verilog [file join $out_dir dummy.v]
synth_design -top dummy -part $part_name

proc safe_prop {name obj} {
  set val ""
  catch {set val [get_property $name $obj]}
  return $val
}

set summary [open [file join $out_dir PIN_OBJECT_SUMMARY.tsv] w]
puts $summary "PIN\tPACKAGE_OBJECT\tSITE\tIOBANK\tPIN_FUNC\tIS_CLK_CAPABLE\tIS_GLOBAL_CLK\tIS_DUAL\tIS_CONFIG_PIN\tIS_USER_ACCESSIBLE"

set raw [open [file join $out_dir PIN_OBJECT_ALL_PROPERTIES.txt] w]
puts $raw "VIVADO_VERSION=[version -short]"
puts $raw "PART_REQUESTED=$part_name"
puts $raw "CURRENT_PART=[get_property PART [current_project]]"

foreach pin $proposed_pins {
  set pobj [get_package_pins -quiet $pin]
  puts $raw "\n===== PACKAGE_PIN $pin ====="
  if {[llength $pobj] != 1} {
    puts $raw "ERROR package-object-count=[llength $pobj]"
    puts $summary "$pin\tERROR\t\t\t\t\t\t\t\t"
    continue
  }
  set sites [get_sites -quiet -of_objects $pobj]
  set banks [get_iobanks -quiet -of_objects $pobj]
  set props [lsort [list_property $pobj]]
  foreach prop $props {
    set val ""
    catch {set val [get_property $prop $pobj]}
    puts $raw "PACKAGE.$prop=$val"
  }
  foreach site $sites {
    puts $raw "-- SITE $site --"
    foreach prop [lsort [list_property $site]] {
      set val ""
      catch {set val [get_property $prop $site]}
      puts $raw "SITE.$prop=$val"
    }
    set bels [get_bels -quiet -of_objects $site]
    puts $raw "SITE.BELS=[join $bels ,]"
  }
  foreach bank $banks {
    puts $raw "-- IOBANK $bank --"
    foreach prop [lsort [list_property $bank]] {
      set val ""
      catch {set val [get_property $prop $bank]}
      puts $raw "IOBANK.$prop=$val"
    }
  }
  puts $summary [join [list $pin $pobj [join $sites ,] [join $banks ,] [safe_prop PIN_FUNC $pobj] [safe_prop IS_CLK_CAPABLE $pobj] [safe_prop IS_GLOBAL_CLK $pobj] [safe_prop IS_DUAL $pobj] [safe_prop IS_CONFIG_PIN $pobj] [safe_prop IS_USER_ACCESSIBLE $pobj]] "\t"]
}
close $summary
close $raw

set allio [open [file join $out_dir ALL_USER_PACKAGE_PINS.tsv] w]
puts $allio "PIN\tSITE\tIOBANK\tPIN_FUNC\tIS_CLK_CAPABLE\tIS_GLOBAL_CLK\tIS_CONFIG_PIN\tIS_USER_ACCESSIBLE"
foreach pobj [lsort -dictionary [get_package_pins]] {
  set pin [get_property NAME $pobj]
  set sites [get_sites -quiet -of_objects $pobj]
  set banks [get_iobanks -quiet -of_objects $pobj]
  puts $allio [join [list $pin [join $sites ,] [join $banks ,] [safe_prop PIN_FUNC $pobj] [safe_prop IS_CLK_CAPABLE $pobj] [safe_prop IS_GLOBAL_CLK $pobj] [safe_prop IS_CONFIG_PIN $pobj] [safe_prop IS_USER_ACCESSIBLE $pobj]] "\t"]
}
close $allio

set partf [open [file join $out_dir EXACT_PART.txt] w]
puts $partf "REQUESTED=$part_name"
puts $partf "CURRENT_PROJECT_PART=[get_property PART [current_project]]"
puts $partf "VIVADO_VERSION=[version -short]"
close $partf

close_project
exit
