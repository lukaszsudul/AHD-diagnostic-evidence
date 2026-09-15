
# AHD v41 G2B NVP camera ACQ1 COMPAT0 R2R1 CONT1R1

## Result

- Engineering gate: `FAIL`
- Overall result: `FAIL`
- First failed gate: `SCAN1_LIVE_32_SCAN_REPEAT_01_RETRY_NACK`
- Runtime error: `RuntimeError:RUNTIME_SCAN_FLAGS_FAILED:0x006a0005`
- Physical camera gate: `NOT_REACHED`
- Functional NVP writes: `0`
- Unauthorized functional writes: `0`
- Cleanup: `PASS`

## Host-only reconciliation

The corrected projection uses complete `(bank, register)` keys. The old Bank 1
`0x88..0x8B` requirement was reproduced and rejected. The accepted ADC-delay family is
Bank 1 `0x84..0x87`; the accepted pre-clock family is Bank 1 `0x8C..0x8F`. Projection
preflight passed, the host regression passed `16/16`, and the exact preserved CONT1 raw
snapshot `5930C78AA52AEC08F09E837D2C1E20EBBB9527A36E49647FACF273F7206D0AD9` replayed with `82/82`, `10/10`, `105/105`, restore PASS,
projection PASS, and zero missing keys.

The corrected closed bundle passed locally and on the DUT. The exact live volatile FPGA
runtime was reused after exact SCAN1/ACQ identity checks, so CONT1R1 performed zero FPGA
programming attempts and zero warm reboots. Driver/PCIe, identities, and both 16-cycle
MMIO sanity gates passed.

## Live qualification and first failure

The corrected live single scan passed at generation 2: `82/82` entries, `10/10` groups,
`105/105` transactions, no retry, `A8_PRE=A8_POST=0x0F`, entry/exit bank `0x00`, restore
PASS, and corrected configuration projection PASS.

The first scan attempted in the 32-scan repetition then recorded one successful retry at
entry 62, `(Bank 7, 0xF4)`. Its status byte was `0x07` (valid, retried, bank verified),
`RETRIED_ENTRY_COUNT=1`, and `SCAN_FLAGS=0x006A0005`, representing `106` transactions.
The retry can only follow a non-timeout WADDR, REGADDR, or RADDR NACK; the exact phase is
not retained after a successful retry. This violates the required `105/105` and `NACK=0`
gate. The failure snapshot was preserved byte-exactly as `671D570715F53E6E1EEB74ADCB7BF08D18C24223FFB191CDE9B8436D89509C6D` before
one ACK returned the scanner to idle. No second scan or camera campaign was attempted.

## Safe terminal state

The scanner and executor were idle, I2C was idle, stream/capture actions were zero,
pending AIO was zero, and functional and unauthorized NVP write counts were zero. The
entry bank had been restored to `0x00`. Rollback was not required because no functional
write occurred. The driver was unloaded normally once, XDMA nodes disappeared, and the
DUT lock and then controller lock were released. No programming, reboot, Flash action,
power-cycle, mode action, EQ action, or capture occurred. The exact diagnostic image was
left in volatile SRAM.

In-commit evidence cannot self-attest its own Git commit; the publication commit and
commit-pinned remote byte read-back are recorded externally after this directory is
committed and pushed.
