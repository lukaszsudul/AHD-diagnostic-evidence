# AHD Project-State Update Policy

Policy version: `1`
Lifecycle status: `FROZEN`

## Authorization contract

Every update task must supply all fields defined in
`META_UPDATE_TEMPLATE.md`, including the literal `SSOT WRITE AUTHORIZED`, one
supported `UPDATE_TYPE`, the expected prior revision, the exact
Owner/Architect decision, an immutable accepted evidence source, and the
expected affected files.

If any field is missing, empty, malformed, unverifiable, or inconsistent, the
META Update Agent must stop without changing the SSOT.

## Exact update procedure

Every future update must perform these steps in this order:

1. Read `GOVERNANCE.md`.
2. Read `UPDATE_POLICY.md`.
3. Read current `PROJECT_STATE.json`.
4. Verify `EXPECTED_PROJECT_STATE_REV`.
5. Verify the explicit Owner/Architect acceptance, rejection, supersession, or blocker instruction.
6. Verify the accepted evidence commit and that the stated directory/files exist at it.
7. Determine the minimal affected SSOT files from the update category and actual decision scope.
8. Update only the affected current state; do not rewrite unrelated truth.
9. Increment `PROJECT_STATE_REV` by exactly 1 in every revision-bearing file.
10. Append a new entry to `CHANGELOG.md`.
11. Preserve every previous changelog entry byte-for-byte.
12. Update `EVIDENCE_MAP.md` with immutable provenance and the acceptance boundary.
13. Recompute `SHA256_MANIFEST.txt` and validate all entries.
14. Commit and push to `main` without force; a non-fast-forward result is a stop condition.
15. Perform remote read-back of remote HEAD and all affected files, then compare bytes or SHA-256 values with the intended commit.

No step may be skipped because an evidence package reports `PASS`.

## Preconditions and stop conditions

Before writing, verify:

- the executing role is `META_UPDATE_AGENT`;
- literal `SSOT WRITE AUTHORIZED` is present;
- the Owner/Architect decision is explicit;
- the evidence commit is a full 40-hex immutable Git commit;
- the evidence directory exists at that commit;
- actual revision equals the expected revision; and
- the proposed lifecycle label is in the normative enum.

Stop without SSOT changes on:

- `BLOCKED — MISSING_SSOT_WRITE_AUTHORIZATION`;
- `BLOCKED — MISSING_OWNER_ARCHITECT_DECISION`;
- `BLOCKED — EVIDENCE_UNVERIFIED`;
- `BLOCKED — SSOT_REVISION_CONFLICT`;
- `BLOCKED — UNSUPPORTED_UPDATE_TYPE`;
- `BLOCKED — NON_MINIMAL_CHANGE_SCOPE`;
- `BLOCKED — INVALID_STATUS_LABEL`;
- `BLOCKED — PUBLICATION_NON_FAST_FORWARD`; or
- `FAIL — REMOTE_READBACK_MISMATCH` after a push.

Never pull, merge, rebase, or auto-resolve a revision conflict. Obtain a new
task whose expected revision and Owner/Architect decision are based on the
current remote state.

## Initial-creation rule

META-0 created revision 1 with `EXPECTED_PROJECT_STATE_REV = ABSENT`. Absence
was verified on evidence `main` at
`f1258ba3ad2d6ab29c01260ce70fd23b59d8d4dd`. Initial creation does not imply a
historical revision 0. Future updates must use a positive integer expected
revision.

## Update categories and normal affected files

All updates normally touch the mandatory bookkeeping set:
`PROJECT_STATE.json`, the revision field in `TRACK_STATUS.json`,
`CHANGELOG.md`, `EVIDENCE_MAP.md`, and `SHA256_MANIFEST.txt`. Other files are
changed only when their state is affected.

