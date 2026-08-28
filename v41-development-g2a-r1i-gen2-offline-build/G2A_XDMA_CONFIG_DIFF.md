# AHD v41 G2A XDMA Configuration Diff

## Gate status

`PASS — 1,001 EFFECTIVE CONFIG VALUES AUDITED; NO UNEXPLAINED DRIFT`

Authority: primary donor `c89e88bcdf389614c884fb129e8b2d42a585bccb`, inherited byte-for-byte by qualified R1i `20c3323d79d3896edc586d6db1df7deee60f9e41` before this G2A change.

## Intentional delta

| Representation | Frozen donor/R1i | G2A | Result |
|---|---|---|---|
| `ip/v41/xdma_v41_m1.xci` | `CONFIG.pl_link_cap_max_link_speed=2.5_GT/s` | `CONFIG.pl_link_cap_max_link_speed=5.0_GT/s` | PASS |
| `scripts/v41/xdma_config_common.tcl` | `CONFIG.pl_link_cap_max_link_speed=2.5_GT/s` | `CONFIG.pl_link_cap_max_link_speed=5.0_GT/s` | PASS |

A canonical full-XCI comparison that reverts only this value in memory is byte-semantic-equal to the qualified base. The only non-semantic text delta is the added terminal newline; the legacy XCI checksum field was not hand-edited.

## Frozen properties statically verified

The offline checker verified the complete XCI configuration and the matching common-Tcl representation, including:

- link width X1 and 100 MHz reference-clock request;
- `axisten_freq=62.5`, 64-bit AXI4-Stream mode, one C2H and one mandatory H2C;
- one MSI vector, MSI enabled, MSI-X disabled;
- 128 KiB AXI-Lite master/BAR0 architecture and BAR1–BAR5 disabled;
- active-low PERST and dedicated PERST;
- vendor `10EE`, device `7011`, subsystem vendor `10EE`, subsystem `0007`, class `058000`;
- bypass/status/debug options preserved disabled and extended tags preserved enabled.

The common Tcl applies only the 19-property minimal configuration dictionary and then checks 40 G1-frozen values read-only. A mismatch stops generation rather than rewriting the drifting property.

## Generated/effective comparison

Vivado 2025.2 reported `XDMA_CONFIG_PROPERTY_COUNT=1001` and wrote all 1,001 sorted effective `CONFIG.*` values to `G2A_XDMA_EFFECTIVE_CONFIG.txt`. An isolated generation from the frozen primary-donor XCI wrote the corresponding 1,001-value reference to `G2A_XDMA_FROZEN_DONOR_EFFECTIVE_CONFIG.txt`. Property names and counts match.

| Effective property | Frozen Gen1 donor | G2A Gen2 | Classification |
|---|---|---|---|
| `CONFIG.pl_link_cap_max_link_speed` | `2.5_GT/s` | `5.0_GT/s` | Intended and only user-controlled configuration delta. |
| `CONFIG.plltype` | `CPLL` | `QPLL1` | Unavoidable Vivado-derived Gen2 metadata. The serialized XCI retains `CPLL` at both revisions with `enabled:false`; no G2A source hunk changes this disabled, non-user-controlled dependent value. Vivado resolves it to `QPLL1` only when generating the Gen2 core. |
| All other 999 effective `CONFIG.*` properties | frozen value | identical frozen value | PASS |

The configured G2A property dictionary also remained byte-value-equal before and after `generate_target all`. The effective x1 width, 100 MHz reference clock, 62.5 MHz AXI request, IDs, BARs, channel counts, MSI/MSI-X settings, PERST polarity, and AXI4-Stream mode therefore remain frozen. The `CPLL -> QPLL1` generated result is not an additional user configuration request and is not a source edit or unexplained drift.

Result: only the approved speed property differs at the user-config level. The sole additional generated value difference is the disabled dependent PLL selection required by Vivado for Gen2. `BLOCKED — UNEXPECTED_XDMA_CONFIG_DRIFT` did not occur.
