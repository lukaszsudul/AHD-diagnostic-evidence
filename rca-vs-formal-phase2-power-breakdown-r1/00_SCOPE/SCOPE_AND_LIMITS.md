# Scope

```text
TASK=V41_RCA_PHASE2_POWER_BREAKDOWN_NO_BUILD_R1
TASK_MODE=OFFLINE_READ_ONLY_ROUTED_DCP_POWER_FORENSIC
PRIMARY_COMPARISON=EXACT_FORMAL_PHASE2_VERSUS_EXACT_RCA
R1_MEASUREMENT_IMAGE_PRIMARY_COMPARATOR=NO
FULL_BUILDS=0
SOURCE_CHANGES=0
HARDWARE_ACTIONS=0
```

The audit asks where Vivado's estimated power difference resides under each exact DCP's unchanged embedded/default assumptions. Model results may rank hypotheses but cannot prove board Vcco droop, ground bounce, SSN, analog I²C margin, or a sole root cause.
