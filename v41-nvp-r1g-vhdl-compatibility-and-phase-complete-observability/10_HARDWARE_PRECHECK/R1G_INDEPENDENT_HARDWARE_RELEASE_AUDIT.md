# R1g independent offline hardware-release audit

```text
AUDIT_UTC=2026-08-24T17:27:11.6235671Z
AUDIT_CLASS=OFFLINE_READ_ONLY
HARDWARE_RELEASE=NOT_RELEASED_BUILD_FAILED
LIVE_SSH_JTAG_VIVADO_MMIO_PROGRAM_REBOOT_DRIVER_ACTIONS=0
ACTIVE_HARDWARE_BINDING=ABSENT
```

## Terminal release decision

The sole authorized clean build was consumed and terminated before a routed
checkpoint or bitstream was produced. The terminal failure receipt is:

```text
R1G_BUILD_TERMINAL_FAILURE_PATH=C:\FPGA\V41_NVP_R1G_VHDL_COMPATIBILITY\08_BUILD\VIVADO_2025_2_CLEAN_BUILD\R1G_BUILD_TERMINAL_FAILURE.txt
R1G_BUILD_TERMINAL_FAILURE_SHA256=446B6468DAE7EB456D0477A21DF465925CB963714C285E664F8A43A3188728A7
R1G_BUILD_TERMINAL_ERROR=ERROR: [Common 17-39] 'place_design' failed due to earlier errors.
R1G_BUILD_RESULT_PRESENT=NO
R1G_ROUTED_DCP_PRESENT=NO
R1G_BITSTREAM_PRESENT=NO
```

Because the prompt prohibits a second build and prohibits hardware after a
failed full-build gate, no active binding was created and no fresh hardware
precheck or campaign step is released.

## Independently rehashed accepted tools

All 14 inherited/task-local executable or read-only leaf bindings were
independently rehashed from their exact paths. Byte counts and SHA-256 values
matched `R1G_INHERITED_TOOL_BINDINGS.csv` in 14 of 14 cases:

| Binding | Bytes | SHA-256 |
|---|---:|---|
| ModeAwareObserverTcl | 11334 | `55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7` |
| ProgramObserverParser | 5102 | `6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66` |
| SelectedTargetSelector | 5676 | `3F315C44C17AF1E5293A314CAA3B0DA63BFAEC687D58E7DADE37BAAE394CD1DE` |
| IndependentDoneTcl | 3527 | `122C960412B7A8ADFD2926BE9A863A2786D4D022854AE8A0D56798461E0CD91B` |
| JtagReconfirmationTcl | 6368 | `6642F60F6D0FDF0208481C7A3CC25AC1127F981851BE7081CFFA3DF64860FF73` |
| ContextualPlink | 10952 | `5AB2E265C494DC4A93E087E52A32D102302070B1DF68B344C01640237A483EC9` |
| BarParser | 3380 | `5F7A6BDBF498720E1B40C54AB71A7E86BBD43AF1758AB207CF7EEBA65B15A922` |
| PreLoaderValidator | 7419 | `21748CA9D698B2657862F8EB423DD00D9151A5FB501C18385B7F4B8470B3163D` |
| PreBootstrapSafetyPayload | 13540 | `FC7868B7CD536A4F3C3D8365AA6950F8B76378687CEE6B8047DECDF2FD6FDB45` |
| HostBaselinePayload | 3717 | `0C49C3FB9192E40F53285844343BAA7AC6EE1801798C62627A6C45EAC718D730` |
| R1fReader | 46868 | `5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C` |
| R1fStatistics | 38404 | `C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD` |
| R1gRuntimeProvenance | 3247 | `8F8C0D31691BB5866BD86369DB28A9B9B12EDA498D2AFCB0C539D6E826F1A4F5` |
| Plink084 | 1043072 | `E5621FFE4879F0EC39ED40F688DB9399C2D43054D41EF14472FA335C4693B915` |

The complete task-local host/campaign tooling manifest was also independently
replayed: 39 rows checked, 0 missing files, 0 byte-count mismatches, and 0
SHA-256 mismatches.

The exact formal bit was independently rehashed:

```text
FORMAL_BIT_PATH=C:\FPGA\V41_NVP_R1E_MODE_AWARE_DONE0_PAIRED_AB_R7\01_ARTIFACT_IDENTITY\artifacts\ahd_capture_v41_phase2_p1.bit
FORMAL_BIT_BYTES=2192144
FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
```

## Frozen campaign contract

Static inspection reconfirmed:

