# R2 tick and ACK-path audit

The exact functional source uses a 62.5 MHz autonomous clock and requests a
50 kHz I2C clock. `DIVIDER = CLK_HZ / (I2C_HZ * 2) = 625`, while the tick
counter asserts a tick when its old value equals `DIVIDER`. The interval is
therefore inclusive:

- `FUNCTIONAL_HALF_PHASE_CYCLES=626`
- `FUNCTIONAL_HALF_PHASE_US=10.016`
- `SHADOW_MID_HIGH_OFFSET_CYCLES=313`
- `SHADOW_MID_HIGH_OFFSET_US=5.008`

All four functional ACK paths use the same architecture: write-address,
register-byte, data-byte, and read-address. In each `ACK_*_HIGH` state, the
unchanged FSM makes its ACK/NACK decision from `sda_filtered_r` on the tick
that also commands SCL release. The following 626-cycle interval is the actual
SCL-high ACK opportunity. R2 starts an observer-only event at that unchanged
decision, records the first qualified SCL-high observation, samples the exact
middle of the following interval, and records the last pre-tick sample.

No R2 signal drives the divider, state, open-drain enables, reset, table,
banking, error bookkeeping, or retry behavior.

I2C_DIVIDER_CHANGED=0
I2C_ACK_LOGIC_CHANGED=0
I2C_STATE_TRANSITIONS_CHANGED=0

