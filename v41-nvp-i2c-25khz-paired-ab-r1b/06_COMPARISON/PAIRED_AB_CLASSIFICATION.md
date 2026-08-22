# R1b paired A/B classification

## Comparison eligibility

| Gate | Arm A: exact 25-kHz image | Arm B: exact formal 50-kHz image |
|---|---|---|
| Exact bit programmed once | PASS | PASS |
| Vendor startup HIGH and same-session DONE=1 | PASS | PASS |
| Required wait | PASS, 223.944751400 s at accepted replay observation | PASS, 5.000408800 s |
| Warm reboot | PASS | Not run; restoration-only path |
| Exact pinned driver | Blocked before invocation | Not run |
| Runtime provenance | Not read | Not read |
| T0/T1 NVP/video telemetry | Not run | Not run |
| Functional arm validity | INVALID_INFRASTRUCTURE | NOT_A_PAIRED_CONTROL |

## Classification

```text
ARM_A_RESULT=INCONCLUSIVE_INFRASTRUCTURE
ARM_B_ROLE=MANDATORY_FORMAL_RESTORATION_ONLY
ARM_B_RESULT=RESTORATION_ONLY_PASS
ARM_B_PAIRED_CONTROL_VALID=NO

PAIRED_AB_CAMPAIGNS=1
PAIRED_AB_CAMPAIGNS_COMPLETED=0
PAIRED_AB_RESULT=INCONCLUSIVE_INFRASTRUCTURE
I2C_25KHZ_DIAGNOSTIC=INCONCLUSIVE_NOT_FUNCTIONALLY_MEASURED
SLOWER_COMPLETE_I2C_TIMING_PROFILE=NOT_EVALUATED
MARGINAL_PROTOCOL_OR_SETTLING_TIMING=NOT_EVALUATED
SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE=NOT_EVALUATED
ROOT_CAUSE_SOLELY_PROVEN=NO
READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW=NO
READY_TO_RETURN_TO_XDMA=NO
SCIENTIFIC_INFERENCE=NONE
```

Arm A reached the first post-reboot compatibility gate with kernel
`7.0.0-30-generic`; the exact pinned module has vermagic
`7.0.0-29-generic`. The accepted loader was not invoked, so runtime Git/build
flags and all functional telemetry remained unread. Consequently Arm A is
neither a functional PASS nor a functional FAIL.

Arm B safely restored the exact formal SRAM image, but the hard-stop branch
did not authorize another reboot or host qualification. It cannot be promoted
to a paired functional control. The campaign therefore makes no scientific
claim for or against the slower complete I2C timing profile.
