# R6 scientific status

## Outcome

R6 hard-stopped before the mandatory formal-bootstrap program. The fresh
offline, host, target-selector, JTAG-transport, and pre-bootstrap host-safety
gates all passed. In particular, two independent read-only Hardware Manager
sessions produced ten accepted samples from the exact selected target, with
the expected part and IDCODE and a stable readable `DONE=0`.

The frozen task-local programming observer requires pre-program `DONE=1` and
would reject the qualified `DONE=0` state before invoking
`program_hw_devices`. The R6 authorization permits adapting that observer only
in its target-selection layer, so changing or bypassing the pre-program gate
was outside scope. The terminal classification is therefore:

```text
BLOCKED_R6_STABLE_DONE_0_VS_FROZEN_PREPROGRAM_DONE_1_CONTRACT
```

No FPGA program invocation was attempted or consumed.

## Gates completed

```text
R5_EVIDENCE_IDENTITY_GATE=PASS
ARTIFACT_IDENTITY_GATE=PASS
HOST_TOOL_HASH_GATE=PASS
HOST_TOOL_FIXTURES=PASS_ALL
TARGET_SELECTOR_FIXTURES=PASS_ALL_8_OF_8
R6_HOST_BASELINE=PASS_3_OF_3
JTAG_TRANSPORT_STABILITY_GATE=PASS_10_OF_10
JTAG_PRECHECK_DONE_VALUE=0
PRE_BOOTSTRAP_HOST_SAFETY_GATE=PASS
```

The pre-bootstrap safety discovery found kernel `7.0.0-29-generic`, proved
the next reboot would retain kernel 29, accepted the absence of an FPGA PCIe
endpoint and XDMA driver, found zero node owners and zero task DMA, and found
no fatal kernel/AER condition.

## Scientific result

Arm A and Arm B were not run. Consequently R6 obtained no lifecycle count,
ordered-NACK sample, address-probe sample, NVP functional result, or paired
A/B result. No scientific classification can be made from R6:

```text
PAIRED_AB_RESULT=NOT_EVALUATED_NO_HARDWARE_CAMPAIGN
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=NOT_EVALUATED_NO_SAMPLE
STOCHASTIC_ADDRESS_OR_BUS_MARGIN=NOT_EVALUATED_NO_SAMPLE
AUTOINIT_OPERATION_OR_PHASE_CONTEXT=NOT_EVALUATED_NO_SAMPLE
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=NOT_EVALUATED_NO_SAMPLE
```

The SRAM image and formal runtime identity remain unproven. The last fresh
read-only JTAG observation was stable `DONE=0`; it is not evidence that exact
formal Phase 2 is active.

## Terminal accounting

```text
FPGA_PROGRAM_INVOCATIONS=0
FORMAL_BOOTSTRAP_PROGRAMS=0
ARM_A_PROGRAMS=0
ARM_B_PROGRAMS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS_DURING_TASK=0
```
