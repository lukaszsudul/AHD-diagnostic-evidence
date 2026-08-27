# R1i–R2 Authoritative Conclusion

## Classification

```text
SCIENTIFIC_VERDICT=THESIS_CONFIRMED
FROZEN_ACCEPTANCE_OUTCOME=STRONG_PASS
SCOPE=QUALIFIED_POC_BASELINE
PRODUCTION_QUALIFICATION=NOT_CLAIMED
EXACT_LOW_LEVEL_CAUSAL_MECHANISM=INCONCLUSIVE
```

## Decisive observation

The fixed R1i candidate completed initialization with zero autoinit NACKs, did not latch `INIT_ERROR`, and produced normal video at a reported frame rate of 24.803727 Hz. The exact unmodified R1h control recorded four autoinit NACKs, latched `INIT_ERROR`, and produced no video.

Both arms subsequently completed 10,000 WADDR, 10,000 REGADDR, and 10,000 DATA selected-target opportunities with zero post-init NACKs. The full frozen post-init accounting is 60,000 / 60,000 phase observations.

## Interpretation boundary

The frozen same-session functional result confirms the combined R1i correction as a PoC. It does not isolate ACK sampling, readiness/retry behavior, initialization timing, or their interaction as the sole mechanism. R1i's early-false, qualified-NACK, and recovery counters were all zero, so no direct causal sub-mechanism attribution is claimed.

The result does not claim production readiness, universal board behavior, analog-margin measurement, or formal proof.
