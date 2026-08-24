# R1f Tri-Phase Probe Focused Offline Verification

## Gate result

```text
TRI_PHASE_PROBE_RTL_COMPILE=PASS
TRI_PHASE_PROBE_RTL_MAIN=PASS
TRI_PHASE_PROBE_SETUP_ABORT_RESTORE=PASS
TRI_PHASE_PROBE_SCL_TIMEOUT_ABORT=PASS
TRI_PHASE_PROBE_ATTEMPT_LIMIT=PASS
TRI_PHASE_PROBE_SECONDARY_RESTORE_FAILURE=PASS
TRI_PHASE_PROBE_INDEX_LOG_OVERFLOW=PASS
TRI_PHASE_PROBE_REFERENCE_MODEL=PASS_8_TESTS
TRI_PHASE_PROBE_SCOREBOARD=PASS_FOCUSED_STANDALONE_SCOPE
```

Only offline compilation, elaboration, simulation, and reference-model tests
were run.  No build, synthesis, implementation, FPGA program, JTAG, SSH,
MMIO, DMA, or hardware operation was performed by this probe subtask.

## Tool identity

```text
Vivado Simulator=2025.2
SW Build=6299465
IP Build=6300035
Python=AMD Design Tools bundled Python 3.13.0
```

The simulator raw logs in this directory carry the exact tool banners and
terminal PASS markers.

## Exact test-source identities

| Test/reference model | Bytes | SHA-256 |
|---|---:|---|
| `tests/v41/tb_nvp_i2c_tri_phase_probe.sv` | 14855 | `BF87C0920936DE3B22E43D88304B415C9FB05B96211AE5DF9E5B3B16F1E4AD9E` |
| `tests/v41/tb_nvp_i2c_tri_phase_probe_abort_restore.sv` | 5464 | `BA56452CFB9298015E0C073E0196B9BAFB4F148E6A15444551ACF386C2E27F1D` |
| `tests/v41/tb_nvp_i2c_tri_phase_probe_timeout.sv` | 4529 | `59605F224BAA28615C9934CB76C6B3E91CCA4B92E0E09A78E6E97B9E77FE358D` |
| `tests/v41/tb_nvp_i2c_tri_phase_probe_attempt_limit.sv` | 4596 | `9DC27EB9E94E06F97D46B11E35BC8669B94A29BEC9BA4FCA02588CCED5A1016B` |
| `tests/v41/tb_nvp_i2c_tri_phase_probe_secondary_restore_failure.sv` | 3942 | `17F99B976EBC25C90C23F09E6FB4777252FFB263D15FE35AB356121765DCA8F1` |
| `tests/v41/tb_nvp_i2c_tri_phase_probe_index_overflow.sv` | 6152 | `2B62A9E6FAD827DAC5B13AE2CA3B850C9F7AC30D98FB6C906A87711B59261065` |
| `tests/python/test_nvp_r1f_tri_phase_probe_model.py` | 10807 | `08AF9824ADD259499946E9EF553D36AB764E0E597568438945D03B20363A8E1E` |

All RTL tests use reduced count parameters for speed while retaining 25 kHz
and the non-parameterized production target `00/85/00`.

## RTL test matrix

| Test | Stimulus and invariant | Result |
|---|---|---|
| Main interleaved test | Entry bank 2; verified selection of Bank 0; frozen target pre/post value 0; WADDR target NACK indices 1,5; REGADDR prerequisite WADDR NACK on attempt 1 and target NACK index 2; DATA prerequisite WADDR NACK on attempt 1, prerequisite REGADDR NACK on attempt 2, target NACK indices 0,1; 8 target opportunities/phase; two blocks; packed index reads; restoration to Bank 2 | `TRI_PHASE_PROBE_RTL_PASS cycles=39940` |
| Setup abort/restore | Frozen target pre-read returns 1 rather than required 0; no phase transaction may run; exactly one safe-bank selection and one restoration; original Bank 2 re-read and verified | `TRI_PHASE_PROBE_ABORT_RESTORE_PASS cycles=10493` |
| SCL timeout | First WADDR transaction holds released SCL low beyond timeout; protocol state cannot advance; exactly one total/WADDR timeout; target phase remains unreached; original bank restored after line recovery | `TRI_PHASE_PROBE_TIMEOUT_PASS cycles=10606` |
| Attempt limit | Every REGADDR probe WADDR prerequisite NACKs; cap 4 consumed; no REGADDR target sample fabricated; bitmap `010`; WADDR/DATA complete; four scheduler rounds; original bank restored | `TRI_PHASE_PROBE_ATTEMPT_LIMIT_PASS cycles=20563` |
| Secondary restoration failure | Primary safe-target pre-read mismatch remains code `0x04`; best-effort restoration write succeeds; returned verification byte `0x03` is preserved with valid bit; independent secondary code becomes `0x0A`; probe lines release | `TRI_PHASE_PROBE_SECONDARY_RESTORE_FAILURE_PASS cycles=10493` |
| Index-log overflow | Six target NACKs in each phase with capacity reduced to four; aggregate/first/last/run/streak/adjacent statistics remain exact; stored counts stop at four; overflow is explicit; packed words contain indices 0..3 and out-of-capacity words read zero | `TRI_PHASE_PROBE_INDEX_OVERFLOW_PASS cycles=31963` |

