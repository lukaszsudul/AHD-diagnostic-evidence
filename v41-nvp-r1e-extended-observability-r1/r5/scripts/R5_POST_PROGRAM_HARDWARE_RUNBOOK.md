# R5 post-program hardware runbook

This runbook covers the independent read-only DONE confirmation, warm reboot,
post-reboot loader-entry validation, one exact pinned-driver load, post-loader
runtime validation, and Arm-A/Arm-B telemetry. It does not authorize or perform
programming itself. The tools documented here were prepared and statically
audited offline; none was executed during preparation.

## Frozen dependencies

```text
Invoke-ContextualPlink.ps1
SHA256=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9

parse_pci_bars.py
SHA256=5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922

read_nvp_r1e.py
SHA256=0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037

read_jtag_identity_done_strong.tcl
SHA256=CD4938C311D886F0DEAB5FC69B9F8CDFDB0B663F40C5D174164FB14B3D9839AD

verify_runtime_identity.py
SHA256=84D143C674AB7CF40E3043178B5F8D926B182A89491B76307CD69E2117D1337C

analyze_r4_telemetry.py
SHA256=A19A290FF57B588AA02868F8E46AA9386005EFB0FBC38072C4373DB32F6AB967

program_once_startup_high_done.tcl
SHA256=7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653

ProgramObserverCommon.ps1
SHA256=6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66
```

The first six are the exact R3/R4 read/transport/analysis tools. The final two
are retained byte-identically for the programming controller’s provenance
gate. No frozen file was rewritten for R5.

## Phase bindings

| Role | Local evidence directory | Remote loader evidence directory | Telemetry expectation |
|---|---|---|---|
| `FormalBootstrap` | `05_FORMAL_BOOTSTRAP` | `/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r5/bootstrap_driver` | formal identity/page-zero through post-loader validator |
| `ArmA` | `06_ARM_A_R1E` | `/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r5/arm_a_driver` | `read_nvp_r1e.py --expect r1e --twice --delay 1.0` |
| `ArmB` | `07_ARM_B_FORMAL` | `/home/vcdeagent1/FPGA_AHD_HOST/v41_nvp_r1e_r5/arm_b_driver` | `read_nvp_r1e.py --expect formal --twice --delay 1.0` |

## Required phase sequence

Set the task root once in the execution shell:

```powershell
$r5 = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
```

For each phase, first require the separately controlled programming operation
to pass vendor-startup HIGH and same-session DONE=1. Immediately after that
programming process closes, consume a new read-only Hardware Manager session:

```powershell
& "$r5\scripts\Invoke-R5IndependentDoneReadOnly.ps1" `
  -Role FormalBootstrap `
  -EvidencePrefix "$r5\05_FORMAL_BOOTSTRAP\IMMEDIATE_POST_PROGRAM_DONE"
```

Use `ArmA`/`06_ARM_A_R1E` and `ArmB`/`07_ARM_B_FORMAL` for the later phases.
The wrapper runs the frozen read-only Tcl through the supported Vivado launcher,
requires the exact HS2/part/IDCODE and DONE=1, records separate log/journal/raw
output, and has zero program commands.

The programming controller must then enforce the phase minimum wait from the
later accepted same-QPC program-return/same-session-DONE marker: at least 5 s
for bootstrap and Arm B, and at least 10 s for Arm A. Preserve the boot ID read
before submitting the reboot as `$previousBootId`.

Submit exactly one reboot:

```powershell
& "$r5\scripts\Invoke-R5WarmRebootOnce.ps1" `
  -Role FormalBootstrap `
  -EvidencePath "$r5\05_FORMAL_BOOTSTRAP\WARM_REBOOT_SUBMIT.log"
```

Observe disappearance and return without changing remote state:

```powershell
& "$r5\scripts\Wait-R5HostCycle.ps1" `
  -Role FormalBootstrap `
  -EvidencePath "$r5\05_FORMAL_BOOTSTRAP\HOST_CYCLE.log"
```

