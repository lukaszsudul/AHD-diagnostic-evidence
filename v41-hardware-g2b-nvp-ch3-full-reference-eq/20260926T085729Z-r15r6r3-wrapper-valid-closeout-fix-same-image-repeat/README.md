# R15R6R3 — wrapper correction and one same-image repeat

**Engineering: FAIL_APPLY_PC70_WADDR_NACK_CONTAINMENT.** The three task-wrapper corrections passed 87/87 scoped offline checks. Product firmware, all 52 released host files, ELF, decoders and driver remain unchanged.

One exact SRAM programming, one planned warm reboot, one driver load and one ARM/PREPARE/APPLY were performed. Autoinit NACK phases WADDR/REGADDR/DATA/RADDR were **18/22/8/1**, total49, timeout0; the retained R15R6 values were30/35/12/4, total81, timeout0. This difference does not establish repair or physical causality.

PREPARE **PASS_WITH_READ_RETRY**, terminal0xC3CD0042, generation1. One READ at **PC25 Bank9/0x44** recovered from RADDR_NACK; 47 main accepted transactions =46+1, complete telemetry and empty terminal hard record. PC12 and PC23 passed as source-derived conclusions from successful PREPARE; no pin trace was collected. The same-bitstream cohort has two actual PREPARE commands: one historical PC23 failure and one pass. R15R6R2 contributes no hardware attempt.

APPLY **FAIL_TERMINAL**, terminal0xC3C02283: **PC70 WRITE Bank0/0x36=0x02, WADDR_NACK**, no timeout. The full hard record and telemetry were retained; the earlier PREPARE snapshot was preserved. No write retry was eligible or accepted. FEQ1 configuration handoff was not reached; full EQ, T0, reader and capture were not started. Zero fresh frames and no PNG; no substitute image was created.

The MMIO ledger contains233 complete IO_BEGIN/IO_RETURN pairs. The first access after each command terminal was the loader hard-failure header. The I2C error was not mislabeled as a BAR transport failure.

**Containment:** no unload was attempted. Loader lockout and unavailable FEQ safe-environment failed the engine remove gate. Some process metadata was incomplete and remained UNKNOWN. Own reader/AIO never started; stream OFF/quiescence passed. Driver and both own reservations remain retained. No forced unload, process kill, unbind, rescue reboot/reset or second attempt was made. HDMI received no targeted operation; the planned reboot affected the whole host.

Next action: separately authorize controlled closeout of the retained containment. This task does not authorize another configuration attempt. Private raw, paths, credentials, product files and pixels are not published. Publication verification is separate from engineering acceptance. No physical NACK root cause, full-EQ success, live scene or product qualification is claimed.
