# CONT1R3R3: one exact DCP -> one full .bit, with read-only preflight.
# No synthesis, implementation, XDC replay, settings changes, or hardware access.
proc r3_fail {reason} {
    puts stderr "CONT1R3R3_FATAL: $reason"
    exit 1
}

set input_dcp {C:/FPGA/G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_20260916T185629Z/inputs/CONT1R3R1_SIGNED_OFF_ROUTED.dcp}
set output_bit {C:/FPGA/G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_20260916T185629Z/firmware/AHD_v41_CONT1R3R3_DIAGNOSTIC.bit}
set route_report {C:/FPGA/G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_20260916T185629Z/logs/route_status.rpt}
set drc_report {C:/FPGA/G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R3_20260916T185629Z/logs/pre_bitstream_drc.rpt}

if {![file isfile $input_dcp]} {r3_fail "exact copied DCP absent"}
if {[file exists $output_bit]} {r3_fail "fresh output path is already occupied"}
puts "CONT1R3R3_TOOL_VERSION_BEGIN"
set tool_version [version]
puts $tool_version
puts "CONT1R3R3_TOOL_VERSION_END"
if {[string first "2025.2" $tool_version] < 0 || [string first "6299465" $tool_version] < 0} {
    r3_fail "Vivado version/build mismatch"
}
puts "CONT1R3R3_INPUT_DCP=$input_dcp"
puts "CONT1R3R3_OUTPUT_BIT=$output_bit"

if {[catch {open_checkpoint $input_dcp} err]} {r3_fail "open_checkpoint failed: $err"}
set design [current_design]
set part [get_property PART $design]
set top [get_property TOP $design]
puts "CONT1R3R3_OPENED_PART=$part"
puts "CONT1R3R3_OPENED_TOP=$top"
if {$part ne "xc7a35tcsg325-2"} {r3_fail "opened DCP part mismatch"}
if {$top ne "ahd_capture_top_xdma"} {r3_fail "opened DCP top mismatch"}

# Fixed allowlist of nonsecret existing configuration properties. Missing
# properties are reported as unavailable; no property is changed.
foreach prop {
    BITSTREAM.GENERAL.COMPRESS
    BITSTREAM.CONFIG.STARTUPCLK
    BITSTREAM.CONFIG.CONFIGRATE
    BITSTREAM.CONFIG.SPI_BUSWIDTH
    BITSTREAM.CONFIG.USERID
} {
    if {[catch {get_property $prop $design} value]} {
        puts "CONT1R3R3_CONFIG_$prop=UNAVAILABLE"
    } else {
        puts "CONT1R3R3_CONFIG_$prop=$value"
    }
}

if {[catch {report_route_status -file $route_report} err]} {r3_fail "read-only route report failed: $err"}
if {[catch {report_drc -file $drc_report} err]} {r3_fail "read-only DRC report failed: $err"}
set route_handle [open $route_report r]
set route_text [read $route_handle]
close $route_handle
foreach {label expected} {
    {# of routable nets} 38667
    {# of fully routed nets} 38667
    {# of nets with routing errors} 0
} {
    set pattern [format {%s[. ]*:[ \t]*%d[ \t]*:} $label $expected]
    if {![regexp -- $pattern $route_text]} {r3_fail "route report gate mismatch: $label"}
}
puts "CONT1R3R3_ROUTE_GATE=38667/38667;ERRORS=0"

set drc_handle [open $drc_report r]
set drc_text [read $drc_handle]
close $drc_handle
if {![regexp {Checks found:[ \t]*24} $drc_text]} {r3_fail "default DRC count differs from accepted 24"}
if {[regexp {[|][ \t]*(Error|Critical Warning)[ \t]*[|]} $drc_text]} {r3_fail "default DRC has error or critical warning"}
foreach {rule count} {
    IOSR-1 2
    PDCN-1569 1
    REQP-1839 12
    REQP-1840 8
    RTSTAT-10 1
} {
    set pattern [format {[|][ \t]*%s[ \t]*[|][ \t]*Warning[ \t]*[|][^\n]*[|][ \t]*%d[ \t]*[|]} $rule $count]
    if {![regexp -- $pattern $drc_text]} {r3_fail "default DRC warning vector mismatch: $rule"}
}
puts "CONT1R3R3_DRC_GATE=0_ERRORS;0_CRITICAL_WARNINGS;24_ACCEPTED_ORDINARY_WARNINGS"
if {[file exists $output_bit]} {r3_fail "output appeared before generation"}

puts "CONT1R3R3_WRITE_BITSTREAM_BEGIN"
flush stdout
if {[catch {write_bitstream $output_bit} err]} {r3_fail "write_bitstream failed: $err"}
puts "CONT1R3R3_WRITE_BITSTREAM_COMPLETED"
flush stdout
exit 0
