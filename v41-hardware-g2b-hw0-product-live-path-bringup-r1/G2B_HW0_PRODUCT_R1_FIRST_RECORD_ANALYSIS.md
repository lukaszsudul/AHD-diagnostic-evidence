# G2B-HW0-PRODUCT-R1 First Record Analysis

T3 result: `NOT_REACHED`

T1 blocked before XDMA and T2 was not executed. No C2H read was attempted and
no first-record file was created.

| Field | Value |
|---|---|
| Local record path | `N/A` |
| Record bytes | `N/A` |
| SHA-256 | `NONE` |
| Header | `NOT_REACHED` |
| Payload size | `NOT_REACHED` |
| Padding / all-zero padding | `NOT_REACHED` |
| Channel / input / sequence / epoch / flags | `N/A` |
| Reserved / malformed / fatal fields | `N/A` |

No host-visible record-boundary claim and no internal AXI `TKEEP` or `TLAST`
claim is made.
