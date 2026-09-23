# AHD v41 — R2R10R14 retry/EQ single-frame attempt

## Result

The exact R13R2 bitstream was programmed once and the DUT completed one planned warm reboot. Fresh runtime identity matched source `88ac649a8484ff359270ec19ab539478edf534c0`.

PREPARE completed as `PASS_CLEAN`: telemetry generation 1 was complete and coherent, the hard-failure record was empty, 46 main transactions were accepted, and no first-attempt NACK or firmware retry occurred.

APPLY_A failed before EQ finalization. Terminal `0xC3C02283` reported code 17 (`I2C_WADDR_NACK`). The coherent first hard-failure record identifies PC111, Bank0B, register 0x68, write 0x03, cause 1. SCAN1 and C2H were therefore not run, and no PNG was created.

Cleanup entered containment because the final loader remained in lockout. Stream was off, transport was quiescent, AIO was zero, and the exact driver plus controller/DUT locks were retained. No forced unload, recovery command, additional reboot, or retry was performed.

This single attempt does not exercise the PREPARE retry path, establish a physical NACK cause, execute the scoped EQ finalization, confirm a live camera scene, or qualify the product.