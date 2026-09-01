# G2B-BS2 Timing Property Inventory

## Scope and query

- Sealed routed DCP SHA-256: `EAE2DEF4B05A04241A36B79BEF154FB455A53DB91F8C6078FCFC75A30E2ACF83`
- Sources: `S_FULL`, 58 exact cells
- Destination: `K_OWNERSHIP_RESULT`, `G2B_ONECH_C2H/own_ok_hold_source_reg`
- Query: one `get_timing_paths -delay_type max -max_paths 58 -nworst 58` call with the exact collections
- Tool: Vivado 2025.2, build 6299465
- Returned path objects: 58, exactly at the configured cap

The query completed, but its 58 objects do not cover 58 source cells. All objects start at `G2B_ONECH_C2H/axis_slot_reg[1]/C` and end at `G2B_ONECH_C2H/own_ok_hold_source_reg/D`. They represent reconvergent alternatives from one startpoint: 32 objects have a 4.868 ns/6-level path and 26 have a 4.824 ns/7-level path. Unique source-cell coverage is therefore `1/58`.

## Actual path properties

The property names below come from `list_property` on returned Vivado timing-path objects. Similar-looking names not returned by Vivado are explicitly marked absent; they were not invented or substituted.

| Requested concept | Actual Vivado property | Availability | Returned value or range | Interpretation |
|---|---|---:|---|---|
| Datapath delay | `DATAPATH_DELAY` | present on 58/58 | 4.824–4.868 ns | Absolute data-path delay for each returned timing path |
| Alternate spelling | `DATA_PATH_DELAY` | absent | N/A | Not an actual property on these objects |
| Arrival | `ARRIVAL_TIME` | present on 58/58 | 4.824–4.868 ns | Equals datapath delay here because launch/capture clock delays are both 0 under the datapath-only exception |
| Generic arrival name | `ARRIVAL` | absent | N/A | Not an actual property on these objects |
| Data arrival name | `DATA_ARRIVAL_TIME` | absent | N/A | Not an actual property on these objects |
| Slack | `SLACK` | present on 58/58 | 1.162–1.206 ns | Slack against the 6.000 ns max-delay constraint plus endpoint setup |
| Constraint requirement | `REQUIREMENT` | present on 58/58 | 6.000 ns | `MaxDelay Path 6.000ns -datapath_only` |
| Computed required time | `REQUIRED_TIME` | present on 58/58 | 6.030 ns | Includes 0.030 ns destination setup time |
| Startpoint clock | `STARTPOINT_CLOCK` | present on 58/58 | `userclk1` | 16.000 ns period in the timing report |
| Endpoint clock | `ENDPOINT_CLOCK` | present on 58/58 | `nvp_vclk1` | 6.734 ns period in the timing report |
| Logic depth | `LOGIC_LEVELS` | present on 58/58 | 6 or 7 | Heterogeneous reconvergent selector/compare paths |
| Delay type | `DELAY_TYPE` | present on 58/58 | `max` | Setup/max, slow process corner |
| Source endpoint | `STARTPOINT_PIN` | present on 58/58 | `G2B_ONECH_C2H/axis_slot_reg[1]/C` | Actual returned source endpoint property |
| Destination endpoint | `ENDPOINT_PIN` | present on 58/58 | `G2B_ONECH_C2H/own_ok_hold_source_reg/D` | Actual returned destination endpoint property |
| Relative skew | `SKEW` | property exists, no value on 58/58 | N/A | These timing paths do not contain a bus-skew result |
| Uncertainty | `UNCERTAINTY` | property exists, no value on 58/58 | N/A | No value exposed for the datapath-only path objects |
| Exception | `EXCEPTION` | present on 58/58 | `MaxDelay Path 6.000ns -datapath_only` | Confirms this is an absolute-delay timing context |
| Maximum fanout | `MAX_FANOUT` | present on 58/58 | sample 142 | High-fanout launch net contributes to topology complexity |

Other actual properties are preserved verbatim in `G2B_BS2_TIMING_PATH_PROPERTY_NAMES.txt` and `G2B_BS2_TIMING_PATH_PROPERTY_VALUES.csv`.

## Exact-scope worst path

The separate exact-scope `report_timing` call returned one global worst path:

- startpoint: `G2B_ONECH_C2H/axis_slot_reg[1]/C`
- destination: `G2B_ONECH_C2H/own_ok_hold_source_reg/D`
- source clock: `userclk1`, 16.000 ns
- destination clock: `nvp_vclk1`, 6.734 ns
- context: Setup / Max / Slow process corner
- `DATAPATH_DELAY`: 4.868 ns
- logic delay: 1.602 ns
- net delay: 3.266 ns
- logic levels: 6 (`CARRY4=2`, `LUT5=1`, `LUT6=3`)
- requirement: 6.000 ns max-delay, datapath-only
- slack: +1.162 ns

This proves the worst absolute path selected from the exact 58-to-1 collection meets the existing 6.000 ns datapath-only bound. It does not prove the relative arrival spread of all 58 sources.

## Alternative-skew availability decision

`ARRIVAL_TIME` exists, but the returned objects cover only one of the 58 sources and the query hit its path-count cap. The mechanical 0.044 ns difference between the two returned arrival values is merely dispersion between reconvergent paths from the same source. It is not a 58-source bus-skew measurement.

- `ALTERNATIVE_COMPUTED_SKEW_AVAILABLE = NO`
- `ALTERNATIVE_COMPUTED_SKEW = N/A`
- `ALTERNATIVE_SLACK = N/A`
- `ALTERNATIVE_TIMING_RESULT = NOT_AVAILABLE`
- Official `report_bus_skew` result: `NOT_COMPLETED`

