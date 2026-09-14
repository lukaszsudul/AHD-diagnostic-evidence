# AHD v41 G2B-NVP-OFFLINE-ADVANCE1-R1 main report

## Result

- Engineering decision closure: `PASS`.
- Overall classification: `PASS_RM1_BUILD_BLOCKED_MODE1_AUTHORITY_INCOMPLETE`.
- Offline continuation gate: `24/24 PASS`.
- DUT/hardware access: `NO`.
- Protected COMPAT0 candidate modification: `NO`.
- PRODUCT mutation: `NO`.

## RM1-R1

The prior Tcl failure was reproduced deterministically and identified as Tcl square-bracket command substitution caused by `[ \t]` inside a double-quoted regex word. The task-local repair uses brace-protected `format` patterns, performs no recursive substitution and uses no `eval`. Regression is `16/16 PASS`; focused RTL is `18/18 PASS`; affected R3 regression is `25/25 PASS`.

The single fresh, nonincremental build reached and passed synthesis. It then stopped at the first explicit post-synthesis exact profile-elaboration gate. Counts were 3173 wrapper-boundary matches, 299 route-boundary matches, 2839 monitor-boundary matches and zero snapshot-BRAM primitives, instead of the required exact isolated profile proof. No correction or retry followed synthesis. Implementation, routing and sign-off were not reached; no DCP, bitstream or HW1 prompt exists. Classification: `RM1_BUILD_BLOCKED`.

## MODE1-AUTH1

The differential audit reconstructed 194 current-v41 trace operations and classified all 211 reference semantic operations. Current v41 already satisfies 52 of 113 final target registers. The reduced first-image set is 74 actions touching 62 functional registers plus the bank selector, rather than the prior 113-register model.

Differential counts are 61 `FINAL_STATE_DELTA`, 2 `REQUIRED_WRITE_PULSE`, 10 `REQUIRED_SEQUENCE_REWRITE`, 1 `REQUIRED_DELAY`, 3 `SOFTWARE_STATE_ONLY`, 35 `OPTIONAL_ACP`, 0 `OPTIONAL_ADAPTIVE_EQ`, 99 `NO_OP_AGAINST_CURRENT_BASELINE`, and 0 `UNRESOLVED`.

ACP is `ACP_NOT_REQUIRED_FOR_FIRST_IMAGE`. Bank1/0xED and Bank9/0x44 are each `EXCLUDED_FROM_MINIMAL_MODE1` because current v41 already satisfies the owned masked bit. Recovery is fully classified but only 36/63 positions have authority: 1 exact entry-bank restore, 35 deterministic sequence reinitializations and 27 `PROHIBITED_UNRESOLVED`. Product-baseline reconstruction fails for those 27 unknown-baseline registers. Structural recovery coverage is 100%; failure injection is 592/592 and always terminates explicitly. Initial EQ and recovery authority remain incomplete, so no source candidate, build, bitstream or HW1 prompt was created.

## Camera and continuation

No broad camera/design-file search was repeated. The tested connector instance to logical CH1 remains high confidence; CH1 to VIN1/U6.76 remains high documentary confidence; physical refdes/AFE path and the camera identity/format remain unresolved. The protected COMPAT0-R2R1-CONT1 prompt was preserved byte-exactly and still reuses bitstream SHA-256 `CFA58A46572094209997F6B1A3A5A033BF4E8C8A71EC261A5BBF1833B8BCF91B` with no build.

Execution after DUT return remains: COMPAT0-R2R1-CONT1 first; MODE1 HW1 only after later authority closure and CH1 AHD1080P25 confirmation; RM1 HW1 only after later offline RM1 sign-off and when Tor A resumes.

## First blockers

- RM1: `RM1_POST_SYNTH_PROFILE_ELABORATION_COUNT_GATE_FAILED`.
- MODE1: `PROHIBITED_UNRESOLVED_TOUCHED_REGISTER_COUNT_NONZERO` (27 registers), with `MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE`.

Final execution point: `HARD STOP AFTER AHD V41 G2B-NVP-OFFLINE-ADVANCE1-R1 RM1 SIGN-OFF AND MODE1 DIFFERENTIAL AUTHORITY`.
