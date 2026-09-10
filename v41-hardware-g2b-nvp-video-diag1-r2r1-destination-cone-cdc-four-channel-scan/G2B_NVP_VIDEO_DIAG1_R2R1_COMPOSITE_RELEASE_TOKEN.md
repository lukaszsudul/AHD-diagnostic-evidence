# G2B-NVP-VIDEO-DIAG1-R2R1 semantic family and composite release-token definition

Status: offline definition only. This document does not claim that either DCP
was extracted successfully or that the PRODUCT and diagnostic support sets
match.

Machine-readable companions:

- `G2B_NVP_VIDEO_DIAG1_R2R1_SOURCE_FAMILY_DEFINITIONS.csv` contains the
  anchored, exact physical-cell classifiers.
- `G2B_NVP_VIDEO_DIAG1_R2R1_SEMANTIC_MODEL.json` contains family metadata,
  use-role resolution, token structures, comparison keys, hard-fail rules, and
  final-manifest schema.
- `G2B_NVP_VIDEO_DIAG1_R2R1_ROW_PARTITION.csv` contains seven disjoint
  selectors whose union is exactly the 522 changed R2 rows.

## Canonical support atom

The comparer must key a semantic support atom on:

```text
(LeafFamily, ParentFamily, Slot, Field, SourceClock, UseRole)
```

It must compare this metadata exactly:

```text
StartpointRole
GoverningToken
Protocol
EarliestUseBarrier
ReplacementGroup
ExceptionClass
ExceptionRequirementNs
```

Physical source names and physical multiplicity are evidence, not semantic
identity. A physical startpoint may classify only through one anchored
full-name rule. Zero matches or multiple matches are failures.

## Required leaf families

The six leaves explicitly required by the R2R1 contract are:

```text
RESET_COMMIT_STABLE_PAYLOAD
OWNERSHIP_STABLE_PAYLOAD
RELEASE_GENERATION_FIELD
RELEASE_EPOCH_FIELD
RESET_ABANDONED_COUNT_STABLE_PAYLOAD
DESCRIPTOR_EPOCH_STABLE_PAYLOAD
```

Complete cone extraction can expose other cross-clock stable-mailbox sources.
The registry therefore also defines exact protocol-specific families for:

```text
DESCRIPTOR_ATTEMPT_STABLE_PAYLOAD
DESCRIPTOR_GENERATION_STABLE_PAYLOAD
OWNERSHIP_RESULT_STABLE_PAYLOAD
ENABLE_VALUE_STABLE_PAYLOAD
TRANSPORT_RESET_STABLE_PAYLOAD
SNAPSHOT_REQUEST_EPOCH_STABLE_PAYLOAD
```

These are not wildcard or suffix-normalized aliases. Each has an exact
physical full-match rule, field shape, clock pair, governing token, protocol,
barrier, exception, replacement group, and authority path. Any other
cross-clock startpoint remains unclassified and stops reconciliation.

`OWNERSHIP_RESULT_STABLE_PAYLOAD` is required because
`own_ok_hold_source_reg` is a reverse acknowledged result that legitimately
appears in AXI-destination cones. It is not the forward 58-bit ownership
payload.

### Six explicit auxiliary PRODUCT occurrences

The completed PRODUCT inventory contains exactly six cross-clock occurrences
outside the six contract-named raw leaves. They are authorized individually:

| Occurrences | Physical source | Destination(s) | Family / field / UseRole | Governing evidence |
|---:|---|---|---|---|
| 1 | enable_value_hold_axi_reg | enable_applied_source_reg/D | ENABLE_VALUE_STABLE_PAYLOAD / VALUE / ENABLE_REQUEST | Source lines 141-149, 534-540, 1857-1861; active XDC lines 27-34 |
| 2 | transport_hard_hold_axi_reg | source_ownership_fatal_event_reg/D, source_ownership_fatal_reg/D | TRANSPORT_RESET_STABLE_PAYLOAD / HARD / TRANSPORT_RESET_REQUEST | Source lines 151-162, 590-600, 629-719; active XDC lines 45-48 |
| 3 | own_ok_hold_source_reg | axis_state_reg[0..2]/D | OWNERSHIP_RESULT_STABLE_PAYLOAD / RESULT / OWNERSHIP_ACKNOWLEDGED_RESULT | Source lines 569-588, 1402-1412, 1483-1485, 1801-1820; active XDC lines 190-203; Group 9 |

The source paths are
C:/FPGA/V41_G2B_NVP_VIDEO_DIAG1/rtl/g2b/v41_g2b_onech_c2h.sv and
C:/FPGA/V41_G2B_NVP_VIDEO_DIAG1/xdc/common/g2b_cdc.xdc. These six
occurrences are explicit family membership, not arbitrary normalization.

## Ownership token

`OWNERSHIP_STABLE_PAYLOAD` is one 58-bit selected-slot token:

