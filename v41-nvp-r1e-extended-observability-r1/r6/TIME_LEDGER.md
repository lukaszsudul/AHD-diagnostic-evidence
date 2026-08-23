# R6 selected-new-JTAG time ledger

| UTC | Event |
|---|---|
| 2026-08-23T21:32:53.6089526Z | Fresh R6 root created; owner prompt saved and hashed before any live action. |
| 2026-08-23T21:48:15.7634417Z | R5/artifact/frozen-tool/selector/phase-tooling offline gates passed; live counters still zero. |
| 2026-08-23T21:49:20.7205525Z | Three read-only SSH sessions passed the fresh host and next-boot-kernel baseline. |
| 2026-08-23T21:53:38Z | Two independent selected-JTAG sessions passed 10/10 refresh samples with exact target/part/IDCODE and stable readable `DONE=0`; no programming or frequency change. |
| 2026-08-23T21:57:32Z | Privileged read-only pre-bootstrap discovery passed with kernel/boot continuity, endpoint/driver absence accepted, zero owners/DMA, healthy kernel/AER, and fresh loader directories. |
| 2026-08-23T21:59:28.0145066Z | Hard-stop before programming on frozen-observer `DONE=1` precondition versus qualified stable `DONE=0`; no program invocation attempted or consumed. |
