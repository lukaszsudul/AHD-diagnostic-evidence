# AHD v41 R1 Causal Candidate Implementation Report

## Gate

**Engineering gate: PASS**

R1 implemented exactly two causally isolated candidates under the accepted R0 contract, tested them offline, and built each from a clean direct-sibling source checkout. No hardware operation was performed and R2 was not started.

## Contract and frozen base

The published R0 contract was fetched and read at evidence commit `aff7e32edc1cf71bde95b6c19e54e6f307764237`; its implementation-contract SHA-256 is `F872DF2DCED1CB84743288914309911346597345F401E58C72AB43299DC7D2C3`. It matches this task.

The frozen base is qualified R1i commit `20c3323d79d3896edc586d6db1df7deee60f9e41`, tree `70d801fd7a879080da399bfa9ee95fd6eb008e16`, and bitstream SHA-256 `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`.

## Candidate summary

| Candidate | Commit / tree | Source contract | Offline tests | Clean build | Runtime identity |
|---|---|---|---|---|---|
| R1i-a / C1 | `8b8ec0fa...` / `a0fcbdb...` | PASS | PASS | PASS | PASS |
| R1i-b / C2 | `e4d10bb8...` / `2658cf45...` | PASS | PASS | PASS | PASS |

C1 preserves physical filtered-SCL qualification and the terminal decision tick while selecting the first filtered-HIGH SDA value from the completing interval. C2 removes ordinary-HIGH divider gating but allows endpoint progression/sampling only when filtered SCL is HIGH, otherwise reusing the exact recovery path.

Both are one-commit direct children of the qualified base. Only `rtl/nvp/nvp6134c_i2c_bringup.vhd` changes synthesizably. Independent inspection found no C1/C2 cross-contamination, and all 231 frozen tracked files match the base byte-for-byte.

## Verification summary

Candidate A passed its complete C1-aware inherited lifecycle, four-phase ACK/NACK timing, delayed-HIGH and broken-interval resampling coverage. Candidate B passed static 10/10 contract checks, endpoint-HIGH/LOW directed simulations, and the inherited suite. Each passed the three MMIO simulations and 40 host fixtures.

Build outcome: both images completed elaboration, synthesis, implementation, routing, timing, DRC and bitstream generation. C1 SHA-256 is `847B2ECE6BAD25A5802677D0125EF0C6A12C87B949E0AD96954500F30434534D`; C2 SHA-256 is `2092322C1C7A06A727691D8A666623FFE1C460CDD7B445DCD836293CAC5E5C1D`. Both reproduce C3's +0.617 ns setup and +0.036 ns hold margins.

The existing frozen MMIO identity registers embed all five Git words. Build provenance proves R1i-a and R1i-b reconstruct their exact, mutually distinct commits while leaving the ABI unchanged.

## Isolation and safety

- Qualified R1i and the active `C:\FPGA\FPGA_AHD` worktree remained unmodified.
- The two candidate builds use separate source and build roots with no checkpoint reuse.
- The earlier B wrapper startup race was terminated before project creation/design processing and quarantined; it did not contribute a build artifact.
- No SSH/DUT connectivity probe, JTAG, hardware manager, programming, MMIO, PCIe, DMA, driver, reboot or power-cycle action occurred.
- R1 stops after offline evidence publication. R2 remains outside this execution.

## Result

**PASS.** Both causally isolated firmware candidates are ready for a later R2 hardware comparison under the separate hardware lock. This execution stops after R1 offline evidence publication.
