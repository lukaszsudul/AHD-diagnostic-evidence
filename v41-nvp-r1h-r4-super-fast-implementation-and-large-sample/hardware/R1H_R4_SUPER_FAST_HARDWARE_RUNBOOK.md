# R1h-R4 super-fast hardware runbook

Status: `PREPARED_NOT_EXECUTED`. This runbook and its scripts performed no
credential read, SSH, JTAG, FPGA programming, reboot, driver load, MMIO, DMA,
or physical action during preparation.

## Frozen paths

```text
TASK_ROOT=C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST
SCRIPTS=C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\scripts
BINDING=C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\hardware\R1H_R4_HARDWARE_BINDING.json
IMPLEMENTATION_RECEIPT=C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\implementation\R1H_R4_IMPLEMENTATION_RESULT.txt
R1H_BIT=C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\implementation\ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit
FORMAL_BIT=C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit
CREDENTIAL_FILE=C:\FPGA\VCDE-DUT-1.txt
HOSTKEY=SHA256:yunI1fwP5I6WfGcSVkyaPxd0siCbdSiOOXVrP0wtEu8
```

The credential file is consumed only inside the exact accepted
`Invoke-ContextualPlink.ps1` process at the first authorized SSH command. It
was not opened or hashed during offline preparation.

## Release and minimal safety

After the one implementation session returns PASS, execute exactly once:

```powershell
& "$scripts\Invoke-R1hR4JtagSafetyReadOnly.ps1"
& "$scripts\Invoke-R1hR4MinimalHostSafetyReadOnly.ps1"
& "$scripts\New-R1hR4HardwareBinding.ps1"
```

The first command reuses the exact accepted five-sample R7 selector and allows
the current informational DONE value to be either zero or one. The second is
read-only and gates kernel 29, next reboot kernel 29, no XDMA node owner, zero
task DMA, kernel/AER health, and the exact pinned module/loader identities. The
third independently binds both bit hashes, exact source/tree, implementation
PASS receipt, exact selected target/part/IDCODE, host gate, reader, and frozen
statistics module. It emits the mandatory-bootstrap gate and immutable JSON
binding.

## Per-program exact order

For every token, the order is fixed:

1. `Invoke-R1hProgramOnce.ps1` with the exact predecessor receipt (none only
   for mandatory `Bootstrap`).
2. Hash `PROGRAM_TIMING_RECEIPT.txt`.
3. `Invoke-R1hIndependentDoneReadOnly.ps1 -Stage Immediate`; hash its receipt.
4. For A1/A2/A3, immediately create `ArmATerminalSafeDone1` receipt.
5. `Wait-R1hProgramMinimum.ps1` with both exact hashes.
6. `Invoke-R1hHostStep.ps1 -Step WarmReboot` exactly once.
7. `Invoke-R1hHostStep.ps1 -Step WaitHostCycle`.
8. `Invoke-R1hHostStep.ps1 -Step PreLoaderValidate -PreviousBootId <exact>`.
9. `Invoke-R1hHostStep.ps1 -Step ExactDriverLoad` once.
10. `Invoke-R1hTelemetryReadOnly.ps1` (two snapshots, one-second separation),
    except Bootstrap uses `-RuntimeOnly` for the exact formal identity and
    diagnostic-magic gate required by R4.
11. `Invoke-R1hIndependentDoneReadOnly.ps1 -Stage Final`.
12. Create `FormalReady` after Bootstrap/B1/B2/B3 or `ValidArmA` after a valid
    A1/A2/A3, binding the current operation-ledger SHA-256.

The bootstrap and B reader uses the accepted formal/R1e telemetry reader for
the essential formal identity, diagnostic-magic, normal telemetry and legacy
window gates. The task-local runtime leaf scans the complete R1h range only as
an optional recorded check, matching the R4 owner policy. Arm A uses the exact
full R1f/R1h reader and validates all 64x6 record words, every phase aggregate,
all ten block counts per phase, stored index entries, bank invariants, target
restoration, and static two-snapshot coherence.

## Command template

