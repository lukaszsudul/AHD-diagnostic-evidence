# Workstream B — ACQ1-MODE1 offline audit/model report

## Outcome

- Initial-EQ classification: `MODE1_INITIAL_EQ_AUTHORITY_INCOMPLETE`
- Recovery disposition: `MODE1_RECOVERY_AUTHORITY_INCOMPLETE`
- ACP required for first image: `UNRESOLVED`
- Candidate/build/bitstream/hardware prompt: not created
- First blocker: `ACQ1_REFERENCE_ONLY_FUNCTIONAL_WRITES_LACK_NVP6134C_COMPATIBILITY_AND_COMPLETE_BASELINE_READBACK_AUTHORITY`

The MODE1 candidate worktree was treated as read-only.  This workstream produced
only task-local audit and model artifacts.

## Frozen authority

- ACQ1-COMPAT source commit: `dae2aff60141ecdbc0afac08fc0df9a3166f66c6`
- ACQ1-COMPAT source tree: `21e33d481ef637667756caa8015e7fa1b1dd8ebf`
- pinned reference commit: `081ebbff9a2722d47acf16c680594be43cb179e2`
- SCAN0 manifest file SHA-256: `9537C24203A3A34978E100779A06DEEC9CE984DB3EB0DFE19DC89654BE3BA6B9`
- SCAN0 semantic action digest: `64FFDBB1EF5E34D4DA2301B0256CFE2BA271E41ECDF26D64F85E42223C6344C1`
- NVP6134C Rev1.0 PDF SHA-256: `301FF799A101B0DBDF6CD946EEAD0C1EDC67D07FFEAC7E65FA8C6AE82C316E46`

The PDF was used only for public semantics.  Vendor implementation was not copied.

## Semantic graph and exclusions

For CH1 / PAL / `NVP6134_VI_1080P_2530`, the independent semantic path is:

`set_chnmode` -> common channel configuration -> FHD common configuration ->
AHD 1080p25/30 configuration -> software status updates -> minimum initial EQ ->
Bank 9 re-arm pulse (`0x61`, 35 ms, `0x00`) -> Bank 0 CH1 enable.

ACP/coax contributes 35 source operations and 210 ms in the donor path and is
excluded from this no-ACP semantic audit model.  That exclusion does not establish
that ACP is unnecessary for first-image acquisition.  The available evidence
neither proves ACP indispensable nor proves first image without ACP; therefore the
final-template field is exactly `ACP required for first image: UNRESOLVED`.
Camera-control, adaptive EQ, audio, motion, unrelated formats and CH2-CH4
coefficients are excluded.  Three vendor software-state rows remain documented but
are not included in the minimum executor action.

No-ACP phase rows are: COMMON 52, FHD_COMMON 57, AHD1080P25 50, EQ_INIT 9,
POST_MODE 6 and STATE 2, totaling 176 semantic rows.  Included executable-model
rows are 173.

## Recovery classification and model gate

There are 113 unique touched functional registers: Bank `0x00` = 27, Bank
`0x01` = 3, Bank `0x02` = 6, Bank `0x05` = 41, Bank `0x09` = 15, Bank
`0x0A` = 20 and Bank `0x11` = 1.
Exactly 5 are `EXACT_READ_RESTORE`; 108 are `PROHIBITED_UNRESOLVED`.  No target is
assigned more than one of the six permitted recovery classes.

Bank 1 / `0xED` and Bank 9 / `0x44` are both required masked updates and both are
`PROHIBITED_UNRESOLVED`; see their separate disposition reports.

Failure coverage is 1211/1211 (`173 operations x 7 failure types`): 1205 fatal and
6 exactly recovered before any unresolved functional write may have committed.
The focused local model gate is 16 PASS / 8 BLOCKED across T1-T24.  Blocked tests
are T2, T8, T16, T17, T18, T19, T20 and T21.  T19-T21 have scope
`MODEL_CONTRACT_DEFINED_NOT_RTL_IMPLEMENTED`: their behavioral contracts exist in
the model, but no RTL implementation proves arbitration, publication suppression
or result retention through ACK.

## Inherited SCAN1 and ACQ tests

The explicit disposition is `G2B_NVP_MODE1_INHERITED_TEST_DISPOSITION.json`:

- SCAN1: `PASS 24/24`; receipt
  `inherited-scan1-gate-01/G2B_NVP_CAMERA_SCAN1_R1_SIMULATION_RECEIPT.txt`;
  SHA-256 `28CA649BF0E2151EA8F924114DF58134F7FE75288FECF0E4A1DF49D705A9D86F`.
- ACQ: `PASS 20/20`; receipt
  `inherited-acq-gate-01/G2B_NVP_ACQ1_COMPAT0_R2_TEST_RECEIPT.txt`;
  SHA-256 `F8BB98CCAD4B98C54FF32B1B18C3E8CAC2E52802FB143C3DA72053F91A342F5F`.

Both receipts identify the clean MODE1 parent at
`dae2aff60141ecdbc0afac08fc0df9a3166f66c6` and record no hardware access.  The
SCAN1 receipt also records tree `21e33d481ef637667756caa8015e7fa1b1dd8ebf`.
These inherited PASS results do not prove a MODE1 RTL implementation for T19-T21;
those tests remain BLOCKED with scope
`MODEL_CONTRACT_DEFINED_NOT_RTL_IMPLEMENTED`.

## Boundary

No RTL/source modification, generic host I2C, DUT access, MMIO, DMA, JTAG, Vivado,
build, commit, DCP, bitstream or hardware prompt was performed or produced.
