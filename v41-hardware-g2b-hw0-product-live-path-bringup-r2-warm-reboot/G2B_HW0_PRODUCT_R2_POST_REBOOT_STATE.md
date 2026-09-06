# G2B-HW0-PRODUCT-R2 Post-Reboot State

Result: `PASS THROUGH THE XDMA INVENTORY POINT`

- Hostname/user/machine identity: exact authoritative DUT, `PASS`.
- Post-reboot boot ID: `52b0bf13-e9d1-4558-ae13-d08f4ecc8dac`.
- Exactly one authenticated boot transition: `PASS`.
- Post-reboot exclusivity and Linux relock: `PASS`.
- Candidate retention: `PASS` by operation continuity and configured state.
- FPGA: `xc7a35t`, IDCODE `0362D093`, index 0, five `DONE=1` samples.
- Exact AHD endpoint: `0000:01:00.0`.
- Endpoint identity: `10ee:7011`, subsystem `10ee:0007`, class `058000`.
- Upstream/root port: `0000:00:01.1`.
- Endpoint link: Gen2 x1 (`LnkCap` and `LnkSta` both `Speed 5GT/s, Width x1`).
- Endpoint driver: none.
- XDMA module: unloaded.
- XDMA driver sysfs: absent.
- XDMA nodes: zero.

The endpoint reappeared only after the single authorized warm reboot. No PCIe
rescan or reset was used. The final read-only capture preserved PCIe topology,
AER/kernel context, endpoint properties, module state, and node state before
the locks were released.
