# AHD v41 META-2 SSOT Update after G2B-PRE Acceptance

## Executive result

This report records the authorized promotion of the accepted G2B-PRE
architecture-contract freeze into `project-current-state/` revision 2. The
promotion freezes the implementation input contracts; it does not promote an
implementation or hardware result.

| Field | Result |
|---|---|
| Engineering gate | `PASS` |
| Evidence publication | `PASS` |
| Overall result | `PASS` |
| `PROJECT_STATE_REV_AT_START` | `1` |
| `PROJECT_STATE_REV_AT_END` | `2` |
| SSOT staleness | `NO_IMPACT` — `AUTHORIZED_SELF_UPDATE` |

## Mandatory META preflight

The following preflight was completed before the first SSOT edit:

```text
EXECUTING_ROLE: META_UPDATE_AGENT
UPDATE_TYPE: INTERFACE_CHANGE
PROJECT_STATE_REV_AT_START: 1
EXPECTED_PROJECT_STATE_REV: 1
REVISION_MATCH: YES
AUTHORIZATION_LITERAL_PRESENT: YES
OWNER_ARCHITECT_DECISION_VERIFIED: YES
EVIDENCE_COMMIT_VERIFIED: YES
EVIDENCE_DIRECTORY_VERIFIED: YES
SOURCE_REPOSITORY_BASELINE_RECORDED: YES
```

Authorization basis:

- the Owner/Architect task explicitly states that G2B-PRE evidence is `PASS`,
  Owner/Architect acceptance is `YES`, and the META update is explicitly
  requested;
- the task incorporates
  `G2B_PRE_SSOT_UPDATE_REQUIREMENTS.md`, whose required META transaction
  contains the literal `SSOT WRITE AUTHORIZED` and identifies update type
  `INTERFACE_CHANGE`; and
- the supplied expected revision, evidence repository, immutable commit,
  directory, decision scope, and affected current-state domains were all
  present and independently verified.

Remote `origin/main` and local `main` both resolved to
`e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` at the revision guard. Both
`project-current-state/PROJECT_STATE.json` instances reported revision 1.

## Accepted decision and immutable input

Owner/Architect decision applied by this transaction:

> Accept G2B-PRE; freeze `AHD_C2H_TRANSPORT_ABI_V1` version 1 for G2B,
> freeze the G2B MMIO contract at `0x3800..0x3BFF`, and freeze the Linux
> consumer contract as a transport input, without claiming G2B, DMA,
> hardware, throughput, or V4L2 implementation or qualification.

| Evidence field | Verified value |
|---|---|
| Repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Directory | `v41-development-g2b-pre-c2h-abi-mmio-freeze` |
| Accepted evidence commit | `e8ab1012d855cfbe68f61a6d0bccd92dc6d6547e` |
| Payload commit | `9fdcca4e3a40b931f07db01ad404b4a3cfc24b10` |
| Evidence subtree | `762b8aba83653969d52ec991cd71ed8173268286` |
| Engineering result | `PASS` |
| ABI consistency | `PASS` (`63/63`) |
| Linux consumer contract | `PASS` |

## Project truth promoted

| Domain | Revision-2 truth |
|---|---|
| G2B-PRE | `ACCEPTED`, architecture-contract-freeze scope only |
| Transport ABI lifecycle | `FROZEN` |
| Transport ABI semantic state | `FROZEN_FOR_G2B` |
| ABI identity | `AHD_C2H_TRANSPORT_ABI_V1`, numeric version `1` |
| Record geometry | `64 + 3840 + 192 = 4096` bytes |
| Payload | one complete validated 1920-pixel UYVY 4:2:2 active line |
| AXI4-Stream | 64 bits, 512 beats, `TKEEP=0xFF`, final-beat-only `TLAST` |
| G2B MMIO lifecycle | `FROZEN` |
| G2B MMIO range | `0x3800..0x3BFF` |
| Protected compatibility | all existing behavior through `0x37FF` |
| Linux consumer contract | lifecycle `FROZEN`; `FROZEN_INPUT_CONTRACT` / transport input only |
| G2B implementation readiness | `READY` from a contract-input perspective |

Non-lifecycle states are deliberately encoded in fields other than a JSON key
named exactly `status`. Thus `status` remains schema-valid (`FROZEN` or
`PLANNED`), while `contract_state=FROZEN_INPUT_CONTRACT`,
`implementation_state=NOT_IMPLEMENTED`, and
`qualification_state=NOT_PROVEN` carry the exact requested meanings.

## Explicit non-promotions

The transaction preserves all of the following:

- one-channel C2H RTL: `NOT_IMPLEMENTED`;
- one-channel hardware DMA: `NOT_PROVEN`;
- two-channel DMA: `NOT_PROVEN`;
- sustained AHD application payload `>= 288 MB/s`: requirement only,
  `NOT_PROVEN`;
- G2B runtime Gen2 negotiation: `NOT_PROVEN`;
- G2B bitstream and G2B host capture: `NOT_IMPLEMENTED`;
- V4L2: `NOT_IMPLEMENTED`, and its architecture is not frozen by this task;
- DMABUF: `NOT_IMPLEMENTED`;
- stable multi-card Linux policy: not frozen or implemented; and
- R-track state: unchanged from revision 1, with no R2 finding promoted.

