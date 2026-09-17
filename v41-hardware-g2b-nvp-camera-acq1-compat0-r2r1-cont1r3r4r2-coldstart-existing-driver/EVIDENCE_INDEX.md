# Evidence index — CONT1R3R4R2 cold-start characterization

This append-only directory records one Owner-attested whole-DUT cold-start
experiment and a **failed, incomplete** 1,000-scan campaign. Evidence
publication is pending while this package is staged; the final commit and
commit-pinned read-back are reported separately after the one commit exists.

## Decision and authority

- `V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R4R2_COLDSTART_MAIN_REPORT.md`
- `OWNER_COLDSTART_AUTHORIZATION.md`
- `AUTHORITY_AND_SCOPE.md`
- `PRE_COLD_SURVEY.json`
- `AUTOSTART_ATTRIBUTION.md`
- `POST_COLD_SURVEY.json`
- `POST_COLD_ADMISSION_DECISION.md`
- `PROTECTED_FUNCTION_LIFECYCLE.md`
- `COLD_START_LEDGER.json`

## Activation and runtime

- `PROGRAMMING_RECEIPT.md`
- `ACTIVATION_RUNTIME_RECEIPT.md`
- `RUNTIME_BUNDLE_MANIFEST.json`
- `CAMPAIGN_CONTEXT_ADDENDUM.md`

## Actual measurement and hard stop

- `CAMPAIGN_CHECKPOINT.json`
- `CAMPAIGN_PROGRESS.csv`
- `EVENTS_SUMMARY.csv`
- `EXPOSURE_SUMMARY.csv`
- `PRIVATE_RAW_DATA_MANIFEST.json` (hashes and sizes only; binary raw records are not published)
- `CAMPAIGN_ANALYSIS.md`
- `HARD_STOP_RECEIPT.md`
- `CLEANUP_RECEIPT.md`
- `CONTROLLER_LOCK_RELEASE.md`

## Verification and host source

- `GATE_MATRIX.csv`
- `STATE.json`
- `SHA256_MANIFEST.txt`
- `host-source/` — selected task-owned admission, bundle, mapping,
  guarded-execution, hard-stop and cleanup adapters/tests. These do not
  contain a credential or alter the frozen FPGA/driver/runtime-bundle files.

The complete controller-private archive is at
`C:\FPGA\G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R4R2_COLDSTART_20260917T063836Z\private\characterization-hardstop.tar.gz`,
108,145 bytes, SHA-256
`96080348A26E00ECF8B4DBA58F6E691EBAD48F2D8B0C3DDC2EC474A316E6A0CB`.
It contains one control plus 25 complete campaign raw records, event and
exposure logs. It is intentionally not committed. No vendor material,
bitstream, DCP, driver binary, credential, camera pixel or raw video is
included here.
