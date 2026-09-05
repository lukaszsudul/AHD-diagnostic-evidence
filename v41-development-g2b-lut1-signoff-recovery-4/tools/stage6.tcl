phase CLOCK_RESOURCES 600
report_clocks -file "$::R/CLOCKS.rpt"
report_clock_utilization -file "$::R/CLOCK_UTILIZATION.rpt"
report_clock_interaction -file "$::R/CLOCK_INTERACTION.rpt"
report_utilization -file "$::R/UTILIZATION.rpt"
report_ram_utilization -file "$::R/RAM_UTILIZATION.rpt"
report_property -file "$::R/DESIGN_PROPERTIES.txt" [current_design]
set clocks {Name,Period_ns,Frequency_MHz,Generated,Source_Pins}
foreach c [get_clocks -quiet] {
 set period [get_property PERIOD $c]
 if {$period<=0} {error "invalid clock period"}
 append clocks "\n[csv_value $c],$period,[expr {1000.0/$period}],[csv_value [property_or_unknown IS_GENERATED $c]],[csv_value [property_or_unknown SOURCE_PINS $c]]"
}
save clocks.csv $clocks
set pins [get_pins -quiet -hier -regexp {.*AXI_LITE_HOST_BRIDGE.*/C}]
set axi [get_clocks -quiet -of_objects $pins]
if {[llength $pins]==0 || [llength $axi]!=1 || abs([get_property PERIOD $axi]-16)>0.0001} {error "AXI clock gate failed"}
if {abs([get_property PERIOD [get_clocks userclk1]]-16)>0.0001} {error "user clock drift"}
save clock_gate.txt "RESULT=PASS\nUSER_MHZ=62.500\nAXI_MHZ=62.500\nAXI_CLOCK=$axi"
set text [read_text "$::R/UTILIZATION.rpt"]
set result "RESULT=PASS"
foreach label {{Slice LUTs} {Slice Registers} {Block RAM Tile} DSPs} key {LUT FF BRAM DSP} expected {20800 41600 50 90} {
 lassign [utilization_row $text $label] used avail
 append result "\n${key}_USED=$used\n${key}_AVAILABLE=$avail"
 if {$avail != $expected || $used>$avail || ($key eq "LUT" && $used>18720)} {save resources.txt $result; error "PRODUCT resource gate failed $key=$used/$avail"}
}
set boxes [get_cells -quiet -hier -filter {IS_BLACKBOX == 1}]
if {[llength $boxes]!=0} {error "unresolved blackboxes"}
set debug [get_debug_cores -quiet]
save debug_cores.txt "COUNT=[llength $debug]\nCORES=$debug"
save resources.txt "$result\nBLACK_BOXES=0"
set pcie [get_cells -quiet -hier -filter {REF_NAME == PCIE_2_1}]
require_count pcie $pcie 1
report_property -file "$::R/PCIE_PROPERTIES.txt" $pcie
save CLOCK_RESOURCES_PASS.marker PASS
