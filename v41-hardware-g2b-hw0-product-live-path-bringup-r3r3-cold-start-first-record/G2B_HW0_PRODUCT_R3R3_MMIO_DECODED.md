# MMIO decode

T2 result: PASS.

- Legacy block/protocol/schema: 0xA40A0C07 / 0x0000400B / 0x00031002
- Runtime embedded GIT_SHA: 224d194e5f82c85bcb29297561c5d5e76d28063b
- Vivado word/build: 0x07E90002 / 6299465
- BUILD_FLAGS: 0x00000103 (PRODUCT)
- XDMA identity: 0x58444D41
- NVP: initialized/ready/locked, NACK 0, INIT_ERROR 0, input 0 live
- G2B magic/ABI/capabilities: 0x43324831 / 0x00010000 / 0x000B001F
- Pre-session CONTROL/STATUS/epoch/ERROR_STATUS: 0x00000000 / 0x000000C4 / 1 / 0x00000000

T3 pre-reset state matched T2. One reset advanced epoch 1 to 2. Post-reset ERROR_STATUS was 0. The only coherent capture snapshot was the authorized pre-capture baseline. After the bounded-drain failure, read-only rollback assessment found CONTROL 0, STATUS 0x000004F4 with quiescent mask 0x00000004, ERROR_STATUS 0x00000007, and LAST_ERROR_CAUSE 0x00000002. Bits 2:0 were preserved and never W1C-cleared. No final coherent snapshot was requested after the first blocker.

Write counts: reset 1, snapshot 1, enable 1, normal disable 1, safety disable 0, fatal W1C 0, nonfatal W1C 0, statistics clear 0, unauthorized 0.
