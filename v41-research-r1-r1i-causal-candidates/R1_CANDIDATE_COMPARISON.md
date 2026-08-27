# AHD v41 R1 Candidate Comparison

## C3 versus C1 versus C2

| Metric | C3 qualified R1i | C1 R1i-a | C2 R1i-b |
|---|---:|---:|---:|
| Commit | `20c3323d...` | `8b8ec0fa...` | `e4d10bb8...` |
| WNS (ns) | +0.617 | +0.617 | +0.617 |
| TNS (ns) | 0.000 | 0.000 | 0.000 |
| WHS (ns) | +0.036 | +0.036 | +0.036 |
| THS (ns) | 0.000 | 0.000 | 0.000 |
| LUT | 18,181 | 18,215 | 18,214 |
| FF | 20,083 | 20,084 | 20,084 |
| RAMB18E1 | 10 | 10 | 10 |
| RAMB36E1 | 21 | 21 | 21 |
| Block RAM tiles | 26 | 26 | 26 |
| Fully routed nets | 35,810 | 35,852 | 35,854 |
| Route errors / partial / unrouted | 0 / 0 / 0 | 0 / 0 / 0 | 0 / 0 / 0 |
| DRC Error / Critical Warning | 0 / 0 | 0 / 0 | 0 / 0 |
| Bitstream SHA-256 | `F6A6905D...D3C6` | `847B2ECE...34534D` | `2092322C...5E5C1D` |

## Build provenance comparison

| Provenance item | C3 qualified R1i | C1 R1i-a | C2 R1i-b |
|---|---|---|---|
| Vivado | 2025.2 build 6299465 | 2025.2 build 6299465 | 2025.2 build 6299465 |
| Part / top | `xc7a35tcsg325-2` / `ahd_capture_top_xdma` | identical | identical |
| Source commit | `20c3323d...` | `8b8ec0fa...` | `e4d10bb8...` |
| Source tree | `70d801fd...` | `a0fcbdbf...` | `2658cf45...` |
| Canonical script SHA-256 | `7A0CF8BA...A58F` | same canonical flow through audited adapter `6BCE35C3...4B49` | same adapter |
| Design-command structure SHA-256 | `30F951EA...3730` | identical | identical |
| Synthesis | `flatten_hierarchy=rebuilt` | identical | identical |
| Strategy/directives/seed | qualified defaults; no candidate override | identical | identical |
| Operation counts | one each through bitstream | one each through bitstream | one each through bitstream |
| Build flags | `0x00000002` | `0x00000002` | `0x00000002` |
| Incremental checkpoint reuse | none | none | none |
| XDC/XCI/build configuration | qualified | byte-identical | byte-identical |

## Source delta

C3 is the frozen physical-qualified/late-sample cell. C1 changes only ACK decision data selection while retaining the C3 physical waveform and qualified dwell. C2 changes ordinary protocol-HIGH divider gating and adds a filtered-SCL endpoint guard while retaining live terminal ACK sampling and the physical STOP/BUS_FREE states.

C1's synthesizable patch is 126 insertions/61 deletions in the allowlisted RTL; C2's is 21 insertions/3 deletions in that same file. Every other synthesizable source, constraint, IP definition and build setting is identical.

## Timing, utilization and route interpretation

All three routed designs have identical setup and hold margins and zero failing endpoints. C1 adds 34 routed LUTs and one FF relative to C3; C2 adds 33 LUTs and one FF. These are 0.16% or less of device LUT capacity and are consistent with the small local ACK-selection/endpoint-control deltas. BRAM use is identical. Routable-net increases are 42 for C1 and 44 for C2, with every net fully routed. No unexpected large timing, utilization or routing change exists, so no optimization or timing-difference suppression was performed.

For additional stage context, C3/A/B post-synthesis LUT counts are 20,319 / 20,342 / 20,351 and post-opt counts are 18,577 / 18,601 / 18,609. FF counts are 21,097 / 21,098 / 21,098 post-synthesis and 20,083 / 20,084 / 20,084 post-opt. The small deltas remain stable through the qualified flow.

The clock topology and frequencies are frozen. The C3 reference contains BUFGCTRL=8, BUFIO=1 and MMCME2_ADV=2 with clocks at 148.5 MHz (NVP), 198 MHz (IDELAY), 100 MHz (PCIe/txout), 125/250 MHz generated, and 62.5 MHz user clock. Candidate reports were checked for the same clock set and resources.

The frozen I/O policy reports no no-clock or unconstrained-internal endpoints. C3 has two inputs without input delay, one additional false-pathed input, and three outputs without output delay; these are interface-policy findings rather than candidate deltas. Candidate comparison confirms exact normalized equivalence of the complete `check_timing` sections, clock name/waveform/period tables, final I/O-resource sections, and final clock-resource sections for both candidates versus C3.

## DRC comparison

C3 has no Error or Critical Warning. Its 15 non-gating warnings are `PDCN-1569` ×1, `REQP-1839` ×4, `REQP-1840` ×9 and `RTSTAT-10` ×1. C1 and C2 have the exact same four rules and counts, with no new rule, Error, or Critical Warning.

## Conclusion

**PASS.** The three-cell build comparison is controlled: build provenance and configuration are equivalent, source deltas are isolated, timing is identical, utilization/net-count changes are small and explained, clock/I/O behavior is unchanged, DRC classifications match, and both candidate bitstreams have unique identities.
