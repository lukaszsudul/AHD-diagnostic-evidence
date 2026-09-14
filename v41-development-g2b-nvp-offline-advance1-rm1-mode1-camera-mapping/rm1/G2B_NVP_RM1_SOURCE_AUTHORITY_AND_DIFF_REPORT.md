# G2B NVP DIAG2-RM1 source authority and exact-diff report

## Frozen identity

- Branch: `diag/v41-g2b-nvp-video-diag2-rm1`
- Parent: `fc37d815b5d64ef90dfbd99c57ae4cc09567b56f`
- Commit: `a7436eb81f69f09ee84301bcf214fcaa2b680ee8`
- Tree: `cce4a561a30d58d4accc2a45e4eb8d72e5a7ec26`
- Direct-parent gate: `PASS`
- Clean committed worktree: `PASS`
- Remote branch read-back: `PASS`
- Fresh no-checkout commit-pinned blob read-back: `PASS 11/11`
- Hardware accessed: `NO`

The remote commit, tree and parent were read from a fresh task-local no-checkout
clone. Every governed blob was read by its commit-pinned Git object identity.
Remote blob bytes, local commit bytes and committed worktree bytes matched for
all eleven files.

## Exact parent-to-commit change set

| Status | Path |
|---|---|
| M | `rtl/g2b/v41_g2b_onech_c2h.sv` |
| M | `rtl/top/ahd_capture_top_xdma.sv` |
| A | `rtl/diagnostic/g2b_nvp_raw_marker_monitor.sv` |
| A | `rtl/diagnostic/g2b_nvp_rm1_route_controller.sv` |
| A | `rtl/g2b/g2b_nvp_video_diag2_rm1.sv` |
| A | `tests/nvp_video_diag/check_nvp_diag2_rm1_contract.ps1` |
| A | `tests/nvp_video_diag/run_nvp_diag2_rm1_focused_gate.ps1` |
| A | `tests/nvp_video_diag/tb_g2b_nvp_diag2_rm1_focused.sv` |
| A | `tests/nvp_video_diag/tb_g2b_nvp_rm1_parser_tap.sv` |
| A | `tests/nvp_video_diag/tb_g2b_nvp_rm1_route_controller.sv` |
| A | `xdc/common/g2b_nvp_diag2_rm1_cdc.xdc` |

`git diff --check` passed. Rename/copy detection with `--find-copies-harder`
reported no rename or copy record and no extra or missing path.

## Read-back receipt

`source-readback-a7436eb/G2B_NVP_DIAG2_RM1_PUBLICATION_READBACK_RECEIPT.json`

Receipt SHA-256:
`78160F4A73DDDA1EB074B7EBFD05F0989D3173DB777909EDBF0207B9D4A86C7B`

