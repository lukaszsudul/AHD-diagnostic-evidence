# AHD v41 G2B-PRE SSOT Update Requirements

## Receipt and authority boundary

- Evidence repository: `lukaszsudul/AHD-diagnostic-evidence`
- Evidence branch inspected: `main`
- Evidence directory produced by this gate: `v41-development-g2b-pre-c2h-abi-mmio-freeze/`
- `PROJECT_STATE_REV_AT_START = 1`
- `PROJECT_STATE_REV_AT_END = 1`
- `SSOT_STALENESS = NONE`
- Files modified under `project-current-state/`: `NONE`

The revision value is sourced from `project-current-state/PROJECT_STATE.json:3`
and is corroborated by `project-current-state/TRACK_STATUS.json:3`,
`project-current-state/CURRENT_INTERFACES.md:3`, and
`project-current-state/README.md:15`. This G2B-PRE task is a Gate Agent task and
therefore keeps the SSOT read-only, as required by
`project-current-state/GOVERNANCE.md:59-80`.

The contracts in this evidence directory are complete and implementation-ready
for the later G2B implementation gate. Within this gate:

```text
CURRENT_TRANSPORT_ABI_STATUS = FROZEN_FOR_G2B
G2B_MMIO_STATUS = FROZEN
```

Those values are evidence truth and task-local interface decisions. They do not
modify accepted project truth. Promotion from the revision-1 SSOT state requires
an explicit Owner/Architect decision followed by a separately authorized META
transaction; evidence publication or engineering `PASS` does not perform that
promotion (`project-current-state/GOVERNANCE.md:15-36,175-191`).

## Required later META authorization

The later META task must provide all mandatory fields in
`project-current-state/META_UPDATE_TEMPLATE.md:8-31`. Its requested transaction
is:

```text
SSOT WRITE AUTHORIZED

UPDATE_TYPE:
INTERFACE_CHANGE

EXPECTED_PROJECT_STATE_REV:
1

OWNER_ARCHITECT_DECISION:
Accept AHD_C2H_TRANSPORT_ABI_V1 as FROZEN_FOR_G2B and accept the G2B MMIO
contract at 0x3800..0x3BFF as FROZEN, without claiming either interface is
implemented or hardware-qualified.

EVIDENCE_REPOSITORY:
lukaszsudul/AHD-diagnostic-evidence

EVIDENCE_COMMIT:
<immutable 40-hex commit containing the remotely read-back G2B-PRE package>

EVIDENCE_DIRECTORY:
v41-development-g2b-pre-c2h-abi-mmio-freeze

EXPECTED_AFFECTED_FILES:
project-current-state/PROJECT_STATE.json
project-current-state/TRACK_STATUS.json
project-current-state/CURRENT_INTERFACES.md
project-current-state/CURRENT_REQUIREMENTS.md
project-current-state/COMPATIBILITY_MATRIX.csv
project-current-state/OPEN_DECISIONS.md
project-current-state/CHANGELOG.md
project-current-state/EVIDENCE_MAP.md
project-current-state/SHA256_MANIFEST.txt
```

The META agent must independently verify that actual revision 1 still equals
the expected revision before writing. A mismatch is
`BLOCKED — SSOT_REVISION_CONFLICT`; it must not be pulled, merged, rebased, or
auto-resolved (`project-current-state/UPDATE_POLICY.md:39-65`). The successful
transaction produces revision 2, publishes without force, and performs byte or
SHA-256 remote read-back (`project-current-state/UPDATE_POLICY.md:17-35`).

## Normative status encoding

`FROZEN_FOR_G2B` is the required transport-domain state, but it is not a
normative lifecycle enum member. The later META update must encode:

```json
{
  "status": "FROZEN",
  "current_transport_abi_status": "FROZEN_FOR_G2B"
}
```

Any JSON key named exactly `status` or `lifecycle_status` must use `FROZEN`,
not `FROZEN_FOR_G2B`, under `project-current-state/GOVERNANCE.md:38-55` and
`project-current-state/STATE_SCHEMA.md:22-41`. A distinct semantic field may
carry `FROZEN_FOR_G2B`.

## Exact file changes required in revision 2

### `PROJECT_STATE.json`

1. Change `project_state_revision` from `1` to `2`; update the transaction date
   and immutable evidence provenance without changing unrelated project truth.
2. In `c2h_architecture`, change `record_family_status` from `PROVISIONAL` to
   lifecycle `FROZEN` and change the transport-domain value from `PROVISIONAL`
   to `FROZEN_FOR_G2B`. Record the canonical name
   `AHD_C2H_TRANSPORT_ABI_V1`, numeric ABI version, record version, exact
   `4096/64/3840/192` geometry, and the authoritative Markdown/JSON artifacts.
