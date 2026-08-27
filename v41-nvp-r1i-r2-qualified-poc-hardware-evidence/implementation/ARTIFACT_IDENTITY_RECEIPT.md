# Frozen R1i–R2 Hardware Artifact Identity Receipt

No build, synthesis, implementation, or bitstream generation was performed.

| Role | Task-local path | Bytes | SHA-256 | Result |
| --- | --- | ---: | --- | --- |
| Fixed R1i PoC | `R1I_POC.bit` | 2,192,144 | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | PASS |
| Exact unmodified R1h control | `R1H_CONTROL.bit` | 2,192,144 | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` | PASS |
| Exact Formal Phase 2 | `FORMAL_PHASE2.bit` | 2,192,144 | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | PASS |
| Protocol resolution | `AHD_v41_R1i_R2_PROTOCOL_RESOLUTION.md` | 10,177 | `FBB650D7111A9A745C82841A7FEE4AB159A38FCE00301AC81C8D69C8DECCA35E` | PASS |
| Prior build report | `AHD_v41_R1i_R2_FINAL_BUILD_REPORT.md` | see file | `AB1C9356F6A177C7C6D16B82E4E4B03BD88A8C336B55C1966566AF4A660C7F5A` | PASS |
| Build validation JSON | `R1I_BUILD_VALIDATION.json` | 942 | `1D05A3D340F0E1D12683CE9CA19E18DEBADA83D2EF69755BF6F83C7561FE9322` | PASS |

No `.ltx` or `.probes` artifact exists or is required. The frozen qualification uses MMIO/BRAM telemetry and independent DONE receipts.

Frozen protocol: A1 fixed R1i PoC -> B1 exact unmodified R1h control -> Formal Phase-2 restoration -> hard stop. Target: 60,000 phase observations, not 90,000.
