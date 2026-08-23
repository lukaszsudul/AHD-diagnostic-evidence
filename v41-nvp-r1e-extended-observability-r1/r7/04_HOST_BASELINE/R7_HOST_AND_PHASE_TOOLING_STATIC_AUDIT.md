# R7 host and post-program tooling static audit

```text
HOST_AND_PHASE_TOOLING_STATIC_AUDIT=PASS
MANIFEST_ROWS=22
MANIFEST_HASH_SIZE_MISMATCHES=0
POWERSHELL_FILES_PARSED=12
POWERSHELL_PARSE_ERRORS=0
FROZEN_JTAG_BUNDLE_AUDIT=PASS_85_OF_85_BY_JTAG_AGENT
LIVE_SSH_EXECUTED_BY_THIS_AUDIT=0
LIVE_JTAG_EXECUTED_BY_THIS_AUDIT=0
PROGRAMS_EXECUTED_BY_THIS_AUDIT=0
REBOOTS_EXECUTED_BY_THIS_AUDIT=0
LOADERS_EXECUTED_BY_THIS_AUDIT=0
MMIO_EXECUTED_BY_THIS_AUDIT=0
DMA_EXECUTED_BY_THIS_AUDIT=0
POST_PROGRAM_TOOLS=PREPARED_NOT_EXECUTED
```

## Static results

- Frozen `Invoke-ContextualPlink.ps1`, BAR parser, runtime-identity reader,
  R1e reader/decoder, and analysis script match their accepted hashes.
- The host baseline performs exactly two independent read-only SSH sessions
  across at least three seconds and gates stable boot ID, kernel 29, monotonic
  uptime, and next-boot kernel 29.
- The pre-bootstrap payload accepts zero or one exact endpoint and accepts
  absent driver/nodes; it rejects foreign/multiple endpoints, wrong XDMA,
  owners, DMA, and critical kernel/AER state.
- The four read-only shell payloads contain zero reboot, module, PCIe-reset,
  filesystem-mutation, MMIO-write, or DMA commands.
- The exact loader wrapper contains one loader invocation, phase-binds the
  three fresh R7 remote evidence directories, and pins loader/module hashes.
- The warm-reboot wrapper contains one reboot invocation. There is no retry
  loop. The host-cycle observer is local/read-only.
- Telemetry uses the exact frozen reader, `O_RDONLY`/`pread`, two snapshots,
  and a one-second delay.
- The independent-DONE wrapper pins the frozen selected-target Tcl and emits
  distinct immutable immediate and final receipts. The immediate receipt is
  bound into the frozen split wait gate.
- The configured-image receipt tool creates the Arm-A terminal-safe DONE1
  receipt immediately from program + independent DONE evidence, while
  formal-ready and valid-Arm-A receipts require their complete phase evidence
  plus an operation-ledger hash.
- The frozen mode-aware program Tcl/supervisor, independent-DONE Tcl, and wait
  tool hashes match the final bundle declared by the JTAG agent.

```text
HOST_TOOL_MANIFEST=04_HOST_BASELINE\R7_HOST_TOOL_SHA256.csv
HOST_TOOL_MANIFEST_SHA256=EBC9F58D20D00BE9BD2CD0F36E93705CCAB686D4F4132644FF902DA93B975E30
PHASE_RUNBOOK=04_HOST_BASELINE\R7_HOST_AND_PHASE_RUNBOOK.md
PHASE_RUNBOOK_SHA256=A2FBF153F92D71F7C57FBAD3307796220B19ED00AF0B4A6681B8C6E3A2C6FB98
PROGRAM_TCL_SHA256=55C3D1F36F815404A081F943B2C2383B3DD2A9E66CF3FBA0F44B5A11B95DA9C7
PROGRAM_SUPERVISOR_SHA256=42C6A969A4CA27375C139CB60B4A1E5C33A58E987EB4A5C84DE7312CB9F4208D
INDEPENDENT_DONE_TCL_SHA256=122C960412B7A8ADFD2926BE9A863A2786D4D022854AE8A0D56798461E0CD91B
INDEPENDENT_DONE_WRAPPER_SHA256=F6FC7B5C4BB61C2F9BF23B43A30D58B8A71AD610AF070822024F5E9EEDC5848A
SPLIT_WAIT_GATE_SHA256=B25B1EE5C8193D9CF1F75C88AD63BFA012343FCAE613D02BF6BAB2668300AEA2
CONFIGURED_RECEIPT_TOOL_SHA256=1896EF7E8F28713BFE8A1A59B2E510F3371E4E665AB6F40104D123449F2372E4
```
