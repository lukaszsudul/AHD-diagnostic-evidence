# R1h-R4 authoritative report schema

This is a schema only. It is not the authoritative report and must not be
renamed or presented as one. The final report must be created only after the
analysis/campaign audit release is `PASS`.

Required authoritative filename:

```text
final/V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE_AUTHORITATIVE_REPORT.md
```

## 1. Executive outcome

State, without inference inflation:

- implementation result and diagnostic-only resource-margin class;
- campaign completeness and pair validity;
- final exact Formal Phase-2 restoration state;
- publication status, separately from the scientific result;
- terminal classification and next action.

## 2. Scope and owner-authorized risk

Record the R4 SUPER-FAST policy delta, including the accepted 5% Slice-LUT
floor, removed report-only blockers, zero source/synthesis changes, one
implementation/bitstream attempt, and the one global infrastructure retry
budget. Do not claim production acceptance.

## 3. Immutable identities and provenance

Bind every claim to evidence paths and SHA-256 values:

- owner prompt and prompt digest;
- exact R1h source commit/tree;
- exact synthesized DCP;
- Vivado version/build, part and top;
- implementation Tcl/static audit/independent launch release;
- routed DCP and diagnostic bit;
- exact formal bit/runtime identity;
- JTAG, kernel and pinned-driver identities.

## 4. Implementation hard gates

Report exact post-opt and final resource values, mapping classification,
place/route status, route errors, unrouted nets, WNS/WHS, failing-path counts,
DRC errors/critical warnings, optional CDC outcome, bitstream result, and
source-to-bit provenance. Distinguish `PASS_STANDARD_MARGIN` from
`PASS_DIAGNOSTIC_ONLY_5_TO_10_PERCENT_MARGIN`.

## 5. Hardware safety, bootstrap and accounting

Report the minimal pre-hardware safety gate, mandatory formal bootstrap,
programming observer results, all warm reboot/driver-load counts, global retry
use, host-only correction cycles, and the invariant zero counts for MMIO
writes, DMA and physical actions.

## 6. Paired campaign datasets

For A1/B1, A2/B2 and A3/B3 report separately:

- infrastructure validity;
- scientific NVP PASS/FAIL;
- coherent T0/T1 and final DONE;
- all autoinit phase opportunities/NACKs;
- all post-init phase opportunities/NACKs/timeouts;
- failed-transaction total/stored/overflow and record decode;
- probe index-log capacity/overflow and positional-analysis coverage;
- bank-invariant and safe-target restore state;
- formal-control identity, magic and NACK result.

Never convert a valid scientific FAIL into infrastructure invalidity.

## 7. Frozen statistical analysis

Include phase-level N, ACK/NACK/timeout, rate, ppm, Wilson 95%, first/last
index, adjacent pairs, runs, maximum consecutive NACKs and ten block rates.
Include autoinit/post-init comparisons, rate differences/ratios, intervals,
raw and Holm-adjusted p-values, and the predeclared three-part support
criterion. Cite the frozen analysis script and its SHA-256.

## 8. Interpretations and limitations

State all required process/context classifications. Preserve:

```text
ROOT_CAUSE_SOLELY_PROVEN=NO
BOARD_VCCO_DROOP_PROVEN=NO
GROUND_BOUNCE_PROVEN=NO
ANALOG_MARGIN_DIRECTLY_MEASURED=NO
```

## 9. Final formal restoration

Bind the last B3/FormalReady evidence proving:

```text
FINAL_ACTIVE_IMAGE=FORMAL_PHASE2
FINAL_FORMAL_IDENTITY=A40A0C07 / 0000400B / 00031002
FINAL_DIAGNOSTIC_MAGIC=0
FINAL_PINNED_DRIVER_LOADED=YES
FINAL_DONE=1
```

## 10. Evidence sealing and publication

Report manifest rows/hash, ZIP entries/bytes/hash, sidecar hash, evidence
repository base/commit, LFS pointer verification for ZIP/DCP/bit, normal push
receipt and public-remote verification. Publication failure must not rewrite
the scientific result.

## Required terminal block

The authoritative report must end with this block, with every placeholder
replaced by one nonempty audited value. No content may follow it.

