# META-7R Governed Groups 15–17 Decision

```json
{
  "topic": "GROUPS15_17_RELEASE_SLOT_SIGNOFF_METHODOLOGY",
  "record_form": "UNNUMBERED_GOVERNED_DECISION",
  "status": "ACCEPTED",
  "decision_state": "RESOLVED",
  "decision": "PROMOTE_COMBINED_SETTLING_PLUS_STRUCTURAL_CDC",
  "covered_groups": [
    15,
    16,
    17
  ],
  "slot_structural_relation": "PARTIALLY_EQUIVALENT",
  "safety_protocol_equivalence": "PROVEN",
  "slot_specific_routed_checks_required": "YES",
  "accepted_by_role": "OWNER_ARCHITECT",
  "decision_source": "META-7R_TASK_DIRECTIVE",
  "source_evidence_commit": "fe6dd4aa4d9083ff5b830d71b9b7f2e51505218c",
  "evidence_directory": "v41-development-g2b-g15-17-release-slot-equivalence-audit"
}
```

The corrected task grants Owner/Architect approval. No OD number is invented.
All existing numbered and unnumbered decisions remain unchanged.

The exact Owner/Architect decision is preserved in
`META7_FROZEN_WRITE_CONTRACT_RECEIPT.md`. The common architecture requires
three independent slot implementations; routed equivalence is partial and
safety-protocol equivalence is proven. The timing cap is 6.000 ns for each
of nine families, with a 13.468 ns minimum launch-to-use window and 7.468 ns
gross reserve. Source/RTL and active XDC remain unchanged by META-7R.
