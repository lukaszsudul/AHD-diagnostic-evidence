# R1h failed-transaction payload implementation

## Identity

- R1g parent commit: `e112a5addb7ac62700a9a71af81bf368fad0bada`
- R1h source state: uncommitted authorized candidate
- Candidate logger SHA-256: `F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761`
- Candidate logger test SHA-256: `9EC3DD7EDF8BDF1864AFF47E135CF0C6CE85AE5519A31583D830614D20B442A5`
- Vivado Simulator: 2025.2, SW build 6299465, IP build 6300035

## Architecture

`v41_r1f_failed_txn_logger` retains the R1f append, count, overflow, first/last
transaction index, saturation, and protocol-error semantics. Only payload
storage and its read interface change.

- Six independent `xpm_memory_sdpram` instances.
- Each instance is 64 rows x 32 bits (`MEMORY_SIZE=2048`).
- `MEMORY_PRIMITIVE="block"`, common clock, simple dual port, read-first.
- A valid finalized 192-bit record drives six simultaneous writes at one common
  row, preserving one-clock acceptance and record atomicity.
- Payload memories have no clear loop and are never initialized as a semantic
  validity mechanism.
- Reset clears metadata and the read pipeline. Resetting `stored_count` makes
  every old payload row logically unused.
- Read request interface: `record_read_enable/index/word` -> fixed synchronous
  `record_read_valid/data`.
- Validity is captured from `stored_count` at request time. An index that is
  unused when requested returns zero even if that same row is appended on the
  request edge.
- Word selectors 6 and 7 return zero with a normal valid response.
- At 64 stored entries, a 65th input sets overflow and performs no payload
  write; later failures likewise cannot overwrite stored rows.

The exact RAMB18 mapping remains a mandatory post-synthesis gate. No synthesis
or implementation was run in this component step; the six-RAMB18 result is not
claimed from source attributes alone.

## Component verification

Working directory:
`05_EQUIVALENCE_AND_SIMULATION/failed_record_bram_component_iteration_02`

Commands:

```text
C:\AMDDesignTools\2025.2\Vivado\bin\xvlog.bat --sv --work work <logger> <testbench>
C:\AMDDesignTools\2025.2\Vivado\bin\xelab.bat tb_r1f_failed_txn_logger -L xpm -debug typical -s r1h_failed_record_bram_snapshot
C:\AMDDesignTools\2025.2\Vivado\bin\xsim.bat r1h_failed_record_bram_snapshot -tclbatch <run.tcl>
```

`-L xpm` is required at elaboration because the candidate instantiates the
precompiled XPM library directly.

Results:

```text
R1F_FAILED_TRANSACTION_LOG_MATCH_SCOREBOARD=PASS
R1F_LOG_64_EXACT_OVERFLOW_65=PASS
R1F_LOG_UNUSED_ZERO_IMMUTABLE=PASS
R1H_LOG_SYNCHRONOUS_READ_AND_REQUEST_SNAPSHOT=PASS
R1H_LOG_ALL_64_X_6_WORDS_AND_ATOMIC_BANK_WRITE=PASS
```

Evidence SHA-256:

```text
71D27E384AAEFA5A9AF7407A3A51AE2845B9CC9633E80E66BB54802D70ED83C3  xvlog.log
15AE9ECE2D58B2FF15355888F66A6678A6AA2EAB20DF09D6F359D4CD9150F50D  xelab.log
F294D27395B0FF9B5E9666AE2639861A0DE8BB4DE99A789669845CDF48C01017  xsim.log
```

## Scope accounting

```text
SOURCE_MUTATIONS=2_FILES_LOGGER_AND_ITS_TESTBENCH
SOURCE_COMMITS=0
FULL_BUILDS=0
SYNTHESIS_RUNS=0
OPT_DESIGN_RUNS=0
PLACE_RUNS=0
ROUTE_RUNS=0
BITSTREAMS=0
HARDWARE_ACTIONS=0
```
