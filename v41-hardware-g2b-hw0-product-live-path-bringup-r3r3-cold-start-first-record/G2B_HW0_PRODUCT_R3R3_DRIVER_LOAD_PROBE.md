# Driver load and automatic probe

T1 result: PASS. One insmod returned 0. Automatic exact-alias probing bound only 0000:01:00.0; unintended endpoints bound: 0. Platform xdma remained absent. Dynamic index 0 created /dev/xdma0_user and /dev/xdma0_c2h_0 plus the sealed driver's ancillary nodes. Two independent sysfs ancestry paths correlated required nodes to the exact BDF.

Kernel taint changed from 0 to 12288, exactly the expected out-of-tree and unsigned bits. No new AER count or kernel/driver fatal signature appeared. No manual bind, new_id, driver_override, modprobe, depmod, installation, or H2C transfer occurred.
