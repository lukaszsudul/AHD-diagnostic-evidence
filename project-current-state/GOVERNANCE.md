# AHD Project Current-State Governance

Governance version: `1`
Project-state revision governed: `3`
Lifecycle status: `FROZEN`

## 1. Purpose and scope

This document governs every file under `project-current-state/`. It freezes
who may decide project truth, who may mechanically update the SSOT, how
concurrent and stale work is handled, and which audit records are mandatory.
It applies to all G-track, R-track, L-track, Gate, Owner/Architect, and META
tasks.

## 2. Two independent truth layers

### EVIDENCE TRUTH

Evidence truth is what was executed, measured, built, or observed. A gate
report or evidence package may report `PASS`, `THESIS_CONFIRMED`,
`BUILD_COMPLETE`, a measurement, or another reproducible result.

### PROJECT TRUTH

Project truth is what the Owner/Architect has explicitly accepted as the
current state of the AHD project. This directory records project truth.

Evidence truth does not modify project truth automatically. In particular:

- execution `PASS` is not equivalent to `ACCEPTED`;
- `THESIS_CONFIRMED` is not a product-baseline promotion;
- `BUILD_COMPLETE` is not architecture acceptance; and
- an evidence publication is not authority to rewrite the SSOT.

An explicit Owner/Architect decision is required before any state promotion,
rejection, supersession, or blocker decision is applied here.

## 3. Normative lifecycle labels

Every important state statement uses one of these labels where practical:

- `ACCEPTED`
- `FROZEN`
- `ACTIVE`
- `PLANNED`
- `PROVISIONAL`
- `SUPERSEDED`
- `OPEN`
- `BLOCKED`
- `REJECTED`

No other value is permitted in a machine-readable field named `status` or
`lifecycle_status`. Evidence results and maturity terms must be stored in
separate fields. `ACTIVE` and evidence `PASS` must never be silently promoted
to `ACCEPTED`.

## 4. Frozen roles and authority

### 4.1 Gate Agent

Examples include a G-track agent, R-track agent, and L-track agent.

Permitted:

- read `project-current-state/`;
- read governance and update policy;
- read authoritative evidence;
- publish gate-specific evidence; and
- publish a gate execution report.

Forbidden:

- modify any file in `project-current-state/`;
- increment `PROJECT_STATE_REV`;
- declare a gate `ACCEPTED`;
- promote `ACTIVE` work into accepted architecture;
- reinterpret evidence `PASS` as project acceptance; or
- rewrite any historical changelog entry.

Gate Agents are SSOT read-only.

### 4.2 Owner / Architect

The Owner/Architect is the project decision authority. Only this role may
declare `ACCEPTED`, `REJECTED`, `SUPERSEDED`, or `BLOCKED` for a result or
proposed architectural change. The decision must be explicit and exact enough
for a mechanical update. The Owner/Architect need not edit Git directly.

### 4.3 META Update Agent

The META Update Agent is the only agent role authorized to write
`project-current-state/`.

It may write only if its task contains all of the following:

1. the literal authorization `SSOT WRITE AUTHORIZED`;
2. an explicit Owner/Architect decision;
3. the accepted evidence repository, immutable commit, and directory; and
4. `EXPECTED_PROJECT_STATE_REV`.

The META Update Agent does not make project decisions, infer acceptance,
reinterpret evidence into acceptance, or independently choose architecture.
Its work is mechanical configuration management: verify the decision and
evidence, verify the current revision, calculate the minimal affected files,
apply the update, increment the revision exactly once, append the changelog,
publish without force, and remotely verify the result.

META-0 is the sole initial-creation exception: its task explicitly authorizes
creation of revision 1 and requires the previous state to be absent.

## 5. Mandatory read-before-work rule

Every G-track, R-track, L-track, or META task must begin by reading, in order:

1. `README.md`
2. `GOVERNANCE.md`
3. `UPDATE_POLICY.md`
4. `PROJECT_STATE.json`
5. `TRACK_STATUS.json`
6. `CURRENT_INTERFACES.md`

