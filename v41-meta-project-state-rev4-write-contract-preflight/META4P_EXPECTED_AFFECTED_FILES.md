# AHD v41 META-4P Expected Affected Files

## Preflight result

This is read-only governance-preflight evidence. It does not authorize or
perform a META-4 promotion and it does not modify `project-current-state/`.

| Field | Verified value |
|---|---|
| Evidence repository checkout | `C:\\FPGA\\V41_G2B_EVIDENCE` |
| Branch / HEAD | `main` / `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae` |
| `PROJECT_STATE_REV` | `3` |
| Frozen governance version | `1` |
| SSOT manifest | `PASS`, 18/18 entries |
| Lifecycle-value validation | `PASS`, zero invalid values |
| Required META-4 update type | `ARCHITECTURE_CHANGE` |
| Required authorization literal | standalone `SSOT WRITE AUTHORIZED` |
| Expected SSOT transaction scope | 16 paths |

## Frozen contract

The authoritative files are:

| Rule file | Current identity |
|---|---|
| `project-current-state/GOVERNANCE.md` | SHA-256 `4B7497BAFA243544AFE9779E046802BF6E7E3F5FAA0AB62D2312724AC5C696E1`; Git blob `4718be1b9c2ef91f646ea62644265dc81d5daf92` |
| `project-current-state/UPDATE_POLICY.md` | SHA-256 `F5927BDDABC47C68597FA745E10429DBB2972F0483F5D335291D09DD45B51497`; Git blob `cf3de9ec8576b0cf5c63c15d060f6dbb32ece21f` |
| `project-current-state/META_UPDATE_TEMPLATE.md` | SHA-256 `F7119369043E5C348AAA4B14BC4A3BBB80FB6AC6E0343BAA904909A2C22D0B27`; Git blob `4dbc2d8547f64fdc048a82c5935ed2d08eb7a452` |
| `project-current-state/STATE_SCHEMA.md` | SHA-256 `6AE9C691748CE9FEF5186083DE50BF9F93EAF5E9AFEBDCB0156A7CDE650B60E3`; Git blob `96b496e913f7dfb1c0fd67069cefa184b4a6bfea` |

The exact supported `UPDATE_TYPE` literals are:

```text
TRACK_GATE_ACCEPTANCE
BASELINE_CHANGE
INTERFACE_CHANGE
REQUIREMENT_CHANGE
ARCHITECTURE_CHANGE
RESEARCH_PROMOTION
SUPERSESSION
BLOCKER_CHANGE
META_GOVERNANCE_CHANGE
```

The policy requires one supported `UPDATE_TYPE`. Promotion of the accepted
ownership CDC sign-off architecture is therefore represented by the single
literal `ARCHITECTURE_CHANGE`. The readiness, requirements, interface,
compatibility, and decision-register edits are consequences needed to keep
that architecture promotion internally consistent.

The exact mandatory prompt contract is a standalone authorization literal
followed by the seven governed field labels:

```text
SSOT WRITE AUTHORIZED

UPDATE_TYPE:
<one supported category>

EXPECTED_PROJECT_STATE_REV:
<positive integer>

OWNER_ARCHITECT_DECISION:
<exact accepted decision>

EVIDENCE_REPOSITORY:
<repository>

EVIDENCE_COMMIT:
<full 40-hex immutable commit>

EVIDENCE_DIRECTORY:
<directory at that commit>

EXPECTED_AFFECTED_FILES:
<exact paths>
```

There is no governed `AUTHORIZATION:` field. `SSOT WRITE AUTHORIZED` is not an
update-type value.

## Exact expected affected files

Every path below exists at the verified rev3 state. `Required by frozen rule`
means the path is mandatory bookkeeping, a revision-bearing mirror, or an
impacted architecture/requirements/interface/tracks/compatibility/decision
document under the frozen update policy.

