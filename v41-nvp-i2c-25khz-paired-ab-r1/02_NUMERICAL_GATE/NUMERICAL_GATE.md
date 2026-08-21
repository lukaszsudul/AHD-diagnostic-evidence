# Exact Numerical Gate

```text
NUMERICAL_GATE=PASS
CLK_HZ=62500000
SUCCESS_PATH_TICK_ACTIONS=31043
SUCCESS_PATH_FIRST_IDLE_TO_FINISH_INTERVALS=31042
TRANSACTION_COUNT=275
WRITE_TRANSACTIONS=220
READ_TRANSACTIONS=55
TABLE_SLOTS=214
TABLE_TARGET_WRITES=187
TABLE_DELAY_SLOTS=1
TABLE_NOP_SLOTS=26
VERIFIED_BANK_CHANGES=25

FORMAL_I2C_HZ=50000
FORMAL_DIVIDER=625
FORMAL_TICK_COUNTER_CYCLES=626
FORMAL_STATE_TICK_US=10.016000
FORMAL_PHYSICAL_SCL_PERIOD_US=20.032000
FORMAL_PHYSICAL_SCL_HZ=49920.1277955
FORMAL_FULL_AUTOINIT_US=1810922.864000
FORMAL_FROM_POR_RELEASE_US=1810917.744000
FORMAL_FROM_FIRST_PHYSICAL_I2C_START_US=310896.640000

DIAGNOSTIC_I2C_HZ=25000
DIAGNOSTIC_DIVIDER=1250
DIAGNOSTIC_TICK_COUNTER_CYCLES=1251
DIAGNOSTIC_STATE_TICK_US=20.016000
DIAGNOSTIC_PHYSICAL_SCL_PERIOD_US=40.032000
DIAGNOSTIC_PHYSICAL_SCL_HZ=24980.0159872
DIAGNOSTIC_FULL_AUTOINIT_US=2121355.744000
DIAGNOSTIC_FROM_POR_RELEASE_US=2121350.624000
DIAGNOSTIC_FROM_FIRST_PHYSICAL_I2C_START_US=621296.640000

LOCAL_POR_CYCLES=320
LOCAL_POR_US=5.120000
C_RESET_HOLD_CYCLES=31250000
PHYSICAL_R17_LOW_SECONDS_AFTER_POR=0.500000
R17_RELEASE_SECONDS_FROM_FIRST_ACTIVE_CLOCK=0.500005120
C_START_CYCLE=93750000
FIRST_I2C_START_SECONDS_NOMINAL=1.500000
SCL_RELEASED_LOW_WATCHDOG_COUNTER_TERMINAL=1250
SCL_RELEASED_LOW_WATCHDOG_WALL_CLOCK_US=20.016000
SCL_RELEASED_LOW_WATCHDOG_UNCHANGED=YES
SDA_SCL_SYNCHRONIZER_DEPTH_UNCHANGED=YES
SDA_SCL_FILTER_DEPTH_UNCHANGED=YES
```

The all-ACK success path contains 31,043 FSM tick actions. From the first IDLE
tick accepting the latched start through the FINISH tick there are 31,042
tick-to-tick intervals. All component counts use the RTL's inclusive counter
semantics.

The component CSV reports a tick-budget contribution, not a point-to-point
first-action-to-last-action edge span. Thus a 61-action write contributes 61
ticks to the complete pipeline accounting while its first-to-last action edges
span 60 intervals. The complete lifecycle total separately and explicitly uses
31,042 intervals between 31,043 actions.

The lifecycle-counter convention records the FINISH edge. Wrapper `init_done`
is physically high one base-clock cycle later; that alternative observation
adds exactly 0.016 microseconds. The first-I2C-start reference above is the
physical START edge where SDA is driven low while SCL is released.

Every state-tick-based interval changes with `I2C_HZ`: LOW/HIGH phases,
START/STOP/ACK dwell, transaction duration, NOP duration, table-delay duration,
and final-settle duration. The local POR, R17 hold, 1.5-second start counter,
synchronizers, filter, and released-SCL watchdog are base-clock quantities and
remain unchanged.
