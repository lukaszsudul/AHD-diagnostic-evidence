# MODE1-AUTH1 differential audit report

## Outcome

- Current v41 target-state overlap: 52 / 113 functional registers.
- Reduced minimum: 62 functional registers plus atomic bank selector, versus the prior overbroad 113-register model.
- Differential operations: {'FINAL_STATE_DELTA': 61, 'NO_OP_AGAINST_CURRENT_BASELINE': 99, 'OPTIONAL_ACP': 35, 'REQUIRED_DELAY': 1, 'REQUIRED_SEQUENCE_REWRITE': 10, 'REQUIRED_WRITE_PULSE': 2, 'SOFTWARE_STATE_ONLY': 3}.
- Bank1/0xED: `EXCLUDED_FROM_MINIMAL_MODE1`.
- Bank9/0x44: `EXCLUDED_FROM_MINIMAL_MODE1`.
- ACP: `ACP_NOT_REQUIRED_FOR_FIRST_IMAGE`; 35 coax-control operations excluded.
- Initial EQ: `MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE`.
- Recovery authority: 36/63 registers (57.143%).
- Recovery graph structural coverage: 100%.
- Failure injection: 592/592 PASS; every scenario terminates explicitly.
- Product baseline reconstruction: FAIL for 27 unknown-baseline registers.
- MODE1 implementation/build/HW1 prompt: not created.

First failed authority gate: `PROHIBITED_UNRESOLVED_TOUCHED_REGISTER_COUNT_NONZERO`.

This result closes the requested differential decision without claiming the speculative candidate ready. SCAN1 remains read-only; generic host NVP I2C is absent. No DUT, hardware, source, RTL, XDC, build, DCP or bitstream was touched.
