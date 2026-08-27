# AHD v41 G2 Implementation Contract

## Recommended partition

`G2A + G2B`

The current qualified image is resource-dense, the Gen2 clock metadata is contradictory, and the application C2H path does not exist. Combining source composition, IP-speed transition, new storage/CDC/MMIO, and a working formatter into one implementation gate would make a failure hard to localize. G2A therefore freezes integration and Gen2 build behavior with C2H still inactive; G2B adds the minimal one-channel C2H implementation on the accepted G2A base. Both are offline-only.

Two-channel RTL is not a G2 deliverable. Its shared-C2H architecture is frozen by G1 for later gates.

## G2A — integration plus Gen2 build

### P1 — construct integration worktree/branch

- Create an isolated branch/worktree directly from immutable tag `v41-r1i-qualified-poc-20260827` / commit `20c3323d...`.
- Record qualified tree `70d801fd...`, clean state, remotes, tool version, and all source blobs before edits.
- Use a new G2A branch name; never modify the preservation branch/tag or primary worktree.
- Prove primary donor `c89e88bc...` and secondary provenance commit `8464af6...` are ancestors of the R1i base.

### P2 — integrate R1i-owned files

- No transplant is required: the exact R1i tree is the starting state.
- Hash and freeze the NVP/I2C engine, autoinit, diagnostics table/package, qualified top NVP region, R1i register mux, R1i build oracle, and focused tests.
- Reject every R-track candidate/diff. R-track results may inform later diagnostic removal only.

### P3 — integrate XDMA donor-owned files

- Prove by blob comparison that the R1i base inherited the primary donor XCI, AXI-Lite bridge, host procedures, record/video substrate outside R1i changes, active XDC, and relevant build structure.
- Primary donor blobs win if an unexpected mismatch exists; stop rather than silently choose.
- Keep H2C unsupported/backpressured and C2H inactive in G2A.

### P4 — resolve top/MMIO conflicts

- Preserve the exact R1i top and `control_status_regs.sv` in G2A.
- Produce an ownership-region diff receipt proving donor endpoint wiring and R1i behavior coexist exactly as specified.
- Do not add new MMIO pages or activate old tied-zero DMA offsets in G2A.

### P5 — apply reviewed provenance hardening

- Retain the exact R1i `r1i_build.tcl` as an untouched regression oracle.
- Create a G2A-specific harness using primary donor project/IP/XDC/report composition.
- Port only the reviewed secondary intents: validated `FULL_BUILD`/`PROVENANCE_ONLY` modes; five-word 40-hex SHA round trip and mismatch failure; expected/reconstructed SHA plus flags/words/generic/PASS receipt; and provenance-only exit before project/build commands.
- Add negative tests for invalid mode and one-word SHA mismatch.

### P6 — change XDMA configuration to Gen2 x1

- Change only `CONFIG.pl_link_cap_max_link_speed` from `2.5_GT/s` to `5.0_GT/s` in the committed XCI configuration and common Tcl dictionary.
- Add read-only invariant assertions for every frozen property.
- Regenerate through the normal tool flow; never hand-edit generated model output.
- Diff every effective property. Stop on any unexplained user-property change.
- Retain requested `axisten_freq=62.5` and stop if generated/implemented `axi_aclk` is not the qualified expectation.

### P7 — minimal C2H adapter skeleton

- Not implemented in G2A. The existing safe C2H-zero/H2C-not-ready boundary is a required structural invariant.
- P7 is the atomic functional scope of G2B below.

### P8 — compile/elaborate

- Compile the exact mixed VHDL/SystemVerilog source set and regenerated XDMA.
- Run R1i focused tests, AXI-Lite bridge tests, record-producer legacy tests, XCI elaboration, ownership/hash checks, and provenance negative tests.
- Zero unresolved references/black boxes outside normal encrypted IP handling.

### P9 — synthesize

- Clean, non-incremental synthesis with the qualified part/tool/strategy/seed.
- Archive flat and hierarchical utilization, inferred RAM, clock, and warning deltas versus qualified R1i and standalone donor evidence.
- Apply development headroom policy; unexplained diagnostic/product growth blocks.

### P10 — implement

- Clean opt/place/phys-opt/route.
- Require fully routed design, zero timing violations, zero DRC error/critical warning, resolved CDC/XDC queries, reset/clock-interaction review, and congestion report.
- Compare Gen1/R1i and Gen2 clocking, PCIe resources, route sites, WNS/WHS, and utilization.

### P11 — generate bitstream

- Generate only after P8-P10 pass.
- Seal bitstream, DCPs, reports, XCI/property dumps, source/runtime SHA, and complete manifests.
- Bitstream generation is not hardware authorization.

### P12 — offline verification only

- Re-run source/hash/property/no-alias/static checks against the sealed build.
- Confirm no hardware command/script was invoked and no driver or host state was changed.
- G2A hard-stops with a package for independent review.

## G2B — one-channel C2H adapter implementation

G2B begins only from an accepted, immutable G2A result and repeats P1-P12 as a separate gate.

- **P1:** create an isolated child worktree/branch from accepted G2A.
- **P2/P3:** re-prove all R1i- and donor-owned blobs/invariants; no NVP functional edit and no extra XCI property change.
- **P4:** add the transparent `0x3800..0x3BFF` extension router while leaving exact R1i registers and legacy forwarding unchanged.
- **P5:** reuse the accepted G2A provenance harness and add hashes for new C2H RTL/tests.
- **P6:** retain accepted Gen2 x1 properties; any XCI edit beyond an independently approved correction is prohibited.
- **P7:** implement only logical channel 0: streaming-mode extension of the donor recordizer with byte-exact legacy mode, one four-slot DMA ring, descriptor/release/reset-epoch CDC, fixed channel-0 scheduler path, 512-beat v41D formatter, counters, snapshot registers, and existing IRQ0 advisory latch if included. H2C remains unsupported. Do not implement logical channel 1 or physical-output expansion.
- **P8:** elaborate and run exhaustive formatter, ready/valid, drop, reset, CDC, MMIO no-alias, v40B golden, and v41D golden simulations.
- **P9-P10:** clean synthesis/implementation with isolated hierarchical resource delta and full timing/CDC/congestion gates.
- **P11:** seal a bitstream only after all offline gates pass.
- **P12:** offline package/read-back only; no programming, enumeration, or DMA host test.

## Required G2B protocol assertions

- 512 handshakes per record; `TLAST` only on handshake 511; `TKEEP=0xFF` always.
- Stable `TDATA/TKEEP/TLAST` during stall.
- No first beat before complete ownership; no release before final handshake.
- Whole-record-only admission/drop.
- Attempt/commit/stream/drop and byte invariants.
- Descriptor generation/slot/epoch match.
- Reset cannot publish a record suffix.
- Exact legacy vectors through `0x35FF` and R1i page `0x3600..0x367F`.

## Explicit exclusions

G2A/G2B do not access hardware, load drivers, change host drivers, qualify Gen2 training, implement two-channel RTL, run throughput, remove diagnostics, alter R1i behavior, or start any later gate.

## Acceptance

Each subgate produces a separate PASS/BLOCKED/FAIL disposition. G2B may not hide a G2A clock/resource/timing issue. A passing G2 build is offline implementation evidence only; G3 and later hardware/functional gates remain necessary.
