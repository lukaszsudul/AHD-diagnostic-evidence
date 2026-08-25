# V41 NVP R1h-R4 SUPER-FAST implementation and large-sample campaign

## Authoritative outcome

R1h-R4 completed successfully. The exact synthesized R1h checkpoint was
continued without source changes or synthesis, and the sole implementation
session produced a diagnostic-only bitstream. All implementation hard gates
passed. The frozen campaign then completed in the exact order
`Bootstrap -> A1 -> B1 -> A2 -> B2 -> A3 -> B3`, with three valid paired
samples and no programming retry.

The scientific result is sharply separated from infrastructure validity. All
three Arm-A samples were complete and instrumentation-valid, but each had the
functional classification `R1H_NVP_FAIL`. All three exact Formal Phase-2
controls were complete and valid, and each had the functional classification
`FORMAL_NVP_FAIL`. A valid scientific FAIL did not stop or invalidate the
campaign.

The experiment ended in the required safe state: exact Formal Phase 2,
runtime identity `A40A0C07 / 0000400B / 00031002`, diagnostic magic zero,
the exact pinned driver loaded, and fresh JTAG `DONE=1`.

## Scope, owner risk acceptance, and immutable identities

The owner authorized SUPER-FAST diagnostic execution with the 5% free
Slice-LUT floor and explicitly removed report-only preflight findings as hard
blockers. The implementation still retained every real hard gate: exact DCP,
part and provenance; opt/place/route success; nonnegative setup timing;
positive hold timing; zero unrouted nets; the 5% final resource floor; zero
DRC errors or critical warnings; and one successful bitstream attempt.

No source, XDC, XCI, register map, probe parameter, statistical method, or
scientific scope changed. No synthesis ran in this task.

```text
OWNER_PROMPT_SHA256=61EC5F55015C28B5136251148D69FEED7071364EB7EE44002DD750E4CA15E4A1
OWNER_PROMPT_BYTES=22278
R1H_SOURCE_COMMIT=c4f4bfcf577c92c3021d1fe83c05878dd12e001c
R1H_SOURCE_TREE=161e561f007912d73dba93c5ecd78e3cc3a6955b
R1H_SYNTH_DCP_SHA256=807D292909804FDE573867A681A3407366BF9AF0796E290E609951B7DD68E46E
PART=xc7a35tcsg325-2
TOP=ahd_capture_top_xdma
VIVADO=2025.2 build 6299465
FORMAL_BIT_SHA256=7E4E909D78C2BE5C1E0ECA56229F2B88ECC2DBF5974B32BDF07EF1AFCD9449A2
```

The exact owner prompt is `raw/OWNER_PROMPT_VERBATIM.txt`. The input DCP is
`raw/R1H_synth.dcp`; it is an actual 46,972,058-byte checkpoint, not a Git-LFS
pointer. The scientific source worktree remained clean at the exact commit and
tree.

## Implementation hard gates

The frozen task-local Tcl was
`scripts/continue_exact_r1h_r4_super_fast.tcl`, SHA-256
`07F4113E45CD3156FAEEBDA705EB04A1F7CDF0737F9AD54BA318A579C2E16B82`.
Its command inventory contained one each of open-checkpoint, opt, place,
phys-opt, route, routed-checkpoint, and bitstream operations; it contained no
synthesis, source, constraint, XCI, project, directive, or raw ROUTE-property
query. The raw nonempty ROUTE-property finding from R3 was never queried or
used as a gate.

| Gate | Result |
|---|---:|
| Post-opt Slice LUT / registers | 17,510 / 19,381 |
| Post-opt resource class | `PASS_STANDARD_MARGIN` |
| Post-opt R1h storage attribution | 6 + 1 + 1 + 1 RAMB18 payload stores, FDRE 81 + 3, RAM64M/RAMD64E 0 |
| Place / route | PASS / PASS |
| Route errors / unrouted nets | 0 / 0 |
| WNS / WHS | +0.617 ns / +0.036 ns |
| Failing setup / hold paths | 0 / 0 |
| Final Slice LUT / registers | 17,119 / 19,381 |
| Final resource class | `PASS_STANDARD_MARGIN` |
| DRC errors / critical warnings | 0 / 0 |
| CDC critical / unknown | 0 / 0 |

