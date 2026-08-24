# V41 NVP R1f phase-complete observability final report

## Outcome

R1f completed its authorized diagnostic design, source audit, safe-probe
selection, simulation matrix, cycle-equivalence proof, host-tool fixtures,
frozen statistical plan, single source commit, and hash-bound pre-build
release. The one authorized clean build was then consumed and failed during
RTL elaboration/synthesis. Vivado reported:

```text
ERROR: [Synth 8-2757] this construct is only supported in VHDL 1076-2008
       [rtl/nvp/nvp6134c_i2c_bringup.vhd:994]
ERROR: [Synth 8-12189] Failed to read vhdl
RTL Elaboration failed
```

Committed line 994 is the diagnostic-only conditional signal assignment
`r1f_tx_wdata_r <= write_data when is_read_op = '0' else x"00";`. The build
log records exactly one `synth_design` invocation and exit code 1. The
one-build sentinel had already been atomically created, so the owner's
no-second-build and no-source-correction rules required the terminal
classification:

```text
BLOCKED_ONE_CLEAN_BUILD_SYNTHESIS_VHDL_2008_CONSTRUCT
```

No implementation run, synthesis DCP, routed DCP, or R1f bitstream exists.
The task therefore stopped before the hardware start-state gate. There was no
JTAG or SSH session, FPGA program, reboot, driver load, MMIO access, DMA, or
physical action in R1f.

## Frozen input and source identity

| Object | Exact identity |
|---|---|
| R7 evidence repository commit | `16beec37a266c421da5838fbb986301d072cbb50` |
| R7 evidence package | `A1864DA7EC52AEE852169656808510C42D98FDCE27816D82449946B610DD2A56` |
| Exact R1e base commit | `f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd` |
| Exact R1e base tree | `db8b5581a237e19905fd01c6d453793047bc3ba7` |
| R1f source commit | `225544084dbfcaadb8592fcecc947aa1cec4970e` |
| R1f source tree | `cfde8769af95cf20586391c411fab3ddfa2c87b6` |
| Commits above R1e base | 1 |
| Owner prompt | `83FB94A3EF41A884323528BDA9D75412F6710B739E1D531A54A218324268670D` |
| Pre-build manifest | `34626CAFDF0D2CD6A4DA87B6D7ED6C7146B4C16E7384BD5AA3927BE440859A04` |
| Frozen R1f build Tcl | `53813BB6A120EC2CD454A614667FB2824A5CABFFA54D58C9A158C1C25E62C55B` |

The source worktree remained clean after the single R1f commit. The evidence
contains the full-index binary-capable commit patch, commit/tree proof,
per-source hashes, accepted simulation-log hashes, and a copy of the exact
build Tcl. The diagnostic branch was not pushed: the owner authorized that
push only after build PASS, which did not occur.

## Historical semantics and safe target

The exact R1e source audit proved that the internal legacy operation index is
bounded at 255 and saturates rather than wraps. Its six-bit diagnostic alias
is modulo 64, while eight-bit legacy fields retain the saturated value. It is
not a unique transaction serial, and multiple selector, verify, and target
transactions can share it.

Exact table/source replay maps R7 operation 86 to table slot 85, Bank 2,
register `0x02`, data `0x03`, in a bank-verify read. The old record's physical
Bank 9, requested/metadata Bank 2, register `0xFF`, and invalid placeholder
write data are consistent with legal transitional context. The old overloaded
record does not prove tracker corruption.

The bounded authoritative audit selected Bank `0x00`, register `0x85`
(`SPL_MD_CH1`), data `0x00` as the safe data-probe target. The datasheet and
exact R1e table prove it is a normal mode register and that the same value is
already written repeatedly. The frozen contract requires verified Bank 0,
pre-read `0x00`, same-value writes only, post-read `0x00`, exact restoration
and readback of the entry bank, and released lines. This contract passed
offline review but was not exercised in R1f hardware.

## R1f diagnostic implementation and offline proof

