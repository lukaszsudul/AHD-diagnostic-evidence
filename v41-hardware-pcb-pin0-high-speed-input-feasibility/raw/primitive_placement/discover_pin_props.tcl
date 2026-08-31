set requested_part "xc7a35t-csg325-2"
set part_matches [get_parts -quiet -filter {DEVICE == xc7a35t && PACKAGE == csg325 && SPEED == -2}]
puts "REQUESTED_PART=$requested_part"
puts "MATCHES=$part_matches"
puts "MATCH_COUNT=[llength $part_matches]"
foreach part $part_matches {
    puts "PART_OBJECT=$part"
    puts [report_property -return_string $part]
}
if {[llength $part_matches] != 1} {
    error "Expected exactly one xc7a35t/csg325/-2 part"
}
set exact_part [lindex $part_matches 0]
create_project -in_memory -part $exact_part
puts "CURRENT_PART=[get_property PART [current_project]]"

set proposed_pins {E16 B16 C16 A17 B17 C17 C18 E17 D18 R16 R18 T15 T18 T17 U17 V17 U16 V16 K17 L18 M17 N17 C13 J18}
foreach pin_name $proposed_pins {
    puts "===== PACKAGE_PIN $pin_name ====="
    set pp [get_package_pins -quiet $pin_name]
    puts "PACKAGE_PIN_OBJECT=$pp"
    puts "PACKAGE_PIN_COUNT=[llength $pp]"
    if {[llength $pp] == 1} {
        puts [report_property -return_string $pp]
        set sites [get_sites -quiet -of_objects $pp]
        puts "SITES=$sites"
        foreach site $sites {
            puts "--- SITE $site ---"
            puts [report_property -return_string $site]
            set bank [get_iobanks -quiet -of_objects $site]
            puts "IOBANK_FROM_SITE=$bank"
            set cr [get_clock_regions -quiet -of_objects $site]
            puts "CLOCK_REGION_FROM_SITE=$cr"
            puts "BELS=[get_bels -quiet -of_objects $site]"
        }
        puts "IOBANK_FROM_PIN=[get_iobanks -quiet -of_objects $pp]"
        puts "CLOCK_REGION_FROM_PIN=[get_clock_regions -quiet -of_objects $pp]"
    }
}
close_project
exit
