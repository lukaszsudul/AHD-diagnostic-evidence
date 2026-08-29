# AHD v41 G2B-LUT0 Resource Attribution and Diagnostic De-instrumentation Plan

## Gate result

Engineering gate: **PASS** as an analysis and implementation plan.

The blocked G2B snapshot exceeds the XC7A35T capacity because the accepted image already carries a large research stack and the G2B addition consumes a stage-matched net 2,843 LUT. A reversible PRODUCT profile can realistically reach the 90% continuation target without changing R1i functional behavior, XDMA Gen2, the four-slot transport, or frozen G2B ABI/MMIO. The preferred 80–85% band is reached by the 84.192% point estimate but remains unmeasured.

Implementation is not authorized by this gate. Current SSOT requires OWNER_ARCHITECT-accepted R-track closure and a separate meta update before diagnostic reduction.

## Authority and preservation

- Evidence repository start: `main` at `3ea9acdcbe955c688c2861e749c114414efa241b`.
- `PROJECT_STATE_REV_AT_START = 2`; required value matched.
- Accepted G2A base: `integration/v41-r1i-gen2-g2a` at `224d194e5f82c85bcb29297561c5d5e76d28063b`.
- Blocked G2B evidence: `v41-development-g2b-one-channel-c2h-implementation-offline` at evidence commit `3ea9acdc...`.
- G2B source snapshot SHA-256: `8D9BECA7C4990B526D0D1C102739417D72A84F6CA290198BB8AA8CE5AFB11471`.
- No G2B integration commit exists.
- Source, integration branch and SSOT were not modified; no DUT/hardware access occurred and no bitstream was produced.

## Report-stage normalization

Both designs have Vivado 2025.2 reports for the same top (`ahd_capture_top_xdma`) and part (`xc7a35tcsg325-2`). The current G2B package stopped at post-opt, while accepted G2A has post-opt and routed reports.

| Comparison | G2A LUT/FF/BRAM | G2B LUT/FF/BRAM | Delta | Use |
|---|---|---|---|---|
| Like-for-like post-opt | 18,569 / 20,137 / 26 | 21,412 / 23,643 / 30 | +2,843 LUT / +3,506 FF / +4 BRAM | attribution authority |
| Requested accepted-reference comparison | 18,178 routed / 20,137 / 26 | 21,412 post-opt / 23,643 / 30 | +3,234 LUT / +3,506 FF / +4 BRAM | blocker headline only |

The 391-LUT difference is G2A's post-opt-to-routed reduction. It is not attributable G2B RTL and cannot be projected as guaranteed G2B recovery.

## 1. What consumes accepted G2A's 18,178 LUT

Accepted routed hierarchy:

| Hierarchy | LUT | FF | BRAM |
|---|---:|---:|---:|
| XDMA | 9,617 | 11,066 | 19 RAMB36 + 1 RAMB18 |
| NVP autoinit (mixed functional R1i + observability) | 3,211 | 2,247 | 0 |
| Post-init tri-phase research probe | 2,077 | 2,934 | 3 RAMB18 |
| AXI-Lite host bridge (mixed product/research decode) | 1,760 | 110 | 0 |
| Capture subsystem | 1,156 | 2,561 | 2 RAMB36 |
| Failed-transaction logger | 103 | 81 | 6 RAMB18 flattened to top |
| Lifecycle observer | 88 | 311 | 0 |
| R1h MMIO service | 75 | 71 | 0 |
| Control/status hierarchy | 57 | 65 | 0 |
| Top-local | 26 | 671 | 0 |
| Cross-hierarchy reconciliation | 8 | 20 | 0 |
| **Total** | **18,178** | **20,137** | **26 tiles** |

Thus the accepted base is not a product-minimum image: the tri-phase probe alone is the third-largest non-XDMA hierarchy, and research decode/counters also sit inside mixed hierarchies.

## 2. What consumes the additional G2B LUT

Exact stage-matched decomposition:

| Incremental contributor | LUT | FF | BRAM | Status |
|---|---:|---:|---:|---|
| G2B one-channel core hierarchy | +1,990 | +2,908 | +4 | measured; direct DCP scope is 1,994 LUT/4 RAMB36 |
| XDMA C2H activation | +619 | +598 | 0 tile-equivalent | measured |
| MMIO router/top/integration/repartition | +234 | 0 | 0 | exact reconciliation, not a standalone module measurement |
| **Comparable delta** | **+2,843** | **+3,506** | **+4** | exact |

The G2B core's largest estimated cones are source formatting/ring control, coherent snapshot/Gray CDC, descriptor ownership, and AXIS scheduling. No research-only cone was found in either G2B RTL file.

## 3. Attribution by requested class

Values on different rows may overlap unless marked additive. Exact file-level separation is impossible after flattening/LUT combining; estimates and methodology are explicit.

