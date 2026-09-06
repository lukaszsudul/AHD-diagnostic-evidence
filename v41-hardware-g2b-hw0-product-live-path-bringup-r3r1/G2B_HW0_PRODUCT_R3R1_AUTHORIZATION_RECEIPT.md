# G2B-HW0-PRODUCT-R3R1 authorization receipt

Owner R3R1 authorization: `GRANTED`.

Authorized setup, read-only checks, exact one-load/one-unload driver path,
bounded C2H tests, and the three enumerated MMIO writes were read literally.
All explicit no-touch boundaries were retained.

The granted MMIO writes are only `0x380C=1`, `0x380C=0`, and `0x3844=1`.
Transport reset, statistics/error clear, every other MMIO write, FPGA SRAM or
Flash programming, reboot, and power-cycle remain forbidden.

The authorization cannot simultaneously satisfy the frozen mandatory Linux
session-start reset at `0x380C=4`; therefore hardware execution is blocked
before connection rather than broadened implicitly.

`OWNER_R3R1_AUTHORIZATION = GRANTED`

`AUTHORIZED_EXECUTION_FEASIBILITY = BLOCKED_BY_FROZEN_CONTRACT_CONFLICT`
