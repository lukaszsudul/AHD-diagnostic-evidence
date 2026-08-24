# R1f VHDL failed-transaction producer semantic audit

## Audit identity and scope

This is a read-only audit of the root-owned instrumentation in:

```text
C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\
rtl\nvp\nvp6134c_i2c_bringup.vhd

AUDITED_SHA256=
239DCC664B9B622C9A21D14ED4D571531F42D6E852C88CBBC34AE542C93FE37D

REFERENCE_BASE_COMMIT=
f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd
```

No VHDL source was changed by this audit. The comparison shows 484 inserted
lines and one replaced entity-port terminator relative to the exact R1e base;
the added `r1f_*` signals have no observed fanout into inherited state, branch,
byte, bank-cache, SCL/SDA, reset, or timing decisions.

## Overall verdict

```text
R1F_RECORD_BIT_MAPPING=PASS
R1F_PHASE_OPPORTUNITY_AND_NACK_ACCUMULATION=PASS
R1F_TRANSACTION_FINALIZATION=PASS
R1F_TIMEOUT_INCLUSION=PASS
R1F_VERIFY_MISMATCH_INCLUSION=PASS
R1F_EFFECTIVE_BANK_AFTER_SEMANTICS=PASS
R1F_RESERVED_ZERO_BITS=PASS
R1F_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0_STATIC_AUDIT

R1F_FIRST_BANK_INVARIANT_ERROR_PACKING=FAIL
R1F_BANK_INVARIANT_PREDICATE_SET=FAIL_VERSUS_FROZEN_SPEC
R1F_REQUESTED_BANK_VALIDITY=FAIL_UNAMBIGUOUS_SEMANTICS
R1F_PHYSICAL_START_WORDING=REQUIRES_EXPLICIT_ATTEMPT_SEMANTICS_OR_DELTA

R1F_VHDL_PRODUCER_READY_FOR_INTEGRATION_BUILD=NO
```

## Passing findings

### Exact 192-bit allocation

The assignments at result finalization match record version 1:

| Record bits | Producer field | Audit |
|---:|---|---|
| 15:0 | independent transaction index | PASS |
| 31:16 | exact table slot or `0xffff` | PASS |
| 39:32 | legacy 8-bit operation field | PASS |
| 43:40 | inherited phase enumeration | PASS |
| 47:44 | transaction-kind enumeration | PASS |
| 51:48 | WADDR/REGADDR/DATA/RADDR opportunity bitmap | PASS |
| 55:52 | matching phase-NACK bitmap | PASS |
| 58:56 | bitmap population count | PASS |
| 59 | transaction timeout | PASS |
| 60 | normal `STORE_RESULT` completion | PASS |
| 61 | atomic record-valid bit | PASS |
| 63:62 | reserved zero | PASS |
| 71:64 | register byte | PASS |
| 79:72 | write byte gated by bit 89 | PASS |
| 87:80 | read byte gated by bit 90 | PASS |
| 95:88 | all eight data/bank validity bits | PASS, except requested-bank semantics below |
| 103:96 | requested/metadata bank | PASS encoding; validity gap below |
| 111:104 | physical bank before | PASS |
| 119:112 | selector byte | PASS |
| 127:120 | verify expected | PASS |
| 135:128 | verify observed | PASS |
| 143:136 | physical bank after | PASS |
| 144 | physical-bank-after valid | PASS |
| 147:145 | bank-verify result | PASS |
| 151:148 | bank-update reason | PASS |
| 159:152 | finalization FSM state | PASS |
| 167:160 | kind-specific context | PASS |
| 175:168 | terminal error | PASS |
| 191:176 | reserved zero | PASS |

The record variable begins as all zero, and every invalid byte field except the
requested-bank issue below remains zero. This enforces reserved-zero and
valid-bit-gated byte encoding.

### Transaction identity and accumulation

At `START_W_A`, the producer snapshots the pre-increment 16-bit serial, exact
slot/kind/phase/context, register and data semantics, requested bank, physical
bank before, selector, and verify expectation. It increments the serial once
and increments the saturating start counter once. NOP and delay entries never
reach `START_W_A`, so they consume no serial.

The first transaction is index zero; values above 255 are independent of the
legacy saturating 8-bit operation field. Serial overflow is sticky when index
`0xffff` is consumed. A hardware-valid sample must reject that condition before
the next value can alias zero.

Each physical ACK-sampling state independently increments its 32-bit
saturating opportunity counter and sets its accumulator bit. A NACK in that
same state increments the phase NACK counter, sets the NACK bit, and increments
the three-bit per-transaction NACK count. The inherited FSM can deliberately
continue to later ACK states after an earlier NACK; those later opportunities
are correctly counted because they are physically reached.

### Finalization and failure inclusion

`STORE_RESULT` increments the completion counter once. It appends exactly one
record when any phase NACK exists, the per-transaction SCL-timeout flag is set,
or a separate terminal error is nonzero. Thus:

- multiple phase NACKs remain one failed transaction with a bitmap;
- timeouts are included and counted in the timeout subset;
- a bank-verify value mismatch is included with verify-result 5 and terminal
  error `0x08`, even when the NACK bitmap is zero;
- a stuck-low SDA diagnosis is included with terminal error `0x06` unless the
  higher-priority timeout class `0x07` is also present;
