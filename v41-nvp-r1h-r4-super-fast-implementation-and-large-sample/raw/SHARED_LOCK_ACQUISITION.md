# Shared implementation/hardware lock acquisition

The canonical shared slot was empty and was acquired once with an atomic
create-new operation. No prior owner was removed or replaced.

```text
LOCK_PATH=C:\FPGA\_VCDE_SHARED_BUILD_SLOT\OWNER.md
LOCK_CLASS=SHARED_IMPLEMENTATION_AND_HARDWARE
LOCK_OWNER_TASK=V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE
LOCK_OWNER_THREAD=/root
LOCK_ACQUIRED_UTC=2026-08-25T12:33:40.1919744Z
LOCK_NONCE=68370740-036b-4bae-bcda-7fd7ada4b35f
LOCK_SHA256=B6D8A5D7DC18BC1BE3D40A2499833E41C984D72AA7524C0F8E4FB806157DA0A1
LOCK_ACQUISITION_COUNT=1
LOCK_STATUS=HELD
RELEASE_AUTHORITY=/root

ACTIVE_VIVADO_IMPLEMENTATION_PROCESSES_BEFORE_LOCK=0
ACTIVE_JTAG_PROGRAMMING_PROCESSES_BEFORE_LOCK=0
ACTIVE_HARDWARE_OWNER_LOCKS_BEFORE_LOCK=0
VALID_PRIOR_OWNER_DISRUPTED=NO
```

A transient Codex remote-capability probe (`ssh ... ahd-ubuntu ... command -v
codex`) was observed. It was not launched by this P0 agent, contained no
programming or telemetry command, and was not classified as a hardware owner.
It was not interrupted.
