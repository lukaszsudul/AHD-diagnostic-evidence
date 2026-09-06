# G2B-HW0-PRODUCT-R2 Post-Reboot JTAG-to-PCIe Correlation

Result: `PASS`

The correlation binds:

`localhost:3121/xilinx_tcf/Xilinx/80802026a98b01` / `xc7a35t` / IDCODE `0362D093` / index 0

to the physical AHD board and current endpoint:

`0000:01:00.0` / `10ee:7011` / subsystem `10ee:0007` / class `058000`

behind upstream/root port `0000:00:01.1`.

The decision combines the hash-verified R1 accepted physical binding, the same
authoritative DUT and uninterrupted controller lock, the same exact JTAG
target/part/IDCODE/index, reappearance of the historical endpoint identity and
parent, an exact `10ee:7011` endpoint count of one, and explicit
discrimination from the other Xilinx device, which has a different ID, class,
and root path. Vendor/device ID alone was not treated as sufficient.

Endpoint `LnkCap` is `Speed 5GT/s, Width x1` and `LnkSta` is `Speed 5GT/s, Width x1`. The measured PCIe
Gen2 x1 hardware gate is `PASS`.