- the valid pulse is one clock wide and the complete 192-bit payload is stable
  for the downstream logger sampling edge.

### Bank before/after semantics

The physical-bank-before value and validity are sampled at transaction start.
At finalization, local variables compute the inherited effective next cache
state rather than reading a stale same-edge signal value. The audited cases
match the inherited updates:

- successful original-bank read proves the observed bank;
- successful deferred selector write retains the last proven bank pending
  verify and reports reason 9;
- failed deferred selector write invalidates and reports result 2/reason 5;
- successful selector verification proves the expected/observed bank and
  reports result 1/reason 3;
- verify NACK or timeout invalidates and reports result 3/4 with reason 6;
- verify mismatch invalidates and reports result 5/reason 7;
- successful direct selector or restore write updates according to the exact
  inherited rule and reports reason 2 or 4;
- unrelated target/read transactions retain the before state with no-change
  reason.

## Blocking mismatch: first invariant-error word

The frozen specification requires:

```text
bit 31       valid
bits 30:24   invariant error code
bits 23:8    authoritative transaction index
bits 7:4     transaction kind
bits 3:0     high-level phase
```

The current producer instead concatenates:

```text
error_code[7:0] & transaction_kind[3:0] & 4'b0000 & transaction_index[15:0]
```

This places error code in bits 31:24, kind in 23:20, zeros in 19:16, and the
index in 15:0. It omits phase. Because implemented codes are `0x01..0x0a`, bit
31 is zero, so a decoder following the frozen contract sees the first-error
word as invalid even when the error count is nonzero.

```text
CLASSIFICATION=BLOCKED_FIRST_BANK_INVARIANT_ERROR_PROTOCOL
SOURCE_LOCATION=nvp6134c_i2c_bringup.vhd:1395
```

## Blocking mismatch: invariant predicate/code contract

The frozen evidence defines 12 bank-invariant predicates and stable codes. The
producer unconditionally adds 10 checks per transaction and uses a different
code table:

1. NACK bitmap subset of opportunity bitmap;
2. NACK population-count match;
3. transaction kind nonzero;
4. init target-write bank prerequisite;
5. successful verify after-state;
6. selector register/request agreement;
7. verify expected/request agreement;
8. read transaction has no write-data-valid;
9. selected failed selector/verify kinds have invalid after-state;
10. verify-pass valid/observed agreement.

The first three are useful record-protocol checks, but they are not the frozen
bank-invariant code table. The current implementation does not independently
cover or identify all required predicates, including:

- write transactions must have read-data-valid zero;
- bank-before snapshot must equal the inherited functional cache at start;
- bank-after snapshot must equal the inherited effective next cache for every
  kind, not only selected success/failure cases;
- the direct-write exception must be exact and explicitly labeled;
- invalid diagnostic bytes must never be interpreted;
- init/non-init table-slot context must be coherent.

Combining selector-write failure, verify transport failure, and verify mismatch
under current code 9 also prevents the predeclared classifications from being
decoded independently.

```text
CLASSIFICATION=BLOCKED_BANK_INVARIANT_CONTRACT_NOT_IMPLEMENTED
SOURCE_LOCATION=nvp6134c_i2c_bringup.vhd:1332
```

## Semantic gap: requested-bank validity

At every start the producer assigns the inherited `meta_bank_r` byte and forces
`requested_bank_valid=1`. For `ORIGINAL_BANK_READ`, there is no requested target
bank; `meta_bank_r` is merely the reset placeholder. It must not be presented
as a known requested bank. A restore attempted without a proven original-bank
readback has the same risk in any exact source mode that permits that path.

The producer must either make the validity kind/knowledge-aware or freeze an
explicit alternate semantic definition before build. Leaving the current
always-valid bit would reintroduce the overloaded-field ambiguity R1f is
designed to remove.

```text
CLASSIFICATION=BLOCKED_REQUESTED_BANK_VALIDITY_OVERCLAIM
SOURCE_LOCATION=nvp6134c_i2c_bringup.vhd:937
```

## Contract ambiguity: commanded start versus physical START edge

The serial and start counter increment when the controller enters `START_W_A`.
Normally that edge drives SDA from released high to low while SCL is released,
which is the physical I2C START. If SDA was already low, however, no physical
high-to-low START edge exists; the producer still consumes a serial and marks
terminal error `0x06`.

This is coherent if the authoritative term is “transaction attempt at the
START-command edge.” It is not literally coherent with “increments once per
actual physical I2C transaction start” in the stuck-SDA path. The contract must
be made explicit or the diagnostic event rule must be adjusted without
changing inherited control flow.

```text
CLASSIFICATION=START_EVENT_SEMANTICS_REQUIRES_FREEZE
SOURCE_LOCATION=nvp6134c_i2c_bringup.vhd:875
```

## Required disposition before build

```text
1. Correct FIRST_BANK_TRACKER_INVARIANT_ERROR packing.
2. Implement the frozen invariant predicate/code contract or revise the frozen
   evidence before it is consumed elsewhere; no silent divergence.
3. Make requested-bank validity semantically truthful for original/unknown
   contexts.
4. Freeze commanded-attempt versus physical-START serial semantics.
5. Re-run focused producer scoreboards after the root-owned changes.
```

No functional source correction is implied. Each required change can remain a
diagnostic-only producer/contract correction with zero fanout to inherited
control.
