# AHD Active Baselines and Working Identities

`PROJECT_STATE_REV = 2`

This page distinguishes accepted/frozen baselines from active or provisional
working branches. Branch existence is provenance; it does not confer
acceptance.

## Qualified FPGA baseline — R1i

| Field | Verified value |
|---|---|
| Name | `R1i` |
| Lifecycle status | `ACCEPTED` |
| Preservation status | `FROZEN` |
| Scope | `QUALIFIED_POC_BASELINE` |
| Source repository | `lukaszsudul/FPGA_AHD` |
| Preservation branch | `baseline/v41-r1i-qualified-poc` |
| Historical commit | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Qualified tree | `70d801fd7a879080da399bfa9ee95fd6eb008e16` |
| Annotated tag | `v41-r1i-qualified-poc-20260827` |
| Tag object | `f7847a259dbe43bf99fa6d6515ed85131fafffc0` |
| Qualified bitstream SHA-256 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` |
| LFS object size | `2,192,144 bytes` |
| Scientific result | `THESIS_CONFIRMED` |
| Frozen outcome | `STRONG_PASS` |
| Exact causal mechanism | `INCONCLUSIVE` |
| Production qualification | `NOT_CLAIMED` |
| Accepted by role | `OWNER_ARCHITECT` |

Verification at META-0 execution established that the remote preservation
branch and peeled annotated tag resolve to the historical commit, and that the
commit's tree is the qualified tree. The public evidence LFS pointer identifies
the bitstream by the exact SHA-256 above. The source commit itself does not
contain the bitstream bytes.

Authoritative evidence path:
`v41-nvp-r1i-r2-qualified-poc-hardware-evidence` at final path commit
`955ba0cd2462f4dec9dcb086175ab6eca57365bb`.

### Proven behavior

- R1i: autonomous-init NACK = 0, `INIT_ERROR = 0`, video present.
- R1h control: autonomous-init NACK = 4, `INIT_ERROR = 1`, video absent.
- Post-init: 60,000 of 60,000 selected-phase observations captured.
- Scope remains qualified PoC; exact causality and production qualification
  are not claimed.

## Primary XDMA donor

| Field | Verified value |
|---|---|
| Lifecycle status | `FROZEN` |
| Role | `PRIMARY_XDMA_DONOR` |
| Branch | `v41/xdma-v40.1.0-base` |
| HEAD | `c89e88bcdf389614c884fb129e8b2d42a585bccb` |
| Tree | `417820c69c134161fcafae0947dc5976919814d1` |
| Annotated tag | `v41-xdma-primary-donor-g0-20260827` |
| Tag object | `c834c1ea77d24fcc4d9b8e01ee7f4ed1e1754db1` |
| Current link | `PCIe Gen1 x1` |
| Accepted role | Proven endpoint/control-plane donor |
| Final throughput role | Not the final v41 throughput configuration |

The donor proves endpoint enumeration, XDMA driver load, BAR discovery,
AXI-Lite identity/status/scratch behavior, one C2H interface, and the
control-plane substrate. Application C2H is tied inactive and is not proven.

G1 establishes that qualified R1i already inherits the required donor
endpoint/control-plane substrate; future integration starts from R1i rather
than merging this donor over it.

Evidence:
`v41-development-g0-baseline-freeze` at
`b5efb25082d7d18c8e022142e2303fd8a7bc3c6d` and
`v41-development-g1-integration-architecture` at
`f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd`.

## Secondary XDMA donor

| Field | Verified value |
|---|---|
| Lifecycle status | `FROZEN` for provenance identity |
| Branch | `dev/v41-xdma-offline-next` |
| HEAD | `8464af66611f7c22b8a36a4aab915d598eedda3f` |
| Tree | `4bf1988785baf4bae46bdfaf5bb12d0d25f26e68` |
| Role | `PROVENANCE_HARDENING_ONLY` |
| Adoption state | `PROVISIONAL`; review required before adoption |

This branch is not an alternative functional baseline. No separate hardware
run qualifies it.

## Active integration context

| Branch / work context | HEAD at META-0 audit | Status | Authority boundary |
|---|---|---|---|
| `integration/v41-r1i-gen2-g2a` | `22f15a6befe911172073e46a95d50b53afe1fc33` | `ACTIVE` | Local linked-worktree branch; no upstream or matching advertised remote ref; not accepted |
| G2A evidence package | none on evidence `main` at `f1258ba...` | `ACTIVE` | Absence of package does not negate Owner-declared in-progress state; no result promoted |

The observed integration head is a direct child of R1i with subject
`Integrate qualified R1i with Gen2 x1 for G2A offline build`. Its presence
does not establish a build result or acceptance. META-0 did not inspect,
modify, build, or otherwise interfere with the active G2A worktree.

## Accepted G2B-PRE contract baseline

| Field | Current accepted value |
|---|---|
| Lifecycle status | `ACCEPTED` |
| Scope | `ARCHITECTURE_CONTRACT_FREEZE_ONLY` |
| Transport ABI | `AHD_C2H_TRANSPORT_ABI_V1`, version 1, `FROZEN_FOR_G2B` |
| G2B MMIO contract | `FROZEN`, `0x3800..0x3BFF` |
| Linux consumer contract | `FROZEN_INPUT_CONTRACT` for transport parsing only |
| G2B implementation readiness | `READY`; RTL/data plane remains `NOT_IMPLEMENTED` |
| Hardware qualification | `NOT_STARTED`; G2B hardware remains `NOT_PROVEN` |
| Evidence | `v41-development-g2b-pre-c2h-abi-mmio-freeze` at `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |

This accepted contract baseline does not promote a source branch, bitstream,
DMA result, Gen2 negotiation result, throughput result, or Linux/V4L2
implementation. G2A remains `ACTIVE`; implementation execution remains a
separate later gate.

## Active research context

| Branch / work context | HEAD at META-0 audit | Status | Authority boundary |
|---|---|---|---|
| `research/v41-r1i-causal-isolation` | `20c3323d79d3896edc586d6db1df7deee60f9e41` | `ACTIVE` | Local R1 umbrella branch; no upstream; research only |
| `research/v41-r1i-a` | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` | `PROVISIONAL` | Local implemented-unqualified candidate; not product baseline |
| `research/v41-r1i-b` | `e4d10bb8e85e3797d078144fd0965e9625ee727c` | `PROVISIONAL` | Local implemented-unqualified candidate; not product baseline |
| R1 evidence package | none on evidence `main` at `f1258ba...` | `ACTIVE` | No execution result is represented or accepted |

The candidate branches are local-only at the audit point and have no matching
advertised remote refs. R1i-a/R1i-b are research-only. They may not replace or
modify the accepted product baseline without explicit Owner/Architect
promotion and a separate authorized META update.

## Source-repository audit anchor

The read-only primary source worktree was clean on `main` at
`be94f88ee8d179f12928ab791bdae27c22cd1762`, tree
`e128ff47a5e21e8131971f5e5caa7657e2eccc7f`. This is an audit context, not the
qualified v41 baseline.
