# R1f failed-transaction record format, version 1

## Decision

The required record is implementable in exactly six little-endian 32-bit
words. The allocation below uses 174 of the 192 bits and reserves 18 bits as
zero. No required field or required validity indication is omitted.

```text
R1F_FAILED_TXN_RECORD_WIDTH_BITS=192
R1F_FAILED_TXN_RECORD_WORDS=6
R1F_FAILED_TXN_RECORD_VERSION=1
R1F_FAILED_TXN_LOG_CAPACITY=64
REQUIRED_FIELDS_FIT=PASS_174_USED_18_RESERVED_ZERO
WIDTH_IMPOSSIBILITY=NO
```

This specification was derived against the exact R1e source at commit
`f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`, tree
`db8b5581a237e19905fd01c6d453793047bc3ba7`. The source was inspected
read-only. In particular:

- `rtl/nvp/nvp6134c_i2c_bringup.vhd` defines nine high-level phases, the
  functional transaction contexts, the four ACK sampling phases, the legacy
  eight-record logger, and the physical-bank cache;
- the legacy record samples an 8-bit conversion of `op_idx`, phase code,
  register, `write_data`, physical bank, metadata bank, and physical-bank
  validity at each NACK;
- R1f does not reinterpret those overloaded fields. It builds a separate
  transaction accumulator and finalizes one new record per failed or timed-out
  I2C transaction.

## Byte and word order

The AXI-Lite register plane is little-endian and DWORD-aligned. For record
number `r` in `0..63`:

```text
record_base(r) = 0x2400 + r * 0x18
word_address(r,w) = record_base(r) + w * 4, w in 0..5
```

Word 0 is at the lowest address. Within a word, bit 0 is the least
significant bit returned by a 32-bit AXI-Lite read.

## Exact bit allocation

| Word | Bits | Width | Field | Encoding and validity |
|---:|---:|---:|---|---|
| 0 | 15:0 | 16 | `transaction_index_16` | Authoritative independent transaction serial. |
| 0 | 31:16 | 16 | `table_slot_index_16` | Exact init-table slot, or `0xFFFF` when not applicable. |
| 1 | 7:0 | 8 | `legacy_operation_index_8` | Compatibility label only; never authoritative above 255. |
| 1 | 11:8 | 4 | `autoinit_phase` | Enumeration below. |
| 1 | 15:12 | 4 | `transaction_kind` | Enumeration below. |
| 1 | 19:16 | 4 | `phase_opportunity_bitmap` | Bit 0 WADDR, bit 1 REGADDR, bit 2 DATA, bit 3 RADDR. A bit is set only if that ACK sample was physically reached. |
| 1 | 23:20 | 4 | `phase_nack_bitmap` | Same phase order. Must be a subset of the opportunity bitmap. |
| 1 | 26:24 | 3 | `nack_count_within_transaction` | Exact population count of `phase_nack_bitmap`, range 0..4. |
| 1 | 27 | 1 | `timeout_flag` | At least one timeout occurred during this transaction. |
| 1 | 28 | 1 | `transaction_completed` | Normal transaction finalization reached `STORE_RESULT`; zero is retained for a future synthetic timeout-finalization path. |
| 1 | 29 | 1 | `record_valid` | Set only by the atomic final record write. Unused entries are entirely zero. |
| 1 | 31:30 | 2 | reserved | Must read zero. |
| 2 | 7:0 | 8 | `register_address` | Interpret only when `register_address_valid=1`. |
| 2 | 15:8 | 8 | `write_data` | Interpret only when `write_data_valid=1`. |
| 2 | 23:16 | 8 | `read_data` | Interpret only when `read_data_valid=1`. |
| 2 | 24 | 1 | `register_address_valid` | Explicitly disambiguates transaction kinds with no register byte. |
| 2 | 25 | 1 | `write_data_valid` | Must be zero for reads and for address/register-only transactions. |
| 2 | 26 | 1 | `read_data_valid` | Set only if a read byte was physically sampled and is semantically usable. |
| 2 | 27 | 1 | `requested_bank_valid` | Gates `requested_bank`. |
| 2 | 28 | 1 | `physical_bank_before_valid` | Gates `physical_bank_before`. |
| 2 | 29 | 1 | `selector_value_valid` | Gates `selector_value_sent`. |
| 2 | 30 | 1 | `bank_verify_expected_valid` | Gates `bank_verify_expected`. |
| 2 | 31 | 1 | `bank_verify_observed_valid` | Gates `bank_verify_observed`. |
| 3 | 7:0 | 8 | `requested_bank` | Requested/metadata target bank at transaction start. |
| 3 | 15:8 | 8 | `physical_bank_before` | Last proven physical bank, sampled at actual transaction start. |
| 3 | 23:16 | 8 | `selector_value_sent` | Byte actually sent to register `0xFF`, if applicable. |
| 3 | 31:24 | 8 | `bank_verify_expected` | Expected selector readback, if applicable. |
| 4 | 7:0 | 8 | `bank_verify_observed` | Observed selector readback, if applicable. |
| 4 | 15:8 | 8 | `physical_bank_after` | Effective cache state after applying this transaction's exact update/invalidation rule. |
| 4 | 16 | 1 | `physical_bank_after_valid` | Gates `physical_bank_after`. |
| 4 | 19:17 | 3 | `bank_verify_result` | Enumeration below. |
| 4 | 23:20 | 4 | `bank_update_reason` | Enumeration below. |
| 4 | 31:24 | 8 | `fsm_state` | Exact `t_state'pos(state)` at failure finalization. |
| 5 | 7:0 | 8 | `fsm_context` | Context index described below. |
| 5 | 15:8 | 8 | `terminal_error_code` | Exact diagnostic error class; zero means no separate terminal error beyond phase NACK bits. |
| 5 | 31:16 | 16 | reserved | Must read zero. |