The output bitstream is
`implementation/ahd_capture_v41_i2c_25khz_r1h_phase_complete_observability.bit`,
2,192,144 bytes, SHA-256
`73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41`.
The routed DCP SHA-256 is
`BB73A8B90AEE8F87F6706CD0F0C5D7D5D3DC77603071B057B17750DB7B64B394`.
This is a diagnostic-only image; production acceptance is not claimed.

The machine result SHA-256 is
`E8D755A52FEEDB6CEB4B514728B48074464482275423B8DF6B3BD5A228164751`.
The independent implementation audit SHA-256 is
`E44570F411E20BB3CDCBF98401D7E59D93B01C14192AAAC44371CE5E1133EDED`.

## Minimal safety gate, mandatory bootstrap, and accounting

The selected target was stable at
`Xilinx/80802026a98b01`, part `xc7a35t`, IDCODE `0362D093`. The host was
reachable on kernel `7.0.0-29-generic`, with the next reboot pinned to kernel
29, no XDMA node owner, zero task DMA, and no fatal kernel/AER finding. The
hardware binding document SHA-256 is
`6B1D02E29D964250DA169957FB4FC9AC2384220C2B89649BDD20C5C077F8D4AB`.

The mandatory bootstrap programmed exact Formal Phase 2, waited at least five
seconds, performed one warm reboot, loaded the exact pinned driver, verified
the formal runtime identity and diagnostic magic zero, and ended with fresh
DONE 1. The resulting formal-ready receipt SHA-256 is
`9DB981816CCD38ECD23CA7A22EA7D6B4F653194032CB8BA7FF8C3319A82B18F4`.

The complete campaign consumed seven valid one-shot programs: four formal
programs (bootstrap plus B1/B2/B3) and three R1h programs. It consumed seven
warm reboots and seven pinned-driver loads. The global infrastructure retry
budget remained unused. All runtime BAR access was `O_RDONLY`/`pread`-only;
AXI-Lite writes, C2H/H2C DMA, and physical actions were all zero.

Three supervisor/postprocessor defects were recovered from immutable completed
program logs without reprogramming: bootstrap, A1, and B1. A read-only JTAG
safety wrapper also needed postprocessing after an empty-stderr serialization
defect, without a second JTAG session. These were process-evidence corrections,
not programming retries. Two live-image host-reader correction cycles were
used: one bootstrap runtime-reader syntax correction and one A1 telemetry path
sanitization/formatting correction. Both stayed on the same image and boot,
used no reboot or reprogram, and performed no write or DMA.

## Three paired repetitions

All T0/T1 pairs were coherent. All three Arm-A probes reported DONE and not
ABORTED, each phase reached exactly 10,000 target opportunities, all probe
timeouts were zero, failed-record overflow was zero, bank-invariant errors were
zero, the safe target remained `0x00`, the original bank was restored and
verified, and final DONE was 1.

| Run | Autoinit opportunities W/R/D/RA | Autoinit NACK W/R/D/RA | Post-init NACK W/R/D | Failed total/stored/overflow | NVP result |
|---|---|---|---|---|---|
| A1 | 273 / 273 / 219 / 54 | 3 / 5 / 7 / 0 | 0 / 0 / 0 | 7 / 7 / 0 | `R1H_NVP_FAIL` |
| A2 | 275 / 275 / 220 / 55 | 1 / 4 / 2 / 1 | 0 / 0 / 0 | 5 / 5 / 0 | `R1H_NVP_FAIL` |
| A3 | 276 / 276 / 220 / 56 | 3 / 3 / 4 / 0 | 0 / 0 / 0 | 5 / 5 / 0 | `R1H_NVP_FAIL` |

The lifecycle count readbacks were A1 `132404591` (signed error `-180143`
cycles), A2 `132584735` (`+1`), and A3 `132688568` (`+103834`) relative to
the modeled `132584734`. The validity contract did not require equality to the
modeled count, and all static T0/T1 fields were coherent. These differences are
retained as scientific observations and are not assigned a cause.

Each B control re-established exact Formal Phase 2, diagnostic magic zero, the
pinned driver, coherent normal telemetry, deterministic zero over the complete
R1h diagnostic range, and fresh DONE 1. B1, B2, and B3 each observed aggregate
NACK count 12 and each was a valid `FORMAL_NVP_FAIL` scientific control.

