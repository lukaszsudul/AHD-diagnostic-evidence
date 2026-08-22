# Raw NACK count versus effective path metric

Raw `NACK_COUNT` increments for every observed byte-level NACK.  The exact
I²C FSM continues through the remaining states of that transaction after an
address-, register-, data-, or read-address NACK.  Many NACKs therefore leave
the number of later FSM states unchanged.

A completion-counter deficit instead measures the net duration of all path
changes relative to the all-ACK path.  It is consequently less sensitive than
raw NACK count to NACKs that do not alter the subsequent state path.

It is not automatically less noisy when:

- the completion counter is absent;
- multiple failure paths share the same net tick cost; or
- only aggregate NACK data is available.

Historical R1 demonstrates both properties.  Its measured deficit is 61 ticks
to the nearest tick, but the exact FSM admits multiple NACK-path decompositions
with that same net cost.  The total shortening is measured; the number and
identity of skipped operations are not uniquely identified.

For R1c, Arm A recorded 8 NACKs and Arm B 15, a raw reduction of 7.  Neither
arm contains a lifecycle count or a host-visible ordered NACK log, so the raw
reduction is not converted into an effective-operation reduction.

```text
RAW_NACK_REDUCTION=7
RAW_NACK_REDUCTION_INTERPRETED_AS_EFFECTIVE_OPERATION_REDUCTION=NO_UNLESS_PROVEN
```

