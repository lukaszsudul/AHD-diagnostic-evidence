# Semantic parser static audit

STATUS=PASS

- The acceptance value is the deduplicated length of Vivado violation objects returned from a named `report_drc` result.
- Exactly one `REQP-1839` check object is required.
- Every violation is passed individually to `report_property -all`.
- Raw report text is counted only after the semantic inventory and is not present in any acceptance expression.
- No unstructured textual fallback is implemented.
- The read-only preflight contains no `write_bitstream`, `write_checkpoint`, implementation command, or property assignment.
- The write continuation contains one lexical `write_bitstream` command and no synthesis, optimization, placement, routing, checkpoint-writing, or source-edit command.

RAW_TEXT_OCCURRENCES_USED_AS_GATE=NO
READ_ONLY_PREFLIGHT_WRITE_BITSTREAM_COMMAND_COUNT=0
WRITE_CONTINUATION_WRITE_BITSTREAM_COMMAND_COUNT=1
CURRENT_DESIGN_TO_RTL_TOP_EQUALITY_COMPARISON_COUNT=0
