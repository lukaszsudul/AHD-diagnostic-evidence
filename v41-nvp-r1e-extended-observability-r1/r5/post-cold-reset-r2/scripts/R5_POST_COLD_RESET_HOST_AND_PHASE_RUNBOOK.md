# R5 post-cold-reset host and phase runbook

This runbook binds the R5 `POST_COLD_RESET_R2` prompt to the prepared task-local
tools. Preparing and auditing it was offline only: no SSH, Vivado, JTAG, MMIO,
reboot, loader, or hardware operation was executed.

## Frozen tool identities

```text
Invoke-ContextualPlink.ps1=5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9
parse_pci_bars.py=5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922
read_nvp_r1e.py=0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037
read_jtag_identity_done_strong.tcl=CD4938C311D886F0DEAB5FC69B9F8CDFDB0B663F40C5D174164FB14B3D9839AD
verify_runtime_identity.py=84D143C674AB7CF40E3043178B5F8D926B182A89491B76307CD69E2117D1337C
analyze_r4_telemetry.py=A19A290FF57B588AA02868F8E46AA9386005EFB0FBC38072C4373DB32F6AB967
program_once_startup_high_done.tcl=7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653
ProgramObserverCommon.ps1=6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66
```

The selected programming supervisor is owned and audited separately by the
JTAG workstream:

```text
Invoke-R5ProgramPhaseOnce.ps1=F27D4FB38AB8E080D30F647BA87D8CFC87F2A35B14A4B125DB03F15DCD099A44
```

## 1. Stable post-cold-reset Ubuntu baseline

Run this once, before the JTAG stability sessions:

```powershell
$r5 = 'C:\FPGA\V41_NVP_R1E_JTAG_RECOVERED_PAIRED_AB_R5'
& "$r5\scripts\Invoke-R5PostColdResetHostStability.ps1"
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_POST_COLD_RESET_HOST_NOT_STABLE' }
```

The wrapper starts exactly three independent Plink processes, writes three
different immutable logs, spans at least five monotonic seconds, and requires:

```text
same hostname and vcdeagent1 user;
kernel 7.0.0-29-generic in every sample;
same UUID boot ID in all three samples;
strictly increasing remote uptime;
local and remote sample spans >=5 seconds;
POST_COLD_RESET_HOST_STABILITY_GATE=PASS_3_OF_3.
```

Extract `POST_COLD_RESET_BOOT_ID_BASELINE` from
`04_HOST_SAFETY_DISCOVERY\POST_COLD_RESET_HOST_STABILITY_GATE.md`. This new R5
baseline replaces historical R4 boot continuity.

## 2. Pre-bootstrap safety discovery

Run this only after the separately owned JTAG stability gate passes 10/10:

```powershell
$baseline = '<exact POST_COLD_RESET_BOOT_ID_BASELINE UUID>'
& "$r5\scripts\Invoke-R5PreBootstrapSafetyDiscovery.ps1" `
  -PostColdResetBootIdBaseline $baseline
if ($LASTEXITCODE -ne 0) { throw 'BLOCKED_UNSAFE_PRE_BOOTSTRAP_HOST_STATE' }
```

The read-only discovery deliberately accepts either zero or one exact expected
endpoint and accepts absent XDMA module/nodes after the cold reset. It rejects a
foreign or multiple Xilinx endpoint, a wrong same-name XDMA module/binding,
node ownership, changed baseline boot ID, non-kernel-29 next boot, nonzero task
DMA, or a targeted critical kernel/AER condition. Current application identity
is optional, O_RDONLY/pread-only, and informational; it is not a bootstrap
entry gate.

## 3. Common program/reboot/loader sequence

Use this sequence once for each role. Never retry any failed step. The selected
program supervisor performs the accepted startup-HIGH/same-session-DONE gate
and the role-specific QPC minimum wait (FormalBootstrap 5 seconds, ArmA 10
seconds, ArmB 5 seconds). The separate DONE sessions are read-only.

Set the phase bindings as follows:

| Role | Program phase | Evidence directory | Remote loader directory |
|---|---|---|---|
| Formal bootstrap | `FormalBootstrap` | `05_FORMAL_BOOTSTRAP` | `bootstrap_driver` |
| Arm A | `ArmA` | `06_ARM_A_R1E` | `arm_a_driver` |
| Arm B | `ArmB` | `07_ARM_B_FORMAL` | `arm_b_driver` |

For a role `$role`, phase directory `$phaseDir`, and exact pre-reboot UUID
`$previousBootId`:

```powershell
& "$r5\scripts\Invoke-R5ProgramPhaseOnce.ps1" -Phase $role
if ($LASTEXITCODE -ne 0) { throw "PROGRAM_GATE_FAILED_$role" }

& "$r5\scripts\Invoke-R5IndependentDoneReadOnly.ps1" `
  -Role $role `
  -EvidencePrefix "$phaseDir\POST_PROGRAM_INDEPENDENT_DONE"
if ($LASTEXITCODE -ne 0) { throw "INDEPENDENT_DONE_FAILED_$role" }
```

Start the disappearance/return observer before submitting the one reboot. A
PowerShell background job is sufficient; it must be joined and must pass:

```powershell
$cycleLog = "$phaseDir\HOST_CYCLE.log"
$cycleJob = Start-Job -ScriptBlock {
  param($scriptPath, $phaseRole, $evidencePath)
  & $scriptPath -Role $phaseRole -EvidencePath $evidencePath
  if ($LASTEXITCODE -ne 0) { throw "host-cycle gate failed: $phaseRole" }
} -ArgumentList "$r5\scripts\Wait-R5HostCycle.ps1", $role, $cycleLog

