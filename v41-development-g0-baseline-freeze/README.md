# AHD v41 G0 Baseline Freeze

Gate G0 establishes the immutable, auditable starting point for the AHD v41 development track. G-1 is accepted and is used as an input; it is not repeated here.

## Frozen baseline

- Qualified NVP/I2C source: original R1i commit `20c3323d79d3896edc586d6db1df7deee60f9e41`, exact tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- Permanent source branch: `baseline/v41-r1i-qualified-poc`
- Immutable R1i tag: `v41-r1i-qualified-poc-20260827`
- Primary XDMA donor: `v41/xdma-v40.1.0-base` at `c89e88bcdf389614c884fb129e8b2d42a585bccb`
- Immutable donor tag: `v41-xdma-primary-donor-g0-20260827`
- Secondary donor: `dev/v41-xdma-offline-next` at `8464af66611f7c22b8a36a4aab915d598eedda3f`, limited to `PROVENANCE_HARDENING_ONLY` and requiring review before adoption

## Frozen product architecture

- Four physical video inputs; no more than two simultaneously active inputs
- Required sustained application payload: **at least 288 MB/s decimal**
- PCIe Gen1 x1: legacy/proven donor configuration only and prohibited as the final v41 throughput configuration
- Minimum target: **PCIe Gen2 x1 or better**; preferred current target is Gen2 x1
- Gen2 x1 architecture feasibility: `LIKELY_FEASIBLE_NEEDS_G1_VALIDATION`

Gen2 x1 has a 500 MB/s raw post-8b/10b byte-rate ceiling, not a payload guarantee. Later acceptance requires measured sustained application payload of at least 288 MB/s with two concurrently active channels and all integrity/error conditions in the acceptance contract.

## Remaining data-plane gap

The XDMA IP exposes C2H, but the donor has no working application DMA path. The missing end-to-end function is:

`record/video data -> record-to-AXI-Stream adapter -> XDMA C2H -> host receive/correctness tooling`

One-channel application DMA is missing/unproven, two-channel DMA is missing, and 288 MB/s is unproven. PCIe enumeration, driver loading, and MMIO acceptance do not prove application DMA.

## G1 entry condition

G1 is ready only from the preserved R1i ref/tag, frozen XDMA donor ref/tag, reviewed secondary-donor diff receipt, all G0 contracts/registers, and the accepted G-1 reuse matrix. G1 may design the exact R1i/XDMA/Gen2 transition; it must not treat G0 as implementation.

G0 performed no integration, XDMA XCI modification, build, Vivado execution, throughput test, or hardware access.
