
# Cleanup receipt

Final cleanup passed: stream disabled, physical quiescence PASS, pending AIO 0,
native helpers absent, `xdma_ahd_pcie` unloaded, XDMA nodes removed, Linux lock
released, and controller lock released last.

The inherited cleanup utility first rejected the fresh R3R2R1 lock prefix and
its frozen R3R2 compatibility task literal before any unload or lock mutation.
An exact task-local adapter then required both the frozen task literal and the
R3R2R1 owner-task field and completed successfully. No force unload was used.
