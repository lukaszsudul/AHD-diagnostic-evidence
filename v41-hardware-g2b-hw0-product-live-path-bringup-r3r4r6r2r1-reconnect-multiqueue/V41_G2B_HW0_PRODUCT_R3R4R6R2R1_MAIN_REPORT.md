# AHD v41 G2B-HW0-PRODUCT-R3R4R6R2R1

Engineering gate: **BLOCKED**. Overall result: **BLOCKED**.

First blocker: `R3R4R6R2R1_DUT_RECONNECT_TIMEOUT`.

The fresh R3R4R6R2R1 connection helper made 10 bounded SSH attempts to the sole authorized address `10.132.1.111`. Every attempt ended locally with exit code 124, empty stdout/stderr, and no remotely executed command. The first attempt began at `2026-09-08T07:40:24.417933+00:00`. The six-minute reconnect deadline was `2026-09-08T07:46:24.417933+00:00`. The final attempt began before the deadline; its fixed local 15-second process timeout closed the final receipt at `2026-09-08T07:46:35.863319+00:00`, 11.445 seconds after the deadline. This local receipt-boundary overrun did not produce a connection or remote mutation.

Per the hard-stop contract, no stale-state release, DUT-local build, driver load, MMIO, DMA, characterization probe, finite capture, FPGA programming, reboot, Flash operation, or power-cycle followed. The old helper/module/node/lock state therefore remains unobserved and unresolved. No fresh execution locks were acquired.

The accepted R3R4R6R2 multi-request source was copied byte-exactly into the fresh run; its SHA-256 remains `8FE35664F1F7A4CA23ABA012DE7488CC428B32587BCF184458DD3C76A00BB301`. It was not compiled or executed. The speed-up host-tool gate is `0/7 NOT_REACHED`.

Evidence publication is assessed independently from the blocked engineering gate. This package contains only sanitized connection receipts, source, helper, hashes, and NOT_REACHED evidence. It contains no credentials, executable, driver, bitstream, MMIO/DMA data, records, frame, or camera image.
