# AHD v41 META-6 SSOT Update Report

## Result

- Engineering gate: `PASS`.
- Update type: `ARCHITECTURE_CHANGE`.
- Authorization literal: `SSOT WRITE AUTHORIZED`.
- Owner/Architect approval: `GRANTED` by `META-6_TASK_DIRECTIVE`.
- `PROJECT_STATE_REV_AT_START = 5`.
- `PROJECT_STATE_REV_AT_END = 6`.
- Frozen write contract: `VERIFIED`.
- META-5 procedural precedent: `VERIFIED` at
  `bbdeb474ce9d7e5f0db3e8ca8afb5448eef8f314`.
- META-4R2 unnumbered-decision precedent: `VERIFIED` at
  `27dcf152e862c6db88a365328b92c0fd250f04c2`.
- G14-A evidence: `VERIFIED` at
  `9e91315968453e859006077191cd5fc711fc6b96`.
- Expected SSOT files: `16`.
- Actual SSOT files: `16`.
- Unauthorized SSOT files: `0`.
- `SSOT_CONSISTENCY = PASS`.

The publication commit and fresh remote read-back are executor completion
actions. This in-commit report does not invent a not-yet-created containing
commit SHA or pre-complete the remote read-back.

## Frozen-contract preflight

Current frozen governance, update policy, META template, state schema, and the
successful META-5 package were read before mutation. The supported contract is
the standalone `SSOT WRITE AUTHORIZED` literal plus the exact fields
`UPDATE_TYPE`, `EXPECTED_PROJECT_STATE_REV`, `OWNER_ARCHITECT_DECISION`,
`EVIDENCE_REPOSITORY`, `EVIDENCE_COMMIT`, `EVIDENCE_DIRECTORY`, and
`EXPECTED_AFFECTED_FILES`. There is no separate governed `AUTHORIZATION:` input
field.

Both machine mirrors reported revision 5, the 18-entry SSOT manifest passed,
local and remote `main` matched the evidence authority, and the calculated
16-file footprint was recorded before the first SSOT edit. The complete input
and preflight are preserved in `META6_WRITE_CONTRACT_RECEIPT.md` and
`META6_EXPECTED_AFFECTED_FILES.md`.

The authoritative G14-A package passed all 65 manifest entries and its
engineering gate. The exact directory tree is
`ae0c1472b90bf4cecc2df8feebe192b35b8355be`; candidate-XDC SHA-256 is
`094F7182116FC2A2C68479B8BDB6A6C2327F14DA6ABFEB244EC7F26D7BE2809A`.

## Accepted Group-14 promotion

Group 14 is `RELEASE_SLOT_0_AXI_TO_SOURCE`. The old required method
`GLOBAL_SET_BUS_SKEW_3NS`—the exact relation
`set_bus_skew 3.000 -from $g2b_release0_payload_src -to $g2b_release_payload_dst`
over 56 sources and 20 destinations—is `RETIRED_FROM_REQUIRED_SIGNOFF`. Its
verified `301.299 s` bounded timeout remains historical provenance; the full
query was not retried. The path set is `INVALID_FOR_SKEW_COMPARISON`.

The promoted method is `SETTLING_PLUS_STRUCTURAL_CDC`, decision
`REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`. The exact three families are:

1. `RELEASE_SLOT0_NORMAL_STATE_TRANSITION`: 56 sources to 3 destinations,
   `6.000 ns` required, `5.467 ns` worst actual, `0.563 ns` slack, `63.236 s`;
2. `RELEASE_SLOT0_MISMATCH_CONTAINMENT`: 56 sources to 4 destinations,
   `6.000 ns` required, `5.554 ns` worst actual, `0.478 ns` slack, `0.117 s`;
3. `RELEASE_SLOT0_RESET_OVERLAP_ACCOUNTING`: 56 sources to 3 destinations,
   `6.000 ns` required, `4.191 ns` worst actual, `1.839 ns` slack, `0.111 s`.

All three candidate timing validations passed. The candidate contains exactly
three `set_max_delay -datapath_only 6.000` requirements. The `6.000 ns` value
comes from the G14-A evidence and its existing governed aggregate AXI-to-source
mailbox bound; META-6 invents no numerical limit.

