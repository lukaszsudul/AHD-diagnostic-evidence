# R1h-R2 P5 prebuild identity and no-RTL-change gate

## Disposition

This is an independent, read-only audit of the exact terminal R1h scientific
source and immutable published R1h evidence. No Vivado frontend, simulation,
synthesis, implementation, Git mutation, hardware operation, or manifest
generation was performed. The only new artifact is this task-local report.

```text
P5_PREBUILD_IDENTITY_AND_NO_RTL_CHANGE_GATE=PASS
R1H_SCIENTIFIC_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SCIENTIFIC_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_RTL_BLOBS_UNCHANGED=YES
R1H_XDC_UNCHANGED=YES
R1H_XDMA_XCI_UNCHANGED=YES
R1H_REGISTER_MAP_UNCHANGED=YES
R1H_HOST_DECODERS_UNCHANGED=YES
R1H_STATISTICAL_PLAN_UNCHANGED=YES
R1H_SIMULATION_RESULTS_REPLAY=EXACT_PUBLISHED_PASS_REUSED
R1H_OOC_BRAM_INFERENCE_REPLAY=PASS_6_PLUS_3_EXACT_PUBLISHED_RECEIPT_REUSED
PROJECT_SETUP_DRY_RUN=PASS
SEMANTIC_ELABORATION=PASS
```

## Exact Git identity

FACT - fresh read-only Git queries returned:

```text
SOURCE_REPOSITORY=C:\FPGA\WORKTREES\V41_NVP_R1H_BRAM_BACKED_LARGE_SAMPLE
SOURCE_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_DIRECT_PARENT=e112a5addb7ac62700a9a71af81bf368fad0bada
WORKTREE_STATUS_PORCELAIN_ENTRIES=0
WORKTREE_CLEAN=YES
FPGA_RTL_SOURCE_CHANGES_BY_R1H_R2=0
TRACKED_BUILD_HARNESS_COMMITS=0
BUILD_PROVENANCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
BUILD_PROVENANCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
```

No tracked harness-only child exists or is needed. The corrected R1h-R2
harness remains task-local, SHA-256
`5A43D241DA4092E51A3A4A4EB112E06FC9BF333C6CD9817DA0111EDDF2DCB38F`.

## Published-evidence hash chain

FACT - P0 independently proved the exact public evidence commit
`7dc8b8fb07033148e7c232c235da012d8b14b621`, authoritative report SHA-256
`E7B41C0DD5CF21499BE55D8C4019F07694B1255252AB7539A1A376E7839B6468`,
and package SHA-256
`C56FE89CE24403FE7BD4702B53778BA4C2B5403536185BCC66EB32B8118CBC78`.
It replayed the package manifest 1,799/1,799 and ZIP contents 1,800/1,800.

This P5 audit independently followed the source/test subset of that chain:

```text
R1H_PUBLISHED_SHA256_MANIFEST_SHA256=263088E4D07E25844FFD7A60070B201B0CE706FAF8DF9BC708625FCBBF717DD5
R1H_PUBLISHED_SHA256_MANIFEST_ROWS=1799
R1H_PREBUILD_MANIFEST_SHA256=192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79
R1H_PREBUILD_MANIFEST_BYTES=35266
PUBLISHED_PREBUILD_MANIFEST_HASH_AND_SIZE_MATCH=YES
```

The immutable R1h prebuild manifest is used here only as the published source
and accepted-test hash anchor. Its historical build-Tcl field names the exact
terminal R1h harness (`2E6E...`), which intentionally is not the corrected R2
harness authority. No field in that historical artifact was edited.

## Complete tracked-source closure

SOURCE-DERIVED FACT - the prebuild manifest contains exactly 224
`SOURCE_SHA256` rows. The exact commit contains exactly 224 tracked paths.
Every manifest path is tracked at `c4f4...`; every current file exists and its
fresh SHA-256 equals the published row:

```text
SOURCE_SHA256_ROWS=224
GIT_TRACKED_PATHS=224
SOURCE_PATHS_NOT_TRACKED=0
SOURCE_FILES_MISSING=0
SOURCE_SHA256_MISMATCHES=0
SOURCE_MANIFEST_REHASH=PASS_224_OF_224
```

This complete closure subsumes the requested classes:

| Tracked blob class | Rows | Missing/hash mismatch | Result |
|---|---:|---:|---|
| `rtl/**` | 30 | 0 | PASS |
| `xdc/**` | 8 | 0 | PASS |
| `*.xci` | 4 | 0 | PASS |
| `scripts/v41/**` | 23 | 0 | PASS |
| `tests/v41/**` | 19 | 0 | PASS |
| `tests/python/**` | 4 | 0 | PASS |

