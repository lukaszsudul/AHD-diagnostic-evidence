# Configured-image receipt helper correction audit

The first offline-only formal-ready receipt construction stopped before
creating an output because the accepted post-loader evidence prints each BAR
size twice: once inside `BAR_PARSER_OUTPUT_BEGIN/END` and once in the summary.
Both occurrences were identical (`131072` and `65536`).

The task-local receipt helper was corrected to require at least one occurrence
and exactly one unique value. Missing or conflicting values still fail. This
does not alter program, JTAG, reboot, driver, MMIO, DMA, runtime validation, or
scientific behavior.

```text
ORIGINAL_RECEIPT_TOOL_SHA256=1896EF7E8F28713BFE8A1A59B2E510F3371E4E665AB6F40104D123449F2372E4
CORRECTED_RECEIPT_TOOL_SHA256=9FAFEE34C81DE05115E301A485681848F55F496D15A0F1B8A75B51CD0C2BFB9E
POWERSHELL_PARSE_ERRORS_AFTER_FIX=0
BAR0_MATCH_COUNT=2
BAR0_UNIQUE_VALUE_COUNT=1
BAR0_UNIQUE_VALUE=131072
BAR1_MATCH_COUNT=2
BAR1_UNIQUE_VALUE_COUNT=1
BAR1_UNIQUE_VALUE=65536
CONFLICTING_REPEATED_VALUES_ACCEPTED=NO
FIRST_FAILED_CALL_CREATED_RECEIPT=NO
RECEIPT_CREATION_LIVE_ACTIONS=0
```
