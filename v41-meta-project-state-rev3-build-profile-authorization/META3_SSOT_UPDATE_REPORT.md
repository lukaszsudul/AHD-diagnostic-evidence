# AHD v41 META-3 Build Profile Authorization

## Executive result

This report records the authorized promotion of the accepted G2B-LUT0
resource architecture into `project-current-state/` revision 3. The promotion
authorizes reversible `PRODUCT` and `RESEARCH_DIAGNOSTIC` profiles and places
the R-track on `HOLD`. It does not implement either profile or promote an
offline-qualified G2B, bitstream, hardware, or V4L2 result.

| Field | Result |
|---|---|
| Engineering gate | `PASS` |
| Evidence publication | `PASS` |
| Overall result | `PASS` |
| `PROJECT_STATE_REV_AT_START` | `2` |
| `PROJECT_STATE_REV_AT_END` | `3` |
| SSOT staleness | `NO_IMPACT` — `AUTHORIZED_SELF_UPDATE` |

## Mandatory META preflight

The following preflight was completed before the first SSOT edit:

```text
EXECUTING_ROLE: META_UPDATE_AGENT
UPDATE_TYPE: ARCHITECTURE_CHANGE + REQUIREMENT_CHANGE + BLOCKER_CHANGE
PROJECT_STATE_REV_AT_START: 2
EXPECTED_PROJECT_STATE_REV: 2
REVISION_MATCH: YES
AUTHORIZATION_LITERAL_PRESENT: YES — explicit Owner/Architect META-3 execution and publication directive
OWNER_ARCHITECT_DECISION_VERIFIED: YES
EVIDENCE_COMMIT_VERIFIED: YES
EVIDENCE_DIRECTORY_VERIFIED: YES
SOURCE_REPOSITORY_BASELINE_RECORDED: YES
```

Local `main`, local `origin/main`, and remote `origin/main` all resolved to
`a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` at the revision guard. The
working tree was clean and both machine-readable SSOT documents reported
revision 2.

## Accepted decision and immutable input

Owner/Architect decision applied by this transaction:

> Keep the R-track on HOLD, preserve its work for later resumption, and
> authorize PRODUCT and RESEARCH_DIAGNOSTIC build profiles. PRODUCT may omit
> G2B-LUT0-classified research-only instrumentation while retaining complete
> qualified R1i behavior and all frozen product interfaces.

| Evidence field | Verified value |
|---|---|
| Repository | `lukaszsudul/AHD-diagnostic-evidence` |
| Directory | `v41-development-g2b-lut0-resource-attribution` |
| Evidence commit | `a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` |
| Evidence subtree | `05fd1075e0a8deb5082accccb0a88a3f18dfca54` |
| Engineering result | `PASS` |
| Main review | `V41_G2B_LUT0_ARCHITECTURE_REVIEW.md` |
| Instrumentation inventory | `G2B_LUT0_RTRACK_INSTRUMENTATION_INVENTORY.md` |
| Recommended plan | `G2B_LUT0_RECOMMENDED_PLAN.md` |
| Resource targets | `G2B_LUT0_RESOURCE_TARGETS.md` |
| Build-profile proposal | `G2B_LUT0_BUILD_PROFILE_PROPOSAL.md` |

## Project truth promoted

| Domain | Revision-3 truth |
|---|---|
| G2B-PRE | `ACCEPTED` (unchanged) |
| G2B-LUT0 | `ACCEPTED` |
| G2B-IMPL | lifecycle `BLOCKED`; `BLOCKED_RESOURCE_HEADROOM` |
| G2B-LUT1 | lifecycle `PLANNED`; readiness `READY` |
| PRODUCT | `AUTHORIZED_NOT_IMPLEMENTED` |
| RESEARCH_DIAGNOSTIC | `AUTHORIZED_NOT_IMPLEMENTED` |
| R-track | `HOLD`, not closed/cancelled/superseded |
| PRODUCT LUT hard gate | `<= 90%` routed |
| Preferred PRODUCT LUT target | `80–85%` routed |
| Frozen ABI | `AHD_C2H_TRANSPORT_ABI_V1`, unchanged |
| Frozen MMIO | `0x3800..0x3BFF`, unchanged |
| G2B hardware | `NOT_PROVEN` |

The lifecycle schema is preserved. Values such as `AUTHORIZED_NOT_IMPLEMENTED`,
`HOLD`, and `BLOCKED_RESOURCE_HEADROOM` are stored in authorization, state,
readiness, implementation, or qualification fields rather than invalid JSON
`status` fields.

## Resource evidence and qualification boundary

| Quantity | G2B-LUT0 evidence |
|---|---:|
| G2A routed LUT | `18,178 / 20,800` |
| Blocked G2B post-opt LUT | `21,412 / 20,800` (`102.942%`) |
| Research/diagnostic planning estimate | approximately `3,900 LUT`, range `3,500–4,300` |
| Estimated PRODUCT Plan-B point | approximately `17,512 LUT` (`84.192%`) |

