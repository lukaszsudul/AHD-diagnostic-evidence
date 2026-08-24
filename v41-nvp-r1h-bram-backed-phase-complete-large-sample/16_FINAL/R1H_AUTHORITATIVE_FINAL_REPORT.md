# V41 NVP R1h — authoritative final report

## Decision

R1h is terminally classified as
`BLOCKED_ONE_CLEAN_BUILD_PROJECT_SETUP_COMPILE_ORDER_ASSERTION`.

The exact R1h BRAM/MMIO source passed the pre-commit compiler, component,
scientific-event, pre-init, MMIO transaction, reset-liveness, host-decoder and
out-of-context memory-inference gates. One direct-child source commit was
created. The one provenance-bound clean build was then consumed exactly once
and stopped during `PROJECT_SETUP`, before `synth_design`, because the frozen
build Tcl rejected Vivado's queried relative file order with:

```text
R1h probe-index BRAM wrapper is not before its probe consumer
```

No retry, source correction, synthesis, optimization, placement, routing,
checkpoint, bitstream, programming, host access or hardware campaign followed.
The requested 90,000 target-phase hardware opportunities therefore do not
exist and no R1h scientific hardware conclusion is reported.

## Evidence vocabulary

- **FACT** identifies a byte, Git, filesystem, counter or receipt observation.
- **SOURCE-DERIVED FACT** identifies a conclusion directly supported by exact
  committed source.
- **TOOL-DERIVED FACT** identifies a result emitted by Vivado/XSim or another
  frozen tool.
- **INFERENCE** identifies an interpretation whose evidence boundary is stated.
- **NOT AVAILABLE** means the corresponding stage did not run; it never means
  zero or PASS.

## Exact identities

FACT:

```text
R1G_SOURCE_COMMIT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_DIRECT_PARENT=e112a5addb7ac62700a9a71af81bf368fad0bada
R1H_COMMITS_ABOVE_R1G=1
SOURCE_BRANCH=diag/v41-nvp-r1h-bram-backed-large-sample
SOURCE_WORKTREE_CLEAN=YES
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
OWNER_PROMPT_SHA256=870B78B78A37AB09486DC63CCADB81C5F4CB1398C02DDE935D35BF89B5DEDB9A
```

The public R1g evidence package, its 1,120-file manifest, authoritative report,
public commit, exact R1g source, independent 61-entry resource audit, formal
bit and inherited R7 tool identities all passed fresh hash/identity checks.
The resource audit itself was task-local and supplied no public evidence commit
or separate package; those two identities remain unavailable and were not
invented.

## Frozen scientific scope

SOURCE-DERIVED FACT: the sole R1h commit changes storage and diagnostic read
latency/handshake implementation without reducing the R1f/R1g scientific
contract. It retains:

- 64 append-only failed records, 192 bits each, overflow on failure 65;
- 512 zero-based NACK indices for each of WADDR, REGADDR and DATA, overflow on
  index 513;
- 10,000 target opportunities per phase, ten 1,000-opportunity blocks and the
  12,000-attempt cap;
- every address and field in `0x20A0..0x35FF`, legacy projections and formal
  zero behavior;
- the NVP table, functional FSM, transaction timing, watchdog, filters, XDC,
  XDMA XCI and statistical plan.

SOURCE-DERIVED FACT: `autonomous_clk` and `axi_aclk` are the same clock in the
top. The new MMIO service permits at most one outstanding diagnostic read,
holds the response stable under backpressure, preserves zero/OKAY handling for
invalid reads, preserves diagnostic-write forwarding and cancels pending reads
under the combined AXI/NVP-POR reset. There is no new diagnostic-to-functional
fanout.

## Storage and MMIO implementation evidence

The committed architecture contains six independent 64x32 XPM block-memory
banks for a complete 192-bit record and three independent 512x16 XPM
block-memory banks for probe indices. Payload memory is not physically reset;
metadata and request-time validity masking provide deterministic zero for
unused entries. Two index reads are serialized and packed into the unchanged
32-bit MMIO word. The old combinational 512:1 index read path is absent.

TOOL-DERIVED FACT: two bounded pre-commit, task-local out-of-context inference
runs reported:

```text
FAILED_RECORD_BANKS=6_RAMB18E1
INDEX_BANKS=3_RAMB18E1
RAMB36E1=0
FAILED_RECORD_RAM64M=0
FAILED_RECORD_RAMD64E=0
INDEX_WRAPPER_FDRE=3
```

These are component/OOC results only. Because the full build never invoked
`synth_design`, the integrated full-top primitive mapping and post-synthesis
resource margin are **NOT AVAILABLE** and are not promoted from the OOC runs.

