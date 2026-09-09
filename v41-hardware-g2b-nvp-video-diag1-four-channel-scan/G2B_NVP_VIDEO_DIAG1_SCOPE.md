# Scope and execution boundary

The intended scope was a diagnostic-only four-channel NVP scan with fixed I2C operations, rotating non-black BGDCOL values, VDO1 routing, and 16 finite captures. PRODUCT ABI/MMIO/XDMA/BT.656 behavior remained frozen.

Execution stopped at the first failed mandatory build gate: post-opt LUT utilization. Placement, route, timing, CDC, DRC, diagnostic bitstream generation, hardware execution, and capture were not reached.