After return, validate loader-entry state. This read-only gate proves the boot
ID changed, kernel 29 is active, exact endpoint/link/BAR geometry is present,
the endpoint is unbound, XDMA is absent, the role-specific remote evidence
directory is fresh, node owners are absent, and targeted kernel/AER health is
clean:

```powershell
& "$r5\scripts\Invoke-R5RemoteValidator.ps1" `
  -Validator PreLoader `
  -Role FormalBootstrap `
  -PreviousBootId $previousBootId `
  -EvidencePath "$r5\05_FORMAL_BOOTSTRAP\POST_REBOOT_PRELOADER.log"
```

Invoke the exact accepted loader once:

```powershell
& "$r5\scripts\Invoke-R5ExactPinnedLoaderOnce.ps1" `
  -Role FormalBootstrap `
  -EvidencePath "$r5\05_FORMAL_BOOTSTRAP\EXACT_PINNED_DRIVER_LOAD.log"
```

Then run the read-only post-loader gate:

```powershell
& "$r5\scripts\Invoke-R5RemoteValidator.ps1" `
  -Validator PostLoader `
  -Role FormalBootstrap `
  -PreviousBootId $previousBootId `
  -EvidencePath "$r5\05_FORMAL_BOOTSTRAP\POST_LOADER_FORMAL_IDENTITY.log"
```

The post-loader gate checks the exact module/loader/accepted-reader identities,
21-node set, binding, zero owners, BARs, kernel health, raw O_RDONLY identity,
accepted-reader identity, and role-specific R1e provenance or formal page-zero
semantics. For bootstrap, run a second independent-DONE invocation with a fresh
prefix such as `FINAL_FORMAL_READY_DONE` after identity validation.

Repeat the same reboot/preloader/loader/postloader sequence with `ArmA`, then
collect the full static T0/T1 sample:

```powershell
& "$r5\scripts\Invoke-R5TelemetryReadOnly.ps1" `
  -Role ArmA `
  -EvidencePath "$r5\06_ARM_A_R1E\ARM_A_FULL_T0_T1_TELEMETRY.log"
```

After the reader passes all R1e invariants and static coherence, run the final
independent-DONE invocation with a fresh prefix such as `FINAL_POST_TELEMETRY_DONE`.

Repeat with `ArmB`; its post-loader gate proves formal identity and the entire
0x2000..0x20FF page is zero/reserved. Collect the full control sample:

```powershell
& "$r5\scripts\Invoke-R5TelemetryReadOnly.ps1" `
  -Role ArmB `
  -EvidencePath "$r5\07_ARM_B_FORMAL\ARM_B_FULL_T0_T1_TELEMETRY.log"
```

Only after that telemetry passes, obtain final independent DONE=1. The final
accepted state is exact formal Phase 2 with the exact pinned driver loaded.

## Analysis handoff

The exact frozen lifecycle/log/probe analyzer accepts the two contextual
telemetry logs directly:

```powershell
python "$r5\scripts\analyze_r4_telemetry.py" `
  --arm-a "$r5\06_ARM_A_R1E\ARM_A_FULL_T0_T1_TELEMETRY.log" `
  --arm-b "$r5\07_ARM_B_FORMAL\ARM_B_FULL_T0_T1_TELEMETRY.log" `
  --output-json "$r5\08_ANALYSIS\R5_PAIRED_ANALYSIS.json" `
  --output-markdown "$r5\08_ANALYSIS\R5_PAIRED_ANALYSIS.md"
```

Its internal schema name remains R4 because the accepted analyzer is frozen;
that label is tool provenance, not a change to the R5 sample identity.

## Terminal restrictions

There is no retry loop in the reboot, loader, telemetry, or independent-DONE
wrappers. A failed phase gate is terminal under the R5 master prompt. These
tools do not authorize a second bootstrap, second Arm-A/Arm-B sample, fourth
program, PCIe reset/rescan, AXI-Lite write, DMA, build, source edit, or physical
recovery action.
