# R2 Runtime and Artifact Identity Receipt

## Immutable artifact rehash

| Candidate | Exact source commit | Tree where frozen | Bytes | SHA-256 | Result |
|---|---|---|---:|---|---|
| C0 | `c4f4bfcf577c92c3021d1fe83c05878dd12e001c` | `161e561f007912d73dba93c5ecd78e3cc3a6955b` | 2192144 | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` | PASS |
| C1 | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` | `a0fcbdbfb2b01049b357a8f8bf68bd448d6394f7` | 2192144 | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` | PASS |
| C2 | `e4d10bb8e85e3797d078144fd0965e9625ee727c` | `2658cf45e36c3dab81005117056b1f8e6cf3ddc1` | 2192144 | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` | PASS |
| C3 | `20c3323d79d3896edc586d6db1df7deee60f9e41` | `70d801fd7a879080da399bfa9ee95fd6eb008e16` | 2192144 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | PASS |
| Formal | frozen Formal Phase-2 | frozen Formal Phase-2 | 2192144 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | PASS |

No bitstream was rebuilt.

## Candidate-aware harness

The inherited runtime gate could not distinguish C1/C2. The host-side read-only replacement at `tools/r2_runtime_identity_readonly.py` recognizes all four exact source commits and hashes, records candidate, run ID, epoch, cold/warm epoch kind, source words, common identity, build flags, and diagnostic magic, and opens MMIO only as `O_RDONLY|O_CLOEXEC` with `pread`.

- offline self-test: `PASS`
- candidates recognized: `C0,C1,C2,C3`
- RTL modified: `NO`
- DUT behavior modified: `NO`

Live candidate identity verification: `NOT_RUN`, because the mandatory hardware lock failed before any programming. The initial cold-reset state was unprogrammed, so it carried no readable firmware/MMIO identity.
