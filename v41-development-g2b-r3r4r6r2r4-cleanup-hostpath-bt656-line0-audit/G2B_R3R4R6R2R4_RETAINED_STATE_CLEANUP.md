
# Retained-state cleanup

Result: `PASS`

## Targeted starting checks

- helper PID 6055: present and command identity matched the exact retained
  R3R4R6R2R3 helper/run root;
- `/dev/xdma0_user` and `/dev/xdma0_c2h_0`: present;
- preserved primary: regular, 10240000 bytes, read-only open PASS.

## Cleanup-only transport reset

- authorized write count: 1
- write: `0x380C = 0x00000004`
- epoch: `3 -> 4`
- before CONTROL / STATUS: `0x00000000 / 0x000004FA`
- after CONTROL / STATUS: `0x00000000 / 0x00000074`
- ERROR_STATUS remained `0x00000007`; no W1C was performed
- LAST_ERROR_CAUSE remained `0x00000001`
- five accepted quiescent samples: PASS
- first-to-last span: `400.413 ms`
- records-abandoned delta: `0` (expected from the earlier retained snapshot: 4)

The abandoned-count difference is recorded as an operational-state deviation.
It did not block cleanup because the one authorized reset completed, the ring
became empty, and physical quiescence passed. No broad rediscovery was launched.

## Process/module/lock closure

- SIGTERM sent to PID 6055: exactly 1
- SIGKILL: 0
- helper exit: YES, within approximately 0.1 s
- C2H holder removed: YES
- module reference count before unload: 0
- normal `rmmod xdma_ahd_pcie`: PASS
- forced unload: NO
- expected XDMA nodes absent: YES
- exact retained Linux lock removed: YES
- exact retained controller lock removed: YES
- warm reboot: 0

Final targeted state: primary preserved, helper absent, module absent, XDMA
nodes absent, retained locks absent.
