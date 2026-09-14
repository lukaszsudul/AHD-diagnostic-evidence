# AHD v41 G2B-NVP-OFFLINE-ADVANCE1 main report

## Result separation

- Engineering gate: `PASS`
- Evidence publication: `PENDING_POST_PUSH_READBACK`
- Overall result: `PASS_OFFLINE_AUDITS_COMPLETE_NO_FUNCTIONAL_CANDIDATE_READY`
- Umbrella offline gate: `24/24 PASS`
- Offline-only: `YES`
- DUT accessed: `NO`

## Workstream A — RM1

RM1 clean-room source was committed as
`a7436eb81f69f09ee84301bcf214fcaa2b680ee8`, tree
`cce4a561a30d58d4accc2a45e4eb8d72e5a7ec26`, directly above parent
`fc37d815b5d64ef90dfbd99c57ae4cc09567b56f`. The exact eleven blobs passed a
fresh remote commit-pinned byte read-back. Focused tests passed 18/18 and the
affected R3 suite passed 25/25 with protected inputs byte-identical.

The single full build failed before synthesis while Tcl evaluated a dynamically
quoted publication-receipt regex and reported `invalid command name "\\t"`.
The finalizer did not run; timing, CDC, DRC, methodology and resource gates were
not reached. No DCP, bitstream or RM1 HW1 prompt was created. Classification:
`RM1_BUILD_BLOCKED`.

## Workstream B — MODE1

The audit identified 176 semantic operations, 173 executor-included operations
and 113 touched registers. Recovery classification is exactly 5
`EXACT_READ_RESTORE` and 108 `PROHIBITED_UNRESOLVED`; all other recovery classes
are zero. Bank 1/0xED and Bank 9/0x44 remain prohibited/unresolved. Initial-EQ
authority is partial, ACP necessity for first image is unresolved, recovery
coverage is structurally 100%, and the failure matrix covers 1211/1211 cases.
The focused model result is 16 PASS / 8 BLOCKED. No MODE1 source, build, DCP,
bitstream or HW1 prompt was created. Classification:
`MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE`.

## Workstream C — camera and connector

The strict search found zero schematic/PCB/as-built design files in the three
authorized roots or their relevant Git histories. The high-confidence logical
tuple is `TESTED_CONNECTOR_INSTANCE -> UNKNOWN_EXTERNAL_AFE_PATH -> VIN1/U6.76 -> CH1`;
physical connector refdes and routing remain unresolved. A 75-ohm
termination is only a datasheet expectation, not a schematic/as-built proof.
Camera model requires Owner input, standard is unknown, and the external tester
was not run. First failed gate: `CONNECTOR_REFDES_NOT_FOUND`.

## Causal limits

Alternating CH2/CH4 behavior is compatible with route-dependent state but does
not prove parity, private-bank, delay, C8/CA, or VDO1 re-arm causality. RM1 was
designed to observe raw markers without DMA, but its implementation is not
signed off. The CH1 MODE1 path remains independently blocked by compatibility,
initial-EQ and deterministic-recovery authority. The connector-to-VIN physical
path remains an Owner documentation/continuity task.

## Next authorized package

Only the existing COMPAT0-R2R1 CONT1 prompt is generated. RM1 HW1 and MODE1 HW1
are absent. A new governed decision is required before any RM1 build fix/retry.
Physical continuation requires connector refdes/schematic/PCB/as-built evidence,
camera model and externally confirmed standard.
