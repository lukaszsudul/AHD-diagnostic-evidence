# AHD v41 G2A Source Diff Audit

## Result

`PASS — EXACTLY FOUR AUTHORIZED FILES; NO UNEXPECTED FUNCTIONAL CHANGE`

Audit range: `20c3323d79d3896edc586d6db1df7deee60f9e41..224d194e5f82c85bcb29297561c5d5e76d28063b`  
Base tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`  
Integration tree: `283f98c02e6f9c61716875415cf000682f8ab856`  
Patch: `G2A_SOURCE_DIFF.patch`  
Patch SHA-256: `BD2796E63CDBBA0AE974691F5F0A6511CBE9B23DE9CA369C9AA24A4837E449A2`

The integration commit is the direct child of the qualified R1i commit. `git diff --check` passed before and after staging. The final audit found no conflict markers, R-track leakage, secret-like material, RTL change, XDC change, or executable hardware-access command.

## Changed-file classification

| Path | Classification | Sealed blob / SHA-256 | Audit disposition |
|---|---|---|---|
| `ip/v41/xdma_v41_m1.xci` | `GEN2_REQUIRED`; terminal-newline delta is `TOOL_GENERATED_METADATA` | `450aa334e2bda4396cd5a7270ba15895c7f7ed54` / `9BDA9F1C79C1553C0271DD1599119D8F6E74D4F089ECFBDE1E4A067F3F50CA9F` | The sole semantic JSON delta is `CONFIG.pl_link_cap_max_link_speed: 2.5_GT/s -> 5.0_GT/s`. Width remains X1. The embedded legacy checksum text was not hand-recomputed. The disabled serialized `plltype=CPLL` field is untouched; Vivado's effective `QPLL1` result is tool-derived Gen2 metadata, not another source delta. |
| `scripts/v41/xdma_config_common.tcl` | `GEN2_REQUIRED` | `ea9c2b5a463e6c4e15743d53abab734ba5fdf516` / `4B240CE27E4C8065C897EF4D184EC7EB97BB1CF4BF747C1E06F92ED3A9AE2162` | Matching speed change plus read-only frozen-G1 assertions and complete effective `CONFIG.*` dump support. No other property is configured to a new value. |
| `scripts/v41/g2a_build.tcl` | `PROVENANCE_HARDENING` | `990557711e2bb231806bb3b8f6286ce62bc165d4` / `5817A5A6B80C1DD99B3270FC4625131582207C21CED3CEB2B3461D6BC92D2E28` | New isolated G2A wrapper/harness. It preserves the qualified R1i source/XDC/top oracle, performs one clean default implementation flow, emits required reports, and hard-gates provenance, clocks, route, timing, DRC, CDC, resources, and configuration. Its final CDC logic accepts only the exact two generated-XDMA Gen2 PIPE-clock objects with exact report/XDC proof; every other Critical/Critical Warning or Unknown remains a failure. `BROAD_CDC_WAIVER_APPLIED=NO`. |
| `tests/v41/run_g2a_offline_checks.ps1` | `PROVENANCE_HARDENING` | `52f9ffc15e8da67530a700dfa8da835236df5fc3` / `C42993C7833DD51078F0A054C6456F0B023DF2FC56FDC7319297427746B6E73A` | New offline source-contract/provenance test runner. It relaunches the protected focused suite under the current compatible PowerShell host, verifies the exact CDC-disposition/no-broad-waiver markers, does not modify product behavior, and contains no DUT or hardware operation. |

`UNEXPECTED` files: `NONE`.

## CDC correction classification

The exact-signature CDC harness correction is `PROVENANCE_HARDENING`, not a product-function change and not a generic waiver. It verifies the complete object set, report rows, generated-XDMA endpoints, two precise clock contexts, `False Path`/`User Ignored` classification, and the generated-XDC false-path/physically-exclusive clauses. It dispositions zero application CDC objects and fails closed for any other Critical/Critical Warning or Unknown. No RTL or XDC file changed to obtain this disposition.

## Protected-source boundary

All files outside the four-row allowlist are byte-identical to qualified R1i. In particular, the NVP bring-up/autoinit logic, composite top, MMIO/control RTL, active constraints, `r1i_build.tcl` oracle, focused R1i tests, record path, and C2H/H2C constant tie-offs are unchanged.

No generated IP output product, project file, checkpoint, bitstream, LTX, log, report, or evidence file is committed to the product-source branch.
