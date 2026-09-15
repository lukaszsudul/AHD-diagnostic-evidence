# Runtime identity

Result: `PASS`

SCAN1: MAGIC `0x4E565343`, VERSION `0x00010001`, CAPABILITIES `0x0000000F`, 82 entries, 10 bank groups, 25 kHz, `READ_ONLY_ONESHOT_SINGLE_FROZEN_SNAPSHOT`, MMIO `0x12000..0x123FF`.

ACQ: MAGIC `0x4E564143`, VERSION `0x00010000`, CAPABILITIES `0x000000FF`; CH1-only, Bank-5 registers 0x08/0x05 only, fixed 0x08-then-0x05 order, full-byte baseline, exact rollback, and no generic I2C, mode-write, EQ-write, ACP, Bank-9 re-arm, route-write, or BGDCOL-write capability.

Legacy DIAG1 was absent. Stream enable was zero. Executor functional and unauthorized write counters were zero.

The first task-local reader treated the documented SCAN1 `FIRST_ERROR_INDEX=0xFFFFFFFF` no-error reset sentinel as a transport-wide all-ones fault. The reader was corrected to exempt only that exact address and to continue rejecting all other all-ones responses. The corrected gate reported zero MMIO fault all-ones reads.
