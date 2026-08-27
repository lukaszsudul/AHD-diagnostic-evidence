# AHD v41 G1 Exact Integration Architecture

## 1. Executive recommendation

G1 engineering disposition is `PASS`. Build the future integration from the exact qualified R1i tree `70d801fd7a879080da399bfa9ee95fd6eb008e16` at commit `20c3323d79d3896edc586d6db1df7deee60f9e41`, not by merging the older XDMA donor over it. Git ancestry and blob inspection prove that the qualified tree already inherits the primary donor's endpoint, AXI-Lite, BAR, capture/record, constraints, and build substrate. R1i remains whole-file authority for NVP bring-up, autoinit, the qualified composite top, and all existing MMIO semantics.

Use two implementation gates: `G2A` for exact integration/provenance plus the reviewed Gen2 x1 configuration and an offline build; then `G2B` for a minimal one-channel C2H path. Do not combine two-channel physical ingress with G2. The frozen final DMA model is one Gen2 x1 C2H channel with two private four-record rings, channel-tagged 4 KiB records, and work-conserving round-robin arbitration at record boundaries. It minimizes scarce LUT/routing cost while preserving per-channel buffering and loss isolation.

Gen2 implementation is allowed from repository evidence. One routed lane, the Artix-7 PCIe block/GTP resources, 100 MHz differential reference clock, and active-low PERST are present with no contradiction. Schematic/SI and host root-port capability receipts are absent; those are later hardware-validation gaps, not an invented G2 blocker. Gen2 training and the `>=288 MB/s` application requirement remain unclaimed until later hardware gates, with G8 reserved for measured throughput qualification.

## 2. Frozen inputs