The timing requirements are inseparable from the accepted structural proof:
the 24-bit generation plus 32-bit epoch token is held stable through event
consumption; token and release toggle launch on the same accepted final beat;
ordinary use follows the two-stage `release_toggle` synchronizer; reset
accounting follows the two-stage transport-request synchronizer; both chains
use destination-domain `ASYNC_REG` stages; ordinary release decoding is
suppressed during reset; acknowledgement waits for synchronized release phase
to equal the captured phase and for retirement; destination use requires the
matching generation, descriptor epoch, reset epoch, and `DMA_OWNED` state; and
all identity mismatch fails closed by latching ownership-fatal containment and
disabling admission. Reset abandonment uses the same-episode token before
captured release-phase retirement. Timing alone and structure alone are each
insufficient.

The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT` and is not a safety
relaxation. `GROUP14_CDC_STRUCTURE = PASS_WITH_DISPOSITION` and
`SIGNOFF_RUNTIME = PRACTICAL`. `RTL_CHANGE_REQUIRED = NO`.

## Active-XDC and implementation boundary

Active production XDC was not modified by META-6. For Group 14,
`ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`. Candidate
authority is `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` from the exact G14-A commit.

Group 9 remains promoted with `PRESERVE_PASS`; Groups 10–12 remain
`PRESERVE_PASS`; Group 13 remains promoted with `PRESERVE_PASS`. None is to be
repeated. Promotion-time pending-XDC fields for Group 9 and Group 13 are
retained only as explicitly labelled historical boundaries, not current work
instructions. `GROUP9_GOVERNANCE_REGRESSION = NO` and
`GROUP13_GOVERNANCE_REGRESSION = NO`.

Groups 15–17 remain `PENDING_UNCHANGED`. The Group-14 decision is a named
`UNNUMBERED_GOVERNED_DECISION`; no OD number was invented. All 12 open numbered
OD records, the decided OD-03 record, and the prior Group-9 and Group-13
unnumbered decisions are preserved.

G2B-LUT1 remains `READY_FOR_SIGNOFF_RECOVERY`, not qualified or released.
G2B-HW remains `BLOCKED`, with no bitstream and no hardware proof. The next
allowed engineering step is `G2B-LUT1-SIGNOFF-RECOVERY-3`: preserve prior PASS
results, implement and validate only the promoted Group-14 candidate, continue
Groups 15–17, and then complete routed timing, DRC, CDC disposition, clocks,
PRODUCT resources, and the pre-bitstream hard gate. Bitstream generation is
allowed only after PASS and is outside META-6.

## Validation and protection audit

- `PROJECT_STATE.json`: parse and project-state checks `PASS`.
- `TRACK_STATUS.json`: parse and project-state checks `PASS`.
- compatibility CSV: 18 data rows and 8 columns `PASS`.
- revision and recovery-gate mirrors: `PASS`.
- G14-A evidence values and candidate identity: `PASS`.
- open/decided numbered decision identity: `PASS`.
- Group-14 current stale required-signoff reference scan: `NONE`.
- Group-9 governance regression: `NO`.
- Group-13 governance regression: `NO`.
- final 18-entry SSOT SHA-256 manifest: `PASS`.
- exact expected-versus-actual SSOT change set: `PASS`.
- `git diff --check`: `PASS`.

Protection anchors remained unchanged: FPGA_AHD commit
`be94f88ee8d179f12928ab791bdae27c22cd1762`, tree
`e128ff47a5e21e8131971f5e5caa7657e2eccc7f`; V41_G2B commit
`64feb60de5d07f400e6b92527bfe54838b3372ee`, tree
`26399ed456941e26d5ee4b1b2ca50392338fa24a`; active-XDC SHA-256
`C12A371F7F21D350A28C6B310046D543C788D40E805160F12C49FB24C467674C`.
Tracked source/index changes were absent. FPGA_AHD source modified `NO`; RTL
modified `NO`; active XDC modified `NO`; R-track modified `NO`; Vivado executed
`NO`; bitstream produced `NO`; DUT/hardware/JTAG/PCIe/DMA accessed `NO`; reboot
and power-cycle performed `NO`.

## Publication contract

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Branch: `main`.
- Exact commit subject: `Promote AHD v41 Group 14 release-slot sign-off method to project state rev6`.
- Push mode: ordinary fast-forward, never force.
- Required completion: remote HEAD equality plus fresh SHA-256 read-back of
  all 19 SSOT files and all 10 META-6 package files.
