# CONT1R3 Preregistered Hypotheses and Analysis Plan

Frozen before RTL implementation, FPGA build, DUT contact, and hardware data collection.

Task: `AHD v41 G2B-NVP-CAMERA-ACQ1-COMPAT0-R2R1-CONT1R3`

Parent source: `dae2aff60141ecdbc0afac08fc0df9a3166f66c6`

Parent tree: `21e33d481ef637667756caa8015e7fa1b1dd8ebf`

CONT1R2 evidence: `501a0dea7588679b0379b88cdc32c8fec2507c3f`

## Frozen authority and opportunities

The primary campaign contains exactly 1,000 complete scans and excludes the control scan. Each complete scan has 82 eligible first attempts distributed across ten execution groups with group counts `1,3,7,16,10,11,11,11,11,1`.

The early positional category is zero-based `POSITION_IN_GROUP=0..5`; the late category is `POSITION_IN_GROUP>=6`. Short groups contribute no nonexistent late opportunities. In every complete scan the exact manifest provides 47 early and 35 late eligible first attempts, so the intended complete campaign provides 47,000 early and 35,000 late exposures. Actual retained exposure counts, not these planned counts, are authoritative in the final analysis.

Actual bank changes occur at groups 4–9 and contribute 55 exposures per complete scan. Same-bank reselections occur at groups 1–3 and contribute 26 exposures. Group 0 has no valid previous-group bank and contributes one separately reported exposure.

## H1 — bank-local temporal association

Recovered first-attempt NACKs may be enriched at short elapsed time or early position after successful `VERIFY_GROUP_BANK`. The primary prediction is a higher opportunity-normalized event rate at offsets 0–5 than at offsets 6 and later. Supporting evidence also requires recovered-event elapsed-time ranks to be concentrated toward the short end of the eligible exposure distribution.

`ERR_RADDR_NACK` may dominate as a secondary prediction. A dominant phase neither proves H1 nor proves a physical bank-relaxation mechanism.

Actual bank changes and same-bank reselections are reported separately. A same-bank reselection still has a real select/verify boundary and remains eligible for H1.

## H2 — no localized recent-verify association

After normalization by eligible first attempts, event rates may show no material early-versus-late enrichment. Phase mixture or phase dominance is reported but is not by itself decisive. Fixed manifest order may instead expose register-family, channel, or phase-dependent susceptibility.

## H3 — insufficient discrimination

Use `CAUSAL_MODEL_UNRESOLVED` when event count, exposure coverage, telemetry precision, dependence, or confounding prevents the predeclared comparison. Position/time association remains observational and cannot prove a physical root cause because manifest position, time, group, register family, bank, and channel are fixed together.

## Frozen FPGA-time bins

The scanner/master command domain is the XDMA `axi_aclk`, expected and later build-verified at 62,500,000 Hz (16 ns per counter tick). The exact fixed-master source uses 25 kHz I2C and a nominal register-read duration near 102,000 FPGA ticks. Before hardware data, the following half-open bins are frozen:

| Bin | TIME_SINCE_VERIFY_TICKS | Approximate interpretation only |
|---|---:|---|
| T0 | 0..4,095 | immediate first entry after verify |
| T1 | 4,096..131,071 | approximately one preceding command or less |
| T2 | 131,072..262,143 | approximately two preceding commands |
| T3 | 262,144..524,287 | approximately three to five preceding commands |
| T4 | 524,288..1,048,575 | approximately six to ten preceding commands |
| T5 | 1,048,576 and above | later exposure or accumulated retry delay |

Final nanoseconds are calculated as integer `ticks * 1,000,000,000 / VERIFIED_CLOCK_HZ`; raw 64-bit ticks remain authoritative and integer nanoseconds use floor division. Counter subtraction is unsigned modulo 2^64. At 62.5 MHz the wrap interval is far beyond a governed scan/campaign, and any observed wrap ambiguity is a hard telemetry failure.

## Required summaries

The primary campaign and the control scan are analyzed separately. Publish:

1. Raw and decoded first-attempt cause counts and rates.
2. Counts and rates by execution group, bank, register family, and full `(bank,register)` key.
3. Counts and rates by exact `POSITION_IN_GROUP`.
4. Early offsets 0–5 versus late offsets 6+ using actual denominators.
5. Counts and rates by the frozen FPGA-time bins above.
6. Counts and rates by `TRANSACTIONS_SINCE_VERIFY`.
7. Actual-bank-change, same-bank-reselection, and no-predecessor categories.
8. Per-scan event counts, including the number of multiple-event scans.
9. Retry outcome, final-value validity, hard errors, overflow, loss, and censored observations.

The null allocation is proportional to measured eligible first-attempt opportunities. Raw event counts are never compared to a uniform wall-clock distribution.

## Frozen descriptive decision rule

- If the complete 1,000-scan campaign has no recovered event, return `NO_RECOVERED_NACK_OBSERVED_IN_1000_SCANS`.
- If fewer than 10 recovered campaign events exist, or any required exposure denominator is unavailable, return `CAUSAL_MODEL_UNRESOLVED`.
- With at least 10 events and complete denominators, call `BANK_LOCAL_TEMPORAL_ASSOCIATION_SUPPORTED` only when both: (a) the early opportunity-normalized rate is at least 2.0 times the late rate, and (b) at least 75% of recovered events lie at or below the 35th percentile of the retained eligible `TIME_SINCE_VERIFY_TICKS` distribution.
- With at least 10 events and complete denominators, call `BANK_LOCAL_TEMPORAL_ASSOCIATION_NOT_SUPPORTED_IN_THIS_RUN` when the early/late rate ratio is below 2.0 and the time concentration condition is not met.
- All other complete-campaign outcomes are `CAUSAL_MODEL_UNRESOLVED`.
- Any incomplete campaign is `NOT_ASSESSED_CAMPAIGN_INCOMPLETE`.

These thresholds are descriptive preregistered classification rules, not a proof of independence, a causal effect, or an electrical root cause. Repeated entries within a scan may be dependent. No p-value or confidence interval will be claimed unless its assumptions and dependence limitations are stated explicitly; none is required for the primary decision.

## Prohibited post-observation changes

The original predictions, bins, denominators, and decision thresholds above will not be rewritten after hardware results. Any later view is labeled exploratory or an explicit amendment with a new hash. CONT1R3 does not execute an I2C timing change, delay intervention, cadence sweep, camera operation, 10,000-scan qualification, or functional NVP write.
