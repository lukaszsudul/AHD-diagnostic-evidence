# Cleanup receipt

Result: `PASS`

- safe post-failure state: `PASS`
- scanner idle: `YES`
- executor idle: `YES`
- I2C bus idle: `YES`
- stream disabled: `YES`
- physical quiescence: `PASS`
- pending AIO: `0`
- functional NVP writes: `0`
- unauthorized functional writes: `0`
- rollback required: `NO`
- normal `rmmod` attempts: `1`
- `xdma_ahd_pcie` absent after cleanup: `YES`
- all `/dev/xdma*` nodes removed: `YES`
- DUT lock released: `YES`
- warm reboots: `1`
- power-cycles: `0`
- Flash programming: `NO`
- diagnostic image left in volatile SRAM: `YES`

The normal cleanup operation completed unload, node-removal checks, and DUT-lock removal, then its first receipt write failed because the contracted fresh DUT root had no `cleanup/` directory. The execution traceback proved that terminal point. A reporting-only recovery checked the unchanged boot ID, absent module, absent nodes, absent DUT lock, and prior safe-state hash, then wrote the receipt under `logs/`. It did not repeat `rmmod` or lock removal.
