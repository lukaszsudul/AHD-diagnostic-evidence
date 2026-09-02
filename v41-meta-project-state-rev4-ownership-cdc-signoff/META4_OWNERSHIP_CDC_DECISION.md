# META-4R2 Ownership CDC Decision

## Governed decision

- Record form: `UNNUMBERED_GOVERNED_DECISION`
- Scope: Group-9 `OWNERSHIP_AXI_TO_SOURCE` sign-off methodology
- Decision state: `RESOLVED`
- Decision:
  `REPLACE_GLOBAL_BUS_SKEW_WITH_PER_FAMILY_SETTLING_CHECKS`
- Accepted by: `OWNER_ARCHITECT`

No `OD-*` number is created. All registered OD entries remain unchanged.

## Retired method

`GLOBAL_SET_BUS_SKEW_3NS` is `RETIRED_FROM_REQUIRED_SIGNOFF`. The 58-source
ownership scope is structurally heterogeneous: slot, generation, and epoch
signals feed selector/equality logic and reconverge on ownership-result logic.
It is not a homogeneous bus for a global skew comparison. BS1R reproduced the
pathological global query on an exact 58-to-1 scope, and BS2 classified the
set as `INVALID_FOR_SKEW_COMPARISON`.

## Promoted method

`PER_FAMILY_SETTLING_PLUS_STRUCTURAL_CDC` is the current required Group-9
method. It signs off the actual request/acknowledgement stable-data mailbox:

- two-stage request synchronizer;
- two-stage acknowledgement synchronizer;
- held 58-bit `{slot,generation,epoch}` payload;
- source hold until acknowledgement;
- reset/epoch coherency proof; and
- per-family absolute settling checks.

The three coherent families are:

| Family | Width | Maximum settling |
|---|---:|---:|
| `slot` | 2 bits | `6.000 ns` |
| `generation` | 24 bits | `6.000 ns` |
| `epoch` | 32 bits | `6.000 ns` |

The bound is based on the `13.468 ns` minimum launch-to-use margin and
`7.468 ns` gross reserve.

The replacement is `SAFER_AND_MORE_SEMANTICALLY_CORRECT`. **This is not a
relaxation of safety.** It replaces a topologically inappropriate global
metric with checks that correspond to mailbox correctness.

## Implementation boundary

- `RTL_CHANGE_REQUIRED = NO`.
- `ACTIVE_XDC_CHANGE = AUTHORIZED_NEXT_STEP_NOT_YET_IMPLEMENTED`.
- Candidate authority: `G2B_BS3_CANDIDATE_OWNERSHIP_CONSTRAINTS.xdc`.
- `GROUPS_10_TO_17 = UNCHANGED`.
- G2B-LUT1: `READY_FOR_SIGNOFF_RECOVERY`.
- G2B-HW: `BLOCKED`.

## Provenance

- BS1R: `f3a0df6f8c3369e229e5f5d57fef10afd6dfbf62`.
- BS2: `4699632c591238fee46ada3b0de37532fddd0b6f`.
- BS3: `10f1b66ed7c5fbbf02c7a62f3b2e6d053a88e8ae`.
