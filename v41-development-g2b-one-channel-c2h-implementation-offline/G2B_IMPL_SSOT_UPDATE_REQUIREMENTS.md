# AHD v41 G2B-IMPL SSOT Update Requirements

## Policy boundary

The G2B-IMPL task did not modify `project-current-state`. The start revision
was 2, and that directory remained read-only. Only an Owner-accepted META
process may update project state.

`SSOT_UPDATE_REQUIRED = YES`

## Current supportable state

The engineering gate is blocked at post-opt resource headroom. Therefore this
evidence does **not** support promotion of the implementation to
`OFFLINE_QUALIFIED`.

- G2B source implementation: `IMPLEMENTED_UNCOMMITTED_BLOCKED_RESOURCE`.
- G2B offline qualification: `BLOCKED`.
- G2B hardware: `NOT_PROVEN`.
- One-channel product hardware behavior: `NOT_PROVEN`.
- Runtime Gen2 x1 negotiation: `NOT_PROVEN`.
- Required application payload >= 288 MB/s: `NOT_PROVEN`.
- Two-channel C2H: `NOT_IMPLEMENTED`.
- Linux/V4L2 production integration: `NOT_IMPLEMENTED`.

After architect-reviewed resource closure, a new complete clean build, all
offline gates, source commit, evidence publication, and Owner acceptance, the
maximum supported promotion would be G2B implementation
`OFFLINE_QUALIFIED` with G2B hardware still `NOT_PROVEN`.

## Evidence a later META update must bind

The update should bind the accepted G2A base, a passing G2B integration
commit/tree/parent, frozen PRE and META evidence commits, Vivado and XDMA XCI
identities, focused simulation and parser results, CDC and R1i protection
audits, complete clean build/timing/DRC/resource results, bitstream identity,
the evidence repository commit, and remote read-back.

## Prohibited promotion

Do not label this work `OFFLINE_QUALIFIED`, `HARDWARE_PROVEN`, qualified
hardware firmware, measured throughput, real-video DMA evidence, two-channel
complete, or V4L2 complete. Do not alter prior evidence directories while
applying any later META update.
