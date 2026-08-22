# R1c paired A/B classification

## Result

```text
ARM_A_RESULT=VALID_FUNCTIONAL_FAIL
ARM_B_RESULT=VALID_FUNCTIONAL_FAIL
ARM_B_PAIRED_CONTROL_VALID=YES
PAIRED_AB_RESULT=PARTIAL_OR_MIXED_EFFECT_SINGLE_SAMPLE
I2C_25KHZ_DIAGNOSTIC=NOT_A_FULL_PASS
SLOWER_COMPLETE_I2C_TIMING_PROFILE=PARTIAL_EFFECT_OBSERVED_NOT_SUFFICIENT_FOR_RECOVERY
SIMPLE_PER_BIT_TIMING_MARGIN_AS_SOLE_CAUSE=NOT_ESTABLISHED_BY_SINGLE_PARTIAL_SAMPLE
ROOT_CAUSE_SOLELY_PROVEN=NO
READY_FOR_PHASE3_25KHZ_INTEGRATION_REVIEW=NO
READY_TO_RETURN_TO_XDMA=NO
NEXT_ACTION=OWNER_AND_AUDITOR_REVIEW_NO_AUTOMATIC_REPEAT
FINAL_ACTIVE_IMAGE=FORMAL_PHASE2
FINAL_FORMAL_IDENTITY=0xA40A0C07/0x0000400B/0x00031002
FINAL_DIAGNOSTIC_MAGIC=0x00000000
FINAL_PINNED_DRIVER_LOADED=YES
FINAL_DONE=1
```

## Owner-prompt precedence

Both new R1c arms are infrastructure-valid functional failures. A coarse
pass/fail-only reading could therefore resemble Case 2. The owner's Case 5 is
more specific and explicitly lists “A has fewer NACKs but remains FAIL” as a
partial/mixed example. Arm A produced 8 NACKs versus 15 in Arm B, while both
arms retained `INIT_ERROR=1`, zero SAV, and zero frame activity. Case 5
therefore takes precedence over the coarser Case-2 label.

This is not a recovery: the 25-kHz image still failed initialization and did
not produce active video. The seven-NACK reduction and changed first-error
tuple are a single-sample partial effect only. They do not authorize a repeat,
Phase 3 integration, or return to XDMA work, and they do not prove a sole root
cause.

## New-pair comparison

| Metric | Arm A: exact 25 kHz | Arm B: exact formal 50 kHz | Interpretation |
|---|---:|---:|---|
| Infrastructure | valid | valid | Scientific comparison is admissible |
| `INIT_DONE` | 1 | 1 | Equal |
| `INIT_ERROR` | 1 | 1 | Both fail |
| NACK count | 8 | 15 | Arm A has 7 fewer NACKs, a partial effect |
| Timeout count | 0 | 0 | Equal |
| First error | code 02, step 2D, reg ED | code 01, step 02, reg CA | Failure locus changed; no recovery |
| VCLK range | 147.776–149.234 MHz | 147.785–149.158 MHz | Both pass frozen 140–160-MHz gate |
| SAV rate | 0 | 0 | Both fail |
| Frame rate | 0 | 0 | Both fail |
| Reset/VDD status | 1/1/1 | 1/1/1 | Equal and valid |
| Final DONE | 1 | 1 | Both valid |

Only the two new R1c samples drive this classification. Historical R1/R1b and
the pre-Arm-A formal telemetry remain contextual evidence only.
