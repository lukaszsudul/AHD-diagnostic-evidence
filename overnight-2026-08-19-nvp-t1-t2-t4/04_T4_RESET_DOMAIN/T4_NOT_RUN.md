# T4 gate disposition

```text
T4_RUN=NO
T4_CLASSIFICATION=NOT_RUN_T1_PASS_3_OF_3_GATE_NOT_MET
T1_CLASSIFICATION=INCONCLUSIVE_INFRASTRUCTURE
NEW_OFFLINE_BUILDS=0
EXPERIMENTAL_BITSTREAMS=0
HARDWARE_PROGRAMS=0
```

T4 was conditional on `RCA_CURRENT_HARDWARE_PASS_3_OF_3`. T1 produced no valid functional samples because non-interactive SSH authentication was unavailable before any programming operation. Therefore no v41-specific reset-domain conclusion is permitted and T4 was correctly skipped.
