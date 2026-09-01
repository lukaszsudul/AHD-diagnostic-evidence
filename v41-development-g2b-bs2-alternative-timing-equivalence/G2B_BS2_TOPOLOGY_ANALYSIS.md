# G2B-BS2 Topology Analysis

## Result

`PATH_SET_COMPARABILITY = INVALID_FOR_SKEW_COMPARISON`

The 58 sources are one coherent transaction token, but their paths do not form 58 parallel capture-bit paths at the singleton destination. They feed a selector and wide equality reductions that reconverge into one Boolean ownership result. The exact sink therefore measures a decision cone, not a multibit capture boundary.

## Exact 58-to-1 scope

| Family | Width | Routed launch objects | Clock | Semantic role |
|---|---:|---|---|---|
| Slot | 2 | `axis_slot_reg[1:0]` | `userclk1` | Select one of four local slot records |
| Generation | 24 | `axis_generation_reg[23:0]` | `userclk1` | Compare the selected slot generation |
| Epoch | 32 | `axis_epoch_reg[31:0]` | `userclk1` | Compare descriptor epoch and reset epoch |
| Result | 1 | `own_ok_hold_source_reg` | `nvp_vclk1` | Registered Boolean result of the ownership decision |

Every endpoint inventory row is an FDRE. All 58 sources are clocked by `userclk1`; the one sink is clocked by `nvp_vclk1` and placed at `SLICE_X37Y57`.

## Why 58 sources converge to one sink

The AXI-side scheduler launches slot, generation, and epoch together and toggles the ownership request. After the request crosses two synchronizer stages, source-domain logic:

1. uses the two slot bits to select a slot record;
2. checks that its state is `COMMITTED`;
3. compares the selected 24-bit generation against the held generation;
4. compares the selected 32-bit descriptor epoch and the reset epoch against the held epoch;
5. reconverges those predicates into `own_ok_hold_source` and related state/fatal side effects.

This topology explains why one startpoint can have multiple enumerated timing paths to the same D pin. It also explains the direct `TIMING-39` warning: the bus-skew constraint covers paths with more than one logic level.

## Routed timing observations

The exact worst path starts at `axis_slot_reg[1]`, whose routed net has fanout 142, and crosses six logic levels before `own_ok_hold_source_reg/D`. It contains two `CARRY4`, one `LUT5`, and three `LUT6` elements. Delay is 4.868 ns: 1.602 ns logic and 3.266 ns routing.

The capped `get_timing_paths` call returned two distinct delay/depth signatures, both from the same startpoint:

| Returned objects | Startpoint | Datapath delay | Logic levels | Arrival time |
|---:|---|---:|---:|---:|
| 32 | `axis_slot_reg[1]/C` | 4.868 ns | 6 | 4.868 ns |
| 26 | `axis_slot_reg[1]/C` | 4.824 ns | 7 | 4.824 ns |

Because the call reached its cap with only 1/58 source coverage, these counts are not a complete logic-depth distribution for `S_FULL`.

## Clock, exception, and CDC structure

- source clock: `userclk1`, 16.000 ns
- destination clock: `nvp_vclk1`, 6.734 ns
- request crossing: two `ASYNC_REG` stages
- acknowledgement crossing: two `ASYNC_REG` stages
- stable payload paths: covered by an existing 6.000 ns `set_max_delay -datapath_only`
- first-stage control synchronizer paths: false/async treatment in the source constraints
- destination identity: one registered result, not 58 receiver bits

The payload is held while the request/ack protocol runs. Its correctness is therefore governed primarily by stable-data ordering and absolute settling before request consumption, not by simultaneous sampling of 58 independent D pins.

## Pathology interpretation

The alternative queries complete, so `TIMING_QUERY_PATHOLOGY_BROADER_THAN_BUS_SKEW` is not established. The evidence instead narrows the issue:

- `report_timing` completed in 64.164 s;
- `get_timing_paths` completed in 2.957 s;
- focused methodology completed in 23.461 s;
- the predecessor single-sink `report_bus_skew` exceeded 300 s.

The most defensible inference is that `report_bus_skew` is particularly expensive on this high-fanout, deeply reconvergent decision cone. The capped path enumeration also shows why a naive request for many paths does not produce one comparable arrival per source.

## Comparability classification

The sources are homogeneous only in transaction membership and launch clock. They are heterogeneous in function and cone depth: slot selection, generation equality, and epoch/reset equality. The sink is one aggregate Boolean result, and the dynamic inventory lacks full source coverage. A cross-source max/min arrival calculation would therefore combine incomplete objects and semantically different logic roles.

For those reasons, the exact classification is `INVALID_FOR_SKEW_COMPARISON`, not `HOMOGENEOUS` or `MOSTLY_HOMOGENEOUS`.

