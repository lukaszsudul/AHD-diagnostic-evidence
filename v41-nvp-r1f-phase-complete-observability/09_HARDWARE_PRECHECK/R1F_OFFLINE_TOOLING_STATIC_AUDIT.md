# R1f offline hardware-tooling static audit

Audit date: 2026-08-24

```text
STATIC_AUDIT_GATE=PASS_OFFLINE_TOOLING_BINDING_PENDING
HARDWARE_BINDING_STATUS=PENDING_R1F_BUILD
LIVE_SSH_JTAG_PROGRAM_REBOOT_MMIO_ACTIONS=0
```

All 15 PowerShell files under `08_HOST_TOOLS` and `09_HARDWARE_PRECHECK`
parsed with zero syntax errors. No script was invoked against the DUT or
hardware server.

Passed static gates:

```text
ACCEPTED_R7_TOOL_HASHES=PASS
PROGRAM_HW_DEVICES_EXACT_COUNT=1
VENDOR_STARTUP_HIGH_PARSER_FROZEN=PASS
SAME_SESSION_BIT5_DONE_GATE=PASS
BIT4_EOS_QUERY_ABSENT=PASS
JTAG_FREQUENCY_CHANGE_ABSENT=PASS
SELECTED_TARGET_EXACT=Xilinx/80802026a98b01
START_JTAG_RECONFIRMATION_READ_ONLY=PASS
START_JTAG_RECONFIRMATION_SAMPLE_COUNT=5
WRAPPER_HAS_NO_DIRECT_PROGRAM_COMMAND=PASS
IMMUTABLE_ATTEMPT_RESERVATION=PASS
ONE_PROGRAM_PROCESS_START=PASS
CONDITIONAL_BOOTSTRAP_GATE=PASS
FROZEN_PAIR_SEQUENCE=A1_B1_A2_B2_A3_B3
UNIQUE_LOCAL_EVIDENCE_DIRECTORIES=7_OF_7
UNIQUE_REMOTE_DRIVER_DIRECTORIES=7_OF_7
PRELOADER_DIRECTORY_ADAPTER_MATRIX=PASS_8_OF_8
PREBOOTSTRAP_ADAPTED_PAYLOAD_SHA=98B776EDF8FEDD8638F71FCAF908D797EF3218938CF79B83A1DFBD6BF0B3EE05
R7_HARDCODED_WRAPPER_COLLISION_AVOIDED=PASS
TEMPLATE_FAILS_CLOSED=PASS
R1F_READER_HASH_BOUND=PASS
```

Exact observer properties:

```text
program_hw_devices anchored command count=1
vendor [Labtools 27-3164] HIGH parser occurrence=1
post-program BIT5 property read present
post-program BIT4 property read count=0
JTAG frequency set_property count=0
```

The active hardware binding does not exist yet because the authorized one
clean R1f build has not produced the final bit size/SHA/source/tree or the
simulation-derived Arm-A wait. This is an expected offline state, not a live
precheck pass. Hardware entry remains blocked until the active binding passes:

```text
STATIC_AUDIT_GATE=PASS_READY_FOR_SEPARATE_LIVE_PRECHECK
```

The R1f reader is already frozen:

```text
PATH=C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\scripts\v41\read_nvp_r1f.py
BYTES=46868
SHA256=5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C
OFFLINE_FIXTURES=PASS_16_OF_16
```

No build, source commit, FPGA source edit, SSH, live JTAG, FPGA program, warm
reboot, driver load, MMIO, AXI-Lite write or DMA operation was performed by
this tooling-preparation subtask.
