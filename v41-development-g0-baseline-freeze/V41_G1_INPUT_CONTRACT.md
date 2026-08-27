# AHD v41 G1 Input Contract

## Purpose

This document freezes the complete input package required before G1 may begin. It authorizes no G1 work and performs no integration.

## Required source identities

### Qualified R1i

- Original historical commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Exact qualified tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- Preservation branch: `baseline/v41-r1i-qualified-poc`
- Immutable tag: `v41-r1i-qualified-poc-20260827`
- Qualified bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`

G0 verified that the preservation ref points directly to the original historical commit and resolves to the exact qualified tree. No preservation-wrapper commit was used; G1 shall reverify both identities on entry.

### Primary XDMA donor

- Branch: `v41/xdma-v40.1.0-base`
- HEAD: `c89e88bcdf389614c884fb129e8b2d42a585bccb`
- Immutable donor tag: `v41-xdma-primary-donor-g0-20260827`
- Functional Phase-1 anchor: `fd32fcb65be3f1a59c569874195d1faeaf7d27e9`
- Hardware Phase-2 acceptance anchor: `9306c25a48dedd2372bf5d06e37344ae2aa3e85a`

### Secondary donor

- Branch: `dev/v41-xdma-offline-next`
- HEAD: `8464af66611f7c22b8a36a4aab915d598eedda3f`
- Frozen role: `SECONDARY_DONOR`, `PROVENANCE_HARDENING_ONLY`, `REQUIRES_REVIEW_BEFORE_ADOPTION`
- Review scope: the exact `scripts/v41/phase3_build.tcl` hunks recorded in the G0 secondary-donor diff receipt

No secondary-donor hunk is adopted merely because it is present in the receipt. G1 must record an adopt/reject decision and rationale for each in-scope provenance-hardening portion.

## Mandatory G1 documents

G1 shall receive and verify all of the following:

1. Qualified R1i preservation receipt, preserved branch, and immutable tag
2. Primary XDMA donor receipt, donor ref, and immutable donor tag
3. Secondary provenance-hardening patch/diff receipt
4. `V41_R1I_PROTECTED_BEHAVIOR_CONTRACT.md`
5. `V41_INTEGRATION_BASELINE.md`
6. `V41_G0_INTEGRATION_CONFLICT_REGISTER.csv`
7. `V41_PCIE_GEN2_FEASIBILITY_AUDIT.md`
8. `V41_PCIE_THROUGHPUT_ARCHITECTURE_CONTRACT.md`
9. `V41_288MBPS_ACCEPTANCE_CONTRACT.md`
10. `V41_DATA_PLANE_GAP.md`
11. The accepted G-1 reuse matrix from evidence directory `v41-development-g-minus-1-existing-work-inventory` at publication commit `654b9adf7d02cbf8946e420538955ffaaeae7eb2`
12. The R1i qualification evidence from `v41-nvp-r1i-r2-qualified-poc-hardware-evidence` at publication commit `955ba0cd2462f4dec9dcb086175ab6eca57365bb`

## Frozen product constraints passed to G1

- Four physical video inputs
- At most two simultaneously active video inputs
- At least 288 MB/s sustained application payload, measured in decimal MB/s
- PCIe Gen1 x1 prohibited as the final v41 throughput configuration
- PCIe Gen2 x1 preferred and required at minimum, unless another configuration is proven to sustain at least 288 MB/s application payload
- Qualified R1i protected behavior and legacy MMIO compatibility through `0x35FF` preserved
- R1i telemetry page `0x3600-0x367F` preserved
- Existing application data-plane gap explicitly open

## G1 mission boundary

After all inputs are verified, G1's mission is to design the exact R1i/XDMA integration and the exact Gen2-capable XDMA transition. G1 shall resolve the registered design decisions on paper without implementation.

This G0 package does not authorize source integration, XCI modification, building, Vivado execution, hardware access, or throughput testing.
