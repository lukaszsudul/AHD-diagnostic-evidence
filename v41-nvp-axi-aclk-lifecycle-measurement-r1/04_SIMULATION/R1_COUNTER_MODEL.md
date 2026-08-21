# Exact counter model

The unchanged engine regression reports 341465 one-MHz clock cycles from the
first sampled start level to the first sampled done level. With the inclusive
divider of 10 this resolves to 31043 FSM tick actions. At 62.5 MHz the exact
divider is 625 and the tick spacing is 626 clocks.

The top POR releases after 320 edges. The unchanged wrapper creates its start
pulse after the inclusive 93,750,000-cycle delay. The first engine tick action
able to consume the latched start is edge 93,750,387. FINISH is tick action
31043, at edge 113,182,679. The observer captures the newly asserted done on
the following edge while the counter's pre-increment value is 113,182,679.

```text
COUNTER_FREQUENCY_HZ=62500000
EXPECTED_CNT_AT_INIT_DONE=113182679
EXPECTED_CNT_AT_INIT_DONE_TOLERANCE_CYCLES=0
REFERENCE_METHOD=SAME_PROGRAM_PROCESS_RETURN_MARKER
PRIMARY_GUARD_MIN_SECONDS=0.250
```