| Path | Exists | Current identity | Reason for change | Expected fields/sections | Required by frozen rule? |
|---|---|---|---|---|---|
| `project-current-state/ACTIVE_BASELINES.md` | YES | SHA-256 `7E28F64B92CB34A0741ADAC9EB8633976BFEAD1760907233D33D6B6F625C8154`; blob `c110a3b48aaa055a379e729a235fe8df981293ae` | Revision-bearing live G2B baseline/readiness summary | `PROJECT_STATE_REV`; accepted G2B contract/resource baseline; G2B-LUT1 readiness and next-step boundary | YES |
| `project-current-state/CHANGELOG.md` | YES | SHA-256 `19D1F81930FC7CF8F262436C9A564965A09DC87EAC61EF113626E83EB762245E`; blob `0fce426f8071c86663e770e6c318fc681b12611a` | Mandatory append-only transaction history | Append `PROJECT_STATE_REV 4` entry with authorization, decision, evidence, affected paths, non-promotions, publication, and read-back | YES |
| `project-current-state/COMPATIBILITY_MATRIX.csv` | YES | SHA-256 `94D381D87CFB84617CA8D4E2374697E3487BC6B451A5D5BA84EDB81533B7DF1D`; blob `4b786193686fc99560cd99215efe1953745c731b` | The Future G2B implementation row carries the current CDC/timing action and evidence | Update only impacted G2B implementation/profile/hardware row content, `Current_Revision` for changed rows, required Group-9 action, and BS1R/BS2/BS3 provenance | YES |
| `project-current-state/CURRENT_ARCHITECTURE.md` | YES | SHA-256 `BE455DDE9BC312355D7207CCECF39E5CCB2046ACBE2B95675A9E55C96188043D`; blob `2f42cb490ddcbe62efe4b769865f66e080914bef` | Primary domain file for `ARCHITECTURE_CHANGE` | `PROJECT_STATE_REV`; G2B state/maturity matrix; ownership mailbox structure; retired and replacement Group-9 sign-off; next engineering boundary | YES |
| `project-current-state/CURRENT_INTERFACES.md` | YES | SHA-256 `525F16AE4E5CC99E2D52A1CA0AA9AE7C7231390E40BA0CD3781A2BDACE739BCD`; blob `92c911ed1750672f4bdc199a75f13973984a4ae0` | Ownership/epoch mailbox semantics are part of the frozen G2B implementation input | `PROJECT_STATE_REV`; ownership CDC sign-off subsection; held 58-bit payload; request/ack synchronizers; candidate-XDC intent and non-implementation boundary | YES |
| `project-current-state/CURRENT_REQUIREMENTS.md` | YES | SHA-256 `09AB4260542CE4932B329737F257E83B01D70643B6D19DFF85B15DC247C353E5`; blob `95a46326ddfc7d8b46d593da2b5d2a3e5373156f` | The governed future sign-off recipe and unchanged Groups 10-17 are requirements | `PROJECT_STATE_REV`; Group-9 structural/per-family checks and numerical bounds; Groups 10-17 unchanged; routed timing/DRC/CDC/clocks/resources/pre-bitstream gates | YES |
| `project-current-state/CURRENT_RESOURCE_STATE.md` | YES | SHA-256 `AF9E23B2C26C03FB93A41BF36DD33EC36BD3E3A4CE866E7FFCE3E6C87866C700`; blob `6f30cfab237ae5fb2e26ce62b9ce4ed645ccce29` | Revision-bearing current-state mirror; G2B-LUT1 recovery wording is live | `PROJECT_STATE_REV`; G2B-LUT1 readiness wording only as needed; no resource result promotion | YES |
| `project-current-state/CURRENT_STATUS.md` | YES | SHA-256 `27E03220554434D964D3C2D0BA49CF201BA2641B880195EC31EE6B95DA0A13DA`; blob `e24bc8e8ebd17e7b2801e67cf7daa3bd5d246c71` | Current gate/state summary must expose the promoted method and remaining block | `PROJECT_STATE_REV`; decision basis; G2B-LUT1 `READY_FOR_SIGNOFF_RECOVERY`; G2B-HW `BLOCKED`; META-4 state; no bitstream/hardware claim | YES |
| `project-current-state/CURRENT_TRACKS.md` | YES | SHA-256 `850468BA0FB4F5AB0C5CE6E50A5AE43D99A5E71C1096CA62A1845FE4AC64DD06`; blob `8e285ea103e1052ad55d13c8a96a1b5a8d61dd19` | G-track next decision/action and META transaction state change | `PROJECT_STATE_REV`; G2B-LUT1 readiness; exact next gate `G2B-LUT1-SIGNOFF-RECOVERY`; META-4 promotion; R-track unchanged | YES |
| `project-current-state/EVIDENCE_MAP.md` | YES | SHA-256 `F63CCB065C8A995EB88EB790C05340EB484D53162668C8DFDA94241F5F358698`; blob `9b7e69dabb4e8508c724751fd5928643ed076bb2` | Mandatory statement-to-evidence provenance | `PROJECT_STATE_REV`; BS1R/BS2/BS3 package entries; Group-9/CDC/retirement/readiness statement rows; acceptance and non-qualification boundaries | YES |
| `project-current-state/GOVERNANCE.md` | YES | SHA-256 `4B7497BAFA243544AFE9779E046802BF6E7E3F5FAA0AB62D2312724AC5C696E1`; blob `4718be1b9c2ef91f646ea62644265dc81d5daf92` | Factual governed-revision mirror | Change only `Project-state revision governed: 3` to `4`; governance version and semantics remain unchanged | YES |
| `project-current-state/OPEN_DECISIONS.md` | YES | SHA-256 `921B0087ABFEC3603FD4EBDBA26B9A1CD0BDEDED95119293DD95C66B7467FA9E`; blob `9f17f7af25053c728a89f3e11da1487cfb673e75` | Revision-bearing decision register and requested Group-9 resolution | `PROJECT_STATE_REV`; add the explicitly authorized Group-9 decided/closure record; preserve every currently registered open decision | YES |
| `project-current-state/PROJECT_STATE.json` | YES | SHA-256 `9ED040C2146C6938F7C4B90694396182D4E1B0C9BD2450675508415386001A14`; blob `d45da466c20e4adcfb1d1890429043d38c193a31` | Mandatory machine-readable project truth | Revision/transaction metadata; product next gate; G2B-LUT1 readiness; G2B-HW block; ownership CDC/Group-9 decision; evidence references; decided-decision record | YES |
| `project-current-state/README.md` | YES | SHA-256 `BB240DFE1A1E3E5996EF5D67D5569A2CE172F6E0D8CD0C8BA4C3EA6ED16657A3`; blob `6d82625e4671225fc9c82fe96ac69b0b02e0197a` | Top-level revision and current snapshot mirror | Revision, last update, revision-4 basis, current G2B-LUT1/G2B-HW/META snapshot and non-promotion boundary | YES |
| `project-current-state/SHA256_MANIFEST.txt` | YES | SHA-256 `E6F4281186CCFA1A5549092217C92E94FF0C97EDAA5A12B350D7A54ABE8F67FA`; blob `b57c2d60440b8869593fa1a28af356995df53dc9` | Mandatory SSOT integrity inventory | Recompute all 18 non-self entries after the transaction; uppercase SHA-256; lexical relative paths | YES |
| `project-current-state/TRACK_STATUS.json` | YES | SHA-256 `C91D97A727B421D1EE85AAACB0F68681CC05C006F7289C91FCAD09344EEB7C2B`; blob `84baccd43c2cc9d19b815cadef50ba057d6228a1` | Mandatory machine-readable track/revision state | Revision/transaction metadata; G2B-LUT1 readiness and next gate; G2B-IMPL/HW block; META-4 task/evidence | YES |

