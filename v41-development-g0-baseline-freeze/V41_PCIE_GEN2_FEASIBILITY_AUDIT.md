# AHD v41 PCIe Gen2 x1 Feasibility Audit

## Audit result

`LIKELY_FEASIBLE_NEEDS_G1_VALIDATION`

This is a read-only architecture audit. It is not hardware qualification and it does not claim that Gen2 trains, routes, closes timing, moves DMA payload, or sustains 288 MB/s. G0 did not edit the XCI, run Vivado, build, or access hardware.

## Evidence summary

| Area | Existing evidence | G0 finding |
|---|---|---|
| FPGA device | `xc7a35tcsg325-2` in donor scripts/XCI; one `PCIE_2_1` hard block at `X0Y0` | Device class and -2 speed grade are compatible with a Gen2 x1 candidate |
| XDMA IP | XDMA 4.2 revision 2; current generated maximum speed is Gen1, width x1 | IP/device family supports a Gen2 x1 target, but the committed XCI does not configure it |
| Lane routing | One RX pair G4/G3 and one TX pair B2/B1; `GTPE2_CHANNEL_X0Y3`, `GTPE2_COMMON_X0Y0`, `PCIE_X0Y0` | One electrical lane is routed and already works at Gen1; no wider link is evidenced |
| Connector/PCB | No schematic, layout, connector declaration, or SI/compliance artifact in the repository | Mechanical lane count and 5 GT/s channel margin are not proven |
| Reference clock | D6/D5 differential reference; `IBUFDS_GTE2_X0Y0`; constrained at 100 MHz | Standard reference-clock architecture exists; Gen2 operation remains unvalidated |
| Reset | C8 active-low PERST, LVCMOS33 pull-up, direct input buffer to XDMA dedicated active-low reset | Functional reset path is proven at Gen1; Gen2/link-reset behavior needs validation |
| Host/slot | Accepted host evidence identifies ASUS Pro B650M-CT / Ryzen 8600G and current 2.5 GT/s x1 operation | Platform generation is plausibly sufficient, but the exact root-port `LnkCap` and a 5 GT/s negotiation receipt are absent |
| Constraints | Active `xdma_pcie.xdc` plus `pcie_pio.xdc` bind clock/reset/lane/hard-block sites | Existing bindings align with the x1 target; no Gen2 implementation evidence exists |
| Application interface | 64-bit AXI4-Stream at nominal 62.5 MHz | Conceptual 500 MB/s fabric byte-rate matches Gen2 x1 raw ceiling, but it is not payload proof |
| Resources | Qualified R1i approximately 18,181/20,800 LUT, 87.41% | About 12.59% LUT headroom makes adapter, buffering and two-channel closure a material risk |

## Device and IP capability

The donor XCI identifies XDMA 4.2 revision 2 for Artix-7 `XC7A35T-CSG325-2`, block `X0Y0`, one lane, 100 MHz reference, dedicated active-low PERST, and a 64-bit/62.5 MHz AXI stream. The current `PL_LINK_CAP_MAX_LINK_SPEED` is Gen1 and remains untouched.

AMD's Series-7 PCIe documentation lists the XC7A35T -2 class as supporting Gen2 x1 through x4 and identifies `GTPE2_CHANNEL_X0Y3` as the recommended X0Y0 x1 mapping for the CSG325 package; that is the site already constrained by the donor. AMD's XDMA 4.2 documentation likewise lists 7-series Gen2 x1 support for the applicable speed grade.

Primary references:

- [AMD PG054 minimum device requirements](https://docs.amd.com/r/en-US/pg054-7series-pcie/Minimum-Device-Requirements)
- [AMD PG054 Artix-7 GT mapping](https://docs.amd.com/r/en-US/pg054-7series-pcie/Artix-7-Devices)
- [AMD PG195 XDMA minimum device requirements](https://docs.amd.com/r/en-US/pg195-pcie-dma/Minimum-Device-Requirements)

This establishes architectural plausibility, not a generated or qualified v41 configuration.

## Board lane, connector and signal-integrity boundary

`xdc/boards/current/pcie_pio.xdc` and the top-level port widths prove exactly one routed RX/TX lane. That lane has accepted Gen1 hardware evidence. No second lane is routed or evidenced in the source package.

The repository contains no PCB schematic, PCB layout, mechanical connector-form-factor declaration, insertion-loss budget, impedance/crosstalk analysis, or Gen2 compliance result. Therefore G0 cannot prove the physical channel at 5 GT/s or independently state the connector's mechanical width. These absences prevent `FEASIBLE_FROM_EXISTING_EVIDENCE`, but they do not demonstrate that a PCB change is required.

Gen2 x1 is the only presently evidenced no-PCB candidate. If measured Gen2 x1 cannot sustain 288 MB/s, a wider-link fallback is not established by current board evidence and may require PCB redesign.

## Clock and reset constraints

The 100 MHz differential reference clock is explicitly constrained. PERST is a dedicated active-low path from package pin C8 through an input buffer to the XDMA core, with accepted Gen1 reset behavior.

The qualified top describes the nominal 62.5 MHz XDMA `axi_aclk` as free-running, while XDMA documentation defines it as PCIe-derived and unavailable under portions of reset/link lifecycle. Accepted evidence measured approximately 62.383 MHz but did not fully resolve lifecycle behavior. G1 must preserve and revalidate the R1i rule that NVP power/reset/autoinit is independent of PCIe link-up and AXI reset.

Reference: [AMD PG195 clocking and resets](https://docs.amd.com/r/en-US/pg195-pcie-dma/Clocking-and-Resets).

## Host capability boundary

The accepted host record proves the current endpoint only at 2.5 GT/s x1. The host platform identity is compatible with slots newer than Gen2 according to its manufacturer specification, but the exact root-port `LnkCap`, slot wiring used, BIOS policy, ASPM policy, IOMMU effects and 5 GT/s negotiated result are not frozen evidence.

Reference: [ASUS Pro B650M-CT specifications](https://www.asus.com/motherboards-components/motherboards/business/pro-b650m-ct-csm/techspec/).

Legacy `host/v41/phase2_xdma_validate.sh` explicitly requires `2.5 GT/s` and width 1. That remains historical donor evidence. G1 must inventory the future validation transition to an expected negotiated 5.0 GT/s x1 without editing it in G0.

## Throughput feasibility constraints

Gen2 x1 transports 5 GT/s with 8b/10b encoding, producing a 500 MB/s raw post-encoding byte-rate ceiling. The product requirement of 288 MB/s therefore requires at least `288/500 = 57.6%` end-to-end application-payload efficiency.

That efficiency must include the actual TLP/DLLP/flow-control, descriptor, DMA engine, host driver, memory, scheduling and application costs. It also depends on payload sizing, outstanding work, host buffers and record packing. Current endpoint evidence reports MaxPayload 256 bytes and MRRS 512 bytes, which are measurement-sensitive inputs rather than proof.

Seven-series Gen2 host AXI bypass/register accesses are limited to one DWORD in the XDMA documentation. This does not limit the C2H streaming data plane, but G1 must retain the 32-bit control/MMIO contract and must not infer burst MMIO capability.

Reference: [AMD PG195 7-series Gen2 limitations](https://docs.amd.com/r/en-US/pg195-pcie-dma/Others).

## Missing proof and required later validation

The following prevent a stronger feasibility conclusion:

- no Gen2-configured XCI or complete Gen2 property audit
- no Gen2 synthesis, route, timing, DRC, CDC or clock/reset validation
- no 5 GT/s x1 training, error-counter, recovery or reset evidence
- no board/connector/SI evidence at 5 GT/s
- no frozen exact host root-port capability receipt
- no application C2H data path or host correctness tool
- no one-channel or two-channel DMA evidence
- no two-active-channel buffering/backpressure proof
- no 288 MB/s application-payload measurement
- limited LUT headroom in the qualified R1i design

## G1 feasibility inputs

G1 must define, on paper only, the exact Gen2-capable XDMA transition and validation plan; preserve the exact R1i clock/reset/start/final-settle behavior; audit every effective XCI property; update future link-speed expectations; retain 32-bit MMIO semantics; and treat resource, buffering, host, PCB/SI and 57.6%-minimum efficiency as explicit risks.

## Conclusion

Existing device, hard-block, single-lane routing, reference-clock and reset evidence make Gen2 x1 without a PCB redesign plausible. Missing Gen2 configuration/implementation, PCB/SI and host-link proof prevent an unconditional feasibility claim. The correct G0 classification is `LIKELY_FEASIBLE_NEEDS_G1_VALIDATION`.
