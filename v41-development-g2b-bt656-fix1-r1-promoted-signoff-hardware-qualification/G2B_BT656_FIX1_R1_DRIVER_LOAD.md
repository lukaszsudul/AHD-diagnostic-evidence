# Driver and PCIe receipt

The exact existing `xdma_ahd_pcie.ko` was loaded once after reboot. `/dev/xdma0_user` and `/dev/xdma0_c2h_0` appeared. Minimal exact-image confirmation showed PCI vendor/device `10ee:7011`, subsystem `10ee:0007`, current link 5.0 GT/s x1 (Gen2 x1). No modprobe, depmod, new_id, driver_override, manual bind or module parameter was used.
