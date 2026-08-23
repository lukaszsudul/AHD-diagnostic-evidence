# R7 mode-aware DONE0 operation ledger

```text
TASK=V41_NVP_R1E_MODE_AWARE_BOOTSTRAP_FROM_DONE0_AND_COMPLETE_PAIRED_AB_R7
TASK_ROOT=C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7
INITIALIZED_UTC=2026-08-23T22:33:46.1986954Z
OWNER_STANDING_AUTHORIZATION=GRANTED
OWNER_PROMPT_SHA256=F7DF54CF287B5DC87B83B956989E43F9550167769DD4D3742526AD9E31AF56E5

FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0
READ_ONLY_R7_JTAG_RECONFIRMATION_SESSIONS=1
R7_JTAG_RECONFIRMATION_SAMPLES=5
READ_ONLY_HOST_BASELINE_SESSIONS=2
READ_ONLY_PRE_BOOTSTRAP_SAFETY_SESSIONS=1
READ_ONLY_INDEPENDENT_DONE_SESSIONS=6
FPGA_PROGRAM_INVOCATIONS=3
FORMAL_BOOTSTRAP_PROGRAMS=1
ARM_A_PROGRAMS=1
ARM_B_PROGRAMS=1
WARM_REBOOTS=3
FORMAL_BOOTSTRAP_WARM_REBOOTS=1
ARM_A_WARM_REBOOTS=1
ARM_B_WARM_REBOOTS=1
DRIVER_LOADS=3
FORMAL_BOOTSTRAP_DRIVER_LOADS=1
ARM_A_DRIVER_LOADS=1
ARM_B_DRIVER_LOADS=1
PROGRAM_RETRIES=0
HISTORICAL_PRETASK_COLD_RESET=YES_RECORDED_R5
COLD_STARTS_DURING_R7=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS_DURING_TASK=0
JTAG_FREQUENCY_CHANGES=0
KERNEL_OR_GRUB_CHANGES=0
PCI_REMOVE_RESCAN_RESETS=0
FORMAL_REPOSITORY_MUTATIONS=0
OWNER_INTERACTIVE_APPROVAL_REQUESTS=0
```

## Events

