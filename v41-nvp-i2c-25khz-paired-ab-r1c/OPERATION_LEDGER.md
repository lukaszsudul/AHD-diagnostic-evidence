# R1c Operation Ledger

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FPGA_PROGRAM_INVOCATIONS=2
ARM_A_FPGA_PROGRAM_INVOCATIONS=1
ARM_B_FPGA_PROGRAM_INVOCATIONS=1
HARDWARE_MANAGER_PROGRAM_SESSIONS=2
WARM_REBOOTS=2
ARM_A_WARM_REBOOTS=1
ARM_B_WARM_REBOOTS=1
OPTIONAL_PRE_ARM_A_DRIVER_LOADER_INVOCATIONS=1
POST_REBOOT_DRIVER_LOADER_INVOCATIONS=2
ARM_A_POST_REBOOT_DRIVER_LOADER_INVOCATIONS=1
ARM_B_POST_REBOOT_DRIVER_LOADER_INVOCATIONS=1
DRIVER_LOADER_INVOCATIONS_TOTAL=3
PROGRAM_RETRIES=0
READ_ONLY_JTAG_SESSIONS=4
HARDWARE_MANAGER_PROPERTY_PREFLIGHTS=1
READ_ONLY_SSH_SESSIONS=14
MUTATING_DRIVER_LOADER_SSH_SESSIONS=3
MUTATING_REBOOT_SSH_SESSIONS=2
SSH_SESSIONS_TOTAL=19
POST_REBOOT_PRELOADER_READ_ONLY_ATTEMPTS=3
POST_REBOOT_PRELOADER_READ_ONLY_FAILURES=1
POST_REBOOT_PRELOADER_READ_ONLY_PASSES=2
LOADER_LOCAL_LAUNCH_FAILURES_BEFORE_SSH=3
LOADER_PRETRANSPORT_RECEIPTS_CREATED=1
LOADER_PRETRANSPORT_RECOVERIES_ACCEPTED=1
AXI_LITE_WRITES=0
MMIO_READS=120
PRE_ARM_A_FORMAL_CONTEXT_TELEMETRY_TRANSACTIONS=1
ARM_A_TELEMETRY_TRANSACTIONS=1
ARM_B_TELEMETRY_TRANSACTIONS=1
TELEMETRY_TRANSACTIONS_TOTAL=3
MMIO_READS_PER_TELEMETRY_TRANSACTION=40
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PCI_REMOVE_RESCAN_RESETS=0
COLD_STARTS=0
PHYSICAL_ACTIONS=0
KERNEL_CHANGES_DURING_TASK=0
GRUB_WRITES=0
PHASE3_RESUMED=NO
XDMA_DEVELOPMENT_CONTINUED=NO
FORMAL_REPOSITORY_MUTATIONS=0
TAGS=0
RELEASES=0
FINAL_ACTIVE_IMAGE=FORMAL_PHASE2
FINAL_FORMAL_IDENTITY=0xA40A0C07/0x0000400B/0x00031002
FINAL_DIAGNOSTIC_MAGIC=0x00000000
FINAL_FORMAL_RUNTIME_GIT_SHA=0000000000000000000000000000000000000000
FINAL_FORMAL_BUILD_FLAGS=0x00000000
FINAL_PINNED_DRIVER_LOADED=YES
FINAL_PINNED_DRIVER_SHA256=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
FINAL_DRIVER_NODE_COUNT=21
FINAL_DONE=1
LAST_RETAINED_LOCAL_PROCESS_ZERO_GATE=PASS_ARM_B_POST_REBOOT_PRELOADER
LAST_RETAINED_LOCAL_VIVADO_PROCESS_COUNT=0
LAST_RETAINED_LOCAL_HW_SERVER_PROCESS_COUNT=0
LAST_RETAINED_LOCAL_CS_SERVER_PROCESS_COUNT=0
FINAL_PROCESS_ZERO_AFTER_FINAL_JTAG=PASS
FINAL_PROCESS_ZERO_RECEIPT=06_FINAL/FINAL_LOCAL_PROCESS_ZERO_GATE.txt
```

Counters are consumed only at the explicit boundaries defined by the owner prompt. The final hardware-campaign values include one optional pre-Arm-A load, one post-reboot load per arm, and no retries.

## Exact SSH accounting

The 14 unique read-only SSH sessions are: two host-preflight syntax checks, two host-preflight executions, one exact-loader syntax check, one pre-Arm-A formal telemetry session, two pre-Arm-A zero-activity sessions, two Arm-A post-reboot preloader attempts, one Arm-A telemetry session, one Arm-B pre-program zero-activity session, one Arm-B post-reboot preloader session, and one Arm-B telemetry session. `KERNEL_AND_BOOT_RAW.log` is a preserved copy of the successful second host-preflight execution and is not counted twice.

The five mutating SSH sessions are exactly three accepted loader invocations and two warm-reboot submissions. Three retained loader-wrapper failures occurred locally before SSH transport and therefore do not increase `SSH_SESSIONS_TOTAL`.

The four read-only JTAG sessions are the property-inventory preflight, the pre-Arm-A formal DONE confirmation, the Arm-A final DONE confirmation, and the Arm-B final DONE confirmation. The two programming Hardware Manager sessions are accounted separately.

## Final-state evidence limits

The formal identity and diagnostic magic come from `ARM_B_TELEMETRY_PARSED.txt`; the pinned-driver state and 21-node set come from the successful Arm-B loader receipt followed by telemetry; and final DONE comes from `ARM_B_FINAL_JTAG_DONE.log`. A final local receipt captured after the final JTAG session shows zero `vivado`, `hw_server`, and `cs_server` processes. That is a local process-ownership result, not another JTAG, SSH, MMIO, or hardware action.
