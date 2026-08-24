# R7 operation-86 replay

## Classification

```text
R7_OPERATION_86_CLASSIFICATION=LEGAL_TRANSITIONAL_CONTEXT
R7_OPERATION_86_BANK_TRACKER_DEFECT=NOT_PROVEN_FROM_OVERLOADED_RECORD_FIELDS
```

This classification means the recorded bank fields follow the exact source's intended before/verify/after sequencing. It does not treat the observed NACKs as normal and does not infer an electrical cause.

## Frozen R7 records

The exact R7 ordered-record CSV (SHA-256 `CD6E9463C00E51D14A7C02C61B3FD41998C23147DAC7C3BB6180F74836C01713`) contains:

| Raw record | Legacy op | Phase | Register | Write-data field | Physical bank | Metadata bank | Record valid | Physical valid |
|---|---:|---|---|---|---|---|---:|---:|
| `0x0003020900FF0156` | 86 | WRITE_ADDRESS_ACK | `0xFF` | `0x00` | `0x09` | `0x02` | 1 | 1 |
| `0x0003020900FF0256` | 86 | REGISTER_ADDRESS_ACK | `0xFF` | `0x00` | `0x09` | `0x02` | 1 | 1 |

## Exact operation mapping

The enabled R1e sequence uses operation 0 for entry-bank discovery/verification. Table slot 0 therefore begins at legacy operation 1. Table slot 85 maps to legacy operation 86.

At stage `"10"`, the exact table entries are:

```text
slot 84 / operation 85 = 0x099900  (bank 0x09, register 0x99, data 0x00)
slot 85 / operation 86 = 0x020203  (bank 0x02, register 0x02, data 0x03)
```

The slot-85 value is from `nvp6134c_diagnostics_pkg.vhd:318`. The preceding slot is at line 317.

## Cycle-semantic replay

1. After the preceding Bank-9 operation, the cache can legally hold `phys_bank=0x09`, valid.
2. Decoding slot 85 requests Bank 2. Because valid physical Bank 9 does not equal requested Bank 2, `INIT_DECODE` schedules a deferred physical bank-selector write: register `0xFF`, data `0x02`, metadata bank `0x02` (`nvp6134c_i2c_bringup.vhd:595-608`).
3. The FSM reaches the verification transaction only if that selector-write transaction completed without `cur_error` and without timeout (`:1112-1118`). This proves the retained records are not from the selector write itself.
4. A successful deferred selector write intentionally leaves `phys_bank=0x09`, valid, until readback proves Bank 2. The source does not update physical bank on successful deferred writes (`:1023-1032`).
5. `INIT_BANK_VERIFY` is a read transaction of register `0xFF`, with metadata/requested Bank 2 and expected readback 2 (`:623-629`). `SETUP_OP` has reset `write_data` to zero; because this is a read, zero is only a placeholder (`:508-520`).
6. The verification read sees a write-address NACK and then a register-address NACK. The FSM continues after the first NACK, so both records belong to the same read transaction and legitimately share operation 86 (`:726-785`).
7. Both records are captured before `STORE_RESULT`. At those sampling instants, the last proven physical bank is still 9 and valid, while the requested metadata bank is 2. This is the exact legal transitional state.
8. At `STORE_RESULT`, `cur_error=1` causes the bank-verification path to invalidate the physical-bank cache (`:933-945`). The 64-bit records have no physical-bank-after field, so that later invalidation is not represented in either retained record.

## What the old records cannot prove

The `write_data=0x00` field cannot be treated as a selector value because the transaction is a read and no write-data-valid bit exists. The physical-bank byte is the last proven bank before the verification result, not the requested bank and not the after-transaction state. The metadata byte is the requested target bank.

Accordingly, the old record cannot prove tracker corruption. R1f must make this replay unambiguous with transaction kind, valid bits, requested bank, physical bank before/after, selector value, verify expected/observed/result, and bank-update reason.

```text
R7_OPERATION_86_TRANSACTION_KIND=BANK_SELECTION_VERIFY_READ
R7_OPERATION_86_TABLE_SLOT=85
R7_OPERATION_86_REQUESTED_BANK=0x02
R7_OPERATION_86_PHYSICAL_BANK_BEFORE=0x09_VALID
R7_OPERATION_86_WRITE_DATA_FIELD=INVALID_READ_PLACEHOLDER_0x00
R7_OPERATION_86_PHASE_EVENTS=WADDR_NACK_AND_REGADDR_NACK_IN_ONE_TRANSACTION
R7_OPERATION_86_PHYSICAL_BANK_AFTER=INVALIDATED_BY_VERIFY_FAILURE_NOT_RECORDED_IN_LEGACY_ENTRY
R1F_BANK_SEMANTICS_AUDIT_REQUIRED=YES
```

