# R1f frozen statistical analysis plan

```text
PLAN_STATUS=FROZEN_BEFORE_R1F_HARDWARE
PLAN_FROZEN_UTC=2026-08-24T08:41:38Z
R1F_HARDWARE_RESULTS_SEEN_WHEN_FROZEN=NO
PAIR_SEQUENCE=A1_B1_A2_B2_A3_B3
PAIR_COUNT=3
```

This document fixes the primary calculations, tests, multiplicity handling, edge cases, and classifications before any R1f hardware sample exists. R7 values are historical design inputs only; they are not R1f results and are not used to choose an R1f test.

## 1. Analysis populations and validity

The primary unit labels are fixed as `A1`, `B1`, `A2`, `B2`, `A3`, and `B3`. Bootstrap telemetry, if any, is contextual and is never included as a B observation.

An A arm enters inference only when all Section 18.1 instrumentation gates pass. In particular, counter coherence, no saturation, complete failed-transaction log without overflow, zero bank-invariant errors, complete tri-phase probe, 10,000 target opportunities per phase, zero timeout, safe-target pre/post equality, bank restoration, coherent snapshots, and final DONE are prerequisites. T0/T1 are repeated reads of one hardware state and are never treated as two samples.

A B arm enters paired/replicate analysis only when its full functional-control gates pass. Formal zeros over the R1f range are not imputed as zero R1f phase counters; B has no R1f probe or phase-rate observation.

Any `NACKS > OPPORTUNITIES`, negative count, counter saturation, snapshot disagreement in a static field, invalid record field, impossible valid-bit combination, or failed legacy reconciliation is an instrumentation contradiction, not a statistical edge case.

## 2. Common conventions

- All rates use exact integer numerator and denominator; no rounded value enters a test.
- `rate = k/n`; `ppm = 1,000,000*k/n`.
- All confidence intervals are two-sided 95% unless explicitly stated.
- The normal quantile used by Wilson intervals is `z=1.959963984540054`.
- Exact tests use full probability, not mid-p.
- Decision comparisons are strict: `p < alpha`, never `p <= alpha`.
- Raw and adjusted p-values are retained at full machine precision and displayed with at least six significant digits.
- Probe analysis positions are one-based `1..10000`. If hardware stores zero-based indices, the decoder performs the frozen transformation `analysis_index = raw_index + 1` and preserves both values.
- Probe blocks are fixed by target-opportunity order: 1–1000, 1001–2000, ..., 9001–10000. Transaction-attempt number and wall-clock order are not substituted.
- A prerequisite NACK that prevents a target phase from being reached is not a target-phase opportunity or target-phase NACK.
- No continuity correction or pseudocount is used in primary point estimates or exact tests.

### 2.1 Wilson interval

For `p_hat=k/n` and `n>0`:

```text
center = (p_hat + z^2/(2n)) / (1 + z^2/n)
half   = z/(1 + z^2/n) * sqrt(p_hat*(1-p_hat)/n + z^2/(4n^2))
CI     = [max(0,center-half), min(1,center+half)]
```

This formula is used without a special-case approximation at `k=0` or `k=n`.

### 2.2 Holm adjustment

For a fixed family of `m` raw p-values sorted `p_(1)<=...<=p_(m)`:

```text
adjusted_p_(i) = min(1, max_{j<=i}((m-j+1)*p_(j)))
```

Adjusted values are mapped back to their original hypotheses. A missing but planned comparison receives p=1 for multiplicity accounting and is separately labeled unestimable; it cannot make the family smaller or easier to reject.

## 3. Per-phase post-init probe analysis

The three primary phase sequences are WADDR, REGADDR, and DATA, separately for A1/A2/A3. Each is the binary target-phase sequence in target-opportunity order.

For every run/phase panel report:

```text
n, ACKs, NACKs, rate, ppm, Wilson95;
first and last NACK index;
adjacent NACK-pair count;
binary run count;
maximum consecutive NACKs;
ten fixed-block NACK counts and rates.
```

### 3.1 Exact block-homogeneity test

The null is one common NACK probability across the ten equal 1,000-opportunity blocks. Conditional on total NACK count `K`, all `K` event positions are uniformly distributed among the 10,000 positions. The exact allocation probability is:

```text
P(k1,...,k10 | K) = product_b C(1000,kb) / C(10000,K),  sum(kb)=K.
```

The statistic is the Pearson statistic of the fixed-margin 10x2 NACK/ACK table. The exact tail is the sum of conditional probabilities for allocations with statistic at least the observed statistic. Because block sizes are equal and margins fixed, a dynamic program over block number, allocated NACKs, and `sum(kb^2)` is the required deterministic implementation. No asymptotic chi-square substitution or Monte Carlo decision is used.