| Field | Logical physical aliases | Routed physical aliases | Width |
|---|---|---|---:|
| SLOT | `own_slot_hold_axi_reg[1:0]` | `axis_slot_reg[1:0]` | 2 |
| GENERATION | `own_generation_hold_axi_reg[23:0]` | `axis_generation_reg[23:0]` | 24 |
| EPOCH | `own_epoch_hold_axi_reg[31:0]` | `axis_epoch_reg[31:0]` | 32 |

The aliases are authorized by the Group 9 proof that synthesis can merge the
logical ownership holds with same-edge AXIS staging registers. All three
fields must be retained. A SLOT-only match cannot stand for the missing
GENERATION or EPOCH fields.

The forward token's UseRole is destination-specific and fail-closed:

- `own_ok_hold_source_reg/D` is `OWNERSHIP_DECISION`, because the complete
  58-bit token is evaluated to produce the held decision for both success and
  failure.
- `slot_state_source_reg[slot][bit]/D` is `OWNERSHIP_NORMAL`.
- `enable_applied_source_reg/D` and the three ownership-fatal destinations are
  `OWNERSHIP_MISMATCH`.

No other forward-ownership destination is authorized by this definition; an
unlisted destination is `FAIL_UNRESOLVED_USE_ROLE`, not a generic ownership
normalization.

The forward token is governed by:

```text
own_req_toggle_axi
-> own_req_sync1_source
-> own_req_sync2_source
-> source ownership decision
```

The result returns through:

```text
own_ack_toggle_source
-> own_ack_sync1_axi
-> own_ack_sync2_axi
```

Group 9 supplies the 6.000 ns settling cap and the 13.468 ns earliest forward
semantic-use window. The reverse `own_ok_hold_source` result retains its
source-to-AXI 6.000 ns cap and is consumed only after acknowledgement sync2,
with at least 32.000 ns acknowledgement-to-use separation in the reviewed
model.

## Composite release token

The sole release parent is:

```text
RELEASE_TOKEN_STABLE_PAYLOAD
```

For each slot `0..3` it contains exactly:

```text
RELEASE_GENERATION_FIELD:
  release_generation_axi_reg[slot][23:0]
  24 bits

RELEASE_EPOCH_FIELD:
  release_epoch_axi_reg[slot][31:0]
  32 bits

TOTAL:
  56 stable payload bits per slot
```

The leaves remain separately identified. Parent membership means only that the
two fields launch, remain stable, and are semantically consumed as one
per-slot release message.

The parent explicitly excludes all ownership fields and aliases:

```text
axis_slot_reg
own_slot_hold_axi_reg
axis_generation_reg
own_generation_hold_axi_reg
axis_epoch_reg
own_epoch_hold_axi_reg
```

### Legacy R2 names

R2 used:

```text
RELEASE_SLOT_STABLE_PAYLOAD
RELEASE_EPOCH_STABLE_PAYLOAD
```

R2R1 records those names only as explicit legacy aliases:

```text
RELEASE_SLOT_STABLE_PAYLOAD -> RELEASE_GENERATION_FIELD
RELEASE_EPOCH_STABLE_PAYLOAD -> RELEASE_EPOCH_FIELD
```

This is a naming bridge, not a change of meaning and not a merge between
generation and epoch.

## Release use roles

### Ordinary normal release

For `slot_state_source_reg[slot][0..2]/D`, the use role is
`ORDINARY_RELEASE_NORMAL`. Only the matching destination slot is required.
The governing event is:

```text
release_toggle_axi[slot]
-> release_sync1_source[slot]
-> release_sync2_source[slot]
-> generation/epoch/reset-epoch/state-qualified release decision
```

The barrier is the Groups 14-17 13.468 ns earliest-use window with a 6.000 ns
absolute settling cap.

### Ordinary mismatch containment

For `enable_applied_source_reg/D` and the three ownership-fatal destinations,
the use role is `ORDINARY_RELEASE_MISMATCH`. Each release slot actually
present in the extracted cone remains a separate atom. The governing event is
the same per-slot release sync2 chain. A mismatch drives the fatal event and
admission-disable containment path.

### Reset-overlap accounting

For `reset_abandoned_hold_source_reg[0..2]/D`, the use role is
`RESET_OVERLAP_ACCOUNTING`. This role is not governed by ordinary release
sync2 detection.

The semantic-use trigger is:

```text
transport_req_toggle_axi
-> transport_req_sync1_source
-> transport_req_sync2_source
-> aggregate abandoned-record calculation
```

The retirement barrier is separately recorded:

```text
transport_release_phase_hold_axi[3:0]
==
release_sync2_source[3:0]
before transport acknowledgement
```

All four slots require both release child fields, their ordinary
release-toggle/sync2 structures, captured transport release phase, and local
slot-state qualification. Group 13 governs returned reset accounting.
Groups 14-17 govern the four release-token families.

The three exact rows are:

```text
WARN-CHG-0218 -> reset_abandoned_hold_source_reg[0]/D
WARN-CHG-0219 -> reset_abandoned_hold_source_reg[1]/D
WARN-CHG-0220 -> reset_abandoned_hold_source_reg[2]/D
```

