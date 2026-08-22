# Historical R1 failure-path trace

## Inputs re-read

This trace uses immutable evidence commit
`cbe2cee94c3b8fd7b8b6c13e6978bc26bc903c7c` and exact source commit
`0af44dee3bc091eaff805704dd5c687eeaa01bbd`. The protected NVP blobs are
byte-identical in the R1 source, R1c source
`f007dc172d43d30b02729755e60382f8ce3dbff4`, and formal checkpoint
`c89e88bcdf389614c884fb129e8b2d42a585bccb`.

The R1 T0 and T1 logs independently contain:

```text
CNT_AT_INIT_DONE=113144494
NVP_SUMMARY0=0x00000013
FIRST_ERROR_META=0x80020100
```

The preserved expected count is `113182679`; `NVP_SUMMARY0` therefore reports
19 raw NACKs, and the compact first-error word decodes as valid=1, code=`0x02`,
step=`0x01`.

## Exact first-error path

`control_status_regs.sv` maps the compact word at offset `0x9C` as
valid/code/step. `nvp6134c_i2c_bringup.vhd` assigns code `0x02` only in
`ACK_REG_HIGH` when the register byte is NACKed. The first table slot is the
exact effective operation `0x00800F` (bank `00`, register `80`, data `0F`).
After the successful preinit bank-0 verification, `NEXT_OP` increments
`op_idx` to 1 before slot 0, so step `0x01` identifies this slot-0 target
write.

The register-byte NACK does not abort the transaction. The FSM still executes
the data-byte states, STOP, STORE_RESULT and NEXT_OP. Because the failing
operation is `INIT_TARGET_WRITE`, NEXT_OP advances to the next table slot.
The exact first error is therefore:

```text
R1_FIRST_ERROR_PATH=
    SLOT_0_TARGET_WRITE_REGISTER_BYTE_NACK_PATH_NEUTRAL

R1_FIRST_ERROR_TRANSACTION_TICKS=
    61

R1_FIRST_ERROR_SHORTENING_TICKS=
    0
```

The shortening must have arisen from one or more later bank-selection path
changes; the compact R1 host map did not preserve their ordered NACK records.

## Source-derived branch rules

For a real table entry whose requested bank is not the verified physical-bank
cache, the all-ACK path is:

```text
SELECT_WRITE (61 ticks)
    -> SELECT_VERIFY (83 ticks)
    -> TARGET_WRITE (61 ticks)
```

The exact failure rules are:

- Selector-write NACK: STORE_RESULT invalidates the physical-bank cache;
  NEXT_OP finishes the table entry without issuing SELECT_VERIFY or
  TARGET_WRITE.
- Selector-verify NACK or readback mismatch: the cache remains invalid and
  NEXT_OP finishes the entry without issuing TARGET_WRITE.
- Target-write NACK: transaction cost and next-table-slot path are unchanged.
- A later same-bank table entry retries selection while the cache is invalid.
  That retry can add a selector write and/or verify read relative to the
  all-ACK cache-hit path.

Consequently, an immediate omitted-target count is not the same thing as the
net end-to-end tick deficit.

The exact table also contains explicit target writes to register `FF` at slots
148, 171, 192, 211 and 213. Their data bytes equal their metadata banks
(`00`, `01`, `09`, `00`, `00`). A successful write leaves the cache at the
same bank; a NACK leaves the already-current cache unchanged. These operations
do not remove the ambiguity.

## Two explicit 61-tick witnesses

Each witness starts with the measured slot-0 path-neutral register-byte NACK.
Each listed failed transaction needs only one raw NACK; enough later target or
post-read/write transactions exist to carry the remaining path-neutral NACKs
and reach the measured aggregate count 19.

| Witness | Later path-changing failures | Skipped target slots | Init writes vs all ACK | Init reads vs all ACK | Net shortening | Raw NACK construction |
|---|---|---:|---:|---:|---:|---:|
| One skipped target | Slot 1 bank-01 selector write ACKs; selector verify NACKs. The next real slot changes to bank 03. | 1 | -1 | 0 | 61 ticks | slot-0 first error + 1 verify NACK + 17 path-neutral NACKs = 19 |
| Three skipped targets | In bank-03 run slots 2, 3, 5 (slot 4 is the delay), slot 2 selector write ACKs and verify NACKs; selector writes NACK at slots 3 and 5. The next real slot changes to bank 00. | 2, 3, 5 | -1 | 0 | 61 ticks | slot-0 first error + 1 verify NACK + 2 selector-write NACKs + 15 path-neutral NACKs = 19 |

The staged analysis script replays both witnesses through the exact cache
rules and obtains 211 init writes, 25 init reads, and 30,982 total tick actions
for each, versus 212 writes, 25 reads, and 31,043 actions for all ACKs.

## Verdict

```text
R1_OMITTED_TRANSACTION_INTERPRETATION=
    R1_61_TICKS_HAS_MULTIPLE_VALID_DECOMPOSITIONS

R1_CONTROL_FLOW_EFFECTIVE_NACK_EVENTS=
    NOT_UNIQUELY_DETERMINABLE

R1_SKIPPED_I2C_TRANSACTIONS=
    NOT_UNIQUELY_DETERMINABLE

R1_SKIPPED_TABLE_ENTRIES=
    NOT_UNIQUELY_DETERMINABLE
```

The counter proves an aggregate net shortening equivalent to 61 state ticks
under the preserved edge convention. It does not prove that exactly one NACK
was control-flow-effective or that exactly one transaction/table entry was
skipped.  “Skipped transactions” here means gross omitted target transactions
(one in the first witness, three in the second); both witnesses nevertheless
have the same net transaction delta of one fewer write and zero fewer reads.