The production project subset separately proven by P3 contains the exact 17
SystemVerilog plus four VHDL sources, seven XDCs, and the unchanged production
XDMA XCI. The production XCI is:

```text
ip/v41/xdma_v41_m1.xci
SHA256=EA651CA26A2FE4AA5201A5E88BA41D9BD737A3BF19D58AA89394D1CB8C1B0A7C
```

All four tracked XCI blobs and all eight tracked XDC blobs match the exact
commit and published prebuild manifest; the statement above identifies which
XCI and seven-XDC subset the unchanged R1h build consumes.

## Register-map and MMIO contract blobs

SOURCE-DERIVED FACT - the direct map/decode/response and verification closure
is byte-identical to exact `c4f4...` and to the 224-row published source
manifest. Key identities are:

| Blob | SHA-256 |
|---|---|
| `rtl/v41/control_status_regs.sv` | `FAD14CD8E56BCE583FDD643C1828D03A6673ADE22A0B66EE0ED490C48C0F33DD` |
| `rtl/v41/r1f_measurement_regs.sv` | `EC246486BD0F5DF0966F6DC81BC8A8EAC17741E2641F8DFE68E276EDBE567542` |
| `rtl/v41/r1h_mmio_read_service.sv` | `00ECE27375BE07D52E8FA4BF07F535AB29DC39A099AF4FC148BF654E0073BA2B` |
| `scripts/v41/read_nvp_r1e.py` | `0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037` |
| `scripts/v41/read_nvp_r1f.py` | `5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C` |
| `tests/v41/r1g_measurement_regs_reference.sv` | `58AB2C44693FA89B60430B583B4FB117FD41EEE5C69359F170BA644B728AC686` |
| `tests/v41/tb_r1f_measurement_regs.sv` | `8F64CE2852C2C4325B5B83AFAA3EC945BD4EFD0C59CB385F2B62B390F8C26054` |
| `tests/v41/tb_r1h_mmio_integration_exhaustive.sv` | `6DE31F62629E0C64D35700DD1A57193C5F4240A224B4BF4763D69076FD61BD68` |
| `tests/v41/tb_r1h_mmio_read_service.sv` | `2EA788E5A9CA5D9F5663A0A1595009BDB20D7D1F81F8BE917721F79BFE802B40` |

The address-bearing source search closes on the same exact committed RTL,
reader, and verification files for `0x20A0..0x35FF`. The published superseding
MMIO report is unchanged at SHA-256
`D54CDFD10300EE9CB71D741FE7E7CEDEE5B2A5CD0DF8D80B6A1D561C586AB4FA`.
It records exhaustive equality for all 1,368 aligned DWORD addresses, all
4,104 unaligned byte addresses, response ordering/backpressure/reset behavior,
and `LOST_RESPONSES=0`, `DUPLICATED_RESPONSES=0`. Therefore exact-source
identity plus exact published transaction evidence proves:

```text
R1H_REGISTER_MAP_UNCHANGED=YES
R1H_MMIO_RESPONSE_DATA_AND_ORDER_UNCHANGED=YES
R1H_R2_LATENCY_CHANGE=NO
```

## Host decoders and frozen statistical plan

FACT - the exact committed host/statistical sources and the frozen published
R1h host-tool copies are byte-for-byte equal:

| Source/frozen pair | SHA-256 | Equal |
|---|---|---|
| `read_nvp_r1e.py` | `0BE8AD0ECEF0FC333FEDFFAC9C7D94D2851E7FC319EEB88579D7EA3B2AEA7037` | YES |
| `read_nvp_r1f.py` | `5BDE0B94E8817DA9EC92FBE8BF7149E93C631E348FCD0B395D4EA539EC2A734C` | YES |
| `r1f_statistics.py` | `C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD` | YES |
| `test_nvp_r1f_tools.py` | `7AD2E8FA36D685CFC916B007A65BE9B807398A71CB6730E067C31CD9673C52B1` | YES |
| `fixtures/r1f_valid_scenario.json` | `8D6C63878488F79B1299F1AD2576EF830C52741F2938A9715EC597FBF4FAB1A8` | YES |

The committed independent probe/statistics model is unchanged at SHA-256
`08AF9824ADD259499946E9EF553D36AB764E0E597568438945D03B20363A8E1E`.
The immutable host gate SHA-256 is
`8AA3DC0829CB43DA32401A87E7C5D531694B0515BC5BF2FA9AE51C7EE7AE5B30`
and records `HOST_TOOL_FIXTURES=PASS_24_OF_24`,
`STATISTICAL_SCRIPT_FIXTURES=PASS`, and `HOST_MMIO_WRITES=0`.