The cumulative independent campaign audit is
`hardware/07_B3/INDEPENDENT_FORMAL_CONTROL_AND_FINAL_CAMPAIGN_AUDIT.md`,
SHA-256
`D9EC2A6233E0BA70CCBFE9E31738C48885AEBBC1BFD63DBC8B4AF3D2D666CA82`.

## Frozen statistical analysis

The exact frozen statistics implementation SHA-256 was
`C0188FF2AB7AC03034DAA7F412F447E3DBC21C15FB5458B126C0A96FEB771CCD`.
The opportunity audit passed exactly `90000/90000`: 90,000 ACK, zero NACK,
and zero timeout. The pooled Wilson 95% interval for the post-init target NACK
rate is `[0, 0.0000426810540]`; this is zero observed events, not proof that
the underlying rate is exactly zero.

All nine individual phase panels had zero events, so temporal
stationarity/independence is `INSUFFICIENT_EVENTS`. The autoinit-versus-postinit
support rule was met for WADDR in A1 and A3 and for REGADDR and DATA in all
three runs. Each supported comparison had Holm-adjusted `p < 0.01` and a
rate-ratio lower 95% bound greater than 2. Therefore context-rate elevation is
supported for all three write phases.

Autoinit phase-rate heterogeneity was not detected, which is not an equality
proof. No estimable replicate-family test rejected at 0.05. The planned exact
TABLE_SLOT composition test exceeded the frozen 250,000-table enumeration cap,
so the strict replicate classification is `INSUFFICIENT_VALID_DATA`; this is
not evidence against homogeneity. Failed transactions showed a repeatable
composition concentration, but category opportunity denominators were absent,
so no category-rate claim is made.

Arm-A aggregate NACK totals were `15, 8, 10`; the B controls were `12, 12,
12`. Paired A-minus-B differences were `+3, -4, -2`, yielding a descriptive
majority direction in two of three pairs (one-sided sign `p=0.5`, two-sided
`p=1.0`). This is not statistically compelling.

The detailed report SHA-256 is
`49ACF5BA58F72042A00C5EA795700240334DDAE073A0AF543E211A620D5F3690`;
the independent analysis receipt SHA-256 is
`A78E62150E16C775567FEDD2D2FB162E326A74910B9F454F44C91CA8E098ED62`.

## Interpretation limits and final state

The data support context-dependent autoinit rate elevation relative to the
zero-event post-init target panels under the frozen criteria. They do not
prove a sole root cause, VCCO droop, ground bounce, or analog margin because
none of those physical quantities was directly measured.

B3 is the authoritative terminal state. Its formal-ready receipt SHA-256 is
`DC0EAAD18A9B29A64D0AB13B67A08ED985EC2C292971EC56C334C776E7A714BA`.
The shared implementation/hardware lock was released only after the exact
final formal state and independent cumulative audit were sealed; the release
receipt is `raw/SHARED_LOCK_RELEASE_RECEIPT.txt`.

Evidence sealing and publication are intentionally noncircular. This report
is immutable inside the ZIP and evidence commit, so the package digest,
publication commit, and public-verification outcome are recorded in external
sidecar/publication receipts referenced by the terminal block. Publication
status cannot change the scientific result or trigger a hardware rerun.

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
    17510
POST_OPT_SLICE_REGISTERS=
    19381
POST_OPT_RESOURCE_CLASS=
    PASS_STANDARD_MARGIN

PLACE=
    PASS
ROUTE=
    PASS
ROUTE_ERRORS=
    0
UNROUTED_NETS=
    0
WNS=
    0.617
WHS=
    0.036
FINAL_SLICE_LUTS=
    17119
FINAL_SLICE_REGISTERS=
    19381
FINAL_RESOURCE_CLASS=
    PASS_STANDARD_MARGIN

R1H_BIT_SHA256=
    73E973A42083D7D22CF427ED09B73F8DE2D2C05506697EA36E1FA1B5F7163C41
R1H_ROUTED_DCP_SHA256=
    BB73A8B90AEE8F87F6706CD0F0C5D7D5D3DC77603071B057B17750DB7B64B394
SOURCE_COMMIT_TO_BIT_PROVENANCE=
    PASS_BY_EXACT_SHA_BOUND_DCP

DIAGNOSTIC_ONLY_IMAGE=
    YES

PRODUCTION_ACCEPTANCE_CLAIM=
    NO

PAIR_COUNT_VALID=
    3

A1_PROBE_WADDR_NACKS=
    0
A1_PROBE_REGADDR_NACKS=
    0