The CSV beside this document is the machine-readable form of the same
allocation.

## Phase enumeration

The four-bit `autoinit_phase` is the exact position of the inherited R1e
`t_phase` value:

| Value | Name |
|---:|---|
| 0 | `PH_ORIGINAL` |
| 1 | `PH_INIT` |
| 2 | `PH_WIN_BANK` |
| 3 | `PH_WIN_READ` |
| 4 | `PH_OUT_BANK` |
| 5 | `PH_OUT_READ` |
| 6 | `PH_AFE_BANK` |
| 7 | `PH_AFE_READ` |
| 8 | `PH_RESTORE` |
| 9..15 | reserved; decoder must reject a valid record using these values |

## Transaction-kind enumeration

Four bits cover every I2C transaction kind in the exact R1e sequence and
leave two encodings reserved.

| Value | Name | Table slot |
|---:|---|---|
| 0 | `INVALID_UNUSED` | `0xFFFF` |
| 1 | `ORIGINAL_BANK_READ` | `0xFFFF` |
| 2 | `PREINIT_BANK_SELECT_WRITE` | `0xFFFF` |
| 3 | `PREINIT_BANK_VERIFY_READ` | `0xFFFF` |
| 4 | `INIT_BANK_SELECT_WRITE` | exact current table slot |
| 5 | `INIT_BANK_VERIFY_READ` | exact current table slot |
| 6 | `INIT_TARGET_WRITE` | exact current table slot |
| 7 | `WINDOW_BANK_WRITE` | `0xFFFF` |
| 8 | `WINDOW_REGISTER_READ` | `0xFFFF` |
| 9 | `OUTPUT_BANK_WRITE` | `0xFFFF` |
| 10 | `OUTPUT_REGISTER_READ` | `0xFFFF` |
| 11 | `AFE_BANK_WRITE` | `0xFFFF` |
| 12 | `AFE_REGISTER_READ` | `0xFFFF` |
| 13 | `RESTORE_BANK_WRITE` | `0xFFFF` |
| 14..15 | reserved; decoder must reject a valid record using these values |

NOP and delay table slots do not start an I2C transaction and therefore do
not consume a transaction serial and cannot create a failed-transaction
record.

## FSM context

`fsm_state` records the exact inherited state enumeration position. The
current R1e state enumeration has 35 values and therefore fits in eight bits
without conversion loss. `fsm_context` supplies the context whose meaning is
selected by `transaction_kind`:

- init bank-select, bank-verify, and target-write: low eight bits of the exact
  table slot, while the full authoritative slot remains in word 0;
- window read: `result_idx`;
- output read: `out_idx`;
- AFE bank/read: `afe_idx`;
- pre-init kinds: exact `t_preinit_action'pos`;
- restore and contexts without a secondary index: zero.

The decoder must not use `fsm_context` as a transaction identifier.

## Bank-verify result enumeration

