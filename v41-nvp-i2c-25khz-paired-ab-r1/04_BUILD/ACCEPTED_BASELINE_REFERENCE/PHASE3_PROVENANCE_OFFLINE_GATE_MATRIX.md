# Phase 3 provenance offline gate matrix

All mandatory pre-hardware gates pass.

| Gate | Observed | Result |
|---|---:|---|
| Synthesis / implementation / route | PASS / PASS / fully routed | PASS |
| Setup timing | WNS 0.617 ns, TNS 0 ns | PASS |
| Hold timing | WHS 0.036 ns, THS 0 ns | PASS |
| DRC | 0 errors, 0 critical warnings, 6 reviewed warnings | PASS |
| Bus skew | 0 violations | PASS |
| Critical-class CDC types | 0 | PASS |
| Raw SDA/SCL forbidden fanout | 0 / 0 | PASS |
| NVP reset forbidden FSM fan-in | 0 | PASS |
| Provenance round trip / static binding | PASS / PASS | PASS |
| XDMA XCI | exact Phase-2 SHA match | PASS |
| AXI-Lite map / v40B AXIS contract | unchanged / unchanged | PASS |
| Resource decision | PROCEED | PASS |

The six DRC warnings are the same rule classes and counts as the accepted
Phase-2 implementation: PDCN-1569 (1), REQP-1839 (4), and RTSTAT-10 (1).
The provenance-only build consumes 38 additional LUTs while all other reported
resource totals remain within the accepted headroom.

```text
OFFLINE_TIMING=PASS
OFFLINE_DRC=PASS
OFFLINE_CDC=PASS
OFFLINE_BUS_SKEW=PASS
SDA_SCL_GATE=PASS
NVP_RST_GATE=PASS
RESOURCE_DECISION=PROCEED
PROVENANCE_STATIC_GATE=PASS
OVERALL_OFFLINE_GATE=PASS
```
