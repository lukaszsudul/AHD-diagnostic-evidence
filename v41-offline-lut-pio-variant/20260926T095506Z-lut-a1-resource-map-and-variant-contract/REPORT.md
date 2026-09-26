# LUT-A1: existing resource map and PIO-less variant contract

Result: **CONTRACT_DRAFT_READY_FOR_OWNER_VARIANT_DECISION**. This is offline analysis of existing implementation checkpoints and a proposed contract. No product implementation, simulation, new build or DUT operation was performed. R15R6R3 was not modified.

Firmware commit: `719bcd63aa40cbeadb2b6eae99697f574209b6de`. Firmware tree: `386d0bcff67d3835c6377f767b2b35c2f4698216`. Released host commit: `c4bc671620f2cc2ae57fcbf9d11c31ba2d56aac4`. Original checkpoint and independent-copy hashes matched before and after analysis; pinned sources and released host files were unchanged.

Two existing checkpoints were read with Vivado 2025.2: **21,469 Slice LUTs post-opt and 20,753 final routed**, with 47 free out of 20,800. Final resources: 19,500 logic LUTs, 1,253 memory LUTs, 22,963 FF, 26 RAMB36, 5 RAMB18, 0 DSP. RAMB18 and RAMB36 are block counts (28.5 RAMB36 equivalents).

| Functional group | Post-opt LUT | Final disjoint physical LUT |
|---|---:|---:|
| IP/vendor/frontend | 10,313 | 9,921 |
| NVP initialization and postinit I2C | 2,724 | 2,698 |
| Common control | 2,646 | 2,517 |
| SCAN1/CH3/FEQ1 | 2,526 | 2,464 |
| Active G2B/C2H | 2,114 | 2,037 |
| Legacy PIO capture | 1,146 | 1,092 |
| Cross-group shared physical LUTs | included above | 24 |
| **Total** | **21,469** | **20,753** |

Final top-level inclusive hierarchy rows sum to 20,782 because physical LUTs can be shared. Deduplication by physical site/LUT gives exactly 20,753. The 24 cross-group shared LUTs are reported once; the 29-count hierarchy excess also includes sharing within functional groups. Post-opt is reported preplacement attribution, while final columns use disjoint physical attribution. Hierarchy rebuilding does not establish exact per-line RTL costs.

PIO has 1,097 final inclusive hierarchy LUTs: 1,092 exclusive physical LUTs plus 5 shared with other groups, 2,561 FF and 2 RAMB36. **This is baseline cost, not the net gain of removal.** A replacement responder, retained diagnostics and integration effects must be included in a future complete candidate.

The review found real capture/control consumers, diagnostic consumers and fixed protocol/capability checks. C2H use alone does not establish that PIO can be retired. Retained execution logs cover admission/configuration/cleanup, not every deployed procedure or normal acquisition path. Specific Owner decisions remain for acceptance/capture replacement, current clients of the PIO library, changed diagnostic semantics and variant identity allocation.

The first recommended candidate is B1: static PIO removal with necessary diagnostics, responder, explicit variant recognition, separate compatible host tools and exact constraint updates. Preserve active C2H transport, four slots, initialization, scanning and full EQ. Validate targeted regression before one complete candidate build using the actual baseline recipe. Net gain must be measured as **20,753 minus complete new final-routed LUTs**. No gain forecast or product qualification is claimed. Engineering gate: **PASS_ANALYSIS_ONLY**; evidence publication is a separate process.

Detailed source maps, register contracts, private audit, checkpoints and raw logs remain private. This folder contains only the sanitized report, result and aggregate resource table.