A1_PROBE_DATA_NACKS=
    0
A1_AUTOINIT_WADDR_NACKS=
    3
A1_AUTOINIT_REGADDR_NACKS=
    5
A1_AUTOINIT_DATA_NACKS=
    7
A1_FAILED_TXN_TOTAL=
    7
A1_NVP_RESULT=
    R1H_NVP_FAIL

B1_NACK_COUNT=
    12
B1_NVP_RESULT=
    FORMAL_NVP_FAIL

A2_PROBE_WADDR_NACKS=
    0
A2_PROBE_REGADDR_NACKS=
    0
A2_PROBE_DATA_NACKS=
    0
A2_AUTOINIT_WADDR_NACKS=
    1
A2_AUTOINIT_REGADDR_NACKS=
    4
A2_AUTOINIT_DATA_NACKS=
    2
A2_FAILED_TXN_TOTAL=
    5
A2_NVP_RESULT=
    R1H_NVP_FAIL

B2_NACK_COUNT=
    12
B2_NVP_RESULT=
    FORMAL_NVP_FAIL

A3_PROBE_WADDR_NACKS=
    0
A3_PROBE_REGADDR_NACKS=
    0
A3_PROBE_DATA_NACKS=
    0
A3_AUTOINIT_WADDR_NACKS=
    3
A3_AUTOINIT_REGADDR_NACKS=
    3
A3_AUTOINIT_DATA_NACKS=
    4
A3_FAILED_TXN_TOTAL=
    5
A3_NVP_RESULT=
    R1H_NVP_FAIL

B3_NACK_COUNT=
    12
B3_NVP_RESULT=
    FORMAL_NVP_FAIL

POSTINIT_WADDR_PROCESS=
    INSUFFICIENT_EVENTS
POSTINIT_REGADDR_PROCESS=
    INSUFFICIENT_EVENTS
POSTINIT_DATA_PROCESS=
    INSUFFICIENT_EVENTS

AUTOINIT_PHASE_RATE_HETEROGENEITY=
    NOT_DETECTED_NOT_EQUALITY_PROOF
AUTOINIT_CONTEXT_RATE_ELEVATION_WADDR=
    SUPPORTED
AUTOINIT_CONTEXT_RATE_ELEVATION_REGADDR=
    SUPPORTED
AUTOINIT_CONTEXT_RATE_ELEVATION_DATA=
    SUPPORTED

R1H_REPLICATE_HOMOGENEITY=
    INSUFFICIENT_VALID_DATA
BANK_TRACKER_COHERENCE=
    PASS_ZERO_INVARIANT_ERRORS
FAILED_TRANSACTION_DISTRIBUTION=
    REPEATABLE_FAILURE_COMPOSITION_CONCENTRATION_DENOMINATORS_LIMIT_RATE_CLAIM
PAIRED_AB_RESULT=
    DIRECTION_MAJORITY_2_OF_3

GLOBAL_PROGRAM_RETRY_BUDGET=
    1

GLOBAL_PROGRAM_RETRIES_USED=
    0

HOST_ONLY_CORRECTION_CYCLES_USED=
    2

FPGA_PROGRAM_INVOCATIONS=
    7
WARM_REBOOTS=
    7
DRIVER_LOADS=
    7

AXI_LITE_WRITES=
    0

DMA_TRANSFERS=
    0

PHYSICAL_ACTIONS=
    0

FINAL_ACTIVE_IMAGE=
    FORMAL_PHASE2

FINAL_FORMAL_IDENTITY=
    A40A0C07 / 0000400B / 00031002
FINAL_DIAGNOSTIC_MAGIC=
    0
FINAL_PINNED_DRIVER_LOADED=
    YES
FINAL_DONE=
    1

ROOT_CAUSE_SOLELY_PROVEN=
    NO

EVIDENCE_PACKAGE_SHA256=
    SEE_EXTERNAL_PACKAGE_SHA256_SIDECAR_NONCIRCULAR
EVIDENCE_REPOSITORY_COMMIT=
    SEE_EXTERNAL_PUBLICATION_RECEIPT_NONCIRCULAR
PUBLICATION_RESULT=
    SEE_EXTERNAL_PUBLICATION_RECEIPT_NONCIRCULAR

NEXT_ACTION=
    OWNER_REVIEW_OF_THE_R1H_LARGE_SAMPLE_RESULT
```
