# AHD META Update Task Template

Use this template for every proposed modification to
`project-current-state/`. All fields are mandatory. A META Update Agent must
stop before writing if a field is absent, empty, malformed, unverifiable, or
inconsistent with the current SSOT.

```text
SSOT WRITE AUTHORIZED

UPDATE_TYPE:
<category>

EXPECTED_PROJECT_STATE_REV:
<n>

OWNER_ARCHITECT_DECISION:
<exact accepted decision>

EVIDENCE_REPOSITORY:
<repo>

EVIDENCE_COMMIT:
<SHA>

EVIDENCE_DIRECTORY:
<path>

EXPECTED_AFFECTED_FILES:
<list>
```

## Allowed update categories

- `TRACK_GATE_ACCEPTANCE`
- `BASELINE_CHANGE`
- `INTERFACE_CHANGE`
- `REQUIREMENT_CHANGE`
- `ARCHITECTURE_CHANGE`
- `RESEARCH_PROMOTION`
- `SUPERSESSION`
- `BLOCKER_CHANGE`
- `META_GOVERNANCE_CHANGE`

## Mandatory META preflight record

The META Update Agent must add the following to its local audit report before
any edit:

```text
EXECUTING_ROLE: META_UPDATE_AGENT
PROJECT_STATE_REV_AT_START: <actual>
EXPECTED_PROJECT_STATE_REV: <from task>
REVISION_MATCH: YES | NO
AUTHORIZATION_LITERAL_PRESENT: YES | NO
OWNER_ARCHITECT_DECISION_VERIFIED: YES | NO
EVIDENCE_COMMIT_VERIFIED: YES | NO
EVIDENCE_DIRECTORY_VERIFIED: YES | NO
MINIMAL_AFFECTED_FILES: <calculated list>
```

If `REVISION_MATCH = NO`, stop with:

```text
BLOCKED — SSOT_REVISION_CONFLICT
```

Do not pull, merge, rebase, or automatically combine the proposed update with
another state revision.

## Mandatory completion record

```text
PROJECT_STATE_REV_AT_END: <actual>
RESULTING_PROJECT_STATE_REV: <n+1>
ACTUAL_AFFECTED_FILES: <list>
CHANGELOG_APPENDED: YES | NO
MANIFEST_VERIFIED: YES | NO
PUBLICATION_COMMIT: <SHA or NONE>
PUSH_WITHOUT_FORCE: PASS | BLOCKED | FAIL
REMOTE_READBACK: PASS | FAIL | NOT_RUN
SSOT_STALENESS: NONE | NO_IMPACT | REVALIDATION_REQUIRED | TASK_INVALIDATED
SSOT_STALENESS_REASON: <reason>
```

The normal authorized self-increment may use `SSOT_STALENESS = NO_IMPACT`
with reason `AUTHORIZED_SELF_UPDATE`. Any unexpected concurrent increment is a
revision conflict.

## Decision boundary

The template conveys a decision; it does not authorize the META agent to make
one. An evidence result such as `PASS`, `THESIS_CONFIRMED`, or
`BUILD_COMPLETE` cannot substitute for `OWNER_ARCHITECT_DECISION` and cannot
promote `ACTIVE` or `PROVISIONAL` state to `ACCEPTED`.
