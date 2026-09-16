# CONT1R3R2 comparison contract v1 (frozen before patch validation)

## Authority and objects

- The only closure candidate is the existing final provisional DCP, SHA-256
  `C09145B1397E2A8DC972E435E755917C9104A5FDA2E5EF297FE4628EF9672CC2`,
  17,469,233 bytes. The earlier routed DCP (SHA-256
  `804CB25D89DF3729A65D2771B892738AC2D580E2921AF48CAE1C5C28D76BC208`)
  is a provenance reference, never a candidate substitute.
- Vivado 2025.2, SW build 6299465; part `xc7a35tcsg325-2`, top
  `ahd_capture_top_xdma`. All fresh collectors must open a byte-verified copy
  of each DCP in a new batch session and capture the as-open constraint view
  before any `reset_timing`, `read_xdc`, `source` of constraints, or other
  in-memory change. Use `write_xdc -exclude_physical -force` with identical
  options and design scope. Compare clock, netlist, placement and route
  signatures as separate identities.
- The historical restored view A is not the as-stored view of the final DCP.
  Historical as-open original routed view B and historical as-open final
  provisional view B are the like-for-like pair. The A/B comparison is a
  separate diagnostic of exporter representation and restoration provenance.

## Comparisons and exclusions

1. Preserve complete raw export bytes and SHA-256 on both sides. A raw hash
   mismatch remains visible, even when a comparable view matches.
2. For the A/B diagnostic only, parse each line in order. Expand only
   Vivado-generated `_xlnx_shared_iN` assignments whose right-hand side is
   a read-only object query or a literal object list. Reject missing or
   duplicate aliases, recursive aliases, unused aliases, and any other
   statement in an alias definition. Do not sort, deduplicate, discard or
   rewrite executable constraint commands. Compare the exact ordered
   expanded command stream. This proves only the audited export delta, not
   by itself effective DCP constraint equality.
3. For the acceptance pair, compare identical collector outputs from
   independently opened, unmodified DCPs. The raw exports, structured
   command stream and six report families must be separately accounted for.
   Reports are `report_timing_summary`, `report_exceptions`, `report_clocks`,
   `report_clock_networks`, `report_cdc`, and `report_bus_skew`; supported
   command options are frozen in an invocation manifest after querying the
   installed tool. Targeted differences are inspected by exact object/value.
4. No metadata exclusion is pre-approved in v1. If a generated timestamp or
   report-output filename is encountered, document the exact lines and prove
   non-semantic status before changing this contract. Never remove warnings,
   values, names, targets, scope or clock properties. No whole-XDC sorting.
5. Preserve the inherited 11 active bus-skew and 17 promoted checks, timing
   coverage, CDC/DRC/methodology and resource gates. Identical summary
   values cannot replace command/object identity or explain missing coverage.

## Stop conditions

Any meaningful command difference, unlinked historical state, as-open
constraint difference, unexplained report delta, failed required regression,
tool mismatch, or missing inherited-gate linkage prevents sign-off. A
reconstructed restored analysis view may explain A, but it cannot be used as
the unmodified closure candidate. No DCP write, bitstream, hardware or source
change is permitted under this contract.
