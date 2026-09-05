# META-8A write contract receipt

EXECUTING_ROLE: META_UPDATE_AGENT

PROJECT_STATE_REV_AT_START: 7

EXPECTED_PROJECT_STATE_REV: 7

REVISION_MATCH: YES

AUTHORIZATION_LITERAL_PRESENT: YES

OWNER_ARCHITECT_DECISION_VERIFIED: YES

EVIDENCE_COMMIT_VERIFIED: YES

EVIDENCE_DIRECTORY_VERIFIED: YES

UPDATE_TYPE: TRACK_GATE_ACCEPTANCE — supported for accepting this offline gate and authorizing the next product gate without replacing R1i.

Mandatory files read in frozen order. Preflight verified source publication, local binaries, candidate identity, all 181 Recovery-4 manifest entries and the existing SSOT manifest. MINIMAL_AFFECTED_FILES: exact 16 paths in META8A_EXPECTED_AFFECTED_FILES.md.

## Exact supplied contract


Use the following contract exactly.

SSOT WRITE AUTHORIZED

UPDATE_TYPE:
TRACK_GATE_ACCEPTANCE

EXPECTED_PROJECT_STATE_REV:
7

OWNER_ARCHITECT_DECISION:
Accept the exact AHD v41 G2B-LUT1 Sign-Off Recovery 4 result as the completed
offline G2B-LUT1 PRODUCT qualification gate.

Promote the exact candidate identified by:

- source repository: lukaszsudul/FPGA_AHD
- source branch: integration/v41-g2b-onech-c2h
- source commit: 92e9b3d914134c044371779def1ee18eaaeda98a
- source tree: cf6bf82249c90782eab1978c68541ed9c0e6430b
- signed-off DCP SHA-256:
  95587CCEE934942C4745EC10EB6367D7C212DDB116B94A32C2B6D973AA29A175
- PRODUCT bitstream SHA-256:
  AF10C6108B5D99AD239E0F0008ACF7C790333CA1FDD69FD775394091CDEEF4B7

as:

OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE

accepted exclusively for the next controlled hardware gate:

G2B-HW0-PRODUCT

The exact future hardware-gate scope is:

G2B-HW0-PRODUCT — Exact Candidate Live-Path Bring-Up

It begins with:

1. candidate binary identity verification,
2. runtime identity verification,
3. FPGA SRAM programming of the exact candidate,
4. DONE and PCIe endpoint verification,
5. read-only MMIO/ABI baseline verification,
6. one complete 4096-byte C2H record from the PRODUCT live AHD path on the
   fixed supported input,
7. bounded finite capture,
8. continuous one-channel AHD capture only after earlier gates pass.

This authorization does not permit a release claim, persistent Flash update,
four-input auto-scan claim, synthetic-generator claim, 288 MB/s hardware claim,
V4L2 claim, or hardware qualification claim.

G2B-LUT1 shall become ACCEPTED with maturity
OFFLINE_QUALIFIED_G2B_PRODUCT_CANDIDATE.

The product track shall record:

LAST_ACCEPTED_GATE =
G2B-LUT1-SIGNOFF-RECOVERY-4

NEXT_ALLOWED_ENGINEERING_STEP =
G2B-HW0-PRODUCT

G2B-HW shall move from the previous no-candidate blocker to a schema-valid
PLANNED state with readiness:

AUTHORIZED_FOR_SEPARATE_CONTROLLED_EXECUTION

G2B-HW remains NOT_PROVEN and not ACCEPTED.

The R1i qualified PoC baseline remains ACCEPTED and FROZEN. The new G2B
candidate does not replace R1i as a hardware-qualified baseline.

release/v41.0.0 remains NOT_CREATED and NOT_AUTHORIZED.

EVIDENCE_REPOSITORY:
lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT:
6843d582fd367fbc0edc0b1d55a9617162c489b0

EVIDENCE_DIRECTORY:
v41-development-g2b-lut1-signoff-recovery-4

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

