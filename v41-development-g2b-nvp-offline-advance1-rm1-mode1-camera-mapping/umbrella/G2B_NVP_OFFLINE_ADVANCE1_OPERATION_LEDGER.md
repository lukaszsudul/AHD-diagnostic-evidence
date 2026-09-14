# G2B-NVP-OFFLINE-ADVANCE1 operation ledger

## Authorized mutations performed

- Created fresh offline task root and lock.
- Created isolated RM1 and MODE1 worktrees.
- Produced task-local MODE1 and camera/connector audit artifacts.
- Added and committed exactly eleven RM1 source/test/XDC paths on branch
  `diag/v41-g2b-nvp-video-diag2-rm1`.
- Pushed that branch and verified commit-pinned bytes from a fresh clone.
- Ran RM1 focused simulation `18/18 PASS`.
- Ran affected R3 regression `25/25 PASS`.
- Invoked exactly one full RM1 Vivado build; it failed before synthesis on the
  first Tcl gate. No retry was performed.
- Prepared the explicitly allowlisted public evidence package.

## Operations not performed

`DUT`, `PCIe`, `MMIO`, `JTAG`, NVP hardware I2C, DMA, capture, driver changes,
programming, reboot, power-cycle, PRODUCT/release mutation, SSOT/META mutation,
MODE1 source change, alternate route, build retry, RM1 HW1, and MODE1 HW1 were
not performed.

## Protected artifact post-check

- Existing COMPAT0 DCP SHA-256:
  `EE0982524E8C6E5B1395836BEF55130FC6914C9C9BFE47731C09D7621CD86BDC`
- Existing COMPAT0 bitstream SHA-256:
  `CFA58A46572094209997F6B1A3A5A033BF4E8C8A71EC261A5BBF1833B8BCF91B`
- Result: `BYTE_IDENTICAL`

