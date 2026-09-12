# Source diff

- Branch: `diag/v41-g2b-nvp-camera-acq1-compat0`.
- Parent: `c7e16fa3da26545cef960a6c75427a3614c4b655`.
- Commit: `dae2aff60141ecdbc0afac08fc0df9a3166f66c6`.
- Tree: `21e33d481ef637667756caa8015e7fa1b1dd8ebf`.
- Changed files: `24`.
- Canonical `git diff --binary parent commit` SHA-256: `61EA23F2582F911D8A247B03522148D7EDFD0BE6B3AB433EA45C730D2A4C8876`.
- PRODUCT branch/source changed: `NO`.
- Transport ABI changed: `NO`.

## Diff stat

```text
host/acq1_compat0_r2/__init__.py                   |    3 +
 host/acq1_compat0_r2/campaign.py                   |  246 +++++
 host/acq1_compat0_r2/contract.py                   |   81 ++
 host/acq1_compat0_r2/controller.py                 |  209 ++++
 host/acq1_compat0_r2/evidence.py                   |   37 +
 host/acq1_compat0_r2/format_decision.py            |   58 ++
 host/acq1_compat0_r2/mmio.py                       |   75 ++
 host/acq1_compat0_r2/policy.py                     |   34 +
 ...P_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.json |   48 +
 ...NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.md |    8 +
 ...G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json |   68 ++
 .../G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.md  |   26 +
 .../resources/G2B_NVP_ACQ1_COMPAT0_R2_PROFILE.json |   13 +
 ...2B_NVP_ACQ1_COMPAT0_R2_REGISTER_SAFETY_AUDIT.md |   12 +
 host/acq1_compat0_r2_campaign_launcher.py          |   14 +
 host/acq1_compat0_r2_launcher.py                   |   14 +
 rtl/g2b/g2b_nvp_acq1_compat0_r2.sv                 | 1006 ++++++++++++++++++++
 rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv    |  135 +++
 rtl/top/ahd_capture_top_xdma.sv                    |   68 +-
 scripts/acq1_compat0_r2/build_runtime_bundle.py    |  179 ++++
 tests/acq1_compat0_r2/check_static_contract.py     |  121 +++
 tests/acq1_compat0_r2/run_acq1_compat0_r2_gate.ps1 |  136 +++
 .../acq1_compat0_r2/tb_g2b_nvp_acq1_compat0_r2.sv  |  360 +++++++
 tests/acq1_compat0_r2/test_host_policy.py          |   59 ++
 24 files changed, 3002 insertions(+), 8 deletions(-)
```

## Changed paths

- `host/acq1_compat0_r2_campaign_launcher.py`
- `host/acq1_compat0_r2_launcher.py`
- `host/acq1_compat0_r2/__init__.py`
- `host/acq1_compat0_r2/campaign.py`
- `host/acq1_compat0_r2/contract.py`
- `host/acq1_compat0_r2/controller.py`
- `host/acq1_compat0_r2/evidence.py`
- `host/acq1_compat0_r2/format_decision.py`
- `host/acq1_compat0_r2/mmio.py`
- `host/acq1_compat0_r2/policy.py`
- `host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.json`
- `host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_FORMAT_DECISION_MANIFEST.md`
- `host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.json`
- `host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_OPERATION_MANIFEST.md`
- `host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_PROFILE.json`
- `host/acq1_compat0_r2/resources/G2B_NVP_ACQ1_COMPAT0_R2_REGISTER_SAFETY_AUDIT.md`
- `rtl/g2b/g2b_nvp_acq1_compat0_r2.sv`
- `rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv`
- `rtl/top/ahd_capture_top_xdma.sv`
- `scripts/acq1_compat0_r2/build_runtime_bundle.py`
- `tests/acq1_compat0_r2/check_static_contract.py`
- `tests/acq1_compat0_r2/run_acq1_compat0_r2_gate.ps1`
- `tests/acq1_compat0_r2/tb_g2b_nvp_acq1_compat0_r2.sv`
- `tests/acq1_compat0_r2/test_host_policy.py`
