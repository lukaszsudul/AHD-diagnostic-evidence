# AHD v41 G2B NVP VIDEO DIAG1-R1 main report

Engineering gate: **BLOCKED**

Overall result: **BLOCKED**

The host-owned result correction is functionally complete. The 128x32
asynchronously read and bulk-reset result table was removed, the eight-word
atomic current-session snapshot was implemented, and the complete simulation
gate passed 19/19. A fresh nonincremental build reduced post-opt LUT use from
22,306 to 19,102, a reduction of 3,204 LUT, and completed routing with positive
setup and hold slack.

The first routed hard gate stopped at the diagnostic CDC canonical manifest.
The task-local harness incorrectly required the prior PRODUCT routed design's
physical launch-register names. The diagnostic design produced the same rule
counts, clock directions, exceptions, and all 423 CDC-1 destinations, while
302 rows used different synthesis-selected launch-register representatives.
This strongly identifies harness authority drift, but does not itself provide
authority to disposition the new diagnostic physical-name manifest.

First blocker: `BLOCKED — NVP_DIAG1_R1_DIAGNOSTIC_CDC_MANIFEST_RECONCILIATION_AUTHORITY_REQUIRED`

Exact observed error: `CDC-1 critical CDC canonical manifest drift: expected=A7FE533FE9165E714D2CB171265D7653E99C8A1F88CD25942B99C036EB3D564D actual=BFD68E3E735133AFFD546985A382CA83F25A744F8B6E4B0B9A5000202968CF99`

No bitstream was generated. Hardware eligibility was not reached. No DUT,
JTAG, FPGA programming, reboot, driver load, NVP I2C transaction, MMIO, DMA,
AIO, route change, BGDCOL change, or capture occurred.

The next governed action is a harness-only continuation authorizing semantic
CDC reconciliation against routed DCP SHA-256
`45376E1B2BA92A5A4C19B4349FFE1B7A2F57C39A4B77AAF3AD421644376CE99F`
and explicitly authorizing that exact DCP to be reopened for the remaining
sign-off gates. No RTL, XDC, IP, ABI, PRODUCT MMIO, or transport change is
indicated.
