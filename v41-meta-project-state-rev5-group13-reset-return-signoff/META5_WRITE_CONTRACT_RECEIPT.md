# META-5 Write Contract Receipt

## Frozen-rule authority

- Contract source: `META-5_TASK_DIRECTIVE`.
- Executing role: `META_UPDATE_AGENT`.
- Current SSOT commit: `10c7c2898d162af8e2262b3f99861c7d560c4557`.
- Current remote `main`: `10c7c2898d162af8e2262b3f99861c7d560c4557`.
- `GOVERNANCE.md` SHA-256: `8AA0960BF846F497502EF1482BF0E63DB4C1CF4CA4D6CA3CAA2768A93A11E930`.
- `UPDATE_POLICY.md` SHA-256: `F5927BDDABC47C68597FA745E10429DBB2972F0483F5D335291D09DD45B51497`.
- `META_UPDATE_TEMPLATE.md` SHA-256: `F7119369043E5C348AAA4B14BC4A3BBB80FB6AC6E0343BAA904909A2C22D0B27`.
- `STATE_SCHEMA.md` SHA-256: `6AE9C691748CE9FEF5186083DE50BF9F93EAF5E9AFEBDCB0156A7CDE650B60E3`.
- Successful procedural precedent: META-4R2 evidence commit
  `27dcf152e862c6db88a365328b92c0fd250f04c2`.
- Precedent contract receipt SHA-256:
  `156017CCDA9758A488F0CC40A1BACC779B81100D4840297FD46D04B36F888369`.
- Frozen-contract verification: `VERIFIED`.

The current template defines the authorization as the standalone literal
`SSOT WRITE AUTHORIZED`; it does not define a separate `AUTHORIZATION:` input
field. The literal below is therefore preserved exactly in the supported
contract form.

## Complete validated contract

```text
SSOT WRITE AUTHORIZED

UPDATE_TYPE:
ARCHITECTURE_CHANGE

EXPECTED_PROJECT_STATE_REV:
4

OWNER_ARCHITECT_DECISION:
Promote the accepted G2B-G13-A Group-13 reset-return sign-off architecture into
project-current-state revision 5.
Retire the current required Group-13 global:
set_bus_skew 3.000
-from $g2b_reset_return_src
-to $g2b_reset_return_dst
for RESET_RETURN_SOURCE_TO_AXI.
Replace it with the accepted G13-A:
SETTLING_PLUS_STRUCTURAL_CDC
sign-off architecture.
The replacement must preserve the actual reset-return safety semantics:
- stable-data behavior,
- handshake correctness,
- commit-phase completion barrier,
- reset-return coherency,
- appropriate semantic-family settling checks,
- structural CDC proof.
The replacement has been validated as:
SAFER_AND_MORE_SEMANTICALLY_CORRECT
and:
RTL_CHANGE_REQUIRED = NO.
Active production XDC is NOT modified by META-5.
The candidate XDC is authorized for implementation only in the next governed
engineering sign-off-recovery task.
Groups 10–12 retain their previous authoritative PASS results.
Groups 14–17 remain pending and unchanged.
G2B-HW remains BLOCKED.

EVIDENCE_REPOSITORY:
lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT:
10c7c2898d162af8e2262b3f99861c7d560c4557

EVIDENCE_DIRECTORY:
v41-development-g2b-g13a-reset-return-signoff-audit

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

## Mandatory preflight record

```text
EXECUTING_ROLE: META_UPDATE_AGENT
PROJECT_STATE_REV_AT_START: 4
EXPECTED_PROJECT_STATE_REV: 4
REVISION_MATCH: YES
AUTHORIZATION_LITERAL_PRESENT: YES
OWNER_ARCHITECT_DECISION_VERIFIED: YES
EVIDENCE_COMMIT_VERIFIED: YES
EVIDENCE_DIRECTORY_VERIFIED: YES
MINIMAL_AFFECTED_FILES: 16 paths listed in META5_EXPECTED_AFFECTED_FILES.md
```

## Validation receipt

- `PROJECT_STATE.json` revision: `4`.
- `TRACK_STATUS.json` revision: `4`.
- SSOT manifest: `18/18 PASS`, `0 FAIL`.
- G13-A commit type: `commit`.
- G13-A directory tree:
  `d4694977a5bfecfec8005d9cc0dd1c1c44f36f7f`.
- G13-A package manifest: `74/74 PASS`, `0 FAIL`.
- G13-A engineering gate: `PASS`.
- Owner/Architect approval: `GRANTED` by `META-5_TASK_DIRECTIVE`.
- Update category support: `ARCHITECTURE_CHANGE` is an allowed frozen
  category.
- Affected-file calculation: `VERIFIED`; the 16-path set is the minimal
  propagation footprint for the revision pointer, Group-13 architecture,
  requirements, interface, track/recovery, compatibility, provenance,
  unnumbered decision, machine mirrors, changelog, and manifest transaction.
- Unsupported additions: none. `UPDATE_POLICY.md`, `META_UPDATE_TEMPLATE.md`,
  and `STATE_SCHEMA.md` remain unchanged because governance/schema semantics
  do not change.

All mandatory fields are present, non-empty, well-formed, verified, and
consistent. Partial SSOT mutation is not authorized.
