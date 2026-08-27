# AHD v41 G1 → G2 Entry Checklist

## G1 disposition

G2 entry is `READY` for the recommended G2A scope only. G2B entry is conditional on an accepted G2A. Two-channel physical ingress/RTL is explicitly later and does not enter G2.

## Mandatory G2A entry checks

| Check | Required evidence | Status at G1 |
|---|---|---|
| Qualified R1i identity | Branch `baseline/v41-r1i-qualified-poc` -> `20c3323d...`; tree `70d801fd...`; immutable tag; bit SHA `F6A690...` | READY |
| Primary donor identity | Branch/tag -> `c89e88bc...`; donor ancestor of R1i | READY |
| Secondary donor role | `8464af6...`, provenance-hardening-only; ancestor of R1i; reviewed intent list | READY |
| Five conflict decisions | Exact rules in `V41_G1_CONFLICT_RESOLUTION_PLAN.csv` | READY |
| Gen2 property delta | One intentional property, speed `2.5_GT/s` -> `5.0_GT/s`; invariants enumerated | READY |
| Gen2 board feasibility | One lane/refclk/PERST/hard-block evidence and no contradiction | `G2_IMPLEMENTATION_ALLOWED` |
| R1i clock protection | 62.5 MHz requested and hard stop if generated/implemented value differs; no link/reset gating | READY FOR VERIFICATION IN G2A |
| MMIO collision policy | Existing through `0x35FF`, R1i `0x3600..0x367F`, new pages disjoint | READY |
| Resource policy | Current total and diagnostic/product decomposition recorded; G2A must measure Gen2 delta | READY |
| C2H/two-channel architecture | One shared C2H, per-channel rings, record scheduler, v41D contract | READY; implementation deferred |
| Source isolation | New worktree/branch from immutable R1i; primary worktree read-only | REQUIRED AT G2 START |
| R-track separation | No R1 candidate or incomplete result may enter G2 | REQUIRED AT G2 START |

## Conditions that block G2A

G2A must not start, or must stop immediately, on the first occurrence of:

1. any R1i branch/tag/commit/tree/bitstream identity mismatch;
2. any primary donor branch/tag/commit mismatch or failure to prove donor ancestry/blob inheritance;
3. a need to merge an R-track candidate or modify protected R1i behavior;
4. inability to express `5.0_GT/s`, x1, 100 MHz, 64-bit stream, one C2H/one H2C, IDs/BARs/MSI/PERST unambiguously in the installed XDMA 4.2 configuration;
5. a board/XDC contradiction, such as wrong GT/PCIe block, missing lane, incompatible refclock, or reset polarity—not merely absent schematic/SI evidence;
6. an unresolved existing MMIO collision or any requirement to change behavior through `0x367F`;
7. no clean isolated worktree/branch or any risk of modifying the primary/preservation refs;
8. source/build provenance that cannot reconstruct the exact 40-hex runtime SHA; or
9. two-channel architecture being reopened in a way that changes G2A scope.

## Conditions that stop G2A during execution

- Effective/generated `axi_aclk` is not the qualified 62.5 MHz expectation, its lifecycle cannot be established for offline acceptance, or NVP timing would need silent rescaling.
- Any unexplained XDMA user-property delta besides maximum link speed.
- Timing, DRC, CDC, reset, routing, congestion, or development resource policy failure.
- Any protected source/hash/MMIO/test difference.
- Any request to program or access hardware.

## Additional G2B entry checks

G2B is blocked until:

- G2A has an accepted sealed commit/build/property/clock/resource package;
- the one-channel ring/formatter resource estimate fits the development policy with explicit diagnostic coexistence;
- new MMIO exhaustive no-alias tests and v41D golden vectors are reviewed;
- record storage is separate from protected PIO read ownership/latency;
- reset-epoch and descriptor CDC assertions are reviewed; and
- G2B scope remains logical channel 0 only.

## Later—not G2—blockers

The absent repository proof for a second NVP digital output/pin or a specified multiplexed two-channel mode blocks later two-channel physical implementation/qualification, not G2A or one-channel G2B. Gen2 host `LnkCap`, 5 GT/s negotiation/SI, application DMA, and 288 MB/s are likewise later hardware gates.

## Gate statement

At G1 close, the first blocker is `NONE` for G2A entry. Every execution-time stop above remains mandatory. No G2 action is performed by this checklist.
