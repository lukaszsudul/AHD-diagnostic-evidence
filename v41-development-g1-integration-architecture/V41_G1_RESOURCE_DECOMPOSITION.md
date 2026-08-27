# AHD v41 G1 Resource Decomposition

## Executive finding

The qualified R1i routed utilization is a mixed integration total, not a measurement of product logic alone. It contains the inherited XDMA endpoint, capture/record and control plane, the functional R1i NVP correction, and substantial R1h/R1i causal instrumentation. No qualified-R1i hierarchical utilization report was found, so the exact number of removable R1i LUTs is `UNKNOWN` and is not fabricated here.

All figures below are classified as `MEASURED`, `DERIVED`, `ESTIMATED`, or `UNKNOWN`. A standalone or earlier-revision measurement is never added to or subtracted from R1i as if implementation optimization were linear.

## Qualified R1i global resources

Target: `xc7a35tcsg325-2`.

| Stage | LUT | FF | RAMB36 | RAMB18 | BRAM tile equivalents | Classification |
|---|---:|---:|---:|---:|---:|---|
| Post-synthesis | 20,319 / 20,800 (97.69%) | 21,097 / 41,600 (50.71%) | 21 | 12 | 27 / 50 (54%) | MEASURED |
| Post-opt | 18,577 / 20,800 (89.31%) | 20,083 / 41,600 (48.28%) | 21 | 10 | 26 / 50 (52%) | MEASURED |
| Final routed | 18,181 / 20,800 (87.41%) | 20,083 / 41,600 (48.28%) | 21 | 10 | 26 / 50 (52%) | MEASURED |
| Final routed available | 2,619 LUT (12.59%) | 21,517 FF (51.72%) | — | — | 24 tiles (48%) | DERIVED from measured totals |

Final timing is `WNS +0.617 ns`, `TNS 0`, `WHS +0.036 ns`, `THS 0`; routing completed with zero route errors. These are `MEASURED`. There is no qualified `.ltx` payload. The presence of debug-IP catalog/source material is not proof of a synthesized ILA/VIO instance, so no ILA/VIO removal credit is claimed.

Primary source: `v41-nvp-r1i-r2-qualified-poc-hardware-evidence/implementation/AHD_v41_R1i_R2_FINAL_BUILD_REPORT.md`.

## R1h to R1i controlled delta

R1h is the immediately relevant same-flow inherited reference. Its measured global totals were:

| Stage | R1h LUT | R1h FF | R1h BRAM tiles | Exact R1i − R1h delta | Classification |
|---|---:|---:|---:|---|---|
| Post-synthesis | 19,255 | 20,395 | 27 | +1,064 LUT, +702 FF, 0 BRAM | MEASURED totals; DERIVED delta |
| Post-opt | 17,510 | 19,381 | 26 | +1,067 LUT, +702 FF, 0 BRAM | MEASURED totals; DERIVED delta |
| Routed | 17,119 | 19,381 | 26 | +1,062 LUT, +702 FF, 0 BRAM | MEASURED totals; DERIVED delta |

The qualified changeset proves that R1h→R1i changes are confined to the bring-up engine, autoinit wrapper, top, and control/status file. The approximately 1,062 routed-LUT increase cannot be labelled research-only: it combines the functional SCL/ACK/STOP/BUS_FREE/retry/bank correction with the new telemetry cone. The functional/diagnostic split is `UNKNOWN` until a controlled same-stage build removes only approved telemetry.

## Same-stage hierarchy reference

The public R1h post-synthesis hierarchy is the closest measured attribution. It is a `MEASURED_R1H_REFERENCE`, not a measured R1i hierarchy and not an additive R1i bill of materials.

