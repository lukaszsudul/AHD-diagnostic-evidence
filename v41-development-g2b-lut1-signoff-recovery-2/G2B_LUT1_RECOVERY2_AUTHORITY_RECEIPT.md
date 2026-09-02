# G2B-LUT1 Recovery 2 Authority Receipt

## SSOT revision 5

- Repository: `lukaszsudul/AHD-diagnostic-evidence`
- Evidence branch: `main`
- Revision-5 promotion commit: `bbdeb474ce9d7e5f0db3e8ca8afb5448eef8f314`
- SSOT directory: `project-current-state`
- `PROJECT_STATE_REV_AT_START = 5`
- Revision-5 SSOT manifest: `18 / 18` entries verified
- `SSOT_REV5_COMPATIBILITY = PASS`

The governed state was read before the source change and establishes:

- Group 9: `PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC = PROMOTED`; its global
  `report_bus_skew` is retired from required sign-off.
- Group 13: `SETTLING_PLUS_STRUCTURAL_CDC = PROMOTED`; its global
  `report_bus_skew` is retired from required sign-off.
- Groups 10–12: `PRESERVE_PREVIOUS_RESULTS`.
- Groups 14–17: `PENDING`.
- G2B-HW: `BLOCKED`.

## META-5

- Evidence directory: `v41-meta-project-state-rev5-group13-reset-return-signoff`
- Successful promotion commit: `bbdeb474ce9d7e5f0db3e8ca8afb5448eef8f314`
- Direct parent / accepted G13-A evidence commit:
  `10c7c2898d162af8e2262b3f99861c7d560c4557`
- Package manifest: `9 / 9` entries verified
- `META5 = VERIFIED`

META-5 was used exactly as the promotion authority and was not reinterpreted.
The successful META-4R2 procedural/evidence authority retained for Group 9 is
commit `27dcf152e862c6db88a365328b92c0fd250f04c2`.

## G13-A

- Evidence directory: `v41-development-g2b-g13a-reset-return-signoff-audit`
- Evidence commit: `10c7c2898d162af8e2262b3f99861c7d560c4557`
- Evidence-directory tree:
  `d4694977a5bfecfec8005d9cc0dd1c1c44f36f7f`
- Package manifest: `74 / 74` entries verified
- Candidate XDC: `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc`
- Candidate SHA-256:
  `E941A6F4A8D435B7496892C189CAA4A67DC5A8B17FE3CC9EACB2B9F18091D312`
- Candidate Git blob: `415317598b98cfeb8c01df41ab519cc5ee3ad5fa`
- `G13A_CANDIDATE = VERIFIED`

The only accepted semantic families are:

1. `RESET_ABANDONED_COUNT_STABLE_PAYLOAD`
2. `RESET_COMMIT_PHASE_COMPLETION_BARRIER`

No additional semantic family was introduced.

