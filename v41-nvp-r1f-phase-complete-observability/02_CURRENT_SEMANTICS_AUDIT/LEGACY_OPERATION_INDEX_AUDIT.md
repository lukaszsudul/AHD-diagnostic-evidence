# Legacy operation-index audit

## Scope and result

This audit is against exact R1e commit `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`, tree `db8b5581a237e19905fd01c6d453793047bc3ba7`, and source blob `cfe33464d8e75c514462786593b278d90b4059a4`.

```text
LEGACY_OPERATION_INDEX_BEHAVIOR=INTERNAL_SATURATES_AT_255_WITH_SEPARATE_MODULO_64_DEBUG_ALIAS
LEGACY_OPERATION_INDEX_UNIQUE_ABOVE_255=NO
LEGACY_OPERATION_INDEX_IS_TRANSACTION_SERIAL=NO
LEGACY_OPERATION_INDEX_FUNCTIONAL_FANOUT=0
```

## Exact type and range

`nvp6134c_i2c_bringup.vhd:117` declares:

```vhdl
signal op_idx : integer range 0 to 255 := 0;
```

It is reset to zero on controller reset (`:393`) and on a newly accepted start (`:496`).

## Increment and terminal behavior

Every assignment that increments `op_idx` has the same guard:

```vhdl
if op_idx < 255 then op_idx <= op_idx + 1; end if;
```

The exhaustive occurrences are at lines 1056, 1064, 1080, 1089, 1094, 1109, 1129, 1136, 1150, 1158, 1169, 1173, 1184, and 1207. There is no decrement, wrap assignment, or alternate increment conversion.

Therefore the internal value saturates at 255. It does not wrap. Once 255 is reached, every guarded increment is a no-op.

## What it indexes

For the enabled R1e table path:

1. `op_idx=0` covers the entry bank read, the forced Bank-0 selector write, and its verification read.
2. After successful entry verification, table slot 0 begins at `op_idx=1`.
3. A table slot increments `op_idx` only when that slot finishes.
4. A selector write, selector verification read, and target write belonging to one table slot all share the same `op_idx`.
5. NOP and delay slots consume the same legacy operation sequence, even though they may not issue an I2C transaction.

Consequently the legacy field is neither an independent I2C transaction serial nor an unambiguous table-slot field. Multiple actual transactions can share a value, and some values can represent a no-I2C slot.

## Export conversions and aliasing

The same internal value has two different legacy exports:

- `step_index_dbg` is `to_unsigned(op_idx, 8)` (`:230`). It is exact for 0..255 and then remains 255 because the source value saturates.
- The ordered-NACK record stores `to_unsigned(op_idx, 8)` in bits 7:0 (`:349`), with the same saturation behavior.
- `op_index_dbg` is only six bits and explicitly exports `op_idx mod 64` (`:227`). It aliases values 64 apart even before internal saturation.

The required R1f 16-bit transaction serial must therefore be independent of all three legacy views and must increment on each actual I2C transaction start.

## Exhaustive fanout audit

All exact-source references to `op_idx` fall into these classes:

| Use | Lines | Classification |
|---|---|---|
| Declaration/reset | 117, 393, 496 | local index state |
| Six-bit debug export | 227 | diagnostic only |
| Eight-bit step export | 230 | diagnostic only |
| Ordered-log field | 349 | diagnostic only |
| First-error snapshot | 530, 734, 772, 814, 872, 923, 952 | diagnostic only |
| Saturating self-increment | 1056, 1064, 1080, 1089, 1094, 1109, 1129, 1136, 1150, 1158, 1169, 1173, 1184, 1207 | changes only `op_idx` |

It does not drive `slot_idx`, operation-table lookup, transaction bytes, I2C state transitions, branch decisions, bank-cache state, SCL/SDA release, init completion, or error handling. The `op_idx < 255` comparison controls only whether `op_idx` itself increments.

```text
LEGACY_INDEX_AUDIT=PASS
R1F_REQUIRE_INDEPENDENT_TRANSACTION_INDEX_16=YES
R1F_REQUIRE_SEPARATE_TABLE_SLOT_INDEX_16=YES
```