| Requested class | LUT attribution | FF/BRAM attribution | Interpretation |
|---|---:|---:|---|
| Mandatory PRODUCT profile | ~17,512 | estimated | current 21,412 minus 3,900 point recovery; includes R1i telemetry and full G2B contract |
| Qualified R1i functional logic | exact UNKNOWN | part of 3,135-LUT/2,247-FF NVP hierarchy | R1h→R1i +1,062 routed LUT/+702 FF mixes fix and telemetry |
| R-track diagnostics | ~3,900 planning point; 3,500–4,300 range | named lower bound 3,430 FF/4.5 BRAM | profile-removal estimate; measured A/B required |
| Active ILA/VIO/debug cores | 0 | 0/0 | no hierarchy and no `.ltx`; helper source presence is not cost |
| Legacy D1/R1e/R1f/R1h diagnostics | exact UNKNOWN inside mixed hierarchies | D1 history at least 512 source FF | included in research estimate; signal-by-signal fanout required |
| Diagnostic MMIO | 103 measured read-service LUT plus flattened UNKNOWN | 71 FF plus flattened | bridge grows substantially across diagnostic waves; no fabricated split |
| Counters/probes | 2,092 probe + 106 logger + 89 lifecycle + mixed counters | 2,934 + 81 + 311 FF; 9 RAMB18 | R1i causal counters retained in recommended PRODUCT |
| G2B functional data plane | ~855 additive within 1,990 | estimated | parser/formatter 300, header 140, scheduler 230, sequence 160, glue 25 |
| G2B MMIO/identity | ~140 additive within 1,990 | ~52 FF | frozen product logic |
| G2B CDC/snapshot | ~290 additive within 1,990 | ~1,039 FF | coherent snapshot 260 plus other CDC 30 |
| Ring control/ownership/descriptors | ~320 additive within 1,990 | ~450 FF | mandatory four-slot ownership |
| Memories/address glue | ~35 additive within 1,990 | 4 RAMB36 | one efficient BRAM per slot; no payload LUTRAM spill |
| G2B statistics | ~115 additive within 1,990 | ~320 FF | frozen counter semantics |
| G2B reset epoch/error | ~235 additive within 1,990 | ~225 FF | reset 150 + errors 85 |

The additive G2B conceptual rows sum to 1,990 LUT when identity, CDC, data plane, ring, memory, statistics and reset/error are included. The full new functional implementation is the exact +2,843 post-opt net when mandatory XDMA and integration effects are included.

## 4. Removable and retained diagnostics

Move to `RESEARCH_DIAGNOSTIC` after approval:

- post-init tri-phase 10,000-opportunity campaign and 512-index stores;
- 64×192 failed-transaction history;
- deep lifecycle timestamps/transition counters;
- D1 eight-record history and duplicate wide snapshots after fanout proof;
- R1f failed-record construction and transaction accounting not consumed by R1i/product status;
- deep-history MMIO and flattened research-only decode/mux;
- optional ILA/VIO source selection (active cost already zero).

Keep in PRODUCT:

- all R1i functional behavior;
- full R1i causal telemetry/page for the first implementation;
- required R1f phase opportunity/NACK and serial values consumed by that page;
- identity/capabilities, init state/errors, basic qualified NACK/retry/timeout/bank health, video presence;
- all capture, transport, reset-epoch, DMA error/drop and frozen G2B statistics/snapshot behavior.

Keep restorable for R2/R3: every moved diagnostic remains in the same source tree and elaborates under `RESEARCH_DIAGNOSTIC`. R0 added no current RTL; R1 C1/C2 are separate functional research branches; R2 used inherited telemetry and off-chip observers, adding no product instrumentation.

## 5. R1i fix versus R1i observability

The split is source-evident and mandatory:

**R1i FIX—never remove:** two-FF input synchronizers, three-sample filters, physical-SCL-qualified HIGH dwell, qualified ACK decisions, first qualified NACK abort, legal STOP/BUS_FREE, timeout and readiness/recovery state, fixed retry/backoff, bank cache verification/invalidation and initialization sequencing.

**R1i OBSERVABILITY—research:** early/false-early comparisons, raw/recovered/unrecovered/exhausted distributions, success-on-retry tiers, maximum wait/timeouts as telemetry, and first-event identifiers. The current recommendation retains these in PRODUCT because the page is protected and R2/R3 may resume; their exact LUT cost remains unknown.

Therefore the fix is separable in principle and by fanout, but its isolated resource count is not proven. No proposed recovery relies on changing the fix.

## 6. BRAM packing

