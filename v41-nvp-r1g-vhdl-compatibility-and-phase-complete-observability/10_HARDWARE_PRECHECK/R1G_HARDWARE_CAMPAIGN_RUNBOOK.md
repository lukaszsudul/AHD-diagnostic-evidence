# R1g hardware campaign runbook

This file prepares the authorized campaign but records no live action. The
active binding file does not exist until the one R1g source commit and one
clean build pass.

## Offline release gates

After build PASS, create
`09_HOST_TOOLS/R1G_HARDWARE_BINDINGS.json` from the template and replace only
the pending selected full path, R1g bit, and R1g source commit/tree values.
Then require both offline commands to pass:

```powershell
& .\fixtures\Test-R1gCampaignToolingOffline.ps1 `
  -BindingPath .\09_HOST_TOOLS\R1G_HARDWARE_BINDINGS.json `
  -RequireFrozenHardwareBindings

& .\fixtures\Test-R1gPostBuildHardwareBindings.ps1 `
  -BindingPath .\09_HOST_TOOLS\R1G_HARDWARE_BINDINGS.json
```

Expected gates:

```text
STATIC_AUDIT_GATE=PASS_READY_FOR_SEPARATE_LIVE_PRECHECK
POSTBUILD_BINDING_GATE=PASS_READY_FOR_FRESH_HARDWARE_PRECHECK
```

## Fresh formal start state

Initialize the seven evidence leaves once, then run the fresh read-only gates
in order:

```powershell
$tools = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\09_HOST_TOOLS'
$pre = 'C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\10_HARDWARE_PRECHECK'
$binding = "$tools\R1G_HARDWARE_BINDINGS.json"

& "$tools\Initialize-R1gCampaignEvidenceDirectories.ps1"
& "$pre\Invoke-R1gHostBaselineReadOnly.ps1"
& "$pre\Invoke-R1gPrecheckJtagDoneReadOnly.ps1" -BindingPath $binding
& "$pre\Invoke-R1gStartSafetyReadOnly.ps1" -BindingPath $binding
```

If the exact formal candidate exists, collect formal telemetry, finalize the
gate, and issue the existing-formal receipt. If it does not, the finalized
read-only gate must explicitly say `BOOTSTRAP_REQUIRED_SAFE` before the one
optional bootstrap is authorized. Bootstrap is never B1.

## Frozen phase transaction

The phase order is immutable:

```text
A1 -> B1 -> A2 -> B2 -> A3 -> B3
```

For each authorized phase token, using its exact predecessor receipt SHA:

1. `Invoke-R1gProgramOnce.ps1` (one reservation, one process, zero retry);
2. `Invoke-R1gIndependentDoneReadOnly.ps1 -Stage Immediate`;
3. `Wait-R1gProgramMinimum.ps1`;
4. `Invoke-R1gHostStep.ps1 -Step WarmReboot`;
5. `Invoke-R1gHostStep.ps1 -Step WaitHostCycle`;
6. `Invoke-R1gHostStep.ps1 -Step PreLoaderValidate`;
7. `Invoke-R1gHostStep.ps1 -Step ExactDriverLoad`;
8. `Invoke-R1gTelemetryReadOnly.ps1`;
9. `Invoke-R1gIndependentDoneReadOnly.ps1 -Stage Final`;
10. `New-R1gConfiguredImageReceipt.ps1`.

Arm A uses the exact wait `33.536673744` seconds. Bootstrap and every B use
five seconds. Telemetry first proves exact R1g source commit/build flags (or
formal identity and complete R1f/R1g-range zero), then collects two complete
coherent snapshots with the exact inherited R1f reader.

Receipt chain:

```text
A1 <- 10_HARDWARE_PRECHECK/FORMAL_START_READY_RECEIPT.txt
B1 <- 12_PAIR_1/A1_R1G/VALID_ARM_A_RECEIPT.txt
A2 <- 12_PAIR_1/B1_FORMAL/FORMAL_READY_RECEIPT.txt
B2 <- 13_PAIR_2/A2_R1G/VALID_ARM_A_RECEIPT.txt
A3 <- 13_PAIR_2/B2_FORMAL/FORMAL_READY_RECEIPT.txt
B3 <- 14_PAIR_3/A3_R1G/VALID_ARM_A_RECEIPT.txt
```

An infrastructure-invalid A may issue only its terminal-safe DONE1 receipt,
run its immediate B control/restoration when safe, and then stop. An invalid B
stops before the next A. No arm repeats.

## Absolute accounting

| Start route | Programs | Warm reboots | Driver loads |
|---|---:|---:|---:|
| existing formal | 6 | 6 | 6 |
| one safe formal bootstrap | 7 | 7 | 7 |

No cold start, physical action, JTAG-frequency change, PCI remove/rescan,
AXI-Lite write, NVP/I2C host write, C2H/H2C transfer, Phase 3, or XDMA
development path is provided.
