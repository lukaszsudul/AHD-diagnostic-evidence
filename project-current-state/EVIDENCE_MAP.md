# AHD Current-State Evidence Map

`PROJECT_STATE_REV = 3`
Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`
Evidence `main` snapshot used for revision 3:
`a70c55eca5f0c0ad349143ad93ab87eb80d11ac4`

## Acceptance rule

Evidence proves execution, measurement, build, observation, or documented
architecture input. It does not prove Owner/Architect acceptance. For every
`ACCEPTED`, `REJECTED`, `SUPERSEDED`, or `BLOCKED` project-truth statement,
the decision basis must be explicit.

Revision 1 uses `META-0_TASK_DIRECTIVE` as the Owner/Architect decision basis.
That directive explicitly identifies the supplied current state as approved
input and authorizes only initial SSOT creation. Evidence packages support the
facts but do not auto-promote their `PASS` results.

Revision 2 uses the explicit `META-2_TASK_DIRECTIVE` Owner/Architect decision
to accept the G2B-PRE architecture freeze and promote only its C2H transport
ABI, MMIO, and Linux transport-input contract. The G2B-PRE engineering `PASS`
supports that decision but does not itself establish acceptance or any G2B,
DMA, hardware, or V4L2 implementation result.

Revision 3 uses the explicit `META-3_TASK_DIRECTIVE` Owner/Architect decision
to accept G2B-LUT0 resource architecture, place the R-track on `HOLD`, and
authorize reversible `PRODUCT` and `RESEARCH_DIAGNOSTIC` profiles. G2B-LUT0
engineering `PASS` supports the decision but does not prove a profile
implementation, the PRODUCT LUT target, timing, a bitstream, hardware, or
V4L2.

## Authoritative evidence packages

| Evidence ID | Directory | Latest path commit | Original payload/add commit | Current subtree |
|---|---|---|---|---|
| `EVID-R1I` | [v41-nvp-r1i-r2-qualified-poc-hardware-evidence](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/955ba0cd2462f4dec9dcb086175ab6eca57365bb/v41-nvp-r1i-r2-qualified-poc-hardware-evidence) | `955ba0cd2462f4dec9dcb086175ab6eca57365bb` | `c1c552fa4fc693d6c375db9478abecd7960ec3ce` | `04f5c0f311b3a5c7ad6db981195ecb3476355f72` |
| `EVID-GM1` | [v41-development-g-minus-1-existing-work-inventory](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/654b9adf7d02cbf8946e420538955ffaaeae7eb2/v41-development-g-minus-1-existing-work-inventory) | `654b9adf7d02cbf8946e420538955ffaaeae7eb2` | `510cb2ead5dc49d36031b745022742f912b54e77` | `5a1b83879ace86c03a029f584a50163f163c73bf` |
| `EVID-G0` | [v41-development-g0-baseline-freeze](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/b5efb25082d7d18c8e022142e2303fd8a7bc3c6d/v41-development-g0-baseline-freeze) | `b5efb25082d7d18c8e022142e2303fd8a7bc3c6d` | `64eca0cfbb76593d7e875df7b3271651668cbe61` | `5313caf2f15335510b2e264abb19e8ef1c7a8d42` |
| `EVID-G1` | [v41-development-g1-integration-architecture](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd/v41-development-g1-integration-architecture) | `f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd` | `221f65aef9664a6d6ad35c3ec7644badd69ba381` | `5c81b36b96841ca76d135c3d737c8abc91372e88` |
| `EVID-G2B-PRE` | [v41-development-g2b-pre-c2h-abi-mmio-freeze](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze) | `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` | `9fdcca4e3a40b931f07db01ad404b4a3cfc24b10` | `762b8aba83653969d52ec991cd71ed8173268286` |
| `EVID-G2B-LUT0` | [v41-development-g2b-lut0-resource-attribution](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/a70c55eca5f0c0ad349143ad93ab87eb80d11ac4/v41-development-g2b-lut0-resource-attribution) | `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` | `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` | `05fd1075e0a8deb5082accccb0a88a3f18dfca54` |
| `EVID-R0` | [v41-research-r0-r1i-causal-isolation-design](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/aff7e32edc1cf71bde95b6c19e54e6f307764237/v41-research-r0-r1i-causal-isolation-design) | `aff7e32edc1cf71bde95b6c19e54e6f307764237` | `aff7e32edc1cf71bde95b6c19e54e6f307764237` | `5a9c08d9c48ac2e3ef7e0d79e189c8bdd2dbeaa9` |

Later receipt commits are used as `source_evidence_commit` because they contain
the final cited path state. Payload commits are retained to explain
self-reference-free publication receipts. For `EVID-G2B-PRE`, the payload was
published at `9fdcca4e3a40b931f07db01ad404b4a3cfc24b10`; the immutable final path state
and publication read-back are at
`e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e`.

### `EVID-G2B-PRE` authoritative artifacts

- [Main architecture-freeze report](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_G2B_PRE_ARCHITECTURE_FREEZE_REPORT.md)
- [Normative ABI Markdown](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_C2H_TRANSPORT_ABI_V1.md)
- [Normative ABI JSON](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_C2H_TRANSPORT_ABI_V1.json)
- [Normative MMIO contract](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_G2B_MMIO_CONTRACT.md)
- [Normative MMIO CSV](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_G2B_MMIO_MAP.csv)
- [Linux transport consumer contract](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze/V41_C2H_LINUX_CONSUMER_CONTRACT.md)
- [ABI consistency report](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze/G2B_PRE_ABI_CONSISTENCY_REPORT.md)
- [Decision log](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e/v41-development-g2b-pre-c2h-abi-mmio-freeze/G2B_PRE_DECISION_LOG.md)

### `EVID-G2B-LUT0` authoritative artifacts

- [Main architecture review](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/a70c55eca5f0c0ad349143ad93ab87eb80d11ac4/v41-development-g2b-lut0-resource-attribution/V41_G2B_LUT0_ARCHITECTURE_REVIEW.md)
- [R-track instrumentation inventory](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/a70c55eca5f0c0ad349143ad93ab87eb80d11ac4/v41-development-g2b-lut0-resource-attribution/G2B_LUT0_RTRACK_INSTRUMENTATION_INVENTORY.md)
- [Recommended Plan B](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/a70c55eca5f0c0ad349143ad93ab87eb80d11ac4/v41-development-g2b-lut0-resource-attribution/G2B_LUT0_RECOMMENDED_PLAN.md)
- [Resource targets](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/a70c55eca5f0c0ad349143ad93ab87eb80d11ac4/v41-development-g2b-lut0-resource-attribution/G2B_LUT0_RESOURCE_TARGETS.md)
- [Build-profile proposal](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/a70c55eca5f0c0ad349143ad93ab87eb80d11ac4/v41-development-g2b-lut0-resource-attribution/G2B_LUT0_BUILD_PROFILE_PROPOSAL.md)
- [Machine state](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/a70c55eca5f0c0ad349143ad93ab87eb80d11ac4/v41-development-g2b-lut0-resource-attribution/G2B_LUT0_STATE.json)
- [Evidence index](https://github.com/lukaszsudul/AHD-diagnostic-evidence/blob/a70c55eca5f0c0ad349143ad93ab87eb80d11ac4/v41-development-g2b-lut0-resource-attribution/G2B_LUT0_EVIDENCE_INDEX.md)

Revision 3 promotes only the accepted resource architecture and profile
authorization. No source profile implementation, accepted offline G2B
implementation, achieved LUT/timing target, bitstream, hardware result,
Linux driver, V4L2 implementation, or R2/R3 closure is inferred.

## Statement-level provenance

| Statement ID | Current-state statement | Status | Owner/Architect decision basis | Evidence and immutable commit | What evidence supports | Boundary |
|---|---|---|---|---|---|---|
| `STMT-GM1` | G-1 is current accepted product history/inventory | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-GM1`; `STATE.json` and inventory report at `654b9ad...` | Engineering inventory `PASS`, source/donor context | Evidence `PASS` alone did not accept G-1 |
| `STMT-G0` | G0 baseline freeze is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G0`; `V41_G0_STATE.json` and freeze report at `b5efb25...` | Exact R1i/donor identities and requirements | Acceptance supplied separately |
| `STMT-G1` | G1 architecture is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1`; `V41_G1_STATE.json` and architecture report at `f1258ba...` | `G2_IMPLEMENTATION_ALLOWED` and integration/C2H design | Does not accept G2 execution or throughput |
| `STMT-G2B-PRE` | G2B-PRE architecture freeze is accepted and its contract input was ready for implementation from the accepted G2A input base | `ACCEPTED` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; architecture-freeze report, state, consistency report, and decision log at `e8ab101...` | Engineering `PASS`, exact G2A input identity, complete ABI/MMIO decisions, and Linux consumer input contract | Historical contract-input readiness is not current G2B-IMPL readiness; G2B-IMPL is now `BLOCKED_RESOURCE_HEADROOM` and only G2B-LUT1 is `READY` |
| `STMT-G2B-LUT0` | G2B-LUT0 resource-architecture review is accepted | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; architecture review, inventory, plan, targets, and proposal at `a70c55e...` | Engineering `PASS`; blocked G2B 21,412/20,800 LUT; separable R1i fix; reversible Plan B | Acceptance authorizes architecture only; no source profile, achieved target, timing, bitstream, or hardware result |
| `STMT-BUILD-PROFILES` | PRODUCT and RESEARCH_DIAGNOSTIC are authorized but not implemented; functional and external product semantics must be identical | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; build-profile proposal and recommended plan | Reversible separation of qualified function from research observability | RESEARCH_DIAGNOSTIC post-G2B build/route is not proven; implementation mechanism remains for G2B-LUT1 |
| `STMT-PRODUCT-LUT-POLICY` | PRODUCT routed LUT hard gate is `<=90%`, preferred target is `80–85%` | `FROZEN` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; resource targets | Point estimate 17,512 LUT / 84.192%, planning range and required recovery | Estimate is not qualification evidence; target is not achieved until actual post-route measurement |
| `STMT-G2B-IMPL` | G2B-IMPL is `BLOCKED_RESOURCE_HEADROOM`; G2B-LUT1 is `READY` to resolve the blocker | `BLOCKED` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; main review and recommended plan | Current blocked resource result and implementation-ready recovery architecture | G2B remains not offline-qualified; no bitstream or hardware proof |
| `STMT-G2A` | G2A is active/in progress | `ACTIVE` | `META-0_TASK_DIRECTIVE` | No G2A package at evidence snapshot; local-only `integration/v41-r1i-gen2-g2a@22f15a6befe911172073e46a95d50b53afe1fc33` | Execution-time working context only; no published evidence commit | No result, build, or architecture promotion inferred |
| `STMT-R0` | R0 is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-R0`; `R0_STATE.json` and experiment plan at `aff7e32...` | Research design/protocol `PASS` | R0 evidence states R1 was not started at publication |
| `STMT-R1` | R-track lifecycle context remains active but execution state is `HOLD`; R2/R3 remain resumable and not closed | `ACTIVE` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0` instrumentation inventory/proposal plus preserved `EVID-R0` | Research instrumentation is separable and recoverable through RESEARCH_DIAGNOSTIC | No scientific closure, cancellation, supersession, branch modification, or research evidence deletion |
| `STMT-L0` | L0 is planned | `PLANNED` | `META-0_TASK_DIRECTIVE` | No L0/Linux/V4L2 package at snapshot | Owner-provided product direction only | No implementation status is claimed |
| `STMT-META0` | META-0 governance infrastructure is accepted by creation task | `ACCEPTED` | `META-0_TASK_DIRECTIVE` / `SSOT WRITE AUTHORIZED` | Revision-1 SSOT transaction | Authorization permits governance creation | No G/R/L result accepted by implication |
| `STMT-R1I-ID` | R1i exact source and artifact identity | `FROZEN` | `META-0_TASK_DIRECTIVE` | `EVID-R1I` source provenance/state; [FPGA commit](https://github.com/lukaszsudul/FPGA_AHD/commit/20c3323d79d3896edc586d6db1df7deee60f9e41) | Branch/tag peel, tree, LFS oid, bitstream digest | Bitstream bytes are not in the source commit tree |
| `STMT-R1I-BEHAVIOR` | R1i 0 NACK/error 0/video present; R1h 4/error 1/video absent; 60,000/60,000 | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-R1I` state, conclusion, measurements at `955ba0c...` | Controlled hardware observations | Qualified PoC only; not production |
| `STMT-R1I-LIMIT` | Thesis confirmed/strong pass but exact mechanism inconclusive | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-R1I` conclusion and limitations; `EVID-R0` | Scientific result and causal limitation | No sole root cause claimed |
| `STMT-PROTECTED` | NVP/I2C/MMIO/R1i telemetry behavior is protected | `FROZEN` | `META-0_TASK_DIRECTIVE` | `EVID-G0` protected behavior contract; `EVID-G1` architecture report | Exact product-preservation contract | Research instrumentation reduction is conditional |
| `STMT-XDMA-PRIMARY` | Primary donor is `v41/xdma-v40.1.0-base@c89e88...` | `FROZEN` | `META-0_TASK_DIRECTIVE` | `EVID-G0` donor receipt; donor annotated tag | Endpoint/control-plane donor identity and scope | Gen1 x1; no application C2H proof |
| `STMT-XDMA-SECONDARY` | Secondary donor is provenance-hardening only | `FROZEN` | `META-0_TASK_DIRECTIVE` | `EVID-G0` donor receipt and diff receipt | Exact `8464af...` identity and one-file delta | Adoption remains provisional/reviewed |
| `STMT-INHERITANCE` | R1i already inherits required XDMA substrate | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1` architecture report at `f1258ba...` | Git ancestry/blob comparison and conflict plan | Future integration starts from R1i |
| `STMT-PCIE` | Gen2 x1 or better and `>=288 MB/s/card` are frozen requirements | `FROZEN` | `META-0_TASK_DIRECTIVE` | `EVID-G0` throughput contract; `EVID-G1` budget/feasibility | Gen1 impossibility and Gen2 planning feasibility | Gen2 and throughput not qualified |
| `STMT-VIDEO` | 1080p25, 4 inputs/card, max 2 active/card, 2 planned cards/host | `FROZEN` | `META-0_TASK_DIRECTIVE` | G0/G1 support per-card inputs/concurrency; two-card direction is Owner input | Per-card architecture and planning assumptions | Two-card operation not qualified |
| `STMT-C2H-ARCH` | One C2H/card, two private four-record rings, shared engine, record RR | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1` C2H and two-channel architecture at `f1258ba...` | Selected G1 architecture and scheduler model | Second ingress and implementation not qualified |
| `STMT-ABI` | `AHD_C2H_TRANSPORT_ABI_V1`, version 1, is lifecycle `FROZEN` with semantic state `FROZEN_FOR_G2B`; geometry is 4096/64/3840/192 bytes | `FROZEN` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; normative ABI Markdown/JSON and consistency report at `e8ab101...` | Exact header, UYVY line payload, zero padding, sequence/epoch, ownership, loss, reset, and 64-bit AXI mapping | Frozen contract is not implemented transport or hardware proof |
| `STMT-G2B-MMIO` | G2B MMIO contract `0x3800..0x3BFF` is frozen; all legacy behavior through `0x37FF` remains protected | `FROZEN` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; normative MMIO Markdown/CSV at `e8ab101...` | Exact capability, control/status, counter, snapshot, and error semantics | Implementation is `NOT_IMPLEMENTED`; hardware is `NOT_PROVEN`; no current build may advertise it |
| `STMT-LINUX-TRANSPORT-INPUT` | Linux consumer contract is frozen as the transport input contract for `AHD_C2H_TRANSPORT_ABI_V1` | `FROZEN` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; Linux consumer contract and ABI artifacts at `e8ab101...` | Parser validation for ABI/version, record boundaries, sequence, epoch, and zero padding | V4L2, DMABUF, timestamping, persistent identity, and multi-card policy remain not implemented or open |
| `STMT-OD-06-CLOSURE` | Tracked decision `OD-06 / Final C2H transport ABI` is closed by the accepted G2B-PRE contract, including all 15 technical closure groups | `ACCEPTED` | `META-2_TASK_DIRECTIVE` | `EVID-G2B-PRE`; decision log closure matrix at `e8ab101...` | Final values for sequences, epoch, identity, payload/padding, ownership/reset, MMIO, coherency, errors, and compatibility | This closes only OD-06; OD-01..OD-05 and OD-07..OD-10 remain open |
| `STMT-APP-DMA` | Endpoint/MMIO/AXI-Lite proven; application C2H and DMA qualification absent | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-GM1` inventory; `EVID-G0` data-plane gap/donor receipt; `EVID-G1` | Proven control plane and documented tied-off C2H | Enumeration/nonzero bytes are insufficient |
| `STMT-INTERFACES` | Identity words, BAR structure, legacy MMIO, R1i page, and the G2B extension contract are authoritative | `FROZEN` | `META-0_TASK_DIRECTIVE`; `META-2_TASK_DIRECTIVE` for the G2B extension only | G-1 document index, [donor AXI-Lite map](https://github.com/lukaszsudul/FPGA_AHD/blob/c89e88bcdf389614c884fb129e8b2d42a585bccb/docs/v41/phase3/AXI_LITE_REGISTER_MAP.md), R1i source `20c332...`, and `EVID-G2B-PRE` MMIO artifacts | Exact legacy values/ranges, preservation rule, and frozen G2B extension contract | The G2B extension remains not implemented and not hardware-qualified |
| `STMT-RESOURCES` | R1i qualified resource result remains historical; G2A is 18,178 routed LUT, blocked G2B is 21,412 post-opt LUT, and PRODUCT is estimated at 17,512 LUT / 84.192% | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-G1` for qualified R1i; `EVID-G2B-LUT0` for G2A/G2B attribution and estimates | Exact reported values, stage warning, 3,900 LUT estimate with 3,500–4,300 range | PRODUCT estimate is not an achieved or post-route-qualified result |
| `STMT-RESEARCH` | R-track research remains valid and resumable under state `HOLD`; RESEARCH_DIAGNOSTIC preserves its observability | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-R0` experiment plan/matrix; `EVID-G2B-LUT0` inventory/profile proposal | Controlled research purpose and reproducible observability boundary | R2/R3 scientific closure remains open and no branch/evidence is modified |
| `STMT-OD-03-CLOSURE` | Resource-architecture question is decided by PRODUCT + RESEARCH_DIAGNOSTIC, with implementation pending | `ACCEPTED` | `META-3_TASK_DIRECTIVE` | `EVID-G2B-LUT0`; main review, recommended plan, build-profile proposal | Safest resource-recovery architecture without R1i/ABI/MMIO/G2B architecture changes | Actual LUT, timing, hardware, and R2/R3 closure remain open |
| `STMT-LINUX` | V4L2/common core/transport abstraction/XDMA-first direction | `PLANNED` | `META-0_TASK_DIRECTIVE` | No matching evidence package at snapshot | Owner/Architect-approved planned direction | No driver/frontend/backend implementation claimed |
| `STMT-GOV` | Only authorized META writer after explicit Owner decision may update SSOT | `FROZEN` | `META-0_TASK_DIRECTIVE` / `SSOT WRITE AUTHORIZED` | `GOVERNANCE.md` and `UPDATE_POLICY.md` in revision 1 | Governance authorization itself | Future governance change needs new accepted META revision |

## Evidence usage rule

A future META agent must verify the exact evidence commit and cited directory,
not merely current branch HEAD. If later evidence contradicts or supersedes a
statement, the old project truth remains current until the Owner/Architect
issues an explicit decision and a separate authorized META update increments
the revision.
