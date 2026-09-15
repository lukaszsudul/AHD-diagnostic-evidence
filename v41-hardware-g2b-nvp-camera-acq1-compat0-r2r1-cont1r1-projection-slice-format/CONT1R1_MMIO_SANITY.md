
# CONT1R1 MMIO sanity

- SCAN1: `16/16 PASS`
- ACQ: `16/16 PASS`
- Post-write `0xFFFFFFFF` reads: `0`
- MMIO timeouts: `0`
- Unexpected reboot: `NO`
- DPC/AER: `0`
- Functional NVP writes: `0`

The exact controller can start a SCAN1 physical scan only after both 16-cycle loops and
the post-sanity safe-idle gate return successfully. Generation 2 was subsequently
published, proving the ordered sanity gates completed before the later regression stop.
