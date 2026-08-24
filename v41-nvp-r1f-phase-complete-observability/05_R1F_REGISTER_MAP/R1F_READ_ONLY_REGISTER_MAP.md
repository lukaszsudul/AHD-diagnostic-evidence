# R1f phase-complete read-only register map

## Bus contract

All offsets are byte offsets in the existing 128-KiB XDMA user AXI-Lite
aperture. Words are 32-bit little-endian and must be read on four-byte
boundaries. Unlisted aligned words in the R1f range return zero. Unaligned
reads return zero.

The R1f reader must be version-gated by magic, version, capabilities, record
version/width/word count, log capacity, phase mask, and frozen safe-target
identity before interpreting any dynamic field.

```text
R1F_MAP_FIRST=0x20A0
R1F_MAP_LAST=0x35FF
R1F_MAGIC=0x31463152       # little-endian bytes spell R1F1
R1F_VERSION=1
R1F_RECORD_VERSION=1
R1F_RECORD_WIDTH_BITS=192
R1F_RECORD_WORDS=6
R1F_LOG_CAPACITY=64
R1F_PROBE_PHASE_MASK=0x00000007
```

Writes are not locally decoded as R1f operations. They retain the exact prior
invalid-write path and cannot mutate an R1f field. The prior path does update
the pre-existing `err_bad_mmio_addr`/`last_bad_mmio_addr` diagnostic
accounting; this is documented precisely in the collision proof. The R1f
hardware campaign performs no AXI-Lite writes.

## Summary of ranges

| Range | Size | Allocation |
|---:|---:|---|
| `0x2000..0x2094` | existing | Preserved R1e lifecycle/probe-page offsets and decoder compatibility; R1f uses the compatibility projection defined below. |
| `0x2098..0x209F` | 8 B | Preserved reserved-zero gap. |
| `0x20A0..0x21FF` | 352 B | R1f identity, configuration, passive phase counters, failed-log summary, invariant summary, and probe summary. |
| `0x2200..0x227F` | 128 B | Write-address target-probe statistics. |
| `0x2280..0x22FF` | 128 B | Register-address target-probe statistics. |
| `0x2300..0x237F` | 128 B | Data target-probe statistics. |
| `0x2380..0x23FF` | 128 B | Probe scheduler/setup/restoration detail. |
| `0x2400..0x29FF` | 1536 B | 64 failed-transaction records x 24 bytes. |
| `0x2A00..0x2DFF` | 1024 B | 512 write-address target-NACK indices x 16 bits. |
| `0x2E00..0x31FF` | 1024 B | 512 register-address target-NACK indices x 16 bits. |
| `0x3200..0x35FF` | 1024 B | 512 data target-NACK indices x 16 bits. |

The existing legacy log remains at `0x10098..0x100D8` and is unchanged.

### R1e-page compatibility projection

The inherited R1e page remains readable at the same offsets, but R1f does not
claim that its post-init probe lifecycle is semantically identical to the old
address-only engine.  The R1f tri-phase engine projects its write-address
target counters, ACK/NACK counts, zero-based first/last indices, and maximum
NACK streak into the corresponding legacy words.  The legacy status word
retains its terminal-on-success-or-abort `DONE` convention and its sticky
guard, bus-idle, SCL-timeout, and bus-idle-timeout meanings.

The compatibility-page start timestamp marks completion of the post-init
guard and entry into R1f setup.  Its terminal timestamp and `DONE`/`ABORTED`
status cover the complete R1f setup, interleaved three-phase measurement,
post-readback, bank-restoration, and final-idle lifecycle.  Its timeout count
is the low-level transaction-timeout total across setup/probe/restore, not a
WADDR-only timeout count; high-level final-idle failure is reported by the
abort-code fields.  Therefore R1f scientific rate, timing, stationarity, and timeout
analysis must use the version-gated R1f fields at `0x20A0..0x35FF`; the legacy
projection is retained only for address/decoder compatibility and contextual
cross-checks.

## R1f header and counters: `0x20A0..0x21FF`

