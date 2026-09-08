# Source-domain isolation

`transport_hard_hold_axi` was removed from the source trace cone. Event valid, trigger, next-frame-line1, and the 512-bit payload are registered exclusively in `source_clk` and aligned by one diagnostic pipeline stage.

Source-local trace sequence count: 773 cells. Event sequence count: 377 cells. Raw userclk1 startpoints: 0. Forbidden AXI startpoints: 0. Raw source metadata bypasses: 0.

Functional parser/transport behavior remained byte-identical during DIAG1-R1 instrumentation; noninterference simulation passed.
