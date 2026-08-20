# Current RC-A versus historical RC-A and v41

The exact accepted RC-A passed all three current warm-state samples. Its three
current observations match both the five-run historical cold acceptance and
the three-run B7 new-host sanity in broad class and in exact error location:
there was no error tuple, no NACK, no timeout, and all video counters advanced.

By contrast, the listed valid v41 Phase-3, formal Phase-2, R2, and Z8 samples
all had `INIT_ERROR=1`, nonzero NACK counts, and stationary SAV/frame counters.
They share a broad autonomous-I2C/video failure class, but their exact first
error locations differ and are not called identical:

- Phase-3: address NACK at step `0x13`, bank `05`, register/value `59/11`.
- Formal Phase-2: address NACK at step `0x17`; the retained context sample did
  not expose bank/register/value in its summary.
- R2: write-address NACK at step `0x1F`, bank `05`, register/value `58/00`.
- Z8: write-address NACK at step `0x02`, meta/physical bank `01/00`,
  register/value `FF/00`.

The current result therefore strongly supports—but does not solely prove—that
the reproduced failure is isolated to the v41/reset-autoinit domain rather
than a global current-hardware inability to run the sealed RC-A. A changed
hardware/electrical state as a global explanation is weakened, not eliminated.

    CURRENT_VALID_SAMPLES=3
    CURRENT_FUNCTIONAL_PASSES=3
    CURRENT_FUNCTIONAL_FAILS=0
    CURRENT_INVALID_SAMPLES=0
    T1_CLASSIFICATION=RCA_CURRENT_HARDWARE_PASS_3_OF_3
    FAILURE_ISOLATED_TO_V41=STRONGLY_SUPPORTED_NOT_SOLELY_PROVEN
    CHANGED_HARDWARE_STATE_AS_GLOBAL_EXPLANATION=WEAKENED_NOT_ELIMINATED
    NEXT_RECOMMENDED_ACTION=OFFLINE_T4_V40_1_VERSUS_V41_RESET_AUTOINIT_DOMAIN_AUDIT
