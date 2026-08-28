# R2 Review — Protocol Impact

## Historical status

The original R2 halt remains valid under the frozen protocol that was active during execution. This review does not rewrite history.

- halt at sequence 10: preserved;
- halt reason `C3_NON_CLEAN_SUSPEND_BLOCK`: preserved;
- ten countable run receipts: preserved;
- original classifications: preserved;
- original evidence commit/package: preserved;
- original scientific result `BLOCKED`: preserved as the pre-review execution state.

## Defect scope

The identified defect is confined to the host-side frame-rate clean-gate measurement:

- approximately one-second window not phase-locked to frame events;
- integer frame-event delta;
- tolerance much tighter than one-event resolution;
- frozen target coupled to one legacy window outcome.

No change is proposed to:

- C0/C1/C2/C3 artifacts or RTL;
- NVP behavior or table;
- I2C frequency or causal factors;
- run count or Williams ordering;
- autoinit NACK/retry/recovery classifications;
- cold-start denominator;
- INIT_DONE timing protocol;
- safe-baseline rules;
- R3 triggers.

## Existing ten-run disposition

`KEEP_RAW_DATA_BUT_PRIMARY_CLASSIFICATION_INVALID`

| Seq. | Cell | Historical class | Immutable historical treatment | Use after review |
|---:|---|---|---|---|
| 1 | C0 | FAIL | preserve | exploratory raw/identity/video evidence only |
| 2 | C1 | INCONCLUSIVE | preserve | exploratory raw/identity/autoinit evidence only |
| 3 | C3 | CLEAN_PASS | preserve | exploratory raw/identity/autoinit evidence only |
| 4 | C2 | CLEAN_PASS | preserve | exploratory raw/identity/autoinit evidence only |
| 5 | C1 | INCONCLUSIVE | preserve | exploratory raw/identity/autoinit evidence only |
| 6 | C2 | RECOVERED_PASS | preserve | recovery evidence remains an independent R3 trigger |
| 7 | C0 | FAIL | preserve | exploratory raw/identity/video evidence only |
| 8 | C3 | CLEAN_PASS | preserve | exploratory raw/identity/autoinit evidence only |
| 9 | C2 | RECOVERED_PASS | preserve | recovery evidence remains an independent R3 trigger |
| 10 | C3 | INCONCLUSIVE | preserve | exploratory raw/identity/autoinit evidence only |

The raw values are not invalid. The invalidity is specifically their use as a primary causal-classification prefix to be pooled with future rows under a different estimator. No historical label is deleted or rewritten.

## Continuation impact

The halted R2 campaign must remain at 10/32. Do not execute sequence 11 or append any corrected-method row to its denominator. A post-hoc short-window overlay cannot create the missing prospective 20-second observations, and combining a retrospective rule with a prospective rule would confound method with campaign sequence/session.

If the Owner/Architect authorizes future work:

1. publish the prospective measurement amendment before DUT access;
2. validate it in a separately identified measurement-control experiment using a stable known video source, an independent timing reference, simultaneous FRAME/SAV/VCLK capture, phase-varied short windows, long-window OLS, and the finite no-video path;
3. retain sequences 1–10 outside every new primary denominator;
4. authorize a new full balanced causal campaign from its own sequence 1 only after control validation passes;
5. use one predeclared method uniformly from the first through last run;
6. re-establish Owner DUT exclusivity before any hardware action.

## R3 impact

`R3_STILL_REQUIRED`.

The frame artifact does not remove C2's observed recovery activity:

- sequence 6: REGADDR NACK/retry/recovered `1/1/1`;
- sequence 9: REGADDR NACK/retry/recovered `2/2/2`.

Those are frozen R3/recovery-review triggers independent of the frame estimator. R3 must not be started by this review and remains separately authorized work.

## Bias and integrity controls

Changing a clean gate after observing outcomes can create confirmation bias. Required controls for any new work are:

- one candidate-neutral rule;
- explicit Owner/Architect authorization;
- no deleted or overwritten data;
- one prospectively declared rule for every run in the new campaign;
- predeclared target and tolerance from independent mode authority;
- preserve the old campaign as exploratory evidence beside, but never pooled into, the new campaign;
- publication before any new hardware execution.

## Protocol-impact decision

`NEW_CONTROL_EXPERIMENT_REQUIRED`. The proposed amendment and control/new-campaign design require separate Owner/Architect authorization; this decision is not hardware authority.
