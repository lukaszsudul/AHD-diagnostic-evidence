# Gate summary

| Gate | Result |
|---|---|
| Exact Candidate 2 source | PASS_EXACT_CANDIDATE2_ALLOWED_SOURCE_DIFF |
| Resource | PASS_POST_OPT_AND_ROUTED_WITHIN_20384 |
| Physical timing and sign-off | PASS |
| Bitstream identity | PASS_HASH_VERIFIED |
| DUT/runtime admission | PASS_EXACT_ACTIVATION |
| Fresh CH3 F0/NOVID | FAIL_RUNTIME_SCAN_FLAGS_0X006A0005_BEFORE_OBSERVATION |
| PN variant A | NOT_RUN |
| PN variant B | NOT_RUN |
| CH2 impact | NOT_RUN |
| CH3 to VDO1 | NOT_RUN |
| C2H frame integrity | NOT_RUN |
| Cleanup | PASS_PRISTINE_VIRGIN |

The first blocker is `DETECTION`. Publication remains a separate gate until commit-pinned independent readback.
