# R1f authoritative input identity

## Result

`PASS_EXACT_PUBLIC_R1F_EVIDENCE_AND_TERMINAL_IDENTITIES`

The R1g input gate used the exact R1f evidence commit and did not infer or
complete any abbreviated digest.

## Public Git identity

| Field | Proven value |
|---|---|
| Repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Commit | `1130c4686a7aaedcf2609dd4a5739d7a7eb73fff` |
| Tree | `6abf61a0f23718869e810dd5fe4e678ed929bc9c` |
| Parent | `16beec37a266c421da5838fbb986301d072cbb50` |
| Subject | `Add R1f phase-complete observability evidence` |
| Required path | `v41-nvp-r1f-phase-complete-observability/` |
| Files at required path | `1526` |
| Fresh `ls-remote origin refs/heads/main` | `1130c4686a7aaedcf2609dd4a5739d7a7eb73fff` |
| Public remote gate | `PASS` |

The authoritative report, evidence-package sidecar, and published patch were
downloaded from URLs pinned to the commit above. Their downloaded Git blob IDs
equal the corresponding tree entries:

| Object | Commit blob |
|---|---|
| Authoritative report | `30359e8987b73f61154b107d2b0eb962d7476843` |
| Evidence-package sidecar | `10ba5ec5e8394308784893f76795c5b39837bd1b` |
| Published source patch | `c2ae3a52a49cef79149cdf1d0b79c9be66c75968` |

## Resolved non-abbreviated identities

| Input | SHA-256 |
|---|---|
| R1f authoritative report | `2F0D7997B2226C7A770F9221ED2BB095B1C2A53EB5BB74882629C5900544C09D` |
| R1f evidence ZIP | `62350D80ACAA86E897E73B4DD0EFCF9D3DC34D58783DE20016790DB56F4704E4` |
| R1f publication receipt | `CE7CBC5FADDE7368DC40A85979381E422AFF4DCB69D7999100A2D61461FDCCE3` |
| Evidence ZIP SHA-256 sidecar | `5651CD48C368A65AD5A6EC612A2C096B5957BC4D2DB9586B215DE390EAFDEEE5` |

The local evidence ZIP is 15,872,143 bytes and independently rehashed to the
exact digest in the public sidecar and publication receipt.

## Pinned R1f build identities

| Input | Required SHA-256 | Observed | Gate |
|---|---|---|---|
| Prebuild manifest | `34626CAFDF0D2CD6A4DA87B6D7ED6C7146B4C16E7384BD5AA3927BE440859A04` | exact | PASS |
| Frozen build Tcl | `53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B` | exact | PASS |
| Terminal build log | `43C05651BEFA0DB30E00B7B16058D424AFEF38FEA2D0E15A9AF0381604A7E4D0` | exact | PASS |
| Terminal failure receipt | `1073A967F9E551FF716DF18983397B1B71D9082505A849DC4ACDBBA6DDC87AD1` | exact | PASS |
| Independent terminal audit | `9E4DA8D0F966F652F1EAAA3B4FF39DE305CDB4511AE5570DE1D97797DC44E15E` | exact | PASS |

## Terminal result preserved without reinterpretation

```text
R1F_CLASSIFICATION=
    BLOCKED_ONE_CLEAN_BUILD_SYNTHESIS_VHDL_2008_CONSTRUCT

R1F_SYNTHESIS=
    FAIL_RTL_ELABORATION

R1F_IMPLEMENTATION_RUNS=
    0

R1F_BITSTREAMS=
    0

R1F_HARDWARE_ACTIONS=
    0
```

The R1f NOT_RUN scientific results remain NOT_RUN. No value was converted to
zero, PASS, or a hardware observation.

## Preserved bounded raw inputs

- `R1F_PUBLIC_AUTHORITATIVE_FINAL_REPORT.md`
- `R1F_PUBLIC_EVIDENCE_PACKAGE_SHA256.txt`
- `R1F_PUBLICATION_RECEIPT.txt`
- `R1F_PREBUILD_MANIFEST.txt`
- `R1F_FROZEN_BUILD_TCL.tcl`
- `R1F_TERMINAL_BUILD_LOG.log`
- `R1F_TERMINAL_FAILURE_RECEIPT.txt`
- `R1F_TERMINAL_AUDIT.md`

