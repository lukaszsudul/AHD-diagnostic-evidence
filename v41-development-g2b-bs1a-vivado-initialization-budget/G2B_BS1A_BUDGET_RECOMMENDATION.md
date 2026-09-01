# G2B-BS1A Initialization Budget Recommendation

## Result

- Measured time from Vivado process launch to `COMMAND_READY`: **312.233 seconds**.
- Decision-tree classification: **INITIALIZATION_BUDGET_TOO_SMALL_CONFIRMED**.
- Recommended future initialization watchdog: **900 seconds**.
- Recommended future BUS_SKEW command watchdog: **300 seconds**, armed only after `COMMAND_READY`.

The isolated worker reached readiness 12.233 seconds after the previous 300-second total initialization ceiling. The earlier ceiling therefore could not reliably distinguish initialization completion from timeout.

## Budget derivation

The prescribed margin rule gives:

- measured time × 2 = 624.466 seconds;
- measured time + 300 seconds = 612.233 seconds;
- rule minimum = max(624.466, 612.233) = 624.466 seconds.

The recommendation is rounded upward to **900 seconds** as a practical 15-minute watchdog. This also accommodates observed process-startup variability: BS1 took 136.972 seconds to enter Tcl, whereas BS1A took 42.532 seconds. The recommendation remains below the 1800-second cap.

## Independent watchdog structure

The future BS1 retry should use two non-overlapping budgets:

1. `INITIALIZATION` — one serialized worker, maximum 900 seconds, through exact DCP/context/object identity preparation.
2. `COMMAND_READY` — write and verify the readiness marker.
3. `BUS_SKEW` — only then arm a separate 300-second command watchdog.

Unused initialization time must not be transferred to the command watchdog, and the command watchdog must not begin at process launch.

## Phase basis

| Phase | Elapsed (s) |
|---|---:|
| Process startup | 42.532 |
| Tcl entry to checkpoint start | 4.047 |
| Checkpoint open | 159.754 |
| Route-status query | 8.037 |
| Context/XDC preparation | 95.066 |
| Source resolution | 0.101 |
| Sink resolution | 0.008 |
| Identity verification | 0.023 |
| Readiness finalization | 2.519 |
| **Total to `COMMAND_READY`** | **312.233** |

Checkpoint opening was the dominant phase at 51.165% of total readiness time. Context/XDC preparation was second at 30.447%.

## Timing-database boundary

Vivado automatically restored timing data from the checkpoint's binary archive during `open_checkpoint`; that work is included in the 159.754-second checkpoint-open measurement and was not separately timed by Vivado. No explicit timing update was run, and no `UpdateTimingParams` message appeared during pre-command preparation. Any additional automatic timing update performed inside a future BUS_SKEW command belongs to the separate command watchdog and remains untested by BS1A.