| R1h hierarchy | LUT | FF | BRAM | G1 category | R1i attribution status |
|---|---:|---:|---:|---|---|
| XDMA hierarchy | 11,656 total: 10,509 logic, 1,133 distributed-RAM LUT, 14 SRL | 11,970 | 19 RAMB36 + 3 RAMB18 | PRODUCT FUNCTIONAL LOGIC | MEASURED_R1H_REFERENCE; R1i exact value UNKNOWN |
| Capture/record subsystem | 1,097 | 2,617 | 2 RAMB36 | PRODUCT FUNCTIONAL LOGIC | MEASURED_R1H_REFERENCE; R1i exact value UNKNOWN |
| AXI-Lite host bridge | 1,845 | 110 | 0 | MIXED: product transport plus diagnostic decode/fanout | MEASURED_R1H_REFERENCE; internal split UNKNOWN |
| NVP autoinit hierarchy | 2,166 | 1,545 | 0 | MIXED: product sequencing plus observability | MEASURED_R1H_REFERENCE; R1i exact value UNKNOWN |
| Post-init tri-phase probe | 2,093 | 2,934 | 3 RAMB18 | RESEARCH/DIAGNOSTIC LOGIC | MEASURED_R1H_REFERENCE |
| Failed-transaction logger | 151 | 81 | 6 RAMB18 | RESEARCH/DIAGNOSTIC LOGIC | MEASURED_R1H_REFERENCE |
| Diagnostic MMIO read service | 93 | 71 | 0 | RESEARCH/DIAGNOSTIC LOGIC | MEASURED_R1H_REFERENCE |
| AXI-clock lifecycle monitor | 89 | 311 | 0 | DIAGNOSTIC/OBSERVER; future product value undecided | MEASURED_R1H_REFERENCE; lifecycle UNKNOWN |
| Control-register hierarchy | 27 | 65 | 0 | MIXED | MEASURED_R1H_REFERENCE; split UNKNOWN |
| Top direct logic | 26 | 671 | 0 | MIXED/UNKNOWN after absorbed optimization | MEASURED_R1H_REFERENCE |

Downstream optimization, replicated fanout, hierarchy flattening, and routing can change these figures even when source text is unchanged. They must not be summed with the routed R1i total.

## Named research-island bounds

The following sums are useful evidence bounds, not a removable R1i estimate:

| Named R1h diagnostic islands | LUT | FF | RAMB18 | Classification |
|---|---:|---:|---:|---|
| Tri-phase probe + failed logger + diagnostic read service | 2,337 | 3,086 | 9 (4.5 tiles) | DERIVED sum of MEASURED_R1H_REFERENCE rows |
| Above plus lifecycle monitor | 2,426 | 3,397 | 9 (4.5 tiles) | DERIVED sum of MEASURED_R1H_REFERENCE rows |

These bounds omit diagnostic decode and telemetry embedded in mixed hierarchies. Conversely, deleting the source islands may not recover the sum after global optimization. Exact R1i removal benefit is `UNKNOWN` until controlled A/B implementation.

Historical R1g→R1h evidence independently proves that diagnostics can dominate this device: R1g diagnostic post-synthesis used 33,982 LUT/45,262 FF versus an R1e baseline of 15,101 LUT/17,036 FF. Three 512×16 index arrays mapped to 24,576 FDRE in R1g; the R1h BRAM redesign cut 14,727 LUT, 24,867 FF, and 220 LUTRAM while adding nine RAMB18. These are `MEASURED/DERIVED HISTORICAL` figures demonstrating material overhead, not a current R1i removal budget.

## Functional decomposition

