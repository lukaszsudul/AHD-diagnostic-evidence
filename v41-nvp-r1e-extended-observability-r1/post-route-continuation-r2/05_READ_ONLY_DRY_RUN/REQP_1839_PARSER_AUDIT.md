# REQP-1839 parser audit

SEMANTIC_REQP_1839_VIOLATION_COUNT=4
RAW_REQP_1839_TEXT_OCCURRENCES=5
ACCEPTED_BASELINE_COUNT=4
SEMANTIC_COUNT_COMPATIBLE_WITH_BASELINE=YES

The generated DRC report is semantically identical to the frozen prior report:
its summary row reports four `REQP-1839` warnings and it contains four detailed
records numbered `#1` through `#4`. The string `REQP-1839` appears five times
because the summary row also contains the rule label.

The task-local helper used an unqualified full-text occurrence count and then
required that raw value to equal four. It therefore rejected the valid report
after all report commands completed. This is a harness parser defect, not an
implementation, DRC, or scientific NVP result.

