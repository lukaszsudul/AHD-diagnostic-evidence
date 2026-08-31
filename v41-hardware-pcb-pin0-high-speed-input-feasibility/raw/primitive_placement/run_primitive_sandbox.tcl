set exact_part xc7a35tcsg325-2
set root_dir [file dirname [info script]]
set ch1_pins {B16 C16 A17 B17 C17 C18 E17 D18}
set ch2_current_pins {R18 T15 T18 T17 U17 V17 U16 V16}
set ch2_u15_pins {R18 U15 T18 T17 U17 V17 U16 V16}

proc emit_site_resources {label pin_name} {
    set pp [get_package_pins -quiet $pin_name]
    set iob [get_sites -quiet -of_objects $pp]
    set cr [get_clock_regions -quiet -of_objects $iob]
    puts "RESOURCE|PIN|$label|$pin_name|FUNC=[get_property PIN_FUNC $pp]|BANK=[get_property BANK $pp]|IOB=$iob|CR=$cr"
    if {[regexp {IOB_X([0-9]+)Y([0-9]+)} $iob dummy x y]} {
        foreach prefix {ILOGIC IDELAY OLOGIC} {
            set site_name "${prefix}_X${x}Y${y}"
            set site [get_sites -quiet $site_name]
            puts "RESOURCE|DEDICATED_SITE|$label|$pin_name|$prefix|$site|BELS=[get_bels -quiet -of_objects $site]"
        }
    }
}

proc set_common_constraints {ch1_pins ch2_pins} {
    set_property PACKAGE_PIN E16 [get_ports ch1_vclk]
    set_property PACKAGE_PIN R16 [get_ports ch2_vclk]
    for {set i 0} {$i < 8} {incr i} {
        set_property PACKAGE_PIN [lindex $ch1_pins $i] [get_ports "ch1_vdo\[$i\]"]
        set_property PACKAGE_PIN [lindex $ch2_pins $i] [get_ports "ch2_vdo\[$i\]"]
    }
    set_property IOSTANDARD LVCMOS33 [get_ports *]
    create_clock -name ch1_vclk_in -period 6.734 [get_ports ch1_vclk]
    create_clock -name ch2_vclk_in -period 6.734 [get_ports ch2_vclk]
    create_clock -name idelay_ref_200 -period 5.000 [get_ports idelay_refclk_200]
}

proc emit_placements {variant} {
    puts "PLACE|BEGIN|$variant"
    foreach cell [lsort -dictionary [get_cells -hier -filter {REF_NAME == BUFIO || REF_NAME == BUFR || REF_NAME == IDELAYCTRL || REF_NAME == IDELAYE2 || REF_NAME == IDDR}]] {
        puts "PLACE|CELL|$variant|$cell|REF=[get_property REF_NAME $cell]|LOC=[get_property LOC $cell]|BEL=[get_property BEL $cell]"
    }
    foreach port [lsort -dictionary [get_ports {ch1_vclk ch1_vdo[*] ch2_vclk ch2_vdo[*]}]] {
        puts "PLACE|PORT|$variant|$port|PACKAGE_PIN=[get_property PACKAGE_PIN $port]|IOSTANDARD=[get_property IOSTANDARD $port]"
    }
    puts "PLACE|END|$variant"
}

puts "SANDBOX|VIVADO_VERSION|[version -short]"
puts "SANDBOX|EXACT_PART_QUERY|[get_parts -quiet -filter {DEVICE == xc7a35t && PACKAGE == csg325 && SPEED == -2}]"
create_project -in_memory -part $exact_part
read_verilog [file join $root_dir primitive_sandbox.v]
synth_design -top primitive_sandbox -part $exact_part
write_checkpoint -force [file join $root_dir primitive_post_synth.dcp]

foreach pin {E16 B16 C16 A17 B17 C17 C18 E17 D18 R16 R18 T15 U15 T18 T17 U17 V17 U16 V16 C13} {
    emit_site_resources PROPOSED_AND_ALT $pin
}
foreach cr_name {X0Y0 X0Y1} {
    set cr [get_clock_regions -quiet $cr_name]
    foreach site_type {BUFIO BUFR IDELAYCTRL} {
        set resources [get_sites -quiet -of_objects $cr -filter "SITE_TYPE == $site_type"]
        puts "RESOURCE|CLOCK_REGION|$cr_name|$site_type|$resources|BELS=[get_bels -quiet -of_objects $resources]"
    }
}

set_common_constraints $ch1_pins $ch2_current_pins
opt_design
place_design
puts "SANDBOX|CURRENT_PINSET|PLACE_COMPLETED"
emit_placements CURRENT_T15
report_drc -file [file join $root_dir current_t15_post_place_drc.rpt]
report_clock_utilization -file [file join $root_dir current_t15_clock_utilization.rpt]
write_checkpoint -force [file join $root_dir current_t15_post_place.dcp]

close_design
open_checkpoint [file join $root_dir primitive_post_synth.dcp]
set_common_constraints $ch1_pins $ch2_u15_pins
opt_design
place_design
puts "SANDBOX|U15_ALTERNATIVE|PLACE_COMPLETED"
emit_placements ALTERNATIVE_U15
report_drc -file [file join $root_dir alternative_u15_post_place_drc.rpt]
report_clock_utilization -file [file join $root_dir alternative_u15_clock_utilization.rpt]
write_checkpoint -force [file join $root_dir alternative_u15_post_place.dcp]

close_design
close_project
exit