```text
R1H_HOST_DECODERS_UNCHANGED=YES
R1H_STATISTICAL_PLAN_UNCHANGED=YES
HOST_TOOL_FIXTURES=EXACT_PUBLISHED_PASS_REUSED
STATISTICAL_SCRIPT_FIXTURES=EXACT_PUBLISHED_PASS_REUSED
```

## Exact published simulation reuse

FACT - all 32 `ACCEPTED_LOG_SHA256` rows in the immutable R1h prebuild
manifest were freshly rehashed. They reference 11 unique files. All 32 rows
are also present with identical hashes in the published 1,799-row manifest:

```text
ACCEPTED_LOG_ROWS=32
ACCEPTED_LOG_UNIQUE_FILES=11
ACCEPTED_LOG_MISSING=0
ACCEPTED_LOG_SHA256_MISMATCHES=0
ACCEPTED_LOG_PUBLISHED_MANIFEST_MISMATCHES=0
ACCEPTED_LOG_REHASH=PASS_32_OF_32
```

The principal immutable scientific receipts are:

| Published receipt | SHA-256 | Reused result |
|---|---|---|
| Scientific/event equivalence gate | `6879A5D0F58783D156BD08336FF06B27CFDB6096A2E58A1976A1357C2F343283` | P5/P6 PASS |
| Reset-coherent MMIO integration | `D54CDFD10300EE9CB71D741FE7E7CEDEE5B2A5CD0DF8D80B6A1D561C586AB4FA` | PASS current RTL |
| Probe BRAM/block statistics | `2A41F04EFE929256148C2B411ECBB40852C5178FFFB6FEDD63C129460816D9A4` | PASS matrix |
| Failed-record BRAM implementation | `A2082BB9BF1061890DD0B49975DE4990237AA35B7BE9E3450EF469A363B3069B` | PASS 64/65 semantics |
| Host/statistics gate | `8AA3DC0829CB43DA32401A87E7C5D531694B0515BC5BF2FA9AE51C7EE7AE5B30` | PASS 24/24 plus statistics |

The scientific receipt records:

```text
PRE_INIT_DONE_CYCLE_EQUIVALENCE=PASS
AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
FUNCTIONAL_STATE_SEQUENCE_IDENTICAL=YES
PROBE_TRANSACTION_STREAM_BYTE_IDENTICAL=YES
DIAGNOSTIC_EVENT_STREAM_IDENTICAL=YES
R1H_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=0
MMIO_TRANSACTION_LEVEL_EQUIVALENCE=PASS_ALL_ADDRESSES
```

No simulation was rerun in R1h-R2 because exact published PASS reuse is the
explicitly permitted P5 path and no scientific blob changed.

## Exact OOC 6+3 receipt reuse

NETLIST-DERIVED HISTORICAL FACT - the immutable published OOC result is:

```text
MEMORY_INFERENCE_RESULT_SHA256=C32709568814661F51F7D7F4C4C534ED390FA63328E14591AC718B7F7C73CA22
VIVADO_VERSION=2025.2
PART=xc7a35tcsg325-2
FAILED_RECORD_RAMB18=6
FAILED_RECORD_RAMB36=0
FAILED_RECORD_RAM64M=0
FAILED_RECORD_RAMD64E=0
PROBE_INDEX_RAMB18=3
PROBE_INDEX_RAMB36=0
MEMORY_INFERENCE_GATE=PASS
```

The three source hashes frozen by that OOC report freshly match exact
`c4f4...`:

| OOC input | SHA-256 |
|---|---|
| `rtl/v41/r1f_failed_txn_logger.sv` | `F8B11E29D99E6FA548899681C2A9A3D76144DB3EAC73BFBDE599462E488C7761` |
| `rtl/v41/r1h_probe_index_bram_store.sv` | `67410872DE78C7C48531E96E831E82ED5D97AF2EDF42F34C4FADB2C7EAE8433F` |
| `tests/v41/r1h_memory_inference_top.sv` | `7B77B07339ADA100B43348316877EF6CCB1C636DFF8671DCCAA6C6045E1A6B82` |

This proves exact reuse of the accepted OOC wrapper mapping. It does not claim
that full-top synthesis has already mapped 6+3 RAMB18. Full-top primitive and
resource mapping remains a mandatory, fail-closed post-synthesis gate in the
single R1h-R2 clean build.

## Fresh R1h-R2 P3 and P4 gates