Four `xpm_memory_sdpram` instances implement 512×64 simple-dual-port storage, one RAMB36 each. Independent source-write/AXI-read clocks and a registered read are required. Only 488 beats are stored; 24 zero-padding beats are generated outside RAM. Meaningful stored-bit efficiency is 84.722% of raw RAMB36 capacity, and no payload spills into distributed RAM. Combining banks cannot reduce four BRAM and likely saves 0–20 LUT at best. Keep this inference style.

## 7. Counter/snapshot cost and contract

G2B uses source binary counters, registered Gray holds, five two-stage 32-bit synchronizer buses, AXI counters including a 64-bit accepted-beat count, shadow registers and a request/acknowledge snapshot with generation/epoch invalidation. Snapshot/Gray/shadow logic is estimated at 308 LUT/939 FF in direct-cell normalization. Complete mandatory G2B observability is approximately 600 ±100 LUT/~1,350 FF.

All defined counters and exact events are frozen. Constant-zero or incoherent substitutes are nonconforming. Only reserved addresses may retain their existing deterministic zero response.

## 8. Profile strategy and minimum observability

Use one top profile parameter/generic, explicit per-module enables and named generate blocks. Tcl selects and receipts the profile. Only optional debug XCI files use source-set selection. PRODUCT and RESEARCH_DIAGNOSTIC share one functional graph and one G2B implementation.

Minimum production observability retains identity/profile/capabilities, `INIT_DONE`, `INIT_ERROR`, qualified NACK/terminal error, retry exhaustion, SCL timeout, bank safety, video presence/input state, transport/ring/source status, attempted/committed/streamed/dropped/overflow/abandoned/discontinuity/beat counts, fatal/last error, reset epoch/events and snapshot generation/validity. The cross-design planning footprint is ~850 ±250 LUT/~1,500 ±300 FF/0 dedicated BRAM, overlapping the measured totals.

## 9. Candidate plans

| Plan | Recovery | Expected result | Risk/target |
|---|---:|---:|---|
| A—isolated blocks | 2,300–2,500; point 2,400 | 19,012 LUT / 91.404% | low; misses 90% |
| B—PRODUCT profile | 3,500–4,300; point 3,900 | 17,512 LUT / 84.192% | low-moderate; reaches 90%, preferred band at point |
| C—B + safe G2B structural | B + 120–220; point total 4,070 | 17,342 LUT / 83.375% | medium; use only if measured need remains |

Plan B is recommended. Its historical anchor is the same-tool routed R1e→R1h +4,125-LUT diagnostic wave, while its current named-module lower bound is 2,445 LUT. The range accounts for retained R1i inputs, flattened decode and nonlinear optimization. It is not a synthesized promise.

## 10. Optimization risk classification

- **A—ZERO_FUNCTIONAL_RISK after proof:** whole research modules, deep histories, inactive debug IP, and counter cones whose only fanout is research readout. Open-drain tie-off and exhaustive address behavior are proof obligations.
- **B—LOW_RISK_IMPLEMENTATION_OPTIMIZATION:** lightweight equivalent read responder, serialized Gray decode, descriptor-state reduction, equivalent fatal/reset logic, shared comparisons.
- **C—ARCHITECTURAL_CHANGE:** slot reduction, record/ABI changes, dropped/changed counters, weaker coherency/reset semantics or XDMA changes. Not required and prohibited for LUT1.

## 11. Headroom conclusion

Recovery required from 21,412 is 612 LUT for 100%, 1,652 for 95%, 2,692 for 90%, 3,732 for 85%, and 4,772 for 80%. Plan B's 3,900 point recovery reaches 84.192%. The entire estimate range reaches 90%; only the point and upper recovery portion reach 85%, so the preferred band is not proven until paired builds.

## 12. Acceptance review

| Criterion | Result |
|---|---|
| SSOT revision 2 at start/end | PASS |
| G2A/G2B reports compared at compatible stage | PASS |
| hierarchy/file attribution actionable | PASS; estimates labeled |
| R-track inventory and history | PASS |
| R1i fix separated from observability | PASS |
| G2B/BRAM/counter/snapshot decomposition | PASS |
| two-profile strategy and minimum observability | PASS |
| targets and three plans | PASS |
| implementation-ready recommendation | PASS, pending governance authority |
| source/DUT/SSOT preservation | PASS |

## Conclusion

G2B does not fit because a mandatory +2,843-LUT post-opt implementation was added to a base containing several thousand LUTs of research observability. The G2B transport itself contains zero safely removable research LUT. Plan B moves reversible R1f/R1h/deep legacy instrumentation to a diagnostic profile while keeping the R1i functional fix, current R1i telemetry, minimum product status and the entire frozen G2B transport/MMIO. No frozen ABI/MMIO, R1i behavior, XDMA configuration or G2B architecture change is required.

First implementation blocker: `OWNER_ARCHITECT_ACCEPTED_R_TRACK_CLOSURE_AND_SEPARATE_META_UPDATE` plus an approved legacy research-page compatibility response.

