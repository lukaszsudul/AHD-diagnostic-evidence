# Candidate-3 source scope

Stable parent `09cd7cbb426027acaefd0cf3989579b80a451f3a` to W3a candidate 3 `70266f0b90c6fc6a853495eba1d526b285fd7286`: exactly 12 changed paths, all in the approved W3a cone.

| Path | Scope |
|---|---|
| `rtl/g2b/g2b_nvp_camera_w3_telemetry.sv` | Replace wide W3 telemetry with compact persistent bank-failure/cleanup record and guarded pause controls. |
| `rtl/g2b/g2b_nvp_camera_scan1.sv` | Wire reduced W3a MMIO, record inputs and inherited candidate-2 pause gate; retain SCAN1 snapshot and BRAM. |
| `rtl/g2b/g2b_nvp_camera_scan1_acq1_compat0_r2.sv` | Explicit five-bit first-raw and reset wiring, W3a page decode. |
| `rtl/top/ahd_capture_top_xdma.sv` | Explicit five-bit first-raw and reset wiring, route W3a page. |
| `rtl/v41/nvp_i2c_fixed_master.sv` | Add observation-only per-command raw first-cause output; functional I2C FSM unchanged. |
| `host/w3a/__init__.py`, `contract.py`, `controller.py`, `decoder.py`, `device.py`, `resources/W3A_CONTRACT.json`, `host/w3a_launcher.py` | Versioned reduced ABI, fail-closed decoder and existing explicit BDF-bound node selection; no implicit device open during import. |

No active XDC, project-state SSOT, PCIe/DMA/capture, autoinit, NVP tables or vendor source was changed. Build recipes, frozen manifest, reports and read-back receipts are outside the source commit in the new task root. The omitted broad W3b arrays, successful-operation history and phase statistics are not in this synthesized candidate.
