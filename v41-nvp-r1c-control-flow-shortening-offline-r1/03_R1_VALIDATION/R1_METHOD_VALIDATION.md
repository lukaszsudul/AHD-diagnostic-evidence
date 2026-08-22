# Historical R1 shortening-method validation

## Result

```text
R1_METHOD_VALIDATION=
    PASS_61_TICKS_WITH_MINUS_1_CYCLE_EDGE_RESIDUAL

R1_OMITTED_TRANSACTION_INTERPRETATION=
    R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS
```

The method is valid for the aggregate counter-derived net control-flow
shortening. It is not sufficient to assign a unique number of effective NACK
events, skipped transactions, or skipped table entries without the ordered
NACK/path record.

## Arithmetic

```text
EXPECTED_CNT_AT_INIT_DONE=113182679
ACTUAL_CNT_AT_INIT_DONE=113144494

SIGNED_COUNT_ERROR_CYCLES=
    113144494 - 113182679
    = -38185

CONTROL_FLOW_SHORTENING_CYCLES=
    113182679 - 113144494
    = 38185

TICK_CYCLES=
    DIVIDER + 1
    = 625 + 1
    = 626

CONTROL_FLOW_SHORTENING_TICKS_EXACT=
    38185 / 626
    = 60.9984025559105

CONTROL_FLOW_SHORTENING_TICKS_NEAREST=61

RESIDUAL_CYCLES=
    38185 - (61 * 626)
    = -1
```

## One-cycle residual review

The exact lifecycle monitor increments its 48-bit counter and captures the
pre-increment `counter` value when it samples `nvp_init_done`. The preserved
expected model uses that same next-edge/pre-increment capture convention and
therefore expects `113182679`.  The separately documented wrapper-high edge
at `113182680` is not substituted into the counter comparison.

Using the like-for-like authoritative expectation leaves the reported `-1`
cycle residual after rounding to 61 state ticks.  It is consistent with a
single base-clock model/observer boundary difference, but the retained
evidence does not uniquely attribute that cycle.  No tolerance or approximate
scaling is introduced, and the mixed wrapper-high comparison is not used to
claim exact reconciliation.

## What is and is not validated

Validated:

- T0 and T1 contain the same measured `CNT_AT_INIT_DONE`.
- The deficit is nearest to 61 complete state ticks.
- The exact 50-kHz tick spacing is 626 FPGA clocks.
- The first recorded NACK is a path-neutral slot-0 target-write NACK.
- Exact FSM replay has at least two different skipped-operation histories with
  the same 61-tick net shortening and raw NACK count 19.

Not uniquely available:

- number of control-flow-effective NACK events;
- number of skipped I2C transactions;
- number of skipped table entries;
- identity of the later branch-changing NACKs.

This validation is offline. It ran no HDL simulation, build, hardware access,
MMIO, DMA, source edit, or repository mutation.