## Verification before the commit

The sealed pre-commit evidence proves:

- full-duration 62.5 MHz / 25 kHz R1g-reference and R1h-candidate pre-init runs
  both passed at `2121355816 ns` with cycle, byte-stream and functional-state
  equality;
- autoinit all-ACK and injected NACK matrices, all 13 transaction kinds,
  operation-86 context, 13/15/36-event patterns, serial index 300 and legacy
  first-eight reconciliation passed;
- a strict dual-instance probe comparison matched 83 common outputs each
  cycle, low/high I2C events, scheduler/counters/block values and stored index
  values transactionally;
- the failed-record matrix exercised all 64 records and six words, atomic
  banks, concurrent append/read, unused/reset logical zero and failure 65
  overflow without overwrite;
- all 1,536 probe-index entries, overflow, odd/even packing, concurrent
  bank traffic and payload-reset masking passed;
- exhaustive integrated MMIO testing covered 1,368 aligned reads, 4,104
  unaligned zero reads, 1,368 forwarded writes, ordering, busy rejection,
  variable response backpressure and reset cancellation;
- inherited probe cases, production timing, top elaboration, 24/24 host and
  statistics fixtures passed.

The first reset regression was explicitly rejected after it emitted a `FAIL`
token despite a misleading footer/exit status. The corrected second run was
clean and is the only accepted reset receipt.

## Source commit and prebuild release

FACT:

```text
R1H_COMMIT_TREE_PROOF_SHA256=8743849F8278E08AF059EEC97A7F776A9B127B8F16BD3D3C5AFD4897985A620C
R1H_SOURCE_SHA256_MANIFEST_SHA256=C8419FE64BD673F464B450C425C6052B2FC0BA23F62C8B2384105CE4D26E7EE5
R1G_TO_R1H_PATCH_SHA256=C573FA3379F2C300BAD6AD464142923F2B5318DA93DD5594705B1472105EB8FF
R1H_PREBUILD_MANIFEST_SHA256=192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79
R1H_BUILD_TCL_SHA256=2E6ECDE9E9109D510CC9E3272C88E5AA6E0C5BD73119A154CB10A41062D67C18
```

The independent post-commit audit rehashed 224/224 tracked source records and
32/32 accepted evidence records, verified all 27 required labels, the exact
direct-child topology and a clean worktree, and released exactly one build.

## Sole build and exact terminal blocker

FACT: the atomic sentinel was created before project creation and records:

```text
FULL_CLEAN_BUILDS_CONSUMED=1
CONSUMED_UTC=2026-08-24T22:44:11Z
SOURCE_GIT_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
SOURCE_GIT_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
PREBUILD_MANIFEST_SHA256=192F9BD87FC5C9CA8499C783B4A3B75F7D49940E395D383D47874E9C2A38AE79
VIVADO_VERSION=2025.2
VIVADO_SW_BUILD=6299465
PROGRAM_RETRY_AUTHORIZED=NO
```

TOOL-DERIVED FACT: the terminal receipt has SHA-256
`BC21A70F01CDBE4EAAA929326711E3A0E0C48BBF9EE31FF017513C003B2BD363`
and records `TERMINAL_BUILD_STAGE=PROJECT_SETUP`. The exact Tcl exception is:

```text
R1h probe-index BRAM wrapper is not before its probe consumer
```

The executing Tcl's explicit source list places the index-store file before
the probe file. After project creation and `update_compile_order`, Vivado's
queried list returned the reverse relative order, so the Tcl assertion at
lines 1009–1011 terminated the flow. The exact numeric queried indexes are
unavailable because the receipt intended to record them was written after the
failing assertion. The saved project independently preserves probe before
index store (`.xpr` source entries at lines 145 and 201).

SOURCE-DERIVED FACT: these are standalone SystemVerilog module units. The probe
has no textual include/package/interface/typedef/macro/bind dependency on the
index-store module. Its relation is an ordinary module instantiation. Thus the
assertion is an overconstrained, non-semantic project policy, not a compiler or
synthesis diagnostic.

INFERENCE: it is strongly supported that the gate was a false-positive source-
order policy. It is **not** proven that the production frontend would accept
and synthesize the complete R1h design, because synthesis was never attempted
and the one-build limit forbids the experiment.

The task-local planned-order document also mentions an unused
`nvp_i2c_address_probe.sv` file that neither the executing R1h Tcl nor frozen
R1g Tcl adds; source search finds no production instantiation. This is a
disclosed documentation inconsistency, not the observed terminal cause.

Exact runtime accounting:

```text
FULL_CLEAN_BUILDS=1
SYNTHESIS_RUNS=0
OPT_DESIGN_RUNS=0
PLACE_DESIGN_RUNS=0
ROUTE_DESIGN_RUNS=0
BITSTREAM_RUNS=0
SYNTH_DCP_COUNT=0
ROUTED_DCP_COUNT=0
BITSTREAM_COUNT=0
POST_SYNTH_RESOURCE_GATE=NOT_RUN
```

No post-synthesis resource number, integrated BRAM mapping, timing, DRC, CDC,
REQP-1839, routed-impact or source-to-bit result exists.

## Hardware and scientific result

The build failure made R1h ineligible for hardware. No fresh JTAG, host,
kernel, driver, BAR, formal identity, diagnostic magic or DONE observation was
made. Bootstrap, A1/B1, A2/B2 and A3/B3 were not run. `PAIR_COUNT_VALID=0`.
The R7 Formal Phase 2 terminal state remains historical context only and is not
reported as freshly reconfirmed by R1h.

Consequently every requested process, heterogeneity, rate-elevation,
replicate, bank-tracker, operation-86, failure-distribution and paired A/B
classification is `NOT_RUN_NO_HARDWARE_DATA`. No zero result is substituted
for a missing observation.

## Final accounting and next action

```text
R1H_SOURCE_COMMITS=1
FULL_CLEAN_BUILDS=1
SYNTHESIS_RUNS=0
OPT_DESIGN_RUNS=0
PLACE_DESIGN_RUNS=0
ROUTE_DESIGN_RUNS=0
BITSTREAMS=0
SOURCE_FIXES_AFTER_BUILD_START=0
SECOND_SOURCE_COMMITS=0
SECOND_BUILDS=0
SOURCE_BRANCH_PUSHES=0
FPGA_PROGRAMS=0
WARM_REBOOTS=0
DRIVER_LOADS=0
PROGRAM_RETRIES=0
AXI_LITE_READS=0
AXI_LITE_WRITES=0
C2H_TRANSFERS=0
H2C_TRANSFERS=0
PHYSICAL_ACTIONS=0
OWNER_INTERACTIVE_APPROVAL_REQUESTS=0
```

The authorized next operation is only to seal and publish the safely available
terminal evidence, then hard-stop. Any correction of the compile-order policy
or any new build requires a separately authorized continuation.

## Required final report block

