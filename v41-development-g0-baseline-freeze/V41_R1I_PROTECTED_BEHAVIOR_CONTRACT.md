# AHD v41 R1i Protected Behavior Contract

## Authority and scope

This contract is mandatory for G1 and every later v41 gate. It freezes the qualified R1i NVP/I2C functional behavior; G0 does not redesign it. Any later implementation must demonstrate equivalence to the exact qualified source oracle before it may be accepted.

- Original historical commit: `20c3323d79d3896edc586d6db1df7deee60f9e41`
- Qualified tree: `70d801fd7a879080da399bfa9ee95fd6eb008e16`
- Preservation branch: `baseline/v41-r1i-qualified-poc`
- Immutable tag: `v41-r1i-qualified-poc-20260827`
- Bitstream SHA-256: `F6A6905DD4AA40FD5F68923629AC3C02929D7D5628895AB43FDADB248929D3C6`
- Scientific verdict: `THESIS_CONFIRMED`
- Outcome: `STRONG_PASS`
- Scope: `QUALIFIED_POC_BASELINE`, not a production release
- Exact low-level causal mechanism: `INCONCLUSIVE`

Independent R-track experiments and candidates are excluded from this G-track baseline.

## Exact source oracles

| Function | Qualified path | SHA-256 |
|---|---|---|
| Initialization table/package | `rtl/nvp/nvp6134c_diagnostics_pkg.vhd` | `36BCA98533647E998A281A518935669FB29B48125D48F6D3785EA12CBFF04156` |
| NVP autoinit wrapper | `rtl/nvp/nvp6134c_autoinit.vhd` | `FCB5F98955F0507C095E774FA9E3048ACD34D07DF5EA40B6B8EEA715B649D5E5` |
| I2C transaction engine | `rtl/nvp/nvp6134c_i2c_bringup.vhd` | `C7AA56E8BC546DD0173FF79FA6E3376DEE607B2DDFDA3F52FD1503C05FFC6C68` |
| Qualified top-level wiring | `rtl/top/ahd_capture_top_xdma.sv` | `5E60D388BB9516E3AC2C86F0761901C0669DE4DC40121B2423A36E4445C66DF4` |
| R1i MMIO mux | `rtl/v41/control_status_regs.sv` | `77B63935A7042D74A11A85C2220715F87CF58EF7B42AF34D8D47BF04A6870A16` |

The tree identity controls if prose and implementation are ever found to disagree.

## Protected initialization table and operating profile

The exact qualified initialization table is source-identical and may not be regenerated, reordered, shortened, substituted, or reconstructed from memory. The frozen table has 214 slots, indices `0..213`, including 148 Marek-table slots, with `ENABLE_MAREK_INIT_TABLE=1`.

The qualified operating selections are:

- profile/range `"10"`: AHD 1080p25
- window `"000"`
- output phase `"A"`
- channel `"00"`: CH1 routed to VDO1
- auto-enable `0`
- stage `"10"`

Changing any of these is outside the protected R1i behavior and requires a later explicitly approved qualification scope.

## I2C rate and sampled-bus model

- Autonomous clock parameter: `CLK_HZ=62_500_000`
- I2C target parameter: `I2C_HZ=25_000`
- Divider semantics: `DIVIDER = CLK_HZ / (I2C_HZ * 2)`; they are frozen
- NVP address: seven-bit `0x30`, wire write/read bytes `0x60/0x61`

SCL and SDA use dedicated two-flop synchronizers with `ASYNC_REG=TRUE` and shift-register extraction disabled, followed by qualification requiring three consecutive matching samples. Protocol decisions use the filtered signals, not raw pins or the first synchronized sample.

Every high phase releases SCL, waits until filtered physical SCL is high, and then provides a full `DIVIDER+1` base-clock dwell before sampling SDA or changing it. The divider is held/reset while filtered SCL remains low. The per-high physical-SCL qualification timeout is 20 microseconds and follows the same bounded STOP/recovery policy as a qualified NACK.

## ACK decision and first-NACK abort

The low-state SDA observation is diagnostic only. ACK/NACK is decided only in the corresponding `ACK_*_HIGH` state after the qualified physical-high dwell. Filtered SDA equal to zero is ACK; any other value is NACK.

The first qualified NACK at WADDR, REGADDR, DATA, or RADDR immediately enters the STOP path. No later byte phase and no read-data phase may be emitted for that physical attempt. Intermediate-attempt NACKs remain visible in raw counters and failed-attempt logs.

## Legal STOP and BUS_FREE proof

The legal STOP sequence is protected:

1. `STOP_A` holds SCL and SDA low.
2. `STOP_B` releases SCL but retains SDA low until filtered physical SCL has completed the qualified-high dwell.
3. `STOP_C` releases SDA.
4. The resolved SDA high level is observed; merely releasing the output enable is insufficient.

A STOP edge must never be manufactured while physical SCL remains low.

