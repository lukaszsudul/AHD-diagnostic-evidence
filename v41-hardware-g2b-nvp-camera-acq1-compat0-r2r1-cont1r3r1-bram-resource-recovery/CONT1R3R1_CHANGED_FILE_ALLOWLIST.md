# Candidate 1 changed-file allowlist and source seal

The candidate is a clean, direct child of `dc73d486bf0d68e52dc394dd731031e8598212f5` with commit `09cd7cbb426027acaefd0cf3989579b80a451f3a`, tree `c6be008ddc387c1f43eefa35d4fed0e2ccb968db`, on branch `diag/v41-g2b-nvp-camera-cont1r3r1-bram-recovery-20260916T105442Z`. The primary `C:\FPGA\FPGA_AHD` worktree and PRODUCT authority were not modified.

The exact tracked diff contains only:

| Path | Disposition |
|---|---|
| `rtl/g2b/g2b_nvp_camera_scan1.sv` | BRAM-backed new telemetry payload, linear synchronous read path, writer/publication barrier and read-only implementation ID. |
| `host/cont1r3/contract.py` | New implementation ID constants only. |
| `host/cont1r3/telemetry.py` | Require new implementation ID and bounded complete/frozen readiness. |
| `host/cont1r3/resources/CONT1R3R1_IMPLEMENTATION_IDENTITY.json` | Separate implementation-extension contract. |
| `tests/cont1r3/tb_g2b_nvp_camera_scan1_cont1r3.sv` | Exact parent payload and non-telemetry cycle comparisons. |
| `tests/cont1r3/test_cont1r3_offline.py` | Correct same-edge verify assertion; no relaxed functional expectation. |

Unchanged authorities include the exact scanner manifest package, low-level I²C master, combined wrapper, ACQ executor, clock/reset/PCIe/DMA path, IP and XDC. No changed file is outside the Owner-authorized storage/readout/identity/test/host cone. Supplemental simulation, bundle and build harness files live only in the fresh task root and do not alter the frozen source tree.
