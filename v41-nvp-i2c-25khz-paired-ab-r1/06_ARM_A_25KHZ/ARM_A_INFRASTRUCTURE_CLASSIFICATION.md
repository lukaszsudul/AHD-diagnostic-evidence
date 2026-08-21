# Arm A infrastructure classification

Arm A consumed exactly one diagnostic FPGA programming invocation. Vivado's
program command returned and reported vendor startup status HIGH, but the
prescribed supervisor then attempted to read the unavailable
`REGISTER.IR.BIT4_EOS` property and emitted `PROGRAM_RESULT=FAIL_NO_RETRY`.

A separate zero-program JTAG session subsequently proved the exact target,
IDCODE, and `DONE=1`. That observation proves the programmed image was alive
and made formal restoration safe; it does not retroactively make the Arm-A
procedure valid or authorize a second final-DONE session after telemetry.
Accordingly no Arm-A reboot, driver load, runtime-provenance read, or NVP/video
telemetry was performed.

```text
ARM_A_PROGRAM=EXECUTED_ONCE
ARM_A_VENDOR_STARTUP_STATUS=HIGH
ARM_A_EOS=HIGH_VENDOR_END_OF_STARTUP_STATUS
ARM_A_POST_PROGRAM_OBSERVER=FAIL_UNAVAILABLE_BIT4_EOS_PROPERTY
ARM_A_SUPERVISOR_RESULT=FAIL_NO_RETRY
ARM_A_SEPARATE_READ_ONLY_DONE=1
ARM_A_WAIT_SECONDS=5.012176700
ARM_A_REBOOT=NOT_RUN_FAIL_CLOSED
ARM_A_DRIVER_LOAD=NOT_RUN_FAIL_CLOSED
ARM_A_TELEMETRY=NOT_RUN_FAIL_CLOSED
ARM_A_RESULT=INFRASTRUCTURE_INVALID
SCIENTIFIC_INFERENCE=NONE
PROGRAM_RETRY=NO
NEXT_HARDWARE_ROLE=MANDATORY_FORMAL_RESTORATION_ONLY
```
