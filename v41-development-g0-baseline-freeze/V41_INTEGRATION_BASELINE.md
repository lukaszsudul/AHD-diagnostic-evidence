# AHD v41 Integration Baseline

## Status and scope

This document freezes the authoritative conceptual inputs to AHD v41 integration at Gate G0. It does not perform integration, select an implementation mapping, modify XDMA configuration, or qualify hardware.

## Authoritative source inputs

### NVP/I2C functional source

- Qualified source state: R1i
- Original historical commit identity: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Exact qualified tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- Qualified bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`
- Preservation branch: `baseline/v41-r1i-qualified-poc`
- Immutable tag: `v41-r1i-qualified-poc-20260827`
- Scientific state: `THESIS_CONFIRMED`, `STRONG_PASS`, `QUALIFIED_POC_BASELINE`
- Exact low-level mechanism: `INCONCLUSIVE`

G0 verified that the preservation branch points directly to the original historical commit and resolves to the exact qualified tree above. No preservation-wrapper commit was required.

R1i behavior is governed by `V41_R1I_PROTECTED_BEHAVIOR_CONTRACT.md`. Independent R-track experiments and candidates are not G-track baseline inputs.

### PCIe/XDMA/control-plane source

- Primary donor branch: `v41/xdma-v40.1.0-base`
- Primary donor HEAD: `c89e88bcdf389614c884fb129e8b2d42a585bccb`
- Immutable donor tag: `v41-xdma-primary-donor-g0-20260827`
- Functional Phase-1 anchor: `fd32fcb65be3f1a59c569874195d1faeaf7d27e9`
- Hardware Phase-2 acceptance anchor: `9306c25a48dedd2372bf5d06e37344ae2aa3e85a`

This donor supplies the proven PCIe endpoint, one C2H interface, mandatory H2C interface, AXI-Lite bridge, MMIO/control-status architecture, BAR architecture, single-input video/record context, constraints/build infrastructure, and host validation procedures. Its accepted evidence covers PCIe enumeration, driver loading, and BAR/identity/scratch access. It does not prove an application DMA data plane.

### Optional provenance-hardening input

- Secondary donor branch: `dev/v41-xdma-offline-next`
- Secondary donor HEAD: `8464af66611f7c22b8a36a4aab915d598eedda3f`
- Role: `SECONDARY_DONOR`, `PROVENANCE_HARDENING_ONLY`, `REQUIRES_REVIEW_BEFORE_ADOPTION`
- Candidate delta location: `scripts/v41/phase3_build.tcl`

Only the reviewed hunks identified in the G0 secondary-donor diff receipt may be considered by G1. No secondary-donor change is adopted by this baseline.

The branches `v41/xdma` and `archive/v41-xdma-pre-v40.1.0-20260817` remain history/reference sources, not primary implementation donors.

## Frozen product architecture requirements

- Physical video inputs: **4**
- Maximum simultaneously active video inputs: **2**
- Required sustained application payload: **at least 288 MB/s**, where MB/s is decimal
- Current donor configuration: **PCIe Gen1 x1**
- Current donor meets the throughput requirement: **NO**
- Minimum v41 target link class: **PCIe Gen2 x1, or another configuration proven to sustain at least 288 MB/s of application payload**
- Preferred current target: **PCIe Gen2 x1**

PCIe Gen1 x1 is retained only as the legacy/proven donor configuration. Its raw post-8b/10b ceiling is 250 MB/s before protocol overhead, so it is prohibited as the final v41 throughput configuration.

## Composition rule

G1 shall design the exact integration using qualified R1i as the NVP/I2C functional authority and the frozen primary donor as the PCIe/XDMA/control-plane authority. The protected R1i behaviors, legacy MMIO compatibility through `0x35FF`, and the registered conflict boundaries are mandatory design constraints. G1 may review—but shall not automatically adopt—the recorded secondary-donor provenance-hardening delta.

No implementation conflict is resolved by this document. No source integration occurred at G0.