```text
TASK=
    V41_NVP_R1H_BRAM_BACKED_PHASE_COMPLETE_OBSERVABILITY_AND_LARGE_SAMPLE_AB

EXPERIMENT_NAME=
    R1h

R1G_SOURCE_COMMIT=
    e112a5addb7ac62700a9a71af81bf368fad0bada

R1G_EVIDENCE_COMMIT=
    31786f351a9b8aab86291b5058ce075da5fba46a

R1G_TERMINAL_CLASSIFICATION=
    BLOCKED_ONE_CLEAN_BUILD_PLACE_PRECONDITION_RESOURCE_OVERUTILIZATION

RESOURCE_ATTRIBUTION_REPORT_SHA256=
    45A5E7BE82D94BFB781BA6726F3FBD47236CD551703542EE4964C6C392C2ACB6

RESOURCE_AUDIT_MANIFEST_SHA256=
    776A900D108880230CFFA4CC0BC1AF989858E3A2C0298C5F0B38B0DC310A691F

R1H_PARENT_COMMIT=
    e112a5addb7ac62700a9a71af81bf368fad0bada

R1H_SOURCE_COMMIT=
    c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=
    161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_BIT_SHA256=
    NOT_GENERATED
R1H_ROUTED_DCP_SHA256=
    NOT_GENERATED

SCIENTIFIC_SCOPE_REDUCTION=
    NO

FAILED_RECORD_CAPACITY=
    64

FAILED_RECORD_WIDTH=
    192

INDEX_CAPACITY_PER_PHASE=
    512

PROBE_TARGET_OPPORTUNITIES_PER_PHASE=
    10000

ARM_A_REPETITIONS=
    3

TOTAL_TARGET_PHASE_OPPORTUNITIES=
    90000

FAILED_RECORD_PAYLOAD_RAMB18=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
WADDR_INDEX_PAYLOAD_RAMB18=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
REGADDR_INDEX_PAYLOAD_RAMB18=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
DATA_INDEX_PAYLOAD_RAMB18=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
R1H_NEW_PAYLOAD_RAMB18_TOTAL=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN

FAILED_RECORD_PAYLOAD_FDRE=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
INDEX_PAYLOAD_FDRE_TOTAL=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
FAILED_RECORD_PAYLOAD_RAM64M=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN
FAILED_RECORD_PAYLOAD_RAMD64E=
    NOT_AVAILABLE_FULL_PROJECT_SYNTHESIS_NOT_RUN

MMIO_READ_SERVICE=
    SYNCHRONOUS_ONE_OUTSTANDING

COMBINATIONAL_INDEX_512_TO_1_MUX=
    ABSENT

FULL_CLEAN_BUILDS=
    1

POST_SYNTH_SLICE_LUTS=
    NOT_AVAILABLE_SYNTHESIS_NOT_RUN
POST_SYNTH_LOGIC_LUTS=
    NOT_AVAILABLE_SYNTHESIS_NOT_RUN
POST_SYNTH_SLICE_REGISTERS=
    NOT_AVAILABLE_SYNTHESIS_NOT_RUN
POST_SYNTH_RAMB18=
    NOT_AVAILABLE_SYNTHESIS_NOT_RUN
POST_SYNTH_RAMB36=
    NOT_AVAILABLE_SYNTHESIS_NOT_RUN

POST_SYNTH_RESOURCE_MARGIN_GATE=
    NOT_RUN_BUILD_BLOCKED_PROJECT_SETUP
OPT_DESIGN=
    NOT_RUN
PLACE=
    NOT_RUN
ROUTE=
    NOT_RUN
ROUTE_ERRORS=
    NOT_AVAILABLE_ROUTE_NOT_RUN
WNS=
    NOT_AVAILABLE_ROUTE_NOT_RUN
WHS=
    NOT_AVAILABLE_ROUTE_NOT_RUN
DRC_ERRORS=
    NOT_AVAILABLE_IMPLEMENTATION_NOT_RUN
DRC_CRITICAL_WARNINGS=
    NOT_AVAILABLE_IMPLEMENTATION_NOT_RUN
REQP_1839_SEMANTIC_COUNT=
    NOT_AVAILABLE_IMPLEMENTATION_NOT_RUN
CDC_CRITICAL=
    NOT_AVAILABLE_SYNTHESIS_NOT_RUN
CDC_UNKNOWN=
    NOT_AVAILABLE_SYNTHESIS_NOT_RUN
SOURCE_COMMIT_TO_BIT_PROVENANCE=
    NOT_APPLICABLE_NO_BIT

PAIR_COUNT_PLANNED=
    3

PAIR_COUNT_VALID=
    0

BOOTSTRAP_RUN=
    NO_BUILD_BLOCKED
BOOTSTRAP_RESULT=
    NOT_RUN_BUILD_BLOCKED

A1_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A1_AUTOINIT_WADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A1_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A1_AUTOINIT_REGADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A1_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A1_AUTOINIT_DATA_NACKS=
    NOT_RUN_BUILD_BLOCKED
A1_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A1_AUTOINIT_RADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A1_FAILED_TXN_TOTAL=
    NOT_RUN_BUILD_BLOCKED
A1_FAILED_TXN_STORED=
    NOT_RUN_BUILD_BLOCKED
A1_FAILED_TXN_OVERFLOW=
    NOT_RUN_BUILD_BLOCKED
A1_BANK_INVARIANT_ERRORS=
    NOT_RUN_BUILD_BLOCKED
A1_PROBE_WADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A1_PROBE_REGADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A1_PROBE_DATA_NACKS=
    NOT_RUN_BUILD_BLOCKED
A1_PROBE_TIMEOUTS=
    NOT_RUN_BUILD_BLOCKED
A1_NVP_RESULT=
    NOT_RUN_BUILD_BLOCKED

B1_NACK_COUNT=
    NOT_RUN_BUILD_BLOCKED
B1_NVP_RESULT=
    NOT_RUN_BUILD_BLOCKED

A2_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A2_AUTOINIT_WADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A2_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A2_AUTOINIT_REGADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A2_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A2_AUTOINIT_DATA_NACKS=
    NOT_RUN_BUILD_BLOCKED
A2_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A2_AUTOINIT_RADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A2_FAILED_TXN_TOTAL=
    NOT_RUN_BUILD_BLOCKED
A2_FAILED_TXN_STORED=
    NOT_RUN_BUILD_BLOCKED
A2_FAILED_TXN_OVERFLOW=
    NOT_RUN_BUILD_BLOCKED
A2_BANK_INVARIANT_ERRORS=
    NOT_RUN_BUILD_BLOCKED
A2_PROBE_WADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A2_PROBE_REGADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A2_PROBE_DATA_NACKS=
    NOT_RUN_BUILD_BLOCKED
A2_PROBE_TIMEOUTS=
    NOT_RUN_BUILD_BLOCKED
A2_NVP_RESULT=
    NOT_RUN_BUILD_BLOCKED

B2_NACK_COUNT=
    NOT_RUN_BUILD_BLOCKED
B2_NVP_RESULT=
    NOT_RUN_BUILD_BLOCKED

A3_AUTOINIT_WADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A3_AUTOINIT_WADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A3_AUTOINIT_REGADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A3_AUTOINIT_REGADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A3_AUTOINIT_DATA_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A3_AUTOINIT_DATA_NACKS=
    NOT_RUN_BUILD_BLOCKED
A3_AUTOINIT_RADDR_OPPORTUNITIES=
    NOT_RUN_BUILD_BLOCKED
A3_AUTOINIT_RADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A3_FAILED_TXN_TOTAL=
    NOT_RUN_BUILD_BLOCKED
A3_FAILED_TXN_STORED=
    NOT_RUN_BUILD_BLOCKED
A3_FAILED_TXN_OVERFLOW=
    NOT_RUN_BUILD_BLOCKED
A3_BANK_INVARIANT_ERRORS=
    NOT_RUN_BUILD_BLOCKED
A3_PROBE_WADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A3_PROBE_REGADDR_NACKS=
    NOT_RUN_BUILD_BLOCKED
A3_PROBE_DATA_NACKS=
    NOT_RUN_BUILD_BLOCKED
A3_PROBE_TIMEOUTS=
    NOT_RUN_BUILD_BLOCKED
A3_NVP_RESULT=
    NOT_RUN_BUILD_BLOCKED

B3_NACK_COUNT=
    NOT_RUN_BUILD_BLOCKED
B3_NVP_RESULT=
    NOT_RUN_BUILD_BLOCKED

POSTINIT_WADDR_PROCESS=
    NOT_RUN_NO_HARDWARE_DATA
POSTINIT_REGADDR_PROCESS=
    NOT_RUN_NO_HARDWARE_DATA
POSTINIT_DATA_PROCESS=
    NOT_RUN_NO_HARDWARE_DATA

AUTOINIT_PHASE_RATE_HETEROGENEITY=
    NOT_RUN_NO_HARDWARE_DATA
AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR=
    NOT_RUN_NO_HARDWARE_DATA
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR=
    NOT_RUN_NO_HARDWARE_DATA
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA=
    NOT_RUN_NO_HARDWARE_DATA

R1H_REPLICATE_HOMOGENEITY=
    NOT_RUN_NO_HARDWARE_DATA
BANK_TRACKER_COHERENCE=
    NOT_RUN_NO_HARDWARE_DATA
R7_OPERATION_86_SEMANTICS=
    NOT_RUN_NO_R1H_HARDWARE_DATA_R7_HISTORICAL_CONTEXT_ONLY
FAILED_TRANSACTION_DISTRIBUTION=
    NOT_RUN_NO_HARDWARE_DATA
PAIRED_AB_RESULT=
    NOT_RUN_BUILD_BLOCKED

ROOT_CAUSE_SOLELY_PROVEN=
    NO

BOARD_VCCO_DROOP_PROVEN=
    NO

GROUND_BOUNCE_PROVEN=
    NO

ANALOG_MARGIN_DIRECTLY_MEASURED=
    NO

FINAL_ACTIVE_IMAGE=
    NOT_FRESHLY_VERIFIED_R1H_HARDWARE_NOT_RUN

FINAL_FORMAL_IDENTITY=
    NOT_FRESHLY_VERIFIED_R7_HISTORICAL_A40A0C07_0000400B_00031002
FINAL_DIAGNOSTIC_MAGIC=
    NOT_FRESHLY_VERIFIED_R7_HISTORICAL_0
FINAL_PINNED_DRIVER_LOADED=
    NOT_FRESHLY_VERIFIED
FINAL_DONE=
    NOT_FRESHLY_VERIFIED_R7_HISTORICAL_1

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
    870B78B78A37AB09486DC63CCADB81C5F4CB1398C02DDE935D35BF89B5DEDB9A
EVIDENCE_PACKAGE_SHA256=
    SEE_EXTERNAL_SHA256_SIDECAR_NONCIRCULAR
EVIDENCE_REPOSITORY_COMMIT=
    SEE_EXTERNAL_PUBLICATION_RECEIPT
PUBLIC_REMOTE_VERIFICATION=
    SEE_EXTERNAL_PUBLICATION_RECEIPT
NEXT_ACTION=
    OWNER_AND_AUDITOR_REVIEW_OF_R1H_LARGE_SAMPLE_RESULTS
```
