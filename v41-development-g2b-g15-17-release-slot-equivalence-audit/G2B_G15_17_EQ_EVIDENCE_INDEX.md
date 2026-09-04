# G2B-G15-17-EQ-R1 evidence index

Publication directory: `v41-development-g2b-g15-17-release-slot-equivalence-audit`

The original directory name was absent at the fresh pre-publication `origin/main` commit `d8fba44fe4a7446ccefdd86027f2c2be73225f91`, so the `-r1` fallback was not used.

## Decision evidence

- `V41_G2B_G15_17_EQ_MAIN_REPORT.md` — complete gate, authority, method, result, protection, and recommendation.
- `G2B_G15_17_EQ_STATE.json` — machine-readable final state.
- `G2B_G15_17_EQ_R1_WORKTREE_INVENTORY.md` — every Git worktree and exact authority-selection proof.
- `G2B_G15_17_EQ_CURRENT_CONSTRAINTS.md` — exact Groups 15-17 active definitions, counts, clocks, intent, and comparability.
- `G2B_G15_17_EQ_SLOT0_REFERENCE_SIGNATURE.json` — canonical accepted slot-0 signature.
- `G2B_G15_17_EQ_SLOT1_SIGNATURE.json`, `G2B_G15_17_EQ_SLOT2_SIGNATURE.json`, `G2B_G15_17_EQ_SLOT3_SIGNATURE.json` — normalized signatures retaining actual routed differences.
- `G2B_G15_17_EQ_STRUCTURAL_EQUIVALENCE_MATRIX.csv` — all six pairwise comparisons.
- `G2B_G15_17_EQ_SEMANTIC_MODELS.md` — independent functional reconstruction and per-slot candidate decision.
- `G2B_G15_17_EQ_SAFETY_INVARIANT_COMPARISON.md` — eight invariants for all three slots.
- `G2B_G15_17_EQ_CDC_COMPARISON.md` — focused release, stable-data, reset, mismatch, and retirement review.
- `G2B_G15_17_EQ_FAMILIES.csv` — nine exact semantic-family definitions.
- `G2B_G15_17_EQ_PROTOCOL_TIMING_MARGINS.csv` — independently derived 13.468/6.000/7.468 ns margins.
- `G2B_G15_17_EQ_CANDIDATE_CONSTRAINTS.xdc` — combined three-slot candidate, SHA-256 `BFB8482C1A84961E43FF24A69008C91EBA4E5B37E494CB5C65D262FAFE00AE6F`.
- `G2B_G15_17_EQ_CANDIDATE_XDC_DIFF.md` — candidate scope and preservation audit.
- `G2B_G15_17_EQ_CANDIDATE_RESULTS.csv` — nine bounded checks, all PASS.
- `G2B_G15_17_EQ_TIMING_METHODOLOGY.md` — focused TIMING-32/34/37/38/39 disposition.
- `G2B_G15_17_EQ_RUNTIME.csv` — initialization, query, accepted-session, and disclosed retry runtimes.
- `G2B_G15_17_EQ_SIGNOFF_CONTINUATION_PLAN.md` — future governed steps; not executed here.
- `G2B_G15_17_EQ_BOUNDED_WORKER.tcl` — exact bounded Vivado harness.
- `G2B_G15_17_EQ_SHA256_MANIFEST.txt` — SHA-256 for every other published evidence file.

## Raw evidence

- `raw/structural/` — input identities, resolved scope, synchronizer inventory, fanout profile, transport topology, bounded path CSVs, and per-query completion markers. The README dispositions the later fail-closed harness error.
- `raw/candidate/` — applied temporary context, removed release-skew inventory, candidate results, three focused timing reports, methodology report, runtimes, and successful worker marker.
- `raw/README.md` — raw-session validity boundary.

## Authority chain

- SSOT: `project-current-state/`, revision 6.
- G14-A: commit `9e91315968453e859006077191cd5fc711fc6b96`.
- META-6: commit `0061a20ab735b4ff5dabdfe1f81ed9f1ba718dde`.
- Recovery-3: commit `d8fba44fe4a7446ccefdd86027f2c2be73225f91`.
- Source: commit `bdae16e06fb5b8564763941f530e4ce9e28896c7`, tree `e18833d46f7672f851c3cb8239f2f29091378294`.
- Routed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`.

The containing Git commit is the publication identity. Remote read-back verifies the committed tree and manifest after the non-force push.
