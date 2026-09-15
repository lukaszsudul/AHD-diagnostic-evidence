
# CONT1R1 root cause and terminal live gate

## Corrected CONT1 cause

`HOST_CONFIGURATION_PROJECTION_STALE_OR_WRONG_ADDRESS_FAMILY`

The old host projection requested Bank 1 registers `0x88..0x8B`, which are absent from
the exact frozen manifest. The corrected schema uses `(0x01,0x84..0x87)` for ADC clock
delay and `(0x01,0x8C..0x8F)` for pre-clock, with full `(bank, register)` keys. The
offline 16-test gate and exact preserved-snapshot replay passed.

## First failed CONT1R1 live gate

The corrected live single scan passed at generation 2 with `82/82`, `10/10`, `105/105`,
no retry, stable A8 bookends, entry-bank restore, and projection PASS. The first attempt
of the required 32-scan regression then published a complete generation-3 snapshot with
one successful retry: entry 62, `(Bank 7, 0xF4)`, status `0x07`. The frozen counter was
`RETRIED_ENTRY_COUNT=1` and `SCAN_FLAGS=0x006A0005`, hence `106` physical transactions.

The SCAN1 RTL permits a retry only for non-timeout WADDR, REGADDR, or RADDR NACK causes.
The successful retry status does not preserve which of those three NACK phases occurred.
This violates the literal `105/105` and `NACK=0` live-regression gate. No retry scan was
run. This is not the corrected host projection defect and is not a camera-format result.
