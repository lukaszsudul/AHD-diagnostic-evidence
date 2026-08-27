# AHD Current-State Evidence Map

`PROJECT_STATE_REV = 1`
Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`
Evidence `main` snapshot inspected before SSOT creation:
`f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd`

## Acceptance rule

Evidence proves execution, measurement, build, observation, or documented
architecture input. It does not prove Owner/Architect acceptance. For every
`ACCEPTED`, `REJECTED`, `SUPERSEDED`, or `BLOCKED` project-truth statement,
the decision basis must be explicit.

Revision 1 uses `META-0_TASK_DIRECTIVE` as the Owner/Architect decision basis.
That directive explicitly identifies the supplied current state as approved
input and authorizes only initial SSOT creation. Evidence packages support the
facts but do not auto-promote their `PASS` results.

## Authoritative evidence packages

| Evidence ID | Directory | Latest path commit | Original payload/add commit | Current subtree |
|---|---|---|---|---|
| `EVID-R1I` | [v41-nvp-r1i-r2-qualified-poc-hardware-evidence](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/955ba0cd2462f4dec9dcb086175ab6eca57365bb/v41-nvp-r1i-r2-qualified-poc-hardware-evidence) | `955ba0cd2462f4dec9dcb086175ab6eca57365bb` | `c1c552fa4fc693d6c375db9478abecd7960ec3ce` | `04f5c0f311b3a5c7ad6db981195ecb3476355f72` |
| `EVID-GM1` | [v41-development-g-minus-1-existing-work-inventory](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/654b9adf7d02cbf8946e420538955ffaaeae7eb2/v41-development-g-minus-1-existing-work-inventory) | `654b9adf7d02cbf8946e420538955ffaaeae7eb2` | `510cb2ead5dc49d36031b745022742f912b54e77` | `5a1b83879ace86c03a029f584a50163f163c73bf` |
| `EVID-G0` | [v41-development-g0-baseline-freeze](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/b5efb25082d7d18c8e022142e2303fd8a7bc3c6d/v41-development-g0-baseline-freeze) | `b5efb25082d7d18c8e022142e2303fd8a7bc3c6d` | `64eca0cfbb76593d7e875df7b3271651668cbe61` | `5313caf2f15335510b2e264abb19e8ef1c7a8d42` |
| `EVID-G1` | [v41-development-g1-integration-architecture](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd/v41-development-g1-integration-architecture) | `f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd` | `221f65aef9664a6d6ad35c3ec7644badd69ba381` | `5c81b36b96841ca76d135c3d737c8abc91372e88` |
| `EVID-R0` | [v41-research-r0-r1i-causal-isolation-design](https://github.com/lukaszsudul/AHD-diagnostic-evidence/tree/aff7e32edc1cf71bde95b6c19e54e6f307764237/v41-research-r0-r1i-causal-isolation-design) | `aff7e32edc1cf71bde95b6c19e54e6f307764237` | `aff7e32edc1cf71bde95b6c19e54e6f307764237` | `5a9c08d9c48ac2e3ef7e0d79e189c8bdd2dbeaa9` |

Later receipt commits are used as `source_evidence_commit` because they contain
the final cited path state. Payload commits are retained to explain
self-reference-free publication receipts.

The execution-time scan found no newer top-level G2A, R1, L0, Linux, or V4L2
package. The latest package was G1. Newer evidence, when it appears, still will
not imply acceptance.

## Statement-level provenance

| Statement ID | Current-state statement | Status | Owner/Architect decision basis | Evidence and immutable commit | What evidence supports | Boundary |
|---|---|---|---|---|---|---|
| `STMT-GM1` | G-1 is current accepted product history/inventory | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-GM1`; `STATE.json` and inventory report at `654b9ad...` | Engineering inventory `PASS`, source/donor context | Evidence `PASS` alone did not accept G-1 |
| `STMT-G0` | G0 baseline freeze is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G0`; `V41_G0_STATE.json` and freeze report at `b5efb25...` | Exact R1i/donor identities and requirements | Acceptance supplied separately |
| `STMT-G1` | G1 architecture is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1`; `V41_G1_STATE.json` and architecture report at `f1258ba...` | `G2_IMPLEMENTATION_ALLOWED` and integration/C2H design | Does not accept G2 execution or throughput |
| `STMT-G2A` | G2A is active/in progress | `ACTIVE` | `META-0_TASK_DIRECTIVE` | No G2A package at evidence snapshot; local-only `integration/v41-r1i-gen2-g2a@22f15a6befe911172073e46a95d50b53afe1fc33` | Execution-time working context only; no published evidence commit | No result, build, or architecture promotion inferred |
| `STMT-R0` | R0 is accepted | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-R0`; `R0_STATE.json` and experiment plan at `aff7e32...` | Research design/protocol `PASS` | R0 evidence states R1 was not started at publication |
| `STMT-R1` | R1 is active/in progress | `ACTIVE` | `META-0_TASK_DIRECTIVE` | No R1 package at evidence snapshot; local-only candidates `R1i-a@8b8ec0fa9c22965e46d0421c25e63d83e7971597` and `R1i-b@e4d10bb8e85e3797d078144fd0965e9625ee727c` | Execution-time working context only; no published evidence commit | Candidates are research-only and not product truth |
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
| `STMT-ABI` | v41D 4096/~3840 record plan and transport ABI are provisional | `PROVISIONAL` | `META-0_TASK_DIRECTIVE` | `EVID-G1` C2H/MMIO plans | Concrete record/header/AXIS proposal | Owner directive prevents treating it as fully frozen |
| `STMT-APP-DMA` | Endpoint/MMIO/AXI-Lite proven; application C2H and DMA qualification absent | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-GM1` inventory; `EVID-G0` data-plane gap/donor receipt; `EVID-G1` | Proven control plane and documented tied-off C2H | Enumeration/nonzero bytes are insufficient |
| `STMT-INTERFACES` | Identity words, BAR structure, legacy MMIO, R1i page are authoritative | `FROZEN` | `META-0_TASK_DIRECTIVE` | G-1 document index, G1 MMIO plan, and [donor AXI-Lite map](https://github.com/lukaszsudul/FPGA_AHD/blob/c89e88bcdf389614c884fb129e8b2d42a585bccb/docs/v41/phase3/AXI_LITE_REGISTER_MAP.md); R1i source `20c332...` | Exact values/ranges and preservation rule | G2 extension pages remain provisional |
| `STMT-RESOURCES` | R1i routed 18181 LUT, 20083 FF, 26 BRAM; diagnostics substantial | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-G1` resource decomposition/headroom policy | Routed utilization and accepted interpretation | Exact removable LUT count unknown; not production expectation |
| `STMT-RESEARCH` | R-track studies SCL qualification, ACK sampling, combined/recovery effects | `ACCEPTED` | `META-0_TASK_DIRECTIVE` | `EVID-R0` experiment plan/matrix | Controlled question and variants | Research truth cannot auto-modify product truth |
| `STMT-LINUX` | V4L2/common core/transport abstraction/XDMA-first direction | `PLANNED` | `META-0_TASK_DIRECTIVE` | No matching evidence package at snapshot | Owner/Architect-approved planned direction | No driver/frontend/backend implementation claimed |
| `STMT-GOV` | Only authorized META writer after explicit Owner decision may update SSOT | `FROZEN` | `META-0_TASK_DIRECTIVE` / `SSOT WRITE AUTHORIZED` | `GOVERNANCE.md` and `UPDATE_POLICY.md` in revision 1 | Governance authorization itself | Future governance change needs new accepted META revision |

## Evidence usage rule

A future META agent must verify the exact evidence commit and cited directory,
not merely current branch HEAD. If later evidence contradicts or supersedes a
statement, the old project truth remains current until the Owner/Architect
issues an explicit decision and a separate authorized META update increments
the revision.