### 3.2 Exact Wald–Wolfowitz runs test

Let `K` be NACK count, `Z=N-K`, and `R` the observed number of binary runs. Conditional on `K`, the exact mass is:

```text
P(R=2u) = 2*C(K-1,u-1)*C(Z-1,u-1)/C(N,K)

P(R=2u+1) =
  [C(K-1,u)*C(Z-1,u-1) + C(K-1,u-1)*C(Z-1,u)] / C(N,K)
```

Out-of-range binomial coefficients are zero. The reference center is `E[R]=1+2*K*Z/N`. The fixed two-sided p-value sums exact masses for all `r` satisfying `|r-E[R]| >= |Robs-E[R]|`.

### 3.3 Exact adjacent-pair test

`J=sum_{i=1}^{N-1} x_i*x_{i+1}`. Conditional on `K`, if `U` is the number of NACK runs, then `J=K-U` and:

```text
P(U=u | K) = C(K-1,u-1)*C(Z+1,u)/C(N,K).
```

The reference center is `E[J]=K*(K-1)/N`. The fixed two-sided p-value sums exact masses with `|j-E[J]| >= |Jobs-E[J]|`.

### 3.4 First/last order-statistic context

For `K>0`, report exact central 95% conditional intervals using:

```text
P(Min >= m | K) = C(N-m+1,K)/C(N,K)
P(Max <= m | K) = C(m,K)/C(N,K)
E[Min] = (N+1)/(K+1)
E[Max] = K*(N+1)/(K+1)
```

First/last positions are contextual and do not add a fourth hypothesis test.

### 3.5 Stationarity/independence multiplicity and classification

The fixed family contains up to 27 tests: three tests x three phases x three A repetitions. Holm controls familywise alpha 0.05 across all 27 planned hypotheses. Undefined tests receive raw p=1 and an insufficiency flag.

A run/phase panel is informative only when `5 <= K <= N-5`, the complete target NACK-index sequence is available, and all sequence invariants reconcile. Panel classification is:

- `EVIDENCE_AGAINST_STATIONARITY_OR_INDEPENDENCE` if any globally Holm-adjusted panel test has `p<0.05`;
- `COMPATIBLE_WITH_STATIONARY_MEMORYLESS_PROCESS` if informative and none rejects;
- `INSUFFICIENT_EVENTS` otherwise.

For each final phase field (`POSTINIT_WADDR_PROCESS`, `POSTINIT_REGADDR_PROCESS`, `POSTINIT_DATA_PROCESS`):

- evidence against takes precedence if any valid repetition has a globally adjusted rejection;
- compatible requires all three repetition panels to be informative and none to reject;
- otherwise use insufficient events.

A compatible classification is expressly not proof of stationarity, independence, or memorylessness.

If a 512-entry phase index log overflows, aggregate rate and block analysis remain reportable, but runs, adjacent-pair, first/last, and maximum-streak inference are not complete. Without a rejecting complete test, that phase/run panel is `INSUFFICIENT_EVENTS`, not compatible.

## 4. Autoinit per-phase rates and heterogeneity

For WADDR, REGADDR, DATA, and RADDR in every A run report `k/n`, ppm, and Wilson95 using measured opportunities. The equality audit `sum(phase NACKs) = legacy aggregate NACK_COUNT` is a prerequisite.

The within-run heterogeneity null is a common NACK probability across the four phases. Use the exact Fisher–Freeman–Halton conditional test on the 4x2 phase-by-outcome table. With row opportunities `n_i`, phase NACKs `k_i`, and total `K`:

```text
P(k1,...,k4 | margins) = product_i C(ni,ki) / C(sum(ni),K).
```

The two-sided exact p-value uses probability ordering: sum the probabilities of all tables with the same margins whose probability is no greater than the observed table's probability. The three run-specific p-values are Holm-adjusted at familywise alpha 0.05.

`AUTOINIT_PHASE_RATE_HETEROGENEITY` is:

- `SUPPORTED_REPEATABLE` when at least two of three adjusted tests reject and the intersection of their maximum-observed-rate phase sets is nonempty (ties remain sets; they are not broken post hoc);
- `MIXED_OR_RUN_SPECIFIC` when one run rejects or rejecting runs have incompatible directions;
- `NOT_DETECTED_NOT_EQUALITY_PROOF` when all three are estimable and none rejects;
- `INSUFFICIENT_VALID_DENOMINATORS` otherwise.

A zero phase denominator makes that run's four-phase test unestimable. A zero NACK count with nonzero denominator remains valid.

## 5. Autoinit versus matching post-init phase

The three fixed comparisons within each A run are:

1. autoinit WADDR versus post-init WADDR;
2. autoinit REGADDR versus post-init REGADDR;
3. autoinit DATA versus post-init DATA.

For each comparison report:

```text
p_auto, p_probe;
rate difference = p_auto-p_probe;
rate ratio = p_auto/p_probe;
95% CI for the difference;
95% CI for the rate ratio;
one-sided Fisher exact p for H1: p_auto>p_probe;
Holm-adjusted p within that run's fixed three-test family.
```

The difference interval is the two-sample Miettinen–Nurminen score interval. The rate-ratio interval is the 95% profile-likelihood interval from the two independent binomial likelihoods under `p_auto = RR*p_probe`, profiling the nuisance probability over its legal range. No Wald log-ratio interval and no 0.5 correction is primary.

Holm uses a fixed family size of three in each repetition. The decision alpha is the prompt-required 0.01.

A run-specific phase comparison meets the support rule only when all are true:

```text
rate difference > 0;
Holm-adjusted one-sided Fisher p < 0.01;
rate-ratio lower 95% bound > 2.
```

For each final `AUTOINIT_CONTEXT_RATE_ELEVATION_<PHASE>` field:

- `SUPPORTED` requires the run-specific support rule in at least two of three A runs;
- `MIXED` means exactly one run supports, or the valid point-estimate rate differences contain both positive and negative signs across repetitions;
- `NOT_SUPPORTED` means zero runs support, all three comparisons are valid/estimable, and the point-estimate signs are not mixed;
- `INSUFFICIENT_EVENTS` means fewer than two comparisons have an identifiable rate ratio and valid denominators.

### 5.1 Zero handling

- `n=0`: rate/test/CI unestimable; p is assigned 1 only for Holm bookkeeping.
- both event counts zero: difference 0, Fisher greater-p 1, rate ratio `NOT_IDENTIFIABLE_0_OVER_0`; this run cannot meet support.
- probe events zero and autoinit events positive: point RR is `+INF`; the profile lower bound remains the decision quantity.
- autoinit events zero and probe events positive: RR is 0 and the greater-direction test cannot support elevation.
- event count zero does not trigger a pseudocount.

## 6. Replicate-consistency analyses

### 6.1 Arm A

Fixed homogeneity tests are:

- four exact 3x2 Fisher–Freeman–Halton tests comparing A1/A2/A3 autoinit rates, one per phase; Holm across four at alpha 0.05;
- three exact 3x2 tests comparing A1/A2/A3 post-init probe rates, one per phase; Holm across three at alpha 0.05;
- one exact 3x2 failed-transaction-rate test using `failed transactions / transaction starts`, when starts are coherent;
- exact conditional homogeneity tests of failed-record composition across runs for the predeclared categories: high-level phase, transaction kind, phase-NACK bitmap, table slot, requested bank, and valid physical-bank-before context. Holm across these six composition tests at alpha 0.05.

Sparse RxC tables use the exact fixed-margin Fisher–Freeman–Halton probability-ordering tail. Categories with zero total count across all runs are removed before computing the table, but no observed nonzero category is pooled post hoc.

Bank invariant results are deterministic gates, not rates: all valid A runs must have zero errors. Functional NVP PASS/FAIL repetition is reported descriptively; three identical binary results are not called statistically equivalent because no equivalence margin or adequately powered equivalence test was predeclared.

### 6.2 Arm B

When exact formal transaction exposure is proven equal across B1/B2/B3, aggregate NACK-count homogeneity uses the exact multinomial conditional test with probabilities `(1/3,1/3,1/3)`. Otherwise counts are descriptive only.

The first-eight legacy records are compared byte-for-byte and field-by-field as chronological prefixes. `IDENTICAL_PREFIX` does not establish equality of the unobserved overflow tail. Functional results are descriptive and are not an equivalence test.

### 6.3 Final replicate classification

`R1F_REPLICATE_HOMOGENEITY` is:

- `EVIDENCE_AGAINST_HOMOGENEITY` if any valid predeclared replicate family rejects after its Holm correction;
- `NO_HETEROGENEITY_DETECTED_NOT_EQUIVALENCE` if every required comparison is estimable and none rejects;
- `INSUFFICIENT_VALID_DATA` otherwise.

## 7. Failed-transaction distribution and bank semantics

For each A run report counts and proportions by high-level phase, transaction kind, phase-opportunity bitmap, phase-NACK bitmap, table slot, requested bank, physical-bank-before context, physical-bank-after context, and bank-update reason. Multiple phase NACK bits in one failed transaction count as one failed transaction.

