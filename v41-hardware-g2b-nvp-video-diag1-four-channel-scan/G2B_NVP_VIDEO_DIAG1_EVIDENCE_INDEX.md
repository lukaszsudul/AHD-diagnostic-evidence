# Evidence index

This directory contains the authoritative offline result for G2B-NVP-VIDEO-DIAG1. The task reached register authority, source implementation, simulation, commit publication, synthesis, and optimization. It stopped at the post-opt LUT resource gate before hardware.

Key files:

- `V41_G2B_NVP_VIDEO_DIAG1_MAIN_REPORT.md` — overall decision
- `G2B_NVP_VIDEO_DIAG1_REGISTER_AUTHORITY.md` — PDF/source-backed register contract
- `G2B_NVP_VIDEO_DIAG1_SIMULATION_REPORT.md` — 16/16 gate
- `G2B_NVP_VIDEO_DIAG1_BUILD_REPORT.md` — exact build stop
- `G2B_NVP_VIDEO_DIAG1_RESOURCE_REPORT.md` — measured utilization and correction target
- `G2B_NVP_VIDEO_DIAG1_STATE.json` — machine-readable state
- `raw-build/` — preserved non-camera Vivado evidence
- `raw-simulation/` — final simulation receipts/logs
- `source/` — diagnostic and host source used for this run

CSV hardware tables contain headers only because the hardware phase was not reached. No raw camera data or generated hardware artifacts are published.
