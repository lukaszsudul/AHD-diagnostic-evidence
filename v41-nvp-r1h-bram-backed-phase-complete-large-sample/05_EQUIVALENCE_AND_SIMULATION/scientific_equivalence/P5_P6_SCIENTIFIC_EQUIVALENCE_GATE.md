# R1h P5/P6 scientific equivalence gate

## Exact identities

FACT: the reference worktree was clean at exact R1g commit
`e112a5addb7ac62700a9a71af81bf368fad0bada`, tree
`3a59ebec130103055d24a3a32ecda00dedde5534`.

FACT: the R1h candidate working tree remained based directly on that exact
commit. No VHDL production source or VHDL scientific test changed. Exact
same-byte identities are listed in `VHDL_SAME_BIT_IDENTITY.csv`.

FACT: all runs used Vivado/XSim 2025.2, SW build 6299465. This lane invoked no
`synth_design`, `opt_design`, `place_design`, `route_design`, checkpoint writer,
or bitstream writer.

## Integrated autoinit and immutable VHDL behavior

NETLIST-INDEPENDENT FACT: exact R1g and R1h-candidate copies were compiled into
separate libraries/runs with the default production-compatible VHDL mode and
identical `--2008` testbench mode. Both executions passed and their normalized
transcripts were byte-identical.

| Pair | Covered contract | Normalized transcript SHA-256 | Result |
|---|---|---|---|
| autoinit | all ACK; all 13 transaction kinds; first/middle/final NACK; isolated WADDR/REGADDR/DATA/RADDR; first-eight reconciliation; 13/15/36 historical patterns; bank invariant cases; operation-86 transitional context | `BCF01FA89F1566DCBC876F815AF87193ECDDF6425585A789D64BBFFED3F8393F` | PASS |
| D2b sequence | complete D1 + Z5-ALT sequence with operations 1..148 disabled | `1A6696A631E372E0CCBFB7B8E953B1D37BBF34C73F5DFB709BBEA70606E84AE8` | PASS |
| D2b table gate | 148 disabled, 66 retained, operation 149 boundary | `FE067B4559182ACD1E3BB36A94568B650D2E7B1B396719270A170F6ADC37FDE0` | PASS |
| power | enable/reset/start timing | `AAFBE0F9A8550DF6E03EBF34FBAE3DE8A0D6F5F9456502D336B68FBCC312A127` | PASS |
| serial | unique independent 16-bit transaction index through 300 and reset | `535F99FD261872E0C3E89157B6064CD6B40C9ED6CAC97A0B0D1825B28DBC2A82` | PASS |
| production 62.5-MHz/25-kHz pre-init | direct cycle-by-cycle R1e comparison in each variant; I2C byte stream and functional-state sequence | `850532A5AF3C9776856253D3A3DF5C2A52CD7322F0D78A54D69D2FE6B928AE7C` | PASS |

SOURCE-DERIVED FACT: because the four VHDL design units and their stimuli are
byte-identical between exact R1g and the R1h candidate, the paired executions
exercise the same transition relation. The production pre-init test also
compares every candidate cycle directly against the exact frozen R1e behavior;
its final fresh result is the fail-closed release condition below.

SIMULATION-DERIVED FACT: both full-duration production pre-init simulations
reached 2,121,355,816 ns and emitted all three required markers. The exact R1g
reference XSim log SHA-256 is
`05333452F4D94869462395FC0D4B6CBC0D5233BF0C120CEB8C5C92D8C0EF8403`;
the R1h-candidate log SHA-256 is
`BC927CE4DB941E3FB3021FE02FD2D8BBF66483DFFBBCCDDBDCDB50A3F8C81FC6`.
Each log has zero failure diagnostics. Their normalized transcripts are
byte-identical with SHA-256
`850532A5AF3C9776856253D3A3DF5C2A52CD7322F0D78A54D69D2FE6B928AE7C`.
The pair receipt SHA-256 is
`48544003519FD90A844BE860FF5DD7455091A2DF7E26AB98D579E84A8457244A`.

## Strict R1g/R1h probe pair

FACT: a task-local generator transformed the exact R1g probe only by renaming
its module identifier, then instantiated it beside the current R1h probe. The
reference source SHA-256 was
`4AA823B5896D9C11DB9837D1F30E4E077557FE367942B032B404ACBA92E03552`; the
candidate probe SHA-256 was
`D459FC7AE6D72F1B604974CADDF4D633468334D9D488818746A0C0B5EE22B4DD`.

SIMULATION-DERIVED FACT: on every compared clock, the paired harness checked 83
common output ports, including SCL/SDA release, lifecycle, safe-target and bank
state, all prerequisite/target/timeout statistics, scheduler state, index
counts/overflow, and block-read values. It separately checked the low-level and
high-level FSMs, latched I2C kind/register/data, reached/ACK events, transaction
start/done pulses and read data. Only the explicitly authorized changed
synchronous index-read latency interface was excluded from cycle equality.

SIMULATION-DERIVED FACT: the five injected logical index-creation events were
checked against the R1h BRAM write phase, address, and data. After termination,
every stored index was read synchronously and compared transactionally with the
exact R1g chronological payload. Every block value was compared.

```text
R1G_R1H_PROBE_CYCLE_BY_CYCLE_COMMON_OUTPUT_EQUIVALENCE=PASS
R1G_R1H_PROBE_I2C_AND_FSM_EVENT_STREAM_EQUIVALENCE=PASS
R1G_R1H_PROBE_BLOCK_STATISTICS_EQUIVALENCE=PASS
R1G_R1H_PROBE_INDEX_TRANSACTION_EQUIVALENCE=PASS
COMMON_OUTPUT_COUNT=83
INDEX_CREATION_EVENTS=5
XSIM_LOG_SHA256=D8440A7A5A5F50764F04D7F21246069B1005F4BDCAC5C9DB783C3FCE7E178BAF
VCD_SHA256=E24652DA16ED0216A3EBABC28F8EA1E3EF6E27367B6233C678558A92EC14BAB6
VCD_BYTES=3788748
```

