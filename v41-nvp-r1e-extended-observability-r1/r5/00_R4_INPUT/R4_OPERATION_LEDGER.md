# R4 Operation Ledger

TASK=V41_NVP_R1E_FORMAL_BOOTSTRAP_RECOVERY_AND_COMPLETE_PAIRED_AB_R4
OWNER_STANDING_AUTHORIZATION=GRANTED
TASK_ROOT=C:\FPGA\V41_NVP_R1E_FORMAL_BOOTSTRAP_AND_PAIRED_AB_R4
INITIALIZED_UTC=2026-08-23T12:58:15.7747847Z

FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
FPGA_PROGRAM_INVOCATIONS=1
FORMAL_BOOTSTRAP_PROGRAMS=1
ARM_A_PROGRAMS=0
ARM_B_PROGRAMS=0
WARM_REBOOTS=0
FORMAL_BOOTSTRAP_WARM_REBOOTS=0
ARM_A_WARM_REBOOTS=0
ARM_B_WARM_REBOOTS=0
DRIVER_LOADS=0
FORMAL_BOOTSTRAP_DRIVER_LOADS=0
ARM_A_DRIVER_LOADS=0
ARM_B_DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS=0
KERNEL_OR_GRUB_CHANGES=0
PCI_REMOVE_RESCAN_RESETS=0
FORMAL_REPOSITORY_MUTATIONS=0

## Events

- 2026-08-23T12:58:15.7747847Z: Created isolated R4 task root and required directory structure.
- 2026-08-23T12:58:15.7747847Z: Saved the verbatim R4 owner prompt before any R4 hardware command; SHA-256 5B65A807FADC4558169B9F6AD103DEF61C45730ECF406359082B1BEC1B9B29B5.
- 2026-08-23T13:08:55Z: Began one fresh read-only JTAG discovery session. No program command was present or executed.
- 2026-08-23T13:11:34Z: Read-only JTAG discovery passed: one HS2 210241768436 target, xc7a35t, IDCODE 0362D093, DONE=1, programs=0.
- 2026-08-23T13:18:58.9933409Z: Fresh host/PCIe/driver/MMIO discovery completed. Exact endpoint/BARs/pinned driver/zero owners/health passed; both readers returned BLOCK_ID=0xFFFFFFFF.
- 2026-08-23T13:20:02.9255635Z: Classified start state REQUIRES_EXACT_FORMAL_BOOTSTRAP; bootstrap safety gate passed. Program/reboot/driver counters remain zero.
- 2026-08-23T13:24:58Z: Exact formal bootstrap `program_hw_devices` invocation consumed (program 1 of maximum 3; bootstrap 1 of maximum 1).
- 2026-08-23T13:25:06Z: Bootstrap failed with vendor startup LOW (`[Labtools 27-3165]`); no program-return or fresh-DONE marker. Hard stop invoked with no retry. Arm A and Arm B not run; reboots and driver loads remain zero.
- 2026-08-23T13:34:09.8847368Z: Offline blocked-outcome analysis and the single authoritative report completed. Secret scan passed; exact bit copies, raw programming transcript, and Vivado log/journal were staged for sealing. No post-failure hardware command occurred.
- 2026-08-23T13:34:09.8847368Z: Evidence seal prepared for `V41_NVP_R1E_R4_COMPLETE_MEASUREMENT_EVIDENCE.zip`; final SHA-256 is authoritative in the external sidecar.
