# G2B-BS3 Candidate Exception Effectiveness

## Isolated context

After the full-context family queries and methodology report, the successful worker used `reset_timing -invalid`, loaded the BS2 skew-free routed constraint base, and reloaded the BS3 candidate. Thus this report contains no bus-skew constraint while preserving ordinary clocks, false paths, and the existing aggregate mailbox max-delay caps.

## Coverage

`report_exceptions -coverage` reports the three candidate commands as positions 50–52:

| Position | Type | From | To | Endpoints | From coverage | To coverage | Result |
|---:|---|---:|---:|---:|---:|---:|---|
| 50 | Max Delay Datapath Only, 6 ns | 2 cells | 17 pins | 17 | 100.00% | 100.00% | PASS — slot |
| 51 | Max Delay Datapath Only, 6 ns | 24 cells | 17 pins | 17 | 100.00% | 100.00% | PASS — generation |
| 52 | Max Delay Datapath Only, 6 ns | 32 cells | 17 pins | 17 | 100.00% | 100.00% | PASS — epoch |

Exact list/hash validation independently proves that those counts are the qualified BS0 identities, not merely collections of the right size.

## Ignored/overlap disposition

`report_exceptions -ignored` does not list positions 50, 51, or 52 as totally ignored. Vivado documents that this report does not enumerate partially overridden constraints, so absence alone is not treated as proof of independent dominance.

The candidate scopes overlap the retained broad AXI-to-source aggregate max-delay constraint at the identical 6.000 ns value. Each routed family query returns:

- `REQUIREMENT=6.000`;
- `EXCEPTION=MaxDelay Path 6.000ns -datapath_only`;
- start clock `userclk1` and endpoint clock `nvp_vclk1`;
- a nonnegative slack and raw datapath delay below 6.000 ns.

Therefore any equal-value partial precedence cannot relax the safety property. The coverage report proves all 2/24/32 by 17 candidate endpoints are represented; the path reports prove the effective selected exception has the required type/value/direction. The candidate commands are useful explicit audit scopes even where the retained aggregate cap is equivalent.

`CANDIDATE_EXCEPTION_EFFECTIVENESS = PASS_WITH_EQUAL_VALUE_OVERLAP`

Owner/architect review should choose whether production promotion retains these explicit equal-value family scopes or instead names the same family queries against the existing aggregate cap. Either choice must preserve the exact identity, coverage, timing, and structural gates.
