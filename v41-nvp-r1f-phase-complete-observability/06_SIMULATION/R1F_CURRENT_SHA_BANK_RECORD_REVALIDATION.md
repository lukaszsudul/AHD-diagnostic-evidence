# R1f current-SHA bank and record revalidation

## Scope and identity

This is an independent, read-only source revalidation of the final candidate
producer after extraction of the independent transaction-serial counter.  It
does not replace or rewrite the earlier audit; it closes that audit's source
hash freshness gap.

```text
AUDITED_PRODUCER=
    C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\rtl\nvp\nvp6134c_i2c_bringup.vhd

AUDITED_PRODUCER_SIZE_BYTES=
    85260

AUDITED_PRODUCER_SHA256=
    A2865C428B89E9492BB1D62144963558805B036F1A1212C09F968D6059AE9533

SERIAL_COUNTER=
    C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\rtl\nvp\r1f_transaction_serial_counter.vhd

FROZEN_BANK_INVARIANT_SPEC_SHA256=
    E3254621D904D7E52E702BE87AF2A691621661070F106758152F12CD9D6C1EE8

FROZEN_RECORD_SPEC_SHA256=
    F3D4B598C019432FB58CC2574D529F1051888BE166A2C55DA0AE1C569052E5A6

FROZEN_RECORD_CSV_SHA256=
    0088A8F90ED88E53DFCD300494BE369258D6E1B8C5C90525D297FA0B72BD948F

REFERENCE_BASE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

RTL_MUTATED_BY_THIS_AUDIT=
    NO
```

## Current-source findings

The separately instantiated serial counter is cleared only by reset/run clear,
increments once for each producer `transaction_start` pulse, exposes the
pre-increment current index and next index, and has no output connected to an
inherited functional-control input.  The producer snapshots the current
16-bit index at the inherited `START_W_A` command attempt and uses it only in
the new record and invariant diagnostics.

The current producer retains the explicit, kind-aware bank fields:

- original-bank discovery records requested bank invalid/zero;
- actual kinds 2 through 13 snapshot their exact requested/metadata bank;
- physical bank before, selector byte, verify expected byte, write byte and
  read byte are all validity-gated;
- effective physical bank after is calculated from the exact inherited cache
  update/invalidation semantics before the record is packed;
- read transactions never mark write data valid, and write transactions never
  mark read data valid.

Record-v1 bits `0..175` still match the frozen 192-bit specification.  Bits
`176..191` remain zero.  A record is emitted once at `STORE_RESULT` only when
the transaction has a phase NACK, timeout, or explicit terminal error.  The
phase-opportunity and phase-NACK bitmaps are accumulated in physical ACK order,
so multiple NACK phases remain one failed-transaction record.

All twelve frozen bank predicates are present.  Predicates 1 through 8 and 10
through 12 are evaluated at finalization; predicate 9 compares the scheduled
effective after-state with the inherited functional cache one cycle later.
The check count therefore advances by exactly twelve per completed
transaction.  Only `r1f_*` diagnostic state is assigned by these checks; no
counter, record field, first-error field, or serial output drives an inherited
state transition, branch decision, reset/power signal, or SCL/SDA release.

```text
R1F_REQUESTED_BANK_SEMANTICS=PASS_CURRENT_SHA_STATIC_AUDIT
R1F_RECORD_V1_SEMANTICS=PASS_CURRENT_SHA_STATIC_AUDIT
R1F_BANK_INVARIANT_12_PREDICATES=PASS_CURRENT_SHA_STATIC_AUDIT
R1F_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0_SOURCE_LEVEL
```

## Dynamic binding

The current producer/TB compile and run is:

```text
EVIDENCE=
    06_SIMULATION/r1f_autoinit_observability_scoreboard/final_matrix_v4/xsim.log

EVIDENCE_SHA256=
    EC8FA7BF2B49097B584658CE89869F37EDEED462A5DE5B81ECD2BF6F00847961

RESULT=
    PASS_STAGE6_G0P8C5D_AUTOINIT_SIMULATION
```

That run covers every transaction kind; isolated WADDR, REGADDR, DATA and
RADDR NACKs; a multi-phase failure; selector failure; verify mismatch and
transport failure; the operation-86-like legal transitional context; exact
13/15/36-event patterns; and legacy first-eight reconciliation.  All modeled
legal/all-ACK paths require zero invariant errors.  The stuck-SDA case is an
intentional negative detector test and must produce predicate-3 errors; it is
not a hardware-valid zero-error case.

The independently instantiated exact serial-counter RTL additionally proves
unique index 300 and run clear in
`06_SIMULATION/transaction_serial_16/xsim.log`.

## Verdict

```text
CURRENT_SHA_STATIC_BANK_RECORD_AUDIT=PASS
CURRENT_SHA_DYNAMIC_BANK_RECORD_MATRIX=PASS
TRANSACTION_INDEX_16_UNIQUE_AT_300=PASS
BANK_RECORD_SEMANTICS_BLOCKER=NONE
```

Any later producer or serial-counter source change invalidates this binding
and requires another read-only revalidation before the one clean build.
