# Exact formal Phase-2 restoration classification

```text
ARM_B_ROLE=MANDATORY_FORMAL_RESTORATION_ONLY
FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
FORMAL_FUNCTIONAL_SOURCE_COMMIT=fd32fcb65be3f1a59c569874195d1faeaf7d27e9
ARM_B_PROGRAM=PASS_STARTUP_HIGH_DONE_1
ARM_B_VENDOR_STARTUP_STATUS=HIGH
ARM_B_DONE=1
ARM_B_PROGRAM_INVOCATIONS=1
ARM_B_PROGRAM_RETRIES=0
ARM_B_WAIT_SECONDS=5.000408800
ARM_B_WARM_REBOOT=NOT_RUN_RESTORATION_ONLY_AFTER_INFRASTRUCTURE_HARD_STOP
ARM_B_DRIVER_LOADER_INVOCATIONS=0
ARM_B_DRIVER=NOT_LOADED
ARM_B_RUNTIME_IDENTITY=NOT_READ
ARM_B_DIAGNOSTIC_MAGIC=NOT_READ
ARM_B_NVP_VIDEO_TELEMETRY=NOT_RUN
ARM_B_PAIRED_CONTROL_VALID=NO
ARM_B_RESULT=RESTORATION_ONLY_PASS
FINAL_FRESH_READ_ONLY_DONE=1
FINAL_ACTIVE_IMAGE=FORMAL_PHASE2
FINAL_PINNED_DRIVER_LOADED=NO
```

The exact formal bit was rehashed and programmed once. The supported Vivado
process reported vendor startup status HIGH, same-session `DONE=1`, one
consumed programming invocation, count/order gates PASS, and exit code zero.
The monotonic wait from the fresh-DONE reference was 5.000408800 seconds.

Because Arm A had already reached the kernel/module compatibility hard stop,
no Arm-B reboot, driver load, MMIO identity read, or NVP/video telemetry was
authorized. A separate zero-program JTAG session subsequently proved the
exact target and `DONE=1`. This proves successful SRAM restoration of the
exact formal image, but it is not a valid interleaved Arm-B functional control.
