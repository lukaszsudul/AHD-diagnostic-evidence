# AHD v41 CH3 R2R10R13 — bounded PREPARE read retry build only

## Result

- Source implementation: **IMPLEMENTED, COMMITTED, UNTESTED**.
- Build: **BLOCKED_POST_OPT_LUT_CAPACITY**.
- First blocker: 20,851 Slice LUT used after the sole `opt_design`; physical capacity is 20,800 and the gate requires `Used < Available`.
- Synthesis / opt: **PASS / PASS**.
- Place / route / bitgen: **NOT RUN / NOT RUN / NOT RUN**.
- Bitstream / routed DCP: **NONE / NONE**.
- Tests and additional sign-off: **NOT PERFORMED BY OWNER DIRECTION**.
- DUT: **UNTOUCHED**.

## Source identity and scope

- Base: `d0f28b35c44d66bfd46c2b02388cdf03923e0c0a`, tree `082c6dbc7c2367ac872ca8bc71039926227360ac`.
- Candidate: `cb403d24999e760b47db5ebe1775ea5e218edb66`, tree `66245a471b5f6380e869026a72fa503462c03aff`.
- Frozen microcode SHA-256: `6821A46132381F9E2B52D2BF023294073F36653A814C9FF7BA95E02180FF6054`.

The loader-only change covers exactly 16 allowlisted PREPARE baseline-read instruction occurrences. It permits one retry per instruction and four per PREPARE after NACK causes 1/2/3 without timeout, using 300 us continuous bus idle and a nonrenewable 1 ms retry-accept deadline. The existing reset-only first terminal-failure record is preserved. Recovered attempts use a separate read-only version-1 journal with four slots and coherent generation/counter checks. The host classifications are `PASS_CLEAN`, `PASS_WITH_READ_RETRY`, `FAIL_TERMINAL`, and `OBSERVABILITY_INCOMPLETE`.

The I2C master, SCAN1, microcode, EQ, PN, frontend, DMA, driver and XDC are unchanged.

## Build evidence

| Stage | Slice LUT used / available | Result |
|---|---:|---|
| Post-synth | 22,449 / 20,800 | Owner exception into one opt |
| Post-opt | 20,851 / 20,800 | **FAIL** |

The candidate is 51 LUT over physical capacity. The strict gate therefore needs at least 52 fewer post-opt LUT before placement can be admitted. Post-synth/post-opt DCPs were retained privately. Their SHA-256 values are `BEFEF5320CDE8BD08269518FFA29556FE165841ABC0D0B9AC3FC243057852B18` and `7D0598671BB91F0375705EA674389F90078B306770979480FD27B30234AF09A6`.

No hardware result, retry effectiveness, NACK-frequency improvement, EQ execution, live scene, timing sign-off or product qualification is claimed.