| Input | Frozen identity/status |
|---|---|
| Qualified R1i preservation branch | `baseline/v41-r1i-qualified-poc` |
| R1i commit/tree/tag | `20c3323d79d3896edc586d6db1df7deee60f9e41`; tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`; `v41-r1i-qualified-poc-20260827` |
| Qualified bitstream | SHA-256 `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`; `THESIS_CONFIRMED`, `STRONG_PASS`, `QUALIFIED_POC_BASELINE` |
| Primary XDMA donor | `v41/xdma-v40.1.0-base`; `c89e88bcdf389614c884fb129e8b2d42a585bccb`; tag `v41-xdma-primary-donor-g0-20260827` |
| Secondary donor | `dev/v41-xdma-offline-next`; `8464af66611f7c22b8a36a4aab915d598eedda3f`; `PROVENANCE_HARDENING_ONLY` |
| Product inputs | Four physical video inputs; maximum two simultaneously active; sustained useful application payload `>=288 MB/s`; final PCIe Gen2 x1 or better |

G−1 and G0 findings and the qualified R1i hardware package are authoritative. The current R0 causal-isolation design informs diagnostic retention, but this architecture does not depend on an incomplete R1 result or assume a final causal explanation.

## 3. R1i authority

R1i wins wholesale for `rtl/nvp/nvp6134c_i2c_bringup.vhd` and `rtl/nvp/nvp6134c_autoinit.vhd`, including their exact qualified package/table interface. Protected behavior includes 25 kHz operation from the qualified 62.5 MHz binding, physical-SCL filtering and high dwell, qualified ACK timing, diagnostic-only early sampling, first-qualified-NACK abort, legal STOP/BUS_FREE, bounded four-attempt retry/backoff, timeout, recovered versus terminal classification, bank verification/invalidation, one autonomous startup sequence, and exact R1i telemetry meanings.

R1i also owns every existing MMIO behavior through `0x35FF` and the read-only telemetry page at `0x3600–0x367F`, including response timing, forwarding, unaligned behavior, and reserved-zero results. The qualified top is the composition oracle because it contains the donor endpoint plus all protected R1i wiring. No R-track candidate may enter G2 unless a separate owner decision requalifies the baseline.

## 4. XDMA donor authority

The primary donor owns the endpoint architecture: PCIe lane/refclock/PERST wiring, the XDMA 4.2 instance, AXI-Lite bridge, BAR transport, PCI IDs, MSI mode, one C2H and mandatory one H2C interface, existing capture/record path outside R1i-owned logic, active XDC set, and build/report structure. In the R1i tree those donor-owned anchors are inherited and byte-identical unless listed as an R1i conflict.

The secondary donor is not an alternative functional source. Only its reviewed provenance intents may be ported into a new G2 harness: validated `FULL_BUILD`/`PROVENANCE_ONLY` mode, five-word 40-hex SHA round-trip, explicit receipt/PASS fields, and an exit before project commands in provenance-only mode. The immutable `r1i_build.tcl` remains the qualified oracle. The G−1 inventory contains a transcribed SHA-256 error for that script; the decisive Git blob `843d644...` recomputes to `7A0CF8BA86FB9245355AD964D6127CC1412A3CF4B9D3228C478F9FC768CDA58F`.

## 5. Conflict resolution

All five registered hotspots are resolved on paper in [V41_G1_CONFLICT_RESOLUTION_PLAN.csv](V41_G1_CONFLICT_RESOLUTION_PLAN.csv):

1. take the exact R1i bring-up engine whole-file;
2. take the exact R1i autoinit/table/telemetry interface whole-file;
3. start from the exact R1i composite top, preserve inherited donor endpoint semantics, and later replace only the explicit C2H tie-off boundary;
4. retain the exact R1i register block and place a transparent, disjoint extension router before it for proposed `0x3800–0x3BFF` pages; and
5. create a G2-specific reproducible harness from donor structure plus R1i sources/tests and only the reviewed secondary provenance intent.

The top rule is the documented exception to a simplistic “donor file wins” interpretation: donor semantics win for endpoint content, but the qualified R1i file is the correct starting text because the donor is its ancestor and replacing the composite would discard protected R1i wiring. No merge occurs in G1.

## 6. Gen2 transition

The exact intentional user-configuration delta is one property in two authoritative representations:

```text
CONFIG.pl_link_cap_max_link_speed: 2.5_GT/s -> 5.0_GT/s
```

It must eventually change in `ip/v41/xdma_v41_m1.xci` and `scripts/v41/xdma_config_common.tcl`; the helper reapplies the setting, so changing only one is invalid. The regenerated model's encoded value is expected to change from 1 to 2, but generated output is never hand-edited. Every effective `CONFIG.*` property is dumped and compared.

Width x1, 100 MHz refclk, AXI4-Stream/64-bit datapath, one C2H, mandatory unused one H2C with application `TREADY=0`, one MSI vector, MSI-X disabled, 128 KiB AXI-Lite aperture, BAR architecture, active-low dedicated PERST, and identities `10EE:7011`, subsystem `10EE:0007`, class `058000` remain unchanged. No intentional active XDC change is expected.

Actual `user_clk`/`axi_aclk` expectation is `TO_BE_VERIFIED_IN_G2/G3`. The XCI requests 62.5 MHz, interface metadata reports 125 MHz, while routed evidence measured 62.5 MHz. G2A must request and prove the effective/generated/routed clock and stop if it differs from the qualified 62.5 MHz expectation; no silent timing-constant change is allowed. See [V41_G1_GEN2_XDMA_CHANGE_PLAN.md](V41_G1_GEN2_XDMA_CHANGE_PLAN.md).

## 7. Hardware feasibility

Disposition: `G2_IMPLEMENTATION_ALLOWED`.

The active constraints prove one PCIe lane, RX G4/G3, TX B2/B1, GTP channel/common and PCIe hard-block placement, D6/D5 100 MHz differential reference clock, and C8 active-low PERST. Gen2 retains the same lane, hard block, transceiver, refclock, and reset topology. Repository evidence contains no board-level contradiction.

The missing schematic/layout/insertion-loss/Gen2 compliance and exact parent-root-port `LnkCap` evidence are recorded gaps. Later hardware validation must capture endpoint and parent capability/status, negotiated 5.0 GT/s x1, current/max sysfs speed/width, retrain/reset behavior, and AER/link errors. G2A is offline and cannot claim link feasibility by measurement. See [V41_G1_GEN2_HARDWARE_FEASIBILITY.md](V41_G1_GEN2_HARDWARE_FEASIBILITY.md).

## 8. C2H data plane

The frozen path is source byte stream → validated record producer → channel-local dual-clock record ring → committed-descriptor CDC → record scheduler → 64-bit formatter → XDMA `S_AXIS_C2H_0` → host. New role blocks are the record sink, four-slot ring, descriptor/release CDC, scheduler, formatter/skid stage, counter bank, MMIO extension router, and optional advisory IRQ latch.

The transport retains exactly 4,096 bytes/512×64-bit beats because it aligns naturally, makes `TKEEP=0xFF` on every beat, uses `TLAST` only on beat 511, and yields 93.75% useful-record efficiency for the existing 3,840-byte payload. C2H uses a versioned `v41D` header (`0x00004101`) with logical channel, physical input, per-channel attempt sequence, and global streamed sequence. Legacy v40B PIO records remain byte-exact and use separate storage; PIO and DMA streaming modes are mutually exclusive.

Video cannot be backpressured. When a channel ring is full, the next whole record for that channel is dropped before any byte is written, its attempt/drop/overflow counters increment, and the next admitted record signals discontinuity. Partial drop, overwrite-oldest, and cross-channel slot borrowing are forbidden. AXIS payload/control remain stable under `TVALID && !TREADY`, selection locks through the final handshake, and ownership returns only after beat 511 is accepted. See [V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md](V41_G1_C2H_DATA_PLANE_ARCHITECTURE.md).

## 9. One-channel architecture

G6's one-channel contract selects physical input 0 through the already proven video path into logical channel 0, writes complete `v41D` records into a dedicated four-slot ring, and presents them on `/dev/xdma*_c2h_0`. The host validates magic/version/length/zeros, source and attempt sequences, payload, `TKEEP`/`TLAST` behavior through FPGA assertions, and all drop/error counters. Frame, line, and capture sequences retain source association; the channel and physical-input fields remove ambiguity.

G2B implements only this one-channel logical path. It does not claim G6 hardware qualification or a second physical video output. The exact host and telemetry contract is [V41_G1_ONE_CHANNEL_DMA_CONTRACT.md](V41_G1_ONE_CHANNEL_DMA_CONTRACT.md).

## 10. Two-channel architecture

The evaluated choices were a shared unpartitioned/tagged FIFO, two independent XDMA C2H engines, and one C2H with per-channel rings plus arbitration. The selected model is the third: one Gen2 x1 C2H, two private four-record rings, channel-tagged records, and record-boundary work-conserving round-robin scheduling.

It uses one formatter/engine, spends relatively available BRAM on deterministic isolation, preserves total streamed order, and cannot gain link bandwidth by duplicating XDMA engines on one lane. Each logical channel maps to a distinct physical ID from 0..3; mapping changes require the channel disabled and drained. Equal-size records make round-robin byte-fair. A channel-local overflow or source fault does not consume the other ring; a shared formatter/link fault affects both.

Repository evidence does not prove the second NVP digital output/pin or a multiplexed two-channel contract. That gap blocks later physical two-channel implementation/qualification, not the frozen shared-C2H design, G2A, or one-channel G2B. See [V41_G1_TWO_CHANNEL_DMA_ARCHITECTURE.md](V41_G1_TWO_CHANNEL_DMA_ARCHITECTURE.md).

## 11. Throughput budget

Gen2 x1 is 5 GT/s with 8b/10b encoding, giving a 500 MB/s post-encoding byte ceiling. The frozen useful payload requires at least `288/500 = 57.6%` end-to-end effective PCIe efficiency. Because a 4,096-byte record carries 3,840 useful bytes, the application requires 75,000 records/s, 307.2 MB/s of record bytes, and 38.4 million accepted 64-bit AXIS beats/s. After record padding, the required remaining link/AXI efficiency is 61.44%.

The planning product `0.82 PCIe × 0.96 XDMA × 0.95 AXI × 0.9375 record × 0.92 host = 64.50%` yields 322.5 MB/s. A deliberately conservative product of 54.73% yields 273.6 MB/s and misses. Therefore the architecture is plausible but carries real margin risk; it is not a throughput PASS. Host copy cost is excluded from the FPGA payload contract but must be reported separately. G8 alone qualifies sustained payload, zero drops, and long-run behavior. See [V41_G1_THROUGHPUT_BUDGET.md](V41_G1_THROUGHPUT_BUDGET.md).

## 12. Resource decomposition

Qualified R1i final routed use is 18,181/20,800 LUT (87.41%), 20,083/41,600 FF (48.28%), and 26/50 BRAM tile equivalents (52%), leaving an arithmetic 2,619 LUT and 24 BRAM tiles. This is not a safe insertion budget. Post-opt LUT use is already 89.31%, and no qualified R1i hierarchy isolates removable diagnostics.

Same-stage R1h hierarchy provides a non-additive reference: XDMA 11,656 LUT; capture/record 1,097; autoinit 2,166 mixed; bridge 1,845 mixed; tri-phase research probe 2,093; failed logger 151 plus six RAMB18; diagnostic read service 93; lifecycle observer 89. Named probe/logger/read-service islands sum to 2,337 LUT, 3,086 FF, and nine RAMB18 in R1h. The exact R1i removable amount remains `UNKNOWN`; the R1i−R1h routed delta of +1,062 LUT/+702 FF mixes functional fixes and telemetry.

The product/diagnostic attribution, classifications, structural ring estimate, and non-additivity rules are frozen in [V41_G1_RESOURCE_DECOMPOSITION.md](V41_G1_RESOURCE_DECOMPOSITION.md).

## 13. Diagnostic reduction

Keep in product: initialization state/error, aggregate qualified NACK, retry exhausted, SCL timeout, bank-safety error, FIFO overflow, DMA/drop/protocol counters, reset epoch, and channel state/mapping. Keep until R-track completes: early/qualified/raw comparisons, per-phase and retry-tier detail, maximum SCL wait, first-event identifiers, failed-attempt records, lifecycle evidence, tri-phase probe, deep histories, and their MMIO service.

After causal closure and owner-approved ABI review, candidates include the autonomous post-init probe campaign, three index BRAMs, six failed-record BRAMs, block/run/adjacency history, and deep-record read service. Functional ACK timing, STOP/BUS_FREE, retry/backoff, timeout, and bank safety are never diagnostic-removal candidates. Existing MMIO addresses cannot be silently reused. See [V41_G1_DIAGNOSTIC_REDUCTION_PLAN.md](V41_G1_DIAGNOSTIC_REDUCTION_PLAN.md).

## 14. Resource headroom

Development hard stops are >90% LUT, >80% FF, or >80% BRAM at post-opt/routed stages, any unroutable/severe-congestion condition, or non-positive setup/hold. Preferred development LUT is <=85%. Release candidates require routed LUT <=85% with <=80% as the objective, FF <=70%, BRAM <=75%, no level-5-or-higher congestion, WNS >= max(0.25 ns, 3% of the shortest relevant period), WHS >=0.02 ns, TNS/THS zero, and clean DRC/CDC/clock evidence.

G2A measures the Gen2 delta. G2B must fit with diagnostics intact or stop. The later two-channel commitment requires measured remaining work with a 1.25 uncertainty multiplier plus a 5%-device ECO reserve under the applicable cap. See [V41_G1_RESOURCE_HEADROOM_POLICY.md](V41_G1_RESOURCE_HEADROOM_POLICY.md).

## 15. Clock/reset/CDC

Logical domains are NVP control, each recovered video clock, XDMA user/AXI-Lite/C2H stream clock, and the PCIe refclock/internal domain. R1i currently derives the NVP control clock from `axi_aclk` but intentionally excludes `user_lnk_up` and `axi_aresetn` from NVP reset/start. G2A must prove 62.5 MHz and a lifecycle adequate for autonomous bring-up; otherwise it stops for an approved stable-clock architecture with explicit CDC. PCIe availability must never accidentally become an NVP bring-up prerequisite.

Video-to-XDMA payload crosses only through dual-clock ring RAM and asynchronous descriptor/release protocols. Multi-bit data is never sampled through independent synchronizers. Slow status uses two-flop synchronizers for levels, toggle/pulse capture for events, Gray transfer or snapshot/handshake for counters, and epoch-tagged reset release. Resets assert safely and release synchronously in each domain. PERST/XDMA reset flushes only the stream/control plane; NVP reset is independently owned. The full map is [V41_G1_CLOCK_RESET_CDC_PLAN.md](V41_G1_CLOCK_RESET_CDC_PLAN.md).

## 16. MMIO plan

Every address through `0x35FF` and R1i `0x3600–0x367F` remains exact. Existing named-but-zero DMA placeholders at `0x00C0–0x00E0` are protected and not repurposed. `0x3680–0x37FF` remains reserved.

`PROPOSED_FOR_G2` pages are `0x3800–0x38FF` global DMA control/status, `0x3900–0x397F` channel 0, `0x3980–0x39FF` channel 1, `0x3A00–0x3A7F` coherent throughput snapshot, `0x3A80–0x3AFF` error/IRQ, and `0x3B00–0x3BFF` future/reserved. A transparent extension router intercepts only these pages; all other transactions go to the exact R1i service without an added registered stage. See [V41_G1_MMIO_MAP_PLAN.md](V41_G1_MMIO_MAP_PLAN.md).

## 17. Host test architecture

Reuse the installed XDMA driver procedures; do not reinstall or modify the driver. Add a userspace C2H record reader/validator plus orchestration and report tooling. Tests progress from node/identity/MMIO checks to deterministic one-record validation, sequence/drop detection, one-channel capture, synthetic or later real two-channel demultiplexing, bounded throughput, and long-run soak.

Every run records endpoint/parent link capability and status, driver/device identities, firmware provenance, bytes/records/payload rates, short reads/timeouts, global and per-channel gaps, pre/post FPGA counter snapshots, CPU/host-copy policy, and zero-drop/error assertions. Interrupts are advisory; blocking reads and record accounting determine correctness. See [V41_G1_HOST_DMA_TEST_ARCHITECTURE.md](V41_G1_HOST_DMA_TEST_ARCHITECTURE.md).

## 18. G2 implementation contract

The recommended split is `G2A+G2B`. G2A contains P1 worktree/branch construction from the immutable R1i base, P2/P3 identity and authority receipts, P4 conflict composition with no C2H activation, P5 reviewed provenance hardening, P6 the one-property Gen2 x1 change, and P8–P12 compile/elaborate/synthesize/implement/bitstream/offline evidence. It makes no hardware claim.

G2B begins only after accepted G2A and implements P7's minimal logical-channel-0 C2H blocks, the v41D golden contract, disjoint MMIO pages, protocol/CDC/reset assertions, then repeats P8–P12 offline. Two-channel physical ingress and the second ring/scheduler activation remain later gates. Atomic entry/exit and hard stops are in [V41_G2_IMPLEMENTATION_CONTRACT.md](V41_G2_IMPLEMENTATION_CONTRACT.md).

## 19. G2 blockers

No known blocker prevents G2A entry. Mandatory stop conditions include identity/tag/tree mismatch; ambiguity expressing the exact Gen2 property and invariants; a real board/XDC contradiction; effective application clock not proved at the qualified expectation; any NVP dependence on link/reset; protected source/MMIO/test change; unresolved clock/reset/CDC; resource/timing/routing failure; or contaminated/non-reproducible provenance.

G2B additionally requires an accepted G2A, a bounded one-channel resource estimate that fits with diagnostics, reviewed v41D vectors and no-alias tests, separate DMA/PIO storage, and reviewed reset-epoch/descriptor CDC assertions. The second physical ingress evidence gap blocks only the later two-channel implementation. See [V41_G1_G2_ENTRY_CHECKLIST.md](V41_G1_G2_ENTRY_CHECKLIST.md).

## 20. Risks

| Risk | Consequence | Control |
|---|---|---|
| Gen2 clock metadata contradicts routed evidence | Silent NVP timing or reset-lifecycle regression | G2A property/generated/routed clock proof and hard stop; G3 lifecycle measurement |
| Only 57.6% end-to-end efficiency is mathematically required but conservative budget misses | 288 MB/s may fail despite Gen2 link | Fixed 4 KiB records, no intentional AXIS bubbles, efficient host reads, staged measurement; G8 remains qualification |
| Qualified LUT utilization is high | C2H/two-channel may not route or close timing | G2A delta first, G2B resource gate, BRAM-heavy private rings, later causal/ABI-approved diagnostic reduction |
| Second physical digital ingress unproved | Cannot implement two simultaneous sources safely | Later board/NVP/output-mode qualification; do not infer pins or alter R1i |
| PCIe x1 shared failure/backpressure | Both channels eventually stall/drop | Private rings and counters isolate short/local effects; shared fault is explicit |
| MMIO extension changes protected behavior | Host/qualification regression | Disjoint pages, transparent router, exhaustive no-alias and response equivalence |
| Reset during a record | Truncation or stale ownership | Epoch flush, no admission until domain acknowledgement, restart only at beat 0, counted abandonment |
| Premature diagnostic removal | Loses causal evidence or changes function/ABI | No removal through G2; R-track closure, fanout proof, compatibility decision, controlled A/B gate |
| Missing schematic/SI/root-port receipt | Gen2 may not train on target host/board | Recorded evidence gap and later link capability/status/AER validation; not an offline G2 blocker |

## 21. Final recommendation

Freeze G1 as `PASS`, with R1i and the primary donor authorities frozen and all five conflict decisions accepted. Permit `G2A` from the immutable R1i tree for an isolated, provenance-sealed Gen2 x1 offline build; require the effective 62.5 MHz/lifecycle and resource/timing evidence before acceptance. If G2A passes, permit `G2B` to add only the minimal one-channel four-record-ring/v41D C2H path under the protected MMIO, CDC, and headroom contracts. Do not implement the second physical channel, remove diagnostics, access hardware, or claim `>=288 MB/s` in G2. The final two-channel product remains one shared C2H with private rings and record-boundary arbitration, and G8 remains the measured throughput gate.
