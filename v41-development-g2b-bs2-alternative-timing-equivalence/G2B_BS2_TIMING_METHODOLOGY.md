# G2B-BS2 Timing Methodology Review

## Focused run

After the alternative queries completed, BS2 applied the exact 3.000 ns 58-to-1 bus-skew constraint in memory and ran only:

```tcl
report_methodology -checks {TIMING-32 TIMING-34 TIMING-37 TIMING-38 TIMING-39}
```

The skew-free base XDC contained zero `set_bus_skew` commands, so the findings below correlate to the exact BS2 constraint. No production XDC was changed. The focused report completed in 23.461 s; a full methodology ruledeck was not run.

## Results

| Rule | Status | Count | Relevance |
|---|---|---:|---|
| `TIMING-32` | `ABSENT` | 0 | The focused check ran and produced no finding. It provides no contrary evidence for this scope. |
| `TIMING-34` | `PRESENT` | 1 | Direct. Vivado reports the 3.000 ns bus-skew value as unrealistic/aggressive and names `own_ok_hold_source_reg/D` as the first endpoint. |
| `TIMING-37` | `ABSENT` | 0 | The focused check ran and produced no finding. |
| `TIMING-38` | `ABSENT` | 0 | The focused check ran and produced no finding. |
| `TIMING-39` | `PRESENT` | 1 | Direct. Vivado reports that the bus-skew constraint covers paths with more than one logic level and names the exact sink. |

## TIMING-34 interpretation

Vivado defines the finding here as a bus-skew value below half the shorter source/destination period, or below 1 ns. The measured clock periods are:

- `userclk1`: 16.000 ns; half-period 8.000 ns
- `nvp_vclk1`: 6.734 ns; half-period 3.367 ns

The 3.000 ns requirement is below 3.367 ns. Vivado also states that an aggressive value increases runtime. This warning directly supports the observed `report_bus_skew` runtime concern, but it does not by itself authorize relaxing or removing a necessary CDC protection.

## TIMING-39 interpretation

The exact worst path contains six logic levels, and the capped path objects show six- and seven-level reconvergent alternatives. The constraint is therefore applied well beyond a simple parallel bundle capture boundary. This warning supports the structural conclusion that a 58-to-1 max/min arrival comparison is not a clean bus-skew sign-off primitive.

## Other warnings and errors

The timing queries reported no query-specific errors. Vivado emitted one startup warning about a duplicate user strategy definition; it is unrelated to the routed timing scope. Standard informational messages from loading the generated base XDC are preserved in the console log.

## Disposition

The focused methodology result changes the previously unresolved Gen12 status to:

- `TIMING-32 = ABSENT`
- `TIMING-34 = PRESENT`
- `TIMING-37 = ABSENT`
- `TIMING-38 = ABSENT`
- `TIMING-39 = PRESENT`

Both present findings are directly relevant to Group 9 and favor a mailbox-semantic, absolute-settling methodology over retaining the current broad bus-skew formulation.