Start-Sleep -Milliseconds 500
& "$r5\scripts\Invoke-R5WarmRebootOnce.ps1" `
  -Role $role `
  -EvidencePath "$phaseDir\REBOOT_SUBMIT.log"
$rebootSubmitExit = $LASTEXITCODE

Wait-Job -Job $cycleJob | Out-Null
$cycleOutput = Receive-Job -Job $cycleJob
$cycleState = $cycleJob.State
Remove-Job -Job $cycleJob
if ($rebootSubmitExit -ne 0 -or $cycleState -ne 'Completed') {
  throw "REBOOT_OR_HOST_CYCLE_FAILED_$role"
}
```

Then prove the new boot, validate the clean loader-entry state, invoke the exact
loader once, and validate the loaded/runtime state:

```powershell
& "$r5\scripts\Invoke-R5RemoteValidator.ps1" `
  -Validator PreLoader -Role $role -PreviousBootId $previousBootId `
  -EvidencePath "$phaseDir\POST_REBOOT_PRELOADER.log"
if ($LASTEXITCODE -ne 0) { throw "PRELOADER_FAILED_$role" }

& "$r5\scripts\Invoke-R5ExactPinnedLoaderOnce.ps1" `
  -Role $role -EvidencePath "$phaseDir\EXACT_PINNED_DRIVER_LOAD.log"
if ($LASTEXITCODE -ne 0) { throw "DRIVER_LOAD_FAILED_$role" }

& "$r5\scripts\Invoke-R5RemoteValidator.ps1" `
  -Validator PostLoader -Role $role -PreviousBootId $previousBootId `
  -EvidencePath "$phaseDir\POST_LOADER_VALIDATION.log"
if ($LASTEXITCODE -ne 0) { throw "POSTLOADER_FAILED_$role" }
```

Finally, run a fresh read-only JTAG DONE session:

```powershell
& "$r5\scripts\Invoke-R5IndependentDoneReadOnly.ps1" `
  -Role $role -EvidencePrefix "$phaseDir\FINAL_DONE"
if ($LASTEXITCODE -ne 0) { throw "FINAL_DONE_FAILED_$role" }
```

The post-loader validator requires exact common identity and role-specific
runtime provenance. FormalBootstrap/ArmB require the formal zero page and
diagnostic magic zero. ArmA requires the exact R1e Git SHA, build flags, and
frozen lifecycle/probe constants.

## 4. Arm A and Arm B telemetry

After Arm A post-loader validation and before its final DONE, capture the
complete two-snapshot R1e sample:

```powershell
& "$r5\scripts\Invoke-R5TelemetryReadOnly.ps1" `
  -Role ArmA `
  -EvidencePath "$r5\06_ARM_A_R1E\FULL_TELEMETRY_T0_T1.log"
if ($LASTEXITCODE -ne 0) { throw 'ARM_A_TELEMETRY_INVALID' }
```

After Arm B post-loader validation and before its final DONE, capture the full
formal control sample:

```powershell
& "$r5\scripts\Invoke-R5TelemetryReadOnly.ps1" `
  -Role ArmB `
  -EvidencePath "$r5\07_ARM_B_FORMAL\FULL_TELEMETRY_T0_T1.log"
if ($LASTEXITCODE -ne 0) { throw 'ARM_B_TELEMETRY_INVALID' }
```

The byte-exact reader opens `/dev/xdma0_user` O_RDONLY, reads T0/T1 about one
second apart, checks static coherence, validates the ordered-log rules, and
applies R1e/formal role invariants. It issues no AXI-Lite write and no DMA.

After both valid captures, the frozen analyzer accepts the contextual Plink
logs directly because it extracts the first JSON object containing `T0`/`T1`:

```powershell
& python "$r5\scripts\analyze_r4_telemetry.py" `
  --arm-a "$r5\06_ARM_A_R1E\FULL_TELEMETRY_T0_T1.log" `
  --arm-b "$r5\07_ARM_B_FORMAL\FULL_TELEMETRY_T0_T1.log" `
  --output-json "$r5\08_ANALYSIS\R5_PAIRED_ANALYSIS.json" `
  --output-markdown "$r5\08_ANALYSIS\R5_PAIRED_ANALYSIS.md"
if ($LASTEXITCODE -ne 0) { throw 'R5_PAIRED_ANALYSIS_FAILED' }
```

Use the exact Python executable already proven on the Ubuntu DUT or another
explicitly proven local interpreter; the Windows App Execution Alias at
`WindowsApps\python.exe` is not a Python runtime.

## 5. Accounting and hard-stop behavior

- Bootstrap, Arm A, and Arm B each have exactly one program, one warm reboot,
  and one loader invocation.
- No wrapper contains an automatic program, reboot, or loader retry.
- Arm B remains a full control after a terminal Arm-A result whenever the
  target remains safe and its one program authorization remains.
- Any failed gate stops that phase without corrective source, bitstream,
  PCIe-reset/rescan, driver-unload, or physical action.
- Post-program tools remain unexecuted until their preceding live gates pass.

## 6. Secret-scan boundary

Evidence may contain credential-file paths and command metadata, but never the
credential contents. Before packaging, scan text evidence for private-key
headers, bearer/token assignments, password assignments, PuTTY `-pw`, and any
unexpected credential literal. Preserve `-pwfile`, `-batch`, pinned `-hostkey`,
`-noagent`, and `-noshare`; do not replace them with an inline password.
