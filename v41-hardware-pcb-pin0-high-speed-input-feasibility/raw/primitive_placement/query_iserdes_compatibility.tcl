set root_dir [file dirname [info script]]
open_checkpoint [file join $root_dir current_t15_post_place.dcp]
puts "ISERDES_QUERY|PART|[get_property PART [current_design]]"
foreach primitive {IDDR ISERDESE2 IDELAYE2} {
    set lib [get_lib_cells -quiet $primitive]
    puts "ISERDES_QUERY|LIB_CELL|$primitive|COUNT=[llength $lib]|OBJECT=$lib"
    foreach prop [lsort [list_property $lib]] {
        if {[regexp {PRIMITIVE|SITE|BEL|CLASS|NAME|TYPE} $prop]} {
            puts "ISERDES_QUERY|LIB_PROP|$primitive|$prop|[get_property $prop $lib]"
        }
    }
}
foreach site_name {ILOGIC_X0Y70 ILOGIC_X0Y20 ILOGIC_X0Y16 ILOGIC_X0Y23} {
    set site [get_sites -quiet $site_name]
    puts "ISERDES_QUERY|SITE|$site_name|TYPE=[get_property SITE_TYPE $site]|CR=[get_clock_regions -quiet -of_objects $site]"
    foreach bel [get_bels -quiet -of_objects $site] {
        puts "ISERDES_QUERY|BEL|$site_name|$bel"
        foreach prop [lsort [list_property $bel]] {
            if {[regexp {PRIMITIVE|SITE|BEL|CLASS|NAME|TYPE} $prop]} {
                puts "ISERDES_QUERY|BEL_PROP|$bel|$prop|[get_property $prop $bel]"
            }
        }
    }
}
foreach cell [get_cells -hier -filter {REF_NAME == IDDR}] {
    puts "ISERDES_QUERY|PLACED_IDDR|$cell|LOC=[get_property LOC $cell]|BEL=[get_property BEL $cell]|PRIMITIVE_TYPE=[get_property PRIMITIVE_TYPE $cell]"
}
close_design
exit
