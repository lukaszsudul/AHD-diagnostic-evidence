# MODE1 deterministic recovery audit

The machine-readable graph is
`G2B_NVP_MODE1_DETERMINISTIC_RECOVERY_GRAPH.json`.  It contains every required
state plus the explicit publication terminal `RECOVERED_PRODUCT_BASELINE`.

The only permitted recovery outcomes are:

- `RECOVERED_PRODUCT_BASELINE` after exact reverse restore and complete protected
  baseline verification; or
- `FATAL_RECOVERY_FAILURE` for any unresolved committed register, lost recovery
  context, unavailable reconstruction action, NACK/timeout/mismatch during
  recovery, or protected-check failure.

The model covers 173 included operations and seven failure types per operation:
`173 x 7 = 1211` scenarios.  Coverage is `1211/1211`.  Results are 6
`RECOVERED_PRODUCT_BASELINE` and 1205 `FATAL_RECOVERY_FAILURE`.  The six recovered
cases occur only before any unresolved functional target may have committed.
This is coverage of fail-closed classification, not evidence that MODE1 is safe to
execute.

Reset-between-operations and MMIO-reset scenarios always end fatal because a
callable product reconstruction action and persistent recovery context are not
proven.  No path silently returns to `IDLE_PRODUCT_BASELINE`.

