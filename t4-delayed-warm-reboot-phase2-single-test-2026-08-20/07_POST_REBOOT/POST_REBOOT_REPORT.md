# Post-reboot host and JTAG result

The host returned with a new boot ID. PCIe enumeration itself was correct: one 10ee:7011 endpoint, subsystem 10ee:0007, class 058000, Gen1 x1, BAR0 128 KiB and BAR1 64 KiB. However, the required pinned XDMA runtime gate failed: the in-tree platform `xdma` module identity was visible, the endpoint was not bound to the expected driver, and `/dev/xdma0_user` and `/dev/xdma0_control` were absent. The task authorized only read-only validation, so no module load or driver rebind was performed.

The NVP baseline was not run because the mandatory post-reboot host gate failed. Final fresh read-only JTAG nevertheless proved xc7a35t / 0362D093 / DONE=1.
