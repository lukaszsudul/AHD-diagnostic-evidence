# Lifecycle model

ACTIVE_I2C_HZ=25000

ACTIVE_TICK_CYCLES=1251

EXPECTED_CNT_AT_INIT_DONE_ACTIVE=132584734

EXPECTED_CNT_AT_INIT_DONE_50KHZ=113182679

CAPTURE_CONVENTION=PRE_INCREMENT_COUNTER_VALUE_ON_FIRST_CLOCK_SAMPLING_INIT_DONE

The expected 25-kHz value was independently reproduced by the exact production autoinit cycle simulation. The simulation reported `EXACT_PRODUCTION_LIFECYCLE_COUNTER=132584734` and `EXACT_LIFECYCLE_COUNTER_CONVENTION=FINISH_EDGE_PREINCREMENT`.

No hardware lifecycle value exists because the build hard stop prohibited programming.
