# AHD v41 G2B-BT656-FIX1-R1 main report

## Result

- Engineering gate: **PASS**.
- Evidence publication gate: **pending commit and commit-pinned read-back**.
- Overall engineering classification: **PASS_BT656_FIX1_R1_HARDWARE_QUALIFIED_WITH_POST_TARGET_TAIL_FLUSH**.
- First blocker: **NONE**.

## Promoted sign-off reconciliation

The exact routed DCP `C:\FPGA\G2B_BT656_FIX1_20260909T060432Z\artifacts\full-build-20260909T064549Z\G2B_ROUTED.dcp` matched `45D04813DC3B9C354235F28959067EF8B8F021CCB180E7454A060D44B8FE4173` and was reused without rerouting. The stale 17-command assumption was replaced only in the task-local recovery harness. The governed partition is 11 active relative bus-skew groups plus 6 promoted replacement-method groups. All 11 active reports passed, all six retired relations were absent, all 17 promoted family checks passed, and Groups 1 through 17 passed their governed methods. No RTL, XDC, IP, ABI, XDMA configuration, VDO constraint, repository build harness or hardened commit changed.

Full timing restoration passed with route, clock and netlist signatures unchanged. The routed result is WNS +0.148 ns, TNS 0.000 ns, WHS +0.044 ns and THS 0.000 ns. CDC, DRC, methodology, clock, resource and PRODUCT-identity gates passed. One PRODUCT bitstream was then generated from the restored signed-off DCP.

## Hardware qualification

The exact candidate `8180372428577769878C80CBC46E944C050801C9F80781711D39338EE88B68DA` was programmed once to volatile SRAM and DONE was asserted. One graceful post-program reboot returned successfully without boot-ID comparison. Runtime identity matched `30b14d13b0b789b62b05ab513eb9578c7c43b11a` with PRODUCT BUILD_FLAGS `0x00000102`; PCIe identity was `10ee:7011`, subsystem `10ee:0007`, Gen2 x1; NVP initialization, fixed input 0 and live-source readiness passed.

The inherited primary-only rolling receive path submitted 1024 initial 4096-byte IOCBs and completed 2500/2500 requests exactly, producing 10,240,000 bytes with no short, failed, duplicate, missing or pending request. Maximum outstanding was 1024, descriptor violations and starvation were zero. The parent issued normal disable in **76.242 microseconds**, passing both the 500-microsecond hard gate and the 100-microsecond engineering target.

All 2500 fixed-boundary records passed structural integrity. Global sequence was exactly 0..2499; attempt gaps, overflow flags, malformed-preceding flags, source malformed delta and source dropped delta were zero. Two frame boundaries showed the governed capture-sequence delta 22. Line 0 was present with SOF and flags `0x00000021`; line 1 followed with flags `0x00000020`. A complete real 1920x1080 UYVY frame was reconstructed from primary records 761..1840 with no missing, duplicate or synthetic line.

Three committed post-target records remained in the transport ring after the already complete primary window. They caused no streamed bytes, drop or overflow. The one authorized post-target reset advanced epoch 2 to 3, accounted the three records as abandoned, and restored physical quiescence. This is the sole reason for the `_WITH_POST_TARGET_TAIL_FLUSH` variant and does not alter the primary qualification.

The native helper exited normally with pending AIO 0 and `io_cancel` calls 0. Normal driver unload passed, XDMA nodes disappeared, both task locks were released, the bounded kernel interval contained no PCIe/AER/IOMMU/DMA/kernel fault, and final taint remained 12288.

## Nonclaims and publication boundary

Continuous 60-second performance was not run. Hardware throughput at or above 288 MB/s is not proven. Two-channel, four-input, V4L2, synthetic-generator, soak and release qualification remain out of scope. Raw records, raw UYVY, camera PNG, bitstream, DCPs, driver binary, native binary and credentials are not published.
