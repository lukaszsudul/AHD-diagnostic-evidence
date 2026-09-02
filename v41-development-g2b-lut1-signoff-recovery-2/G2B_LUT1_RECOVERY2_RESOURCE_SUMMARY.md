# G2B-LUT1 Recovery 2 PRODUCT Resource Summary

## Result

`PRODUCT_RESOURCES = NOT_REACHED`

Fresh utilization for the governed PRODUCT profile was not run. The
Group-14 required bus-skew query timed out first, and the bounded-runtime policy
stopped the execution before downstream resource sign-off.

| Resource | Used | Total | Percent |
|---|---:|---:|---:|
| LUT | N/A | N/A | N/A |
| FF | N/A | N/A | N/A |
| BRAM | N/A | N/A | N/A |

| Gate | Result |
|---|---|
| PRODUCT LUT hard gate `<= 90%` | `NOT_REACHED` |
| Preferred LUT target `80-85%` | N/A |

The offline functional-protection receipt confirms that the PRODUCT profile
selection and its protected build inputs were unchanged by the constraints-only
source delta. That static protection result is not a substitute for the fresh
PRODUCT utilization required here. RESEARCH_DIAGNOSTIC utilization is not used
for this disposition, and no bitstream was generated.
