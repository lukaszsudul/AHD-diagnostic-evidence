# G2B-LUT0 Build Profile Proposal

## Recommendation

Adopt two explicit profiles from one source graph:

- `PRODUCT`
- `RESEARCH_DIAGNOSTIC`

Use an auditable top-level build-profile parameter/generic, propagated as narrow per-module booleans such as `ENABLE_RTRACK_DIAGNOSTICS`, and named `generate` blocks around complete research islands. Set the profile from Tcl and record it in build provenance. Use source-set selection only for optional ILA/VIO XCI files; do not use global preprocessor defines as the primary boundary.

## Profile content

### PRODUCT

Always present:

- exact R1i physical-SCL synchronizers/filter/qualification;
- qualified ACK sampling, first-NACK abort, legal STOP/BUS_FREE, retry/backoff, timeout, readiness/recovery and bank safety;
- initialization table, power/reset/start/final-settle behavior;
- full current R1i `0x3600–0x367F` telemetry for the first product-profile iteration;
- firmware/build identity, capabilities, `INIT_DONE`, `INIT_ERROR`, aggregate qualified NACK, retry exhausted/unrecovered, SCL timeout, bank-safety state and video presence;
- capture/PIO legacy product behavior;
- XDMA Gen2 x1 and complete G2B one-channel four-slot transport;
- every frozen G2B MMIO counter, coherent snapshot, error, status, identity and reset-epoch semantic.

Not elaborated in PRODUCT after approval:

- autonomous post-init tri-phase probe and three 512×16 index stores;
- six-RAMB18 failed-transaction history;
- deep AXI lifecycle timestamps/transitions;
- deep failed-record assembly and D1 eight-record history whose fanout is research-only;
- research-only R1e/R1f/R1h readout/decode and wide duplicate snapshots.

The R1f WADDR/REGADDR/DATA/RADDR opportunity/NACK counters and transaction serial remain initially because the frozen R1i page consumes them. The R1h scalar read path is retained or reduced to an equivalent scalar responder; it is not deleted wholesale.

When the probe is absent, `probe_scl_release` and `probe_sda_release` must be constant high before the existing open-drain AND, preserving the initializer's exact drive path while eliminating post-init research traffic.

### RESEARCH_DIAGNOSTIC

`PRODUCT` plus the exact current R-track instrumentation, depths, widths, sample points, address behavior and host-tool compatibility. It must reproduce:

- lifecycle timestamps and transitions;
- phase-complete post-init campaign;
- 512 index entries/phase;
- 64×192 failed records;
- full R1f/R1h scalar/history MMIO service;
- record construction and diagnostic correlation;
- optional ILA/VIO only when explicitly selected.

## MMIO boundary

The frozen G2B page is identical in both profiles. Reserved G2B addresses stay deterministic zero, and no defined counter can be stubbed.

The existing project SSOT also protects legacy and R1i address behavior. Therefore a profile implementation cannot silently remove pages, change response latency/backpressure, alias addresses, or invent values. Before implementation, OWNER_ARCHITECT must approve one compatibility strategy for R1e/R1f/R1h research-only addresses and a separate meta update must authorize diagnostic reduction. The recommended first implementation keeps the R1i page exact and supplies deterministic, profile-identifiable compatibility responses for research-only deep-history pages under that approval.

## Why generics/generate

- Both profiles compile the same functional source graph and share review history.
- The elaborated presence/absence of whole research islands is mechanically reportable.
- Functional state-machine code need not contain broad preprocessor branches.
- Restoration does not depend on Git archaeology.
- Tcl provenance can record the exact profile, generic values, source list and XCI selection.

Required build receipts should include profile name, parameter values, elaborated research-instance presence/absence, address-map responder presence, debug-IP presence/absence, input source hashes and post-opt/routed hierarchy.

## Minimum production observability

The following must remain diagnosable:

| Area | Minimum retained signal |
|---|---|
| identity | firmware/source identity, ABI version, profile/build flags and capabilities |
| initialization | `INIT_DONE`, `INIT_ERROR`, terminal/last error |
| I2C health | aggregate qualified NACK, unrecovered/retry-exhausted, SCL timeout, bank-safety error |
| video | video presence/frame-edge indication and input mapping/state |
| transport | enable/active/ring empty/full/source ready/locked, fatal and last error |
| data integrity | attempted, committed, streamed, dropped, overflow, abandoned, discontinuity and accepted beats |
| reset | reset epoch/events and snapshot generation/validity |

The complete frozen G2B observability portion is approximately `600 ±100 LUT` and about `1,350 FF`. Adding shared identity, basic NVP/video health and compatibility decode yields a device-wide minimum-production-observability planning envelope of approximately `850 ±250 LUT`, `1,500 ±300 FF`, and no dedicated BRAM. These are overlapping estimates, not additive to the measured hierarchy totals.

