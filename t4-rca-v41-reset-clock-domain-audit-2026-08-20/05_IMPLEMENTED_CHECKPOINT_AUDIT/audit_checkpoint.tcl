if {$argc != 2} {
  puts stderr "usage: audit_checkpoint.tcl <checkpoint.dcp> <output_dir>"
  exit 2
}

set checkpoint [file normalize [lindex $argv 0]]
set output_dir [file normalize [lindex $argv 1]]
file mkdir $output_dir

proc emit_query {path label objects} {
  set fh [open $path a]
  puts $fh "===== $label ====="
  puts $fh "COUNT=[llength $objects]"
  foreach obj $objects {
    puts $fh "OBJECT=$obj"
    foreach prop {NAME REF_NAME TYPE LOC BEL CLOCK_PIN IS_SEQUENTIAL DONT_TOUCH INIT} {
      if {![catch {set value [get_property $prop $obj]}]} {
        puts $fh "$prop=$value"
      }
    }
    puts $fh ""
  }
  close $fh
}

open_checkpoint $checkpoint

set summary [file join $output_dir checkpoint_summary.txt]
set fh [open $summary w]
puts $fh "CHECKPOINT=$checkpoint"
puts $fh "PART=[get_property PART [current_design]]"
puts $fh "DESIGN=[current_design]"
puts $fh "DCP_VERSION=[get_property DCP_VERSION [current_design]]"
puts $fh "CLOCK_COUNT=[llength [get_clocks -quiet]]"
close $fh

report_clocks -file [file join $output_dir report_clocks.rpt]
if {[catch {report_clock_networks -file [file join $output_dir report_clock_networks.rpt]} msg]} {
  set fh [open [file join $output_dir report_clock_networks_error.txt] w]
  puts $fh $msg
  close $fh
}
if {[catch {report_clock_interaction -file [file join $output_dir report_clock_interaction.rpt]} msg]} {
  set fh [open [file join $output_dir report_clock_interaction_error.txt] w]
  puts $fh $msg
  close $fh
}

set query [file join $output_dir nvp_clock_reset_objects.txt]
file delete -force $query
emit_query $query "NVP_CELLS" [get_cells -hier -quiet -filter {NAME =~ *nvp*}]
emit_query $query "NVP_POR_CELLS" [get_cells -hier -quiet -filter {NAME =~ *nvp_por*}]
emit_query $query "I2C_STATE_CELLS" [get_cells -hier -quiet -filter {NAME =~ *u_sequence*state*}]
emit_query $query "SCL_CELLS" [get_cells -hier -quiet -filter {NAME =~ *scl*}]
emit_query $query "SDA_CELLS" [get_cells -hier -quiet -filter {NAME =~ *sda*}]
emit_query $query "NVP_RESET_CELLS" [get_cells -hier -quiet -filter {NAME =~ *nvp*rst* || NAME =~ *nvp*reset*}]

set nets [file join $output_dir nvp_clock_reset_nets.txt]
set fh [open $nets w]
foreach pattern {*user_clk* *axi_aclk* *autonomous_clk* *nvp_por* *nvp*rst* *nvp*reset* *scl*oen* *sda*oen*} {
  set found [get_nets -hier -quiet -filter "NAME =~ $pattern"]
  puts $fh "===== $pattern COUNT=[llength $found] ====="
  foreach net $found {
    puts $fh "NET=$net"
    set drivers [get_pins -quiet -of_objects $net -filter {DIRECTION == OUT}]
    set loads [get_pins -quiet -of_objects $net -filter {DIRECTION == IN}]
    puts $fh "DRIVERS=$drivers"
    puts $fh "LOAD_COUNT=[llength $loads]"
    puts $fh "CLOCKS=[get_clocks -quiet -of_objects $net]"
  }
}
close $fh

foreach port_name {nvp_rst nvp_scl nvp_sda sys_rst_n sys_clk_p sys_clk_n} {
  set port [get_ports -quiet $port_name]
  if {[llength $port] == 1} {
    report_property -all $port > [file join $output_dir "port_${port_name}_properties.txt"]
  }
}

close_design
exit 0