BUS_FREE requires filtered SCL and filtered SDA simultaneously high for a full divider dwell. Qualification is bounded by 1 millisecond. Retry is permitted only after a completed legal STOP and successful BUS_FREE proof. If the engine cannot prove a safe STOP/BUS_FREE state, the logical transaction terminates unrecovered and must not be mislabeled as ordinary retry exhaustion.

## Bounded retry, recovery and terminal errors

R1i allows three retries, four total attempts. Fixed base-clock backoffs start only after completed STOP/BUS_FREE:

| Retry | Backoff |
|---:|---:|
| 1 | 100 microseconds |
| 2 | 500 microseconds |
| 3 | 2,000 microseconds |

A retry preserves byte identity, operation/table/result indices, phase, requested bank, and logical transaction serial. It does not replay setup in a manner that changes the logical operation.

A later successful attempt is classified as recovered: it increments recovered/retry-success telemetry but does not latch terminal `INIT_ERROR`, first-error state, terminal masks, or advance the logical operation twice. Failed intermediate attempts remain auditable.

A transaction becomes terminal after the fourth failed attempt, or earlier when safe STOP/BUS_FREE recovery cannot be proven. Retry exhaustion and unsafe-bus termination remain distinct classifications. Terminal and recovered outcomes must never be conflated.

## Bank invalidation and safety

- A target write is legal only after exact bank verification.
- Failed bank selection, failed verification, retry exhaustion, and unsafe recovery invalidate physical-bank validity.
- A bank verification mismatch invalidates the cache and is reported.
- Recovered attempts must not corrupt terminal masks, functional readback, table progression, logical serials, or operation indices.
- The original bank value is retained solely for the qualified final restoration policy.
- The existing bank-invariant checks and failed-transaction record semantics are protected.

## Reset, start and final-settle policy

- Autonomous NVP POR: 320 nominal 62.5 MHz cycles, approximately 5.12 microseconds, independent of PCIe link-up and AXI reset.
- NVP reset remains asserted for `CLK_HZ/2`, 500 milliseconds.
- Exactly one autoinit start pulse occurs at `CLK_HZ + CLK_HZ/2`, 1.5 seconds.
- Final settle remains exactly `C_INIT_SETTLE_TICKS=12000` under the qualified divider/state-tick semantics; no alternate derived delay may be substituted.
- `INIT_DONE` and `INIT_ERROR` are latched only when sequence completion asserts.

The future Gen2 transition must revalidate the actual lifecycle of the PCIe-derived application clock. It may not make NVP power, reset, start, I2C initialization, or final settle dependent on link training or AXI reset.

## MMIO compatibility and R1i telemetry

Every pre-existing MMIO address and behavior through `0x35FF` is protected, including access semantics, write behavior, latency, legacy payloads, failed-record layout, and probe-index semantics.

The R1i page is a read-only byte range `0x3600..0x367F`. Aligned 32-bit words carry data; the exact qualified mux behavior for unaligned/reserved locations is preserved.

| Address/range | Protected meaning |
|---|---|
| `0x3600` | magic `0x52314950` |
| `0x3604` | version `1` |
| `0x3608` | policy flags `0x3F` |
| `0x360C..0x3618` | WADDR opportunities, early observation, qualified NACK, early-false |
| `0x361C..0x3628` | REGADDR equivalents |
| `0x362C..0x3638` | DATA equivalents |
| `0x363C..0x3648` | RADDR equivalents |
| `0x364C` | raw qualified NACKs |
| `0x3650` | recovered transactions |
| `0x3654` | recovered NACKs |
| `0x3658` | unrecovered transactions |
| `0x365C` | retry exhausted |
| `0x3660`, `0x3664`, `0x3668` | success on retries 1, 2 and 3 |
| `0x366C` | maximum SCL-high wait cycles |
| `0x3670` | SCL-high timeout count |
| `0x3674`, `0x3678`, `0x367C` | first early-false, recovered and unrecovered logical serials |

## Frozen regression outcomes

The qualified R1i baseline outcome to preserve is:

- `INIT_DONE = 1`
- `INIT_ERROR = 0`
- autoinit NACK total `0`
- video present with the qualified 1080p25 profile
- measured normal frame rate `24.803727 Hz` and SAV rate `28,124.980562/s`
- post-init WADDR, REGADDR and DATA: `0/10,000` NACKs in each class
- SCL-high timeout count `0`
- retry-exhausted count `0`
- recovered transactions `0` and unrecovered transactions `0`
- raw qualified and early-false NACK counters `0`
- bank-invariant errors `0` across 3,300 checks
- counter overflow and failed-log overflow `0`

These results are functional regression requirements, not a claim of production margin, population coverage, or isolated low-level causality.

## Change-control rule

G1 may design composition around this contract but may not weaken or redesign it. Later implementation changes that touch a protected source oracle or observable behavior require an explicit equivalence/qualification plan, exact source provenance, regression evidence, and Owner-approved gate disposition.
