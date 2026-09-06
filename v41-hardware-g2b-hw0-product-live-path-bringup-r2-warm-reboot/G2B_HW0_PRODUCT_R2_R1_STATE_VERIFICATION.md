# G2B-HW0-PRODUCT-R2 R1 State Verification

Result: `PASS`

- R1 evidence directory:
  `v41-hardware-g2b-hw0-product-live-path-bringup-r1`.
- R1 final evidence commit: `eb3a75c09925574c6947d67cdefb8e2a723add9e`.
- R1 package manifest: `57/57 PASS`, zero mismatches.
- R1 publication and commit-pinned remote read-back: `PASS`.
- R1 final candidate: exact Recovery-4 PRODUCT image remained in volatile SRAM
  by unbroken operation accounting.
- R1 final `DONE`: `1`.
- R1 final AHD endpoint: `ABSENT`.
- R1 final XDMA state: module unloaded, driver sysfs absent, zero nodes.
- R1 Flash operations: `0`.
- R1 reboot and power-cycle counts: `0 / 0`.

The rev8 SSOT manifest passed with zero mismatches. It records META-8A as the
accepted current meta task, G2B-LUT1 `ACCEPTED / OFFLINE_QUALIFIED`, candidate
maturity `OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE`, G2B-HW0-PRODUCT
`AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION`, scope
`ONE_CHANNEL_FIXED_LIVE_AHD_PATH`, and persistent Flash programming not
authorized.

The exact source commit/tree, bitstream size/hash, and signed-off DCP hash were
rehash-verified before hardware work. Fresh pre-reboot JTAG found the same
target, `xc7a35t`, IDCODE `0362D093`, index 0, and five `DONE=1`
samples. There were zero known intervening SRAM programs, Flash operations, or
power cycles. This establishes operation continuity plus configured state; it
does not claim live JTAG read-back of the bitstream hash.