Their PRODUCT representatives are generation leaves and their diagnostic
representatives are epoch leaves. Only
`COMPOSITE_RELEASE_TOKEN_EQUIVALENCE` can reconcile them.

## Exact changed-row partition

| Partition | Exact selectors | Count | Proof class |
|---|---|---:|---|
| Critical reset commit | `CDC1-CHG-0001..0285` | 285 | `SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE` |
| Critical ownership | `CDC1-CHG-0287`, `CDC1-CHG-0291..0299` | 10 | `SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE` |
| Critical cross-family | `CDC1-CHG-0286`, `0288`, `0289`, `0290`, `0300`, `0301`, `0302` | 7 | `DESTINATION_CONE_SUPPORT_SET_EQUIVALENCE` |
| Warning descriptor epoch | `WARN-CHG-0001..0024` | 24 | `SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE` |
| Warning reset commit | `WARN-CHG-0025..0088`, `WARN-CHG-0119..0217` | 163 | `SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE` |
| Warning reset abandoned | `WARN-CHG-0089..0118` | 30 | `SAME_FAMILY_REPRESENTATIVE_EQUIVALENCE` |
| Warning composite release | `WARN-CHG-0218..0220` | 3 | `COMPOSITE_RELEASE_TOKEN_EQUIVALENCE` |

Therefore:

```text
critical same-family = 285 + 10 = 295
critical destination-cone = 7
critical total = 302

warning same-family = 24 + 163 + 30 = 217
warning composite release = 3
warning total = 220

changed total = 522
```

The selector union must equal the RowID set in the two hash-pinned R2
registries. The 522 destinations must remain unique, with terminal counts
`D=226`, `CE=265`, `R=31` and clock-pair counts
`nvp_vclk1->userclk1=502`, `userclk1->nvp_vclk1=20`.

## Seven critical cross-family rows

The seven rows have PRODUCT representative
`release_epoch_axi_reg[0][9]/C` and diagnostic representative
`axis_slot_reg[1]/C`. They are not same-family changes.

The exact destinations are:

```text
CDC1-CHG-0286  enable_applied_source_reg/D
CDC1-CHG-0288  slot_state_source_reg[0][0]/D
CDC1-CHG-0289  slot_state_source_reg[0][1]/D
CDC1-CHG-0290  slot_state_source_reg[0][2]/D
CDC1-CHG-0300  source_ownership_fatal_deferred_reg/D
CDC1-CHG-0301  source_ownership_fatal_event_reg/D
CDC1-CHG-0302  source_ownership_fatal_reg/D
```

For each destination, the actual extracted PRODUCT and diagnostic support
sets control. Ownership and release are expected when the cone proves their
presence, but must not be forced into a missing cone. PASS requires exact
support-atom and metadata equality, zero diagnostic-only family, zero missing
PRODUCT family, and no asynchronous bypass.

## Fail-closed interpretation notes

1. The R2 representative `/C` pin is not a Q/startpoint pin. Resolve its one
   sequential owner and separately prove that owner belongs to the destination
   startpoint-cell set.
2. `reset_abandoned_hold_source_reg` is dual-role: it is a cross-clock source
   for AXI return/accounting destinations, and it is the destination of the
   three reset-overlap composite rows. Classification follows startpoint
   identity, not destination base name.
3. Same-clock controls are recorded separately and excluded from the
   cross-clock family set. Their control/use roles must still be audited.
4. The mandated 23-column support CSV does not expose source-clock sets,
   token structure, unclassified sources, or local controls. Every
   `EvidencePath` must point to detailed per-row JSON containing those fields.
5. Group 9 and Groups 13-17 prove protocol and timing semantics. They do not
   prove membership in a current DCP fan-in cone. Only complete extraction of
   each exact endpoint does that.
6. Physical startpoint multiplicity may change under legal merging. Missing
   semantic fields, slots, parents, tokens, protocols, barriers, exceptions,
   or replacement groups may not.
7. The prompt names the V2 manifest as
   `NVP_VIDEO_DIAG1_R1_CDC_SEMANTIC_MANIFEST_V2.*` in Phase I but lists
   `G2B_NVP_VIDEO_DIAG1_R2R1_CDC_SEMANTIC_MANIFEST_V2.*` in the required
   artifacts. Both three-file name sets are required; corresponding CSV, JSON,
   and key/value SHA sidecar files must be byte-identical.

## Authority

- R2 critical registry SHA-256:
  `7E60B4855BD2A1D578A8D03E49806A6BDC0806DAEAAB0A490A95F3C8714B4148`.
- R2 warning registry SHA-256:
  `5A1B267ED3EDA48D0A8DB545DE47DF8E8C83634D4AE7674991F7EE69A078945E`.
- Ownership semantics: Group 9 BS3 ownership mailbox evidence.
- Reset-return semantics: Group 13 reset semantic proof.
- Release semantics: Group 14 and Groups 15-17 structural, timing, and
  equivalence evidence.
- Descriptor semantics: preserved Groups 10-12 evidence.
- Auxiliary enable, transport, and snapshot semantics: exact source protocol
  plus preserved active CDC constraints.
