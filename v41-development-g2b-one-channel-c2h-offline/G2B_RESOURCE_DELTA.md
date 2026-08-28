# AHD v41 G2B Resource Delta

## Result

`G2B_SYNTHESIS: NOT_RUN`

`G2B_IMPLEMENTATION: NOT_RUN`

`G2B_RESOURCE_DELTA: NOT_MEASURED`

The gate stopped before RTL edits because the record ABI is not frozen. No
G2B resource value is reported as zero: unimplemented future logic consumes
unknown resources, and an empty source diff is not a resource result.

## Accepted G2A comparison baseline

These are inherited measurements from the accepted G2A clean R2 build, not
G2B measurements.

| Stage/resource | G2A used | Device total | Utilization |
|---|---:|---:|---:|
| Post-opt LUT | 18,569 | 20,800 | 89.274% |
| Routed LUT | 18,178 | 20,800 | 87.394% |
| Post-opt/routed FF | 20,137 | 41,600 | 48.406% |
| Post-opt/routed BRAM tile equivalents | 26 | 50 | 52.000% |
| Post-opt/routed DSP | 0 | 90 | 0.000% |

G2A routing was fully routed, with no unresolved level-5-or-higher congestion
finding. The accepted G2A routed delta versus qualified R1i was `-3 LUT`,
`+54 FF`, and `0 BRAM`.

## G1 development limits and inherited headroom

| Metric | Development limit | G2A position | G2B result |
|---|---:|---:|---|
| LUT | preferred <=85%; hard stop >90% post-opt or routed | above preferred; below hard stop | NOT_RUN |
| FF | <=80% post-opt and routed | 48.406% | NOT_RUN |
| BRAM | <=80% post-opt and routed | 52.000% | NOT_RUN |
| DSP | <=85% | 0.000% | NOT_RUN |
| Congestion | no unresolved level >=5 hotspot | G2A PASS | NOT_RUN |

The 90% LUT boundary is 18,720 LUT. G2A had only 151 LUT of post-opt margin
and 542 LUT of routed margin to that temporary development hard boundary.
Those numbers are warning headroom, not a budget that G2B has demonstrated it
can meet.

## Architecture-only storage floor

The G1 one-channel plan calls for four complete 4,096-byte slots:

```text
4 slots × 4,096 bytes = 16,384 bytes = 131,072 bits
```

Pure capacity corresponds to approximately four RAMB36 tile equivalents
before packing inefficiency, descriptors, CDC state, formatter storage, or
control/status logic. This is a raw capacity floor, not an inference report
or permission to add four to the G2A total and declare resource acceptance.

## Unmeasured G2B fields

| Field | Value |
|---|---|
| LUT used/percent/delta | N/A — NOT_RUN |
| FF used/percent/delta | N/A — NOT_RUN |
| BRAM used/percent/delta | N/A — NOT_RUN |
| DSP used/percent/delta | N/A — NOT_RUN |
| Hierarchical C2H delta | N/A — NOT_RUN |
| Route congestion | N/A — NOT_RUN |
| Seed/directive stability | N/A — NOT_RUN |

No R-track diagnostics were removed or reduced. Resource-policy compliance
cannot be classified PASS until a frozen-contract G2B design is cleanly
synthesized, implemented, and routed.

