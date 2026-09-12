# Scope

The implemented diagnostic source is limited to CH1, Bank `0x05`, registers
`0x08` and `0x05`, slice levels `0x50/0x40/0x60`, exact full-byte baseline and
rollback, SCAN1 read-only observation, and read-only format decision.

Source inspection and 44/44 tests found no generic host NVP I2C, mode, EQ, ACP,
Bank9 re-arm, route, channel-enable, BGDCOL, CH2-CH4 functional-write, Flash,
capture, or second-programming path. Hardware execution was not reached.

First blocker: `ACQ1_COMPAT0_R2_BUILD_PROFILE_COUNTER_PREFIX_COLLISION`.
