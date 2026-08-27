# AHD v41 PCIe Throughput Architecture Contract

## Frozen requirement

The AHD v41 product shall sustain **at least 288 MB/s of application payload**, measured at the application/host boundary in decimal megabytes per second.

The link architecture shall be **PCIe Gen2 x1 at minimum**, or another configuration demonstrated to sustain at least 288 MB/s of application payload under the separate acceptance contract. The preferred current target is PCIe Gen2 x1.

This requirement is not reduced or reinterpreted to fit the existing donor.

## Current donor classification

The frozen primary donor is `v41/xdma-v40.1.0-base` at `c89e88bcdf389614c884fb129e8b2d42a585bccb`. Its current PCIe configuration is Gen1 x1.

**PCIe Gen1 x1 is prohibited as the final v41 throughput configuration.** It remains only a legacy/proven donor configuration. At 2.5 GT/s with 8b/10b encoding, Gen1 x1 has a raw post-encoding byte-rate ceiling of 250 MB/s before PCIe protocol overhead. It therefore cannot satisfy a sustained 288 MB/s application-payload requirement.

## Gen2 interpretation

PCIe Gen2 x1 has a 500 MB/s raw post-8b/10b byte-rate ceiling. That figure is a line-rate ceiling, not an application-throughput promise and not a qualification result. Protocol, DMA, host, buffering, and application overhead reduce attainable payload throughput.

Training or enumerating at Gen2 does not qualify throughput. Acceptance requires a measured result of at least 288 MB/s at the application/host boundary, under `V41_288MBPS_ACCEPTANCE_CONTRACT.md`.

## Product operating context

- Physical video inputs: 4
- Maximum simultaneously active video inputs: 2
- Throughput acceptance load: 2 concurrently active video channels

## Gate boundary

G0 freezes this architecture requirement only. It does not edit the XDMA XCI, choose exact IP parameters, design the transition, implement a data path, build, run Vivado, or qualify hardware. The read-only feasibility audit is architectural evidence for G1; it is not hardware qualification.

