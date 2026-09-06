# G2B-HW0-PRODUCT-R3R2 — PCIE_AER_KERNEL_LOG_REVIEW

Overall hardware-session health BLOCKED by unexpected DUT boot changes. Exact-alias driver-load kernel delta had expected unsigned/out-of-tree warnings and no observed driver Oops, Call Trace, BUG, IOMMU fault or AER fatal in that captured interval. AER sysfs counters were unavailable; no invented zero counts.
Original taint0 ->12288 after load. After normal unload N/A (unload not run). New boot taint0 must NOT be compared as an unload-cleared taint or unchanged original boot.
Original boot52b0bf13-e9d1-4558-ae13-d08f4ecc8dac journal ends20:40:00 CEST; intermediate3decbc63-3fc7-43fe-88b0-8901d225846b begins20:41:28; current9fec7547-fd31-4592-a9ce-89ea082d2484 begins20:42:00. T3 connection attempted18:41:02.988 UTC and timed out18:41:48.215 UTC.
Cause and initiator of reboot(s) unresolved. No task reboot/reset/power-cycle command exists. Do not attribute the boot change to driver, capture, operator or power supply without evidence. No capture START receipt was present after reconnection.