`UPDATE_POLICY.md`, `META_UPDATE_TEMPLATE.md`, and `STATE_SCHEMA.md` are not
expected affected files: META-4 changes accepted architecture/project state,
not frozen policy, template, schema, or governance semantics.

## Decision-register precondition

Current revision 3 contains no Group-9, `OWNERSHIP_AXI_TO_SOURCE`, or
`report_bus_skew` entry in either `OPEN_DECISIONS.md` or
`PROJECT_STATE.json.open_decisions`. The currently registered open IDs are
`OD-01`, `OD-02`, `OD-04`, `OD-05`, and `OD-07` through `OD-14`.

A compliant META-4R reissue must therefore do one of the following explicitly:

1. authorize a new named, unnumbered Group-9 decided/closure record while
   preserving every current `OD-*` entry; or
2. supply the exact existing decision ID to close.

The META agent must not invent an OD number or silently remove an unrelated
open decision. The companion reissue header uses option 1.

## Historical META precedent

### META-2

- Exact update type: `INTERFACE_CHANGE`.
- Exact authorization syntax is preserved in
  `v41-development-g2b-pre-c2h-abi-mmio-freeze/G2B_PRE_SSOT_UPDATE_REQUIREMENTS.md`:
  standalone `SSOT WRITE AUTHORIZED`, followed by the seven template fields.
- Nine expected paths were explicitly listed before the later update; the
  calculated and actual revision-2 SSOT scope was 16 after adding live
  revision mirrors/current summaries.
- Revision mechanism: guard revision 1, increment every revision-bearing
  file to 2, update both JSON revisions, append one changelog entry, regenerate
  the 18-entry manifest.
- Payload commit: `7225dae0464a41aaed8ae007f0cc0cd6b0c2e48b`.
- Evidence-only read-back receipt: `4452f6b4293bd4e4267f81c7c8d42cac3f14fd83`.

### META-3

- The report records `ARCHITECTURE_CHANGE + REQUIREMENT_CHANGE + BLOCKER_CHANGE`.
  Those are three allowed literals combined, not one supported composite
  literal; the still-frozen single-category rule controls META-4.
- The exact original authorization header and a pre-write expected-file block
  are not preserved. The report attests that authorization was present and
  later records a calculated/actual 16-file scope.
- Revision mechanism: guard revision 2, increment every revision-bearing
  file to 3, update both JSON revisions, append one changelog entry, regenerate
  the 18-entry manifest.
- Payload commit: `fc03d01c3ac37ca4ff40694a9e21d5ffdcc589ac`.
- Evidence-only read-back receipt: `25bd079c540392a5848ea404e1151672225c1497`.

Both successful transactions used an ordinary non-force payload push,
remote-HEAD plus SHA-256 read-back, and a later evidence-only receipt commit
that did not rewrite `project-current-state/`.

## Rev3 to rev4 transaction rule

The frozen contract permits revision `3 -> 4` when a new prompt contains the
exact companion header, remote/current revision still equals 3, the accepted
BS3 commit/directory remain verifiable, the calculated scope is these 16
paths, lifecycle values remain in the frozen enum, the earlier changelog is
preserved byte-for-byte, the SSOT manifest validates, publication is an
ordinary non-force push, and remote read-back passes.
