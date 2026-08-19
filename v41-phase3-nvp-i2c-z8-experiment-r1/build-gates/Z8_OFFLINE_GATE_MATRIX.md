# Stage C Z8 offline gate matrix

| Gate | Result | Evidence |
|---|---:|---|
| Exact non-Git base export | PASS | exact `fd32fcb...` tree; no `.git` |
| Frozen combined source manifest | PASS | 193 files; zero post-freeze mismatches |
| Observer R2 patch identity | PASS | `78C2D409...CCD2F0E51` |
| Isolated Z8 functional patch identity | PASS | `A41797FB...DEE1872` |
| Z8 functional delta scope | PASS | ACK sample phase only; four existing ACK paths |
| Functional half phase | PASS | 626 clocks / 10.016 us |
| Midpoint sample | PASS | 313 clocks / 5.008 us |
| SCL period unchanged | PASS | no state, tick, divider, or drive-transition change |
| START/STOP behavior unchanged | PASS | inherited and dedicated simulation |
| Retry/reset/table/bank/abort policy | PASS | no change |
| Dedicated Z8 simulations | PASS | all ACK/NACK phases, real ACK, real NACK, invalid SCL-high |
| Inherited NVP/I2C simulations | PASS | autoinit, D2b, and power/reset regressions |
| Trace retention / read-only window | PASS | PCIe `user_reset` retention and write-no-effect simulation |
| Synthesis / implementation / full route | PASS | Vivado 2025.2, build cycle 1 |
| Route errors | PASS | 0 |
| Setup timing | PASS | WNS 0.617 ns, TNS 0 |
| Hold timing | PASS | WHS 0.036 ns, THS 0 |
| VDO setup / hold | PASS | 0.617 / 0.601 ns |
| DRC errors / critical warnings | PASS | 0 / 0; six noncritical warnings retained verbatim |
| Critical CDC rule classes | PASS | 0 |
| Bus-skew violations | PASS | 0 |
| Raw SDA protocol/FSM fanout | PASS | existing first synchronizer only; no forbidden endpoint |
| Raw SCL protocol/FSM fanout | PASS | existing first synchronizer only; no forbidden endpoint |
| Prohibited NVP reset FSM fan-in | PASS | 0 startpoints |
| Trace-to-functional fanout | PASS | 0 forbidden endpoints |
| Shadow-monitor-to-functional fanout | PASS | 0 forbidden endpoints |
| Existing 53-register offsets/semantics | PASS | formal block byte-identical; overlay outside active formal slots |
| Diagnostic AXI-Lite window | PASS | non-overlapping, identity-gated, read-only |
| XDMA XCI/configuration | PASS | byte-identical to validated R2/formal source |
| v40B/AXIS contract | PASS | byte-identical functional path |
| Resource decision | PROCEED_EXPERIMENTAL_Z8 | 36.12% LUT, 62.00% FF, 38.00% BRAM free |

Resource comparison against the accepted formal Phase-2 implementation:

```text
                         FORMAL_PHASE2   Z8_EXPERIMENT   DELTA
LUT_USED                 12408           13286           +878
FF_USED                  15187           15809           +622
BRAM_TILE_USED           21.5            31.0            +9.5
WNS_NS                   0.617           0.617           0.000
WHS_NS                   0.036           0.036           0.000
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
Z8_OFFLINE_GATE=PASS
RESOURCE_DECISION=PROCEED_EXPERIMENTAL_Z8
```

This gate authorizes only the single ephemeral Z8 hardware experiment. It does
not qualify a production correction or resume Phase 3.

