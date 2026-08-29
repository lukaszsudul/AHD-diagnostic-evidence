# AHD v41 G2B-IMPL Minimal One-Channel C2H Offline Report

## Result

`ENGINEERING_GATE = BLOCKED`

`FIRST_BLOCKER = BLOCKED — RESOURCE_HEADROOM_REQUIRES_ARCHITECT_REVIEW: LUT_GT_90_PERCENT`

`CLASSIFICATION = OFFLINE_IMPLEMENTATION_EVIDENCE_WITH_RESOURCE_BLOCKER`

The frozen one-channel transport was implemented and its focused offline tests
passed. The sealed clean Vivado build passed synthesis and `opt_design`, then
the mandatory post-opt resource gate stopped the flow at 21,412 LUTs on a
20,800-LUT device (102.942%). Placement, physical optimization, routing,
routed timing/DRC/CDC qualification, bitstream generation, and the integration
commit were therefore not performed. This is not an
`OFFLINE_QUALIFIED_G2B_CANDIDATE`.

Evidence publication documents the blocker; it does not waive it.

## Authoritative identities

| Item | Identity |
|---|---|
| Project-state revision at start | `2` |
| Project-state revision at end, before publication | `2` |
| Accepted G2A base/HEAD | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Accepted G2A tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| Integration branch | `integration/v41-g2b-onech-c2h` |
| Integration commit | `NONE` |
| Frozen PRE evidence | `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| META promotion evidence | `4452f6b4293bd4e4267f81c7c8d42cac3f14fd83` |
| Transport | `AHD_C2H_TRANSPORT_ABI_V1`, version 1 |
| MMIO | `0x3800..0x3BFF` |
| Vivado | `2025.2`, SW build `6299465` |
| Sealed build-input manifest | `9897784DB1C642CBF0F7F25EB864A05F904DFB4F8DE5B714FEA3B395AB69A587` |

The G2B branch remained an uncommitted direct worktree over the exact accepted
G2A base because the user required a source commit only after all focused tests
and the complete clean build passed.

## Implemented source path

The product source is the accepted active-video path, not a synthetic source:

- source clock domain: `nvp_clk` (`nvp_vclk1` timing object);
- source data: existing registered `nvp_data_byte`, 8 bits;
- readiness: `nvp_enable && nvp_frontend_released`;
- line validity: the existing BT.656 active-line byte stream is validated for
  a complete 1,920-pixel active line before commit;
- byte order: source left-to-right UYVY, `U0 Y0 V0 Y1`;
- frame/line metadata: source-domain validated frame and active-line sequence;
- logical channel: 0;
- physical input mapping: 0;
- CDC boundary: private dual-clock XPM record memories plus acknowledged
  toggle/mailbox crossings and a coherent Gray-coded statistics snapshot.

The `physical_frontend` change is an additive observation of its existing
registered ingress-release state. It does not alter the NVP initialization,
I2C master, SCL/ACK, capture producer, or legacy MMIO behavior.

## Data plane

The source snapshot implements exactly one application C2H channel and the
frozen geometry:

- four private 4,096-byte record slots;
- ownership lifecycle `WRITABLE → FILLING → COMMITTED → DMA_OWNED →
  RELEASABLE → WRITABLE` with generation/epoch protection;
- 64-byte ABI header, 3,840-byte active UYVY payload, and 192 zero bytes;
- 512 64-bit beats, `TKEEP=0xFF`, and TLAST only on beat 511;
- oldest-committed-first scheduling and only one DMA-owned slot;
- stable TVALID/TDATA/TKEEP/TLAST under arbitrary TREADY stalls;
- release only after the final-beat handshake;
- ring-full complete-record admission drop with no partial overwrite;
- frozen attempt/global sequence, discontinuity, overflow, error, reset epoch,
  reset coalescing, and coherent-counter snapshot semantics;
- fatal admission stop while preserving an already presented valid record.

The standalone formatter-reset protocol exists in the core, but no distinct
accepted product cause exists in the top, so that top-level cause is tied low.
The explicit source-reset port is also tied low in product integration and was
exercised only in offline simulation. NVP/source reset is deliberately not
mapped to transport epoch reset.

## MMIO and XDMA protection

The implementation decodes only the frozen G2B words within
`0x3800..0x3BFF`, including identity `0x43324831`, ABI `0x00010000`, and
one-channel capability `0x000B001F`. Exhaustive router simulation confirmed
that every address outside the G2B window retains the prior legacy/future path.
No undocumented register was added.

The accepted XDMA XCI was unchanged. Its SHA-256 is
`9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F`
and its Git blob is `450aa334e2bda4396cd5a7270ba15895c7f7ed54`.
Generated effective configuration retained Gen2 x1, a 64-bit AXI Stream C2H
interface, a 62.5 MHz requested AXI-stream clock, and the accepted BAR
settings. This is build-time configuration, not runtime PCIe negotiation proof.

## Focused offline qualification

| Gate | Result |
|---|---|
| Static frozen-contract audit | PASS |
| Four-slot ownership/ring tests | PASS |
| Formatter/header/payload/padding tests | PASS |
| AXI scheduler/backpressure tests | PASS |
| Attempt/global sequence tests | PASS |
| Epoch/reset/drop/fatal/statistics/snapshot tests | PASS |
| Exhaustive MMIO router test | PASS |
| ABI golden vectors | PASS, 8 records byte-exact 4,096/4,096 |
| Host parser tests | PASS |
| Simulated 1,080-line frame reconstruction | PASS |
| Static CDC audit | PASS |
| R1i protected behavior | PASS |
| Offline throughput arithmetic | PASS |
| Hardware accessed | NO |

These results are detailed in the companion reports. The simulated frame is a
host/parser fixture and is not hardware DMA or real-camera evidence.

## Clean build disposition

| Stage | Result |
|---|---|
| Project creation / XDMA generation | PASS |
| Synthesis | PASS |
| Optimization | PASS |
| Post-opt resource gate | BLOCKED |
| Placement / physical optimization | NOT_RUN |
| Routing | NOT_RUN |
| Routed timing | NOT_RUN |
| Routed critical DRC / CDC / bus skew | NOT_RUN |
| Bitstream | NOT_PRODUCED |

Post-opt use was 21,412 LUTs / 20,800 (102.942%), 23,643 FFs / 41,600
(56.834%), 30 BRAM tiles / 50 (60.000%), and 0 DSPs / 90. Against the accepted
G2A values, the deltas are +3,234 LUTs, +3,506 FFs, and +4 BRAM tiles. The G2B
hierarchy itself reports 1,990 LUTs and 2,908 FFs; memory packing and added
integration logic contribute to the device-wide delta.

The generated post-synthesis clock table resolves `userclk1` to 16.000 ns /
62.500 MHz. Routed effective user/AXI clock proof, WNS, and WHS are unavailable
because placement and routing were not allowed to start.

## Required next action

Architecture review is required to reduce LUT use and restore safe headroom
without removing R-track/diagnostic logic, altering qualified R1i behavior, or
changing the frozen ABI/MMIO contracts. Then rerun the complete sealed build
from the exact accepted G2A parent. Only after every offline gate passes may an
integration commit and bitstream candidate be produced. G2B-HW remains blocked.

## Scope boundary

No DUT was accessed; no FPGA was programmed; no SSH, PCIe rescan, driver
operation, or hardware DMA was performed. The HDMI project, R-track,
qualified R1i behavior, prior evidence directories, and
`project-current-state` were not modified.
