# Recovery 3 XDC scope audit

The only source change is the META-6-authorized Group-14 replacement in `xdc/common/g2b_cdc.xdc`.

- Source parent: `64feb60de5d07f400e6b92527bfe54838b3372ee`
- Source commit: `bdae16e06fb5b8564763941f530e4ce9e28896c7`
- Parent tree: `26399c01f7c15ef61988367e33375cec396880cf`
- Commit tree: `e18833d46f7672f851c3cb8239f2f29091378294`
- Active XDC SHA-256: `49CE028909F25303807E85E8835BD3379F1C6965EC302E08812105C280736C4A`

The retired `set_bus_skew 3.000` Group-14 relation was removed. Exactly three G14-A `set_max_delay -datapath_only 6.000` semantic-family relations were added: normal state transition, mismatch containment, and reset-overlap accounting. The added block is byte-sequence identical to the G14-A candidate authority.

Group 9, Groups 10-12, Group 13, Groups 15-17, clocks, false paths, unrelated max-delay constraints, ABI/MMIO, and R1i behavior are unchanged. No unintended XDC delta was found.

