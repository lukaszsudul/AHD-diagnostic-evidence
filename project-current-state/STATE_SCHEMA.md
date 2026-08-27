# AHD Current-State Machine Schema

Schema version: `1`
Applies to: `PROJECT_STATE.json`, `TRACK_STATUS.json`, and machine-readable
fields mirrored by the Markdown/CSV SSOT.

## Normative primitives

| Field | Type | Meaning |
|---|---|---|
| `project` | string | Stable project identifier; revision 1 uses `AHD_v41` |
| `project_state_revision` | positive integer | Accepted state revision, incremented exactly once per authorized update and never derived from Git |
| `state_type` | string | State collection meaning; main SSOT uses `CURRENT_ACCEPTED_STATE` |
| `governance_version` | positive integer | Semantic version of the governance model |
| `last_update` | ISO-8601 full date or timestamp | Date/time at which the state revision was mechanically applied |
| `accepted_by_role` | string or null | Decision role; accepted project truth uses `OWNER_ARCHITECT`; null is allowed only for non-accepted/planned context |
| `source_evidence_commit` | 40-character lowercase Git SHA or null | Immutable evidence snapshot/package commit; null only when no evidence package exists and `decision_source` is mandatory |

`project_state_revision` must match in both JSON files. Duplicate facts across
JSON, Markdown, and CSV must also match.

## Lifecycle status enum

Every key named `status` or `lifecycle_status` must contain exactly one of:

```text
ACCEPTED
FROZEN
ACTIVE
PLANNED
PROVISIONAL
SUPERSEDED
OPEN
BLOCKED
REJECTED
```

Values such as `PASS`, `THESIS_CONFIRMED`, `STRONG_PASS`, `PROVEN`,
`IMPLEMENTED_UNQUALIFIED`, `NOT_YET_QUALIFIED`, `IN_PROGRESS`, and
`INCONCLUSIVE` are evidence, maturity, progress, qualification, or scientific
classifications. They must not appear as lifecycle status values.

## Track state

A track object has:

```json
{
  "status": "ACTIVE",
  "last_accepted_gate": "G1",
  "active_gate": "G2A",
  "next_gate": "G2B",
  "gates": [
    {"gate": "G1", "status": "ACCEPTED", "accepted_by_role": "OWNER_ARCHITECT"}
  ],
  "source_evidence_commit": "<40-hex-sha>"
}
```

`last_accepted_gate` and `active_gate` may be null. A track's overall status
does not promote its gates. Each gate carries its own lifecycle status.

## Baseline state

A baseline object contains:

- `name`;
- lifecycle `status`;
- optional `preservation_status` using the lifecycle enum;
- repository, branch, commit, tree, and tag identities;
- artifact digest such as `bitstream_sha256` when applicable;
- scope and qualification boundaries;
- `accepted_by_role` for accepted selection; and
- an evidence reference or `source_evidence_commit`.

Git commits and trees are distinct 40-character lowercase hashes. Artifact
SHA-256 values are normalized to 64 uppercase hexadecimal characters.

## Requirement state

A requirement object contains:

```json
{
  "id": "REQ-PCIE-PAYLOAD",
  "status": "FROZEN",
  "requirement": ">= 288 MB/s per card",
  "implementation_target": "PCIe Gen2 x1 or better",
  "qualification": "NOT_YET_QUALIFIED",
  "accepted_by_role": "OWNER_ARCHITECT",
  "source_evidence_commit": "<40-hex-sha>"
}
```

Requirement, target, implementation state, and qualification result are
separate fields. Meeting a target in a build is not inferred from the
requirement itself.

## Interface state

An interface object contains:

- stable `id`;
- lifecycle `status`;
- interface type and consumer/provider boundary;
- current semantic/version/address values;
- compatibility or preservation requirements;
- implementation/qualification state in a field not named `status`; and
- immutable evidence provenance.

Incomplete contracts use `PROVISIONAL`. Accepted architecture choices may be
`ACCEPTED` while their encoded transport ABI remains separately
`PROVISIONAL`.

## Evidence-reference object

The canonical evidence-reference shape is:

```json
{
  "id": "EVID-G1",
  "repository": "lukaszsudul/AHD-diagnostic-evidence",
  "source_evidence_commit": "<40-hex-sha>",
  "payload_commit": "<40-hex-sha-or-null>",
  "directory": "v41-development-g1-integration-architecture",
  "files": ["V41_G1_STATE.json"],
  "supports": ["STMT-C2H-ARCH"],
  "acceptance_boundary": "Evidence PASS does not itself establish Owner/Architect ACCEPTED"
}
```

`source_evidence_commit` is the immutable latest commit containing the cited
path state. `payload_commit` may identify the original publication payload
when later commits finalized receipts. Acceptance authority is always recorded
separately.

## Governance state

Governance objects must state:

- SSOT write role;
- whether Owner/Architect acceptance is required;
- whether execution pass auto-promotes state;
- optimistic concurrency behavior;
- stale-agent behavior; and
- governance lifecycle status and version.

The machine-readable writer value is `META_UPDATE_AGENT`; human-facing
summaries may render `META_UPDATE_AGENT_ONLY`.

## Unknown, absent, and false

- Use JSON `null` for an inapplicable or absent identity, such as no accepted
  Linux gate.
- Use `source_evidence_commit: null` when an Owner/Architect decision has no
  matching evidence package; the same object must then identify
  `decision_source`.
- Use `UNKNOWN` only when the subject exists but its value has not been
  established, such as the exact removable diagnostic LUT count.
- Use Boolean `false` only for a verified negative state, such as
  `gen2_qualified: false`.
- Never invent a value to avoid null or `UNKNOWN`.

## Revision invariants

1. Both JSON documents must parse as UTF-8 JSON.
2. Both carry the same `project`, `project_state_revision`, and
   `governance_version`.
3. Every accepted item identifies `OWNER_ARCHITECT` or an explicit narrow
   creation basis authorized by the Owner/Architect task.
4. Every revision-bearing update increments by exactly one.
5. All evidence commits are immutable 40-hex SHAs.
6. Every status value is in the exact lifecycle enum.
7. `CHANGELOG.md` has one immutable entry for every revision.
8. `SHA256_MANIFEST.txt` verifies every other SSOT file and excludes itself.

## Compatibility matrix schema

`COMPATIBILITY_MATRIX.csv` has exactly these columns:

```text
Consumer,Dependency,Current_Interface,Status,Current_Revision,Compatibility_Risk,Required_Action,Evidence
```

`Status` uses the lifecycle enum. `Current_Revision` is the most recent SSOT
revision that changed that row, not necessarily the global revision after
unrelated updates.
