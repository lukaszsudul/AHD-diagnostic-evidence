# Cleanup receipt

- stream was directly observed disabled before CLEAR (`CONTROL=0x00000000`)
- pre-CLEAR transport status `0x000000C4`; C2H holder none
- captures/AIO started: 0; final pending AIO: 0
- exact `/dev/xdma0_user` holder after failure: none
- exact `/dev/xdma0_c2h_0` holder after failure: none
- `xdma_ahd_pcie`: absent when cleanup ran
- XDMA nodes: absent
- normal `rmmod`: not issued because module was already absent
- exact Linux lock: released after ownership check
- exact controller lock: released last at `2026-09-10T19:05:02.5041604Z`
- power-cycle: NO
- final task-issued reboot: NO

The module disappearance and bounded kernel reinitialization interval occurred
after the MMIO hang without a task-issued unload or second reboot; this is part
of the engineering failure evidence.
