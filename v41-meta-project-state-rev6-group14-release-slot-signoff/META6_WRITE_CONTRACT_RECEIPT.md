# META-6 Write Contract Receipt

## Frozen-rule authority

- Contract source: `META-6_TASK_DIRECTIVE`.
- Executing role: `META_UPDATE_AGENT`.
- Current SSOT commit: `9e91315968453e859006077191cd5fc711fc6b96`.
- Current remote `main`: `9e91315968453e859006077191cd5fc711fc6b96`.
- `GOVERNANCE.md` SHA-256: `4C46A89982F0B2F1C2096AC9E4ACD0585C18AAE9DAD65F19E36518F349794A3E`.
- `UPDATE_POLICY.md` SHA-256: `F5927BDDABC47C68597FA745E10429DBB2972F0483F5D335291D09DD45B51497`.
- `META_UPDATE_TEMPLATE.md` SHA-256: `F7119369043E5C348AAA4B14BC4A3BBB80FB6AC6E0343BAA904909A2C22D0B27`.
- `STATE_SCHEMA.md` SHA-256: `6AE9C691748CE9FEF5186083DE50BF9F93EAF5E9AFEBDCB0156A7CDE650B60E3`.
- Successful procedural precedents: META-4R2 commit
  `27dcf152e862c6db88a365328b92c0fd250f04c2` and META-5 commit
  `bbdeb474ce9d7e5f0db3e8ca8afb5448eef8f314`.
- META-5 contract receipt SHA-256:
  `D6C0DB8DCEC4B7418A302D43D37F64CD09DA0F557D79B4EAB8C6FF3C81FDC933`.
- Frozen-contract verification: `VERIFIED`.

The frozen template defines authorization as the standalone literal
`SSOT WRITE AUTHORIZED`; it does not define a separate `AUTHORIZATION:` input
field. The literal below is preserved exactly in the supported contract form.

## Complete validated contract

```text
SSOT WRITE AUTHORIZED

UPDATE_TYPE:
ARCHITECTURE_CHANGE

EXPECTED_PROJECT_STATE_REV:
5

OWNER_ARCHITECT_DECISION:
Promote the accepted G2B-G14-A Group-14 release-slot sign-off architecture into
project-current-state revision 6.
Retire the current global Group-14:
set_bus_skew 3.000
-from $g2b_release0_payload_src
-to $g2b_release_payload_dst
for RELEASE_SLOT_0_AXI_TO_SOURCE.
Replace it with the accepted G14-A:
SETTLING_PLUS_STRUCTURAL_CDC
sign-off architecture.
The replacement is:
SAFER_AND_MORE_SEMANTICALLY_CORRECT
and:
RTL_CHANGE_REQUIRED = NO.
Active production XDC is NOT modified by META-6.
The candidate XDC is authorized for implementation only in the next governed
engineering sign-off-recovery task.
Group 9 retains its promoted authoritative PASS result.
Groups 10–12 retain their previous authoritative PASS results.
Group 13 retains its promoted authoritative PASS result.
Groups 15–17 remain pending and unchanged.
G2B-LUT1 remains READY_FOR_SIGNOFF_RECOVERY, with next allowed engineering
step G2B-LUT1-SIGNOFF-RECOVERY-3.
G2B-HW remains BLOCKED.

EVIDENCE_REPOSITORY:
lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT:
9e91315968453e859006077191cd5fc711fc6b96

EVIDENCE_DIRECTORY:
v41-development-g2b-g14a-release-slot0-signoff-audit

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
PROJECT_STATE_REV_AT_START: 5
EXPECTED_PROJECT_STATE_REV: 5
REVISION_MATCH: YES
AUTHORIZATION_LITERAL_PRESENT: YES
OWNER_ARCHITECT_DECISION_VERIFIED: YES
EVIDENCE_COMMIT_VERIFIED: YES
EVIDENCE_DIRECTORY_VERIFIED: YES
MINIMAL_AFFECTED_FILES: 16 paths listed in META6_EXPECTED_AFFECTED_FILES.md
```

## Validation receipt

- `PROJECT_STATE.json` revision: `5`.
- `TRACK_STATUS.json` revision: `5`.
- Local `main`, `origin/main`, and remote `main` at preflight:
  `9e91315968453e859006077191cd5fc711fc6b96`.
- SSOT manifest: `18/18 PASS`, `0 FAIL`.
- G14-A commit type: `commit`.
- G14-A commit tree: `95961d96ca164d4b7838454df4075f1287e7a19f`.
- G14-A directory tree: `ae0c1472b90bf4cecc2df8feebe192b35b8355be`.
- G14-A package manifest: `65/65 PASS`, `0 FAIL`.
- G14-A engineering gate: `PASS`.
- Candidate XDC SHA-256:
  `094F7182116FC2A2C68479B8BDB6A6C2327F14DA6ABFEB244EC7F26D7BE2809A`.
- Owner/Architect approval: `GRANTED` by `META-6_TASK_DIRECTIVE`.
- Update category support: `ARCHITECTURE_CHANGE` is an allowed frozen
  category.
- META-5 precedent: `VERIFIED`; the successful Group-13 promotion used the
  same 16-path architecture-change propagation footprint.
- META-4R2 precedent: `VERIFIED`; the successful Group-9 promotion used the
  same named unnumbered governed-decision mechanism.
- Affected-file calculation: `VERIFIED`; the 16-path set is the minimal
  propagation footprint for the revision pointer, Group-14 architecture,
  requirements, interface, track/recovery, compatibility, provenance,
  unnumbered decision, machine mirrors, changelog, and manifest transaction.
- Unsupported additions: none. `UPDATE_POLICY.md`, `META_UPDATE_TEMPLATE.md`,
  and `STATE_SCHEMA.md` remain unchanged because governance/schema semantics
  do not change.

All mandatory fields are present, non-empty, well-formed, verified, and
consistent. Partial SSOT mutation is not authorized.
