# AHD v41 G2B-HW0-PRODUCT-R3R2

Engineering gate: BLOCKED
Overall result: BLOCKED
First blocker: R3R2_DUT_BOOT_CHANGED_EXCLUSIVITY_LOST

T0 authority/exclusivity, T1 exact-driver auto-bind/node proof and T2 runtime/live-source readiness passed on boot52b0bf13-e9d1-4558-ae13-d08f4ecc8dac. One exact insmod succeeded. T3 launch timed out during loss of DUT continuity. Subsequent read-only inventory discovered two new boot IDs, no Linux lock, no driver or XDMA nodes, and no T3 start/write/capture artifacts. No retry, reset, reload, recovery or programming was performed.

No task reboot command was issued, but an actual reboot occurred: the requested literal 'Reboot: NO' cannot truthfully describe observed system state. 'NO' applies only to task-initiated reboot. Likewise absent driver/nodes is not a normal unload PASS, and final DONE1 does not establish exact candidate retention across changed boots.

T3 BLOCKED; T4/T5 NOT_REACHED. No first record, finite capture, frame or measured throughput. Reset/W1C/enable/MMIO writes0. Last verified MMIO was disabled T2 baseline; post-reboot stream/DMA state was not re-read without driver/node proof.

Fresh root: C:\FPGA\G2B_HW0_PRODUCT_R3R2_20260906T182010Z. Helper hard gate PASS; 29 helper invocations, all exact fresh helper, credential remnants0. Prior immutable boundary PASS with10814 rows/zero differences. PROJECT_STATE_REV8 unchanged. Source/RTL/XDC/SSOT and prior evidence untouched. Only new task scripts/logs/artifacts and new publication directory created.

Final read-only JTAG xc7a35t/0362D093/DONE1 five samples. Endpoint Gen2x1/unbound; module/nodes absent after reboot. Linux lock lost, controller lock released last. Normal cleanup qualification BLOCKED; exact retained candidate UNRESOLVED.

Evidence is sealed independently of engineering. Commit and commit-pinned remote byte/blob/SHA readback are completed after sealing; the final transaction receipt is stored outside this immutable commit under the fresh controller artifacts directory. No publication PASS is inferred merely from push success.

Recommended next step: resolve unexpected DUT boot changes and obtain fresh Owner authorization with a stable exclusive boot. No SSOT promotion justified. >=288MB/s NOT_PROVEN; four-input/two-channel NOT_QUALIFIED; synthetic/V4L2 NOT_TESTED.
