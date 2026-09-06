# R3R1 prior immutable-boundary final comparison

Final observation UTC: `2026-09-06T17:32:56.6552578Z`

Boundary: `C:\FPGA\G2B_HW0_PRODUCT_R1_20260905`

| Field | Baseline | Final | Match |
|---|---|---|---|
| recursive files | `107` | `107` | `YES` |
| descendant directories | `38` | `38` | `YES` |
| root creation UTC | `2026-09-05T21:54:19.3132153Z` | same | `YES` |
| root last-write UTC | `2026-09-05T22:54:01.4590886Z` | same | `YES` |
| secret subtree inventory | one directory plus one `10908`-byte package-copy file | identical | `YES` |

Sentinel SHA-256 values remained identical:

- `3E63F22C0F45722D0F2220A9689C87633FB922FA2E1A67202E10296B3875E20E`
  for both controller lock-release receipts;
- `5C922E314F8B20560BCA62A2EC94ED9FB240CDC50445C2EF0BD11DDE3F37519A`
  for the initial readback result;
- `12BE29D2805CDF1FE911E7469F1EB30D0538E0A0EB3457C561BE6A3CAE57018C`
  for the completion readback result.

No temporary credential file was present at either observation.

`PRIOR_IMMUTABLE_ARTIFACT_NEW_WRITES = 0`

`PRIOR_IMMUTABLE_BOUNDARY_GATE = PASS`
