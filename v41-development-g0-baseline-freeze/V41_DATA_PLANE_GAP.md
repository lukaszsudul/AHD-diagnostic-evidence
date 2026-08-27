# AHD v41 Existing Data-Plane Gap

## Frozen G0 finding

The primary XDMA donor contains a PCIe endpoint and an exposed C2H IP interface, but it does **not** contain a working application DMA data plane. The application-side C2H data inputs are effectively unimplemented or tied inactive, and no application DMA payload has been proven.

The missing end-to-end function is:

`record/video data -> record-to-AXI-Stream adapter -> XDMA C2H -> host receive/correctness tooling`

## What existing evidence establishes

For `v41/xdma-v40.1.0-base` at `c89e88bcdf389614c884fb129e8b2d42a585bccb`, accepted evidence establishes the XDMA endpoint, one C2H interface, mandatory H2C interface, AXI-Lite bridge, MMIO/control-status and BAR architecture, PCIe enumeration, driver loading, and BAR/identity/scratch access.

Those control-plane and link observations do not establish application DMA functionality or payload correctness.

## Gap status

| Capability | G0 status |
|---|---|
| C2H IP interface exists | PRESENT |
| Application C2H producer/adapter | MISSING / UNIMPLEMENTED |
| One-channel application DMA | MISSING / UNPROVEN |
| Two-channel application DMA | MISSING |
| Host receive and correctness tooling | MISSING / UNPROVEN FOR APPLICATION PAYLOAD |
| Sustained 288 MB/s application payload | UNPROVEN |

PCIe enumeration must never be reported as completed XDMA application functionality. Driver loading and successful MMIO likewise do not close this gap.

## Gate boundary

G0 records the gap; it does not design or implement its resolution. The exact data-path and Gen2-capable integration design belongs to G1, with implementation deferred to later gates.
