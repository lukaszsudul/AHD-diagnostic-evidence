# Driver and endpoint

- BDF `0000:01:00.0`
- vendor/device `10ee:7011`
- subsystem `10ee:0007`
- link `5.0 GT/s`, width 1 (Gen2 x1)
- exact qualified driver path used with one `insmod`
- `/dev/xdma0_user` created
- `/dev/xdma0_c2h_0` created
- result: PASS

No driver hash, module parameter, manual bind, or broad PCIe audit was used.
