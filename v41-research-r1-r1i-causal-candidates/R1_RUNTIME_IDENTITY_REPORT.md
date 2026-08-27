# AHD v41 R1 Runtime Identity Report

## Result

**PASS.** Each candidate uses the existing frozen source-identity path and remains distinguishable from qualified R1i, the sibling candidate and R1h without changing the MMIO ABI.

## Frozen mechanism

The frozen top forwards five 32-bit `GIT_SHA_W0..W4` generics plus `BUILD_FLAGS` into the frozen control/status register block. Read-only MMIO offsets `0x10`, `0x14`, `0x18`, `0x1C` and `0x20` expose all 160 Git bits; offset `0x2C` exposes build flags. The top RTL, CSR RTL, ABI documentation, XCI, XDC and qualified build-source lists have byte-identical Git blobs across base and both candidates.

The build adapter validates clean HEAD, tree, branch, direct parent and one-commit ancestry before project creation, then slices the exact requested commit into the five existing generic words with `BUILD_FLAGS=0x00000002`.

## Candidate identities

| Image | Five runtime words | Reconstructed commit |
|---|---|---|
| Qualified R1i | `20c3323d 79d3896e dc586d6d b1df7dee 60f9e41` | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| R1i-a / C1 | `8b8ec0fa 9c22965e 46d0421c 25e63d83 e7971597` | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` |
| R1i-b / C2 | `e4d10bb8 e85e3797 d078144f d0965e96 25ee727c` | `e4d10bb8e85e3797d078144fd0965e9625ee727c` |

Both candidate tuples differ from each other, qualified R1i, and R1h commit `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` (control-bitstream SHA-256 `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41`). The frozen formal Phase-2 safe image is independently identified by SHA-256 `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2`.

## Build-time proof

| Candidate | Build provenance | Build-time generic binding plus frozen implemented MMIO path | Bitstream |
|---|---|---|---|
| R1i-a | PASS — exact commit/tree/base/branch and clean source | PASS — five implemented generic words reconstruct `8b8ec0fa9c22965e46d0421c25e63d83e7971597`, flags `0x2` | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` |
| R1i-b | PASS — exact commit/tree/base/branch and clean source | PASS — five implemented generic words reconstruct `e4d10bb8e85e3797d078144fd0965e9625ee727c`, flags `0x2` | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` |

The corresponding `BUILD_PROVENANCE.txt` SHA-256 values are `D37ACBDE342DEB6E92B8BE014381EBDBEEEB7A63F84A89566F69829C3D69AABC` for C1 and `A8B089AD3D28D6FEBDA9237C6F10DAC699086D1DDA9FE05A178CF0D9AE574EFD` for C2. Elaboration/synthesis logs bind these generics into the implemented design; the frozen register path establishes their later read-only runtime exposure. No runtime MMIO read was performed in R1.

No new address, field, access type, decoder case, register, or software-visible ABI behavior was introduced to create these identities.
