# Semantic REQP-1839 counter

The acceptance gate uses Vivado DRC objects, not report text. Vivado 2025.2 help establishes that `report_drc` creates violation objects and that `get_drc_violations -name` returns the violations associated with a named report result. R3 obtains exactly one `REQP-1839` check object, runs a named report for that check, selects `REQP-1839*` violation objects in that result, deduplicates exact object names, and requires four objects.

Each violation is passed individually to `report_property -all`. Associated cells, pins, and nets are inventoried when exposed by Vivado. Raw `REQP-1839` string occurrences are recorded but never participate in acceptance.

`RAW_TEXT_OCCURRENCES_USED_AS_GATE=NO`
