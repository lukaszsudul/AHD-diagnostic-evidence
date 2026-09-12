# Clean-room source map

- Fixed executor: `source/rtl/g2b/g2b_nvp_acq1_compat0_r2.sv`.
- SCAN1/executor arbitration and MMIO integration: `source/rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv` and `source/rtl/top/ahd_capture_top_xdma.sv`.
- Operation checker: `source/tests/acq1_compat0_r2/check_static_contract.py`.
- Format decision: `source/host/acq1_compat0_r2/format_decision.py`.
- Host controller and baseline/rollback policy: `source/host/acq1_compat0_r2/controller.py`, `campaign.py`, and `policy.py`.
- Runtime bundle builder: `source/scripts/acq1_compat0_r2/build_runtime_bundle.py` (not executed after the blocker).
- Evidence helpers/aggregator: `source/host/acq1_compat0_r2/evidence.py` and `generate_acq1_compat0_r2_evidence.py`.
- Failed evidence harness: `source/task-local/g2b_nvp_camera_acq1_compat0_r2_build.tcl`.

No pinned reference-driver source is included.
