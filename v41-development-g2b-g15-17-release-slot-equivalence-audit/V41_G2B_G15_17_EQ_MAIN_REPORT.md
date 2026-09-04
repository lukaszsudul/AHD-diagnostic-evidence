# AHD v41 G2B-G15-17 Release-Slot Structural Symmetry and Combined Sign-Off Audit

## Result

Engineering gate: **PASS**

Groups 15-17 do not form exact naming-only routed-netlist copies of Group 14. The safety-relevant RTL protocol, CDC structure, endpoint roles, reset behavior, hold lifetime, and retirement protocol are equivalent, but synthesis produced real per-slot combinational-depth and LUT-pin-mapping differences. All six pairwise structural comparisons are therefore `PARTIALLY_EQUIVALENT`.

That does not block a combined replacement. Each slot was treated as a slot-specific implementation of the same semantic protocol. Its normal, mismatch, and reset-overlap families were resolved and validated independently. All nine 6.000 ns datapath-only settling checks passed. The combined candidate is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` than each original global bus-skew relation.

- Candidate scope: `COMBINED_ALL_THREE`
- Final disposition: `PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC`
- META readiness: `YES_WITH_OWNER_ARCHITECT_REVIEW`
- RTL changes required: slot 1 `NO`, slot 2 `NO`, slot 3 `NO`
- Sign-off runtime: `PRACTICAL`

## Governance authority

SSOT revision 6 was verified from `project-current-state/`. Group 9 and Group 13 promoted replacements remain PASS; Groups 10-12 remain `PRESERVE_PASS`; Group 14's three-family `SETTLING_PLUS_STRUCTURAL_CDC` method is promoted and its later active implementation is PASS; Groups 15-17 remain `PENDING_UNCHANGED`; G2B-LUT1 is `READY_FOR_SIGNOFF_RECOVERY`; G2B-HW remains `BLOCKED`.

META-6 commit `0061a20ab735b4ff5dabdfe1f81ed9f1ba718dde` was verified. It retires Group 14's global bus skew, promotes three semantic families, requires no RTL change, and authorizes the active-XDC follow-up.

Recovery-3 commit `d8fba44fe4a7446ccefdd86027f2c2be73225f91` was verified. Its three Group-14 family checks pass. It did not run Group 14's global bus skew. Its Group-15 global query started and exceeded the 300-second limit at 300.679 seconds; Groups 16 and 17 were not run; no bitstream was produced and no hardware was accessed.

G14-A commit `9e91315968453e859006077191cd5fc711fc6b96` supplied the accepted slot-0 model and 6.000 ns methodology. All authority manifests passed. One Recovery-3 diff note contains a non-blocking parent-tree typo (`26399c01...`); independent Git verification gives the real parent tree `26399ed456941e26d5ee4b1b2ca50392338fa24a`. The required current source identity and technical evidence are unaffected.

## Worktree authority recovery

`git worktree list --porcelain` found six existing worktrees. Exactly one matched all three required identities:

- authoritative path: `C:\FPGA\V41_G2B`
- branch: `integration/v41-g2b-onech-c2h`
- HEAD: `bdae16e06fb5b8564763941f530e4ce9e28896c7`
- tree: `e18833d46f7672f851c3cb8239f2f29091378294`
- parent: `64feb60de5d07f400e6b92527bfe54838b3372ee`
- tracked worktree: clean
- index: clean
- untracked files: 0
- lock/prunable state: unlocked/not prunable

The protected primary `C:\FPGA\FPGA_AHD` remained on `main` at `be94f88ee8d179f12928ab791bdae27c22cd1762`, with clean tracked/index state and all 47 pre-existing untracked files preserved. No checkout, switch, reset, clean, stash, reconstruction, or branch movement occurred.

## Routed checkpoint and environment

The only checkpoint used was:

`C:\FPGA\G2B_LUT1_PRODUCT_PRECOMMIT_RECOVERY_20260831_12R1\sealed_inputs\G2B_ROUTED.dcp`

Its SHA-256 is `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83` and size is 57,900,063 bytes. No substitute DCP was used.

Vivado v2025.2 analysis processes ran strictly serially and left zero Vivado processes. Harness defects caused early sessions to fail closed; no result was inferred from them. The accepted structural artifacts came from three bounded original-scope queries that had explicit completion markers before a later candidate-application harness error. A clean serialized continuation then applied the candidate and completed all validation with `WORKER_COMPLETED=PASS`. No global Groups 15-17 `report_bus_skew` command ran in any session.

Accepted structural initialization and inventory took 234.406 seconds; accepted candidate initialization took 212.223 seconds, both below 900 seconds. The accepted structural and candidate sessions used 575.267 seconds combined. All five serialized worker attempts, including fail-closed harness corrections, used 1217.126 seconds. This disclosed harness-development overhead is not a timing-query pathology; the reusable candidate session completed in 280.584 seconds.

## Current Groups 15-17 method

Each group has 56 sources: 24 release-generation and 32 release-epoch sequential objects on `userclk1`. Each targets the same 20-object collection on `nvp_vclk1` with `set_bus_skew 3.000`.

For every slot, the 20 endpoints mix three normal state bits, four shared mismatch/fault/admission registers, four release-history bits, and nine state bits belonging to other slots. They omit the three actual reset-overlap accounting bits. The bounded path samples independently showed only normal and mismatch roles; the reset role was absent. Therefore all three original path sets are `INVALID_FOR_SKEW_COMPARISON`.

Historical Group-15 timeout: verified. Global Group-15/16/17 bus-skew execution in this audit: `NO/NO/NO`.

## Structural comparison

All four slots have:

- 56-bit generation/epoch tokens with identical field composition;
- `userclk1` launch and `nvp_vclk1` use;
- one direct two-stage FDRE `ASYNC_REG` release chain per slot;
- the shared two-stage transport-request and acknowledgement chains;
- identical stable-hold, mismatch-containment, reset-overlap, and coherent-retirement rules;
- 3 normal, 4 mismatch, and 3 reset semantic destinations;
- 24 generation bits with one direct leaf sink each and 32 epoch bits with two each.

The mapped family depth vectors are different:

| Slot | Normal | Mismatch | Reset |
|---:|---:|---:|---:|
| 0 | 8 | 8 | 6 |
| 1 | 9 | 9 | 6 |
| 2 | 9 | 9 | 5 |
| 3 | 8 | 9 | 7 |

Bounded old-scope logic-level distributions are slot 0: 49 paths at level 8; slot 1: 49 at level 9; slot 2: 49 at level 9; slot 3: 7 at level 7, 14 at level 8, and 28 at level 9. Per-bit LUT input bindings differ for every pair. These differences arise in the synthesized reconvergent/carry cones, including reset-abandoned accumulation. They are real and were not normalized away.

Consequently every pair is `PARTIALLY_EQUIVALENT`, while logical safety-protocol equivalence is proven. The per-slot candidate decision is `REQUIRE_SLOT_SPECIFIC_SETTLING_PLUS_STRUCTURAL_CDC` for slots 1, 2, and 3.

## Safety and CDC

All eight required invariants are directly proven for every slot: stable pre-event payload, two-stage release crossing, post-sync destination use, stability through consumption, fail-closed mismatch recording, stale-safe reset overlap, coherent captured-phase retirement, and no premature overwrite/reuse.

The CDC classification for every slot is `PASS_WITH_DISPOSITION`. The disposition is the accepted held-data crossing qualified by a two-stage synchronized event. It is not an unresolved failure and does not claim global CDC closure.

## Timing-margin derivation

The destination clock period is 6.734 ns. Both ordinary release and transport-reset qualification require two destination stages, and same-edge sequential logic observes the previous sync2 value. Thus the theoretical launch-to-use window is `2 x 6.734 = 13.468 ns`.

The 6.000 ns cap is the governed aggregate AXI-to-source mailbox settling cap, retained only after proving equal clock periods, qualifier latency, destination-use phase, and hold lifetime for each slot. Gross reserve is `13.468 - 6.000 = 7.468 ns`. The number was therefore derived and independently applied, not copied on naming symmetry.

## Candidate results

| Slot | Normal actual/slack ns | Mismatch actual/slack ns | Reset actual/slack ns |
|---:|---|---|---|
| 1 | 5.548 / +0.528 | 5.576 / +0.456 | 4.338 / +1.692 |
| 2 | 5.473 / +0.559 | 5.772 / +0.260 | 4.480 / +1.550 |
| 3 | 5.515 / +0.557 | 5.729 / +0.303 | 4.585 / +1.445 |

All nine checks resolved the expected 56 sources and 3/4/3 destinations, carried exactly `MaxDelay Path 6.000ns -datapath_only`, and passed. The minimum slack is +0.260 ns in slot-2 mismatch containment. Three additional focused `report_timing` commands passed and completed in 0.139, 0.139, and 0.135 seconds.

## Methodology warnings

The focused methodology command completed in 7.633 seconds. TIMING-32, TIMING-37, and TIMING-38 were absent. It reported 11 TIMING-34 and one TIMING-39 warning, all attributable to 11 preserved non-release bus-skew relations. The applied context contained zero release-slot bus-skew relation. The candidate's nine scoped max-delay relations recreate neither warning pattern. Result: `PASS_WITH_DISPOSITION`.

## Scope and protection

The combined candidate replaces only Groups 15-17. Group 14 remains its accepted three-family implementation. Groups 9 and 13 remain promoted PASS; Groups 10-12 remain preserved PASS. No clock, unrelated false path, unrelated max delay, ABI/MMIO rule, RTL, active XDC, SSOT, R-track, HDMI project, source commit, or Git index was changed.

No synthesis, implementation, placement, routing, bitstream generation, DUT/JTAG, PCIe, DMA, driver, reboot, or power-cycle action occurred. G2B-HW remains `BLOCKED`. Project state revision remained 6.

## Publication and next step

The planned remote directory was absent at the fresh `origin/main` tip, so publication uses `v41-development-g2b-g15-17-release-slot-equivalence-audit` rather than the `-r1` fallback. The containing Git commit is the immutable publication identity; remote read-back validates the directory and manifest after push.

Recommended next action: run one combined META promotion task for Groups 15-17, explicitly accepting the slot-specific routed cones and the independently validated common method. Do not modify SSOT or active XDC in this audit.
