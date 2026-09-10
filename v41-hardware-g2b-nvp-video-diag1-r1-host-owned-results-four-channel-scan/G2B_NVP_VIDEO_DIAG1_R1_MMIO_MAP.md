# Diagnostic MMIO map

`G2B_NVP_VIDEO_DIAG_MMIO_V1` remains in 0x3C00..0x3FFF with magic 0x4E565034
and version 0x00010001. Current snapshot registers occupy 0x3D00..0x3D28 and
the remainder through 0x3EFF is reserved-zero. Capability bits declare current
snapshot and host-owned history, and do not declare on-chip session history.
PRODUCT MMIO 0x3800..0x3BFF and AHD_C2H_TRANSPORT_ABI_V1 are unchanged.
