# G2B HW0 PRODUCT DUT Authority and Lock Receipt

Result: `BLOCKED`

Owner hardware authorization was present, but the task stopped before lock
acquisition because an additional MMIO authorization is mandatory.

Read-only coordination observations:

- Accepted historical receipts identify one authoritative Linux DUT and one
  fail-closed JTAG selector.
- A controller SSH alias was found to be stale and tied to an archived host;
  its timeout was not used as DUT availability evidence.
- No local Vivado, hardware-server, JTAG, or hardware-test process was active.
- Only the present HW0 task was active in the observable task list.
- A historical shared hardware lock record was released, not held.
- No reusable governed Linux lock protocol was found.

Not established before the hard stop:

- authenticated fresh Linux DUT session;
- current remote process and device-owner inventory;
- current JTAG chain;
- current AHD PCIe endpoint mapping;
- fresh physical/JTAG/PCIe correlation; or
- task-local Windows and Linux lock pair.

A lock file alone would not have proved physical exclusivity. Therefore
`DUT_EXCLUSIVITY = BLOCKED`, and no hardware mutation was attempted.
