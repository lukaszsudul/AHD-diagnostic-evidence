# W4 evidence index

- `W4_MAIN_REPORT.md`: gates, runtime, measurement, cleanup, limits.
- `W4_AUTHORITY_AND_OWNER_SCOPE.md`: governing scope and pinned release identities.
- `W4_PLAN.json`: frozen 16-block plan.
- `W4_LOCAL_BUNDLE_MANIFEST.json`, `W4_DUT_BUNDLE_GATE.json`: closed host bundle and DUT gate.
- `W4_DEPLOYMENT_RECEIPT.json`, `W4_RUNTIME_AND_MAPPING_RECEIPT.json`: SRAM program, runtime and target identity.
- `W4_BLOCKS.csv`, `W4_SCAN_SUMMARY.csv`, `W4_ERROR_EVENTS.csv`: all blocks, all 256 scan summaries, and recovered event rows (header only because none occurred).
- `W4_AB_DECISION.md`: denominator-correct effect classification.
- `W4_HARD_STOP_RECEIPT.json`, `W4_PRECHECK_CORRECTION.json`, `W4_LOCAL_COPY_RECOVERY_RECEIPT.json`: initial host preflight false reject, bounded correction, and retained evidence identity.
- `W4_CLEANUP_RECEIPT.json`, `W4_STATE.json`, `W4_GATE_MATRIX.csv`, `W4_GATE_MATRIX.json`: final state and gate receipts.
- `W4_PRIVATE_RAW_MANIFEST.json`: exact DUT file paths, byte sizes and hashes for all 532 private data files; raw snapshots stay on private controller storage.
- `w4_coordinator.py`, `analyze_w4.py`: task-local coordinator and report/verification source; no credentials or vendor materials.
- `SHA256_MANIFEST.txt`: hashes of every public file except itself.

The immutable report carries `PENDING_REMOTE_READBACK`. The final publication receipt is held beside the private task root after independent remote read-back of the exact commit.