The main test additionally proves:

- exact prerequisite opportunities/ACK/NACK reconciliation;
- target ACK+NACK=opportunities for all phases;
- first/last indices use zero-based target-opportunity order;
- run, adjacent-pair, maximum-streak, and block counts match hand scoreboards;
- index words pack `{index[2w+1],index[2w]}`;
- unused index halves/words and invalid phases return zero;
- all setup, target pre/post, bank restoration, final idle, timeout, and line
  release gates are coherent;
- scheduler rounds are 10 for the injected unequal prerequisite-loss pattern;
- terminal scheduler phase is 3 and the attempt-limit bitmap is zero.

## Reference-model test matrix

The final Python unittest run completed eight tests in 0.225 seconds:

1. all-ACK round-robin scheduling;
2. an exact 29-of-10000 WADDR target-NACK pattern;
3. three independently seeded Bernoulli-like phase patterns;
4. clustered NACK runs, adjacent pairs, maximum streak, and blocks;
5. prerequisite NACK semantics and the main RTL hand-scoreboard pattern;
6. zero-based first/last indices and 512-entry index-log overflow;
7. per-phase attempt-limit bitmap with no fabricated target sample;
8. static freeze of production defaults and non-parameterized `00/85/00`.

Captured terminal result:

```text
Ran 8 tests in 0.225s
OK
```

## Raw test-log identities

| Evidence log | SHA-256 |
|---|---|
| `TRI_PHASE_PROBE_XVLOG.log` | `EB519C6B73868A99774782026EDB6C4DB2CCE4481D92D07256DB841AAF3DBDD8` |
| `TRI_PHASE_PROBE_XELAB_MAIN.log` | `640DBAADA84DF6F4FDD4040E6ADC8110DD9747A0CD0B6CF69E26E00A91EA1443` |
| `TRI_PHASE_PROBE_XSIM_MAIN.log` | `CC97017C5D46BBB85A70B5B568221A49A915B98E4A7A9D6E03658D43C1D88F6C` |
| `TRI_PHASE_PROBE_XELAB_ABORT.log` | `A1002AD5CA2FDCC5448FCF38E1241434C0DCC0AEB69A30B630CE8A38FE059311` |
| `TRI_PHASE_PROBE_XSIM_ABORT.log` | `A0F1C31529B88743153701865475F5CFDFD37FD0A29105830AFC7EE1219F6671` |
| `TRI_PHASE_PROBE_XELAB_TIMEOUT.log` | `D8E5E9E3D15ED51033287C2C5431DF11897BE8D30D75EFAB49EF95BC5C787F70` |
| `TRI_PHASE_PROBE_XSIM_TIMEOUT.log` | `0F9E73CDB34127173518A19D3CE0B7111105312116858379D65B09CE01EF1580` |
| `TRI_PHASE_PROBE_XELAB_LIMIT.log` | `E57A0A153597266783A226CD957156894DDFB157B093BE4B214A67C0DCC58786` |
| `TRI_PHASE_PROBE_XSIM_LIMIT.log` | `57DEA7DC5B75B014A0DB81AE8206605FBABEB05BB032CA839CF82D9F2DFB4AF0` |
| `TRI_PHASE_PROBE_XELAB_SECONDARY_RESTORE.log` | `F469849FE1FD23419E56AFC15CA3FDD9DCA853CC0F51BABD582392F3639DEECC` |
| `TRI_PHASE_PROBE_XSIM_SECONDARY_RESTORE.log` | `FCC916336A07BB9C83406F275F7E4E7DEAB52885FF4A2ADB3B81C5D6B779DC45` |
| `TRI_PHASE_PROBE_XELAB_OVERFLOW.log` | `29788235E62BFCFC543D6D08ED042096765E5BEE372A601594B223A6DD948555` |
| `TRI_PHASE_PROBE_XSIM_OVERFLOW.log` | `217D26DDD047CA4D9D0A108B586EC02BA60A4E3A5777A1AD0F93044AB9972EEF` |
| `TRI_PHASE_PROBE_PYTHON_MODEL.log` | `2DDE15A6C2981510E4F5CB31E86E144F7A49D63D691E90AF9424CF58628D49AA` |

Focused elaboration emits only expected warnings that intentionally unused
output ports are unconnected in five specialized testbenches.  The main test
connects the complete audited interface and elaborates without that warning.

## Scope boundary

This focused gate validates the standalone probe engine and its host-facing
read ports.  Full top-level arbitration, complete R1f pre-init equivalence,
register-map integration, and the mission-wide simulation matrix remain
separate parent-task gates.
