# R1f failed-log, bank-state, and reconciliation semantics

## Architectural boundary

The R1f logger, phase counters, transaction serial, bank snapshots, and
invariant counters are observers. Their outputs may feed only the read-only
R1f register plane and verification assertions.

```text
R1F_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0_REQUIRED
LEGACY_CONTROL_FLOW_CHANGED=NO
LEGACY_FIRST8_LOG_CHANGED=NO
FUNCTIONAL_BANK_CACHE_CHANGED=NO
```

The logger observes the exact R1e functional state; it does not replace the
legacy `op_idx`, table `slot_idx`, ACK decisions, bank cache, I2C bytes, state
transitions, or branch decisions.

## Transaction accumulator

One private accumulator is cleared and initialized on each actual I2C START.
It latches:

- pre-increment 16-bit transaction serial;
- exact 16-bit table slot or `0xFFFF`;
- high-level phase and transaction kind;
- register, write byte, and all validity bits applicable to the selected kind;
- requested bank and validity;
- physical bank before and validity;
- selector and bank-verify metadata and validity;
- phase opportunity and NACK bitmaps, initially zero;
- timeout and terminal error, initially zero.

Every physically reached ACK sample performs these observer updates in this
order:

1. set the phase opportunity bit;
2. increment the matching 32-bit saturating opportunity counter;
3. evaluate the exact existing ACK sample;
4. on NACK, set the phase NACK bit and increment the matching 32-bit
   saturating phase-NACK counter.

The observer must consume the same sampled ACK value as the functional FSM.
It must not add a synchronizer, filter, sample point, or timing decision.

At transaction result storage, effective physical-bank-after state is computed
from the exact inherited update/invalidation rule. When the transaction has a
phase NACK, timeout, or separate terminal diagnostic error, one complete
192-bit record is appended atomically.

## Phase and transaction counters

All required aggregate counters are 32-bit unsigned saturating counters.
Saturation is sticky and invalidates a scientific sample even though wrap is
prevented.

```text
AUTOINIT_WADDR_ACK_OPPORTUNITIES
AUTOINIT_WADDR_NACKS
AUTOINIT_REGADDR_ACK_OPPORTUNITIES
AUTOINIT_REGADDR_NACKS
AUTOINIT_DATA_ACK_OPPORTUNITIES
AUTOINIT_DATA_NACKS
AUTOINIT_RADDR_ACK_OPPORTUNITIES
AUTOINIT_RADDR_NACKS
AUTOINIT_TRANSACTION_STARTS
AUTOINIT_TRANSACTION_COMPLETIONS
AUTOINIT_FAILED_TRANSACTIONS
AUTOINIT_TIMEOUT_TRANSACTIONS
```

`AUTOINIT_FAILED_TRANSACTIONS` counts a transaction once when it contains one
or more NACK phases, a timeout, or a separately classified terminal failure.
`AUTOINIT_TIMEOUT_TRANSACTIONS` is its timeout-bearing subset. A transaction
with three phase NACKs contributes three to the phase-NACK sum but only one to
the failed-transaction count and one stored log entry.

Required live invariants are:

```text
phase_nacks <= phase_opportunities for all four phases
sum(WADDR_NACKS, REGADDR_NACKS, DATA_NACKS, RADDR_NACKS) == legacy NACK_COUNT
AUTOINIT_FAILED_TRANSACTIONS == R1F_FAILED_TXN_TOTAL_COUNT
AUTOINIT_TRANSACTION_COMPLETIONS <= AUTOINIT_TRANSACTION_STARTS
AUTOINIT_TIMEOUT_TRANSACTIONS <= AUTOINIT_FAILED_TRANSACTIONS
no counter saturation
```

An opportunity is not counted when an earlier failure prevents the FSM from
reaching that phase's ACK sample.

## Capacity-64 append-only log

The following counters are exposed as zero-extended 32-bit register words:

```text
R1F_FAILED_TXN_TOTAL_COUNT       32-bit saturating
R1F_FAILED_TXN_STORED_COUNT      range 0..64
R1F_FAILED_TXN_OVERFLOW          one sticky bit
R1F_FIRST_FAILED_TXN_INDEX       16-bit plus explicit valid status
R1F_LAST_FAILED_TXN_INDEX        16-bit plus explicit valid status
```

Append behavior is exact:

- failed transactions 1 through 64 are written chronologically to entries 0
  through 63;
- each written 192-bit entry becomes immutable;
- the 65th failed transaction increments total count and sets overflow, but
  writes no entry and changes none of entries 0..63;
- subsequent failed transactions continue incrementing total count while
  stored count remains 64 and overflow remains one;
- overflow is zero for exactly 64 failed transactions and becomes one only on
  processing failure number 65;
- all six words of all unused entries are zero;
- first/last index validity is carried by log-status bits, so transaction
  serial zero is not confused with no failure.

Hardware-valid R1f samples require overflow zero. Historical 13-, 15-, and
36-event patterns are below capacity and therefore retain all failed
transactions.

## Explicit bank-state snapshot semantics

The record distinguishes every formerly overloaded bank meaning:

- `requested_bank`: logical metadata/table target for this transaction;
- `physical_bank_before`: last functionally proven bank before actual START;
- `selector_value_sent`: byte actually sent to `0xFF`;
- `bank_verify_expected`: value that a selector verification must return;
- `bank_verify_observed`: value physically received by that verification;
- `physical_bank_after`: effective functional cache state after the
  transaction's update/invalidation rule;
- `bank_verify_result`: why verification passed, failed, or was not applicable;
- `bank_update_reason`: why after-state changed, stayed deferred, or became
  invalid.

