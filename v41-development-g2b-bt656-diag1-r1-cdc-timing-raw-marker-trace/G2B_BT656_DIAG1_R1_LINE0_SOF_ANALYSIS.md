# G2B BT.656 DIAG1-R1 Line-0/SOF Analysis

- Line-1079 SAV: YES, logical index 31.
- Line-1079 EAV: YES, logical index 32, raw `FF 00 00 90`.
- Next-frame line-0 SAV: YES, logical index 123, raw `FF 00 00 80`, F/V/H 0/0/0, XY parity PASS.
- Line 0 enters `SRC_CAPTURE`: YES.
- Line 0 receives an attempt: NO; `source_locked_before=0`.
- Line 0 receives a writable slot: NO (allocation is available, but admission is lock-gated).
- Next-frame line-0 EAV: YES, logical index 124, raw `FF 00 00 90`.
- Line 0 commits: NO in the hardware trace; streaming was disabled for every captured event.
- Line 0 composes SOF: NO in the hardware trace.
- Line 1 commits: NO in the hardware trace; streaming was disabled for every captured event.

The trace directly shows 21 reason-2 malformed increments at EAV for pending lines 1080 through 1100. The parser's accepted-line predicate is otherwise satisfied but rejects `pending_line > 1079`. The first such rejection drops source lock. At the next active-frame SAV, the parser recognizes line 0 and enters capture, but lock is still low; line-0 EAV only restores lock. This makes lock admission a downstream contributing effect, not the initiating root cause.

Because `enable_applied=0` and `monitor_has_attempt=0` throughout this frozen hardware trace, commit behavior is established by the current-parser replay rather than falsely attributed to the passive trace alone.
