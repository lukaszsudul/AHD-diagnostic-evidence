set out {C:/FPGA/V41_NVP_ROUTED_DCP_POWER_TIMING_AUDIT_R1/raw/VIVADO_HELP_2025_2/HELP_API_PROBE.txt}
set fh [open $out w]
puts $fh "INFO_COMMAND_HELP=[info commands help]"
puts $fh "INFO_COMMAND_VERSION=[info commands version]"
if {[catch {version -short} v]} {
    puts $fh "VERSION_ERROR=$v"
} else {
    puts $fh "VERSION=$v"
}
foreach {label script} {
    FORM_A {help -return_string report_power}
    FORM_B {help report_power -return_string}
    FORM_C {help -args report_power}
    FORM_D {help report_power}
} {
    if {[catch {uplevel #0 $script} result opts]} {
        puts $fh "${label}_STATUS=ERROR"
        puts $fh "${label}_RESULT=$result"
    } else {
        puts $fh "${label}_STATUS=PASS"
        puts $fh "${label}_LENGTH=[string length $result]"
        puts $fh "${label}_RESULT_BEGIN"
        puts $fh $result
        puts $fh "${label}_RESULT_END"
    }
}
close $fh
exit 0
