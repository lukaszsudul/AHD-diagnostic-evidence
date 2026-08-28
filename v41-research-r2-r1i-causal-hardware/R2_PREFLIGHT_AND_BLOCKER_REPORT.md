# AHD v41 R2 Causal Hardware Preflight and Blocker Report

## Result

- R2 executed: `NO`
- R2 causal result: `BLOCKED`
- C0: `NOT_RUN`
- C1: `NOT_RUN`
- C2: `NOT_RUN`
- C3: `NOT_RUN`
- Hardware accessed by this continuation: `NO`
- Hardware lock: `NOT_ACQUIRED`

## Qualified R1 gate

R1 was fully qualified before this preflight:

- engineering gate, source contract, focused tests, clean builds, timing, DRC,
  sibling ancestry, single synthesizable-file allowlist, cross-contamination,
  and candidate runtime identities: `PASS`;
- R1 evidence commit:
  `d02a3dbc41075764ecf915e4e2d0a1da3c0ce07e`;
- Candidate A commit/tree:
  `8b8ec0fa9c22965e46d0421c25e63d83e7971597` /
  `a0fcbdbfb2b01049b357a8f8bf68bd448d6394f7`;
- Candidate B commit/tree:
  `e4d10bb8e85e3797d078144fd0965e9625ee727c` /
  `2658cf45e36c3dab81005117056b1f8e6cf3ddc1`.

No R1 corrective iteration was required or used.

## Frozen R0 campaign

The authoritative R0 commit is
`aff7e32edc1cf71bde95b6c19e54e6f307764237`.

The frozen campaign requires eight independent runs for each of C0, C1, C2,
and C3, for 32 primary runs total, in these exact rows:

1. C0, C1, C3, C2
2. C1, C2, C0, C3
3. C2, C3, C1, C0
4. C3, C0, C2, C1
5. C3, C0, C2, C1
6. C2, C3, C1, C0
7. C1, C2, C0, C3
8. C0, C1, C3, C2

A safe baseline must be restored and verified after every primary run. Partial
rows or fewer than eight valid runs per cell cannot be interpreted as the
frozen causal experiment.

## Blocker 1 — exclusive lock is not provable

R0 requires the shared `FPGA_AHD_HW_LOCK` before JTAG, programming, MMIO, SSH
hardware control, or any other DUT action. A read-only inventory found no
canonical executable or current state receipt implementing that exact shared
lock. Eight older campaign-specific locks were released and their owner PIDs
were not live, but they use different `Local\AHD_V41_*` mutex names and cannot
prove cross-track exclusion.

The current canonical shared-lock state is therefore `NOT_PROVABLE`, not
`FREE`. Inventing a new private mutex during execution would not establish that
other tasks honor it. The preflight stopped before connectivity, SSH, JTAG,
programming, MMIO, power, reset, or driver activity.

An active G2A process was inspected read-only. It was an offline Vivado build;
its Tcl contained synthesis/implementation/bitstream commands and no hardware
commands. It was not interrupted. This confirms that the observed G2A process
was offline, but it does not repair the missing cross-track lock contract.

## Blocker 2 — frozen denominator does not fit the window

The deadline policy prohibited starting a new arm at or after 07:45
Europe/Warsaw. At the 06:31 go/no-go decision only about 74 minutes remained.

The latest proven receipts show 437.643 seconds for one B1 image run and
331.323 seconds for the following Formal Phase-2 safe restoration: 768.967
seconds active and 795.479 seconds observed wall time for one primary-run plus
restore cycle. Thirty-two such cycles project to 6.84–7.07 hours. Even omitting
the mandatory restorations would project to about 3.89 hours. At 06:35:15 only
69.75 minutes remained to the cutoff, enough for at most about five observed
cycles. The exact 32-run campaign therefore could not complete safely before
the cutoff.

Starting one row or one apparently informative cell would violate the frozen
denominator and the instruction not to stop early when a result looks obvious.
No partial R2 campaign was started.

## Additional execution-contract gaps

The proven earlier harness cannot be reused unmodified for R2. It hardcodes
the earlier `POC_A`, `R1H_CONTROL`, and `FORMAL_RESTORE` roles, their source
SHAs, output directories, and a six-process Vivado accounting model. It has no
candidate-aware C0/C1/C2/C3-by-eight receipt chain.

More importantly, its first telemetry snapshot occurs only after a warm reboot
and runtime gate, by which time the autonomous post-init 10,000-opportunity
probe is already complete. R0 requires the raw autoinit snapshot to be sealed
before any post-init probe. The prior recipe also records no explicit
counter-clear time/policy, while R0 requires both. These are provenance and
scientific-execution gaps, not permission to reinterpret the frozen protocol.
A reviewed capture mechanism must close them before R2 hardware execution.

## Artifact identity preflight

Every required image was found locally and rehashed successfully:

| Cell/state | SHA-256 | Bytes |
|---|---|---:|
| C0 exact R1h | `73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41` | 2,192,144 |
| C1 R1i-a | `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D` | 2,192,144 |
| C2 R1i-b | `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D` | 2,192,144 |
| C3 exact qualified R1i | `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6` | 2,192,144 |
| Formal Phase-2 safe restore | `7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2` | 2,192,144 |

Artifact availability did not override the lock and schedule stop conditions.

## Preservation

- Qualified R1i source/worktree modified: `NO`
- Product source worktree modified: `NO`
- G-track branch modified: `NO`
- Flash changed: `NO`
- Drivers changed: `NO`
- Hardware state changed: `NO ACTION BY THIS CONTINUATION`
- R0 design/criteria changed: `NO`
- R3 started: `NO`

## Required resolution

Before a later R2 attempt, the project must establish one canonical,
cross-track `FPGA_AHD_HW_LOCK` implementation and state receipt, then schedule
enough uninterrupted time for all 32 primary runs and the mandatory safe
restorations. The candidate-aware execution harness must be reviewed before
use; the prior R1i/R1h harness hardcodes those earlier roles and source IDs.
