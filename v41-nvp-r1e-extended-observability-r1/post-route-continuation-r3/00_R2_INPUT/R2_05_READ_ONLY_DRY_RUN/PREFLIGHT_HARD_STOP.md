# R2 read-only preflight hard stop

CLASSIFICATION=BLOCKED_R2_READ_ONLY_PREFLIGHT_REQP_1839_TEXT_OCCURRENCE_PARSER

The sole authorized read-only preflight opened the exact routed DCP and passed:

- namespace-correct design identity;
- part `xc7a35tcsg325-2`;
- fully routed state, 26,488/26,488 routable nets and zero route errors;
- source-derived top-level port signature;
- probe and lifecycle structural signature;
- exact two-object NVP IOBUF query;
- deterministic property reports for both objects;
- every remaining report-only command.

The final aggregate gate then exited 1 because it counted five textual
`REQP-1839` occurrences. The DRC report's semantic summary count is four: one
summary label plus four detailed violations creates five string occurrences.
The prior frozen report has the same structure and semantic count.

Accounting at the hard stop:

```text
READ_ONLY_DCP_PREFLIGHT_SESSIONS=1
READ_ONLY_PREFLIGHT_PROCESS_EXIT_CODE=1
WRITE_CAPABLE_CONTINUATION_SESSIONS=0
WRITE_BITSTREAM_ATTEMPTS=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
```

R2 forbids a second preflight. Therefore no helper correction or rerun was
performed, the write-capable session was not entered, and no hardware operation
occurred.

