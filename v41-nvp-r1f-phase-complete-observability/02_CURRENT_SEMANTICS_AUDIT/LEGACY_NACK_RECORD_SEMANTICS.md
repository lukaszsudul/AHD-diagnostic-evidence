# Legacy NACK-record semantics

## Scope

This is the exact R1e legacy log at commit `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd`. The legacy eight-record implementation remains the compatibility reference for R1f.

## Log organization

`t_nack_log` is eight 64-bit entries (`nvp6134c_i2c_bringup.vhd:100`). `record_nack` appends while `nack_log_count_r < 8`; later events set overflow without circular overwrite (`:342-361`). Unused records retain reset zero. A record is created per sampled NACK phase, not per failed transaction. One transaction can therefore create multiple records.

The record is composed as follows:

| Bits | Exact source | Meaning | Validity semantics |
|---:|---|---|---|
| 7:0 | `op_idx` | legacy saturated operation value | Always present when record-valid is 1; not a transaction serial and not necessarily unique. |
| 15:8 | procedure argument | NACK phase code: `01` WADDR, `02` REGADDR, `03` DATA, `04` RADDR | Always present. |
| 23:16 | `reg_addr` | intended register-pointer byte for the current transaction | Always populated for the transaction context. |
| 31:24 | `write_data` | write payload for a write transaction; zero placeholder for a read transaction | No write-data-valid bit exists. It must not be interpreted as payload unless transaction kind is known elsewhere. |
| 39:32 | `phys_bank_r` | last proven physical bank as it exists before the current transaction completes | Interpret only when bit 49 is 1. It is not an after-transaction bank. |
| 47:40 | `meta_bank_r` | requested/table/diagnostic target bank for the current operation | No separate requested-bank-valid bit exists. |
| 48 | constant 1 | record valid | Authoritative record-valid bit. |
| 49 | `phys_bank_valid_r` | validity of bits 39:32 at the NACK sampling instant | Authoritative physical-bank-valid bit. |
| 63:50 | zero | reserved | Must remain zero. |

## Exact sampling instant

`record_nack` is called inside the clocked process only from the four ACK-high states when filtered SDA is not low:

- `ACK_W_HIGH` (`:726-740`);
- `ACK_REG_HIGH` (`:764-778`);
- `ACK_DATA_HIGH` (`:806-820`);
- `ACK_R_HIGH` (`:864-878`).

The procedure reads the registered context that exists at that ACK sample: `op_idx`, `reg_addr`, `write_data`, `phys_bank_r`, `meta_bank_r`, and `phys_bank_valid_r`. Standard VHDL signal-update semantics mean assignments scheduled later in the same rising-edge execution are not reflected in that record. In particular, a record describes the before/completing transaction context, not the `STORE_RESULT` after-state.

The FSM does not short-circuit after an early NACK. It continues through later byte phases, so a transaction can legitimately emit several phase records sharing one legacy operation value.

## Read/write data validity

At every `SETUP_OP`, `write_data` is first scheduled to zero (`:515`). Write paths subsequently schedule a real payload. Read paths leave the zero value. Thus a read-transaction record's `write_data=0x00` is a placeholder, not proof that zero was written.

`data_rx` is reset at `SETUP_OP` (`:509`) and accumulated only in `READ_HIGH` (`:887-895`). It is exported as the global `last_rdata_dbg`, but it is not stored in each 64-bit NACK record and has no per-record read-data-valid bit. On a write transaction, that global value is a zero placeholder. On a read transaction, it becomes meaningful only after the read byte has completed; an earlier phase record cannot encode that later value.

## Bank meanings and update timing

The exact source comments define:

- `meta_bank_r`: requested table/diagnostic bank;
- `phys_bank_r`: last bank proven by a successful 0xFF read, a verified D2 bank selection, or an acknowledged explicit 0xFF write outside the verified-selection helper;
- `phys_bank_valid_r`: whether that last-proven physical-bank value is usable.

The important transitions are:

1. A successful original 0xFF read sets both metadata and physical bank to the observed value and marks physical valid (`:959-965`).
2. A verified selector write uses `defer_phys_bank_update=1`; success intentionally does not change the physical bank yet (`:1023-1032`).
3. Its successful verification read sets the physical bank to the expected/requested bank and marks it valid (`:933-938`).
4. Verification transport failure or value mismatch invalidates the physical-bank cache (`:939-958`).
5. A failed deferred selector write invalidates the cache (`:1028-1031`).
6. A successful explicit 0xFF write outside the deferred helper updates the physical bank immediately (`:1023-1027`).
7. A target table write is selected only when the pre-transaction physical bank is valid and equals the requested bank; otherwise the verified selector helper runs (`:595-609`).

Therefore requested metadata bank and last-proven physical bank may differ legally during a bank-selection/verification sequence.

## Known ambiguity boundary

The legacy record has no transaction-kind bit, no write/read-data-valid bits, no selector/verify fields, and no physical-bank-after field. It cannot by itself distinguish a selector write from its verification read when only the overloaded bytes are examined. This is precisely why R1f requires a versioned 192-bit failed-transaction record while preserving these eight legacy records byte-for-byte.

```text
LEGACY_NACK_RECORD_SEMANTICS_AUDIT=PASS
LEGACY_RECORD_IS_PER_NACK_PHASE=YES
LEGACY_RECORD_IS_PER_FAILED_TRANSACTION=NO
LEGACY_BANK_FIELDS_ARE_BEFORE_TRANSACTION_CONTEXT=YES
LEGACY_WRITE_DATA_VALID_BIT=ABSENT
LEGACY_READ_DATA_PER_RECORD=ABSENT
```

