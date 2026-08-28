# AHD v41 G2A Provenance Hardening Diff

## Result

`PASS — FROZEN DONOR INTENT PORTED; G2A BUILD-GATE PROVENANCE SEALED`

Secondary provenance donor: `dev/v41-xdma-offline-next` at `8464af66611f7c22b8a36a4aab915d598eedda3f`.  
Primary comparison donor: `v41/xdma-v40.1.0-base` at `c89e88bcdf389614c884fb129e8b2d42a585bccb`.  
Donor source: `scripts/v41/phase3_build.tcl`, blob `b908146795f6bf0033a4e2ae211208ff20532583` at the secondary donor.  
G2A destination: `scripts/v41/g2a_build.tcl`, blob `990557711e2bb231806bb3b8f6286ce62bc165d4`, SHA-256 `5817A5A6B80C1DD99B3270FC4625131582207C21CED3CEB2B3461D6BC92D2E28`.

Final integration identity: commit `224d194e5f82c85bcb29297561c5d5e76d28063b`, tree `283f98c02e6f9c61716875415cf000682f8ab856`, direct parent `20c3323d79d3896edc586d6db1df7deee60f9e41`.

Qualified R1i already contains the secondary donor's `phase3_build.tcl` blob. The R1i oracle was not modified. G2A implements a separate wrapper so the qualified harness remains immutable.

## Adopted provenance hunks and origins

| Adopted G2A intent | Exact donor origin | G2A realization |
|---|---|---|
| `FULL_BUILD` / `PROVENANCE_ONLY` selection | Secondary-donor delta at `phase3_build.tcl` header and argument parsing: optional sixth argument, default `FULL_BUILD`, only `PROVENANCE_ONLY` accepted | `g2a_build.tcl:15-27` accepts the same two-mode contract while also carrying the G2A source-tree argument. |
| 40-hex SHA validation and five-word round trip | Secondary-donor delta around the five `git_words`: `reconstructed_commit = join(git_words, "")`, then exact equality check | `g2a_build.tcl:429-451` validates lowercase 40-hex commit/tree inputs, constructs five eight-hex words, rejoins them, and rejects any mismatch. |
| Explicit receipt/PASS fields | Secondary-donor `EXPECTED_RUNTIME_PROVENANCE.txt` hunk containing source commit, five expected words, build flags, reconstructed SHA, `PROVENANCE_ROUND_TRIP=PASS`, and generic string | `g2a_build.tcl:465-497` writes `G2A_EXPECTED_RUNTIME_PROVENANCE.txt` with commit, tree, base, branch, all words, reconstruction, build flags, mode, round-trip PASS, preflight PASS, and early-exit disposition. |
| Provenance-only exit before project commands | Secondary-donor conditional exit immediately after writing the receipt and before `file mkdir $build_root` / project work | `g2a_build.tcl:493-499` writes `PROVENANCE_ONLY_EXIT_BEFORE_BUILD=PASS`, exits zero, and places every build/project operation below the boundary. Static ordering check: the receipt/exit boundary precedes `create_project` at line 715. |

No unrelated secondary-donor functionality was transplanted. The additional branch/base/tree cleanliness checks, direct-parent requirement, evidence freshness, effective-config comparison, one-pass implementation sequence, and engineering gates are G2A contract controls, not donor logic.

## Exact-signature CDC build-gate correction

The first clean implementation routed with positive setup/hold timing and no critical DRC, then stopped because the initial G2A wrapper treated every Vivado `Critical` CDC object as an unconditional failure. Review against the frozen G1 CDC plan established that G1 requires generated-clock/exception findings to be resolved and recorded; it does not authorize a generic waiver or require an unclassified severity-only stop.

The final harness correction is classified `PROVENANCE_HARDENING` because it makes the build gate prove the exact accepted generated-IP condition. It does not change RTL, XDC, XDMA user configuration, generated output products, or application CDC behavior. Acceptance requires all of the following simultaneously:

- the complete critical-object set is exactly `CDC-13#1` and `CDC-13#2`;
- exactly two report rows and one summary row match the frozen `CDC-13` text;
- both rows have depth zero, `Exception=False Path`, the exact generated-XDMA PIPE source/destination endpoints, and `CDC Type=User Ignored`;
- the two exact clock contexts are `clk_125mhz_mux_x0y0 -> clk_250mhz_x0y0` and `clk_250mhz_mux_x0y0 -> clk_250mhz_x0y0`;
- the single generated XDMA PCIe XDC contains the exact S0 and S1 false paths and the 125/250 MHz physically-exclusive clock group;
- the Unknown count remains zero and every Critical/Critical Warning object is dispositioned by this exact check.

The receipt states `APPLICATION_CDC_DISPOSITIONED=0` and `BROAD_CDC_WAIVER_APPLIED=NO`. Any different count, ID, severity, endpoint, clock pair, exception, CDC type, generated-XDC clause, new application CDC, or Unknown finding remains a hard failure. This is an exact evidence-bound gate correction, not a slack waiver or a broad `CDC-13`/XDMA exemption.

## Offline verification

Final sealed static verification uses:

- harness SHA-256 `5817A5A6B80C1DD99B3270FC4625131582207C21CED3CEB2B3461D6BC92D2E28`;
- offline checker SHA-256 `C42993C7833DD51078F0A054C6456F0B023DF2FC56FDC7319297427746B6E73A`;
- complete source patch SHA-256 `BD2796E63CDBBA0AE974691F5F0A6511CBE9B23DE9CA369C9AA24A4837E449A2`.

The static contract verifies:

- both execution-mode markers present;
- exact five-word reassembly statement present;
- receipt and PASS fields present;
- provenance exit text precedes all project commands;
- exact-signature CDC disposition and explicit no-broad-waiver markers are present;
- Tcl structure complete;
- no hardware-manager/programming/DUT command present.

The sealed offline runner executes one valid provenance-only invocation plus invalid-mode and mismatched-word negative invocations and records their results in `G2A_OFFLINE_TEST_REPORT.md`. Provenance-only execution exits before project creation and does not touch its disjoint build root.
