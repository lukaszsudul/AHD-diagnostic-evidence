# R1f Standalone Tri-Phase Probe Implementation Audit

## Result

```text
TRI_PHASE_PROBE_IMPLEMENTED=YES
TRI_PHASE_PROBE_SAFE_TARGET=00/85/00
TRI_PHASE_PROBE_SCHEDULER=ROUND_ROBIN_INTERLEAVED
TRI_PHASE_TARGET_OPPORTUNITIES_PER_PHASE=10000
TRI_PHASE_PROBE_INDEX_BASE=ZERO_BASED_TARGET_OPPORTUNITY_ORDINAL
TRI_PHASE_PROBE_INDEX_MMIO_PACKING={INDEX_2W_PLUS_1,INDEX_2W}
TRI_PHASE_PROBE_COUNTER_SATURATION_STATUS=0_STRUCTURALLY_BOUNDED
TRI_PHASE_PROBE_DIAGNOSTIC_TO_AUTOINIT_FUNCTIONAL_FANOUT=0
```

The implementation is a new standalone module.  It does not edit or replace
the inherited R1e probe, and none of its counters, logs, status bits, or
readback ports feed an autoinit functional decision.

## Exact file identity

| File | Bytes | SHA-256 |
|---|---:|---|
| `rtl/v41/nvp_i2c_tri_phase_probe.sv` | 46060 | `430FA0FD71FD7BDD6A8F9D2469C27C7CC57CD4D3266EC60708D505C6D1D7FBC3` |

The file is in the isolated R1f worktree:

```text
C:\FPGA\WORKTREES\V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY
```

## Frozen production configuration

The source defaults and non-parameterized target constants are:

| Item | Frozen value | Source location |
|---|---:|---|
| Probe clock | 25 kHz | line 18 |
| Target opportunities per phase | 10000 | line 19 |
| Blocks per phase | 10 | line 20 |
| NACK-index capacity per phase | 512 | line 21 |
| Attempts cap per phase | 12000 | line 22 |
| Safe bank | `0x00` | line 130 |
| Bank-selector register | `0xFF` | line 131 |
| Safe register | `0x85` | line 132 |
| Safe data | `0x00` | line 133 |

Count parameters permit bounded, fast RTL tests.  The Bank/Reg/Data target is
made of local constants, not parameters, so a test or integration instance
cannot retarget the active write.

The safe-target gate is separately sealed as:

| Evidence | SHA-256 |
|---|---|
| `03_SAFE_PROBE_TARGET/SAFE_IDEMPOTENT_DATA_PROBE_TARGET.md` | `0C221E56ADF7CCED1D45DE57D949FB973803674B0B648CB0FA81BAF7076AA59F` |
| `03_SAFE_PROBE_TARGET/REJECTED_CANDIDATES.csv` | `4FC3CE50EC5B85CB88D9C2DD7E23C89E3DAFFF17860888ADA755BF551207381E` |
| `03_SAFE_PROBE_TARGET/PROBE_SETUP_AND_RESTORE_CONTRACT.md` | `E955143DDCFDE007BCEC0F64C26D4C62E109B8448F34458A8CD21D6831E9F7EA` |

## Setup, validation, and restoration

The high-level state machine performs, in order:

1. waits for original `init_done`, `init_busy=0`, `nvp_rst=1`, original-master
   release, and a stable post-init guard;
2. reads and preserves Bank Select `0xFF`;
3. selects Bank 0 when needed and always verifies the Bank-0 readback;
4. reads `0x85` and requires the frozen value `0x00`;
5. runs the interleaved target-phase scheduler;
6. re-verifies Bank 0 and requires post-read `0x85==0x00==pre-read`;
7. writes the preserved entry bank, reads it back, and requires equality;
8. releases both lines and qualifies final bus idle before `probe_done`.

