# G2B-HW0-PRODUCT-R3 evidence index

State: **CONTROLLER-LOCAL PUBLIC STAGING; PUBLICATION PENDING**

All user-required report/CSV/JSON filenames are present except the SHA-256
manifest, which is intentionally left to the final validator after the package
is complete.

## Required artifacts

- `V41_G2B_HW0_PRODUCT_R3_MAIN_REPORT.md`
- `G2B_HW0_PRODUCT_R3_AUTHORIZATION_RECEIPT.md`
- `G2B_HW0_PRODUCT_R3_AUTHORITY_VERIFICATION.md`
- `G2B_HW0_PRODUCT_R3_DUT_LOCK_RECEIPT.md`
- `G2B_HW0_PRODUCT_R3_PRELOAD_INVENTORY.md`
- `G2B_HW0_PRODUCT_R3_DRIVER_VERIFICATION.md`
- `G2B_HW0_PRODUCT_R3_DRIVER_LOAD_PROBE.md`
- `G2B_HW0_PRODUCT_R3_NODE_TO_BDF_PROOF.md`
- `G2B_HW0_PRODUCT_R3_NODE_MAP.csv`
- `G2B_HW0_PRODUCT_R3_MMIO_RAW.csv`
- `G2B_HW0_PRODUCT_R3_MMIO_DECODED.md`
- `G2B_HW0_PRODUCT_R3_NVP_VIDEO_READINESS.md`
- `G2B_HW0_PRODUCT_R3_FIRST_RECORD_REPORT.md`
- `G2B_HW0_PRODUCT_R3_FIRST_RECORD_HEADER.csv`
- `G2B_HW0_PRODUCT_R3_FINITE_CAPTURE_REPORT.md`
- `G2B_HW0_PRODUCT_R3_FINITE_CAPTURE_METRICS.csv`
- `G2B_HW0_PRODUCT_R3_FRAME_RECONSTRUCTION_REPORT.md`
- `G2B_HW0_PRODUCT_R3_CONTINUOUS_CAPTURE_REPORT.md`
- `G2B_HW0_PRODUCT_R3_CONTINUOUS_METRICS.csv`
- `G2B_HW0_PRODUCT_R3_COUNTER_RECONCILIATION.md`
- `G2B_HW0_PRODUCT_R3_PCIE_AER_KERNEL_LOG_REVIEW.md`
- `G2B_HW0_PRODUCT_R3_CLEANUP_RECEIPT.md`
- `G2B_HW0_PRODUCT_R3_FINAL_HARDWARE_STATE.md`
- `G2B_HW0_PRODUCT_R3_GATE_MATRIX.csv`
- `G2B_HW0_PRODUCT_R3_STATE.json`
- `G2B_HW0_PRODUCT_R3_EVIDENCE_INDEX.md`
- `G2B_HW0_PRODUCT_R3_SHA256_MANIFEST.txt` — validator-generated last

## Tool source

- `tools/` contains full publishable source of task-specific tools actually
  executed, with status mapping in `tools/SOURCE_PROVENANCE.csv`.
- The connection helpers and their prior-R1 dependency remain controller-only
  because credential-handling source is inside the protected credential
  boundary. Only hashes and execution disposition are published.
- The prior-R2 JTAG TCL historical dependency is disclosed and included; its
  run is superseded by the R3-local selector/session source and evidence.
- `tools/unexecuted/` contains the full MMIO/C2H qualification source written
  but not executed.
- `tools/T1_DRAFT_SAFETY_REVIEW.md` records hashes and findings for the
  unexecuted unsafe T1 trio; the unsafe source bodies are excluded.

## Exclusions

No `.ko`, secret/credential, raw log, C2H record, raw frame, reconstructed
image, or camera payload is present. Raw controller/DUT evidence remains sealed
outside public staging.

## Publication target

- repository: `lukaszsudul/AHD-diagnostic-evidence`
- branch: `main`
- directory: `v41-hardware-g2b-hw0-product-live-path-bringup-r3`
- commit: NONE
- push/read-back: NOT_RUN