The 17,512 / 84.192% value is an estimate, not qualification evidence. The
PRODUCT hard gate is not marked achieved. Actual post-route utilization and
timing require G2B-LUT1/G2B-IMPL requalification.

## Frozen cross-profile invariants

1. PRODUCT and RESEARCH_DIAGNOSTIC have identical qualified R1i functional
   behavior.
2. Research instrumentation is never required for functional correctness.
3. Profile selection must not change NVP initialization, I2C protocol
   behavior, video capture semantics, C2H ABI, MMIO contract, or XDMA
   configuration.
4. PRODUCT retains the qualified R1i correction, physical SCL/ACK behavior,
   synchronizers/readiness/recovery, minimum production NVP/video
   observability, identity, XDMA Gen2, G2B transport/status/counters/reset
   epoch/capabilities, and frozen ABI/MMIO.
5. RESEARCH_DIAGNOSTIC is PRODUCT behavior plus reproducible R-track
   observability needed to resume R2/R3.
6. Research-only instrumentation excluded from PRODUCT remains recoverable
   through RESEARCH_DIAGNOSTIC; Git archaeology alone is not the preferred
   recovery method when a practical profile implementation exists.

G2B-LUT1 may use generics, Tcl profile selection/defines, generate blocks, or
source-set selection, but the implementation agent must select the least
invasive reversible method supported by the repository. META-3 makes no source
implementation choice.

## Explicit non-promotions

- no source profile implementation exists;
- no PRODUCT LUT target is proven or achieved;
- no accepted offline-qualified G2B implementation exists;
- no G2B bitstream exists;
- no G2B hardware result exists;
- G2B hardware remains `NOT_PROVEN`;
- V4L2 remains `NOT_IMPLEMENTED`;
- R2/R3 scientific closure remains open; and
- no research evidence is deleted.

## SSOT files changed

The calculated and actual revision-3 SSOT scope is 16 files:

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

`GOVERNANCE.md` changes only its factual governed-revision pointer. Governance
version, policy semantics, update policy, schema, and template are unchanged.

## Source and execution protection

Source baseline recorded before work:

| Field | Value |
|---|---|
| Source path | `C:\FPGA\FPGA_AHD` |
| Source branch | `main` |
| Source HEAD | `be94f88ee8d179f12928ab791bdae27c22cd1762` |
| Source tree | `e128ff47a5e21e8131971f5e5caa7657e2eccc7f` |
| Source worktree status | clean |
| Full non-Git content aggregate | `65073bf871cc0edf8dbc999c0ac12b7ce63f0a8419b46407d98c82b274bd46b1` |

```text
FPGA_AHD modified: NO
Branch movement: NO
FPGA source/RTL/XCI/XDC modified: NO
R-track source branch modified: NO
Research evidence deleted: NO
Vivado executed: NO
DUT or hardware accessed: NO
FPGA programmed: NO
DMA run: NO
G2B-LUT1 started: NO
```

## Validation and publication receipt

| Check | Result |
|---|---|
| JSON parse and lifecycle-status validation | `PASS` |
| CSV parse and compatibility boundary | `PASS` |
| Revision and evidence-reference consistency | `PASS` |
| ABI/MMIO unchanged | `PASS` |
| No achieved-LUT/bitstream/hardware/V4L2 overclaim | `PASS` |
| SSOT SHA-256 manifest | `PASS`, 18/18 |
| Revision-2 changelog prefix | `PASS`, 5,845 bytes, SHA-256 `2243DC023A7B75858C75B9AEEA98096ABE8CA1639BE65D52FDDBEB3B5AE0F16D` |
| Source repository final protection check | `PASS`; clean at original HEAD/tree/content aggregate |
| Publication payload commit | `fc03d01c3ac37ca4ff40694a9e21d5ffdcc589ac` |
| Push without force | `PASS` |
| Remote HEAD and affected-file read-back | `PASS`; 24/24 paths matched by SHA-256 |

## Completion record

```text
PROJECT_STATE_REV_AT_END: 3
RESULTING_PROJECT_STATE_REV: 3
ACTUAL_AFFECTED_FILES: 16 SSOT files listed above
CHANGELOG_APPENDED: YES
MANIFEST_VERIFIED: YES
PUBLICATION_COMMIT: fc03d01c3ac37ca4ff40694a9e21d5ffdcc589ac
PUSH_WITHOUT_FORCE: PASS
REMOTE_READBACK: PASS
SSOT_STALENESS: NO_IMPACT
SSOT_STALENESS_REASON: AUTHORIZED_SELF_UPDATE
```

The ordinary non-force payload push advanced remote `main` from
`a70c55eca5f0c0ad349143ad93ab87eb80d11ac4` to
`fc03d01c3ac37ca4ff40694a9e21d5ffdcc589ac`. A fresh remote clone resolved to
that exact commit. A commit archive containing all 19 SSOT files and all five
META-3 package files was read back, and all 24 remote files matched their
local intended bytes by SHA-256. The final evidence-only receipt commit
contains this completed report and does not modify `project-current-state/`.