- `2026-08-23T22:33:46.1986954Z` — Created the fresh R7 task root, saved the owner prompt verbatim, and initialized all counters before any R7 JTAG or SSH operation.
- `2026-08-23T22:55:45.6284160Z` — Offline P0-P3 gates passed: exact R6 evidence/artifact identities, frozen host-tool identities and fixtures, mode-aware observer 12/12 fixtures, R6 replay, 85/85 observer static audit, and 22/22 host/phase tool manifest. No live JTAG, SSH, FPGA program, reboot, driver load, MMIO, or DMA operation occurred.
- `2026-08-23T22:56:23.7153152Z` — Fresh R7 host baseline passed 2/2 read-only SSH sessions. Stable boot ID `dd140158-f8dc-46eb-9a05-27bb532713aa`, kernel and next-reboot kernel `7.0.0-29-generic`, strictly increasing uptime, no observed reboot/shutdown.
- `2026-08-23T22:58:22.9528100Z` — Fresh selected-JTAG reconfirmation passed 5/5 read-only refresh samples on `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`, exact `xc7a35t` / `0362D093`, stable readable DONE=0, recorded default frequency 6000000 with no change, and zero program invocations.
- `2026-08-23T22:58:58.8585299Z` — Pre-bootstrap read-only host safety gate passed: kernel/boot continuity and next-boot kernel 29; expected endpoint, XDMA driver, and nodes absent and accepted; node owners 0; task DMA 0; kernel/AER health PASS; all three remote loader evidence directories fresh.
- `2026-08-23T23:02:09.3777863Z` — Consumed the single formal-bootstrap program authorization. Bootstrap-mode pre-DONE samples `0,0,0,0,0`; exact formal bit programmed once; vendor startup HIGH; same-session fresh DONE=1; program observer PASS; no retry. Program timing receipt SHA-256 `5DC6D84707E9B76AAE37D0EE0ACA5A99C58D1C91E027E6926B602056E18DEF13`.
- `2026-08-23T23:04:49.0038560Z` — Bootstrap independent DONE=1 and 5-second minimum-wait gates passed; submitted exactly one bootstrap warm reboot. Reboot evidence SHA-256 `F37EB7225AB07CD475224D8887638F81D51BFCAA3D997F3882478304C325C22D`.
- `2026-08-23T23:07:17.6562356Z` — Bootstrap host cycle proven from the original TCP/22 false/exception branch plus returned pre-loader SSH, changed boot ID `093fec43-4e32-4c5a-87cc-cbaa389662a1`, and kernel 29. Corrected only missing whitespace in the task-local read-only TCP observer for later phases; no second reboot or other state change.
- `2026-08-23T23:08:19.3585670Z` — Invoked the exact pinned bootstrap driver loader once; exit 0, exact module path/hash/version/vermagic, one expected endpoint, and expected 21-node set. Loader evidence SHA-256 `EE56FC3B83E135DC83B2644EE4CA370891DF9601D22AFB336ECB54DF4C1366B9`.
- `2026-08-23T23:10:39.0879265Z` — Bootstrap post-loader validation passed: exact formal identity `A40A0C07/0000400B/00031002`, diagnostic magic 0, exact BARs/driver/nodes, no owners/DMA, health PASS; fresh final selected-JTAG DONE=1.
- `2026-08-23T23:12:15.4346017Z` — Sealed `FORMAL_READY_RECEIPT` after correcting only the offline receipt helper's duplicate-identical BAR-value handling. Receipt SHA-256 `1E9F7530C5A0E34CE9CCC299C6CC558AE6C46E4C2A073BAF16D17EC8BBD1D879`; FORMAL_READY=YES.
- `2026-08-23T23:14:40.5303207Z` — Consumed the single Arm-A program authorization. Transition-mode pre-DONE samples `1,1,1,1,1` with exact formal-ready receipt; exact R1e bit programmed once; vendor startup HIGH; same-session fresh DONE=1; no retry. Program timing receipt SHA-256 `084BD273D2E43795CA30A11CA21B424DD6A276BE2EFBB70B35C4D53505D29800`.
- `2026-08-23T23:17:19.7117218Z` — Arm-A independent DONE=1, terminal-safe DONE1 receipt, and 10-second wait gates passed; submitted exactly one Arm-A warm reboot. Reboot evidence SHA-256 `0CCC6F12145FCBF8D7526DE37FD0332977A678EC56EC48461D5B49FEC72E7CBB`.
- `2026-08-23T23:18:50.6231813Z` — Arm-A host cycle, changed boot ID `c6cf85f0-0a06-4d2f-8656-5bca7cbb19a3`, kernel/BAR pre-loader gate, exact pinned-driver load 2/3, and post-loader R1e provenance gate all passed (`f3d9e5c...`, build flags `0x2`, lifecycle magic present).
- `2026-08-23T23:20:54.7634600Z` — Arm-A T0/T1 telemetry passed all coherence/instrumentation gates and fresh final selected-JTAG DONE=1. Lifecycle count `132688568` (signed extension `+103834` cycles); autoinit NACK count 13 with first-8-only ordered log; probe 9971 ACK / 29 NACK / 0 timeout of 10000.
- `2026-08-23T23:21:35.3112321Z` — Sealed `VALID_ARM_A_RECEIPT` SHA-256 `B74C6B83F9DE583397EDF7A5B7E192401B05D3DEDBDFA9A01E1352809F68AFCB`; Arm A sample valid and safe for the mandatory Arm-B formal transition/restoration.
- `2026-08-23T23:24:20.9590132Z` — Consumed the single Arm-B and final task program authorization. Transition-mode pre-DONE samples `1,1,1,1,1` with exact valid Arm-A receipt; exact formal bit programmed once; vendor startup HIGH; same-session fresh DONE=1; no retry. Program timing receipt SHA-256 `7C7E8D4A7A0B69F7139931476904546729ADA80FDE38F40B3580F735CF02B9DB`.
- `2026-08-23T23:26:42.2625269Z` — Arm-B independent DONE=1 and 5-second wait gates passed; submitted exactly one Arm-B warm reboot (task warm reboot 3/3). Reboot evidence SHA-256 `1F404201DA238E439D6B7EFDBFB0869C7D3EB3B97CB8A8311F101534201C8C29`.
- `2026-08-23T23:33:35.6069738Z` — Arm-B reboot proven by successful submission plus changed boot ID `e2a2517a-c275-4ea9-bf11-83c0db94111e`; the delayed TCP observer saw only UP and made no state change. Kernel/BAR pre-loader gate, exact pinned-driver load 3/3, and formal post-loader identity/page-zero gate passed.
- `2026-08-23T23:36:20.6209549Z` — Arm-B full T0/T1 formal control telemetry passed: exact identity/page zero, matching static snapshots, NACK count 15 with first-8-only ordered log, zero timeout; fresh final selected-JTAG DONE=1. Hardware campaign complete with exact formal Phase 2 active, pinned driver loaded, and no remaining program/reboot/load authorization.
