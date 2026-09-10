# CDC protocol and semantic source-family disposition

Destination/rule/severity/clock/exception preservation: PASS.

Changed critical rows: 302. Changed warning rows: 220. The run stopped before a
522-row cone proof could establish the same-base candidates. Accordingly, zero
changed rows are represented as formally reconciled in the fail-closed CSVs.

## Prohibited Critical cross-base rows (7)

| Row | Product physical source | Diagnostic physical source | Destination | Disposition |
|---|---|---|---|---|
| `CDC1-CHG-0286` | `G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C` | `G2B_ONECH_C2H/axis_slot_reg[1]/C` | `G2B_ONECH_C2H/enable_applied_source_reg/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_EPOCH_STABLE_PAYLOAD->OWNERSHIP_STABLE_PAYLOAD` |
| `CDC1-CHG-0288` | `G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C` | `G2B_ONECH_C2H/axis_slot_reg[1]/C` | `G2B_ONECH_C2H/slot_state_source_reg[0][0]/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_EPOCH_STABLE_PAYLOAD->OWNERSHIP_STABLE_PAYLOAD` |
| `CDC1-CHG-0289` | `G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C` | `G2B_ONECH_C2H/axis_slot_reg[1]/C` | `G2B_ONECH_C2H/slot_state_source_reg[0][1]/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_EPOCH_STABLE_PAYLOAD->OWNERSHIP_STABLE_PAYLOAD` |
| `CDC1-CHG-0290` | `G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C` | `G2B_ONECH_C2H/axis_slot_reg[1]/C` | `G2B_ONECH_C2H/slot_state_source_reg[0][2]/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_EPOCH_STABLE_PAYLOAD->OWNERSHIP_STABLE_PAYLOAD` |
| `CDC1-CHG-0300` | `G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C` | `G2B_ONECH_C2H/axis_slot_reg[1]/C` | `G2B_ONECH_C2H/source_ownership_fatal_deferred_reg/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_EPOCH_STABLE_PAYLOAD->OWNERSHIP_STABLE_PAYLOAD` |
| `CDC1-CHG-0301` | `G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C` | `G2B_ONECH_C2H/axis_slot_reg[1]/C` | `G2B_ONECH_C2H/source_ownership_fatal_event_reg/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_EPOCH_STABLE_PAYLOAD->OWNERSHIP_STABLE_PAYLOAD` |
| `CDC1-CHG-0302` | `G2B_ONECH_C2H/release_epoch_axi_reg[0][9]/C` | `G2B_ONECH_C2H/axis_slot_reg[1]/C` | `G2B_ONECH_C2H/source_ownership_fatal_reg/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_EPOCH_STABLE_PAYLOAD->OWNERSHIP_STABLE_PAYLOAD` |

## Prohibited Warning cross-base rows (3)

| Row | Product physical source | Diagnostic physical source | Destination | Disposition |
|---|---|---|---|---|
| `WARN-CHG-0218` | `G2B_ONECH_C2H/release_generation_axi_reg[3][2]/C` | `G2B_ONECH_C2H/release_epoch_axi_reg[2][8]/C` | `G2B_ONECH_C2H/reset_abandoned_hold_source_reg[0]/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_SLOT_STABLE_PAYLOAD->RELEASE_EPOCH_STABLE_PAYLOAD` |
| `WARN-CHG-0219` | `G2B_ONECH_C2H/release_generation_axi_reg[0][0]/C` | `G2B_ONECH_C2H/release_epoch_axi_reg[2][8]/C` | `G2B_ONECH_C2H/reset_abandoned_hold_source_reg[1]/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_SLOT_STABLE_PAYLOAD->RELEASE_EPOCH_STABLE_PAYLOAD` |
| `WARN-CHG-0220` | `G2B_ONECH_C2H/release_generation_axi_reg[0][0]/C` | `G2B_ONECH_C2H/release_epoch_axi_reg[2][8]/C` | `G2B_ONECH_C2H/reset_abandoned_hold_source_reg[2]/D` | `FAIL_SOURCE_BASE_DRIFT_PROHIBITED:RELEASE_SLOT_STABLE_PAYLOAD->RELEASE_EPOCH_STABLE_PAYLOAD` |

The 7 Critical rows cross `RELEASE_EPOCH_STABLE_PAYLOAD` to
`OWNERSHIP_STABLE_PAYLOAD`. The 3 Warning rows cross
`RELEASE_SLOT_STABLE_PAYLOAD` to `RELEASE_EPOCH_STABLE_PAYLOAD`. R2 section 4
explicitly prohibits normalization of different bus base names and section 13
forbids acceptance when the semantic source base differs. No composite family
was authorized. These ten rows are therefore deterministically unreconcilable
under the R2 contract, independent of whether the remaining same-base rows could
have passed a later cone proof.

Formal result: **FAIL — NVP_DIAG1_R2_UNRECONCILED_CDC_SOURCE_FAMILY**.
