# Failed-command root cause

FAILED_TCL_LINE=237-238

FAILED_OBJECT_QUERY=`get_cells -quiet -hier -filter {NAME =~ *NVP_SCL_IOBUF || NAME =~ *NVP_SDA_IOBUF}`

FAILED_OBJECT_COUNT=2

FAILED_REPORT_PURPOSE=Document every matched NVP SCL/SDA IOBUF and all of its properties.

REPORT_PROPERTY_ROOT_CAUSE=MULTI_OBJECT_LIST_PASSED_TO_SINGLE_OBJECT_COMMAND

REPORT_PROPERTY_CARDINALITY_FIX=DETERMINISTIC_FOREACH_ALL_MATCHED_OBJECTS

The query intentionally identifies both physical NVP IOBUFs, so this is multi-object report semantics. The correction sorts both full hierarchical names, requires exactly two matches, invokes `report_property` once per object, and emits a combined index plus two per-object files. No object is silently discarded.

