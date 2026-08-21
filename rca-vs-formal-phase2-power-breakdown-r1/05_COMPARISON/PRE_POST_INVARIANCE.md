# Pre/post analysis invariance

The report-only Tcl contains no operating-condition setter, switching-activity
setter/reset, or SAIF command. Core-voltage queries and default activity
queries are byte-identical before and after `report_power`; clock definitions
and networks are semantically identical after removing only report date and
output-command headers.

The estimated junction temperature and average top-port activity change after
power analysis because they are derived analysis results populated by
vectorless propagation. They are not user assumption mutations.

```text
OPERATING_CONDITIONS_CHANGED_DURING_TASK=NO
SWITCHING_ACTIVITY_CHANGED_DURING_TASK=NO
VECTORLESS_DERIVED_ACTIVITY_POPULATED_BY_REPORT_POWER=YES
```