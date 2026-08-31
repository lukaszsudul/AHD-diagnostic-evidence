set expected_part "xc7a35tcsg325-2"
set matches [get_parts -quiet -filter {DEVICE == xc7a35t && PACKAGE == csg325 && SPEED == -2}]
puts "AUDIT|VIVADO_VERSION|[version -short]"
puts "AUDIT|PART_MATCHES|$matches"
if {[llength $matches] != 1 || [lindex $matches 0] ne $expected_part} {
    error "Exact target part mismatch: expected $expected_part, got $matches"
}
create_project -in_memory -part $expected_part
read_verilog [file join [file dirname [info script]] dummy_top.v]
synth_design -top dummy_top -part $expected_part
puts "AUDIT|CURRENT_PART|[get_property PART [current_project]]"
puts "AUDIT|CURRENT_DESIGN|[current_design]"

set requested_pins {E16 B16 C16 A17 B17 C17 C18 E17 D18 R16 R18 T15 T18 T17 U17 V17 U16 V16 K17 L18 M17 N17 C13 J18}
set all_pin_props {NAME CLASS BANK PIN_FUNC SITE IS_BONDED IS_CLK_CAPABLE IS_DUAL IS_GENERAL_PURPOSE IS_GLOBAL_CLK IS_VREF IS_VRN IS_VRP IS_DCI IS_GC IS_MRCC IS_SRCC DIFF_PAIR_PIN DIFF_PAIR_TYPE}
set site_props {NAME CLASS SITE_TYPE RPM_X RPM_Y X Y CLOCK_REGION}

foreach pin_name $requested_pins {
    set pp [get_package_pins -quiet $pin_name]
    puts "AUDIT|PIN_BEGIN|$pin_name|COUNT=[llength $pp]"
    if {[llength $pp] != 1} {
        puts "AUDIT|PIN_MISSING|$pin_name"
        continue
    }
    foreach prop $all_pin_props {
        if {[lsearch -exact [list_property $pp] $prop] >= 0} {
            puts "AUDIT|PIN_PROP|$pin_name|$prop|[get_property $prop $pp]"
        }
    }
    set sites [get_sites -quiet -of_objects $pp]
    puts "AUDIT|PIN_SITES|$pin_name|$sites"
    foreach site $sites {
        foreach prop $site_props {
            if {[lsearch -exact [list_property $site] $prop] >= 0} {
                puts "AUDIT|SITE_PROP|$pin_name|$site|$prop|[get_property $prop $site]"
            }
        }
        set cr [get_clock_regions -quiet -of_objects $site]
        set bank [get_iobanks -quiet -of_objects $site]
        set bels [get_bels -quiet -of_objects $site]
        puts "AUDIT|SITE_REL|$pin_name|$site|CLOCK_REGION=$cr|IOBANK=$bank|BELS=$bels"
    }
    puts "AUDIT|PIN_END|$pin_name"
}

puts "AUDIT|ALL_BANK14_PIN_BEGIN"
foreach pp [lsort -dictionary [get_package_pins -quiet -filter {BANK == 14 && IS_BONDED == 1}]] {
    set pn [get_property NAME $pp]
    set func [get_property PIN_FUNC $pp]
    set site [get_property SITE $pp]
    set cr [get_clock_regions -quiet -of_objects [get_sites -quiet $site]]
    set cc "ORDINARY"
    if {[string match *MRCC* $func]} {set cc "MRCC"}
    if {[string match *SRCC* $func]} {set cc "SRCC"}
    puts "AUDIT|BANK_PIN|14|$pn|$func|$site|$cr|$cc"
}
puts "AUDIT|ALL_BANK14_PIN_END"

puts "AUDIT|ALL_BANK15_PIN_BEGIN"
foreach pp [lsort -dictionary [get_package_pins -quiet -filter {BANK == 15 && IS_BONDED == 1}]] {
    set pn [get_property NAME $pp]
    set func [get_property PIN_FUNC $pp]
    set site [get_property SITE $pp]
    set cr [get_clock_regions -quiet -of_objects [get_sites -quiet $site]]
    set cc "ORDINARY"
    if {[string match *MRCC* $func]} {set cc "MRCC"}
    if {[string match *SRCC* $func]} {set cc "SRCC"}
    puts "AUDIT|BANK_PIN|15|$pn|$func|$site|$cr|$cc"
}
puts "AUDIT|ALL_BANK15_PIN_END"

foreach clock_pin {E16 R16 C13 T15} {
    set pp [get_package_pins -quiet $clock_pin]
    set site [get_sites -quiet -of_objects $pp]
    set cr [get_clock_regions -quiet -of_objects $site]
    puts "AUDIT|CLOCK_CONTEXT|$clock_pin|SITE=$site|CLOCK_REGION=$cr|PIN_FUNC=[get_property PIN_FUNC $pp]"
    foreach pattern {BUFIO* BUFR* IDELAYCTRL*} {
        set sites [get_sites -quiet -of_objects $cr -filter "SITE_TYPE =~ $pattern"]
        puts "AUDIT|CLOCK_REGION_SITES|$clock_pin|$pattern|$sites"
    }
}

close_design
close_project
exit
