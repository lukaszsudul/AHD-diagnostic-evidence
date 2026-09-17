# Evidence index — CONT1R3R4R4-I2C-OFFLINE

This is an offline, source-frozen digital experiment and documentary review. The report distinguishes design simulation, historical hardware evidence and unverified assembled-board behavior. The [main report](V41_G2B_NVP_CAMERA_ACQ1_COMPAT0_R2R1_CONT1R3R4R4_I2C_OFFLINE_MAIN_REPORT.md) is the entry point. Publication/read-back status is deliberately not predeclared inside this immutable package; the final external receipt is evaluated after push.

## Authority and experiment

- [Authority and no-touch scope](AUTHORITY_AND_SCOPE.md); [frozen experiment contract](EXPERIMENT_CONTRACT.md); [timing rules](TIMING_RULES.json).
- [214-case preregistered matrix](CASE_MATRIX.csv); [joined case results](CASE_RESULTS.csv); [transparent CSV export repair](CASE_RESULTS_EXPORT_RECEIPT.md); [three checker amendments](HARNESS_AMENDMENTS.md).
- [Source timing audit](SOURCE_TIMING_AUDIT.md); [resolved-bus model validation](MODEL_VALIDATION.md); [20 named check results](TEST_RESULTS.md); [independent audit counts and negative tests](INDEPENDENT_AUDIT.json); [independent per-case compliance classes](INDEPENDENT_COMPLIANCE.csv); [selected event timelines](TIMING_BOUNDARY_TIMELINES.md).

## Status, canary and documentary sources

- [Raw-cause lifetime](RAW_CAUSE_LIFETIME.md); [reset-canary candidate matrix](RESET_CANARY_FEASIBILITY.csv); [canary decision](RESET_CANARY_DECISION.md).
- [NVP6134C and pinned reference findings](NVP_REFERENCE_FINDINGS.md); [Rev0.1 PCB documentary findings and as-built limit](PCB_RESET_I2C_FINDINGS.md).
- [Future single-image first-frame design note, not implemented](FUTURE_SINGLE_IMAGE_FIRST_FRAME_PLAN.md); [one next action](NEXT_ONE_ACTION.md).

## Reproduction and provenance

- [State at report freeze](STATE.json); [private artifact identities, not proprietary bytes](PRIVATE_ARTIFACT_MANIFEST.json); [SHA-256 for the public file set](SHA256_MANIFEST.txt).
- Task-owned host sources: [case generator](host-source/make_case_matrix.py), [sweep/checker](host-source/run_grid.py), [independent audit](host-source/audit_results.py).
- Task-owned simulator sources: [resolved-bus bench](simulation-source/tb_i2c_timing.sv), [delayed-rise cancellation negative](simulation-source/tb_delay_cancel.sv), [scanner integration bench](simulation-source/tb_scanner_stretch.sv).
- Selected retained originals: [clean scanner stretch](simulation-receipts/SCANNER_STRETCH_CLEAN.log), [scanner timeout](simulation-receipts/SCANNER_STRETCH_TIMEOUT.log), [delay-cancellation negative](simulation-receipts/MODEL_DELAY_CANCELLATION.log), [case16 last sampled success](simulation-receipts/case_0016.log), [case17 local timeout](simulation-receipts/case_0017.log), [case211 invalid early release](simulation-receipts/case_0211.log). Each selected case also has a companion resolved-pin CSV in the exact published file set. The complete 214 logs and 214 pin traces remain private with individual identities in the private manifest.

No vendor PDF/source, PCB design file, frozen FPGA source, bitstream, DCP, driver, credentials, camera pixels or video is included. For all public files other than the self-excluded hash manifest, the manifest records relative path, size and SHA-256; the public file set is checked again against a commit-pinned independent read-back.
