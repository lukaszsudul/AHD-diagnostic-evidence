# R1f corrected bank-invariant and record-semantics superseding audit

## Scope and evidence identity

This is an independent, read-only static audit of the corrected R1f producer:

```text
AUDITED_FILE=
    C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY\rtl\nvp\nvp6134c_i2c_bringup.vhd

AUDITED_FILE_SIZE_BYTES=
    85076

AUDITED_VHDL_SHA256=
    A83E795BA38C76AF4445F8B5F443471C3D69211495DFF86968D04A726D556F9E

FROZEN_BANK_INVARIANT_SPEC_SHA256=
    E3254621D904D7E52E702BE87AF2A691621661070F106758152F12CD9D6C1EE8

FROZEN_RECORD_SPEC_SHA256=
    F3D4B598C019432FB58CC2574D529F1051888BE166A2C55DA0AE1C569052E5A6

FROZEN_RECORD_CSV_SHA256=
    0088A8F90ED88E53DFCD300494BE369258D6E1B8C5C90525D297FA0B72BD948F

REFERENCE_BASE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

VHDL_MUTATED_BY_THIS_AUDIT=
    NO
```

This document supersedes only the source-level conclusions in
`R1F_VHDL_RECORD_PRODUCER_SEMANTIC_AUDIT.md`, which audited the earlier VHDL
SHA-256 `239DCC...` and correctly blocked that earlier revision. The prior
audit remains preserved. Architecture, simulation, equivalence, logger
storage, and hardware-result evidence are not replaced by this audit.

## Overall source-level verdict

```text
R1F_REQUESTED_BANK_SEMANTICS=
    PASS_STATIC_SOURCE_AUDIT

R1F_RECORD_V1_SEMANTICS=
    PASS_STATIC_SOURCE_AUDIT

R1F_BANK_INVARIANT_12_PREDICATES=
    PASS_STATIC_SOURCE_AUDIT

FIRST_BANK_INVARIANT_ERROR_PACKING=
    PASS

BANK_INVARIANT_CHECKS_PER_COMPLETED_TRANSACTION=
    12

R1F_BANK_SEMANTIC_BLOCKER=
    NONE
```

This verdict means the corrected producer now implements the frozen semantic
contract at source level. It does not substitute for required simulation
scoreboards, structural fanout/equivalence proof, or the hardware-valid
requirement that the measured invariant error count equal zero.

## Requested-bank correction

`meta_bank_r` is explicitly documented as the requested/table/diagnostic bank,
while `phys_bank_r` is the last functionally proven physical bank (lines
195-200). At `START_W_A`, the corrected producer snapshots the requested bank
with kind-aware validity (lines 987-994):

- kind 1, `ORIGINAL_BANK_READ`, records requested bank invalid and byte zero;
- impossible/unused kind 0 is also invalid and zero;
- every actual kind 2 through 13 records the phase-specific `meta_bank_r` as a
  valid requested bank.

The setup assignments that precede the START-command state make those kind
2-through-13 values unambiguous:

| Kind | Transaction | Requested-bank source | Audit |
|---:|---|---|---|
| 1 | original bank read | discovery, not a request; invalid/zero | PASS |
| 2 | pre-init Bank-0 selector write | constant Bank 0 | PASS |
| 3 | pre-init Bank-0 verify read | constant Bank 0 | PASS |
| 4 | init selector write | exact pending table bank | PASS |
| 5 | init verify read | exact pending table bank | PASS |
| 6 | init target write | exact pending table bank | PASS |
| 7 | window bank write | constant Bank 0 | PASS |
| 8 | window register read | constant Bank 0 | PASS |
| 9 | output bank write | constant Bank 1 | PASS |
| 10 | output register read | constant Bank 1 | PASS |
| 11 | AFE bank write | exact formatted AFE bank | PASS |
| 12 | AFE register read | exact formatted AFE bank | PASS |
| 13 | restore bank write | preserved original-bank byte | PASS |

The restore transaction is issued only under the inherited authorization at
lines 900-914. Under the exact verified-table configuration it requires a
valid original readback; otherwise no I2C transaction starts. Consequently an
untrusted reset placeholder is not exposed as a valid requested bank.

The corrected behavior removes the earlier always-valid requested-bank
overclaim and prevents the overloaded-field ambiguity that motivated R1f.

## Transaction snapshot and record-v1 semantics

The private accumulator snapshots the following at the START-command attempt
(lines 922-1014):

- the pre-increment independent 16-bit transaction serial;
- exact init table slot or `0xFFFF` for a non-init transaction;
- phase, kind, legacy index, and kind-specific context;
- register and valid-gated write data;
- kind-aware requested bank;
- valid-gated physical bank before;
- valid-gated selector byte and verify-expected byte.

The source now explicitly defines this event as the inherited controller's
START-command attempt. A stuck-low SDA consumes one unique attempted-
transaction serial and is separately labeled terminal error `0x06` (lines
922-929). This resolves the wording ambiguity recorded by the prior audit
without changing functional flow.

At `STORE_RESULT`, local variables compute the effective bank state after the
transaction before record construction (lines 1254-1329). This avoids a stale
same-edge VHDL signal read. The cases match the inherited functional updates at
lines 1535-1635:

- successful original-bank read proves the observed bank;
- successful deferred selector write retains the previous proven bank with
  reason 9 pending verification;
- failed deferred selector write invalidates the cache with result 2/reason 5;
- successful verification proves the expected/observed bank with result
  1/reason 3;