| Product function | Current/future status | Cost classification | Architectural treatment |
|---|---|---|---|
| NVP/I2C core fix: physical-SCL filtering, qualified ACK, legal STOP/BUS_FREE, retry/backoff, timeout, bank safety | Qualified R1i | Exact isolated LUT/FF `UNKNOWN`; part of R1h→R1i measured global delta and mixed NVP hierarchy | Protected product behavior; never remove as diagnostics |
| Autoinit sequencer/table/reset/start/completion | Qualified R1i | R1h mixed hierarchy `MEASURED_R1H_REFERENCE`; R1i exact `UNKNOWN` | Protected product behavior |
| Video physical frontend/capture | Inherited/qualified integration | Included in capture/top references; exact isolated R1i `UNKNOWN` | Donor authority outside R1i logic |
| Record producer, PIO mailbox/BAR target | Inherited/qualified integration | Capture/record R1h reference 1,097 LUT/2,617 FF/2 RAMB36; exact R1i `UNKNOWN` | Preserve legacy PIO; DMA storage is separate |
| PCIe/XDMA endpoint | Inherited primary donor, current Gen1 x1 | Standalone donor and R1h hierarchy are measured but non-additive; R1i exact `UNKNOWN` | Retain one C2H/one mandatory H2C; Gen2 soft delta `UNKNOWN` |
| AXI-Lite/MMIO control plane | Inherited plus R1i pages | Mixed hierarchy; exact product/diagnostic split `UNKNOWN` | Preserve all existing addresses; add disjoint extension router |
| Future one-channel C2H adapter: ring, descriptor CDC, formatter, counters | Not implemented | `ESTIMATED/UNKNOWN` until G2B | Four 4 KiB slots imply about four RAMB36 structural minimum plus descriptors; LUT/FF unknown |
| Future two-channel extension: second ring, per-channel descriptors/counters, scheduler | Not implemented | `ESTIMATED/UNKNOWN` | Two rings imply about eight RAMB36 structural minimum total; scheduler LUT/FF unknown |

The four-RAMB36-per-channel figure is a structural storage estimate for 16 KiB at 32 Kib per RAMB36 before packing/tool effects; it is not an implementation measurement.

## Research/diagnostic decomposition

| Diagnostic function | Structure/evidence | Cost status | Lifecycle |
|---|---|---|---|
| Extended ACK and early-versus-qualified telemetry | Per-phase early, false-early, raw/qualified/recovered/unrecovered observations | Embedded R1i cost `UNKNOWN` | KEEP_UNTIL_R_TRACK_COMPLETE |
| Detailed retry/recovery counters and first identifiers | Retry tier, recovered NACK, exhaustion, max SCL wait, first-event serials | Embedded R1i cost `UNKNOWN` | KEEP_UNTIL_R_TRACK_COMPLETE |
| Post-init tri-phase research probe | 10,000 reached opportunities/phase, block/run/adjacency statistics, 512 retained indices/phase | R1h 2,093 LUT/2,934 FF/3 RAMB18 `MEASURED_R1H_REFERENCE` | Candidate REMOVE_AFTER_R_TRACK |
| Deep failed-transaction history | 64×192-bit records across six XPM block-RAM banks | R1h 151 LUT/81 FF/6 RAMB18 `MEASURED_R1H_REFERENCE` | Candidate REMOVE_AFTER_R_TRACK |
| Deep history/index MMIO service | Synchronous record/index reads | R1h 93 LUT/71 FF `MEASURED_R1H_REFERENCE` | Candidate REMOVE_AFTER_R_TRACK |
| AXI lifecycle observer | 48-bit time, event timestamps, transition counts and ordering | R1h 89 LUT/311 FF `MEASURED_R1H_REFERENCE` | KEEP until Gen2/R-track closure; final status UNKNOWN |
| ILA/VIO/debug helpers | Catalog/source presence only; no qualified `.ltx` payload | Active qualified cost `UNKNOWN` and no removal credit | UNKNOWN |

## Capacity conclusion

- Current routed arithmetic leaves 2,619 LUT and 24 BRAM tile equivalents, but neither amount is a safe insertion budget because routeability, post-opt margin, Gen2 delta, and C2H/two-channel cost are not measured.
- R1h evidence proves named causal instrumentation is material; it does not prove a specific R1i release saving.
- Gen2 x1, the minimal one-channel C2H implementation, and the two-channel extension each require same-stage measured deltas.
- G2A is allowed to measure the small Gen2 integration delta. G2B proceeds only under the headroom policy with all R-track instrumentation present.
- If G2B cannot fit, the gate stops for an explicit post-R-track productization decision; diagnostic deletion is not an implicit implementation tactic.

Resource decomposition status: `COMPLETE`, with every unavailable exact attribution explicitly classified `UNKNOWN`.
