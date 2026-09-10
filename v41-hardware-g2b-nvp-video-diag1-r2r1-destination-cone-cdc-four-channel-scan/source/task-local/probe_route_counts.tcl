set dcp {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R1_20260909T203832Z/reports/vivado_full/G2B_NVP_VIDEO_DIAG1_R1_ROUTED.dcp}
open_checkpoint $dcp
puts "LOGICAL_NETS=[llength [get_nets -quiet -hier]]"
puts "ROUTED_NETS=[llength [report_route_status -return_nets -route_type ROUTED]]"
puts "HAS_ROUTING_NETS=[llength [report_route_status -return_nets -route_type HAS_ROUTING]]"
puts "INTRASITE_NETS=[llength [report_route_status -return_nets -route_type INTRASITE]]"
puts "UNROUTED_NETS=[llength [report_route_status -return_nets -route_type UNROUTED]]"
puts "PARTIAL_NETS=[llength [report_route_status -return_nets -route_type PARTIAL]]"
puts "ROUTED_FULLY=[report_route_status -boolean_check ROUTED_FULLY]"
puts "ERRORS_IN_ROUTES=[report_route_status -boolean_check ERRORS_IN_ROUTES]"
report_route_status -file {C:/FPGA/G2B_NVP_VIDEO_DIAG1_R2R1_20260910T104826Z/reports/probe_route_status_full.rpt}
close_design
exit 0