```text
TASK=
    V41_NVP_R1H_R4_SUPER_FAST_IMPLEMENTATION_AND_LARGE_SAMPLE

EXPERIMENT_NAME=
    R1h

CONTINUATION_REVISION=
    R4

SUPER_FAST_OWNER_RISK_ACCEPTED=
    YES

SOURCE_FILE_MUTATIONS=
    0

SOURCE_COMMITS=
    0

SYNTH_DESIGN_INVOCATIONS_THIS_TASK=
    0

R1H_SOURCE_COMMIT=
    c4f4bfcf577c92c3021d1fe83c05878dd12e001c

R1H_SOURCE_TREE=
    161e561f007912d73dba93c5ecd78e3cc3a6955b

R1H_SYNTH_DCP_SHA256=
    807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E

RAW_NONEMPTY_ROUTE_PROPERTY_USED_AS_GATE=
    NO

OPT_DESIGN_INVOCATIONS=
    1

POST_OPT_SLICE_LUTS=
    <REQUIRED_VALUE>
POST_OPT_SLICE_REGISTERS=
    <REQUIRED_VALUE>
POST_OPT_RESOURCE_CLASS=
    <REQUIRED_VALUE>

PLACE=
    <REQUIRED_VALUE>
ROUTE=
    <REQUIRED_VALUE>
ROUTE_ERRORS=
    <REQUIRED_VALUE>
UNROUTED_NETS=
    <REQUIRED_VALUE>
WNS=
    <REQUIRED_VALUE>
WHS=
    <REQUIRED_VALUE>
FINAL_SLICE_LUTS=
    <REQUIRED_VALUE>
FINAL_SLICE_REGISTERS=
    <REQUIRED_VALUE>
FINAL_RESOURCE_CLASS=
    <REQUIRED_VALUE>

R1H_BIT_SHA256=
    <REQUIRED_VALUE>
R1H_ROUTED_DCP_SHA256=
    <REQUIRED_VALUE>
SOURCE_COMMIT_TO_BIT_PROVENANCE=
    <REQUIRED_VALUE>

DIAGNOSTIC_ONLY_IMAGE=
    YES

PRODUCTION_ACCEPTANCE_CLAIM=
    NO

PAIR_COUNT_VALID=
    <REQUIRED_VALUE>

A1_PROBE_WADDR_NACKS=
    <REQUIRED_VALUE>
A1_PROBE_REGADDR_NACKS=
    <REQUIRED_VALUE>
A1_PROBE_DATA_NACKS=
    <REQUIRED_VALUE>
A1_AUTOINIT_WADDR_NACKS=
    <REQUIRED_VALUE>
A1_AUTOINIT_REGADDR_NACKS=
    <REQUIRED_VALUE>
A1_AUTOINIT_DATA_NACKS=
    <REQUIRED_VALUE>
A1_FAILED_TXN_TOTAL=
    <REQUIRED_VALUE>
A1_NVP_RESULT=
    <REQUIRED_VALUE>

B1_NACK_COUNT=
    <REQUIRED_VALUE>
B1_NVP_RESULT=
    <REQUIRED_VALUE>

A2_PROBE_WADDR_NACKS=
    <REQUIRED_VALUE>
A2_PROBE_REGADDR_NACKS=
    <REQUIRED_VALUE>
A2_PROBE_DATA_NACKS=
    <REQUIRED_VALUE>
A2_AUTOINIT_WADDR_NACKS=
    <REQUIRED_VALUE>
A2_AUTOINIT_REGADDR_NACKS=
    <REQUIRED_VALUE>
A2_AUTOINIT_DATA_NACKS=
    <REQUIRED_VALUE>
A2_FAILED_TXN_TOTAL=
    <REQUIRED_VALUE>
A2_NVP_RESULT=
    <REQUIRED_VALUE>

B2_NACK_COUNT=
    <REQUIRED_VALUE>
B2_NVP_RESULT=
    <REQUIRED_VALUE>

A3_PROBE_WADDR_NACKS=
    <REQUIRED_VALUE>
A3_PROBE_REGADDR_NACKS=
    <REQUIRED_VALUE>
A3_PROBE_DATA_NACKS=
    <REQUIRED_VALUE>
A3_AUTOINIT_WADDR_NACKS=
    <REQUIRED_VALUE>
A3_AUTOINIT_REGADDR_NACKS=
    <REQUIRED_VALUE>
A3_AUTOINIT_DATA_NACKS=
    <REQUIRED_VALUE>
A3_FAILED_TXN_TOTAL=
    <REQUIRED_VALUE>
A3_NVP_RESULT=
    <REQUIRED_VALUE>

B3_NACK_COUNT=
    <REQUIRED_VALUE>
B3_NVP_RESULT=
    <REQUIRED_VALUE>

POSTINIT_WADDR_PROCESS=
    <REQUIRED_VALUE>
POSTINIT_REGADDR_PROCESS=
    <REQUIRED_VALUE>
POSTINIT_DATA_PROCESS=
    <REQUIRED_VALUE>

AUTOINIT_PHASE_RATE_HETEROGENEITY=
    <REQUIRED_VALUE>
AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR=
    <REQUIRED_VALUE>
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR=
    <REQUIRED_VALUE>
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA=
    <REQUIRED_VALUE>

R1H_REPLICATE_HOMOGENEITY=
    <REQUIRED_VALUE>
BANK_TRACKER_COHERENCE=
    <REQUIRED_VALUE>
FAILED_TRANSACTION_DISTRIBUTION=
    <REQUIRED_VALUE>
PAIRED_AB_RESULT=
    <REQUIRED_VALUE>

GLOBAL_PROGRAM_RETRY_BUDGET=
    1

GLOBAL_PROGRAM_RETRIES_USED=
    <REQUIRED_VALUE>

HOST_ONLY_CORRECTION_CYCLES_USED=
    <REQUIRED_VALUE>

FPGA_PROGRAM_INVOCATIONS=
    <REQUIRED_VALUE>
WARM_REBOOTS=
    <REQUIRED_VALUE>
DRIVER_LOADS=
    <REQUIRED_VALUE>

AXI_LITE_WRITES=
    0

DMA_TRANSFERS=
    0

PHYSICAL_ACTIONS=
    0

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
    <REQUIRED_VALUE>
FINAL_DIAGNOSTIC_MAGIC=
    <REQUIRED_VALUE>
FINAL_PINNED_DRIVER_LOADED=
    <REQUIRED_VALUE>
FINAL_DONE=
    <REQUIRED_VALUE>

ROOT_CAUSE_SOLELY_PROVEN=
    NO

EVIDENCE_PACKAGE_SHA256=
    <REQUIRED_VALUE>
EVIDENCE_REPOSITORY_COMMIT=
    <REQUIRED_VALUE>
PUBLICATION_RESULT=
    <REQUIRED_VALUE>

NEXT_ACTION=
    OWNER_REVIEW_OF_THE_R1H_LARGE_SAMPLE_RESULT
```
