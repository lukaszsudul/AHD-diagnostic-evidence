# R2 Hardware Lock Receipt

- task: `R2`
- owner: `Codex R2 execution context on NBLSUDUL`
- DUT identity: `VCDE-DUT-1 / xc7a35t / IDCODE 0362D093`
- requested lock: `FPGA_AHD_HW_LOCK`
- current holder before acquire: `UNPROVABLE`
- acquired timestamp: `NOT_ACQUIRED`
- lease/expiry: `NOT_IMPLEMENTED_OR_PROVABLE`
- `ACQUIRE=FAIL`
- `VERIFY_OWNERSHIP=FAIL`
- release: `NOT_APPLICABLE_NOT_ACQUIRED`

Read-only non-acquiring probes found no existing Windows mutex under the exact names `FPGA_AHD_HW_LOCK`, `Local\FPGA_AHD_HW_LOCK`, or `Global\FPGA_AHD_HW_LOCK`. Repository, workspace, and remote inventories found no canonical executable/state receipt, exact remote reference, file lock, service, `lslocks` entry, or distinct current owner process.

Absence of a discovered object is not proof of exclusive ownership. An ad-hoc new mutex would not prove that product and research tasks honor it. The mandatory gate therefore failed before programming.

First blocker: `FPGA_AHD_HW_LOCK_STATE_NOT_PROVABLE`.

Raw evidence: `raw/REMOTE_LOCK_INVENTORY.txt` and `raw/REMOTE_LOCK_REFERENCES.txt`.