```text
PAIR_SEQUENCE=A1 -> B1 -> A2 -> B2 -> A3 -> B3
ARM_A_REQUIRED_WAIT_SECONDS=33.536673744
BOOTSTRAP_AND_ARM_B_MINIMUM_WAIT_SECONDS=5.0
SELECTED_JTAG_CANONICAL_ID=Xilinx/80802026a98b01
HISTORICAL_FULL_JTAG_TARGET_PATH=localhost:3121/xilinx_tcf/Xilinx/80802026a98b01
FPGA_PART=xc7a35t
FPGA_IDCODE=0362D093
JTAG_FREQUENCY_CHANGE=FORBIDDEN
MODULE_PATH=/home/vcdeagent1/FPGA_AHD_HOST/dma_ip_drivers/XDMA/linux-kernel/xdma/xdma.ko
MODULE_SHA256=1AEF06244DF308FEE544A2662B73855C81BEB88BC929E7885D8D113E474B320A
LOADER_PATH=/home/vcdeagent1/FPGA_AHD_HOST/phase2_precheck_accepted/phase2_load_xdma_driver.sh
LOADER_SHA256=7279E316A2D647826B8D5EC6BEDF78A143B72D100B4008C7AC006C1B6653649F
LOADER_MODE=0644
CONDITIONAL_FORMAL_BOOTSTRAP_PROGRAMS_MAX=1
ARM_A_PROGRAMS_MAX=3
ARM_B_PROGRAMS_MAX=3
FPGA_PROGRAM_INVOCATIONS_MAX=7
WARM_REBOOTS_MAX=7
DRIVER_LOADS_MAX=7
PROGRAM_RETRIES=0
```

The programming wrapper writes an immutable per-phase program-attempt
reservation before its sole Vivado process start. The accepted Tcl contains
exactly one anchored `program_hw_devices` command. The wrappers bind each arm
to its exact predecessor receipt, enforce transition-mode pre-program DONE
`1,1,1,1,1`, use independent immediate/final DONE sessions, and expose no
program-retry path. Seven unique phase evidence directories and seven unique
remote driver-evidence directories enforce the optional-bootstrap-plus-six-arm
maximum.

## Exact post-build binding procedure (not executed)

Had the one full build passed, the only permitted binding procedure was:

1. Require an exact `R1G_BUILD_RESULT.txt` PASS receipt, exact 2,192,144-byte
   R1g bit, and exact source-to-bit provenance.
2. Copy `09_HOST_TOOLS/R1G_HARDWARE_BINDINGS.template.json` to the new,
   non-overwriting active path
   `09_HOST_TOOLS/R1G_HARDWARE_BINDINGS.json`.
3. Replace only the template's pending values:
   `status=FROZEN_FOR_HARDWARE`, the selected full JTAG path, R1g bit absolute
   path/byte count/SHA-256, and the R1g commit/tree at both document and bit
   levels.
4. Bind the exact source identities:
   `e112a5addb7ac62700a9a71af81bf368fad0bada` /
   `3a59ebec130103055d24a3a32ecda00dedde5534` and preserve the exact reader,
   formal-bit, filename, target, part, IDCODE, and wait fields unchanged.
5. Run only the two offline fixtures and require:
   `STATIC_AUDIT_GATE=PASS_READY_FOR_SEPARATE_LIVE_PRECHECK` and
   `POSTBUILD_BINDING_GATE=PASS_READY_FOR_FRESH_HARDWARE_PRECHECK`.
6. Seal a binding receipt containing the active-binding SHA-256 and both
   fixture-log SHA-256 values before any live precheck.

This procedure was not executed because no valid R1g bit identity exists.

## Zero-live-action proof

Read-only filesystem inspection found:

```text
ACTIVE_BINDING_FILE_COUNT=0
PROGRAM_ATTEMPT_RESERVATION_COUNT=0
WARM_REBOOT_EVIDENCE_COUNT=0
DRIVER_LOAD_EVIDENCE_COUNT=0
INDEPENDENT_DONE_RECEIPT_COUNT=0
FINAL_DONE_RECEIPT_COUNT=0
TELEMETRY_EVIDENCE_COUNT=0
FRESH_HOST_BASELINE_GATE_COUNT=0
FRESH_JTAG_GATE_COUNT=0
START_SAFETY_DISCOVERY_COUNT=0
FORMAL_START_READY_RECEIPT_COUNT=0
BOOTSTRAP_DATASET_FILE_COUNT=0
PAIR_1_DATASET_FILE_COUNT=0
PAIR_2_DATASET_FILE_COUNT=0
PAIR_3_DATASET_FILE_COUNT=0
```

The read-only ledger audit agrees: `FPGA_PROGRAMS=0`, `WARM_REBOOTS=0`,
`DRIVER_LOADS=0`, `PROGRAM_RETRIES=0`, `AXI_LITE_WRITES=0`,
`DMA_TRANSFERS=0`, and `PHYSICAL_ACTIONS=0`.

```text
INDEPENDENT_TOOL_HASH_GATE=PASS_14_OF_14
INDEPENDENT_TASK_TOOLING_MANIFEST_GATE=PASS_39_OF_39
FROZEN_CAMPAIGN_CONTRACT_GATE=PASS
POSTBUILD_BINDING_GATE=NOT_RUN_BUILD_FAILED
FRESH_HARDWARE_PRECHECK=NOT_RUN
HARDWARE_CAMPAIGN=NOT_RUN
HARDWARE_RELEASE_DECISION=NOT_RELEASED_BUILD_FAILED
BLOCKER=ONE_CLEAN_BUILD_CONSUMED_PLACE_DESIGN_FAILED_NO_R1G_BIT
```
