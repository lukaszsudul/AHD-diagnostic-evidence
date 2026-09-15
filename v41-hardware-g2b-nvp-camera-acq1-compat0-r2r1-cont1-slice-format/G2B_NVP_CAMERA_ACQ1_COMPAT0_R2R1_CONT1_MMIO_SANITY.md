# MMIO sanity

- SCAN1 write/read sanity: `16/16 PASS`
- ACQ write/read sanity: `16/16 PASS`
- post-write `0xFFFFFFFF` fault reads: `0`
- MMIO timeouts: `0`
- functional NVP writes: `0`
- unexpected reboot: `NO`
- DPC/AER delta: `0`

Completion is established by the frozen controller's strict sequential flow: both 16-cycle sanity loops and their PASS assertions precede the persisted SCAN1 snapshot at which the later host-projection gate failed.