| Offset | Name | Encoding |
|---:|---|---|
| `0x20A0` | `R1F_MAGIC` | Constant `0x31463152`. |
| `0x20A4` | `R1F_VERSION` | Constant 1. |
| `0x20A8` | `R1F_CAPABILITIES` | Bits 0 phase counters, 1 transaction log, 2 explicit bank semantics, 3 bank invariants, 4 tri-phase probe, 5 block statistics, 6 NACK-index logs, 7 legacy reconciliation, 8 safe-target contract, 9 transaction-index-16, 10 table-slot-index-16. Required value `0x000007FF`. |
| `0x20AC` | `R1F_RECORD_VERSION` | Constant 1. |
| `0x20B0` | `R1F_RECORD_WIDTH_BITS` | Constant 192. |
| `0x20B4` | `R1F_RECORD_WORDS` | Constant 6. |
| `0x20B8` | `R1F_LOG_CAPACITY` | Constant 64. |
| `0x20BC` | `R1F_PROBE_PHASE_MASK` | Constant 7: bit 0 WADDR, bit 1 REGADDR, bit 2 DATA. |
| `0x20C0` | `R1F_SAFE_TARGET_BANK_REG_DATA` | Bank `[7:0]`, register `[15:8]`, data `[23:16]`, bit 31 `SAFE_TARGET_PROVEN`. Reserved bits zero. |
| `0x20C4` | `AUTOINIT_I2C_HZ` | Constant 25000. |
| `0x20C8` | `PROBE_I2C_HZ` | Constant 25000. |
| `0x20CC` | `PROBE_TARGET_OPPORTUNITIES_PER_PHASE` | Constant 10000. |
| `0x20D0` | `PROBE_BLOCKS_PER_PHASE` | Constant 10. |
| `0x20D4` | `PROBE_TARGET_OPPORTUNITIES_PER_BLOCK` | Constant 1000. |
| `0x20D8` | `PROBE_MAX_TRANSACTION_ATTEMPTS_PER_PHASE` | Constant 12000. |
| `0x20DC` | `PROBE_NACK_INDEX_LOG_CAPACITY_PER_PHASE` | Constant 512. |
| `0x20E0` | `AUTOINIT_WADDR_ACK_OPPORTUNITIES` | 32-bit saturating. |
| `0x20E4` | `AUTOINIT_WADDR_NACKS` | 32-bit saturating. |
| `0x20E8` | `AUTOINIT_REGADDR_ACK_OPPORTUNITIES` | 32-bit saturating. |
| `0x20EC` | `AUTOINIT_REGADDR_NACKS` | 32-bit saturating. |
| `0x20F0` | `AUTOINIT_DATA_ACK_OPPORTUNITIES` | 32-bit saturating. |
| `0x20F4` | `AUTOINIT_DATA_NACKS` | 32-bit saturating. |
| `0x20F8` | `AUTOINIT_RADDR_ACK_OPPORTUNITIES` | 32-bit saturating. |
| `0x20FC` | `AUTOINIT_RADDR_NACKS` | 32-bit saturating. |
| `0x2100` | `AUTOINIT_TRANSACTION_STARTS` | 32-bit saturating. |
| `0x2104` | `AUTOINIT_TRANSACTION_COMPLETIONS` | 32-bit saturating. |
| `0x2108` | `AUTOINIT_FAILED_TRANSACTIONS` | 32-bit saturating; one per failed/timed-out transaction. |
| `0x210C` | `AUTOINIT_TIMEOUT_TRANSACTIONS` | 32-bit saturating subset. |
| `0x2110` | `PHASE_COUNTER_STATUS` | Bit 0 counters final, 1 no saturation, 2 NACKs <= opportunities, 3 transaction counts coherent. Other bits zero. |
| `0x2114` | `LEGACY_AGGREGATE_NACK_COUNT` | Zero-extended inherited aggregate NACK count. |
| `0x2118` | `R1F_PHASE_NACK_SUM` | Sum of the four R1f phase-NACK counters. |
| `0x211C` | `PHASE_RECONCILIATION_STATUS` | Bit 0 measured phase-NACK sum equals the legacy aggregate; bit 1 static capability (`LEGACY_FIRST8_RECONCILIATION_SUPPORTED`), not a measured pass; bit 2 measured transaction-failure total equals the failed-log total. The version-gated host reader independently reconciles both raw record sets and fails closed. Other bits zero. |
| `0x2120` | `R1F_FAILED_TXN_TOTAL_COUNT` | 32-bit saturating. |
| `0x2124` | `R1F_FAILED_TXN_STORED_COUNT` | Range 0..64, zero-extended. |
| `0x2128` | `R1F_FAILED_TXN_OVERFLOW` | Bit 0 sticky; all other bits zero. |
| `0x212C` | `R1F_FIRST_FAILED_TXN_INDEX` | Low 16 bits; validity is in `LOG_STATUS`. |
| `0x2130` | `R1F_LAST_FAILED_TXN_INDEX` | Low 16 bits; validity is in `LOG_STATUS`. |
| `0x2134` | `LOG_STATUS` | Bit 0 first valid, 1 last valid, 2 overflow, 3 total equals failed-transactions, 4 stored count coherent, 5 unused entries zero, 6 entries immutable, 7 transaction-serial overflow, 8 logger input-protocol error, 9 total-count saturation. Others zero. Valid sample requires bits 3..6 one and bits 2,7,8,9 zero. |
| `0x2138` | `NEXT_TRANSACTION_SERIAL` | Next serial `[15:0]`, bit 16 serial-overflow sticky, other bits zero. |
| `0x213C` | `BANK_TRACKER_INVARIANT_CHECK_COUNT` | 32-bit saturating. |
| `0x2140` | `BANK_TRACKER_INVARIANT_ERROR_COUNT` | 32-bit saturating. |
| `0x2144` | `FIRST_BANK_TRACKER_INVARIANT_ERROR` | Bit 31 valid, code `[30:24]`, transaction index `[23:8]`, kind `[7:4]`, phase `[3:0]`. |
| `0x2148` | `FINAL_PHYSICAL_BANK_STATE` | Bank `[7:0]`, valid bit 8, other bits zero. |
| `0x214C` | `TRI_PHASE_PROBE_STATUS` | Bit 0 started, 1 done, 2 aborted, 3 all phase targets complete, 4 setup pass, 5 pre/post target equal, 6 bank restore verified, 7 lines released, 8 no counter saturation, 9 no index overflow. Other bits zero. |
| `0x2150` | `PROBE_TIMEOUT_COUNT_TOTAL` | Low-level I2C transaction-timeout total across setup, probe, and restore. A high-level final-idle timeout is represented by its abort code rather than this counter. |
| `0x2154` | `PROBE_SETUP_RESTORE_STATUS` | Packed detailed status; layout below is mirrored by detail words. |
| `0x2158` | `SAFE_TARGET_PRE_READBACK` | Value `[7:0]`, valid bit 8, other bits zero. |
| `0x215C` | `SAFE_TARGET_POST_READBACK` | Value `[7:0]`, valid bit 8, other bits zero. |
| `0x2160` | `ORIGINAL_BANK_READBACK` | Value `[7:0]`, valid bit 8, other bits zero. |
| `0x2164` | `RESTORED_BANK_READBACK` | Value `[7:0]`, valid bit 8, verified bit 9, other bits zero. |
| `0x2168` | `PROBE_START_FREERUN_LO` | Low 32 bits. |
| `0x216C` | `PROBE_START_FREERUN_HI` | Low 16 bits hold bits `[47:32]`; upper bits zero. |
| `0x2170` | `PROBE_DONE_FREERUN_LO` | Low 32 bits. |
| `0x2174` | `PROBE_DONE_FREERUN_HI` | Low 16 bits hold bits `[47:32]`; upper bits zero. |
| `0x2178..0x21FC` | reserved | Read zero. |

