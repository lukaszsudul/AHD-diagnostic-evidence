# G2B-BS3 Constraint Diff

## Conceptual change

OLD:

```tcl
set_bus_skew 3.000 \
  -from $g2b_ownership_payload_src \
  -to   $g2b_ownership_payload_dst
```

The resolved old scope was 58 sources by 19 heterogeneous destinations. It mixed 17 real payload-dependent state/effect registers with two request/ack bookkeeping registers. Its relative-skew report was pathological, and TIMING-34/TIMING-39 identified the value/topology as unsuitable.

NEW:

```tcl
set_max_delay -datapath_only 6.000 \
  -from $g2b_bs3_ownership_slot_src \
  -to   $g2b_bs3_ownership_payload_dst_d
set_max_delay -datapath_only 6.000 \
  -from $g2b_bs3_ownership_generation_src \
  -to   $g2b_bs3_ownership_payload_dst_d
set_max_delay -datapath_only 6.000 \
  -from $g2b_bs3_ownership_epoch_src \
  -to   $g2b_bs3_ownership_payload_dst_d
```

The three source families resolve exactly 2/24/32 objects. The destination set resolves exactly 17 payload-dependent D pins. `own_req_seen_source` and `own_ack_toggle_source` are removed from the payload endpoint set and remain covered by the structural control proof.

## Preservation boundary

The routed full constraint export contains 17 `set_bus_skew` commands. The isolated BS3 analysis base removes exactly the one ownership command and retains the other 16 unchanged. The candidate stanza adds no ownership bus-skew command. All non-Group-9 constraints remain unchanged, including:

- the aggregate 6.000 ns AXI-to-source acknowledged-mailbox cap;
- the aggregate 6.000 ns source-to-AXI acknowledged-mailbox cap covering `own_ok_hold_source`;
- first-stage synchronizer false paths;
- the 16 unrelated bus-skew checks.

## Why this is not a safety relaxation

The mailbox does not sample 58 bits in an unqualified vector bank. The fields feed dynamic selection and equality logic, then reconverge into registered success/failure effects only when a synchronized request is recognized. The actual safety property is that every cone is stable before that edge.

The replacement proves a stronger relevant statement for every family: the complete data cone reaches its destination D pin within 6.000 ns, while the earliest request-use edge is 13.468 ns after launch. A relative-only check cannot by itself prevent all bits from arriving late together. A common absolute deadline plus the proven hold protocol provides atomic-token coherence even if relative route spread exceeds 3.000 ns.

The 6.000 ns limit is not new or relaxed; it is the already-present aggregate mailbox limit made explicit and separately reportable for the three ownership fields. The companion sign-off Tcl—not the declarative XDC—fails closed on exact object, synchronizer, and clock identity/count checks. The resulting classification is `SAFER_AND_MORE_SEMANTICALLY_CORRECT`.

## Candidate promotion boundary

The published candidate is the Group-9 replacement stanza, not a mutation of active XDC. Promotion must replace only the old ownership `set_bus_skew` line, preserve the other 16 skew relations and all other production constraints, and rerun the recipe in `G2B_BS3_RECOMMENDED_SIGNOFF_RECIPE.md`.