The existing v40B `PROTOCOL=0x0000400B` identity is preserved until a future
accepted implementing build actually advertises the new transport. ABI and
MMIO contract capability must not be confused with implemented-this-build or
runtime qualification.

## SSOT files changed

The calculated and actual revision-2 SSOT scope is 16 files:

1. `project-current-state/ACTIVE_BASELINES.md`
2. `project-current-state/CHANGELOG.md`
3. `project-current-state/COMPATIBILITY_MATRIX.csv`
4. `project-current-state/CURRENT_ARCHITECTURE.md`
5. `project-current-state/CURRENT_INTERFACES.md`
6. `project-current-state/CURRENT_REQUIREMENTS.md`
7. `project-current-state/CURRENT_RESOURCE_STATE.md`
8. `project-current-state/CURRENT_STATUS.md`
9. `project-current-state/CURRENT_TRACKS.md`
10. `project-current-state/EVIDENCE_MAP.md`
11. `project-current-state/GOVERNANCE.md`
12. `project-current-state/OPEN_DECISIONS.md`
13. `project-current-state/PROJECT_STATE.json`
14. `project-current-state/README.md`
15. `project-current-state/SHA256_MANIFEST.txt`
16. `project-current-state/TRACK_STATUS.json`

The accepted G2B-PRE requirements named the nine semantic/bookkeeping files.
The seven additional current-state documents contain live revision pointers
or current ABI/track summaries; changing them is required by the later
Owner/Architect task and the rule to increment every revision-bearing file.
`GOVERNANCE.md` changes only its factual governed-revision pointer. Governance
version and semantics, update policy, schema, and template remain unchanged.

## Decision closure

Exactly one numbered current SSOT decision is resolved: `OD-06`, Final C2H
transport ABI. The evidence decision log freezes 24 technical decisions,
grouped into 15 closure-matrix rows under that umbrella. `OD-01..OD-05` and
`OD-07..OD-10` remain open. In particular, transport UYVY byte semantics do
not decide the final V4L2 pixel format, and transport sequences do not decide
the later timestamp architecture.

## Source and execution protection

Source baseline recorded before work:

| Field | Value |
|---|---|
| Source path | `C:\FPGA\FPGA_AHD` |
| Source branch | `main` |
| Source HEAD | `be94f88ee8d179f12928ab791bdae27c22cd1762` |
| Source worktree status | clean |

Operation ledger:

```text
FPGA source modified: NO
RTL/XCI/XDC modified: NO
G2B source branch modified: NO
R-track modified: NO
Vivado executed: NO
DUT or hardware accessed: NO
FPGA programmed: NO
DMA run: NO
G2B implementation started: NO
```

## Validation and publication receipt

| Check | Result |
|---|---|
| JSON parse and schema-status validation | `PASS` |
| CSV parse and compatibility boundary | `PASS` |
| Record geometry and AXI geometry | `PASS` |
| ABI/MMIO/evidence reference consistency | `PASS` |
| No stale current ABI provisional claim | `PASS`; historical revision-1 changelog text is intentionally retained |
| Non-implementation/non-qualification assertions | `PASS` |
| SSOT SHA-256 manifest | `PASS`, 18/18 |
| Revision-1 changelog prefix preserved byte-for-byte | `PASS`, 2,168 bytes, SHA-256 `72F08C4661E150F46DF252C6D57F192769820ADDCC0D2B8471680C2A01287607` |
| Source repository final protection check | `PASS`; clean at original HEAD |
| Publication payload commit | `7225dae0464a41aaed8ae007f0cc0cd6b0c2e48b` |
| Push without force | `PASS` |
| Remote HEAD read-back | `PASS`; remote `main` resolved to the payload commit |
| Remote affected-file byte/hash read-back | `PASS`, 24/24 paths matched by SHA-256 |

The publication receipt is completed after the non-force payload push and
remote byte/hash read-back. A final evidence-only receipt commit may record
the payload SHA and PASS result without rewriting the revision-2 SSOT.

## Completion record

```text
PROJECT_STATE_REV_AT_END: 2
RESULTING_PROJECT_STATE_REV: 2
ACTUAL_AFFECTED_FILES: 16 SSOT files listed above
CHANGELOG_APPENDED: YES
MANIFEST_VERIFIED: YES
PUBLICATION_COMMIT: 7225dae0464a41aaed8ae007f0cc0cd6b0c2e48b
PUSH_WITHOUT_FORCE: PASS
REMOTE_READBACK: PASS
SSOT_STALENESS: NO_IMPACT
SSOT_STALENESS_REASON: AUTHORIZED_SELF_UPDATE
```

Local validation replayed 75 META-2 SSOT invariants with zero failures and
the accepted package validator with 63/63 checks passing. `git diff --check`
also passed. The ordinary non-force payload push completed, remote `main`
resolved to `7225dae0464a41aaed8ae007f0cc0cd6b0c2e48b`, and all 24 required
remote paths matched their local intended bytes by SHA-256. The final
evidence-only receipt commit is the remote HEAD containing this completed
report; it does not modify `project-current-state/`.
