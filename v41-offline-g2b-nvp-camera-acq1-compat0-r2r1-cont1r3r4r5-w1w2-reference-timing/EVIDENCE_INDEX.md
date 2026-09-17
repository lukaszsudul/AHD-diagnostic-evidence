# Evidence index — CONT1R3R4R5 W1/W2 offline

The [main report](V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R4R5_W1W2_MAIN_REPORT.md) summarizes the combined engineering result. W1/W2 are offline analysis and minimal simulation. The package does not contain vendor code/PDFs, frozen FPGA source, hardware data, driver/bitstream/DCP, credentials or camera frames. Publication and commit-pinned read-back are evaluated separately after the immutable package is committed.

## Authority and W1 timing

- [Authority, SSOT state and scope](AUTHORITY_AND_SCOPE.md)
- [Source timing derivation](W1_TIMING_DERIVATION.md), [required resolved-line gaps](W1_TRANSACTION_GAPS.csv), [XSim receipt](W1_MINIMAL_SIMULATION_RECEIPT.md)
- [Task-owned checker](host-source/extract_w1_gaps.py), [pin-level simulation bench](simulation-source/tb_w1_clean_scan.sv), [concise edge proof](simulation-receipts/W1_PUBLIC_PROOF_LOG.txt), [negative checker proof](simulation-receipts/W1_CHECKER_PROOF.txt)

## W2 path and decision

- [Executed FPGA path, reference conditions and counts](W2_ACTIVE_PATH_AND_COUNTS.md)
- [Scoped Bank5 and sequence differences](W2_SEQUENCE_DIFF.csv), [all 11 current event rows](W2_CURRENT_EVENT_REVIEW.csv)
- [Task-owned W2 extractor](host-source/extract_w2.py)
- [Joint decision and minimum W3 handoff](W1W2_DECISION_AND_W3_HANDOFF.md)

## Provenance

- [State at package freeze](STATE.json)
- [Private artifact identities, not bytes](PRIVATE_ARTIFACT_MANIFEST.json)
- [SHA-256 and sizes of every other public file](SHA256_MANIFEST.txt)

The full XSim trace and bounded reference/table ledgers remain private with byte hashes. Historical 214-case receiver tests, 25 complete hardware scans, 11 recovered first-attempt read events and the separate Bank5 hard stop are inherited at their pinned evidence commits, not re-executed here.
