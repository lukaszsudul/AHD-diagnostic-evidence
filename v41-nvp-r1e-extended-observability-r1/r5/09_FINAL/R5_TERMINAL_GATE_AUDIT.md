# R5 terminal-gate and operation-accounting audit

## Outcome

R5 reached its required terminal hard stop at the fresh read-only JTAG
transport-stability gate. Both independently launched Hardware Manager sessions
enumerated one intended target path, but `open_hw_target` failed before device
enumeration with:

```text
[Labtools 27-2269] No devices detected on target
localhost:3121/xilinx_tcf/Digilent/210241768436.
```

Consequently no refresh sample, device property list, part, IDCODE, or DONE
value was obtained. The bootstrap entry gate did not open.

```text
HARD_STOP_CLASSIFICATION=BLOCKED_JTAG_TRANSPORT_NOT_STABLE
READ_ONLY_JTAG_STABILITY_SESSIONS=2
JTAG_STABILITY_SAMPLES=0
JTAG_TRANSPORT_STABILITY_GATE=FAIL_0_OF_10
JTAG_PRECHECK_DONE_VALUE=UNREADABLE
FPGA_PROGRAM_INVOCATIONS=0
SSH_SESSIONS=0
```

## Evidence reconciliation

The two session records independently agree:

| Field | Session 1 | Session 2 |
|---|---:|---:|
| Process started | yes | yes |
| Process timed out | no | no |
| Process exit code | 1 | 1 |
| Initial target count | 1 | 1 |
| Intended target-path matches | 1 | 1 |
| Device enumeration completed | no | no |
| Successful refresh samples | 0 | 0 |
| DONE readable | no | no |
| FPGA program operations | 0 | 0 |
| Failure | Labtools 27-2269 | Labtools 27-2269 |

The empty aggregate matrix and header-only session matrices are consistent
with failure before the first sample. The supervisor gate correctly rejected
both nonzero process exits, both missing five-sample sets, both absent property
lists, and the absence of a stable readable DONE value.

Relevant evidence identities:

```text
OWNER_PROMPT_SHA256=
    070F457D04D5569AB4DE54E00285CA155A0E4687B5A156B16D8776F389673522

SESSION_1_RAW_SHA256=
    7DE947BDC7A802A6C2716B6CE63D3B9CDABC4164BFAFC180946B486C58B332BF

SESSION_2_RAW_SHA256=
    EA64AAB907D1AA23EBA051EE9F207288ED1E087D6F87826F620CFCF791CAD673

SESSION_1_MATRIX_SHA256=
    0169E9795B1FBED6EE40F1ACCE59B505660C09BBE4D5BD71455B2259F2943CAA

SESSION_2_MATRIX_SHA256=
    0169E9795B1FBED6EE40F1ACCE59B505660C09BBE4D5BD71455B2259F2943CAA

AGGREGATE_MATRIX_SHA256=
    E3B0C44298FC1C149AFBF4C8996FB92427AE41E4649B934CA495991B7852B855

JTAG_GATE_REPORT_SHA256=
    EE482964959DFC178A7211463B2DD97CDECA0A100794E050DC33624596AC3302
```

## Terminal operation accounting

```text
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
FPGA_SOURCE_CHANGES=0

READ_ONLY_JTAG_STABILITY_SESSIONS=2
JTAG_STABILITY_SAMPLES=0

FORMAL_BOOTSTRAP_PROGRAMS=0
ARM_A_PROGRAMS=0
ARM_B_PROGRAMS=0
FPGA_PROGRAM_INVOCATIONS=0
PROGRAM_RETRIES=0

FORMAL_BOOTSTRAP_WARM_REBOOTS=0
ARM_A_WARM_REBOOTS=0
ARM_B_WARM_REBOOTS=0
WARM_REBOOTS=0

FORMAL_BOOTSTRAP_DRIVER_LOADS=0
ARM_A_DRIVER_LOADS=0
ARM_B_DRIVER_LOADS=0
DRIVER_LOADS=0

HOST_SAFETY_DISCOVERY_RUN=NO
SSH_SESSIONS=0
RAW_MMIO_READS=0
ACCEPTED_READER_INVOCATIONS=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0

COLD_STARTS=0
PHYSICAL_ACTIONS_DURING_TASK=0
KERNEL_OR_GRUB_CHANGES=0
PCI_REMOVE_RESCAN_RESETS=0
FORMAL_REPOSITORY_MUTATIONS=0
PHASE3_RESUMED=NO
XDMA_DEVELOPMENT_CONTINUED=NO
OWNER_INTERACTIVE_APPROVAL_REQUESTS=0
```

## Post-program tool execution audit

The post-program tools were prepared and statically audited before the live
stability gate. They were not invoked. Their presence in `scripts/` is not an
execution record.

```text
Invoke-R5IndependentDoneReadOnly.ps1=PREPARED_NOT_EXECUTED
Invoke-R5WarmRebootOnce.ps1=PREPARED_NOT_EXECUTED
Wait-R5HostCycle.ps1=PREPARED_NOT_EXECUTED
Invoke-R5RemoteValidator.ps1=PREPARED_NOT_EXECUTED
Invoke-R5ExactPinnedLoaderOnce.ps1=PREPARED_NOT_EXECUTED
Invoke-R5TelemetryReadOnly.ps1=PREPARED_NOT_EXECUTED
r5_post_reboot_preloader_readonly.sh=PREPARED_NOT_EXECUTED
r5_post_loader_readonly.sh=PREPARED_NOT_EXECUTED
analyze_r4_telemetry.py=FROZEN_COPY_NOT_EXECUTED_ON_R5_SAMPLES
```

Filesystem accounting corroborates this status:

```text
04_HOST_SAFETY_DISCOVERY_FILE_COUNT=0
05_FORMAL_BOOTSTRAP_FILE_COUNT=0
06_ARM_A_R1E_FILE_COUNT=0
07_ARM_B_FORMAL_FILE_COUNT=0
08_ANALYSIS_FILE_COUNT=0
POST_PROGRAM_LIVE_OUTPUT_NAME_MATCH_COUNT=0
```

No loader evidence directory was requested or created by R5, no reboot was
submitted, and no host telemetry was read. Arm A and Arm B therefore remain
unrun.

## Scientific and final-state status

```text
FORMAL_BOOTSTRAP_PROGRAM=NOT_RUN_GATE_FAILED_BEFORE_PROGRAM
FORMAL_READY=NO
ARM_A_PROGRAM=NOT_RUN
ARM_A_SAMPLE=NOT_OBTAINED
ARM_B_PROGRAM=NOT_RUN
ARM_B_SAMPLE=NOT_OBTAINED
PAIRED_AB_RESULT=NOT_EVALUATED_NO_HARDWARE_CAMPAIGN
CURRENT_SRAM_IMAGE=UNPROVEN_NOT_MODIFIED_BY_R5
FINAL_ACTIVE_IMAGE=UNPROVEN_NOT_MODIFIED_BY_R5
FINAL_FORMAL_IDENTITY=NOT_READ
FINAL_PINNED_DRIVER_LOADED=NOT_EVALUATED_NO_SSH
FINAL_DONE=UNREADABLE
```

There is no scientific lifecycle, ordered-NACK, address-probe, or paired A/B
result to interpret from R5. The frozen R1e and formal bitstream artifacts were
not altered.

## Secret-scan handoff

The evidence publication step must run the local-only procedure in
`R5_SECRET_SCAN_GUIDANCE.md` after the final report and manifest staging are
complete. This audit did not open the credential file and did not run SSH.