The task report must record `PROJECT_STATE_REV_AT_START`. Failure to record it
invalidates the report's SSOT-conformance claim.

## 6. Revision rules

- `PROJECT_STATE_REV` is a positive integer representing accepted project
  state; it is not derived from Git history, timestamps, evidence count, or
  gate numbers.
- Revision 1 is the initial SSOT creation authorized by META-0.
- A later accepted update increments the prior revision by exactly 1.
- No update may skip, reuse, decrement, or renumber a revision.
- `PROJECT_STATE.json`, `TRACK_STATUS.json`, and the changelog must agree on the
  current revision.
- Historical revision entries are immutable. The changelog is append-only.
- Corrections to historical claims require a new revision and, when
  applicable, `SUPERSESSION`; history is never silently rewritten.

## 7. Stale-state detection

Before publishing its final result, every agent must read the current revision
again and record `PROJECT_STATE_REV_AT_END`.

- If start equals end: `SSOT_STALENESS = NONE`.
- If start differs from end: the agent must inspect every intervening SSOT
  change and classify the impact as exactly one of:
  - `NO_IMPACT`
  - `REVALIDATION_REQUIRED`
  - `TASK_INVALIDATED`

The impact classification and rationale must appear in the report. The agent
must not silently publish a result based on stale assumptions.

For an authorized META update, the expected self-created increment may be
classified `NO_IMPACT` with reason `AUTHORIZED_SELF_UPDATE`. Any additional or
unexpected revision change is a concurrency conflict, not a benign stale-state
event.

## 8. Optimistic concurrent-update protection

A META Update Agent must receive `EXPECTED_PROJECT_STATE_REV` and compare it
with the actual value before any write.

```text
if actual PROJECT_STATE_REV != EXPECTED_PROJECT_STATE_REV:
    BLOCKED — SSOT_REVISION_CONFLICT
```

Two independent state updates must not be merged automatically. The agent must
stop, preserve both proposals outside the SSOT if needed, and request a new
Owner/Architect decision based on the latest revision. For initial creation,
the expected prior state is `ABSENT`; an existing directory or revision is a
conflict.

## 9. Frozen acceptance workflow

```text
Gate execution
→ gate-specific evidence publication
→ Owner/Architect review
→ explicit acceptance/rejection decision
→ separate META Update task
→ SSOT update
→ PROJECT_STATE_REV + 1
→ CHANGELOG append
→ remote read-back
```

For example, `G2A execution = PASS` does not change project truth. Only an
explicit `Owner/Architect decision: G2A = ACCEPTED` authorizes a separate META
update.

## 10. Prohibited behavior

No agent may:

- write the SSOT without all mandatory authorization fields;
- treat evidence publication or execution success as acceptance;
- alter unrelated state as part of an authorized update;
- invent a missing decision, requirement, interface, baseline, timestamp, or
  evidence identity;
- use an unverified or mutable evidence reference as sole provenance;
- automatically merge concurrent SSOT proposals;
- force-push, rewrite published SSOT history, or amend an older state entry;
- remove or modify prior changelog entries; or
- claim remote verification without byte/hash read-back.

## 11. Audit requirements

Every META update audit record must retain:

- the literal write authorization;
- update category;
- exact Owner/Architect decision;
- expected and actual prior revisions;
- evidence repository, immutable commit, directory, and files inspected;
- minimal expected and actual affected-file lists;
- resulting revision;
- resulting SHA-256 manifest;
- local validation results;
- publication commit and push result; and
- remote HEAD and byte/hash read-back result.

Every gate report must retain start/end revisions and its staleness result.

## 12. Governance changes

This governance is itself project truth with status `FROZEN`. It may change
only through an authorized `META_GOVERNANCE_CHANGE`, an explicit
Owner/Architect decision, evidence or rationale sufficient to audit the
change, a governance-version update when semantics change, a single project
state revision increment, changelog append, non-force publication, and remote
read-back.
