# CONT1R2 prior retried-NACK event

- PRIOR_EVENT_REPLAY: `PASS`
- Raw snapshot SHA-256: `671D570715F53E6E1EEB74ADCB7BF08D18C24223FFB191CDE9B8436D89509C6D`
- Raw bytes: `584`
- Generation: `3`
- Counts: `82/82 entries`, `10/10 groups`, `106` transactions
- Scan duration: `10552314` scanner ticks (tick frequency is not encoded in the frozen artifact)
- Entry/exit bank: `0x00` / `0x00`; restore `PASS`
- Logical target: `Bank7/0xF4` at entry `62`
- Raw word/value/status: `0x07F40007` / `0x00` / `0x07`
- Decoded final status: `VALUE_VALID=1`, `RETRIED=1`, `BANK_VERIFIED=1`, `ERROR_CODE=NONE`
- Final retry result: `PASS_VALID_VALUE`
- EXACT_NACK_PROTOCOL_PHASE: `NOT_ENCODED`
- Hardware ERR_CNT delta: `N/A` (`SCAN1` exposes per-scan failed/retried fields, not a cumulative ERR_CNT register)
- Host-derived frozen-event delta: `1`

The target identifies where the recovered transaction was observed. It does not prove that Bank7, register 0xF4, or CH3 caused the electrical NACK. On a successful retry the exact RTL replaces the status error nibble with `NONE` and never populates `FIRST_ERROR`; therefore WADDR, REGADDR, and RADDR cannot be distinguished from this artifact.
