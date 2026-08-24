# R1g offline campaign-tooling static audit

## Classification

```text
STATIC_AUDIT_GATE=PASS_OFFLINE_BINDING_PENDING
HARDWARE_BINDING_STATUS=PENDING_R1G_COMMIT_AND_BUILD
FRESH_HARDWARE_PRECHECK_EXECUTED=NO
LIVE_SSH_JTAG_VIVADO_MMIO_PROGRAM_REBOOT_DRIVER_ACTIONS=0
```

The audit parsed all fourteen derived R1g campaign/precheck PowerShell files
with zero syntax errors and rehashed every inherited R7/R6 leaf. It did not
invoke any wrapper against the DUT.

Verified contracts:

- exact target `Xilinx/80802026a98b01`, part `xc7a35t`, IDCODE `0362D093`;
- one accepted `program_hw_devices`, vendor startup HIGH, same-session BIT5
  DONE, independent DONE, no BIT4 query, no JTAG-frequency change;
- optional bootstrap is mutually exclusive with a fresh exact-formal receipt;
- immutable pre-launch program reservation and no retry/restart path;
- frozen order `A1 -> B1 -> A2 -> B2 -> A3 -> B3`;
- programs/reboots/driver loads each capped at seven, with one maximum per
  phase and zero retry;
- Arm-A waits exactly `33.536673744` seconds; bootstrap/B waits at least five;
- seven unique local evidence leaves and seven unique remote loader leaves;
- exact predecessor receipt chain, including terminal-safe A-to-immediate-B
  restoration only;
- two complete coherent snapshots for every arm;
- exact inherited R1f reader ABI for R1g and exact formal full-range zero;
- R1g runtime Git SHA and build flags checked before full Arm-A telemetry;
- all remote directory-only payload adaptations have frozen SHA-256 values;
- no active binding can pass without the exact R1g commit/tree, bit filename,
  bit size/hash, reader hash, target path, and frozen wait.

The binding template is intentionally not live. A separate post-build fixture
must pass before any fresh SSH/JTAG precheck.
