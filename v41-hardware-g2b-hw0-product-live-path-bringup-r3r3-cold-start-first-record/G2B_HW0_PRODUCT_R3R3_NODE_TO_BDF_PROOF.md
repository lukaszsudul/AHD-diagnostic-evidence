# XDMA node-to-BDF proof

Result: PASS. Dynamic index: 0.

/dev/xdma0_user and /dev/xdma0_c2h_0 were the sole required user/C2H nodes. Both /sys/dev/char/<major>:<minor>/device and /sys/class/xdma/<node>/device resolved through 0000:01:00.0. The automatic driver binding contained exactly that BDF. Full node rows are in G2B_HW0_PRODUCT_R3R3_NODE_MAP.csv and raw/node-map.json.
