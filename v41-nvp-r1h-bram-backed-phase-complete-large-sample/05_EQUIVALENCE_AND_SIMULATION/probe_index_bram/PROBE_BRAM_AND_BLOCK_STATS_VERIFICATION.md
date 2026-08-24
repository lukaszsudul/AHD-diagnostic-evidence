# R1h probe-index BRAM and block-statistics verification

SOURCE-DERIVED FACT: The candidate worktree is a direct working-tree delta
from R1g source commit `e112a5addb7ac62700a9a71af81bf368fad0bada`.

FACT: All tests and the one bounded inference check used Vivado/XSim 2025.2,
SW build 6299465, part `xc7a35tcsg325-2` for inference.

## Architecture

SOURCE-DERIVED FACT: `r1h_probe_index_bram_store` contains three independent
XPM simple-dual-port memories. Each payload is 512x16, common-clock, block
primitive, one write port and one synchronous entry-read port. Payload has no
reset. The probe retains count/overflow semantics and emits a one-cycle payload
write event only when an index is accepted.

SOURCE-DERIVED FACT: Completed block statistics use a 30x32 distributed-memory
payload without payload reset, 30 valid bits, three 32-bit live NACK counts,
three 16-bit within-block positions, and three 4-bit block indices. The update
path contains no division or modulo. A completing opportunity commits exactly
the updated live count, including its own NACK outcome.

## Simulation results

FACT: The inherited probe test matrix passed 7/7:

- `TRI_PHASE_PROBE_RTL_PASS cycles=39940`
- `TRI_PHASE_PROBE_ABORT_RESTORE_PASS cycles=10493`
- `TRI_PHASE_PROBE_TIMEOUT_PASS cycles=10606`
- `TRI_PHASE_PROBE_ATTEMPT_LIMIT_PASS cycles=20563`
- `TRI_PHASE_PROBE_SECONDARY_RESTORE_FAILURE_PASS cycles=10493`
- `TRI_PHASE_PROBE_INDEX_OVERFLOW_PASS cycles=31963`
- `TRI_PHASE_PROBE_IDLE_TIMEOUT_COMPAT_PASS cycles=30`

FACT: The production-timing simulation passed with all 30 completed-block
valid bits set, every block count zero for the all-ACK model, every phase cursor
at block 10/position 0/live 0, and:

```text
PASS R1F_PRODUCTION_TIMING_MODEL
R1F_PROBE_CYCLES_FROM_INIT_DONE=29415318
R1F_PROBE_SECONDS_FROM_INIT_DONE=29.415318000
MODELED_R1F_PROBE_COMPLETE_SECONDS_FROM_CONFIGURATION=31.536673744
ARM_A_REQUIRED_WAIT_SECONDS=33.536673744
```

FACT: The direct BRAM payload test wrote and read all 1,536 locations, tested
simultaneous different-bank read/write, invalid-phase zero, and preservation of
payload across reset:

```text
R1H_PROBE_INDEX_BRAM_STORE_PASS entries=1536 banks=3
```

FACT: Pre-init open-drain arbitration also passed:

```text
PASS R1F_PRE_INIT_EFFECTIVE_OPEN_DRAIN_ARBITRATION
```

## Bounded memory-inference check

FACT: Exactly one `synth_design` invocation was used for this subtask. It was a
bounded OOC inference-only run with top `r1h_probe_index_bram_store`; it was not
the project top/full build and invoked no opt/place/route/checkpoint/bitstream.

NETLIST-DERIVED FACT: Final OOC cell mapping:

```text
RAMB18E1=3
RAMB36E1=0
FDRE=3
RAM64M=0
RAMD64E=0
MUXF7=0
MUXF8=0
```

NETLIST-DERIVED FACT: Each named `GEN_INDEX_BRAM[0..2]` payload maps to exactly
one `RAMB18E1`. The full-project post-synthesis gate remains authoritative for
the integrated mapping and for the completed-block LUTRAM inference.

## Frozen file hashes

```text
67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F  rtl/v41/r1h_probe_index_bram_store.sv
D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD  rtl/v41/nvp_i2c_tri_phase_probe.sv
128EF41613C1B13A4E394D3F1722C085DDDA21CFF702995A0515C1F1248B6A34  tests/v41/tb_nvp_i2c_tri_phase_probe.sv
8539D5378624738EA4D2FBCF94203AE36C8A76526C9FA822E254267AB0615474  tests/v41/tb_nvp_i2c_tri_phase_probe_abort_restore.sv
703B6EF5F2A7EF8DCC464B918677C685F463F07AC2D6A6D63C17391E760B227D  tests/v41/tb_nvp_i2c_tri_phase_probe_attempt_limit.sv
6CC2B42D6B06E46444593F1E78FC7BD8DEAEB18192EEAC267E84176CD9663EA5  tests/v41/tb_nvp_i2c_tri_phase_probe_idle_timeout.sv
2E60DD6FDC4F8F2D1CB94CD26167CD471C8358B9AA755453226CAF0CDECC384E  tests/v41/tb_nvp_i2c_tri_phase_probe_index_overflow.sv
241F8B59392DC893F62F5C5DC231DCA5063655E1F7D292296EEFEA0A9E51481B  tests/v41/tb_nvp_i2c_tri_phase_probe_secondary_restore_failure.sv
E8AFF41C5E43326156CC5E357380B180931606E4F6145CD7ACD1E31AF23FB618  tests/v41/tb_nvp_i2c_tri_phase_probe_timeout.sv
AD4884DE8237CED872BBE8779A7488FC0469B4C4DC6B66BF59D64F9AD3B32C94  tests/v41/tb_r1f_preinit_arbitration.sv
04203B9DF8874463FFEBB655D74BC2CB5C7E69AFD6F337906BCFBA0D7C7216FB  tests/v41/tb_r1h_probe_index_bram_store.sv
```
