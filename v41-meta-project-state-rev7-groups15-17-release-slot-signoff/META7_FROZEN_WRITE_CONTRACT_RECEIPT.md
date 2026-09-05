# META-7R Frozen Write Contract Receipt

Executing role: `META_UPDATE_AGENT`. Update type: `ARCHITECTURE_CHANGE`.
Standalone `SSOT WRITE AUTHORIZED`: `RECOGNIZED`.
Corrected frozen write contract: `VERIFIED`. Owner/Architect approval: `GRANTED`.
The prior malformed META-7 attempt is superseded and is not reused.

## Exact corrected contract, preserved without field or literal changes

```text
UPDATE_TYPE:
ARCHITECTURE_CHANGE

SSOT WRITE AUTHORIZED

EXPECTED_PROJECT_STATE_REV:
6

OWNER_ARCHITECT_DECISION:
Promote the accepted G2B-G15-17-EQ release-slot sign-off architecture for
Groups 15, 16, and 17 into project-current-state revision 7. Retire the
required global 3.000 ns set_bus_skew checks for RELEASE_SLOT_1_AXI_TO_SOURCE,
RELEASE_SLOT_2_AXI_TO_SOURCE, and RELEASE_SLOT_3_AXI_TO_SOURCE. Replace them
with independently validated slot-specific SETTLING_PLUS_STRUCTURAL_CDC
sign-off methods covering three semantic families per slot: normal state
transition, mismatch containment, and reset-overlap accounting. The slots are
PARTIALLY_EQUIVALENT at routed-netlist level but their safety-relevant protocol,
CDC structure, stable-data lifetime, reset behavior, mismatch containment, and
retirement semantics are equivalent. Each slot must retain its own independently
resolved timing collections and routed-cone validation. The replacement uses a
6.000 ns absolute datapath settling cap supported by a 13.468 ns minimum
launch-to-use window and 7.468 ns gross protocol reserve. All nine candidate
timing checks passed. The replacement is SAFER_AND_MORE_SEMANTICALLY_CORRECT.
RTL_CHANGE_REQUIRED is NO. ACTIVE_XDC_CHANGE is
AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED. Preserve Groups 9 through 14 PASS,
keep G2B-HW BLOCKED, and set the next allowed engineering step to
G2B-LUT1-SIGNOFF-RECOVERY-4. Do not claim final timing sign-off, qualification,
release, bitstream availability, hardware readiness, DMA operation, or hardware
proof.

EVIDENCE_REPOSITORY:
lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT:
fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c

EVIDENCE_DIRECTORY:
v41-development-g2b-g15-17-release-slot-equivalence-audit

EXPECTED_AFFECTED_FILES:
project-current-state/ACTIVE_BASELINES.md
project-current-state/CHANGELOG.md
project-current-state/COMPATIBILITY_MATRIX.csv
project-current-state/CURRENT_ARCHITECTURE.md
project-current-state/CURRENT_INTERFACES.md
project-current-state/CURRENT_REQUIREMENTS.md
project-current-state/CURRENT_RESOURCE_STATE.md
project-current-state/CURRENT_STATUS.md
project-current-state/CURRENT_TRACKS.md
project-current-state/EVIDENCE_MAP.md
project-current-state/GOVERNANCE.md
project-current-state/OPEN_DECISIONS.md
project-current-state/PROJECT_STATE.json
project-current-state/README.md
project-current-state/SHA256_MANIFEST.txt
project-current-state/TRACK_STATUS.json

```

## Pre-mutation verification

`EXECUTING_ROLE = META_UPDATE_AGENT`
`PROJECT_STATE_REV_AT_START = 6`
`EXPECTED_PROJECT_STATE_REV = 6`
`REVISION_MATCH = YES`
`AUTHORIZATION_LITERAL_PRESENT = YES`
`OWNER_ARCHITECT_DECISION_VERIFIED = YES`
`EVIDENCE_COMMIT_VERIFIED = YES`
`EVIDENCE_DIRECTORY_VERIFIED = YES`
`MINIMAL_AFFECTED_FILES = 16` (exact paths in the preceding contract and expected-file ledger).

Local/remote main both resolve to `fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`. Both JSON revisions are 6.
SSOT manifest: 18/18 PASS. META-6 at
`0061a20ab735b4ff5dabdfe1f81ed9f1ba718dde`: immutable package bytes and
9/9 manifest entries verified; exact 16-file SSOT transaction verified.
META-6 established the unnumbered decision, one-revision increment,
one ordinary promotion commit, root `project-current-state` publication,
and post-commit executor remote verification pattern.
Authoritative G15–17 package: 58/58 manifest entries PASS; exact commit
`fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c`, directory `v41-development-g2b-g15-17-release-slot-equivalence-audit`, subtree `d3f336f5067e7e4814c65838da00aa50d4ab0425`.
All 9 candidate rows match raw timing properties and independently scoped
families; 6.000 ns cap and 13.468 - 6.000 = 7.468 ns basis verified.
Frozen governance semantics and schema do not change. GOVERNANCE.md changes
only its factual revision pointer, following META-6.

## Frozen-rule identities at start

- `GOVERNANCE.md`: SHA256 `E26B6208F2707B637995305EB8D2521609E97F5F6DC9CE4AD517AC1FF9BE2B02`.
- `UPDATE_POLICY.md`: SHA256 `F5927BDDABC47C68597FA745E10429DBB2972F0483F5D335291D09DD45B51497`.
- `META_UPDATE_TEMPLATE.md`: SHA256 `F7119369043E5C348AAA4B14BC4A3BBB80FB6AC6E0343BAA904909A2C22D0B27`.
- `STATE_SCHEMA.md`: SHA256 `6AE9C691748CE9FEF5186083DE50BF9F93EAF5E9AFEBDCB0156A7CDE650B60E3`.