Phase failure rates use the measured phase-opportunity denominators. A transaction-kind, table-slot, or bank-context *rate* is computed only when its matching opportunity exposure is independently and completely reconstructable and reconciles with the transaction serial/counters. Otherwise the report uses the explicit term `failure composition`, never `failure rate`, and performs no equal-cell test.

For a denominator-limited composition, a predeclared descriptive concentration requires the same modal category in at least two runs, at least five failed transactions in each supporting run, and modal share >=50% in each. This does not imply an elevated opportunity-normalized rate.

`FAILED_TRANSACTION_DISTRIBUTION` is one of:

- `REPEATABLE_OPPORTUNITY_NORMALIZED_CONCENTRATION`;
- `REPEATABLE_FAILURE_COMPOSITION_CONCENTRATION_DENOMINATORS_LIMIT_RATE_CLAIM`;
- `RUN_VARIABLE_DISTRIBUTION`;
- `NO_REPEATABLE_CONCENTRATION_DETECTED`;
- `INSUFFICIENT_FAILED_TRANSACTIONS`.

`BANK_TRACKER_COHERENCE` is:

- `PASS_ZERO_INVARIANT_ERRORS` only when every valid A run reports zero invariant errors;
- `CONTRADICTION_MEASURED` when any error is nonzero;
- `INCONCLUSIVE_INFRASTRUCTURE` when no valid A bank sample exists.

`R7_OPERATION_86_SEMANTICS` is:

- `EXPLAINED_BY_R1F_FIELDS` only if an operation-86-like event is observed with coherent requested/before/selector/verify/after valid fields that explain the old overloaded representation;
- `TRUE_TRACKER_CONTRADICTION_REPRODUCED` when coherent valid bits expose an invariant contradiction;
- `REMAINS_INCONCLUSIVE` when no comparable event occurs or its new record is unavailable.

Bank dispersion is not interpreted as independent scientific evidence if coherence fails.

## 8. Paired A/B direction and completion

For each valid pair report the signed aggregate autoinit NACK-count difference `A_i-B_i`, its sign, and the functional-result pair. Because three pairs cannot yield a conventional 0.05 sign-test result, repeatability is descriptive and accompanied by the exact sign-test p-value. With three non-tied differences in one direction, one-sided p is 0.125 and two-sided p is 0.25.

Directional label:

- `DIRECTION_REPEATABLE_3_OF_3` when all three nonzero differences have the same sign;
- `DIRECTION_MAJORITY_2_OF_3` when exactly two have one sign and the third is opposite or tied;
- `NO_REPEATABLE_DIRECTION` otherwise;
- `INSUFFICIENT_VALID_PAIRS` with fewer than three valid pairs.

`PAIRED_AB_RESULT` combines completion and this label:

- `COMPLETE_VALID_3_PAIRS_<DIRECTION_LABEL>` when all six arms are valid;
- `INCOMPLETE_INFRASTRUCTURE_AFTER_PAIRED_B_RESTORATION` when an A becomes invalid and its safe immediate B completes;
- `INCONCLUSIVE_ARM_B_INFRASTRUCTURE` when a B is invalid;
- `NOT_RUN_FOR_SAFETY_<EXACT_BLOCKER>` when applicable.

No bootstrap sample is counted, no invalid arm is repeated, and no later pair is silently substituted.

## 9. Multiple-use and interpretation restrictions

- The stationarity family, autoinit heterogeneity family, three per-run context families, and replicate families are separate predeclared scientific families; no p-value is moved between families after results are seen.
- Confidence intervals used in the context support rule remain per-comparison 95% intervals; multiplicity control is supplied by the fixed Holm p-value criterion exactly as specified by the owner prompt.
- Non-significant p-values are never phrased as proof of equality, stationarity, independence, memorylessness, or equivalence.
- Statistical association does not prove an electrical mechanism.
- Any additional visualization or model is labeled exploratory and cannot change a required classification.

The final report always states:

```text
ROOT_CAUSE_SOLELY_PROVEN=NO
BOARD_VCCO_DROOP_PROVEN=NO
GROUND_BOUNCE_PROVEN=NO
ANALOG_MARGIN_DIRECTLY_MEASURED=NO
```

## 10. Frozen primary output fields

```text
POSTINIT_WADDR_PROCESS=
POSTINIT_REGADDR_PROCESS=
POSTINIT_DATA_PROCESS=

AUTOINIT_PHASE_RATE_HETEROGENEITY=

AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR=
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR=
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA=

R1F_REPLICATE_HOMOGENEITY=
BANK_TRACKER_COHERENCE=
R7_OPERATION_86_SEMANTICS=
FAILED_TRANSACTION_DISTRIBUTION=
PAIRED_AB_RESULT=
```

No threshold, family, direction, denominator rule, or classification rule in this plan may change after R1f hardware begins.
