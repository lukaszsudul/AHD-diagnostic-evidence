# G2B-HW0-PRODUCT-R2 Pre-Reboot State

Result: `PASS`

- DUT: `VCDE-DUT-HOST-01 / VCDE-DUT-1 / 10.132.1.111`.
- Authenticated user: `vcdeagent1`.
- Machine ID: `0e90f50d9465492b80258da5658446f8`.
- Kernel: `7.0.0-29-generic`.
- Boot ID: `37131b8d-0e38-4b4e-b77a-b3bda55b4e97`.
- AHD endpoint: `ABSENT`.
- XDMA module: `UNLOADED`.
- XDMA driver sysfs: absent.
- XDMA nodes: `0`.
- FPGA: `xc7a35t`, IDCODE `0362D093`, chain index 0.
- JTAG target: `localhost:3121/xilinx_tcf/Xilinx/80802026a98b01`.
- Five pre-reboot samples: `DONE=1`.
- R2 program operations before reboot: `0`.
- Controller and Linux locks: `HELD`.

The snapshot preserved PCIe topology, relevant root-port state, AER data,
kernel logs, users, device owners, uptime, and reboot inhibitors. The listed
inhibitors covered sleep or physical-key handling; no evidence showed an
unresolved shutdown/reboot inhibitor. The recovery plan limited reconnect
polling to exact IP `10.132.1.111`, denied network scanning and all second
reboots, and set the maximum reconnect window to 900 seconds.
