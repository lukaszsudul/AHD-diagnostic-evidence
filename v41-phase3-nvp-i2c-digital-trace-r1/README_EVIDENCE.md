# AHD Capture Card — v41 Phase 3 NVP/I2C Digital Trace R1

This directory is a sealed diagnostic-evidence publication for independent
review. It documents one ephemeral, observer-only FPGA image used to capture
the internal digital I2C state surrounding the first NVP NACK. It is not a
release candidate and contains no authorized functional correction.

## Evidence identity

```text
PROJECT=AHD Capture Card
TEST_PURPOSE=EPHEMERAL_OBSERVER_ONLY_NVP_I2C_FIRST_NACK_DIGITAL_TRACE
FORMAL_BASELINE_TAG=v41.0.0-phase2-p2
FORMAL_BASELINE_CHECKPOINT_COMMIT=c89e88bcdf389614c884fb129e8b2d42a585bccb
BASE_FUNCTIONAL_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
DIAGNOSTIC_PATCH_SHA256=0D7BD2907296D65401D83EF9F41CF7270940DF4FB392264C32B76E455CD45A6F
DIAGNOSTIC_SOURCE_MANIFEST_SHA256=3C415A97490E723829E6DE3A1B9F2CDE0F3A2A5AE605A1996A613A50CAF597BD
DIAGNOSTIC_BIT_SHA256=DA7489BD3458A0DFD5FC8F86D1E3CD90F2DFCAC8CE7FA87D0CC5AD7307B459E3
MEASUREMENT_PACKAGE_SHA256=0C204F94A6C6CE228F60AAD63752F5C7BFAAABF4D9B726CEA615B3ADA2A99732
BUILD_PACKAGE_SHA256=91642DBA5F12317EB56FF6C65BD1A3AD582FCA60022E7C0851FB03FFBB7FAADA

PRIMARY_CLASSIFICATION=NO_DIGITAL_ACK_OBSERVED_AT_FPGA_INPUT_PATH_AT_DECISION_STROBE
IMPORTANT_TRACE_RESULT=ALL_SDA_STAGES_LOW_FOR_9_888_US_WHILE_SCL_HIGH; FSM_DECIDED_NACK_APPROX_10_000_US_LATER_WHILE_SCL_LOW_AND_SDA_HIGH

FORMAL_BASELINE_RESTORED=YES
FORMAL_PROJECT_REPOSITORY_MUTATIONS=0
PHASE3_RESUMED=NO
FUNCTIONAL_I2C_CHANGE=NO
RELEASE_CANDIDATE=NO
```

## Reading order

1. `reports/V41_NVP_EPHEMERAL_DIGITAL_TRACE_REPORT.md`
2. `reports/FPGA_FIRST_ERROR_VS_TRACE_CORRELATION.md`
3. `trace/TRACE_SCHEMA.md`
4. `trace/ACK_DECISION_FOCUSED.csv`
5. `trace/TRACE_DECODED.csv`
6. `diagnostic_patch/DIAGNOSTIC_TAP_WHITELIST.md`
7. `build_gates/OFFLINE_GATE_MATRIX.md`
8. `audit/FORMAL_RESTORE_RESULT.md`
9. `audit/FORMAL_REPOSITORY_NO_CHANGE_PROOF.md`

`trace/TRACE_RAW.bin` is the frozen 4096 × 64-bit capture. The build ZIP is
stored through Git LFS; the measurement ZIP and all other evidence are normal
Git objects. The package SHA-256 files are authoritative for package-level
verification.

## Scientific limitation

The observer records digital states inside the FPGA. It does not measure
analog voltage, threshold margin, edge rate, ringing, rail droop, or ground
bounce. The evidence therefore supports a timing/phase diagnosis but does not
exclude an electrical contribution.

