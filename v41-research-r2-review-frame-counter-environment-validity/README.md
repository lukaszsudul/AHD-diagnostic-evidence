# AHD v41 R2 Measurement Review

This package is an offline forensic review of the halted Owner-mediated R2 evidence. It does not modify the DUT, firmware, drivers, FPGA configuration, evidence source, SSOT, or any historical run receipt.

## Review result

- Review gate: `PASS`
- Primary review result: `MEASUREMENT_ARTIFACT_PROBABLE`
- Confidence: `HIGH`
- Quantization mechanism: `CONFIRMED`
- Residual alternative: a real timing change is not absolutely excluded by the available digital evidence
- Probable artifact: integer-event endpoint quantization in an approximately 1.008-second `time.monotonic()` window not phase-locked to frame events
- Observed frame-counter branches: exactly `25` or `26` events
- C3 direct finding: exact identity, clean autoinit telemetry, and no independent abnormality in the halted run
- Existing ten-run prefix: `KEEP_RAW_DATA_BUT_PRIMARY_CLASSIFICATION_INVALID`
- Campaign decision: `NEW_CONTROL_EXPERIMENT_REQUIRED`
- Measurement amendment: `PROPOSED — NOT AUTHORIZED`
- R3: `STILL_REQUIRED`
- Hardware operations during review: `0`
- Firmware/source modifications during review: `0`
- SSOT operations during review: `0`

The historical halt and historical labels remain valid records of the frozen protocol as executed. This review does not relabel `R2OM-R01-P2-C1`, `R2OM-R02-P1-C1`, or `R2OM-R03-P2-C3`. Because the primary frame gate was under-resolved, however, the ten-run prefix cannot be pooled with future observations taken under a corrected method. Its raw identity, autoinit, recovery, and timing evidence remains useful as exploratory evidence, not as a primary denominator for a new causal conclusion.

## Why the probable-artifact conclusion is high confidence

Across all eight runs with video present:

- four windows recorded exactly 25 frame events;
- four windows recorded exactly 26 frame events;
- exact raw-monotonic elapsed windows span only `1.007711409000` to `1.008668054000` seconds;
- the two frame-rate clusters are `24.799186–24.808690 Hz` and `25.776567–25.797844 Hz`;
- one integer event per window contributes approximately `0.992 Hz`, while the frozen clean band is only `±0.10 Hz`;
- 25- and 26-event outcomes occur in more than one candidate and at multiple campaign times;
- normalized SAV and VCLK rates remain stable;
- all three C3 runs use the same exact bitstream and runtime commit, with identical clean autoinit results and `SCL_HIGH_WAIT_MAX_BASE_CYCLES=8`.

The one-second estimator therefore cannot resolve the frozen tolerance. It converts counter-boundary phase into an apparent full-frame frequency step.

## Governance boundary

The proposed amendment is intentionally not self-authorizing. Before any new hardware campaign, the Owner/Architect must explicitly approve:

1. the amended measurement rule;
2. a separate measurement-control validation;
3. a new, independently identified full causal campaign using one prospective rule from its first run;
4. newly confirmed DUT exclusivity.

The halted R2 campaign must not resume at sequence 11. Its historical state remains 10/32 with scientific causal result blocked.

## Source evidence

Frozen source directory:

`C:\AHD_R2_REVIEW_20260828\input_r2_evidence\v41-research-r2-r1i-causal-hardware-owner-mediated-continuation-halted-20260828`

- source manifest SHA-256: `D6D8FA70973A9A1DFC8406A90A93B527341BAF2A36C0B0F0E104C15A24822002`
- source state SHA-256: `FA3E9C1FC08A89F64729A4146E5049C4D80435D5829FB417B63686BDD4833EE4`
All ten aggregate raw captures were independently rehashed and match the `RAW_CAPTURE_SHA256` values in the committed historical per-run receipts. Exact linked copies are included under `audit/linked_raw_captures/`; all ten rates are therefore independently recalculable from cryptographically anchored T0/T1 values and monotonic read timestamps.

SSOT was read-only: `PROJECT_STATE_REV_AT_START=1`, `PROJECT_STATE_REV_AT_END=1`, staleness `NONE`.

See `R2_REVIEW_MAIN_REPORT.md` for the integrated finding and `R2_MEASUREMENT_PROTOCOL_AMENDMENT_PROPOSAL.md` for the proposed, non-authorized corrective protocol.