| Update category | Normally affected domain files |
|---|---|
| `TRACK_GATE_ACCEPTANCE` | `CURRENT_STATUS.md`, `CURRENT_TRACKS.md`, `TRACK_STATUS.json`, relevant architecture/baseline document, plus mandatory bookkeeping |
| `BASELINE_CHANGE` | `ACTIVE_BASELINES.md`, affected architecture/interface/resource files, `COMPATIBILITY_MATRIX.csv`, plus mandatory bookkeeping |
| `INTERFACE_CHANGE` | `CURRENT_INTERFACES.md`, `COMPATIBILITY_MATRIX.csv`, plus mandatory bookkeeping |
| `REQUIREMENT_CHANGE` | `CURRENT_REQUIREMENTS.md`, impacted architecture/interfaces/compatibility rows, plus mandatory bookkeeping |
| `ARCHITECTURE_CHANGE` | `CURRENT_ARCHITECTURE.md`, impacted requirements/interfaces/tracks/compatibility rows, plus mandatory bookkeeping |
| `RESEARCH_PROMOTION` | `CURRENT_STATUS.md`, `CURRENT_TRACKS.md`, and only the affected baseline/architecture/resource files, plus mandatory bookkeeping |
| `SUPERSESSION` | Every document containing the superseded statement and affected compatibility rows, plus mandatory bookkeeping |
| `BLOCKER_CHANGE` | `CURRENT_STATUS.md`, `CURRENT_TRACKS.md`, `OPEN_DECISIONS.md`, plus mandatory bookkeeping |
| `META_GOVERNANCE_CHANGE` | affected `README.md`, `GOVERNANCE.md`, `UPDATE_POLICY.md`, `STATE_SCHEMA.md`, `META_UPDATE_TEMPLATE.md`, governance version, plus mandatory bookkeeping |

This matrix defines the normal maximum, not permission to create unrelated
churn. The decision and evidence determine the minimal actual subset.

## Applying a state decision

The META agent must quote or preserve the exact decision in its audit record.
It must distinguish:

- accepted project decision;
- evidence result and measurement;
- lifecycle label;
- implementation maturity;
- qualification state; and
- open limitations.

An acceptance of a gate does not automatically accept every candidate,
interface draft, research conclusion, or future requirement mentioned in its
evidence. Only the explicit decision scope changes.

## Revision and changelog transaction

Treat the SSOT update as one configuration transaction:

1. lock the verified prior revision logically through the expected-revision
   comparison;
2. edit the minimal state set;
3. set both JSON revisions to prior plus one;
4. append one changelog entry describing the decision, evidence, and files;
5. recompute the manifest excluding the manifest itself;
6. validate before commit; and
7. publish exactly one ordinary commit unless the task explicitly defines a
   different auditable atomic unit.

If validation fails, fix the proposed transaction before publication. Do not
publish a knowingly inconsistent partial revision.

## Manifest convention

`SHA256_MANIFEST.txt` contains SHA-256 hashes for the other 18 files in this
directory and excludes itself to avoid self-reference. Paths are relative to
`project-current-state/`, sorted lexically, and use the form:

```text
<64-uppercase-hex-digest>  <relative-path>
```

## Publication and remote read-back

- Publish only to `lukaszsudul/AHD-diagnostic-evidence`, branch `main`, unless
  a later explicit Owner/Architect decision changes the SSOT repository.
- Re-read remote `main` immediately before push; any divergence from the
  verified base is a revision conflict.
- Push normally and never use force.
- Verify remote `main` resolves to the new commit.
- Read back every affected file from that exact remote commit and compare its
  SHA-256 with the local intended file.
- Always read back at least `README.md`, `GOVERNANCE.md`, `UPDATE_POLICY.md`,
  `PROJECT_STATE.json`, `TRACK_STATUS.json`, `CURRENT_INTERFACES.md`,
  `META_UPDATE_TEMPLATE.md`, `STATE_SCHEMA.md`, and `CHANGELOG.md`.
- Record `PASS` only after all comparisons match.

## Staleness at completion

Record `PROJECT_STATE_REV_AT_END` and apply the governance staleness rule. For
the update's own expected increment, record `SSOT_STALENESS = NO_IMPACT` and
`SSOT_STALENESS_REASON = AUTHORIZED_SELF_UPDATE`. Any other intervening change
is `BLOCKED — SSOT_REVISION_CONFLICT` and requires new authorization.
