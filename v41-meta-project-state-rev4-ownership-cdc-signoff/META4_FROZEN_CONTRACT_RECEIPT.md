# META-4R2 Frozen Contract Receipt

## Header identity

- Source: `v41-meta-project-state-rev4-write-contract-preflight/META4P_REISSUE_HEADER.txt`
- SHA-256: `D7456D989F0D879B2E1FD8777876F5AE786947D789CE1D480CA720316AC7342B`
- META-4P publication commit: `24be8a8c6eb227c548db130009ca495bfb472802`
- Read result: `VERIFIED`
- Verbatim use: `YES`

## Exact frozen fields

```text
SSOT WRITE AUTHORIZED

UPDATE_TYPE:
ARCHITECTURE_CHANGE

EXPECTED_PROJECT_STATE_REV:
3

OWNER_ARCHITECT_DECISION:
Promote the accepted G2B-BS3 ownership CDC sign-off architecture into
project-current-state revision 4. Retire GLOBAL_SET_BUS_SKEW_3NS and make
PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC the required Group-9 sign-off method.
The replacement consists of the two-stage request synchronizer, two-stage
acknowledgement synchronizer, held 58-bit stable-data payload, source hold
until acknowledgement, reset/epoch coherency, and 6.000 ns absolute settling
checks for the slot, generation, and epoch payload families. Its basis is the
13.468 ns minimum launch-to-use margin and 7.468 ns gross reserve, and its
equivalence is SAFER_AND_MORE_SEMANTICALLY_CORRECT. RTL_CHANGE_REQUIRED is NO.
ACTIVE_XDC_CHANGE is AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED, using
G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc in a later governed source task.
Set G2B-LUT1 readiness to READY_FOR_SIGNOFF_RECOVERY and its next gate to
G2B-LUT1-SIGNOFF-RECOVERY. Keep G2B-HW BLOCKED, keep Groups 10-17 unchanged,
and do not claim PASS, qualification, release, hardware readiness, bitstream,
or hardware proof. Record the named, unnumbered Group-9
OWNERSHIP_AXI_TO_SOURCE sign-off-methodology decision as RESOLVED with decision
REPLACE_GLOBAL_BUS_SKEW_WITH_PER_FAMILY_SETTLING_CHECKS; do not invent an OD
number and do not remove or alter any currently registered OD-* open decision.

EVIDENCE_REPOSITORY:
lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT:
10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae

EVIDENCE_DIRECTORY:
v41-development-g2b-bs3-ownership-mailbox-settling-proof

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

The block above is reproduced verbatim from the authoritative preflight header;
no field name or literal was normalized or substituted.
