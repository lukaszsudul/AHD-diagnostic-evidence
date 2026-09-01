set part_name xc7a35tcsg325-2
proc pin1_safe_prop {prop obj} {
  set value ""
  catch {set value [get_property $prop $obj]}
  return $value
}
puts "PIN1_BEGIN_DEVICE_QUERY"
puts "VIVADO_VERSION=[version -short]"
puts "VIVADO_VERSION_FULL=[version]"
puts "REQUESTED_PART=$part_name"
set part_obj [get_parts -quiet $part_name]
puts "PART_COUNT=[llength $part_obj]"
if {[llength $part_obj] != 1} {
  puts "PIN1_FATAL_PART_NOT_FOUND"
  exit 2
}
puts "PART_NAME=[get_property NAME $part_obj]"
puts "PART_FAMILY=[get_property FAMILY $part_obj]"
puts "PART_ARCHITECTURE=[get_property ARCHITECTURE $part_obj]"
puts "PART_DEVICE=[get_property DEVICE $part_obj]"
puts "PART_PACKAGE=[get_property PACKAGE $part_obj]"
puts "PART_SPEED=[get_property SPEED $part_obj]"
foreach prop {TEMPERATURE_GRADE SPEED PACKAGE DEVICE FAMILY ARCHITECTURE} {
  if {[lsearch -exact [list_property $part_obj] $prop] >= 0} {
    puts "PART_${prop}=[get_property $prop $part_obj]"
  }
}

create_project -in_memory -part $part_name pin1_query

foreach pin_name {D13 A14 T12 J18} {
  puts "PIN1_BEGIN_PIN=$pin_name"
  set pin_obj [get_package_pins -quiet $pin_name]
  puts "PIN_COUNT=[llength $pin_obj]"
  if {[llength $pin_obj] == 1} {
    puts "PIN_NAME=[get_property NAME $pin_obj]"
    foreach prop {BANK PIN_FUNC IS_CLK_CAPABLE IS_GLOBAL_CLK IS_REGIONAL_CLK IS_VREF IS_DUAL_GRANULARITY IS_DELAYCTRL IS_BYTE_GROUP} {
      if {[lsearch -exact [list_property $pin_obj] $prop] >= 0} {
        puts "PIN_${prop}=[get_property $prop $pin_obj]"
      }
    }
    set sites [get_sites -quiet -of_objects $pin_obj]
    puts "PIN_SITES=[join $sites ,]"
    foreach site $sites {
      puts "PIN_SITE_NAME=[get_property NAME $site]"
      puts "PIN_SITE_TYPE=[pin1_safe_prop SITE_TYPE $site]"
      if {[lsearch -exact [list_property $site] CLOCK_REGION] >= 0} {
        puts "PIN_SITE_CLOCK_REGION=[get_property CLOCK_REGION $site]"
      }
      puts "PIN_SITE_X=[pin1_safe_prop SITE_X $site]"
      puts "PIN_SITE_Y=[pin1_safe_prop SITE_Y $site]"
      if {[regexp {IOB_X([0-9]+)Y([0-9]+)} $site dummy x y]} {
        foreach prefix {ILOGIC IDELAY OLOGIC} {
          set dedicated_site [get_sites -quiet "${prefix}_X${x}Y${y}"]
          puts "PIN_DEDICATED_${prefix}_SITE=[join $dedicated_site ,]"
          puts "PIN_DEDICATED_${prefix}_BELS=[join [get_bels -quiet -of_objects $dedicated_site] ,]"
        }
      }
    }
    puts "PIN_REPORT_PROPERTY_BEGIN"
    report_property $pin_obj
    puts "PIN_REPORT_PROPERTY_END"
  }
  puts "PIN1_END_PIN=$pin_name"
}

puts "PIN1_END_DEVICE_QUERY"

puts "PIN1_BEGIN_IMPL"
read_verilog [file normalize "clock_forward.v"]
read_xdc [file normalize "clock_forward.xdc"]
synth_design -top clock_forward -part $part_name
puts "PIN1_SYNTH_DESIGN_STATUS=[pin1_safe_prop STATUS [current_design]]"
opt_design
place_design
puts "PIN1_PLACE_DESIGN_STATUS=[pin1_safe_prop STATUS [current_design]]"
route_design
puts "PIN1_ROUTE_DESIGN_STATUS=[pin1_safe_prop STATUS [current_design]]"

report_io -file "impl_report_io.txt"
report_clock_utilization -file "impl_report_clock_utilization.txt"
report_route_status -file "impl_report_route_status.txt"
report_timing_summary -file "impl_report_timing_summary.txt"
report_drc -file "impl_report_drc.txt"

set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
set drc_critical [get_drc_violations -quiet -filter {SEVERITY == Critical_Warning}]
set drc_warnings [get_drc_violations -quiet -filter {SEVERITY == Warning}]
puts "PIN1_DRC_ERROR_COUNT=[llength $drc_errors]"
puts "PIN1_DRC_CRITICAL_WARNING_COUNT=[llength $drc_critical]"
puts "PIN1_DRC_WARNING_COUNT=[llength $drc_warnings]"

foreach cell_name {u_ibuf u_bufgce u_oddr u_obuf} {
  set cell_obj [get_cells -quiet $cell_name]
  puts "PIN1_IMPL_CELL=$cell_name COUNT=[llength $cell_obj]"
  if {[llength $cell_obj] == 1} {
    foreach prop {REF_NAME LOC BEL IS_LOC_FIXED IS_BEL_FIXED STATUS} {
      if {[lsearch -exact [list_property $cell_obj] $prop] >= 0} {
        puts "PIN1_IMPL_CELL_${cell_name}_${prop}=[get_property $prop $cell_obj]"
      }
    }
    puts "PIN1_IMPL_CELL_${cell_name}_SITES=[join [get_sites -quiet -of_objects $cell_obj] ,]"
    puts "PIN1_IMPL_CELL_${cell_name}_BELS=[join [get_bels -quiet -of_objects $cell_obj] ,]"
  }
}

foreach port_name {osc27_d13 gate_enable_t12 nvp_clk_a14} {
  set port_obj [get_ports -quiet $port_name]
  puts "PIN1_IMPL_PORT=$port_name PACKAGE_PIN=[get_property PACKAGE_PIN $port_obj] IOSTANDARD=[get_property IOSTANDARD $port_obj]"
  puts "PIN1_IMPL_PORT_${port_name}_SITES=[join [get_sites -quiet -of_objects $port_obj] ,]"
}

puts "PIN1_END_IMPL"
close_project
exit 0
