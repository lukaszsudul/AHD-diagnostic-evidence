# R1h prebuild manifest contract

STATUS: `DESIGN_ONLY_NOT_EXECUTED`

The build script accepts only:

```text
META|KEY|VALUE
SOURCE_SHA256|repository/relative/path|64_HEX_SHA256
ACCEPTED_LOG_SHA256|LABEL|absolute_or_manifest_relative_path|64_HEX_SHA256
```

The complete manifest file is bound by the separately supplied uppercase SHA-256. Duplicate keys, malformed records, missing files, hash mismatches, source paths outside the exact repository, and missing proof labels are fatal before the one-build sentinel is consumed.

Required R1h-specific metadata includes:

```text
SOURCE_GIT_COMMIT=<exact R1h commit>
SOURCE_GIT_TREE=<exact R1h tree>
R1H_BUILD_TCL_SHA256=<hash of executing r1h_build.tcl>
R1G_FROZEN_BUILD_TCL_SHA256=C4BF67C7412E73955D722D678846A3EB72B9E55E8CCC7DFA5279DF5679911E9A
PREBUILD_AUDIT=PASS
R1H_PREBUILD_RELEASE=PASS
SCIENTIFIC_SCOPE_REDUCTION=NO
PRE_INIT_DONE_CYCLE_EQUIVALENCE=PASS
AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
FUNCTIONAL_STATE_SEQUENCE_IDENTICAL=YES
PROBE_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
DIAGNOSTIC_EVENT_STREAM_IDENTICAL=YES
R1H_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0
MMIO_TRANSACTION_LEVEL_EQUIVALENCE=PASS_ALL_ADDRESSES
BRAM_ARCHITECTURE_TESTS=PASS
MMIO_LATENCY_AND_BACKPRESSURE_TESTS=PASS
ALL_R1G_SCIENTIFIC_TESTS=PASS
HOST_TOOL_FIXTURES=PASS
STATISTICAL_SCRIPT_FIXTURES=PASS
```

The manifest also preserves every inherited safety/equivalence gate required by frozen R1g: NVP table, functional FSM, POR/watchdog, SDA/SCL filters, XDC, XDMA XCI, safe target, record-map collision, phase and failed-record scoreboards, bank semantics, index uniqueness, legacy first-eight reconciliation, probe scoreboard, restoration, 64/65 overflow behavior, inherited timing/power/D2B proofs, and production timing model.

Required new accepted-log labels are:

```text
R1H_FAILED_TXN_BRAM_ARCHITECTURE
R1H_PROBE_INDEX_BRAM_ARCHITECTURE
R1H_MEMORY_INFERENCE_ELABORATION
R1H_EVENT_STREAM_EQUIVALENCE
R1H_MMIO_TRANSACTION_EQUIVALENCE
R1H_MMIO_BACKPRESSURE
R1G_VS_R1H_DECODED_FIXTURE_EQUALITY
STATISTICAL_SCRIPT_FIXTURES
```

Every changed path from exact R1e through the final R1h commit is automatically added to the required source-hash set. The task-local build Tcl is bound separately by `R1H_BUILD_TCL_SHA256` because it intentionally resides outside the clean production repository.