3. In `interfaces.transport_abi`, change lifecycle `status` from `PROVISIONAL`
   to `FROZEN` and `current_transport_abi_status` from `PROVISIONAL` to
   `FROZEN_FOR_G2B`. Add the exact compatibility, sequence, reset-epoch,
   build-identity, flag, padding, channel, payload, and parser rules by value or
   immutable artifact reference.
4. Change `interfaces.channel_identity.encoded_record_fields` from
   `PROVISIONAL` to `FROZEN`, retaining logical IDs `0,1` and physical IDs
   `0..3`.
5. Add a G2B MMIO interface object with lifecycle `status = FROZEN`, range
   `0x3800..0x3BFF`, the exact register-map artifact and compatibility rules,
   and a separate implementation state of `NOT_IMPLEMENTED`. Preserve the
   frozen legacy and R1i ranges.
6. Add an evidence-reference object for the immutable remotely verified
   G2B-PRE commit and this directory. It must cite at least
   `V41_C2H_TRANSPORT_ABI_V1.md`, `V41_C2H_TRANSPORT_ABI_V1.json`,
   `V41_G2B_MMIO_CONTRACT.md`, `V41_G2B_MMIO_MAP.csv`,
   `V41_C2H_LINUX_CONSUMER_CONTRACT.md`, and
   `G2B_PRE_ABI_CONSISTENCY_REPORT.md`.
7. Close `OD-06 / FINAL_C2H_ABI` by removing it from the current
   `open_decisions` collection. Preserve `OD-07`, `OD-08`, `OD-09`, and
   `OD-10` as `OPEN`.
8. Do not promote `application_c2h_payload`, `record_to_axi_stream_data_plane`,
   `one_channel_dma`, `two_channel_dma`, or throughput qualification. Contract
   freeze is not implementation acceptance.

Revision-1 source locations are `PROJECT_STATE.json:294-309` for C2H status,
`:374-392` for transport/channel interfaces, and `:477-499` for OD-06 through
OD-10.

### `CURRENT_INTERFACES.md`

1. Change the document revision to 2 and the top semantic banner from
   `CURRENT_TRANSPORT_ABI_STATUS = PROVISIONAL` to
   `CURRENT_TRANSPORT_ABI_STATUS = FROZEN_FOR_G2B`.
2. Replace the provisional v41D table at revision-1 lines 79-99 with the exact
   named/versioned `AHD_C2H_TRANSPORT_ABI_V1` contract and immutable artifact
   references. Mark lifecycle state `FROZEN` and implementation state
   `NOT_IMPLEMENTED`.
3. Replace the proposed G2 MMIO section at revision-1 lines 101-117 with the
   frozen `0x3800..0x3BFF` register contract. Distinguish
   `ABI_SUPPORTED`/contract capability from `IMPLEMENTED_IN_THIS_BUILD`, and
   retain `NOT_IMPLEMENTED` until a later implementation result is accepted.
4. Preserve the exact legacy/R1i behavior at revision-1 lines 45-57. The current
   identity `PROTOCOL = 0x0000400B (v40B)` must remain unchanged until a build
   actually implements and advertises the new transport; revision-1 lines
   29-30 explicitly forbid advertising unimplemented v41D.
5. Reference the frozen Linux transport consumer contract while retaining the
   V4L2 frontend, stable card identity, final V4L2 pixel format, timestamps,
   DMABUF, and future LitePCIe backend as later L-track topics.

### `CURRENT_REQUIREMENTS.md`

1. Change the document revision to 2.
2. In the C2H implementation-target section at revision-1 lines 49-63, replace
   only the statement that v41D encoding is `PROVISIONAL` with the accepted
   named ABI and `FROZEN_FOR_G2B` contract state. State the exact record
   geometry and refer to the Linux consumer contract.
3. Keep application C2H, one-channel DMA, two-channel DMA, sustained
   `>= 288 MB/s`, and hardware qualification explicitly unaccepted/unqualified.
4. Do not convert transport UYVY byte semantics into a final V4L2 pixel-format
   decision; `OD-07` remains open.

### `COMPATIBILITY_MATRIX.csv`

1. Update the `Linux/V4L2` → `FPGA transport ABI` row currently at line 5 from
   `PROVISIONAL` revision 1 to lifecycle `FROZEN` revision 2. Name
   `AHD_C2H_TRANSPORT_ABI_V1`, state the exact geometry and validation rules,
   and cite the immutable G2B-PRE evidence commit/directory.