| Value | Meaning |
|---:|---|
| 0 | `NOT_APPLICABLE` |
| 1 | `PASS_MATCHED` |
| 2 | `WRITE_NACK_OR_EARLIER_PHASE_FAILURE` |
| 3 | `VERIFY_TRANSPORT_NACK` |
| 4 | `VERIFY_TIMEOUT` |
| 5 | `VERIFY_VALUE_MISMATCH` |
| 6 | `VERIFY_NOT_REACHED` |
| 7 | reserved |

`PASS_MATCHED` requires both expected-valid and observed-valid. A value
mismatch is not a NACK and is represented by result 5 plus a nonzero
`terminal_error_code`; its phase-NACK bitmap can legitimately be zero.

## Bank-update reason enumeration

| Value | Meaning |
|---:|---|
| 0 | `NO_CHANGE` |
| 1 | `ORIGINAL_READ_PROVED_BANK` |
| 2 | `ACKED_DIRECT_SELECTOR_WRITE_PROVED_BANK` |
| 3 | `VERIFIED_SELECTOR_READBACK_PROVED_BANK` |
| 4 | `RESTORE_SELECTOR_WRITE_PROVED_BANK` |
| 5 | `SELECTOR_WRITE_FAILURE_INVALIDATED_CACHE` |
| 6 | `SELECTOR_VERIFY_TRANSPORT_FAILURE_INVALIDATED_CACHE` |
| 7 | `SELECTOR_VERIFY_MISMATCH_INVALIDATED_CACHE` |
| 8 | `RESET_OR_START_STATE_INVALID` |
| 9 | `DEFERRED_PENDING_VERIFY_NO_CHANGE` |
| 10..15 | reserved; decoder must reject a valid record using these values |

## Transaction serial contract

The independent 16-bit serial has no functional fanout. Reset initializes the
next serial to zero. At each actual I2C transaction start, the accumulator
latches the current serial into `transaction_index_16`, then increments the
next serial exactly once. Thus the first actual transaction is serial 0 and
transaction 300 is represented as `0x012C`, independent of the legacy
operation field.

No NOP, delay, setup-only state, or failed prerequisite before an actual START
consumes a serial. A sticky serial-overflow status must be exposed in the
header. Simulation and every hardware-valid sample require fewer than 65,536
transaction starts, so no valid sample can contain a wrapped/aliased serial.

## Finalization contract

At actual START, a private accumulator snapshots transaction serial, exact
table slot or `0xFFFF`, kind, phase, requested bank and its validity, physical
bank before and its validity, and all applicable selector/verify metadata.

At every ACK sample, the implementation first sets the matching opportunity
bit and increments the corresponding phase opportunity counter, then samples
ACK/NACK and updates the NACK bitmap/count. If an earlier failure prevents a
later ACK state from being reached, that later opportunity bit remains zero.

At `STORE_RESULT`, or an explicitly tested synthetic timeout-finalization
point if ever required, the record is committed only when:

```text
phase_nack_bitmap != 0 OR timeout_flag = 1 OR terminal_error_code != 0
```

The physical-bank-after byte and valid bit are the *effective next cache
state* after this transaction. An RTL implementation must compute that next
state explicitly or delay finalization until it is observable; reading the
old VHDL signal value in the same clock edge as a nonblocking cache update is
not acceptable.

The entire 192-bit entry is written atomically. `record_valid` is part of that
atomic write. An entry is never modified again. A failed transaction creates
one record even when two or more phase bits are set.

## Required record invariants

```text
record_valid -> (phase_nack_bitmap != 0 OR timeout_flag OR terminal_error_code != 0)
phase_nack_bitmap & ~phase_opportunity_bitmap == 0
nack_count_within_transaction == popcount(phase_nack_bitmap)
nack_count_within_transaction <= 4
transaction_kind != INVALID_UNUSED for every valid record
autoinit_phase <= PH_RESTORE for every valid record
write_data_valid == 0 for all read kinds
read_data_valid == 0 for all write kinds unless an explicitly represented verify read exists
selector_value_valid -> register_address_valid && register_address == 0xFF
bank_verify_result == PASS_MATCHED -> expected_valid && observed_valid && expected == observed
physical_bank_after_valid == 0 -> physical_bank_after is not interpreted
all reserved bits == 0
all six words of every unused entry == 0
```

## Storage-size note

The exact failed-log payload is 64 x 192 = 12,288 bits. This is not a width or
map impossibility. It may infer multiple physical RAM lanes because Artix-7
block-RAM port widths are narrower than 192 bits; the routed build must report
the actual BRAM/LUTRAM implementation and must not claim placement neutrality.