The committed diagnostic-only delta adds the requested independent phase
opportunity/NACK counters, 16-bit transaction serial and 16-bit table-slot
index, append-only 64-entry 192-bit failed-transaction log, explicit bank
before/requested/selector/verify/after semantics, passive invariant counters,
round-robin WADDR/REGADDR/DATA probe, and version-gated read-only register
map/tooling. The probe target and frozen counts are Bank `00`, register `85`,
data `00`, 25 kHz, and 10,000 physically reached target opportunities per
phase.

The final independent pre-build audit reported `PREBUILD_RELEASE=PASS`.
Material gates were:

| Gate | Result |
|---|---|
| Exact-base and protected-source identities | PASS |
| Address-map collision / formal zero model | PASS |
| Production 62.5 MHz, 25 kHz pre-init cycle equivalence | PASS |
| Autoinit transaction stream byte identity | YES |
| Effective pre-init SCL/SDA arbitration equality | PASS |
| Diagnostic-to-functional fanout | 0 |
| Phase counters versus scoreboard | PASS |
| 13-, 15-, 36-event patterns | PASS |
| Isolated WADDR/REGADDR/DATA/RADDR failures | PASS |
| All 13 transaction kinds / operation-86-like context | PASS |
| Legacy first-eight reconciliation | PASS |
| Transaction serial uniqueness at index 300 | PASS |
| Failed-log entries 64 and overflow at 65 | PASS |
| Bank before/after semantics and invariant model | PASS |
| Tri-phase probe RTL/model suite | PASS |
| Safe-target setup/readback/restoration model | PASS |
| Version-gated read-only host fixtures | PASS 24/24 |
| Frozen pre-hardware statistical plan | PASS |

The modeled complete-probe time was frozen before hardware, producing an
Arm-A wait requirement of `33.536673744` seconds. This value was never used
because no R1f bitstream was generated.

## Sole build evidence

The build was bound before consumption to the clean R1f commit/tree, the
frozen pre-build manifest, Vivado 2025.2 software build 6299465, part
`xc7a35tcsg325-2`, top `ahd_capture_top_xdma`, exact XDMA XCI and XDC inputs,
and the provenance-correct build script. The atomic sentinel records
`2026-08-24T11:09:45Z`. Synthesis began once at
`2026-08-24T11:12:46.5694670Z` and terminated at
`2026-08-24T11:13:51Z`.

| Build item | Actual result |
|---|---|
| Authorized clean builds consumed | 1 |
| Synthesis invocations | 1 |
| Synthesis | FAIL during RTL elaboration |
| Implementation runs | 0 |
| Bitstreams generated | 0 |
| Program/build retries | 0 |
| Place/route/timing/DRC/CDC/REQP gates | NOT REACHED |
| R1f routed-impact audit | NOT RUN; no R1f routed DCP |

The exact terminal log is SHA-256
`43C05651BEFA0DB30E00B7B16058D424AFEF38FEA2D0E15A9AF0381604A7E4D0`.
The terminal-failure receipt is
`1073A967F9E551FF716DF18983397B1B71D9082505A849DC4ACDBBA6DDC87AD1`;
the independent terminal audit is
`9E4DA8D0F966F652F1EAAA3B4FF39DE305CDB4511AE5570DE1D97797DC44E15E`.
The exact R1e routed checkpoint was independently rehashed as
`1CA3F857F2E3655FD06E8BF283B6BEC8826568402160EE004D7B8CD4D110C0B1`,
but no R1f physical comparison was possible.

## Hardware and scientific status

The build gate failed before any live-hardware step. Conditional bootstrap,
A1/B1, A2/B2, and A3/B3 were not run. There are no R1f autoinit phase
denominators, failed-transaction records, tri-phase probe sequences, bank
invariant measurements, functional NVP outcomes, replicate tests, or paired
A/B classifications. All result fields are therefore explicitly marked
`NOT_RUN` or `NOT_EVALUATED`; no zero result is imputed.

The following R7 interpretation boundaries remain in force:

- `POSTINIT_WRITE_ADDRESS_PROCESS` is compatible with a stationary
  memoryless Bernoulli process within the 25-kHz post-autoinit write-address
  probe scope; memorylessness is not proven.
