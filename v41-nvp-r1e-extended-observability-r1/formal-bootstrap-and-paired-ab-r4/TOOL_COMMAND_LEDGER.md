# R4 Tool and Command Ledger

All commands are recorded with their role and mutation class. Secret values are never recorded.

| UTC | Role | Mutation class | Result |
|---|---|---|---|
| 2026-08-23T12:58:15.7747847Z | Create required task directories | Task-local filesystem only | PASS |
| 2026-08-23T12:58:15.7747847Z | Extract exact R4 prompt from the current Codex session record | Task-local evidence file only | PASS |
# R4 Tool Command Ledger

All timestamps are UTC. Secret-bearing transport used the accepted contextual
Plink helper with `-pwfile -batch -hostkey -noagent -noshare`; no password is
recorded here or in task evidence.

| UTC | Class | Operation | Result | State change |
|---|---|---|---|---|
| 2026-08-23T12:58Z | local read/write | Create isolated R4 evidence root, ledgers, and save owner prompt | PASS | task-local files only |
| 2026-08-23T12:59Z..13:05Z | local read-only | Rehash R3 commit/package/237-file manifest, R1e bit/source/DCP, and formal bit | PASS | none |
| 2026-08-23T13:05Z..13:08Z | fixture | Exact observer, R1e reader, identity, lifecycle/log/probe/Wilson, and PCI BAR fixtures | PASS_ALL | none |
| 2026-08-23T13:08:55Z | JTAG read-only | Supported Vivado launcher with exact `read_jtag_identity_done_strong.tcl` | PASS; one target, DONE=1 | none; programs=0 |
| 2026-08-23T13:12Z..13:18Z | host read-only | Kernel/GRUB/PCIe/BAR/driver/node/health/MMIO discovery | PASS after two preserved task-harness corrections | none |
| 2026-08-23T13:18:58Z | MMIO read-only | Raw O_RDONLY preads plus exact accepted AXI-Lite reader | both returned all ones | none |
| 2026-08-23T13:20Z | local read-only | Rehash exact formal bit and accepted programming observer/parser | PASS | none |
| 2026-08-23T13:21Z | host read-only | Immediate pre-bootstrap endpoint/node-owner/DMA safety check | PASS | none |
| 2026-08-23T13:24:58Z | JTAG program | Exact formal Phase-2 bit through accepted one-shot observer | FAIL: vendor startup LOW | one FPGA program invocation consumed |

## Program accounting

PROGRAM_TCL=program_once_startup_high_done.tcl
PROGRAM_TCL_SHA256=7E1EE248BF3D818561DDA5990411EAD3757205F39DCEBA8888079061F4A1F653
PROGRAM_OBSERVER_PARSER_SHA256=6F3CCFD6DF0DE449196970DE2BC3F570F68E562DF29F18EB8E8800B04F1EAB66
R4_IDENTITY_QPC_WRAPPER_SHA256=2E8FC0730A37352D1D30A1E7DDED943C5BB98E72F58E10428481579882E16E05
PROGRAM_INVOCATION_CONSUMED_MARKERS=1
PROGRAM_RETRIES=0
WARM_REBOOTS=0
DRIVER_LOADS=0

The terminal programming error prevented the QPC wait, reboot, driver load,
formal-ready proof, Arm A, and Arm B. No later hardware command was issued.
