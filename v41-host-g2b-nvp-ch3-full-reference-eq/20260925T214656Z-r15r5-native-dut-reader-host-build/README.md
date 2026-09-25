# R15R5 — native DUT host build

Result: `PASS_NATIVE_DUT_READER_BUILT_HOST_PACKAGE_PREPARED_UNTESTED`.

An R15 continuous C2H reader was compiled and linked natively on the DUT as an ordinary user. The final ELF is 63,080 bytes, SHA-256 `2621B77C9DB756908A9C993A86F70C72F4831DB85EB48EA703B31D1E083040E1`. The complete private host package was copied and byte-verified on the controller. The ELF is x86-64 PIE and requires `libc.so.6`; metadata inspection found compatibility with the DUT environment.

The host source branch is `r15r5/native-dut-reader-host-build` at commit `c4bc671620f2cc2ae57fcbf9d11c31ba2d56aac4`. Changes are confined to the C reader and Python session runner for AIO closeout, reader event handling, and epoch-aware selection. The expected frozen R15R4R4 bitstream remains SHA-256 `3962886A7813B16D4A3B5C0D21F81A5B930696FF8E6DCD319A3331FA7FD2D5E2` and was not programmed.

Nineteen Python files passed syntax compilation without executing project modules; nine JSON resources parsed. No system packages were installed. Reader and runner executions, XDMA opens, MMIO, I2C, EQ, DMA, driver operations, capture, and hardware tests were zero. The current FPGA runtime was not measured. Source review and successful linking do not qualify full EQ, ten frames, or live camera output. The retained R15R4R4 local CDC limitation remains.

A later hardware attempt requires separate Owner authorization and fresh exact-image admission. Private source, ABI, binary, logs, firmware, and environment details are excluded from this publication.
