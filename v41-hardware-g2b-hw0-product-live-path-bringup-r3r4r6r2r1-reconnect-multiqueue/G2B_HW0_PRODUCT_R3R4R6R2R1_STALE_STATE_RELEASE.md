# Stale-state release

Result: **BLOCKED / NOT_REACHED**.

SSH reconnect never succeeded. PID 25287, `xdma_ahd_pcie`, `/dev/xdma0_user`, `/dev/xdma0_c2h_0`, and exact stale Linux locks were not inspected in this run. No signal, `rmmod`, lock removal, or additional warm reboot was performed. The known stale controller/Linux locks were preserved fail-closed.