- `EXACT_R7_AUTOINIT_TO_PROBE_RATE_RATIO` is not identifiable because R7 lacks
  exact phase-opportunity denominators.
- The retained R7 phase counts 4/7/5 are not a phase-rate test without those
  denominators.
- R7 operation 86 is legal transitional context under the exact-source audit,
  not a proven tracker defect.

R7 recorded exact formal Phase 2, formal identity
`A40A0C07 / 0000400B / 00031002`, diagnostic magic zero, pinned driver, and
`DONE=1`. R1f made zero hardware mutation, so that is the preserved task
context; R1f did not freshly reconfirm it after the mandatory build failure.

No result in this task proves a sole root cause, VCCO droop, ground bounce, or
directly measured analog margin.

## Operation accounting

```text
R1F_SOURCE_COMMITS=1
CLEAN_BUILDS=1
SYNTHESIS_RUNS=1
IMPLEMENTATION_RUNS=0
BITSTREAMS_GENERATED=0
CONDITIONAL_FORMAL_BOOTSTRAP_PROGRAMS=0
ARM_A_PROGRAMS=0
ARM_B_PROGRAMS=0
FPGA_PROGRAM_INVOCATIONS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
COLD_STARTS=0
PHYSICAL_ACTIONS=0
JTAG_FREQUENCY_CHANGES=0
PCI_REMOVE_RESCAN_RESETS=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHASE3_RESUMED=NO
XDMA_DEVELOPMENT_CONTINUED=NO
FORMAL_REPOSITORY_MUTATIONS=0
OWNER_INTERACTIVE_APPROVAL_REQUESTS=0
```

## Required final block

