# Driver and PCIe gate

Result: `PASS`

- module: `xdma_ahd_pcie`
- module SHA-256: `E8B48E342C80B019BB4884FD7AF16AB1049BC60266101E6E4A8B6514AEEB3D77`
- kernel/vermagic: `7.0.0-29-generic`
- load method: exact-path `insmod`, one attempt, no parameters
- endpoint: `0000:01:00.0`
- vendor/device: `10ee:7011`
- subsystem: `10ee:0007`
- link: `Gen2 x1`
- `/dev/xdma0_user`: present and mapped to exact BDF
- `/dev/xdma0_c2h_0`: present and mapped to exact BDF
- unintended bound endpoints: `0`
- AER/fatal delta: `0`

No `modprobe`, `new_id`, `driver_override`, or manual bind was used.
