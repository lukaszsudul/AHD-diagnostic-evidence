# Stage B observer R2 offline gate matrix

| Gate | Result | Evidence |
|---|---:|---|
| Exact non-Git base export | PASS | exact `fd32fcb...` tree, no `.git` |
| Sealed R2 source manifest | PASS | 190 files, zero mismatches |
| Observer-specific simulation | PASS | false ACK, real NACK, invalid SCL-high, all ACK phases, context ring, reset retention |
| Inherited NVP/I2C simulations | PASS | full fault matrix, D2b, power/reset |
| Base-versus-R2 non-diagnostic behavior | PASS | identical inherited regression outcomes/timing |
| Synthesis / implementation / full route | PASS | Vivado 2025.2 |
| Route errors | PASS | 0 |
| Setup timing | PASS | WNS 0.617 ns, TNS 0 |
| Hold timing | PASS | WHS 0.035 ns, THS 0 |
| VDO setup / hold | PASS | 0.617 / 0.601 ns |
| DRC errors / critical warnings | PASS | 0 / 0 |
| Critical CDC rule classes | PASS | 0 |
| Bus-skew violations | PASS | 0 |
| Raw SDA protocol/FSM fanout | PASS | no endpoint beyond existing first synchronizer stage |
| Raw SCL protocol/FSM fanout | PASS | no endpoint beyond existing first synchronizer stage |
| Prohibited NVP reset FSM fan-in | PASS | 0 startpoints |
| Trace-to-functional fanout | PASS | 0 forbidden endpoints |
| Shadow-monitor-to-functional fanout | PASS | 0 forbidden endpoints |
| Existing 53-register offsets/semantics | PASS | unchanged; overlay is outside active formal slots |
| Diagnostic AXI-Lite window | PASS | non-overlapping, read-only, diagnostic writes consumed with no state effect |
| XDMA XCI/configuration | PASS | unchanged |
| v40B/AXIS contract | PASS | unchanged |
| Resource decision | PROCEED_DIAGNOSTIC_R2 | 36.45% LUT, 62.04% FF, 38.00% BRAM free |

Resource comparison against the accepted formal Phase-2 implementation:

```text
                         FORMAL_PHASE2   OBSERVER_R2   DELTA
LUT_USED                 12408           13218         +810
FF_USED                  15187           15793         +606
BRAM_TILE_USED           21.5            31.0          +9.5
WNS_NS                   0.617           0.617         0.000
WHS_NS                   0.036           0.035         -0.001
```

Independent routed-checkpoint replays produced:

```text
ASYNC_INPUT_FANOUT_GATE=PASS
NVP_RST_FANIN_GATE=PASS
OBSERVER_CELL_COUNT=2
TRACE_TO_FUNCTIONAL_FANOUT=0
SHADOW_MONITOR_TO_FUNCTIONAL_FANOUT=0
TRACE_OUTPUTS_TO_I2C_FSM=0
TRACE_OUTPUTS_TO_NVP_RESET=0
TRACE_OUTPUTS_TO_VIDEO_CAPTURE=0
TRACE_OUTPUTS_TO_XDMA_STREAM=0
R2_OFFLINE_GATE=PASS
RESOURCE_DECISION=PROCEED_DIAGNOSTIC_R2
```

No functional NVP/I2C correction, ACK-timing change, retry, reset change,
frequency change, table change, AXI-Lite write, or DMA operation was introduced.
