# R3R4 capture-tool architecture audit

Integrated hard-gate result: `FAIL`.

The source implements parent-only MMIO, compact control IPC, direct private-file persistence, a separate first-record persister thread, a 2500-record primary boundary, bounded 512-record drain, parent quiescence, and cooperative one-second quiet exit. The first synthetic persistence case completed. However, the mandatory suite stopped at `1/11` because its partial-read case used an invalid chunk-count assertion. Under the frozen rule, any self-test failure fails the architecture hard gate for this run.

Blocker: `R3R4_CAPTURE_TOOL_HARD_GATE_FAILED`. DUT connections: `0`. Hardware access: `NO`.
