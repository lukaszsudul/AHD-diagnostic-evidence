# Post-autoinit address probe model

PROBE_CLASS=ACTIVE_NON_REGISTER_WRITING_POST_AUTOINIT_DIAGNOSTIC

PROBE_TARGET_COUNT=10000

PROBE_ADDRESS_BYTE=0x60

PROBE_I2C_HZ=25000

DIVIDER=1250

TICK_CYCLES=1251

TICKS_PER_PROBE=23

CYCLES_PER_PROBE=28773

TOTAL_PROBE_CYCLES=287730000

TOTAL_PROBE_SECONDS=4.603680000

MODELED_PROBE_COMPLETE_SECONDS_FROM_CONFIGURATION=6.726055776

FROZEN_ARM_A_REQUIRED_WAIT_SECONDS=10.000000

The probe sends START, write address byte `0x60`, one ACK bit, STOP, and a bus-free state. It sends zero register bytes, zero data bytes, zero read-address bytes, no repeated START, and no retry. The independent two-FF/three-sample input qualification is used at the ACK decision point. Before terminal `init_done`, the probe releases both lines and has no sequencer/control fanout.

The 10,000-transaction self-checking simulation completed with count 10,000, ACK 10,000, NACK 0, timeout 0. This is a simulation integrity result, not a device measurement.