`PROBE_SETUP_RESTORE_STATUS` uses bits 0 setup started, 1 original bank read,
2 bus idle qualified, 3 safe bank selected, 4 safe bank verified, 5 target pre
read pass, 6 target post read pass, 7 target unchanged, 8 original bank restore
write pass, 9 restore readback pass, 10 lines released, 11 setup failure, 12
post-probe validation/restoration/final-idle failure. Bits 31:13 are zero.

## Per-phase probe blocks: `0x2200..0x237F`

Three identical 128-byte blocks are used:

```text
WADDR block base   = 0x2200
REGADDR block base = 0x2280
DATA block base    = 0x2300
```

For each phase base `P`:

| Relative | Name | Meaning |
|---:|---|---|
| `+0x00` | `STATUS` | Bit 0 enabled, 1 done, 2 target complete, 3 first-NACK valid, 4 last-NACK valid, 5 index-log overflow, 6 counter saturation, 7 attempt limit hit. Others zero. |
| `+0x04` | `TRANSACTION_ATTEMPTS` | Attempts scheduled for this target class. |
| `+0x08` | `PREREQ_WADDR_OPPORTUNITIES` | Physically reached prerequisite WADDR samples. Zero for the WADDR target block. |
| `+0x0C` | `PREREQ_WADDR_ACKS` | Prerequisite WADDR ACKs. |
| `+0x10` | `PREREQ_WADDR_NACKS` | Prerequisite WADDR NACKs. |
| `+0x14` | `PREREQ_REGADDR_OPPORTUNITIES` | Physically reached prerequisite REGADDR samples. Nonzero only for DATA target. |
| `+0x18` | `PREREQ_REGADDR_ACKS` | Prerequisite REGADDR ACKs. |
| `+0x1C` | `PREREQ_REGADDR_NACKS` | Prerequisite REGADDR NACKs. |
| `+0x20` | `TARGET_OPPORTUNITIES` | Exactly 10000 in a valid completed phase. |
| `+0x24` | `TARGET_ACKS` | Target ACK count. |
| `+0x28` | `TARGET_NACKS` | Target NACK count. |
| `+0x2C` | `TIMEOUTS` | Phase-attributed timeouts; valid sample requires zero total. |
| `+0x30` | `FIRST_TARGET_NACK_INDEX` | Low 16 bits, zero when status says invalid. Index is zero-based target-opportunity index. |
| `+0x34` | `LAST_TARGET_NACK_INDEX` | Low 16 bits, zero when status says invalid. |
| `+0x38` | `MAX_CONSECUTIVE_TARGET_NACKS` | 32-bit count. |
| `+0x3C` | `ADJACENT_TARGET_NACK_PAIR_COUNT` | 32-bit count. |
| `+0x40` | `BINARY_SEQUENCE_RUN_COUNT` | Runs in the complete 10,000-bit target ACK/NACK sequence. |
| `+0x44` | `NACK_INDEX_STORED_COUNT` | Range 0..512. |
| `+0x48` | `NACK_INDEX_OVERFLOW` | Bit 0 sticky, other bits zero. |
| `+0x4C..+0x70` | `BLOCK_0_NACKS..BLOCK_9_NACKS` | Ten consecutive 1000-opportunity blocks. |
| `+0x74..+0x7C` | reserved | Read zero. |

