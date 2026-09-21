# AHD v41 CH3 R2R10R5 — experimental build only

## Outcome

`BUILD_RESULT=BITSTREAM_GENERATED_UNTESTED`

A single bounded CH3 detector-readiness window change was built with one
Vivado 2025.2 implementation run. The run completed synthesis, optimization,
placement, physical optimization, routing and one bitstream generation.

This is an experimental build artifact. Functional tests and additional
timing, CDC and bus-skew sign-off were explicitly deferred by the Owner. No DUT
access or hardware operation was performed.

## Identity

| Item | Value |
|---|---|
| Base source commit / tree | `e804b5a865637781f6a0f7e85a3607c284b72ffe` / `428ebb18e6f4057f333b78d0f889041ccf136363` |
| Built source commit / tree | `bc20bfbde7b5eb9a6d9deec5796651ffa4be0886` / `cbf787a8ca3ba71a97fd2175e021fe05e6f61475` |
| Target / top | `xc7a35tcsg325-2` / `ahd_capture_top_xdma` |
| Routed DCP | 62,878,434 bytes; SHA-256 `5FBD91805CA3D2D52EBE4E87EFCBFAA3510F7602E13B7B5B064CB53E2511B846` |
| Bitstream | 2,192,144 bytes; SHA-256 `B95F95C9392EE34DE6FDC969B1FF1266C55AA211C1F8523262170D14359389D9` |

Private source, detailed microcode/profile data, DCP and bitstream are not
published here.

## Build observations

- Post-opt Slice LUT: 20,301 / 20,800 (97.60%).
- Routed Slice LUT: 19,846 / 20,800 (95.41%).
- Routed registers: 21,792; BRAM tiles: 28.5.
- Routing: 38,961 / 38,961 routable nets fully routed; 0 routing errors.
- Native route log: WNS +0.291 ns, TNS 0, WHS +0.036 ns, THS 0.
- Native bitgen DRC: 0 errors; bitgen completed successfully.
- Main log: 0 `ERROR`, 0 `FATAL`, 0 `CRITICAL WARNING` lines.

No separate timing summary, check_timing, DRC report, CDC audit, bus-skew
report, methodology report or promoted checks were run. Native timing messages
are recorded observations and do not constitute full timing sign-off.

## Deferred assurance and causal boundary

XSim, other RTL simulation, host tests, regression, formal and lint were all
zero by explicit Owner instruction. The new change is behaviorally untested.

The image changes classification of bounded dynamic detector readiness. It
does not repair I2C reads, change the I2C master or profile values, establish
the root cause of the historical NACK, prove APPLY success, establish camera
sync or grant capture admission. Earlier terminal-18 NACK and the later
localized F0 readback failure remain separate historical results.

Any hardware activation or experiment requires separate Owner authorization.

```text
QUALIFICATION_SCOPE=EXPERIMENTAL_BUILD_ONLY_NOT_QUALIFIED
OWNER_TEST_DEFERRAL=EXPLICIT
TIMING_SIGNOFF=NOT_PERFORMED
CDC_SIGNOFF=NOT_PERFORMED
BUS_SKEW_SIGNOFF=NOT_PERFORMED
BEHAVIORAL_ASSURANCE=UNTESTED_NEW_CHANGE
HARDWARE_QUALIFICATION=NOT_RUN
DUT_CONTACT=SSH=JTAG=LIVE_MMIO=LIVE_I2C=0
CAPTURE_ADMISSION=NOT_GRANTED
NEXT_HARDWARE_EXPERIMENT=SEPARATE_OWNER_AUTHORIZATION_REQUIRED
```
