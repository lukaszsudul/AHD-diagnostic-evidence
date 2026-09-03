# META-6 Group-14 Governed Decision

## Record

- Group: `14`.
- Group name: `RELEASE_SLOT_0_AXI_TO_SOURCE`.
- Topic: `GROUP14_RELEASE_SLOT_0_AXI_TO_SOURCE_SIGNOFF_METHODOLOGY`.
- Record form: `UNNUMBERED_GOVERNED_DECISION`.
- Lifecycle status: `ACCEPTED`.
- Decision state: `RESOLVED`.
- Decision: `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`.
- Accepted by role: `OWNER_ARCHITECT`.
- Decision source: `META-6_TASK_DIRECTIVE`.
- Owner/Architect approval: `GRANTED`.

No numbered Group-14 OD record existed. Following successful META-4R2 and
META-5, this decision is named but unnumbered. No `OD-*` identifier was
invented; all 12 open OD records, the existing OD-03 decided record, and the
revision-4 Group-9 and revision-5 Group-13 unnumbered decisions remain
unchanged.

## Immutable authority

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Commit: `9e91315968453e859006077191cd5fc711fc6b96`.
- Commit tree: `95961d96ca164d4b7838454df4075f1287e7a19f`.
- Directory: `v41-development-g2b-g14a-release-slot0-signoff-audit`.
- Directory tree: `ae0c1472b90bf4cecc2df8feebe192b35b8355be`.
- G14-A engineering gate: `PASS`.
- G14-A package manifest: `65/65 PASS`.

## Decision content

The former Group-14 global `set_bus_skew 3.000` relation from
`$g2b_release0_payload_src` to `$g2b_release_payload_dst` is retired from
required `RELEASE_SLOT_0_AXI_TO_SOURCE` sign-off. It had 56 source and 20
destination registers. The query's pathological runtime is verified, the
full `report_bus_skew` was not retried, and the heterogeneous reconvergent
path set is `INVALID_FOR_SKEW_COMPARISON`.

The current required method is `SETTLING_PLUS_STRUCTURAL_CDC`, comprising the
exact three G14-A family timing checks and the complete release-token CDC and
protocol proof. This is `SAFER_AND_MORE_SEMANTICALLY_CORRECT`, not a
relaxation of safety.

The promoted invariant requires a held 24-bit generation plus 32-bit epoch
release token, stable until the relevant synchronized event is consumed.
Ordinary use follows two-stage release-toggle synchronization. Reset-overlap
accounting follows two-stage transport-request synchronization, uses the same
episode token, and completes only after the captured release phase is retired.
Normal token use requires matching slot generation, descriptor epoch, current
reset epoch, and `DMA_OWNED` state; mismatch fails closed by latching ownership
fatal and disabling admission.

`RTL_CHANGE_REQUIRED = NO`. Active production XDC remains unchanged. The
candidate `G2B_G14A_CANDIDATE_CONSTRAINTS.xdc` is authorized only for the next
governed engineering task, `G2B-LUT1-SIGNOFF-RECOVERY-3`.

Group 9, Groups 10–12, and Group 13 retain their authoritative PASS results.
Groups 15–17 remain pending unchanged. G2B-HW remains `BLOCKED`.
