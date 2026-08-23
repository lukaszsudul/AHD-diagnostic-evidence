# R7 authorized host and phase runbook

STATUS=PREPARED_NOT_EXECUTED
LIVE_ACTIONS_PERFORMED_BY_RUNBOOK_AUTHOR=0

This runbook binds the task-local host tools to the R7 evidence layout. It is
not an authorization expansion. Stop on the first nonzero exit or failed gate;
do not retry a program, reboot, loader, telemetry sample, or JTAG session.

## Offline-frozen paths

```text
TASK_ROOT=C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7
SCRIPTS=C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\scripts
FORMAL_PHASE=07_FORMAL_BOOTSTRAP
ARM_A_PHASE=08_ARM_A_R1E
ARM_B_PHASE=09_ARM_B_FORMAL
REMOTE_BOOTSTRAP_DRIVER=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/bootstrap_driver
REMOTE_ARM_A_DRIVER=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_a_driver
REMOTE_ARM_B_DRIVER=/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r7/arm_b_driver
```

The selected full JTAG target path must be read from the passed, immutable
`05_JTAG_RECONFIRMATION\R7_JTAG_RECONFIRMATION_GATE.md` receipt. Do not infer
it from a suffix or substitute a newly enumerated target.

## Baseline and pre-bootstrap discovery

1. Run `Invoke-R7HostBaseline.ps1` once. Require
   `R7_HOST_BASELINE=PASS_2_OF_2`; preserve its exact boot ID and receipt hash.
2. Complete the separately owned selected-JTAG reconfirmation. Require
   `R7_JTAG_RECONFIRMATION_GATE=PASS_5_OF_5` and freeze the exact full target
   path.
3. Run `Invoke-R7PreBootstrapSafetyDiscovery.ps1 -R7BootIdBaseline <boot-id>`
   once. Require its contextual evidence `RESULT=PASS`, `EXIT_CODE=0`, and
   pre-bootstrap safety gate PASS. Endpoint, driver, and node absence are
   accepted only through that bounded gate.

## Per-program ordering

For `FormalBootstrap`, `ArmA`, and `ArmB`, preserve this order:

1. Invoke the frozen `Run-ProgramOnceModeAware.ps1` exactly once with the
   exact full target path. Bootstrap has no configured-image receipt. Arm A
   supplies the exact hashed `FORMAL_READY_RECEIPT.txt`. Arm B supplies exactly
   one exact hashed `VALID_ARM_A_RECEIPT.txt` or
   `ARM_A_TERMINAL_SAFE_DONE1_RECEIPT.txt`.
2. Hash the immutable `PROGRAM_TIMING_RECEIPT.txt`.
3. Run `Invoke-R7IndependentDoneReadOnly.ps1 -Stage Immediate` once. Hash
   `INDEPENDENT_DONE_RECEIPT.txt` and require
   `INDEPENDENT_DONE_GATE=PASS_SELECTED_TARGET_DONE_1`.
4. Immediately after Arm A step 3, create
   `ARM_A_TERMINAL_SAFE_DONE1_RECEIPT.txt` with
   `New-R7ConfiguredImageReceipt.ps1 -ReceiptKind ArmATerminalSafeDone1`.
   This receipt intentionally depends only on the accepted program timing
   receipt and the independent immediate DONE=1 receipt, so it remains usable
   for safe Arm-B restoration if a later Arm-A infrastructure gate fails.
5. Run `Wait-R7ProgramMinimumAfterIndependentDone.ps1` with the exact hashes
   of the timing and immediate-DONE receipts. Require `WAIT_GATE=PASS`.
6. Run `Invoke-R7WarmRebootOnce.ps1` once, writing
   `WARM_REBOOT_EVIDENCE.log` in the phase directory.
7. Run `Wait-R7HostCycle.ps1`, writing `HOST_CYCLE_RECEIPT.txt`; require
   `PASS_HOST_DISAPPEARED_AND_RETURNED`.
8. Run `Invoke-R7RemoteValidator.ps1 -Validator PreLoader` using the boot ID
   from immediately before the reboot, writing `PRELOADER_EVIDENCE.log`.
9. Run `Invoke-R7ExactPinnedLoaderOnce.ps1` once, writing
   `LOADER_EVIDENCE.log`.
10. Run `Invoke-R7RemoteValidator.ps1 -Validator PostLoader` with the same
    previous boot ID, writing `POSTLOADER_EVIDENCE.log`.
11. For Arm A and Arm B only, run `Invoke-R7TelemetryReadOnly.ps1` once,
    writing `TELEMETRY_EVIDENCE.log`. It invokes the exact frozen reader with
    two read-only snapshots separated by one second.
12. Run `Invoke-R7IndependentDoneReadOnly.ps1 -Stage Final` once, producing
    `FINAL_DONE_RECEIPT.txt`; require DONE=1.
13. After a fully passed bootstrap, create `FORMAL_READY_RECEIPT.txt` using
    `New-R7ConfiguredImageReceipt.ps1 -ReceiptKind FormalReady` and the exact
    hashes of every named input plus the current operation-ledger SHA-256.
14. After a fully valid Arm A, create `VALID_ARM_A_RECEIPT.txt` using
    `-ReceiptKind ValidArmA` and the telemetry plus operation-ledger hashes.

The immediate independent-DONE check occurs before the minimum-wait gate. The
minimum-wait gate measures from the later accepted same-QPC program-return or
same-session fresh-DONE marker and enforces 5/10/5 seconds for bootstrap,
Arm A, and Arm B respectively.

## Evidence filenames fixed by the tooling

```text
PROGRAM_TIMING_RECEIPT.txt
INDEPENDENT_DONE_RECEIPT.txt
PROGRAM_WAIT_RECEIPT.txt
WARM_REBOOT_EVIDENCE.log
HOST_CYCLE_RECEIPT.txt
PRELOADER_EVIDENCE.log
LOADER_EVIDENCE.log
POSTLOADER_EVIDENCE.log
TELEMETRY_EVIDENCE.log          # Arm A and Arm B only
FINAL_DONE_RECEIPT.txt
FORMAL_READY_RECEIPT.txt        # bootstrap output
ARM_A_TERMINAL_SAFE_DONE1_RECEIPT.txt
VALID_ARM_A_RECEIPT.txt         # only after a valid Arm-A sample
```

## Accounting boundary

The host baseline and all validators are read-only. The only task-local host
state changes are the three individually bounded warm-reboot wrappers and
three exact pinned-loader wrappers, each called at most once in its phase.
Telemetry uses `O_RDONLY`/`pread`; no AXI-Lite write or DMA command appears in
the prepared host toolchain.
