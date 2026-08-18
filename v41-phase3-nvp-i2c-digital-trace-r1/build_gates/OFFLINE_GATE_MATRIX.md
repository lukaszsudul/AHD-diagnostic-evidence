# Offline diagnostic gate matrix

| Gate | Result | Evidence |
|---|---:|---|
| Exact non-Git source export | PASS | 185/185 files, zero mismatches, no `.git` |
| Existing NVP regressions | PASS | exact sealed R2 replay |
| Observer-specific regressions | PASS | all ACK/NACK/reset/readout cases |
| Base vs diagnostic functional simulation outputs | PASS | all non-diagnostic outputs equal |
| Trace survives PCIe `user_reset` | PASS | byte-identical frozen BRAM and metadata |
| Synthesis / implementation / full route | PASS | Vivado 2025.2 |
| Route errors | PASS | 0 |
| Setup timing | PASS | WNS 0.617 ns, TNS 0 |
| Hold timing | PASS | WHS 0.019 ns, THS 0 |
| VDO setup / hold | PASS | 0.617 / 0.601 ns |
| DRC errors / critical warnings | PASS | 0 / 0 |
| Critical CDC rule classes | PASS | 0 |
| Bus-skew violations | PASS | 0 |
| Raw SDA protocol/FSM fanout | PASS | only existing first synchronizer stage |
| Raw SCL protocol/FSM fanout | PASS | only existing first synchronizer stage |
| Prohibited NVP reset FSM fan-in | PASS | 0 startpoints |
| Trace-to-functional fanout | PASS | 0 forbidden endpoints |
| Existing 53-register map | PASS | offsets and semantics byte-identical |
| XDMA XCI/configuration | PASS | unchanged |
| v40B/AXIS contract | PASS | unchanged |
| Resource decision | PROCEED_DIAGNOSTIC | 39.38% LUT, 63.22% FF, 42.00% BRAM free |

Compared with the accepted Phase-2 implementation, the observer adds 200 LUTs,
115 flip-flops, and 7.5 BRAM tiles. The accepted Phase-2 setup slack was also
0.617 ns; hold slack changed from 0.036 ns to 0.019 ns and remains positive.

```text
TRACE_TO_FUNCTIONAL_FANOUT=0
TRACE_OUTPUTS_TO_I2C_FSM=0
TRACE_OUTPUTS_TO_NVP_RESET=0
TRACE_OUTPUTS_TO_VIDEO_CAPTURE=0
TRACE_OUTPUTS_TO_XDMA_STREAM=0
RAW_SDA_DIRECT_PROTOCOL_FANOUT=0
RAW_SCL_DIRECT_PROTOCOL_FANOUT=0
PROHIBITED_NVP_RST_FSM_STATE_FANIN=0
DIAGNOSTIC_IMPLEMENTATION_GATE=PASS
RESOURCE_DECISION=PROCEED_DIAGNOSTIC
```