Block 0 covers target indices 0..999, block 1 covers 1000..1999, and so on.
The sum of ten block counts must equal `TARGET_NACKS`.

Prerequisite interpretation is exact:

- WADDR target: both prerequisite groups are zero;
- REGADDR target: WADDR prerequisite group populated, REGADDR prerequisite
  group zero because REGADDR is the target;
- DATA target: WADDR and REGADDR prerequisite groups both populated.

For each populated group, ACKs + NACKs = opportunities. For every block,
target ACKs + target NACKs = target opportunities.

## Probe scheduler/setup/restoration detail: `0x2380..0x23FF`

| Offset | Name | Encoding |
|---:|---|---|
| `0x2380` | `PROBE_GLOBAL_STATUS` | Same status meaning as `TRI_PHASE_PROBE_STATUS`; implementations must return identical relevant bits. |
| `0x2384` | `ROUND_ROBIN_SCHEDULER_ROUNDS` | Completed scheduler rounds. |
| `0x2388` | `TOTAL_TRANSACTION_ATTEMPTS` | Sum of the three phase-block attempt counts. |
| `0x238C` | `TOTAL_PROBE_TIMEOUTS` | Same low-level transaction-timeout total as the header. |
| `0x2390` | `SETUP_FAILURE_CODE` | Zero on success; versioned code otherwise. |
| `0x2394` | `POST_PROBE_OR_RESTORE_FAILURE_CODE` | Zero on success. Otherwise holds a versioned post-probe bank/target validation, restoration, final-idle, or secondary best-effort restoration failure code. |
| `0x2398` | `ORIGINAL_BANK_PRESERVED` | Bank `[7:0]`, valid bit 8. |
| `0x239C` | `SAFE_BANK_SELECTED_READBACK` | Bank `[7:0]`, valid bit 8, matched bit 9. |
| `0x23A0` | `SAFE_TARGET_PRE_READBACK_DETAIL` | Value `[7:0]`, valid bit 8, matched-expected bit 9. |
| `0x23A4` | `SAFE_TARGET_POST_READBACK_DETAIL` | Value `[7:0]`, valid bit 8, matched-pre bit 9, matched-expected bit 10. |
| `0x23A8` | `RESTORED_BANK_READBACK_DETAIL` | Bank `[7:0]`, valid bit 8, matched-original bit 9. |
| `0x23AC` | `BUS_IDLE_QUALIFICATION` | Bits 0/1 are the current original-master SCL/SDA release requests, bits 2/3 are the current raw sampled SCL/SDA levels, and bit 4 is the sticky initial stable-bus-idle qualification result. |
| `0x23B0` | `PROBE_LINE_RELEASE_STATUS` | Bit 0 probe SCL release, 1 probe SDA release, 2 original master release, other bits zero. |
| `0x23B4` | `PROBE_CURRENT_SCHEDULER_PHASE` | 0 WADDR, 1 REGADDR, 2 DATA, 3 complete; valid only while active. |
| `0x23B8` | `PROBE_ATTEMPT_LIMIT_STATUS` | Bits 0 WADDR hit, 1 REGADDR hit, 2 DATA hit. Valid sample requires zero. |
| `0x23BC` | `PROBE_COUNTER_SATURATION_STATUS` | Versioned bitmap; valid sample requires zero. |
| `0x23C0..0x23FC` | reserved | Read zero. |

