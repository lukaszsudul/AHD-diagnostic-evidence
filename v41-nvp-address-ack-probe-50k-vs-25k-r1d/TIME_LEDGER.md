# R1d time ledger

Times are UTC. Exact tool timestamps remain in the raw XSim, Vivado, and lock
receipts.

| Event | UTC |
|---|---|
| First shared XSim lock acquisition | 2026-08-22T16:10:55.3256880Z |
| First shared XSim lock release | 2026-08-22T17:10:31.8760424Z |
| Final simulation/regression lock acquisition | 2026-08-22T18:22:01.8360620Z |
| Final simulation/regression lock release | 2026-08-22T18:23:52.9395191Z |
| Build-lock acquisition | 2026-08-22T18:34:28.8780856Z |
| Vivado build session start | 2026-08-22T18:35:11Z |
| Vivado build session end | 2026-08-22T19:08:52Z |
| Build-lock release | 2026-08-22T19:52:24.4271569Z |

The release command was submitted immediately after the build result returned,
but its approval/tool session completed about 43 minutes later. During that
delay the lock remained R1d-owned, no heavy process was active, and no hardware
or evidence-publication work was started.