```powershell
$scripts = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\scripts'
$binding = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\hardware\R1H_R4_HARDWARE_BINDING.json'

# Program. Add the two receipt arguments for every non-Bootstrap token.
& "$scripts\Invoke-R1hProgramOnce.ps1" -PhaseToken Bootstrap -BindingPath $binding

$phaseDir = 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\hardware\01_BOOTSTRAP'
$timingSha = (Get-FileHash "$phaseDir\PROGRAM_TIMING_RECEIPT.txt" -Algorithm SHA256).Hash
& "$scripts\Invoke-R1hIndependentDoneReadOnly.ps1" -PhaseToken Bootstrap -Stage Immediate -BindingPath $binding
$doneSha = (Get-FileHash "$phaseDir\INDEPENDENT_DONE_RECEIPT.txt" -Algorithm SHA256).Hash
& "$scripts\Wait-R1hProgramMinimum.ps1" -PhaseToken Bootstrap -BindingPath $binding -ProgramTimingSha256 $timingSha -IndependentDoneSha256 $doneSha
& "$scripts\Invoke-R1hHostStep.ps1" -PhaseToken Bootstrap -Step WarmReboot -BindingPath $binding
& "$scripts\Invoke-R1hHostStep.ps1" -PhaseToken Bootstrap -Step WaitHostCycle -BindingPath $binding
& "$scripts\Invoke-R1hHostStep.ps1" -PhaseToken Bootstrap -Step PreLoaderValidate -BindingPath $binding -PreviousBootId '<exact-current-boot-id-before-reboot>'
& "$scripts\Invoke-R1hHostStep.ps1" -PhaseToken Bootstrap -Step ExactDriverLoad -BindingPath $binding
& "$scripts\Invoke-R1hTelemetryReadOnly.ps1" -PhaseToken Bootstrap -BindingPath $binding -RuntimeOnly
& "$scripts\Invoke-R1hIndependentDoneReadOnly.ps1" -PhaseToken Bootstrap -Stage Final -BindingPath $binding
$ledgerSha = (Get-FileHash 'C:\FPGA\V41_NVP_R1H_R4_SUPER_FAST\OPERATION_LEDGER.md' -Algorithm SHA256).Hash
& "$scripts\New-R1hConfiguredImageReceipt.ps1" -PhaseToken Bootstrap -ReceiptKind FormalReady -BindingPath $binding -OperationLedgerSha256 $ledgerSha
```

For a non-bootstrap phase, add:

```powershell
-ConfiguredImageReceiptPath '<exact predecessor receipt>' `
-ExpectedConfiguredImageReceiptSha256 '<exact predecessor SHA256>'
```

The exact previous boot ID for Bootstrap is recorded by the minimal host-safety
raw evidence. Each later phase uses `CURRENT_BOOT_ID` from the immediately
preceding phase's accepted `PRELOADER_EVIDENCE.log`; no extra mutable discovery
is required.

## Single global programming retry

Primary program failure does not automatically retry. Only when the failure is
classified `FAIL_BEFORE_PROGRAM` or `FAIL_OBSERVER_GATE`, the mode-aware target
precondition passed, and no reboot/telemetry followed, invoke the task-local
`Invoke-R1hR4EligibleProgramRetryOnce.ps1` with the same phase, binding, and
predecessor-receipt arguments. It:

- reserves the single global retry irreversibly;
- performs one fresh read-only five-sample target/part/IDCODE re-establishment;
- rehashes the identical bit before and after that check;
- archives the failed primary evidence without deletion;
- invokes the same exact program observer once with `PROGRAM_RETRIES=1`.

It refuses a second retry, changed target/bit, post-failure reboot/telemetry,
or any non-infrastructure classification.

## Fixed accounting

```text
PRIMARY_PROGRAMS_PLANNED=7
GLOBAL_PROGRAM_RETRY_BUDGET=1
FPGA_PROGRAM_INVOCATIONS_MAX=8
WARM_REBOOTS_MAX=7
DRIVER_LOADS_MAX=7
HOST_MMIO_WRITES=0
DMA_TRANSFERS=0
PHYSICAL_ACTIONS=0
```
