phase METHODOLOGY 600
report_methodology -file "$::R/METHODOLOGY.rpt"
set rows {Name,Severity,Description}
foreach v [get_methodology_violations -quiet] {
 append rows "\n[csv_value [get_property NAME $v]],[csv_value [get_property SEVERITY $v]],[csv_value [get_property DESCRIPTION $v]]"
}
save methodology_objects.csv $rows
