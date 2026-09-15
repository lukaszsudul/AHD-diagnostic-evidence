# Scope

In scope: endpoint reconnect, minimal DUT identity/safety survey, exact bundle deployment, locks, one SRAM programming, product-equivalent autoinit, one warm reboot, exact driver load, runtime identities, MMIO sanity, and SCAN1 pre-camera regression.

Conditionally in scope after `ACQ1_CAMERA_READY_GATE`: CH1-only Bank-5 full-byte baseline, idempotent rewrite, slices `0x50`, `0x40`, `0x60`, read-only format identification, and exact rollback.

The conditional scope was not reached. Source, RTL, XDC, IP, SSOT, PRODUCT source, Flash, power-cycle, mode programming, EQ, ACP, Bank-9, routing, BGDCOL, capture, DMA video acquisition, generic host I2C, and CH2-CH4 functional writes were untouched.
