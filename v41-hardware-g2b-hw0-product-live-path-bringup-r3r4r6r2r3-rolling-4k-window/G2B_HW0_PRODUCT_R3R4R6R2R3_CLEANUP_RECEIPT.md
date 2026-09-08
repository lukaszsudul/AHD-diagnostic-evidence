# Cleanup receipt

- Normal stream-disable writes: 1
- Safety-disable writes: 0
- Physical quiescence: FAIL
- Last observed CONTROL: 0x00000000
- Last observed STATUS: 0x000004FA
- PARENT_QUIESCENT sent: NO
- Guard cancellation: NOT_REACHED
- Final pending AIO: N/A
- Helper normal exit: NO
- Task helper PID retained: 6055
- Driver unload: NOT PERFORMED
- XDMA nodes removed: NO
- Linux lock released: NO
- Controller lock released: NO
- Forced signal, forced unload, reset, reboot, JTAG, or power cycle: NO

Safe cleanup is blocked by `R3R4R6R2R3_GUARD_AIO_CLEANUP_UNRESOLVED`. The retained state is intentional
and requires a new Owner-authorized corrective task.
