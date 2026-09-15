# CONT1R2 I2C Integrity Summary

- Control scan: `PASS`, 105/105 transactions, zero NACK/retry.
- Zero-error qualification: `7/10000` scans; the first recovered NACK appeared at qualification scan 7.
- All governed recorded scans: `65` (1 control + 7 qualification + 57 same-cadence characterization).
- Complete projections: `65/65`
- Clean 105-transaction scans: `56`
- Recovered NACK/retry events: `10`
- Timeouts/bank-verify failures/incomplete publications/snapshot mutations: `0/0/0/0`
- Hardware ERR_CNT: `N/A — not exposed by SCAN1 MMIO contract`
- Host-derived event-counter delta: `10`
- Raw campaign data: retained privately; public evidence contains hashes and summaries only.
- Final integrity classification: `FAIL_RETRIED_NACK`
