
# Preserved-primary frame-boundary analysis

The read-only fixed-boundary parse reproduced all 2500 structurally integral
records and global sequence `0..2499`.

| Event | Index | Transition | Attempt behavior | Malformed delta | Dropped delta | Flags | Classification |
|---|---:|---|---|---:|---:|---|---|
| initial fragment | 0 | starts at frame 202797 line 503 | first record | n/a | n/a | `0x24` | INITIAL_TRANSITION_FRAGMENT |
| A2 | 441 | line 943 to line 946 | attempt 440 to 443 | 0 | +2 | `0x2C` | PRIMARY_TRANSIENT_OVERFLOW_EVENT |
| B1 | 575 | frame 202797 line 1079 to frame 202798 line 1 | attempt 576 to 578 | +21 | +1 | `0x34` | BT656_FRAME_BOUNDARY_EVENT |
| B2 | 1654 | frame 202798 line 1079 to frame 202799 line 1 | attempt 1656 to 1658 | +21 | +1 | `0x34` | BT656_FRAME_BOUNDARY_EVENT |

The overflow event is independent of the repeatable frame-boundary events.
Both complete observed frame transitions lose line 0, add exactly 21 to the
source malformed snapshot, add one source drop, leave one attempt-sequence gap,
and put `MALFORMED_PRECEDING` on the next committed line-1 record. Line 0 and a
clean SOF record are absent from the preserved primary window.

The one-attempt/one-drop boundary evidence is inconsistent with a pure
lock-only omission (which consumes no attempt and creates no drop). It proves
that at least one eligible line was admitted and then discarded during each
boundary episode. It does not reveal the raw marker sequence responsible for
the other malformed increments.
