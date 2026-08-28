# R2 Publication and DUT Release Receipt

## Initial evidence publication

- Repository: `lukaszsudul/AHD-diagnostic-evidence`
- Branch: `main`
- Directory: `v41-research-r2-r1i-causal-hardware-owner-mediated-continuation-halted-20260828`
- Initial evidence commit: `2ddb3a6d7bebcc96235b0263b337916a7d70627d`
- Remote advertised commit: `2ddb3a6d7bebcc96235b0263b337916a7d70627d`
- Remote archive file count: `35`
- Remote manifest read-back: `PASS`

The initial remote read-back completed before DUT authority was released.

## DUT exclusivity release

Agent declaration in chat:

> R2 hardware operations are complete. DUT exclusivity is released.

- First system-clock capture after declaration: `2026-08-28T18:49:33.6866517Z`
- `DUT_EXCLUSIVITY_RELEASED=YES`
- DUT operations after release: `0`

The enclosing final evidence commit contains this release record. Its commit SHA and final remote read-back are reported in the task handoff because a Git commit cannot contain its own SHA without creating another commit.