Every byte above has an explicit validity bit, except the result/reason enums,
which have `NOT_APPLICABLE`/`NO_CHANGE` encodings. A host decoder must render
an invalid byte as `null`, never as bank zero.

For the exact verified-selection sequence, a successful selector write with
deferred update can legally retain the previous proven physical bank until a
matching verify read succeeds. This is `bank_update_reason =
DEFERRED_PENDING_VERIFY_NO_CHANGE`, not tracker corruption. A failed selector
write, failed verify transport, or verify mismatch invalidates the cache as
the inherited source requires.

## Passive bank invariant counters

```text
BANK_TRACKER_INVARIANT_CHECK_COUNT       32-bit saturating
BANK_TRACKER_INVARIANT_ERROR_COUNT       32-bit saturating
FIRST_BANK_TRACKER_INVARIANT_ERROR       packed word below
```

The check count increments once per predicate evaluation. The error count
increments once for each false evaluated predicate; more than one predicate
may fail in one transaction. The first-error word is sticky:

| Bits | Field |
|---:|---|
| 31 | valid |
| 30:24 | invariant error code |
| 23:8 | authoritative transaction index |
| 7:4 | transaction kind |
| 3:0 | high-level phase |

Required predicate/error codes are:

| Code | Predicate evaluated at the stated event |
|---:|---|
| 1 | `TARGET_WRITE_REQUIRES_PROVEN_BANK`: an init target write may start only when physical-bank-before is valid and equals requested bank, except an exact source-authorized direct-write mode explicitly tagged in context. |
| 2 | `VERIFIED_SELECT_SUCCESS_AFTER_STATE`: successful verify ends with physical-bank-after valid and equal to requested/expected/observed bank. |
| 3 | `SELECTOR_WRITE_FAILURE_INVALIDATES`: a failed deferred selector write ends with physical-bank-after invalid. |
| 4 | `VERIFY_TRANSPORT_FAILURE_INVALIDATES`: verify NACK/timeout ends with physical-bank-after invalid. |
| 5 | `VERIFY_MISMATCH_INVALIDATES`: an ACKed mismatching verify byte ends with physical-bank-after invalid. |
| 6 | `READ_WRITE_DATA_VALIDITY`: read transactions have write-data-valid zero; write transactions have read-data-valid zero unless a separately represented verify read supplies it. |
| 7 | `SELECTOR_REQUEST_EXPECTED_AGREE`: whenever valid for a verified selection, selector value, requested bank, and expected verify byte are equal. |
| 8 | `BANK_BEFORE_SNAPSHOT_MATCHES_FUNCTIONAL_CACHE`: start snapshot exactly matches the functional cache and validity. |
| 9 | `BANK_AFTER_SNAPSHOT_MATCHES_EFFECTIVE_UPDATE`: finalized after-state exactly matches the inherited functional cache next state. |
| 10 | `DIRECT_WRITE_EXCEPTION_EXACT`: a target write without a proven matching bank is accepted only in the exact inherited direct-write mode and is labeled as such; no broader exception is allowed. |
| 11 | `VALID_BITS_CONTROL_INTERPRETATION`: selector/verify/read/write values are consumed by invariant logic only when their validity bits are one. |
| 12 | `TABLE_SLOT_CONTEXT_COHERENT`: init kinds carry the current exact slot and non-init kinds carry `0xFFFF`. |

The invariant logic compares signals but drives none of them. Simulation must
also perform a structural fanout audit proving the counters and first-error
word have no path into functional state, SCL/SDA release, reset, power, or
branch decisions.

Any nonzero hardware invariant error count is
`BANK_TRACKER_COHERENCE=CONTRADICTION_MEASURED`; it is not permission for an
automatic source correction.

## Legacy first-eight reconciliation

The inherited 8 x 64-bit per-NACK log remains byte-identical. It can contain
multiple entries for one R1f failed-transaction record because it records one
entry per NACK phase.

For reconciliation, expand valid R1f records in ascending transaction index
and, within each transaction, in physical ACK order:

```text
WADDR -> REGADDR -> (DATA for writes | RADDR for reads)
```

The first eight expanded NACK events must match the eight legacy entries in
order. Compare:

- low eight bits of transaction's legacy operation field;
- corresponding phase code (`0x01`, `0x02`, `0x03`, `0x04`);
- register address when valid;
- write data only when valid (the inherited read placeholder is not
  reinterpreted);
- requested/metadata bank when valid;
- physical-bank-before only when the R1f and legacy physical-valid semantics
  both make it valid.

No invalid R1f field is compared to an overloaded legacy byte. Every legacy
event must be explained by exactly one expanded R1f transaction/phase event,
and no expanded event among the chronological first eight may be absent from
the legacy log.

```text
LEGACY_FIRST8_RECONCILIATION=PASS_REQUIRED
LEGACY_OPERATION_INDEX_AUTHORITATIVE=NO
R1F_TRANSACTION_INDEX_16_AUTHORITATIVE=YES
```

## Assertions required before build

At minimum, simulation/formal checks must prove:

```text
no diagnostic signal has functional fanout
serial increments exactly once per actual START
serial remains unique through index 300 and every modeled sequence
table slot is exact or 0xFFFF by kind
opportunity/NACK scoreboards match all four phase counters
one record per failed/timed-out transaction
multi-phase NACK transaction creates one bitmap record
entries are chronological and immutable
64 failures: stored=64, overflow=0
65 failures: stored=64, overflow=1, entries unchanged
unused records are all zero
bank before/after and validity match the exact functional cache
all bank invariants pass in legal transitional contexts
all required contradictions increment invariant errors
legacy first-eight bytes remain reference-identical
legacy-to-R1f reconciliation passes
```

