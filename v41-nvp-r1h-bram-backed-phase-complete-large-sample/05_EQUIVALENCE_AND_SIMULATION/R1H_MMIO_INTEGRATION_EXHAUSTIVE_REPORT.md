# R1h exhaustive MMIO integration result

## Result

```text
R1H_MMIO_INTEGRATION_EXHAUSTIVE=PASS
MMIO_TRANSACTION_LEVEL_EQUIVALENCE=PASS_COMPLETE_RANGE
ALIGNED_READS_0x20A0_TO_0x35FC=1368_OF_1368
UNALIGNED_READS_0x20A1_TO_0x35FF=4104_OF_4104
UNALIGNED_READ_VALUE=DETERMINISTIC_ZERO
FORWARDED_ALIGNED_WRITES=1368_OF_1368
R1H_RANGE_WRITES_ENTERED_READ_SERVICE=0
ORDER_AND_BUSY_REJECTION_SCENARIOS=PASS
RESPONSE_BACKPRESSURE=PASS_0_TO_4_HELD_CYCLES_PER_ADDRESS
RESET_CANCELLATION_SCENARIOS=PASS_2_OF_2
LOST_RESPONSES=0
DUPLICATED_RESPONSES=0
FULL_BUILDS=0
SYNTHESIS_RUNS=0
IMPLEMENTATION_RUNS=0
```

The authoritative simulation ended at 210796 ns with:

```text
R1H_MMIO_INTEGRATION_EXHAUSTIVE_PASS aligned_reads=1368 unaligned_reads=4104 forwarded_writes=1368 ordering_pairs=1 reset_cancellations=2
```

## Evidence identity

FACT: the exact reference worktree was clean at commit
`e112a5addb7ac62700a9a71af81bf368fad0bada` when the reference decoder was
captured.  The authoritative R1g decoder source SHA-256 is:

```text
BB77188A3A28F34DB3BBC195129A58620D11ECFE4F617528D68002DC1F1FDBFF
```

FACT: `tests/v41/r1g_measurement_regs_reference.sv` is the exact R1g source
except for these two module-identifier substitutions, as proven by
`git diff --no-index`:

```text
v41_r1f_measurement_regs    -> v41_r1g_measurement_regs_reference
v41_r1f_formal_zero_model  -> v41_r1g_formal_zero_model_reference
```

No decoder expression, address, field, parameter, or data path was changed in
the oracle.

The exact candidate/test source hashes used by authoritative run 03 were:

```text
EC246486BD0F5DF0966F6DC81BC8A8EAC17741E2641F8DFE68E276EDBE567542  rtl/v41/r1f_measurement_regs.sv
DFA30D5C4695E02ABFC5EB09ED3FD087DACC45AAE6340A17B00BAFE20D26F2E4  rtl/v41/r1h_mmio_read_service.sv
FAD14CD8E56BCE583FDD643C1828D03A6673ADE22A0B66EE0ED490C48C0F33DD  rtl/v41/control_status_regs.sv
58AB2C44693FA89B60430B583B4FB117FD41EEE5C69359F170BA644B728AC686  tests/v41/r1g_measurement_regs_reference.sv
9DD48EE38DE63C878B3379F1137DD44A23BEF7FC7778581375D30801E31918D0  tests/v41/tb_r1h_mmio_integration_exhaustive.sv
```

The installed simulator was Vivado Simulator 2025.2, SW build 6299465.  Log
identities are:

```text
DA5112B62132305C1FB4A3F250B005B8D86EEE57C34F70345D9AF833D2FE6307  MMIO_INTEGRATION_EXHAUSTIVE_RUN_04/xvlog.log
E5D0FF96F4AAF0CC6975D1656C51D673DE65C6C1979E010FC6D546B0547CEF89  MMIO_INTEGRATION_EXHAUSTIVE_RUN_04/xelab.log
B696D89C74A8D81DED4ED1419E00E6EEE723F12870256D02D199D3EF2F481474  MMIO_INTEGRATION_EXHAUSTIVE_RUN_04/xsim.log
```

## Test architecture

The test instantiates the candidate `v41_r1f_measurement_regs`,
`v41_r1h_mmio_read_service`, and `v41_control_status_regs` as one integrated
request/response path.  The exact R1g decoder is instantiated in parallel as a
transaction-value oracle.

Record payload is represented by a synchronous one-cycle stub with a unique
value for every one of the 64 rows and six words.  Probe-index payload is
represented by a synchronous one-cycle stub with a unique value for every one
of the 512 entries in each of the three phases.  Probe-detail words likewise
have unique controlled values.  Every scalar input to both decoders is tied to
the same controlled constant.

For each aligned address from 0x20A0 through 0x35FC, the test:

1. samples the exact R1g reference value;
2. sends the address through the host request interface;
3. permits the candidate service to consume its actual synchronous memory
   latency, including the two ordered reads required for a packed index word;
4. compares response order and all 32 data bits while ignoring latency;
5. holds response-ready low for zero through four cycles according to a
   deterministic per-address schedule and verifies stable valid/data;
6. accepts the response once and verifies it is not duplicated.

Every unaligned byte address in the same complete range is also issued.  Each
is accepted by the R1h local read service and matches the exact R1g value zero.
The integration interface has no explicit response-status signal; therefore
the accepted normal response path is the implicit OKAY behavior being checked.

An independent two-request scenario keeps the second request asserted while
the first response is backpressured.  It proves the second request is not
accepted early, the first response is returned first, and the second request
is accepted only after the first response handshake.

Two reset scenarios separately cancel (a) a completed scalar response held by
backpressure and (b) an index read after its first BRAM request but before the
packed response is assembled.  Neither cancelled response leaks after reset,
and the subsequent exhaustive transaction sweep proves post-reset service
recovery.

Finally, every aligned address in the range is issued as a write.  The test
checks address, data, byte enables, and write direction at the app interface,
while proving `r1h_req_valid=0`.  This preserves the exact R1g behavior that
the diagnostic range is read-only locally and writes continue to the app path.

## Scope and limitations

SOURCE-DERIVED FACT: this test proves the integrated transaction behavior of
the three named modules for the exact source hashes above.  It is not a proof
for later edits whose hashes differ; such edits require rerunning this test.

SOURCE-DERIVED FACT: stored counts were fixed at 512 for this exhaustive data
comparison so all physical index entries are logically valid.  Request-time
count snapshotting and unused-half masking are tested separately by
`tb_r1h_mmio_read_service.sv`.

SOURCE-DERIVED FACT: no production RTL was edited by this test task.  Added
files are test-only; no commit, synthesis, implementation, or hardware action
was performed.
