# META-5 Group-13 Governed Decision

## Record

- Group: `13`.
- Group name: `RESET_RETURN_SOURCE_TO_AXI`.
- Topic: `GROUP13_RESET_RETURN_SOURCE_TO_AXI_SIGNOFF_METHODOLOGY`.
- Record form: `UNNUMBERED_GOVERNED_DECISION`.
- Lifecycle status: `ACCEPTED`.
- Decision state: `RESOLVED`.
- Decision: `REPLACE_WITH_SETTLING_PLUS_STRUCTURAL_CDC`.
- Accepted by role: `OWNER_ARCHITECT`.
- Decision source: `META-5_TASK_DIRECTIVE`.
- Owner/Architect approval: `GRANTED`.

No numbered Group-13 OD record existed. Following successful META-4R2, this
decision is named but unnumbered. No `OD-*` identifier was invented; all 12
open OD records, the existing OD-03 decided record, and the revision-4
Group-9 unnumbered decision remain unchanged.

## Immutable authority

- Repository: `lukaszsudul/AHD-diagnostic-evidence`.
- Commit: `10c7c2898d162af8e2262b3f99861c7d560c4557`.
- Directory: `v41-development-g2b-g13a-reset-return-signoff-audit`.
- Directory tree: `d4694977a5bfecfec8005d9cc0dd1c1c44f36f7f`.
- G13-A engineering gate: `PASS`.

## Decision content

The former Group-13 global `set_bus_skew 3.000` relation from
`$g2b_reset_return_src` to `$g2b_reset_return_dst` is retired from required
sign-off. It had seven source and 207 destination registers. The query's
pathological runtime is verified, the full `report_bus_skew` was not retried,
and the heterogeneous stable-data/handshake/reconvergent path set is
`INVALID_FOR_SKEW_COMPARISON`.

The current required method is `SETTLING_PLUS_STRUCTURAL_CDC`, comprising the
exact G13-A family timing checks, the unchanged broad aggregate relation, and
the complete structural reset-return CDC proof. This is
`SAFER_AND_MORE_SEMANTICALLY_CORRECT`, not a relaxation of safety.

`RTL_CHANGE_REQUIRED = NO`. Active production XDC remains unchanged. The
candidate `G2B_G13A_CANDIDATE_CONSTRAINTS.xdc` is authorized only for the next
governed engineering task, `G2B-LUT1-SIGNOFF-RECOVERY-2`.

Group 9 and Groups 10–12 retain their authoritative results. Groups 14–17
remain pending unchanged. G2B-HW remains `BLOCKED`.
