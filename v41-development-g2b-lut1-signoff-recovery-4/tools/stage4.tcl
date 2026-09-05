phase DRC 600
report_drc -file "$::R/DRC.rpt"
set errors 0; set critical 0; set rows {Name,Severity,Description}
foreach v [get_drc_violations -quiet] {
 set severity [string toupper [get_property SEVERITY $v]]
 if {$severity eq "ERROR"} {incr errors}
 if {$severity eq "CRITICAL WARNING"} {incr critical}
 append rows "\n[csv_value [get_property NAME $v]],[csv_value $severity],[csv_value [get_property DESCRIPTION $v]]"
}
save drc_objects.csv $rows
save drc_result.txt "ERRORS=$errors\nCRITICAL_WARNINGS=$critical"
if {$errors || $critical} {error "DRC gate failed errors=$errors critical=$critical"}