Any failed gate produces `probe_aborted=1`, leaves `probe_done=0`, records a
versioned abort code, and releases the probe's open-drain requests.  When the
entry bank is known and the bus remains operable, failures before normal
restoration receive one best-effort restore and verification.  Failure of the
normal restoration itself cannot trigger a second restoration attempt.

The primary `probe_abort_code` is immutable after the first failure.
`probe_restore_failure_code` independently records a secondary best-effort
restore write, restore verification, or final-idle failure.  The actual safe
bank and restored bank readback bytes and their valid bits are exported even
when comparison fails, so the evidence does not replace a mismatch with an
expected constant.

The low-level SCL timeout has strict priority over normal protocol movement.
While a released SCL remains sampled low, the state and divider are held.  On
timeout, one sticky timeout event is recorded and both probe lines are
released; the normal transition logic cannot overwrite that timeout state.

## Exact target-opportunity semantics

- WADDR target is counted only at the physical ACK sample following `0x60`.
- REGADDR target is counted only when its prerequisite WADDR ACKed and the
  `0x85` ACK sample was physically reached.
- DATA target is counted only when WADDR and REGADDR both ACKed and the `0x00`
  ACK sample was physically reached.
- A prerequisite NACK consumes a transaction attempt but never fabricates a
  downstream target opportunity.
- Scheduler order is WADDR, REGADDR, DATA; completed phases are skipped without
  generating transactions.
- `round_robin_scheduler_rounds` increments whenever a complete three-slot
  scheduler pass wraps from DATA back to WADDR, including completed slots that
  were skipped.
- `current_scheduler_phase` is WADDR/REGADDR/DATA while active and `3` whenever
  inactive or complete.
- `attempt_limit_status[2:0]` is sticky per WADDR/REGADDR/DATA and has no
  control fanout; the attempt-count comparison itself remains authoritative.

## Sequence statistics and index map

For every phase the module records ACK/NACK totals, first/last NACK index,
maximum consecutive NACKs, adjacent NACK-pair count, binary run count, ten
fixed target-opportunity block counts, and up to 512 chronological indices.

The index convention is exactly the inherited R1e convention: the first
physically reached target opportunity is index `0`.  Therefore block 0 covers
indices `0..999` in production.  First/last fields and stored index entries all
use the same zero base.

The MMIO-oriented read port is:

```text
index_read_phase[1:0]
index_read_word[7:0]
index_read_data[31:0] = {index[2w+1], index[2w]}
```

Unused halves, unused words, invalid phases, and words beyond a reduced test
capacity return deterministic zero.  Stored-count bounds remain authoritative
for host decoding.

## Counter-bound proof

In the frozen production configuration:

- transaction attempts are bounded by 12000 per phase;
- target opportunities, ACKs, NACKs, runs, streaks, adjacent pairs, and the
  sum of block counts are bounded by 10000 per phase;
- populated prerequisite counters are bounded by their phase's attempts;
- stored index counts are bounded by 512;
- scheduler rounds are bounded by the longest phase's 12000-attempt cap;
- the first probe timeout aborts the run, so a valid sample has zero and an
  invalid run cannot accumulate unbounded probe timeouts.

All exposed counters are at least 16 or 32 bits as appropriate.  None can
reach its representation limit under the frozen parameters, so the version-1
map's counter-saturation word is correctly constant zero.

## Integration interface requirements

In addition to the per-phase counters and setup/restore receipts, integration
must connect:

```text
round_robin_scheduler_rounds[31:0]
current_scheduler_phase[1:0]
attempt_limit_status[2:0]
probe_restore_failure_code[7:0]
safe_bank_readback[7:0]
safe_bank_readback_valid
restored_bank_readback[7:0]
restored_bank_readback_valid
index_read_phase[1:0]
index_read_word[7:0]
index_read_data[31:0]
block_read_phase[1:0]
block_read_index[3:0]
block_read_nack_count[31:0]
```

No host write port exists.
