set requested_part xc7a35tcsg325-2

proc safe_property {property object} {
  set value "<ABSENT>"
  if {[lsearch -exact [list_property $object] $property] >= 0} {
    set value [get_property $property $object]
  }
  return $value
}

puts "PWR0_SANDBOX_BEGIN"
puts "VIVADO_VERSION=[version -short]"
set part_object [get_parts -quiet $requested_part]
puts "REQUESTED_PART=$requested_part"
puts "PART_COUNT=[llength $part_object]"
if {[llength $part_object] != 1} {
  puts "PWR0_FATAL_EXACT_PART_NOT_FOUND"
  exit 2
}
foreach property {NAME DEVICE PACKAGE SPEED FAMILY ARCHITECTURE} {
  puts "PART_${property}=[safe_property $property $part_object]"
}

create_project -in_memory -part $requested_part pwr0_pudc_high_query
read_verilog [file normalize "pudc_high_legality.v"]
read_xdc [file normalize "pudc_high_legality.xdc"]
synth_design -top pudc_high_legality -part $requested_part

puts "CONFIG_VOLTAGE=[get_property CONFIG_VOLTAGE [current_design]]"
puts "CFGBVS=[get_property CFGBVS [current_design]]"
puts "CURRENT_A35T_PRODUCT_SPI_WIDTH=UNRESOLVED"

set pudc_design_properties [lsearch -all -inline -glob [list_property [current_design]] "*PUDC*"]
puts "PUDC_DESIGN_PROPERTIES=[join $pudc_design_properties ,]"

foreach pin_name {E8 F12 F13 J15 J16 J18 K16 L15 L17 P10 R11 R12 T10 T18} {
  set pin_object [get_package_pins -quiet $pin_name]
  puts "PIN=$pin_name COUNT=[llength $pin_object] PIN_FUNC=[safe_property PIN_FUNC $pin_object] BANK=[safe_property BANK $pin_object]"
}

opt_design
place_design
report_io -file "pwr0_v2_report_io.rpt"
report_drc -file "pwr0_v2_report_drc.rpt"

set drc_errors [get_drc_violations -quiet -filter {SEVERITY == Error}]
set drc_critical [get_drc_violations -quiet -filter {SEVERITY == Critical_Warning}]
set drc_warnings [get_drc_violations -quiet -filter {SEVERITY == Warning}]
puts "DRC_ERROR_COUNT=[llength $drc_errors]"
puts "DRC_CRITICAL_WARNING_COUNT=[llength $drc_critical]"
puts "DRC_WARNING_COUNT=[llength $drc_warnings]"
foreach violation [concat $drc_errors $drc_critical $drc_warnings] {
  puts "DRC=[get_property NAME $violation]|[get_property SEVERITY $violation]|[get_property DESCRIPTION $violation]"
}

puts "NO_WRITE_BITSTREAM_COMMAND=TRUE"
puts "PUDC_STRAP_IS_EXTERNAL_AND_NOT_MODELED_BY_VIVADO=TRUE"
puts "PWR0_SANDBOX_END"
close_project
exit 0
