# R15R6R2 — same-image repeat preparation stopped

**Engineering result: BLOCKED_PRE_ACTIVATION_LOADER_HARD_RECORD_VALID_BIT_MISMATCH.**

The camera was freshly confirmed by the Owner. The bitstream, ELF and all 52 released host files matched their retained identities. No DUT connection, hardware lock, programming, reboot, ARM, PREPARE, EQ or DMA operation was performed.

## First blocker

Read-only inspection found that the retained execution wrapper interprets loader hard-failure-record validity differently from the frozen normative decoder. A valid record without a raw I2C cause can follow the empty-record branch, omitting command/context and the consistency reread. This prevents the required complete failure observation. Correcting the condition changes control flow, which this same-image, unchanged-wrapper task did not authorize.

The same inspected closeout code also lacks the complete endpoint ownership/engine-state evidence required for normal unload and can access the user BAR after a prior MMIO failure. These limitations are retained for the next decision. No corrective patch or functional test was performed.

The historical R15R6 PC23 failure payload was captured; that result remains unchanged. The legacy APPLY classification at a valid FEQ1 handoff was not identified as a blocker.

## Comparison

| Observation | R15R6 retained | R15R6R2 |
|---|---|---|
| PREPARE | FAIL_TERMINAL, 0xC3C02202 | NOT_RUN |
| PC12 | One recovered WADDR_NACK on read | NOT_EVALUABLE |
| PC23 | WADDR_NACK writing FF=09; pending bank9 unconfirmed | NOT_EVALUABLE |
| Autoinit phase NACKs | 30 / 35 / 12 / 4, total 81; timeout 0 | NOT_MEASURED |
| Initial EQ / T0 / DMA | NOT_RUN / NOT_ESTABLISHED / NOT_RUN | Same non-execution state |
| Frames / PNG | 0 / NOT_CREATED | 0 / NOT_CREATED |
| Cleanup | PASS, historical | NOT_REQUIRED_NO_RESOURCES_ACQUIRED |

There is still one executed PREPARE and one observed PC23 failure in this comparison. This preparation stop adds no hardware trial, success or repeated failure. Each target at T0+1 through T0+10 seconds is NOT_RUN; no ten-second image observation occurred.

## Identity and limits

- Firmware source: `719bcd63aa40cbeadb2b6eae99697f574209b6de`.
- Host source: `c4bc671620f2cc2ae57fcbf9d11c31ba2d56aac4`.
- Bitstream: 2,192,144 bytes; SHA-256 `3962886A7813B16D4A3B5C0D21F81A5B930696FF8E6DCD319A3331FA7FD2D5E2`.
- ELF: 63,080 bytes; SHA-256 `2621B77C9DB756908A9C993A86F70C72F4831DB85EB48EA703B31D1E083040E1`.
- Host archive SHA-256: `68F92CAE218DD1063499F37E720C70173A4962CBC1A7196F4EA731AF33CC8177`.

HDMI received no targeted operation; its current state and the DUT boot/driver were not measured. Firmware/host/build/LUT changes and functional tests: zero. Physical NACK root cause and full EQ behavior remain unproven. Publication is separate from engineering acceptance.

## One next action

Separately authorize a minimal task-wrapper correction for loader hard-record validity and the documented failure-closeout requirements. Preserve the firmware, ELF, host product modules and normative decoder bytes. No correction or new hardware attempt is authorized by this result.
