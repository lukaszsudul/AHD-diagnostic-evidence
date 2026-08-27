# AHD v41 XDMA Donor Receipt

## Primary donor freeze

| Field | Frozen value |
|---|---|
| Role | `PRIMARY_XDMA_DONOR` |
| Branch | `v41/xdma-v40.1.0-base` |
| HEAD | `c89e88bcdf389614c884fb129e8b2d42a585bccb` |
| Tree | `417820c69c134161fcafae0947dc5976919814d1` |
| Functional Phase-1 | `fd32fcb65be3f1a59c569874195d1faeaf7d27e9` |
| Hardware Phase-2 acceptance | `9306c25a48dedd2372bf5d06e37344ae2aa3e85a` |
| Annotated donor tag | `v41-xdma-primary-donor-g0-20260827` |
| Tag object | `c834c1ea77d24fcc4d9b8e01ee7f4ed1e1754db1` |
| Peeled tag target | `c89e88bcdf389614c884fb129e8b2d42a585bccb` |

The annotated tag records the branch/head, Phase-1 and Phase-2 anchors, current Gen1 x1 configuration, known PCIe/MMIO acceptance, absence of a working application DMA data plane, and incompatibility with 288 MB/s sustained application payload. It is an immutable donor identity, not production qualification.

## Proven and unproven scope

Accepted donor evidence establishes:

- XDMA PCIe endpoint
- one C2H interface and the mandatory H2C interface
- AXI-Lite bridge, register bank and BAR architecture
- single-input video/record context
- active XDC and build infrastructure
- PCIe enumeration at 2.5 GT/s x1
- official XDMA driver loading and expected device nodes
- BAR discovery, identity/status reads and scratch-register behavior

It does not establish:

- an application record-to-AXI-Stream adapter
- an application C2H packet or host payload
- one-channel application DMA correctness
- two-channel DMA
- sustained application throughput

The current application C2H `tdata`, `tkeep`, `tlast` and `tvalid` are tied inactive/zero. H2C is present but application `tready` is low. Enumeration is not application DMA.

## Current XCI identity

- Path: `ip/v41/xdma_v41_m1.xci`
- SHA-256: `EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C`
- IP: XDMA 4.2 revision 2
- Target: `xc7a35tcsg325-2`
- Current link: PCIe Gen1 x1, block `X0Y0`
- Reference clock: 100 MHz differential
- Application stream: 64 bit at nominal 62.5 MHz
- Channels: one C2H, one mandatory H2C
- Reset: dedicated active-low PERST

The XCI was not edited, regenerated, or reconfigured in G0. The exact XCI remains the donor oracle; the helper Tcl is not a complete configuration authority.

## Secondary donor freeze

| Field | Frozen value |
|---|---|
| Branch | `dev/v41-xdma-offline-next` |
| HEAD | `8464af66611f7c22b8a36a4aab915d598eedda3f` |
| Tree | `4bf1988785baf4bae46bdfaf5bb12d0d25f26e68` |
| Relationship | direct child of primary donor |
| Role | `SECONDARY_DONOR` |
| Scope | `PROVENANCE_HARDENING_ONLY` |
| Adoption | `REQUIRES_REVIEW_BEFORE_ADOPTION` |

RTL, XCI, XDC, MMIO and host assets are identical to the primary. The entire tree delta is one modified file, `scripts/v41/phase3_build.tcl`, with 31 insertions and 2 deletions. No separate hardware run qualifies it.

### Exact diff receipt

- Primary blob: `ddf447f959c06118a43164901b8814ec4a8cc55e`
- Secondary blob: `b908146795f6bf0033a4e2ae211208ff20532583`
- Stable patch ID: `30f508f5626b26076bc36352a37da33376826724`
- `git diff --check`: `PASS`
- Reproduction command: `git diff c89e88bcdf389614c884fb129e8b2d42a585bccb 8464af66611f7c22b8a36a4aab915d598eedda3f -- scripts/v41/phase3_build.tcl`

### Exact portions admitted as G1 review inputs

1. Optional sixth argument `PROVENANCE_ONLY`, with backward-compatible full-build default and rejection of any unsupported mode.
2. Reconstruction of the full 40-hex source SHA from five 32-bit words, with hard failure on mismatch.
3. Emission of `EXPECTED_RUNTIME_PROVENANCE.txt` containing `BIT_SOURCE_COMMIT`, expected `GIT_SHA_W0..W4`, `BUILD_FLAGS=0x00000002`, reconstructed SHA, PASS marker, and exact generic string.
4. Successful provenance-only exit before Vivado project creation or build commands.

G1 must review and compose these ideas into the qualified R1i build/provenance flow. It must not wholesale adopt the secondary Phase-3 source list or harness. G0 applied none of the changes.

## Historical donors

`v41/xdma` and `archive/v41-xdma-pre-v40.1.0-20260817`, both at `f3cfa6bf72f3cdcc5688f3a28ff16e80afc5d875`, remain provenance/history references only and are not selected implementation donors.

## Publication result

The primary donor tag was published by an atomic non-force push and independently read back to the exact donor commit. No donor branch was modified.