```text
TASK=
    V41_NVP_R1F_PHASE_COMPLETE_OBSERVABILITY_AND_REPLICATED_PAIRED_AB

EXPERIMENT_NAME=
    R1f

R7_EVIDENCE_COMMIT=
    16beec37a266c421da5838fbb986301d072cbb50

R7_EVIDENCE_PACKAGE_SHA256=
    A1864DA7EC52AEE852169656808510C42D98FDCE27816D82449946B610DD2A56

BASE_COMMIT=
    f3d9e5cdcacfb6fdebed5e5fe8b9143ef226aebd

BASE_TREE=
    db8b5581a237e19905fd01c6d453793047bc3ba7

R1F_SOURCE_COMMIT=
    225544084dbfcaadb8592fcecc947aa1cec4970e
R1F_SOURCE_TREE=
    cfde8769af95cf20586391c411fab3ddfa2c87b6
R1F_BIT_SHA256=
    NOT_GENERATED_BUILD_BLOCKED_AT_SYNTHESIS
R1F_ROUTED_DCP_SHA256=
    NOT_GENERATED_BUILD_BLOCKED_AT_SYNTHESIS

FULL_BUILDS=
    1

PRE_INIT_DONE_CYCLE_EQUIVALENCE=
    PASS
AUTOINIT_TRANSACTION_STREAM_BYTE_IDENTICAL=
    YES
R1F_DIAGNOSTIC_TO_FUNCTIONAL_FANOUT=
    0

SAFE_DATA_PROBE_TARGET=
    PASS
R1F_PROBE_BANK=
    0x00
R1F_PROBE_REGISTER=
    0x85
R1F_PROBE_DATA=
    0x00
SAFE_TARGET_PRE_POST_READBACK_CONTRACT=
    PASS_FROZEN_OFFLINE_NOT_EXECUTED_HARDWARE

LEGACY_OPERATION_INDEX_BEHAVIOR=
    SATURATES_AT_255_WITH_SIX_BIT_DEBUG_ALIAS_MODULO_64
R1F_TRANSACTION_INDEX_WIDTH=
    16
R1F_TABLE_SLOT_INDEX_WIDTH=
    16

R1F_FAILED_TXN_LOG_CAPACITY=
    64
R1F_FAILED_TXN_RECORD_WIDTH=
    192
R1F_FAILED_TXN_RECORD_VERSION=
    1

R1F_PHASE_COUNTERS=
    WADDR_REGADDR_DATA_RADDR

R1F_PROBE_PHASES=
    WADDR_REGADDR_DATA
R1F_PROBE_TARGET_OPPORTUNITIES_PER_PHASE=
    10000
R1F_PROBE_BLOCKS_PER_PHASE=
    10
R1F_PROBE_INDEX_LOG_CAPACITY_PER_PHASE=
    512

PAIR_COUNT_PLANNED=
    3
PAIR_COUNT_VALID=
    0

BOOTSTRAP_RUN=
    NO_BUILD_GATE_FAILED_BEFORE_HARDWARE
BOOTSTRAP_RESULT=
    NOT_RUN_BUILD_GATE_FAILED

A1_RESULT=
    NOT_RUN_BUILD_GATE_FAILED
A1_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_MEASURED
A1_AUTOINIT_WADDR_NACKS=
    NOT_MEASURED
A1_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_MEASURED
A1_AUTOINIT_REGADDR_NACKS=
    NOT_MEASURED
A1_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_MEASURED
A1_AUTOINIT_DATA_NACKS=
    NOT_MEASURED
A1_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_MEASURED
A1_AUTOINIT_RADDR_NACKS=
    NOT_MEASURED
A1_FAILED_TXN_TOTAL=
    NOT_MEASURED
A1_FAILED_TXN_STORED=
    NOT_MEASURED
A1_FAILED_TXN_OVERFLOW=
    NOT_MEASURED
A1_BANK_INVARIANT_ERRORS=
    NOT_MEASURED
A1_PROBE_WADDR_NACKS=
    NOT_MEASURED
A1_PROBE_REGADDR_NACKS=
    NOT_MEASURED
A1_PROBE_DATA_NACKS=
    NOT_MEASURED
A1_PROBE_TIMEOUTS=
    NOT_MEASURED
A1_NVP_RESULT=
    NOT_RUN

B1_NACK_COUNT=
    NOT_MEASURED
B1_NACK_LOG_COUNT=
    NOT_MEASURED
B1_NACK_LOG_OVERFLOW=
    NOT_MEASURED
B1_NVP_RESULT=
    NOT_RUN

A2_RESULT=
    NOT_RUN_BUILD_GATE_FAILED
A2_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_MEASURED
A2_AUTOINIT_WADDR_NACKS=
    NOT_MEASURED
A2_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_MEASURED
A2_AUTOINIT_REGADDR_NACKS=
    NOT_MEASURED
A2_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_MEASURED
A2_AUTOINIT_DATA_NACKS=
    NOT_MEASURED
A2_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_MEASURED
A2_AUTOINIT_RADDR_NACKS=
    NOT_MEASURED
A2_FAILED_TXN_TOTAL=
    NOT_MEASURED
A2_FAILED_TXN_STORED=
    NOT_MEASURED
A2_FAILED_TXN_OVERFLOW=
    NOT_MEASURED
A2_BANK_INVARIANT_ERRORS=
    NOT_MEASURED
A2_PROBE_WADDR_NACKS=
    NOT_MEASURED
A2_PROBE_REGADDR_NACKS=
    NOT_MEASURED
A2_PROBE_DATA_NACKS=
    NOT_MEASURED
A2_PROBE_TIMEOUTS=
    NOT_MEASURED
A2_NVP_RESULT=
    NOT_RUN

B2_NACK_COUNT=
    NOT_MEASURED
B2_NACK_LOG_COUNT=
    NOT_MEASURED
B2_NACK_LOG_OVERFLOW=
    NOT_MEASURED
B2_NVP_RESULT=
    NOT_RUN

A3_RESULT=
    NOT_RUN_BUILD_GATE_FAILED
A3_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_MEASURED
A3_AUTOINIT_WADDR_NACKS=
    NOT_MEASURED
A3_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_MEASURED
A3_AUTOINIT_REGADDR_NACKS=
    NOT_MEASURED
A3_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_MEASURED
A3_AUTOINIT_DATA_NACKS=
    NOT_MEASURED
A3_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_MEASURED
A3_AUTOINIT_RADDR_NACKS=
    NOT_MEASURED
A3_FAILED_TXN_TOTAL=
    NOT_MEASURED
A3_FAILED_TXN_STORED=
    NOT_MEASURED
A3_FAILED_TXN_OVERFLOW=
    NOT_MEASURED
A3_BANK_INVARIANT_ERRORS=
    NOT_MEASURED
A3_PROBE_WADDR_NACKS=
    NOT_MEASURED
A3_PROBE_REGADDR_NACKS=
    NOT_MEASURED
A3_PROBE_DATA_NACKS=
    NOT_MEASURED
A3_PROBE_TIMEOUTS=
    NOT_MEASURED
A3_NVP_RESULT=
    NOT_RUN

B3_NACK_COUNT=
    NOT_MEASURED
B3_NACK_LOG_COUNT=
    NOT_MEASURED
B3_NACK_LOG_OVERFLOW=
    NOT_MEASURED
B3_NVP_RESULT=
    NOT_RUN

POSTINIT_WADDR_PROCESS=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE
POSTINIT_REGADDR_PROCESS=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE
POSTINIT_DATA_PROCESS=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE

AUTOINIT_PHASE_RATE_HETEROGENEITY=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE
AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE
R1F_REPLICATE_HOMOGENEITY=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE

BANK_TRACKER_COHERENCE=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE
R7_OPERATION_86_SEMANTICS=
    LEGAL_TRANSITIONAL_CONTEXT_FROM_EXACT_SOURCE_AUDIT
FAILED_TRANSACTION_DISTRIBUTION=
    NOT_EVALUATED_NO_R1F_HARDWARE_SAMPLE

PAIRED_AB_RESULT=
    NOT_RUN_BUILD_GATE_FAILED_AT_SYNTHESIS

ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2
FINAL_FORMAL_IDENTITY=
    A40A0C07 / 0000400B / 00031002_R7_RECORDED_NOT_R1F_FRESHLY_RECONFIRMED
FINAL_DIAGNOSTIC_MAGIC=
    0_R7_RECORDED_NOT_R1F_FRESHLY_RECONFIRMED
FINAL_PINNED_DRIVER_LOADED=
    YES_R7_RECORDED_NOT_R1F_FRESHLY_RECONFIRMED
FINAL_DONE=
    1_R7_RECORDED_NOT_R1F_FRESHLY_RECONFIRMED

CONDITIONAL_FORMAL_BOOTSTRAP_PROGRAMS=
    0
ARM_A_PROGRAMS=
    0
ARM_B_PROGRAMS=
    0
FPGA_PROGRAM_INVOCATIONS=
    0
WARM_REBOOTS=
    0
DRIVER_LOADS=
    0

PROGRAM_RETRIES=
    0

COLD_STARTS=
    0

PHYSICAL_ACTIONS=
    0

JTAG_FREQUENCY_CHANGES=
    0

PCI_REMOVE_RESCAN_RESETS=
    0

AXI_LITE_WRITES=
    0

C2H_TRANSFERS=
    0

H2C_TRANSFERS=
    0

PHASE3_RESUMED=
    NO

XDMA_DEVELOPMENT_CONTINUED=
    NO

FORMAL_REPOSITORY_MUTATIONS=
    0

OWNER_INTERACTIVE_APPROVAL_REQUESTS=
    0

OWNER_PROMPT_SHA256=
    83FB94A3EF41A884323528BDA9D75412F6710B739E1D531A54A218324268670D
EVIDENCE_PACKAGE_SHA256=
    SEE_EXTERNAL_NONCIRCULAR_SHA256_SIDECAR
EVIDENCE_REPOSITORY_COMMIT=
    SEE_EXTERNAL_PUBLICATION_RECEIPT
PUBLIC_REMOTE_VERIFICATION=
    SEE_EXTERNAL_PUBLICATION_RECEIPT
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_R1F_PHASE_COMPLETE_RESULTS
```