FACT: all seven inherited probe cases produced exactly the same terminal PASS
marker and cycle count as exact R1g. The 10,000-opportunity-per-phase all-ACK
production run also had an exact salient transcript match:

```text
R1F_PROBE_CYCLES_FROM_INIT_DONE=29415318
R1F_PROBE_SECONDS_FROM_INIT_DONE=29.415318000
MODELED_R1F_PROBE_COMPLETE_SECONDS_FROM_CONFIGURATION=31.536673744
ARM_A_REQUIRED_WAIT_SECONDS=33.536673744
```

Candidate production log SHA-256:
`27AC9B4AB2CA92CCFFECFC4FBCA12F6B909525B5DBCC5AC9D92FD574030D5A10`.
The run additionally checked all 30 completed-block valid bits and all exact
10-block cursor terminal states.

## Storage atomicity, concurrency and no loss

FACT: all 64 failed records, all six words, unused-zero behavior, concurrent
append/read behavior, exact overflow on failure 65, and no overwrite passed.
Log SHA-256:
`F294D27395B0FF9B5E9666AE2639861A0DE8BB4DE99A789669845CDF48C01017`.

FACT: a supplemental test proved three complete 192-bit records on consecutive
clock edges. Another supplemental test proved consecutive same-bank index
writes and simultaneous same-BRAM, different-address host read/probe write.
Their log SHA-256 values are respectively
`50BEDA2BF68CB94740608C2D2FFE42A866FF8348D6AC848C75A0F31114E8E5C5`
and `FB0DE6800028E2B67DD3A2699278C7D4F66E1C3B981A44D38899DF45C26E89D2`.

SOURCE-DERIVED FACT: the production probe producer has a conservative lower
bound greater than 1,251 clocks between logical index events, while the BRAM
store accepts one index every clock. The logger independently accepts one full
record every clock. See `EVENT_SPACING_AND_NO_LOSS_PROOF.md`.

## MMIO transaction equivalence and functional isolation

FACT: the reset-coherent exhaustive MMIO regression is bound to final
candidate top SHA-256
`D37A7ECC4C4335149428A75FFE71E0C2FA128F69AEA8E0781658DD22ED65623E`
and service SHA-256
`00ECE27375BE07D52E8FA4BF07F535AB29DC39A099AF4FC148BF654E0073BA2B`.
It checked all 1,368 aligned DWORD addresses in `0x20A0..0x35FF`, all 4,104
unaligned byte addresses, all 1,368 forwarded writes, ordering, busy rejection,
arbitrary response backpressure, NVP/AXI reset cancellation and recovery. The
current-R1h service and integration XSim logs have SHA-256 values
`4479BD039180B0D7EED39A2963DBBF34B7B85BB549DB8D1DD5B6566CBC0D752D`
and `A26C1F98E17F1DB42E1DBB5ABB677AF8626EBE0F71EA100940A2990E7EBD3977`;
both have zero failure diagnostics. The superseding report SHA-256 is
`D54CDFD10300EE9CB71D741FE7E7CEDEE5B2A5CD0DF8D80B6A1D561C586AB4FA`.

SOURCE-DERIVED FACT: the independent source-scope audit proves zero new
diagnostic-to-functional fanout and zero new CDC. Host record/index reads reach
only the payload read ports and response service; their data cannot reach the
functional NVP FSM, SCL/SDA release requests, reset/power controls, NVP table,
watchdog, filters, or video path. Its SHA-256 is
`B97C46A1C259D12D6491CF2D997E252433EDFC992E3B447CB5DB08C574E8FCEA`.

## Fail-closed log audit

FACT: all authoritative logs listed in `AUTHORITATIVE_LOG_DIAGNOSTIC_AUDIT.csv`
were searched for start-of-line `ERROR`/`FATAL`, assertion violations, VHDL
`severity failure`, executed `$fatal`, and standalone `FAIL`/`FAILED`; the final
count is zero for every accepted row.

FACT: three failed task-local probe harness iterations are retained and
explicitly rejected in `probe_pair/HARNESS_ITERATION_CLASSIFICATION.md`. Two
never passed an HDL filename because of a runner bug; one failed only while
compiling an unsupported nested X-macro harness form. None reached design
simulation and none is used by this gate.

## Gate result

```text
R1H_SCIENTIFIC_EQUIVALENCE_GATE=PASS
P5_SOURCE_LEVEL_SCIENTIFIC_EQUIVALENCE=PASS
P6_SCIENTIFIC_SIMULATION_MATRIX=PASS
PRE_INIT_DONE_CYCLE_EQUIVALENCE=PASS
AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
FUNCTIONAL_STATE_SEQUENCE_IDENTICAL=YES
PROBE_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
DIAGNOSTIC_EVENT_STREAM_IDENTICAL=YES
R1H_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0
MMIO_TRANSACTION_LEVEL_EQUIVALENCE=PASS_ALL_ADDRESSES
MMIO_STORAGE_LATENCY_EXCLUDED_FROM_THIS_REPORT=YES_AUTHORIZED
SYNTHESIS_OR_IMPLEMENTATION_INVOKED_BY_THIS_LANE=NO
BLOCKERS=NONE
FINAL_GATE=PASS
```