2. Add a distinct G2B MMIO compatibility row for `0x3800..0x3BFF`, lifecycle
   `FROZEN`, current revision 2, capability-gated host use, and implementation
   state `NOT_IMPLEMENTED`.
3. Preserve the revision-1 frozen legacy BAR/MMIO row currently at line 7 and
   its `Current_Revision = 1`; `Current_Revision` is the revision that last
   changed the row, not the global revision
   (`project-current-state/STATE_SCHEMA.md:177-187`).
4. Do not promote planned V4L2 topology, userspace presentation, timestamps,
   persistent identity, or LitePCIe rows.

### `OPEN_DECISIONS.md`

1. Change the document revision to 2.
2. Remove `OD-06 / Final C2H transport ABI` from the current open table and
   record its exact closure in the new changelog/evidence-map statements.
3. Keep `OD-07 / Final V4L2 pixel format`, `OD-08 / Timestamp architecture`,
   `OD-09 / Persistent card identity`, and `OD-10 / Future LitePCIe role`
   `OPEN`. The transport-facing Linux contract does not decide those topics.
4. Keep unrelated `OD-01..OD-05` unchanged.

The revision-1 open-decision table and closure rule are at
`OPEN_DECISIONS.md:5-21`.

### `CHANGELOG.md`

Append, without modifying any byte of revision 1, a
`PROJECT_STATE_REV 2` entry that records:

- update type `INTERFACE_CHANGE`;
- exact Owner/Architect acceptance wording;
- expected/actual prior revision 1 and resulting revision 2;
- immutable G2B-PRE evidence commit and directory;
- ABI name/version and `FROZEN_FOR_G2B` semantic state;
- G2B MMIO `FROZEN` contract and `NOT_IMPLEMENTED` boundary;
- closure of only `OD-06`;
- the complete affected-file list;
- no G2B/application/two-channel/V4L2/hardware qualification promotion; and
- publication plus remote-read-back result.

The changelog is append-only (`CHANGELOG.md:3-5`).

### `EVIDENCE_MAP.md`

1. Change the document revision to 2 and record the immutable evidence snapshot
   used by the META transaction.
2. Add an `EVID-G2B-PRE` package row containing the remotely verified path
   commit, payload commit if separately recorded, directory, subtree identity,
   and the authoritative ABI/MMIO/Linux/consistency artifacts.
3. Replace revision-1 `STMT-ABI` at line 60 with a lifecycle `FROZEN` statement
   naming `AHD_C2H_TRANSPORT_ABI_V1` and the semantic state
   `FROZEN_FOR_G2B`.
4. Add a statement for the frozen G2B MMIO contract with explicit
   `NOT_IMPLEMENTED` and no-hardware-qualification boundaries.
5. Update the interface statement only as needed to say the extension contract
   is frozen; retain the exact legacy/R1i preservation boundary.
6. Record the explicit Owner/Architect decision separately from evidence
   `PASS`; the package alone does not accept project truth
   (`EVIDENCE_MAP.md:8-18,68-74`).

### `TRACK_STATUS.json`

Change only mandatory transaction bookkeeping needed for consistency:
`project_state_revision: 1 -> 2`, the update date, and evidence provenance if
the schema requires it. Do not advance, accept, or rename G2A/G2B or any G/R/L
track gate as part of this interface-only transaction.

### `SHA256_MANIFEST.txt`

After all eight non-manifest edits are final, regenerate and validate the
manifest according to `project-current-state/UPDATE_POLICY.md:130-138`. The
manifest excludes itself, uses sorted relative paths, and must match every
published affected file during remote read-back.

## Explicit non-transitions

The later META update must not infer any of the following:

- G2B RTL exists or has passed simulation, synthesis, implementation, DRC, or
  timing;
- application C2H is active in an accepted build;
- the one-channel or two-channel DMA design is qualified;
- a second physical ingress or round-robin scheduler is implemented;
- the current identity register may advertise the new ABI;
- a V4L2 driver, final V4L2 pixel format, timestamps, stable card identity,
  DMABUF path, or LitePCIe backend has been accepted;
- PCIe Gen2 training or sustained `>= 288 MB/s` has been qualified; or
- NVP/I2C reset behavior is coupled to transport reset.

## Required META completion proof

The later transaction is complete only when all nine expected affected files
are consistent at revision 2, JSON/CSV/Markdown invariants pass, the manifest
passes, the commit is pushed to `main` without force, remote HEAD equals the
publication commit, and every affected remote file matches by bytes or SHA-256.
Until then, revision 1 remains the authoritative SSOT.
