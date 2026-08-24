# R1h event-spacing and storage-acceptance proof

## Identity

- Exact R1g parent: `e112a5addb7ac62700a9a71af81bf368fad0bada`.
- Candidate failed-record logger SHA-256: `F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761`.
- Candidate probe SHA-256: `D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD`.
- Candidate probe-index store SHA-256: `67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F`.
- Tool: Vivado/XSim 2025.2, SW build 6299465.

## Evidence first

SOURCE-DERIVED FACT: `v41_r1f_failed_txn_logger` has no busy or ready state on
its append input. `payload_write_enable` is exactly `r1f_failed_txn_valid &&
(stored_count < 64)`. The same valid pulse drives all six 32-bit XPM banks at
one common row. Metadata increments in the same clocked process. Therefore the
implementation has one complete 192-bit-record-per-clock acceptance capacity.

SIMULATION-DERIVED FACT: the isolated consecutive-acceptance test applied three
different complete records on three consecutive rising edges, then read all 18
32-bit words. It passed:

```text
R1H_FAILED_RECORD_BACK_TO_BACK_FULL_RECORD_ACCEPTANCE=PASS
RTL_SHA256=F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761
TB_SHA256=1128E4F68423504B4DF51CB3E95F30FB02D1A03948D80D81D4EDC34F19B146C0
XSIM_LOG_SHA256=50BEDA2BF68CB94740608C2D2FFE42A866FF8348D6AC848C75A0F31114E8E5C5
```

SOURCE-DERIVED FACT: `r1h_probe_index_bram_store` likewise has no busy state.
Each accepted `write_valid` selects exactly one of three independent XPM
simple-dual-port memories and is sampled on every rising edge. The other XPM
port is the synchronous host-read port.

SIMULATION-DERIVED FACT: the isolated store test proved both (a) three
same-phase writes on consecutive rising edges and (b) a same-phase,
same-physical-BRAM host read and probe write on one rising edge at different
addresses:

```text
R1H_INDEX_STORE_BACK_TO_BACK_SAME_BANK_WRITES=PASS
R1H_INDEX_STORE_SAME_BANK_DIFFERENT_ADDRESS_CONCURRENT_RW=PASS
RTL_SHA256=67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F
TB_SHA256=EAD12685E7E44D153A55E081DC6578AB243193D72654BD5733EF7CF97841AC9B
XSIM_LOG_SHA256=FB0DE6800028E2B67DD3A2699278C7D4F66E1C3B981A44D38899DF45C26E89D2
```

SOURCE-DERIVED FACT: an index creation can occur only in
`record_target_outcome`, which is called from `H_PROBE_WAIT` on `ll_done` and
only for a physically reached target phase. That state moves to
`H_PROBE_SELECT`; a subsequent transaction is launched only when `!ll_busy`.
Every newly launched low-level transaction first enters `LL_WAIT_IDLE`.

SOURCE-DERIVED FACT: at the frozen production parameters,
`DIVIDER = 62,500,000 / (25,000 * 2) = 1250` and `TICK_CYCLES = 1251`.
`LL_WAIT_IDLE` alone requires 1,251 consecutive clock cycles of qualified idle
before the first I2C START state. A new target outcome additionally requires
the complete address/phase and STOP sequence. Thus a conservative, deliberately
non-tight source lower bound between two logical probe-index events is greater
than 1,251 clocks. This is far above the one-clock payload acceptance interval.

SIMULATION-DERIVED FACT: the paired R1g/R1h probe run checked each logical
stored-count transition against the R1h BRAM write event phase, address and
data. All five injected NACK-index creation events matched, and subsequent
synchronous reads matched the exact R1g chronological index payload.

## Conclusion

`RECORD_LOSS_AT_MINIMUM_EVENT_SPACING=PROVEN_ABSENT` because the logger accepts
one full record every clock, including consecutive clocks.

`INDEX_LOSS_AT_MINIMUM_EVENT_SPACING=PROVEN_ABSENT` because the store accepts
one index every clock, including consecutive same-bank clocks, while the exact
producer has a source-proven lower bound greater than 1,251 clocks in the
production configuration.

No serializer or multi-cycle write service exists on either producer path, so
there is no unproved event-rate precondition hidden by the BRAM conversion.
