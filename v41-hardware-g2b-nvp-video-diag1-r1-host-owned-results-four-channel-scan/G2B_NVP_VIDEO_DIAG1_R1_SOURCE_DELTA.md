# Source delta

Branch: `diag/v41-g2b-nvp-video-scan`

Failed-DIAG1 baseline: `bed970032dd4acdfbb2cf254f3e21ebcfb60c6f1`

Intermediate result-storage commit: `e212cd4c9928ede75ef8efce47f938fd10cb48bf`

Final commit's direct parent: `e212cd4c9928ede75ef8efce47f938fd10cb48bf`

R1 commit: `fcab95726761a0666a67e31c283dbdfb9e775074`

R1 tree: `bbf1a5fee70a2eb68bb96305ed10934a1559ca6a`

The bounded two-commit correction moved result history to the host and added
exact timing-boundary simulation assertions. Changed files across the bounded
R1 delta were:

- `rtl/g2b/g2b_nvp_video_diag.sv`
- `tests/nvp_video_diag/run_nvp_video_diag1_sim.ps1`
- `tests/nvp_video_diag/tb_g2b_nvp_video_diag.sv`

The branch was pushed normally. The PRODUCT branch was not modified.
Transport ABI, PRODUCT MMIO, XDMA, VDO XDC, and BT.656 FIX1 behavior were not
changed.