FACT - the one project-setup dry-run passed and the independent audit confirmed
one Vivado PID, process exit zero, semantic source gate PASS, compile order
recorded but not used as a SystemVerilog relative-position gate, and zero
forbidden build commands:

```text
P3_RESULT_SHA256=F5AC518813A394E38F1D969F2802907994903DB76CD26DE4E59D998A5DDBCFB6
P3_INDEPENDENT_AUDIT_SHA256=3232F2FA10C6036C3D8D7F3F8E9A3CBC45BAEA4821B8F7A2739F14806F3C60AD
PROJECT_SETUP_DRY_RUNS=1
PROJECT_SETUP_DRY_RUN=PASS
PROJECT_SETUP_SEMANTIC_GATE=PASS
R1H_FALSE_ASSERTION_TRIGGERED=NO
```

FACT - the one semantic frontend/elaboration preflight passed with all exact
production sources and required bindings, zero unresolved modules/black boxes,
and no synthesis or implementation invocation:

```text
P4_RESULT_SHA256=95A60F11432DA014AAF4B63989AFCF1FFD217139D8B979BB50CFD67EE1B1BDFD
P4_INDEPENDENT_AUDIT_SHA256=90BE8B4EBF4EFD3EFD5211A6FDA338B91EC55020EDC6F9132CD44E219AD32A69
P4_SEMANTIC_INPUT_SHA256_CSV=3BD47D6A84C8A9FC2DABE2E5079F048EF5DBCC2E7BF419AD4676B406556011E3
SEMANTIC_ELABORATION_PREFLIGHTS=1
SEMANTIC_ELABORATION=PASS
R1H_TEST_ELABORATION=PASS
UNRESOLVED_MODULES=0
UNRESOLVED_BLACKBOXES=0
FAILED_RECORD_WRAPPER_BINDING=PASS
PROBE_INDEX_WRAPPER_BINDING=PASS
PROCESS_EXIT_CODE=0
```

P4 independently rehashed all 23 elaboration inputs before and after the run
(four production VHDL, 17 production SystemVerilog, and two simulation-support
files) with zero mismatch. The source repository remained exact and clean.

## Gate conclusion

The exact published R1h scientific source, storage/MMIO RTL, constraints, XCI,
register-map contract, host decoders, frozen statistics, accepted simulation
receipts, and OOC 6+3 inference receipt are unchanged. The only R1h-R2 delta is
the already audited task-local build-harness gate. P3 proves exact project
registration and semantic file properties; P4 proves actual frontend binding.

```text
TASK=V41_NVP_R1H_R2_BUILD_HARNESS_CORRECTION_AND_LARGE_SAMPLE_EXECUTION
GATE=P5_PREBUILD_IDENTITY_AND_NO_RTL_CHANGE
R1H_SCIENTIFIC_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SCIENTIFIC_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_RTL_MANIFEST_EQUAL_TO_C4F4BFCF=YES
R1H_RTL_BLOBS_UNCHANGED=YES
R1H_XDC_UNCHANGED=YES
R1H_XDMA_XCI_UNCHANGED=YES
R1H_REGISTER_MAP_UNCHANGED=YES
R1H_HOST_DECODERS_UNCHANGED=YES
R1H_STATISTICAL_PLAN_UNCHANGED=YES
R1H_SIMULATION_RESULTS_REPLAY=EXACT_PUBLISHED_PASS_REUSED
R1H_OOC_BRAM_INFERENCE_REPLAY=PASS_6_PLUS_3_EXACT_PUBLISHED_RECEIPT_REUSED
PROJECT_SETUP_DRY_RUN=PASS
SEMANTIC_ELABORATION=PASS
P5_PREBUILD_IDENTITY_AND_NO_RTL_CHANGE_GATE=PASS
FPGA_RTL_SOURCE_CHANGES=0
TRACKED_BUILD_HARNESS_COMMITS=0
FULL_CLEAN_BUILDS=0
SYNTH_DESIGN_INVOCATIONS_BY_P5=0
OPT_DESIGN_INVOCATIONS_BY_P5=0
PLACE_DESIGN_INVOCATIONS_BY_P5=0
ROUTE_DESIGN_INVOCATIONS_BY_P5=0
BITSTREAMS_BY_P5=0
HARDWARE_ACTIONS_BY_P5=0
FULL_TOP_BRAM_MAPPING_CLAIM=NOT_YET_AVAILABLE_REQUIRES_AUTHORIZED_FULL_BUILD
NEXT_GATE=ONE_NEW_CLEAN_PROVENANCE_CORRECT_R1H_R2_BUILD
```
