# Arm A infrastructure classification

```text
ARM_A_PROGRAM=PASS_REPLAYED_COMPLETE_SAME_SESSION_RAW_EVIDENCE
ARM_A_VENDOR_STARTUP_STATUS=HIGH
ARM_A_DONE=1
ARM_A_PROGRAM_INVOCATIONS=1
ARM_A_PROGRAM_RETRIES=0
ARM_A_WAIT_SECONDS=223.944751400_AT_ACCEPTED_RECOVERY_OBSERVATION
ARM_A_WARM_REBOOT=PASS
ARM_A_BOOT_ID_CHANGED=YES
ARM_A_PRE_REBOOT_BOOT_ID=b9d58c87-6574-4596-8ff9-b61052ba26dc
ARM_A_POST_REBOOT_BOOT_ID=2051bd6b-28c4-4570-8ed9-f127a7002bae
ARM_A_RUNNING_KERNEL=7.0.0-30-generic
PINNED_XDMA_VERMAGIC=7.0.0-29-generic
ARM_A_DRIVER_LOADER_INVOCATIONS=0
ARM_A_DRIVER=BLOCKED_PREINVOCATION_KERNEL_VERMAGIC_MISMATCH
ARM_A_RUNTIME_GIT_SHA=NOT_READ
ARM_A_RUNTIME_BUILD_FLAGS=NOT_READ
ARM_A_NVP_VIDEO_TELEMETRY=NOT_RUN
ARM_A_RESULT=INCONCLUSIVE_INFRASTRUCTURE
SCIENTIFIC_INFERENCE=NONE
```

The single authorized diagnostic program completed with the exact reused bit,
vendor startup status HIGH, same-session `DONE=1`, and Vivado exit code zero.
The complete raw program transcript replayed through the pinned parser with
both count and ordering gates passing. The supervisor's only failure was a
post-observation evidence-append overload; a separate no-hardware replay and
same-QPC record preserved that distinction.

The authorized warm reboot then changed the boot ID, but the system booted
kernel `7.0.0-30-generic`. The exact pinned XDMA module is built for
`7.0.0-29-generic`. Because the exact-driver compatibility gate failed before
the loader was invoked, no loader attempt, runtime provenance read, or NVP/video
telemetry was made. Arm A is therefore not a functional PASS or FAIL.
