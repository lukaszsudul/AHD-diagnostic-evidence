# Comparison contract v2 addendum: report-header provenance

This addendum narrows the v1 contract after inspecting the first exact
candidate/reference report pairs. The v1 file and its SHA-256
`27442E8DB36DCD2CFC0243DD3519C25D1A8ABDB2BA929E776C6FC983A5D43F37`
remain preserved. It does not relax executable XDC, clock, object, path,
warning, target or constraint comparisons.

The five paired reports for exceptions summary, ignored exceptions, clocks,
clock networks and CDC have line-for-line identical bodies when precisely
two generated header lines are excluded: the line beginning `| Date` and the
line beginning `| Command`. Each complete raw report and raw SHA-256 remains
retained; the exclusion ledger must list the exact removed strings and their
file hashes. `Command` differs only in the output file path after identical
command options. No other line is excluded, re-ordered, sorted or modified.

The initial timing-summary reports have an additional methodology-cache
section difference: the final DCP carries previously computed methodology
warnings, whereas the original routed DCP initially says no methodology
report has run. That block is **not** excluded. Instead, the same audited
`report_methodology -file` call is made on both as-open designs, followed by
the same detailed timing-summary call. The full warning content must then be
retained and compared. An unexplained remaining difference is a stop.

The raw XDC export comments similarly name different output paths and source
XDC files; these are preserved in complete raw exports. The canonical XDC
comparison is not merely a header comparison: the ordered 97 executable
constraint commands and every value/target must match after the narrowly
specified `_xlnx_shared_iN` selector expansion in v1.

`report_bus_skew` is not waived. The historical global report was known to be
prohibitively expensive for overlapping groups, so the original exact-group
11/11 result may be inherited only if the two fresh as-open DCP views have
identical ordered effective selector/constraint commands, clocks, netlist,
placement and route signatures, and the historical exact-group receipt is
hash-linked to the original routed DCP. Otherwise the bus-skew gate remains
unresolved; a bare count of 11 is insufficient.
