# R5 POST_COLD_RESET_R2 scientific status

```text
POST_COLD_RESET_HOST_STABILITY_GATE=PASS_3_OF_3
POST_COLD_RESET_BOOT_ID_BASELINE=dd140158-f8dc-46eb-9a05-27bb532713aa
JTAG_TRANSPORT_STABILITY_GATE=FAIL_BLOCKED_JTAG_TRANSPORT_NOT_STABLE
READ_ONLY_JTAG_STABILITY_SESSIONS=2
JTAG_STABILITY_SAMPLES=0
FORMAL_BOOTSTRAP_PROGRAMS=0
ARM_A_PROGRAMS=0
ARM_B_PROGRAMS=0
R1E_ARM_A_SAMPLE=NOT_RUN
R1E_ARM_B_SAMPLE=NOT_RUN
PAIRED_AB_RESULT=NOT_EVALUATED_NO_HARDWARE_CAMPAIGN
CONTROL_FLOW_SHORTENING_EXPLAINED_BY_LOG=NOT_EVALUATED_NO_SAMPLE
STOCHASTIC_ADDRESS_OR_BUS_MARGIN=NOT_EVALUATED_NO_SAMPLE
AUTOINIT_OPERATION_OR_PHASE_CONTEXT=NOT_EVALUATED_NO_SAMPLE
POST_INIT_VERSUS_AUTOINIT_CONTEXT_DEPENDENCE=NOT_EVALUATED_NO_SAMPLE
ROOT_CAUSE_SOLELY_PROVEN=NO
ANALOG_MARGIN_DIRECTLY_MEASURED=NO
```

The three read-only host-baseline samples proved one stable post-cold-reset
Ubuntu boot and exact kernel `7.0.0-29-generic`. The later JTAG qualification
did not find the required HS2 target: each independent session enumerated one
target, but it was `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`, yielding
zero exact HS2 matches, zero accepted refresh samples, and no readable `DONE`.

The hard stop occurred before formal bootstrap, Arm A, or Arm B. Therefore no
lifecycle count, ordered-NACK log, address-probe result, NVP functional sample,
or formal-control sample exists for R5. The JTAG result is an infrastructure
blocker and is not an NVP scientific observation.

