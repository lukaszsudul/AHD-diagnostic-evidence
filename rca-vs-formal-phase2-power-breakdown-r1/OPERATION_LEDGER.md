# Operation ledger

```text
FULL_BUILDS=0
SYNTHESIS_COMMANDS=0
IMPLEMENTATION_COMMANDS=0
SOURCE_CHANGES=0
OPERATING_CONDITION_CHANGES=0
SWITCHING_ACTIVITY_CHANGES=0
HARDWARE_ACTIONS=0
FORMAL_REPOSITORY_MUTATIONS=0
PRESERVED_VIVADO_BATCH_INVOCATIONS=12
READ_ONLY_DCP_OPEN_ATTEMPTS=9
EXPLICIT_CLOSE_DESIGN_INVOCATIONS=6
FAIL_CLOSED_PROCESS_EXIT_DCP_UNLOADS=3
COMPLETE_IDENTICAL_REPORT_SEQUENCES=2
SUCCESSFUL_REPORT_POWER_INVOCATIONS=12
FAILED_REPORT_POWER_INVOCATIONS=0
HELP_CAPTURE_ATTEMPTS=3
SUCCESSFUL_HELP_CAPTURES=1
SUPPLEMENTAL_CLOCK_INVENTORY_ATTEMPTS=5
SUPPLEMENTAL_CLOCK_INVENTORY_FAIL_CLOSED_ATTEMPTS=3
SUPPLEMENTAL_CLOCK_INVENTORY_PASSES=2
OPTIONAL_SSN_REPORTS=0
```

The first four read-only checkpoint opens were three formal Phase-2 opens and
one RC-A open. The first formal open stopped at the top-identity check because the
Vivado session label had been mistaken for the top; the second stopped before
power analysis because the installed switching-activity syntax requires an
explicit type or object collection. Both stopped before `report_power`, and
their raw evidence is retained. The adapted final formal sequence and the RC-A
sequence then completed identically, with six successful power-report forms
per role.

Five further read-only opens performed the required clock-domain fallback:
three formal attempts stopped fail-closed on Tcl query edge cases, followed by
one successful formal inventory and one successful RC-A inventory. All partial
logs were preserved. Failed attempts exited without saving; successful attempts
used `close_design`. No attempt invoked `report_power` or changed an assumption.

Only bounded hashing/copying, read-only routed-checkpoint opening, object
queries, reporting, parsing, evidence packaging, and the authorized scoped
evidence publication were performed.
