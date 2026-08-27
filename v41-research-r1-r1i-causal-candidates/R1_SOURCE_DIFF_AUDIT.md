# AHD v41 R1 Source-Diff Audit

## Result

**PASS.** R1i-a and R1i-b are independent one-commit siblings of the frozen qualified R1i commit. Each candidate changes exactly one synthesizable tracked file, `rtl/nvp/nvp6134c_i2c_bringup.vhd`, plus add-only candidate-local research tests. All other 231 qualified-base tracked files are byte-identical.

## Frozen base and ancestry

| Item | R1i-a / C1 | R1i-b / C2 |
|---|---|---|
| Branch | `research/v41-r1i-a` | `research/v41-r1i-b` |
| Commit | `8b8ec0fa9c22965e46d0421c25e63d83e7971597` | `e4d10bb8e85e3797d078144fd0965e9625ee727c` |
| Tree | `a0fcbdbfb2b01049b357a8f8bf68bd448d6394f7` | `2658cf45e36c3dab81005117056b1f8e6cf3ddc1` |
| Direct parent | `20c3323d79d3896edc586d6db1df7deee60f9e41` | `20c3323d79d3896edc586d6db1df7deee60f9e41` |
| Merge base with qualified R1i | exact qualified commit | exact qualified commit |
| Commits above qualified R1i | 1 | 1 |
| Worktree at audit | clean | clean |

The pairwise merge base is the qualified R1i commit, and `git rev-list --left-right --count A...B` is `1 1`. Neither candidate is an ancestor of the other. The orchestration branch `research/v41-r1i-causal-isolation` remains clean at the qualified commit/tree `20c3323d...` / `70d801fd...`.

## Changed paths and diff checks

Candidate A changes three paths:

- `M rtl/nvp/nvp6134c_i2c_bringup.vhd`
- `A research_tests/r1i_a/run_r1i_a_focused_sim.ps1`
- `A research_tests/r1i_a/tb_r1i_a_c1_semantics.sv`

Its total patch is 601 insertions and 61 deletions; the allowlisted RTL contribution is 126 insertions and 61 deletions. `git diff --check` exits 0.

Candidate B changes six paths:

- `M rtl/nvp/nvp6134c_i2c_bringup.vhd`
- five add-only files under `research_tests/r1i_b/`

Its total patch is 589 insertions and 3 deletions; the allowlisted RTL contribution is 21 insertions and 3 deletions. `git diff --check` exits 0.

Both `research_tests` directories are excluded from the production synthesis file set. Full unified diffs are preserved as `R1I_A_SOURCE_DIFF.patch` and `R1I_B_SOURCE_DIFF.patch`.

## Frozen-file verification

The audit compared Git blob identities for every tracked qualified-base path other than the one allowlisted RTL file. Result for each candidate: 231 checked, 231 identical, 0 missing, 0 different. The per-file records are preserved in `R1I_A_FROZEN_FILE_VERIFICATION.txt` and `R1I_B_FROZEN_FILE_VERIFICATION.txt`.

This proves byte identity for the frozen top-level RTL, `rtl/v41`, autoinit, XDC, XDMA XCI, IP references, MMIO implementation and ABI documentation, build configuration, table data, and every other qualified tracked path.

## Contract isolation

Candidate A contains the two C1 selected-ACK registers and their four ACK-state capture/invalidate/terminal-decision paths. It has no C2 ordinary-HIGH predicate, divider bypass, or endpoint-abort delta.

Candidate B contains the C2 predicate with exactly the frozen 14 ordinary protocol-HIGH states. STOP_B and STOP_C are excluded and remain physically qualified. Candidate B has no selected-sample value or valid latch and no C1 capture path.

Programmatic added-line scans and independent review found no cross-contamination. The RTL SHA-256 values are:

| Source | SHA-256 |
|---|---|
| Qualified R1i | `C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68` |
| R1i-a | `6345A67E369A3AED2460722F9040B7DA1E80F0FFC142F9E33A87BEBEB89238A9` |
| R1i-b | `8121E4B2D8B0519B1D0718D8CFA97802389367FBF4948A4F371BE6D6B808E908` |

## State, fanout and protected-body audit

The ordered 42-state `t_state` declaration is identical in base, C1 and C2 (normalized SHA-256 `CC6A9630E0B5A19B12F9EA6E123D2511F60C377507B9D0B15CF836C86B4FD5A4`). The ordinal eight-bit debug encoding is also identical (`DA8807D4ED1996A8E9AF0EE8F62074F32E58D8C393127AD46FE48DDEE5F352AC`), and no enum/FSM encoding attribute exists in any cell.

C1 adds exactly two internal signals and no port, type, constant or state. Their fanout terminates only in the four ACK capture/helper/decision paths; no read-data, output-decoder, STOP, BUS_FREE, retry or bank-safety fanout exists. C2 adds no signal, latch, state, port or constant—only the 14-state local predicate with three call sites. The opposing candidate-specific identifier count is zero in each sibling.

Anchor-bounded byte projections prove base=A=B identity for STOP_A/B/C; ABORT_RELEASE and ABORT_HIGH_RECOVERY; BUS_FREE; RETRY_BACKOFF/RETRY_START; ATTEMPT_PREPARE; the complete STORE_RESULT retry/terminal/bank-safety body; READ_HIGH; synchronizer/filter; open-drain output decoder; timeout/retry constants; and the existing x07/timeout action bodies. Composite hashes are `1F795683...9009` for physical STOP/abort/BUS_FREE and `E1110095...16A3` for retry/terminal/bank behavior. Candidate B's four ACK_HIGH bodies are independently byte-identical to base, proving it retains live filtered terminal SDA sampling and contains no C1 latch logic.

`provenance/R1_SOURCE_SEMANTIC_AUDIT.txt` preserves all per-block hashes, state order, signal-reference counts, intentional divider/endpoint hashes, and the line-by-line functional-hunk mapping to numbered C1/C2 clauses.

## Protected worktrees

The qualified R1i worktree was not modified. The active `C:\FPGA\FPGA_AHD` worktree was read-only throughout R1 and remained clean at its pre-task commit/tree. No protected production or release branch was changed.