- verify NACK or timeout invalidates with result 3/4 and reason 6;
- verify mismatch invalidates with result 5/reason 7 and terminal error
  `0x08`;
- successful direct selector and restore writes prove their selected byte with
  reason 2 or 4;
- unrelated reads and target writes retain the start snapshot with reason 0.

The 192-bit payload at lines 1340-1387 matches record version 1. It is first
zero-initialized, so reserved bits and invalid byte fields remain zero. Read,
selector, verify, before-bank, and after-bank bytes are copied only when their
validity conditions hold. Requested bank is gated by the corrected kind-aware
valid bit. The record is emitted atomically only for a phase NACK, timeout, or
separate terminal error (lines 1331-1351), with one record per failed
transaction.

## Frozen twelve-predicate audit

The corrected producer evaluates predicates 1-8 and 10-12 at finalization and
predicate 9 independently on the following clock after the inherited cache
update. `inv_checks_v := 11` at line 1395 plus the delayed predicate-9
increment at lines 617-619 gives exactly 12 checks per completed transaction.

| Code | Frozen predicate | Corrected implementation | Static result |
|---:|---|---|---|
| 1 | `TARGET_WRITE_REQUIRES_PROVEN_BANK` | Kind-6 target writes require valid/equal before/requested bank; only the exact compile-time direct-table mode is excepted (1399-1407). | PASS |
| 2 | `VERIFIED_SELECT_SUCCESS_AFTER_STATE` | PASS requires valid requested/expected/observed fields, equality, and valid/equal computed after state (1409-1419). | PASS |
| 3 | `SELECTOR_WRITE_FAILURE_INVALIDATES` | A failed deferred selector write may not retain a valid after cache (1421-1426). | PASS |
| 4 | `VERIFY_TRANSPORT_FAILURE_INVALIDATES` | Verify NACK or timeout may not retain a valid after cache (1428-1433). | PASS |
| 5 | `VERIFY_MISMATCH_INVALIDATES` | Result-5 mismatch may not retain a valid after cache (1435-1438). | PASS |
| 6 | `READ_WRITE_DATA_VALIDITY` | Reads reject valid write data; writes reject valid read data (1440-1444). | PASS |
| 7 | `SELECTOR_REQUEST_EXPECTED_AGREE` | Valid selector/request and expected/request pairs must agree and selector register must be `0xFF` (1446-1455). | PASS |
| 8 | `BANK_BEFORE_SNAPSHOT_MATCHES_FUNCTIONAL_CACHE` | Start validity and, when valid, byte are compared to the inherited pre-update cache (1457-1462). | PASS |
| 9 | `BANK_AFTER_SNAPSHOT_MATCHES_EFFECTIVE_UPDATE` | Computed after state is latched at 1514-1519 and compared one clock later with the actual inherited cache at 613-631. | PASS |
| 10 | `DIRECT_WRITE_EXCEPTION_EXACT` | A mismatched/unproven kind-6 write is accepted only for `ENABLE_MAREK_INIT_TABLE=0` in `PH_INIT`; the exact R1f configuration defaults to verified-table mode 1 (1464-1473). The build generic plus kind/phase record context identify the narrow exception; no broader runtime exception exists. | PASS |
| 11 | `VALID_BITS_CONTROL_INTERPRETATION` | Invalid requested/before/selector/expected/write/after bytes must be zero (1475-1488); record construction conditionally copies read/verify/after bytes (1352-1380). | PASS |
| 12 | `TABLE_SLOT_CONTEXT_COHERENT` | Kinds 4/5/6 require `PH_INIT` and the exact live slot; all other kinds require `0xFFFF` (1490-1500). | PASS |

The source-level checks are passive: they read inherited state and local
diagnostic snapshots and update only diagnostic counters/first-error outputs.
This audit found no invariant output used as a functional branch input.
Required full structural fanout proof remains a separate pre-build gate.

## First-invariant-error protocol

Both error paths use the frozen 32-bit layout:

```text
bit 31       valid = 1
bits 30:24   seven-bit predicate code
bits 23:8    authoritative transaction index
bits 7:4     transaction kind
bits 3:0     high-level phase
```

Predicate 9 packs this at lines 625-628. Predicates 1-8 and 10-12 pack the
first false code at lines 1504-1511. Codes `1..12` fit in seven bits, and the
sticky first-error word is written only while the accumulated error count is
zero. This corrects the prior incompatible packing.

## Important limits of this audit

The following still require their separately mandated evidence and are not
claimed merely from source inspection:

- dynamic evaluation of all legal and contradiction cases;
- check-count and error-count scoreboards;
- downstream capacity-64 chronological/immutable storage behavior;
- legacy first-eight byte identity and reconciliation;
- pre-init cycle equivalence and diagnostic-to-functional fanout zero;
- hardware `BANK_TRACKER_INVARIANT_ERROR_COUNT=0`.

No source-level bank/requested-bank/record semantic blocker remains in the
audited VHDL revision.

```text
AUDIT_CLASSIFICATION=
    PASS_CORRECTED_REQUESTED_BANK_RECORD_AND_12_PREDICATE_SOURCE_SEMANTICS

SUPERSEDES_PRIOR_SOURCE_BLOCKERS=
    YES_FOR_AUDITED_SHA_A83E795B_ONLY

SOURCE_EDIT_PERFORMED=
    NO

NEXT_REQUIRED_GATE=
    EXISTING_DYNAMIC_SCOREBOARDS_EQUIVALENCE_AND_HARDWARE_ZERO_ERROR_PROOF
```
