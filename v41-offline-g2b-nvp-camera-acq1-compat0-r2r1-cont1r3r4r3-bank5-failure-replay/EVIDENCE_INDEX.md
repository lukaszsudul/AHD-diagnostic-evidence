# Evidence index — offline Bank5 failure replay

This is additive interpretation of the immutable COLDSTART evidence at `b1b12524d41435aad49d7ce7662af26981682143`. It does not overwrite its `FAIL` outcome. Publication commit and commit-pinned remote read-back are deliberately reported outside the hashed payload after the commit exists.

## Decision and authority

- `V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R4R3_BANK5_OFFLINE_MAIN_REPORT.md`
- `AUTHORITY_AND_SCOPE.md`
- `HISTORICAL_SIGNATURE.json`
- `SSOT_HASH_RECEIPT.json`
- `STATE.json`

## Source and simulation findings

- `SOURCE_CAUSE_AND_SCHEDULE_AUDIT.md`
- `MASTER_TO_SCANNER_CAUSE_MAP.csv`
- `SIMULATION_TEST_MATRIX.csv`
- `FAILURE_SIGNATURE_COMPARISON.csv`
- `REACHABILITY_AND_AMBIGUITY.md`
- `HARNESS_ITERATIONS.md` — three bounded task-owned correction rounds; frozen design unchanged.
- `simulation-receipts/` — compact task-owned mock/pin simulation logs, including T02 and T15 byte/ACK traces. No private RTL or board waveform is included.

## Existing-record review and reproducibility

- `REGADDR_EXISTING_EVENTS_REVIEW.md`
- `REGADDR_EXISTING_EVENTS.csv` — sanitized rows derived from 26 private complete raw records using frozen host schema; no raw payload.
- `PRIVATE_REANALYSIS_RECEIPT.json`
- `NEXT_ONE_ACTION.md`
- `reproducer/tb_bank5_mock.sv`, `reproducer/tb_bank5_pin.sv`, `reproducer/replay_private.py`, `reproducer/run_offline.py` — task-authored harness/checker/launcher only. To reproduce, obtain frozen RTL from exact source commit and the controller-held private archive separately; neither is republished here.
- `SHA256_MANIFEST.txt` — hashes of every other file in this new evidence directory.

Complete raw records, original archive, compiled private RTL copies, bitstream, DCP, driver, vendor material, credentials, camera pixels and full simulator working directory stay private.