Setup, post-probe validation, restoration, or final-idle failure sets
`PROBE_ABORTED`, prevents a valid rate inference, and leaves all lines
released.

## Failed-transaction records: `0x2400..0x29FF`

```text
record_base(r) = 0x2400 + 0x18*r, r=0..63
word_addr(r,w) = record_base(r) + 4*w, w=0..5
last word = word_addr(63,5) = 0x29FC
```

The exact six-word field allocation is specified in
`../04_R1F_RECORD_FORMAT/R1F_FAILED_TRANSACTION_RECORD_V1.md`. Entries at or
above stored count must return six zero words.

## Probe target-NACK index logs

| Phase | Base | End |
|---|---:|---:|
| WADDR | `0x2A00` | `0x2DFF` |
| REGADDR | `0x2E00` | `0x31FF` |
| DATA | `0x3200` | `0x35FF` |

Each range holds 256 DWORDs = 512 16-bit indices. For stored index ordinal
`i` in `0..511`:

```text
address = base + 4 * floor(i/2)
i even: index in bits 15:0
i odd:  index in bits 31:16
```

Indices are zero-based target-opportunity indices in range 0..9999, strictly
increasing within each phase. Words/halfwords beyond the phase's stored count
are zero. Stored count and overflow are in the corresponding phase block.
Overflow sets on target NACK number 513; aggregate and block counters remain
valid, but exact-distribution analysis is limited.

## Read decode integration

The R1f image should add a read-only selection term without weakening the
existing identity page or altering the R1e offsets:

```text
r1f_read_select = !host_req_write &&
                  host_req_addr >= 17'h020A0 &&
                  host_req_addr <= 17'h035FF
```

Selection includes unaligned addresses so the local response can return zero.
R1f selection takes precedence over the inherited R1e page decoder at
`0x20A0..0x20FF`. All R1f writes remain unselected locally and are forwarded
unchanged to preserve prior invalid-write accounting. The R1f read mux and
all exported observer state have zero fanout into application request writes,
functional NVP state, or I2C controls.
