# Executor contract

Status: `NOT_IMPLEMENTED`

The intended executor was compile-time CH1-only and limited to baseline, `0x50/0x40/0x60`, restore, abort/restore, and result ACK operations. Generic bank/register/value, mode, EQ, route, and BGDCOL paths were forbidden. Implementation did not begin because the complete reference slice action requires the unauthorized `Bank5/0x05=0xA4` companion write.

First blocker: `ACQ1_COMPAT0_SLICE_ACTION_EXCEEDS_AUTHORIZED_WRITE_SET`
