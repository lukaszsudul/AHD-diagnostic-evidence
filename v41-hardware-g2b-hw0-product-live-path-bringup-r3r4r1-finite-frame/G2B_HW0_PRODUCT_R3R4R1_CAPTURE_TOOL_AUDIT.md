# R3R4R1 capture-tool architecture audit

Ordered architecture hard gate: `FAIL (NOT RUN AFTER PRIOR HARD GATE)`.

The pre-suite delta audit verified that the capture and frame runtime normalize
exactly to R3R4 identity-only changes; the ABI files are byte-exact; parent-only
MMIO, no raw record IPC, direct private persistence, asynchronous first-record
persistence, primary target 2500, bounded drain, parent-owned quiescence,
cooperative quiet-window exit, failure persistence, and timeouts are unchanged.

The full architecture audit was not advanced because the mandatory self-test
suite stopped at `PARENT_QUIESCENCE_HANDSHAKE_PASS`. This conservative FAIL is a gate result,
not an adverse runtime-architecture finding.
