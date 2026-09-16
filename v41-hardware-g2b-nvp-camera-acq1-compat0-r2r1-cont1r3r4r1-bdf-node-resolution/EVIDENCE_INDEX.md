# CONT1R3R4R1 evidence index

This append-only package records a **BLOCKED** engineering admission decision before hardware intervention. It intentionally contains no dummy scan, MMIO, firmware-programming or runtime-identity output.

| File | Purpose |
| --- | --- |
| `V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R4R1_MAIN_REPORT.md` | Outcome, causal model and hard stop |
| `AUTHORITY_AND_SCOPE.md` | Exact source/artifact and Owner scope |
| `LIVE_PCI_DRIVER_NODE_MAP.json` | Current BDF/driver/module/node ancestry |
| `LOADED_MODULE_VS_DISK_IDENTITY.md` | Distinct live and on-disk module metadata |
| `NAMESPACE_AND_PROBE_IMPACT_DECISION.md` | Exact class conflict and Path C admission |
| `NON_TARGET_PRESERVATION_RECEIPT.md` | Before/after no-touch comparison |
| `GATE_MATRIX.csv` | First failed gate and unreached downstream work |
| `STATE.json` | Machine-readable task state |
| `SHA256_MANIFEST.txt` | Payload hashes; excludes itself |
| `host-source/readonly_live_mapping_survey.py` | Executed read-only initial collector |
| `host-source/readonly_module_identity_followup.py` | Executed exact-file metadata follow-up |
| `host-source/readonly_preservation_verify.py` | Executed post-decision preservation check |

Private, nonpublished connection receipts remain under `C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R4R1_20260916T215125Z\logs`; their hashes are in `LIVE_PCI_DRIVER_NODE_MAP.json`. No credentials, full unrelated process command lines, firmware, DCP, driver binary, vendor source/PDF, camera pixels or raw video are in this package.

The Git commit and independent commit-pinned remote byte/size/hash read-back are publication controls performed after the payload is finalized, not assertions embedded before commit.
