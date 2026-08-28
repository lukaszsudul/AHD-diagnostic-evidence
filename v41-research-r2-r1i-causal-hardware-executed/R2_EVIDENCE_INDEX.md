# R2 Evidence Index

## Required evidence

| Evidence | Path | Purpose |
|---|---|---|
| Package overview | `README.md` | Result and preservation summary |
| Main report | `R2_CAUSAL_HARDWARE_REPORT.md` | Engineering/scientific adjudication |
| Frozen run matrix | `R2_RUN_MATRIX.csv` | Exact 32-run order, all not run |
| Raw result schema | `R2_RAW_RESULTS.csv` | Required per-run fields; no fabricated rows |
| Cold-start matrix | `R2_COLD_START_10X.csv` | Ten formal trials, all not run |
| Timing matrix | `R2_INIT_DONE_TIMING.csv` | Timing protocol status |
| Lock receipt | `R2_HARDWARE_LOCK_RECEIPT.md` | Failed acquire/ownership proof |
| Cold-reset receipt | `R2_COLD_RESET_BASELINE_RECEIPT.md` | Live SSH/PCIe/JTAG state |
| Runtime receipt | `R2_RUNTIME_IDENTITY_RECEIPT.md` | Artifact identities and harness gate |
| Final-state receipt | `R2_FINAL_STATE_RECEIPT.md` | Terminal SSH/PCIe/JTAG read-only verification |
| Statistical summary | `R2_STATISTICAL_SUMMARY.md` | Frozen denominator and no inference |
| Machine state | `R2_STATE.json` | Machine-readable blocked state |
| Publication receipt | `R2_PUBLICATION_RECEIPT.md` | Remote main content/read-back closure |
| Integrity manifest | `R2_SHA256_MANIFEST.txt` | SHA-256 of published package files |

## Supporting evidence

- `R2_RUNTIME_IDENTITY_HARNESS_SELFTEST.txt`
- `tools/r2_runtime_identity_readonly.py`
- `raw/REMOTE_IDENTITY.txt`
- `raw/REMOTE_LOCK_INVENTORY.txt`
- `raw/REMOTE_LOCK_REFERENCES.txt`
- `raw/REMOTE_PCIE_DRIVER_PREFLIGHT.txt`
- `raw/REMOTE_PCIE_TOPOLOGY.txt`
- `raw/JTAG_DONE_SAMPLES_SANITIZED.csv`
- `raw/REMOTE_FINAL_CHECKPOINT_SANITIZED.txt`
- `raw/JTAG_FINAL_DONE_SAMPLES_SANITIZED.csv`

The published JTAG sample matrix omits the unique cable/target serial while retaining part, IDCODE, DONE, timestamps, and zero-programming evidence. No credential or password is present.
