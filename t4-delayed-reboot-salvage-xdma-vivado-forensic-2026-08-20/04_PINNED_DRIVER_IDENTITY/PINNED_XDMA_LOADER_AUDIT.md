# Accepted loader audit

The byte-identical accepted loader verifies its module hash, requires exactly one `10ee:7011` endpoint, and refuses to run if any `xdma` module is loaded. It then performs one `insmod`, waits for udev, and verifies the user node. It contains no reboot, PCI remove/rescan/reset, FLR, bus reset, `setpci`, `driver_override`, FPGA operation, MMIO write, DMA, or build.

The preserved copy has mode `0644`. Consequently, the authorized sudo invocation could not execute it directly; sudo returned permission denied before the script or `insmod` ran.

    PINNED_XDMA_LOADER_AUDIT=PASS_CONTENT
    LOADER_EXECUTABILITY_GATE=FAIL_MODE_0644

