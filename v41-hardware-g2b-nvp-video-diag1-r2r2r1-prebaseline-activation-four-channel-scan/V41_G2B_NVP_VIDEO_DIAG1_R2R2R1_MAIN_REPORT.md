# AHD v41 G2B-NVP-VIDEO-DIAG1-R2R2R1 main report

Engineering gate: **FAIL**

The inherited offline sign-off, exact candidate hash, one SRAM programming,
product-equivalent autoinit, one commanded warm reboot, endpoint/driver gate,
PRODUCT runtime identity, diagnostic identity, capabilities, and pre-baseline
transport quiescence passed.

The first executed failing gate was `NVP_DIAG1_R2R2R1_DIAG_CLEAR_MMIO_PATH_BECAME_UNRESPONSIVE`. The sole initial
`DIAG_CONTROL.CLEAR` write completed, but the next diagnostic STATUS and ERROR
reads returned `0xFFFFFFFF`. A bounded read-only MMIO probe then produced no
first read before its 30-second timeout. No PREPARE, START, BGDCOL change, VDO1
route change, AIO submission, capture, or image analysis occurred.

The task subsequently observed a new kernel-initialization interval and found
the previously loaded module absent without any task-issued `rmmod`. Together
with the timed-out MMIO operation, this is evidence of an unexpected DUT
restart after CLEAR. This conclusion uses the bounded task log and exact module
lifecycle only; no boot-ID comparison was performed.

Cleanup passed for the state that remained: no user-node or C2H holder, the
driver and XDMA nodes were absent, pending AIO remained zero, and both exact
task locks were released. PRODUCT baseline restoration was not executed because
the Double-PREPARE gate was never established and no diagnostic functional NVP
write was authorized or performed.

Overall result: **FAIL**

Evidence publication is evaluated separately by the immutable commit and
commit-pinned remote read-back containing this report.

Generated: 2026-09-10T19:11:14.785774+00:00
