# AHD v41 G2B-IMPL Evidence Index

## Result and scope

This directory publishes the offline implementation and first-blocker evidence
for the minimal one-channel C2H data plane under the frozen G2B-PRE contract.

- Engineering gate: `BLOCKED`.
- First blocker: `BLOCKED — RESOURCE_HEADROOM_REQUIRES_ARCHITECT_REVIEW:
  LUT_GT_90_PERCENT`.
- Focused offline tests: `PASS`.
- Clean synthesis and optimization: `PASS`.
- Placement, routing, timing, critical DRC, bitstream: `NOT_RUN` /
  `NOT_PRODUCED` because the earlier resource gate stopped the flow.
- Hardware accessed: `NO`.
- Hardware throughput proven: `NO`.
- Integration commit: `NONE`.
- Project-state revision at start: `2`.
- Project-state revision at end, before publication: `2`.

This is a blocker-grade evidence publication. It does not classify the source
as an `OFFLINE_QUALIFIED_G2B_CANDIDATE` and does not recommend SSOT promotion to
that level.

## Authoritative inputs

| Input | Identity |
|---|---|
| Accepted G2A source base | `224d194e5f82c85bcb29297561c5d5e76d28063b` |
| Accepted G2A tree | `283f98c02e6f9c61716875415cf000682f8ab856` |
| G2B branch | `integration/v41-g2b-onech-c2h` |
| Frozen G2B-PRE evidence | `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| G2B-PRE META promotion | `4452f6b4293bd4e4267f81c7c8d42cac3f14fd83` |
| ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version 1 |
| MMIO | `0x3800..0x3BFF` |
| Sealed source manifest | `9897784DB1C642CBF0F7F25EB864A05F904DFB4F8DE5B714FEA3B395AB69A587` |

## Principal reports

| Artifact | Role |
|---|---|
| `V41_G2B_IMPL_REPORT.md` | Main engineering result, implementation summary, acceptance boundary, and first blocker |
| `G2B_IMPL_TEST_REPORT.md` | Focused core/router simulation matrix and authoritative receipts |
| `G2B_IMPL_CDC_AUDIT.md` | Complete new-crossing inventory, methods, constraints, verification, and routed-check boundary |
| `G2B_IMPL_R1I_PROTECTION_AUDIT.md` | Static protected diff plus byte-identical R1i wire-sequence qualification |
| `G2B_IMPL_ABI_GOLDEN_VECTOR_REPORT.md` | Eight exact 4,096/4,096-byte vectors and all-record structural parsing |
| `G2B_IMPL_HOST_PARSER_REPORT.md` | Parser behavior, negative controls, and frame reconstruction |
| `G2B_IMPL_BUILD_RESOURCE_REPORT.md` | Clean build stages, exact utilization/deltas, hashes, and resource blocker |
| `G2B_IMPL_TIMING_DRC_SUMMARY.md` | Generated clocks and explicit not-run routed timing/DRC disposition |
| `G2B_IMPL_SOURCE_IDENTITIES.md` | Source/base/XDMA/tool/test identities and absence of integration commit/bitstream |
| `G2B_IMPL_OFFLINE_THROUGHPUT_REPORT.md` | Theoretical payload/record/transport/Gen2 x1 arithmetic; no hardware claim |
| `G2B_HW_TEST_PLAN.md` | Prepare-only next hardware gate; current readiness blocked |
| `V41_G2B_IMPL_LINUX_V4L2_HANDOFF.md` | Frozen contract, implemented source state, hardware gap, and V4L2 gap |
| `G2B_IMPL_SSOT_UPDATE_REQUIREMENTS.md` | Read-only SSOT policy and accurate blocker-state requirements |

## Machine-readable and raw text receipts

| Artifact | Role |
|---|---|
| `G2B_ABI_GOLDEN_VECTOR.json` | Machine-readable golden-vector and structural-parser result |
| `G2B_XSIM_RECEIPT.txt` | Authoritative focused core XSim receipt |
| `G2B_ROUTER_XSIM_RECEIPT.txt` | Exhaustive MMIO-router XSim receipt |
| `G2B_ROUTER_XSIM_RESULT.txt` | Router terminal result |
| `G2B_HOST_UNIT_TEST_RECEIPT.txt` | 11/11 host reference-tool test receipt |
| `G2B_HOST_FRAME_FIXTURE_RECEIPT.txt` | 1,080-line simulated frame-fixture identities and checks |
| `G2B_BUILD_RESULT.txt` | Authoritative clean-build terminal receipt |
| `G2B_BUILD_PROVENANCE.txt` | Clean-build source/tool/IP provenance |
| `G2B_BUILD_INPUT_SHA256.txt` | Canonical 34-file build-input manifest |
| `G2B_XDMA_EFFECTIVE_CONFIG.txt` | Generated effective XDMA configuration |
| `POST_OPT_RESOURCE_GATE.txt` | Machine-readable resource-gate result |
| `POST_OPT_UTILIZATION_FLAT.rpt` | Vivado optimized flat utilization report |
| `POST_OPT_UTILIZATION_HIER.rpt` | Vivado optimized hierarchy utilization report |
| `G2B_IMPL_SHA256_MANIFEST.txt` | SHA-256 binding for every other published file in this directory |

## Artifact publication policy

Only reports, receipts, configuration text, hashes, and provenance are
published. RTL source, Vivado projects, DCPs, waveform databases, simulated
record binaries, raw UYVY frame binaries, and any bitstream are not published.
Their permitted identities are recorded in the reports. No bitstream exists for
this blocked run.

## Preservation boundary

The publication commit must add only this new directory. It must not change:

- `v41-development-g2b-one-channel-c2h-offline`;
- `v41-development-g2b-pre-c2h-abi-mmio-freeze`;
- `v41-meta-project-state-rev2-g2b-pre-promotion`;
- `project-current-state`;
- any prior evidence directory.

## Publication binding

The exact evidence commit is the remote `main` commit containing this index and
the SHA-256 manifest. The commit identity is supplied by the final remote
read-back and task response, avoiding impossible Git self-reference.
